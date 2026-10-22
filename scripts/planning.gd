extends Control
## 节点卡组界面：每次抵达普通路线格时选择一张卡；同类型同等级三合一。

const NODE_NAMES := {
	"battle": "镇守", "event": "奇遇", "reward": "奖励", "recruit": "招募",
	"shop": "商店", "rest": "恢复", "elite": "精英", "boss": "首领"
}
const NODE_ORDER := ["battle", "event", "reward", "recruit", "shop", "rest"]
const NODE_COLORS := {
	"battle": Color(0.57, 0.27, 0.27), "event": Color(0.26, 0.44, 0.66),
	"reward": Color(0.67, 0.43, 0.20), "recruit": Color(0.22, 0.55, 0.57),
	"shop": Color(0.64, 0.54, 0.21), "rest": Color(0.25, 0.54, 0.36),
	"elite": Color(0.45, 0.30, 0.58), "boss": Color(0.55, 0.16, 0.21),
	"empty": Color(0.13, 0.17, 0.28)
}

var _status: Label
var _card_grid: GridContainer
var _merge_box: VBoxContainer
var _route_box: HBoxContainer
var _route_scroll: ScrollContainer


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "map")
	UITheme.add_top_right_status(self)
	var fallback := get_node_or_null("Fallback")
	# 直接运行此场景时也能初始化；正常流程不会重置已经进行中的本局。
	if Run.player.is_empty() or Run.planned_slots.size() != 13:
		Run.start_run()
	_build_ui()
	_refresh()
	if fallback != null:
		fallback.visible = false


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.015, 0.025, 0.06, 0.18)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var header := ColorRect.new()
	header.color = Color(0.06, 0.085, 0.16, 0.88)
	header.position = Vector2(24, 18)
	header.size = Vector2(1232, 104)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var title := Label.new()
	title.text = "选择下一个节点"
	title.position = Vector2(48, 34)
	title.size = Vector2(500, 40)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.79, 0.37))
	add_child(title)

	var help := Label.new()
	help.text = "选择或拖动一张牌，放入当前空位。"
	help.position = Vector2(48, 72)
	help.size = Vector2(580, 44)
	help.add_theme_font_size_override("font_size", 15)
	help.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	help.add_theme_color_override("font_color", Color(0.72, 0.76, 0.85))
	add_child(help)

	_status = Label.new()
	_status.position = Vector2(48, 124)
	_status.size = Vector2(1184, 74)
	_status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status.add_theme_font_size_override("font_size", 15)
	add_child(_status)

	var route_title := Label.new()
	route_title.text = "本层航线（第 4、8 格为精英，第 13 格为首领）"
	route_title.position = Vector2(34, 204)
	route_title.size = Vector2(700, 28)
	route_title.add_theme_font_size_override("font_size", 18)
	add_child(route_title)

	_route_scroll = ScrollContainer.new()
	_route_scroll.position = Vector2(34, 232)
	_route_scroll.size = Vector2(1200, 112)
	_route_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_route_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_route_scroll)

	_route_box = HBoxContainer.new()
	_route_box.custom_minimum_size = Vector2(1200, 104)
	_route_box.add_theme_constant_override("separation", 4)
	_route_scroll.add_child(_route_box)

	var deck_title := Label.new()
	deck_title.text = "节点卡组"
	deck_title.position = Vector2(34, 356)
	deck_title.size = Vector2(500, 30)
	deck_title.add_theme_font_size_override("font_size", 20)
	add_child(deck_title)

	var card_scroll := ScrollContainer.new()
	card_scroll.position = Vector2(34, 394)
	card_scroll.size = Vector2(716, 290)
	add_child(card_scroll)

	_card_grid = GridContainer.new()
	_card_grid.columns = 3
	_card_grid.custom_minimum_size = Vector2(710, 0)
	_card_grid.add_theme_constant_override("h_separation", 10)
	_card_grid.add_theme_constant_override("v_separation", 10)
	card_scroll.add_child(_card_grid)

	var merge_panel := ColorRect.new()
	merge_panel.color = Color(0.055, 0.075, 0.135, 0.92)
	merge_panel.position = Vector2(792, 356)
	merge_panel.size = Vector2(376, 328)
	merge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(merge_panel)

	var merge_title := Label.new()
	merge_title.text = "三合一升级"
	merge_title.position = Vector2(812, 370)
	merge_title.size = Vector2(336, 30)
	merge_title.add_theme_font_size_override("font_size", 20)
	add_child(merge_title)

	var merge_help := Label.new()
	merge_help.text = "3 张同类牌 → 1 张高一级牌"
	merge_help.position = Vector2(812, 402)
	merge_help.size = Vector2(336, 48)
	merge_help.add_theme_font_size_override("font_size", 15)
	merge_help.add_theme_color_override("font_color", Color(0.72, 0.76, 0.85))
	add_child(merge_help)

	var merge_scroll := ScrollContainer.new()
	merge_scroll.position = Vector2(808, 460)
	merge_scroll.size = Vector2(344, 208)
	add_child(merge_scroll)

	_merge_box = VBoxContainer.new()
	_merge_box.custom_minimum_size = Vector2(324, 0)
	_merge_box.add_theme_constant_override("separation", 8)
	merge_scroll.add_child(_merge_box)


