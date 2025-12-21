extends Node2D
## Demo scene for testing the complete crop planting system
## Tests: HexGrid, PlantingSystem, BaseCrop, EconomyManager, TimeManager integration

#region Nodes
@onready var hex_grid: HexGrid = $HexGrid
@onready var planting_system: PlantingSystem = $PlantingSystem
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var instructions_label: RichTextLabel = $HUD/InstructionsPanel/VBoxContainer/InstructionsLabel
@onready var status_label: RichTextLabel = $HUD/StatusPanel/VBoxContainer/StatusLabel
@onready var credits_label: Label = $HUD/StatusPanel/VBoxContainer/CreditsLabel
@onready var time_label: Label = $HUD/StatusPanel/VBoxContainer/TimeLabel
@onready var crops_label: Label = $HUD/StatusPanel/VBoxContainer/CropsLabel

#endregion

#region Variables
var _crop_count: int = 0
var _total_harvested: int = 0
var _total_earned: int = 0

#endregion

func _ready() -> void:
	print("[CropSystemDemo] Initializing demo...")

	# Set camera to center of grid (hex grid origin is at 0,0)
	# With flat-top hexagons, approximate center
	var grid_center := Vector2(600, 500)  # Approximate center for a small hex grid
	camera.position = grid_center

	# Position mech at same location
	if is_instance_valid($Mech):
		$Mech.position = grid_center

	# Set camera zoom for better view
	camera.zoom = Vector2(1.0, 1.0)

	# Connect signals
	_connect_signals()

	# Force camera to initial mech position
	if hex_grid and is_instance_valid($Mech):
		hex_grid.resume_following()

	# Initialize UI
	_update_instructions()
	_update_status()

	print("[CropSystemDemo] Demo ready! Press 1/2/3 to start planting.")

func _connect_signals() -> void:
	# EconomyManager
	EconomyManager.credits_changed.connect(_on_credits_changed)

	# TimeManager
	TimeManager.phase_changed.connect(_on_phase_changed)
	TimeManager.phase_time_remaining.connect(_on_time_remaining)

	# PlantingSystem
	planting_system.crop_planted.connect(_on_crop_planted)
	planting_system.placement_mode_changed.connect(_on_placement_mode_changed)

func _update_instructions() -> void:
	var mode_text := ""
	if planting_system.is_in_placement_mode():
		var crop_type := planting_system.get_selected_crop_type()
		var crop_data := CropDatabase.get_crop(crop_type)
		mode_text = "[COLOR=yellow]PLANTING MODE: %s[/COLOR]\n" % crop_data.name
		mode_text += "Cost: %d | Value: %d | Grow Time: %.0fs\n\n" % [crop_data.cost, crop_data.value, crop_data.grow_time]

	instructions_label.text = mode_text + """[b]CONTROLS:[/b]
[1] Plant Wheat (10 credits, 30s, +25)
[2] Plant Corn (25 credits, 60s, +80)
[3] Plant Alien Fruit (50 credits, 90s, +200)
[ESC] Exit placement mode
[CLICK] Plant crop / Harvest crop

[b]CAMERA:[/b]
[Mouse Wheel] Zoom in/out
[Arrow Keys] Pan camera

[b]DEBUG CHEATS:[/b]
[C] +100 Credits
[F] Fast-forward time (skip 10s)
[N] Force night phase
[D] Force day phase
[R] Reset demo

[b]TIP:[/b] Crops only grow during DAY!"""

func _update_status() -> void:
	var phase_text := "DAY %d" % TimeManager.current_day if TimeManager.is_day() else "NIGHT %d" % TimeManager.current_night
	var phase_color := Color.YELLOW if TimeManager.is_day() else Color.CYAN

	status_label.text = "[COLOR=#%s]%s[/COLOR]" % [phase_color.to_html(false), phase_text]
	credits_label.text = "Credits: %d" % EconomyManager.get_credits()
	crops_label.text = "Planted: %d | Harvested: %d | Total Earned: %d" % [_crop_count, _total_harvested, _total_earned]

func _on_credits_changed(new_amount: int) -> void:
	_update_status()

func _on_phase_changed(new_phase) -> void:
	_update_status()

func _on_time_remaining(seconds_left: float) -> void:
	time_label.text = "Time: %s" % TimeManager.format_time(seconds_left)

func _on_crop_planted(hex_coords: Vector2i, crop_type: CropDatabase.CropType) -> void:
	_crop_count += 1
	_update_status()

	# Connect to individual crop's harvest signal
	var crop := planting_system.get_crop_at(hex_coords)
	if crop:
		crop.harvested.connect(_on_crop_harvested)

func _on_crop_harvested(crop_type: CropDatabase.CropType, value: int, hex_coords: Vector2i) -> void:
	_crop_count -= 1
	_total_harvested += 1
	_total_earned += value
	_update_status()

func _on_placement_mode_changed(active: bool, crop_type: CropDatabase.CropType) -> void:
	_update_instructions()

#endregion

#region Debug Cheats
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				EconomyManager.add_credits(100)
				print("[CropSystemDemo] CHEAT: +100 credits")

			KEY_F:
				# Fast-forward 10 seconds
				if TimeManager.is_day():
					TimeManager.time_remaining = max(0, TimeManager.time_remaining - 10)
				else:
					TimeManager.time_remaining = max(0, TimeManager.time_remaining - 10)
				print("[CropSystemDemo] CHEAT: Fast-forwarded 10 seconds")

			KEY_N:
				if TimeManager.is_day():
					TimeManager.start_night()
					print("[CropSystemDemo] CHEAT: Forced night phase")

			KEY_D:
				if TimeManager.is_night():
					TimeManager.start_day()
					print("[CropSystemDemo] CHEAT: Forced day phase")

			KEY_R:
				print("[CropSystemDemo] CHEAT: Resetting demo...")
				get_tree().reload_current_scene()

#endregion
