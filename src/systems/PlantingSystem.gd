class_name PlantingSystem
extends Node
## Handles crop planting logic, placement validation, and ghost preview
## Integrates with HexGrid for tile validation and EconomyManager for costs

#region Signals
signal crop_planted(hex_coords: Vector2i, crop_type: CropDatabase.CropType)
signal placement_mode_changed(active: bool, crop_type: CropDatabase.CropType)

#endregion

#region Exports
@export var hex_grid: HexGrid  # Reference to hex grid system
@export var crop_scene: PackedScene  # BaseCrop.tscn
@export var show_preview: bool = true  # Show ghost preview on hover

#endregion

#region Private Variables
var _is_placement_mode: bool = false
var _selected_crop_type: CropDatabase.CropType = CropDatabase.CropType.WHEAT
var _preview_sprite: Sprite2D = null  # Ghost preview node
var _planted_crops: Dictionary = {}  # hex_coords -> BaseCrop instance

# Tile validation
const FARMABLE_TILE_ID: int = 0  # Adjust this based on your TileMap setup

#endregion

#region Initialization
func _ready() -> void:
	if not self.hex_grid:
		push_error("PlantingSystem: hex_grid not assigned!")
		return

	if not self.crop_scene:
		# Try to load default crop scene
		self.crop_scene = load("res://scenes/entities/crops/BaseCrop.tscn")
		if not self.crop_scene:
			push_error("PlantingSystem: crop_scene not found!")
			return

	_setup_preview()
	_connect_signals()

	print("PlantingSystem: Initialized")

func _setup_preview() -> void:
	"""Create ghost preview sprite"""
	if not self.show_preview:
		return

	_preview_sprite = Sprite2D.new()
	_preview_sprite.modulate = Color(1, 1, 1, 0.5)  # Transparent white
	_preview_sprite.visible = false
	_preview_sprite.z_index = 100  # Draw on top
	add_child(_preview_sprite)

func _connect_signals() -> void:
	"""Connect to input and TimeManager signals"""
	if self.hex_grid:
		self.hex_grid.tile_clicked.connect(_on_tile_clicked)
		self.hex_grid.tile_hovered.connect(_on_tile_hovered)

#endregion

#region Input Handling
func _unhandled_input(event: InputEvent) -> void:
	if not _is_placement_mode:
		# Check for crop selection keys (1, 2, 3)
		if event.is_action_pressed("crop_1"):
			enter_placement_mode(CropDatabase.CropType.WHEAT)
		elif event.is_action_pressed("crop_2"):
			enter_placement_mode(CropDatabase.CropType.CORN)
		elif event.is_action_pressed("crop_3"):
			enter_placement_mode(CropDatabase.CropType.ALIEN_FRUIT)
	else:
		# Exit placement mode with ESC or right-click
		if event.is_action_pressed("ui_cancel") or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			exit_placement_mode()

