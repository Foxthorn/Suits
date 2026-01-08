class_name WeaponSystem
extends Node
## Manages mech weapon firing, cooldowns, and projectile spawning
##
## Responsible for:
## - Fire rate management and cooldowns
## - Spawning bullets in the correct direction
## - Damage upgrades integration
## - Projectiles self-destruct after collision (no pooling)

#region Signals
## Emitted when a bullet is fired
signal bullet_fired(bullet: Bullet, position: Vector2, direction: Vector2)

## Emitted when fire rate cooldown starts
signal cooldown_started(cooldown_time: float)

#endregion

#region Exports
@export var bullet_scene: PackedScene = preload("res://scenes/entities/projectiles/Bullet.tscn")
@export var damage_multiplier: float = 1.0  # For upgrades

#endregion

#region Private Variables
var _fire_cooldown: float = 0.0
var _damage_base: float = WeaponConfig.WEAPON_DAMAGE
var _bullets_container: Node  # Container for active bullets
var debug_draw: bool = false

#endregion

#region Lifecycle
func _ready() -> void:
	# Create a container for bullets under this node
	_bullets_container = Node.new()
	_bullets_container.name = "ActiveBullets"
	add_child(_bullets_container)

	if self.debug_draw:
		print("[WeaponSystem] Initialized")

func _physics_process(delta: float) -> void:
	# Update fire cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta

#endregion



#region Firing
## Fire a bullet in the given direction
func fire(from_position: Vector2, direction: Vector2) -> void:
	# Check if we can fire (cooldown)
	if not can_fire():
		return

	# Instantiate new bullet
	var bullet = bullet_scene.instantiate() as Bullet
	_bullets_container.add_child(bullet)

	# Set up bullet
	bullet.global_position = from_position
	bullet.damage = _damage_base * self.damage_multiplier
	bullet.set_velocity(direction, WeaponConfig.BULLET_SPEED)

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
