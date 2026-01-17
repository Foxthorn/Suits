class_name GameConfig
## Global game configuration constants
## All tunable gameplay values live here - NO MAGIC NUMBERS in gameplay code!

#region DEBUG
const DEBUG_MODE: bool = true
#endregion

#region Mech / Player Settings
const MECH_MOVE_SPEED: float = 200.0  # pixels per second
const MECH_MAX_HEALTH: float = 100.0
const MECH_STARTING_HEALTH: float = 100.0
const MECH_ROTATION_SPEED: float = 0.0  # 0 = instant snap to mouse (can add lerp later)
const MECH_COLLISION_RADIUS: float = 30.0

#endregion

#region Grid Settings
const HEX_TILE_SIZE: Vector2i = Vector2i(120, 140)
const GRID_SIZE: Vector2i = Vector2i(15, 15)  # 15x15 for vertical slice

#endregion

#region Day/Night Cycle (Step 3)
const DAY_DURATION: float = 60.0  # seconds
const NIGHT_DURATION: float = 45.0  # seconds
const DAY_TINT: Color = Color.WHITE
const NIGHT_TINT: Color = Color(0.2, 0.2, 0.4, 1.0)

#endregion

#region Crop Settings (Step 4)
const CROP_WHEAT_GROW_TIME: float = 30.0
const CROP_WHEAT_COST: int = 10
const CROP_WHEAT_VALUE: int = 25

const CROP_CORN_GROW_TIME: float = 60.0
const CROP_CORN_COST: int = 25
const CROP_CORN_VALUE: int = 80

const CROP_ALIEN_FRUIT_GROW_TIME: float = 90.0
const CROP_ALIEN_FRUIT_COST: int = 50
const CROP_ALIEN_FRUIT_VALUE: int = 200

#endregion

#region Combat Settings (Step 6-7)
## Note: Weapon fire rate defined in WeaponConfig.WEAPON_FIRE_RATE (single source of truth)
const BULLET_SPEED: float = 400.0
const BULLET_LIFETIME: float = 3.0

#endregion

#region Enemy Settings (Step 6)
const ENEMY_RUSHER_SPEED: float = 150.0
const ENEMY_RUSHER_HP: float = 30.0
const ENEMY_RUSHER_DAMAGE: float = 10.0

const ENEMY_SHOOTER_SPEED: float = 80.0
const ENEMY_SHOOTER_HP: float = 50.0
const ENEMY_SHOOTER_FIRE_RATE: float = 2.0

#endregion

#region Wave Settings (Step 6)
const WAVE_BASE_ENEMY_COUNT: int = 5
const WAVE_SCALING_FACTOR: int = 3
const WAVE_RUSHER_PERCENTAGE: float = 0.7  # 70% rushers, 30% shooters

#endregion

#region Economy (Step 5)
const STARTING_CREDITS: int = 100
const UPGRADE_REPAIR_COST: int = 50
const UPGRADE_REPAIR_AMOUNT: float = 50.0
const UPGRADE_DAMAGE_COST: int = 100
const UPGRADE_DAMAGE_BONUS: float = 0.1  # +10%
const UPGRADE_MAX_HP_COST: int = 150
const UPGRADE_MAX_HP_BONUS: float = 25.0

#endregion

#region Tower Settings (Step 8)
const TOWER_BASIC_COST: int = 75
const TOWER_BASIC_RANGE: float = 300.0
const TOWER_BASIC_DAMAGE: float = 15.0
const TOWER_BASIC_FIRE_RATE: float = 1.0

#endregion

#region Physics & Collision Layers
## Layer bit values for Godot physics collision detection
## Formula: bit_value = 2^(layer_number - 1)
## Usage: collision_layer = GameConfig.COLLISION_LAYER_PLAYER  # Sets entity to layer 2
##        collision_mask = GameConfig.COLLISION_MASK_ENEMIES    # Detects entities on layer 3

# Layer definitions (1-9 in Godot)
const COLLISION_LAYER_WORLD: int = 1                # Layer 1: Static world geometry
const COLLISION_LAYER_PLAYER: int = 2               # Layer 2: Player mech
const COLLISION_LAYER_ENEMIES: int = 4              # Layer 3: Enemy entities (bit value = 2^2)
const COLLISION_LAYER_ENEMY_PROJECTILES: int = 8    # Layer 4: Enemy-fired projectiles (bit value = 2^3)
const COLLISION_LAYER_PLAYER_PROJECTILES: int = 16  # Layer 5: Player-fired projectiles (bit value = 2^4)
const COLLISION_LAYER_TOWERS: int = 32              # Layer 6: Automated turrets (bit value = 2^5)
const COLLISION_LAYER_CROPS: int = 64               # Layer 7: Planted crops (bit value = 2^6)
const COLLISION_LAYER_GROUND_ITEMS: int = 128       # Layer 8: Dropped loot/items (bit value = 2^7)
const COLLISION_LAYER_UI_INTERACTIVE: int = 256     # Layer 9: Interactive UI elements (bit value = 2^8)

# Collision masks for common entity types
# These define which layers each entity type should detect
const COLLISION_MASK_MECH: int = 0b0000_1101              # Detect: world(1), enemies(3), enemy_projectiles(4)
const COLLISION_MASK_PLAYER_PROJECTILES: int = 0b0000_0100  # Detect: enemies(3) only
const COLLISION_MASK_ENEMY: int = 0b0010_0011             # Detect: world(1), player(2), towers(6)
const COLLISION_MASK_ENEMY_PROJECTILES: int = 0b0000_0010   # Detect: player(2) only
const COLLISION_MASK_TOWER: int = 0b0000_0101             # Detect: world(1), enemies(3) - towers need to detect enemies to target them
const COLLISION_MASK_CROP: int = 0                        # Detect: nothing (area-only)

#endregion
