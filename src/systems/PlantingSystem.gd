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
var _crops_harvested_total: int = 0  # Track for victory stats

# Tile validation
const FARMABLE_TILE_ID: int = 0  # Adjust this based on your TileMap setup

#endregion

#region Initialization
func _ready() -> void:
	# Phase 1: Validate HexGrid reference
	if not self.hex_grid:
		push_error("[PlantingSystem] CRITICAL: hex_grid not assigned in editor!")
		push_error("[PlantingSystem] → Set PlantingSystem.hex_grid = $HexGrid in MainGame.tscn")
		return

	# Phase 2: Verify HexGrid has required signals
	if not self.hex_grid.has_signal("tile_clicked"):
		push_error("[PlantingSystem] CRITICAL: hex_grid missing 'tile_clicked' signal!")
		return
	if not self.hex_grid.has_signal("tile_hovered"):
		push_error("[PlantingSystem] CRITICAL: hex_grid missing 'tile_hovered' signal!")
		return

	# Phase 3: Validate CropDatabase is initialized
	if not CropDatabase.has_crop(CropDatabase.CropType.WHEAT):
		push_error("[PlantingSystem] CRITICAL: CropDatabase not initialized!")
		push_error("[PlantingSystem] → Ensure CropDatabase autoload is registered")
		return

	# Phase 4: Load or locate crop scene
	if not self.crop_scene:
		# Try to load default crop scene
		self.crop_scene = load("res://scenes/entities/crops/BaseCrop.tscn")
		if not self.crop_scene:
			push_error("[PlantingSystem] CRITICAL: Could not load BaseCrop.tscn!")
			push_error("[PlantingSystem] → Verify file exists at res://scenes/entities/crops/BaseCrop.tscn")
			return
		print("[PlantingSystem] Loaded BaseCrop.tscn from default path")
	else:
		print("[PlantingSystem] Using BaseCrop.tscn from editor export")

	# Phase 5: Verify EconomyManager is available
	if not is_instance_valid(EconomyManager):
		push_error("[PlantingSystem] CRITICAL: EconomyManager autoload not found!")
		push_error("[PlantingSystem] → Ensure EconomyManager is registered in project.godot autoloads")
		return

	# Phase 6: Initialize systems
	_setup_preview()
	_connect_signals()

	print("[PlantingSystem] ✓ Fully initialized and ready!")
	print("[PlantingSystem] → Crops available: %d" % CropDatabase.get_all_crop_types().size())
	print("[PlantingSystem] → Input actions: crop_1 (key 1), crop_2 (key 2), crop_3 (key 3)")

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
	"""Connect to HexGrid signals for tile interaction"""
	if not self.hex_grid:
		push_error("[PlantingSystem] Cannot connect signals: hex_grid is null")
		return

	# Connect tile interaction signals
	if not self.hex_grid.tile_clicked.is_connected(_on_tile_clicked):
		self.hex_grid.tile_clicked.connect(_on_tile_clicked)
		print("[PlantingSystem] Connected to tile_clicked signal")

	if not self.hex_grid.tile_hovered.is_connected(_on_tile_hovered):
		self.hex_grid.tile_hovered.connect(_on_tile_hovered)
		print("[PlantingSystem] Connected to tile_hovered signal")

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
	"""Handle tile click for crop placement with validation"""
	if not _is_placement_mode:
		return

	# Validate placement location
	if not self.can_place_crop_at(hex_coords):
		print("[PlantingSystem] ✗ Cannot place at %v - tile invalid" % hex_coords)
		_show_invalid_feedback(world_pos)
		return

	# Check if player has enough credits
	var crop_cost := CropDatabase.get_crop_cost(_selected_crop_type)
	if not EconomyManager.can_afford(crop_cost):
		print("[PlantingSystem] ✗ Cannot plant %s - insufficient credits (need %d, have %d)" % [
			CropDatabase.get_crop_name(_selected_crop_type),
			crop_cost,
			EconomyManager.get_credits()
		])
		_show_invalid_feedback(world_pos)
		return

	# Verify crop_scene is still valid
	if not self.crop_scene:
		push_error("[PlantingSystem] ERROR: crop_scene lost reference!")
		_show_invalid_feedback(world_pos)
		return

	# Deduct cost and plant crop
	if EconomyManager.spend_credits(crop_cost):
		_plant_crop_at(hex_coords, world_pos)
	else:
		push_error("[PlantingSystem] ERROR: spend_credits() returned false")
		_show_invalid_feedback(world_pos)

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
	"""Enter placement mode for a specific crop type with validation"""
	# Validate crop type exists
	if not CropDatabase.has_crop(crop_type):
		push_error("[PlantingSystem] Invalid crop type: %d" % crop_type)
		push_error("[PlantingSystem] → Valid types: WHEAT(0), CORN(1), ALIEN_FRUIT(2)")
		return

	# Prevent entering placement mode multiple times
	if _is_placement_mode:
		print("[PlantingSystem] Already in placement mode, switching to %s" % CropDatabase.get_crop_name(crop_type))

	_is_placement_mode = true
	_selected_crop_type = crop_type

	# Get crop data for validation
	var crop_data := CropDatabase.get_crop(crop_type)
	if not crop_data:
		push_error("[PlantingSystem] Could not load crop data for type: %d" % crop_type)
		return

	# Update preview sprite texture
	if _preview_sprite:
		# Try to load actual sprite
		var sprite_texture: Texture2D = crop_data.get_sprite()
		if sprite_texture:
			_setup_preview_sprite(sprite_texture)
			print("[PlantingSystem] Loaded sprite for %s" % crop_data.name)
		else:
			# Fallback to placeholder
			_preview_sprite.texture = _create_placeholder_texture(32, 32, crop_data.color)
			print("[PlantingSystem] Using placeholder sprite for %s" % crop_data.name)

		# Apply scale from config
		var preview_scale: float = CropConfig.PREVIEW_SCALE
		_preview_sprite.scale = Vector2(preview_scale, preview_scale)

	self.placement_mode_changed.emit(true, crop_type)
	print("[PlantingSystem] ✓ Entered placement mode: %s (Cost: %d)" % [crop_data.name, crop_data.cost])

