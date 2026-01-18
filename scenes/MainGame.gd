extends Node2D
## Main game scene - integrates all core systems
## This is the primary scene you run to play the game

@onready var hex_grid: Node2D = $HexGrid
@onready var mech: MechController = $Mech
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var upgrade_shop: UpgradeShop = $UpgradeShop
@onready var pause_menu: Control = $PauseMenu
@onready var defeat_screen: Control = $DefeatScreen
@onready var victory_screen: Control = $VictoryScreen
@onready var planting_system: PlantingSystem = $PlantingSystem


func _ready() -> void:
	print("[MainGame] Initializing...")

	# Setup PlantingSystem dependencies
	_setup_planting_system()

	# Center mech on the grid
	_position_mech_at_center()

	# Connect mech health to HUD
	if mech and hud:
		mech.health_changed.connect(_on_mech_health_changed)
		mech.died.connect(_on_mech_died)

	# Connect PlantingSystem signals
	if planting_system:
		planting_system.crop_planted.connect(_on_crop_planted)
		planting_system.placement_mode_changed.connect(_on_placement_mode_changed)

	# Initialize camera at mech position (HexGrid will handle following)
	if camera and mech:
		camera.position = mech.global_position

	print("[MainGame] Ready! Day/Night cycle starting...")


func _process(_delta: float) -> void:
	# Camera following is now handled by HexGrid
	pass


func _setup_planting_system() -> void:
	"""Initialize and validate PlantingSystem dependencies"""
	if not planting_system:
		push_error("[MainGame] PlantingSystem not found in scene!")
		return

	# Setup hex_grid reference if not already set
	if not planting_system.hex_grid:
		planting_system.hex_grid = hex_grid
		print("[MainGame] Assigned hex_grid to PlantingSystem")

	# Setup crop_scene reference if not already set
	if not planting_system.crop_scene:
		planting_system.crop_scene = load("res://scenes/entities/crops/BaseCrop.tscn")
		if not planting_system.crop_scene:
			push_error("[MainGame] Could not load BaseCrop.tscn!")
			return
		print("[MainGame] Loaded BaseCrop.tscn for PlantingSystem")



func _position_mech_at_center() -> void:
	"""Position mech at the center of the hex grid"""
	if not hex_grid or not mech:
		return

	# Get the center tile of the grid
	var grid_center := Vector2i(GameConfig.GRID_SIZE.x / 2, GameConfig.GRID_SIZE.y / 2)

	# Convert to world position if hex_grid has the conversion function
	if hex_grid.has_method("hex_to_world"):
		var world_pos: Vector2 = hex_grid.hex_to_world(grid_center)
		mech.global_position = world_pos
		print("[MainGame] Mech positioned at grid center: ", grid_center, " -> ", world_pos)
	else:
		# Fallback: just center in viewport
		mech.global_position = Vector2.ZERO
		print("[MainGame] Hex conversion not available, mech at origin")


func _on_mech_health_changed(current_hp: float, max_hp: float) -> void:
	"""Forward health updates to HUD"""
	if hud and hud.has_method("update_mech_health"):
		hud.update_mech_health(current_hp, max_hp)


func _on_mech_died() -> void:
	"""Handle mech death - GameStateManager will show defeat screen"""
	print("[MainGame] Mech destroyed! Game Over")


func _on_crop_planted(hex_coords: Vector2i, crop_type: CropDatabase.CropType) -> void:
	"""Handle crop planted event from PlantingSystem"""
	if hud and hud.has_method("on_crop_planted"):
		hud.on_crop_planted(crop_type)
	print("[MainGame] Crop planted at %v: %s" % [hex_coords, CropDatabase.get_crop_name(crop_type)])


func _on_placement_mode_changed(active: bool, crop_type: CropDatabase.CropType) -> void:
	"""Handle placement mode changes from PlantingSystem"""
	if active:
		var crop_data := CropDatabase.get_crop(crop_type)
		if crop_data:
			print("[MainGame] Placement mode ACTIVE - %s (Cost: %d)" % [crop_data.name, crop_data.cost])
	else:
		print("[MainGame] Placement mode INACTIVE")


## Input handling - Tab for shop, debug keys
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Tab to toggle upgrade shop (only when game is playing)
		if event.keycode == KEY_TAB and not event.echo:
			if GameStateManager and GameStateManager.current_state == GameStateManager.State.PLAYING:
				if upgrade_shop:
					upgrade_shop.toggle_shop()
					get_viewport().set_input_as_handled()
