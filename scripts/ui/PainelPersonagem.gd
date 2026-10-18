extends CanvasLayer

signal fechado

@onready var raiz: Control = $Raiz

var _id := ""
var _nome: Label
var _historia: Label
var _btn_sel: Button
var _btn_fechar: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ancora := VBoxContainer.new()
	ancora.set_anchors_preset(Control.PRESET_FULL_RECT)
	ancora.offset_bottom = -24
	ancora.alignment = BoxContainer.ALIGNMENT_END
	ancora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(ancora)

	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(640, 0)
	caixa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ancora.add_child(caixa)

	var vb := VBoxContainer.new()
	caixa.add_child(vb)

	_nome = Label.new()
	vb.add_child(_nome)

	_historia = Label.new()
	_historia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_historia.custom_minimum_size = Vector2(600, 0)
	vb.add_child(_historia)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	_btn_sel = Button.new()
	_btn_sel.pressed.connect(_on_selecionar)
	hb.add_child(_btn_sel)

	_btn_fechar = Button.new()
	_btn_fechar.text = "FECHAR"
	_btn_fechar.pressed.connect(_on_fechar)
	hb.add_child(_btn_fechar)

	for b in [_btn_sel, _btn_fechar]:
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func abrir(id: String) -> void:
	_id = id
	var info: Dictionary = Catalogo.PERSONAGENS[id]
	var livre := SavedData.personagem_desbloqueado(id)
	var atual := SavedData.personagem_atual() == id
	_nome.text = info["nome"] if livre else "????"
	_historia.text = info["historia"] if livre else "????"
	_btn_sel.text = "SELECIONADA" if atual else "SELECIONAR"
	_btn_sel.disabled = (not livre) or atual   # desabilitado fica cinza
	if _btn_sel.disabled:
		_btn_fechar.grab_focus()
	else:
		_btn_sel.grab_focus()


func _on_selecionar() -> void:
	SavedData.selecionar_personagem(_id)
	abrir(_id)


func _on_fechar() -> void:
	fechado.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_fechar()
