#!/usr/bin/env python3
"""Procedural generators for The Forensic Ward's original sound effects and stingers.

Every sound here is synthesized from noise and oscillators with a fixed random
seed, so output is reproducible and owned by the project (no third-party
samples). Run from the repository root:

    .venv-audio/bin/python tools/audio/synth_sfx.py            # all assets
    .venv-audio/bin/python tools/audio/synth_sfx.py pager      # one asset

Writes 48 kHz OGG Vorbis files into audio/ (encoded with ffmpeg/libvorbis).
"""
import argparse
from pathlib import Path
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
SR = 48000


# --- Building blocks -----------------------------------------------------------

def seconds(duration):
    return int(round(duration * SR))


def t_axis(duration):
    return np.arange(seconds(duration)) / SR


def butter(data, kind, cutoff, order=4):
    sos = signal.butter(order, cutoff, btype=kind, fs=SR, output="sos")
    return signal.sosfilt(sos, data, axis=0)


def pink_noise(n, rng):
    """Voss-McCartney approximation via 1/f spectral shaping."""
    white = rng.standard_normal(n)
    spectrum = np.fft.rfft(white)
    freqs = np.fft.rfftfreq(n, 1 / SR)
    freqs[0] = freqs[1]
    spectrum /= np.sqrt(freqs)
    pink = np.fft.irfft(spectrum, n)
    return pink / np.max(np.abs(pink))


def env_exp(n, decay_seconds):
    return np.exp(-np.arange(n) / SR / decay_seconds)


def place(track, clip, start_seconds, gain=1.0):
    start = seconds(start_seconds)
    end = min(len(track), start + len(clip))
    track[start:end] += clip[: end - start] * gain


def reverb_ir(rt60, rng, pre_delay=0.01, length=None, brightness=6000):
    """Synthetic stereo impulse response: decaying, decorrelated, darkening noise."""
    length = length or rt60 * 1.2
    n = seconds(length)
    decay = np.exp(-6.91 * np.arange(n) / SR / rt60)
    channels = []
    for _ in range(2):
        noise = rng.standard_normal(n) * decay
        noise = butter(noise, "lowpass", brightness, order=2)
        noise = np.concatenate([np.zeros(seconds(pre_delay)), noise])
        channels.append(noise / np.sqrt(np.sum(noise ** 2)))
    return np.stack(channels, axis=1)


def apply_reverb(dry, ir, wet):
    """dry: mono or stereo. Returns stereo dry/wet mix, tail included."""
    if dry.ndim == 1:
        dry = np.stack([dry, dry], axis=1)
    tail = len(ir)
    out = np.zeros((len(dry) + tail, 2))
    out[: len(dry)] += dry * (1 - wet)
    for channel in range(2):
        out[:, channel][: len(dry) + len(ir) - 1] += signal.fftconvolve(dry[:, channel], ir[:, channel]) * wet
    return out


def normalize_peak(data, peak_db):
    return data / np.max(np.abs(data)) * 10 ** (peak_db / 20)


def normalize_rms(data, rms_db, ceiling_db=-1.0):
    rms = np.sqrt(np.mean(data ** 2))
    data = data / rms * 10 ** (rms_db / 20)
    ceiling = 10 ** (ceiling_db / 20)
    peak = np.max(np.abs(data))
    if peak > ceiling:  # Soft-limit rare transients instead of lowering the whole bed.
        data = np.tanh(data / ceiling) * ceiling
    return data


def fade(data, fade_in=0.0, fade_out=0.0):
    data = data.copy()
    if fade_in:
        n = seconds(fade_in)
        ramp = np.sin(np.linspace(0, np.pi / 2, n)) ** 2
        data[:n] *= ramp if data.ndim == 1 else ramp[:, None]
    if fade_out:
        n = seconds(fade_out)
        ramp = np.cos(np.linspace(0, np.pi / 2, n)) ** 2
        data[-n:] *= ramp if data.ndim == 1 else ramp[:, None]
    return data


def write_ogg(data, relative_path, quality=6):
    """Encode float audio to OGG Vorbis via ffmpeg (libvorbis)."""
    target = ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as directory:
        wav = Path(directory) / "master.wav"
        sf.write(wav, np.clip(data, -1.0, 1.0), SR, subtype="FLOAT")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                        "-c:a", "libvorbis", "-q:a", str(quality),
                        "-map_metadata", "-1", "-fflags", "+bitexact", str(target)], check=True)
    print(f"wrote {relative_path} ({len(data) / SR:.2f} s)")


