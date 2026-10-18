# Portal.gd
extends Interagivel

@export_file("*.tscn") var destino: String = ""
@export var conta_como_partida := false


func interagir() -> void:
	if destino.is_empty():
		push_warning("Portal sem destino definido")
		return
	bloquear()
	if conta_como_partida:
		SavedData.registrar_partida()   # zera os contadores da run e soma a partida
	SavedData.salvar()
	SceneTransistor.start_transition_to(destino)
