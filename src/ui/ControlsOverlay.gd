## Controller for the controls overlay screen
## Shows/hides controls information and handles close interactions
class_name ControlsOverlay

extends CanvasLayer

#region References
@onready var background_control: Control = $Control
@onready var panel: PanelContainer = $Control/PanelContainer

#endregion

#region Variables
var _is_visible_target: bool = false

#endregion

#region Initialization
func _ready() -> void:
	# Start hidden
	visible = false

	# Connect background click detection
	if background_control:
		background_control.gui_input.connect(_on_background_gui_input)

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
## Handle keyboard input to show/hide controls
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

## Handle mouse input on background (click outside panel to close)
func _on_background_gui_input(event: InputEvent) -> void:
	if not visible:
		return

	# Only handle mouse clicks
	if event is InputEventMouseButton and event.pressed:
		# Check if click is outside the panel
		if not panel.get_global_rect().has_point(background_control.get_global_mouse_position()):
			_hide_controls()
			get_tree().root.set_input_as_handled()

#endregion
