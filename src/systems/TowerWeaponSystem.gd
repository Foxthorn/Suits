class_name TowerWeaponSystem
## Handles tower projectile spawning and pooling
## Similar to WeaponSystem but for tower-specific bullets
## Manages a separate pool of tower projectiles

#region Signals
signal tower_bullet_fired(bullet: Node2D, position: Vector2, direction: Vector2)

#endregion

#region Configuration
const TOWER_BULLET_POOL_SIZE: int = 100  # Max pooled tower bullets
const TOWER_BULLET_SCENE: PackedScene = preload("res://scenes/entities/projectiles/TowerBullet.tscn")

#endregion

#region Private Variables
var _bullet_pool: Array[Node2D] = []
var _active_bullets: Array[Node2D] = []
var _tower_data: TowerDatabase.TowerData

#endregion

#region Initialization
func initialize(tower_data: TowerDatabase.TowerData) -> void:
	"""Initialize the weapon system with tower data"""
	_tower_data = tower_data
	_setup_bullet_pool()

func _setup_bullet_pool() -> void:
	"""Pre-create bullet pool for performance"""
	for i in range(TOWER_BULLET_POOL_SIZE):
		var bullet = TOWER_BULLET_SCENE.instantiate()
		bullet.set_process(false)
		bullet.set_physics_process(false)
		bullet.hide()
		_bullet_pool.append(bullet)

	print("TowerWeaponSystem: Initialized pool with %d bullets" % TOWER_BULLET_POOL_SIZE)

#endregion

#region Firing
func fire(from_position: Vector2, direction: Vector2, color: Color) -> void:
	"""Fire a tower bullet in the given direction"""
	var bullet = _get_pooled_bullet()

	if not bullet:
		# Pool exhausted, create new one
		bullet = TOWER_BULLET_SCENE.instantiate()

	# Setup bullet
	bullet.global_position = from_position
	bullet.set_velocity(direction, _tower_data.bullet_speed)
	bullet.set_color(color)
	bullet.set_lifetime(_tower_data.bullet_lifetime)

	# Add to scene if not already added
	if bullet.get_parent() == null:
		get_tree().current_scene.add_child(bullet)
	else:
		bullet.show()

	# Enable processing
	bullet.set_process(true)
	bullet.set_physics_process(true)

	# Connect expiry signal
	if not bullet.expired.is_connected(_on_bullet_expired):
		bullet.expired.connect(_on_bullet_expired.bindv([bullet]))

	# Track active bullet
	_active_bullets.append(bullet)

	# Emit signal
	tower_bullet_fired.emit(bullet, from_position, direction)

#endregion

#region Pooling
func _get_pooled_bullet() -> Node2D:
	"""Get a bullet from the pool"""
	if _bullet_pool.is_empty():
		return null
	return _bullet_pool.pop_back()

func _on_bullet_expired(bullet: Node2D) -> void:
	"""Handle bullet expiry - return to pool"""
	_active_bullets.erase(bullet)
	bullet.set_process(false)
	bullet.set_physics_process(false)
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

#endregion
