class_name TowerWeaponSystem extends Node
## Handles tower projectile spawning and pooling
## Similar to WeaponSystem but for tower-specific bullets
## Manages a separate pool of tower projectiles
## Uses AtlasTexture for sprite rendering with configurable colors
## Updates bullet positions and lifetimes each frame

#region Signals
signal tower_bullet_fired(bullet: Node2D, from_position: Vector2, direction: Vector2)
signal tower_bullet_expired(bullet: Node2D)

#endregion

#region Private Variables
var _bullet_pool: Array[TowerBullet] = []
var _active_bullets: Array[TowerBullet] = []
var _tower_data: TowerDatabase.TowerData

#endregion

#region Static Sprite Cache
## Cached sprite textures to avoid repeated loads
static var _sprite_sheet_cache: Dictionary = {}  # Path -> Texture2D
static var _cached_placeholder_texture: Texture2D = null

#endregion

#region Lifecycle
func _physics_process(delta: float) -> void:
	"""Monitor active bullets - handle expiration"""
	# Process in reverse to safely remove expired bullets
	for i in range(_active_bullets.size() - 1, -1, -1):
		var bullet = _active_bullets[i]
		if not is_instance_valid(bullet):
			_active_bullets.remove_at(i)
			continue

		# TowerBullet handles its own movement and lifetime via _physics_process
		# Listen for expiration signal
		if not bullet.expired.is_connected(_on_tower_bullet_expired.bindv([bullet])):
			bullet.expired.connect(_on_tower_bullet_expired.bindv([bullet]), CONNECT_ONE_SHOT)

#endregion

#region Initialization
func initialize(tower_data: TowerDatabase.TowerData) -> void:
	"""Initialize the weapon system with tower data"""
	_tower_data = tower_data
	_setup_bullet_pool()

func _setup_bullet_pool() -> void:
	"""Pre-create bullet pool for performance"""
	for i in range(TowerConfig.TOWER_BULLET_POOL_SIZE):
		var bullet = _create_bullet_node()
		bullet.set_process(false)
		bullet.set_physics_process(false)
		bullet.hide()
		_bullet_pool.append(bullet)

	# Initialization logged at debug level (remove for production if excessive)

func _create_bullet_node() -> TowerBullet:
	"""Create a tower bullet node using TowerBullet class (instead of inline node)"""
	var bullet = TowerBullet.new()
	bullet.name = "TowerBullet"
	return bullet

#endregion

#region Firing
func fire(from_position: Vector2, direction: Vector2, color: Color) -> void:
	"""Fire a tower bullet in the given direction"""
	var bullet = _get_pooled_bullet()

	if not bullet:
		# Pool exhausted, create new one
		bullet = _create_bullet_node()
		get_tree().current_scene.add_child(bullet)
		bullet.prepare()
	else:
		# Reuse from pool - clean up previous state
		bullet.prepare()

	# Setup bullet using TowerBullet API
	bullet.global_position = from_position
	bullet.set_velocity(direction, _tower_data.bullet_speed)
	bullet.set_color(color)
	bullet.set_lifetime(_tower_data.bullet_lifetime)
	bullet.set_damage(_tower_data.damage)

	# Add to scene if not already added
	if bullet.get_parent() == null:
		get_tree().current_scene.add_child(bullet)

	# Track active bullet (lifetime managed by TowerBullet._physics_process)
	_active_bullets.append(bullet)

	# Emit signal
	tower_bullet_fired.emit(bullet, from_position, direction)


func _on_tower_bullet_expired(bullet: TowerBullet) -> void:
	"""Handle tower bullet expiration"""
	tower_bullet_expired.emit(bullet)
	_return_bullet_to_pool(bullet)

#endregion

#region Pooling
func _get_pooled_bullet() -> TowerBullet:
	"""Get a bullet from the pool"""
	if _bullet_pool.is_empty():
		return null
	return _bullet_pool.pop_back()



func _return_bullet_to_pool(bullet: Node2D) -> void:
	"""Return bullet to pool for reuse"""
	_active_bullets.erase(bullet)
	(bullet as TowerBullet).reset()
	bullet.hide()
	_bullet_pool.append(bullet)

#endregion



#region Public API
func get_active_bullet_count() -> int:
	"""Get number of active bullets in flight"""
	return _active_bullets.size()

func get_pooled_bullet_count() -> int:
	"""Get number of bullets available in pool"""
	return _bullet_pool.size()

func retire_bullet(bullet: Node2D) -> void:
	"""Retire an active bullet back to the pool (used when hit or expired)"""
	if not _active_bullets.has(bullet):
		return
	_return_bullet_to_pool(bullet)

#endregion
