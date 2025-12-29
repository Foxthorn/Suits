# ARCHITECTURE.md — System Design & Technical Architecture

> **Living Document**: This file documents the high-level architecture, system interactions, and design decisions for SUITS: Iron Harvest. Update this file whenever you make significant architectural changes.

---

## 🏗️ Table of Contents

1. [Overview](#overview)
2. [Core Architecture](#core-architecture)
3. [System Diagrams](#system-diagrams)
4. [Key Systems](#key-systems)
5. [Data Flow](#data-flow)
6. [Camera System](#camera-system)
7. [Scene Hierarchy](#scene-hierarchy)
8. [Performance Considerations](#performance-considerations)
9. [Future Architecture Plans](#future-architecture-plans)

---

## Overview

SUITS: Iron Harvest is built on Godot 4.3+ using a modular, signal-driven architecture designed to scale from initial prototyping to full production with 1000+ simultaneous enemies.

### Design Philosophy

- **Decoupled Systems**: Systems communicate via signals through EventBus, not direct references
- **Single Responsibility**: Each system manages one domain (farming, combat, waves, etc.)
- **Scene Composition**: Prefer scene inheritance and composition over deep class hierarchies
- **Performance-First**: Designed for 60fps with 1000+ active entities via pooling and shared paths

---

## Core Architecture

### High-Level System Layers

```
┌─────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                     │
│  (UI, HUD, Menus, Visual Effects, Camera)                   │
└─────────────────────────────────────────────────────────────┘
                            ↕ Signals
┌─────────────────────────────────────────────────────────────┐
│                      GAME LOGIC LAYER                        │
│  (MainGame, HexGrid, MechController, WaveManager)           │
└─────────────────────────────────────────────────────────────┘
                            ↕ Signals
┌─────────────────────────────────────────────────────────────┐
│                      CORE SYSTEMS LAYER                      │
│  (EventBus, GameConfig, SaveManager, PathfindingSystem)     │
└─────────────────────────────────────────────────────────────┘
                            ↕ Direct Access
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAYER                            │
│  (Game State, Save Data, Configuration)                     │
└─────────────────────────────────────────────────────────────┘
```

### Autoload Singletons (Global Systems)

These systems are available globally via `Autoload` and manage cross-cutting concerns:

| Singleton | Purpose | Key Responsibilities |
|-----------|---------|---------------------|
| `EventBus` | Central signal hub | Global event routing (wave_started, day_ended, etc.) |
| `GameConfig` | Configuration constants | All balance values, enums, and tunable settings |
| `TimeManager` | Day/night cycle | Phase management, timer progression, wave blocking |
| `EconomyManager` | Player economy | Credits tracking, spending validation, balance management |
| `SaveManager` | Persistence | Save/load game state, player progression |
| `WaveManager` | Wave spawning & scaling | Enemy spawn calculation, wave tracking, progression signals |
| `AudioManager` | Audio playback | Music, SFX, volume control |

---

## System Diagrams

### Main Game Loop

```
┌──────────────┐
│  MainGame    │ (Root Scene)
│  (Node2D)    │
└──────┬───────┘
       │
       ├─────► HexGrid (manages grid, camera input, placement)
       │         │
       │         └─────► TileMapLayer (visual grid representation)
       │
       ├─────► Mech (player-controlled entity)
       │         │
       │         └─────► MechController (movement, shooting, health)
       │
       ├─────► Camera2D (shared camera, managed by HexGrid)
       │
       ├─────► DayNightTint (visual cycle effects)
       │
       └─────► HUD (health bars, resources, wave timer)
```

### Signal Flow Example: Enemy Death

```
Enemy.took_damage() → Enemy.health <= 0
    │
    └──► Enemy.die()
        └──► Enemy.died.emit(self)
            │
            ├──► WaveManager._on_enemy_died()
            │       └──► Remove from enemies_in_wave array
            │           └──► If array empty: wave_completed.emit()
            │               └──► TimeManager.set_wave_active(false)
            │
            ├──► HUD._on_enemy_died()
            │       └──► Updates enemy count display
            │
            └──► (Future) DropSystem._on_enemy_died()
                    └──► Spawns loot/resources
```

---

## Key Systems

### HexGrid System

**Purpose**: Manages hexagonal grid logic, tile queries, coordinate conversion, and camera control.

**Location**: `src/systems/HexGrid.gd`

**Key Responsibilities**:
- Convert between world positions and hex coordinates (axial system)
- Provide neighbor calculations and distance queries
- Handle tile placement validation
- Manage camera input (zoom, pan, mech following)
- Emit signals for tile clicks and hover events

**Exported Properties**:
```gdscript
@export var tile_map_layer: TileMapLayer    # Visual grid
@export var camera: Camera2D                 # Shared camera reference
@export var mech_node: Node2D                # Target for camera following
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var smooth_camera: bool = true
```

**Public API**:
```gdscript
func world_to_hex(world_pos: Vector2) -> Vector2i
func hex_to_world(hex_coords: Vector2i) -> Vector2
func get_neighbors(hex: Vector2i) -> Array[Vector2i]
func hex_distance(hex_a: Vector2i, hex_b: Vector2i) -> int
func has_tile(hex: Vector2i) -> bool
func get_camera() -> Camera2D
func set_camera_position(pos: Vector2) -> void
```

**Signals**:
- `tile_clicked(hex_coords: Vector2i, world_pos: Vector2)`
- `tile_hovered(hex_coords: Vector2i, world_pos: Vector2)`

---

### MechController System

**Purpose**: Player-controlled mech with movement, combat, and health management.

**Location**: `src/entities/player/MechController.gd`

**Key Responsibilities**:
- WASD/gamepad movement
- Mouse-aimed shooting (via WeaponSystem)
- Health and damage management
- Weapon/upgrade integration

**Signals**:
- `health_changed(current_hp: float, max_hp: float)`
- `died()`
- `position_changed(new_position: Vector2)`

**Input Actions**:
- `move_up/down/left/right`: WASD movement
- `fire`: Left-click to shoot

**Public API**:
```gdscript
func take_damage(amount: float) -> void
func heal(amount: float) -> void
func set_health(value: float) -> void
func get_health_percentage() -> float
func upgrade_max_health(amount: float) -> void
func upgrade_weapon_damage(amount: float) -> void
func set_weapon_damage_multiplier(multiplier: float) -> void
```

---

### WeaponSystem

**Purpose**: Manages mech weapon firing, cooldowns, and projectile pooling.

**Location**: `src/systems/WeaponSystem.gd`

**Key Responsibilities**:
- Fire rate management and cooldown tracking
- Projectile pooling for performance (50-bullet default pool)
- Spawning bullets in player-aimed direction
- Damage multiplier application from upgrades

**Signals**:
- `bullet_fired(bullet: Bullet, position: Vector2, direction: Vector2)`

**Public API**:
```gdscript
func fire(from_position: Vector2, direction: Vector2) -> void
func can_fire() -> bool
func upgrade_damage(bonus: float) -> void
func set_damage_multiplier(multiplier: float) -> void
```

---

### Bullet (Projectile Entity)

**Purpose**: Individual projectile with collision detection and damage.

**Location**: `src/entities/projectiles/Bullet.gd`

**Key Responsibilities**:
- Linear movement at constant velocity
- Lifetime management (3 second default)
- Enemy collision detection and damage
- Particle effect on impact
- Pooling support

**Signals**:
- `hit_enemy(enemy: BaseEnemy, damage: float)`
- `expired()`

**Public API**:
```gdscript
func set_velocity(direction: Vector2, spd: float = WeaponConfig.BULLET_SPEED) -> void
func reset() -> void
func prepare() -> void
```

---

### TimeManager System (Autoload)

**Purpose**: Manages the day/night cycle, game phase timing, and wave blocking.

**Location**: `autoload/TimeManager.gd`

**Key Responsibilities**:
- Track current phase (DAY, NIGHT, TRANSITION)
- Manage phase timers and transitions
- Block night from ending while wave is active
- Emit phase change signals for system coordination

**Signals**:
- `day_started(day_number: int)`
- `night_started(night_number: int)`
- `phase_time_remaining(seconds_left: float)`
- `phase_changed(new_phase: Phase)`

**Public API**:
```gdscript
func is_day() -> bool
func is_night() -> bool
func pause_cycle() -> void
func resume_cycle() -> void
func set_wave_active(active: bool) -> void
```

---

### EconomyManager System (Autoload)

**Purpose**: Manages player credits, spending validation, and economic transactions.

**Location**: `autoload/EconomyManager.gd`

**Key Responsibilities**:
- Track player credit balance
- Validate spending transactions
- Emit credit change events for UI updates

**Signals**:
- `credits_changed(new_amount: int)`
- `insufficient_credits(attempted_cost: int, current_credits: int)`

**Public API**:
```gdscript
func add_credits(amount: int) -> void
func spend_credits(amount: int) -> bool
func can_afford(amount: int) -> bool
func get_credits() -> int
```

---

### Enemy System (Hierarchy)

**Purpose**: Defines the enemy entity structure with extensible types for different behaviors, sprite sheet animation support, and centralized database.

**Location**: `src/entities/enemies/`

**Architecture**:

#### EnemyDatabase System (`src/systems/EnemyDatabase.gd`)
**Purpose**: Centralized registry for all enemy types with extensible registration pattern.

**Key Features**:
- Static-only class with registry pattern (no instantiation needed)
- Automatic initialization on first access
- Extensible via `register_enemy()` method
- Loads all constants from `EnemyConfig` automatically
- Provides lookup methods for type-safe enemy data access

**Public API**:
```gdscript
static func get_enemy(type: EnemyType) -> EnemyData
static func get_enemy_name(type: EnemyType) -> String
static func get_all_enemy_types() -> Array[EnemyType]
static func register_enemy(enemy_data: EnemyData) -> void
```

**EnemyData Class**:
Immutable data structure containing all enemy configuration:
- Core stats: `speed`, `max_health`, `damage`, `name`, `description`
- Sprite assets: Main sprite + per-animation sprite sheets (idle, walk, attack, hit, death)
- Animation frames: Per-animation frame counts for sprite sheet division
- Visual: `color` (fallback if sprites fail to load)
- Debug: `debug_draw` flag for logging
- Methods: `get_idle_sprite()`, `get_walk_sprite()`, `get_attack_sprite()`, `get_hit_sprite()`, `get_death_sprite()`

**To Add New Enemy Type**:
1. Add to `EnemyType` enum in EnemyDatabase
2. Add constants to `config/enemy_config.gd`:
   - `ENEMY_NAME`, `ENEMY_DESCRIPTION`
   - `ENEMY_SPEED`, `ENEMY_MAX_HP`, `ENEMY_DAMAGE`
   - `ENEMY_SPRITE`, sprite sheet paths for each animation
   - `ENEMY_*_FRAMES` for frame counts
3. Call `EnemyDatabase.register_enemy()` in `_ensure_initialized()`

---

#### BaseEnemy (`src/entities/enemies/BaseEnemy.gd`)
**Purpose**: Base class for all enemy types with sprite sheet animation support.

**Location**: `src/entities/enemies/BaseEnemy.gd`

**Key Responsibilities**:
- Load enemy data from EnemyDatabase on spawn
- Health and damage system with signals (`health_changed`, `died`, `animation_state_changed`)
- Sprite sheet animation with state machine (IDLE, WALK, ATTACK, HIT, DEATH)
- Direct movement toward mech via target tracking
- Death handling with configurable animation duration before particle effects
- Collision detection and physics-based movement
- Animation frame progression based on state and frame count

**Exported Properties**:
```gdscript
@export var enemy_type: EnemyDatabase.EnemyType = EnemyDatabase.EnemyType.RUSHER
@export var debug_draw: bool = false  # Override per-instance
```

**Animation States** (enum):
- `IDLE`: Stationary animation (4 frames default)
- `WALK`: Movement animation (4 frames default)
- `ATTACK`: Attacking animation (5 frames default)
- `HIT`: Damage reaction animation (2 frames default)
- `DEATH`: Death animation (4 frames default)

**Signals**:
- `died(enemy: BaseEnemy)` - Emitted when health reaches 0
- `health_changed(current_hp: float, max_hp: float)` - Emitted on damage
- `animation_state_changed(new_state: AnimationState)` - Emitted when animation state changes

**Key Methods**:
```gdscript
func _set_animation_state(new_state: AnimationState) -> void  # Switch animation
func _update_animation(delta: float) -> void                   # Advance frames
func _update_sprite_direction(direction: Vector2) -> void      # Flip sprite
func take_damage(amount: float) -> void                        # Health -= amount, play HIT animation
func die() -> void                                              # Play DEATH, wait for animation, then cleanup
func get_health_percent() -> float                             # Returns 0.0-1.0 for UI bars
```

**Sprite Sheet Animation System**:
- Loads sprite sheets from EnemyData
- Uses `hframes` property to divide sprites into frames
- Frame advancement: Increments `_animation_frame` at `ANIMATION_SPEED` rate
- Wraps frame count per animation state
- Sprite flipping: Horizontal flip based on movement direction
- Fallback: Procedurally generated placeholder if sprite fails to load

---

#### RusherEnemy (`src/entities/enemies/RusherEnemy.gd`)
**Purpose**: Fast melee attacker that rushes the mech.

**Location**: `scenes/entities/enemies/RusherEnemy.tscn` + `src/entities/enemies/RusherEnemy.gd`

**Stats** (from EnemyConfig):
- Speed: 150 px/s (RUSHER_SPEED)
- Health: 30 HP (RUSHER_MAX_HP)
- Damage: 10 per collision (RUSHER_DAMAGE)
- Collision Cooldown: 1.0s (RUSHER_COLLISION_COOLDOWN)

**Animation Assets** (all from Insect-Enemy-Pack-V.1):
- Little-Enemy sprite sheets (5 animations: idle, walk, attack, hit, death)
- Configurable frame counts per animation

**Behavior**:
- Direct movement toward mech at high speed
- Plays WALK animation during movement
- Plays IDLE animation when stationary
- Plays ATTACK animation when dealing damage (TODO: implement collision detection)
- Plays HIT animation when taking damage
- Plays DEATH animation before being removed

---

#### ShooterEnemy (`src/entities/enemies/ShooterEnemy.gd`)
**Purpose**: Ranged attacker that maintains distance and fires projectiles.

**Location**: `scenes/entities/enemies/ShooterEnemy.tscn` + `src/entities/enemies/ShooterEnemy.gd`

**Stats** (from EnemyConfig):
- Speed: 80 px/s (SHOOTER_SPEED)
- Health: 50 HP (SHOOTER_MAX_HP)
- Damage: 15 per projectile hit (SHOOTER_DAMAGE)
- Fire Rate: 2.0 seconds (SHOOTER_FIRE_RATE)
- Projectile Range: 400px (SHOOTER_PROJECTILE_RANGE)

**Animation Assets** (all from Insect-Enemy-Pack-V.1):
- Fly-Enemy sprite sheets (5 animations: idle, walk, attack, hit, death)
- Configurable frame counts per animation

**Behavior**:
- Maintains distance from mech (800px detection range)
- Plays WALK animation during movement
- Plays IDLE animation when at range
- Plays ATTACK animation when firing projectile
- Plays HIT animation when taking damage
- Plays DEATH animation before being removed
- (TODO: Implement actual projectile spawning in Step 7)

---

**Extensibility Pattern**:
- New enemy types inherit from BaseEnemy
- Set `enemy_type` in `_ready()` before calling `super._ready()`
- Override `_physics_process()` for unique combat behaviors
- All stats automatically loaded from EnemyDatabase
- All configuration values in `config/enemy_config.gd` (NO hardcoding)

---

### WaveManager System (Autoload)

**Purpose**: Manages enemy wave spawning, difficulty scaling, and wave progression with proper entity instantiation.

**Location**: `autoload/WaveManager.gd` (✅ IMPLEMENTED)

**Key Responsibilities**:
- Calculate enemy counts per wave using exponential scaling formula
- Spawn RusherEnemy and ShooterEnemy from dedicated scene files
- Track active enemies via signal connections to `BaseEnemy.died`
- Signal wave start/completion to control day/night progression
- Manage wave state (active, completed, progression)

**Signals**:
- `wave_started(wave_number: int)` - Emitted when enemies spawn
- `wave_completed(wave_number: int)` - Emitted when all enemies defeated
- `all_waves_cleared()` - Emitted when full progression complete

**Scene References**:
```gdscript
var enemy_rusher_scene: PackedScene = preload("res://scenes/entities/enemies/RusherEnemy.tscn")
var enemy_shooter_scene: PackedScene = preload("res://scenes/entities/enemies/ShooterEnemy.tscn")
```

**Configuration** (via `config/enemy_config.gd`):
```gdscript
const WAVE_BASE_COUNT: int = 5              # Base enemies for wave 1
const WAVE_COUNT_PER_LEVEL: int = 3         # +3 enemies per wave
const WAVE_RUSHER_PERCENTAGE: float = 0.7   # 70% rushers, 30% shooters
const SPAWN_DISTANCE_FROM_MECH: float = 500.0  # Spawn 500px from mech
const SPAWN_POINTS_PER_WAVE: int = 4        # 4 spawn locations
const SPAWN_SPREAD_ANGLE: float = PI * 0.25 # 45° variation around points
```

**Wave Scaling Formula**:
```
enemy_count = 5 + (wave_number * 3)
Wave 1: 5 enemies
Wave 2: 8 enemies
Wave 3: 11 enemies
```

**Spawn Pattern**:
- Enemies spawn in 4 cardinal directions around mech
- Distance: 500px from mech center
- Random spread ±45° around cardinal points
- 70% spawn as RusherEnemy, 30% as ShooterEnemy
- RusherEnemy and ShooterEnemy instantiated from dedicated .tscn files
- Each enemy's stats are auto-loaded from EnemyDatabase on _ready()

**Integration with TimeManager**:
- WaveManager listens to `TimeManager.night_started` signal
- On night start, calls `start_wave(night_number)`
- Calls `TimeManager.set_wave_active(true)` to block day progression
- On `wave_completed`, calls `TimeManager.set_wave_active(false)` to allow day

**Enemy Tracking**:
- Maintains `enemies_in_wave: Array[BaseEnemy]`
- Connects to each enemy's `died` signal
- Removes dead enemies from array
- When array is empty, emits `wave_completed`

---

### Farming System

**Purpose**: Manages crop planting, growth, and harvest mechanics (✅ COMPLETED Step 4)

**Key Components**:

#### CropDatabase (`src/systems/CropDatabase.gd`)
- Centralized crop definitions with extensible registration system
- Defines crop types (WHEAT, CORN, ALIEN_FRUIT)
- Stores crop stats: grow time, cost, value, appearance

**Extensibility Pattern**:
```gdscript
# To add a new crop:
# 1. Add to CropType enum
# 2. Call register_crop() with new CropData
CropDatabase.register_crop(CropData.new(
    CropType.NEW_CROP,
    "Crop Name",
    grow_time,
    cost,
    value,
    "Description",
    Color.BLUE
))
```

#### BaseCrop (`src/entities/crops/BaseCrop.gd`)
- Individual crop entity with three growth states:
  - PLANTED: Just planted, small sprite (frame 1)
  - GROWING: Actively growing (frames 1-8, interpolated by progress)
  - HARVESTABLE: Ready to harvest, player can click (frame 8)
- Emits `harvested(crop_type, value, hex_coords)` signal
- Visual feedback: hover indicator, growth scaling, harvest particles

**Sprite Sheet Animation System**:
- Uses `AtlasTexture` to extract frames from multi-frame sprite sheets
- Standard format: 9 frames in a single horizontal row
  - Frame 0: Menu icon (not used in-game)
  - Frames 1-8: Growth progression (planted to harvestable)
- Frame mapping: `frame_index = 1 + (growth_progress * 7.0)` where progress is 0.0-1.0
- Frame width calculation: `texture.width / 9`

#### PlantingSystem (`src/systems/PlantingSystem.gd`)
- Handles crop placement mode (keys 1/2/3 for crop selection)
- Validates tile placement (farmable, unoccupied)
- Ghost preview with valid/invalid coloring
- Integrates with EconomyManager for cost deduction
- Tracks all planted crops by hex coordinates

**Signals**:
- `crop_planted(hex_coords: Vector2i, crop_type: CropType)`
- `placement_mode_changed(active: bool, crop_type: CropType)`

**Input Actions**:
- `crop_1`: Select Wheat (Key: 1)
- `crop_2`: Select Corn (Key: 2)
- `crop_3`: Select Alien Fruit (Key: 3)
- `ui_cancel`: Exit placement mode (ESC)

#### CropConfig (`config/crop_config.gd`)
- Centralized crop configuration following "NO MAGIC NUMBERS" standard
- Separates crop-specific config from global GameConfig
- Defines shared visual settings (scales, opacities, harvest effects) for ALL crops
- Defines per-crop data (names, descriptions, grow times, costs, values, sprite paths, fallback colors)
- **Extensibility**: Add new crop types by adding constants (e.g., CARROT_NAME, CARROT_GROW_TIME, etc.)

**Configuration Pattern**:
```gdscript
# config/crop_config.gd
class_name CropConfig extends Node

# Shared visual settings
const PLANTED_SCALE: float = 0.4
const HARVESTABLE_SCALE: float = 1.2
const HOVER_INDICATOR_SIZE: int = 48

# Per-crop data
const WHEAT_GROW_TIME: float = 30.0
const WHEAT_COST: int = 10
const WHEAT_VALUE: int = 25
const WHEAT_SPRITE: String = "Wheat.png"
```

**Benefits**:
- Eliminates magic numbers from entity scripts
- Clear visual hierarchy (shared vs per-crop settings)
- Easy to balance by tweaking one file
- **Future Pattern**: Similar configs for `tower_config.gd`, `enemy_config.gd`, `wave_config.gd`

---



### EventBus System (Autoload)

**Purpose**: Global signal hub for decoupled system communication.

**Location**: `autoload/EventBus.gd`

**Key Signals**:
```gdscript
signal day_started()
signal night_started()
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal mech_died()
signal crop_planted(hex: Vector2i, crop_type: int)
signal crop_harvested(hex: Vector2i, crop_type: int, value: int)
```

**Usage Pattern**:
```gdscript
# Emitting (from any system)
EventBus.wave_completed.emit(current_wave)

# Listening (in another system)
func _ready():
    EventBus.wave_completed.connect(_on_wave_completed)

func _on_wave_completed(wave_number: int):
    # React to wave completion
```

---

## Data Flow

### Farming System Flow

```
Player presses 1/2/3 → PlantingSystem.enter_placement_mode(crop_type)
    ↓
Player hovers tile → HexGrid.tile_hovered signal
    ↓
PlantingSystem shows ghost preview (green=valid, red=invalid)
    ↓
Player clicks → HexGrid.tile_clicked signal
    ↓
PlantingSystem validates placement + cost
    ↓
EconomyManager.spend_credits(cost)
    ↓
PlantingSystem instantiates BaseCrop at hex position
    ↓
BaseCrop loads sprite from CropData.get_sprite() → fallback to placeholder if sprite fails
    ↓
BaseCrop.start_growing() → Growth only during DAY phase
    ↓
Player clicks harvestable crop → BaseCrop.harvested signal
    ↓
EconomyManager.add_credits(value)
```

### Combat System Flow (Step 7: Mech Weapon)

```
Player clicks → Input.is_action_pressed("fire")
    ↓
MechController._handle_weapon()
    ↓
WeaponSystem.can_fire() check
    ↓
WeaponSystem.fire(from_position, direction)
    ↓
Get Bullet from object pool
    ↓
Bullet.set_velocity(direction, speed)
    ↓
Bullet moves via _physics_process
    ↓
Bullet.area_entered(Enemy)
    ↓
Enemy.take_damage(damage)
    ↓
Bullet.expired signal → Return to pool
    ↓
If enemy.health <= 0:
    Enemy.died.emit()
    ↓
    WaveManager._on_enemy_died()
    ↓
    Check if wave complete → wave_completed.emit()
```

---

## Camera System

### Architecture Decision: Single Shared Camera

**Design**: The main scene (`MainGame`) owns a single `Camera2D` node which is passed to `HexGrid` for management.

**Rationale**:
- **Single Source of Truth**: Only one camera is active, preventing conflicts
- **Centralized Control**: HexGrid handles all camera logic (zoom, pan, following)
- **Clear Ownership**: Scene tree shows camera hierarchy clearly
- **Flexible Integration**: Other systems can request camera reference via `HexGrid.get_camera()`

**Implementation**:
```gdscript
# MainGame.gd
@onready var camera: Camera2D = $Camera2D
@onready var hex_grid: HexGrid = $HexGrid

# Camera is wired to HexGrid in MainGame.tscn:
# camera = NodePath("../Camera2D")
```

**Camera Responsibilities** (handled by HexGrid):
1. **Zoom Control**: Mouse wheel zoom with min/max limits
2. **Mech Following**: Smooth lerp to follow mech position (configurable)
3. **Manual Panning**: Arrow key panning when not locked to mech
4. **Offset Management**: Manual pan offset when following mech

**Camera Access**:
```gdscript
# Other systems can get camera reference via HexGrid
var camera = hex_grid.get_camera()
camera.position = some_target_position
```

### Design Notes

**Why not create camera internally?**
- Scene tree clarity: Camera ownership is visible in scene hierarchy
- Flexibility: Easy to swap camera types or add camera modifiers
- Debugging: Can inspect camera in remote scene tree
- No hidden state: All nodes are explicit in the scene

---

## Scene Hierarchy

### MainGame.tscn (Root Scene)

```
MainGame (Node2D)
├── HexGrid (HexGrid.tscn instance)
│   ├── TileMapLayer (renders hex grid)
│   └── (manages camera reference)
├── Mech (Mech.tscn instance)
│   ├── CollisionShape2D
│   ├── Sprite2D
│   └── (weapons, effects as children)
├── Camera2D (shared, managed by HexGrid)
├── DayNightTint (CanvasModulate)
└── HUD (HUD.tscn instance)
    ├── HealthBar
    ├── ResourceDisplay
    └── WaveTimer
```

### Entity Hierarchy (Standard Pattern)

All entities (enemies, crops, towers) follow this pattern:

```
EntityName (Area2D or CharacterBody2D)
├── CollisionShape2D
├── Sprite2D or AnimatedSprite2D
├── HealthBar (if applicable)
├── Timers (AttackTimer, etc.)
└── Effects (Particles, AudioStreamPlayer2D)
```

---

## Performance Considerations

### Object Pooling Strategy

**Implemented For**:
- Bullets (high spawn rate)
- Enemies (100+ per wave)
- Particles/VFX (burst effects)

**Pattern**:
```gdscript
# Pool.gd utility class
class_name Pool extends Node

var _pool: Array[Node] = []
var _scene: PackedScene

func get_instance() -> Node:
    if _pool.is_empty():
        return _scene.instantiate()
    return _pool.pop_back()

func return_instance(instance: Node) -> void:
    instance.hide()
    instance.set_process(false)
    _pool.append(instance)
```

### Pathfinding Optimization

**Strategy**: Shared pre-baked paths per wave

```gdscript
# WaveManager calculates path ONCE per wave
var _shared_path: PackedVector2Array

func spawn_wave():
    _shared_path = _calculate_path()  # Single A* calculation
    for i in enemy_count:
        var enemy = spawn_enemy()
        enemy.set_path(_shared_path)  # All enemies use same path
```

**Benefits**:
- 1000 enemies = 1 pathfinding calculation instead of 1000
- Enemies can still have minor variations (random offset, speed variance)

### Process Disabling

**Rule**: Disable `_process()` and `_physics_process()` when entities are:
- Off-screen (use VisibleOnScreenNotifier2D)
- Inactive (returned to pool)
- Dead (before queue_free())

```gdscript
func _on_screen_exited():
    set_physics_process(false)

func _on_screen_entered():
    set_physics_process(true)
```

### Configuration Architecture

**Pattern**: Separate config files per system to avoid monolithic GameConfig

**Current Structure**:
- `config/game_config.gd`: Global game constants (day/night duration, economy multipliers, universal settings)
- `config/crop_config.gd`: Crop-specific constants (stats, visuals, asset paths, harvest effects)
- `config/enemy_config.gd`: Enemy types, stats, wave scaling, spawn rules, sprite sheet paths (✅ IMPLEMENTED)

**Enemy Configuration Details** (new in `config/enemy_config.gd`):
```gdscript
# Asset paths
const ASSET_BASE_PATH: String = "res://assets/Insect-Enemy-Pack-V.1/"

# Visual settings for all enemies
const ANIMATION_SPEED: float = 0.1  # Frame advance interval (seconds)
const MOVEMENT_THRESHOLD: float = 1.0  # Velocity threshold for movement detection

# Per-enemy animation frame counts
const RUSHER_IDLE_FRAMES: int = 4
const RUSHER_WALK_FRAMES: int = 4
const RUSHER_ATTACK_FRAMES: int = 7
# ... and sprite paths for each animation state

const SHOOTER_IDLE_FRAMES: int = 5
const SHOOTER_WALK_FRAMES: int = 5
const SHOOTER_ATTACK_FRAMES: int = 6
# ... and sprite paths for each animation state
```

**Future Expansion** (when implemented):
- `config/tower_config.gd`: Tower types, damage, range, costs
- `config/wave_config.gd`: Advanced wave progression and difficulty curves

**Benefits**:
- **Separation of Concerns**: Each system's config is self-contained
- **Maintainability**: Easy to find and modify system-specific values
- **Scalability**: Prevents GameConfig from becoming 1000+ line monolith
- **AI-Friendly**: Agents can update specific configs without touching global state
- **Collaboration**: Multiple developers/agents can work on different configs without merge conflicts

**Implementation Pattern**:
```gdscript
# All system configs follow this structure:
class_name SystemConfig extends Node

# Shared settings (apply to all entities in system)
const SHARED_SETTING: float = 1.0

# Per-entity settings (each entity type has constants)
const ENTITY_A_STAT: int = 10
const ENTITY_A_SPRITE: String = "entity_a.png"
const ENTITY_A_COLOR: Color = Color.RED
```

---

## Future Architecture Plans

### Completed Systems

1. ✅ **FarmingSystem**: Crop planting, growth, harvesting (COMPLETED - Step 4)
2. ✅ **WaveManager**: Enemy spawning and wave progression (COMPLETED - Step 6)
3. ✅ **EnemyDatabase**: Centralized enemy type registry with sprite sheet animation support (COMPLETED - Step 6)
4. ✅ **BaseEnemy with Animation States**: Sprite sheet animation system (IDLE, WALK, ATTACK, HIT, DEATH) (COMPLETED - Step 6)
5. ✅ **CombatSystem**: Mech weapon and projectile system (Step 7)

### Planned Systems (Not Yet Implemented)

6. **TowerSystem**: Automated turret placement and targeting (Step 8)
7. **UpgradeSystem**: Mech and tower upgrade trees (Step 5)
8. **SaveSystem**: Persistent progression between runs
9. **AIDirector**: Dynamic difficulty adjustment

### Planned Optimizations

- MultiMesh for 100+ identical enemies
- Spatial partitioning for collision/targeting queries
- GPU particles for large-scale VFX
- Async pathfinding via threads for complex scenarios

---

## How to Update This Document

When making architectural changes, update the relevant sections:

1. **System changes**: Update [Key Systems](#key-systems) with new responsibilities
2. **Communication changes**: Update [Signal Flow](#system-diagrams) diagrams
3. **Performance patterns**: Update [Performance Considerations](#performance-considerations)
4. **Structure changes**: Update [Scene Hierarchy](#scene-hierarchy)
5. **Future plans**: Update [Future Architecture Plans](#future-architecture-plans) as systems are implemented

---

**Related Docs**: [PROJECT_CONTEXT.md](docs/agent/PROJECT_CONTEXT.md), [CODING_STANDARDS.md](docs/agent/CODING_STANDARDS.md)
