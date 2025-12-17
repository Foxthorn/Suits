# CODING_STANDARDS.md — Godot 4 GDScript Guidelines for SUITS: Iron Harvest

> **Purpose**: Enforce consistent, performant, maintainable code patterns for a hex-grid wave-defense game optimized for 1000+ simultaneous enemies.

## Related Documentation
- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design, data flow, and architectural decisions
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Project vision and core requirements
- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - File organization rules

**Update Policy**: When establishing new coding patterns or architectural standards, update relevant sections in ARCHITECTURE.md as well.

---

## 🎯 Core Principles

1. **Performance First**: Target 1000+ enemies at 60fps
2. **Signals Over Coupling**: Never directly reference unrelated systems
3. **No Magic Numbers**: All values in config files or named constants
4. **Readable > Clever**: Prioritize clarity for AI-assisted workflows
5. **Static Typing Always**: Enable type hints everywhere

---

## 📝 GDScript Style Guide

### Naming Conventions

```gdscript
# Variables & Functions: snake_case
var player_health: int = 100
func calculate_damage(base: float) -> float:

# Constants: SCREAMING_SNAKE_CASE
const MAX_ENEMIES = 1000
const TILE_SIZE = 64

# Classes & Nodes: PascalCase
class_name MechController extends CharacterBody2D

# Private/internal: prefix with underscore
var _cached_path: PackedVector2Array
func _internal_update() -> void:

# Signals: past tense, snake_case
signal enemy_died(enemy: Enemy)
signal wave_completed(wave_number: int)
signal crop_harvested(crop_type: String, value: int)
```

### Self Reference Rules (Mandatory)

```gdscript
# ✅ GOOD: Always use 'self.' for public variables/functions
var health: int = 100
var max_health: int = 150

func take_damage(amount: int) -> void:
    self.health -= amount
    if self.health <= 0:
        self.die()

func die() -> void:
    queue_free()

# ✅ GOOD: Private variables/functions do NOT require 'self.'
var _cached_target: Node2D

func _process(delta: float) -> void:
    _update_internal_state()  # No self. needed for private
    if _cached_target:
        self.attack(_cached_target)  # self. needed for public function

func _update_internal_state() -> void:
    pass

# ❌ BAD: Missing 'self.' for public members
func take_damage(amount: int) -> void:
    health -= amount  # WRONG! Should be self.health
    if health <= 0:
        die()  # WRONG! Should be self.die()
```

### Type Hints (Mandatory)

```gdscript
# ✅ GOOD: Always specify types
var speed: float = 300.0
var enemies: Array[Enemy] = []
@onready var sprite: Sprite2D = $Sprite2D

func spawn_enemy(position: Vector2, type: Enemy.Type) -> Enemy:
    return enemy

# ❌ BAD: No type hints
var speed = 300.0
var enemies = []
```

### Line Length & Formatting

- **Max 100 characters per line**
- **Indentation**: Use tabs (Godot default) or 4 spaces
- **One statement per line** (no `if x: do_thing()` on same line)

```gdscript
# ✅ GOOD
if health <= 0:
    die()

# ❌ BAD
if health <= 0: die()
```

---

## 🧩 Node & Scene Patterns

### Scene Structure Rules

1. **Always use inherited scenes** for reusable entities (enemies, crops, towers, bullets)
2. **Root node type matches purpose**:
   - `CharacterBody2D` for player/mech
   - `Area2D` for detection zones, collectibles
   - `Node2D` for pure logic controllers (WaveManager)
3. **Match scene name to script name**: `MechController.tscn` + `MechController.gd`

### Node References

```gdscript
# ✅ GOOD: Cache with @onready
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
    attack_timer.start()

# ❌ BAD: Repeated get_node() calls
func _process(delta: float) -> void:
    $UI/HealthBar.value = health  # Don't do this every frame!
```

### @export for Designer Values

