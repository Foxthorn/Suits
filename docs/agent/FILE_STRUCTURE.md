# FILE_STRUCTURE.md — NEVER deviate without updating this file

├── .godot/                      # Godot cache (gitignored)
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
├── addons/                      # Only vetted plugins (e.g. godot-kenney-ui, hex-tools)
├── docs/
│   ├── agent/                   # AI agent instructions (ALWAYS read before coding)
│   │   ├── PROJECT_CONTEXT.md   # Core vision, tech stack, coding standards
│   │   ├── FILE_STRUCTURE.md    # This file — project organization rules
│   │   ├── CODING_STANDARDS.md  # Code style and best practices
│   │   └── step_summaries/      # Implementation summaries for vertical slice steps
│   ├── verticalslice/           # Vertical slice planning and progress tracking
│   │   ├── VERTICAL_SLICE.md    # 10-step implementation plan
│   │   └── STEP_*_*.md          # Individual step completion summaries
│   └── ARCHITECTURE.md          # System design and architectural decisions
├── assets/
│   ├── imported/                # NEVER commit — .import folder is gitignored
│   ├── raw/                     # Original .png/.gltf from Kenney / AI generation
│   ├── Fruit and Veg/           # Crop sprite assets
│   │   └── Fruit and Veg/       # Individual crop .png files
│   ├── kennyshexagon/           # Hex tile assets
│   └── textures/
│       ├── ui/
│       ├── environment/
│       ├── mechs/
│       ├── enemies/
│       └── effects/
├── autoload/                    # Global singletons only
│   ├── TimeManager.gd           # Day/night cycle management
│   ├── EconomyManager.gd        # Credits and economy system
│   ├── WaveManager.gd           # Enemy wave spawning and tracking
│   ├── ProgressManager.gd       # Upgrade purchase tracking (NEW - Step 5)
│   ├── SaveManager.gd           # Save/load persistence
│   ├── AudioManager.gd          # Music and SFX control
│   └── EventBus.gd              # Central signal hub (future)
├── config/
│   ├── game_config.gd           # Global game constants & balance values
│   ├── crop_config.gd           # Crop-specific constants (NO magic numbers)
│   ├── enemy_config.gd          # Enemy types, stats, animation frames, sprite paths
│   ├── weapon_config.gd         # Weapon types, projectile balance values
│   ├── tower_config.gd          # Tower types, stats, projectile properties (✅ Step 8)
│   └── upgrade_config.gd        # Upgrade costs, effects, UI colors (NEW - Step 5)
├── src/
│   ├── systems/
│   │   ├── HexGrid.gd           # Hex grid system with camera control
│   │   ├── EnemyDatabase.gd     # Enemy registry with extensible types
│   │   ├── TowerDatabase.gd     # Tower registry with extensible types (✅ Step 8)
│   │   ├── TowerSystem.gd       # Tower placement mode and validation (✅ Step 8)
│   │   ├── TowerWeaponSystem.gd # Tower projectile pooling and firing (✅ Step 8)
│   │   ├── CropDatabase.gd      # Crop registry with extensible types
│   │   ├── PlantingSystem.gd    # Crop placement mode
│   │   └── WeaponSystem.gd      # Mech projectile pooling and firing
│   ├── ui/
│   │   └── UpgradeShop.gd       # Upgrade shop UI controller (NEW - Step 5)
│   └── entities/
│       ├── player/
│       │   └── MechController.gd
│       ├── enemies/
│       │   ├── BaseEnemy.gd
│       │   ├── RusherEnemy.gd
│       │   └── ShooterEnemy.gd
│       ├── crops/
│       │   └── BaseCrop.gd
│       ├── towers/
│       │   ├── BaseTower.gd     # Base tower class (✅ Step 8)
│       │   └── GatlingGun.gd    # Rapid-fire tower (✅ Step 8)
│       └── projectiles/
│           ├── Bullet.gd
│           └── TowerBullet.gd   # Tower projectile (✅ Step 8)
├── scenes/
│   ├── MainGame.tscn            # Root scene
│   ├── world/
│   │   └── HexGrid.tscn         # Hex grid with TileMapLayer
│   ├── entities/
│   │   ├── mech/
│   │   │   └── Mech.tscn        # Player mech entity
│   │   ├── enemies/
│   │   │   ├── BaseEnemy.tscn   # Base enemy scene
│   │   │   ├── RusherEnemy.tscn # Fast melee attacker
│   │   │   └── ShooterEnemy.tscn # Ranged attacker
│   │   ├── crops/
│   │   │   └── BaseCrop.tscn    # Crop growth entity
│   │   ├── towers/
│   │   │   ├── GatlingGun.tscn  # Rapid-fire turret (✅ Step 8)
│   │   │   └── (more tower types here)
│   │   └── projectiles/
│   │       ├── Bullet.tscn      # Player projectile
│   │       └── TowerBullet.tscn # Tower projectile (✅ Step 8)
│   └── ui/
│       ├── HUD.tscn             # Main heads-up display
│       └── UpgradeShop.tscn     # Upgrade shop UI panel (NEW - Step 5)
├── shaders/
│   ├── hex_highlight.gdshader
│   └── night_bloom.tres
├── audio/
│   ├── sfx/
│   └── music/
├── demos/                       # Demo scenes & tutorial scripts (NOT for production)
│   ├── mechanics/               # Individual system demos
│   │   ├── HexGridDemo.tscn     # Hex placement & highlighting test
│   │   ├── PathfindingDemo.tscn # A* visualization
│   │   ├── WaveSpawnerDemo.tscn # Enemy wave testing
│   │   ├── CropSystem/          # Complete crop planting system demo
│   │   │   ├── CropSystemDemo.tscn
│   │   │   └── CropSystemDemo.gd
│   │   └── TowerSystem/         # Complete tower placement and firing demo (✅ Step 8)
│   │       ├── TowerSystemDemo.tscn
│   │       ├── TowerSystemDemo.gd
│   │       └── README.md
│   ├── tutorials/               # Step-by-step tutorial scenes
│   │   ├── Tutorial01_Movement.tscn
│   │   └── Tutorial02_Farming.tscn
│   └── prototypes/              # Quick throwaway experiments
├── tests/                       # Future unit tests (GUT or manual)
└── README.md                    # User-facing project overview

