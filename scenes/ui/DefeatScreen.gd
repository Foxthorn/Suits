## DefeatScreen.gd
## Controller for the defeat/game-over screen
## Listens to GameStateManager and shows when defeat is triggered

extends Control

#region Exports
@export var title_label: Label = null
@export var reason_label: Label = null
@export var stats_label: Label = null
@export var restart_button: Button = null
@export var quit_button: Button = null
@export var background: ColorRect = null

#endregion

#region Variables
var _defeat_reason: String = ""
var _show_delay: float = 1.0  # Wait before showing buttons
var _show_timer: float = 0.0

#endregion

#region Initialization
func _ready() -> void:
	# Auto-find children if not assigned
	if not title_label:
		title_label = find_child("TitleLabel", true, false)
	if not reason_label:
		reason_label = find_child("ReasonLabel", true, false)
	if not stats_label:
		stats_label = find_child("StatsLabel", true, false)
	if not restart_button:
		restart_button = find_child("RestartButton", true, false)
	if not quit_button:
		quit_button = find_child("QuitButton", true, false)
	if not background:
		background = find_child("Background", true, false)

	# Connect button signals
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Start hidden
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # Don't intercept input when hidden

	# Connect to GameStateManager
	if GameStateManager:
		GameStateManager.defeat_triggered.connect(_on_defeat_triggered)
	else:
		push_error("DefeatScreen: GameStateManager autoload not found!")

	print("DefeatScreen: Initialized")

#endregion

#region Signal Handlers
func _on_defeat_triggered(reason: String) -> void:
	"""Called when GameStateManager triggers defeat"""
	_defeat_reason = reason
	_show_timer = 0.0  # Reset timer for button delay
	_show_defeat_screen()

func _on_restart_pressed() -> void:
	"""Restart game button clicked"""
	GameStateManager.restart_game()

func _on_quit_pressed() -> void:
	"""Quit to desktop button clicked"""
	GameStateManager.quit_game()

#endregion

#region Display Control
func _show_defeat_screen() -> void:
	"""Show the defeat screen with animations"""
	# Pause the game silently (no pause menu shown)
	GameStateManager.pause_game(false)

	visible = true
	mouse_filter = MOUSE_FILTER_STOP  # Capture input when visible

	# Set defeat reason
	if reason_label:
		reason_label.text = _defeat_reason

	# Set stats (optional - could pull from GameStateManager if desired)
	if stats_label:
		var night_num = GameStateManager.get_current_night()
		var stats_text = "Night: %d / 3\n" % night_num
		stats_text += "Enemies Defeated: %d\n" % (WaveManager.get_enemies_defeated_count() if WaveManager else 0)
		stats_text += "Credits Earned: %d" % (EconomyManager.get_total_credits_earned() if EconomyManager else 0)
		stats_label.text = stats_text

	# Disable buttons initially (will enable after delay)
	if restart_button:
		restart_button.disabled = true
	if quit_button:
		quit_button.disabled = true

	# Fade in background
	if background:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		background.modulate.a = 0.0
		tween.tween_property(background, "modulate:a", 0.7, 0.3)

	print("DefeatScreen: Showing defeat screen - Reason: %s" % _defeat_reason)

func _hide_defeat_screen() -> void:
	"""Hide the defeat screen"""
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # Don't intercept input when hidden

	# Kill any ongoing animations
	#if is_instance_valid(self):
		#var tweens = get_all_tweens()
		#for tween in tweens:
			#tween.kill()

	print("DefeatScreen: Hiding defeat screen")

#endregion

#region Process
func _process(delta: float) -> void:
	"""Handle button delay before making them clickable"""
	if not visible:
		return

	# Check if we're in DEFEAT state (could exit to LOADING if restarting)
	if GameStateManager.current_state != GameStateManager.State.DEFEAT:
		return

	_show_timer += delta

	# Enable buttons after delay
	if _show_timer >= _show_delay:
		if restart_button and restart_button.disabled:
			restart_button.disabled = false
			restart_button.grab_focus()  # Focus first button
		if quit_button and quit_button.disabled:
			quit_button.disabled = false

#endregion

#region Input Handling
func _input(event: InputEvent) -> void:
	"""Handle input on defeat screen"""
	if not visible or GameStateManager.current_state != GameStateManager.State.DEFEAT:
		return

	# Only handle input after delay (prevent accidental clicks)
	if _show_timer < _show_delay:
		if event is InputEventMouseButton or event is InputEventKey:
			get_tree().root.set_input_as_handled()
		return

	# ESC key to quit
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
		get_tree().root.set_input_as_handled()

#endregion
