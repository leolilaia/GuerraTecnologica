# Catalogo.gd
extends Node

const JOGADOR_CENA := "res://scenes/player/player.tscn"

# "character" = recurso com sprite e arma inicial usado pelo Player.
# "unlock_level" = fase cujo boss libera o personagem (0 = livre desde o início).
const PERSONAGENS := {
	"ada": {
		"nome": "ADA LOVELACE",
		"historia": "Matemática inglesa (1815-1852). Nas notas sobre a Máquina Analítica de Babbage, escreveu o que é considerado o primeiro algoritmo feito para ser executado por uma máquina.",
		"estatua": "res://assets/sprites/interativos/estatua_ada.png",
		"character": "res://resources/characters/ada_lovelace.tres",
		"unlock_level": 0,
	},
	"turing": {
		"nome": "ALAN TURING",
		"historia": "Matemático britânico (1912-1954). Formalizou a ideia de computação com a Máquina de Turing e ajudou a decifrar a Enigma na Segunda Guerra Mundial.",
		"estatua": "res://assets/sprites/interativos/estatua_turing.png",
		"character": "res://resources/characters/alan_turing.tres",
		"unlock_level": 1,
	},
	"hedy": {
		"nome": "HEDY LAMARR",
		"historia": "Atriz e inventora (1914-2000). Criou com George Antheil o salto de frequência, ideia que está na base de tecnologias como Wi-Fi e Bluetooth.",
		"estatua": "res://assets/sprites/interativos/estatua_hedy.png",
		"character": "res://resources/characters/hedy_lamarr.tres",
		"unlock_level": 2,
	},
}

# A chave é o nome do arquivo da cena do inimigo (scenes/enemies/<id>.tscn)
const INIMIGOS := {
	"smartwatch": {"nome": "SMARTWATCH", "icone": "res://assets/sprites/Inimigos/Genericos/Smartwatch.png",
		"historia": "Pequeno e rápido. Conta seus passos enquanto corre atrás de você."},
	"celular": {"nome": "CELULAR", "icone": "res://assets/sprites/Inimigos/Genericos/Samsung.png",
		"historia": "Vive pedindo atualização. Aparece em bando e nunca deixa você em paz."},
	"robo": {"nome": "ROBÔ", "icone": "res://assets/sprites/Inimigos/Genericos/Robo.png",
		"historia": "Lento, mas aguenta muito dano. Foi programado para não desistir."},
	"microondas": {"nome": "MICRO-ONDAS", "icone": "res://assets/sprites/Inimigos/Genericos/Microondas.png",
		"historia": "Esquenta tudo o que chega perto. O apito dele é o último som que muitos ouvem."},
	"boss_smartphone": {"nome": "SMARTPHONE", "icone": "res://assets/sprites/Inimigos/Bosses/Smartphone.png",
		"historia": "Chefe da fase 1. Arremessa aparelhos e não larga a tela por nada."},
	"boss_laptop": {"nome": "LAPTOP", "icone": "res://assets/sprites/Inimigos/Bosses/Laptop.png",
		"historia": "Chefe da fase 2. Esquenta, trava e mesmo assim continua atacando."},
}

# A chave é o nome do arquivo da cena da arma (scenes/weapons/**/<id>.tscn)
const ARMAS := {
	"ada_weapon": {"nome": "CÓDIGO", "icone": "res://assets/sprites/Weapons/Feixes.png",
		"descricao": "Arma da Ada. Dispara feixes na direção em que ela anda, ou no mouse enquanto clica."},
	"turing_weapon": {"nome": "ENGRENAGENS", "icone": "res://assets/icons/weapons/gear.png",
		"descricao": "Arma do Turing. Solta engrenagens em volta dele; cada nível acrescenta uma."},
	"hedy_weapon": {"nome": "WI-FI", "icone": "res://assets/sprites/Weapons/Wifi.png",
		"descricao": "Arma da Hedy. Um pulso em volta dela e um leque na direção do mouse, que enfraquecem com a distância."},
	"tesla_coil_weapon": {"nome": "BOBINA DE TESLA", "icone": "res://assets/sprites/Itens/BobinaTesla.png",
		"descricao": "Lança um raio que salta de inimigo em inimigo."},
	"stun_radio_weapon": {"nome": "RÁDIO DE STUN", "icone": "res://assets/sprites/Itens/Radio.png",
		"descricao": "Onda de alta frequência que paralisa quem estiver em volta. Não causa dano."},
	"polaroid_weapon": {"nome": "POLAROID", "icone": "res://assets/sprites/Itens/Polaroid.png",
		"descricao": "Flash em cone na direção do mouse que desintegra quem pegar."},
	"phone_whip_weapon": {"nome": "TELEFONE FIXO", "icone": "res://assets/sprites/Itens/Telefone.png",
		"descricao": "Chicotada com o cabo do telefone na direção do mouse: pouco dano, muita frequência."},
	"lightning_weapon": {"nome": "RAIO", "icone": "res://assets/sprites/Weapons/RaioParaRaio.png",
		"descricao": "Raios caem pela tela e congelam quem pegarem. No nível máximo vira Para-raio e cai no mouse."},
}

# stat = contador do SavedData que alimenta a conquista
const CONQUISTAS := {
	"primeiro_boot": {"nome": "PRIMEIRO BOOT",     "descricao": "Inicie 1 partida",              "stat": "partidas",  "meta": 1,   "secreta": false},
	"cacador":       {"nome": "CAÇADORA DE BUGS",  "descricao": "Derrote 100 inimigos",          "stat": "abates",    "meta": 100, "secreta": false},
	"veterana":      {"nome": "VETERANA",          "descricao": "Inicie 10 partidas",            "stat": "partidas",  "meta": 10,  "secreta": false},
	"segredo_1":     {"nome": "FREQUÊNCIA OCULTA", "descricao": "Encontre o terminal escondido", "stat": "segredo_1", "meta": 1,   "secreta": true},
}


func character_data(id: String) -> CharacterData:
	if not PERSONAGENS.has(id):
		id = "ada"
	return load(PERSONAGENS[id]["character"]) as CharacterData


## Personagem para a Base: sem arma, porque lá não há inimigos
func criar_jogador(id: String) -> Player:
	var jogador := (load(JOGADOR_CENA) as PackedScene).instantiate() as Player
	jogador.character = character_data(id)   # definido antes de entrar na árvore
	jogador.armed = false
	return jogador


## Personagens que o boss desta fase libera
func characters_unlocked_by(level: int) -> Array[String]:
	var ids: Array[String] = []
	for id in PERSONAGENS:
		if PERSONAGENS[id]["unlock_level"] == level:
			ids.append(id)
	return ids
