# SavedData.gd
extends Node

signal personagem_mudou(id: String)

const SLOT_COUNT := 3
const SAVE_PATH := "user://save_slot_%d.json"

var slot_atual: int = -1
var dados: Dictionary = {}

var contando_tempo: bool = false
var _acumulado_autosave: float = 0.0

# Contadores da partida atual (não vão para o save, só o resultado vai)
var run_abates: int = 0
var run_pontos: int = 0
var _tempo_inicio_run: float = 0.0


func _ready() -> void:
	# Conta o tempo mesmo com o jogo pausado (pausa, estátua, Guia)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not contando_tempo or slot_atual < 0 or dados.is_empty():
		return
	dados["tempo_jogado"] += delta
	_acumulado_autosave += delta
	if _acumulado_autosave >= 30.0:   # salva sozinho a cada 30 s
		_acumulado_autosave = 0.0
		salvar()


static func formatar_tempo(segundos: float) -> String:
	var total := int(segundos)
	var horas := floori(total / 3600.0)
	var minutos := floori((total % 3600) / 60.0)
	return "%02dh %02dmin" % [horas, minutos]


func _dados_padrao() -> Dictionary:
	return {
		"versao": 1,
		"personagem_atual": "ada",
		"personagens_desbloqueados": ["ada"],
		"armas_usadas": [],
		"inimigos_derrotados": {},   # id -> quantas vezes
		"estatisticas": {},          # contadores: abates, partidas...
		"melhorias": {},
		"moedas": 0,
		"partidas": 0,
		"melhor_tempo": 0.0,
		"tempo_jogado": 0.0,
	}


# ---------- Slots ----------
func _caminho(slot: int) -> String:
	return SAVE_PATH % (slot + 1)   # slots 0, 1, 2 -> arquivos 1, 2, 3


func existe_save(slot: int) -> bool:
	return FileAccess.file_exists(_caminho(slot))


# Lê o slot sem selecioná-lo (usado na tela de saves)
func resumo_slot(slot: int) -> Dictionary:
	if not existe_save(slot):
		return {}
	var f := FileAccess.open(_caminho(slot), FileAccess.READ)
	if f == null:
		return {}
	var lido = JSON.parse_string(f.get_as_text())
	if typeof(lido) != TYPE_DICTIONARY:
		return {}
	var base := _dados_padrao()
	base.merge(lido, true)   # saves antigos ganham os campos novos
	base["moedas"] = int(base["moedas"])
	base["partidas"] = int(base["partidas"])
	return base


func carregar_slot(slot: int) -> void:
	slot_atual = slot
	dados = resumo_slot(slot)
	if dados.is_empty():
		dados = _dados_padrao()
	_acumulado_autosave = 0.0
	contando_tempo = true      # o tempo começa a contar ao escolher o save


func iniciar_novo(slot: int) -> void:
	slot_atual = slot
	dados = _dados_padrao()
	salvar()
	_acumulado_autosave = 0.0
	contando_tempo = true


func salvar() -> void:
	if slot_atual < 0 or dados.is_empty():
		return
	var f := FileAccess.open(_caminho(slot_atual), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dados, "\t"))


# Chamar ao voltar para o menu principal
func encerrar_sessao() -> void:
	if slot_atual >= 0:
		salvar()
	contando_tempo = false
	slot_atual = -1
	dados = {}


func resetar_slot(slot: int) -> void:
	if existe_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_caminho(slot)))
	if slot_atual == slot:
		slot_atual = -1
		dados = {}
		contando_tempo = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		salvar()
		SettingsManager.save_settings()


# ---------- Partida (run) ----------
# O Portal chama isto ao sair da Base para o primeiro mapa
func registrar_partida() -> void:
	iniciar_run()
	if dados.is_empty():
		return
	dados["partidas"] = int(dados.get("partidas", 0)) + 1
	add_stat("partidas")


func iniciar_run() -> void:
	run_abates = 0
	run_pontos = 0
	_tempo_inicio_run = float(dados.get("tempo_jogado", 0.0))


func tempo_da_run() -> float:
	return maxf(float(dados.get("tempo_jogado", 0.0)) - _tempo_inicio_run, 0.0)


# Ao morrer ou vencer: soma os pontos (Bytes) e salva
func finalizar_run() -> void:
	if dados.is_empty():
		return
	dados["moedas"] = int(dados.get("moedas", 0)) + run_pontos
	var t := tempo_da_run()
	if t > float(dados.get("melhor_tempo", 0.0)):
		dados["melhor_tempo"] = t
	salvar()


# ---------- Personagens ----------
func personagem_desbloqueado(id: String) -> bool:
	return id in dados.get("personagens_desbloqueados", ["ada"])


func personagem_atual() -> String:
	var id: String = dados.get("personagem_atual", "ada")
	if id == "" or not personagem_desbloqueado(id):
		return "ada"
	return id


func desbloquear_personagem(id: String) -> void:
	if dados.is_empty():
		return
	if not personagem_desbloqueado(id):
		dados["personagens_desbloqueados"].append(id)
		salvar()


func selecionar_personagem(id: String) -> bool:
	if dados.is_empty() or not personagem_desbloqueado(id):
		return false
	dados["personagem_atual"] = id
	salvar()
	personagem_mudou.emit(id)
	return true


# ---------- Bestiário e armas ----------
# Chame quando um inimigo morrer: SavedData.registrar_abate("bug", 5)
func registrar_abate(id_inimigo: String, pontos: int = 1) -> void:
	run_abates += 1
	run_pontos += pontos
	if dados.is_empty():
		return
	var d: Dictionary = dados["inimigos_derrotados"]
	d[id_inimigo] = int(d.get(id_inimigo, 0)) + 1
	add_stat("abates")


func inimigo_visto(id: String) -> bool:
	return int(dados.get("inimigos_derrotados", {}).get(id, 0)) > 0


func registrar_arma_usada(id_arma: String) -> void:
	if dados.is_empty():
		return
	if id_arma not in dados["armas_usadas"]:
		dados["armas_usadas"].append(id_arma)


func arma_usada(id: String) -> bool:
	return id in dados.get("armas_usadas", [])


# ---------- Conquistas ----------
func add_stat(nome: String, qtd: int = 1) -> void:
	if dados.is_empty():
		return
	var e: Dictionary = dados["estatisticas"]
	e[nome] = int(e.get(nome, 0)) + qtd


func get_stat(nome: String) -> int:
	return int(dados.get("estatisticas", {}).get(nome, 0))


func progresso_conquista(id: String) -> float:
	var c: Dictionary = Catalogo.CONQUISTAS[id]
	return clampf(float(get_stat(c["stat"])) / float(c["meta"]), 0.0, 1.0)


func conquista_completa(id: String) -> bool:
	return progresso_conquista(id) >= 1.0
