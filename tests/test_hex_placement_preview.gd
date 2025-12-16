extends GutTest
## Unit tests for HexPlacementPreview tool

var preview: HexPlacementPreview
var tile_map: TileMapLayer

func before_each() -> void:
	preview = HexPlacementPreview.new()
	tile_map = TileMapLayer.new()

	# Create a basic tile set for testing
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	tile_set.tile_size = Vector2i(120, 140)
	tile_map.tile_set = tile_set

	add_child_autofree(tile_map)
	add_child_autofree(preview)

	preview.set_tile_map(tile_map)

func after_each() -> void:
	preview = null
	tile_map = null

#region Basic Functionality Tests

func test_initialization() -> void:
	assert_not_null(preview, "Preview should be created")
	assert_eq(preview.preview_mode, HexPlacementPreview.PreviewMode.SINGLE,
			  "Default mode should be SINGLE")
	assert_true(preview.enabled, "Preview should be enabled by default")

func test_set_tile_map() -> void:
	var new_tile_map := TileMapLayer.new()
	preview.set_tile_map(new_tile_map)
	# If no errors, test passes
	assert_true(true, "Should set tile map without errors")
	new_tile_map.queue_free()

func test_enable_disable() -> void:
	preview.enabled = true
	assert_true(preview.enabled, "Preview should be enabled")
	assert_true(preview.visible, "Preview should be visible when enabled")

	preview.enabled = false
	assert_false(preview.enabled, "Preview should be disabled")
	assert_false(preview.visible, "Preview should be hidden when disabled")

func test_opacity_setting() -> void:
	preview.preview_opacity = 0.5
	assert_almost_eq(preview.modulate.a, 0.5, 0.01, "Opacity should be set correctly")

	preview.preview_opacity = 1.0
	assert_almost_eq(preview.modulate.a, 1.0, 0.01, "Opacity should be 1.0")

#endregion

#region Preview Mode Tests

func test_single_mode() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 1, "Single mode should preview 1 tile")
	assert_eq(hexes[0], Vector2i(0, 0), "Should preview the correct tile")

func test_area_mode() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
	preview.area_size = Vector2i(2, 2)
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 4, "2x2 area should have 4 tiles")

func test_area_mode_3x3() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
	preview.area_size = Vector2i(3, 3)
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 9, "3x3 area should have 9 tiles")

func test_radius_mode() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
	preview.radius = 1
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_gt(hexes.size(), 1, "Radius mode should have multiple tiles")
	assert_true(hexes.has(Vector2i(0, 0)), "Should include center tile")

func test_custom_mode() -> void:
	var custom_shape: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
	]

	preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
	preview.set_custom_shape(custom_shape)
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 3, "Custom shape should have 3 tiles")
	assert_true(hexes.has(Vector2i(0, 0)), "Should include origin")
	assert_true(hexes.has(Vector2i(1, 0)), "Should include offset 1")
	assert_true(hexes.has(Vector2i(0, 1)), "Should include offset 2")

#endregion

#region Custom Shape Tests

func test_add_to_custom_shape() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
	preview.set_custom_shape([Vector2i(0, 0)])
	preview.add_to_custom_shape(Vector2i(1, 0))

	assert_eq(preview.custom_offsets.size(), 2, "Should have 2 offsets")
	assert_true(preview.custom_offsets.has(Vector2i(1, 0)), "Should contain new offset")

func test_remove_from_custom_shape() -> void:
	var shape: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	preview.set_custom_shape(shape)
	preview.remove_from_custom_shape(Vector2i(1, 0))

	assert_eq(preview.custom_offsets.size(), 1, "Should have 1 offset after removal")
	assert_false(preview.custom_offsets.has(Vector2i(1, 0)), "Should not contain removed offset")

func test_add_duplicate_to_custom_shape() -> void:
	preview.set_custom_shape([Vector2i(0, 0)])
	preview.add_to_custom_shape(Vector2i(0, 0))

	assert_eq(preview.custom_offsets.size(), 1, "Should not add duplicates")

#endregion

#region Validation Tests

func test_default_validation() -> void:
	preview.update_preview_at_hex(Vector2i(0, 0))
	assert_true(preview.is_placement_valid(), "Should be valid by default")

func test_custom_validation_valid() -> void:
	preview.set_validation_function(func(_hex: Vector2i) -> bool: return true)
	preview.update_preview_at_hex(Vector2i(0, 0))

	assert_true(preview.is_placement_valid(), "Should be valid with always-true validation")

func test_custom_validation_invalid() -> void:
	preview.set_validation_function(func(_hex: Vector2i) -> bool: return false)
	preview.update_preview_at_hex(Vector2i(0, 0))

	assert_false(preview.is_placement_valid(), "Should be invalid with always-false validation")

func test_validation_with_multiple_tiles() -> void:
	# Validation that rejects tiles with x > 0
	var validation := func(hex: Vector2i) -> bool:
		return hex.x <= 0

	preview.set_validation_function(validation)
	preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
	preview.area_size = Vector2i(2, 2)

	# At origin, will include tiles at x=1
	preview.update_preview_at_hex(Vector2i(0, 0))

	assert_false(preview.is_placement_valid(),
				 "Should be invalid when any tile fails validation")

