class_name DialogueVisemeTrack
extends RefCounted
## Deterministic text/grapheme approximation, NOT phoneme timing or true lip sync.
## Slots span the existing subtitle/voice duration; punctuation makes quiet gaps.

const PREFIX: String = "viseme_"
const SILENCE: StringName = &"viseme_sil_00"
const PAIRS: Dictionary = {
	"th": "th_dh_17", "sh": "sh_ch_jh_zh_16", "ch": "sh_ch_jh_zh_16",
	"ph": "f_v_18", "ng": "k_g_ng_20", "oo": "w_uw_07", "ee": "y_iy_ih_ix_06",
	"ow": "ow_08", "oy": "oy_10", "ay": "ay_11", "ai": "ay_11", "ou": "aw_09",
}
const LETTERS: Dictionary = {
	"a": "aa_02", "e": "ey_eh_uh_04", "i": "y_iy_ih_ix_06", "o": "ao_03",
	"u": "aa_ah_ax_01", "b": "p_b_m_21", "p": "p_b_m_21", "m": "p_b_m_21",
	"f": "f_v_18", "v": "f_v_18", "d": "d_t_n_19", "t": "d_t_n_19",
	"n": "d_t_n_19", "k": "k_g_ng_20", "g": "k_g_ng_20", "c": "k_g_ng_20",
	"q": "k_g_ng_20", "x": "s_z_15", "s": "s_z_15", "z": "s_z_15",
	"j": "sh_ch_jh_zh_16", "h": "h_12", "r": "r_13", "l": "l_14",
	"w": "w_uw_07", "y": "y_iy_ih_ix_06",
}


static func build(text: String, seconds: float) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	if not is_finite(seconds) or seconds <= 0.0 or text.strip_edges().is_empty():
		return slots
	var lower: String = text.to_lower()
	var index: int = 0
	var total: float = 0.0
	while index < lower.length():
		var pair: String = lower.substr(index, 2)
		var letter: String = lower.substr(index, 1)
		var shape: StringName = SILENCE
		if PAIRS.has(pair):
			shape = StringName(PREFIX + str(PAIRS[pair]))
			index += 2
		else:
			if LETTERS.has(letter):
				shape = StringName(PREFIX + str(LETTERS[letter]))
			index += 1
		var weight: float = 1.0
		if shape == SILENCE:
			weight = 1.5 if letter in ".,;:!?" else 0.5
		slots.append({"shape": shape, "start": total, "end": total + weight})
		total += weight
	for slot: Dictionary in slots:
		slot["start"] = float(slot["start"]) * seconds / total
		slot["end"] = float(slot["end"]) * seconds / total
	return slots


static func sample(slots: Array[Dictionary], seconds: float) -> Dictionary:
	for slot: Dictionary in slots:
		var start: float = float(slot["start"])
		var end: float = float(slot["end"])
		if seconds >= start and seconds < end:
			var phase: float = (seconds - start) / maxf(end - start, 0.0001)
			return {"shape": slot["shape"], "weight": sin(phase * PI) * 0.6}
	return {"shape": SILENCE, "weight": 0.0}
