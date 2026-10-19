# FundoHacker.gd  (raiz da cena: CanvasLayer)
extends CanvasLayer

const CHARS := "01{}[]<>/\\;:=+*#$%&@!?ABCDEFabcdef"
const COMANDOS := [
	"> ssh ada@analytical-engine",
	"> sudo ./patch --all",
	"> decrypt enigma.key",
	"> ping 127.0.0.1",
	"> grep -r \"bug\" ./src",
	"> chmod +x freq_hop.sh",
	"> loading memory... OK",
	"> access granted",
	"[ OK ] boot sequence",
	"0x7FFF 0xA3C1 0x00FE",
	"> compile --target=future",
	"> whoami",
]

@export var fonte: Font                        # opcional: a fonte do seu jogo
@export var tamanho_fonte: int = 10
@export var cor_verde := Color(0.0, 1.0, 0.35)
@export var cor_branca := Color(0.9, 1.0, 0.93)
@export var velocidade: float = 0.6            # menor = mais calmo
@export_range(0.0, 1.0) var brilho: float = 0.5
@export_range(0.0, 1.0) var densidade: float = 0.55
@export var linhas_de_comando: int = 6

var _desenho: Control
var _cel := Vector2(7, 12)
var _rows := 0
var _cols: Array = []
var _cmds: Array = []
var _t := 0.0


func _ready() -> void:
	layer = -10                                # atrás do mapa, dos interativos e do jogador
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	_desenho = Control.new()
	_desenho.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desenho.draw.connect(_desenhar)
	add_child(_desenho)

	get_viewport().size_changed.connect(_montar)
	_montar()


func _montar() -> void:
	var tam := get_viewport().get_visible_rect().size
	_cel = Vector2(tamanho_fonte * 0.7, tamanho_fonte * 1.2)
	_rows = int(ceil(tam.y / _cel.y))
	_cols.clear()
	for i in range(int(ceil(tam.x / _cel.x))):
		var c := {"i": i}
		_resetar_coluna(c, true)
		_cols.append(c)
	_cmds.clear()
	for n in linhas_de_comando:
		var l := {}
		_resetar_comando(l, true)
		_cmds.append(l)


func _resetar_coluna(c: Dictionary, inicial := false) -> void:
	c["ativa"] = randf() < densidade
	c["vel"] = randf_range(5.0, 14.0)
	c["len"] = randi_range(6, 16)
	c["troca"] = randf_range(2.0, 6.0)
	c["head"] = randf_range(-5.0, float(_rows)) if inicial else -randf_range(0.0, 20.0)


func _resetar_comando(l: Dictionary, inicial := false) -> void:
	var tam := get_viewport().get_visible_rect().size
	l["txt"] = COMANDOS.pick_random()
	l["x"] = randf_range(4.0, maxf(tam.x * 0.6, 8.0))
	l["y"] = randf_range(0.0, tam.y) if inicial else -12.0
	l["vel"] = randf_range(6.0, 14.0)    # pixels por segundo (bem lento)


func _process(delta: float) -> void:
	_t += delta
	for c in _cols:
		c["head"] += c["vel"] * delta * velocidade
		if c["head"] - c["len"] > _rows:
			_resetar_coluna(c)
	var altura := get_viewport().get_visible_rect().size.y
	for l in _cmds:
		l["y"] += l["vel"] * delta * velocidade
		if l["y"] > altura + 12.0:
			_resetar_comando(l)
	_desenho.queue_redraw()


func _desenhar() -> void:
	var f: Font = fonte if fonte else ThemeDB.fallback_font
	var asc := f.get_ascent(tamanho_fonte)

	# Chuva de código
	for c in _cols:
		if not c["ativa"]:
			continue
		var x: float = c["i"] * _cel.x
		for k in range(c["len"]):
			var row := int(floor(c["head"])) - k
			if row < 0 or row >= _rows:
				continue
			var h: int = (c["i"] * 73856093) ^ (row * 19349663) ^ (int(_t * c["troca"]) * 83492791)
			var ch: String = CHARS[absi(h) % CHARS.length()]
			var cor: Color = cor_branca if k == 0 else cor_verde
			cor.a = (1.0 if k == 0 else pow(1.0 - float(k) / c["len"], 1.5)) * brilho
			_desenho.draw_string(f, Vector2(x, row * _cel.y + asc), ch,
					HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte, cor)

	# Linhas de comando, bem fracas, descendo devagar
	for l in _cmds:
		var cor2 := cor_verde
		cor2.a = 0.35 * brilho
		_desenho.draw_string(f, Vector2(l["x"], l["y"]), l["txt"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte, cor2)
