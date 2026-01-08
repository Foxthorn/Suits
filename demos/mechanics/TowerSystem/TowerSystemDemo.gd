extends Node2D
## Tower System Demo - Test tower placement, range detection, and auto-targeting
##
## Features:
## - Place towers with ghost preview
## - Visual range indicators
## - Auto-targeting and firing at enemies
## - Wave spawning during night phase
## - Economy integration

#region Private Variables
var tower_system: TowerSystem

var total_towers_placed: int = 0
var total_enemies_killed: int = 0

#endregion

#region Lifecycle
func _ready() -> void:
	# Get references to key systems
	tower_system = $TowerSystem

	if not tower_system:
		push_error("TowerSystemDemo: TowerSystem not found!")
		return

	if not TimeManager or not EconomyManager:
		push_error("TowerSystemDemo: Required autoloads not found (TimeManager, EconomyManager)")
		return

	_connect_signals()
	_setup_ui()

	print("TowerSystemDemo: Ready - Press 'T' to enter tower placement mode, 'N' to toggle night/day")

func _connect_signals() -> void:
	"""Connect to system signals"""
	if tower_system:
		tower_system.tower_placed.connect(_on_tower_placed)
		tower_system.placement_mode_changed.connect(_on_placement_mode_changed)

	if TimeManager:
		TimeManager.phase_changed.connect(_on_phase_changed)

	if EconomyManager:
		EconomyManager.credits_changed.connect(_on_credits_changed)

func _setup_ui() -> void:
	"""Setup UI labels"""
	var instructions_label = $HUD/InstructionsPanel/VBoxContainer/InstructionsLabel
	if instructions_label:
		instructions_label.text = """
[b]🏰 TOWER SYSTEM DEMO 🏰[/b]

[color=ffff99]Controls:[/color]
• [b]T[/b] - Enter tower placement mode
• [b]Left Click[/b] - Place tower
• [b]Right Click / ESC[/b] - Cancel placement
• [b]N[/b] - Toggle Night/Day phase

[color=ffff99]Features:[/color]
• Ghost preview (Green=Valid, Red=Invalid)
• Range indicator circles
• Auto-targeting nearest enemy
• Rapid-fire bullets (5 shots/sec)
• Auto-clear wave on all enemies dead

[color=ffff99]Tower Stats:[/color]
• Cost: 50 credits
• Range: 250px
• Damage: 8 per shot
• Fire Rate: 0.2s (5 shots/sec)
"""

	_update_status_ui()

func _update_status_ui() -> void:
	"""Update status display"""
	# Guard against null references
	if not TimeManager or not EconomyManager or not tower_system:
		return

	var status_label = $HUD/StatusPanel/VBoxContainer/StatusLabel
	var phase_label = $HUD/StatusPanel/VBoxContainer/PhaseLabel
	var credits_label = $HUD/StatusPanel/VBoxContainer/CreditsLabel
	var towers_label = $HUD/StatusPanel/VBoxContainer/TowersLabel
	var enemies_label = $HUD/StatusPanel/VBoxContainer/EnemiesLabel

	if status_label:
		var phase_text = "DAY" if TimeManager.is_day() else "NIGHT"
		status_label.text = "[b]%s[/b]" % phase_text

	if phase_label:
		phase_label.text = "Phase: %s" % ("DAY" if TimeManager.is_day() else "NIGHT")

	if credits_label:
		credits_label.text = "[color=ffff99]Credits: %d[/color]" % EconomyManager.credits

	if towers_label:
		towers_label.text = "Towers: %d" % tower_system.get_tower_count()

	if enemies_label:
		var enemy_count = len(get_all_enemies())
		enemies_label.text = "Enemies: %d" % enemy_count

#endregion

#region Signals
func _on_tower_placed(hex_coords: Vector2i, tower_type: TowerDatabase.TowerType) -> void:
	"""Handle tower placement"""
	total_towers_placed += 1
	_update_status_ui()

	print("Demo: Tower #%d placed at %v" % [total_towers_placed, hex_coords])

	# Automatically exit placement mode
	tower_system.exit_placement_mode()

func _on_placement_mode_changed(active: bool, tower_type: TowerDatabase.TowerType) -> void:
	"""Handle placement mode change"""
	var status_text = "Placement Mode: %s" % TowerDatabase.get_tower_name(tower_type) if active else "Normal Mode"
	print("Demo: %s" % status_text)

func _on_phase_changed() -> void:
	"""Handle day/night phase change"""
	_update_status_ui()

	if not TimeManager.is_day():
		# Night started - show wave info
		var wave_num = WaveManager.current_wave
		print("Demo: NIGHT %d - Wave started!" % wave_num)

func _on_credits_changed(new_amount: int) -> void:
	"""Handle economy changes"""
	_update_status_ui()

#endregion

#region Input Handling
func _input(event: InputEvent) -> void:
	"""Handle keyboard input for tower placement"""
	if not tower_system:
		return

	# Press 'T' to enter tower placement mode
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		get_tree().root.set_input_as_handled()
		tower_system.enter_placement_mode(TowerDatabase.TowerType.GATLING_GUN)
		print("Demo: Entering tower placement mode")

	# Press ESC or Right Click to cancel placement
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if tower_system.is_in_placement_mode():
			get_tree().root.set_input_as_handled()
			tower_system.exit_placement_mode()
			print("Demo: Exiting tower placement mode")

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if tower_system.is_in_placement_mode():
			get_tree().root.set_input_as_handled()
			tower_system.exit_placement_mode()
			print("Demo: Exiting tower placement mode (right-click)")

	# Press 'N' to toggle night/day phase
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		if TimeManager:
			TimeManager.advance_phase()

#endregion

#region Frame Updates
func _process(_delta: float) -> void:
	"""Update UI each frame"""
	_update_status_ui()

#endregion

#region Utility
func get_all_enemies() -> Array[BaseEnemy]:
	"""Get all living enemies in scene"""
	var enemies: Array[BaseEnemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is BaseEnemy and is_instance_valid(node):
			enemies.append(node)
	return enemies

#endregion
