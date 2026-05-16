extends CanvasLayer
## Attach to TransitionLayer. Controls fade overlay + flavor text.

@onready var overlay: ColorRect = $FadeOverlay
@onready var flavor: Label = $FlavorLabel
@onready var sfx: AudioStreamPlayer = $SfxPlayer

const FADE_DURATION := 0.4
const TEXT_HOLD := 1.2
const RESLEEVE_TEXTS: Array[String] = [
	"Your new fingers feel like someone else's.",
	"For a moment, you forget your own name.",
	"Phantom limbs twitch — ghosts of your last sleeve.",
	"The mind fits. The body doesn't. Not yet.",
	"Your memories feel... copied.",
	"Something in the brainstem screams wrong shape.",
]

var running := false

func _ready() -> void:
	overlay.modulate.a = 0.0
	flavor.modulate.a = 0.0
	_build_sfx()

func play_resleeve(morph_id: StringName) -> void:
	if running:
		return
	running = true
	var data := MorphManager.get_morph(morph_id)

	# Fade to black
	overlay.modulate.a = 0.0
	var tw1 := overlay.create_tween()
	tw1.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw1.tween_property(overlay, "modulate:a", 1.0, FADE_DURATION)
	await tw1.finished

	# Switch morph
	MorphManager.switch_morph(morph_id)
	sfx.play()

	# Flavor text
	flavor.text = "You resleeve into a %s...\n%s" % [data.display_name, RESLEEVE_TEXTS[randi() % RESLEEVE_TEXTS.size()]]
	flavor.modulate.a = 1.0
	await get_tree().create_timer(TEXT_HOLD, true, false, true).timeout

	# Fade out
	flavor.modulate.a = 0.0
	var tw2 := overlay.create_tween()
	tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(overlay, "modulate:a", 0.0, FADE_DURATION)
	await tw2.finished

	running = false
	get_tree().paused = false

func _build_sfx() -> void:
	var rate := 22050
	var dur := 0.5
	var n := int(rate * dur)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var freq := lerpf(220.0, 880.0, t / dur)
		var env := 1.0 - t / dur
		var s := sin(TAU * freq * t) * env * 0.4
		var v := clampi(int(s * 32767.0), -32768, 32767)
		buf[i * 2] = v & 0xFF
		buf[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = buf
	sfx.stream = stream
