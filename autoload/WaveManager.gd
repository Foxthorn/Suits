extends Node
## Manages enemy waves: spawning, scaling, and progression
## Autoload singleton for global wave management

#region Signals
## Emitted when a wave starts (with wave number)
signal wave_started(wave_number: int)

## Emitted when all enemies in current wave are defeated
signal wave_completed(wave_number: int)

## Emitted when all waves are defeated (game won)
signal all_waves_cleared()

#endregion

#region Variables - State
var current_wave: int = 0
var enemies_in_wave: Array[BaseEnemy] = []
var is_wave_active: bool = false

#endregion

#region Variables - Configuration
var enemy_rusher_scene: PackedScene = preload("res://scenes/entities/enemies/BaseEnemy.tscn")
var enemy_shooter_scene: PackedScene = preload("res://scenes/entities/enemies/BaseEnemy.tscn")

#endregion

#region Initialization
func _ready() -> void:
	print("WaveManager: Initialized")

	# Connect to TimeManager for night/day transitions
	if TimeManager:
		TimeManager.night_started.connect(_on_night_started)
	else:
		push_error("WaveManager: TimeManager autoload not found!")

#endregion

#region Wave Management
## Start a new wave (called by TimeManager on night start)
func _on_night_started(night_number: int) -> void:
	self.current_wave = night_number
	start_wave(night_number)


## Begin spawning enemies for a specific wave
func start_wave(wave_number: int) -> void:
	if self.is_wave_active:
		push_warning("WaveManager: Wave already active!")
		return

	self.current_wave = wave_number
	self.enemies_in_wave.clear()
	self.is_wave_active = true

	# Notify TimeManager that wave is active
	TimeManager.set_wave_active(true)

	# Spawn enemies
	_spawn_wave_enemies(wave_number)

	self.wave_started.emit(wave_number)
	print("WaveManager: Wave %d started with %d enemies" % [wave_number, self.enemies_in_wave.size()])


## Calculate how many enemies to spawn for this wave
func _get_enemy_count_for_wave(wave_number: int) -> int:
	"""Formula: 5 + (wave_num * 3)"""
	return EnemyConfig.WAVE_BASE_COUNT + (wave_number * EnemyConfig.WAVE_COUNT_PER_LEVEL)


## Spawn all enemies for the wave
func _spawn_wave_enemies(wave_number: int) -> void:
	"""Spawn enemies at edges of map, distributed around mech"""
	var enemy_count: int = _get_enemy_count_for_wave(wave_number)
	var rusher_count: int = int(enemy_count * EnemyConfig.WAVE_RUSHER_PERCENTAGE)
	var shooter_count: int = enemy_count - rusher_count

	var spawn_points: Array[Vector2] = _calculate_spawn_points()

	# Spawn rushers
	for i in range(rusher_count):
		var spawn_point: Vector2 = spawn_points[i % spawn_points.size()]
		_spawn_rusher(spawn_point)

	# Spawn shooters
	for i in range(shooter_count):
		var spawn_point: Vector2 = spawn_points[(rusher_count + i) % spawn_points.size()]
		_spawn_shooter(spawn_point)


## Calculate spawn points around the mech
func _calculate_spawn_points() -> Array[Vector2]:
	"""Generate spawn points in 4 directions around the mech"""
	var spawn_points: Array[Vector2] = []
	var mech = get_tree().get_first_node_in_group("player_mech")

	if mech == null:
		push_error("WaveManager: Cannot find mech to calculate spawn points!")
		return spawn_points

	var mech_pos: Vector2 = mech.global_position
	var spawn_distance: float = EnemyConfig.SPAWN_DISTANCE_FROM_MECH
	var point_count: int = EnemyConfig.SPAWN_POINTS_PER_WAVE

	for i in range(point_count):
		var angle: float = (TAU / point_count) * i
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_distance

		# Add some randomness to spawn position
		var spread_angle: float = randf_range(-EnemyConfig.SPAWN_SPREAD_ANGLE, EnemyConfig.SPAWN_SPREAD_ANGLE)
		var spread_distance: float = randf_range(-50.0, 50.0)
		var spread_offset: Vector2 = Vector2(cos(spread_angle), sin(spread_angle)) * spread_distance

		spawn_points.append(mech_pos + offset + spread_offset)

	return spawn_points


## Spawn a single rusher enemy
func _spawn_rusher(position: Vector2) -> void:
	"""Instantiate a rusher enemy at the specified position"""
	var enemy = self.enemy_rusher_scene.instantiate() as BaseEnemy
	enemy.global_position = position

	# Configure as rusher
	enemy.enemy_type = EnemyConfig.EnemyType.RUSHER
	enemy.speed = EnemyConfig.RUSHER_SPEED
	enemy.max_health = EnemyConfig.RUSHER_MAX_HP
	enemy.damage = EnemyConfig.RUSHER_DAMAGE

	_add_enemy_to_wave(enemy)


## Spawn a single shooter enemy
func _spawn_shooter(position: Vector2) -> void:
	"""Instantiate a shooter enemy at the specified position"""
	var enemy = self.enemy_shooter_scene.instantiate() as BaseEnemy
	enemy.global_position = position

	# Configure as shooter
	var shooter = enemy as ShooterEnemy
	if shooter:
		enemy.enemy_type = EnemyConfig.EnemyType.SHOOTER
		enemy.speed = EnemyConfig.SHOOTER_SPEED
		enemy.max_health = EnemyConfig.SHOOTER_MAX_HP
	else:
		# Fallback if not a shooter
		enemy.enemy_type = EnemyConfig.EnemyType.SHOOTER
		enemy.speed = EnemyConfig.SHOOTER_SPEED
		enemy.max_health = EnemyConfig.SHOOTER_MAX_HP

	_add_enemy_to_wave(enemy)


## Register enemy in wave and track its death
func _add_enemy_to_wave(enemy: BaseEnemy) -> void:
	"""Add enemy to tracking array and connect death signal"""
	self.enemies_in_wave.append(enemy)
	enemy.died.connect(_on_enemy_died.bindv([enemy]))

	# Add to scene (find the root node or use get_tree().current_scene)
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(enemy)


## Called when an enemy dies
func _on_enemy_died(enemy: BaseEnemy) -> void:
	"""Remove dead enemy from tracking and check if wave is complete"""
	if enemy in self.enemies_in_wave:
		self.enemies_in_wave.erase(enemy)

	# Check if all enemies defeated
	if self.enemies_in_wave.is_empty():
		_on_wave_complete()


## Called when all enemies in wave are defeated
func _on_wave_complete() -> void:
	"""Signal wave completion and allow night to end"""
	self.is_wave_active = false
	TimeManager.set_wave_active(false)

	self.wave_completed.emit(self.current_wave)
	print("WaveManager: Wave %d complete!" % self.current_wave)

#endregion

#region Utilities
func get_active_enemy_count() -> int:
	"""Return number of alive enemies in current wave"""
	return self.enemies_in_wave.size()


func get_wave_progress() -> float:
	"""Return 0.0 to 1.0 progress through current wave (inverse of enemies remaining)"""
	if self.enemies_in_wave.is_empty():
		return 1.0

	# Would need to track initial count to calculate this properly
	# For now, return 0.0 while wave active, 1.0 when complete
	return 0.0 if self.is_wave_active else 1.0

#endregion
