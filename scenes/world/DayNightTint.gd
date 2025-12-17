extends CanvasModulate
## Provides visual feedback for day/night cycle by tinting the screen

const DAY_COLOR: Color = Color(1.0, 1.0, 0.9, 1.0)  # Slight warm tint
const NIGHT_COLOR: Color = Color(0.6, 0.7, 1.0, 1.0)  # Cool blue tint
const TRANSITION_DURATION: float = 2.0  # Seconds to fade between colors

var target_color: Color = DAY_COLOR
var tween: Tween


func _ready() -> void:
	# Start with day color
	color = DAY_COLOR

	# Connect to TimeManager
	TimeManager.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(new_phase: TimeManager.Phase) -> void:
	match new_phase:
		TimeManager.Phase.DAY:
			_fade_to_color(DAY_COLOR)
		TimeManager.Phase.NIGHT:
			_fade_to_color(NIGHT_COLOR)


func _fade_to_color(new_color: Color) -> void:
	"""Smoothly transition to new color"""
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "color", new_color, TRANSITION_DURATION)
