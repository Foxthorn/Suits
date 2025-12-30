# Combat System Demo 🎯

A comprehensive test scene for the Step 7 Combat System implementation in SUITS: Iron Harvest.

## Overview

This demo provides an interactive environment to test and validate all aspects of the weapon firing, projectile pooling, and combat mechanics.

## What's Being Tested

### ✅ Weapon System
- **Fire Rate**: 0.3 seconds between shots (3.3 shots/second)
- **Cooldown**: Prevents firing faster than the configured rate
- **Damage**: 10 base damage per bullet (upgradeable)
- **Multipliers**: Support for damage upgrades and boosts

### ✅ Projectile Pooling
- **Pre-allocation**: 50 bullets pre-allocated at startup
- **Reuse**: Bullets are returned to pool after expiry
- **Dynamic Growth**: Pool expands if all bullets are in use
- **Lifecycle**: reset() for return to pool, prepare() for reuse

### ✅ Bullet Mechanics
- **Movement**: Constant velocity (400 px/s)
- **Lifetime**: 3 seconds before automatic removal
- **Collision**: Area2D-based detection for enemies
- **Damage**: Enemy.take_damage() on collision
- **Effects**: Particle effects on impact

### ✅ Wave System Integration
- **Enemy Spawning**: Rusher and Shooter enemies spawn at night
- **Wave Progression**: Each wave spawns more enemies
- **Difficulty**: Enemies get stronger with each wave
- **Tracking**: Active enemy count and composition

### ✅ Mech Integration
- **Aiming**: Mech rotates toward mouse cursor
- **Firing**: Left-click to fire weapon
- **Health**: Mech takes damage from enemy collisions
- **Stats**: Real-time display of health, position, weapon status

## Controls

### Movement & Aiming
- **WASD**: Move mech
- **Mouse**: Aim (mech rotates toward cursor)
- **Left-Click**: Fire weapon

### Demo Controls
- **N**: Skip to night time (start wave)
- **E**: Spawn a test enemy (for isolated testing)
- **D**: Increase weapon damage by 50% (progression test)
- **ESC**: Return to main menu

## How to Use

### 1. Launch the Demo
Open `CombatSystemDemo.tscn` in Godot Editor and press Play.

### 2. Read the Instructions
The left panel displays:
- Objective and what to test
- Current controls
- Debug information

### 3. Test During Day Phase
- Move around with WASD
- Aim with mouse
- Press N to skip to night

### 4. Test During Night Phase
Enemies spawn automatically. You can:
- Fire at enemies with left-click
- Watch projectiles damage enemies
- See enemies die and waves complete
- Press E to spawn additional test enemies

### 5. Monitor Stats
Real-time displays show:
- Time and current phase
- Weapon status and cooldown
- Fire rate and damage
- Wave number and enemy count
- Mech health and position

## What to Verify

### Basic Functionality
- [ ] Weapon fires when left-click pressed
- [ ] Cooldown prevents firing too fast (0.3s minimum)
- [ ] Bullets move in aimed direction at 400 px/s
- [ ] Bullets disappear after 3 seconds
- [ ] Particle effects appear on enemy hits

### Projectile Pooling
- [ ] Bullets are reused (check console for firing message)
- [ ] Pool doesn't grow excessively
- [ ] Performance stays smooth with continuous firing

### Damage & Combat
- [ ] Enemies take damage when hit by bullets
- [ ] Enemy health decreases visibly
- [ ] Enemies die when health reaches 0
- [ ] Wave completes when all enemies defeated

### Wave Progression
- [ ] Night starts automatically or when skipped
- [ ] Enemies spawn around mech
- [ ] More enemies spawn in successive waves
- [ ] Different enemy types (Rushers/Shooters) behave differently

### Upgrade Testing
- [ ] Press D to increase damage
- [ ] Damage display updates in real-time
- [ ] Increased damage is visible in enemy defeat speed

### Input & Controls
- [ ] WASD moves mech smoothly
- [ ] Mouse aiming is responsive
- [ ] Mech rotates toward mouse cursor
- [ ] Firing works only when weapon is ready

## Console Debug Output

Watch the console for detailed logging:

```
CombatSystemDemo: Initialized
CombatSystemDemo: WeaponSystem found with 50 bullet pool size
CombatSystemDemo: Night 1 started - enemies spawning!
CombatSystemDemo: Bullet #1 fired from 600.0 towards 45.0°
CombatSystemDemo: Hit! Dealt 10.0 damage to enemy
CombatSystemDemo: Wave 1 complete! Total damage dealt: 100.0
```

## Known Limitations

This is a demo scene for testing Step 7 features:
- ❌ Towers not yet implemented (Step 8)
- ❌ Advanced upgrades not yet implemented (Step 5)
- ❌ No procedural map generation (using fixed HexGrid)
- ⚠️ Limited to 2 enemy types (Rusher, Shooter)

## Performance Considerations

The demo is optimized for:
- 60 FPS gameplay with 50+ enemies
- Smooth projectile firing with 50 pre-allocated bullets
- Efficient object pooling with zero allocations during gameplay
- Real-time UI updates without performance impact

## Next Steps

After validating this demo:

1. **Step 8**: Tower System
   - Tower placement
   - Auto-targeting
   - Tower firing and projectiles

2. **Step 5**: Upgrade System
   - Weapon damage upgrades
   - Max health upgrades
   - Tower upgrades

3. **Integration**: Full Game Loop
   - Day/night cycle
   - Crop farming
   - Combat
   - Wave progression

## Files

- `CombatSystemDemo.tscn` - Main demo scene
- `CombatSystemDemo.gd` - Demo controller script
- `README.md` - This file

## Related Documentation

- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design
- [VERTICAL_SLICE.md](/docs/verticalslice/VERTICAL_SLICE.md) - Step 7 implementation details
- [CODING_STANDARDS.md](/docs/agent/CODING_STANDARDS.md) - Code quality guidelines

---

**Demo Version**: 1.0
**Step**: 7 - Combat System
**Last Updated**: When Step 7 was completed
**Maintained By**: AI agents and development team
