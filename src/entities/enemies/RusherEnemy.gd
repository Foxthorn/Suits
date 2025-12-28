class_name RusherEnemy
extends BaseEnemy
## Rusher enemy type: Fast melee attacker that charges at mech
## Rushes at mech at high speed using sprite sheet animation, deals damage on collision

#region Variables
var _last_collision_time: float = 0.0
var _attack_timer: float = 0.0

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

	# Decrement attack timer
	if _attack_timer > 0:
		_attack_timer -= delta

	# Update movement and animation (includes move_and_slide)
	# This will handle animation state, but we'll override if in attack
	super._physics_process(delta)

	# Check collision with mech for damage (after move_and_slide)
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider().is_in_group("player_mech"):
			_damage_mech(collision.get_collider(), delta)

	# Keep attack animation active for its duration, then revert to movement state
	if _attack_timer > 0:
		_set_animation_state(AnimationState.ATTACK)
	elif _current_animation_state == AnimationState.ATTACK:
		# Attack animation finished, revert to idle/walk based on movement
		if velocity.length() > EnemyConfig.MOVEMENT_THRESHOLD:
			_set_animation_state(AnimationState.WALK)
		else:
			_set_animation_state(AnimationState.IDLE)


func _damage_mech(mech: Node2D, delta: float) -> void:
	"""Deal damage to mech on collision"""
	var current_time: float = Time.get_ticks_msec() / 1000.0

	# Only damage once per cooldown
	if current_time - _last_collision_time < EnemyConfig.RUSHER_COLLISION_COOLDOWN:
		return

	_last_collision_time = current_time

	# Play attack animation for its full duration
	_set_animation_state(AnimationState.ATTACK)
	_attack_timer = _attack_frame_count * EnemyConfig.ANIMATION_SPEED

	# Call take_damage if mech has that method
	if mech.has_method("take_damage"):
		mech.take_damage(_damage)
		if self.debug_draw:
			print("RusherEnemy: Damaged mech for %.0f damage" % _damage)

#endregion
