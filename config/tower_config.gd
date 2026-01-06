class_name TowerConfig
## Tower-specific configuration constants
## All tower balance values live here - NO MAGIC NUMBERS in tower scripts!
## Sprite loading uses AtlasTexture pattern similar to WeaponConfig.gd

#region Configuration
const TOWER_BULLET_POOL_SIZE: int = 100  # Max pooled tower bullets

#endregion

#region Tower Sprite Assets
## Tower sprites use fire bullet assets from New_All_Fire_Bullet_Pixel_16x16/
## This creates visual consistency between tower and projectile effects
const TOWER_SPRITE_SHEET_BASE: String = "res://assets/New_All_Fire_Bullet_Pixel_16x16/All_Fire_Bullet_Pixel_16x16_%02d.png"

enum TowerSpriteType {
	GATLING_YELLOW = 0,    # Yellow fire medium (main turret body)
	GATLING_ORANGE = 1,    # Orange fire medium (variant)
	SNIPER_BLUE = 2,       # Blue fire large (future sniper tower)
	FLAME_RED = 3,         # Red fire trail (future flame tower)
	ICE_CYAN = 5,          # Cyan ice variant (future ice tower)
}

## Sprite sheet file mapping for tower types
const TOWER_TYPE_SHEETS: Dictionary = {
	TowerSpriteType.GATLING_YELLOW: 1,   # Use sheet 01
	TowerSpriteType.GATLING_ORANGE: 1,   # Use sheet 01
	TowerSpriteType.SNIPER_BLUE: 2,      # Use sheet 02
	TowerSpriteType.FLAME_RED: 3,        # Use sheet 03
	TowerSpriteType.ICE_CYAN: 5,         # Use sheet 05
}

## AtlasTexture regions for each tower sprite type (x, y, width, height)
## Regions define which portion of the sprite sheet to extract
const TOWER_TYPE_REGIONS: Dictionary = {
	TowerSpriteType.GATLING_YELLOW: Rect2(176, 0, 16, 16),   # Yellow fire center
	TowerSpriteType.GATLING_ORANGE: Rect2(176, 0, 16, 16),   # Orange fire center
	TowerSpriteType.SNIPER_BLUE: Rect2(48, 4, 28, 28),       # Larger blue fire
	TowerSpriteType.FLAME_RED: Rect2(4, 40, 16, 12),         # Red fire trail
	TowerSpriteType.ICE_CYAN: Rect2(60, 40, 16, 24),         # Cyan ice effect
}

#endregion

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
const TOWER_GATLING_GUN_SPRITE_TYPE: TowerSpriteType = TowerSpriteType.GATLING_YELLOW  # Uses atlas texture
const TOWER_GATLING_GUN_BULLET_COLOR: Color = Color(1.0, 0.8, 0.0, 1.0)  # Yellow
const TOWER_GATLING_GUN_SIZE: float = 2.0        # Sprite scale (doubles size for tower visibility)
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
