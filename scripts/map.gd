extends Control
## 边走边构筑的节点地图：普通位置先选卡，精英与首领固定。

const NODE_NAMES := {
	"battle": "镇守",
	"event": "奇遇",
	"reward": "奖励",
	"recruit": "招募",
	"shop": "商店",
	"rest": "恢复",
	"elite": "精英",
	"boss": "首领",
	"branch": "岔路",
}

const BATTLE_NODE_TYPES := ["battle", "elite", "boss"]

const NODE_COLORS := {
	"battle": Color(0.72, 0.28, 0.28),
	"event": Color(0.25, 0.45, 0.72),
	"reward": Color(0.82, 0.42, 0.18),
	"recruit": Color(0.25, 0.65, 0.68),
	"shop": Color(0.72, 0.58, 0.2),
	"rest": Color(0.22, 0.58, 0.36),
	"elite": Color(0.58, 0.3, 0.68),
	"boss": Color(0.55, 0.12, 0.12),
	"branch": Color(0.45, 0.45, 0.45),
}

var _layer_label: Label
var _status_label: Label
var _player_label: Label
var _node_box: HBoxContainer
var _node_scroll: ScrollContainer
var _action_box: HBoxContainer
var _notice := ""   # 一次性提示（如"在营地休息回复 X 点"）


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "map")
	UITheme.add_top_right_status(self)
	_build_ui()
	if not Run.run_started:
		Run.start_run()
	_refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.025, 0.06, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.07, 0.13, 0.90)
	panel.position = Vector2(24, 100)
	panel.size = Vector2(1232, 150)
	add_child(panel)

	_layer_label = Label.new()
	_layer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_layer_label.add_theme_font_size_override("font_size", 30)
	_layer_label.position = Vector2(48, 20)
	_layer_label.size = Vector2(680, 44)
	add_child(_layer_label)

	_player_label = Label.new()
	_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_player_label.add_theme_font_size_override("font_size", 18)
	_player_label.position = Vector2(24, 66)
	_player_label.size = Vector2(1200, 32)
	_player_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_player_label)

	_node_scroll = ScrollContainer.new()
	_node_scroll.position = Vector2(36, 108)
	_node_scroll.size = Vector2(1208, 120)
	_node_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_node_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_node_scroll)

	_node_box = HBoxContainer.new()
	_node_box.custom_minimum_size = Vector2(1200, 112)
	_node_box.add_theme_constant_override("separation", 5)
	_node_scroll.add_child(_node_box)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 20)
	_status_label.position = Vector2(24, 256)
	_status_label.size = Vector2(1200, 150)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_status_label)

	_action_box = HBoxContainer.new()
	_action_box.position = Vector2(36, 434)
	_action_box.size = Vector2(1200, 90)
	_action_box.add_theme_constant_override("separation", 16)
	add_child(_action_box)

	var abandon := Button.new()
	abandon.text = "放弃本局"
	abandon.position = Vector2(1082, 738)
	abandon.size = Vector2(128, 40)
	abandon.add_theme_font_size_override("font_size", 15)
	abandon.pressed.connect(_on_abandon)
	add_child(abandon)


func _on_abandon() -> void:
	Run.run_started = false
	get_tree().change_scene_to_file("res://scenes/select.tscn")


func _refresh() -> void:
	_layer_label.text = "梦境航线"
	if Run.planning:
		_status_label.text = "正在打开节点卡组，请为第 %d 格选择节点……" % (Run.node_pos + 1)
		for child in _action_box.get_children():
			child.queue_free()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/planning.tscn")
		return
	if Run.player.is_empty():
		_player_label.text = ""
	else:
		_player_label.text = "%s　HP %d/%d　金币 %d　探索 Lv.%d　压力 %d　梦蚀 %d" % [
			Run.player["name"], Run.player["hp"], Run.player["max_hp"],
			Run.gold, Run.exploration_level, Run.dream_pressure, Run.dream_corruption]
		_player_label.text += "　队伍 %d 人" % Run.party.size()

	for child in _node_box.get_children():
		child.queue_free()
	for i in Run.nodes.size():
		_node_box.add_child(_make_card(Run.nodes[i], i, i == Run.node_pos))

	var status := ""
	var result_notice := Run.take_notice()
	if Run.finished:
		status = "你已击破首领，梦境暂时恢复平静。"
	elif Run.at_layer_end():
		status = "节点已全部探索，准备结算。"
	else:
		var node_level: int = int(Run.node_levels[Run.node_pos]) if Run.node_pos < Run.node_levels.size() else 1
		status = "当前位置：%s Lv.%d　综合强度 %d　进度 %d / %d\n%s　记忆残片 %d" % [
			NODE_NAMES.get(Run.current_node(), "待选择"),
			node_level, Run.effective_tier(node_level),
			Run.node_pos + 1, Run.nodes.size(),
			Run.exploration_progress_text(), Run.memory_fragments]
	if result_notice != "":
		status = result_notice + "\n" + status
	if _notice != "":
		status = _notice + "\n" + status
		_notice = ""
	_status_label.text = status
	_refresh_actions()


