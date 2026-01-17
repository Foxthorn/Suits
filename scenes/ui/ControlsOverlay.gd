## Controller for the controls overlay screen
## Shows/hides controls information and handles close interactions
class_name ControlsOverlay

extends CanvasLayer

#region Variables
var _is_visible_target: bool = false

#endregion

#region Initialization
func _ready() -> void:
	# Start hidden
	visible = false

	# Connect to input events
	print("ControlsOverlay: Initialized")

#endregion

#region Display Control
## Show the controls overlay with fade-in animation
func _show_controls() -> void:
	visible = true
	_is_visible_target = true

	# Fade in animation
	var bg_control = find_child("Control", true, false)
	if bg_control:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		bg_control.modulate.a = 0.0
		tween.tween_property(bg_control, "modulate:a", 1.0, 0.2)

	print("ControlsOverlay: Showing controls")

## Hide the controls overlay
func _hide_controls() -> void:
	visible = false
	_is_visible_target = false
	print("ControlsOverlay: Hiding controls")

#endregion

#region Input Handling
## Handle input to show/hide controls
func _input(event: InputEvent) -> void:
	if not visible:
		# Only handle C key when hidden, let other inputs pass through
		if event.is_action_pressed("controls_show"):
			_show_controls()
			get_tree().root.set_input_as_handled()
		return

	# When visible, only handle close actions
	# Close on C key or ESC
	if event.is_action_pressed("controls_show") or event.is_action_pressed("ui_cancel"):
		_hide_controls()
		get_tree().root.set_input_as_handled()
		return

	# Don't consume mouse clicks - let them pass to UI buttons
	# Click outside the panel will close it naturally as user closes and clicks button

#endregion
