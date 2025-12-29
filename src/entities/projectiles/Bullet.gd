class_name Bullet
extends Area2D
## Mech projectile - travels in straight line, damages enemies on hit
##
## Part of the weapon system (Step 7). Reuses bullets via object pooling.
## Each bullet tracks its age for lifetime management.

#region Signals
## Emitted when bullet hits a valid target
signal hit_enemy(enemy: BaseEnemy, damage: float)

## Emitted when bullet expires (lifetime reached)
signal expired()

#endregion

#region Exports
@export var damage: float = WeaponConfig.WEAPON_DAMAGE
@export var speed: float = WeaponConfig.BULLET_SPEED
@export var lifetime: float = WeaponConfig.BULLET_LIFETIME
@export var debug_draw: bool = false

#endregion

#region Private Variables
var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _hit_targets: Array[Node] = []  # Track what we've already hit to avoid double-hits

#endregion

#region Lifecycle
func _ready() -> void:
	# Ensure collision detection is set up
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if self.debug_draw:
		print("[Bullet] Spawned at position: ", global_position, " with velocity: ", _velocity)

func _physics_process(delta: float) -> void:
	if not visible:
		return

	# Move bullet
	global_position += _velocity * delta

	# Track age for lifetime management
	_age += delta

	# Check if expired
	if _age >= self.lifetime:
		_expire()
		return

	if self.debug_draw and _age > self.lifetime * 0.9:
		print("[Bullet] Expiring soon, age: %.2f/%.2f" % [_age, self.lifetime])

func _process(_delta: float) -> void:
	if self.debug_draw:
		queue_redraw()

#endregion

#region Collision & Damage
func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with enemies or obstacles"""

	# Skip if we've already hit this target
	if area in _hit_targets:
		return

	# Check if this is an enemy
	if area is BaseEnemy:
		var enemy: BaseEnemy = area as BaseEnemy
		_hit_targets.append(area)

		# Deal damage
		enemy.take_damage(self.damage)
		self.hit_enemy.emit(enemy, self.damage)

		if self.debug_draw:
			print("[Bullet] Hit enemy: ", enemy.name, " for ", self.damage, " damage")

		# Create hit effect
		_create_hit_effect(area.global_position)

		# Destroy bullet after hit
		_expire()

#endregion

#region Setup & Pooling
## Set bullet velocity and direction (call this after instantiation)
func set_velocity(direction: Vector2, spd: float = WeaponConfig.BULLET_SPEED) -> void:
	_velocity = direction.normalized() * spd

## Set bullet velocity directly from angle
func set_velocity_from_angle(angle: float, spd: float = WeaponConfig.BULLET_SPEED) -> void:
	_velocity = Vector2.from_angle(angle) * spd

## Reset bullet for reuse in pool
func reset() -> void:
	_age = 0.0
	_velocity = Vector2.ZERO
	_hit_targets.clear()
	visible = false
	set_physics_process(false)

## Prepare bullet for firing (called when retrieving from pool)
func prepare() -> void:
	_age = 0.0
	_hit_targets.clear()
	visible = true
	set_physics_process(true)

#endregion

#region Effects & Cleanup
func _create_hit_effect(position: Vector2) -> void:
	"""Spawn particle effect at impact point"""
	# Create a simple particle effect
	var particles = CPUParticles2D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = WeaponConfig.HIT_PARTICLE_LIFETIME
	particles.amount = WeaponConfig.HIT_PARTICLE_COUNT
	particles.initial_velocity_min = WeaponConfig.HIT_PARTICLE_SPEED
	particles.initial_velocity_max = WeaponConfig.HIT_PARTICLE_SPEED
	particles.angle_min = 0.0
	particles.angle_max = TAU

	# Visual appearance
	particles.modulate = WeaponConfig.BULLET_COLOR
	particles.scale = Vector2(0.5, 0.5)

	# Add to scene and auto-cleanup
	get_parent().add_child(particles)
	await get_tree().create_timer(WeaponConfig.HIT_PARTICLE_LIFETIME).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _expire() -> void:
	"""Bullet lifetime ended - clean up"""
	if self.debug_draw:
		print("[Bullet] Expired after %.2f seconds at position: %s" % [_age, global_position])

	self.expired.emit()
	reset()
	# Bullet will be returned to pool by WeaponSystem or auto queue_free

#endregion

#region Debug Visualization
func _draw() -> void:
	if not self.debug_draw or not visible:
		return

	# Draw bullet radius
	draw_circle(Vector2.ZERO, WeaponConfig.BULLET_RADIUS, WeaponConfig.BULLET_COLOR)

	# Draw velocity vector
	if _velocity.length() > 0:
		var velocity_visual = _velocity.normalized() * 30
		draw_line(Vector2.ZERO, velocity_visual, Color.WHITE, 2.0)

#endregion
