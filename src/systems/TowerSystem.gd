class_name TowerSystem
extends Node
## Handles tower placement, validation, and management
## Integrates with HexGrid for tile validation and EconomyManager for costs
## Similar to PlantingSystem but for towers

#region Signals
signal tower_placed(hex_coords: Vector2i, tower_type: TowerDatabase.TowerType)
signal placement_mode_changed(active: bool, tower_type: TowerDatabase.TowerType)

#endregion

#region Exports
@export var hex_grid: HexGrid  # Reference to hex grid system
@export var show_preview: bool = true  # Show ghost preview on hover
@export var show_range_indicator: bool = true  # Show detection range circle

#endregion

#region Private Variables
var _is_placement_mode: bool = false
var _selected_tower_type: TowerDatabase.TowerType = TowerDatabase.TowerType.GATLING_GUN
var _preview_node: Node2D = null  # Ghost preview with range indicator
var _preview_sprite: Sprite2D = null
var _range_indicator: CanvasItem = null
var _placed_towers: Dictionary = {}  # hex_coords -> Tower instance

# Tile validation
const FARMABLE_TILE_ID: int = 0  # Adjust based on your TileMap setup

#endregion

#region Initialization
func _ready() -> void:
	if not self.hex_grid:
		push_error("TowerSystem: hex_grid not assigned!")
		return

	_setup_preview()
	_connect_signals()

	print("TowerSystem: Initialized")

func _setup_preview() -> void:
	"""Create ghost preview node with sprite and range indicator"""
	if not self.show_preview:
		return

	_preview_node = Node2D.new()
	_preview_node.visible = false
	_preview_node.z_index = 100  # Draw on top
	add_child(_preview_node)

	# Create preview sprite
	_preview_sprite = Sprite2D.new()
	_preview_sprite.modulate = Color(1, 1, 1, 0.6)  # Transparent
	_preview_sprite.z_index = 100
	_preview_node.add_child(_preview_sprite)

	# Create range indicator (only if enabled)
	#if self.show_range_indicator:
		#_range_indicator = CanvasItem.new()
		#_range_indicator.z_index = 99
		#_preview_node.add_child(_range_indicator)

func _connect_signals() -> void:
	"""Connect to HexGrid signals"""
	if self.hex_grid:
		self.hex_grid.tile_clicked.connect(_on_tile_clicked)
		self.hex_grid.tile_hovered.connect(_on_tile_hovered)

#endregion

#region Input Handling
func _unhandled_input(event: InputEvent) -> void:
	if not _is_placement_mode:
		# Check for tower selection key (T for Tower)
		if event is InputEventKey and event.keycode == KEY_T and event.pressed:
			enter_placement_mode(TowerDatabase.TowerType.GATLING_GUN)
			get_tree().root.set_input_as_handled()
	else:
		# Exit placement mode with ESC or right-click
		if event.is_action_pressed("ui_cancel"):
			exit_placement_mode()
			get_tree().root.set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			exit_placement_mode()
			get_tree().root.set_input_as_handled()

