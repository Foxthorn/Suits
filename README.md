# SUITS: Iron Harvest

> **A hex-grid mech farming & wave-defense game where crops fund firepower**

## 🎮 Core Vision

You are a lone mech pilot defending and expanding an ever-growing farm against escalating alien bug hordes. Every crop you plant and harvest funds bigger guns, stronger armor, and automated defenses. Survive infinitely scaling nights in this top-down/isometric farming & tower-defense hybrid inspired by *Love, Death + Robots "Suits"*.

## 🌟 One-Sentence Pitch

A top-down/isometric hex-grid farming & wave-defense game where every crop you plant and harvest funds bigger guns, stronger armor, and automated defenses for your mech — survive infinitely scaling nights.

## 🎯 Design Pillars

- **Farm by Day, Fight by Night**: Strict day/night cycle — plant & optimize during the day, defend during escalating waves at night
- **Resource Loop**: Crops → Credits → Mech & Tower Upgrades → Survive Harder Waves
- **Infinite Scaling**: Exponentially harder enemy waves (count, speed, HP, special types)
- **Hex-Grid Strategy**: Tactical placement of crops, towers, and defensive structures on a hexagonal grid
- **Mech Power Fantasy**: Direct piloting (WASD + mouse aim) with manual targeting override

## 🛠️ Tech Stack

- **Engine**: Godot 4.3+ (GDScript primary, C# for performance-critical sections)
- **Grid**: Hexagonal (flat-top) using native TileMapLayer
- **Map**: Infinite/procedural via chunked TileMapLayers
- **Pathfinding**: AStarGrid2D with shared/pre-baked paths (optimized for 1000+ enemies)
- **Art**: AI-generated + Kenney.nl CC0 assets (stylized low-poly scifi)
- **Audio**: Synthwave/industrial (combat) + lo-fi/acoustic (farming)

## 🎨 Visual Style

- **Perspective**: Top-down isometric (30–45°) or pure top-down
- **Art Style**: Clean stylized low-poly (think RimWorld meets Factorio with mechs)
- **Color Palette**: Warm earth tones (day) + neon high-contrast bloom (night)

## 🎯 Target Platforms

1. **PC** (Windows/Linux/macOS + Steam) – Primary
2. **Web** (HTML5) – Quick demos & feedback
3. **Mobile** (iOS/Android) – Post-launch
4. **Consoles** – Future (via porting partners)

## 🏗️ Development Status

**Current Phase**: Pre-production / Vertical Slice  
**Goal**: One fully working day/night cycle with 3 crop types, 2 enemy types, 1 tower, and basic mech combat.

## 📋 Core Systems

- ✅ Hex-based farm building & crop growth
- ✅ Resource/income loop (crops → credits → upgrades)
- ✅ Wave manager with exponential scaling
- ✅ Mech controller (WASD + mouse aim)
- ✅ Tower/turret auto-targeting + manual override
- ✅ Day/Night cycle with strict time limits
- 🔄 Persistent roguelite progression (planned v1.5+)

## 🤖 Development Workflow

This is a solo-dev project with heavy AI-assisted workflow:
- **Version Control**: Git (GitHub) with pre-commit hooks
- **AI Tools**: Continue.dev + Sweep AI configured
- **Art Pipeline**: AI-generated + CC0 Kenney assets

## 📖 Documentation

- See [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) for complete technical specifications
- See [FILE_STRUCTURE.md](./FILE_STRUCTURE.md) for project organization rules

## 📝 License

[Specify your license here]

---

*Last updated: 2025-12-11*
