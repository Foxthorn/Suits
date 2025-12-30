class_name BaseEnemy extends CharacterBody2D
## Base class for all enemy types with sprite sheet animation
## Handles health, damage, pathfinding, animation states, and death

#region Signals
## Emitted when enemy dies
signal died(enemy: BaseEnemy)

## Emitted when health changes
signal health_changed(current_hp: float, max_hp: float)

## Emitted when animation state changes
signal animation_state_changed(new_state: AnimationState)

#endregion

#region Enums
enum AnimationState {
	IDLE,
	WALK,
	ATTACK,
	HIT,
	DEATH
}
#endregion

#region Exported Properties
@export var enemy_type: EnemyDatabase.EnemyType = EnemyDatabase.EnemyType.RUSHER
@export var debug_draw: bool = false

#endregion

#region Private Variables - Stats
var _speed: float = 0.0
var _max_health: float = 0.0
var _damage: float = 0.0
var _enemy_data: EnemyDatabase.EnemyData = null

#endregion

#region Variables - Health & State
var health: float = 0.0
var is_alive: bool = true
var _current_animation_state: AnimationState = AnimationState.IDLE
var _animation_timer: float = 0.0
var _animation_frame: int = 0

#endregion

#region Variables - Pathfinding & Movement
var target_position: Vector2 = Vector2.ZERO
var _current_path: PackedVector2Array = []
var _path_index: int = 0
var _mech_target: Node2D = null

#endregion

#region Nodes
var sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null
var projectile_detector: Area2D = null

#endregion

#region Animation Resources
var _idle_sprite: Texture2D = null
var _walk_sprite: Texture2D = null
var _attack_sprite: Texture2D = null
var _hit_sprite: Texture2D = null
var _death_sprite: Texture2D = null

# Per-animation frame counts (loaded from enemy database)
var _idle_frame_count: int = 4
var _walk_frame_count: int = 4
var _attack_frame_count: int = 5
var _hit_frame_count: int = 2
var _death_frame_count: int = 4

#endregion

#region Initialization
func _ready() -> void:
	# Load enemy data from database
	_enemy_data = EnemyDatabase.get_enemy(self.enemy_type)
	if not _enemy_data:
		push_error("BaseEnemy: Invalid enemy_type %d" % self.enemy_type)
		queue_free()
		return

	# Configure collision layers (Layer 3: enemies)
	collision_layer = 4  # Layer 3 = 2^2 = 4 in binary
	# Collision mask: detect world (1), player (2), towers (5)
	collision_mask = 0b0001_0111  # Binary: 0001_0111 = layers 1, 2, 5

	# Apply stats from database
	_speed = _enemy_data.speed
	_max_health = _enemy_data.max_health
	_damage = _enemy_data.damage
	self.health = _max_health

	# Allow debug_draw override from inspector
	if not self.debug_draw and _enemy_data.debug_draw:
		self.debug_draw = true

	_setup_visuals()
	_setup_collision()
	_load_animation_sprites()
	_acquire_target()

		# Debug collision configuration
	if self.debug_draw:
		print("[BaseEnemy] %s - Collision Layer 4 (enemies), Mask: 0b0001_0111 (world, player, towers) - HP: %.0f" % [_enemy_data.name, self.health])
		print("BaseEnemy: Spawned %s (HP: %.0f, Speed: %.0f)" % [_enemy_data.name, _max_health, _speed])


func _setup_visuals() -> void:
	"""Initialize sprite from enemy database"""
	sprite = Sprite2D.new()
	sprite.centered = true

	# Try to load idle sprite from EnemyData
	var idle_sprite_texture: Texture2D = _enemy_data.get_idle_sprite()
	if idle_sprite_texture:
		_setup_sprite_with_animation(idle_sprite_texture)
	else:
		# Fallback to placeholder if sprite fails to load
		sprite.texture = _create_placeholder_texture(32, 32, _enemy_data.color)

	sprite.scale = Vector2(EnemyConfig.IDLE_SCALE, EnemyConfig.IDLE_SCALE)
	add_child(sprite)


func _setup_collision() -> void:
	"""Initialize collision shapes for movement and projectile detection"""
	collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = EnemyConfig.COLLISION_RADIUS
	collision_shape.shape = circle
	add_child(collision_shape)

	# Setup projectile detector (Area2D for bullet collision)
	projectile_detector = Area2D.new()
	projectile_detector.name = "ProjectileDetector"
	projectile_detector.collision_layer = 4  # On layer 3 (bit 2)
	projectile_detector.collision_mask = 2   # Detect layer 2 (bullets)
	add_child(projectile_detector)

	# Add collision shape to detector
	var detector_shape = CollisionShape2D.new()
	var detector_circle = CircleShape2D.new()
	detector_circle.radius = EnemyConfig.COLLISION_RADIUS
	detector_shape.shape = detector_circle
	projectile_detector.add_child(detector_shape)

	# Connect projectile detector signals
	if not projectile_detector.area_entered.is_connected(_on_projectile_detector_hit):
		projectile_detector.area_entered.connect(_on_projectile_detector_hit)


