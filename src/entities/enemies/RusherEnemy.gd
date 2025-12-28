class_name RusherEnemy
extends BaseEnemy
## Rusher enemy type: Fast melee attacker that charges at mech
## Rushes at mech at high speed using sprite sheet animation, deals damage on collision

#region Variables
var _last_collision_time: float = 0.0

#endregion

#region Initialization
func _ready() -> void:
	# Set enemy type before calling parent _ready()
	self.enemy_type = EnemyDatabase.EnemyType.RUSHER
	super._ready()

#endregion

#region Physics & Collision
func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Update movement and animation (includes move_and_slide)
	super._physics_process(delta)

	# Check collision with mech for damage (after move_and_slide)
	# for body in get_colliding_bodies():
	# 	if body.is_in_group("player_mech"):
	# 		_damage_mech(body, delta)


func _damage_mech(mech: Node2D, delta: float) -> void:
	"""Deal damage to mech on collision"""
	var current_time: float = Time.get_ticks_msec() / 1000.0

	# Only damage once per cooldown
	if current_time - _last_collision_time < EnemyConfig.RUSHER_COLLISION_COOLDOWN:
		return

	_last_collision_time = current_time

	# Play attack animation
	_set_animation_state(AnimationState.ATTACK)

	# Call take_damage if mech has that method
	if mech.has_method("take_damage"):
		mech.take_damage(_damage)
		mech.take_damage(self._damage)
		if self.debug_draw:

			print("RusherEnemy: Damaged mech for %.0f damage" % self._damage)

#endregion
