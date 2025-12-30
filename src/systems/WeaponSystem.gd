class_name WeaponSystem
extends Node
## Manages mech weapon firing, cooldowns, and projectile pooling
##
## Responsible for:
## - Fire rate management and cooldowns
## - Projectile pooling for performance
## - Spawning bullets in the correct direction
## - Damage upgrades integration

#region Signals
## Emitted when a bullet is fired
signal bullet_fired(bullet: Bullet, position: Vector2, direction: Vector2)

## Emitted when fire rate cooldown starts
signal cooldown_started(cooldown_time: float)

#endregion

#region Exports
@export var bullet_scene: PackedScene = preload("res://scenes/entities/projectiles/Bullet.tscn")
@export var pool_size: int = 50  # Number of bullets to pre-allocate
@export var damage_multiplier: float = 1.0  # For upgrades

#endregion

#region Private Variables
var _bullet_pool: Array[Bullet] = []
var _fire_cooldown: float = 0.0
var _damage_base: float = WeaponConfig.WEAPON_DAMAGE
var _bullets_container: Node  # Container for active bullets
var _signal_connections: Dictionary = {}  # Track signal connections to avoid duplicates
var debug_draw: bool = false

#endregion

#region Lifecycle
func _ready() -> void:
	# Create a container for bullets under this node
	_bullets_container = Node.new()
	_bullets_container.name = "ActiveBullets"
	add_child(_bullets_container)

	# Pre-allocate bullet pool
	_initialize_pool()

	if self.debug_draw:
		print("[WeaponSystem] Initialized with %d bullets in pool" % self.pool_size)

func _physics_process(delta: float) -> void:
	# Update fire cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta

#endregion

#region Pool Management
func _initialize_pool() -> void:
	"""Pre-allocate bullets for pooling"""
	_bullet_pool.clear()
	_signal_connections.clear()

	for i in range(pool_size):
		var bullet = bullet_scene.instantiate() as Bullet
		bullet.reset()
		_bullets_container.add_child(bullet)
		_bullet_pool.append(bullet)

		# Pre-connect signal once during pool initialization
		if not _signal_connections.has(bullet):
			bullet.expired.connect(_on_bullet_expired.bind(bullet))
			_signal_connections[bullet] = true

func _get_bullet_from_pool() -> Bullet:
	"""Get an available bullet from the pool or create new one"""
	if _bullet_pool.is_empty():
		# Create new bullet if pool is exhausted
		var bullet = bullet_scene.instantiate() as Bullet
		_bullets_container.add_child(bullet)

		# Connect signal for newly created bullets
		if not _signal_connections.has(bullet):
			bullet.expired.connect(_on_bullet_expired.bind(bullet))
			_signal_connections[bullet] = true

		return bullet

	var bullet = _bullet_pool.pop_back()
	bullet.prepare()
	return bullet

func _return_bullet_to_pool(bullet: Bullet) -> void:
	"""Return bullet to pool after use"""
	bullet.reset()
	_bullet_pool.append(bullet)

#endregion

#region Firing
## Fire a bullet in the given direction
func fire(from_position: Vector2, direction: Vector2) -> void:
	# Check if we can fire (cooldown)
	if not can_fire():
		return

	# Get bullet from pool
	var bullet = _get_bullet_from_pool()

	# Set up bullet
	bullet.global_position = from_position
	bullet.damage = _damage_base * self.damage_multiplier
	bullet.set_velocity(direction, WeaponConfig.BULLET_SPEED)

	# Signal connection is established during pool initialization
	# No need to reconnect each time

	# Start cooldown
	_fire_cooldown = WeaponConfig.WEAPON_FIRE_RATE
	self.bullet_fired.emit(bullet, from_position, direction)

	if self.debug_draw:
		print("[WeaponSystem] Fired bullet from %s in direction %s" % [from_position, direction])

## Check if weapon is ready to fire
func can_fire() -> bool:
	return _fire_cooldown <= 0.0

## Get remaining cooldown time
func get_cooldown_remaining() -> float:
	return max(0.0, _fire_cooldown)

## Get fire rate (shots per second)
func get_fire_rate() -> float:
	return 1.0 / WeaponConfig.WEAPON_FIRE_RATE if WeaponConfig.WEAPON_FIRE_RATE > 0 else 0.0

#endregion

#region Upgrades
## Apply damage upgrade
func upgrade_damage(bonus: float) -> void:
	_damage_base += bonus
	if self.debug_draw:
		print("[WeaponSystem] Damage upgraded to %.1f (bonus: %.1f)" % [_damage_base, bonus])

## Set damage multiplier (for percentage upgrades)
func set_damage_multiplier(multiplier: float) -> void:
	self.damage_multiplier = multiplier
	if self.debug_draw:
		print("[WeaponSystem] Damage multiplier set to %.2f" % multiplier)

## Get current effective damage
func get_current_damage() -> float:
	return _damage_base * self.damage_multiplier

#endregion

#region Callbacks
func _on_bullet_expired(bullet: Bullet) -> void:
	"""Called when a bullet expires, return it to pool"""
	_return_bullet_to_pool(bullet)

#endregion
