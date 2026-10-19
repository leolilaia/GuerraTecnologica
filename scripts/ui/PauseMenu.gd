extends CanvasLayer
const CONFIGURACOES_SCENE: PackedScene = preload("res://scenes/ui/Configuracoes.tscn")

@onready var botao_pausar: Button = $Scaler/BotaoPausar
@onready var overlay: ColorRect = $Scaler/Overlay
@onready var painel_pausa: Control = $Scaler/Overlay/Centro/Painel
@onready var botao_continuar: Button = $Scaler/Overlay/Centro/Painel/Conteudo/Botoes/BotaoContinuar
@onready var botao_menu: Button = $Scaler/Overlay/Centro/Painel/Conteudo/Botoes/BotaoMenuPrincipal

var configuracoes_instance: Control = null
# 🔥 NOVO: referência pro TutorialOverlay (é irmão, não filho, dentro de Jogo.tscn)
var tutorial_overlay: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2
	overlay.visible = false

	tutorial_overlay = get_tree().current_scene.get_node_or_null("TutorialOverlay")
	if tutorial_overlay and not tutorial_overlay.fechado.is_connected(_on_tutorial_fechado):
		tutorial_overlay.fechado.connect(_on_tutorial_fechado)

	_configure_mouse_button(botao_pausar)
	_configure_mouse_button(botao_continuar)
	_configure_mouse_button(botao_menu)

func _configure_mouse_button(botao: Button) -> void:
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.focus_mode = Control.FOCUS_ALL
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.mouse_entered.connect(botao.grab_focus)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# Jogo pausado por outra tela (escolha de upgrade): o ESC não pode despausar
		if get_tree().paused and not overlay.visible:
			return
		var tutorial_ui := get_tree().current_scene.get_node_or_null("TutorialOverlay/Overlay")
		if tutorial_ui and tutorial_ui.visible:
			# 🔥 Se foi aberto pelo botão do pause, ESC fecha ele e volta pro pause.
			if tutorial_overlay and tutorial_overlay.aberto_pelo_pause:
				tutorial_overlay.overlay.hide()
				tutorial_overlay.aberto_pelo_pause = false
				_on_tutorial_fechado()
				get_viewport().set_input_as_handled()
			return
		if configuracoes_instance and is_instance_valid(configuracoes_instance):
			_fechar_configuracoes()
			get_viewport().set_input_as_handled()
			return
		toggle_pause()
		get_viewport().set_input_as_handled()

func _on_botao_pausar_pressed() -> void:
	toggle_pause()

func _on_botao_continuar_pressed() -> void:
	set_pause_state(false)

func _on_botao_configuracoes_pressed() -> void:
	if configuracoes_instance and is_instance_valid(configuracoes_instance):
		return
	configuracoes_instance = CONFIGURACOES_SCENE.instantiate()
	configuracoes_instance.modo_overlay = true
	configuracoes_instance.fechado.connect(_fechar_configuracoes)
	painel_pausa.hide()
	$Scaler.add_child(configuracoes_instance)

func _fechar_configuracoes() -> void:
	if configuracoes_instance and is_instance_valid(configuracoes_instance):
		configuracoes_instance = null
	painel_pausa.show()
	botao_continuar.grab_focus()

# 🔥 NOVO: abre o tutorial por cima do pause
func _on_botao_tutorial_pressed() -> void:
	if tutorial_overlay == null:
		return
	painel_pausa.hide()
	tutorial_overlay.abrir_pelo_pause()

# 🔥 NOVO: chamado quando o tutorial (aberto pelo pause) termina
func _on_tutorial_fechado() -> void:
	painel_pausa.show()
	botao_continuar.grab_focus()

func _on_botao_menu_principal_pressed() -> void:
	set_pause_state(false)
	AudioManager.play_background_music()
	SceneTransistor.start_transition_to("res://scenes/ui/MenuPrincipal.tscn")

func toggle_pause() -> void:
	set_pause_state(not get_tree().paused)

func set_pause_state(paused: bool) -> void:
	get_tree().paused = paused
	AudioManager.set_music_paused(paused)
	overlay.visible = paused
	botao_pausar.visible = not paused
	if paused:
		botao_continuar.grab_focus()
