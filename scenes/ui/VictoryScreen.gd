## VictoryScreen.gd
## Controller for the victory screen
## Listens to GameStateManager and shows when victory is triggered

extends Control

#region Exports
@export var title_label: Label = null
@export var subtitle_label: Label = null
@export var stats_container: VBoxContainer = null
@export var play_again_button: Button = null
@export var quit_button: Button = null
@export var background: ColorRect = null

#endregion

#region Variables
var _victory_stats: Dictionary = {}
var _show_delay: float = 1.5  # Wait before showing buttons
var _show_timer: float = 0.0

#endregion

#region Initialization
func _ready() -> void:
	# Auto-find children if not assigned
	if not title_label:
		title_label = find_child("TitleLabel", true, false)
	if not subtitle_label:
		subtitle_label = find_child("SubtitleLabel", true, false)
	if not stats_container:
		stats_container = find_child("StatsContainer", true, false)
	if not play_again_button:
		play_again_button = find_child("PlayAgainButton", true, false)
	if not quit_button:
		quit_button = find_child("QuitButton", true, false)
	if not background:
		background = find_child("Background", true, false)

	# Connect button signals
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Start hidden
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # Don't intercept input when hidden

	# Connect to GameStateManager
	if GameStateManager:
		GameStateManager.victory_triggered.connect(_on_victory_triggered)
	else:
		push_error("VictoryScreen: GameStateManager autoload not found!")

	print("VictoryScreen: Initialized")

#endregion

#region Signal Handlers
func _on_victory_triggered(stats: Dictionary) -> void:
	"""Called when GameStateManager triggers victory"""
	_victory_stats = stats
	_show_timer = 0.0  # Reset timer for button delay
	_show_victory_screen()

func _on_play_again_pressed() -> void:
	"""Play again button clicked"""
	GameStateManager.restart_game()

func _on_quit_pressed() -> void:
	"""Quit to desktop button clicked"""
	GameStateManager.quit_game()

#endregion

#region Display Control
func _show_victory_screen() -> void:
	"""Show the victory screen with animations and stats"""
	visible = true
	mouse_filter = MOUSE_FILTER_STOP  # Capture input when visible

	# Update subtitle
	if subtitle_label:
		subtitle_label.text = "You survived all 3 nights!"

	# Populate stats
	_populate_stats()

	# Disable buttons initially (will enable after delay)
	if play_again_button:
		play_again_button.disabled = true
	if quit_button:
		quit_button.disabled = true

	# Fade in background
	if background:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		background.modulate.a = 0.0
		tween.tween_property(background, "modulate:a", 0.7, 0.4)

	print("VictoryScreen: Showing victory screen with stats")

func _hide_victory_screen() -> void:
	"""Hide the victory screen"""
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE  # Don't intercept input when hidden

	# Kill any ongoing animations
	#if is_instance_valid(self):
		#var tweens = get_all_tweens()
		#for tween in tweens:
			#tween.kill()

	print("VictoryScreen: Hiding victory screen")

func _populate_stats() -> void:
	"""Populate the stats container with victory stats"""
	if not stats_container:
		return

	# Clear existing stat labels
	for child in stats_container.get_children():
		child.queue_free()

	# Create stat labels from dictionary
	var stat_order = [
		"nights_survived",
		"enemies_defeated",
		"total_credits_earned",
		"crops_harvested",
		"towers_built",
		"upgrades_purchased"
	]

	for stat_key in stat_order:
		if _victory_stats.has(stat_key):
			var value = _victory_stats[stat_key]
			var stat_label = Label.new()

			# Format the stat text
			var label_text = ""
			match stat_key:
				"nights_survived":
					label_text = "Nights Survived: %d / 3" % value
				"enemies_defeated":
					label_text = "Enemies Defeated: %d" % value
				"total_credits_earned":
					label_text = "Credits Earned: %d" % value
				"crops_harvested":
					label_text = "Crops Harvested: %d" % value
				"towers_built":
					label_text = "Towers Built: %d" % value
				"upgrades_purchased":
					label_text = "Upgrades Purchased: %d" % value
				_:
					label_text = "%s: %s" % [stat_key, value]

			stat_label.text = label_text
			stat_label.custom_minimum_size = Vector2(0, 30)
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats_container.add_child(stat_label)

#endregion

#region Process
func _process(delta: float) -> void:
	"""Handle button delay before making them clickable"""
	if not visible:
		return

	# Check if we're in VICTORY state (could exit to LOADING if restarting)
	if GameStateManager.current_state != GameStateManager.State.VICTORY:
		return

	_show_timer += delta

	# Enable buttons after delay
	if _show_timer >= _show_delay:
		if play_again_button and play_again_button.disabled:
			play_again_button.disabled = false
			play_again_button.grab_focus()  # Focus first button
		if quit_button and quit_button.disabled:
			quit_button.disabled = false

#endregion

#region Input Handling
func _input(event: InputEvent) -> void:
	"""Handle input on victory screen"""
	if not visible or GameStateManager.current_state != GameStateManager.State.VICTORY:
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
