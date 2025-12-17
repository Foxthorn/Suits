# PROJECT_CONTEXT.md
**Project Codename:** SUITS: Iron Harvest (working title)
**Genre:** Mech-Piloted Farming + Wave-Defense / Tower-Defense Hybrid
**Core Fantasy:** You are a lone mech pilot defending and expanding an ever-growing farm against escalating alien bug hordes (inspired by Love, Death + Robots “Suits”).

### One-Sentence Pitch
A top-down/isometric hex-grid farming & wave-defense game where every crop you plant and harvest funds bigger guns, stronger armor, and automated defenses for your mech — survive infinitely scaling nights.

### Target Platforms (in order of priority)
1. PC (Windows/Linux/macOS + Steam) – primary
2. Web (HTML5) – for quick demos & feedback
3. Mobile (iOS/Android) – post-launch polish
4. Consoles – future (via porting partners)

### Tech Stack (locked decisions – DO NOT deviate)
- Engine: Godot 4.3+ (latest stable or 4.4 when released)
- Primary language: GDScript for 95% of gameplay code (fast iteration, AI-friendly)
- Performance-critical sections only: C# (.NET) via GDExtension or Godot-CSharp
- Grid: Hexagonal (flat-top preferred, pointy-top acceptable if art demands) using native TileMapLayer + TileSet hexagon shape
- Infinite / procedural map via chunked TileMapLayers (load/unload based on camera)
- Pathfinding: AStarGrid2D with pre-baked or occasionally rebaked paths (shared per wave) – NO per-enemy full A* every frame
- Art pipeline: AI-generated + heavily use Kenney.nl CC0 assets as placeholders and final low-poly/scifi style
- Version control: Git (GitHub) with pre-commit hooks + Continue.dev + Sweep AI workflow already configured

### Visual & Audio Style Guidelines
- Perspective: Top-down isometric (30–45° camera) or pure top-down – decide in first month
- Art style: Clean stylized low-poly / pixel-art hybrid acceptable (think RimWorld meets Factorio with mechs)
- Color palette: Day = warm earth tones, Night = high-contrast neon + bloom (defense phase)
- Audio: Synthwave / industrial during waves, calm acoustic/lo-fi during farming

### Core Systems (must exist)
- Hex-based farm building & crop growth cycles
- Resource/income loop (crops → credits → mech & tower upgrades)
- Wave manager with exponential scaling (enemy count, speed, HP, special types)
- Mech controller (WASD + mouse aim or twin-stick)
- Tower/turret auto-targeting + manual override
- Day/Night cycle (strict time limit per day)
- Persistent upgrades between runs (roguelite progression layer planned for v1.5+)

### Coding & Architecture Standards (ENFORCE EVERYWHERE)
- Scene hierarchy: Always use inherited scenes for anything reusable (crops, enemies, towers, bullets)
- Signals only for communication – NO tight coupling
- All gameplay code lives under `/src/` (e.g. `/src/systems/`, `/src/entities/`, `/src/ui/`)
- Autoload singletons under `/autoload/` clearly named and documented
- Use `const` enums aggressively
- No magic numbers – everything in `/config/game_config.gd` or scene-specific constants
- Enemy movement: PathFollow2D or shared waypoint lerp (see performance guidelines)
- Use `@tool` scripts for editor helpers (hex highlighting, placement previews)
- Comments: Write WHY, not what – AI agents already see the what
- Folder naming: snake_case
- File naming: PascalCase for scenes & scripts (MySystem.tscn / MySystem.gd)

### Performance Rules (non-negotiable for horde scaling)
- Max 1000+ simultaneous enemies target
- Shared path or PathFollow2D for waves
- Object pooling for enemies, bullets, particles, effects
- Disable _process/_physics_process on off-screen enemies when possible
- Use MultiMesh or GPU particles for huge swarms if needed
- TileMap merging enabled, occlusion culling on

### AI Agent Instructions (you are reading this!)
You are helping build a solo-dev Godot 4 hex-grid farming wave-defense game.
- Always assume hexagonal flat-top grid unless told otherwise this week
- Prefer simple, readable GDScript solutions over clever C# unless performance is proven bottleneck
- When generating art prompts, include “low-poly stylized scifi farming mech” keywords
- Never suggest Unity, Unreal, or GameMaker
- If unsure about scope, bias toward “vertical slice first” (one fully working day/night cycle with 3 crop types, 2 enemy types, 1 tower, basic mech)

### Related Documentation
- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design, data flow, and architectural decisions
- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - Project organization and file naming
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Code style and best practices
- [VERTICAL_SLICE.md](VERTICAL_SLICE.md) - Implementation roadmap

### Documentation Update Rules
- **When making architectural changes** (new systems, signal flows, camera changes, etc.), update `/ARCHITECTURE.md`
- **When changing system responsibilities or interactions**, update relevant sections in `/ARCHITECTURE.md`
- **When adding/removing files or folders**, update `FILE_STRUCTURE.md`
- **When establishing new coding patterns**, update `CODING_STANDARDS.md`
