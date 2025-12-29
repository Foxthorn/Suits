class_name EnemyConfig
## Centralized enemy configuration - NO MAGIC NUMBERS!
## Defines all enemy types, stats, and visual settings
## Note: EnemyType enum is defined in EnemyDatabase.gd

#region Asset Paths
const ASSET_BASE_PATH: String = "res://assets/Insect-Enemy-Pack-V.1/"
#endregion

#region Visual Settings - Apply to ALL enemies
const COLLISION_RADIUS: float = 20.0  # Collision shape radius
const HOVER_INDICATOR_SIZE: int = 64  # Size of hover indicator when selected
const DEATH_PARTICLE_COUNT: int = 12  # Particles spawned on death

const ANIMATION_SPEED: float = 0.1  # Time between frame updates (seconds)
const IDLE_SCALE: float = 2.0  # Scale during idle
const WALK_SCALE: float = 2.0  # Scale during walk
const ATTACK_SCALE: float = 2.0  # Scale during attack
const HIT_SCALE: float = 2.0  # Scale during hit
const DEATH_SCALE: float = 2.0  # Scale during death

#endregion

#region Movement Settings
const MOVEMENT_THRESHOLD: float = 1.0  # Velocity threshold to distinguish movement from idle
#endregion

#region Rusher Configuration
const RUSHER_NAME: String = "Bug Rusher"
const RUSHER_DESCRIPTION: String = "Fast melee attacker. Rushes at mech, deals damage on collision."
const RUSHER_SPEED: float = 150.0  # pixels per second
const RUSHER_MAX_HP: float = 30.0
const RUSHER_DAMAGE: float = 10.0  # Damage per collision with mech
const RUSHER_COLLISION_COOLDOWN: float = 1.0  # Seconds between damage hits
const RUSHER_COLOR: Color = Color.RED

# Rusher sprite sheets (Little-Enemy from Insect Pack)
const RUSHER_SPRITE: String = "Little-Enemy/Sprite-Sheet/Little-Enemy-Idle-Sheet.png"  # Main sprite for fallback
const RUSHER_IDLE_SPRITE: String = "Little-Enemy/Sprite-Sheet/Little-Enemy-Idle-Sheet.png"
const RUSHER_WALK_SPRITE: String = "Little-Enemy/Sprite-Sheet/Little-Enemy-Walk-Sheet.png"
const RUSHER_ATTACK_SPRITE: String = "Little-Enemy/Sprite-Sheet/Little-Enemy-Attack-Sheet.png"
const RUSHER_HIT_SPRITE: String = "Little-Enemy/Sprite-Sheet/Little-Enemy-Hit-Sheet.png"
const RUSHER_DEATH_SPRITE: String = "Little-Enemy/Sprite-Sheet/Little-Enemy-Death-Sheet.png"

# Rusher animation frame counts
const RUSHER_IDLE_FRAMES: int = 4  # Number of frames in idle animation
const RUSHER_WALK_FRAMES: int = 4  # Number of frames in walk animation
const RUSHER_ATTACK_FRAMES: int = 7  # Number of frames in attack animation
const RUSHER_HIT_FRAMES: int = 3  # Number of frames in hit animation
const RUSHER_DEATH_FRAMES: int = 6  # Number of frames in death animation

const RUSHER_ATTACK_RANGE: float = 150.0  # Distance at which rusher switches to attacking

#endregion

#region Shooter Configuration
const SHOOTER_NAME: String = "Bug Shooter"
const SHOOTER_DESCRIPTION: String = "Ranged attacker. Maintains distance and shoots projectiles."
const SHOOTER_SPEED: float = 80.0  # pixels per second
const SHOOTER_MAX_HP: float = 50.0
const SHOOTER_DAMAGE: float = 15.0  # Damage per projectile hit
const SHOOTER_FIRE_RATE: float = 2.0  # Seconds between shots
const SHOOTER_PROJECTILE_SPEED: float = 250.0
const SHOOTER_PROJECTILE_DAMAGE: float = 15.0
const SHOOTER_PROJECTILE_RANGE: float = 400.0  # How far projectile travels
const SHOOTER_COLOR: Color = Color.DARK_GREEN

const SHOOTER_IDLE_FRAMES: int = 5  # Number of frames in idle animation
const SHOOTER_WALK_FRAMES: int = 5  # Number of frames in walk animation
const SHOOTER_ATTACK_FRAMES: int = 6  # Number of frames in attack animation
const SHOOTER_HIT_FRAMES: int = 3  # Number of frames in hit animation
const SHOOTER_DEATH_FRAMES: int = 6  # Number of frames in death animation

# Shooter sprite sheets (Fly-Enemy from Insect Pack)
const SHOOTER_SPRITE: String = "Fly-Enemy/Sprite-Sheet/Fly-Enemy-Idle-Sheet.png"  # Main sprite for fallback
const SHOOTER_IDLE_SPRITE: String = "Fly-Enemy/Sprite-Sheet/Fly-Enemy-Idle-Sheet.png"
const SHOOTER_WALK_SPRITE: String = "Fly-Enemy/Sprite-Sheet/Fly-Enemy-Walk-Sheet.png"
const SHOOTER_ATTACK_SPRITE: String = "Fly-Enemy/Sprite-Sheet/Fly-Enemy-Attack-Sheet.png"
const SHOOTER_HIT_SPRITE: String = "Fly-Enemy/Sprite-Sheet/Fly-Enemy-Hit-Sheet.png"
const SHOOTER_DEATH_SPRITE: String = "Fly-Enemy/Sprite-Sheet/Fly-Enemy-Death-Sheet.png"

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
const SPAWN_SPREAD_DISTANCE: float = 50.0  # Random distance variance for spawn points

#endregion

#region Particle Settings
const DEATH_PARTICLE_MIN_SPEED: float = 100.0  # Minimum speed for death particles
const DEATH_PARTICLE_MAX_SPEED: float = 200.0  # Maximum speed for death particles
const DEATH_PARTICLE_LIFETIME: float = 0.5  # How long particles stay alive

#endregion
