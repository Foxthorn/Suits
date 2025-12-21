# Crop System Demo

## Overview
Interactive demo scene for testing the complete crop planting and economy system.

## What This Tests
- ✅ HexGrid tile selection and hover feedback
- ✅ PlantingSystem placement mode (keys 1/2/3)
- ✅ Ghost preview (green = valid, red = invalid)
- ✅ Credit validation before planting
- ✅ Crop growth gated by DAY phase (TimeManager)
- ✅ Harvest interaction (click harvestable crops)
- ✅ EconomyManager integration (credits deducted/added)
- ✅ Visual feedback (scaling, pulsing, particles)

## How to Run
1. Open `CropSystemDemo.tscn` in Godot
2. Press F5 or click Play Scene (F6)
3. Follow on-screen instructions

## Controls

### Planting
- **1** - Select Wheat (10 credits, 30s grow, +25 value)
- **2** - Select Corn (25 credits, 60s grow, +80 value)
- **3** - Select Alien Fruit (50 credits, 90s grow, +200 value)
- **ESC** - Exit placement mode
- **Click** - Plant crop (in placement mode) or Harvest (when ready)

### Camera
- **Mouse Wheel** - Zoom in/out
- **Arrow Keys** - Pan camera

### Debug Cheats
- **C** - Add 100 credits
- **F** - Fast-forward 10 seconds (speed up testing)
- **N** - Force night phase
- **D** - Force day phase
- **R** - Reset demo (reload scene)

## Testing Workflow

### Basic Flow Test
1. Press **1** to enter Wheat placement mode
2. Click a tile to plant (costs 10 credits → 90 remaining)
3. Watch crop grow (scale increases from 0.5 to 1.0)
4. Wait 30 seconds of DAY time
5. Crop becomes harvestable (pulsing animation)
6. Click crop to harvest (+25 credits → 115 total)

### Phase Gating Test
1. Plant a crop during DAY
2. Press **N** to force NIGHT
3. Observe: Crop growth **pauses** during night
4. Press **D** to force DAY
5. Observe: Crop growth **resumes**

### Credit Validation Test
1. Spend all credits planting crops
2. Try to plant another crop
3. Observe: Red invalid feedback (insufficient credits)
4. Press **C** to add credits
5. Now planting works again

### Multi-Crop Test
1. Plant 3 different crop types simultaneously
2. Observe different growth rates:
   - Wheat: 30s
   - Corn: 60s
   - Alien Fruit: 90s
3. Use **F** to fast-forward if needed
4. Harvest all 3 and verify correct values

### Tile Validation Test
1. Enter placement mode (press 1/2/3)
2. Hover over empty tiles → ghost is **green**
3. Plant a crop
4. Hover over occupied tile → ghost is **red**
5. Try to click → red flash feedback (invalid placement)

## Expected Behavior

### Visual Feedback
- **Ghost Preview**: Transparent sprite follows mouse
- **Valid Placement**: Green tint (0, 1, 0, 0.5)
- **Invalid Placement**: Red tint (1, 0, 0, 0.5)
- **Invalid Click**: Red flash at cursor position
- **Crop States**:
  - PLANTED: 0.5 scale, darkened color
  - GROWING: 0.5 → 1.0 scale (smooth transition)
  - HARVESTABLE: 1.0 scale, pulsing alpha (0.7 ↔ 1.0)
- **Harvest Effect**: Colored particles burst upward

### Console Output
Check console for debug messages:
```
[CropSystemDemo] Initializing demo...
[CropSystemDemo] Demo ready! Press 1/2/3 to start planting.
PlantingSystem: Entered placement mode for Wheat
PlantingSystem: Planted Wheat at hex (7, 5) for 10 credits
EconomyManager: -10 credits (remaining: 90)
BaseCrop: Planted Wheat at hex (7, 5) (grow time: 30.0s)
BaseCrop: Wheat state changed to GROWING
BaseCrop: Wheat state changed to HARVESTABLE
BaseCrop: Harvested Wheat at hex (7, 5) for 25 credits!
EconomyManager: +25 credits (total: 115)
```

## Known Issues / Limitations
- Demo uses placeholder colored squares (sprites not implemented)
- No save/load functionality (demo resets on restart)
- No tile type validation (all tiles treated as farmable)
- Camera follows grid center (not a mech character)

## Success Criteria
✅ Can plant all 3 crop types
✅ Ghost preview changes color based on validity
✅ Credits deducted when planting
✅ Crops only grow during DAY phase
✅ Can harvest crops when ready
✅ Credits added on harvest
✅ Particle effect plays on harvest
✅ Can plant new crop on harvested tile
✅ Multiple crops can grow simultaneously
✅ Console output shows no errors

## Troubleshooting

### "PlantingSystem: hex_grid not assigned!"
- Open CropSystemDemo.tscn
- Select PlantingSystem node
- Verify hex_grid property points to ../HexGrid

### "CropDatabase: Invalid crop_type"
- Verify GameConfig.gd has crop constants defined
- Check CropDatabase._ensure_initialized() is called

### Crops not growing
- Check TimeManager is running (should see countdown in HUD)
- Verify current phase is DAY (crops don't grow at night)
- Use debug cheat **D** to force day phase

### Ghost preview not showing
- Check PlantingSystem.show_preview is true
- Verify you're in placement mode (press 1/2/3)
- Check console for texture creation errors

## Related Files
- `CropSystemDemo.gd` - Demo scene script
- `CropSystemDemo.tscn` - Demo scene
- `src/systems/PlantingSystem.gd` - Planting logic
- `src/systems/CropDatabase.gd` - Crop definitions
- `src/entities/crops/BaseCrop.gd` - Crop entity
- `autoload/EconomyManager.gd` - Credit management
- `autoload/TimeManager.gd` - Day/night cycle

## Next Steps
After verifying this demo works:
1. ✅ Mark Step 4 as tested
2. → Move to Step 5: Economy UI & Upgrade Shop
3. → Add proper crop sprites (replace colored squares)
4. → Implement tile type system (farmable vs non-farmable)
