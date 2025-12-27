class_name BaseCrop
extends Area2D
## Base crop entity with growth states, visual feedback, and harvest interaction
## Only grows during DAY phase via TimeManager

#region Signals
## Emitted when crop is harvested (for economy system)
signal harvested(crop_type: CropDatabase.CropType, value: int, hex_coords: Vector2i)

## Emitted when growth state changes
signal growth_state_changed(new_state: GrowthState)

#endregion

#region Enums
enum GrowthState {
	PLANTED,      # Just planted, small sprout
	GROWING,      # Actively growing (visual progress)
	HARVESTABLE   # Ready to harvest
}
#endregion

#region Exports
@export var crop_type: CropDatabase.CropType = CropDatabase.CropType.WHEAT
@export var debug_draw: bool = true

#endregion

#region Private Variables
var _current_state: GrowthState = GrowthState.PLANTED
var _growth_timer: float = 0.0  # Time spent growing
var _total_grow_time: float = 0.0  # Total time needed to reach harvest state
var _hex_coords: Vector2i = Vector2i.ZERO  # Grid position this crop occupies
var _crop_data: CropDatabase.CropData = null

# Visual nodes (created in _ready)
var _sprite: Sprite2D = null
var _is_multiframe: bool = false  # True if sprite is a multi-frame sheet
var _collision_shape: CollisionShape2D = null
var _hover_indicator: Sprite2D = null  # Shows when mouse hovers

#endregion

#region Initialization
func _ready() -> void:
	# Get crop data from database
	_crop_data = CropDatabase.get_crop(self.crop_type)
	if not _crop_data:
		push_error("BaseCrop: Invalid crop_type %d" % self.crop_type)
		queue_free()
		return

	_total_grow_time = _crop_data.grow_time

	# Allow debug_draw override from inspector
	if not self.debug_draw and _crop_data.debug_draw:
		self.debug_draw = true

	# Set z-index for proper rendering order (above tiles, below UI)
	z_index = 10

	_setup_visuals()
	_setup_collision()
	_connect_signals()

	# Start in PLANTED state
	_set_state(GrowthState.PLANTED)

	if self.debug_draw:
		print("BaseCrop: Planted %s at hex %v (grow time: %.1fs)" % [_crop_data.name, _hex_coords, _total_grow_time])

func _setup_visuals() -> void:
	# Create main sprite from asset
	_sprite = Sprite2D.new()
	_sprite.centered = true

	# Try to load actual sprite from CropData
	var sprite_texture: Texture2D = _crop_data.get_sprite()
	if sprite_texture:
		_setup_sprite_with_atlas(sprite_texture)
	else:
		# Fallback to placeholder if sprite fails to load
		_sprite.texture = _create_placeholder_texture(32, 32, _crop_data.color)

	var planted_scale: float = CropConfig.PLANTED_SCALE
	_sprite.scale = Vector2(planted_scale, planted_scale)
	add_child(_sprite)

	# Create hover indicator (white outline circle)
	_hover_indicator = Sprite2D.new()
	_hover_indicator.texture = _create_circle_texture(CropConfig.HOVER_INDICATOR_SIZE, Color.WHITE)
	_hover_indicator.modulate = Color(1, 1, 1, 0.3)
	_hover_indicator.z_index = -1
	_hover_indicator.visible = false
	add_child(_hover_indicator)

func _setup_collision() -> void:
	# Collision shape for click detection - scales with crop growth
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CropConfig.COLLISION_SIZE_PLANTED, CropConfig.COLLISION_SIZE_PLANTED)
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _connect_signals() -> void:
	# Connect hover signals for visual feedback
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

#endregion

#region Sprite Setup
func _setup_sprite_with_atlas(sprite_texture: Texture2D) -> void:
	"""Setup sprite with AtlasTexture, handling both single and multi-frame sheets"""
	# Detect if this is a sprite sheet (multi-frame) or single sprite
	# Sprite sheets typically have width >= height * 4 (at least 4 frames wide)
	var is_sprite_sheet: bool = sprite_texture.get_width() >= sprite_texture.get_height() * 4

	if is_sprite_sheet:
		# Multi-frame sprite sheet (9 frames: menu icon + 8 growth frames)
		_setup_multiframe_sprite(sprite_texture)
	else:
		# Single frame sprite - scale it up to simulate growth
		_setup_single_frame_sprite(sprite_texture)

