class_name BaseTower extends CharacterBody2D
## Base class for all tower types
## Handles common tower logic: detection, firing, cooldown management
## Subclasses override behavior while reusing core functionality

#region Exported Properties
@export var tower_type: TowerDatabase.TowerType = TowerDatabase.TowerType.GATLING_GUN
@export var debug_draw: bool = false

@export_group("Weapon")
## Weapon system for managing firing
@export var tower_weapon_system: TowerWeaponSystem

#endregion

#region Signals
signal fired(position: Vector2, direction: Vector2)
signal target_changed(new_target: BaseEnemy)

#endregion

#region Private Variables
var tower_data: TowerDatabase.TowerData
var enemies_in_range: Array[BaseEnemy] = []
var current_target: BaseEnemy = null
var fire_cooldown: float = 0.0

# Visual components
var _sprite: Sprite2D
var _detection_zone: Area2D
var _range_indicator: CanvasItem

#endregion

#region Lifecycle
func _ready() -> void:
	# Load tower data from database
	tower_data = TowerDatabase.get_tower(tower_type)

	if not tower_data:
		push_error("BaseTower: Failed to load tower data for type %s" % tower_type)
		queue_free()
		return

	# Initialize weapon system if not set via export
	if not tower_weapon_system:
		tower_weapon_system = TowerWeaponSystem.new()
		add_child(tower_weapon_system)

	# Initialize weapon system with tower data
	tower_weapon_system.initialize(tower_data)

	_setup_sprite()
	_setup_detection_zone()
	_setup_collision_layer()

	if debug_draw:
		print("BaseTower: Initialized %s at %v" % [tower_data.name, global_position])

func _physics_process(delta: float) -> void:
	# Update fire cooldown
	if self.fire_cooldown > 0:
		self.fire_cooldown -= delta
	else:
		var target = find_nearest_enemy()

		# Target changed
		if target != self.current_target:
			self.current_target = target
			self.target_changed.emit(self.current_target)

		# Fire at target
		if self.current_target:
			if debug_draw:
				print("[Tower %s] FIRING at target" % self.name)
			fire()
			self.fire_cooldown = tower_data.fire_rate
		else:
			if debug_draw and enemies_in_range.size() > 0:
				print("[Tower %s] WARNING: Enemies in range but no target selected" % self.name)

func _draw() -> void:
	"""Debug visualization: draw detection range"""
	if debug_draw and tower_data:
		draw_circle(Vector2.ZERO, tower_data.range, TowerConfig.TOWER_RANGE_INDICATOR_COLOR)

#endregion

#region Setup Methods
func _setup_sprite() -> void:
	"""Initialize tower sprite"""
	_sprite = Sprite2D.new()
	add_child(_sprite)

	# Load sprite as AtlasTexture from configured type
	var sprite_texture = tower_data.get_sprite()
	if sprite_texture:
		_sprite.texture = sprite_texture
		# Set hframes if using AtlasTexture to define frame boundaries
		if sprite_texture is AtlasTexture:
			_sprite.hframes = 1  # Single frame (not animating, just showing one sprite)
	else:
		# Fallback to placeholder if sprite loading fails
		push_warning("BaseTower: Failed to load sprite, using placeholder")
		_sprite.texture = _create_placeholder_texture(48, 48, Color(0.2, 0.5, 0.8))

	_sprite.scale = Vector2.ONE * tower_data.size
	_sprite.z_index = 10  # Draw above ground

func _setup_detection_zone() -> void:
	"""Initialize enemy detection area"""
	_detection_zone = Area2D.new()
	_detection_zone.name = "DetectionZone"
	add_child(_detection_zone)

	# Create circular collision shape for detection
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = tower_data.range
	collision_shape.shape = circle_shape
	_detection_zone.add_child(collision_shape)

	# Configure collision layers
	_detection_zone.collision_layer = 0  # Not on any layer
	_detection_zone.collision_mask = GameConfig.COLLISION_LAYER_ENEMIES  # Detect enemies only

	# Connect signals
	_detection_zone.area_entered.connect(_on_enemy_entered)
	_detection_zone.area_exited.connect(_on_enemy_exited)

