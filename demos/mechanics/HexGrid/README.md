# Hex Placement Preview Tool

> A professional, feature-complete tool for hexagonal tile placement visualization in Godot 4.x

## 📦 What's Included

### Core Files
- **`hex_placement_preview.gd`** - Main tool class with all preview functionality
- **`hex_placement_example.gd`** - Basic usage example with mouse input
- **`hex_placement_advanced_examples.gd`** - Advanced patterns for various game types

### Documentation
- **`../../docs/hex_placement_preview.md`** - Complete API documentation
- **`../../docs/hex_placement_quick_reference.md`** - Quick reference guide
- **`hex_placement_preview_changelog.md`** - Version history and roadmap

### Tests
- **`../../tests/test_hex_placement_preview.gd`** - Comprehensive unit tests (60+ tests)

### Demo
- **`../../scenes/HexPlacementDemo.tscn`** - Interactive demo scene

## 🚀 Quick Start

1. **Add to your scene:**
   ```
   Node2D (your scene)
   ├─ TileMapLayer (your hex tile map)
   └─ HexPlacementPreview (add as Node2D with script)
   ```

2. **Attach script to your scene:**
   ```gdscript
   extends Node2D

   @onready var tile_map: TileMapLayer = $TileMap
   @onready var preview: HexPlacementPreview = $HexPlacementPreview

   func _ready() -> void:
       preview.set_tile_map(tile_map)

   func _input(event: InputEvent) -> void:
       if event is InputEventMouseMotion:
           preview.update_preview(get_global_mouse_position())
   ```

3. **Run your scene** - You should see the hex preview following your mouse!

## 🎯 Use Cases

This tool is perfect for:

- **City Builders** - Preview building footprints and construction zones
- **Tower Defense** - Show tower range and placement restrictions
- **Strategy Games** - Display unit movement ranges and attack areas
- **RPGs** - Visualize spell AOE and area effects
- **Puzzle Games** - Highlight valid tile placements
- **Board Games** - Show valid moves and selections

## 📖 Documentation

- **New to this tool?** Start with `../../docs/hex_placement_quick_reference.md`
- **Need detailed info?** Check `../../docs/hex_placement_preview.md`
- **Want examples?** See `hex_placement_example.gd` and `hex_placement_advanced_examples.gd`
- **Testing?** Run tests in `../../tests/test_hex_placement_preview.gd` using GUT

## 🎮 Preview Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **SINGLE** | Single hex tile | Basic placement, cursor position |
| **AREA** | Rectangular grid of tiles | Buildings, structures |
| **RADIUS** | Circular radius around center | Spell effects, tower range |
| **CUSTOM** | Custom shape from offsets | Complex buildings, special shapes |

## ✨ Key Features

### Visual Feedback
- ✅ Valid/invalid color coding
- ✅ Multiple highlight styles (outline, fill, tint)
- ✅ Animated pulse effects
- ✅ Adjustable opacity and colors

### Validation System
- ✅ Custom validation functions
- ✅ Per-tile validation
- ✅ Real-time validity checking
- ✅ Validation signals

### Hex Utilities
- ✅ Distance calculation
- ✅ Neighbor finding
- ✅ Line drawing
- ✅ Coordinate conversion

### Customization
- ✅ Dynamic shape editing
- ✅ Shape rotation
- ✅ Multiple preview modes
- ✅ Style configuration

## 🔧 API Overview

```gdscript
# Setup
preview.set_tile_map(tile_map)
preview.set_validation_function(your_validation_func)

# Update
preview.update_preview(world_position)
preview.update_preview_at_hex(hex_coords)

# Query
var hex = preview.get_hovered_hex()
var hexes = preview.get_preview_hexes()
var valid = preview.is_placement_valid()

# Configure
preview.preview_mode = PreviewMode.RADIUS
preview.radius = 3
preview.highlight_style = HighlightStyle.BOTH
preview.valid_color = Color.GREEN
preview.animate = true

# Custom Shapes
preview.set_custom_shape([Vector2i(0,0), Vector2i(1,0)])
preview.add_to_custom_shape(Vector2i(0,1))

# Signals
preview.hover_changed.connect(func(hex): print(hex))
preview.validity_changed.connect(func(valid): print(valid))
```

## 🧪 Testing

Run the unit tests using GUT (Godot Unit Test):

```
# From Godot editor
1. Open the GUT panel
2. Select tests/test_hex_placement_preview.gd
3. Click "Run"
```

Or run the demo scene:
```
# From Godot editor
1. Open scenes/HexPlacementDemo.tscn
2. Press F5 to run
3. Use controls shown on screen
```

## 💡 Example: Building Placement

```gdscript
extends Node2D

@onready var preview: HexPlacementPreview = $HexPlacementPreview
var occupied_tiles: Dictionary = {}

func _ready() -> void:
    preview.set_tile_map($TileMap)
    preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
    preview.area_size = Vector2i(2, 2)
    preview.set_validation_function(_is_valid)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        preview.update_preview(get_global_mouse_position())

    if event.is_action_pressed("place") and preview.is_placement_valid():
        for hex in preview.get_preview_hexes():
            occupied_tiles[hex] = true

func _is_valid(hex: Vector2i) -> bool:
    return not occupied_tiles.has(hex)
```

## 📊 Performance

Optimized for:
- ✅ Hundreds of preview tiles
- ✅ Real-time updates (60 FPS+)
- ✅ Low memory footprint
- ✅ Mobile-friendly

Performance tips:
- Disable animation if not needed
- Limit radius/area size for complex validation
- Cache validation results when expensive

## 🤝 Integration

Works seamlessly with:
- TileMapLayer (Godot 4.x)
- Custom hex coordinate systems
- Multiplayer games (per-player previews)
- State machines
- Input systems
- Camera controllers

## 🔍 Troubleshooting

**Preview not visible?**
- Ensure `enabled = true`
- Check `set_tile_map()` was called
- Verify z_index (should be > 0)

**Wrong position?**
- Check HexPlacementPreview node position (should be 0,0)
- Verify TileSet configuration

**Performance issues?**
- Disable animations: `preview.animate = false`
- Reduce preview size
- Simplify validation function

See full troubleshooting in the main documentation.

## 📝 License

See project LICENSE file.

## 🌟 Contributing

Found a bug? Have a feature request? See the project's issue tracker!

---

**Ready to build amazing hex-based games?** Start with the quick reference guide and explore the examples!
