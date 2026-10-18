extends Node2D

@export var player: Node2D
@export var floor_layer: TileMapLayer

@export var render_distance: int = 25

var generated_cells: Dictionary = {}
var last_player_tile: Vector2i = Vector2i.ZERO
var floor_source_id: int = 0

func _ready() -> void:
	add_to_group("world")
	if floor_layer == null and has_node("TileMapLayer"):
		floor_layer = $TileMapLayer

	if floor_layer and floor_layer.tile_set and floor_layer.tile_set.get_source_count() > 0:
		floor_source_id = floor_layer.tile_set.get_source_id(0)

	if player == null and get_parent():
		# O player ainda não entrou no grupo: este _ready roda antes do dele
		player = get_parent().find_child("Player", true, false) as Node2D

	if is_instance_valid(player) and floor_layer:
		last_player_tile = floor_layer.local_to_map(player.global_position)

	_update_world_chunks()

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or floor_layer == null:
		return

	var current_tile := floor_layer.local_to_map(player.global_position)
	if current_tile != last_player_tile:
		last_player_tile = current_tile
		_update_world_chunks()

func _update_world_chunks() -> void:
	if floor_layer == null:
		return

	for x in range(last_player_tile.x - render_distance, last_player_tile.x + render_distance):
		for y in range(last_player_tile.y - render_distance, last_player_tile.y + render_distance):
			var cell := Vector2i(x, y)
			if not generated_cells.has(cell):
				generated_cells[cell] = true
				floor_layer.set_cell(cell, floor_source_id, Vector2i.ZERO)
				
const LEVEL_TINTS := [Color.WHITE, Color(0.75, 0.85, 1.0), Color(1.0, 0.8, 0.8), Color(0.8, 1.0, 0.85), Color(0.85, 0.75, 1.0)]

func set_floor(index: int) -> void:
	if floor_layer == null:
		return
	var ts := floor_layer.tile_set
	if ts != null and index < ts.get_source_count():
		floor_source_id = ts.get_source_id(index)
		generated_cells.clear()
		floor_layer.clear()
		_update_world_chunks()
	floor_layer.modulate = LEVEL_TINTS[index % LEVEL_TINTS.size()]
