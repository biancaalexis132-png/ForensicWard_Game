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
import re
import shutil
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
    """Encode float audio to OGG Vorbis via ffmpeg (libvorbis), or Xiph's oggenc when
    ffmpeg lacks libvorbis (Homebrew's ffmpeg 9 does)."""
    target = ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as directory:
        wav = Path(directory) / "master.wav"
        sf.write(wav, np.clip(data, -1.0, 1.0), SR, subtype="FLOAT")
        encoders = subprocess.run(["ffmpeg", "-hide_banner", "-encoders"], capture_output=True, text=True).stdout
        if re.search(r"\blibvorbis\b", encoders):
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                            "-c:a", "libvorbis", "-q:a", str(quality),
                            "-map_metadata", "-1", "-fflags", "+bitexact", str(target)], check=True)
        elif shutil.which("oggenc"):
            subprocess.run(["oggenc", "-Q", "--discard-comments", "-q", str(quality),
                            "-o", str(target), str(wav)], check=True)
        else:
            sys.exit("No Vorbis encoder: ffmpeg lacks libvorbis. Install it with: brew install vorbis-tools")
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


# --- Environment set (Chapter 1 onward) -------------------------------------------------

def seamless(bed, length, overlap):
    """Equal-power crossfade of the overlap tail into the head; returns exactly `length` seconds."""
    n = seconds(overlap)
    ramp = np.linspace(0, np.pi / 2, n)
    ramp = ramp[:, None] if bed.ndim == 2 else ramp
    looped = bed[:seconds(length)].copy()
    looped[:n] = bed[:n] * np.sin(ramp) + bed[seconds(length):seconds(length) + n] * np.cos(ramp)
    return looped


def stereo_width(mono, rng, spread=0.0008):
    """Cheap decorrelated stereo image from mono via tiny per-channel delays."""
    delays = rng.integers(0, int(spread * SR), size=2)
    return np.stack([np.roll(mono, int(d)) for d in delays], axis=1)


def footsteps():
    """Four takes per surface. AudioDirector picks one at random with slight pitch variation."""
    for surface, seed in (("vinyl", 5101), ("tile", 5201), ("concrete", 5301)):
        rng = np.random.default_rng(seed)
        for take in range(1, 5):
            step = footstep(rng, surface) * rng.uniform(0.85, 1.0)
            if surface == "concrete":  # Old substructure: grit under the sole.
                n = seconds(0.18)
                grit = (rng.random(n) > 0.985) * rng.standard_normal(n) * env_exp(n, 0.06)
                place(step, butter(grit, "highpass", 2500, order=2) * 0.5, 0.05)
            stereo = apply_reverb(step, reverb_ir(0.35, rng, pre_delay=0.005), 0.12)[:seconds(0.6)]
            write_ogg(fade(normalize_peak(stereo, -6.0), 0.0, 0.1), f"audio/sfx/footsteps/sfx_footstep_{surface}_{take:02d}.ogg")


def badge_reader():
    """Standalone badge reader: accept chirp and deny buzz (doors add their own lock sounds)."""
    rng = np.random.default_rng(5401)
    accept = np.concatenate([beep(1760, 0.07), np.zeros(seconds(0.03)), beep(2350, 0.12)])
    accept = apply_reverb(small_speaker(accept), reverb_ir(0.3, rng), 0.1)[:seconds(0.5)]
    write_ogg(fade(normalize_peak(accept, -9.0), 0.0, 0.05), "audio/sfx/sfx_badge_accept.ogg")
    deny = np.concatenate([beep(415, 0.16, square=0.9), np.zeros(seconds(0.06)), beep(415, 0.28, square=0.9)])
    deny = apply_reverb(small_speaker(deny, 300, 4000), reverb_ir(0.3, rng), 0.1)[:seconds(0.8)]
    write_ogg(fade(normalize_peak(deny, -9.0), 0.0, 0.05), "audio/sfx/sfx_badge_deny.ogg")