func _on_tile_clicked(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Handle tile click for crop placement"""
	if not _is_placement_mode:
		return

	# Validate placement
	if not self.can_place_crop_at(hex_coords):
		_show_invalid_feedback(world_pos)
		return

	# Check if player has enough credits
	var crop_cost := CropDatabase.get_crop_cost(_selected_crop_type)
	if not EconomyManager.can_afford(crop_cost):
		print("PlantingSystem: Not enough credits to plant %s (cost: %d)" % [CropDatabase.get_crop_name(_selected_crop_type), crop_cost])
		_show_invalid_feedback(world_pos)
		return

	# Deduct cost and plant crop
	if EconomyManager.spend_credits(crop_cost):
		_plant_crop_at(hex_coords, world_pos)

func _on_tile_hovered(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Update ghost preview on hover"""
	if not _is_placement_mode or not _preview_sprite:
		return

	_preview_sprite.global_position = world_pos
	_preview_sprite.visible = true

	# Change color based on validity
	if self.can_place_crop_at(hex_coords):
		_preview_sprite.modulate = Color(0, 1, 0, 0.5)  # Green = valid
	else:
		_preview_sprite.modulate = Color(1, 0, 0, 0.5)  # Red = invalid

#endregion

#region Placement Logic
func enter_placement_mode(crop_type: CropDatabase.CropType) -> void:
	"""Enter placement mode for a specific crop type"""
	_is_placement_mode = true
	_selected_crop_type = crop_type

	# Update preview sprite texture
	if _preview_sprite:
		var crop_data := CropDatabase.get_crop(crop_type)
		if crop_data:
			# Try to load actual sprite
			var sprite_texture: Texture2D = crop_data.get_sprite()
			if sprite_texture:
				_preview_sprite.texture = sprite_texture
			else:
				# Fallback to placeholder
				_preview_sprite.texture = _create_placeholder_texture(32, 32, crop_data.color)
			var preview_scale: float = CropConfig.PREVIEW_SCALE
			_preview_sprite.scale = Vector2(preview_scale, preview_scale)

	self.placement_mode_changed.emit(true, crop_type)
	print("PlantingSystem: Entered placement mode for %s" % CropDatabase.get_crop_name(crop_type))

func exit_placement_mode() -> void:
	"""Exit placement mode"""
	_is_placement_mode = false

	if _preview_sprite:
		_preview_sprite.visible = false

	self.placement_mode_changed.emit(false, _selected_crop_type)
	print("PlantingSystem: Exited placement mode")

func can_place_crop_at(hex_coords: Vector2i) -> bool:
	"""Check if a crop can be placed at the given hex coordinates"""
	# Check if tile exists
	if not self.hex_grid.has_tile(hex_coords):
		return false

	# Check if tile is farmable (you'll need to implement this in HexGrid)
	if not _is_farmable_tile(hex_coords):
		return false

	# Check if tile is already occupied
	if _planted_crops.has(hex_coords):
		return false

	return true

func _is_farmable_tile(hex_coords: Vector2i) -> bool:
	"""Check if tile is marked as farmable in the TileMap"""
	# For now, assume all tiles are farmable
	# TODO: Implement proper tile type checking via HexGrid
	return self.hex_grid.has_tile(hex_coords)

func _plant_crop_at(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Instantiate and place a crop at the given position"""
	var crop_instance: BaseCrop = crop_scene.instantiate()

	# Setup crop
	crop_instance.setup(_selected_crop_type, hex_coords)
	crop_instance.global_position = world_pos
	crop_instance.z_index = 10  # Draw above tiles but below UI

	# Connect harvest signals: cleanup + economy
	crop_instance.harvested.connect(_on_crop_harvested)

	# Add to HexGrid so crops are part of the grid system
	if self.hex_grid:
		self.hex_grid.add_child(crop_instance)
	else:
		# Fallback to scene root if no hex_grid available
		get_tree().current_scene.add_child(crop_instance)

	# Track planted crop
	_planted_crops[hex_coords] = crop_instance

	# Start growing immediately
	crop_instance.start_growing()

	# Emit signal
	self.crop_planted.emit(hex_coords, _selected_crop_type)

	print("PlantingSystem: Planted %s at hex %v for %d credits" % [
		CropDatabase.get_crop_name(_selected_crop_type),
		hex_coords,
		CropDatabase.get_crop_cost(_selected_crop_type)
	])

func _on_crop_harvested(crop_type: CropDatabase.CropType, value: int, hex_coords: Vector2i) -> void:
	"""Handle crop harvest - cleanup and awards"""
	# Remove from tracking
	_planted_crops.erase(hex_coords)

	# Award credits to player (economy integration)
	EconomyManager.add_credits(value)

	print("PlantingSystem: Crop harvested at hex %v, earned %d credits" % [hex_coords, value])

#endregion

#region Visual Feedback
func _show_invalid_feedback(world_pos: Vector2) -> void:
	"""Show brief visual feedback that placement is invalid"""
	var feedback := Sprite2D.new()
	feedback.texture = _create_placeholder_texture(48, 48, Color.RED)
	feedback.modulate = Color(1, 1, 1, 0.7)
	feedback.global_position = world_pos

	get_tree().current_scene.add_child(feedback)

	# Fade out and destroy
	var tween: Tween = self.create_tween()
	tween.tween_property(feedback, "modulate:a", 0.0, 0.3)
	tween.tween_callback(feedback.queue_free)

#endregion

#region Public API
## Get crop instance at hex coordinates (if any)
func get_crop_at(hex_coords: Vector2i) -> BaseCrop:
	return _planted_crops.get(hex_coords)

## Get all planted crops
func get_all_crops() -> Array[BaseCrop]:
	var crops: Array[BaseCrop] = []
	for crop in _planted_crops.values():
		if is_instance_valid(crop):
			crops.append(crop)
	return crops

## Get total number of planted crops
func get_crop_count() -> int:
	return _planted_crops.size()

## Check if in placement mode
func is_in_placement_mode() -> bool:
	return _is_placement_mode

## Get currently selected crop type
func get_selected_crop_type() -> CropDatabase.CropType:
	return _selected_crop_type

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

#endregion
