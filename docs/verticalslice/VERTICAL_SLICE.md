# VERTICAL SLICE: 10-Step Implementation Plan
**Project:** SUITS: Iron Harvest
**Goal:** Create a minimal but fully playable demonstration of the core gameplay loop
**Estimated Scope:** 2-4 weeks for solo dev with AI assistance
**Success Criteria:** One complete day → plant → night → defend → survive loop that's actually fun

## Related Documentation
- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design and how everything connects
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Project vision and requirements
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Code quality guidelines

**Update Policy**: As you implement each step, update ARCHITECTURE.md with new systems, signal flows, and architectural decisions.

---

## What the Vertical Slice Must Include
- **One playable map:** Small hex-grid farm area (15x15 tiles minimum)
- **Day/Night cycle:** 60 seconds day, 45 seconds night (adjustable via constants)
- **3 Crop types:** Fast/cheap, medium, slow/valuable
- **2 Enemy types:** Basic melee rusher, ranged shooter
- **1 Mech:** Player-controlled with movement + one weapon type
- **1 Tower type:** Auto-targeting turret
- **Economy loop:** Plant → harvest → earn credits → buy upgrades/towers
- **Win condition:** Survive 3 nights
- **Loss condition:** Mech destroyed
- **Minimal UI:** Credits counter, day/night timer, wave number, health bar

---

## Step 1: Hex Grid Foundation & Camera
**Why First:** Everything else depends on the grid coordinate system.

### Deliverables:
- [ ] Create `res://scenes/world/HexGrid.tscn` with TileMapLayer node
- [ ] Configure TileSet with hexagonal flat-top shape (tile size 64x56 or similar)
- [ ] Add 3 tile types: farmable_soil, non-farmable, walkable_path
- [ ] Paint a 15x15 test map manually (no procedural gen yet)
- [ ] Implement `HexGrid.gd` with utility functions:
  - `world_to_hex(pos: Vector2) -> Vector2i`
  - `hex_to_world(hex: Vector2i) -> Vector2`
  - `get_neighbors(hex: Vector2i) -> Array[Vector2i]`
- [ ] Add Camera2D with smooth follow and zoom controls (mouse wheel)
- [ ] Visual test: Click anywhere → print hex coordinates

**Acceptance Test:** Click any tile and see correct hex coords in console; camera pans smoothly.

---

## Step 2: Mech Controller (Player Character)
**Why Second:** Player needs to exist before anything can interact with them.

### Deliverables:
- [ ] Create `res://scenes/entities/mech/Mech.tscn` (CharacterBody2D)
- [ ] Add temp sprite (Kenney.nl topdown-shooter tank or mech placeholder)
- [ ] Implement `Mech.gd`:
  - WASD movement (speed: 200 px/s)
  - Mouse-aim rotation (look_at or angle_to)
  - Basic collision shape (CircleShape2D or small hexagon)
- [ ] Add health system (HP: 100, signal `health_changed`, signal `died`)
- [ ] Spawn mech at map center on scene load
- [ ] Camera follows mech

**Acceptance Test:** Move mech around with WASD, mech sprite rotates toward mouse cursor.

---

## Step 3: Day/Night Cycle Manager
**Why Third:** This is the game's heartbeat—everything gates on day vs night state.

### Deliverables:
- [ ] Create autoload singleton `res://autoload/TimeManager.gd`
- [ ] Define states: `enum Phase { DAY, NIGHT, TRANSITION }`
- [ ] Implement timer-based cycle:
  - Day duration: 60s
  - Night duration: 45s
  - Emit signals: `day_started`, `night_started`, `day_time_remaining(seconds)`
- [ ] Add simple UI label showing "DAY 1" / "NIGHT 1" and countdown
- [ ] Change background color/ambient light on phase switch (day=yellow tint, night=blue tint)
- [ ] Block night from starting if wave still active (extend night until clear)

**Acceptance Test:** Watch 2 full cycles auto-run; UI updates correctly; lighting shifts.

---

## Step 4: Crop System (Planting, Growth, Harvest) ✅ COMPLETED
**Why Fourth:** Core economic engine—no crops = no money = no upgrades.

### Deliverables:
- [x] Create `res://scenes/entities/crops/BaseCrop.tscn` (Area2D)
- [x] Define crop data in `res://src/systems/CropDatabase.gd`:
  - Extensible registration system (easy to add new crops)
  - CropType enum: WHEAT, CORN, ALIEN_FRUIT
  - CropData class with all stats (grow_time, cost, value, color)
- [x] Implement `BaseCrop.gd`:
  - Growth states: PLANTED → GROWING → HARVESTABLE ✅
  - Visual: Colored sprites with scaling animation ✅
  - Only grows during DAY phase (integrates with TimeManager) ✅
  - Click to harvest when ready → emit `harvested(crop_type, value, hex_coords)` ✅
  - Hover indicator for interaction feedback ✅
  - Harvest particle effect ✅
