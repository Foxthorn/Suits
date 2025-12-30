class_name WeaponConfig
## Weapon system configuration - NO MAGIC NUMBERS!
## Defines all weapon types and mech combat balance values

#region Projectile Settings
const BULLET_SPEED: float = 400.0  # pixels per second
const BULLET_LIFETIME: float = 3.0  # seconds before auto-destroy
const BULLET_RADIUS: float = 5.0  # collision detection radius
const BULLET_COLOR: Color = Color.YELLOW

#endregion

#region Weapon Stats (Mech Primary Weapon)
const WEAPON_FIRE_RATE: float = 0.3  # seconds between shots
const WEAPON_DAMAGE: float = 10.0  # damage per bullet

#endregion

#region Particle Effects
const HIT_PARTICLE_COUNT: int = 8
const HIT_PARTICLE_SPEED: float = 100.0
const HIT_PARTICLE_LIFETIME: float = 0.5

#endregion

#region Audio Settings
const BULLET_FIRE_VOLUME: float = 0.5
const BULLET_HIT_VOLUME: float = 0.6

#endregion
