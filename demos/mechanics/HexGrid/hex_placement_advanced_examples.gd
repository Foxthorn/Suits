extends Node
## Advanced examples and patterns for using HexPlacementPreview in various game scenarios.
##
## This file contains practical examples for common use cases like building placement,
## tower defense, unit movement, area effects, and more.

#region Building Placement Example

class BuildingPlacer:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var buildings: Dictionary = {}  # hex_coords -> building_data
	var terrain_types: Dictionary = {}  # hex_coords -> terrain_type

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.set_validation_function(_validate_building_placement)

	func set_building_type(building_type: String) -> void:
		match building_type:
			"small_house":
				preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE
			"large_house":
				preview.preview_mode = HexPlacementPreview.PreviewMode.AREA
				preview.area_size = Vector2i(2, 2)
			"tower":
				preview.preview_mode = HexPlacementPreview.PreviewMode.SINGLE
			"wall":
				preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
				_set_wall_shape()

	func _set_wall_shape() -> void:
		# Straight line of 3 tiles
		var wall_shape: Array[Vector2i] = [
			Vector2i(0, 0),
			Vector2i(1, 0),
			Vector2i(2, 0),
		]
		preview.set_custom_shape(wall_shape)

	func _validate_building_placement(hex: Vector2i) -> bool:
		# Can't build on occupied tiles
		if buildings.has(hex):
			return false

		# Can't build on water
		if terrain_types.get(hex, "grass") == "water":
			return false

		# Must be within map bounds
		if abs(hex.x) > 20 or abs(hex.y) > 20:
			return false

		return true

	func place_building(building_type: String) -> bool:
		if not preview.is_placement_valid():
			return false

		var hexes := preview.get_preview_hexes()
		for hex in hexes:
			buildings[hex] = {"type": building_type, "health": 100}

		return true

#endregion

#region Unit Movement Range Example

class UnitMovementRange:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var unit_position: Vector2i
	var movement_range: int = 3
	var obstacles: Array[Vector2i] = []

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
		preview.set_validation_function(_validate_movement)

	func show_movement_range(from_hex: Vector2i) -> void:
		unit_position = from_hex
		preview.radius = movement_range
		preview.update_preview_at_hex(from_hex)

		# Highlight all reachable tiles
		var reachable := _get_reachable_tiles(from_hex, movement_range)
		_highlight_reachable(reachable)

	func _validate_movement(hex: Vector2i) -> bool:
		# Can't move to obstacles
		if obstacles.has(hex):
			return false

		# Check if within movement range
		var distance := HexPlacementPreview.hex_distance(unit_position, hex)
		return distance <= movement_range

	func _get_reachable_tiles(start: Vector2i, max_range: int) -> Array[Vector2i]:
		# BFS to find all reachable tiles considering obstacles
		var visited: Dictionary = {}
		var queue: Array = [[start, 0]]  # [position, cost]
		var reachable: Array[Vector2i] = []

		while not queue.is_empty():
			var current = queue.pop_front()
			var pos: Vector2i = current[0]
			var cost: int = current[1]

			if visited.has(pos):
				continue

			visited[pos] = true
			reachable.append(pos)

			if cost >= max_range:
				continue

			for neighbor in HexPlacementPreview.get_hex_neighbors(pos):
				if not obstacles.has(neighbor) and not visited.has(neighbor):
					queue.append([neighbor, cost + 1])

		return reachable

	func _highlight_reachable(hexes: Array[Vector2i]) -> void:
		# Could create custom visualization for reachable tiles
		pass

#endregion

#region Area of Effect Example

class AreaOfEffectPreview:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var effect_radius: int = 2
	var friendly_units: Array[Vector2i] = []
	var enemy_units: Array[Vector2i] = []

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
		preview.radius = effect_radius
		preview.set_validation_function(_validate_aoe)

	func set_effect_radius(radius: int) -> void:
		effect_radius = radius
		preview.radius = radius

	func update_aoe_preview(world_pos: Vector2) -> Dictionary:
		preview.update_preview(world_pos)

		var affected_hexes := preview.get_preview_hexes()
		var result := {
			"friendly_hit": 0,
			"enemy_hit": 0,
			"hexes": affected_hexes
		}

		for hex in affected_hexes:
			if friendly_units.has(hex):
				result["friendly_hit"] += 1
			if enemy_units.has(hex):
				result["enemy_hit"] += 1

		# Color code based on targets hit
		if result["enemy_hit"] > 0 and result["friendly_hit"] == 0:
			preview.valid_color = Color(0.2, 1.0, 0.2, 0.6)  # Green - good target
		elif result["friendly_hit"] > 0:
			preview.invalid_color = Color(1.0, 0.5, 0.0, 0.6)  # Orange - warning
		else:
			preview.valid_color = Color(0.5, 0.5, 0.5, 0.4)  # Gray - no targets

		return result

	func _validate_aoe(hex: Vector2i) -> bool:
		# AOE is always valid, but color changes based on targets
		return true

#endregion

#region Pathfinding Preview Example

class PathfindingPreview:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var path: Array[Vector2i] = []

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM

	func show_path(start: Vector2i, end: Vector2i) -> void:
		# Simple straight-line path (replace with A* for real pathfinding)
		path = HexPlacementPreview.get_hex_line(start, end)

		# Convert path to offsets from start
		var offsets: Array[Vector2i] = []
		for hex in path:
			offsets.append(hex - start)

		preview.set_custom_shape(offsets)
		preview.update_preview_at_hex(start)

	func get_path() -> Array[Vector2i]:
		return path.duplicate()

