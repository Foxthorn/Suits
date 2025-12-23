class_name CropConfig
extends Node
## Centralized crop configuration - NO MAGIC NUMBERS!
## Similar to GameConfig, all crop values are defined as constants

#region Asset Paths
const ASSET_BASE_PATH: String = "res://assets/Fruit and Veg/Fruit and Veg/"

#endregion

#region Visual Settings - Apply to ALL crops
const PLANTED_SCALE: float = 0.4  # Scale when just planted
const HARVESTABLE_SCALE: float = 1.2  # Scale when ready to harvest
const PLANTED_OPACITY: float = 0.6  # Opacity when just planted
const GROWING_OPACITY: float = 0.85  # Opacity while growing
const HARVESTABLE_OPACITY: float = 1.0  # Opacity when ready to harvest
const PREVIEW_SCALE: float = 0.8  # Scale for ghost preview
const HOVER_INDICATOR_SIZE: int = 48  # Size of hover circle indicator

#endregion

#region Harvest Effects - Apply to ALL crops
const HARVEST_PARTICLE_COUNT: int = 16  # Number of particles on harvest
const HARVEST_PARTICLE_LIFETIME: float = 0.5  # Particle lifetime
const PULSE_SPEED: float = 0.5  # Speed of "ready to harvest" pulse animation

#endregion

#region Wheat Configuration
const WHEAT_NAME: String = "Wheat"
const WHEAT_DESCRIPTION: String = "Fast-growing, low profit. Good for early game."
const WHEAT_GROW_TIME: float = 30.0  # 30 seconds
const WHEAT_COST: int = 10  # 10 credits to plant
const WHEAT_VALUE: int = 25  # 25 credits on harvest (+15 profit)
const WHEAT_SPRITE: String = "Wheat.png"
const WHEAT_COLOR: Color = Color.GOLDENROD

#endregion

#region Corn Configuration
const CORN_NAME: String = "Corn"
const CORN_DESCRIPTION: String = "Medium growth, medium profit. Balanced choice."
const CORN_GROW_TIME: float = 60.0  # 1 minute
const CORN_COST: int = 25  # 25 credits to plant
const CORN_VALUE: int = 80  # 80 credits on harvest (+55 profit)
const CORN_SPRITE: String = "Corn.png"
const CORN_COLOR: Color = Color.YELLOW

#endregion

#region Alien Fruit Configuration
const ALIEN_FRUIT_NAME: String = "Alien Fruit"
const ALIEN_FRUIT_DESCRIPTION: String = "Slow-growing, high profit. Risky investment."
const ALIEN_FRUIT_GROW_TIME: float = 90.0  # 1.5 minutes
const ALIEN_FRUIT_COST: int = 50  # 50 credits to plant
const ALIEN_FRUIT_VALUE: int = 200  # 200 credits on harvest (+150 profit)
const ALIEN_FRUIT_SPRITE: String = "Grapes.png"  # Using Grapes as "alien fruit"
const ALIEN_FRUIT_COLOR: Color = Color.PURPLE

#endregion

# TODO: Add more crops here:
# - CARROT
# - TOMATO
# - PUMPKIN
# - STRAWBERRY
# - etc.
