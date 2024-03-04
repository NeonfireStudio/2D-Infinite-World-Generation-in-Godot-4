extends Node2D

@onready var tile_map = $TileMap
@onready var camera = $Camera
@onready var player = $Player

var tile_size = 32
var chunk_size = 34
var view_distance = 16

var noise = FastNoiseLite.new()

var grass_atlas_position = Vector2i(0, 2)
var dirt_atlas_position = Vector2i(2, 2)
var water_atlas_position = Vector2i(1, 2)

var object_placed_range = Rect2()
var object_tiles_position = {
	"0": PackedVector2Array(),
	"1": PackedVector2Array(),
	"2": PackedVector2Array()
}

var other_tiles_position = {
	"0": PackedVector2Array()
}

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.03
	noise.domain_warp_amplitude = 1.0
	
	view_distance = (chunk_size / 2) - 1
	load_chunk(0, 0)
	player.position = Vector2((chunk_size * tile_size) / 2, (chunk_size * tile_size) / 2)

func load_chunk(x, y):
	tile_map.clear()
	
	for _x in range(chunk_size):
		for _y in range(chunk_size):
			var current_tile_position = Vector2i(_x+x, _y+y)
			var atlas_position = Vector2i()
			var id = noise.get_noise_2d(_x+x, _y+y)
			
			if id < -0.15:
				atlas_position = water_atlas_position
			elif id > 0.2:
				atlas_position = dirt_atlas_position
			else:
				atlas_position = grass_atlas_position
			
			if tile_map.get_cell_source_id(0, current_tile_position) == -1:
				tile_map.set_cell(0, current_tile_position, 0, atlas_position)
			
			#Object Placement
			if randi() % 25 == 0:
				if !object_placed_range.has_point(current_tile_position):
					for i in object_tiles_position:
						match i:
							"0":
								if randi() % 2 == 0 and atlas_position.x == 0:
									object_tiles_position[i].append(current_tile_position)
									break
							"1":
								if atlas_position.x == 0:
									object_tiles_position[i].append(current_tile_position)
									break
							"2":
								if atlas_position.x == 2:
									object_tiles_position[i].append(current_tile_position)
			
	if !object_placed_range.has_point(tile_map.get_used_rect().position) or !object_placed_range.has_point(tile_map.get_used_rect().end):
		object_placed_range = object_placed_range.merge(tile_map.get_used_rect())
		
	for t in object_tiles_position:
		match t:
			"0":
				for tp in range(object_tiles_position[t].size()):
					if tile_map.get_cell_source_id(0, Vector2i(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y)) != -1 or tile_map.get_cell_source_id(0, Vector2i(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y+1)) == -1:
						draw_tree(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y)
			"1":
				for tp in range(object_tiles_position[t].size()):
					if tile_map.get_cell_source_id(0, Vector2i(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y)) != -1:
						draw_bush(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y)
			"2":
				for tp in range(object_tiles_position[t].size()):
					if tile_map.get_cell_source_id(0, Vector2i(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y)) != -1:
						draw_rock(object_tiles_position[t][tp].x, object_tiles_position[t][tp].y)
	
	for ot in other_tiles_position:
		match ot:
			"0":
				for op in range(other_tiles_position[ot].size()):
					if tile_map.get_cell_source_id(0, other_tiles_position[ot][op]) != -1:
						tile_map.set_cell(2, other_tiles_position[ot][op], 0, Vector2i(3, 2))

func _physics_process(_delta):
	camera.position = player.position
	
	#Chunk Loading/Unloading
	var world_size = tile_map.get_used_rect() as Rect2i
	var world_size_start = world_size.position
	var world_size_end = world_size.end
	var player_position_positive = (player.position / tile_size) + Vector2(view_distance, view_distance)
	var player_position_negative = (player.position / tile_size) - Vector2(view_distance, view_distance)
	
	if player_position_positive.x > world_size_end.x:
		load_chunk(world_size_start.x+1, world_size_start.y)
	elif player_position_negative.x < world_size_start.x:
		load_chunk(world_size_start.x-1, world_size_start.y)
	if player_position_positive.y > world_size_end.y:
		load_chunk(world_size_start.x, world_size_start.y+1)
	elif player_position_negative.y < world_size_start.y:
		load_chunk(world_size_start.x, world_size_start.y-1)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom += Vector2(0.05, 0.05)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom -= Vector2(0.05, 0.05)

func draw_tree(x, y):
	if tile_map.get_cell_source_id(0, Vector2i(x, y-1)) != -1:
		tile_map.set_cell(1, Vector2i(x, y-1), 0, Vector2i(0, 0))
	if tile_map.get_cell_source_id(0, Vector2i(x, y)) != -1:
		tile_map.set_cell(1, Vector2i(x, y), 0, Vector2i(0, 1))
	
	if tile_map.get_cell_atlas_coords(1, Vector2i(x, y-2)) == Vector2i(0, 0):
		tile_map.erase_cell(1, Vector2i(x, y-2))

func draw_bush(x, y):
	if tile_map.get_cell_source_id(0, Vector2i(x, y)) != -1 and tile_map.get_cell_source_id(1, Vector2i(x, y)) == -1:
		tile_map.set_cell(1, Vector2(x, y), 0, Vector2i(1, 1))

func draw_rock(x, y):
	if tile_map.get_cell_source_id(0, Vector2i(x, y)) != -1 and tile_map.get_cell_source_id(1, Vector2i(x, y)) == -1:
		tile_map.set_cell(1, Vector2(x, y), 0, Vector2i(2, 1))

