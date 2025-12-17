extends Node2D
## Example usage of the HexPlacementPreview tool.
##
## This script demonstrates how to integrate the hex placement preview
## into your game with mouse input and validation logic.

@onready var tile_map: TileMapLayer = $TileMap
@onready var placement_preview: HexPlacementPreview = $HexPlacementPreview

## Track if we're in placement mode
var placement_mode: bool = false

## Track which tiles are occupied
var occupied_tiles: Dictionary = {}  # Vector2i -> bool

func _ready() -> void:
	# Initialize the preview with our tile map
	if placement_preview and tile_map:
		placement_preview.set_tile_map(tile_map)

		# Set up validation function
		placement_preview.set_validation_function(_validate_placement)

		# Connect to signals
		placement_preview.hover_changed.connect(_on_preview_hover_changed)
		placement_preview.validity_changed.connect(_on_preview_validity_changed)

		# Start with preview disabled
		placement_preview.enabled = false

	_setup_ui_hints()

func _input(event: InputEvent) -> void:
	if not placement_preview or not tile_map:
		return

	# Toggle placement mode with Space
	if event.is_action_pressed("ui_accept"):  # Space key
		toggle_placement_mode()

	# Handle mouse movement in placement mode
	if placement_mode and event is InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		placement_preview.update_preview(mouse_pos)

	# Handle placement with left click
	if placement_mode and event.is_action_pressed("ui_select"):  # Left click
		if placement_preview.is_placement_valid():
			_place_objects()

	# Handle removal with right click
	if placement_mode and event.is_action_pressed("ui_cancel"):  # Right click or ESC
		_remove_objects()

	# Cycle through preview modes with numbers 1-4
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				placement_preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE
				print("Preview Mode: SINGLE")
			KEY_2:
				placement_preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
				placement_preview.area_size = Vector2i(2, 2)
				print("Preview Mode: AREA (2x2)")
			KEY_3:
				placement_preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
				placement_preview.radius = 2
				print("Preview Mode: RADIUS (2 tiles)")
			KEY_4:
				placement_preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
				_setup_custom_shape()
				print("Preview Mode: CUSTOM (L-shape)")
			KEY_5:
				# Cycle highlight styles
				var current_style := placement_preview.highlight_style
				placement_preview.highlight_style = (current_style + 1) % 4
				print("Highlight Style: ", placement_preview.highlight_style)

func toggle_placement_mode() -> void:
	placement_mode = not placement_mode
	placement_preview.enabled = placement_mode

	if placement_mode:
		print("Placement mode ENABLED")
		print("1-4: Change preview mode | 5: Change style | LMB: Place | RMB: Remove")
	else:
		print("Placement mode DISABLED")
		placement_preview.clear_preview()

func _validate_placement(hex_coords: Vector2i) -> bool:
	# Check if tile is already occupied
	if occupied_tiles.has(hex_coords):
		return false

	# Example: Restrict placement to certain bounds
	if abs(hex_coords.x) > 10 or abs(hex_coords.y) > 10:
		return false

	# Example: Check if tile exists in tile map
	# You could add more complex validation logic here
	# such as checking terrain type, checking for obstacles, etc.

	return true

func _place_objects() -> void:
	var hexes := placement_preview.get_preview_hexes()

	for hex in hexes:
		if not occupied_tiles.has(hex):
			# Mark as occupied
			occupied_tiles[hex] = true

			# Optionally place a visual indicator
			_place_visual_marker(hex)

	print("Placed object(s) at: ", hexes)

	# Update preview to reflect new occupied tiles
	var mouse_pos := get_global_mouse_position()
	placement_preview.update_preview(mouse_pos)

func _remove_objects() -> void:
	var hovered_hex := placement_preview.get_hovered_hex()

	if occupied_tiles.has(hovered_hex):
		occupied_tiles.erase(hovered_hex)
		_remove_visual_marker(hovered_hex)
		print("Removed object at: ", hovered_hex)

		# Update preview
		var mouse_pos := get_global_mouse_position()
		placement_preview.update_preview(mouse_pos)

func _place_visual_marker(hex_coords: Vector2i) -> void:
	# Example: Place a marker sprite or tile
	# You could create a ColorRect, Sprite2D, or use TileMap.set_cell()
	var marker := ColorRect.new()
	marker.size = Vector2(80, 80)
	marker.position = tile_map.map_to_local(hex_coords) - marker.size / 2
	marker.color = Color(0.3, 0.5, 1.0, 0.7)
	marker.name = "Marker_%d_%d" % [hex_coords.x, hex_coords.y]
	add_child(marker)

func _remove_visual_marker(hex_coords: Vector2i) -> void:
	var marker_name := "Marker_%d_%d" % [hex_coords.x, hex_coords.y]
	var marker := get_node_or_null(marker_name)
	if marker:
		marker.queue_free()

func _setup_custom_shape() -> void:
	# Define a custom L-shape
	var l_shape: Array[Vector2i] = [
		Vector2i(0, 0),   # Center
		Vector2i(1, 0),   # Right
		Vector2i(2, 0),   # Right-right
		Vector2i(0, 1),   # Down
		Vector2i(0, 2),   # Down-down
	]
	placement_preview.set_custom_shape(l_shape)

func _setup_ui_hints() -> void:
	# Create a simple label with instructions
	var label := Label.new()
	label.text = """
	HEXAGON PLACEMENT PREVIEW

	Controls:
	- SPACE: Toggle placement mode
	- 1: Single tile mode
	- 2: Area (2x2) mode
	- 3: Radius (2 tiles) mode
	- 4: Custom L-shape mode
	- 5: Cycle highlight styles
	- Left Click: Place object
	- Right Click: Remove object
	- ESC: Exit placement mode
	"""
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

func _on_preview_hover_changed(hex_coords: Vector2i) -> void:
	# Optional: Handle hover change events
	# For example, you could display coordinates or info about the tile
	pass

func _on_preview_validity_changed(is_valid: bool) -> void:
	# Optional: Handle validity changes
	# For example, play a sound or show a UI indicator
	if is_valid:
		pass  # Could play positive feedback sound
	else:
		pass  # Could play negative feedback sound