- [x] Create PlantingSystem (`src/systems/PlantingSystem.gd`):
  - Press 1/2/3 key → enter placement mode for crop type ✅
  - Ghost preview on hover (green = valid, red = invalid) ✅
  - Click to plant if valid tile and enough credits ✅
  - ESC to cancel placement mode ✅
  - Tracks all planted crops by hex coordinates ✅
- [x] Connect to EconomyManager:
  - Deduct cost on plant ✅
  - Add value on harvest ✅
  - Credit validation before planting ✅
- [x] Created EconomyManager autoload (early implementation for Step 5)
- [x] Added input actions (crop_1, crop_2, crop_3) to project.godot
- [x] Updated ARCHITECTURE.md with farming system documentation

**Acceptance Test:** Plant 3 wheat, watch them grow over 30s of day-time, click to harvest, see credits increase.

**Implementation Notes:**
- Crops load real sprites from `/assets/Fruit and Veg/` with fallback to colored placeholders
- Growth is time-based and only progresses during DAY phase
- PlantingSystem validates tile placement (no overlap, valid tiles only)
- Visual feedback for valid/invalid placement and hover states
- All crop constants centralized in `config/crop_config.gd` (NO magic numbers)
- Established config separation pattern for future systems (tower_config, enemy_config, etc.)

---

## Step 5: Economy & Upgrade System (Credits & Shop)
**Why Fifth:** Money makes the combat systems possible.

### Deliverables:
- [ ] Create autoload `res://autoload/EconomyManager.gd`
  - `var credits: int = 100` (starting cash)
  - Functions: `add_credits(amount)`, `spend_credits(amount) -> bool`
  - Signal: `credits_changed(new_amount)`
- [ ] Connect crop harvests → `EconomyManager.add_credits(value)`
- [ ] Create simple UI panel `res://scenes/ui/HUD.tscn`:
  - Credits display (top-left)
  - Current phase & timer (top-center)
  - Mech health bar (bottom-center)
- [ ] Create basic upgrade shop panel (press TAB to open during day):
  - "Repair Mech" button (cost 50, restores 50 HP)
  - "Weapon Damage +10%" (cost 100, persistent)
  - "Max HP +25" (cost 150, persistent)
- [ ] Persist upgrades in `res://autoload/ProgressManager.gd` (even just vars for now)

**Acceptance Test:** Harvest crops → see credits increase → buy upgrade → tooltip shows effect.

---

## Step 6: Enemy Spawning & Basic AI
**Why Sixth:** Can't defend if there's nothing to defend against.

### Deliverables:
- [ ] Create `res://scenes/entities/enemies/BaseEnemy.tscn` (CharacterBody2D)
- [ ] Create 2 enemy types inheriting BaseEnemy:
  - **Rusher:** Fast melee (speed 150, HP 30, damage 10 on collision with mech)
  - **Shooter:** Slow ranged (speed 80, HP 50, fires projectile every 2s)
- [ ] Implement `BaseEnemy.gd`:
  - Simple pathfinding: move toward mech position (direct Vector2.move_toward for now)
  - Health system + death (drop small particle effect + queue_free)
- [ ] Create autoload `res://autoload/WaveManager.gd`:
  - Tracks current wave number
  - On night start → spawn wave around map edges
  - Wave scaling formula: `enemy_count = 5 + (wave_num * 3)`, mix 70% rushers / 30% shooters
  - Signal: `wave_cleared` when all enemies dead → trigger day phase
- [ ] Object pooling setup (simple array-based pool for now)

**Acceptance Test:** Night starts → 5-8 enemies spawn at edges → move toward mech → die when shot.

---

## Step 7: Mech Weapon & Combat ✅ COMPLETED
**Why Seventh:** Player needs to fight back.

### Deliverables:
- [x] Add weapon to Mech:
  - Left-click fires projectile toward mouse cursor ✅
  - Fire rate: 0.3s cooldown (roughly 3 shots/sec) ✅
  - Ammo: Infinite (resource management for v2.0) ✅
- [x] Create `res://scenes/entities/projectiles/Bullet.tscn` (Area2D) ✅
  - Speed: 400 px/s ✅
  - Damage: 10 (affected by player upgrades) ✅
  - Lifetime: 3s then queue_free ✅
  - On `area_entered` → damage enemy if valid ✅
- [x] Add hit feedback:
  - Enemy flash white for 0.1s ✅
  - Spawn impact particle (Kenney explosion sprite or white circle) ✅
- [ ] Add sound effects (placeholder beeps OK):
  - Mech shoots
  - Enemy hit
  - Enemy dies

**Acceptance Test:** Shoot enemies during night → they take damage → die after enough hits → wave clears. ✅

