# Base.gd
extends Sala

const MAPA_1 := "res://scenes/main/main_arena.tscn"

const PORTAL_SCENE := preload("res://scenes/mapas/BASE/interativos/Portal.tscn")
const GUIA_SCENE := preload("res://scenes/mapas/BASE/interativos/Guia.tscn")
const ESTATUA_SCENE := preload("res://scenes/mapas/BASE/interativos/Estatua.tscn")

## Arraste a FundoHacker.tscn aqui, no Inspetor da Base
@export var fundo_hacker: PackedScene

var _jogador: Node2D


func _ready() -> void:
	super._ready()

	# Só acontece ao rodar a Base direto com F6 (sem passar pelo menu)
	if SavedData.slot_atual < 0:
		SavedData.carregar_slot(0)

	if fundo_hacker:
		add_child(fundo_hacker.instantiate())   # CanvasLayer -10: fica atrás de tudo
	else:
		push_warning("Base: o campo 'Fundo Hacker' está vazio no Inspetor")

	_spawnar_jogador()

	_spawn(PORTAL_SCENE, "PortalPos", {"destino": MAPA_1, "conta_como_partida": true})
	_spawn(GUIA_SCENE, "GuiaPos")
	_spawn(ESTATUA_SCENE, "EstatuaAdaPos", {"personagem_id": "ada"})
	_spawn(ESTATUA_SCENE, "EstatuaTuringPos", {"personagem_id": "turing"})
	_spawn(ESTATUA_SCENE, "EstatuaHedyPos", {"personagem_id": "hedy"})
	# TotemPos: entra num próximo passo

	if not SavedData.personagem_mudou.is_connected(_trocar_jogador):
		SavedData.personagem_mudou.connect(_trocar_jogador)


func _spawnar_jogador() -> void:
	var marker := get_node_or_null("JogadorSpawnsPos") as Marker2D
	if marker == null:
		push_warning("JogadorSpawnsPos não encontrado")
		return
	_jogador = Catalogo.criar_jogador(SavedData.personagem_atual())
	if _jogador == null:
		return
	add_child(_jogador)
	_jogador.global_position = marker.global_position


# Quando o jogador seleciona outro personagem numa estátua
func _trocar_jogador(id: String) -> void:
	var marker := get_node_or_null("JogadorSpawnsPos") as Marker2D
	var pos := marker.global_position if marker else Vector2.ZERO
	if _jogador:
		pos = _jogador.global_position
		_jogador.queue_free()
	_jogador = Catalogo.criar_jogador(id)
	if _jogador == null:
		return
	add_child(_jogador)
	_jogador.global_position = pos


# Instancia uma cena na posição de um Marker2D
func _spawn(cena: PackedScene, marker_nome: String, props: Dictionary = {}) -> Node2D:
	var marker := get_node_or_null(marker_nome) as Marker2D
	if marker == null:
		push_warning("Marker não encontrado: " + marker_nome)
		return null
	var n := cena.instantiate() as Node2D
	for k in props:
		n.set(k, props[k])   # define antes de entrar na árvore
	add_child(n)
	n.global_position = marker.global_position
	return n
