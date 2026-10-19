extends Node

const GHOST_HIT_SOUNDS = [
	preload("res://assets/audio/sfx/fantasma_hit_1.wav"),
	preload("res://assets/audio/sfx/fantasma_hit_2.wav"),
	preload("res://assets/audio/sfx/fantasma_hit_3.wav"),
	preload("res://assets/audio/sfx/fantasma_hit_4.wav")
]

@onready var background_player: AudioStreamPlayer = $BackgroundMusic



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	_configure_loop(background_player.stream)
	play_background_music()


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var bus_index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)


func _configure_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= 0:
			stream.loop_end = int(stream.get_length() * stream.mix_rate)


func play_background_music() -> void:
	if not background_player.playing:
		background_player.play()


func set_music_paused(paused: bool) -> void:
	background_player.stream_paused = paused


func stop_all_music() -> void:
	background_player.stop()


func play_ghost_hit(world_position: Vector2) -> void:
	if GHOST_HIT_SOUNDS.is_empty() or get_tree().current_scene == null:
		return

	var player := AudioStreamPlayer2D.new()
	player.stream = GHOST_HIT_SOUNDS.pick_random()
	player.bus = &"SFX"
	player.volume_db = randf_range(-7.0, -3.0)
	player.pitch_scale = randf_range(0.88, 1.12)
	player.max_distance = 650.0
	get_tree().current_scene.add_child(player)
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()
