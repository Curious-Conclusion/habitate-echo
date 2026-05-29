extends Node2D
## Builds the station's interior walls (with doorway gaps) procedurally so the
## four zones + Crew Quarters become connected rooms. Each segment is a solid
## StaticBody2D with a dark visual. Edit SEGMENTS to move walls/doors.
##
## Doorways (gaps) in the layout:
##   vertical wall x=320  -> doors at y 86-134 (Lounge<->ServerAlcove)
##                                   y 336-384 (MedBay<->AirlockCorridor)
##   horizontal wall y=240 -> doors at x 126-174 (Lounge<->MedBay)
##                                    x 456-504 (ServerAlcove<->AirlockCorridor)
##   right wall x=642      -> door  at y 338-386 (AirlockCorridor <-> Crew Quarters)

const WALL_COLOR := Color(0.10, 0.10, 0.14)

# Each segment is (x, y, width, height) in the top-left convention.
const SEGMENTS: Array[Vector4] = [
	# vertical divider at x=316..324
	Vector4(316, 0, 8, 86), Vector4(316, 134, 8, 202), Vector4(316, 384, 8, 96),
	# horizontal divider at y=236..244
	Vector4(0, 236, 126, 8), Vector4(174, 236, 282, 8), Vector4(504, 236, 136, 8),
	# Crew Quarters wall at x=638..646 (door in the Airlock Corridor's east wall)
	Vector4(638, 0, 8, 338), Vector4(638, 386, 8, 94),
]

func _ready() -> void:
	for s: Vector4 in SEGMENTS:
		_make_wall(s.x, s.y, s.z, s.w)

func _make_wall(x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + w * 0.5, y + h * 0.5)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	body.add_child(col)
	var rect := ColorRect.new()
	rect.color = WALL_COLOR
	rect.size = Vector2(w, h)
	rect.position = Vector2(-w * 0.5, -h * 0.5)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(rect)
	add_child(body)
