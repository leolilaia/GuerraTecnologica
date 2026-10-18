extends Node

signal level_started(level: int)
signal wave_started(wave: int)
signal boss_defeated(level: int)
signal enemy_killed
signal game_won

@export var wave_duration: float = 15.0
@export var spawn_radius: float = 600.0
@export var start_level: int = 1
@export var test_boss_now: bool = false    # só para teste: pula as waves e vai direto ao boss
@export var heal_after_boss: float = 30.0
@export var enemy_scenes: Dictionary[String, PackedScene] = {}
@export var default_enemy: PackedScene

# Um bloco por fase. Para cortar uma fase, apague a linha.
var levels: Array[Dictionary] = [
	{"waves": 5, "boss": "boss_smartphone", "enemies": ["smartwatch", "celular"], "interval": 0.8, "hp_mult": 1.0},
	{"waves": 5, "boss": "boss_laptop", "enemies": ["celular", "robo", "microondas"], "interval": 0.65, "hp_mult": 1.4},
	{"waves": 5, "boss": "boss_desktop", "enemies": ["robo", "microondas", "celular", "smartwatch"], "interval": 0.5, "hp_mult": 1.8},
]

var level: int = 0
var wave: int = 0
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var busy: bool = false          # true entre o fim de uma fase e o começo da outra

# Estado do duelo com o boss
var in_boss_fight: bool = false
var fight_center: Vector2
var fight_half_size: Vector2
var fight_camera: Camera2D
var camera_offset: Vector2

func _ready() -> void:
	# Espera a arena e o PlayerSpawner terminarem de montar a cena
	await get_tree().process_frame
	while get_tree().get_first_node_in_group("player") == null:
		await get_tree().process_frame
	_begin_level(start_level)

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or in_boss_fight or busy:
		return
	var cfg: Dictionary = levels[level - 1]

	spawn_timer += delta
	if spawn_timer >= cfg["interval"]:
		spawn_timer = 0.0
		_spawn(cfg["enemies"].pick_random(), player, cfg["hp_mult"])

	wave_timer += delta
	if wave_timer >= wave_duration:
		if wave >= cfg["waves"]:
			_start_boss_fight(cfg["boss"])
		else:
			_next_wave()

func _physics_process(_delta: float) -> void:
	if not in_boss_fight:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	# Prende o jogador dentro da tela durante o duelo
	player.global_position = Vector2(
		clampf(player.global_position.x, fight_center.x - fight_half_size.x, fight_center.x + fight_half_size.x),
		clampf(player.global_position.y, fight_center.y - fight_half_size.y, fight_center.y + fight_half_size.y))

func _begin_level(n: int) -> void:
	level = clampi(n, 1, levels.size())
	wave = 0
	busy = false
	level_started.emit(level)
	get_tree().call_group("world", "set_floor", level - 1)
	_show_banner("FASE %d" % level)
	if test_boss_now:
		_start_boss_fight(levels[level - 1]["boss"])
	else:
		_next_wave()

func _next_wave() -> void:
	wave += 1
	wave_timer = 0.0
	spawn_timer = 0.0
	wave_started.emit(wave)
	print("Fase ", level, " - wave ", wave)

func _spawn(enemy_name: String, player: Node2D, hp_mult: float = 1.0) -> Node2D:
	var scene: PackedScene = enemy_scenes.get(enemy_name, default_enemy)
	if scene == null:
		push_warning("Sem cena para o inimigo '%s'" % enemy_name)
		return null
	var enemy := scene.instantiate() as Node2D
	if "hp" in enemy:
		enemy.hp *= hp_mult
	if "xp_value" in enemy:
		enemy.xp_value *= hp_mult
	enemy.died.connect(enemy_killed.emit)
	get_parent().add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * spawn_radius
	return enemy

func _start_boss_fight(boss_name: String) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	fight_camera = get_viewport().get_camera_2d()
	if not enemy_scenes.has(boss_name) or fight_camera == null:
		push_warning("Boss '%s' indisponível (não cadastrado ou sem câmera): pulando" % boss_name)
		_on_boss_defeated()
		return
	var boss := enemy_scenes[boss_name].instantiate() as Node2D
	if not boss.has_method("begin_fight"):
		push_warning("A cena '%s' não usa o boss_base.gd: pulando" % boss_name)
		boss.queue_free()
		_on_boss_defeated()
		return

	# 1. Limpa a tela
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()

	# 2. Trava a câmera onde o jogador está
	camera_offset = fight_camera.position
	var view := get_viewport().get_visible_rect().size / fight_camera.zoom
	fight_half_size = view / 2.0 - Vector2(24, 24)
	fight_center = player.global_position
	fight_camera.top_level = true
	fight_camera.global_position = fight_center

	# 3. Cria o boss no topo da tela
	get_parent().add_child(boss)
	boss.global_position = fight_center + Vector2(0, -fight_half_size.y * 0.75)
	boss.begin_fight(fight_center, fight_half_size)
	boss.defeated.connect(_on_boss_defeated)
	boss.died.connect(enemy_killed.emit)
	in_boss_fight = true

func _on_boss_defeated() -> void:
	in_boss_fight = false
	busy = true
	get_tree().call_group("enemy_projectiles", "queue_free")
	if fight_camera:
		fight_camera.top_level = false
		fight_camera.position = camera_offset
	boss_defeated.emit(level)
	_heal_player()

	if level >= levels.size():
		_show_banner("VITÓRIA!", 4.0)
		game_won.emit()
		return
	_show_banner("FASE %d CONCLUÍDA!" % level, 2.0)
	await get_tree().create_timer(2.5, false).timeout
	_begin_level(level + 1)

func _heal_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not ("hp" in player) or not ("max_hp" in player):
		return
	player.hp = minf(player.hp + heal_after_boss, player.max_hp)
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.hp, player.max_hp)

# Aviso grande no centro da tela, criado por código (não mexe em nenhuma cena)
func _show_banner(text: String, seconds: float = 2.0) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var label := Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	layer.add_child(label)
	add_child(layer)
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(layer.queue_free)
