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
@export var bullet_type: WeaponConfig.BulletType = WeaponConfig.DEFAULT_BULLET_TYPE
@export var debug_draw: bool = false
@export var debug_show_region: bool = false  # Show sprite sheet region boundaries

#endregion

#region Private Variables
var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _hit_targets: Array[Node] = []  # Track what we've already hit to avoid double-hits
var _particle_cleanup_timer: Timer = null  # Timer for particle cleanup instead of await
var _sprite: Sprite2D = null
var _current_region: Rect2 = Rect2()  # Store current region for debug visualization

#endregion

#region Static Preloaded Textures (Cached)
## Cached sprite textures to avoid synchronous loads during gameplay
static var _sprite_sheet_cache: Dictionary = {}  # Cache for loaded sprite sheets
static var _cached_placeholder_texture: Texture2D = null

## Preloaded sprite sheets - loaded at class initialization to avoid runtime frame drops
static var _preloaded_sheets: Dictionary = {}
static var _sheets_preloading_done: bool = false

#endregion

#region Lifecycle
func _ready() -> void:
	# Preload all sprite sheets on first bullet initialization
	if not _sheets_preloading_done:
		_preload_all_sprite_sheets()
		_sheets_preloading_done = true
	# Configure collision layers (Layer 2: player projectiles)
	collision_layer = GameConfig.COLLISION_LAYER_PLAYER
	# Collision mask: detect enemies (Layer 3)
	collision_mask = GameConfig.COLLISION_MASK_PLAYER_PROJECTILES

	# Ensure collision detection is set up
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Setup sprite
	_setup_sprite()

	# Debug collision configuration
	if self.debug_draw:
		print("[Bullet] Collision Layer: %d (Layer 2 - player_projectiles), Mask: %d (detects Layer 3 - enemies)" % [collision_layer, collision_mask])
		print("[Bullet] Spawned at position: ", global_position, " with velocity: ", _velocity)
		if area_entered.is_connected(_on_area_entered):
			print("[Bullet] area_entered signal connected ✓")
		if _sprite:
			print("[Bullet] Sprite loaded and visible ✓")


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
	if self.debug_draw or self.debug_show_region:
		queue_redraw()

#endregion

#region Collision & Damage
func _on_area_entered(area: Node2D) -> void:
	"""Handle collision with enemies or obstacles"""
	if self.debug_draw:
		print("[Bullet] area_entered fired! Area: %s (type: %s, parent: %s)" % [area.name, area.get_class(), area.get_parent().name if area.get_parent() else "none"])

	# Skip if we've already hit this target
	if area in _hit_targets:
		if self.debug_draw:
			print("[Bullet] Already hit this target, skipping")
		return

	# Get the actual enemy - check if area is BaseEnemy or child of BaseEnemy
	var enemy: BaseEnemy = null

	# Direct hit on the enemy node itself
	if area is BaseEnemy:
		enemy = area as BaseEnemy
		if self.debug_draw:
			print("[Bullet] Direct hit on BaseEnemy: %s" % enemy.name)
	# Hit on collision shape (child of enemy)
	elif area.get_parent() is BaseEnemy:
		enemy = area.get_parent() as BaseEnemy
		if self.debug_draw:
			print("[Bullet] Hit on child of BaseEnemy: %s (child: %s)" % [enemy.name, area.name])

	# Only process if we found a valid enemy
	if enemy == null:
		if self.debug_draw:
			print("[Bullet] No BaseEnemy found in collision! Area type: %s, Parent: %s" % [area.get_class(), area.get_parent().get_class() if area.get_parent() else "null"])
		return

	_hit_targets.append(enemy)

	# Deal damage
	if self.debug_draw:
		print("[Bullet] Dealing %.0f damage to %s (HP: %.0f → %.0f)" % [self.damage, enemy.name, enemy.health, enemy.health - self.damage])
	enemy.take_damage(self.damage)
	self.hit_enemy.emit(enemy, self.damage)

	if self.debug_draw:
		print("[Bullet] Hit enemy: ", enemy.name, " for ", self.damage, " damage")

	# Create hit effect
	_create_hit_effect(enemy.global_position)

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
	monitoring = false  # Disable collision detection while in pool

## Prepare bullet for firing (called when retrieving from pool)
func prepare() -> void:
	_age = 0.0
	_hit_targets.clear()
	visible = true
	set_physics_process(true)
	monitoring = true  # Enable collision detection when active

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

	# Add to scene with timer-based cleanup (avoid await continuation after pool return)
	get_parent().add_child(particles)

	# Use Timer instead of await to prevent execution after bullet returns to pool
	var cleanup_timer = Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = WeaponConfig.HIT_PARTICLE_LIFETIME
	particles.add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.queue_free()
	)
	cleanup_timer.start()

func _expire() -> void:
	"""Bullet lifetime ended - clean up"""
	if self.debug_draw:
		if _age >= self.lifetime:
			print("[Bullet] EXPIRED after %.2f seconds (lifetime: %.2f)" % [_age, self.lifetime])
		else:
			print("[Bullet] Destroyed after hit")

	self.expired.emit()
	reset()
	# Bullet will be returned to pool by WeaponSystem or auto queue_free

