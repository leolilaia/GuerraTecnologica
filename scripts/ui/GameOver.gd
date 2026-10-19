# GameOver.gd
extends Control

const BASE_SCENE := "res://scenes/mapas/BASE/Base.tscn"
const MENU_SCENE := "res://scenes/ui/MenuPrincipal.tscn"

@onready var botao_base: Button = find_child("BotaoBase", true, false)
@onready var botao_menu: Button = find_child("BotaoMenu", true, false)
@onready var label_abates: Label = find_child("Abates", true, false)
@onready var label_pontos: Label = find_child("Pontos", true, false)
@onready var label_tempo: Label = find_child("Tempo", true, false)

var saindo := false


func _ready() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	AudioManager.play_background_music()

	label_abates.text = "INIMIGOS DERROTADOS: %d" % SavedData.run_abates
	label_pontos.text = "BYTES GANHOS: %d" % SavedData.run_pontos
	label_tempo.text = "TEMPO: %s" % SavedData.formatar_tempo(SavedData.tempo_da_run())

	_configurar_botao(botao_base, _voltar_a_base)
	_configurar_botao(botao_menu, _voltar_ao_menu)
	botao_base.grab_focus()


func _configurar_botao(botao: Button, acao: Callable) -> void:
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.focus_mode = Control.FOCUS_ALL
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.mouse_entered.connect(botao.grab_focus)
	botao.pressed.connect(acao)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_voltar_ao_menu()
		get_viewport().set_input_as_handled()


func _voltar_a_base() -> void:
	_ir(BASE_SCENE)


func _voltar_ao_menu() -> void:
	_ir(MENU_SCENE)


func _ir(destino: String) -> void:
	if saindo:
		return
	saindo = true
	botao_base.disabled = true
	botao_menu.disabled = true
	print("GameOver: indo para ", destino)

	# Plano B: se a transição não trocar a cena, troca direto
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 2.0
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(t)   # o Timer some junto com a cena, sem gerar erro
	t.timeout.connect(func():
		push_warning("SceneTransistor não trocou a cena, usando change_scene_to_file")
		get_tree().change_scene_to_file(destino)
	)
	t.start()

	SceneTransistor.start_transition_to(destino)
