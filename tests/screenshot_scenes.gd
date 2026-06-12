extends SceneTree
## Visual verification harness — loads each scene windowed, lets it render,
## and saves the viewport to tests/shots/<name>.png:
##   godot --path . -s res://tests/screenshot_scenes.gd
## (NOT --headless; a window opens briefly.) Generated PNGs are untracked.

const SHOTS := [
	["title", "res://scenes/title.tscn"],
	["hub", "res://scenes/hub.tscn"],
	["op_ke7", "res://scenes/main.tscn"],
	["op_hauler", "res://scenes/op_hauler.tscn"],
	["op_lab", "res://scenes/op_lab.tscn"],
	["op_halcyon", "res://scenes/op_halcyon.tscn"],
	["ending", "res://scenes/ending.tscn"],
]

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://tests/shots")
	for entry: Array in SHOTS:
		root.get_node("GameState").reset_new_game()
		change_scene_to_file(entry[1])
		for i in 60:  # let _ready, sprites, and fades settle (~1s at 60fps)
			await process_frame
		paused = false  # a scene may have opened a pausing dialogue; keep going
		var img := root.get_texture().get_image()
		img.save_png("res://tests/shots/%s.png" % entry[0])
		print("SHOT  " + entry[0])
	print("RESULT: shots done")
	quit(0)
