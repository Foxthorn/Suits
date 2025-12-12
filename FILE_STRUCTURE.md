# FILE_STRUCTURE.md — NEVER deviate without updating this file

├── .godot/                      # Godot cache (gitignored)
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
├── addons/                      # Only vetted plugins (e.g. godot-kenney-ui, hex-tools)
├── assets/
│   ├── imported/                # NEVER commit — .import folder is gitignored
│   ├── raw/                     # Original .png/.gltf from Kenney / AI generation
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
│   └── game_config.gd           # Const enums & balance values
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
│   ├── systems/
│   │   ├── HexGridManager.gd    # Placement, highlighting, snapping
│   │   ├── FarmSystem.gd
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
│   └── levels/
│       └── ProceduralLevel.tscn
├── shaders/
│   ├── hex_highlight.gdshader
│   └── night_bloom.tres
├── audio/
│   ├── sfx/
│   └── music/
├── tests/                       # Future unit tests (GUT or manual)
├── PROJECT_CONTEXT.md
├── FILE_STRUCTURE.md
└── README.md

## Naming & Grouping Rules (non-negotiable)
- Scenes & scripts: PascalCase (MySystem.tscn + MySystem.gd)
- Folders: snake_case
- Reusable entities → always inherited scenes in /src/entities/
- Never put gameplay scripts at root or in scenes/ — only in /src/
- Every new system gets its own folder under /src/systems/ or /src/entities/
- All balance numbers live in GameConfig.gd — no magic numbers in logic
- UI scenes always under /src/ui/, never mixed with gameplay

Last updated: 2025-12-11