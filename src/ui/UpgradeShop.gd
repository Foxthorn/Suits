extends Control
## Upgrade shop UI - centered overlay panel for purchasing upgrades
## Opened/closed via TAB key
## Shows upgrade buttons with real-time affordability feedback

class_name UpgradeShop

#region Signals
signal upgrade_selected(upgrade_id: String)
signal shop_closed

#endregion

#region References
@onready var credits_label: Label = $PanelContainer/VBoxContainer/CreditsLabel
@onready var upgrades_vbox: VBoxContainer = $PanelContainer/VBoxContainer/UpgradesVBox
@onready var panel: PanelContainer = $PanelContainer

#endregion

#region Variables
var upgrade_buttons: Dictionary = {}  # upgrade_id -> Button node
var current_credits: int = 0

#endregion

#region Lifecycle
func _ready() -> void:
	# Initially hidden
	hide()

	# Connect to economy signals
	if EconomyManager:
		EconomyManager.credits_changed.connect(_on_credits_changed)
		current_credits = EconomyManager.get_credits()

	if ProgressManager:
		ProgressManager.upgrade_purchased.connect(_on_upgrade_purchased)

	# Create upgrade buttons
	_create_upgrade_buttons()

	# Update initial state
	_update_all_buttons()

	print("[UpgradeShop] Initialized with %d upgrades" % upgrade_buttons.size())


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# TAB to close
	if event.is_action_pressed("ui_focus_next"):  # TAB is default for ui_focus_next
		get_tree().root.set_input_as_handled()
		hide_shop()

#endregion

#region Shop Management
## Show the shop
func show_shop() -> void:
	# Pause the game silently when opening shop
	GameStateManager.pause_game(false)

	show()
	_update_all_buttons()
	print("[UpgradeShop] Shop opened")


## Hide the shop
func hide_shop() -> void:
	# Resume the game when closing shop
	GameStateManager.resume_game()

	hide()
	shop_closed.emit()
	print("[UpgradeShop] Shop closed")


## Toggle shop visibility
func toggle_shop() -> void:
	if visible:
		hide_shop()
	else:
		show_shop()

#endregion

#region Upgrade Button Creation
## Create buttons for all available upgrades
func _create_upgrade_buttons() -> void:
	if not ProgressManager:
		push_error("[UpgradeShop] ProgressManager not available")
		return

	# Get all upgrade IDs
	var upgrade_ids = ProgressManager.get_all_upgrades()

	for upgrade_id in upgrade_ids:
		var upgrade_data = ProgressManager.get_upgrade(upgrade_id)
		if upgrade_data.is_empty():
			continue

		# Create button
		var button = Button.new()
		button.text = "%s - %d credits" % [upgrade_data.name, EconomyManager.get_upgrade_cost(upgrade_id)]
		button.custom_minimum_size = Vector2(280, 40)
		button.pressed.connect(_on_upgrade_button_pressed.bindv([upgrade_id]))

		# Store reference
		upgrade_buttons[upgrade_id] = button
		upgrades_vbox.add_child(button)


## Update button states based on affordability and purchase status
func _update_all_buttons() -> void:
	for upgrade_id in upgrade_buttons.keys():
		_update_button_state(upgrade_id)


## Update single button state
func _update_button_state(upgrade_id: String) -> void:
	var button = upgrade_buttons.get(upgrade_id)
	if not button:
		return

	var can_purchase = ProgressManager.can_purchase(upgrade_id)
	var can_afford = EconomyManager.can_afford_upgrade(upgrade_id)

	# Already purchased: gray out and disable
	if not can_purchase:
		button.disabled = true
		button.self_modulate = Color(0.5, 0.5, 0.5, 0.7)
		return

	# Can afford: green
	if can_afford:
		button.disabled = false
		button.self_modulate = Color.WHITE
	# Cannot afford: red
	else:
		button.disabled = true
		button.self_modulate = Color(1.0, 0.5, 0.5, 0.7)


## Update credits display
func _update_credits_display() -> void:
	credits_label.text = "Credits: %d" % current_credits

#endregion

#region Signal Handlers
## Handle upgrade button press
func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	print("[UpgradeShop] Button pressed: %s" % upgrade_id)

	# Attempt purchase via ProgressManager + EconomyManager
	if not ProgressManager.has_purchased(upgrade_id):
		if EconomyManager.purchase_upgrade(upgrade_id):
			# Purchase successful
			ProgressManager.purchase_upgrade(upgrade_id)
			upgrade_selected.emit(upgrade_id)
			_apply_upgrade(upgrade_id)
			_update_all_buttons()
			print("[UpgradeShop] Upgrade purchased: %s" % upgrade_id)
		else:
			# Insufficient credits
			print("[UpgradeShop] Cannot afford upgrade: %s" % upgrade_id)


## Handle credits changed
func _on_credits_changed(new_amount: int) -> void:
	current_credits = new_amount
	_update_credits_display()
	_update_all_buttons()


## Handle upgrade purchased by ProgressManager
func _on_upgrade_purchased(upgrade_id: String, upgrade_name: String) -> void:
	_update_button_state(upgrade_id)
	print("[UpgradeShop] Upgrade marked purchased: %s" % upgrade_name)

#endregion

#region Upgrade Application
## Apply upgrade effects to game systems
func _apply_upgrade(upgrade_id: String) -> void:
	var mech = get_tree().get_first_node_in_group("player_mech")
	if not mech:
		push_warning("[UpgradeShop] Mech not found, cannot apply upgrade")
		return

	match upgrade_id:
		"repair_mech":
			mech.heal(UpgradeConfig.UPGRADE_REPAIR_AMOUNT)
			print("[UpgradeShop] Applied upgrade: Mech healed for %.0f HP" % UpgradeConfig.UPGRADE_REPAIR_AMOUNT)

		"weapon_damage":
			mech.set_weapon_damage_multiplier(1.0 + UpgradeConfig.UPGRADE_WEAPON_DAMAGE_BONUS)
			print("[UpgradeShop] Applied upgrade: Weapon damage +%.0f%%" % (UpgradeConfig.UPGRADE_WEAPON_DAMAGE_BONUS * 100))

		"max_hp":
			mech.upgrade_max_health(UpgradeConfig.UPGRADE_MAX_HP_BONUS)
			print("[UpgradeShop] Applied upgrade: Max HP +%.0f" % UpgradeConfig.UPGRADE_MAX_HP_BONUS)

		_:
			push_error("[UpgradeShop] Unknown upgrade ID: %s" % upgrade_id)

#endregion