func _load_animation_sprites() -> void:
	"""Load all animation sprite sheets and frame counts from database"""
	_idle_sprite = _enemy_data.get_idle_sprite()
	_walk_sprite = _enemy_data.get_walk_sprite()
	_attack_sprite = _enemy_data.get_attack_sprite()
	_hit_sprite = _enemy_data.get_hit_sprite()
	_death_sprite = _enemy_data.get_death_sprite()

	# Load per-animation frame counts from enemy data
	_idle_frame_count = _enemy_data.idle_frame_count
	_walk_frame_count = _enemy_data.walk_frame_count
	_attack_frame_count = _enemy_data.attack_frame_count
	_hit_frame_count = _enemy_data.hit_frame_count
	_death_frame_count = _enemy_data.death_frame_count


func _acquire_target() -> void:
	"""Find the mech in the scene"""
	_mech_target = get_tree().get_first_node_in_group("player_mech")
	if _mech_target == null:
		push_warning("BaseEnemy: Could not find mech target in group 'player_mech'")

#endregion

#region Sprite Setup
func _setup_sprite_with_animation(sprite_texture: Texture2D) -> void:
	"""Setup sprite with multi-frame animation from sprite sheet"""
	# All insect enemy sprites use horizontal sprite sheets with frames per animation
	sprite.texture = sprite_texture
	sprite.hframes = _idle_frame_count  # Default to idle frames, will change per animation
	sprite.vframes = 1  # Single row
	sprite.frame = 0  # Start at frame 0

	if self.debug_draw:
		print("BaseEnemy: Setup animation sprite for %s" % _enemy_data.name)

#endregion

#region Animation
func _set_animation_state(new_state: AnimationState) -> void:
	"""Change animation state and load appropriate sprite sheet"""
	if _current_animation_state == new_state:
		return

	_current_animation_state = new_state
	_animation_timer = 0.0
	_animation_frame = 0
	self.animation_state_changed.emit(new_state)

	# Switch sprite sheet based on state
	match new_state:
		AnimationState.IDLE:
			if _idle_sprite:
				sprite.texture = _idle_sprite
				sprite.hframes = _idle_frame_count
			sprite.frame = 0

		AnimationState.WALK:
			if _walk_sprite:
				sprite.texture = _walk_sprite
				sprite.hframes = _walk_frame_count
			sprite.frame = 0

		AnimationState.ATTACK:
			if _attack_sprite:
				sprite.texture = _attack_sprite
				sprite.hframes = _attack_frame_count
			sprite.frame = 0

		AnimationState.HIT:
			if _hit_sprite:
				sprite.texture = _hit_sprite
				sprite.hframes = _hit_frame_count
			sprite.frame = 0

		AnimationState.DEATH:
			if _death_sprite:
				sprite.texture = _death_sprite
				sprite.hframes = _death_frame_count
			sprite.frame = 0

	if self.debug_draw:
		var state_name: String = AnimationState.keys()[new_state]
		print("BaseEnemy: %s animation state changed to %s" % [_enemy_data.name, state_name])


func _update_sprite_direction(direction: Vector2) -> void:
	"""Flip sprite based on movement direction"""
	if direction.x != 0:  # Only flip if moving horizontally
		sprite.flip_h = direction.x > 0  # Flip right if moving right


func _update_animation(delta: float) -> void:
	"""Update animation frame based on timer"""
	_animation_timer += delta

	if _animation_timer >= EnemyConfig.ANIMATION_SPEED:
		_animation_timer = 0.0
		_animation_frame += 1

		# Wrap frame based on current animation
		var max_frames: int = 0
		match _current_animation_state:
			AnimationState.IDLE:
				max_frames = _idle_frame_count
			AnimationState.WALK:
				max_frames = _walk_frame_count
			AnimationState.ATTACK:
				max_frames = _attack_frame_count
			AnimationState.HIT:
				max_frames = _hit_frame_count
			AnimationState.DEATH:
				max_frames = _death_frame_count

		if _animation_frame >= max_frames:
			_animation_frame = 0  # Loop animation

		if sprite:
			sprite.frame = _animation_frame

#endregion

#region Health & Damage
## Take damage and check if dead
func take_damage(amount: float) -> void:
	if not self.is_alive:
		if self.debug_draw:
			print("[BaseEnemy] %s already dead, ignoring damage" % _enemy_data.name)
		return

	var old_health: float = self.health
	self.health -= amount
	self.health_changed.emit(self.health, _max_health)

		# Play hit animation
	_set_animation_state(AnimationState.HIT)

	if self.debug_draw:
		print("[BaseEnemy] %s took %.0f damage! HP: %.0f → %.0f (alive: %s)" % [_enemy_data.name, amount, old_health, self.health, self.is_alive])

	if self.health <= 0:
		if self.debug_draw:
			print("[BaseEnemy] %s is now DEAD (HP: %.0f)" % [_enemy_data.name, self.health])
		die()


