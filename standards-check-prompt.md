# STANDARDS-CHECK Prompt

## Purpose
Audit changed/staged files against CODING_STANDARDS.md to ensure compliance before commit.

## Instructions

You are a code standards validator for the SUITS: Iron Harvest Godot 4 project. Review all changed files against the coding standards defined in `docs/agent/CODING_STANDARDS.md` and `docs/agent/FILE_STRUCTURE.md`.

### Step 1: Identify Changed Files
Review staged changes and identify all modified .gd (GDScript), .tscn (scene), and config files.

### Step 2: Check Each File Against Standards

#### **Naming Conventions**
- ✅ Variables & functions: `snake_case` (e.g., `player_health`, `calculate_damage()`)
- ✅ Constants: `SCREAMING_SNAKE_CASE` (e.g., `MAX_ENEMIES`, `TILE_SIZE`)
- ✅ Classes & Nodes: `PascalCase` (e.g., `class_name MechController`)
- ✅ Private members: prefix with underscore (e.g., `_cached_path`, `_on_event()`)
- ❌ Flag: No mixing cases, no snake_case for classes, no CAPS for variables

#### **Type Hints (Mandatory)**
- ✅ All variables must have explicit types: `var speed: float = 300.0`
- ✅ All functions must have return types: `func spawn_enemy() -> Enemy:`
- ✅ All parameters must be typed: `func take_damage(amount: int) -> void:`
- ✅ Arrays typed: `var enemies: Array[Enemy] = []`
- ✅ @onready nodes typed: `@onready var sprite: Sprite2D = $Sprite2D`
- ❌ Flag: `var speed := 300.0` (inferred), `var enemies = []` (inferred), `func spawn_enemy():` (no return type)

#### **Self Reference Rules (Mandatory)**
- ✅ **PUBLIC variables/functions must use `self.`**:
  - `self.health -= amount`
  - `self.take_damage(10)`
  - `self.died.emit(self)`
- ✅ **Private variables/functions do NOT use `self.`**:
  - `_update_internal_state()` (no self.)
  - `_cached_target` (no self.)
- ❌ Flag: Missing `self.` on public members (e.g., `health -= amount`, `die()` when should be `self.die()`)

#### **Signals**
- ✅ Named in past tense: `signal enemy_died`, `signal wave_completed`, `signal crop_harvested`
- ✅ Descriptive with parameters: `signal player_damaged(amount: int, source: Node)`
- ✅ Always disconnect in `_exit_tree()`:
  ```gdscript
  func _exit_tree() -> void:
      if EventBus.wave_started.is_connected(_on_wave_started):
          EventBus.wave_started.disconnect(_on_wave_started)
  ```
- ❌ Flag: Present tense signals (`signal spawn`, `signal damage`), missing disconnect, vague names

#### **No Magic Numbers**
- ✅ All numeric constants in GameConfig.gd or config files
- ✅ Use named constants: `const LOW_HEALTH_THRESHOLD: int = 50`
- ✅ Use @export for designer-tweakable values
- ❌ Flag: Bare numbers in code (e.g., `if health < 50:`, `velocity *= 300.0`)

#### **File Organization**
- ✅ One class per file
- ✅ Filename matches class name: `MechController.gd` for `class_name MechController`
- ✅ Scene + Script pair: `MechController.tscn` + `MechController.gd`
- ✅ Gameplay code in `/src/` only
- ✅ Autoloads in `/autoload/` only
- ✅ Configs in `/config/` only
- ✅ UI scenes in `/src/ui/` only
- ✅ Folder names: `snake_case`
- ✅ File names: `PascalCase`
- ❌ Flag: Scripts at root, gameplay code in `/scenes/`, mixed folder/file naming

#### **Performance (Critical for 1000+ enemies)**
- ✅ Shared pathfinding: `_calculate_path_once()` per wave, not per enemy
- ✅ Cached references: `@onready var _player: Node2D = ...`
- ✅ No `get_node()` in `_process()` loops
- ✅ Object pooling for spawned entities
- ✅ Disable processing when not needed: `set_process(false)`
- ✅ Use `VisibleOnScreenNotifier2D` to manage physics processing
- ❌ Flag: Per-enemy A* calculations, repeated `get_node()`, no pooling, always-on processing

