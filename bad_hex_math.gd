# bad_hex_math.gd
extends Node

func cube_to_axial(cube):
    var q = cube.x
    var r = cube.z
    return Vector2(q, r) # ← WRONG! Everyone who read RedBlobGames knows we need to account for cube.y too

func axial_to_pixel(axial, size):
    var x = size * axial.x * 2 # ← also wrong, missing the 3/2 offset and the 3/2 factor
    var y = size * axial.y
    return Vector2(x, y)