class_name WeaponConfig
## Weapon system configuration - NO MAGIC NUMBERS!
## Defines all weapon types and mech combat balance values

#region Projectile Settings
const BULLET_SPEED: float = 400.0  # pixels per second
const BULLET_LIFETIME: float = 3.0  # seconds before auto-destroy
const BULLET_RADIUS: float = 5.0  # collision detection radius
const BULLET_COLOR: Color = Color.YELLOW

# Sprite sheet configuration
const BULLET_SPRITE_SHEET_PATH: String = "res://assets/New_All_Fire_Bullet_Pixel_16x16/All_Fire_Bullet_Pixel_16x16_%02d.png"
const BULLET_SPRITE_SHEETS: int = 8  # Number of sprite sheet variants (00-07)

# Bullet types with their sprite sheet and region info
enum BulletType {
	FIRE_SMALL = 0,      # Small yellow fire ball
	FIRE_MEDIUM = 1,     # Medium yellow fire ball
	FIRE_LARGE = 2,      # Large yellow fire ball
	FIRE_TRAIL = 3,      # Fire with trail effect
	FIRE_BURST = 4,      # Burst/explosion type
	FIRE_COMET = 5,      # Comet/meteor type
	FIRE_SPARK = 6,      # Spark/particle type
	FIRE_WAVE = 7,       # Wave/beam type
}

# Bullet type to sprite sheet mapping (which file to load from)
const BULLET_TYPE_SHEETS: Dictionary = {
	BulletType.FIRE_SMALL: 0,
	BulletType.FIRE_MEDIUM: 1,
	BulletType.FIRE_LARGE: 2,
	BulletType.FIRE_TRAIL: 3,
	BulletType.FIRE_BURST: 4,
	BulletType.FIRE_COMET: 5,
	BulletType.FIRE_SPARK: 6,
	BulletType.FIRE_WAVE: 7,
}

# Bullet type to region in sprite sheet (x, y, width, height) in pixels
# These define which portion of the sprite sheet to extract for each bullet type
# Adjust these values based on actual sprite positions in each sheet file
const BULLET_TYPE_REGIONS: Dictionary = {
	BulletType.FIRE_SMALL: Rect2(176, 0, 16, 16),     # Small center sprite
	BulletType.FIRE_MEDIUM: Rect2(176, 0, 16, 16),   # Medium size
	BulletType.FIRE_LARGE: Rect2(48, 4, 28, 28),    # Large size
	BulletType.FIRE_TRAIL: Rect2(4, 40, 16, 12),    # Horizontal trail
	BulletType.FIRE_BURST: Rect2(32, 40, 20, 20),   # Burst effect
	BulletType.FIRE_COMET: Rect2(60, 40, 16, 24),   # Vertical comet
	BulletType.FIRE_SPARK: Rect2(4, 70, 12, 12),    # Small spark
	BulletType.FIRE_WAVE: Rect2(20, 70, 24, 16),    # Wave beam
}

# Default bullet type for primary weapon
const DEFAULT_BULLET_TYPE: BulletType = BulletType.FIRE_MEDIUM

#endregion

#region Weapon Stats (Mech Primary Weapon)
const WEAPON_FIRE_RATE: float = 0.2  # seconds between shots
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
