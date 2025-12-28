class_name EnemyDatabase
## Central database for all enemy definitions
## Static-only class - easily extensible: Just call register_enemy() to add new enemy types

## Enemy types enum - add new entries here when adding enemies
enum EnemyType {
	RUSHER = 0,
	SHOOTER = 1,
	# Add new enemy types here
}

## Enemy data structure - can be extended with more properties
class EnemyData:
	var id: EnemyType
	var name: String
	var speed: float  # pixels per second
	var max_health: float  # HP
	var damage: float  # Damage per hit/collision
	var description: String
	var sprite_path: String  # Path to enemy sprite texture (sprite sheet)
	var color: Color  # fallback color if sprite fails to load
	var debug_draw: bool = false  # Print debug information

	# Animation-specific data
	var idle_sprite_path: String  # Idle animation sprite sheet
	var walk_sprite_path: String  # Walk animation sprite sheet
	var attack_sprite_path: String  # Attack animation sprite sheet
	var hit_sprite_path: String  # Hit/damage animation sprite sheet
	var death_sprite_path: String  # Death animation sprite sheet

	# Per-animation frame counts
	var idle_frame_count: int = 4  # Number of frames in idle animation
	var walk_frame_count: int = 4  # Number of frames in walk animation
	var attack_frame_count: int = 5  # Number of frames in attack animation
	var hit_frame_count: int = 2  # Number of frames in hit animation
	var death_frame_count: int = 4  # Number of frames in death animation

	func _init(p_id: EnemyType, p_name: String, p_description: String, p_speed: float, p_max_health: float, p_damage: float, p_sprite_path: String, p_color: Color, p_idle_sprite: String = "", p_walk_sprite: String = "", p_attack_sprite: String = "", p_hit_sprite: String = "", p_death_sprite: String = "", p_idle_frames: int = 4, p_walk_frames: int = 4, p_attack_frames: int = 5, p_hit_frames: int = 2, p_death_frames: int = 4, p_debug_draw: bool = false):
		id = p_id
		name = p_name
		description = p_description
		speed = p_speed
		max_health = p_max_health
		damage = p_damage
		sprite_path = p_sprite_path
		color = p_color
		idle_sprite_path = p_idle_sprite
		walk_sprite_path = p_walk_sprite
		attack_sprite_path = p_attack_sprite
		hit_sprite_path = p_hit_sprite
		death_sprite_path = p_death_sprite
		idle_frame_count = p_idle_frames
		walk_frame_count = p_walk_frames
		attack_frame_count = p_attack_frames
		hit_frame_count = p_hit_frames
		death_frame_count = p_death_frames
		debug_draw = p_debug_draw

	## Load and return the main sprite texture
	func get_sprite() -> Texture2D:
		if sprite_path.is_empty():
			return null
		var texture: Texture2D = load(sprite_path)
		if not texture:
			push_warning("EnemyData: Failed to load sprite at %s" % sprite_path)
		return texture

	## Load and return the idle animation sprite sheet
	func get_idle_sprite() -> Texture2D:
		if idle_sprite_path.is_empty():
			return null
		var texture: Texture2D = load(idle_sprite_path)
		if not texture:
			push_warning("EnemyData: Failed to load idle sprite at %s" % idle_sprite_path)
		return texture

	## Load and return the walk animation sprite sheet
	func get_walk_sprite() -> Texture2D:
		if walk_sprite_path.is_empty():
			return null
		var texture: Texture2D = load(walk_sprite_path)
		if not texture:
			push_warning("EnemyData: Failed to load walk sprite at %s" % walk_sprite_path)
		return texture

	## Load and return the attack animation sprite sheet
	func get_attack_sprite() -> Texture2D:
		if attack_sprite_path.is_empty():
			return null
		var texture: Texture2D = load(attack_sprite_path)
		if not texture:
			push_warning("EnemyData: Failed to load attack sprite at %s" % attack_sprite_path)
		return texture

	## Load and return the hit animation sprite sheet
	func get_hit_sprite() -> Texture2D:
		if hit_sprite_path.is_empty():
			return null
		var texture: Texture2D = load(hit_sprite_path)
		if not texture:
			push_warning("EnemyData: Failed to load hit sprite at %s" % hit_sprite_path)
		return texture

	## Load and return the death animation sprite sheet
	func get_death_sprite() -> Texture2D:
		if death_sprite_path.is_empty():
			return null
		var texture: Texture2D = load(death_sprite_path)
		if not texture:
			push_warning("EnemyData: Failed to load death sprite at %s" % death_sprite_path)
		return texture