**Implementation Notes:**
- WeaponSystem implemented in `src/systems/WeaponSystem.gd` with 50-bullet object pool
- Bullet class in `src/entities/projectiles/Bullet.gd` with collision detection and damage application
- MechController integrated with WeaponSystem for firing via left-click
- Damage multiplier support for future upgrades (Step 5)
- Particle effects on bullet hit (CPUParticles2D) with configurable count/speed
- All weapon balance values in `config/weapon_config.gd` (NO magic numbers)
- Fire rate: 0.3 seconds (3.33 shots/sec), damage: 10 per bullet, bullet speed: 400 px/s

---

## Step 8: Tower Placement & Auto-Targeting
**Why Eighth:** Core tower-defense mechanic unlocked.

### Deliverables:
- [ ] Create `res://scenes/entities/towers/BasicTurret.tscn` (Node2D or StaticBody2D)
- [ ] Implement `BasicTurret.gd`:
  - Cost: 75 credits
  - Detection range: 300px (Area2D detection zone)
  - Fires at nearest enemy in range every 1.0s
  - Damage: 15 per shot
  - Reuses Bullet.tscn with different color/speed
- [ ] Tower placement system:
  - Press T → enter placement mode
  - Ghost preview follows mouse on valid tiles (not on crops, not on path)
  - Click to place if player has credits
  - ESC to cancel
- [ ] Visual tower range indicator (dashed circle when placing)

**Acceptance Test:** Place 2 towers during day → at night they auto-shoot enemies in range.

---

## Step 9: Win/Loss Conditions & Game Loop
**Why Ninth:** Makes it an actual game with stakes.

### Deliverables:
- [ ] Implement loss condition:
  - Mech HP reaches 0 → pause game → show "DEFEAT" screen
  - Button: "Restart" (reload scene)
- [ ] Implement win condition:
  - Survive 3 full night waves → pause → show "VICTORY" screen
  - Display stats: Total credits earned, enemies killed, crops harvested
- [ ] Add basic pause menu (ESC key):
  - Resume
  - Restart
  - Quit to desktop
- [ ] Ensure game loop works:
  - Day 1 → plant → night 1 → defend → day 2 → expand → night 2 → defend → day 3 → night 3 → WIN

**Acceptance Test:** Play full 3-wave cycle → either die and restart, or win and see victory screen.

---

## Step 10: Polish, Juice & Playtesting
**Why Last:** Make it feel good to play before calling it a vertical slice.

### Deliverables:
- [ ] Add screen shake on:
  - Mech takes damage (medium shake)
  - Enemy dies (small shake)
  - Tower shoots (tiny shake)
- [ ] Particle effects:
  - Crop harvest (small green sparkles)
  - Enemy death (explosion)
  - Mech damaged (red flash + sparks)
- [ ] Audio:
  - Background music track (synthwave for night, calm for day)
  - All SFX assigned (use freesound.org or AI-generated)
- [ ] UI polish:
  - Animate credit counter (+25 floats up)
  - Wave intro overlay ("NIGHT 2 - INCOMING!")
  - Tooltips on hover for crops/towers
- [ ] Balance pass:
  - Can you reasonably win wave 3 with starting credits?
  - Are crops worth planting vs just tower rushing?
  - Adjust costs/timers/damage as needed
- [ ] Get 3 external playtesters:
  - Record session, watch where they get confused
  - Fix top 3 pain points

**Acceptance Test:** Playtesters complete 1 full cycle without asking "what do I do?" and say "that was fun."

---

## Definition of Done for Vertical Slice
✅ A new player can launch the game and understand the core loop within 30 seconds
✅ One complete 3-night cycle is winnable and fun
✅ All 10 systems work together without critical bugs
✅ Performance: 60 FPS with 50+ enemies on screen (potato-test on integrated GPU)
✅ Codebase is clean enough that AI agents can extend it without breaking things
✅ You can confidently show this to a publisher/investor/Steam demo audience

---

## What's Explicitly OUT of Scope (save for post-vertical-slice)
❌ Procedural map generation (use handmade 15x15 for now)
❌ Multiple mech types / loadouts
❌ Meta-progression between runs
❌ Boss enemies
❌ Advanced pathfinding (A* grid can wait)
❌ Multiplayer / co-op
❌ Advanced graphics (shaders, lighting, post-processing)
❌ Controller support
❌ Localization
❌ Advanced tutorial system (tooltips are enough)

---

---

## Completed Steps Summary

✅ **Step 4** - Crop System (Planting, Growth, Harvest)
✅ **Step 6** - Enemy Spawning & Basic AI
✅ **Step 7** - Mech Weapon & Combat

---

## Post-Vertical-Slice Roadmap (Quick Preview)
**Phase 2:** Content Expansion (more crops, enemies, towers, 10-wave mode)
**Phase 3:** Procedural generation + infinite mode
**Phase 4:** Meta-progression (unlocks between runs)
**Phase 5:** Steam Early Access prep (achievements, cloud saves, settings)
