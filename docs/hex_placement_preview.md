# Hex Placement Preview Tool

A comprehensive tool for visualizing placement and highlighting on hexagonal tile maps in Godot 4.x.

## Features

- ✅ **Multiple Preview Modes**: Single tile, area, radius, and custom shapes
- ✅ **Flexible Highlighting**: Outline, fill, tint, or combined styles
- ✅ **Validation System**: Custom validation functions for placement rules
- ✅ **Visual Feedback**: Valid/invalid color coding with animated effects
- ✅ **Hex Utilities**: Distance calculation, pathfinding helpers, neighbor finding
- ✅ **Performance Optimized**: Efficient drawing and caching mechanisms

## Quick Start

### 1. Basic Setup

```gdscript
extends Node2D

@onready var tile_map: TileMapLayer = $TileMap
@onready var preview: HexPlacementPreview = $HexPlacementPreview

func _ready() -> void:
	preview.set_tile_map(tile_map)
	preview.enabled = true
```

### 2. Update Preview Position

```gdscript
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		preview.update_preview(mouse_pos)
```

### 3. Add Validation

```gdscript
func _ready() -> void:
	# ... previous setup code ...
	preview.set_validation_function(_is_valid_placement)

func _is_valid_placement(hex_coords: Vector2i) -> bool:
	# Your validation logic here
	return not is_tile_occupied(hex_coords)
```

## Preview Modes

### Single Tile Mode
Previews a single hexagonal tile at the cursor position.

```gdscript
preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE
```

### Area Mode
Previews a rectangular area of tiles.

```gdscript
preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
preview.area_size = Vector2i(3, 3)  # 3x3 area
```

### Radius Mode
Previews all tiles within a specified radius.

```gdscript
preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
preview.radius = 2  # 2-tile radius
```

### Custom Mode
Previews a custom shape defined by hex offsets.

```gdscript
preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM

# Define an L-shape
var l_shape: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(0, 1),
	Vector2i(0, 2),
]
preview.set_custom_shape(l_shape)
```

## Highlight Styles

### Outline
Draws only the outline of tiles.

```gdscript
preview.highlight_style = HexPlacementPreview.HighlightStyle.OUTLINE
preview.outline_width = 3.0
preview.outline_color = Color.WHITE
```

### Fill
Fills tiles with a solid color.

```gdscript
preview.highlight_style = HexPlacementPreview.HighlightStyle.FILL
```

### Tint
Applies a subtle tint over tiles.

```gdscript
preview.highlight_style = HexPlacementPreview.HighlightStyle.TINT
```

### Both
Combines outline and fill.

```gdscript
preview.highlight_style = HexPlacementPreview.HighlightStyle.BOTH
```

## Color Configuration

```gdscript
# Valid placement color (green)
preview.valid_color = Color(0.2, 1.0, 0.2, 0.6)

# Invalid placement color (red)
preview.invalid_color = Color(1.0, 0.2, 0.2, 0.6)

# Hover color (yellow)
preview.hover_color = Color(1.0, 1.0, 0.2, 0.4)

# Overall opacity
preview.preview_opacity = 0.6
```

## Animation

Enable pulsing animation for visual feedback:

```gdscript
preview.animate = true
preview.animation_speed = 1.0
preview.pulse_intensity = 0.3  # 0.0 = no pulse, 1.0 = full pulse
```

## Validation System

The validation system allows you to define custom rules for placement:

```gdscript
func _ready() -> void:
	preview.set_validation_function(_complex_validation)

func _complex_validation(hex_coords: Vector2i) -> bool:
	# Check multiple conditions
	if is_tile_occupied(hex_coords):
		return false

	if not is_tile_buildable(hex_coords):
		return false

	if not has_adjacent_road(hex_coords):
		return false

	return true
```

## Signals

### hover_changed
Emitted when the cursor moves to a different hex tile.

```gdscript
preview.hover_changed.connect(_on_hover_changed)

func _on_hover_changed(hex_coords: Vector2i) -> void:
	print("Hovering over: ", hex_coords)
```

### validity_changed
Emitted when placement validity changes.

```gdscript
preview.validity_changed.connect(_on_validity_changed)

func _on_validity_changed(is_valid: bool) -> void:
	if is_valid:
		print("Can place here!")
	else:
		print("Cannot place here!")
```

## Public Methods

### Core Methods

#### `set_tile_map(tile_map: TileMapLayer)`
Sets the tile map to preview on.

#### `update_preview(world_pos: Vector2)`
Updates the preview at a world position (e.g., mouse position).

#### `update_preview_at_hex(hex_coords: Vector2i)`
Updates the preview at specific hex coordinates.

#### `clear_preview()`
Clears the preview display.

### Query Methods

#### `get_hovered_hex() -> Vector2i`
Returns the currently hovered hex coordinates.

