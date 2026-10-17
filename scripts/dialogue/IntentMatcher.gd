class_name IntentMatcher
extends RefCounted
## Deterministic, bounded free-text intent matching (no AI, works offline).
##
## Typed text is lower-cased and split into words. Stopwords are dropped and
## each word is reduced to a canonical token through the authored synonym
## lexicon. The token set is scored against each dialogue choice's intents
## (intent ids split on "_", plus the choice label):
##     score = |shared tokens| / |intent tokens|, best intent per choice
## Outcomes:
##     matched:  one choice clearly best (score >= MATCH_THRESHOLD)
##     clarify:  two or more choices tie for best -> ask which was meant
##     fallback: nothing reaches the threshold -> polite authored fallback
## Ties break by choice id, so results never depend on dictionary order.

const MATCH_THRESHOLD: float = 0.5

var _stopwords: Dictionary = {}
var _canonical: Dictionary = {} ## word -> canonical token


func _init(lexicon: Dictionary) -> void:
	for word: String in lexicon.get("stopwords", []):
		_stopwords[word.to_lower()] = true
	var synonyms: Dictionary = lexicon.get("synonyms", {})
	for canonical: String in synonyms:
		_canonical[canonical.to_lower()] = canonical.to_lower()
		for word: String in synonyms[canonical]:
			_canonical[word.to_lower()] = canonical.to_lower()


## Canonical token set for a piece of text.
func tokenize(text: String) -> Dictionary:
	var tokens: Dictionary = {}
	var cleaned: String = ""
	for character: String in text.to_lower():
		cleaned += character if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") else " "
	for word: String in cleaned.split(" ", false):
		if _stopwords.has(word):
			continue
		tokens[_canonical.get(word, _stem(word))] = true
	return tokens


## Matches text against choices [{id, label, intents}].
## Returns {status: "matched"|"clarify"|"fallback", choice_id, candidates, score}.
func match_text(text: String, choices: Array) -> Dictionary:
	var query: Dictionary = tokenize(text)
	var scored: Array[Dictionary] = []
	if not query.is_empty():
		for choice: Dictionary in choices:
			var best: float = 0.0
			var phrases: Array = choice.get("intents", []).duplicate()
			phrases.append(choice.get("label", ""))
			for phrase: String in phrases:
				best = maxf(best, _score(query, tokenize(phrase.replace("_", " "))))
			if best >= MATCH_THRESHOLD:
				scored.append({"id": choice["id"], "score": best})

	if scored.is_empty():
		return {"status": "fallback", "choice_id": "", "candidates": [], "score": 0.0}
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["score"] > b["score"] or (is_equal_approx(a["score"], b["score"]) and a["id"] < b["id"]))
	var top_score: float = scored[0]["score"]
	var tied: Array[String] = []
	for entry: Dictionary in scored:
		if is_equal_approx(entry["score"], top_score):
			tied.append(entry["id"])
	if tied.size() > 1:
		return {"status": "clarify", "choice_id": "", "candidates": tied, "score": top_score}
	return {"status": "matched", "choice_id": scored[0]["id"], "candidates": [scored[0]["id"]], "score": top_score}


func _score(query: Dictionary, intent: Dictionary) -> float:
	if intent.is_empty():
		return 0.0
	var shared: int = 0
	for token: String in intent:
		if query.has(token):
			shared += 1
	return float(shared) / float(intent.size())


## Light suffix stripping for words missing from the lexicon.
func _stem(word: String) -> String:
	for suffix: String in ["ing", "ed", "es", "s"]:
		if word.length() > suffix.length() + 2 and word.ends_with(suffix):
			return word.substr(0, word.length() - suffix.length())
	return word
