# 🏰 Tower System Demo

**Purpose:** Test and demonstrate tower placement mechanics, range detection, enemy targeting, and integration with the game economy.

**Related Systems:**
- TowerSystem.gd (placement and management)
- BaseTower.gd (base tower class)
- GatlingGun.gd (rapid-fire tower type)
- TowerDatabase.gd (tower registry)
- TowerWeaponSystem.gd (projectile management)
- EconomyManager (credit integration)
- WaveManager (enemy spawning)

---

## Features Demonstrated

### ✅ Tower Placement
- **Ghost Preview:** Semi-transparent tower preview follows mouse cursor
- **Validation Feedback:**
  - **Green preview** = Valid placement location
  - **Red preview** = Invalid location (occupied, invalid tile)
- **Credit Deduction:** Towers cost 50 credits; prevents placement if insufficient funds
- **Placement Confirmation:** Click on valid tile to place tower

### ✅ Range Visualization
- **Detection Circle:** Shows the 250px detection range of towers during placement
- **Visual Indicator:** Dashed circle showing exact firing range
- **Real-time Updates:** Range indicator updates as cursor moves during placement mode

### ✅ Enemy Targeting
- **Nearest Enemy Selection:** Towers automatically target closest enemy in range
- **Firing Animation:** Towers rotate/animate while firing at targets
- **Bullet Pooling:** Efficient projectile reuse (100-bullet pool per tower)
- **Hit Effects:** Yellow impact particles when bullets hit enemies

### ✅ Economy Integration
- **Credit Display:** Shows available credits in top-right corner
- **Cost Deduction:** 50 credits per tower placement
- **Insufficient Funds:** Shows feedback if player can't afford tower

### ✅ Wave Management
- **Auto-Wave Spawning:** Enemies spawn at night automatically via WaveManager
- **Wave Info:** Current wave number displayed
- **Enemy Count:** Live display of enemies on map

### ✅ Day/Night Cycle
- **Phase Switching:** Automatic day/night transitions
- **Visual Feedback:** Ambient color changes (yellow day, blue night)
- **Tower Behavior:** Towers only fire at night when enemies are present

---

## How to Use

### 1. Launch the Demo
```
Open: demos/mechanics/TowerSystem/TowerSystemDemo.tscn
```

### 2. Understand the Layout
- **Left Panel:** Instructions and tower stats
- **Right Panel:** Live status (phase, credits, tower count, enemy count)
- **Center:** Hex grid map with mech (player character)
- **Camera:** Auto-follows mech with mouse wheel zoom

### 3. Test Tower Placement

#### Enter Placement Mode
Press **T** to enter tower placement mode
- Message: `TowerSystem: Entered placement mode for Gatling Gun (cost: 50)`
- Preview sprite appears on mouse cursor
- Range indicator shows detection radius

#### Place a Tower
1. Move mouse over the hex grid
2. Preview shows **green** for valid locations, **red** for invalid
3. Click on valid tile to place tower (costs 50 credits)
4. Tower appears on map and begins detecting enemies
5. Credits deducted automatically
6. System exits placement mode after successful placement

#### Cancel Placement
- Press **ESC** or **Right Click** to cancel
- No credits deducted
- Returns to normal mode

### 4. Test Targeting & Firing

#### Spawn Enemies
- Wait for night phase to begin (automatic ~60s into demo)
- Enemies spawn at map edges
- Enemies move toward mech

#### Watch Towers Fire
- Towers detect enemies within 250px range (shown in preview)
- Towers target **nearest enemy**
- Fire rate: 5 shots/second (0.2s between shots)
- Yellow bullets fire from tower toward enemy
- Each bullet deals 8 damage

#### Observe Tower Behavior
- **Firing Animation:** Tower sprite rotates during firing
- **Hit Feedback:** Enemies flash white when hit
- **Particle Effects:** Yellow impact particles on bullet hit
- **Target Switching:** Tower switches to new nearest enemy if current dies

### 5. Validate Placement Rules

#### Invalid Placements (Red Preview)
- On top of existing tower
- On top of crops (from PlantingSystem)
- On tiles that don't exist (map edges)
- Out of bounds

#### Valid Placements (Green Preview)
- Empty farmable tiles
- Valid hex coordinates
- Sufficient funds available

---

## Configuration

All tower balance values are in **config/tower_config.gd**:

```gdscript
# Gatling Gun Settings
const TOWER_GATLING_GUN_COST: int = 50              # 50 credits
const TOWER_GATLING_GUN_RANGE: float = 250.0        # 250px detection radius
const TOWER_GATLING_GUN_DAMAGE: float = 8.0         # 8 damage per shot
const TOWER_GATLING_GUN_FIRE_RATE: float = 0.2      # 0.2s = 5 shots/sec
const TOWER_GATLING_GUN_BULLET_SPEED: float = 350.0 # Projectile speed

# Placement Feedback
const TOWER_PLACEMENT_VALID_COLOR: Color = Color(0.0, 1.0, 0.0, 0.5)   # Green
const TOWER_PLACEMENT_INVALID_COLOR: Color = Color(1.0, 0.0, 0.0, 0.5)  # Red
const TOWER_RANGE_INDICATOR_COLOR: Color = Color(0.5, 0.8, 1.0, 0.3)    # Blue
```

---

## Key Classes Reference

### TowerSystem (src/systems/TowerSystem.gd)
**Responsible for:**
- Tower placement mode (enter/exit)
- Tile validation for placement
- Credit spending integration
- Ghost preview and range visualization

**Key Methods:**
```gdscript
enter_placement_mode(tower_type: TowerDatabase.TowerType)
exit_placement_mode()
can_place_tower_at(hex_coords: Vector2i) -> bool
get_all_towers() -> Array[BaseTower]
```

