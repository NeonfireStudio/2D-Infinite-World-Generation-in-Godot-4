extends CharacterBody2D

const SPEED = 300.0

@onready var tile_map = $"../TileMap"

func _physics_process(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * SPEED
	move_and_slide()
	
	var tile = tile_map.local_to_map(get_global_mouse_position())
	
	#Breaking Tiles
	if Input.is_action_pressed("mouse_left"):
		if tile_map.get_cell_atlas_coords(1, tile) == Vector2i(0, 1):
			tile_map.set_cell(1, tile, 0, Vector2i(-1, -1))
			tile_map.set_cell(1, tile - Vector2i(0, 1), 0, Vector2i(-1, -1))
			get_parent().object_tiles_position["0"].remove_at(get_parent().object_tiles_position["0"].find(tile, 0))
		elif tile_map.get_cell_atlas_coords(1, tile) == Vector2i(1, 1):
			tile_map.set_cell(1, tile, 0, Vector2i(-1, -1))
			get_parent().object_tiles_position["1"].remove_at(get_parent().object_tiles_position["1"].find(tile, 0))
		elif tile_map.get_cell_atlas_coords(1, tile) == Vector2i(2, 1):
			tile_map.set_cell(1, tile, 0, Vector2i(-1, -1))
			get_parent().object_tiles_position["2"].remove_at(get_parent().object_tiles_position["2"].find(tile, 0))
		else:
			if get_parent().other_tiles_position["0"].find(tile, 0) != -1:
				tile_map.set_cell(2, tile, 0, Vector2i(-1, -1))
				get_parent().other_tiles_position["0"].remove_at(get_parent().other_tiles_position["0"].find(tile, 0))
	
	#Placing Tiles
	elif Input.is_action_pressed("mouse_right"):
		if tile_map.get_cell_atlas_coords(1, tile) == Vector2i(-1, -1) and get_parent().other_tiles_position["0"].find(tile, 0) == -1:
			tile_map.set_cell(2, tile, 0, Vector2i(3, 2))
			get_parent().other_tiles_position["0"].append(tile)

