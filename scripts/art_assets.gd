class_name ArtAssets
extends RefCounted
## 美术资源访问层。
##
## 所有外部图片统一从 art/ready_v2 读取；关闭 project.godot 中的开关后，
## 界面会整体回退到脚本绘制的色块、文字和状态条，无需逐个修改场景。

const ROOT := "res://art/ready_v2/"
const FALLBACK_ROOT := "res://art/generated/"
const ENABLED_SETTING := "echo_dungeon/art_assets_enabled"
const TextureView = preload("res://scripts/ui_texture_view.gd")


static func enabled() -> bool:
	return bool(ProjectSettings.get_setting(ENABLED_SETTING, false))

static func _texture(file_name: String) -> Texture2D:
	if not enabled():
		return null
	var path := ROOT + file_name
	if not ResourceLoader.exists(path):
		path = FALLBACK_ROOT + file_name
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func character(key: String) -> Texture2D:
	return _texture("char_%s.png" % key)


static func enemy(key: String) -> Texture2D:
	var mapped := {
		"slime": "rage",
		"archer": "envy",
		"golem": "pride",
		"wisp": "gluttony",
		"spider": "fear",
		"sentinel": "sentinel",
		"mender": "mender",
		"knight": "greed_elite",
		"boss": "void_boss",
	}
	return _texture("enemy_%s.png" % mapped.get(key, key))


static func item(key: String) -> Texture2D:
	return _texture("item_%s.png" % key)


static func node(key: String) -> Texture2D:
	return _texture("node_%s.png" % key)


static func background(key: String) -> Texture2D:
	return _texture("bg_%s.png" % key)


static func event_background(key: String) -> Texture2D:
	return _texture("event_%s.png" % key)




static func frame(key: int) -> Texture2D:
	return _texture("%d.png" % key)


static func add_texture(
		parent: Control,
		texture: Texture2D,
		rect: Rect2,
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE,
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
		fit_scale: float = 1.0,
		pad: float = 0.05
	) -> Control:
	# 用自定义绘制节点（ui_texture_view）按比例缩放贴图，避免 TextureRect 会
	# 因为 min-size = 图片原始尺寸（如角色 798x819）而把立绘撑成巨大。
	# 注意：始终返回一个控件（贴图可为空），调用方会访问 .texture，不能返回 null。
	var shrunk := rect.size * (1.0 - pad * 2.0)
	var fitted_size := shrunk * clampf(fit_scale, 0.1, 1.0)
	var fitted_rect := Rect2(rect.position + (rect.size - fitted_size) * 0.5, fitted_size)
	var view := TextureView.new(texture, fitted_rect)
	parent.add_child(view)
	return view
