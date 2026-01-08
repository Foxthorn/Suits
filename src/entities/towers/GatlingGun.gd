class_name GatlingGun
extends BaseTower
## Gatling Gun tower - rapid-fire turret with high fire rate
## Fires 5 shots per second at the nearest enemy
## Trades damage per shot for volume of fire

#region Exports
@export var tower_sprite: Texture2D = preload("res://assets/towers/gatling/tier1/gun_idle_00.png")

#endregion

#region Configuration
const FIRING_ANIMATION_FRAMES: int = 4  # Number of rotation frames for visual feedback
const BULLET_SPREAD_ANGLE: float = 0.1  # Small inaccuracy for visual interest (radians)

#endregion



#region Private Variables
var _fire_animation_frame: float = 0.0

#endregion

#region Lifecycle
func _ready() -> void:
	# Set tower type before calling parent _ready()
	tower_type = TowerDatabase.TowerType.GATLING_GUN

	super._ready()

	# Override sprite with Gatling Gun specific sprite
	if _sprite and tower_sprite:
		_sprite.scale = Vector2(0.6, 0.6)  # Standard bullet size
		_sprite.texture = tower_sprite

	# Initialize weapon system (already created in scene via _ready NodePath)
	self.tower_weapon_system.initialize(tower_data)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update firing animation (visual rotation/spin effect)
	if fire_cooldown < tower_data.fire_rate / 2:
		# Recently fired - spin animation active
		_update_firing_animation(delta)

#endregion

#region Firing Override
func fire() -> void:
	"""Fire at current target with Gatling Gun behavior"""
	if not current_target:
		return

	# Calculate base direction to target
	var base_direction = (current_target.global_position - global_position).normalized()

	# Add small random spread for visual interest
	var spread = randf_range(-BULLET_SPREAD_ANGLE, BULLET_SPREAD_ANGLE)
	var final_direction = base_direction.rotated(spread)

	# Fire the bullet via TowerWeaponSystem
	self.tower_weapon_system.fire(global_position, final_direction, tower_data.bullet_color)

	# Emit signal for audio/effects
	fired.emit(global_position, final_direction)

	# Visual feedback
	_flash_white()

#endregion

#region Firing Animation
func _update_firing_animation(delta: float) -> void:
	"""Update spinning/rotation animation while firing"""
	_fire_animation_frame += delta / (tower_data.fire_rate * 0.5)

	if _sprite and _fire_animation_frame < FIRING_ANIMATION_FRAMES:
		# Rotate sprite during fire
		var rotation_amount = (_fire_animation_frame / FIRING_ANIMATION_FRAMES) * TAU
		_sprite.rotation = rotation_amount

#endregion

#region Public API
func get_fire_rate_display() -> String:
	"""Get human-readable fire rate"""
	var shots_per_second = 1.0 / tower_data.fire_rate
	return "%.1f shots/sec" % shots_per_second

#endregion
