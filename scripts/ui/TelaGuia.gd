extends CanvasLayer

signal opcao_escolhida(opcao: String)
signal conteudo_fechado
signal fechado

const FALA := "Ah, você voltou! O que quer consultar hoje?"

@onready var raiz: Control = $Raiz

var _dialogo: Control
var _conteudo: Control
var _titulo: Label
var _lista: GridContainer
var _det_nome: Label
var _det_texto: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_montar_dialogo()
	_montar_conteudo()
	_conteudo.hide()


# ---------------- Diálogo ----------------
func _montar_dialogo() -> void:
	var ancora := VBoxContainer.new()
	ancora.set_anchors_preset(Control.PRESET_FULL_RECT)
	ancora.offset_bottom = -24
	ancora.alignment = BoxContainer.ALIGNMENT_END
	ancora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(ancora)
	_dialogo = ancora

	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(640, 0)
	caixa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ancora.add_child(caixa)

	var vb := VBoxContainer.new()
	caixa.add_child(vb)

	var nome := Label.new()
	nome.text = "GUIA"
	vb.add_child(nome)

	var fala := Label.new()
	fala.text = FALA
	fala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(fala)

	var opcoes := {
		"bestiario": "VER BESTIÁRIO",
		"armas": "VER ARMAS",
		"conquistas": "VER CONQUISTAS",
	}
	for chave in opcoes:
		vb.add_child(_botao(opcoes[chave], func(): opcao_escolhida.emit(chave)))
	vb.add_child(_botao("SAIR", func(): fechado.emit(); queue_free()))


# ---------------- Conteúdo (a "tela da TV") ----------------
func _montar_conteudo() -> void:
	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(painel)
	_conteudo = painel

	var vb := VBoxContainer.new()
	painel.add_child(vb)

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_titulo)

	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 2.0
	hb.add_child(scroll)

	_lista = GridContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_lista)

	var det := VBoxContainer.new()
	det.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(det)

	_det_nome = Label.new()
	det.add_child(_det_nome)

	_det_texto = Label.new()
	_det_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_det_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	det.add_child(_det_texto)

	vb.add_child(_botao("VOLTAR", _on_voltar))

	# Linhas e ruído de TV por cima de tudo
	var shader_path := "res://shaders/crt.gdshader"
	if ResourceLoader.exists(shader_path):
		var overlay := ColorRect.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load(shader_path)
		overlay.material = mat
		raiz.add_child(overlay)


func mostrar_dialogo() -> void:
	_conteudo.hide()
	_dialogo.show()
	var vb := _dialogo.get_child(0).get_child(0)
	(vb.get_child(2) as Button).grab_focus()   # primeira opção


func mostrar_conteudo(opcao: String) -> void:
	_dialogo.hide()
	_conteudo.show()
	for c in _lista.get_children():
		c.queue_free()
	_det_nome.text = ""
	_det_texto.text = "Selecione um item."
	match opcao:
		"bestiario":
			_titulo.text = "BESTIÁRIO"
			_lista.columns = 4
			_preencher_bestiario()
		"armas":
			_titulo.text = "ARMAS"
			_lista.columns = 4
			_preencher_armas()
		"conquistas":
			_titulo.text = "CONQUISTAS"
			_lista.columns = 1
			_det_texto.text = ""
			_preencher_conquistas()


func _on_voltar() -> void:
	conteudo_fechado.emit()


# ---------------- Bestiário ----------------
func _preencher_bestiario() -> void:
	for id in Catalogo.INIMIGOS:
		var info: Dictionary = Catalogo.INIMIGOS[id]
		var visto := SavedData.inimigo_visto(id)
		var b := _card(info["icone"], info["nome"], visto)
		if visto:
			b.pressed.connect(func():
				_det_nome.text = info["nome"]
				_det_texto.text = info["historia"]
			)
		_lista.add_child(b)


# ---------------- Armas ----------------
func _preencher_armas() -> void:
	for id in Catalogo.ARMAS:
		var info: Dictionary = Catalogo.ARMAS[id]
		var usada := SavedData.arma_usada(id)
		var b := _card(info["icone"], info["nome"], usada)
		if usada:
			b.pressed.connect(func():
				_det_nome.text = info["nome"]
				_det_texto.text = info["descricao"]
				# PRÓXIMO PASSO: aqui entra o preview do personagem
				# atual (SavedData.personagem_atual()) usando esta arma
				# sobre o fundo do mapa 1.
			)
		_lista.add_child(b)


# ---------------- Conquistas ----------------
func _preencher_conquistas() -> void:
	for id in Catalogo.CONQUISTAS:
		var c: Dictionary = Catalogo.CONQUISTAS[id]
		var pct := SavedData.progresso_conquista(id)
		var completa := pct >= 1.0
		var oculta: bool = c["secreta"] and not completa

		var linha := VBoxContainer.new()
		linha.modulate = Color.WHITE if completa else Color(0.55, 0.55, 0.55)

		var nome := Label.new()
		nome.text = "???" if oculta else c["nome"]
		linha.add_child(nome)

		var desc := Label.new()
		desc.text = "???" if oculta else c["descricao"]
		linha.add_child(desc)

		var barra := ProgressBar.new()
		barra.max_value = 100
		barra.value = pct * 100.0
		barra.custom_minimum_size = Vector2(0, 14)
		linha.add_child(barra)

		_lista.add_child(linha)


# ---------------- Helpers ----------------
func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(acao)
	return b


func _card(icone_path: String, nome: String, liberado: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(120, 130)
	b.text = nome if liberado else "???"
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	if icone_path != "" and ResourceLoader.exists(icone_path):
		b.icon = load(icone_path)
	if not liberado:
		b.disabled = true
		# Silhueta preta
		for cor in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
				"icon_focus_color", "icon_disabled_color", "icon_hover_pressed_color"]:
			b.add_theme_color_override(cor, Color.BLACK)
	else:
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b
