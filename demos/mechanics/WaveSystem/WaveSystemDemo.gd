class_name WaveSystemDemo
extends Node2D
## Demo for testing the wave system and enemy spawning
## Shows enemy spawning, movement, and phase transitions

#region Variables
var mech: Node2D = null
var hex_grid: Node = null
var enemies_spawned_count: int = 0
var enemies_killed_count: int = 0
var last_wave_info: Dictionary = {}

#endregion

#region Nodes
@onready var time_label: Label = $HUD/TimePanel/VBoxContainer/TimeLabel
@onready var phase_label: Label = $HUD/TimePanel/VBoxContainer/PhaseLabel
@onready var wave_label: Label = $HUD/WavePanel/VBoxContainer/WaveLabel
@onready var enemy_label: Label = $HUD/WavePanel/VBoxContainer/EnemyLabel
@onready var breakdown_label: Label = $HUD/WavePanel/VBoxContainer/BreakdownLabel
@onready var mech_health_label: Label = $HUD/MechPanel/VBoxContainer/HealthLabel
@onready var mech_position_label: Label = $HUD/MechPanel/VBoxContainer/PositionLabel
@onready var enemy_counter_label: Label = $HUD/MechPanel/VBoxContainer/EnemyCounterLabel
@onready var instructions_label: RichTextLabel = $HUD/InstructionsPanel/VBoxContainer/InstructionsLabel
@onready var day_night_tint: CanvasModulate = $DayNightTint

#endregion

#region Initialization
func _ready() -> void:
	mech = get_tree().get_first_node_in_group("player_mech")
	hex_grid = $HexGrid

	_setup_instructions()
	_connect_signals()
	_update_ui()

	print("WaveSystemDemo: Initialized")


func _setup_instructions() -> void:
	"""Display instructions in the demo"""
	var instructions = """[b]WAVE SYSTEM DEMO[/b]

[color=ffff99]HOW TO USE:[/color]
• Watch the day/night cycle
• Enemies spawn at night
• Day duration: 60 seconds
• Night duration: 45 seconds

[color=ffff99]WHAT TO TEST:[/color]
1. Enemies spawn at night
2. Rushers (red) move toward mech
3. Shooters (green) move slower
4. Enemies avoid path obstacles
5. Check wave scaling (more per night)

[color=ffff99]CURRENT STATUS:[/color]
Enemies Spawned: 0
Enemies Killed: 0
Current Wave: NONE

[color=ffff99]CONTROLS:[/color]
• WASD: Move mech
• Mouse: Look around
• ESC: Return to main menu
"""
	self.instructions_label.text = instructions


func _connect_signals() -> void:
	"""Connect to time and wave systems"""
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
		TimeManager.night_started.connect(_on_night_started)
		TimeManager.phase_time_remaining.connect(_on_phase_time_remaining)

	if WaveManager:
		WaveManager.wave_started.connect(_on_wave_started)
		WaveManager.wave_completed.connect(_on_wave_completed)

	# Monitor mech health if available
	if mech and mech.has_signal("health_changed"):
		mech.health_changed.connect(_on_mech_health_changed)

#endregion

#region Signal Handlers - Time
func _on_day_started(day_number: int) -> void:
	"""Called when day starts"""
	self.day_night_tint.color = GameConfig.DAY_TINT
	print("WaveSystemDemo: Day %d started" % day_number)


func _on_night_started(night_number: int) -> void:
	"""Called when night starts"""
	self.day_night_tint.color = GameConfig.NIGHT_TINT
	print("WaveSystemDemo: Night %d started" % night_number)
	print("WaveSystemDemo: Wave %d spawned with %d enemies" % [night_number, WaveManager.enemies_in_wave.size()])


func _on_phase_time_remaining(seconds_left: float) -> void:
	"""Update time display"""
	var minutes: int = int(seconds_left) / 60
	var secs: int = int(seconds_left) % 60
	self.time_label.text = "⏱️ Time: %02d:%02d" % [minutes, secs]

#endregion

#region Signal Handlers - Waves
func _on_wave_started(wave_number: int) -> void:
	"""Called when a wave starts"""
	self.enemies_spawned_count += WaveManager.enemies_in_wave.size()
	self.last_wave_info = {
		"number": wave_number,
		"total": WaveManager.enemies_in_wave.size(),
		"rushers": 0,
		"shooters": 0
	}

	# Count enemy types
	for enemy in WaveManager.enemies_in_wave:
		if enemy.enemy_type == EnemyConfig.EnemyType.RUSHER:
			self.last_wave_info["rushers"] += 1
		else:
			self.last_wave_info["shooters"] += 1

	print("WaveSystemDemo: Wave %d started with %d enemies (%d rushers, %d shooters)" % [
		wave_number,
		self.last_wave_info["total"],
		self.last_wave_info["rushers"],
		self.last_wave_info["shooters"]
	])


func _on_wave_completed(wave_number: int) -> void:
	"""Called when all enemies in a wave are defeated"""
	print("WaveSystemDemo: Wave %d complete!" % wave_number)
	self.last_wave_info.clear()


func _on_mech_health_changed(current_hp: float, max_hp: float) -> void:
	"""Update mech health display"""
	self.mech_health_label.text = "Health: %.0f / %.0f" % [current_hp, max_hp]

#endregion

#region UI Updates
func _process(_delta: float) -> void:
	"""Update UI every frame"""
	_update_ui()


func _update_ui() -> void:
	"""Update all UI elements"""
	_update_phase_info()
	_update_wave_info()
	_update_mech_info()


func _update_phase_info() -> void:
	"""Update time and phase display"""
	if not TimeManager:
		return

	var phase_name: String = "DAY" if TimeManager.is_day() else "NIGHT"
	var day_num: int = TimeManager.current_day if TimeManager.is_day() else TimeManager.current_night
	self.phase_label.text = "Phase: %s %d" % [phase_name, day_num]


func _update_wave_info() -> void:
	"""Update wave and enemy display"""
	if not WaveManager:
		return

	if WaveManager.is_wave_active:
		var wave_num: int = WaveManager.current_wave
		var enemy_count: int = WaveManager.get_active_enemy_count()
		var rusher_count: int = 0
		var shooter_count: int = 0

		for enemy in WaveManager.enemies_in_wave:
			if enemy.enemy_type == EnemyConfig.EnemyType.RUSHER:
				rusher_count += 1
			else:
				shooter_count += 1

		self.wave_label.text = "🌊 WAVE: %d" % wave_num
		self.enemy_label.text = "Enemies: %d" % enemy_count
		self.breakdown_label.text = "Rushers: %d | Shooters: %d" % [rusher_count, shooter_count]
	else:
		self.wave_label.text = "🌊 WAVE: NONE"
		self.enemy_label.text = "Enemies: 0"
		self.breakdown_label.text = "Rushers: 0 | Shooters: 0"


func _update_mech_info() -> void:
	"""Update mech information"""
	if not mech:
		return

	self.mech_position_label.text = "Position: (%.0f, %.0f)" % [mech.global_position.x, mech.global_position.y]

	# Count enemies in detection range (arbitrary 300px)
	var enemies_in_range: int = 0
	var detection_range: float = 300.0

	if WaveManager:
		for enemy in WaveManager.enemies_in_wave:
			var distance: float = mech.global_position.distance_to(enemy.global_position)
			if distance <= detection_range:
				enemies_in_range += 1

	self.enemy_counter_label.text = "Enemies in range: %d" % enemies_in_range

#endregion