# --- Reusable sound sources -------------------------------------------------------

def thump(rng, freq=70.0, decay=0.15, click=0.3):
    """Low body impact with a short noisy click on top."""
    n = seconds(decay * 6)
    t = np.arange(n) / SR
    sweep = freq * (1 + 0.6 * np.exp(-t / 0.02))  # Slight downward pitch on impact.
    body = np.sin(2 * np.pi * np.cumsum(sweep) / SR) * env_exp(n, decay)
    noise = butter(rng.standard_normal(n), "bandpass", [800, 5000]) * env_exp(n, 0.008)
    return body + noise * click


def metal_ring(rng, partials=(1210, 2930, 4710, 6150), decay=0.25):
    n = seconds(decay * 5)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for index, freq in enumerate(partials):
        out += np.sin(2 * np.pi * freq * t + rng.uniform(0, 6.28)) * env_exp(n, decay / (1 + 0.5 * index)) / (index + 1)
    return out


def beep(freq, duration, square=0.35):
    """Small-speaker electronic beep: sine blended toward square, clickless edges."""
    t = t_axis(duration)
    sine = np.sin(2 * np.pi * freq * t)
    tone = (1 - square) * sine + square * np.sign(sine)
    return fade(tone, 0.003, 0.004)


def small_speaker(data, low=900, high=6500):
    return butter(np.tanh(data * 1.5), "bandpass", [low, high], order=2)


def footstep(rng, surface="vinyl"):
    """One heel-toe step. 'vinyl' = hospital sheet flooring, 'tile' = brighter, 'concrete' = gritty."""
    color = {"vinyl": (180, 2500, 0.025), "tile": (400, 7000, 0.018), "concrete": (250, 4500, 0.03)}[surface]
    heel = thump(rng, freq=90, decay=0.03, click=0.5)
    heel = butter(heel, "bandpass", [color[0], color[1]], order=2)
    n = seconds(0.12)
    scuff = butter(rng.standard_normal(n), "bandpass", [color[0] * 2, color[1]], order=2) * env_exp(n, color[2]) * 0.4
    step = np.zeros(seconds(0.35))
    place(step, heel, 0.0)
    place(step, scuff, 0.06)
    return step


# --- Assets -------------------------------------------------------------------------

def corridor_ambience_loop():
    """60 s seamless loop: ventilation, duct resonance, fluorescent ballast hum, rare distant events."""
    rng = np.random.default_rng(1101)
    length = 60.0
    overlap = 4.0
    total = seconds(length + overlap)
    t = np.arange(total) / SR
    channels = []
    for channel in range(2):
        # Ventilation: broadband air, mostly low/mid, slow breathing modulation.
        air = pink_noise(total, rng)
        air = butter(air, "lowpass", 900, order=2) + 0.12 * butter(rng.standard_normal(total), "bandpass", [1500, 6000], order=2)
        air *= 1 + 0.12 * np.sin(2 * np.pi * 0.071 * t + channel) + 0.05 * np.sin(2 * np.pi * 0.23 * t)
        # Duct resonances.
        duct = sum(butter(rng.standard_normal(total), "bandpass", [f * 0.97, f * 1.03], order=2) * g
                   for f, g in ((96, 0.9), (183, 0.5), (311, 0.25)))
        channels.append(air + duct * 0.35)
    bed = np.stack(channels, axis=1)

    # Fluorescent ballast hum (60 Hz mains, 120 Hz fundamental) with faint jitter; centered.
    hum = np.zeros(total)
    jitter = 1 + 0.002 * np.sin(2 * np.pi * 0.37 * t)
    for harmonic in range(1, 14):
        hum += np.sin(2 * np.pi * 120 * harmonic * np.cumsum(jitter) / SR) / harmonic ** 1.6
    hum = butter(hum, "highpass", 100, order=2) * 0.035
    bed += hum[:, None]

    # Distant events (kept away from loop seam). Heavily low-passed and reverberant.
    events = np.zeros(total)
    place(events, butter(thump(rng, freq=55, decay=0.25), "lowpass", 600), 13.7, 0.5)
    place(events, butter(thump(rng, freq=62, decay=0.2), "lowpass", 500), 41.2, 0.35)
    for index, step_time in enumerate(np.arange(24.0, 31.5, 0.56)):
        distance_gain = np.sin(np.pi * index / 13) * 0.09  # Approaches, then fades.
        place(events, butter(footstep(rng, "vinyl"), "lowpass", 1800), step_time + rng.uniform(-0.02, 0.02), distance_gain)
    wet_events = apply_reverb(events, reverb_ir(1.6, rng, pre_delay=0.03, brightness=2500), 0.75)[:total]
    bed += wet_events * 0.6

    bed = normalize_rms(bed, -30.0, ceiling_db=-6.0)
    # Seamless loop: equal-power crossfade of the overlap tail into the head.
    n_overlap = seconds(overlap)
    head = bed[:n_overlap]
    tail = bed[seconds(length):seconds(length) + n_overlap]
    ramp = np.linspace(0, np.pi / 2, n_overlap)[:, None]
    looped = bed[:seconds(length)].copy()
    looped[:n_overlap] = head * np.sin(ramp) + tail * np.cos(ramp)
    write_ogg(looped, "audio/ambience/amb_corridor_day_loop.ogg", quality=5)


