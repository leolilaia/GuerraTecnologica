extends CanvasLayer

const SELECAO_SAVE_SCENE := "res://scenes/ui/SelecaoSave.tscn"
const CONFIG_SCENE := "res://scenes/ui/Configuracoes.tscn"

@onready var botao_jogar: Button = $Layout/Conteudo/Botoes/BotaoJogar
@onready var botao_configuracoes: Button = $Layout/Conteudo/Botoes/BotaoConfiguracoes
@onready var botao_sair: Button = $Layout/Conteudo/Botoes/BotaoSair

var botoes: Array[Button]


func _ready() -> void:
	SavedData.encerrar_sessao()   # salva e para o tempo de jogo
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	AudioManager.play_background_music()
	botoes = [botao_jogar, botao_configuracoes, botao_sair]
	_configure_mouse_buttons()
	botao_jogar.grab_focus()


func _configure_mouse_buttons() -> void:
	for botao in botoes:
		botao.mouse_filter = Control.MOUSE_FILTER_STOP
		botao.focus_mode = Control.FOCUS_ALL
		botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not botao.mouse_entered.is_connected(botao.grab_focus):
			botao.mouse_entered.connect(botao.grab_focus)


func _on_botao_jogar_pressed() -> void:
	SceneTransistor.start_transition_to(SELECAO_SAVE_SCENE)


func _on_botao_configuracoes_pressed() -> void:
	SceneTransistor.start_transition_to(CONFIG_SCENE)


func _on_botao_sair_pressed() -> void:
	SettingsManager.save_settings()
	get_tree().quit()
