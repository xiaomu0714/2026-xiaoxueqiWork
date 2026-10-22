class_name UITheme
extends RefCounted
## 纯代码梦境 UI 主题。以后替换模型、插画和图标时可继续沿用。

const BG_TOP := Color(0.025, 0.035, 0.075)
const BG_BOTTOM := Color(0.075, 0.045, 0.12)
const PANEL := Color(0.055, 0.075, 0.13, 0.94)
const PANEL_LIGHT := Color(0.08, 0.105, 0.18, 0.96)
const BORDER := Color(0.25, 0.34, 0.52, 0.85)
const GOLD := Color(0.96, 0.76, 0.32)
const CYAN := Color(0.38, 0.78, 0.88)
const TEXT := Color(0.91, 0.93, 0.98)
const MUTED := Color(0.64, 0.69, 0.80)
const DANGER := Color(0.84, 0.30, 0.36)


static func build_theme(font: Font) -> Theme:
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 16

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)

	theme.set_stylebox("normal", "Button", button_style(PANEL_LIGHT, BORDER))
	theme.set_stylebox("hover", "Button", button_style(Color(0.12, 0.16, 0.26), CYAN))
	theme.set_stylebox("pressed", "Button", button_style(Color(0.16, 0.13, 0.23), GOLD))
	theme.set_stylebox("focus", "Button", button_style(Color(0, 0, 0, 0), GOLD, 2))
	theme.set_stylebox("disabled", "Button", button_style(Color(0.045, 0.055, 0.085, 0.72), Color(0.17, 0.19, 0.25, 0.6)))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", GOLD.lightened(0.15))
	theme.set_color("font_disabled_color", "Button", Color(0.42, 0.45, 0.52))
	theme.set_constant("outline_size", "Button", 1)
	theme.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.45))

	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "TabContainer", panel_style(PANEL, BORDER, 12))
	theme.set_stylebox("tab_selected", "TabBar", button_style(Color(0.14, 0.18, 0.29), GOLD, 2))
	theme.set_stylebox("tab_unselected", "TabBar", button_style(Color(0.06, 0.08, 0.14), BORDER))
	theme.set_stylebox("tab_hovered", "TabBar", button_style(Color(0.10, 0.14, 0.23), CYAN))
	theme.set_color("font_selected_color", "TabBar", GOLD)
	theme.set_color("font_unselected_color", "TabBar", MUTED)
	theme.set_color("font_hovered_color", "TabBar", Color.WHITE)

	theme.set_stylebox("background", "ProgressBar", progress_background())
	theme.set_stylebox("fill", "ProgressBar", progress_fill())
	theme.set_color("font_color", "ProgressBar", Color.WHITE)
	theme.set_color("font_outline_color", "ProgressBar", Color(0, 0, 0, 0.8))
	theme.set_constant("outline_size", "ProgressBar", 2)

	theme.set_stylebox("panel", "TooltipPanel", panel_style(Color(0.04, 0.05, 0.09, 0.98), GOLD, 8))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)

	theme.set_stylebox("separator", "HSeparator", separator_style(CYAN))
	theme.set_stylebox("separator", "VSeparator", separator_style(CYAN))

	# 深色滚动条，替换系统默认的亮色条
	theme.set_stylebox("scroll", "VScrollBar", _scrollbar_style())
	theme.set_stylebox("scroll", "HScrollBar", _scrollbar_style())
	theme.set_stylebox("grabber", "VScrollBar", _grabber_style())
	theme.set_stylebox("grabber_highlight", "VScrollBar", _grabber_style(Color(0.40, 0.52, 0.72)))
	theme.set_stylebox("grabber", "HScrollBar", _grabber_style())
	theme.set_stylebox("grabber_highlight", "HScrollBar", _grabber_style(Color(0.40, 0.52, 0.72)))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _grabber_style(Color(0.88, 0.68, 0.30)))
	theme.set_stylebox("grabber_pressed", "HScrollBar", _grabber_style(Color(0.88, 0.68, 0.30)))
	return theme


