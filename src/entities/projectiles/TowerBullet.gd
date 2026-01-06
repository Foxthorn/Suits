class_name TowerBullet
extends Area2D
## Tower-fired projectile with collision detection and damage
## Similar to player Bullet but with distinct color for visual feedback
## Poolable - resets state when returned to pool

#region Signals
signal hit_enemy(enemy: BaseEnemy, damage: float)
signal expired()

#endregion

#region Exported Properties
@export var lifetime: float = ProjectileConfig.TOWER_BULLET_LIFETIME

#endregion

#region Private Variables
var _velocity: Vector2 = Vector2.ZERO
var _speed: float = ProjectileConfig.TOWER_BULLET_SPEED
var _damage: float = ProjectileConfig.TOWER_BULLET_DAMAGE
var _lifetime_remaining: float = 0.0
var _color: Color = ProjectileConfig.TOWER_BULLET_COLOR
var _sprite: Sprite2D
var _has_hit: bool = false

#endregion

#region Lifecycle
func _ready() -> void:
	# Setup collision layers
	collision_layer = GameConfig.COLLISION_LAYER_PLAYER_PROJECTILES
	collision_mask = GameConfig.COLLISION_MASK_PLAYER_PROJECTILES

	# Create sprite if not present
	if not _sprite:
		_sprite = Sprite2D.new()
		add_child(_sprite)
		_sprite.texture = _create_placeholder_texture(8, 8, _color)

	# Connect to collision detection
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	_lifetime_remaining = lifetime

func _physics_process(delta: float) -> void:
	# Update position
	global_position += _velocity * delta

	# Update lifetime
	_lifetime_remaining -= delta
	if _lifetime_remaining <= 0:
		_expire()

#endregion

#region Collision & Damage
func _on_area_entered(area: Node2D) -> void:
	"""Handle collision with enemy"""
	if _has_hit:
		return

	if area is BaseEnemy:
		var enemy = area as BaseEnemy
		_hit_enemy(enemy)

func _hit_enemy(enemy: BaseEnemy) -> void:
	"""Apply damage to enemy and create hit effect"""
	_has_hit = true

	enemy.take_damage(_damage)
	hit_enemy.emit(enemy, _damage)

	# Visual feedback: impact particles
	_create_impact_particles()

	# Expire bullet
	_expire()

func _create_impact_particles() -> void:
	"""Spawn particle effect on hit"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.amount = ProjectileConfig.TOWER_BULLET_HIT_PARTICLES
	particles.lifetime = ProjectileConfig.TOWER_BULLET_HIT_PARTICLE_LIFETIME
	particles.initial_velocity_min = ProjectileConfig.TOWER_BULLET_HIT_PARTICLE_SPEED_MIN
	particles.initial_velocity_max = ProjectileConfig.TOWER_BULLET_HIT_PARTICLE_SPEED_MAX
	particles.scale_amount_min = ProjectileConfig.TOWER_BULLET_HIT_PARTICLE_SCALE_MIN
	particles.scale_amount_max = ProjectileConfig.TOWER_BULLET_HIT_PARTICLE_SCALE_MAX
	particles.angle_min = 0
	particles.angle_max = 360
	particles.modulate = _color

	get_tree().current_scene.add_child(particles)

	# Use Timer instead of await to prevent execution after bullet returns to pool
	var cleanup_timer = Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = ProjectileConfig.TOWER_BULLET_HIT_PARTICLE_LIFETIME + 0.1
	particles.add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.queue_free()
	)
	cleanup_timer.start()

#endregion

#region Pooling & Lifecycle
func reset() -> void:
	"""Reset bullet state for pooling"""
	_velocity = Vector2.ZERO
	_has_hit = false
	_lifetime_remaining = lifetime

func prepare() -> void:
	"""Prepare bullet for reuse from pool"""
	show()
	_has_hit = false
	_lifetime_remaining = lifetime

func set_velocity(direction: Vector2, speed: float = ProjectileConfig.TOWER_BULLET_SPEED) -> void:
	"""Set bullet velocity"""
	_speed = speed
	_velocity = direction * _speed

func set_color(color: Color) -> void:
	"""Set bullet color and sprite"""
	_color = color
	if _sprite:
		_sprite.modulate = color

func set_damage(damage: float) -> void:
	"""Set bullet damage"""
	_damage = damage

func set_lifetime(duration: float) -> void:
	"""Set bullet lifetime"""
	lifetime = duration
	_lifetime_remaining = duration

func _expire() -> void:
	"""Mark bullet as expired and return to pool"""
	expired.emit()

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

#endregion