#### **Documentation**
- ✅ Public functions have docstrings: `## Spawns a wave of enemies...`
- ✅ Complex logic has explanatory comments (WHY, not WHAT)
- ✅ TODO/FIXME tags used for known issues
- ❌ Flag: Missing docstrings on public functions, comments that just repeat code

#### **Code Style**
- ✅ Max 100 characters per line
- ✅ One statement per line (no `if x: do_thing()`)
- ✅ Indentation: tabs or 4 spaces (consistent)
- ✅ Private callback functions: `func _on_event() -> void:` (no parameters in name)
- ❌ Flag: Lines > 100 chars, multiple statements per line, inconsistent indentation

#### **Anti-Patterns to Flag**
- ❌ Direct node references: `get_node("/root/Main/Player/MechController")`
- ❌ String-based states: `var state = "idle"` (use enums)
- ❌ Global mutable state (everything accessed via autoloads should be read-only or signal-based)
- ❌ Hardcoded input keys: `Input.is_key_pressed(KEY_W)` (use Input Map actions)
- ❌ Per-frame expensive lookups: `get_tree().get_nodes_in_group("player")[0]` in `_process()`

#### **Scene Structure**
- ✅ Reusable entities use inherited scenes (BaseCrop.tscn extends Node2D)
- ✅ Root node type matches purpose: CharacterBody2D for player, Area2D for detection
- ✅ Scene name matches script name
- ❌ Flag: Non-inherited entity scenes, mismatched scene/script names

### Step 3: Generate Report

For each file, output:

```
## File: path/to/File.gd

✅ PASS
- Type hints: Complete
- Self reference: Correct
- Naming: Correct
- No magic numbers
- Signals properly managed

⚠️  ISSUES FOUND
- [ ] Line 45: Missing `self.` on public variable `health -= amount`
- [ ] Line 12: Magic number `50` should be named constant `LOW_HEALTH_THRESHOLD`
- [ ] Missing type hint: `func spawn_enemy() -> ???`
- [ ] Line 78: Direct node reference should use signals
- [ ] Missing docstring on public function `calculate_damage()`

---
```

### Step 4: Summary

Provide final count:
```
✅ Files Passing: X
⚠️  Files with Issues: Y
🚫 Critical Issues: Z (blocking patterns)

Recommendation: [READY TO COMMIT] or [FIX ISSUES FIRST]
```

## Key References
- **Type Hints Rule**: All variables and functions must be explicitly typed (Godot 4 "Warning as Error")
- **Self Reference Rule**: Use `self.` for public members only, never for private members
- **Magic Numbers**: ZERO tolerance - all constants in config files
- **Performance**: Non-negotiable for 1000+ enemy target
- **File Organization**: NEVER deviate without updating FILE_STRUCTURE.md

## Examples

### ✅ GOOD Pattern
```gdscript
# WaveManager.gd
extends Node

signal wave_spawned(count: int)

var current_wave: int = 0  # Public, use self.
var _shared_path: PackedVector2Array  # Private, no self.

const MAX_WAVE_ENEMIES: int = 100
const WAVE_SCALING: float = 1.25

func spawn_wave(wave_number: int) -> int:
    self.current_wave = wave_number
    var count = _calculate_enemy_count(wave_number)
    self.wave_spawned.emit(count)
    return count

func _calculate_enemy_count(wave: int) -> int:
    return int(GameConfig.WAVE_BASE_COUNT * pow(WAVE_SCALING, wave))
```

### ❌ BAD Pattern (Fix These)
```gdscript
# WaveManager.gd
extends Node

signal wave_spawned  # Vague signal
var current_wave = 0  # No type hint
var cached_path = []  # Inferred type, missing underscore

func spawn_wave(wave_number):  # No return type
    current_wave = wave_number  # Missing self.
    var count = 100 * (1.25 ** wave_number)  # Magic numbers!
    wave_spawned.emit()
    return count
```

---

**Last Updated**: Based on CODING_STANDARDS.md v1.0
