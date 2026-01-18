class_name MechController
extends CharacterBody2D
## Player-controlled mech with movement, rotation, and health management
##
## WASD controls for movement, mouse aim for rotation.
## Health system with signals for damage/death events.

#region Signals
## Emitted when mech takes damage
signal health_changed(current_health: float, max_health: float)

## Emitted when mech health reaches zero
signal died()

## Emitted when mech position changes significantly (for camera follow)
signal position_changed(new_position: Vector2)

#endregion

#region Exports
@export_group("Movement")
## Movement speed in pixels per second
@export var move_speed: float = GameConfig.MECH_MOVE_SPEED

## Current health (set on ready)
@export var current_health: float = GameConfig.MECH_STARTING_HEALTH

## Whether to use smooth rotation (false = instant snap to mouse)
@export var smooth_rotation: bool = false

## Rotation lerp speed (only used if smooth_rotation is true)
@export var rotation_speed: float = 10.0

@export_group("Health")
## Maximum health points
@export var max_health: float = GameConfig.MECH_MAX_HEALTH

@export_group("Weapon")
## Weapon system for managing firing
@export var weapon_system: WeaponSystem



#endregion

#region Private Variables
var _is_alive: bool = true
var _last_position: Vector2 = Vector2.ZERO
var _mouse_direction: Vector2 = Vector2.ZERO  # Cache mouse direction for weapon aiming

#endregion

#region Initialization
func _ready() -> void:
	# Configure collision layers (Layer 2: player)
	collision_layer = GameConfig.COLLISION_LAYER_PLAYER
	# Collision mask: detect world (1), enemies (3), enemy_projectiles (4)
	collision_mask = GameConfig.COLLISION_MASK_MECH

	# Initialize health
	self.current_health = min(self.current_health, self.max_health)
	_last_position = global_position

	# Create weapon system if not assigned
	if not self.weapon_system:
		self.weapon_system = WeaponSystem.new()
		add_child(self.weapon_system)

	# Emit initial health state
	self.health_changed.emit(self.current_health, self.max_health)

	if GameConfig.DEBUG_MODE:
		print("MechController: Collision Layer %d (Layer 2 - player), Mask: %d (detects world, enemies, enemy_projectiles)" % [collision_layer, collision_mask])
		print("MechController: Initialized at position ", global_position)
		print("MechController: Weapon system ready")


func _process(_delta: float) -> void:
	if GameConfig.DEBUG_MODE:
		queue_redraw()

func _physics_process(delta: float) -> void:
	if not _is_alive:
		return

	_handle_movement(delta)
	_handle_rotation(delta)
	_handle_weapon()

	# Emit position change if moved significantly
	if global_position.distance_squared_to(_last_position) > 100.0:  # ~10 pixels
		self.position_changed.emit(global_position)
		_last_position = global_position

#endregion

#region Movement & Rotation
func _handle_movement(_delta: float) -> void:
	var input_direction := Vector2.ZERO

	# Use input actions (defined in Project Settings → Input Map)
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1

	# Normalize to prevent faster diagonal movement
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()

	# Set velocity and move
	velocity = input_direction * self.move_speed
	move_and_slide()

func _handle_rotation(delta: float) -> void:
	# Get mouse position in world space
	var mouse_pos: Vector2 = get_global_mouse_position()
	_mouse_direction = global_position.direction_to(mouse_pos)  # Cache for weapon aiming
	var target_rotation: float = _mouse_direction.angle()

	if self.smooth_rotation:
		# Smooth lerp rotation
		rotation = lerp_angle(rotation, target_rotation, self.rotation_speed * delta)
	else:
		# Instant snap to mouse
		rotation = target_rotation

func _handle_weapon() -> void:
	"""Handle weapon firing - supports continuous fire while holding fire button"""
	if not self.weapon_system:
		return

	# Check if fire button is held down
	if Input.is_action_pressed("fire"):
		# Attempt to fire - weapon handles cooldown check internally
		self.weapon_system.fire(global_position, _mouse_direction)

#endregion

