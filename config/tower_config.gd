class_name TowerConfig
## Tower-specific configuration constants
## All tower balance values live here - NO MAGIC NUMBERS in tower scripts!

#region Tower Costs & Economics
const TOWER_GATLING_GUN_COST: int = 50           # Budget turret with high fire rate
const TOWER_GATLING_GUN_UPGRADE_LEVEL_1: int = 75  # Damage upgrade cost

#endregion

#region Gatling Gun Stats
const TOWER_GATLING_GUN_RANGE: float = 250.0     # Detection radius in pixels
const TOWER_GATLING_GUN_DAMAGE: float = 8.0      # Damage per shot
const TOWER_GATLING_GUN_FIRE_RATE: float = 0.2   # Time between shots (seconds) = 5 shots/sec
const TOWER_GATLING_GUN_BULLET_SPEED: float = 350.0  # Projectile speed
const TOWER_GATLING_GUN_BULLET_LIFETIME: float = 3.0  # Projectile max lifetime

#endregion

#region Gatling Gun Visuals
const TOWER_GATLING_GUN_SPRITE: String = "res://assets/placeholders/tower_gatling.png"
const TOWER_GATLING_GUN_BULLET_COLOR: Color = Color(1.0, 0.8, 0.0, 1.0)  # Yellow
const TOWER_GATLING_GUN_SIZE: float = 1.0        # Sprite scale
const TOWER_GATLING_GUN_COLLISION_RADIUS: float = 20.0  # Collision shape size

#endregion

#region Tower Placement Visual Feedback
const TOWER_RANGE_INDICATOR_COLOR: Color = Color(0.5, 0.8, 1.0, 0.3)  # Blue transparent
const TOWER_RANGE_INDICATOR_WIDTH: float = 2.0   # Dashed circle line width
const TOWER_PLACEMENT_VALID_COLOR: Color = Color(0.0, 1.0, 0.0, 0.5)  # Green preview
const TOWER_PLACEMENT_INVALID_COLOR: Color = Color(1.0, 0.0, 0.0, 0.5)  # Red preview
const TOWER_PREVIEW_SCALE: float = 1.0

#endregion

#region Shared Tower Settings
const TOWER_ANIMATION_SPEED: float = 0.1  # Frame update interval for firing animation
const TOWER_HIT_FLASH_DURATION: float = 0.1  # Flash white when it shoots (visual feedback)
const TOWER_DETECTION_AREA_MARGIN: float = 1.0  # Slightly larger detection than stated range

#endregion

#region Future Tower Types (Placeholders)
# Sniper Tower: Low fire rate, high damage, long range
const TOWER_SNIPER_COST: int = 100
const TOWER_SNIPER_RANGE: float = 400.0
const TOWER_SNIPER_DAMAGE: float = 25.0
const TOWER_SNIPER_FIRE_RATE: float = 1.5

# Flame Tower: Medium damage, medium range, fire effect
const TOWER_FLAME_COST: int = 75
const TOWER_FLAME_RANGE: float = 200.0
const TOWER_FLAME_DAMAGE: float = 5.0
const TOWER_FLAME_FIRE_RATE: float = 0.3  # Continuous beam vs projectiles

# Ice Tower: Freeze/slow effect, medium damage
const TOWER_ICE_COST: int = 80
const TOWER_ICE_RANGE: float = 300.0
const TOWER_ICE_DAMAGE: float = 6.0
const TOWER_ICE_FIRE_RATE: float = 1.0
const TOWER_ICE_SLOW_AMOUNT: float = 0.5  # Slow enemies to 50% speed

#endregion
