class_name BaseEnemy
extends CharacterBody2D
## Base class for all enemy types
## Handles health, damage, pathfinding, and death

#region Signals
## Emitted when enemy dies
signal died(enemy: BaseEnemy)

## Emitted when health changes
signal health_changed(current_hp: float, max_hp: float)

#endregion

#region Exported Properties
@export var enemy_type: EnemyConfig.EnemyType = EnemyConfig.EnemyType.RUSHER
@export var speed: float = EnemyConfig.RUSHER_SPEED
@export var max_health: float = EnemyConfig.RUSHER_MAX_HP
@export var damage: float = EnemyConfig.RUSHER_DAMAGE

#endregion

#region Variables - Health & State
var health: float
var is_alive: bool = true

#endregion

#region Variables - Pathfinding & Movement
var target_position: Vector2 = Vector2.ZERO
var _current_path: PackedVector2Array = []
var _path_index: int = 0
var _mech_target: Node2D = null

#endregion

#region Nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

#endregion

#region Initialization
func _ready() -> void:
	self.health = self.max_health
	_setup_visuals()
	_setup_collision()
	_acquire_target()


func _setup_visuals() -> void:
	"""Initialize sprite with fallback color"""
	if self.sprite == null:
		self.sprite = Sprite2D.new()
		add_child(self.sprite)

	# Use fallback colored rectangle
	var fallback_color: Color = EnemyConfig.RUSHER_COLOR if self.enemy_type == EnemyConfig.EnemyType.RUSHER else EnemyConfig.SHOOTER_COLOR
	self.sprite.texture = _create_placeholder_texture(32, 32, fallback_color)


func _setup_collision() -> void:
	"""Initialize collision shape"""
	if self.collision_shape == null:
		self.collision_shape = CollisionShape2D.new()
		add_child(self.collision_shape)

	var circle = CircleShape2D.new()
	circle.radius = EnemyConfig.COLLISION_RADIUS
	self.collision_shape.shape = circle


func _acquire_target() -> void:
	"""Find the mech in the scene"""
	_mech_target = get_tree().get_first_node_in_group("player_mech")
	if _mech_target == null:
		push_warning("BaseEnemy: Could not find mech target in group 'player_mech'")

#endregion

#region Health & Damage
## Take damage and check if dead
func take_damage(amount: float) -> void:
	if not self.is_alive:
		return

	self.health -= amount
	self.health_changed.emit(self.health, self.max_health)

	if self.health <= 0:
		self.die()


## Kill the enemy and emit signals
func die() -> void:
	if not self.is_alive:
		return

	self.is_alive = false
	self.died.emit(self)
	_spawn_death_particles()
	queue_free()


func _spawn_death_particles() -> void:
	"""Spawn particle effect on death"""
	# Simple particle effect: small circles spreading outward
	var particle_count: int = EnemyConfig.DEATH_PARTICLE_COUNT
	var fallback_color: Color = EnemyConfig.RUSHER_COLOR if self.enemy_type == EnemyConfig.EnemyType.RUSHER else EnemyConfig.SHOOTER_COLOR

	for i in range(particle_count):
		var angle: float = (TAU / particle_count) * i
		var particle = await _create_particle(fallback_color, angle)
		get_parent().add_child(particle)


func _create_particle(color: Color, direction_angle: float) -> Node2D:
	"""Create a simple moving particle"""
	var particle = Node2D.new()
	particle.global_position = self.global_position

	var sprite = Sprite2D.new()
	sprite.texture = _create_placeholder_texture(8, 8, color)
	particle.add_child(sprite)

	# Tween particle movement and fade
	var tween = create_tween()
	var speed: float = randf_range(100.0, 200.0)
	var lifetime: float = 0.5
	var target_pos: Vector2 = particle.global_position + Vector2(cos(direction_angle), sin(direction_angle)) * speed * lifetime

	tween.parallel()
	tween.tween_property(particle, "global_position", target_pos, lifetime)
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)

	await tween.finished
	particle.queue_free()

	return particle

#endregion

#region Movement & Pathfinding
func _physics_process(delta: float) -> void:
	if not self.is_alive:
		return

	_update_target()
	_move_toward_target(delta)


func _update_target() -> void:
	"""Update movement target (mech position or waypoint)"""
	if _mech_target == null or not is_instance_valid(_mech_target):
		_acquire_target()
		return

	self.target_position = _mech_target.global_position


func _move_toward_target(delta: float) -> void:
	"""Move directly toward target (simple pathfinding for now)"""
	var direction: Vector2 = (self.target_position - self.global_position).normalized()
	self.velocity = direction * self.speed
	self.move_and_slide()


#endregion

#region Utilities
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored rectangle texture"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func get_enemy_type() -> EnemyConfig.EnemyType:
	"""Return this enemy's type"""
	return self.enemy_type


## Format name with health for debugging
func _to_string() -> String:
	return "%s (HP: %.0f/%.0f)" % [EnemyConfig.RUSHER_NAME if self.enemy_type == EnemyConfig.EnemyType.RUSHER else EnemyConfig.SHOOTER_NAME, self.health, self.max_health]

#endregion