```gdscript
# ✅ Expose tweakable values to Inspector
@export_range(1, 100) var max_health: int = 100
@export var move_speed: float = 300.0
@export var enemy_scene: PackedScene
@export_group("Wave Settings")
@export var enemies_per_wave: int = 10
```

---

## 🔗 Signal Architecture

### Signal Declaration & Naming

```gdscript
# ✅ GOOD: Past tense, descriptive
signal enemy_spawned(enemy: Enemy, position: Vector2)
signal player_damaged(amount: int, source: Node)
signal crop_growth_completed(crop: Crop)

# ❌ BAD: Present tense, vague
signal spawn
signal damage
signal update
```

### Signal Connection Best Practices

```gdscript
# ✅ GOOD: Always disconnect in _exit_tree
func _ready() -> void:
    EventBus.wave_started.connect(_on_wave_started)

func _exit_tree() -> void:
    if EventBus.wave_started.is_connected(_on_wave_started):
        EventBus.wave_started.disconnect(_on_wave_started)

# Private callback functions do not need 'self.'
func _on_wave_started() -> void:
    _prepare_defenses()

# ✅ Use EventBus autoload for global events
# EventBus.gd
extends Node
signal wave_completed(wave_number: int)
signal day_started()
signal night_started()
```

### Communication Rules

```gdscript
# ✅ GOOD: Decouple via signals (using 'self.' for public members)
# Enemy.gd
signal died(enemy: Enemy)

var health: int = 100

func take_damage(amount: int) -> void:
    self.health -= amount
    if self.health <= 0:
        self.died.emit(self)
        queue_free()

# WaveManager.gd connects to enemy.died

# ❌ BAD: Direct coupling
func take_damage(amount: int) -> void:
    health -= amount  # Missing self.
    if health <= 0:
        get_node("/root/WaveManager").on_enemy_died(self)  # NEVER!
```

---

## ⚡ Performance Optimization (Critical for 1000+ Enemies)

### Object Pooling (Mandatory)

```gdscript
# Use Pool.gd utility for bullets, enemies, particles
# Pool.gd
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

### Process Optimization

```gdscript
# ✅ GOOD: Disable processing when not needed
func _ready() -> void:
    set_process(false)  # Enable only when active

# Private callback functions (no self. needed)
func _on_visible_on_screen_notifier_screen_exited() -> void:
    set_physics_process(false)

func _on_visible_on_screen_notifier_screen_entered() -> void:
    set_physics_process(true)
```

### Pathfinding Rules (Non-Negotiable)

```gdscript
# ✅ GOOD: Shared pre-baked paths
# WaveManager.gd
var _shared_path: PackedVector2Array
var enemy_count: int = 10

func spawn_wave() -> void:
    _shared_path = _calculate_path_once()  # Called ONCE per wave (private)
    for i in self.enemy_count:
        var enemy = self.spawn_enemy()  # Use self. for public function
        enemy.set_path(_shared_path)

func spawn_enemy() -> Enemy:
    # Implementation
    return enemy

func _calculate_path_once() -> PackedVector2Array:
    # Private function, no self. needed
    return path

# ❌ BAD: Per-enemy A* every frame
func _physics_process(delta: float) -> void:
    var path = astar.get_point_path(current_pos, target)  # NEVER!
```

### No Frame-by-Frame Lookups

```gdscript
# ❌ BAD: Expensive lookups every frame
func _process(delta: float) -> void:
    var player = get_tree().get_nodes_in_group("player")[0]
    var distance = global_position.distance_to(player.global_position)

# ✅ GOOD: Cache references
var _player: Node2D

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
    var distance = global_position.distance_to(_player.global_position)
```

---

## 📐 Hex-Grid Specific Patterns

### Hex Coordinate System

```gdscript
# Use axial coordinates (q, r) for hex math
# Math.gd utility functions
class_name HexMath extends Node

static func axial_to_pixel(q: int, r: int, size: float) -> Vector2:
    var x = size * (3.0/2.0 * q)
    var y = size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
    return Vector2(x, y)

