extends Node

signal wave_started(wave: int)
signal game_won

@export var wave_duration: float = 15.0
@export var spawn_radius: float = 600.0
@export var max_wave: int = 50
# Em cada chave, o nome do inimigo; em cada valor, a cena (preencha no Inspetor)
@export var enemy_scenes: Dictionary[String, PackedScene] = {}

var wave: int = 0
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var boss_alive: bool = false

# A partir da wave "from", vale esta configuração
var wave_table: Array[Dictionary] = [
	{"from": 1,  "enemies": ["smartwatch"], "interval": 0.8},
	{"from": 4,  "enemies": ["smartwatch", "celular"], "interval": 0.7},
	{"from": 11, "enemies": ["celular", "bluetooth", "microondas"], "interval": 0.6},
	{"from": 41, "enemies": ["smartwatch", "celular", "bluetooth", "microondas", "robo"], "interval": 0.25}, # fase "todos juntos"
]

# Waves de boss: o cronômetro trava até ele morrer
var boss_waves: Dictionary = {10: "boss_smartphone", 20: "boss_laptop", 30: "boss_desktop", 50: "boss_ia"}

func _ready() -> void:
	_start_wave(1)

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	# Spawn contínuo de inimigos comuns
	var cfg := _current_config()
	spawn_timer += delta
	if spawn_timer >= cfg["interval"]:
		spawn_timer = 0.0
		_spawn(cfg["enemies"].pick_random(), player)

	# Cronômetro da wave (para durante o boss)
	if boss_alive:
		return
	wave_timer += delta
	if wave_timer >= wave_duration:
		if wave >= max_wave:
			game_won.emit()
			set_process(false)
		else:
			_start_wave(wave + 1)

func _start_wave(n: int) -> void:
	wave = n
	wave_timer = 0.0
	wave_started.emit(wave)
	if boss_waves.has(wave):
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var boss := _spawn(boss_waves[wave], player)
		if boss:
			boss_alive = true
			boss.tree_exited.connect(func(): boss_alive = false)

func _current_config() -> Dictionary:
	var result: Dictionary = wave_table[0]
	for entry in wave_table:
		if entry["from"] <= wave:
			result = entry
	return result

@export var default_enemy: PackedScene

func _spawn(enemy_name: String, player: Node2D) -> Node2D:
	if player == null:
		return null
	var scene: PackedScene = enemy_scenes.get(enemy_name, default_enemy)
	if scene == null:
		push_warning("Sem cena para o inimigo '%s'" % enemy_name)
		return null
	var enemy := scene.instantiate() as Node2D
	get_parent().add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * spawn_radius
	return enemy