func _refresh() -> void:
	if _card_grid == null or _merge_box == null or _route_box == null:
		return
	var groups := _card_groups()
	Run.take_notice()  # 消费遗留提示，但规划界面只展示节点信息，不显示事件/奖励结果
	_status.text = "当前位置：%d / 13\n卡组：%d 张　待选：%d 格" % [
		Run.node_pos + 1, Run.available_cards.size(), Run.remaining_choice_slots()]

	for child in _route_box.get_children():
		child.queue_free()
	for index in 13:
		var card = Run.planned_slots[index]
		var text := "%d\n" % (index + 1)
		var color: Color = NODE_COLORS["empty"]
		if card == null:
			text += "待选" if index == Run.node_pos else "？"
		else:
			text += "%s\nLv.%d" % [
				NODE_NAMES.get(card["type"], card["type"]),
				int(card.get("level", 1))]
			color = NODE_COLORS.get(card["type"], NODE_COLORS["empty"])
		var route_card := _make_button(
			text, color, Vector2(78, 110),
			"" if card == null else str(card.get("type", "")))
		route_card.focus_mode = Control.FOCUS_NONE
		route_card.mouse_filter = Control.MOUSE_FILTER_STOP
		route_card.set_drag_forwarding(
			_get_no_drag_data,
			_can_drop_route.bind(index),
			_drop_route.bind(index))
		_route_box.add_child(route_card)

	for child in _card_grid.get_children():
		child.queue_free()
	for type_name in NODE_ORDER:
		for level in range(1, _max_level(groups, type_name) + 1):
			var key := _group_key(type_name, level)
			var count: int = int(groups.get(key, 0))
			if count <= 0:
				continue
			var button := _make_button(
				"%s　Lv.%d\n持有 ×%d\n点击放置" % [
					NODE_NAMES[type_name], level, count],
				NODE_COLORS[type_name],
				Vector2(228, 104),
				type_name)
			button.pressed.connect(_choose_card.bind(type_name, level))
			button.set_drag_forwarding(
				_get_card_drag_data.bind(type_name, level),
				_can_drop_any,
				_drop_noop)
			_card_grid.add_child(button)

	for child in _merge_box.get_children():
		child.queue_free()
	var has_recipe := false
	for type_name in NODE_ORDER:
		for level in range(1, _max_level(groups, type_name) + 1):
			var count: int = int(groups.get(_group_key(type_name, level), 0))
			if count < 3:
				continue
			has_recipe = true
			var merge := Button.new()
			merge.text = "%s Lv.%d ×3 → Lv.%d" % [
				NODE_NAMES[type_name], level, level + 1]
			merge.custom_minimum_size = Vector2(286, 50)
			merge.add_theme_font_size_override("font_size", 16)
			merge.disabled = not Run.can_merge_node_cards(type_name, level)
			merge.tooltip_text = "需要保留足够节点卡走完航线" if merge.disabled else "点击合成"
			merge.pressed.connect(_merge_cards.bind(type_name, level))
			_merge_box.add_child(merge)
	if not has_recipe:
		var empty := Label.new()
		empty.text = "暂时没有可合成的节点卡。\n继续探索可获得更多卡牌。"
		empty.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		empty.add_theme_font_size_override("font_size", 16)
		_merge_box.add_child(empty)