func _on_tile_clicked(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Handle tile click for tower placement"""
	if not _is_placement_mode:
		return

	# Validate placement
	if not self.can_place_tower_at(hex_coords):
		_show_invalid_feedback(world_pos)
		return

	# Check if player has enough credits
	var tower_cost := TowerDatabase.get_tower_cost(_selected_tower_type)
	if not EconomyManager.can_afford(tower_cost):
		print("TowerSystem: Not enough credits to place %s (cost: %d)" % [TowerDatabase.get_tower_name(_selected_tower_type), tower_cost])
		_show_invalid_feedback(world_pos)
		return

	# Deduct cost and place tower
	if EconomyManager.spend_credits(tower_cost):
		_place_tower_at(hex_coords, world_pos)

func _on_tile_hovered(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Update ghost preview on hover"""
	if not _is_placement_mode or not _preview_node:
		return

	_preview_node.global_position = world_pos
	_preview_node.visible = true

	# Change color based on validity
	if self.can_place_tower_at(hex_coords):
		_preview_sprite.modulate = TowerConfig.TOWER_PLACEMENT_VALID_COLOR  # Green = valid
	else:
		_preview_sprite.modulate = TowerConfig.TOWER_PLACEMENT_INVALID_COLOR  # Red = invalid

	# Update range indicator
	_update_range_indicator()

#endregion

#region Placement Logic
func enter_placement_mode(tower_type: TowerDatabase.TowerType) -> void:
	"""Enter placement mode for a specific tower type"""
	_is_placement_mode = true
	_selected_tower_type = tower_type

	# Update preview sprite texture
	if _preview_sprite:
		var tower_data := TowerDatabase.get_tower(tower_type)
		if tower_data:
			# Try to load actual sprite
			var sprite_texture: Texture2D = tower_data.get_sprite()
			if sprite_texture:
				_preview_sprite.texture = sprite_texture
			else:
				# Fallback to placeholder
				_preview_sprite.texture = _create_placeholder_texture(32, 32, Color(0.3, 0.6, 1.0))
			_preview_sprite.scale = Vector2.ONE * tower_data.size

	self.placement_mode_changed.emit(true, tower_type)
	print("TowerSystem: Entered placement mode for %s (cost: %d)" % [
		TowerDatabase.get_tower_name(tower_type),
		TowerDatabase.get_tower_cost(tower_type)
	])

func exit_placement_mode() -> void:
	"""Exit placement mode"""
	_is_placement_mode = false

	if _preview_node:
		_preview_node.visible = false

	self.placement_mode_changed.emit(false, _selected_tower_type)
	print("TowerSystem: Exited placement mode")

func can_place_tower_at(hex_coords: Vector2i) -> bool:
	"""Check if a tower can be placed at the given hex coordinates"""
	# Check if tile exists
	if not self.hex_grid.has_tile(hex_coords):
		return false

	# Check if tile is valid for towers (not a path, not already occupied)
	if not _is_valid_tower_tile(hex_coords):
		return false

	# Check if hex is already occupied by a tower or crop
	if _placed_towers.has(hex_coords):
		return false

	# Check if PlantingSystem has a crop here (if it exists)
	var planting_system = get_tree().current_scene.find_child("PlantingSystem", true, false)
	if planting_system and planting_system.get_crop_at(hex_coords):
		return false

	return true

func _is_valid_tower_tile(hex_coords: Vector2i) -> bool:
	"""Check if tile is suitable for tower placement"""
	# For now, assume all tiles are valid for towers
	# TODO: Implement tile type checking (avoid paths, water, etc.)
	return self.hex_grid.has_tile(hex_coords)

func _place_tower_at(hex_coords: Vector2i, world_pos: Vector2) -> void:
	"""Instantiate and place a tower at the given position"""
	# Get the tower scene based on type
	var tower_instance: BaseTower

	match _selected_tower_type:
		TowerDatabase.TowerType.GATLING_GUN:
			tower_instance = GatlingGun.new()
		_:
			push_error("TowerSystem: Unknown tower type: %s" % _selected_tower_type)
			return

	# Setup tower
	tower_instance.tower_type = _selected_tower_type
	tower_instance.global_position = world_pos

	# Add to scene (as child of HexGrid or root)
	if self.hex_grid:
		self.hex_grid.add_child(tower_instance)
	else:
		get_tree().current_scene.add_child(tower_instance)

	# Track placed tower
	_placed_towers[hex_coords] = tower_instance

	# Emit signal
	self.tower_placed.emit(hex_coords, _selected_tower_type)

	print("TowerSystem: Placed %s at hex %v for %d credits" % [
		TowerDatabase.get_tower_name(_selected_tower_type),
		hex_coords,
		TowerDatabase.get_tower_cost(_selected_tower_type)
	])

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

func _update_range_indicator() -> void:
	"""Update the range indicator circle in preview"""
	if not _range_indicator or not _selected_tower_type:
		return

	_range_indicator.queue_redraw()

#endregion

#region Public API
func get_tower_at(hex_coords: Vector2i) -> BaseTower:
	"""Get tower instance at hex coordinates (if any)"""
	return _placed_towers.get(hex_coords)

func get_all_towers() -> Array[BaseTower]:
	"""Get all placed towers"""
	var towers: Array[BaseTower] = []
	for tower in _placed_towers.values():
		if is_instance_valid(tower):
			towers.append(tower)
	return towers

func get_tower_count() -> int:
	"""Get total number of placed towers"""
	return _placed_towers.size()

func is_in_placement_mode() -> bool:
	"""Check if in tower placement mode"""
	return _is_placement_mode

func get_selected_tower_type() -> TowerDatabase.TowerType:
	"""Get currently selected tower type"""
	return _selected_tower_type

#endregion

#region Utility
func _create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	"""Create a simple colored square texture (placeholder)"""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

#endregion
