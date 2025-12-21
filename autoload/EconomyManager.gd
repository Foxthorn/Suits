extends Node
## Manages player economy: credits, spending, and earning
## Autoload singleton for global access

#region Signals
## Emitted whenever credits change
signal credits_changed(new_amount: int)

## Emitted when player tries to spend but can't afford
signal insufficient_credits(attempted_cost: int, current_credits: int)

#endregion

#region Variables
## Current player credits
var credits: int = GameConfig.STARTING_CREDITS:
	set(value):
		credits = value
		credits_changed.emit(credits)

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

	credits += amount
	print("EconomyManager: +%d credits (total: %d)" % [amount, credits])

## Attempt to spend credits (returns true if successful)
func spend_credits(amount: int) -> bool:
	if amount <= 0:
		push_warning("EconomyManager: Attempted to spend non-positive amount: %d" % amount)
		return false

	if credits < amount:
		insufficient_credits.emit(amount, credits)
		print("EconomyManager: Cannot afford %d credits (have: %d)" % [amount, credits])
		return false

	credits -= amount
	print("EconomyManager: -%d credits (remaining: %d)" % [amount, credits])
	return true

## Check if player can afford a cost
func can_afford(amount: int) -> bool:
	return credits >= amount

## Get current credit balance
func get_credits() -> int:
	return credits

## Set credits to specific value (for debugging/cheats)
func set_credits(amount: int) -> void:
	credits = max(0, amount)

## Reset to starting credits (for new game)
func reset() -> void:
	credits = GameConfig.STARTING_CREDITS
	print("EconomyManager: Reset to %d credits" % credits)

#endregion