func _make_card(type_name: String, index: int, is_current: bool) -> PanelContainer:
	var rect := PanelContainer.new()
	rect.custom_minimum_size = Vector2(78, 108)
	var base: Color = NODE_COLORS.get(type_name, Color(0.4, 0.4, 0.4))
	if type_name == "":
		base = Color(0.13, 0.17, 0.28)
	var fill := base.lightened(0.04) if is_current else base.darkened(0.25)
	var border := Color(1.0, 0.80, 0.32) if is_current else base.lightened(0.28)
	var style := FontHelper.panel_style(fill, border, 9)
	style.set_border_width_all(3 if is_current else 1)
	style.shadow_color = Color(border, 0.32 if is_current else 0.18)
	style.shadow_size = 8 if is_current else 4
	rect.add_theme_stylebox_override("panel", style)
	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(content)
	var label := Label.new()
	if type_name == "":
		label.text = "待选"
	else:
		label.text = NODE_NAMES.get(type_name, type_name)
	var icon := ArtAssets.add_texture(
		content,
		ArtAssets.node(type_name),
		Rect2(Vector2(6, 10), Vector2(54, 54)))
	if icon.texture == null:
		icon.queue_free()
	label.add_theme_font_size_override("font_size", 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.clip_text = true
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	if type_name == "":
		label.position = Vector2(0, 0)
		label.size = Vector2(78, 108)
	else:
		label.position = Vector2(0, 66)
		label.size = Vector2(78, 30)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return rect


func _refresh_actions() -> void:
	for child in _action_box.get_children():
		child.queue_free()
	if Run.finished:
		return
	if Run.at_layer_end():
		_add_action_button("完成探索并结算", _on_finish)
	elif Run.is_branch():
		_add_action_button("左路：2 场战斗（高收益）", _on_choose_left)
		_add_action_button("右路：事件 + 休息（稳妥）", _on_choose_right)
	elif Run.current_node() in BATTLE_NODE_TYPES:
		_add_action_button("进入战斗", _on_advance)
	else:
		_add_action_button("进入当前节点", _on_advance)


func _add_action_button(text: String, callable: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 64)
	button.add_theme_font_size_override("font_size", 18)
	FontHelper.style_primary(button)
	button.pressed.connect(callable)
	_action_box.add_child(button)


func _on_advance() -> void:
	var node_type := Run.current_node()
	if node_type in BATTLE_NODE_TYPES:
		Run.enter_battle()
		get_tree().change_scene_to_file("res://scenes/equipment.tscn")
	elif node_type == "rest":
		var healed: int = int(Run.player["max_hp"] * 0.35)
		Run.player["hp"] = mini(Run.player["max_hp"], Run.player["hp"] + healed)
		Run.set_notice("在营地休息，回复 %d 点生命" % healed)
		Run.advance()
		_refresh()
	elif node_type == "shop":
		get_tree().change_scene_to_file("res://scenes/shop.tscn")
	elif node_type == "event":
		Run.pick_event()
		get_tree().change_scene_to_file("res://scenes/event.tscn")
	elif node_type == "reward":
		get_tree().change_scene_to_file("res://scenes/reward.tscn")
	elif node_type == "recruit":
		get_tree().change_scene_to_file("res://scenes/recruit.tscn")
	else:
		Run.set_notice("前方无事发生")
		Run.advance()
		_refresh()


func _on_choose_left() -> void:
	Run.choose_route(Run.BRANCH_LEFT)
	_refresh()


func _on_choose_right() -> void:
	Run.choose_route(Run.BRANCH_RIGHT)
	_refresh()


func _on_next_layer() -> void:
	Run.next_layer()
	_refresh()


func _on_finish() -> void:
	Run.finished = true
	get_tree().change_scene_to_file("res://scenes/settle.tscn")
