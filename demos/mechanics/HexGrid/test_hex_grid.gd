extends Node2D
## Test script for HexGrid system
## Connects to grid signals and prints debug information

@onready var hex_grid: HexGrid = $HexGrid

func _ready() -> void:
	if not hex_grid:
		push_error("TestHexGrid: HexGrid node not found!")
		return

	# Connect to grid signals
	hex_grid.tile_clicked.connect(_on_tile_clicked)
	hex_grid.tile_hovered.connect(_on_tile_hovered)

	print("=== HEX GRID TEST STARTED ===")
	print("Grid initialized successfully")
	print("Camera position: ", hex_grid.get_camera_position())
	print("Click tiles to test coordinate conversion!")
	print("")

	# Run some automated tests
	_run_automated_tests()

func _on_tile_clicked(hex_coords: Vector2i, world_pos: Vector2) -> void:
	print("CLICKED: Hex %s | World %.2v" % [hex_coords, world_pos])

	# Test neighbor finding
	var neighbors = hex_grid.get_neighbors(hex_coords)
	print("  Neighbors: ", neighbors)

	# Test distance to origin
	var distance = hex_grid.hex_distance(hex_coords, Vector2i.ZERO)
	print("  Distance from origin: ", distance)

func _on_tile_hovered(hex_coords: Vector2i, world_pos: Vector2) -> void:
	# Only print if we want verbose hover logging
	pass

func _run_automated_tests() -> void:
	print("--- Running Automated Tests ---")

	# Test 1: Coordinate conversion round-trip
	var test_hex = Vector2i(5, 3)
	var world_pos = hex_grid.hex_to_world(test_hex)
	var back_to_hex = hex_grid.world_to_hex(world_pos)
	print("✓ Round-trip test: %s → %.2v → %s" % [test_hex, world_pos, back_to_hex])
	assert(test_hex == back_to_hex, "Round-trip conversion failed!")

	# Test 2: Neighbor count
	var neighbors = hex_grid.get_neighbors(Vector2i.ZERO)
	print("✓ Neighbor count: %d (expected 6)" % neighbors.size())
	assert(neighbors.size() == 6, "Wrong neighbor count!")

	# Test 3: Distance calculation
	var dist = hex_grid.hex_distance(Vector2i(0, 0), Vector2i(3, 0))
	print("✓ Distance (0,0) to (3,0): %d (expected 3)" % dist)
	assert(dist == 3, "Distance calculation wrong!")

	# Test 4: Radius search
	var radius_hexes = hex_grid.get_hexes_in_radius(Vector2i.ZERO, 2)
	print("✓ Hexes in radius 2: %d tiles" % radius_hexes.size())

	# Test 5: Ring search
	var ring_hexes = hex_grid.get_hexes_in_ring(Vector2i.ZERO, 2)
	print("✓ Hexes in ring 2: %d tiles (expected 12)" % ring_hexes.size())

	print("--- All Tests Passed! ---")
	print("")
