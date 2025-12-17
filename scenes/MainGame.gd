extends Node2D
## Main game scene - integrates all core systems
## This is the primary scene you run to play the game

@onready var hex_grid: Node2D = $HexGrid
@onready var mech: MechController = $Mech
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	print("[MainGame] Initializing...")

	# Center mech on the grid
	_position_mech_at_center()

	# Connect mech health to HUD
	if mech and hud:
		mech.health_changed.connect(_on_mech_health_changed)
		mech.died.connect(_on_mech_died)

	# Connect camera to follow mech
	if camera and mech:
		camera.position = mech.global_position

	print("[MainGame] Ready! Day/Night cycle starting...")


func _process(_delta: float) -> void:
	# Smooth camera follow
	if camera and mech:
		camera.global_position = camera.global_position.lerp(mech.global_position, 0.1)


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
	"""Handle mech death"""
	print("[MainGame] Mech destroyed! Game Over")
	# TODO: Step 9 - Show defeat screen
	get_tree().paused = true


## Debug: Press R to reset mech health
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and not event.echo:
			if mech:
				mech.set_health(mech.max_health)
				print("[MainGame] DEBUG: Mech health restored")

		# Debug: Press T to test damage
		if event.keycode == KEY_T and not event.echo:
			if mech:
				mech.take_damage(20.0)
				print("[MainGame] DEBUG: Mech took 20 damage")