func _setup_multiframe_sprite(sprite_texture: Texture2D) -> void:
	"""Setup a multi-frame sprite sheet using Sprite2D animation frames

	Frames layout (9 total, horizontal):
	  Frame 0: Menu icon (skipped in-game)
	  Frames 1-8: Growth progression from planted to harvestable
	"""
	var total_frames: int = 9  # Menu icon (frame 0) + 8 growth frames (1-8)
	var frame_width: int = int(sprite_texture.get_width() / total_frames)
	var frame_height: int = sprite_texture.get_height()

	# Use Sprite2D's built-in frame animation (simpler than AtlasTexture)
	_sprite.texture = sprite_texture
	_sprite.hframes = total_frames  # 9 frames horizontally
	_sprite.vframes = 1  # 1 row vertically
	_sprite.frame = 1  # Start at frame 1 (skip menu icon frame 0)
	_is_multiframe = true

	if _crop_data.debug_draw:
		print("BaseCrop: Setup multi-frame sprite (%d frames, %dx%d px each) for %s" % [total_frames, frame_width, frame_height, _crop_data.name])

func _setup_single_frame_sprite(sprite_texture: Texture2D) -> void:
	"""Setup a single-frame sprite and use scale to simulate growth

	Single-frame sprites (like from Fruit and Veg asset pack) don't have
	multiple animation frames. Growth is shown through scale changes.
	"""
	_sprite.texture = sprite_texture
	_is_multiframe = false

	if _crop_data.debug_draw:
		print("BaseCrop: Setup single-frame sprite for %s" % _crop_data.name)

#endregion

#region Growth Logic
func _process(delta: float) -> void:
	# Only grow during DAY phase
	if TimeManager and TimeManager.is_day() and _current_state == GrowthState.GROWING:
		_growth_timer += delta

		# Check if crop is ready for harvest
		if _growth_timer >= _total_grow_time:
			_set_state(GrowthState.HARVESTABLE)
		else:
			_update_growth_visuals()

func _set_state(new_state: GrowthState) -> void:
	_current_state = new_state
	self.growth_state_changed.emit(new_state)
	_update_visuals()

	if self.debug_draw:
		var state_name: String = GrowthState.keys()[new_state]
		print("BaseCrop: %s state changed to %s" % [_crop_data.name, state_name])

func _update_visuals() -> void:
	"""Update sprite based on current growth state"""
	match _current_state:
		GrowthState.PLANTED:
			# Show first growth frame (frame 1 for multi-frame, min scale for single-frame)
			if _is_multiframe:
				_sprite.frame = 1
			var scale_val: float = CropConfig.PLANTED_SCALE
			_sprite.scale = Vector2(scale_val, scale_val)
			_sprite.modulate = Color(1, 1, 1, CropConfig.PLANTED_OPACITY)
			# Update collision size for planted state
			if _collision_shape and _collision_shape.shape:
				var shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
				shape.size = Vector2(CropConfig.COLLISION_SIZE_PLANTED, CropConfig.COLLISION_SIZE_PLANTED)

		GrowthState.GROWING:
			# Frames 1-8 will be updated smoothly in _update_growth_visuals()
			_sprite.modulate = Color(1, 1, 1, CropConfig.GROWING_OPACITY)

		GrowthState.HARVESTABLE:
			# Show final growth frame (frame 8 for multi-frame, max scale for single-frame)
			if _is_multiframe:
				_sprite.frame = 8
			var scale_val: float = CropConfig.HARVESTABLE_SCALE
			_sprite.scale = Vector2(scale_val, scale_val)
			_sprite.modulate = Color(1, 1, 1, CropConfig.HARVESTABLE_OPACITY)
			# Update collision size for harvestable state
			if _collision_shape and _collision_shape.shape:
				var shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
				shape.size = Vector2(CropConfig.COLLISION_SIZE_HARVESTABLE, CropConfig.COLLISION_SIZE_HARVESTABLE)
			# Add a subtle "ready" indicator (pulsing glow)
			var tween: Tween = create_tween()
			var _ignored: Tween = tween.set_loops()  # set_loops() returns Tween for chaining
			tween.tween_property(_sprite, "modulate:a", 0.7, CropConfig.PULSE_SPEED)
			tween.tween_property(_sprite, "modulate:a", 1.0, CropConfig.PULSE_SPEED)

