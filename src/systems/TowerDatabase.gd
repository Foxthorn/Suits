class_name TowerDatabase
## Centralized tower type registry with extensible registration system
## Similar pattern to EnemyDatabase and CropDatabase
## All tower types and their stats are defined here

#region Tower Type Enum
enum TowerType {
	GATLING_GUN,
	# Future types:
	# SNIPER_TOWER,
	# FLAME_TOWER,
	# ICE_TOWER,
}
#endregion

#region TowerData Class
class TowerData:
	"""Immutable data structure containing all tower configuration"""
	var type: TowerType
	var name: String
	var description: String
	var cost: int
	var range: float
	var damage: float
	var fire_rate: float
	var bullet_speed: float
	var bullet_lifetime: float
	var sprite_path: String
	var bullet_color: Color
	var size: float
	var collision_radius: float

	func _init(
		p_type: TowerType,
		p_name: String,
		p_description: String,
		p_cost: int,
		p_range: float,
		p_damage: float,
		p_fire_rate: float,
		p_bullet_speed: float,
		p_bullet_lifetime: float,
		p_sprite_path: String,
		p_bullet_color: Color,
		p_size: float,
		p_collision_radius: float
	) -> void:
		type = p_type
		name = p_name
		description = p_description
		cost = p_cost
		range = p_range
		damage = p_damage
		fire_rate = p_fire_rate
		bullet_speed = p_bullet_speed
		bullet_lifetime = p_bullet_lifetime
		sprite_path = p_sprite_path
		bullet_color = p_bullet_color
		size = p_size
		collision_radius = p_collision_radius

	func get_sprite() -> Texture2D:
		"""Load sprite from configured path, with fallback"""
		if sprite_path and sprite_path != "":
			var texture = load(sprite_path)
			if texture:
				return texture
		return null  # Will use placeholder in tower script
#endregion

#region Static Registry
static var _registry: Dictionary = {}  # TowerType -> TowerData
static var _initialized: bool = false

static func _ensure_initialized() -> void:
	"""Initialize registry on first access"""
	if _initialized:
		return

	# Register all tower types
	register_tower(TowerData.new(
		TowerType.GATLING_GUN,
		"Gatling Gun",
		"Rapid-fire turret. High fire rate, lower damage. Great for hordes.",
		TowerConfig.TOWER_GATLING_GUN_COST,
		TowerConfig.TOWER_GATLING_GUN_RANGE,
		TowerConfig.TOWER_GATLING_GUN_DAMAGE,
		TowerConfig.TOWER_GATLING_GUN_FIRE_RATE,
		TowerConfig.TOWER_GATLING_GUN_BULLET_SPEED,
		TowerConfig.TOWER_GATLING_GUN_BULLET_LIFETIME,
		TowerConfig.TOWER_GATLING_GUN_SPRITE,
		TowerConfig.TOWER_GATLING_GUN_BULLET_COLOR,
		TowerConfig.TOWER_GATLING_GUN_SIZE,
		TowerConfig.TOWER_GATLING_GUN_COLLISION_RADIUS
	))

	# TODO: Add more tower types here as they're implemented
	# register_tower(TowerData.new(
	#     TowerType.SNIPER_TOWER,
	#     ...
	# ))

	_initialized = true
	print("TowerDatabase: Initialized with %d tower types" % _registry.size())

#endregion

#region Public API
static func get_tower(type: TowerType) -> TowerData:
	"""Get tower data by type"""
	_ensure_initialized()
	if not _registry.has(type):
		push_error("TowerDatabase: Tower type not found: %s" % type)
		return null
	return _registry[type]

static func get_tower_name(type: TowerType) -> String:
	"""Get tower display name"""
	var data = get_tower(type)
	return data.name if data else "Unknown"

static func get_tower_cost(type: TowerType) -> int:
	"""Get tower placement cost"""
	var data = get_tower(type)
	return data.cost if data else 0

static func get_all_tower_types() -> Array[TowerType]:
	"""Get list of all available tower types"""
	_ensure_initialized()
	var types: Array[TowerType] = []
	for tower_type in _registry.keys():
		types.append(tower_type)
	return types

static func register_tower(tower_data: TowerData) -> void:
	"""Register a new tower type (used during initialization)"""
	if _registry.has(tower_data.type):
		push_warning("TowerDatabase: Tower type already registered: %s" % tower_data.type)
		return
	_registry[tower_data.type] = tower_data

#endregion