#### `get_preview_hexes() -> Array[Vector2i]`
Returns all hexes in the current preview.

#### `is_placement_valid() -> bool`
Checks if the current placement is valid.

### Shape Manipulation

#### `set_custom_shape(offsets: Array[Vector2i])`
Sets a custom shape for CUSTOM mode.

#### `add_to_custom_shape(offset: Vector2i)`
Adds a tile offset to the custom shape.

#### `remove_from_custom_shape(offset: Vector2i)`
Removes a tile offset from the custom shape.

### Validation

#### `set_validation_function(validation_func: Callable)`
Sets a custom validation function.

#### `set_validity(is_valid: bool)`
Manually overrides placement validity.

## Static Helper Functions

### hex_distance(a: Vector2i, b: Vector2i) -> int
Calculates the distance between two hex coordinates.

```gdscript
var dist = HexPlacementPreview.hex_distance(Vector2i(0, 0), Vector2i(3, 2))
print("Distance: ", dist)
```

### get_hex_neighbors(hex: Vector2i) -> Array[Vector2i]
Returns all neighboring hex coordinates.

```gdscript
var neighbors = HexPlacementPreview.get_hex_neighbors(Vector2i(0, 0))
for neighbor in neighbors:
	print("Neighbor: ", neighbor)
```

### get_hex_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]
Returns a line of hexes between two points (useful for pathfinding visualization).

```gdscript
var line = HexPlacementPreview.get_hex_line(Vector2i(0, 0), Vector2i(5, 3))
for hex in line:
	print("Line hex: ", hex)
```

### axial_to_cube(hex: Vector2i) -> Vector3i
Converts axial hex coordinates to cube coordinates.

### cube_to_axial(cube: Vector3i) -> Vector2i
Converts cube coordinates to axial hex coordinates.

## Complete Example

Here's a complete example integrating all features:

```gdscript
extends Node2D

@onready var tile_map: TileMapLayer = $TileMap
@onready var preview: HexPlacementPreview = $HexPlacementPreview

var occupied_tiles: Dictionary = {}
var placement_mode: bool = false

func _ready() -> void:
    # Setup preview
    preview.set_tile_map(tile_map)
    preview.set_validation_function(_validate)
    preview.enabled = false

    # Configure appearance
    preview.highlight_style = HexPlacementPreview.HighlightStyle.BOTH
    preview.valid_color = Color(0.2, 1.0, 0.2, 0.6)
    preview.invalid_color = Color(1.0, 0.2, 0.2, 0.6)
    preview.animate = true

    # Connect signals
    preview.hover_changed.connect(_on_hover_changed)
    preview.validity_changed.connect(_on_validity_changed)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        toggle_placement_mode()

    if placement_mode:
        if event is InputEventMouseMotion:
            preview.update_preview(get_global_mouse_position())

        if event.is_action_pressed("ui_select"):
            if preview.is_placement_valid():
                place_objects()

func toggle_placement_mode() -> void:
    placement_mode = not placement_mode
    preview.enabled = placement_mode
    if not placement_mode:
        preview.clear_preview()

func _validate(hex_coords: Vector2i) -> bool:
    return not occupied_tiles.has(hex_coords)

func place_objects() -> void:
    var hexes = preview.get_preview_hexes()
    for hex in hexes:
        occupied_tiles[hex] = true
        # Place your object here

    # Refresh preview
    preview.update_preview(get_global_mouse_position())

func _on_hover_changed(hex_coords: Vector2i) -> void:
    # Display tooltip or info
    pass

func _on_validity_changed(is_valid: bool) -> void:
    # Play feedback sound
    pass
```

## Performance Tips

1. **Validation Caching**: If validation is expensive, cache results:
   ```gdscript
   var validation_cache: Dictionary = {}

   func _validate(hex: Vector2i) -> bool:
       if not validation_cache.has(hex):
           validation_cache[hex] = _expensive_validation(hex)
       return validation_cache[hex]
   ```

2. **Limit Preview Size**: For radius/area modes, cap the maximum size:
   ```gdscript
   preview.radius = min(requested_radius, 5)
   ```

3. **Disable Animation**: For better performance on low-end devices:
   ```gdscript
   preview.animate = false
   ```

## Troubleshooting

### Preview not appearing
- Ensure `enabled = true`
- Check that `set_tile_map()` has been called
- Verify the TileMapLayer node exists and has a valid TileSet
- Check z_index if preview is being drawn behind other elements

### Preview position incorrect
- Ensure the HexPlacementPreview node is at position (0,0) or adjust calculations
- Verify the tile map's transform matches expectations

### Hex shape wrong
- The script assumes pointy-top hexagons
- Check your TileSet's tile_shape setting (should be TILE_SHAPE_HEXAGON)

## License

This tool is provided as-is for use in your Godot projects.