def secure_door_open():
    """Badge accept beep, maglock release, heavy door swing with hinge and closer hiss."""
    rng = np.random.default_rng(2202)
    out = np.zeros(seconds(3.4))
    reader = np.concatenate([beep(1760, 0.07), np.zeros(seconds(0.03)), beep(2350, 0.12)])
    place(out, small_speaker(reader), 0.0, 0.45)
    place(out, thump(rng, freq=68, decay=0.09, click=0.8), 0.32, 0.9)  # Maglock release.
    place(out, metal_ring(rng, decay=0.15) * 0.25, 0.32)
    place(out, butter(thump(rng, freq=110, decay=0.04, click=1.0), "highpass", 300), 0.36, 0.5)  # Latch.

    swing = seconds(1.9)
    swing_env = np.sin(np.linspace(0, np.pi, swing)) ** 1.5
    whoosh = butter(pink_noise(swing, rng), "bandpass", [120, 1400], order=2) * swing_env * 0.25
    place(out, whoosh, 0.55)
    # Hinge: slowly varying narrowband friction tone.
    creak_n = seconds(1.1)
    creak_t = np.arange(creak_n) / SR
    creak_freq = 380 + 60 * np.sin(2 * np.pi * 1.3 * creak_t) + 25 * rng.standard_normal(creak_n).cumsum() / np.sqrt(creak_n)
    creak = np.sin(2 * np.pi * np.cumsum(creak_freq) / SR) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 9 * creak_t)))
    creak = butter(creak + 0.3 * rng.standard_normal(creak_n), "bandpass", [300, 2400], order=2)
    place(out, creak * np.sin(np.linspace(0, np.pi, creak_n)) * 0.05, 0.75)
    # Hydraulic closer: soft hiss tail.
    hiss_n = seconds(1.2)
    hiss = butter(rng.standard_normal(hiss_n), "bandpass", [2000, 7000], order=2) * np.linspace(1, 0, hiss_n) ** 2 * 0.04
    hiss = fade(hiss, 0.15)
    place(out, hiss, 1.9)

    stereo = apply_reverb(out, reverb_ir(0.7, rng, pre_delay=0.008, brightness=5000), 0.22)
    stereo = fade(normalize_peak(stereo, -3.0), 0.0, 0.3)
    write_ogg(stereo[:seconds(3.4)], "audio/sfx/sfx_door_secure_open.ogg")


def pager_alert():
    """Three-burst pager alert from a belt-clip pager in a quiet room."""
    rng = np.random.default_rng(3303)
    out = np.zeros(seconds(1.8))
    burst = np.concatenate([beep(3100, 0.085, square=0.6), np.zeros(seconds(0.05))] * 2)
    for index in range(3):
        place(out, burst, 0.02 + index * 0.42)
    out = small_speaker(out, 1200, 7500)
    # Vibration motor buzz underneath, coupling into the belt clip.
    n = seconds(1.3)
    buzz_t = np.arange(n) / SR
    buzz = np.sign(np.sin(2 * np.pi * 165 * buzz_t)) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * buzz_t))
    buzz = butter(buzz, "bandpass", [140, 900], order=2) * 0.12
    place(out, fade(buzz, 0.02, 0.05), 0.02)
    stereo = apply_reverb(out, reverb_ir(0.45, rng, pre_delay=0.004), 0.15)
    stereo = fade(normalize_peak(stereo, -9.0), 0.0, 0.1)
    write_ogg(stereo[:seconds(1.8)], "audio/sfx/sfx_pager_alert.ogg")


