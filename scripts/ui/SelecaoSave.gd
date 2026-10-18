extends CanvasLayer

const MENU_SCENE := "res://scenes/ui/MenuPrincipal.tscn"
const NOVO_SAVE_SCENE := "res://scenes/mapas/BASE/Base.tscn"
const CONTINUAR_SCENE := "res://scenes/mapas/BASE/Base.tscn"

@onready var slots: VBoxContainer = find_child("Slots", true, false)
@onready var botao_voltar: Button = find_child("BotaoVoltar", true, false)
@onready var confirmacao: ConfirmationDialog = find_child("Confirmacao", true, false)

var _slot_para_reiniciar := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	confirmacao.ok_button_text = "Reiniciar"
	confirmacao.cancel_button_text = "Cancelar"
	confirmacao.confirmed.connect(_on_reinicio_confirmado)
	botao_voltar.pressed.connect(_on_voltar_pressed)
	botao_voltar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao_voltar.mouse_entered.connect(botao_voltar.grab_focus)

	for i in SavedData.SLOT_COUNT:
		var linha := slots.get_child(i)
		var botao_slot: Button = linha.get_node("BotaoSlot")
		var botao_reiniciar: Button = linha.get_node("BotaoReiniciar")
		botao_slot.pressed.connect(_on_slot_pressed.bind(i))
		botao_reiniciar.pressed.connect(_on_reiniciar_pressed.bind(i))
		for b in [botao_slot, botao_reiniciar]:
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.mouse_entered.connect(b.grab_focus)

	_atualizar_slots()
	(slots.get_child(0).get_node("BotaoSlot") as Button).grab_focus()


func _atualizar_slots() -> void:
	for i in SavedData.SLOT_COUNT:
		var linha := slots.get_child(i)
		var botao_slot: Button = linha.get_node("BotaoSlot")
		var botao_reiniciar: Button = linha.get_node("BotaoReiniciar")
		var resumo := SavedData.resumo_slot(i)

		if resumo.is_empty():
			botao_slot.text = "SAVE %d\nVAZIO - CLIQUE PARA COMEÇAR" % (i + 1)
			botao_reiniciar.disabled = true
		else:
			var tempo := SavedData.formatar_tempo(resumo["tempo_jogado"])
			botao_slot.text = "SAVE %d\nTEMPO: %s  |  MOEDAS: %d  |  PARTIDAS: %d" % [
				i + 1, tempo, resumo["moedas"], resumo["partidas"]
			]
			botao_reiniciar.disabled = false


func _on_slot_pressed(slot: int) -> void:
	if SavedData.existe_save(slot):
		SavedData.carregar_slot(slot)
		SceneTransistor.start_transition_to(CONTINUAR_SCENE)
	else:
		SavedData.iniciar_novo(slot)
		SceneTransistor.start_transition_to(NOVO_SAVE_SCENE)


func _on_reiniciar_pressed(slot: int) -> void:
	_slot_para_reiniciar = slot
	confirmacao.dialog_text = "Apagar todo o progresso do SAVE %d?\nIsso não pode ser desfeito." % (slot + 1)
	confirmacao.popup_centered()


func _on_reinicio_confirmado() -> void:
	SavedData.resetar_slot(_slot_para_reiniciar)
	_slot_para_reiniciar = -1
	_atualizar_slots()


func _on_voltar_pressed() -> void:
	SceneTransistor.start_transition_to(MENU_SCENE)
