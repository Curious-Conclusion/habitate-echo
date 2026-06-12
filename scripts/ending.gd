extends Control
## The campaign epilogue. Reads the composed ending (EndingComposer) and plays
## it as a sequence of fading cards — [E] advances. Closes on the record card,
## then returns to the title screen. If you carried trauma home, its voice gets
## the literal last word, faint, under the title.

const FADE := 0.6

@onready var card: Label = $Card
@onready var hint: Label = $Hint
@onready var last_word: Label = $LastWord

var _cards: Array[String] = []
var _index := -1
var _done := false
var _fading := false
var _ending_id: StringName

func _ready() -> void:
	var ending := EndingComposer.compose()
	_ending_id = ending["id"]
	GameState.set_flag(&"epilogue_seen")
	GameState.save()
	_cards.append("// FINAL REPORT — %s" % ending["title"])
	_cards.append_array(ending["paragraphs"])
	_cards.append("SENTINEL RECORD — CLOSED\n\nHABITAT ECHO")
	card.modulate.a = 0.0
	last_word.modulate.a = 0.0
	hint.text = "[E]"
	_advance()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not _fading:
		get_viewport().set_input_as_handled()
		if _done:
			get_tree().change_scene_to_file("res://scenes/title.tscn")
		else:
			_advance()

func _advance() -> void:
	_index += 1
	if _index >= _cards.size():
		_done = true  # unreachable today; keeps the terminal state safe
		return
	_fading = true
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: card.text = _cards[_index])
	tw.tween_property(card, "modulate:a", 1.0, FADE)
	tw.tween_callback(func() -> void: _fading = false)
	if _index == _cards.size() - 1:
		_done = true
		hint.text = "[E] Return"
		var word := _last_word_text()
		if word != "":
			last_word.text = word
			var tw2 := create_tween()
			tw2.tween_interval(1.8)
			tw2.tween_property(last_word, "modulate:a", 0.45, 2.0)

## Whatever you carried home gets the last word: the newest scar with a voice —
## or, if a CARRIER comes home apparently clean, the script does.
func _last_word_text() -> String:
	for i in range(GameState.traumas.size() - 1, -1, -1):
		var lines: Array = Whispers.TRAUMA_LINES.get(GameState.traumas[i], [])
		if not lines.is_empty():
			return lines[0]
	if _ending_id == &"carrier":
		return "Trust me."
	return ""
