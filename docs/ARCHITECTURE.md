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
| `WaveManager` | Wave spawning & scaling | Enemy wave generation, difficulty progression |
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
Enemy.died signal
    │
    ├──► WaveManager._on_enemy_died()
    │       └──► Checks if wave complete
    │               └──► EventBus.wave_completed.emit()
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
- Mouse-aimed shooting
- Health and damage management
- Weapon/upgrade integration (future)

**Signals**:
- `health_changed(current_hp: float, max_hp: float)`
- `died()`

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

### Farming System

**Purpose**: Manages crop planting, growth, and harvest mechanics.

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
  - PLANTED: Just planted, small sprite
  - GROWING: Actively growing (only during DAY phase)
  - HARVESTABLE: Ready to harvest, player can click
- Emits `harvested(crop_type, value, hex_coords)` signal
- Visual feedback: hover indicator, growth scaling, harvest particles

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

---

### WaveManager System (Autoload)

**Purpose**: Manages enemy wave spawning, difficulty scaling, and wave progression.

**Location**: `autoload/WaveManager.gd` *(Planned)*

**Key Responsibilities**:
- Calculate enemy counts per wave (exponential scaling)
- Spawn enemies at designated points
- Track active enemies
- Signal wave start/completion

**Planned Signals**:
- `wave_started(wave_number: int)`
- `wave_completed(wave_number: int)`
- `all_enemies_defeated()`

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
BaseCrop.start_growing() → Growth only during DAY phase
    ↓
Player clicks harvestable crop → BaseCrop.harvested signal
    ↓
EconomyManager.add_credits(value)
```

### Combat System Flow

```
Player presses fire → MechController shoots
    ↓
Bullet (pooled) spawned with velocity
    ↓
Bullet.area_entered detects Enemy
    ↓
Enemy.take_damage(bullet_damage)
    ↓
If enemy.health <= 0:
    Enemy.died.emit(self)
    ↓
    WaveManager._on_enemy_died()
    ↓
    Check if wave complete → EventBus.wave_completed.emit()
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

---

## Future Architecture Plans

### Planned Systems (Not Yet Implemented)

1. ✅ **FarmingSystem**: Crop planting, growth, harvesting (COMPLETED - Step 4)
2. **TowerSystem**: Automated turret placement and targeting
3. **UpgradeSystem**: Mech and tower upgrade trees
4. **SaveSystem**: Persistent progression between runs
5. **AIDirector**: Dynamic difficulty adjustment

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
