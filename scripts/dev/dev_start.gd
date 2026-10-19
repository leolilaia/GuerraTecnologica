extends Node

## Autoload que aplica o dev/dev_start.tres. Só age quando o jogo foi aberto
## pela cena principal (F5): rodar outra cena com F6 continua igual.

const CONFIG_PATH := "res://dev/dev_start.tres"
const ARENA_SCENE := "res://scenes/main/main_arena.tscn"

var _config: DevStartConfig

func _ready() -> void:
	if not OS.has_feature("editor") or not ResourceLoader.exists(CONFIG_PATH):
		return
	_config = load(CONFIG_PATH) as DevStartConfig
	if _config and _config.enabled:
		_start_arena.call_deferred()

func _start_arena() -> void:
	var scene := get_tree().current_scene
	var main_scene := ResourceUID.ensure_path(ProjectSettings.get_setting("application/run/main_scene"))
	if scene == null or scene.scene_file_path != main_scene:
		return

	var arena := (load(ARENA_SCENE) as PackedScene).instantiate()
	var spawner := arena.get_node("PlayerSpawner") as PlayerSpawner
	spawner.use_saved_character = false
	spawner.character = Catalogo.character_data(_config.character_id)
	spawner.player_spawned.connect(_equip)

	var waves := arena.get_node("WaveManager")
	waves.start_level = _config.level
	waves.start_wave = _config.wave
	waves.test_boss_now = _config.boss_now

	print("[DevStart] %s, fase %d, wave %d%s" % [_config.character_id, _config.level, _config.wave,
		" (boss)" if _config.boss_now else ""])
	get_tree().change_scene_to_node(arena)

func _equip(player: Player) -> void:
	for weapon_scene in _config.extra_weapons:
		if weapon_scene:
			player.add_weapon(weapon_scene)
	for weapon in player.get_weapons():
		while weapon.level < _config.weapon_level and not weapon.is_max_level():
			weapon.level_up()
	# Invulnerável sem ninguém para desligar: o take_damage ignora todos os golpes
	player.invulnerable = _config.invincible
