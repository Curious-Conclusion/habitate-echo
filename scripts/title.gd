extends Control
## Title screen — the game's entry point. New Game starts Op 0 (KE-7 onboarding);
## Continue loads the last save and drops you at the safehouse. Continue is
## disabled when no save exists.

@onready var new_game_btn: Button = $Center/VBox/NewGameButton
@onready var continue_btn: Button = $Center/VBox/ContinueButton
@onready var quit_btn: Button = $Center/VBox/QuitButton

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)
	new_game_btn.grab_focus()

func _on_new_game() -> void:
	GameState.reset_new_game()
	MorphManager.current_morph_id = &"octomorph"  # fresh start morph
	SceneFlow.deploy_op(&"ke7")  # Op 0 — onboarding

func _on_continue() -> void:
	if GameState.load_game():
		SceneFlow.go_to_hub()  # resume at the safehouse

func _on_quit() -> void:
	get_tree().quit()
