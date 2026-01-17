extends Node
## Tracks and manages permanent upgrades during gameplay
## Resets on scene reload (acceptable for vertical slice)
## Future: Extend to persist across saves

## Signal emitted when upgrade is purchased
signal upgrade_purchased(upgrade_id: String, upgrade_name: String)

## Track which upgrades have been purchased (ID -> count/level)
var purchased_upgrades: Dictionary = {}

## Upgrade registry (ID -> effect data)
var upgrade_effects: Dictionary = {}


func _ready() -> void:
	# Initialize upgrade effects from config
	_initialize_upgrades()

	# Reset purchased upgrades on load (vertical slice behavior)
	purchased_upgrades.clear()

	if GameConfig.DEBUG_MODE:
		print("[ProgressManager] Initialized - ready to purchase upgrades")


## Initialize upgrade effect mapping
func _initialize_upgrades() -> void:
	# Repair Mech upgrade
	upgrade_effects["repair_mech"] = {
		"name": "Repair Mech",
		"type": "heal",
		"value": UpgradeConfig.UPGRADE_REPAIR_AMOUNT,
		"description": "Restore 50 HP to mech"
	}

	# Weapon Damage upgrade
	upgrade_effects["weapon_damage"] = {
		"name": "Weapon Damage +1",
		"type": "weapon_damage",
		"value": UpgradeConfig.UPGRADE_WEAPON_DAMAGE_BONUS,
		"description": "+10% weapon damage"
	}

	# Max HP upgrade
	upgrade_effects["max_hp"] = {
		"name": "Max HP +25",
		"type": "max_health",
		"value": UpgradeConfig.UPGRADE_MAX_HP_BONUS,
		"description": "+25 maximum health"
	}


## Check if upgrade has been purchased
func has_purchased(upgrade_id: String) -> bool:
	return purchased_upgrades.has(upgrade_id) and purchased_upgrades[upgrade_id] > 0


## Get upgrade effect data
func get_upgrade(upgrade_id: String) -> Dictionary:
	if upgrade_effects.has(upgrade_id):
		return upgrade_effects[upgrade_id].duplicate()
	push_error("ProgressManager: Unknown upgrade ID: %s" % upgrade_id)
	return {}


## Mark upgrade as purchased (can only purchase once for vertical slice)
func purchase_upgrade(upgrade_id: String) -> bool:
	if not upgrade_effects.has(upgrade_id):
		push_error("ProgressManager: Unknown upgrade ID: %s" % upgrade_id)
		return false

	if has_purchased(upgrade_id):
		push_warning("ProgressManager: Upgrade already purchased: %s" % upgrade_id)
		return false

	purchased_upgrades[upgrade_id] = 1
	var upgrade_data = upgrade_effects[upgrade_id]
	upgrade_purchased.emit(upgrade_id, upgrade_data.name)

	if GameConfig.DEBUG_MODE:
		print("[ProgressManager] Purchased upgrade: %s" % upgrade_data.name)

	return true


## Get list of all available upgrades
func get_all_upgrades() -> Array:
	return upgrade_effects.keys()


## Check if player can still purchase an upgrade (not already owned)
func can_purchase(upgrade_id: String) -> bool:
	return not has_purchased(upgrade_id)