func _card_groups() -> Dictionary:
	var groups := {}
	for card in Run.available_cards:
		var key := _group_key(card["type"], int(card.get("level", 1)))
		groups[key] = int(groups.get(key, 0)) + 1
	return groups


func _group_key(type_name: String, level: int) -> String:
	return "%s:%d" % [type_name, level]


func _max_level(groups: Dictionary, type_name: String) -> int:
	var result := 1
	for level in range(1, 20):
		if groups.has(_group_key(type_name, level)):
			result = level
	return result


func _make_button(
		label_text: String,
		color: Color,
		minimum_size: Vector2,
		node_type: String = ""
	) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = minimum_size
	button.clip_contents = true
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override(
		"normal", FontHelper.button_style(color.darkened(0.28), color.lightened(0.18), 2, 10))
	button.add_theme_stylebox_override(
		"hover", FontHelper.button_style(color.darkened(0.12), color.lightened(0.38), 2, 10))
	button.add_theme_stylebox_override(
		"pressed", FontHelper.button_style(color.darkened(0.40), Color(0.96, 0.78, 0.34), 2, 10))
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	var compact := minimum_size.x < 100.0
	var icon_size := Vector2(58, 58) if compact else Vector2(76, 76)
	var icon_pos := Vector2((minimum_size.x - icon_size.x) / 2.0, 6) if compact else Vector2(10, 10)
	var icon := ArtAssets.add_texture(button, ArtAssets.node(node_type), Rect2(icon_pos, icon_size))
	if icon.texture == null:
		icon.queue_free()
	var label := Label.new()
	label.text = label_text
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if compact:
		label.position = Vector2(0, 58)
		label.size = Vector2(minimum_size.x, minimum_size.y - 58)
		label.add_theme_font_size_override("font_size", 12)
	else:
		var has_art := ArtAssets.enabled()
		label.position = Vector2(96, 8) if has_art else Vector2(16, 8)
		label.size = Vector2(minimum_size.x - 106, minimum_size.y - 16) if has_art else Vector2(minimum_size.x - 32, minimum_size.y - 16)
	button.add_child(label)
	return button


func _choose_card(type_name: String, level: int) -> void:
	for index in Run.available_cards.size():
		var card: Dictionary = Run.available_cards[index]
		if card["type"] == type_name and int(card.get("level", 1)) == level:
			if Run.choose_node_card(index):
				get_tree().change_scene_to_file("res://scenes/map.tscn")
			return


func _get_card_drag_data(_at_position: Vector2, type_name: String, level: int) -> Variant:
	return {"node_type": type_name, "level": level}


func _get_no_drag_data(_at_position: Vector2) -> Variant:
	return null


func _can_drop_any(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("node_type") and data.has("level")


func _drop_noop(_at_position: Vector2, _data: Variant) -> void:
	pass


func _can_drop_route(_at_position: Vector2, data: Variant, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= Run.planned_slots.size():
		return false
	if slot_index != Run.node_pos or Run.planned_slots[slot_index] != null:
		return false
	return _can_drop_any(_at_position, data)


func _drop_route(_at_position: Vector2, data: Variant, slot_index: int) -> void:
	if not _can_drop_route(_at_position, data, slot_index):
		return
	_choose_card(str(data["node_type"]), int(data["level"]))


func _merge_cards(type_name: String, level: int) -> void:
	if Run.merge_node_cards(type_name, level):
		_refresh()
	else:
		_status.text = "无法合成：必须保留足够卡牌走完剩余路线。"