#endregion

#region Sprite Management
func _setup_sprite() -> void:
	"""Load and configure bullet sprite from WeaponConfig sprite sheet system"""
	# Get or create sprite node
	if has_node("Sprite2D"):
		_sprite = get_node("Sprite2D") as Sprite2D
	else:
		_sprite = Sprite2D.new()
		add_child(_sprite)

	# Get sprite sheet index and region from config
	var sheet_index: int = WeaponConfig.BULLET_TYPE_SHEETS.get(self.bullet_type, 0)
	var region: Rect2 = WeaponConfig.BULLET_TYPE_REGIONS.get(self.bullet_type, Rect2(20, 4, 20, 20))
	_current_region = region  # Store for debug visualization

	# Build sprite sheet path using the sheet index
	var sprite_path = WeaponConfig.BULLET_SPRITE_SHEET_PATH % sheet_index
	var sprite_texture = _get_cached_sprite_sheet(sprite_path)

	if sprite_texture:
		# Create AtlasTexture to extract specific region from sprite sheet
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = sprite_texture
		atlas_texture.region = region

		_sprite.texture = atlas_texture
		# Scale up the extracted sprite for visibility
		_sprite.scale = Vector2(2.0, 2.0)
		_sprite.centered = true  # Center sprite on bullet position

		if self.debug_draw:
			var bullet_name = WeaponConfig.BulletType.keys()[self.bullet_type]
			print("[Bullet] Loaded bullet type '%s' from sheet %d, region: %s" % [bullet_name, sheet_index, region])
	else:
		# Fallback: Create visual placeholder if sprite fails to load
		_sprite.texture = _get_placeholder_texture()
		_sprite.scale = Vector2(1.0, 1.0)
		_sprite.centered = true
		if self.debug_draw:
			var bullet_name = WeaponConfig.BulletType.keys()[self.bullet_type]
			print("[Bullet] WARNING: Failed to load sprite sheet %s for bullet type '%s', using placeholder" % [sprite_path, bullet_name])

func _preload_all_sprite_sheets() -> void:
	"""Preload all sprite sheets at class initialization to avoid runtime frame drops"""
	# Load all sprite sheets referenced in WeaponConfig
	for bullet_type in WeaponConfig.BULLET_TYPE_SHEETS.values():
		var sprite_path = WeaponConfig.BULLET_SPRITE_SHEET_PATH % bullet_type
		if not _sprite_sheet_cache.has(sprite_path):
			var texture = load(sprite_path) as Texture2D
			if texture:
				_sprite_sheet_cache[sprite_path] = texture

func _get_cached_sprite_sheet(sprite_path: String) -> Texture2D:
	"""Get sprite sheet from cache (preloaded at class initialization)

	DO NOT load textures here - this is called during gameplay (5 shots/sec).
		Synchronous load() causes frame drops. All textures are preloaded in _preload_all_sprite_sheets().
	"""
	if _sprite_sheet_cache.has(sprite_path):
		return _sprite_sheet_cache[sprite_path] as Texture2D

	# Return null if not preloaded - should not happen in normal gameplay
	return null

func _get_placeholder_texture() -> Texture2D:
	"""Get or create a cached placeholder texture"""
	if _cached_placeholder_texture == null:
		_cached_placeholder_texture = _create_placeholder_texture()
	return _cached_placeholder_texture

func _create_placeholder_texture() -> Texture2D:
	"""Create a simple yellow circle as fallback if sprite fails to load"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x - 8, y - 8).length()
			if dist <= 7:
				image.set_pixel(x, y, WeaponConfig.BULLET_COLOR)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)

#endregion

#region Debug Visualization
func _draw() -> void:
	if not visible:
		return

	# Draw velocity vector for aiming reference
	if self.debug_draw:
		if _velocity.length() > 0:
			var velocity_visual = _velocity.normalized() * 30
			draw_line(Vector2.ZERO, velocity_visual, Color.WHITE, 2.0)

	# Draw sprite sheet region debug visualization
	if self.debug_show_region:
		_draw_region_debug()

func _draw_region_debug() -> void:
	"""Visualize the sprite sheet region being extracted"""
	var bullet_name = WeaponConfig.BulletType.keys()[self.bullet_type]
	var sheet_index: int = WeaponConfig.BULLET_TYPE_SHEETS.get(self.bullet_type, 0)

	# Draw region boundaries relative to sprite center
	var region = _current_region
	var region_rect = Rect2(
		-region.size.x / 2.0,
		-region.size.y / 2.0,
		region.size.x,
		region.size.y
	)

	# Draw bright green border to show extracted region
	draw_rect(region_rect, Color.GREEN, false, 2.0)

	# Draw cross at center for reference
	var cross_size = 10.0
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color.CYAN, 1.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color.CYAN, 1.0)

	# Draw info text
	var info_text = "%s (Sheet %d)" % [bullet_name, sheet_index]
	var region_text = "Region: x=%d y=%d w=%d h=%d" % [int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y)]

	draw_string(ThemeDB.fallback_font, Vector2(-50, -30), info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.YELLOW)
	draw_string(ThemeDB.fallback_font, Vector2(-50, -15), region_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

#endregion
