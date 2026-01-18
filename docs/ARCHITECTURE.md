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
8. [Physics & Collision Layers](#physics--collision-layers)
9. [Performance Considerations](#performance-considerations)
10. [Future Architecture Plans](#future-architecture-plans)

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
| `EconomyManager` | Player economy | Credits tracking, spending validation, upgrade purchasing |
| `ProgressManager` | Upgrade persistence | Track purchased upgrades, prevent duplicate purchases |
| `GameStateManager` | Game state & pause/menus | Game state (PLAYING, PAUSED, DEFEAT, VICTORY), pause control, win/loss triggers |
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

### MainGame System

**Purpose**: Central orchestrator integrating all core systems

**Location**: `scenes/MainGame.gd`

**Key Responsibilities**:
- Setup and validate PlantingSystem with dependency injection
- Setup and validate TowerSystem with dependency injection
- Connect PlantingSystem signals to HUD for feedback
- Forward mech health/death events to HUD and GameStateManager

**Implementation Notes**:
- Dependency Setup Phase: Validates hex_grid, crop_scene, and autoloads at startup
- Signal Connections: PlantingSystem signals connected to HUD methods
- Error Handling: Comprehensive validation with helpful debug messages
- All phases logged for debugging (shows what's working vs what failed)

---

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

**Purpose**: Individual projectile with collision detection and direct damage application.

**Location**: `src/entities/projectiles/Bullet.gd`

**Key Responsibilities**:
- Linear movement at constant velocity
- Lifetime management (3 second default)
- Enemy collision detection via Area2D
- Direct damage application by calling `BaseEnemy.take_damage()`
- Particle effect on impact
- Self-cleanup and queue_free() after collision

**Signals**:
- `hit_enemy(enemy: BaseEnemy, damage: float)` - Emitted when damage is applied
- `expired()` - Emitted when bullet expires or is destroyed

**Public API**:
```gdscript
func set_velocity(direction: Vector2, spd: float = WeaponConfig.BULLET_SPEED) -> void
func set_velocity_from_angle(angle: float, spd: float = WeaponConfig.BULLET_SPEED) -> void
```

**Collision Behavior**:
- Bullets detect enemies via Area2D collision detection
- On collision with BaseEnemy, calls `enemy.take_damage(damage)` directly
- Creates impact particle effect at hit location
- Self-destructs (queue_free) after applying damage
- Tracks hit targets to prevent double-hits on same enemy

---

### Tower System

**Purpose**: Automated tower defense mechanics with extensible tower types and auto-targeting.

**Location**: `src/entities/towers/` + `src/systems/TowerDatabase.gd` + `src/systems/TowerWeaponSystem.gd`

**Architecture**:

#### TowerDatabase System (`src/systems/TowerDatabase.gd`)
**Purpose**: Centralized registry for all tower types with extensible registration pattern.

**Key Features**:
- Static-only class with registry pattern (no instantiation needed)
- Automatic initialization on first access
- Extensible via `register_tower()` method
- Loads all constants from `TowerConfig` automatically
- Provides lookup methods for type-safe tower data access

**Public API**:
```gdscript
static func get_tower(type: TowerType) -> TowerData
static func get_tower_name(type: TowerType) -> String
static func get_tower_cost(type: TowerType) -> int
static func get_all_tower_types() -> Array[TowerType]
static func register_tower(tower_data: TowerData) -> void
```

**TowerData Class**:
Immutable data structure containing all tower configuration:
- Core stats: `speed`, `range`, `damage`, `fire_rate`, `name`, `description`
- Projectile: `bullet_speed`, `bullet_lifetime`, `bullet_color`
- Visual: `sprite_path`, `size`, `collision_radius`
- Debug: `debug_draw` flag for logging
- Methods: `get_sprite()`

**To Add New Tower Type**:
1. Add to `TowerType` enum in TowerDatabase
2. Add constants to `config/tower_config.gd`:
   - `TOWER_NAME_COST`, `TOWER_NAME_RANGE`, `TOWER_NAME_DAMAGE`, etc.
3. Call `TowerDatabase.register_tower()` in `_ensure_initialized()`

---

#### BaseTower (`src/entities/towers/BaseTower.gd`)
**Purpose**: Base class for all tower types with common detection, targeting, and firing logic.

**Location**: `src/entities/towers/BaseTower.gd`

**Key Responsibilities**:
- Load tower data from TowerDatabase on spawn
- Enemy detection via Area2D (detection zone)
- Targeting logic (nearest enemy)
- Fire rate management and cooldown tracking
- Sprite setup and collision layer configuration
- Virtual `fire()` method for subclass behavior override

**Signals**:
- `fired(position: Vector2, direction: Vector2)` - Emitted when firing
- `target_changed(new_target: BaseEnemy)` - Emitted when target switches

**Exported Properties**:
```gdscript
@export var tower_type: TowerDatabase.TowerType = TowerDatabase.TowerType.GATLING_GUN
@export var debug_draw: bool = false
```

**Key Methods**:
```gdscript
func fire() -> void                                      # Virtual - override in subclasses
func find_nearest_enemy() -> BaseEnemy                  # Target selection
func get_tower_data() -> TowerDatabase.TowerData        # Config access
func get_enemies_in_range() -> Array[BaseEnemy]        # Current targets
func get_current_target() -> BaseEnemy                  # Active target
```

**Collision Setup**:
- Tower on Layer 5 (TOWERS)
- Detects Layer 1 (world) + Layer 3 (enemies)
- DetectionZone Area2D automatically configured to detect enemies only

---

#### GatlingGun (`src/entities/towers/GatlingGun.gd`)
**Purpose**: Rapid-fire tower that trades damage for volume of fire.

**Location**: `scenes/entities/towers/GatlingGun.tscn` + `src/entities/towers/GatlingGun.gd`

**Stats** (from TowerConfig):
- Cost: 50 credits (TOWER_GATLING_GUN_COST)
- Range: 250 px (TOWER_GATLING_GUN_RANGE)
- Damage: 8 per shot (TOWER_GATLING_GUN_DAMAGE)
- Fire Rate: 0.2s (TOWER_GATLING_GUN_FIRE_RATE) = 5 shots/second
- Bullet Speed: 350 px/s (TOWER_GATLING_GUN_BULLET_SPEED)
- Bullet Color: Yellow/Orange (TOWER_GATLING_GUN_BULLET_COLOR)

**Behavior**:
- Extends BaseTower
- Overrides `fire()` to add small random spread for visual interest
- Includes firing animation (sprite rotation while active)
- Uses TowerWeaponSystem for projectile spawning
- High fire rate makes it ideal for dealing with enemy swarms

**Design Notes**:
- Lower cost than other towers encourages placement of multiple turrets
- Lower damage per shot balanced by high fire rate
- Smaller range than specialized towers

---

#### TowerWeaponSystem (`src/systems/TowerWeaponSystem.gd`)
**Purpose**: Handles tower projectile spawning and pooling (separate from player WeaponSystem).

**Location**: `src/systems/TowerWeaponSystem.gd`

**Key Responsibilities**:
- Projectile pooling for performance (100-bullet default pool per tower)
- Tower bullet instantiation and reuse from pool
- Projectile lifetime and color management
- Signal emission for audio/VFX feedback

**Signals**:
- `tower_bullet_fired(bullet: Node2D, position: Vector2, direction: Vector2)`

**Public API**:
```gdscript
func initialize(tower_data: TowerDatabase.TowerData) -> void
func fire(from_position: Vector2, direction: Vector2, color: Color) -> void
func get_active_bullet_count() -> int
func get_pooled_bullet_count() -> int
```

---

#### TowerBullet (`src/entities/projectiles/TowerBullet.gd`)
**Purpose**: Tower-fired projectile with collision detection and direct damage application (visually distinct from player bullets).

**Location**: `src/entities/projectiles/TowerBullet.gd` + `scenes/entities/projectiles/TowerBullet.tscn`

**Key Responsibilities**:
- Linear movement at tower-specific speed
- Lifetime management (tower-configurable)
- Enemy collision detection via Area2D
- Direct damage application by calling `BaseEnemy.take_damage()`
- Particle effect on impact
- Self-cleanup and queue_free() after collision
- Color customization for visual feedback

**Signals**:
- `hit_enemy(enemy: BaseEnemy, damage: float)` - Emitted when damage is applied
- `expired()` - Emitted when bullet expires or is destroyed

**Public API**:
```gdscript
func set_velocity(direction: Vector2, speed: float) -> void
func set_color(color: Color) -> void
func set_damage(damage: float) -> void
func set_lifetime(duration: float) -> void
```

**Collision Behavior**:
- Tower bullets detect enemies via Area2D collision detection
- On collision with BaseEnemy, calls `enemy.take_damage(damage)` directly
- Creates impact particle effect at hit location
- Self-destructs (queue_free) after applying damage
- Prevents double-hits on same enemy in single frame

**Design Notes**:
- Yellow/Orange color by default (visually distinct from white player bullets)
- Configurable color allows tower type differentiation in future updates
- Uses same collision detection approach as player bullets (Area2D with direct function calls)

---

#### TowerSystem (`src/systems/TowerSystem.gd`)
**Purpose**: Tower placement mode, validation, and UI feedback (similar to PlantingSystem).

**Location**: `src/systems/TowerSystem.gd`

**Key Responsibilities**:
- Manage tower placement mode (enter/exit)
- Validate tile placement against crops, other towers, and tile types
- Display ghost preview with valid/invalid coloring (green=valid, red=invalid)
- Deduct credits on successful placement via EconomyManager integration
- Track all placed towers by hex coordinates
- Emit signals for placement mode changes and tower placement events
- Handle input for placement mode activation and cancellation

**Signals**:
- `tower_placed(hex_coords: Vector2i, tower_type: TowerDatabase.TowerType)` - Emitted when tower successfully placed
- `placement_mode_changed(active: bool, tower_type: TowerDatabase.TowerType)` - Emitted on mode entry/exit

**Exported Properties**:
```gdscript
@export var hex_grid: HexGrid              # Reference to hex grid for tile validation
@export var show_preview: bool = true      # Show ghost preview on hover
@export var show_range_indicator: bool = true  # Show detection range circle
```

**Key Methods**:
```gdscript
func enter_placement_mode(tower_type: TowerDatabase.TowerType) -> void
func exit_placement_mode() -> void
func can_place_tower_at(hex_coords: Vector2i) -> bool
func get_tower_at(hex_coords: Vector2i) -> BaseTower
func get_all_towers() -> Array[BaseTower]
func get_tower_count() -> int
func is_in_placement_mode() -> bool
func get_selected_tower_type() -> TowerDatabase.TowerType
```

**Features**:
- Ghost preview follows mouse cursor with semi-transparent sprite
- Preview color changes based on tile validity (green for valid, red for invalid)
- Range indicator visualization shows detection radius of towers during placement
- Credit checking: Validates player has sufficient credits before placement
- Tile validation: Checks for existing towers, crops, and valid tile types
- Automatic tower instantiation: Creates tower instances and adds to scene
- Seamless integration with EconomyManager for cost deduction
- Seamless integration with HexGrid for tile interaction events
- Seamless integration with PlantingSystem to prevent tower-on-crop conflicts

**Input Actions**:
- `ui_focus_next`: T key to enter/exit placement mode
- `ui_cancel`: ESC key to cancel placement
- Mouse click to place tower on valid tile
- Right-click to cancel placement

**Validation Rules**:
- Tile must exist in hex grid
- Tile must not already have a tower
- Tile must not have a crop (from PlantingSystem)
- Player must have sufficient credits
- Tile must be valid tower placement location

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

**Purpose**: Manages player credits, spending validation, economic transactions, and upgrade purchasing.

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
- Plays ATTACK animation when dealing damage
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

**Location**: `autoload/WaveManager.gd`

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

**Purpose**: Manages crop planting, growth, and harvest mechanics

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



### GameStateManager System (Autoload)

**Purpose**: Central manager for game state transitions, pause/resume, and win/loss conditions with victory statistics tracking.

**Location**: `autoload/GameStateManager.gd`

**Key Responsibilities**:
- Track game state (PLAYING, PAUSED, DEFEAT, VICTORY, LOADING)
- Manage pause/resume via ESC key input
- Trigger defeat condition when mech is destroyed
- Trigger victory condition when all waves completed
- Gather and emit victory statistics for victory screen
- Control Engine.time_scale for pause functionality
- Emit state change signals for UI coordination

**State Enum**:
```gdscript
enum State {
    PLAYING,
    PAUSED,
    DEFEAT,
    VICTORY,
    LOADING
}
```

**Signals**:
- `state_changed(new_state: State)` - Emitted on any state transition
- `game_paused()` - Emitted when game is paused (state → PAUSED)
- `game_resumed()` - Emitted when game is resumed (state → PLAYING)
- `defeat_triggered(reason: String)` - Emitted when defeat occurs with failure reason
- `victory_triggered(stats: Dictionary)` - Emitted when victory occurs with final stats

**Public API**:
```gdscript
func pause_game(show_pause_menu: bool = true) -> void  # Pause; only show menu if true
func resume_game() -> void                              # Resume from pause
func trigger_defeat(reason: String) -> void             # Trigger loss condition
func trigger_victory(stats: Dictionary) -> void          # Trigger win condition
func restart_game() -> void                             # Reload current scene
func quit_game() -> void                                # Exit to desktop
func get_current_state() -> State                       # Query current state
func is_game_paused() -> bool                           # Convenience pause check
func get_current_night() -> int                         # Get current night number
func get_nights_survived() -> int                       # Get nights survived count
```

**Pause Mechanics**:
- **User-Initiated Pause (ESC key)**: `pause_game()` or `pause_game(true)` → Shows PauseMenu
  - Sets Engine.time_scale to 0.0
  - Emits `game_paused()` signal to show PauseMenu
  - Emits `state_changed(PAUSED)` signal for UI coordination

- **Silent Pause (DefeatScreen, VictoryScreen, UpgradeShop)**: `pause_game(false)` → No pause menu
  - Sets Engine.time_scale to 0.0
  - Does NOT emit `game_paused()` signal (so PauseMenu stays hidden)
  - Emits `state_changed(PAUSED)` signal for UI coordination
  - Used when other UI screens need to freeze gameplay without showing pause menu

- **Resume**: `resume_game()` → Always resumes to PLAYING
  - Sets Engine.time_scale to 1.0
  - Emits `game_resumed()` signal
  - Emits `state_changed(PLAYING)` signal

**Victory Statistics Dictionary**:
```gdscript
{
    "nights_survived": int,           # Total nights survived (1-3)
    "total_credits_earned": int,      # Total credits earned this session
    "enemies_defeated": int,          # Total enemies killed
    "crops_harvested": int,           # Total crops harvested
    "towers_built": int,              # Total towers placed
    "upgrades_purchased": int         # Total upgrades purchased
}
```

**UI Screen Controllers** (All moved to `src/ui/` for code organization):
- `PauseMenu.gd` - Pause menu controller with resume/restart/quit options
- `DefeatScreen.gd` - Defeat screen with failure reason and session statistics
- `VictoryScreen.gd` - Victory screen with end-game statistics display
- `HUD.gd` - Main HUD display with health, credits, and phase information
- `ControlsOverlay.gd` - Controls reference overlay (moved to `src/ui/`)

**Design Notes**:
- Listens to `MechController.died` signal to trigger defeat
- Listens to `WaveManager.wave_completed` signal to detect victory (Night 3, Wave 3)
- Listens to `TimeManager.night_started` signal to track progression
- Gathers stats from EconomyManager, WaveManager, PlantingSystem, ProgressManager
- Sets `Engine.time_scale = 0.0` on pause, `1.0` on resume
- Prevents input processing in UI systems by checking GameStateManager.current_state
- UI controller scripts moved from `scenes/ui/` to `src/ui/` (architectural improvement for code/scene separation)

---

### ControlsOverlay System

**Purpose**: Displays on-screen controls and keybinding reference to the player.

**Location**: `src/ui/ControlsOverlay.gd` (script) + `scenes/ui/ControlsOverlay.tscn` (scene)

**Class**: `ControlsOverlay` (CanvasLayer-based UI controller)

**Key Responsibilities**:
- Show/hide controls overlay with fade-in animation
- Display all input actions and their keybindings
- Handle C key toggle and ESC key to close
- Block game input while overlay is visible

**Input Actions**:
- `controls_show`: C key to toggle controls overlay open/closed
- `ui_cancel`: ESC key to close overlay when visible

**Public API**:
```gdscript
func _show_controls() -> void  # Display overlay with animation
func _hide_controls() -> void  # Hide overlay
```

**Design Notes**:
- Integrated into MainGame.tscn as ControlsOverlay node (CanvasLayer)
- ControlsOverlay.tscn scene references script at `src/ui/ControlsOverlay.gd`
- Can be toggled at any time during gameplay
- Overlays game with semi-transparent background panel
- Lists all key controls:
  - Movement: WASD / Arrow keys
  - Action: Left Click to attack/interact
  - Camera: Mouse Scroll to zoom
  - Shop: S key to toggle shop
  - Pause: ESC / P key to pause/menu
- Closes on C key or ESC key press
- Uses Tween-based fade-in animation on show
- Enhanced with click-outside-to-close functionality for better UX

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

### Game State Transitions (Pause/Defeat/Victory)

```
ESC key pressed → GameStateManager._input()
    ↓
if current_state == PLAYING:
    pause_game() → Engine.time_scale = 0.0
    ↓
    state_changed.emit(PAUSED)
    ↓
    game_paused.emit()
    ↓
    PauseMenu becomes visible

if current_state == PAUSED:
    resume_game() → Engine.time_scale = 1.0
    ↓
    state_changed.emit(PLAYING)
    ↓
    game_resumed.emit()
    ↓
    PauseMenu becomes hidden

---

Mech.died signal → GameStateManager._on_mech_died()
    ↓
trigger_defeat(reason)
    ↓
current_state = DEFEAT
    ↓
state_changed.emit(DEFEAT)
    ↓
defeat_triggered.emit(reason)
    ↓
    DefeatScreen becomes visible
    ↓
Player clicks Restart → GameStateManager.restart_game() → reload scene

---

WaveManager.wave_completed(3) AND TimeManager.current_night == 3
    ↓
GameStateManager._on_wave_completed(3)
    ↓
if night_num == 3 and wave_num == 3:
    _gather_victory_stats() → collect final stats
    ↓
    trigger_victory(stats)
    ↓
    current_state = VICTORY
    ↓
    state_changed.emit(VICTORY)
    ↓
    victory_triggered.emit(stats)
    ↓
    VictoryScreen becomes visible with stats
    ↓
Player clicks Play Again → GameStateManager.restart_game() → reload scene
```

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

### Combat System Flow

```
Player clicks → Input.is_action_pressed("fire")
    ↓
MechController._handle_weapon()
    ↓
WeaponSystem.can_fire() check
    ↓
WeaponSystem.fire(from_position, direction)
    ↓
Instantiate new Bullet or get from pool
    ↓
Bullet.set_velocity(direction, speed)
    ↓
Bullet moves via _physics_process
    ↓
Bullet.area_entered(Enemy) detected
    ↓
Bullet calls Enemy.take_damage(damage) directly
    ↓
Enemy.health -= damage
    ↓
Enemy emits health_changed signal
    ↓
Bullet creates hit effect and queue_free()
    ↓
If enemy.health <= 0:
    Enemy.die()
    ↓
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
│   └── TileMapLayer (hex grid visuals)
├── Mech (Mech.tscn instance)
│   └── (weapons, effects, collision shapes)
├── Camera2D (shared camera, managed by HexGrid)
├── DayNightTint (CanvasModulate for visual cycling)
├── HUD (HUD.tscn instance)
│   └── (health bar, credits, timer displays)
├── PauseMenu (PauseMenu.tscn instance)
│   └── (pause UI overlay)
├── DefeatScreen (DefeatScreen.tscn instance)
│   └── (defeat/game-over UI with stats)
├── VictoryScreen (VictoryScreen.tscn instance)
│   └── (victory/win UI with final statistics)
└── ControlsOverlay (ControlsOverlay.tscn instance)
    └── (controls reference overlay)
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

## Physics & Collision Layers

### Layer Assignment

Godot physics layers are used to control which entities can collide and interact. Each layer has a specific purpose in the game world:

| Layer | Name | Purpose | Entities |
|-------|------|---------|----------|
| 1 | `world` | Static world geometry and obstacles | TileMap, static obstacles, walls |
| 2 | `player` | Player mech and player-owned projectiles | Mech, Player Bullets |
| 3 | `enemies` | Enemy entities | RusherEnemy, ShooterEnemy, BossEnemy |
| 4 | `enemy_projectiles` | Enemy-fired projectiles | ShooterEnemy bullets, boss attacks |
| 5 | `towers` | Player-placed automated turrets | BasicTurret, AdvancedTurret |
| 6 | `crops` | Planted crops (non-physical, visual only) | BaseCrop (detection only, no physics) |
| 7 | `ground_items` | Dropped items and loot | Harvestable drops, resource pickups |
| 8 | `ui_interactive` | Interactive UI elements requiring physics | (reserved for future UI physics) |

### Collision Mask Rules by Entity Type

**Design Philosophy**: Minimize collision checks by having entities only detect what they need to interact with. For example, enemies don't collide with crops because crops occupy the same space but don't block movement.

#### Mech (Player Character) — Layer 2

**Collision Layer**: `2 (player)`
**Collision Mask** (what it collides with): `1, 3, 4`

| Collides With | Reason |
|---|---|
| ✅ Layer 1 (world) | Must not pass through walls or obstacles |
| ✅ Layer 3 (enemies) | Takes damage from contact with enemies |
| ✅ Layer 4 (enemy_projectiles) | Takes damage from enemy bullets |
| ❌ Layer 2 (player) | Only one mech exists, no self-collision |
| ❌ Layer 5 (towers) | Towers are optional obstacles; mech can push through |
| ❌ Layer 6 (crops) | Crops are thin visual overlays, mech walks through them |
| ❌ Layer 7 (ground_items) | Items are collected via area detection, not physics |

#### Player Bullet — Layer 2

**Collision Layer**: `2 (player)`
**Collision Mask**: `3`

| Collides With | Reason |
|---|---|
| ✅ Layer 3 (enemies) | Must damage enemies on impact |
| ❌ All others | Bullets ignore world geometry (can fire over obstacles), towers, crops, other bullets |

**Design Note**: Bullets are Area2D nodes that only care about hitting enemies. World geometry doesn't stop bullets (they have 3-second lifetime instead). This simplifies targeting and feels more arcade-like.

**Projectile Detection Implementation**:
- **Bullet Collision Layer**: `2 (player)`
- **Bullet Collision Mask**: `3 (enemies)` - Only detects enemies
- Bullets connect to `area_entered` signal to detect enemy collisions
- On collision, projectile calls `enemy.take_damage(damage)` directly (not via signal)
- Projectile creates visual feedback (particles) and queue_free() after hit

BaseEnemy provides a dedicated `ProjectileDetector` Area2D for efficient detection:
- **ProjectileDetector Collision Layer**: `4 (enemies)`
- **ProjectileDetector Collision Mask**: `2 (player projectiles)`
- This two-layer detection approach ensures both directions work correctly:
  1. **Bullet → Enemy**: Bullet's collision_mask=3 detects BaseEnemy (Layer 3)
  2. **Enemy → Bullet**: BaseEnemy's ProjectileDetector collision_mask=2 detects Bullet (Layer 2)

#### Enemies (Rusher, Shooter) — Layer 3

**Collision Layer**: `3 (enemies)`
**Collision Mask**: `1, 2, 5`

| Collides With | Reason |
|---|---|
| ✅ Layer 1 (world) | Must not pass through walls |
| ✅ Layer 2 (player) | Damages mech on contact |
| ✅ Layer 5 (towers) | Damaged by towers; can path around them |
| ❌ Layer 3 (enemies) | Enemies pass through each other (no stacking/blocking) |
| ❌ Layer 4 (enemy_projectiles) | Enemies ignore friendly projectiles |
| ❌ Layer 6 (crops) | Enemies walk through crops freely |
| ❌ Layer 7 (ground_items) | Don't collide with drops |

**Design Note**: Enemies don't collide with each other to prevent stalling waves. They can overlap, creating dense swarms that feel chaotic and challenging.

**Projectile Detection via Internal Area2D**:
Each enemy has an internal `projectile_detector: Area2D` node that handles bullet collision detection:
- **Layer**: `4 (enemies)` - Same as main enemy body
- **Mask**: `2 (player projectiles)` - Only detects bullets
- **Size**: Matches the enemy's main collision shape (CircleShape2D with radius = EnemyConfig.COLLISION_RADIUS)
- **Signal**: Connects to `area_entered` signal, routed to `_on_projectile_detector_hit(area: Node2D)`
- **Purpose**: Clean separation between movement physics (main body) and projectile detection (dedicated Area2D)

This design allows enemies to efficiently detect bullets without interfering with movement physics or other collision checks.

#### Enemy Projectile (ShooterEnemy bullets) — Layer 4

**Collision Layer**: `4 (enemy_projectiles)`
**Collision Mask**: `2`

| Collides With | Reason |
|---|---|
| ✅ Layer 2 (player) | Must hit mech to deal damage |
| ❌ All others | Enemy bullets ignore world geometry, towers, other projectiles |

**Design Note**: Like player bullets, enemy projectiles are Area2D and only detect the mech. This keeps attack patterns visible and fair.

#### Tower (BasicTurret, etc.) — Layer 5

**Collision Layer**: `5 (towers)`
**Collision Mask**: `1`

| Collides With | Reason |
|---|---|
| ✅ Layer 1 (world) | Towers sit on ground and collide with terrain |
| ❌ Layer 3 (enemies) | Enemies collide with towers (not vice-versa) |
| ❌ All others | Towers don't need collision detection for other entities |

**Design Note**: Towers are stationary, so they only need one-way collision (enemies detect them). Towers use Area2D for enemy detection via `area_entered` signals, not physics-based collision.

#### Crop (BaseCrop) — Layer 6

**Collision Layer**: `6 (crops)`
**Collision Mask**: `(none)`

| Collides With | Reason |
|---|---|
| ❌ Everything | Crops are visual-only; detection via `area_entered` signals |

**Design Note**: Crops don't block movement. They use Area2D for hover detection and click handling, but don't engage physics collision. This allows dense crop layouts without performance issues.

### Collision Mask Quick Reference

```gdscript
# Quick reference for setting collision layers in code:

# Mech setup
mech.collision_layer = 2       # "I am a player"
mech.collision_mask = 0b0001_0111  # Detect: world, enemies, enemy_projectiles

# Player Bullet setup
bullet.collision_layer = 2     # "I am a player projectile"
bullet.collision_mask = 0b0000_0100  # Detect: enemies only

# Enemy setup
enemy.collision_layer = 4      # "I am an enemy"
enemy.collision_mask = 0b0001_0111  # Detect: world, player, towers

# Enemy Projectile setup
enemyprojectile.collision_layer = 8   # "I am an enemy projectile"
enemyprojectile.collision_mask = 0b0000_0100   # Detect: player only

# Tower setup
tower.collision_layer = 16     # "I am a tower"
tower.collision_mask = 0b0000_0001   # Detect: world only (enemies detect towers)

# Crop setup
crop.collision_layer = 32      # "I am a crop"
crop.collision_mask = 0         # Detect nothing (area-only detection)
```

### Layer Configuration in Project Settings

Physics layers must be configured in Godot project settings:

**Path**: `Project → Project Settings → Physics → 2D → Physics Layers`

**Required Configuration**:
```
Physics Layer 1:  world
Physics Layer 2:  player
Physics Layer 3:  enemies
Physics Layer 4:  enemy_projectiles
Physics Layer 5:  towers
Physics Layer 6:  crops
Physics Layer 7:  ground_items
Physics Layer 8:  ui_interactive
```

### Why This Collision Setup?

**1. Performance**: Minimized collision checks reduce physics frame time
   - Bullets only check enemies, not world geometry
   - Enemies don't collide with each other (no pathfinding around allies)
   - Crops don't use collision (area-only detection)

**2. Game Feel**: Arcade-style action feels better than realistic physics
   - Dense enemy swarms without stacking/blocking
   - Clear line of sight for ranged attacks
   - Mech can navigate tight spaces without tower obstruction

**3. Clarity**: Each layer has one clear purpose
   - Easy to understand what entities interact
   - New developers can quickly add entities to correct layers
   - Debugging collisions is straightforward (check layer vs mask)

**4. Extensibility**: Easy to add new entity types
   - Boss enemies: Layer 3, same mask as regular enemies
   - Advanced towers: Layer 5, same setup as basic towers
   - Obstacles/props: Layer 1, add to world layer
   - Explosions/AoE: Layer 7, add collision detection as needed

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
- `config/enemy_config.gd`: Enemy types, stats, wave scaling, spawn rules, sprite sheet paths
- `config/tower_config.gd`: Tower types, stats, projectile properties, placement visuals

**Tower Configuration Details** (new in `config/tower_config.gd`):
```gdscript
# Tower costs and economics
const TOWER_GATLING_GUN_COST: int = 50

# Gatling Gun stats
const TOWER_GATLING_GUN_RANGE: float = 250.0
const TOWER_GATLING_GUN_DAMAGE: float = 8.0
const TOWER_GATLING_GUN_FIRE_RATE: float = 0.2  # 5 shots/sec
const TOWER_GATLING_GUN_BULLET_SPEED: float = 350.0
const TOWER_GATLING_GUN_BULLET_LIFETIME: float = 3.0

# Visual feedback and placement
const TOWER_RANGE_INDICATOR_COLOR: Color = Color(0.5, 0.8, 1.0, 0.3)
const TOWER_PLACEMENT_VALID_COLOR: Color = Color(0.0, 1.0, 0.0, 0.5)
const TOWER_PLACEMENT_INVALID_COLOR: Color = Color(1.0, 0.0, 0.0, 0.5)
```

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
- `config/wave_config.gd`: Advanced wave progression and difficulty curves
- `config/upgrade_config.gd`: Upgrade costs, effects, and progression tiers

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

## Architecture Roadmap

### Implemented Systems

1. **FarmingSystem**: Crop planting, growth, harvesting
2. **WaveManager**: Enemy spawning and wave progression
3. **EconomyManager**: Credit tracking, economy transactions, upgrade purchasing
4. **ProgressManager**: Upgrade persistence and tracking
5. **EnemyDatabase**: Centralized enemy type registry with sprite sheet animation support
6. **BaseEnemy with Animation States**: Sprite sheet animation system (IDLE, WALK, ATTACK, HIT, DEATH)
7. **CombatSystem**: Mech weapon and projectile system
8. **TowerSystem**: Tower database, base class, GatlingGun turret, placement mode
   - TowerDatabase with extensible registry
   - BaseTower with detection and firing mechanics
   - GatlingGun tower implementation
   - TowerWeaponSystem and TowerBullet projectiles
   - TowerSystem placement mode with validation and preview
9. **GameStateManager**: Game state machine, pause/resume, defeat/victory conditions (✅ Step 9 COMPLETED)
   - State tracking (PLAYING, PAUSED, DEFEAT, VICTORY, LOADING)
   - ESC key pause/resume integration
   - Victory statistics gathering
   - Signal-driven UI coordination for pause/defeat/victory screens
10. **UI Screen Controllers**: Pause, Defeat, Victory screens with player input handling

### Planned Systems

- **SaveSystem**: Persistent progression between runs
- **AIDirector**: Dynamic difficulty adjustment
- **Advanced UI**: Main menu, settings, achievements

### Planned Optimizations

- MultiMesh for 100+ identical enemies
- Spatial partitioning for collision/targeting queries
- GPU particles for large-scale VFX
- Async pathfinding via threads for complex scenarios

---

## How to Update This Document

When making architectural changes, update the relevant sections:

1. **System changes**: Update [Key Systems](#key-systems) with new responsibilities
2. **Communication changes**: Update [Signal Flow](#system-diagrams) diagrams and [Data Flow](#data-flow)
3. **Performance patterns**: Update [Performance Considerations](#performance-considerations)
4. **Structure changes**: Update [Scene Hierarchy](#scene-hierarchy)
5. **State management changes**: Update [Game State Transitions](#data-flow) flow diagram
6. **Future plans**: Update [Implemented Systems](#architecture-roadmap) as systems are completed

**Important**: Update this file whenever:
- New autoload systems are added (add to Autoload Singletons table)
- New major systems are implemented (add to Key Systems section)
- Signal flows between systems change (update Data Flow diagrams)
- UI hierarchy is modified (update Scene Hierarchy)
- Completion milestones are reached (update Architecture Roadmap)

---

**Related Docs**:
- [PROJECT_CONTEXT.md](docs/agent/PROJECT_CONTEXT.md) - Project vision and requirements
- [CODING_STANDARDS.md](docs/agent/CODING_STANDARDS.md) - Code quality guidelines
- [FILE_STRUCTURE.md](docs/agent/FILE_STRUCTURE.md) - Project folder organization
- [VERTICAL_SLICE.md](docs/verticalslice/VERTICAL_SLICE.md) - Implementation progress tracking
