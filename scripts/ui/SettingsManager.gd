extends Node

const SETTINGS_PATH := "user://settings.cfg"
const MIN_BRIGHTNESS := 0.5
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

const DEFAULT_MASTER := 1.0
const DEFAULT_MUSIC := 0.8
const DEFAULT_SFX := 0.8
const DEFAULT_BRIGHTNESS := 1.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_RESOLUTION := 1

var master_volume: float = DEFAULT_MASTER
var music_volume: float = DEFAULT_MUSIC
var sfx_volume: float = DEFAULT_SFX
var brightness: float = DEFAULT_BRIGHTNESS
var fullscreen: bool = DEFAULT_FULLSCREEN
var resolution_index: int = DEFAULT_RESOLUTION

var _brightness_rect: ColorRect
# Tamanho de layout do projeto (640x360, o das telas de menu e da Base)
var _default_layout_size: Vector2i


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_brightness_overlay()
	load_settings()
	apply_all()
	_default_layout_size = get_tree().root.content_scale_size
	get_tree().scene_changed.connect(_apply_scene_layout)
	# A primeira cena não dispara scene_changed
	_apply_scene_layout.call_deferred()


# A arena foi ajustada em 1920x900 e declara isso no metadado "layout_size";
# as demais cenas usam o tamanho do projeto
func _apply_scene_layout() -> void:
	var scene := get_tree().current_scene
	var layout_size := _default_layout_size
	if scene and scene.has_meta("layout_size"):
		layout_size = scene.get_meta("layout_size")
	get_tree().root.content_scale_size = layout_size


func _create_brightness_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_brightness_rect = ColorRect.new()
	_brightness_rect.color = Color(0, 0, 0, 0)
	_brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_brightness_rect)


# ---------- Setters (aplicam na hora) ----------
func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Master", master_volume)

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Music", music_volume)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus("SFX", sfx_volume)

func set_brightness(v: float) -> void:
	brightness = clampf(v, MIN_BRIGHTNESS, 1.0)
	_apply_brightness()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_window()

func set_resolution(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	_apply_window()


# ---------- Aplicação ----------
func apply_all() -> void:
	_apply_bus("Master", master_volume)
	_apply_bus("Music", music_volume)
	_apply_bus("SFX", sfx_volume)
	_apply_brightness()
	_apply_window()


func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func _apply_brightness() -> void:
	_brightness_rect.color = Color(0, 0, 0, 1.0 - brightness)


func _apply_window() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(size)
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_position(area.position + (area.size - size) / 2)


func get_resolution_label(index: int) -> String:
	var r := RESOLUTIONS[index]
	return "%d x %d" % [r.x, r.y]


# ---------- Padrão e persistência ----------
func reset_defaults() -> void:
	master_volume = DEFAULT_MASTER
	music_volume = DEFAULT_MUSIC
	sfx_volume = DEFAULT_SFX
	brightness = DEFAULT_BRIGHTNESS
	fullscreen = DEFAULT_FULLSCREEN
	resolution_index = DEFAULT_RESOLUTION
	apply_all()
	save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(cfg.get_value("audio", "master", DEFAULT_MASTER), 0.0, 1.0)
	music_volume = clampf(cfg.get_value("audio", "music", DEFAULT_MUSIC), 0.0, 1.0)
	sfx_volume = clampf(cfg.get_value("audio", "sfx", DEFAULT_SFX), 0.0, 1.0)
	brightness = clampf(cfg.get_value("video", "brightness", DEFAULT_BRIGHTNESS), MIN_BRIGHTNESS, 1.0)
	fullscreen = cfg.get_value("video", "fullscreen", DEFAULT_FULLSCREEN)
	resolution_index = clampi(cfg.get_value("video", "resolution_index", DEFAULT_RESOLUTION), 0, RESOLUTIONS.size() - 1)
