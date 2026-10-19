# Interagivel.gd
class_name Interagivel
extends Area2D

signal interagido

const GRUPO_JOGADOR := "player"

var jogador_perto := false
var bloqueado := false

var _simbolo_e: Sprite2D
var _tween_simbolo: Tween


func _ready() -> void:
	_simbolo_e = get_node_or_null("SimboloE") as Sprite2D
	if _simbolo_e:
		_simbolo_e.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(GRUPO_JOGADOR):
		jogador_perto = true
		if not bloqueado:
			_mostrar_simbolo()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(GRUPO_JOGADOR):
		jogador_perto = false
		_esconder_simbolo()


func _unhandled_input(event: InputEvent) -> void:
	if jogador_perto and not bloqueado and event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		interagir()


# Cada objeto sobrescreve esta função
func interagir() -> void:
	interagido.emit()


# Use estas duas nas subclasses (evita mexer no símbolo diretamente)
func bloquear() -> void:
	bloqueado = true
	_esconder_simbolo()


func liberar() -> void:
	bloqueado = false
	if jogador_perto:
		_mostrar_simbolo()


# ---------- SimboloE pulsando ----------
func _mostrar_simbolo() -> void:
	if _simbolo_e == null:
		return
	_simbolo_e.show()
	_parar_pulso()
	_tween_simbolo = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_tween_simbolo.tween_property(_simbolo_e, "scale", Vector2(0.8, 0.8), 0.35)
	_tween_simbolo.tween_property(_simbolo_e, "scale", Vector2.ONE, 0.35)


func _esconder_simbolo() -> void:
	if _simbolo_e == null:
		return
	_simbolo_e.hide()
	_parar_pulso()


func _parar_pulso() -> void:
	if _tween_simbolo and _tween_simbolo.is_valid():
		_tween_simbolo.kill()
	if _simbolo_e:
		_simbolo_e.scale = Vector2.ONE