#endregion

#region Tower Defense Range Example

class TowerRangePreview:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var tower_range: int = 3
	var path_tiles: Array[Vector2i] = []  # Enemy path

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
		preview.set_validation_function(_validate_tower_placement)

	func set_tower_range(range: int) -> void:
		tower_range = range
		preview.radius = range

	func update_tower_preview(world_pos: Vector2) -> int:
		preview.update_preview(world_pos)

		# Calculate how much of the enemy path is covered
		var covered_path_tiles := 0
		var range_hexes := preview.get_preview_hexes()

		for hex in range_hexes:
			if path_tiles.has(hex):
				covered_path_tiles += 1

		# Good placement covers enemy path
		if covered_path_tiles > 0:
			preview.valid_color = Color(0.2, 1.0, 0.2, 0.6)
		else:
			preview.valid_color = Color(1.0, 1.0, 0.2, 0.4)  # Suboptimal

		return covered_path_tiles

	func _validate_tower_placement(hex: Vector2i) -> bool:
		# Can't place tower on the enemy path
		return not path_tiles.has(hex)

#endregion

#region Resource Gathering Area Example

class ResourceGatheringArea:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var resource_locations: Dictionary = {}  # hex -> resource_type
	var gathering_radius: int = 2

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.RADIUS
		preview.radius = gathering_radius

	func show_gathering_area(center: Vector2i) -> Dictionary:
		preview.update_preview_at_hex(center)

		var resources := {}
		var range_hexes := preview.get_preview_hexes()

		for hex in range_hexes:
			if resource_locations.has(hex):
				var resource_type: String = resource_locations[hex]
				resources[resource_type] = resources.get(resource_type, 0) + 1

		return resources

#endregion

#region Flood Fill Selection Example

class FloodFillSelection:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var selected_tiles: Array[Vector2i] = []

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM

	func select_connected_tiles(start: Vector2i, terrain_type: String,
								terrain_map: Dictionary) -> Array[Vector2i]:
		var visited: Dictionary = {}
		var queue: Array[Vector2i] = [start]
		var connected: Array[Vector2i] = []

		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()

			if visited.has(current):
				continue

			visited[current] = true

			if terrain_map.get(current, "") != terrain_type:
				continue

			connected.append(current)

			for neighbor in HexPlacementPreview.get_hex_neighbors(current):
				if not visited.has(neighbor):
					queue.append(neighbor)

		# Update preview to show selected tiles
		var offsets: Array[Vector2i] = []
		for tile in connected:
			offsets.append(tile - start)

		preview.set_custom_shape(offsets)
		preview.update_preview_at_hex(start)

		return connected

#endregion

#region Multi-Tile Structure Example

class MultiTileStructure:
	var preview: HexPlacementPreview
	var tile_map: TileMapLayer
	var structure_templates: Dictionary = {}

	func _init(p_preview: HexPlacementPreview, p_tile_map: TileMapLayer) -> void:
		preview = p_preview
		tile_map = p_tile_map
		preview.preview_mode = HexPlacementPreview.PreviewMode.CUSTOM
		_initialize_templates()

	func _initialize_templates() -> void:
		# T-shaped structure
		structure_templates["t_shape"] = [
			Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
			Vector2i(0, 1)
		]

		# Plus-shaped structure
		structure_templates["plus"] = [
			Vector2i(0, -1),
			Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
			Vector2i(0, 1)
		]

		# L-shaped structure
		structure_templates["l_shape"] = [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(0, 2)
		]

		# Hexagon outline
		structure_templates["hex_ring"] = [
			Vector2i(1, -1), Vector2i(1, 0),
			Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(0, -1)
		]

	func select_structure(template_name: String) -> void:
		if structure_templates.has(template_name):
			preview.set_custom_shape(structure_templates[template_name])

	func rotate_structure_clockwise() -> void:
		var current_shape := preview.custom_offsets
		var rotated: Array[Vector2i] = []

		for offset in current_shape:
			# Hex rotation: (q, r) -> (-r, q+r)
			var new_offset := Vector2i(-offset.y, offset.x + offset.y)
			rotated.append(new_offset)

		preview.set_custom_shape(rotated)

	func flip_structure_horizontal() -> void:
		var current_shape := preview.custom_offsets
		var flipped: Array[Vector2i] = []

		for offset in current_shape:
			# Hex horizontal flip: (q, r) -> (-q, -r)
			flipped.append(-offset)

		preview.set_custom_shape(flipped)

#endregion

#region Usage Example

func example_usage() -> void:
	# This function demonstrates how to use the advanced examples
	var tile_map := TileMapLayer.new()
	var preview := HexPlacementPreview.new()

	# Building placement
	var building_placer := BuildingPlacer.new(preview, tile_map)
	building_placer.set_building_type("large_house")

	# Unit movement
	var movement := UnitMovementRange.new(preview, tile_map)
	movement.show_movement_range(Vector2i(0, 0))

	# Area of effect
	var aoe := AreaOfEffectPreview.new(preview, tile_map)
	aoe.set_effect_radius(3)

	# Pathfinding
	var pathfinder := PathfindingPreview.new(preview, tile_map)
	pathfinder.show_path(Vector2i(0, 0), Vector2i(5, 5))

	# Tower defense
	var tower := TowerRangePreview.new(preview, tile_map)
	tower.set_tower_range(4)

	# Multi-tile structures
	var structure := MultiTileStructure.new(preview, tile_map)
	structure.select_structure("plus")
	structure.rotate_structure_clockwise()

#endregion
