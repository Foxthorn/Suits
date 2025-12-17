class_name HexGrid
extends Node2D
## Core hexagonal grid manager for SUITS: Iron Harvest
##
## Handles hex coordinate conversions, neighbor calculations, and tile queries.
## Uses flat-top hexagon orientation with axial coordinates.
##
## Coordinate System:
## - World space: Godot's standard Vector2 pixel coordinates
## - Hex space: Axial coordinates (q, r) stored as Vector2i

#region Signals
## Emitted when a tile is clicked
signal tile_clicked(hex_coords: Vector2i, world_pos: Vector2)

## Emitted when mouse hovers over a new tile
signal tile_hovered(hex_coords: Vector2i, world_pos: Vector2)

#endregion

#region Exports
@export_group("Grid Settings")
## Reference to the TileMapLayer node
@export var tile_map_layer: TileMapLayer

## Whether to enable debug visualization
@export var debug_mode: bool = false:
	set(value):
		debug_mode = value
		queue_redraw()

## Color for debug hex coordinate display
@export var debug_text_color: Color = Color.YELLOW

@export_group("Camera Settings")
## Camera zoom limits
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1

## Camera pan speed (pixels per second when using keyboard)
@export var pan_speed: float = 500.0

## Reference to the Mech node to follow (set manually in the editor)
@export var mech_node: Node2D

## Enable smooth camera follow for mech movement
@export var smooth_camera: bool = true
@export var camera_lerp_speed: float = 5.0

## Enable manual camera control (keyboard panning) when following mech
@export var allow_manual_pan_while_following: bool = false

#endregion

#region Private Variables
var _camera: Camera2D
var _current_hover_hex: Vector2i = Vector2i.MAX
var _last_click_hex: Vector2i = Vector2i.MAX
var _is_following_mech: bool = true  # Whether camera should follow mech
var _manual_camera_offset: Vector2 = Vector2.ZERO  # Offset from mech when manually panning

# Hex direction vectors (flat-top orientation)
const HEX_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # East
	Vector2i(1, -1),  # Northeast
	Vector2i(0, -1),  # Northwest
	Vector2i(-1, 0),  # West
	Vector2i(-1, 1),  # Southwest
	Vector2i(0, 1),   # Southeast
]

#endregion

#region Initialization
func _ready() -> void:
	_setup_camera()

	if not tile_map_layer:
		push_warning("HexGrid: No TileMapLayer assigned! Trying to find one...")
		tile_map_layer = get_node_or_null("TileMapLayer")

	if not tile_map_layer:
		push_error("HexGrid: TileMapLayer not found! Grid functions will not work.")

	if debug_mode:
		print("HexGrid initialized - Debug mode enabled")
		if mech_node:
			print("HexGrid: Camera will follow Mech at: ", mech_node.get_path())
		else:
			print("HexGrid: No Mech node assigned - manual camera control only")

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	add_child(_camera)
	_camera.enabled = true

	# Start at a reasonable position (center of a 15x15 grid)
	_camera.position = Vector2(900, 600)

#endregion

#region Input Handling
func _input(event: InputEvent) -> void:
	_handle_camera_zoom(event)
	_handle_mouse_clicks(event)

func _process(delta: float) -> void:
	_handle_camera_follow(delta)
	_handle_camera_pan(delta)
	_handle_mouse_hover()