static var _registry: Dictionary = {}  # EnemyType -> EnemyData
static var _initialized: bool = false

## Initialize enemy database (called automatically on first access)
static func _ensure_initialized() -> void:
	if _initialized:
		return

	_initialized = true

	# Register all enemies using EnemyConfig constants
	register_enemy(EnemyData.new(
		EnemyType.RUSHER,
		EnemyConfig.RUSHER_NAME,
		EnemyConfig.RUSHER_DESCRIPTION,
		EnemyConfig.RUSHER_SPEED,
		EnemyConfig.RUSHER_MAX_HP,
		EnemyConfig.RUSHER_DAMAGE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.RUSHER_SPRITE,
		EnemyConfig.RUSHER_COLOR,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.RUSHER_IDLE_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.RUSHER_WALK_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.RUSHER_ATTACK_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.RUSHER_HIT_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.RUSHER_DEATH_SPRITE,
		EnemyConfig.RUSHER_IDLE_FRAMES,
		EnemyConfig.RUSHER_WALK_FRAMES,
		EnemyConfig.RUSHER_ATTACK_FRAMES,
		EnemyConfig.RUSHER_HIT_FRAMES,
		EnemyConfig.RUSHER_DEATH_FRAMES
	))

	register_enemy(EnemyData.new(
		EnemyType.SHOOTER,
		EnemyConfig.SHOOTER_NAME,
		EnemyConfig.SHOOTER_DESCRIPTION,
		EnemyConfig.SHOOTER_SPEED,
		EnemyConfig.SHOOTER_MAX_HP,
		EnemyConfig.SHOOTER_DAMAGE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.SHOOTER_SPRITE,
		EnemyConfig.SHOOTER_COLOR,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.SHOOTER_IDLE_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.SHOOTER_WALK_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.SHOOTER_ATTACK_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.SHOOTER_HIT_SPRITE,
		EnemyConfig.ASSET_BASE_PATH + EnemyConfig.SHOOTER_DEATH_SPRITE,
		EnemyConfig.SHOOTER_IDLE_FRAMES,
		EnemyConfig.SHOOTER_WALK_FRAMES,
		EnemyConfig.SHOOTER_ATTACK_FRAMES,
		EnemyConfig.SHOOTER_HIT_FRAMES,
		EnemyConfig.SHOOTER_DEATH_FRAMES
	))

	print("EnemyDatabase: Initialized with %d enemies" % _registry.size())

## Register a new enemy type (extensibility point)
static func register_enemy(enemy_data: EnemyData) -> void:
	if _registry.has(enemy_data.id):
		push_warning("EnemyDatabase: Overwriting existing enemy type %d" % enemy_data.id)

	_registry[enemy_data.id] = enemy_data

## Get enemy data by type
static func get_enemy(type: EnemyType) -> EnemyData:
	_ensure_initialized()
	return _registry.get(type)

## Get enemy name by type
static func get_enemy_name(type: EnemyType) -> String:
	var enemy_data := get_enemy(type)
	return enemy_data.name if enemy_data else "Unknown"

## Get enemy speed by type
static func get_enemy_speed(type: EnemyType) -> float:
	var enemy_data := get_enemy(type)
	return enemy_data.speed if enemy_data else 0.0

## Get enemy health by type
static func get_enemy_health(type: EnemyType) -> float:
	var enemy_data := get_enemy(type)
	return enemy_data.max_health if enemy_data else 0.0

## Get enemy damage by type
static func get_enemy_damage(type: EnemyType) -> float:
	var enemy_data := get_enemy(type)
	return enemy_data.damage if enemy_data else 0.0

## Get all registered enemy types as array (useful for UI iteration)
static func get_all_enemy_types() -> Array[EnemyType]:
	_ensure_initialized()
	var types: Array[EnemyType] = []
	for key in _registry.keys():
		types.append(key)
	return types

## Get all registered enemy data (useful for UI generation)
static func get_all_enemies() -> Array[EnemyData]:
	_ensure_initialized()
	var enemies: Array[EnemyData] = []
	for enemy_data in _registry.values():
		enemies.append(enemy_data)
	return enemies

## Check if an enemy type is registered
static func has_enemy(type: EnemyType) -> bool:
	_ensure_initialized()
	return _registry.has(type)
