@tool
class_name HexPlacementPreview
extends Node2D
## A tool for previewing and highlighting tile placement on hexagonal tile maps.
##
## This script provides visual feedback for placement operations on hex grids,
## including valid/invalid placement indicators, hover effects, and multi-tile
## selection highlighting.

## Emitted when the hovered tile changes
signal hover_changed(hex_coords: Vector2i)
## Emitted when placement validity changes
signal validity_changed(is_valid: bool)

## Preview display mode
enum PreviewMode {
	SINGLE,      ## Single tile preview
	AREA,        ## Rectangular area preview
	CUSTOM,      ## Custom shape preview (defined by offsets)
	RADIUS       ## Circular radius preview
}

## Visual style for the preview
enum HighlightStyle {
	OUTLINE,     ## Draw outline around tiles
	FILL,        ## Fill tiles with color
	TINT,        ## Tint the tile texture
	BOTH         ## Both outline and fill
}

#region Exported Properties
@export_group("Preview Settings")
## Current preview mode
@export var preview_mode: PreviewMode = PreviewMode.SINGLE

## Highlight style to use
@export var highlight_style: HighlightStyle = HighlightStyle.BOTH

## Whether the preview is currently enabled
@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value
		queue_redraw()

## Opacity of the preview (0.0 - 1.0)
@export_range(0.0, 1.0) var preview_opacity: float = 0.6:
	set(value):
		preview_opacity = value
		modulate.a = value
		queue_redraw()

@export_group("Colors")
## Color for valid placement
@export var valid_color: Color = Color(0.2, 1.0, 0.2, 0.6)

## Color for invalid placement
@export var invalid_color: Color = Color(1.0, 0.2, 0.2, 0.6)

## Color for hover highlight (when not placing)
@export var hover_color: Color = Color(1.0, 1.0, 0.2, 0.4)

## Outline color when using outline style
@export var outline_color: Color = Color.WHITE

## Outline width in pixels
@export_range(1.0, 10.0) var outline_width: float = 3.0

@export_group("Area Settings")
## Area size for AREA mode (in tiles)
@export var area_size: Vector2i = Vector2i(3, 3)

## Radius for RADIUS mode (in tiles)
@export var radius: int = 2

## Custom offsets for CUSTOM mode (relative hex coordinates)
@export var custom_offsets: Array[Vector2i] = []

@export_group("Animation")
## Whether to animate the preview
@export var animate: bool = true

## Animation speed multiplier
@export_range(0.1, 5.0) var animation_speed: float = 1.0

## Pulse effect intensity (0.0 = none, 1.0 = full)
@export_range(0.0, 1.0) var pulse_intensity: float = 0.3

#endregion

#region Private Variables
## Reference to the tile map layer
@export var _tile_map: TileMapLayer = null

## Current hovered hex coordinates
var _current_hex: Vector2i = Vector2i.MIN

## Whether current placement is valid
var _is_valid: bool = true

## Animation time accumulator
var _anim_time: float = 0.0

## Cached hex positions for current preview
var _preview_hexes: Array[Vector2i] = []

## Custom validation function (hex_coords: Vector2i) -> bool
var _validation_func: Callable = func(_hex: Vector2i) -> bool: return true

## Cache for hex polygon points
var _hex_polygon: PackedVector2Array = []

#endregion

#region Initialization
func _ready() -> void:
	if not Engine.is_editor_hint():
		z_index = 100  # Draw on top
		modulate.a = preview_opacity

func _process(delta: float) -> void:
	if not enabled or not animate:
		return

	_anim_time += delta * animation_speed
	queue_redraw()

#endregion

#region Public Methods
## Set the tile map to preview on
func set_tile_map(tile_map: TileMapLayer) -> void:
	_tile_map = tile_map
	if _tile_map:
		_calculate_hex_polygon()

## Set custom validation function
func set_validation_function(validation_func: Callable) -> void:
	_validation_func = validation_func

## Update preview at world position
func update_preview(world_pos: Vector2) -> void:
	if not _tile_map or not enabled:
		return

	var hex_coords := _tile_map.local_to_map(world_pos)

	if hex_coords != _current_hex:
		_current_hex = hex_coords
		hover_changed.emit(hex_coords)

	_update_preview_hexes()
	_validate_placement()
	queue_redraw()

## Update preview at specific hex coordinates
func update_preview_at_hex(hex_coords: Vector2i) -> void:
	if not _tile_map or not enabled:
		return

	if hex_coords != _current_hex:
		_current_hex = hex_coords
		hover_changed.emit(hex_coords)

	_update_preview_hexes()
	_validate_placement()
	queue_redraw()

## Get the currently hovered hex coordinates
func get_hovered_hex() -> Vector2i:
	return _current_hex

## Get all hexes in the current preview
func get_preview_hexes() -> Array[Vector2i]:
	return _preview_hexes.duplicate()

## Check if current placement is valid
func is_placement_valid() -> bool:
	return _is_valid

## Manually set placement validity (overrides validation function)
func set_validity(is_valid: bool) -> void:
	if _is_valid != is_valid:
		_is_valid = is_valid
		validity_changed.emit(_is_valid)
		queue_redraw()

## Clear the preview
func clear_preview() -> void:
	_current_hex = Vector2i.MIN
	_preview_hexes.clear()
	queue_redraw()

## Set custom shape for CUSTOM preview mode
func set_custom_shape(offsets: Array[Vector2i]) -> void:
	custom_offsets = offsets
	if preview_mode == PreviewMode.CUSTOM:
		_update_preview_hexes()
		queue_redraw()

## Add hex offset to custom shape
func add_to_custom_shape(offset: Vector2i) -> void:
	if not custom_offsets.has(offset):
		custom_offsets.append(offset)
		if preview_mode == PreviewMode.CUSTOM:
			_update_preview_hexes()
			queue_redraw()

