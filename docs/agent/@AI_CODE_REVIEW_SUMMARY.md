Critical Issues 🔴
1. Sprite Loading Performance Problem
Location: src/entities/projectiles/Bullet.gd:228 (_setup_sprite)

Issue: Using synchronous load() in _ready() can cause frame drops during gameplay, especially with rapid bullet creation from the object pool.

Impact: The weapon system fires at 0.2s intervals (5 shots/sec). When bullets are retrieved from the pool and prepared, the sprite setup happens during active gameplay, potentially causing stuttering.

Recommendation: Pre-load sprite textures as class constants or use preload() at the class level

2. Race Condition in Continuous Fire
Location: src/entities/player/MechController.gd:140-143

Issue: The continuous fire implementation checks can_fire() and then calls fire(), but there's a window between these calls where the state could change in a multi-threaded context. While Godot's physics is single-threaded, this pattern is fragile.

Recommendation: Let fire() handle the cooldown check internally (it already does) and remove the redundant check, or make fire() return a boolean indicating success.

High Priority Issues 🟡
3. Memory Leak Risk with Placeholder Textures
Location: src/entities/projectiles/Bullet.gd:253-263 (_create_placeholder_texture)

Issue: Creating ImageTexture instances dynamically without caching means each bullet in the pool (50+ bullets) could create its own texture if sprite loading fails. These textures are never explicitly freed.

Recommendation: Cache the placeholder texture as a static variable

4. Collision Shape Offset Inconsistency
Location: scenes/entities/projectiles/Bullet.tscn

Issue: The CollisionShape2D was given an offset of Vector2(5, 5), but the sprite is centered. This creates a mismatch between visual position and collision detection.

Impact: Bullets will appear to hit slightly before they visually connect with enemies, or miss when they appear to hit.

Recommendation: Remove the offset or ensure the sprite has the same offset to maintain visual/physical alignment.

5. Fire Rate Inconsistency Between Configs
Location: config/game_config.gd:45 and config/weapon_config.gd:59

Issue: Two different config files define fire rate with different values (0.3 vs 0.2). Code uses WeaponConfig.WEAPON_FIRE_RATE (0.2), making the GameConfig value dead code.

Recommendation: Remove the duplicate constant from game_config.gd to maintain single source of truth.

6. Signal Connection Memory Leak
Location: src/systems/WeaponSystem.gd:70-72, 82-84

Issue: The _signal_connections dictionary tracks bullets but never removes entries when bullets are dynamically created beyond the pool size. Over time, this dictionary grows unbounded.

Recommendation: Clean up the dictionary when bullets are freed, or use a more robust pattern like bullet.expired.is_connected()