def computer_interface():
    """EHR terminal: key presses (4 takes), window open chime, clinical alert tone."""
    rng = np.random.default_rng(5501)
    for take in range(1, 5):
        n = seconds(0.09)
        click = butter(rng.standard_normal(n), "bandpass", [1800, 7000], order=2) * env_exp(n, 0.004)
        thock = np.sin(2 * np.pi * rng.uniform(140, 190) * np.arange(n) / SR) * env_exp(n, 0.012) * 0.5
        key = (click + thock) * rng.uniform(0.8, 1.0)
        write_ogg(fade(normalize_peak(stereo_width(key, rng), -12.0), 0.0, 0.01), f"audio/sfx/ui/sfx_ui_keypress_{take:02d}.ogg")
    blips = np.zeros(seconds(0.5))
    place(blips, fade(np.sin(2 * np.pi * 880 * t_axis(0.09)), 0.005, 0.06), 0.0, 0.6)
    place(blips, fade(np.sin(2 * np.pi * 1318.5 * t_axis(0.16)), 0.005, 0.12), 0.08, 0.5)
    write_ogg(normalize_peak(stereo_width(blips, rng), -12.0), "audio/sfx/ui/sfx_ui_terminal_open.ogg")
    alert = np.zeros(seconds(1.3))
    for index, freq in enumerate((987.8, 784.0, 987.8)):  # B5 G5 B5: noticeable, not alarming.
        tone = np.sin(2 * np.pi * freq * t_axis(0.22)) + 0.2 * np.sin(2 * np.pi * freq * 2 * t_axis(0.22))
        place(alert, fade(tone, 0.015, 0.12), index * 0.26, 0.5)
    alert = apply_reverb(alert, reverb_ir(0.4, rng), 0.12)[:seconds(1.3)]
    write_ogg(fade(normalize_peak(alert, -9.0), 0.0, 0.2), "audio/sfx/ui/sfx_ui_clinical_alert.ogg")


def elevator_arrive():
    """Arrival chime, motor wind-down, doors sliding open."""
    rng = np.random.default_rng(5601)
    out = np.zeros(seconds(4.5))
    n = seconds(1.6)
    motor_t = np.arange(n) / SR
    motor_freq = 95 * (1 - 0.35 * motor_t / 1.6)
    motor = np.sin(2 * np.pi * np.cumsum(motor_freq) / SR) + 0.3 * butter(rng.standard_normal(n), "lowpass", 400)
    place(out, motor * np.linspace(1, 0, n) ** 1.5 * 0.25, 0.0)
    place(out, thump(rng, freq=60, decay=0.12, click=0.2), 1.45, 0.35)  # Car settles.
    chime = metal_ring(rng, partials=(1174.7, 2349.3, 3524.0), decay=0.6)
    place(out, chime * 0.45, 1.7)
    door_n = seconds(1.6)
    rumble = butter(pink_noise(door_n, rng), "bandpass", [80, 900], order=2) * np.sin(np.linspace(0, np.pi, door_n)) * 0.35
    rollers = (rng.random(door_n) > 0.9996) * rng.standard_normal(door_n) * 0.15
    place(out, rumble + butter(rollers, "bandpass", [1500, 5000], order=2), 2.3)
    place(out, thump(rng, freq=80, decay=0.05, click=0.4), 3.85, 0.3)  # Doors stop.
    stereo = apply_reverb(out, reverb_ir(0.9, rng, pre_delay=0.01), 0.2)[:seconds(4.5)]
    write_ogg(fade(normalize_peak(stereo, -4.0), 0.0, 0.3), "audio/sfx/sfx_elevator_arrive.ogg")


def distant_staff_walla():
    """45 s loop of overlapping staff chatter, far down a corridor: texture only, unintelligible."""
    rng = np.random.default_rng(5701)
    clips = sorted((ROOT / "audio/voice/walla").glob("walla_ns_*.ogg"))
    if not clips:
        raise SystemExit("audio/voice/walla is empty: run tools/audio/generate_voice.py first")
    length, overlap = 45.0, 4.0
    total = seconds(length + overlap)
    voices = np.zeros((total, 2))
    when = 0.6
    order = list(rng.permutation(len(clips))) * 3
    while when < length + overlap - 4.0:
        data, rate = sf.read(clips[order.pop(0)])
        data = signal.resample_poly(data, SR, rate) if rate != SR else data
        pan = rng.uniform(0.25, 0.75)
        clip = np.stack([data * np.cos(pan * np.pi / 2), data * np.sin(pan * np.pi / 2)], axis=1)
        place(voices, clip, when, rng.uniform(0.5, 1.0))
        when += len(data) / SR * rng.uniform(0.45, 1.1)  # Overlapping speakers.
    voices = butter(voices, "lowpass", 1100, order=4)  # Through walls and distance.
    voices = butter(voices, "highpass", 180, order=2)
    wet = np.stack([apply_reverb(voices[:, c], reverb_ir(1.4, rng, pre_delay=0.03, brightness=1800), 0.7)[:total, c]
                    for c in range(2)], axis=1)
    write_ogg(seamless(normalize_rms(wet, -34.0, ceiling_db=-14.0), length, overlap), "audio/ambience/amb_distant_staff_loop.ogg", quality=5)


