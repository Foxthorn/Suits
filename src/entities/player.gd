# player.gd
# A simple player controller with health, jumping, and damage handling.

extends CharacterBody2D

# Exported for easy tweaking in the editor
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var max_health: int = 100

# Signals
signal died()
signal health_changed(new_health: int)
signal jumped()

# Private variables (typed where possible)
var _health: int
var _is_dead: bool = false

# Godot built-in gravity from project settings
@onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
    reset_health()


func reset_health() -> void:
    _health = max_health
    _is_dead = false
    emit_signal("health_changed", _health)


func _physics_process(delta: float) -> void:
    if _is_dead:
        return

    # Horizontal movement
    var direction := Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)

    # Gravity
    if not is_on_floor():
        velocity.y += gravity * delta

    # Jump
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = jump_velocity
        emit_signal("jumped")

    move_and_slide()


func take_damage(amount: int) -> void:
    if _is_dead or amount <= 0:
        return

    _health = maxi(_health - amount, 0)
    emit_signal("health_changed", _health)

    if _health <= 0:
        die()


func heal(amount: int) -> void:
    if _is_dead or amount <= 0:
        return

    _health = mini(_health + amount, max_health)
    emit_signal("health_changed", _health)


func die() -> void:
    if _is_dead:
        return
    _is_dead = true
    emit_signal("died")
    # Could disable collision, play animation, etc.
    set_physics_process(false)
