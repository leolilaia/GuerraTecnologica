extends Node2D

@export var player: Node2D
@export var floor_layer: TileMapLayer
@export var props_layer: TileMapLayer

@export var render_distance: int = 25
@export var prop_spawn_chance: float = 0.03

# Cores fortes para diferenciar bem cada fase:
# Fase 1: Branco (Normal) | Fase 2: Ciano Neon | Fase 3: Roxo/Magenta | Fase 4 (IA): Vermelho Matrix
const LEVEL_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),    # Fase 1 (index 0)
	Color(0.35, 0.85, 1.0),  # Fase 2 (index 1)
	Color(0.85, 0.45, 1.0),  # Fase 3 (index 2)
	Color(1.0, 0.30, 0.35),  # Fase 4 - Boss Final IA (index 3)
	Color(0.35, 1.0, 0.55)   # Extra se houver Fase 5
]

var generated_cells: Dictionary = {}
var last_player_tile: Vector2i = Vector2i.ZERO
var floor_source_id: int = 0

func _ready() -> void:
	# Obrigatório pelo contrato com o WaveManager:
	add_to_group("world")
	
	if floor_layer == null and has_node("TileMapLayer"):
		floor_layer = $TileMapLayer
		
	if floor_layer and floor_layer.tile_set and floor_layer.tile_set.get_source_count() > 0:
		floor_source_id = floor_layer.tile_set.get_source_id(0)
	
	if player == null and get_parent():
		player = get_parent().find_child("Player", true, false)
		
	_update_world_chunks()

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		if get_parent():
			player = get_parent().find_child("Player", true, false)
		return
		
	if floor_layer == null:
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
				floor_layer.set_cell(cell, floor_source_id, Vector2i(0, 0))

# Chamada automaticamente pelo WaveManager a cada início de fase
func set_floor(index: int) -> void:
	if floor_layer == null and has_node("TileMapLayer"):
		floor_layer = $TileMapLayer
	if floor_layer == null:
		return
		
	# 1. Se você tiver mais de uma imagem no TileSet, troca a textura e redesenha
	if floor_layer.tile_set and floor_layer.tile_set.get_source_count() > 1:
		var source_idx = index % floor_layer.tile_set.get_source_count()
		floor_source_id = floor_layer.tile_set.get_source_id(source_idx)
		generated_cells.clear()
		_update_world_chunks()
		
	# 2. Muda a cor do chão com transição de 0.6s (sempre funciona, mesmo com 1 só textura)
	var target_color: Color = LEVEL_TINTS[index % LEVEL_TINTS.size()]
	var tween = create_tween()
	tween.tween_property(floor_layer, "modulate", target_color, 0.6)
	print("[WorldGenerator] Mudou chão para Fase index: ", index, " | Cor: ", target_color)
