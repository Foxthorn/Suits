# FILE_STRUCTURE.md — Project Organization

> **Living Document**: This file documents the folder and file organization for SUITS: Iron Harvest. Update this file whenever new folders, files, or structural reorganization occurs.

---

## Project File Tree

```
├── .godot/                      # Godot cache (gitignored)
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
├── addons/                      # Only vetted plugins (e.g. godot-kenney-ui, hex-tools)
├── docs/
│   ├── agent/                   # AI agent instructions (ALWAYS read before coding)
│   │   ├── PROJECT_CONTEXT.md   # Core vision, tech stack, coding standards
│   │   ├── FILE_STRUCTURE.md    # This file — project organization
│   │   ├── CODING_STANDARDS.md  # Code style, naming conventions, patterns
│   │   └── step_summaries/      # Implementation summaries for vertical slice steps
│   ├── verticalslice/           # Vertical slice planning and progress tracking
│   │   ├── VERTICAL_SLICE.md    # 10-step implementation plan
│   │   └── STEP_*_*.md          # Individual step completion summaries
│   └── ARCHITECTURE.md          # System design, architectural decisions, data flow
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
│   ├── ProgressManager.gd       # Upgrade purchase tracking (Step 5)
│   ├── GameStateManager.gd      # Game state, pause, win/loss conditions (Step 9)
│   ├── SaveManager.gd           # Save/load persistence
│   ├── AudioManager.gd          # Music and SFX control
│   └── EventBus.gd              # Central signal hub (future)
├── config/
│   ├── game_config.gd           # Global game constants & balance values
│   ├── crop_config.gd           # Crop-specific constants (NO magic numbers)
│   ├── enemy_config.gd          # Enemy types, stats, animation frames, sprite paths
│   ├── weapon_config.gd         # Weapon types, projectile balance values
│   ├── tower_config.gd          # Tower types, stats, projectile properties (✅ Step 8)
│   └── upgrade_config.gd        # Upgrade costs, effects, UI colors (Step 5)
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
│   │   ├── UpgradeShop.gd       # Upgrade shop UI controller (Step 5)
│   │   ├── HUD.gd              # Main HUD display controller
│   │   ├── PauseMenu.gd        # Pause menu controller (Step 9)
│   │   ├── DefeatScreen.gd     # Defeat screen controller (Step 9)
│   │   ├── VictoryScreen.gd    # Victory screen controller (Step 9)
│   │   └── ControlsOverlay.gd  # Controls overlay controller (Step 9)
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
│       ├── UpgradeShop.tscn     # Upgrade shop UI panel (Step 5)
│       ├── PauseMenu.tscn       # Pause menu UI (Step 9)
│       ├── DefeatScreen.tscn    # Defeat/game-over screen (Step 9)
│       ├── VictoryScreen.tscn   # Victory/win screen (Step 9)
│       └── ControlsOverlay.tscn # Controls reference overlay (Step 9)
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
```

---

## Related Documentation

- **[ARCHITECTURE.md](/docs/ARCHITECTURE.md)** - System design, data flow, and architectural decisions
- **[CODING_STANDARDS.md](CODING_STANDARDS.md)** - Naming conventions, code style, and patterns
- **[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)** - Project vision and tech stack
- **[VERTICAL_SLICE.md](/docs/verticalslice/VERTICAL_SLICE.md)** - Implementation progress tracking

---

## Update Policy

When adding new folders, files, or reorganizing structure:
1. Update this file with new paths and descriptions
2. Update [ARCHITECTURE.md](/docs/ARCHITECTURE.md) if structural changes affect system design
3. Update [CODING_STANDARDS.md](CODING_STANDARDS.md) if new naming conventions or patterns are established
4. Update [VERTICAL_SLICE.md](/docs/verticalslice/VERTICAL_SLICE.md) if step deliverables are affected

---

## Key Organizational Principles

- **Autoloads** (`/autoload/`) - Global singletons only, no gameplay logic should live here
- **Configs** (`/config/`) - All balance values and constants, never hardcoded in scripts
- **Systems** (`/src/systems/`) - Game logic systems like HexGrid, WaveManager, PlantingSystem
- **Entities** (`/src/entities/`) - Reusable entity types (enemies, crops, towers, projectiles, etc.)
- **Scenes** (`/scenes/`) - Scene files (.tscn) organized by hierarchy matching `/src/` organization
- **UI** (`/scenes/ui/` + `/src/ui/`) - All user interface components
- **Demos** (`/demos/`) - Experimental and demo scenes, NOT for production (can be messy)

For more details on naming conventions and architectural patterns, see [CODING_STANDARDS.md](CODING_STANDARDS.md) and [ARCHITECTURE.md](/docs/ARCHITECTURE.md).
