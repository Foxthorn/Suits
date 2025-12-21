# Crop System Demo - Visual Guide

## Screen Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  INSTRUCTIONS PANEL (Top-Left)      STATUS PANEL (Top-Right)       │
│  ┌──────────────────────────┐      ┌──────────────────────────┐   │
│  │  🌾 CROP SYSTEM DEMO 🌾  │      │    📊 STATUS            │   │
│  │  ─────────────────────   │      │  ─────────────────────  │   │
│  │                          │      │  DAY 1                  │   │
│  │  CONTROLS:               │      │  Time: 00:45            │   │
│  │  [1] Wheat  (10c, 30s)  │      │  Credits: 90            │   │
│  │  [2] Corn   (25c, 60s)  │      │  Planted: 1             │   │
│  │  [3] Alien  (50c, 90s)  │      │  Harvested: 0           │   │
│  │                          │      │  Earned: 0              │   │
│  │  CAMERA:                 │      └──────────────────────────┘   │
│  │  [Wheel] Zoom            │                                      │
│  │  [Arrows] Pan            │                                      │
│  │                          │                                      │
│  │  DEBUG CHEATS:           │                                      │
│  │  [C] +100 Credits        │                                      │
│  │  [F] Fast-forward        │                                      │
│  │  [N] Force Night         │                                      │
│  │  [D] Force Day           │                                      │
│  │  [R] Reset               │                                      │
│  └──────────────────────────┘                                      │
│                                                                     │
│             ┌──────────────────────────────────┐                   │
│             │                                  │                   │
│             │    HEX GRID (Center)            │                   │
│             │    ▽  ▽  ▽  ▽  ▽  ▽  ▽         │                   │
│             │   ▽  ▽  ▽  ▽  ▽  ▽  ▽          │                   │
│             │    ▽  ▽  🌱  ▽  ▽  ▽  ▽        │  ← Planted Crop  │
│             │   ▽  ▽  ▽  ▽  ▽  ▽  ▽          │                   │
│             │    ▽  ▽  ▽  ▽  ▽  ▽  ▽         │                   │
│             │   ▽  ▽  ▽  ▽  👻  ▽  ▽         │  ← Ghost Preview │
│             │    ▽  ▽  ▽  ▽  ▽  ▽  ▽         │                   │
│             │                                  │                   │
│             └──────────────────────────────────┘                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Visual States

### 1. Crop Growth Stages

```
PLANTED (0s)          GROWING (15s)        HARVESTABLE (30s)
┌─────┐               ┌─────┐              ┌─────┐
│ 🟫  │ Small         │ 🟨  │ Medium       │ 🟨✨ │ Full + Pulse
│     │ Darkened      │     │ Growing      │     │ Ready!
└─────┘ 50% scale     └─────┘ 75% scale    └─────┘ 100% scale
```

### 2. Ghost Preview Colors

```
VALID PLACEMENT       INVALID PLACEMENT    NOT IN MODE
┌─────┐               ┌─────┐              ┌─────┐
│ 🟩  │ Green         │ 🟥  │ Red          │     │ No ghost
│     │ Semi-trans    │     │ Semi-trans   │     │
└─────┘               └─────┘              └─────┘
```

### 3. Crop Types (Placeholder Colors)

```
WHEAT                 CORN                 ALIEN FRUIT
┌─────┐               ┌─────┐              ┌─────┐
│ 🟨  │ Goldenrod     │ 🟨  │ Yellow       │ 🟪  │ Purple
└─────┘               └─────┘              └─────┘
Cost: 10              Cost: 25             Cost: 50
Time: 30s             Time: 60s            Time: 90s
Value: 25             Value: 80            Value: 200
ROI: 150%             ROI: 220%            ROI: 300%
```

### 4. Day/Night Cycle

```
DAY PHASE                           NIGHT PHASE
┌──────────────────────────┐       ┌──────────────────────────┐
│ ☀️  Warm Yellow Tint     │       │ 🌙  Cool Blue Tint       │
│                          │       │                          │
│ Crops GROW ✅            │       │ Crops PAUSED ❌          │
│ Can plant crops ✅       │       │ Can still harvest ✅      │
│ Duration: 60 seconds     │       │ Duration: 45 seconds     │
└──────────────────────────┘       └──────────────────────────┘
```

## Interaction Flow Diagram