## Kill the enemy and emit signals
func die() -> void:
	if not self.is_alive:
		if self.debug_draw:
			print("[BaseEnemy] %s already dead, ignoring die() call" % _enemy_data.name)
		return

	is_alive = false
	died.emit(self)
	_set_animation_state(AnimationState.DEATH)

	# Wait for death animation to finish before cleanup
	var death_duration: float = _death_frame_count * EnemyConfig.ANIMATION_SPEED
	await get_tree().create_timer(death_duration).timeout

	_spawn_death_particles()

	queue_free()  # Clean up enemy after death animation


func _spawn_death_particles() -> void:
	"""Spawn particle effect on death"""
	# Simple particle effect: small circles spreading outward
	var particle_count: int = EnemyConfig.DEATH_PARTICLE_COUNT
	var particles: Array[Node2D] = []

	# Create all particles in parallel (not sequential)
	for i in range(particle_count):
		var angle: float = (TAU / particle_count) * i
		var particle = _create_particle(_enemy_data.color, angle)
		# Add null safety check: only add particles if parent exists
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(particle)
		else:
			# Fallback: add to scene root if parent is null
			var scene_root = get_tree().current_scene
			if scene_root:
				scene_root.add_child(particle)
		particles.append(particle)


func _create_particle(color: Color, direction_angle: float) -> Node2D:
	"""Create a simple moving particle"""
	var particle = Node2D.new()
	particle.global_position = global_position

	var particle_sprite = Sprite2D.new()
	particle_sprite.texture = _create_placeholder_texture(8, 8, color)
	particle.add_child(particle_sprite)

	# Tween particle movement and fade (non-blocking)
	var tween = create_tween()
	var particle_speed: float = randf_range(EnemyConfig.DEATH_PARTICLE_MIN_SPEED, EnemyConfig.DEATH_PARTICLE_MAX_SPEED)
	var lifetime: float = EnemyConfig.DEATH_PARTICLE_LIFETIME
	var target_pos: Vector2 = particle.global_position + Vector2(cos(direction_angle), sin(direction_angle)) * particle_speed * lifetime

	tween.parallel()
	tween.tween_property(particle, "global_position", target_pos, lifetime)
	tween.tween_property(particle_sprite, "modulate:a", 0.0, lifetime)

	# Non-blocking: particle cleans itself up after tween finishes
	tween.tween_callback(particle.queue_free)

	return particle

#endregion

#region Movement & Pathfinding
func _physics_process(delta: float) -> void:
	if not self.is_alive:
		return

	_update_animation(delta)
	_update_target()
	_move_toward_target(delta)


func _update_target() -> void:
	"""Update movement target (mech position or waypoint)"""
	if _mech_target == null or not is_instance_valid(_mech_target):
		_acquire_target()
		return

	target_position = _mech_target.global_position


func _move_toward_target(delta: float) -> void:
	"""Move directly toward target and update animation state"""
	var direction: Vector2 = (target_position - global_position).normalized()
	velocity = direction * _speed
	move_and_slide()

	# Flip sprite based on direction
	_update_sprite_direction(direction)

	# Update animation state based on movement (but not if in attack/hit states)
	# Allow subclasses to override animation (e.g., attack animations)
	if _current_animation_state != AnimationState.ATTACK and _current_animation_state != AnimationState.HIT:
		if velocity.length() > EnemyConfig.MOVEMENT_THRESHOLD:  # Moving
			_set_animation_state(AnimationState.WALK)
		else:  # Idle
			_set_animation_state(AnimationState.IDLE)

#endregion

#region Projectile Detection
func _on_projectile_detector_hit(area: Node2D) -> void:
	"""Handle collision with projectiles (triggered from projectile_detector Area2D)"""
	# The area hitting us should be a Bullet
	if area is Bullet:
		if self.debug_draw:
			print("[BaseEnemy] %s detected projectile hit from Bullet" % _enemy_data.name)

#endregion

#region Utilities
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored rectangle texture (fallback)"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func get_enemy_type() -> EnemyDatabase.EnemyType:
	"""Return this enemy's type"""
	return enemy_type


func get_health_percent() -> float:
	"""Get current health as percentage (0.0 to 1.0)"""
	if _max_health <= 0:
		return 0.0
	return clamp(health / _max_health, 0.0, 1.0)


## Format name with health for debugging
func _to_string() -> String:
	return "%s (HP: %.0f/%.0f)" % [_enemy_data.name if _enemy_data else "Unknown", health, _max_health]

#endregion
