extends Node
## Manages the day/night cycle and game phase timing
## This is the game's heartbeat - everything gates on the current phase

enum Phase {
	DAY,
	NIGHT,
	TRANSITION  ## Optional brief pause between phases
}

## Emitted when day phase begins
signal day_started(day_number: int)

## Emitted when night phase begins
signal night_started(night_number: int)

## Emitted every frame with remaining time (useful for UI countdown)
signal phase_time_remaining(seconds_left: float)

## Emitted when phase changes (for anything that needs to react to phase switches)
signal phase_changed(new_phase: Phase)

## Current phase of the game
var current_phase: Phase = Phase.DAY

## Current day/night cycle number (both increment together)
var current_day: int = 1
var current_night: int = 0

## Time remaining in current phase
var time_remaining: float = 0.0

## Whether the cycle is actively running
var is_active: bool = true

## Block night from ending if wave is still active
var wave_active: bool = false


func _ready() -> void:
	# Start with day phase
	start_day()


func _process(delta: float) -> void:
	if not is_active:
		return

	time_remaining -= delta
	phase_time_remaining.emit(time_remaining)

	# Check if phase should end
	if time_remaining <= 0.0:
		_advance_phase()


func start_day() -> void:
	"""Begin day phase"""
	current_phase = Phase.DAY
	time_remaining = GameConfig.DAY_DURATION
	day_started.emit(current_day)
	phase_changed.emit(Phase.DAY)
	print("[TimeManager] Day %d started (%d seconds)" % [current_day, GameConfig.DAY_DURATION])


func start_night() -> void:
	"""Begin night phase"""
	current_phase = Phase.NIGHT
	current_night += 1
	time_remaining = GameConfig.NIGHT_DURATION
	night_started.emit(current_night)
	phase_changed.emit(Phase.NIGHT)
	print("[TimeManager] Night %d started (%d seconds)" % [current_night, GameConfig.NIGHT_DURATION])


func _advance_phase() -> void:
	"""Automatically advance to next phase"""
	match current_phase:
		Phase.DAY:
			start_night()

		Phase.NIGHT:
			# Check if wave is still active - if so, extend night
			if wave_active:
				print("[TimeManager] Night extended - wave still active")
				time_remaining = 5.0  # Give 5 more seconds
				return

			# Night complete, move to next day
			current_day += 1
			start_day()

		Phase.TRANSITION:
			# Future: handle transition state if needed
			pass


func pause_cycle() -> void:
	"""Pause the day/night cycle"""
	is_active = false


func resume_cycle() -> void:
	"""Resume the day/night cycle"""
	is_active = true


func set_wave_active(active: bool) -> void:
	"""Called by WaveManager to block night from ending"""
	wave_active = active


func is_day() -> bool:
	"""Convenience check for day phase"""
	return current_phase == Phase.DAY


func is_night() -> bool:
	"""Convenience check for night phase"""
	return current_phase == Phase.NIGHT


func get_phase_progress() -> float:
	"""Returns 0.0 to 1.0 progress through current phase"""
	var total_duration: float = GameConfig.DAY_DURATION if is_day() else GameConfig.NIGHT_DURATION
	return 1.0 - (time_remaining / total_duration)


func format_time(seconds: float) -> String:
	"""Helper to format time as MM:SS"""
	var minutes: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]