static func _scrollbar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.08, 0.60)
	style.border_color = Color(0.28, 0.34, 0.50, 0.60)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


static func _grabber_style(color := Color(0.32, 0.42, 0.62)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 2
	return style


static func add_dream_background(root: Control) -> void:
	if root.get_node_or_null("DreamBackdrop") != null:
		return
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	gradient.colors = PackedColorArray([
		BG_TOP,
		Color(0.035, 0.06, 0.115),
		BG_BOTTOM,
	])
	texture.gradient = gradient
	texture.width = 1280
	texture.height = 800
	texture.fill_from = Vector2(0.05, 0.0)
	texture.fill_to = Vector2(0.95, 1.0)

	var backdrop := TextureRect.new()
	backdrop.name = "DreamBackdrop"
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	root.move_child(backdrop, 0)

	var top_glow := ColorRect.new()
	top_glow.color = Color(0.22, 0.38, 0.62, 0.09)
	top_glow.position = Vector2(0, 0)
	top_glow.size = Vector2(1280, 74)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(top_glow)

	var bottom_glow := ColorRect.new()
	bottom_glow.color = Color(0.48, 0.16, 0.44, 0.08)
	bottom_glow.position = Vector2(0, 680)
	bottom_glow.size = Vector2(1280, 120)
	bottom_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(bottom_glow)

	for x in [62.0, 1218.0]:
		var edge := ColorRect.new()
		edge.color = Color(0.40, 0.66, 0.86, 0.10)
		edge.position = Vector2(x, 0)
		edge.size = Vector2(1, 800)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(edge)




# ── top-right status boxes ───────────────────────────────────

static func add_top_right_status(parent: Control) -> void:
	# 右上三框是这类页面的统一状态区；去掉 FontHelper 自动附加的浮动“效果详情”，
	# 避免右上角出现两个重叠按钮并遮挡标题。
	var floating := parent.get_node_or_null("GlobalDetailButton")
	if floating != null:
		parent.remove_child(floating)
		floating.queue_free()
	var box := HBoxContainer.new()
	box.name = "TopRightStatus"
	box.z_index = 800
	box.position = Vector2(770, 8)
	box.size = Vector2(500, 56)
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("alignment", BoxContainer.ALIGNMENT_END)
	parent.add_child(box)

	# 探索等级
	var exp_box := _make_status_box("Lv.%d 经验 %d/%d\n资源回复 +%d" % [
		Run.exploration_level, Run.exploration_xp, Run.exploration_xp_to_next(),
		Run.exploration_level], Color(0.30, 0.55, 0.78))
	box.add_child(exp_box)

	# 金币
	var gold_box := _make_status_box("金币 %d" % Run.gold, Color(0.88, 0.72, 0.28))
	box.add_child(gold_box)

	# 效果详情按钮
	var detail := Button.new()
	detail.name = "GlobalDetailButton"
	detail.text = "效果详情"
	detail.custom_minimum_size = Vector2(104, 46)
	detail.add_theme_font_size_override("font_size", 13)
	FontHelper.style_card(detail, Color(0.45, 0.68, 0.82))
	detail.pressed.connect(GlobalDetails.toggle.bind(parent))
	box.add_child(detail)

static func _make_status_box(text: String, accent: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(150, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", accent)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.12, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = accent.darkened(0.30)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	label.add_theme_stylebox_override("normal", style)
	return label


## 统一的页面标题：金字 + 投影 + 居中/居左，带小菱形饰角。
static func make_title(
		text: String,
		rect: Rect2,
		font_size: int = 30,
		align: int = HORIZONTAL_ALIGNMENT_CENTER,
		accent: Color = GOLD
	) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.08, 0.65))
	label.position = rect.position
	label.size = rect.size
	label.clip_text = false
	return label


## 角色/物品立绘底板：在素材下方垫一块圆角暗色石板 + 柔光，
## 让透明立绘不再直接漂浮在繁忙背景上，消除「硬贴」感。
static func add_art_plate(parent: Control, rect: Rect2, accent: Color = BORDER) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ArtPlate"
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.06, 0.11, 0.90)
	style.border_color = accent.darkened(0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	# 内部径向柔光，让角色身体底部融入暗底
	var glow := GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([
		Color(0.22, 0.30, 0.50, 0.30),
		Color(0.10, 0.14, 0.26, 0.10),
		Color(0.0, 0.0, 0.0, 0.0),
	])
	glow.gradient = g
	glow.width = 800
	glow.height = 800
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.35)
	glow.fill_to = Vector2(0.5, 0.95)
	var glow_view := TextureRect.new()
	glow_view.texture = glow
	glow_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_view.stretch_mode = TextureRect.STRETCH_SCALE
	glow_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(glow_view)
	return panel

