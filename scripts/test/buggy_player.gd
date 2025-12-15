extends CharacterBody2D
var speed: float = 300.0
var health: int = 100
var speed: float = 300.0  # Typed variable
var health: int = 100

func _ready():
    print("Player ready")  # Fine, but add more

func _physics_process(delta):
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    
    # Missing normalization - diagonal movement is faster!
    velocity = input_vector * speed
    
    move_and_slide()
    
    # Potential null reference if no NodePath set in editor
    $AnimatedSprite2D.play("walk" if velocity.length() > 0 else "idle")
    
    # Inefficient: Calling every frame when not needed
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if position.distance_to(enemy.position) < 50:
            take_damage(1)

func take_damage(amount):
    health -= amount
    if health <= 0:
        queue_free()  # Game over with no feedback
    # Missing emit_signal or visual effect

# Unused function
func unused_heal():
    health += 50

# Bad: Direct node access instead of onready or export
onready var weapon = get_node("Weapon")