func _update_growth_visuals() -> void:
	"""Gradually update sprite frame and scale as crop grows"""
	var growth_progress: float = _growth_timer / _total_grow_time

	if _is_multiframe:
		# Multi-frame sprite: update frame based on growth progress
		# Map progress (0.0-1.0) to frame range (1-8)
		var frame_index: float = 1.0 + (growth_progress * 7.0)  # 1 + (progress * 7) = frames 1-8
		_sprite.frame = int(clamp(frame_index, 1, 8))

	# Both single and multi-frame sprites use scale changes during growth
	var target_scale: float = lerp(CropConfig.PLANTED_SCALE, CropConfig.HARVESTABLE_SCALE, growth_progress)
	_sprite.scale = Vector2(target_scale, target_scale)

#endregion

#region Interaction
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Only harvest if crop is ready and player clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_state == GrowthState.HARVESTABLE:
			_harvest()

func _harvest() -> void:
	"""Harvest the crop, emit signal, and destroy self"""
	if _current_state != GrowthState.HARVESTABLE:
		return

	# Emit harvest signal (EconomyManager will listen to this)
	self.harvested.emit(self.crop_type, _crop_data.value, _hex_coords)

	if self.debug_draw:
		print("BaseCrop: Harvested %s at hex %v for %d credits!" % [_crop_data.name, _hex_coords, _crop_data.value])

	# Visual feedback before destruction
	_play_harvest_effect()

	# Cleanup
	queue_free()

func _play_harvest_effect() -> void:
	"""Simple harvest particle effect (placeholder)"""
	# Create a quick "poof" effect
	var particles := CPUParticles2D.new()
	particles.amount = CropConfig.HARVEST_PARTICLE_COUNT
	particles.lifetime = CropConfig.HARVEST_PARTICLE_LIFETIME
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, 200)
	particles.color = _crop_data.color
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0

	# Add to parent (so it persists after crop is freed)
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true

	# Auto-cleanup after lifetime
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _on_mouse_entered() -> void:
	"""Show hover indicator when mouse enters"""
	if _hover_indicator:
		_hover_indicator.visible = true

	# Change cursor if crop is harvestable
	if _current_state == GrowthState.HARVESTABLE:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	"""Hide hover indicator when mouse exits"""
	if _hover_indicator:
		_hover_indicator.visible = false

	# Reset cursor
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

#endregion

#region Public API
## Initialize crop with specific type and position
func setup(p_crop_type: CropDatabase.CropType, p_hex_coords: Vector2i) -> void:
	self.crop_type = p_crop_type
	_hex_coords = p_hex_coords

## Start growing (called after planting)
func start_growing() -> void:
	_set_state(GrowthState.GROWING)

## Get growth progress (0.0 to 1.0)
func get_growth_progress() -> float:
	if _total_grow_time <= 0:
		return 0.0
	return clamp(_growth_timer / _total_grow_time, 0.0, 1.0)

## Check if crop is ready to harvest
func is_harvestable() -> bool:
	return _current_state == GrowthState.HARVESTABLE

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder fallback)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _create_circle_texture(diameter: int, color: Color) -> ImageTexture:
	"""Create a circular texture for hover indicator"""
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := Vector2(diameter / 2.0, diameter / 2.0)
	var radius: float = diameter / 2.0

	for x in range(diameter):
		for y in range(diameter):
			var dist: float = Vector2(x, y).distance_to(center)
			if dist <= radius:
				# Create soft edge
				var alpha: float = 1.0 if dist < radius - 2 else (radius - dist) / 2.0
				var pixel_color := Color(color.r, color.g, color.b, alpha)
				image.set_pixel(x, y, pixel_color)

	return ImageTexture.create_from_image(image)

#endregion