func exit_placement_mode() -> void:
	"""Exit placement mode and hide preview"""
	if not _is_placement_mode:
		print("[PlantingSystem] Already not in placement mode, ignoring exit request")
		return

	_is_placement_mode = false

	if _preview_sprite:
		_preview_sprite.visible = false

	self.placement_mode_changed.emit(false, _selected_crop_type)
	print("[PlantingSystem] ✓ Exited placement mode")

func can_place_crop_at(hex_coords: Vector2i) -> bool:
	"""Check if a crop can be placed at the given hex coordinates"""
	# Safety check: hex_grid must be valid
	if not is_instance_valid(self.hex_grid):
		push_error("[PlantingSystem] ERROR: hex_grid reference invalid during placement check")
		return false

	# Check if tile exists in grid
	if not self.hex_grid.has_tile(hex_coords):
		return false

	# Check if tile is farmable
	if not _is_farmable_tile(hex_coords):
		return false

	# Check if tile is already occupied by another crop
	if _planted_crops.has(hex_coords):
		return false

	return true

func _is_farmable_tile(hex_coords: Vector2i) -> bool:
	"""Check if tile is marked as farmable in the TileMap"""
	# For now, assume all tiles are farmable
	# TODO: Implement proper tile type checking via HexGrid
	return self.hex_grid.has_tile(hex_coords)

func _plant_crop_at(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Instantiate and place a crop at the given position with error handling"""
	# Safety check: ensure crop_scene is still valid
	if not is_instance_valid(self.crop_scene):
		push_error("[PlantingSystem] ERROR: crop_scene is no longer valid!")
		return

	var crop_instance: BaseCrop = self.crop_scene.instantiate()
	if not crop_instance:
		push_error("[PlantingSystem] ERROR: Failed to instantiate BaseCrop!")
		return

	# Setup crop with validation
	if not crop_instance.has_method("setup"):
		push_error("[PlantingSystem] ERROR: BaseCrop missing 'setup' method!")
		crop_instance.queue_free()
		return

	crop_instance.setup(_selected_crop_type, hex_coords)
	crop_instance.global_position = world_pos
	crop_instance.z_index = 10  # Draw above tiles but below UI

	# Connect harvest signals: cleanup + economy
	if not crop_instance.harvested.is_connected(_on_crop_harvested):
		crop_instance.harvested.connect(_on_crop_harvested)

	# Add to HexGrid so crops are part of the grid system
	if is_instance_valid(self.hex_grid):
		self.hex_grid.add_child(crop_instance)
		print("[PlantingSystem] Added crop to HexGrid")
	else:
		# Fallback to scene root if no hex_grid available
		var scene_root = get_tree().current_scene
		if scene_root:
			scene_root.add_child(crop_instance)
			print("[PlantingSystem] WARNING: Added crop to scene root (hex_grid not available)")
		else:
			push_error("[PlantingSystem] ERROR: No valid parent for crop!")
			crop_instance.queue_free()
			return

	# Track planted crop
	_planted_crops[hex_coords] = crop_instance

	# Start growing immediately
	if crop_instance.has_method("start_growing"):
		crop_instance.start_growing()
	else:
		push_error("[PlantingSystem] ERROR: BaseCrop missing 'start_growing' method!")

	# Emit signal
	self.crop_planted.emit(hex_coords, _selected_crop_type)

	print("[PlantingSystem] ✓ Planted %s at hex %v for %d credits" % [
		CropDatabase.get_crop_name(_selected_crop_type),
		hex_coords,
		CropDatabase.get_crop_cost(_selected_crop_type)
	])

func _on_crop_harvested(crop_type: CropDatabase.CropType, value: int, hex_coords: Vector2i) -> void:
	"""Handle crop harvest - cleanup and awards"""
	# Remove from tracking
	_planted_crops.erase(hex_coords)
	_crops_harvested_total += 1  # Track for victory stats

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

## Get total crops harvested (for victory stats)
func get_crops_harvested_count() -> int:
	return _crops_harvested_total

#endregion

#region Preview Sprite Setup
func _setup_preview_sprite(sprite_texture: Texture2D) -> void:
	"""Setup preview sprite to show final growth frame

	Matches BaseCrop logic: multi-frame sheets show final frame,
	single-frame sprites use full texture.
	"""
	# Detect if this is a sprite sheet (multi-frame) or single sprite
	# Sprite sheets typically have width >= height * 4 (at least 4 frames wide)
	var is_sprite_sheet: bool = sprite_texture.get_width() >= sprite_texture.get_height() * 4

	if is_sprite_sheet:
		# Multi-frame sprite sheet (9 frames: menu icon + 8 growth frames)
		_preview_sprite.texture = sprite_texture
		_preview_sprite.hframes = 9  # 9 frames horizontally
		_preview_sprite.vframes = 1  # 1 row vertically
		_preview_sprite.frame = 8  # Show final frame (harvestable state)
	else:
		# Single-frame sprite - display as-is
		_preview_sprite.texture = sprite_texture

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

#endregion