static func pixel_to_axial(pixel: Vector2, size: float) -> Vector2i:
    # Cube coordinate conversion
    var q = (2.0/3.0 * pixel.x) / size
    var r = (-1.0/3.0 * pixel.x + sqrt(3.0)/3.0 * pixel.y) / size
    return _cube_round(q, r)
```

### Hex Grid Manager Pattern

```gdscript
# HexGridManager.gd (Autoload)
extends Node

const TILE_SIZE: float = 64.0
var _occupied_tiles: Dictionary = {}  # Vector2i -> Entity

func is_tile_occupied(hex_pos: Vector2i) -> bool:
    return _occupied_tiles.has(hex_pos)

func place_entity(hex_pos: Vector2i, entity: Node2D) -> bool:
    if is_tile_occupied(hex_pos):
        return false
    _occupied_tiles[hex_pos] = entity
    entity.global_position = HexMath.axial_to_pixel(hex_pos.x, hex_pos.y, TILE_SIZE)
    return true
```

---

## 🗂️ Constants & Configuration

### GameConfig.gd Pattern (Autoload)

```gdscript
# autoload/GameConfig.gd
extends Node

# Enemy Stats
const ENEMY_BASE_HEALTH: int = 50
const ENEMY_BASE_SPEED: float = 100.0
const ENEMY_HEALTH_SCALING: float = 1.15  # 15% per wave

# Wave Settings
const WAVE_BASE_COUNT: int = 10
const WAVE_COUNT_SCALING: float = 1.25

# Crop Values
enum CropType { WHEAT, CORN, TOMATO }
const CROP_GROWTH_TIMES: Dictionary = {
    CropType.WHEAT: 30.0,
    CropType.CORN: 45.0,
    CropType.TOMATO: 60.0
}
const CROP_VALUES: Dictionary = {
    CropType.WHEAT: 10,
    CropType.CORN: 25,
    CropType.TOMATO: 50
}

# Day/Night Cycle
const DAY_DURATION: float = 180.0  # 3 minutes
const NIGHT_DURATION: float = 120.0  # 2 minutes
```

### Use Enums for States

```gdscript
# ✅ GOOD: Type-safe state management (use self. for public variables)
enum State { IDLE, MOVING, ATTACKING, DEAD }
var current_state: State = State.IDLE

func _process(delta: float) -> void:
    match self.current_state:
        State.IDLE:
            _handle_idle(delta)  # Private functions, no self.
        State.MOVING:
            _handle_moving(delta)
        State.ATTACKING:
            _handle_attacking(delta)

func _handle_idle(delta: float) -> void:
    pass

func _handle_moving(delta: float) -> void:
    pass

func _handle_attacking(delta: float) -> void:
    pass

# ❌ BAD: String-based states
var current_state = "idle"  # Typo-prone, no autocomplete
```

---

## 📖 Documentation Standards

### Docstrings (Use ## for public functions)

```gdscript
## Spawns a wave of enemies at the specified positions.
##
## @param positions: Array of spawn points for enemies
## @param enemy_type: Type of enemy to spawn
## @return: Number of enemies successfully spawned
func spawn_wave(positions: Array[Vector2], enemy_type: Enemy.Type) -> int:
    var spawned: int = 0
    for pos in positions:
        if _spawn_enemy_at(pos, enemy_type):
            spawned += 1
    return spawned
```

### Comment Guidelines

```gdscript
# ✅ GOOD: Explain WHY
# Disable collision during dash to prevent getting stuck in walls
collision_layer = 0

# Clamp to prevent divide-by-zero in damage calculation
var defense = max(armor, 1.0)