def nursing_station_loop():
    """60 s loop: monitor beeps, keyboard bursts and distant chatter. Layer over the corridor bed."""
    rng = np.random.default_rng(5801)
    length, overlap = 60.0, 4.0
    total = seconds(length + overlap)
    out = np.zeros(total)
    for start in rng.uniform(1.0, length, size=14):  # Typing bursts.
        for k in range(rng.integers(4, 12)):
            n = seconds(0.06)
            click = butter(rng.standard_normal(n), "bandpass", [1800, 6000], order=2) * env_exp(n, 0.004)
            place(out, click, start + k * rng.uniform(0.09, 0.2), rng.uniform(0.04, 0.08))
    for start in np.arange(3.0, length, 9.7):  # Patient monitor at the station, far and soft.
        place(out, fade(np.sin(2 * np.pi * 1046.5 * t_axis(0.12)), 0.01, 0.06), start, 0.03)
    n = seconds(3.2)  # One printer pass.
    printer = butter(rng.standard_normal(n), "bandpass", [300, 2500], order=2) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 14 * np.arange(n) / SR)))
    place(out, fade(printer, 0.2, 0.4) * 0.05, 33.0)
    stereo = apply_reverb(out, reverb_ir(0.6, rng, pre_delay=0.01, brightness=4000), 0.35)[:total]
    walla, rate = sf.read(ROOT / "audio/ambience/amb_distant_staff_loop.ogg")
    reps = int(np.ceil(total / len(walla)))
    stereo += np.tile(walla, (reps, 1))[:total] * 1.6
    write_ogg(seamless(normalize_rms(stereo, -36.0, ceiling_db=-12.0), length, overlap), "audio/ambience/amb_nursing_station_loop.ogg", quality=5)


def historic_intercom_static():
    """30 s loop: an old PA channel left open, mains hum, hiss, crackle and dropouts."""
    rng = np.random.default_rng(5901)
    length, overlap = 30.0, 3.0
    total = seconds(length + overlap)
    t = np.arange(total) / SR
    hum = sum(np.sin(2 * np.pi * 60 * h * t) / h for h in range(1, 9))
    hiss = butter(rng.standard_normal(total), "bandpass", [800, 6000], order=2) * 0.35
    crackle = (rng.random(total) > 0.9992) * rng.standard_normal(total) * 2.5
    signal_line = small_speaker(hum * 0.25 + hiss + butter(crackle, "highpass", 700, order=2), 300, 4500)
    dropout = 1 - 0.85 * (np.convolve(rng.random(total) > 0.99995, np.ones(seconds(0.25)), "same") > 0)
    stereo = apply_reverb(signal_line * dropout, reverb_ir(1.5, rng, pre_delay=0.03, brightness=3000), 0.35)[:total]
    write_ogg(seamless(normalize_rms(stereo, -32.0, ceiling_db=-8.0), length, overlap), "audio/ambience/amb_historic_intercom_static_loop.ogg", quality=5)


def electrical():
    """Fluorescent flicker (stuttering ballast and relay ticks) and a startling surge with an arc."""
    rng = np.random.default_rng(6001)
    n = seconds(2.6)
    t = np.arange(n) / SR
    buzz = sum(np.sign(np.sin(2 * np.pi * 120 * h * t)) / h ** 2 for h in (1, 2, 3))
    gate = np.zeros(n)
    when = 0.0
    while when < 2.2:  # Irregular on/off stutter.
        on = rng.uniform(0.03, 0.25)
        gate[seconds(when):seconds(when + on)] = 1.0
        when += on + rng.uniform(0.03, 0.2)
    gate = np.convolve(gate, np.ones(96) / 96, "same")
    flicker = butter(buzz * gate, "bandpass", [100, 5000], order=2) * 0.4
    for edge in np.flatnonzero(np.diff((gate > 0.5).astype(int)) == 1)[:8]:
        place(flicker, butter(thump(rng, freq=200, decay=0.01, click=1.0), "highpass", 1500) * 0.3, edge / SR)
    stereo = apply_reverb(flicker, reverb_ir(0.8, rng), 0.2)[:n]
    write_ogg(fade(normalize_peak(stereo, -8.0), 0.01, 0.2), "audio/sfx/sfx_electrical_flicker.ogg")

    n = seconds(3.2)
    t = np.arange(n) / SR
    rise = np.clip(t / 1.3, 0, 1) ** 2 * (t < 1.35)
    hum = np.sin(2 * np.pi * np.cumsum(60 + 120 * np.clip(t / 1.3, 0, 1)) / SR) * rise
    arc_n = seconds(0.45)
    arc = rng.standard_normal(arc_n) * (rng.random(arc_n) > 0.6) * env_exp(arc_n, 0.15)
    surge = hum * 0.5
    place(surge, butter(arc, "bandpass", [1000, 9000], order=2) * 1.5, 1.3)
    place(surge, thump(rng, freq=50, decay=0.3, click=1.0), 1.32, 0.9)  # Breaker pop.
    stereo = apply_reverb(surge, reverb_ir(1.4, rng, pre_delay=0.02), 0.3)[:n]
    write_ogg(fade(normalize_peak(stereo, -3.0), 0.02, 0.6), "audio/sfx/sfx_electrical_surge.ogg")


