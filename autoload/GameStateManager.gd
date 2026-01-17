## GameStateManager.gd
## Central manager for game state, pause, and win/loss conditions.
## Tracks game phases (PLAYING, PAUSED, DEFEAT, VICTORY) and handles transitions.

extends Node

# Game state enum
enum State {
	PLAYING,
	PAUSED,
	DEFEAT,
	VICTORY,
	LOADING
}

# State tracking
var current_state: State = State.LOADING
var is_restarting: bool = false

# Night/wave progression tracking
var current_night: int = 0
var nights_survived: int = 0

# Statistics for victory screen
var final_stats: Dictionary = {}

# Signals
signal state_changed(new_state: State)
signal game_paused()
signal game_resumed()
signal defeat_triggered(reason: String)
signal victory_triggered(stats: Dictionary)

# Signal connections (will be connected in _ready)
var _mech_controller: Node = null
var _wave_manager: Node = null
var _time_manager: Node = null
var _economy_manager: Node = null
var _tower_system: Node = null
var _planting_system: Node = null
var _progress_manager: Node = null

func _ready() -> void:
	# Get references to autoload systems
	_mech_controller = get_tree().root.get_node("MainGame/Mech")
	_wave_manager = WaveManager
	_time_manager = TimeManager
	_economy_manager = EconomyManager
	_tower_system = get_tree().root.get_node("MainGame/HexGrid").get_node_or_null("../TowerSystem")
	_planting_system = get_tree().root.get_node("MainGame/HexGrid").get_node_or_null("../PlantingSystem")
	_progress_manager = ProgressManager

	# Set initial state to PLAYING when game starts
	current_state = State.PLAYING
	state_changed.emit(current_state)

	# Connect to critical system signals
	if _mech_controller:
		_mech_controller.died.connect(_on_mech_died)

	if _wave_manager:
		_wave_manager.wave_completed.connect(_on_wave_completed)

	if _time_manager:
		_time_manager.night_started.connect(_on_night_started)

func _input(event: InputEvent) -> void:
	# Toggle pause on ESC key (ui_cancel action)
	if event.is_action_pressed("ui_cancel"):
		if current_state == State.PLAYING:
			pause_game()
		elif current_state == State.PAUSED:
			resume_game()
		get_tree().root.set_input_as_handled()

## Pause the game and show pause menu
func pause_game() -> void:
	if current_state != State.PLAYING:
		return

	current_state = State.PAUSED
	Engine.time_scale = 0.0
	state_changed.emit(current_state)
	game_paused.emit()

## Resume the game from pause
func resume_game() -> void:
	if current_state != State.PAUSED:
		return

	current_state = State.PLAYING
	Engine.time_scale = 1.0
	state_changed.emit(current_state)
	game_resumed.emit()

## Trigger defeat (mech destroyed)
func trigger_defeat(reason: String = "Mech destroyed") -> void:
	# Ignore if already in a terminal state
	if current_state in [State.DEFEAT, State.VICTORY]:
		return

	# Unpause if paused
	if current_state == State.PAUSED:
		Engine.time_scale = 1.0

	current_state = State.DEFEAT
	state_changed.emit(current_state)
	defeat_triggered.emit(reason)

## Trigger victory (survived all nights)
func trigger_victory(stats: Dictionary) -> void:
	# Ignore if already in a terminal state
	if current_state in [State.DEFEAT, State.VICTORY]:
		return

	# Unpause if paused
	if current_state == State.PAUSED:
		Engine.time_scale = 1.0

	current_state = State.VICTORY
	final_stats = stats
	state_changed.emit(current_state)
	victory_triggered.emit(stats)

## Restart the game (reload current scene)
func restart_game() -> void:
	if is_restarting:
		return

	is_restarting = true
	Engine.time_scale = 1.0  # Reset time scale before reload
	get_tree().reload_current_scene()

## Quit to main menu (or desktop if no menu implemented)
func quit_game() -> void:
	Engine.time_scale = 1.0  # Reset time scale before quit
	get_tree().quit()

## Query current game state
func get_current_state() -> State:
	return current_state

## Convenience check for pause state
func is_game_paused() -> bool:
	return current_state == State.PAUSED

## Get current night number
func get_current_night() -> int:
	if _time_manager:
		return _time_manager.current_night
	return current_night

## Get nights survived so far
func get_nights_survived() -> int:
	return nights_survived

# ============================================================================
# INTERNAL SIGNAL HANDLERS
# ============================================================================

## Called when MechController emits died signal
func _on_mech_died() -> void:
	var wave_num = _wave_manager.get_current_wave() if _wave_manager else 0
	var night_num = _time_manager.current_night if _time_manager else 0
	var reason: String = "Mech destroyed on Night %d, Wave %d" % [night_num, wave_num]
	trigger_defeat(reason)

## Called when WaveManager emits wave_completed signal
func _on_wave_completed(wave_num: int) -> void:
	# Check if this was the final wave (night 3)
	var night_num = _time_manager.current_night if _time_manager else 0
	if night_num == 3 and wave_num == 3:
		# Gather final statistics
		var stats: Dictionary = _gather_victory_stats()
		trigger_victory(stats)

## Called when TimeManager emits night_started signal
func _on_night_started(night_num: int) -> void:
	current_night = night_num
	nights_survived = night_num

## Gather statistics for victory screen
func _gather_victory_stats() -> Dictionary:
	var night_num = _time_manager.current_night if _time_manager else 0
	var stats: Dictionary = {
		"nights_survived": night_num,
		"total_credits_earned": _economy_manager.get_total_credits_earned() if _economy_manager else 0,
		"enemies_defeated": _wave_manager.get_enemies_defeated_count() if _wave_manager else 0,
		"crops_harvested": _planting_system.get_crops_harvested_count() if _planting_system else 0,
		"towers_built": _tower_system.get_tower_count() if _tower_system else 0,
		"upgrades_purchased": _progress_manager.get_purchased_upgrades_count() if _progress_manager else 0,
	}
	return stats