---

## Related Documentation
- [ARCHITECTURE.md](/docs/ARCHITECTURE.md) - System design and architectural decisions
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Project vision and tech stack
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Code style guidelines

**Update Policy**: When adding new folders, files, or reorganizing structure, update both this file and relevant sections in ARCHITECTURE.md.

---

## Naming & Grouping Rules (non-negotiable)
- Scenes & scripts: PascalCase (MySystem.tscn + MySystem.gd)
- Folders: snake_case
- Reusable entities → always inherited scenes in /src/entities/
- Never put gameplay scripts at root or in scenes/ — only in /src/
- Every new system gets its own folder under /src/systems/ or /src/entities/
- All balance numbers live in config files (game_config.gd, crop_config.gd, tower_config.gd, upgrade_config.gd, etc.) — **NO MAGIC NUMBERS**
- System-specific configs should be separate files (e.g., crop_config.gd for crops, tower_config.gd for towers, upgrade_config.gd for upgrades)
- UI scenes always under `/src/ui/`, never mixed with gameplay
- UI scripts always under `/src/ui/`, never in scenes/
- Demos/tutorials live in /demos/ — never reference from production code
- Demo scenes can be messy/experimental — exempt from strict standards
- All entity types (enemies, crops, towers) have dedicated scene files and scripts
- All database registries (CropDatabase, EnemyDatabase, TowerDatabase) are in /src/systems/
- Entity base classes (BaseEnemy, BaseCrop, BaseTower) are in /src/entities/ with implementations
- Entity scene files match class names: RusherEnemy.gd + RusherEnemy.tscn, GatlingGun.gd + GatlingGun.tscn

---

## Entity Inheritance Pattern

### Enemy Entity Architecture
All enemy types follow this pattern:
1. **BaseEnemy.gd**: Base class in `/src/entities/enemies/`
   - Handles health, damage, death signals
   - Manages sprite sheet animation (IDLE, WALK, ATTACK, HIT, DEATH states)
   - Loads stats from EnemyDatabase
2. **Subclasses** (RusherEnemy, ShooterEnemy, etc.):
   - Extend BaseEnemy
   - Set `enemy_type` before calling `super._ready()`
   - Override `_physics_process()` for unique behaviors
3. **Scene Files** (`scenes/entities/enemies/`):
   - One .tscn per enemy type (RusherEnemy.tscn, ShooterEnemy.tscn)
   - Loaded as PackedScenes by WaveManager
   - No hardcoded stats — all from EnemyDatabase
4. **Configuration** (`config/enemy_config.gd`):
   - Central config with all enemy types and stats
   - Sprite paths, animation frame counts, balance values
   - EnemyDatabase reads from this file and builds registry

### Tower Entity Architecture (Step 8 - Complete)
All tower types follow this pattern:
1. **BaseTower.gd**: Base class in `/src/entities/towers/` (✅ COMPLETED - Step 8)
   - Handles enemy detection via Area2D
   - Manages targeting logic (nearest enemy)
   - Manages fire rate and cooldown
   - Loads stats from TowerDatabase
   - Virtual `fire()` method for subclass override
2. **Subclasses** (GatlingGun, etc.) (✅ COMPLETED - Step 8):
   - Extend BaseTower
   - Set `tower_type` before calling `super._ready()`
   - Override `fire()` for unique firing behavior
   - Create TowerWeaponSystem instance for projectile management
3. **Scene Files** (`scenes/entities/towers/`) (✅ COMPLETED - Step 8):
   - One .tscn per tower type (GatlingGun.tscn, etc.)
   - Loaded as PackedScenes by TowerSystem
   - No hardcoded stats — all from TowerDatabase
4. **Configuration** (`config/tower_config.gd`) (✅ COMPLETED - Step 8):
   - Central config with all tower types and stats
   - Sprite paths, firing parameters, cost, visual feedback colors
   - TowerDatabase reads from this file and builds registry

### Crop Entity Architecture (Step 4 - Complete)
All crop types follow this pattern:
1. **BaseCrop.gd**: Base class in `/src/entities/crops/`
   - Handles growth states (PLANTED, GROWING, HARVESTABLE)
   - Manages sprite sheet animation across growth frames
   - Loads stats from CropDatabase
2. **Scene File** (`scenes/entities/crops/BaseCrop.tscn`):
   - Single reusable scene instantiated by PlantingSystem
   - Configured with crop_type on instantiation
   - No hardcoded stats — all from CropDatabase
3. **Configuration** (`config/crop_config.gd`):
   - Central config with all crop types and stats
   - Sprite paths, grow times, costs, values
   - CropDatabase reads from this file and builds registry