```
┌──────────────┐
│ Press 1/2/3  │ Select crop type
└──────┬───────┘
       │
       v
┌────────────────────────┐
│ PLACEMENT MODE ACTIVE  │
│ Ghost preview visible  │
└──────┬─────────────────┘
       │
       v
┌──────────────┐     YES     ┌──────────────────┐
│ Hover tile?  │────────────>│ Ghost turns:     │
└──────┬───────┘             │ - Green (valid)  │
       │                     │ - Red (invalid)  │
       │                     └──────────────────┘
       v
┌──────────────┐     YES     ┌──────────────────┐
│ Click tile?  │────────────>│ Validate:        │
└──────┬───────┘             │ - Tile exists?   │
       │                     │ - Not occupied?  │
       │                     │ - Has credits?   │
       │                     └──────┬───────────┘
       │                            │
       │                            v
       │                     ┌──────────────────┐
       │                YES  │ Deduct credits   │
       │            ┌────────│ Spawn crop       │
       │            │        │ Start growing    │
       │            │        └──────────────────┘
       │            │
       │            v
       │     ┌──────────────┐
       │     │ GROWING      │ Only during DAY
       │     │ Scale: 0.5→1 │
       │     └──────┬───────┘
       │            │
       │            v
       │     ┌──────────────┐
       │     │ HARVESTABLE  │
       │     │ Pulsing ✨   │
       │     └──────┬───────┘
       │            │
       │            v
       │     ┌──────────────┐
       └────>│ Click crop   │
             │ Harvest!     │
             │ +Credits     │
             │ Particles 🎆 │
             └──────────────┘
```

## Testing Checklist Visualization

```
STEP 1: BASIC PLANTING
├─ [✓] Press 1 → Ghost appears
├─ [✓] Hover tile → Ghost turns green
├─ [✓] Click → Crop planted
├─ [✓] Credits: 100 → 90
└─ [✓] Crop appears on tile

STEP 2: GROWTH
├─ [✓] Crop scale increases over time
├─ [✓] Growth only during DAY
├─ [✓] After 30s → Pulsing animation
└─ [✓] Console: "state changed to HARVESTABLE"

STEP 3: HARVEST
├─ [✓] Click harvestable crop
├─ [✓] Particle burst effect
├─ [✓] Credits: 90 → 115
└─ [✓] Crop disappears

STEP 4: VALIDATION
├─ [✓] Try to plant on same tile → Red ghost
├─ [✓] Try to plant with 0 credits → Red flash
├─ [✓] Press N → Night → Growth pauses
└─ [✓] Press D → Day → Growth resumes
```

## Color Coding Reference

```
UI ELEMENTS:
🟨 Yellow     - Day phase
🔵 Cyan       - Night phase
🟢 Green      - Valid action
🔴 Red        - Invalid action
🟡 Gold       - Credits display
⚪ White      - General text

CROPS:
🟨 Goldenrod  - Wheat (cheap, fast)
🟨 Yellow     - Corn (medium)
🟪 Purple     - Alien Fruit (expensive, slow)

FEEDBACK:
✅ Green      - Success
❌ Red        - Failure
✨ Sparkle    - Ready to harvest
🎆 Burst      - Harvest effect
```

## Keyboard Layout

```
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬─────────┐
│Esc│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ - │ = │ Backsp  │
│ X │Wht│Crn│Ali│   │   │   │   │   │   │   │   │   │         │
├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬───────┤
│ Tab │   │   │   │ R │   │   │   │   │   │   │   │   │       │
│     │   │   │   │Rst│   │   │   │   │   │   │   │   │       │
├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴───────┤
│ Caps │   │   │ C │ D │ F │   │   │   │   │   │   │  Enter   │
│      │   │   │+💰│Day│FF │   │   │   │   │   │   │          │
├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴──────────┤
│ Shift  │   │   │   │   │   │ N │   │   │   │   │   Shift    │
│        │   │   │   │   │   │Ngt│   │   │   │   │            │
└────────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴────────────┘
         [↑] Pan Up
    [←]      [→] Pan Left/Right
         [↓] Pan Down

Wht = Wheat    Crn = Corn    Ali = Alien Fruit
X   = Exit     +💰 = Credits  Rst = Reset
Day = Force Day  Ngt = Force Night  FF = Fast-Forward
```

## Expected Console Output Flow

```
[Starting Demo]
───────────────
[CropSystemDemo] Initializing demo...
CropDatabase: Initialized with 3 crops
PlantingSystem: Initialized
EconomyManager: Initialized with 100 starting credits
[TimeManager] Day 1 started (60 seconds)
[CropSystemDemo] Demo ready! Press 1/2/3 to start planting.

[Player presses 1]
──────────────────
PlantingSystem: Entered placement mode for Wheat

[Player clicks tile]
────────────────────
PlantingSystem: Planted Wheat at hex (7, 5) for 10 credits
EconomyManager: -10 credits (remaining: 90)
BaseCrop: Planted Wheat at hex (7, 5) (grow time: 30.0s)
BaseCrop: Wheat state changed to GROWING

[30 seconds later]
──────────────────
BaseCrop: Wheat state changed to HARVESTABLE

[Player clicks crop]
────────────────────
BaseCrop: Harvested Wheat at hex (7, 5) for 25 credits!
PlantingSystem: Crop harvested at hex (7, 5), earned 25 credits
EconomyManager: +25 credits (total: 115)
```

---

**TIP:** Keep this guide open while testing to verify all visual states appear correctly!
