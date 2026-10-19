extends Control

const SCROLL_STEP := 32
const MENU_SCENE := "res://scenes/ui/MenuPrincipal.tscn"

var modo_overlay: bool = false
signal fechado

@onready var scroll: ScrollContainer = $Centro/Painel/Scroll
@onready var master_slider: HSlider = $Centro/Painel/Scroll/Conteudo/Audio/Master/Linha/Slider
@onready var master_value: Label = $Centro/Painel/Scroll/Conteudo/Audio/Master/Linha/Valor
@onready var music_slider: HSlider = $Centro/Painel/Scroll/Conteudo/Audio/Musica/Linha/Slider
@onready var music_value: Label = $Centro/Painel/Scroll/Conteudo/Audio/Musica/Linha/Valor
@onready var sfx_slider: HSlider = $Centro/Painel/Scroll/Conteudo/Audio/Efeitos/Linha/Slider
@onready var sfx_value: Label = $Centro/Painel/Scroll/Conteudo/Audio/Efeitos/Linha/Valor
@onready var brightness_slider: HSlider = $Centro/Painel/Scroll/Conteudo/Video/Brilho/Linha/Slider
@onready var brightness_value: Label = $Centro/Painel/Scroll/Conteudo/Video/Brilho/Linha/Valor
@onready var fullscreen_toggle: CheckButton = $Centro/Painel/Scroll/Conteudo/Video/TelaCheia
@onready var resolution_option: OptionButton = $Centro/Painel/Scroll/Conteudo/Video/Resolucao/Linha/Opcoes
@onready var botao_padrao: Button = $Centro/Painel/Scroll/Conteudo/Botoes/BotaoPadrao
@onready var botao_voltar: Button = $Centro/Painel/Scroll/Conteudo/Botoes/BotaoVoltar


func _ready() -> void:
	# AJUSTE 2: só toca a música do menu se NÃO estiver aberto dentro do jogo
	if not modo_overlay:
		AudioManager.play_background_music()

	_configure_mouse_controls()

	resolution_option.clear()
	for i in range(SettingsManager.RESOLUTIONS.size()):
		resolution_option.add_item(SettingsManager.get_resolution_label(i), i)

	_sync_controls()
	master_slider.grab_focus()

	await get_tree().process_frame
	scroll.scroll_vertical = 0
	_configure_scrollbar()


func _configure_mouse_controls() -> void:
	var controls: Array[Control] = [
		master_slider, music_slider, sfx_slider, brightness_slider,
		fullscreen_toggle, resolution_option, botao_padrao, botao_voltar
	]

	for control in controls:
		control.mouse_filter = Control.MOUSE_FILTER_STOP
		control.focus_mode = Control.FOCUS_ALL
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not control.mouse_entered.is_connected(control.grab_focus):
			control.mouse_entered.connect(control.grab_focus)

	master_slider.scrollable = false
	music_slider.scrollable = false
	sfx_slider.scrollable = false
	brightness_slider.scrollable = false

	var conteudo := scroll.get_node_or_null("Conteudo")
	if conteudo:
		conteudo.mouse_filter = Control.MOUSE_FILTER_PASS

	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	scroll.scroll_vertical_custom_step = SCROLL_STEP


func _configure_scrollbar() -> void:
	var vertical_bar := scroll.get_v_scroll_bar()
	vertical_bar.custom_minimum_size.x = 18.0
	vertical_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	vertical_bar.focus_mode = Control.FOCUS_ALL
	vertical_bar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	vertical_bar.custom_step = SCROLL_STEP


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed:
		return
	if not scroll.get_global_rect().has_point(event.position):
		return

	var direction := 0
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		direction = -1
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		direction = 1

	if direction != 0:
		var wheel_amount := maxi(1, int(round(event.factor)))
		scroll.scroll_vertical += direction * SCROLL_STEP * wheel_amount
		get_viewport().set_input_as_handled()


func _sync_controls() -> void:
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	brightness_slider.value = SettingsManager.brightness * 100.0
	fullscreen_toggle.set_pressed_no_signal(SettingsManager.fullscreen)
	resolution_option.select(SettingsManager.resolution_index)
	resolution_option.disabled = SettingsManager.fullscreen
	_update_value_labels()
	_update_toggle_texts()


func _update_value_labels() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	brightness_value.text = "%d%%" % int(round(brightness_slider.value))


func _update_toggle_texts() -> void:
	fullscreen_toggle.text = (
		"TELA CHEIA: ATIVADA" if fullscreen_toggle.button_pressed
		else "TELA CHEIA: DESATIVADA"
	)


func _on_master_value_changed(value: float) -> void:
	SettingsManager.set_master_volume(value / 100.0)
	_update_value_labels()


func _on_music_value_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)
	_update_value_labels()


func _on_sfx_value_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
	_update_value_labels()


func _on_brightness_value_changed(value: float) -> void:
	SettingsManager.set_brightness(value / 100.0)
	_update_value_labels()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)
	resolution_option.disabled = toggled_on
	_update_toggle_texts()


func _on_vsync_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)


func _on_resolution_item_selected(index: int) -> void:
	SettingsManager.set_resolution(index)


func _on_botao_padrao_pressed() -> void:
	SettingsManager.reset_defaults()
	_sync_controls()


func _on_botao_voltar_pressed() -> void:
	SettingsManager.save_settings()
	if modo_overlay:
		fechado.emit()
		queue_free()
	else:
		SceneTransistor.start_transition_to(MENU_SCENE)
