class_name TowerWeaponSystem extends Node
## Handles tower projectile spawning
## Similar to WeaponSystem but for tower-specific bullets
## Instantiates tower projectiles on firing
## Projectiles self-destruct after collision

#region Signals
signal tower_bullet_fired(bullet: Node2D, from_position: Vector2, direction: Vector2)

#endregion

#region Exports
@export var projectile_scene: PackedScene = preload("res://scenes/entities/projectiles/TowerBullet.tscn")

#endregion

#region Private Variables
var _tower_data: TowerDatabase.TowerData

#endregion

#region Initialization
func initialize(tower_data: TowerDatabase.TowerData) -> void:
	"""Initialize the weapon system with tower data"""
	_tower_data = tower_data

#endregion

#region Firing
func fire(from_position: Vector2, direction: Vector2, color: Color) -> void:
	"""Fire a tower bullet in the given direction"""
	# Instantiate new bullet
	var bullet = projectile_scene.instantiate() as TowerBullet
	get_tree().current_scene.add_child(bullet)

	bullet.name = "TowerBullet"
	# Setup bullet using TowerBullet API
	bullet.global_position = from_position
	bullet.set_velocity(direction, _tower_data.bullet_speed)
	bullet.set_color(color)
	bullet.set_lifetime(_tower_data.bullet_lifetime)
	bullet.set_damage(_tower_data.damage)

	# Emit signal
	tower_bullet_fired.emit(bullet, from_position, direction)

#endregion