func test_manual_validity_override() -> void:
	preview.set_validation_function(func(_hex: Vector2i) -> bool: return true)
	preview.update_preview_at_hex(Vector2i(0, 0))

	preview.set_validity(false)
	assert_false(preview.is_placement_valid(), "Should respect manual validity override")

#endregion

#region Query Tests

func test_get_hovered_hex() -> void:
	preview.update_preview_at_hex(Vector2i(5, 3))
	assert_eq(preview.get_hovered_hex(), Vector2i(5, 3), "Should return correct hovered hex")

func test_get_preview_hexes() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE
	preview.update_preview_at_hex(Vector2i(2, 2))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 1, "Should return array with 1 hex")
	assert_eq(hexes[0], Vector2i(2, 2), "Should return correct hex coordinates")

func test_clear_preview() -> void:
	preview.update_preview_at_hex(Vector2i(1, 1))
	preview.clear_preview()

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 0, "Should have no preview hexes after clear")

#endregion

#region Static Helper Function Tests

func test_hex_distance_same_tile() -> void:
	var dist := HexPlacementPreview.hex_distance(Vector2i(0, 0), Vector2i(0, 0))
	assert_eq(dist, 0, "Distance to same tile should be 0")

func test_hex_distance_adjacent() -> void:
	var dist := HexPlacementPreview.hex_distance(Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(dist, 1, "Distance to adjacent tile should be 1")

func test_hex_distance_far() -> void:
	var dist := HexPlacementPreview.hex_distance(Vector2i(0, 0), Vector2i(3, 3))
	assert_gt(dist, 0, "Distance should be greater than 0")

func test_get_hex_neighbors() -> void:
	var neighbors := HexPlacementPreview.get_hex_neighbors(Vector2i(0, 0))
	assert_eq(neighbors.size(), 6, "Hex should have 6 neighbors")
	assert_true(neighbors.has(Vector2i(1, 0)), "Should have right neighbor")
	assert_true(neighbors.has(Vector2i(-1, 0)), "Should have left neighbor")

func test_get_hex_line_same_tile() -> void:
	var line := HexPlacementPreview.get_hex_line(Vector2i(0, 0), Vector2i(0, 0))
	assert_eq(line.size(), 1, "Line to same tile should have 1 element")

func test_get_hex_line_adjacent() -> void:
	var line := HexPlacementPreview.get_hex_line(Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(line.size(), 2, "Line to adjacent tile should have 2 elements")
	assert_eq(line[0], Vector2i(0, 0), "Should start at origin")
	assert_eq(line[1], Vector2i(1, 0), "Should end at target")

func test_axial_to_cube_conversion() -> void:
	var cube := HexPlacementPreview.axial_to_cube(Vector2i(1, 2))
	assert_eq(cube.x + cube.y + cube.z, 0, "Cube coordinates should sum to 0")

func test_cube_to_axial_conversion() -> void:
	var cube := Vector3i(1, 2, -3)
	var axial := HexPlacementPreview.cube_to_axial(cube)
	assert_eq(axial.x, 1, "X should be preserved")
	assert_eq(axial.y, 2, "Y should be preserved")

func test_coordinate_round_trip() -> void:
	var original := Vector2i(3, 5)
	var cube := HexPlacementPreview.axial_to_cube(original)
	var back := HexPlacementPreview.cube_to_axial(cube)
	assert_eq(back, original, "Round trip conversion should preserve coordinates")

#endregion

#region Signal Tests

func test_hover_changed_signal() -> void:
	watch_signals(preview)
	preview.update_preview_at_hex(Vector2i(1, 1))
	assert_signal_emitted(preview, "hover_changed", "Should emit hover_changed signal")

func test_validity_changed_signal() -> void:
	watch_signals(preview)
	preview.set_validation_function(func(_hex: Vector2i) -> bool: return true)
	preview.update_preview_at_hex(Vector2i(0, 0))

	# Change validation to trigger signal
	preview.set_validation_function(func(_hex: Vector2i) -> bool: return false)
	preview.update_preview_at_hex(Vector2i(0, 0))

	assert_signal_emitted(preview, "validity_changed", "Should emit validity_changed signal")

#endregion

#region Edge Cases

func test_update_preview_without_tilemap() -> void:
	var preview_no_map := HexPlacementPreview.new()
	add_child_autofree(preview_no_map)

	# Should not crash
	preview_no_map.update_preview(Vector2.ZERO)
	assert_true(true, "Should handle missing tilemap gracefully")

func test_negative_coordinates() -> void:
	preview.update_preview_at_hex(Vector2i(-5, -5))
	var hex := preview.get_hovered_hex()
	assert_eq(hex, Vector2i(-5, -5), "Should handle negative coordinates")

func test_large_coordinates() -> void:
	preview.update_preview_at_hex(Vector2i(1000, 1000))
	var hex := preview.get_hovered_hex()
	assert_eq(hex, Vector2i(1000, 1000), "Should handle large coordinates")

func test_empty_custom_shape() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
	preview.set_custom_shape([])
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 0, "Empty custom shape should result in no preview")

func test_zero_radius() -> void:
	preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
	preview.radius = 0
	preview.update_preview_at_hex(Vector2i(0, 0))

	var hexes := preview.get_preview_hexes()
	assert_eq(hexes.size(), 1, "Zero radius should only include center tile")

#endregion