# ❌ BAD: Explain WHAT (code already shows this)
# Set health to 100
health = 100
```

### TODO/FIXME Tags

```gdscript
# TODO: Implement enemy pathfinding around obstacles
# FIXME: Memory leak when despawning 1000+ enemies rapidly
# NOTE: This uses shared path - do not modify per-enemy
# OPTIMIZE: Consider GPU particles for 500+ bugs
```

---

## 🚫 Anti-Patterns (Never Do This)

### ❌ Tight Coupling

```gdscript
# ❌ NEVER directly reference unrelated systems
get_node("/root/Main/Player/MechController").take_damage(10)

# ✅ Use signals or dependency injection
signal damage_dealt(target: Node, amount: int)
damage_dealt.emit(target, 10)
```

### ❌ Magic Numbers

```gdscript
# ❌ BAD
if health < 50:
    sprite.modulate = Color(1, 0.5, 0.5)

# ✅ GOOD
const LOW_HEALTH_THRESHOLD: int = 50
const LOW_HEALTH_COLOR: Color = Color(1, 0.5, 0.5)

if health < LOW_HEALTH_THRESHOLD:
    sprite.modulate = LOW_HEALTH_COLOR
```

### ❌ Global State Abuse

```gdscript
# ❌ BAD: Mutable global state
# Globals.gd
var player_health: int = 100  # Any script can modify this!

# ✅ GOOD: Encapsulated singleton with signals (use self. for public)
# PlayerState.gd
signal health_changed(new_health: int)
var _health: int = 100  # Private, no self. needed

func get_health() -> int:
    return _health  # Accessing private variable

func take_damage(amount: int) -> void:
    _health = max(0, _health - amount)  # Private variable
    self.health_changed.emit(_health)  # Use self. for signal
```

---

## 🔧 Error Handling

### Assertions & Validation

```gdscript
# Use assert() for development checks
var _speed: float
var damage: int = 10

func initialize(config: Dictionary) -> void:
    assert(config.has("speed"), "Config must have speed key")
    assert(config.speed > 0, "Speed must be positive")
    _speed = config.speed  # Private variable, no self.

# Check null before accessing
func attack_target(target: Node2D) -> void:
    if not is_instance_valid(target):
        return
    target.take_damage(self.damage)  # Use self. for public variable
```

---

## 📂 File Organization Checklist

- ✅ One class per file
- ✅ Filename matches class name: `MechController.gd`
- ✅ Scene + Script together: `MechController.tscn` + `MechController.gd`
- ✅ All gameplay code in `/src/`
- ✅ All autoloads in `/autoload/`
- ✅ All configs in `/config/`
- ✅ Folder names: `snake_case`
- ✅ File names: `PascalCase`

---

## 🎮 Input Handling

```gdscript
# ✅ GOOD: Use Input Map actions (defined in Project Settings)
func _physics_process(delta: float) -> void:
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * move_speed
    move_and_slide()

if Input.is_action_just_pressed("fire"):
    shoot()

# ❌ BAD: Hardcoded keys
if Input.is_key_pressed(KEY_W):
    move_up()
```

---

## 🧪 Testing Guidelines (Future)

```gdscript
# Unit test structure (using GUT or manual)
# tests/test_wave_manager.gd
extends GutTest

func test_wave_scaling():
    var manager = WaveManager.new()
    var wave_1 = manager.calculate_enemy_count(1)
    var wave_2 = manager.calculate_enemy_count(2)
    assert_gt(wave_2, wave_1, "Wave 2 should have more enemies than wave 1")
```

---

## 📋 Pre-Commit Checklist

Before committing code, verify:

- [ ] All variables/functions have type hints
- [ ] No magic numbers (all in GameConfig.gd or constants)
- [ ] Signals used instead of direct references
- [ ] No `get_node()` in `_process()` loops
- [ ] Object pooling used for spawned entities
- [ ] Docstrings on all public functions
- [ ] No hardcoded keys (Input Map actions only)
- [ ] File naming: PascalCase for .gd/.tscn, snake_case for folders
- [ ] Code follows scene hierarchy rules (inherited scenes)
- [ ] **'self.' used for all public variables/functions** (not needed for private ones)
