extends Node
## Manages player economy: credits, spending, and earning
## Autoload singleton for global access

#region Signals
## Emitted whenever credits change
signal credits_changed(new_amount: int)

## Emitted when player tries to spend but can't afford
signal insufficient_credits(attempted_cost: int, current_credits: int)

## Emitted when upgrade is successfully purchased
signal upgrade_purchased(upgrade_id: String, cost: int)

#endregion

#region Variables
## Current player credits
var credits: int = GameConfig.STARTING_CREDITS:
	set(value):
		credits = value
		self.credits_changed.emit(credits)

#endregion

#region Initialization
func _ready() -> void:
	print("EconomyManager: Initialized with %d starting credits" % credits)

#endregion

#region Public API
## Add credits to player's balance
func add_credits(amount: int) -> void:
	if amount <= 0:
		push_warning("EconomyManager: Attempted to add non-positive amount: %d" % amount)
		return

	self.credits += amount
	print("EconomyManager: +%d credits (total: %d)" % [amount, self.credits])

## Attempt to spend credits (returns true if successful)
func spend_credits(amount: int) -> bool:
	if amount <= 0:
		push_warning("EconomyManager: Attempted to spend non-positive amount: %d" % amount)
		return false

	if self.credits < amount:
		self.insufficient_credits.emit(amount, self.credits)
		print("EconomyManager: Cannot afford %d credits (have: %d)" % [amount, self.credits])
		return false

	self.credits -= amount
	print("EconomyManager: -%d credits (remaining: %d)" % [amount, self.credits])
	return true

## Check if player can afford a cost
func can_afford(amount: int) -> bool:
	return self.credits >= amount

## Get current credit balance
func get_credits() -> int:
	return self.credits

## Set credits to specific value (for debugging/cheats)
func set_credits(amount: int) -> void:
	self.credits = max(0, amount)

## Reset to starting credits (for new game)
func reset() -> void:
	self.credits = GameConfig.STARTING_CREDITS
	print("EconomyManager: Reset to %d credits" % self.credits)

#endregion

#region Upgrade System
## Attempt to purchase an upgrade (returns true if successful)
func purchase_upgrade(upgrade_id: String) -> bool:
	if not UpgradeConfig:
		push_error("EconomyManager: UpgradeConfig not loaded")
		return false

	# Determine cost based on upgrade ID
	var cost: int = 0
	match upgrade_id:
		"repair_mech":
			cost = UpgradeConfig.UPGRADE_REPAIR_COST
		"weapon_damage":
			cost = UpgradeConfig.UPGRADE_WEAPON_DAMAGE_COST
		"max_hp":
			cost = UpgradeConfig.UPGRADE_MAX_HP_COST
		_:
			push_error("EconomyManager: Unknown upgrade ID: %s" % upgrade_id)
			return false

	# Attempt to spend credits
	if not self.spend_credits(cost):
		return false

	# Upgrade purchased successfully
	self.upgrade_purchased.emit(upgrade_id, cost)
	print("EconomyManager: Upgrade purchased: %s (cost: %d)" % [upgrade_id, cost])
	return true


## Get cost of specific upgrade
func get_upgrade_cost(upgrade_id: String) -> int:
	match upgrade_id:
		"repair_mech":
			return UpgradeConfig.UPGRADE_REPAIR_COST
		"weapon_damage":
			return UpgradeConfig.UPGRADE_WEAPON_DAMAGE_COST
		"max_hp":
			return UpgradeConfig.UPGRADE_MAX_HP_COST
		_:
			push_error("EconomyManager: Unknown upgrade ID: %s" % upgrade_id)
			return 0


## Check if player can afford specific upgrade
func can_afford_upgrade(upgrade_id: String) -> bool:
	var cost = self.get_upgrade_cost(upgrade_id)
	return self.can_afford(cost)

#endregion
