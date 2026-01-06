class_name ProjectileConfig
## Projectile configuration for towers and other sources
## Centralized projectile balance values - NO MAGIC NUMBERS!

#region Tower Bullet Settings
## Tower bullet pool size for performance optimization
const TOWER_BULLET_POOL_SIZE: int = 100

## Default tower bullet properties
const TOWER_BULLET_LIFETIME: float = 3.0  # seconds before auto-destroy
const TOWER_BULLET_SPEED: float = 350.0  # pixels per second
const TOWER_BULLET_DAMAGE: float = 10.0  # damage per hit
const TOWER_BULLET_COLOR: Color = Color(1.0, 0.8, 0.0, 1.0)  # Yellow

## Tower bullet collision shape
const TOWER_BULLET_COLLISION_RADIUS: float = 4.0  # pixels

## Tower bullet sprite scale
const TOWER_BULLET_SPRITE_SCALE: float = 2.0  # Scale factor for visibility

#endregion

#region Tower Bullet Effects
## Particle effects on bullet impact
const TOWER_BULLET_HIT_PARTICLES: int = 8  # Number of particles on hit
const TOWER_BULLET_HIT_PARTICLE_SPEED_MIN: float = 100.0
const TOWER_BULLET_HIT_PARTICLE_SPEED_MAX: float = 200.0
const TOWER_BULLET_HIT_PARTICLE_LIFETIME: float = 0.5  # seconds
const TOWER_BULLET_HIT_PARTICLE_SCALE_MIN: float = 0.5
const TOWER_BULLET_HIT_PARTICLE_SCALE_MAX: float = 1.0

#endregion

#region Player Bullet Settings (Reference)
## Player bullet configuration is in WeaponConfig
## TowerWeaponSystem uses ProjectileConfig instead for tower-specific bullets
## This keeps tower and player weapons properly separated

#endregion
