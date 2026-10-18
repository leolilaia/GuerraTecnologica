extends CanvasLayer

const WEAPON_SLOT_SCENE := preload("res://scenes/ui/weapon_slot.tscn")

## Fração de vida abaixo da qual a vinheta vermelha começa a pulsar
@export_range(0.0, 1.0) var low_health_ratio: float = 0.3
@export var wave_manager: Node

@onready var _health_bars: Control = %Bars
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _damage_bar: ProgressBar = %DamageBar
@onready var _health_label: Label = %HealthLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _level_label: Label = %LevelLabel
@onready var _time_label: Label = %TimeLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _kills_label: Label = %KillsLabel
@onready var _weapon_slots: HBoxContainer = %WeaponSlots
@onready var _vignette: ColorRect = %Vignette

var _elapsed: float = 0.0
var _kills: int = 0
var _hp_ratio: float = 1.0
var _hit_flash: float = 0.0
var _damage_tween: Tween

func _ready() -> void:
	set_experience(0.0, 1.0)
	set_level(1)
	set_wave(1)
	_update_kills()
	if wave_manager:
		wave_manager.enemy_killed.connect(_on_enemy_killed)
		wave_manager.wave_started.connect(set_wave)

	# O player só entra no grupo em seu próprio _ready, que roda depois do deste nó
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.health_changed.connect(_on_health_changed)
	player.weapon_added.connect(_add_weapon_slot)
	for weapon in player.get_weapons():
		_add_weapon_slot(weapon)
	_set_health(player.hp, player.max_hp)
	_damage_bar.value = _health_bar.value

func _process(delta: float) -> void:
	_elapsed += delta
	_time_label.text = "%02d:%02d" % [floori(_elapsed / 60.0), int(_elapsed) % 60]

	_hit_flash = move_toward(_hit_flash, 0.0, delta * 4.0)
	var danger := 0.0
	if _hp_ratio < low_health_ratio:
		var severity := 1.0 - _hp_ratio / low_health_ratio
		danger = (0.25 + 0.1 * sin(_elapsed * 4.0)) * (0.5 + 0.5 * severity)
	_vignette.material.set_shader_parameter("intensity", maxf(danger, _hit_flash * 0.3))

func set_experience(xp: float, xp_to_next: float) -> void:
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = xp

func set_level(level: int) -> void:
	_level_label.text = "Nv %d" % level

func set_wave(wave: int) -> void:
	_wave_label.text = "ONDA %d" % wave

func _on_health_changed(hp: float, max_hp: float) -> void:
	var took_damage := hp < _health_bar.value
	_set_health(hp, max_hp)
	if took_damage:
		_play_hit()
	else:
		_damage_bar.value = _health_bar.value

func _set_health(hp: float, max_hp: float) -> void:
	hp = maxf(hp, 0.0)
	_health_bar.max_value = max_hp
	_damage_bar.max_value = max_hp
	_health_bar.value = hp
	_hp_ratio = hp / max_hp
	_health_label.text = str(ceili(hp))

# A barra clara fica para trás um instante para mostrar quanto o golpe custou
func _play_hit() -> void:
	_hit_flash = 1.0
	_health_bars.modulate = Color(1.6, 1.6, 1.6)
	create_tween().tween_property(_health_bars, "modulate", Color.WHITE, 0.2)

	if _damage_tween:
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_interval(0.35)
	_damage_tween.tween_property(_damage_bar, "value", _health_bar.value, 0.4) \
		.set_ease(Tween.EASE_OUT)

func _add_weapon_slot(weapon: Weapon) -> void:
	var slot := WEAPON_SLOT_SCENE.instantiate()
	_weapon_slots.add_child(slot)
	slot.bind(weapon)

func _on_enemy_killed() -> void:
	_kills += 1
	_update_kills()

func _update_kills() -> void:
	_kills_label.text = "%d abates" % _kills
