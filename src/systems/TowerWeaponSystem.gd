class_name TowerWeaponSystem
## Handles tower projectile spawning and pooling
## Similar to WeaponSystem but for tower-specific bullets
## Manages a separate pool of tower projectiles
## Uses AtlasTexture for sprite rendering with configurable colors

#region Signals
signal tower_bullet_fired(bullet: Node2D, from_position: Vector2, direction: Vector2)

#endregion

#region Private Variables
var _bullet_pool: Array[Node2D] = []
var _active_bullets: Array[Node2D] = []
var _tower_data: TowerDatabase.TowerData

#endregion

#region Static Sprite Cache
## Cached sprite textures to avoid repeated loads
static var _sprite_sheet_cache: Dictionary = {}  # Path -> Texture2D
static var _cached_placeholder_texture: Texture2D = null

#endregion

#region Initialization
func initialize(tower_data: TowerDatabase.TowerData) -> void:
	"""Initialize the weapon system with tower data"""
	_tower_data = tower_data
	_setup_bullet_pool()

func _setup_bullet_pool() -> void:
	"""Pre-create bullet pool for performance"""
	for i in range(TowerConfig.TOWER_BULLET_POOL_SIZE):
		var bullet = _create_bullet_node()
		bullet.set_process(false)
		bullet.set_physics_process(false)
		bullet.hide()
		_bullet_pool.append(bullet)

	print("TowerWeaponSystem: Initialized pool with %d bullets" % TowerConfig.TOWER_BULLET_POOL_SIZE)

func _create_bullet_node() -> Node2D:
	"""Create a tower bullet node with sprite and collision"""
	var bullet = Area2D.new()
	bullet.name = "TowerBullet"

	# Add sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.centered = true
	bullet.add_child(sprite)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 4.0
	collision.shape = circle
	bullet.add_child(collision)

	# Setup collision layers (tower projectiles)
	bullet.collision_layer = 0  # Not on any layer for pooled bullets
	bullet.collision_mask = 0   # Disabled while pooled

	return bullet

#endregion

#region Firing
func fire(from_position: Vector2, direction: Vector2, color: Color) -> void:
	"""Fire a tower bullet in the given direction"""
	var bullet = _get_pooled_bullet()

	if not bullet:
		# Pool exhausted, create new one
		bullet = _create_bullet_node()
		get_tree().current_scene.add_child(bullet)
	else:
		bullet.show()

	# Setup bullet position and velocity
	bullet.global_position = from_position
	_set_bullet_velocity(bullet, direction, _tower_data.bullet_speed)
	_set_bullet_sprite(bullet, color)
	_set_bullet_lifetime(bullet, _tower_data.bullet_lifetime)

	# Add to scene if not already added
	if bullet.get_parent() == null:
		get_tree().current_scene.add_child(bullet)

	# Enable processing
	bullet.set_physics_process(true)
	bullet.monitoring = true

	# Connect expiry signal if not already connected
	if not bullet.tree_entered.is_connected(_on_bullet_entered):
		bullet.tree_entered.connect(_on_bullet_entered.bindv([bullet]))

	# Track active bullet
	_active_bullets.append(bullet)

	# Emit signal
	tower_bullet_fired.emit(bullet, from_position, direction)

func _set_bullet_velocity(bullet: Node2D, direction: Vector2, speed: float) -> void:
	"""Store velocity as metadata on bullet for physics processing"""
	if not bullet.has_meta("velocity"):
		bullet.set_meta("velocity", Vector2.ZERO)
	bullet.set_meta("velocity", direction.normalized() * speed)

func _set_bullet_sprite(bullet: Area2D, color: Color) -> void:
	"""Setup bullet sprite with tower-specific color"""
	var sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return

	# Load sprite from tower config
	var sheet_index: int = TowerConfig.TOWER_TYPE_SHEETS.get(_tower_data.sprite_type, 1)
	var region: Rect2 = TowerConfig.TOWER_TYPE_REGIONS.get(_tower_data.sprite_type, Rect2(176, 0, 16, 16))

	# Get cached sprite sheet
	var sheet_path: String = TowerConfig.TOWER_SPRITE_SHEET_BASE % sheet_index
	var base_texture = _get_cached_sprite_sheet(sheet_path)

	if base_texture:
		# Create AtlasTexture to extract specific region
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = base_texture
		atlas_texture.region = region

		sprite.texture = atlas_texture
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = color
	else:
		# Fallback to placeholder
		sprite.texture = _get_placeholder_texture()
		sprite.modulate = color

func _set_bullet_lifetime(bullet: Node2D, lifetime: float) -> void:
	"""Store lifetime as metadata on bullet"""
	if not bullet.has_meta("lifetime"):
		bullet.set_meta("lifetime", lifetime)
	else:
		bullet.set_meta("lifetime", lifetime)
	bullet.set_meta("age", 0.0)

#endregion

#region Pooling
func _get_pooled_bullet() -> Node2D:
	"""Get a bullet from the pool"""
	if _bullet_pool.is_empty():
		return null
	return _bullet_pool.pop_back()

func _on_bullet_entered(bullet: Node2D) -> void:
	"""Handle bullet entering scene tree"""
	# Reset age timer for lifetime tracking
	if bullet.has_meta("age"):
		bullet.set_meta("age", 0.0)

func _return_bullet_to_pool(bullet: Node2D) -> void:
	"""Return bullet to pool for reuse"""
	_active_bullets.erase(bullet)
	bullet.set_physics_process(false)
	bullet.monitoring = false
	bullet.hide()
	_bullet_pool.append(bullet)

#endregion

#region Sprite Caching
func _get_cached_sprite_sheet(sprite_path: String) -> Texture2D:
	"""Get sprite sheet from cache (loaded on first access)"""
	if _sprite_sheet_cache.has(sprite_path):
		return _sprite_sheet_cache[sprite_path] as Texture2D

	# Load texture and cache it
	var texture = load(sprite_path) as Texture2D
	if texture:
		_sprite_sheet_cache[sprite_path] = texture
	else:
		push_error("TowerWeaponSystem: Failed to load sprite sheet: %s" % sprite_path)

	return texture

func _get_placeholder_texture() -> Texture2D:
	"""Get or create a cached placeholder texture"""
	if _cached_placeholder_texture == null:
		_cached_placeholder_texture = _create_placeholder_texture()
	return _cached_placeholder_texture

func _create_placeholder_texture() -> Texture2D:
	"""Create a simple colored circle as fallback"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x - 8, y - 8).length()
			if dist <= 7:
				image.set_pixel(x, y, _tower_data.bullet_color)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)

#endregion

#region Public API
func get_active_bullet_count() -> int:
	"""Get number of active bullets in flight"""
	return _active_bullets.size()

func get_pooled_bullet_count() -> int:
	"""Get number of bullets available in pool"""
	return _bullet_pool.size()

func retire_bullet(bullet: Node2D) -> void:
	"""Retire an active bullet back to the pool"""
	_return_bullet_to_pool(bullet)

#endregion
