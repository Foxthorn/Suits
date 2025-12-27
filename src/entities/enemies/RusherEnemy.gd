extends BaseEnemy
## Rusher enemy type: Fast melee attacker that charges at mech
## Rushes at mech at high speed, deals damage on collision

#region Variables
var _last_collision_time: float = 0.0

#endregion

#region Initialization
func _ready() -> void:
	self.enemy_type = EnemyConfig.EnemyType.RUSHER
	self.speed = EnemyConfig.RUSHER_SPEED
	self.max_health = EnemyConfig.RUSHER_MAX_HP
	self.damage = EnemyConfig.RUSHER_DAMAGE

	super._ready()


#endregion

#region Physics & Collision
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Check collision with mech for damage
	var colliding_bodies = self.get_colliding_bodies()
	for body in colliding_bodies:
		if body.is_in_group("player_mech"):
			_damage_mech(body, delta)


func _damage_mech(mech: Node2D, delta: float) -> void:
	"""Deal damage to mech on collision"""
	var current_time: float = Time.get_ticks_msec() / 1000.0

	# Only damage once per cooldown
	if current_time - _last_collision_time < EnemyConfig.RUSHER_COLLISION_COOLDOWN:
		return

	_last_collision_time = current_time

	# Call take_damage if mech has that method
	if mech.has_method("take_damage"):
		mech.take_damage(self.damage)
		print("RusherEnemy: Damaged mech for %.0f damage" % self.damage)

#endregion
