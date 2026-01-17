## Centralized upgrade configuration - NO MAGIC NUMBERS
## All upgrade costs, effects, and balance values defined here
## Follow pattern: UPGRADE_{EFFECT_TYPE}_{PROPERTY}

extends Node

class_name UpgradeConfig

# ============================================================================
# REPAIR MECH UPGRADE
# ============================================================================
## Cost in credits to purchase repair upgrade
const UPGRADE_REPAIR_COST: int = 50

## HP restored when repair upgrade is purchased
const UPGRADE_REPAIR_AMOUNT: float = 50.0


# ============================================================================
# WEAPON DAMAGE UPGRADE
# ============================================================================
## Cost in credits to purchase weapon damage upgrade
const UPGRADE_WEAPON_DAMAGE_COST: int = 100

## Weapon damage bonus (percentage multiplier, not absolute)
## Applied as: new_damage = base_damage * (1.0 + UPGRADE_WEAPON_DAMAGE_BONUS)
## Example: +0.1 means 10% damage increase
const UPGRADE_WEAPON_DAMAGE_BONUS: float = 0.1  # +10%


# ============================================================================
# MAX HP UPGRADE
# ============================================================================
## Cost in credits to purchase max HP upgrade
const UPGRADE_MAX_HP_COST: int = 150

## Max health increase from upgrade
## Applied as: mech.max_health += UPGRADE_MAX_HP_BONUS
const UPGRADE_MAX_HP_BONUS: float = 25.0


# ============================================================================
# UI/DISPLAY CONFIGURATION
# ============================================================================
## Color for affordable upgrades (can purchase)
const UPGRADE_AFFORDABLE_COLOR: Color = Color.GREEN

## Color for unaffordable upgrades (insufficient credits)
const UPGRADE_UNAFFORDABLE_COLOR: Color = Color.RED

## Color for already-purchased upgrades
const UPGRADE_PURCHASED_COLOR: Color = Color.GRAY

## Button disabled state opacity
const UPGRADE_BUTTON_DISABLED_OPACITY: float = 0.5

## Animation speed for button feedback (scale, color fade)
const UPGRADE_BUTTON_ANIMATION_SPEED: float = 0.2
