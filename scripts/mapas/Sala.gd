# Sala.gd
class_name Sala
extends Node2D

signal sala_limpa

const GRUPO_JOGADOR := "player"

@export var boss_room: bool = false
@export var inimigos_cenas: Array[PackedScene] = []   # inimigos comuns da sala
@export var boss_cena: PackedScene                    # usado se boss_room = true
@export var efeito_spawn: PackedScene                 # opcional (explosão ao nascer)
@export_file("*.tscn") var cena_final: String = ""    # opcional (tela de vitória)
@export var min_inimigos: int = 4
@export var max_inimigos: int = 8

var num_enemies: int = 0
var fila_de_spawn: Array = []
var markers_disponiveis: Array = []
var final_triggered: bool = false

# Todos opcionais: a Base e mapas sem portas funcionam normalmente
@onready var entrance: Node2D = get_node_or_null("Entrada")
@onready var door_container: Node2D = get_node_or_null("Portas")
@onready var enemy_position_container: Node2D = get_node_or_null("InimigosPosicao")
@onready var player_detector: Area2D = get_node_or_null("JogadorDetector")


func _ready() -> void:
	if entrance:
		for door in entrance.get_children():
			if door.has_method("set_open_instant"):
				door.set_open_instant()
	if door_container:
		for door in door_container.get_children():
			if door.has_method("set_closed_instant"):
				door.set_closed_instant()
	if player_detector and not player_detector.body_entered.is_connected(_on_jogador_detector_body_entered):
		player_detector.body_entered.connect(_on_jogador_detector_body_entered)


func _on_enemy_killed() -> void:
	if not is_inside_tree():
		return
	num_enemies -= 1
	if num_enemies <= 0 and fila_de_spawn.is_empty():
		sala_limpa.emit()
		if boss_room:
			_trigger_final()
		else:
			_open_doors()


func _trigger_final() -> void:
	if final_triggered or cena_final.is_empty():
		return
	final_triggered = true
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		SceneTransistor.start_transition_to(cena_final)


func _open_doors() -> void:
	if door_container:
		for door in door_container.get_children():
			if door.has_method("open"):
				door.open()
	if entrance:
		for door in entrance.get_children():
			if door.has_method("open"):
				door.open()
	var pai = get_parent()
	if pai is Sala:
		pai._open_doors()


func _close_entrance() -> void:
	if entrance:
		for door in entrance.get_children():
			if door.has_method("close"):
				door.close()


func _iniciar_onda() -> void:
	var total := 1 if boss_room else randi_range(min_inimigos, max_inimigos)
	for i in range(total):
		fila_de_spawn.append(true)
	_processar_fila_spawn()


func _processar_fila_spawn() -> void:
	var batch_size := 1 if boss_room else 2
	while fila_de_spawn.size() > 0 and batch_size > 0:
		fila_de_spawn.pop_back()
		_spawnar_um_inimigo()
		batch_size -= 1
	if fila_de_spawn.size() > 0:
		await get_tree().create_timer(3.0).timeout
		if is_inside_tree():
			_processar_fila_spawn()


func _proximo_marker() -> Node2D:
	if enemy_position_container == null:
		return null
	if markers_disponiveis.is_empty():
		markers_disponiveis = enemy_position_container.get_children().duplicate()
		markers_disponiveis.shuffle()
	if markers_disponiveis.is_empty():
		return null
	return markers_disponiveis.pop_back()


func _spawnar_um_inimigo() -> void:
	var marker := _proximo_marker()
	if marker == null:
		return

	var cena: PackedScene = null
	if boss_room:
		cena = boss_cena
	elif not inimigos_cenas.is_empty():
		cena = inimigos_cenas.pick_random()
	if cena == null:
		push_warning("Sala sem cena de inimigo configurada no Inspetor")
		return

	var enemy := cena.instantiate() as CharacterBody2D
	var collision := enemy.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true
	if enemy.has_signal("inimigo_morto"):
		enemy.inimigo_morto.connect(_on_enemy_killed)

	add_child(enemy)
	enemy.global_position = marker.global_position
	num_enemies += 1

	if collision:
		collision.set_deferred("disabled", false)

	if efeito_spawn:
		var fx := efeito_spawn.instantiate() as Node2D
		add_child(fx)
		fx.global_position = marker.global_position


func _on_jogador_detector_body_entered(body: Node) -> void:
	if not body.is_in_group(GRUPO_JOGADOR):
		return
	if is_instance_valid(player_detector):
		player_detector.queue_free()
	if (enemy_position_container and enemy_position_container.get_child_count() > 0) or boss_room:
		_close_entrance()
		_iniciar_onda()
	else:
		_open_doors()
