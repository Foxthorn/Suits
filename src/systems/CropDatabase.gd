class_name CropDatabase
extends Node
## Central database for all crop definitions
## Easily extensible: Just call register_crop() to add new crop types

## Crop types enum - add new entries here when adding crops
enum CropType {
	WHEAT = 0,
	CORN = 1,
	ALIEN_FRUIT = 2,
	# Add new crop types here
}

## Crop data structure - can be extended with more properties
class CropData:
	var id: CropType
	var name: String
	var grow_time: float  # seconds to reach harvest state
	var cost: int  # credits to plant
	var value: int  # credits gained on harvest
	var description: String
	var color: Color  # temporary visual until we have sprites

	func _init(p_id: CropType, p_name: String, p_grow_time: float, p_cost: int, p_value: int, p_description: String, p_color: Color):
		id = p_id
		name = p_name
		grow_time = p_grow_time
		cost = p_cost
		value = p_value
		description = p_description
		color = p_color

static var _registry: Dictionary = {}  # CropType -> CropData
static var _initialized: bool = false

## Initialize crop database (called automatically on first access)
static func _ensure_initialized() -> void:
	if _initialized:
		return

	_initialized = true

	# Register default crops (vertical slice)
	register_crop(CropData.new(
		CropType.WHEAT,
		"Wheat",
		GameConfig.CROP_WHEAT_GROW_TIME,
		GameConfig.CROP_WHEAT_COST,
		GameConfig.CROP_WHEAT_VALUE,
		"Fast-growing, low profit. Good for early game.",
		Color.GOLDENROD
	))

	register_crop(CropData.new(
		CropType.CORN,
		"Corn",
		GameConfig.CROP_CORN_GROW_TIME,
		GameConfig.CROP_CORN_COST,
		GameConfig.CROP_CORN_VALUE,
		"Medium growth, medium profit. Balanced choice.",
		Color.YELLOW
	))

	register_crop(CropData.new(
		CropType.ALIEN_FRUIT,
		"Alien Fruit",
		GameConfig.CROP_ALIEN_FRUIT_GROW_TIME,
		GameConfig.CROP_ALIEN_FRUIT_COST,
		GameConfig.CROP_ALIEN_FRUIT_VALUE,
		"Slow-growing, high profit. Risky investment.",
		Color.PURPLE
	))

	print("CropDatabase: Initialized with %d crops" % _registry.size())

## Register a new crop type (extensibility point)
static func register_crop(crop_data: CropData) -> void:
	if _registry.has(crop_data.id):
		push_warning("CropDatabase: Overwriting existing crop type %d" % crop_data.id)

	_registry[crop_data.id] = crop_data

## Get crop data by type
static func get_crop(type: CropType) -> CropData:
	_ensure_initialized()
	return _registry.get(type)

## Get crop name by type
static func get_crop_name(type: CropType) -> String:
	var crop_data := get_crop(type)
	return crop_data.name if crop_data else "Unknown"

## Get crop cost by type
static func get_crop_cost(type: CropType) -> int:
	var crop_data := get_crop(type)
	return crop_data.cost if crop_data else 0

## Get crop value by type
static func get_crop_value(type: CropType) -> int:
	var crop_data := get_crop(type)
	return crop_data.value if crop_data else 0

## Get all registered crop types as array (useful for UI iteration)
static func get_all_crop_types() -> Array[CropType]:
	_ensure_initialized()
	var types: Array[CropType] = []
	for key in _registry.keys():
		types.append(key)
	return types

## Get all registered crop data (useful for UI generation)
static func get_all_crops() -> Array[CropData]:
	_ensure_initialized()
	var crops: Array[CropData] = []
	for crop_data in _registry.values():
		crops.append(crop_data)
	return crops

## Check if a crop type is registered
static func has_crop(type: CropType) -> bool:
	_ensure_initialized()
	return _registry.has(type)
