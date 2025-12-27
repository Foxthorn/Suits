class_name ShooterEnemy
extends BaseEnemy
## Shooter enemy type: Ranged attacker that fires projectiles at mech
## Maintains distance and shoots at player from range

#region Variables
var _fire_timer: float = 0.0
var _mech_in_range: bool = false
var _detection_range: float = EnemyConfig.SHOOTER_PROJECTILE_RANGE

#endregion

#region Initialization
func _ready() -> void:
	self.enemy_type = EnemyConfig.EnemyType.SHOOTER
	self.speed = EnemyConfig.SHOOTER_SPEED
	self.max_health = EnemyConfig.SHOOTER_MAX_HP

	super._ready()


#endregion

#region Physics & Combat
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not self.is_alive:
		return

	# Update fire timer
	_fire_timer += delta

	# Check if mech is in range
	if _mech_target and is_instance_valid(_mech_target):
		var distance: float = self.global_position.distance_to(_mech_target.global_position)
		_mech_in_range = distance <= _detection_range

		# Fire at mech if timer is ready
		if _mech_in_range and _fire_timer >= EnemyConfig.SHOOTER_FIRE_RATE:
			_fire_at_mech()
			_fire_timer = 0.0


func _fire_at_mech() -> void:
	"""Shoot a projectile at the mech"""
	# For now, just print that we're firing
	# TODO: Spawn actual projectile when we implement bullets
	print("ShooterEnemy: Firing at mech from distance %.0f" % self.global_position.distance_to(_mech_target.global_position))

	# Visual feedback: quick color flash
	var tween = create_tween()
	tween.tween_property(self.sprite, "modulate", Color.YELLOW, 0.05)
	tween.tween_property(self.sprite, "modulate", Color.WHITE, 0.05)

#endregion
