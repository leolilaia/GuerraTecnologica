# Door.gd
extends StaticBody2D

enum Modo { MANUAL, AUTOMATICA, COM_E }

const GRUPO_JOGADOR := "player"

## MANUAL = só abre por código (salas com inimigos, Sala.gd)
## AUTOMATICA = abre ao chegar perto e fecha ao sair
## COM_E = aperta E perto dela para abrir/fechar (fecha sozinha ao se afastar)
@export var modo: Modo = Modo.MANUAL
@export var comeca_fechada := true

var aberta := false
var jogador_perto := false
var _tween: Tween

@onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")
@onready var detector: Area2D = get_node_or_null("Detector")
@onready var colisao: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var simbolo_e: Sprite2D = get_node_or_null("SimboloE")


func _ready() -> void:
	if simbolo_e:
		simbolo_e.hide()
	if detector and modo != Modo.MANUAL:
		detector.body_entered.connect(_on_entrou)
		detector.body_exited.connect(_on_saiu)
	if modo != Modo.MANUAL:
		if comeca_fechada:
			set_closed_instant()
		else:
			set_open_instant()


func _on_entrou(body: Node) -> void:
	if not body.is_in_group(GRUPO_JOGADOR):
		return
	jogador_perto = true
	if modo == Modo.AUTOMATICA:
		open()
	elif modo == Modo.COM_E:
		_mostrar_simbolo()


func _on_saiu(body: Node) -> void:
	if not body.is_in_group(GRUPO_JOGADOR):
		return
	jogador_perto = false
	_esconder_simbolo()
	close()


func _unhandled_input(event: InputEvent) -> void:
	if modo == Modo.COM_E and jogador_perto and event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		if aberta:
			close()
		else:
			open()


func close() -> void:
	if not aberta and animation_player.current_animation == "close":
		return
	aberta = false
	_colisao(true)
	animation_player.play("close")


func open() -> void:
	aberta = true
	_colisao(false)
	animation_player.play("open")


func set_open_instant() -> void:
	aberta = true
	_colisao(false)
	animation_player.play("open")
	animation_player.seek(animation_player.current_animation_length, true)


func set_closed_instant() -> void:
	aberta = false
	_colisao(true)
	animation_player.play("close")
	animation_player.seek(animation_player.current_animation_length, true)


func _colisao(ativa: bool) -> void:
	if colisao:
		colisao.set_deferred("disabled", not ativa)


# ---------- SimboloE pulsando ----------
func _mostrar_simbolo() -> void:
	if simbolo_e == null:
		return
	simbolo_e.show()
	_parar_pulso()
	_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(simbolo_e, "scale", Vector2(0.8, 0.8), 0.35)
	_tween.tween_property(simbolo_e, "scale", Vector2.ONE, 0.35)


func _esconder_simbolo() -> void:
	if simbolo_e == null:
		return
	simbolo_e.hide()
	_parar_pulso()


func _parar_pulso() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if simbolo_e:
		simbolo_e.scale = Vector2.ONE