## Remove hex offset from custom shape
func remove_from_custom_shape(offset: Vector2i) -> void:
	var idx = custom_offsets.find(offset)
	if idx >= 0:
		custom_offsets.remove_at(idx)
		if preview_mode == PreviewMode.CUSTOM:
			_update_preview_hexes()
			queue_redraw()

#endregion

#region Private Methods
func _update_preview_hexes() -> void:
	_preview_hexes.clear()

	if _current_hex == Vector2i.MIN:
		return

	match preview_mode:
		PreviewMode.SINGLE:
			_preview_hexes.append(_current_hex)

		PreviewMode.AREA:
			for x in range(area_size.x):
				for y in range(area_size.y):
					_preview_hexes.append(_current_hex + Vector2i(x, y))

		PreviewMode.CUSTOM:
			for offset in custom_offsets:
				_preview_hexes.append(_current_hex + offset)

		PreviewMode.RADIUS:
			_preview_hexes = _get_hexes_in_radius(_current_hex, radius)

func _get_hexes_in_radius(center: Vector2i, rad: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []

	# Cube coordinates for hex distance calculation
	for q in range(-rad, rad + 1):
		for r in range(max(-rad, -q - rad), min(rad, -q + rad) + 1):
			hexes.append(center + Vector2i(q, r))

	return hexes

func _validate_placement() -> void:
	var was_valid := _is_valid
	_is_valid = true

	for hex in _preview_hexes:
		if not _validation_func.call(hex):
			_is_valid = false
			break

	if was_valid != _is_valid:
		validity_changed.emit(_is_valid)

func _calculate_hex_polygon() -> void:
	if not _tile_map:
		return

	var tile_set := _tile_map.tile_set
	if not tile_set:
		return

	var tile_size := tile_set.tile_size
	var hex_size := Vector2(tile_size) * 0.5

	# Calculate hex vertices for pointy-top hexagon
	_hex_polygon.clear()
	for i in range(6):
		var angle := PI / 3.0 * i - PI / 6.0  # Start from top-right
		var x := hex_size.x * cos(angle)
		var y := hex_size.y * sin(angle)
		_hex_polygon.append(Vector2(x, y))

func _draw() -> void:
	if not _tile_map or not enabled or _preview_hexes.is_empty():
		return

	var tile_set := _tile_map.tile_set
	if not tile_set:
		return

	# Calculate pulse effect
	var pulse := 1.0
	if animate:
		pulse = 1.0 + sin(_anim_time * TAU) * pulse_intensity

	# Determine color based on validity
	var base_color := valid_color if _is_valid else invalid_color
	base_color.a *= pulse

	# Draw each hex in preview
	for hex in _preview_hexes:
		var world_pos := _tile_map.map_to_local(hex)
		var local_pos := to_local(world_pos)

		_draw_hex(local_pos, base_color)

func _draw_hex(pos: Vector2, color: Color) -> void:
	if _hex_polygon.is_empty():
		_calculate_hex_polygon()

	if _hex_polygon.is_empty():
		return

	# Transform polygon to position
	var transformed_polygon := PackedVector2Array()
	for point in _hex_polygon:
		transformed_polygon.append(pos + point)

	# Draw based on highlight style
	match highlight_style:
		HighlightStyle.FILL:
			draw_colored_polygon(transformed_polygon, color)

		HighlightStyle.OUTLINE:
			draw_polyline(transformed_polygon + PackedVector2Array([transformed_polygon[0]]),
						  outline_color, outline_width, true)

		HighlightStyle.BOTH:
			draw_colored_polygon(transformed_polygon, color)
			draw_polyline(transformed_polygon + PackedVector2Array([transformed_polygon[0]]),
						  outline_color, outline_width, true)

		HighlightStyle.TINT:
			# For tint mode, just draw a subtle fill
			var tint_color := color
			tint_color.a *= 0.3
			draw_colored_polygon(transformed_polygon, tint_color)

#endregion

#region Helper Functions
## Convert axial hex coordinates to cube coordinates
static func axial_to_cube(hex: Vector2i) -> Vector3i:
	var q := hex.x
	var r := hex.y
	var s := -q - r
	return Vector3i(q, r, s)

## Convert cube coordinates to axial hex coordinates
static func cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.y)

## Calculate distance between two hex coordinates
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var ac := axial_to_cube(a)
	var bc := axial_to_cube(b)
	return (abs(ac.x - bc.x) + abs(ac.y - bc.y) + abs(ac.z - bc.z)) / 2

## Get neighboring hex coordinates
static func get_hex_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions := [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]

	for dir in directions:
		neighbors.append(hex + dir)

	return neighbors

## Get line of hexes between two points
static func get_hex_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var distance := hex_distance(start, end)
	var results: Array[Vector2i] = []

	if distance == 0:
		results.append(start)
		return results

	for i in range(distance + 1):
		var t := float(i) / float(distance)
		var start_cube := axial_to_cube(start)
		var end_cube := axial_to_cube(end)

		var x: float = lerp(float(start_cube.x), float(end_cube.x), t)
		var y: float = lerp(float(start_cube.y), float(end_cube.y), t)
		var z: float = lerp(float(start_cube.z), float(end_cube.z), t)

		results.append(_round_cube(Vector3(x, y, z)))

	return results

static func _round_cube(cube: Vector3) -> Vector2i:
	var rx: float = round(cube.x)
	var ry: float = round(cube.y)
	var rz: float = round(cube.z)

	var x_diff: float = abs(rx - cube.x)
	var y_diff: float = abs(ry - cube.y)
	var z_diff: float = abs(rz - cube.z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(int(rx), int(ry))

#endregion