static func _show_top_right_detail(parent: Control) -> void:
	var lines := []
	lines.append("—— 队伍成员 ——")
	for actor in Run.party:
		var key: String = actor.get("key", "")
		var role := "前台" if actor.get("role", "front") == "front" else "后台"
		lines.append("%s [%s] Lv.%d HP %d/%d 攻 %d" % [
			actor["name"], role, actor.get("level", 1),
			actor["hp"], actor["max_hp"], actor["atk"]])
	lines.append("")
	lines.append("—— 已装备 ——")
	for actor in Run.party:
		var eq := Run._equipment_list_for(actor.get("key", ""))
		if eq.is_empty():
			continue
		lines.append("%s：" % actor["name"])
		for item_key in eq:
			if item_key == "":
				continue
			lines.append("  " + Run.item_detail(item_key).replace("\n", " "))
	lines.append("")
	lines.append("—— 联动效果 ——")
	var syns := Run.active_synergy_names()
	lines.append("无" if syns.is_empty() else "、".join(syns))
	lines.append("")
	lines.append("—— 探索状态 ——")
	lines.append("压力 %d　梦蚀 %d　记忆残片 %d" % [
		Run.dream_pressure, Run.dream_corruption, Run.memory_fragments])
	GlobalDetails.show_text_popup(parent, "效果详情", "\n".join(lines))

# ── frame helpers ────────────────────────────────────────────

## 各框素材九宫格的角边尺寸（单位：素材像素）。九宫格会按控件大小等比缩放，
## 只保留四角纹饰与顶/底装饰不变形，仅拉伸边框与中心，实现「按比例缩放并铺满」。
const FRAME_MARGINS := {
	0: 120,   # 大外框：复杂的四角纹饰 + 顶中宝石
	1: 84,    # 对话框：圆角描边 + 顶/底宝石
	2: 84,    # 方形框
	3: 84,    # 横框
	4: 70,    # 小横框
}

static func add_frame(parent: Control, frame_id: int, rect: Rect2, tint: Color = Color(1, 1, 1, 0.88)) -> NinePatchRect:
	var texture := ArtAssets.frame(frame_id)
	if texture == null:
		return null
	var patch := NinePatchRect.new()
	patch.name = "Frame_%d" % frame_id
	# 九宫格边距按矩形自适应钳制：宁可四角略小，也不让边距超过框的 45%，
	# 避免小尺寸框（如标题条）因边距大于高度而塌陷。
	var margin: float = FRAME_MARGINS.get(frame_id, 84)
	margin = clampf(margin, 6.0, min(rect.size.x, rect.size.y) * 0.45)
	patch.patch_margin_left = int(margin)
	patch.patch_margin_top = int(margin)
	patch.patch_margin_right = int(margin)
	patch.patch_margin_bottom = int(margin)
	patch.texture = texture
	patch.position = rect.position
	patch.size = rect.size
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	patch.modulate = tint
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(patch)
	return patch

static func add_frame_centered(parent: Control, frame_id: int, size: Vector2, tint: Color = Color(1, 1, 1, 0.88)) -> NinePatchRect:
	var pos := (Vector2(1280, 800) - size) / 2.0
	return add_frame(parent, frame_id, Rect2(pos, size), tint)