func _handle_camera_zoom(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_camera.zoom = _camera.zoom * (1.0 + zoom_speed)
			_camera.zoom = _camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_camera.zoom = _camera.zoom * (1.0 - zoom_speed)
			_camera.zoom = _camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func _handle_camera_pan(delta: float) -> void:
	# Skip manual panning if following mech and manual control is disabled
	if _is_following_mech and mech_node and not allow_manual_pan_while_following:
		return

	var pan_direction := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1

	if pan_direction != Vector2.ZERO:
		var pan_amount := pan_direction.normalized() * pan_speed * delta / _camera.zoom.x

		if _is_following_mech and allow_manual_pan_while_following:
			# Add to offset instead of moving camera directly
			_manual_camera_offset += pan_amount
		else:
			# Manual camera control (not following mech)
			_camera.position += pan_amount

func _handle_mouse_clicks(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos := get_global_mouse_position()
			var hex_coords := world_to_hex(world_pos)
			_last_click_hex = hex_coords

			tile_clicked.emit(hex_coords, world_pos)

			if debug_mode:
				print("Clicked hex: ", hex_coords, " at world pos: ", world_pos)

			queue_redraw()

func _handle_mouse_hover() -> void:
	var world_pos := get_global_mouse_position()
	var hex_coords := world_to_hex(world_pos)

	if hex_coords != _current_hover_hex:
		_current_hover_hex = hex_coords
		tile_hovered.emit(hex_coords, world_pos)

		if debug_mode:
			queue_redraw()

#endregion

#region Coordinate Conversion
## Convert world position to hex coordinates (axial)
func world_to_hex(world_pos: Vector2) -> Vector2i:
	if not tile_map_layer:
		push_warning("HexGrid.world_to_hex: No TileMapLayer available")
		return Vector2i.ZERO

	return tile_map_layer.local_to_map(world_pos)

## Convert hex coordinates to world position (center of hex)
func hex_to_world(hex_coords: Vector2i) -> Vector2:
	if not tile_map_layer:
		push_warning("HexGrid.hex_to_world: No TileMapLayer available")
		return Vector2.ZERO

	return tile_map_layer.map_to_local(hex_coords)

## Convert hex axial coordinates to cube coordinates for distance calculations
func axial_to_cube(hex: Vector2i) -> Vector3i:
	var q := hex.x
	var r := hex.y
	var s := -q - r
	return Vector3i(q, r, s)

## Convert cube coordinates back to axial
func cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.y)

#endregion

#region Neighbor & Distance Functions
## Get all 6 neighboring hex coordinates
func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []

	for direction in HEX_DIRECTIONS:
		neighbors.append(hex + direction)

	return neighbors

## Get hex at specific direction (0-5, starting from East, going clockwise)
func get_neighbor_in_direction(hex: Vector2i, direction: int) -> Vector2i:
	if direction < 0 or direction >= HEX_DIRECTIONS.size():
		push_warning("HexGrid.get_neighbor_in_direction: Invalid direction %d" % direction)
		return hex

	return hex + HEX_DIRECTIONS[direction]

## Calculate distance between two hex coordinates
func hex_distance(hex_a: Vector2i, hex_b: Vector2i) -> int:
	var cube_a := axial_to_cube(hex_a)
	var cube_b := axial_to_cube(hex_b)

	return (abs(cube_a.x - cube_b.x) + abs(cube_a.y - cube_b.y) + abs(cube_a.z - cube_b.z)) / 2

## Get all hexes within a certain radius
func get_hexes_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []

	for q in range(-radius, radius + 1):
		for r in range(max(-radius, -q - radius), min(radius, -q + radius) + 1):
			hexes.append(center + Vector2i(q, r))

	return hexes

## Get hexes in a ring at specific radius
func get_hexes_in_ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []

	if radius == 0:
		hexes.append(center)
		return hexes

	var hex := center + HEX_DIRECTIONS[4] * radius  # Start from southwest

	for direction_idx in range(6):
		for _step in range(radius):
			hexes.append(hex)
			hex = get_neighbor_in_direction(hex, direction_idx)

	return hexes

#endregion

#region Tile Queries
## Check if a tile exists at hex coordinates
func has_tile(hex: Vector2i) -> bool:
	if not tile_map_layer:
		return false

	return tile_map_layer.get_cell_source_id(hex) != -1

## Get tile data at hex coordinates (returns source_id)
func get_tile_id(hex: Vector2i) -> int:
	if not tile_map_layer:
		return -1

	return tile_map_layer.get_cell_source_id(hex)

## Check if tile is valid for a specific purpose (placeholder for future use)
func is_tile_valid_for_placement(hex: Vector2i) -> bool:
	# For now, just check if tile exists
	# Later, this will check tile type (farmable vs non-farmable)
	return has_tile(hex)

#endregion

#region Debug Visualization
func _draw() -> void:
	if not debug_mode or not tile_map_layer:
		return

	# Draw hex coordinates on hovered tile
	if _current_hover_hex != Vector2i.MAX:
		var world_pos := hex_to_world(_current_hover_hex)
		var local_pos := to_local(world_pos)

		var text := "(%d, %d)" % [_current_hover_hex.x, _current_hover_hex.y]
		draw_string(ThemeDB.fallback_font, local_pos - Vector2(30, -5), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, debug_text_color)

	# Draw marker on last clicked tile
	if _last_click_hex != Vector2i.MAX:
		var world_pos := hex_to_world(_last_click_hex)
		var local_pos := to_local(world_pos)
		draw_circle(local_pos, 10, Color.RED)

#endregion

#region Camera Follow Functions
## Update camera position to follow mech
func _handle_camera_follow(delta: float) -> void:
	if not _is_following_mech or not mech_node:
		return

	if not is_instance_valid(mech_node):
		push_warning("HexGrid: Mech node is no longer valid")
		mech_node = null
		return

	var target_position := mech_node.global_position + _manual_camera_offset

	if smooth_camera:
		_camera.position = _camera.position.lerp(target_position, camera_lerp_speed * delta)
	else:
		_camera.position = target_position

#endregion

#region Public Utility Functions
## Get the camera node (for external systems that need camera access)
func get_camera() -> Camera2D:
	return _camera

## Set camera position (useful for centering on player/mech)
func set_camera_position(pos: Vector2) -> void:
	if smooth_camera:
		# Smooth camera will be handled in _process
		_camera.position = pos
	else:
		_camera.position = pos

## Get current camera position
func get_camera_position() -> Vector2:
	return _camera.position if _camera else Vector2.ZERO

## Set the mech node to follow
func set_follow_target(target: Node2D) -> void:
	mech_node = target
	_is_following_mech = true
	_manual_camera_offset = Vector2.ZERO
	if debug_mode and target:
		print("HexGrid: Now following target at: ", target.get_path())

## Stop following the mech and switch to manual camera control
func stop_following() -> void:
	_is_following_mech = false
	if debug_mode:
		print("HexGrid: Stopped following mech - manual camera control enabled")

## Resume following the mech
func resume_following() -> void:
	if mech_node:
		_is_following_mech = true
		_manual_camera_offset = Vector2.ZERO
		if debug_mode:
			print("HexGrid: Resumed following mech")
	else:
		push_warning("HexGrid: Cannot resume following - no mech node set")

## Check if camera is currently following mech
func is_following_mech() -> bool:
	return _is_following_mech and mech_node != null

## Reset camera offset (useful after manual panning)
func reset_camera_offset() -> void:
	_manual_camera_offset = Vector2.ZERO

#endregion
