extends Node
## 全局音频管理器：BGM（主题曲/战斗曲，切场景时切换）+ SFX（音效池，可同时响）。
## 作为 autoload 使用：AudioMan.use_theme_music() / use_battle_music() / play_sfx()。

const THEME_PATH := "res://audio/theme.mp3"
const BATTLE_PATH := "res://audio/battle.mp3"

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _cur_path := ""
const SFX_POOL := 8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	# 默认播放主题曲
	use_theme_music()


func play_music(path: String, fade := 0.6) -> void:
	if path == _cur_path:
		return
	_cur_path = path
	var stream := load(path)
	if stream == null:
		return
	# 设置为循环播放
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music.stop()
	_music.stream = stream
	_music.volume_db = 0.0
	_music.play()


func use_theme_music() -> void:
	play_music(THEME_PATH)


func use_battle_music() -> void:
	play_music(BATTLE_PATH)


func stop_music() -> void:
	_music.stop()
	_cur_path = ""


func play_sfx(path: String, volume_db := 0.0) -> void:
	# 自动尝试 .wav / .mp3 / .ogg 扩展名，方便接入不同格式素材
	var stream: AudioStream = null
	for ext in [".wav", ".mp3", ".ogg"]:
		stream = load(path + ext)
		if stream != null:
			break
	if stream == null:
		return
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	_sfx[0].stream = stream
	_sfx[0].volume_db = volume_db
	_sfx[0].play()
