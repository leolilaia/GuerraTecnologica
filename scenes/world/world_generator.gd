extends Node2D

@export var player: Node2D
@export var floor_layer: TileMapLayer
@export var props_layer: TileMapLayer

@export var render_distance: int = 25
@export var prop_spawn_chance: float = 0.03

var generated_cells: Dictionary = {}
var last_player_tile: Vector2i = Vector2i.ZERO
var floor_source_id: int = 0

func _ready() -> void:
	# 1. Pega o TileMapLayer automaticamente se você não tiver arrastado no Inspetor
	if floor_layer == null and has_node("TileMapLayer"):
		floor_layer = $TileMapLayer
		
	# 2. Descobre sozinho qual é o ID (0, 1, 2...) da sua imagem Branco.png no TileSet
	if floor_layer and floor_layer.tile_set and floor_layer.tile_set.get_source_count() > 0:
		floor_source_id = floor_layer.tile_set.get_source_id(0)
	
	# 3. Procura o Player automaticamente na MainArena se não estiver conectado
	if player == null and get_parent():
		player = get_parent().find_child("Player", true, false)
		
	# 4. Começa gerando na posição real do Player (ou no centro 0,0)
	if is_instance_valid(player) and floor_layer:
		last_player_tile = floor_layer.local_to_map(player.global_position)
	else:
		last_player_tile = Vector2i.ZERO
		
	_update_world_chunks()

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or floor_layer == null:
		return
	
	var current_tile: Vector2i = floor_layer.local_to_map(player.global_position)
	if current_tile != last_player_tile:
		last_player_tile = current_tile
		_update_world_chunks()

func _update_world_chunks() -> void:
	if floor_layer == null:
		return
		
	for x in range(last_player_tile.x - render_distance, last_player_tile.x + render_distance):
		for y in range(last_player_tile.y - render_distance, last_player_tile.y + render_distance):
			var cell = Vector2i(x, y)
			if not generated_cells.has(cell):
				generated_cells[cell] = true
				# Desenha o chão usando o ID descoberto automaticamente
				floor_layer.set_cell(cell, floor_source_id, Vector2i(0, 0))
