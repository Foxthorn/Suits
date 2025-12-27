class_name EnemyConfig
## Centralized enemy configuration - NO MAGIC NUMBERS!
## Defines all enemy types, stats, and visual settings

enum EnemyType {
	RUSHER,
	SHOOTER
}

#region Visual Settings - Apply to ALL enemies
const COLLISION_RADIUS: float = 20.0  # Collision shape radius
const HOVER_INDICATOR_SIZE: int = 64  # Size of hover indicator when selected
const DEATH_PARTICLE_COUNT: int = 12  # Particles spawned on death

#endregion

#region Rusher Configuration
const RUSHER_NAME: String = "Bug Rusher"
const RUSHER_SPEED: float = 150.0  # pixels per second
const RUSHER_MAX_HP: float = 30.0
const RUSHER_DAMAGE: float = 10.0  # Damage per collision with mech
const RUSHER_COLLISION_COOLDOWN: float = 1.0  # Seconds between damage hits
const RUSHER_COLOR: Color = Color.RED
const RUSHER_SPRITE: String = ""  # Placeholder, use fallback color

#endregion

#region Shooter Configuration
const SHOOTER_NAME: String = "Bug Shooter"
const SHOOTER_SPEED: float = 80.0  # pixels per second
const SHOOTER_MAX_HP: float = 50.0
const SHOOTER_FIRE_RATE: float = 2.0  # Seconds between shots
const SHOOTER_PROJECTILE_SPEED: float = 250.0
const SHOOTER_PROJECTILE_DAMAGE: float = 15.0
const SHOOTER_PROJECTILE_RANGE: float = 400.0  # How far projectile travels
const SHOOTER_COLOR: Color = Color.DARK_GREEN
const SHOOTER_SPRITE: String = ""  # Placeholder, use fallback color

#endregion

#region Wave Scaling
const WAVE_BASE_COUNT: int = 5  # Base enemy count for wave 1
const WAVE_COUNT_PER_LEVEL: int = 3  # +3 enemies per wave
const WAVE_RUSHER_PERCENTAGE: float = 0.7  # 70% rushers, 30% shooters

#endregion

#region Spawn Settings
const SPAWN_DISTANCE_FROM_MECH: float = 500.0  # How far from mech to spawn enemies
const SPAWN_POINTS_PER_WAVE: int = 4  # Spawn from 4 different edge points
const SPAWN_SPREAD_ANGLE: float = PI * 0.25  # 45 degree spread around edge points

#endregion
