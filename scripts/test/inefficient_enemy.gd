extends Node2D

@export var move_speed = 100.0

var target_player  # No type, no initialization

func _process(delta):
    if target_player == null:
        # Find player every frame - very inefficient!
        target_player = get_node("/root/Main/Player")
    
    if target_player:
        var direction = (target_player.global_position - global_position)
        # Missing normalization again
        global_position += direction * move_speed * delta
        
        # Expensive string concat in loop (if many enemies)
        print("Enemy moving towards " + target_player.name + " at " + str(global_position))

# No type on parameter
func attack(damage):
    print(damage)  # Does nothing useful

# Cyclic preload risk if mutual references
const BulletScene = preload("res://bullet.tscn")  # Assume this exists or not - potential error if missing