static func add_asset_background(root: Control, key: String, tint: Color = Color(1, 1, 1, 0.82)) -> void:
	## Use a generated scene background when present, while preserving the fallback gradient.
	add_dream_background(root)
	_add_generated_backdrop(root, ArtAssets.background(key), tint)
	_add_dim_overlay(root, key)


static func add_event_background(root: Control, key: String, tint: Color = Color(1, 1, 1, 0.9)) -> void:
	## 奇遇专属插画背景：按事件 ID 读取 event_*.png；缺失时回退到通用场景渐变。
	add_dream_background(root)
	_add_generated_backdrop(root, ArtAssets.event_background(key), tint)
	_add_dim_overlay(root, key)


## 画一层半透明深色遮罩 + 上下渐晕，让明亮的场景插画退到背景，
## 保证前景文字与卡片的可读性，也统一所有场景的影调。
static func _add_dim_overlay(root: Control, key: String) -> void:
	if root.get_node_or_null("BackgroundDim") != null:
		return
	var dim := ColorRect.new()
	dim.name = "BackgroundDim"
	dim.color = Color(0.012, 0.018, 0.045, 0.14)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	# 让遮罩位于生成背景之上、所有 UI 之下
	var backdrop := root.get_node_or_null("GeneratedBackdrop")
	if backdrop != null:
		var idx := backdrop.get_index()
		root.move_child(dim, idx + 1)

	# 中央径向提亮，聚焦视觉中心并柔化压暗后的死黑
	var glow := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.10, 0.16, 0.30, 0.20),
		Color(0.06, 0.10, 0.20, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
	])
	glow.gradient = gradient
	glow.width = 1200
	glow.height = 760
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.42)
	glow.fill_to = Vector2(0.5, 0.92)
	var glow_view := TextureRect.new()
	glow_view.texture = glow
	glow_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_view.stretch_mode = TextureRect.STRETCH_SCALE
	glow_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_view.z_index = -1
	dim.add_child(glow_view)


static func _add_generated_backdrop(root: Control, texture: Texture2D, tint: Color) -> void:
	if texture == null:
		return
	var backdrop := TextureRect.new()
	backdrop.name = "GeneratedBackdrop"
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = tint
	backdrop.position = Vector2(0, 0)
	backdrop.size = Vector2(1280, 800)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	root.move_child(backdrop, 1)


static func panel_style(
		fill: Color = PANEL,
		border: Color = BORDER,
		radius: int = 12
	) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.36)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


static func button_style(
		fill: Color,
		border: Color,
		border_width: int = 1,
		radius: int = 10
	) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


static func style_primary_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color(0.54, 0.34, 0.10), GOLD, 2, 12))
	button.add_theme_stylebox_override("hover", button_style(Color(0.70, 0.45, 0.13), GOLD.lightened(0.20), 2, 12))
	button.add_theme_stylebox_override("pressed", button_style(Color(0.38, 0.22, 0.08), GOLD, 2, 12))
	button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


static func style_card_button(button: Button, accent: Color) -> void:
	button.add_theme_stylebox_override("normal", button_style(PANEL_LIGHT, accent.darkened(0.15), 2, 10))
	button.add_theme_stylebox_override("hover", button_style(PANEL_LIGHT.lightened(0.06), accent, 2, 10))
	button.add_theme_stylebox_override("pressed", button_style(PANEL_LIGHT.darkened(0.10), accent.lightened(0.18), 2, 10))


static func make_panel(
		position: Vector2,
		size: Vector2,
		accent: Color = BORDER,
		fill: Color = PANEL
	) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", panel_style(fill, accent, 14))
	return panel


static func progress_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.055, 0.95)
	style.border_color = Color(0.25, 0.30, 0.42, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


static func progress_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.32, 0.72, 0.55)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.25, 0.90, 0.65, 0.28)
	style.shadow_size = 1
	return style


static func separator_style(color: Color) -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = color
	style.thickness = 1
	return style