func _setup_collision_layer() -> void:
	"""Configure collision layers and masks for tower"""
	# Tower is on layer 6 (TOWERS)
	collision_layer = GameConfig.COLLISION_LAYER_TOWERS
	# Tower detects: world(1), enemies(3)
	collision_mask = GameConfig.COLLISION_MASK_TOWER

#endregion

#region Detection & Targeting
func _on_enemy_entered(area: Node2D) -> void:
	"""Enemy entered detection range"""
	# Handle both direct BaseEnemy and child nodes of BaseEnemy
	var enemy: BaseEnemy = null

	if area is BaseEnemy:
		enemy = area
	elif area.owner is BaseEnemy:
		enemy = area.owner
	elif area.get_parent() is BaseEnemy:
		enemy = area.get_parent()

	if enemy:
		if not enemies_in_range.has(enemy):
			enemies_in_range.append(enemy)
			if debug_draw:
				print("[Tower %s] Enemy entered range: %s (total in range: %d)" % [self.name, enemy.name, enemies_in_range.size()])
			# Connect to enemy death signal to clean up
			if not enemy.died.is_connected(_on_enemy_died):
				enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)

func _on_enemy_exited(area: Node2D) -> void:
	"""Enemy left detection range"""
	# Handle both direct BaseEnemy and child nodes of BaseEnemy
	var enemy: BaseEnemy = null

	if area is BaseEnemy:
		enemy = area
	elif area.owner is BaseEnemy:
		enemy = area.owner
	elif area.get_parent() is BaseEnemy:
		enemy = area.get_parent()

	if enemy:
		enemies_in_range.erase(enemy)
		if debug_draw:
			print("[Tower %s] Enemy left range: %s (total in range: %d)" % [self.name, enemy.name, enemies_in_range.size()])
		if self.current_target == enemy:
			if debug_draw:
				print("[Tower %s] Current target left range!" % self.name)
			self.current_target = null

func _on_enemy_died(dead_enemy: BaseEnemy) -> void:
	"""Clean up when enemy dies"""
	enemies_in_range.erase(dead_enemy)
	if self.current_target == dead_enemy:
		self.current_target = null

func find_nearest_enemy() -> BaseEnemy:
	"""Find closest valid enemy in detection range"""
	var nearest: BaseEnemy = null
	var nearest_dist: float = tower_data.range

	if enemies_in_range.size() == 0:
		return null

	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest

#endregion

#region Firing (Abstract - Override in Subclasses)
func fire() -> void:
	"""Fire at current target. Override in subclasses for specific behavior"""
	if not current_target:
		return

	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()

	# Emit signal for subclasses to handle
	fired.emit(global_position, direction)

	# Visual feedback
	_flash_white()

func _flash_white() -> void:
	"""Brief white flash when firing (visual feedback)"""
	if not _sprite:
		return

	var original_color = _sprite.modulate
	_sprite.modulate = Color.WHITE

	# Reuse tween instead of creating new one each shot
	if _sprite.get_meta("flash_tween", null):
		var old_tween = _sprite.get_meta("flash_tween")
		if old_tween:
			old_tween.kill()

	var tween = create_tween()
	_sprite.set_meta("flash_tween", tween)
	tween.tween_callback(func(): _sprite.modulate = Color.WHITE)
	tween.tween_property(_sprite, "modulate", original_color, TowerConfig.TOWER_HIT_FLASH_DURATION)
	tween.finished.connect(func(): if is_instance_valid(_sprite): _sprite.modulate = original_color)

#endregion

#region Public API
func get_tower_data() -> TowerDatabase.TowerData:
	"""Get tower configuration data"""
	return tower_data

func get_enemies_in_range() -> Array[BaseEnemy]:
	"""Get list of enemies currently in detection range"""
	return enemies_in_range.duplicate()

func get_current_target() -> BaseEnemy:
	"""Get the tower's current firing target"""
	return current_target

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

#endregion
