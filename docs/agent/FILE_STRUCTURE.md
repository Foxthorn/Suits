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
│   ├── SaveManager.gd           # Save/load persistence
│   ├── AudioManager.gd          # Music and SFX control
│   └── EventBus.gd              # Central signal hub (future)
├── config/
│   ├── game_config.gd           # Global game constants & balance values
│   ├── crop_config.gd           # Crop-specific constants (NO magic numbers)
│   ├── enemy_config.gd          # Enemy types, stats, animation frames, sprite paths
│   └── weapon_config.gd         # Weapon types, projectile balance values (✅ NEW)
│   │   ├── DayNightCycle.gd
│   │   └── UpgradeSystem.gd
│   ├── entities/                # Inherited scenes + scripts
│   │   ├── player/
│   │   │   └── MechController.gd
│   │   ├── enemies/
│   │   │   ├── BaseEnemy.gd
│   │   │   ├── RusherEnemy.gd
│   │   │   └── ShooterEnemy.gd
│   │   ├── projectiles/
│   │   │   └── Bullet.gd            # Mech projectile with pooling (✅ NEW)
│   │   └── crops/
│   │   │   ├── BugBasic.tscn
│   │   │   └── BugBoss.tscn
│   │   ├── towers/
│   │   ├── HUD.tscn
│   │       └── BaseCrop.gd      # Base crop entity with growth states & harvest
│       ├── Pool.gd              # Generic object pool
│   │   ├── HexGridManager.gd    # Placement, highlighting, snapping
│   │   ├── FarmSystem.gd
│   ├── world/
│   │   └── HexGrid.tscn         # Hex grid system (TileMap + camera follow)
│   │   ├── EnemyDatabase.gd     # Enemy registry with sprite sheet animation metadata (✅ NEW)
│   │   ├── Pathfinding.gd       # Shared AStarGrid2D wrapper
│   │   └── WaveSpawner.gd
│   │   └── crops/
│   │       └── BaseCrop.tscn    # Base crop scene (instantiated by PlantingSystem)
│   └── levels/
│       └── ProceduralLevel.tscn
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
│   │   └── CropSystem/          # Complete crop planting system demo
│   │       ├── CropSystemDemo.tscn
│   │       └── CropSystemDemo.gd
│   ├── tutorials/               # Step-by-step tutorial scenes
│   │   ├── Tutorial01_Movement.tscn
│   │   └── Tutorial02_Farming.tscn
│   └── prototypes/              # Quick throwaway experiments
├── tests/                       # Future unit tests (GUT or manual)
└── README.md                    # User-facing project overview

## Related Documentation
- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design and architectural decisions
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Project vision and tech stack
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Code style guidelines

**Update Policy**: When adding new folders, files, or reorganizing structure, update both this file and relevant sections in ARCHITECTURE.md.

## Naming & Grouping Rules (non-negotiable)
- Scenes & scripts: PascalCase (MySystem.tscn + MySystem.gd)
- Folders: snake_case
- Reusable entities → always inherited scenes in /src/entities/
- Never put gameplay scripts at root or in scenes/ — only in /src/
- Every new system gets its own folder under /src/systems/ or /src/entities/
- All balance numbers live in config files (game_config.gd, crop_config.gd, etc.) — **NO MAGIC NUMBERS**
- System-specific configs should be separate files (e.g., crop_config.gd for crops)
- UI scenes always under /src/ui/, never mixed with gameplay
- Demos/tutorials live in /demos/ — never reference from production code
- Demo scenes can be messy/experimental — exempt from strict standards
- All enemy types have dedicated scene files in /scenes/entities/enemies/
- All database registries (CropDatabase, EnemyDatabase) are in /src/systems/
- Entity base classes (BaseEnemy, BaseCrop) are in /src/entities/ with implementations
- Entity scene files match class names: RusherEnemy.gd + RusherEnemy.tscn

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
3. **Scene Files** (`scenes/entities/enemi
es/`):
   - One .tscn per enemy type (RusherEnemy.tscn, ShooterEnemy.tscn)
   - Loaded as PackedScenes by WaveManager
   - No hardcoded stats — all from EnemyDatabase
4. **Configuration** (`config/enemy_config.gd`):
   - Central config with all enemy types and stats
   - Sprite paths, animation frame counts, balance values
   - EnemyDatabase reads from this file and builds registry
