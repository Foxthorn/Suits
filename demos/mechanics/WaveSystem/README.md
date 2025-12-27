# Wave System Demo

**Purpose**: Test enemy spawning, wave progression, and the day/night cycle integration.

**Run**: Open `WaveSystemDemo.tscn` and press Play

## What This Tests

✅ Enemy spawning at night starts
✅ Enemies spawn around mech at configurable distance
✅ Rusher enemies (red) move fast toward mech
✅ Shooter enemies (green) move slower
✅ Wave scaling formula: `5 + (wave * 3)` enemies
✅ 70% rushers, 30% shooters spawn ratio
✅ Day/night cycle controls wave progression
✅ Wave ends when all enemies defeated
✅ TimeManager blocks night from ending until wave complete

## Controls

- **WASD**: Move mech around the map
- **Mouse**: Aim/rotate mech (prepares for combat in later steps)
- **ESC**: Return to main menu (when implemented)

## Expected Behavior

### Night 1
- ~5 enemies spawn in 4 directions around mech
- Mostly red (rushers), some green (shooters)
- Enemies path toward mech's current position
- 45 second timer, but extends until all enemies defeated

### After Wave Clears
- Night ends, day begins
- Timer resets to 60 seconds

### Night 2
- ~8 enemies spawn (5 + 2*3 = 11, but 70/30 split)
- Scaling makes it slightly harder
- Same spawn mechanic

## Architecture Notes

**WaveManager** is the central system:
- Spawns enemies when night starts (signal from TimeManager)
- Tracks active enemies in `enemies_in_wave` array
- Removes enemies when they die (listens to `died` signal)
- Signals `wave_completed` when array is empty
- Tells TimeManager to allow/block night ending

**BaseEnemy** handles:
- Health and damage
- Direct movement toward mech
- Death and particles
- Signal emission when killed

**Enemy Types**:
- `RusherEnemy`: Melee damage on collision
- `ShooterEnemy`: TODO - projectile firing (Step 7)

## Configuration

All enemy values are in `config/enemy_config.gd`:

```gdscript
const RUSHER_SPEED: float = 150.0
const RUSHER_MAX_HP: float = 30.0
const SHOOTER_SPEED: float = 80.0
const SHOOTER_MAX_HP: float = 50.0
const WAVE_BASE_COUNT: int = 5
const WAVE_COUNT_PER_LEVEL: int = 3
const WAVE_RUSHER_PERCENTAGE: float = 0.7
```

## Next Steps

- **Step 7**: Add bullets/projectiles to ShooterEnemy
- **Step 7**: Add Mech weapon system to shoot back
- **Step 8**: Add tower placement and auto-targeting