def ward_zero():
    """Ward Zero: ambience bed (old masonry, drips, pipe ticks, beating hum) and two event-only anomalies."""
    rng = np.random.default_rng(6101)
    length, overlap = 60.0, 4.0
    total = seconds(length + overlap)
    t = np.arange(total) / SR
    channels = []
    for channel in range(2):
        room = butter(pink_noise(total, rng), "lowpass", 300, order=2)
        wind = butter(rng.standard_normal(total), "bandpass", [400, 1600], order=2) * (0.3 + 0.3 * np.sin(2 * np.pi * 0.05 * t + channel * 1.7)) * 0.15
        channels.append(room + wind)
    bed = np.stack(channels, axis=1)
    beating = (np.sin(2 * np.pi * 50.0 * t) + np.sin(2 * np.pi * 50.4 * t) + 0.4 * np.sin(2 * np.pi * 100.8 * t)) * 0.012
    bed += beating[:, None]
    events = np.zeros(total)
    for when in rng.uniform(1.0, length - 1.0, size=11):  # Water drips.
        n = seconds(0.12)
        freq = rng.uniform(900, 1700)
        drip = np.sin(2 * np.pi * np.cumsum(freq * (1 + 0.8 * np.exp(-np.arange(n) / SR / 0.01))) / SR) * env_exp(n, 0.02)
        place(events, drip, when, rng.uniform(0.05, 0.12))
    for when in rng.uniform(2.0, length - 2.0, size=5):  # Pipes ticking as they cool.
        place(events, metal_ring(rng, partials=(2200, 3400, 5100), decay=0.05) * 0.06, when)
    bed += apply_reverb(events, reverb_ir(2.6, rng, pre_delay=0.04, brightness=3500), 0.6)[:total]
    write_ogg(seamless(normalize_rms(bed, -32.0, ceiling_db=-8.0), length, overlap), "audio/ambience/amb_ward_zero_loop.ogg", quality=5)

    knocks = np.zeros(seconds(5.5))
    for index, when in enumerate((0.3, 0.95, 1.6)):  # Three slow knocks on a heavy door, far away.
        knock = butter(thump(rng, freq=rng.uniform(70, 85), decay=0.09, click=0.6), "lowpass", 1400)
        place(knocks, knock, when, (0.9, 1.0, 0.8)[index])
    stereo = apply_reverb(knocks, reverb_ir(3.4, rng, pre_delay=0.05, brightness=2000), 0.55)[:seconds(5.5)]
    write_ogg(fade(normalize_peak(stereo, -6.0), 0.0, 1.0), "audio/sfx/anomaly/sfx_w0_distant_knocks.ogg")

    n = seconds(12.0)
    t = np.arange(n) / SR
    swell = np.sin(np.pi * np.clip(t / 12.0, 0, 1)) ** 2
    pressure = (np.sin(2 * np.pi * 38 * t) + np.sin(2 * np.pi * 38.6 * t) + 0.5 * np.sin(2 * np.pi * 57.2 * t)) * swell
    air = butter(pink_noise(n, rng), "bandpass", [200, 1200], order=2) * swell * 0.3
    stereo = apply_reverb(pressure * 0.6 + air, reverb_ir(3.0, rng, pre_delay=0.05, brightness=1500), 0.4)[:n]
    write_ogg(fade(normalize_peak(stereo, -6.0), 0.5, 1.5), "audio/sfx/anomaly/sfx_w0_pressure_swell.ogg")


ASSETS = {
    "corridor": corridor_ambience_loop,
    "door": secure_door_open,
    "pager": pager_alert,
    "transition": transition_unease,
    "footsteps": footsteps,
    "badge": badge_reader,
    "ui": computer_interface,
    "elevator": elevator_arrive,
    "walla": distant_staff_walla,
    "nursing_station": nursing_station_loop,  # Needs walla first.
    "intercom_static": historic_intercom_static,
    "electrical": electrical,
    "ward_zero": ward_zero,
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
