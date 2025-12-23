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
│   ├── GameConfig.gd            # All tunable constants
│   ├── SaveManager.gd
│   ├── WaveManager.gd
│   ├── AudioManager.gd
│   └── EventBus.gd              # Central signal hub
├── config/
│   ├── game_config.gd           # Global game constants & balance values
│   └── crop_config.gd           # Crop-specific constants (NO magic numbers)
├── src/                         # ALL gameplay code lives here
│   ├── core/                    # Fundamental systems
│   │   ├── DayNightCycle.gd
│   │   └── UpgradeSystem.gd
│   ├── entities/                # Inherited scenes + scripts
│   │   ├── player/
│   │   │   └── MechController.tscn + .gd
│   │   ├── enemies/
│   │   │   ├── BugBasic.tscn
│   │   │   └── BugBoss.tscn
│   │   ├── towers/
│   │   └── crops/
│   │       └── BaseCrop.gd      # Base crop entity with growth states & harvest
│   ├── systems/
│   │   ├── HexGridManager.gd    # Placement, highlighting, snapping
│   │   ├── FarmSystem.gd
│   │   ├── PlantingSystem.gd    # Crop placement logic & ghost preview
│   │   ├── CropDatabase.gd      # Crop registry & lookup (uses CropConfig)
│   │   ├── Pathfinding.gd       # Shared AStarGrid2D wrapper
│   │   └── WaveSpawner.gd
│   ├── ui/
│   │   ├── HUD.tscn
│   │   ├── UpgradeMenu.tscn
│   │   └── BuildMenu.tscn
│   └── utils/
│       ├── Pool.gd              # Generic object pool
│       └── Math.gd              # Hex → pixel conversions
├── scenes/                      # Main game scenes
│   ├── Main.tscn                # Root scene (loads everything)
│   ├── world/
│   │   └── HexGrid.tscn         # Hex grid system (TileMap + camera follow)
│   ├── entities/
│   │   ├── mech/
│   │   │   └── Mech.tscn        # Player mech entity
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
