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
var current_state: GrowthState = GrowthState.PLANTED
var growth_timer: float = 0.0  # Time spent growing
var total_grow_time: float = 0.0  # Total time needed to reach harvest state
var hex_coords: Vector2i = Vector2i.ZERO  # Grid position this crop occupies
var crop_data: CropDatabase.CropData = null

# Visual nodes (created in _ready)
var _sprite: Sprite2D = null
var _collision_shape: CollisionShape2D = null
var _hover_indicator: Sprite2D = null  # Shows when mouse hovers

#endregion

#region Initialization
func _ready() -> void:
	# Get crop data from database
	crop_data = CropDatabase.get_crop(crop_type)
	if not crop_data:
		push_error("BaseCrop: Invalid crop_type %d" % crop_type)
		queue_free()
		return

	total_grow_time = crop_data.grow_time

	_setup_visuals()
	_setup_collision()
	_connect_signals()

	# Start in PLANTED state
	_set_state(GrowthState.PLANTED)

	if debug_draw:
		print("BaseCrop: Planted %s at hex %v (grow time: %.1fs)" % [crop_data.name, hex_coords, total_grow_time])

func _setup_visuals() -> void:
	# Create main sprite (colored square for now, will be replaced with actual sprites later)
	_sprite = Sprite2D.new()
	_sprite.texture = _create_placeholder_texture(32, 32, crop_data.color)
	_sprite.scale = Vector2(0.5, 0.5)  # Start small for PLANTED state
	add_child(_sprite)

	# Create hover indicator (white outline)
	_hover_indicator = Sprite2D.new()
	_hover_indicator.texture = _create_placeholder_texture(40, 40, Color.WHITE)
	_hover_indicator.modulate = Color(1, 1, 1, 0.5)
	_hover_indicator.z_index = -1
	_hover_indicator.visible = false
	add_child(_hover_indicator)

func _setup_collision() -> void:
	# Collision shape for click detection
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _connect_signals() -> void:
	# Connect hover signals for visual feedback
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

#endregion

#region Growth Logic
func _process(delta: float) -> void:
	# Only grow during DAY phase
	if TimeManager and TimeManager.is_day() and current_state == GrowthState.GROWING:
		growth_timer += delta

		# Check if crop is ready for harvest
		if growth_timer >= total_grow_time:
			_set_state(GrowthState.HARVESTABLE)
		else:
			_update_growth_visuals()

func _set_state(new_state: GrowthState) -> void:
	current_state = new_state
	growth_state_changed.emit(new_state)
	_update_visuals()

	if debug_draw:
		var state_name: String = GrowthState.keys()[new_state]
		print("BaseCrop: %s state changed to %s" % [crop_data.name, state_name])

func _update_visuals() -> void:
	"""Update sprite based on current growth state"""
	match current_state:
		GrowthState.PLANTED:
			_sprite.scale = Vector2(0.5, 0.5)
			_sprite.modulate = crop_data.color.darkened(0.4)

		GrowthState.GROWING:
			# Scale will be updated in _update_growth_visuals()
			_sprite.modulate = crop_data.color.darkened(0.2)

		GrowthState.HARVESTABLE:
			_sprite.scale = Vector2(1.0, 1.0)
			_sprite.modulate = crop_data.color
			# Add a subtle "ready" indicator (pulsing glow)
			var tween: Tween = create_tween()
			var _ignored: Tween = tween.set_loops()  # set_loops() returns Tween for chaining
			tween.tween_property(_sprite, "modulate:a", 0.7, 0.5)
			tween.tween_property(_sprite, "modulate:a", 1.0, 0.5)

func _update_growth_visuals() -> void:
	"""Gradually scale up sprite as crop grows"""
	var growth_progress: float = growth_timer / total_grow_time
	var target_scale: float = lerp(0.5, 1.0, growth_progress)
	_sprite.scale = Vector2(target_scale, target_scale)

#endregion

#region Interaction
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Only harvest if crop is ready and player clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_state == GrowthState.HARVESTABLE:
			_harvest()

func _harvest() -> void:
	"""Harvest the crop, emit signal, and destroy self"""
	if current_state != GrowthState.HARVESTABLE:
		return

	# Emit harvest signal (EconomyManager will listen to this)
	harvested.emit(crop_type, crop_data.value, hex_coords)

	if debug_draw:
		print("BaseCrop: Harvested %s at hex %v for %d credits!" % [crop_data.name, hex_coords, crop_data.value])

	# Visual feedback before destruction
	_play_harvest_effect()

	# Cleanup
	queue_free()

func _play_harvest_effect() -> void:
	"""Simple harvest particle effect (placeholder)"""
	# Create a quick "poof" effect
	var particles := CPUParticles2D.new()
	particles.amount = 16
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, 200)
	particles.color = crop_data.color
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
	if current_state == GrowthState.HARVESTABLE:
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
	crop_type = p_crop_type
	hex_coords = p_hex_coords

## Start growing (called after planting)
func start_growing() -> void:
	_set_state(GrowthState.GROWING)

## Get growth progress (0.0 to 1.0)
func get_growth_progress() -> float:
	if total_grow_time <= 0:
		return 0.0
	return clamp(growth_timer / total_grow_time, 0.0, 1.0)

## Check if crop is ready to harvest
func is_harvestable() -> bool:
	return current_state == GrowthState.HARVESTABLE

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder until we have real sprites)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

#endregion
