# Hex Placement Preview - Quick Reference

## 🚀 Quick Setup (30 seconds)

```gdscript
# 1. Add nodes to your scene
@onready var tile_map: TileMapLayer = $TileMap
@onready var preview: HexPlacementPreview = $HexPlacementPreview

# 2. Initialize in _ready()
func _ready() -> void:
    preview.set_tile_map(tile_map)
    preview.enabled = true

# 3. Update in _input()
func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        preview.update_preview(get_global_mouse_position())
```

## 📋 Essential Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `enabled` | bool | true | Show/hide preview |
| `preview_mode` | PreviewMode | SINGLE | SINGLE, AREA, RADIUS, CUSTOM |
| `highlight_style` | HighlightStyle | BOTH | OUTLINE, FILL, TINT, BOTH |
| `valid_color` | Color | Green | Color when placement valid |
| `invalid_color` | Color | Red | Color when placement invalid |
| `preview_opacity` | float | 0.6 | Preview transparency (0-1) |

## 🎮 Preview Modes Cheatsheet

```gdscript
# Single Tile
preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE

# 3x3 Area
preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
preview.area_size = Vector2i(3, 3)

# 2-Tile Radius
preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
preview.radius = 2

# Custom L-Shape
preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
preview.set_custom_shape([
    Vector2i(0, 0),
    Vector2i(1, 0),
    Vector2i(0, 1)
])
```

## ✅ Validation Quick Patterns

### Block occupied tiles
```gdscript
var occupied: Dictionary = {}

preview.set_validation_function(func(hex: Vector2i) -> bool:
    return not occupied.has(hex)
)
```

### Restrict to terrain type
```gdscript
var terrain: Dictionary = {}  # hex -> type

preview.set_validation_function(func(hex: Vector2i) -> bool:
    return terrain.get(hex, "") == "grass"
)
```

### Range restriction
```gdscript
preview.set_validation_function(func(hex: Vector2i) -> bool:
    return abs(hex.x) <= 10 and abs(hex.y) <= 10
)
```

### Multiple conditions
```gdscript
preview.set_validation_function(func(hex: Vector2i) -> bool:
    return (not occupied.has(hex) and
            terrain.get(hex) == "buildable" and
            hex.x >= 0)
)
```

## 🔧 Common Methods

```gdscript
# Update preview
preview.update_preview(world_position)
preview.update_preview_at_hex(hex_coords)

# Query state
var hex = preview.get_hovered_hex()
var hexes = preview.get_preview_hexes()
var valid = preview.is_placement_valid()

# Control
preview.clear_preview()
preview.enabled = true/false
preview.set_validity(true/false)
```

## 📡 Signals

```gdscript
# Connect to signals
preview.hover_changed.connect(_on_hover_changed)
preview.validity_changed.connect(_on_validity_changed)

func _on_hover_changed(hex_coords: Vector2i) -> void:
    print("Now hovering: ", hex_coords)

func _on_validity_changed(is_valid: bool) -> void:
    print("Valid: ", is_valid)
```

## 🧮 Hex Math Utilities

```gdscript
# Distance between hexes
var dist = HexPlacementPreview.hex_distance(hex_a, hex_b)

# Get 6 neighbors
var neighbors = HexPlacementPreview.get_hex_neighbors(hex)

# Line between points
var line = HexPlacementPreview.get_hex_line(start, end)

# Coordinate conversion
var cube = HexPlacementPreview.axial_to_cube(hex)
var axial = HexPlacementPreview.cube_to_axial(cube)
```

## 🎨 Visual Styles

```gdscript
# Bright outline
preview.highlight_style = HexPlacementPreview.HighlightStyle.OUTLINE
preview.outline_width = 4.0
preview.outline_color = Color.YELLOW

# Transparent fill
preview.highlight_style = HexPlacementPreview.HighlightStyle.FILL
preview.valid_color = Color(0, 1, 0, 0.3)

# Pulsing animation
preview.animate = true
preview.animation_speed = 1.5
preview.pulse_intensity = 0.4
```

## 💡 Common Patterns

### Toggle Placement Mode
```gdscript
var placing := false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        placing = not placing
        preview.enabled = placing
```

### Place on Click
```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_select"):
        if preview.is_placement_valid():
            var hexes = preview.get_preview_hexes()
            for hex in hexes:
                place_object_at(hex)
```

### Dynamic Custom Shapes
```gdscript
# Start with center
preview.set_custom_shape([Vector2i(0, 0)])

# Add tiles on click
func _on_tile_clicked(hex: Vector2i) -> void:
    var offset = hex - preview.get_hovered_hex()
    preview.add_to_custom_shape(offset)
```

### Rotate Shape
```gdscript
func rotate_preview_clockwise() -> void:
    var shape = preview.custom_offsets
    var rotated: Array[Vector2i] = []
    for offset in shape:
        rotated.append(Vector2i(-offset.y, offset.x + offset.y))
    preview.set_custom_shape(rotated)
```

## 🎯 Game-Specific Examples

### Building Placement
```gdscript
# Show 2x2 building footprint
preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
preview.area_size = Vector2i(2, 2)
preview.set_validation_function(func(hex): return not is_occupied(hex))
```

### Spell AOE
```gdscript
# Show 3-tile radius spell effect
preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
preview.radius = 3
preview.valid_color = Color(1, 0.5, 0, 0.5)  # Orange
```

### Unit Movement Range
```gdscript
# Show where unit can move
preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
preview.radius = unit.movement_speed
preview.valid_color = Color(0.2, 0.5, 1, 0.4)  # Blue
```

### Tower Attack Range
```gdscript
# Show tower coverage
preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
preview.radius = tower.attack_range
preview.highlight_style = HexPlacementPreview.HighlightStyle.OUTLINE
preview.outline_color = Color.RED
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Preview not showing | Check `enabled = true` and `set_tile_map()` called |
| Wrong position | Ensure HexPlacementPreview at (0,0) or adjust coords |
| No validation | Set validation function with `set_validation_function()` |
| Performance issues | Disable animation, reduce radius/area size |
| Wrong hex shape | Check TileSet tile_shape = TILE_SHAPE_HEXAGON |

## 📦 Export for Inspector

Add `@export` to make properties editable in inspector:

```gdscript
@export var my_preview: HexPlacementPreview
```

Then drag the HexPlacementPreview node to the exported variable in the inspector.

## 🔗 Integration with Other Systems

### With State Machine
```gdscript
match current_state:
    State.PLACING_BUILDING:
        preview.enabled = true
        preview.preview_mode = PreviewMode.AREA
    State.CASTING_SPELL:
        preview.enabled = true
        preview.preview_mode = PreviewMode.RADIUS
    _:
        preview.enabled = false
```

### With Resource System
```gdscript
preview.set_validation_function(func(hex: Vector2i) -> bool:
    var cost = get_building_cost()
    return player_resources >= cost and not is_occupied(hex)
)
```

### With Multiplayer
```gdscript
# Only show preview for local player
preview.enabled = is_multiplayer_authority()
```

---

**Need more help?** Check the full documentation at `docs/hex_placement_preview.md`