**Signals:**
```gdscript
signal tower_placed(hex_coords: Vector2i, tower_type: TowerDatabase.TowerType)
signal placement_mode_changed(active: bool, tower_type: TowerDatabase.TowerType)
```

### BaseTower (src/entities/towers/BaseTower.gd)
**Responsible for:**
- Enemy detection in range
- Targeting logic (nearest enemy)
- Fire rate management
- Abstract fire() method for subclasses

**Key Methods:**
```gdscript
find_nearest_enemy() -> BaseEnemy
get_enemies_in_range() -> Array[BaseEnemy]
get_current_target() -> BaseEnemy
```

### GatlingGun (src/entities/towers/GatlingGun.gd)
**Responsible for:**
- Rapid-fire behavior (0.2s between shots)
- Bullet spread pattern (small inaccuracy for visual interest)
- Firing animation (sprite rotation)
- TowerWeaponSystem integration

**Fire Behavior:**
```gdscript
func fire() -> void:
    # Fires yellow projectile at nearest enemy
    # Small spread angle for visual variety
    # 8 damage per bullet
    # Instantaneous firing (pooled bullets)
```

### TowerWeaponSystem (src/systems/TowerWeaponSystem.gd)
**Responsible for:**
- Tower projectile pooling (100 bullets per tower)
- Bullet spawning and firing
- Collision detection and damage application
- Hit particle effects

### TowerDatabase (src/systems/TowerDatabase.gd)
**Responsible for:**
- Tower type registry (extensible system)
- Loading tower data from config files
- Immutable TowerData objects for safe access

---

## Testing Scenarios

### Scenario 1: Basic Placement
1. Start demo (200 credits default)
2. Press T to enter placement mode
3. Hover over various tiles and observe green/red feedback
4. Place 4 towers (costs 50 each = 200 total)
5. Verify all towers appear on map
6. Verify preview becomes invalid (no more funds)

**Expected Results:**
- ✅ Preview correctly shows valid/invalid tiles
- ✅ Credits deducted on successful placement
- ✅ Cannot place without sufficient funds
- ✅ Towers persist on map

### Scenario 2: Range Detection
1. Place tower near center of map
2. Start night phase (auto-spawn enemies)
3. Watch enemies enter and exit tower detection range
4. Observe tower targeting behavior

**Expected Results:**
- ✅ Tower detects enemies within 250px
- ✅ Tower fires at nearest enemy
- ✅ Tower stops firing when no enemies in range
- ✅ Tower switches targets as enemies move

### Scenario 3: Combat Effectiveness
1. Place 3-4 towers around mech
2. Start night phase
3. Let towers defend against waves
4. Observe:
   - Tower firing patterns
   - Bullet impact effects
   - Enemy health reduction
   - Wave completion

**Expected Results:**
- ✅ Towers fire at appropriate rate (5 shots/sec)
- ✅ Bullets deal damage (8 per shot)
- ✅ Enemies take 12-13 shots to kill (100 HP / 8 damage)
- ✅ Multiple towers can target same enemy
- ✅ Wave clears when all enemies dead

### Scenario 4: Placement Conflicts
1. Plant crops using PlantingSystem (press 1-3 keys)
2. Try to place tower on top of crop
3. Preview should show red (invalid)

**Expected Results:**
- ✅ Cannot place tower on crop
- ✅ Preview correctly shows invalid tile
- ✅ No credit deduction on invalid placement

---

## Common Issues & Solutions

### Problem: Tower doesn't fire at enemies
**Solution:**
- Verify tower is in range (show ghost preview to see range circle)
- Check that enemies are in "enemies" group (WaveManager sets this)
- Check enemy health > 0 (dead enemies won't be targeted)

### Problem: Ghost preview doesn't show
**Solution:**
- Verify TowerSystem.show_preview = true (check .tscn file)
- Verify tower_type is valid (GATLING_GUN defined in TowerDatabase)
- Check that sprite texture can load from config/tower_config.gd

### Problem: Placement doesn't deduct credits
**Solution:**
- Verify EconomyManager is initialized (check autoload in project.godot)
- Verify EconomyManager.can_afford() returns true
- Check PlantingSystem isn't already tracking that hex (tile_occupied check)

### Problem: No enemies spawn at night
**Solution:**
- Verify WaveManager is initialized (check autoload)
- Verify TimeManager.night_started signal is emitted
- Check enemy scenes exist (RusherEnemy.tscn, ShooterEnemy.tscn)

---

## Next Steps / Future Enhancements

1. **Tower Variety:** Add Sniper Tower and Flame Tower types (config already prepared)
2. **Upgrades:** Upgrade towers after placement (damage, range, fire rate)
3. **Tower Destruction:** Enemies can destroy towers (add HP system)
4. **Visual Polish:** Add tower selection highlight, placement grid overlay
5. **Sound Effects:** Add tower firing and bullet impact sounds
6. **Pathfinding:** Enemies use A* pathfinding instead of direct movement
7. **Special Abilities:** Towers have special attack modes (burst, sweep, etc.)

---

## Demo Files

```
demos/mechanics/TowerSystem/
├── TowerSystemDemo.gd          # Demo controller script
├── TowerSystemDemo.tscn        # Demo scene
├── README.md                   # This file
└── VISUAL_GUIDE.md            # Screenshots and visual reference (optional)
```

---

## Related Documentation

- **ARCHITECTURE.md** - Tower system design and integration
- **FILE_STRUCTURE.md** - Project file organization
- **CODING_STANDARDS.md** - Code style and patterns
- **VERTICAL_SLICE.md** - Step 8 Tower Placement & Auto-Targeting

---

**Last Updated:** When Step 8 tower system was completed
**Maintained By:** AI agents and core development team
