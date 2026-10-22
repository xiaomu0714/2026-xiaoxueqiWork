class_name FontHelper
## 中文显示修复：让界面所有文字使用系统字体（微软雅黑等）
## Godot 4 默认字体不含中文字形，不设置会显示为方块。
## 用法：在每个场景的 _ready() 第一行调用 FontHelper.apply_to(self)

const DREAM_UI = preload("res://scripts/ui_theme.gd")
const GLOBAL_DETAILS = preload("res://scripts/global_details.gd")

static func apply_to(control: Control) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI",
		"Microsoft YaHei",
		"SimHei",
		"Noto Sans CJK SC",
		"PingFang SC",
	])
	control.theme = DREAM_UI.build_theme(font)
	# 所有界面统一裁剪到视口，避免长字幕或临时提示绘制到窗口外。
	control.clip_contents = true
	DREAM_UI.add_dream_background(control)
	GLOBAL_DETAILS.attach(control)


static func make_panel(
	position: Vector2,
	size: Vector2,
	accent: Color = DREAM_UI.BORDER,
	fill: Color = DREAM_UI.PANEL
	) -> PanelContainer:
	return DREAM_UI.make_panel(position, size, accent, fill)


static func style_primary(button: Button) -> void:
	DREAM_UI.style_primary_button(button)


static func style_card(button: Button, accent: Color) -> void:
	DREAM_UI.style_card_button(button, accent)


static func panel_style(
	fill: Color = DREAM_UI.PANEL,
	border: Color = DREAM_UI.BORDER,
	radius: int = 12
	) -> StyleBoxFlat:
	return DREAM_UI.panel_style(fill, border, radius)


static func button_style(
	fill: Color,
	border: Color,
	border_width: int = 1,
	radius: int = 10
	) -> StyleBoxFlat:
	return DREAM_UI.button_style(fill, border, border_width, radius)