def piano_note(rng, freq, duration=5.0, velocity=1.0):
    """Additive piano-like tone with stretched (inharmonic) partials and hammer noise."""
    n = seconds(duration)
    t = np.arange(n) / SR
    inharmonicity = 0.0004
    out = np.zeros(n)
    for k in range(1, 16):
        partial = k * freq * np.sqrt(1 + inharmonicity * k * k)
        if partial > SR / 2.2:
            break
        decay = 2.6 / (1 + 0.35 * (k - 1)) / (freq / 440) ** 0.4
        detune = 1 + rng.uniform(-0.0006, 0.0006)  # Unison strings beating.
        out += (np.sin(2 * np.pi * partial * t) + 0.6 * np.sin(2 * np.pi * partial * detune * t)) * np.exp(-t / decay) / k ** 1.25
    hammer = butter(rng.standard_normal(n), "bandpass", [freq, min(freq * 12, 12000)], order=2) * env_exp(n, 0.006) * 0.4
    out = (out + hammer) * velocity
    return fade(out, 0.002, 0.4)


def string_drone(rng, freqs, duration, cutoff=900):
    """Ensemble-ish low strings: several detuned bandlimited saws with bow noise and slow vibrato."""
    n = seconds(duration)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for freq in freqs:
        for voice in range(4):
            detune = 1 + rng.uniform(-0.004, 0.004)
            vibrato = 1 + 0.0025 * np.sin(2 * np.pi * rng.uniform(4.5, 5.5) * t + rng.uniform(0, 6.28)) * np.clip(t / 2, 0, 1)
            phase = 2 * np.pi * np.cumsum(freq * detune * vibrato) / SR
            saw = sum(np.sin(k * phase) / k for k in range(1, int(4000 / freq)))
            out += saw / 4
    bow = butter(rng.standard_normal(n), "bandpass", [300, 2500], order=2) * 0.05
    return butter(out + bow, "lowpass", cutoff, order=2)


def transition_unease():
    """~9 s psychological-horror transition: swelling low-string cluster, two sparse piano notes, return to silence."""
    rng = np.random.default_rng(4404)
    duration = 9.5
    n = seconds(duration)
    t = np.arange(n) / SR
    out = np.zeros(n)

    drone = string_drone(rng, [55.0, 110.0], duration, cutoff=700)
    drone *= np.clip(t / 4.0, 0, 1) ** 2 * np.clip((duration - t) / 3.5, 0, 1)
    out += drone * 0.5
    # Dissonant minor second enters late and quietly, then leaves first.
    rub = string_drone(rng, [116.54], duration, cutoff=900)
    out += rub * np.clip((t - 2.8) / 2.5, 0, 1) * np.clip((7.2 - t) / 1.8, 0, 1) * 0.28
    # Reverse-swell breath into the second piano note.
    swell_n = seconds(2.2)
    swell = butter(pink_noise(swell_n, rng), "bandpass", [400, 3000], order=2) * np.linspace(0, 1, swell_n) ** 3 * 0.25
    place(out, swell, 2.0)
    piano = np.zeros(n)
    place(piano, piano_note(rng, 659.26, 5.5, 0.55), 1.0)   # E5
    place(piano, piano_note(rng, 622.25, 5.0, 0.42), 4.2)   # D#5: a semitone below, unresolved.
    out += piano * 0.6

    stereo = apply_reverb(out, reverb_ir(3.2, rng, pre_delay=0.025, brightness=4500), 0.42)[:n]
    stereo = fade(normalize_peak(stereo, -6.0), 0.05, 1.2)
    write_ogg(stereo, "audio/music/mus_transition_unease_01.ogg")


ASSETS = {
    "corridor": corridor_ambience_loop,
    "door": secure_door_open,
    "pager": pager_alert,
    "transition": transition_unease,
}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("assets", nargs="*", help="assets to build (default: all): " + ", ".join(ASSETS))
    args = parser.parse_args()
    unknown = set(args.assets) - set(ASSETS)
    if unknown:
        parser.error("unknown asset(s): " + ", ".join(sorted(unknown)))
    for name in args.assets or ASSETS:
        ASSETS[name]()


if __name__ == "__main__":
    sys.exit(main())
