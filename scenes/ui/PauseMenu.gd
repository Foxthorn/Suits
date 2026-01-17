## PauseMenu.gd
## Controller for the pause menu UI
## Listens to GameStateManager and shows/hides based on state

extends Control

#region Exports
@export var pause_label: Label = null
@export var resume_button: Button = null
@export var restart_button: Button = null
@export var quit_button: Button = null
@export var background: ColorRect = null

#endregion

#region Variables
var _is_visible_target: bool = false

#endregion

#region Initialization
func _ready() -> void:
	# Auto-find children if not assigned
	if not pause_label:
		pause_label = find_child("PauseLabel", true, false)
	if not resume_button:
		resume_button = find_child("ResumeButton", true, false)
	if not restart_button:
		restart_button = find_child("RestartButton", true, false)
	if not quit_button:
		quit_button = find_child("QuitButton", true, false)
	if not background:
		background = find_child("Background", true, false)

	# Connect button signals
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Start hidden
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # Don't intercept input when hidden

	# Connect to GameStateManager
	if GameStateManager:
		GameStateManager.state_changed.connect(_on_game_state_changed)
	else:
		push_error("PauseMenu: GameStateManager autoload not found!")

	print("PauseMenu: Initialized")

#endregion

#region Signal Handlers
func _on_game_state_changed(new_state: GameStateManager.State) -> void:
	"""Called when game state changes"""
	match new_state:
		GameStateManager.State.PAUSED:
			_show_pause_menu()
		GameStateManager.State.PLAYING:
			_hide_pause_menu()
		_:
			# For DEFEAT, VICTORY, etc., hide pause menu
			_hide_pause_menu()

func _on_resume_pressed() -> void:
	"""Resume game button clicked"""
	GameStateManager.resume_game()

func _on_restart_pressed() -> void:
	"""Restart game button clicked"""
	GameStateManager.restart_game()

func _on_quit_pressed() -> void:
	"""Quit to desktop button clicked"""
	GameStateManager.quit_game()

#endregion

#region Display Control
func _show_pause_menu() -> void:
	"""Show the pause menu with fade-in animation"""
	visible = true
	mouse_filter = MOUSE_FILTER_STOP  # Capture input when visible

	# Focus resume button for keyboard navigation
	if resume_button:
		resume_button.grab_focus()

	# Optional: Fade in animation
	if background:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		background.modulate.a = 0.0
		tween.tween_property(background, "modulate:a", 0.7, 0.2)

	print("PauseMenu: Showing pause menu")

func _hide_pause_menu() -> void:
	"""Hide the pause menu"""
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # Don't intercept input when hidden

	# Optional: Kill any ongoing animations
	#if is_instance_valid(self):
		#var tweens = get_all_tweens()
		#for tween in tweens:
			#tween.kill()

	print("PauseMenu: Hiding pause menu")

#endregion

#region Input Handling
func _input(event: InputEvent) -> void:
	"""Capture ESC key to resume game when pause menu is visible"""
	if not visible:
		return

	# ESC key to resume (already handled by GameStateManager, but provide visual feedback)
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_tree().root.set_input_as_handled()

#endregion