#region Health Management
## Deal damage to the mech
func take_damage(amount: float) -> void:
	if not _is_alive:
		return

	self.current_health -= amount
	self.current_health = max(self.current_health, 0.0)

	self.health_changed.emit(self.current_health, self.max_health)

	if GameConfig.DEBUG_MODE:
		print("MechController: Took %.1f damage. Health: %.1f/%.1f" % [amount, self.current_health, self.max_health])

	# Check for death
	if self.current_health <= 0:
		_die()
	else:
		_flash_damage()

## Heal the mech
func heal(amount: float) -> void:
	if not _is_alive:
		return

	self.current_health += amount
	self.current_health = min(self.current_health, self.max_health)

	self.health_changed.emit(self.current_health, self.max_health)

	if GameConfig.DEBUG_MODE:
		print("MechController: Healed %.1f. Health: %.1f/%.1f" % [amount, self.current_health, self.max_health])

## Set health to a specific value
func set_health(value: float) -> void:
	self.current_health = clamp(value, 0.0, self.max_health)
	self.health_changed.emit(self.current_health, self.max_health)

	if self.current_health <= 0 and _is_alive:
		_die()

## Get current health percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	return self.current_health / self.max_health if self.max_health > 0 else 0.0

## Check if mech is alive
func is_alive() -> bool:
	return _is_alive

func _die() -> void:
	if not _is_alive:
		return

	_is_alive = false
	velocity = Vector2.ZERO

	print("MechController: DIED!")
	self.died.emit()

	# Visual feedback (can be expanded with particles, animation, etc.)
	modulate = Color.RED

func _flash_damage() -> void:
	# Simple damage flash effect
	var original_modulate := modulate
	modulate = Color.RED

	# Use a timer to restore color
	await get_tree().create_timer(0.1).timeout
	if _is_alive and is_instance_valid(self):
		modulate = original_modulate
#endregion

#region Upgrade System (for Step 5)
## Increase maximum health
func upgrade_max_health(amount: float) -> void:
	self.max_health += amount
	self.current_health += amount  # Also heal by the upgrade amount
	self.health_changed.emit(self.current_health, self.max_health)

	if GameConfig.DEBUG_MODE:
		print("MechController: Max health upgraded to %.1f" % self.max_health)

## Get current max health
func get_max_health() -> float:
	return self.max_health

## Upgrade weapon damage
func upgrade_weapon_damage(amount: float) -> void:
	if self.weapon_system:
		self.weapon_system.upgrade_damage(amount)

## Apply damage multiplier to weapon (percentage-based upgrades)
func set_weapon_damage_multiplier(multiplier: float) -> void:
	if self.weapon_system:
		self.weapon_system.set_damage_multiplier(multiplier)

#endregion

#region Debug Visualization
func _draw() -> void:
	if not GameConfig.DEBUG_MODE:
		return

	# Draw health bar above mech
	var bar_width: float = 60.0
	var bar_height: float = 8.0
	var bar_offset: Vector2 = Vector2(-bar_width / 2, -50)

	# Background
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.BLACK)

	# Health fill
	var health_percent: float = self.get_health_percentage()
	var fill_width: float = bar_width * health_percent
	var health_color: Color = Color.GREEN.lerp(Color.RED, 1.0 - health_percent)
	draw_rect(Rect2(bar_offset, Vector2(fill_width, bar_height)), health_color)

	# Border
	draw_rect(Rect2(bar_offset, Vector2(bar_width, bar_height)), Color.WHITE, false, 1.0)

	# Draw direction indicator (line to mouse)
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = global_position.direction_to(mouse_pos)
	draw_line(Vector2.ZERO, direction * 40, Color.YELLOW, 2.0)

#endregion

#region Public Utility Functions
## Stop all movement (useful for cutscenes, death, etc.)
func stop_movement() -> void:
	velocity = Vector2.ZERO

## Enable/disable controls
func set_controls_enabled(enabled: bool) -> void:
	_is_alive = enabled
	if not enabled:
		stop_movement()

#endregion
