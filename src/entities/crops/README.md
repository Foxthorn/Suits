# Crop System

## Overview
The crop system handles planting, growth, and harvesting mechanics. Crops are the primary economic engine in SUITS: Iron Harvest.

## Key Components

### BaseCrop.gd
Individual crop entity with three growth states:
- **PLANTED**: Just planted, 50% scale, darkened color
- **GROWING**: Actively growing, scale increases from 0.5 to 1.0
- **HARVESTABLE**: Ready to harvest, full scale, pulsing animation

**Growth Rules**:
- Crops only grow during DAY phase (via TimeManager)
- Growth timer pauses during NIGHT
- Player can click to harvest when HARVESTABLE

### CropDatabase.gd
Centralized crop definitions using an extensible registration system.

**Current Crops**:
- **Wheat**: 30s grow time, 10 cost, 25 value (fast/cheap)
- **Corn**: 60s grow time, 25 cost, 80 value (balanced)
- **Alien Fruit**: 90s grow time, 50 cost, 200 value (slow/expensive)

**Adding New Crops**:
```gdscript
# 1. Add to enum
enum CropType {
    WHEAT = 0,
    CORN = 1,
    ALIEN_FRUIT = 2,
    NEW_CROP = 3  # Add here
}

# 2. Register in _ensure_initialized()
CropDatabase.register_crop(CropData.new(
    CropType.NEW_CROP,
    "New Crop Name",
    grow_time,
    cost,
    value,
    "Description",
    Color.BLUE
))
```

### PlantingSystem.gd
Handles crop placement logic and player interaction.

**Controls**:
- Press `1`: Select Wheat
- Press `2`: Select Corn
- Press `3`: Select Alien Fruit
- Click tile: Plant selected crop (if valid)
- `ESC`: Exit placement mode

**Validation**:
- Tile must exist in HexGrid
- Tile must be farmable (not occupied)
- Player must have enough credits

## Integration

### EconomyManager
- Planting deducts credits: `EconomyManager.spend_credits(cost)`
- Harvesting adds credits: `EconomyManager.add_credits(value)`

### TimeManager
- Crops only grow during DAY phase
- Growth timer pauses during NIGHT

### HexGrid
- Uses `tile_clicked` and `tile_hovered` signals for placement
- Validates hex coordinates via `has_tile()`

## Signals

### BaseCrop
- `harvested(crop_type, value, hex_coords)` - When crop is harvested
- `growth_state_changed(new_state)` - When growth state transitions

### PlantingSystem
- `crop_planted(hex_coords, crop_type)` - When crop is planted
- `placement_mode_changed(active, crop_type)` - When placement mode toggles

## Future Enhancements
- Crop diseases/pests (requires maintenance)
- Fertilizer system (speed up growth)
- Crop rotation bonuses
- Seasonal crops (only plantable in certain phases)
- Multi-tile crops (e.g., 2x2 or 3x3 plants)
