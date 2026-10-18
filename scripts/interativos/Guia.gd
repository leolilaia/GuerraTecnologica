extends Interagivel

const TELA_GUIA := preload("res://scenes/ui/TelaGuia.tscn")

@export var fator_zoom := 3.0
@export var offset_tela := Vector2(0, -16)   # centro da tela da TV em relação ao marker

var _tela: CanvasLayer
var _camera: Camera2D
var _zoom_orig: Vector2
var _pos_orig: Vector2
var _suave_orig := false




func interagir() -> void:
	_camera = get_viewport().get_camera_2d()
	bloquear()
	get_tree().paused = true

	_tela = TELA_GUIA.instantiate()
	get_tree().current_scene.add_child(_tela)
	_tela.opcao_escolhida.connect(_on_opcao)
	_tela.conteudo_fechado.connect(_on_conteudo_fechado)
	_tela.fechado.connect(_on_fechado)
	_tela.mostrar_dialogo()


func _on_opcao(opcao: String) -> void:
	await _zoom(true)
	_tela.mostrar_conteudo(opcao)


func _on_conteudo_fechado() -> void:
	await _zoom(false)
	_tela.mostrar_dialogo()


func _on_fechado() -> void:
	get_tree().paused = false
	liberar()


func _zoom(entrando: bool) -> void:
	if _camera == null:
		return
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if entrando:
		_zoom_orig = _camera.zoom
		_pos_orig = _camera.position
		_suave_orig = _camera.position_smoothing_enabled
		_camera.position_smoothing_enabled = false
		t.tween_property(_camera, "zoom", _zoom_orig * fator_zoom, 0.8)
		t.tween_property(_camera, "global_position", global_position + offset_tela, 0.8)
	else:
		t.tween_property(_camera, "zoom", _zoom_orig, 0.6)
		t.tween_property(_camera, "position", _pos_orig, 0.6)
	await t.finished
	if not entrando:
		_camera.position_smoothing_enabled = _suave_orig
