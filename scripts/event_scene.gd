extends Control
## 奇遇节点（v6 UI 改造：0号背景 + 1号选择框，移除查看效果）

const BG := Color(0.035, 0.043, 0.075)
const PANEL := Color(0.075, 0.09, 0.14)

var _title: Label
var _desc_label: Label
var _result_label: Label
var _choice_box: VBoxContainer
var _result_panel: Control
var _continue_button: Button
var _pending_result: Dictionary = {}
var _resolved := false


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	Run.pick_event()
	UITheme.add_event_background(
		self, str(Run.current_event.get("id", "")))
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	_title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.36))
	_title.position = Vector2(0, 50)
	_title.size = Vector2(1280, 50)
	add_child(_title)

	_desc_label = Label.new()
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.add_theme_font_size_override("font_size", 20)
	_desc_label.add_theme_color_override("font_color", Color(0.76, 0.80, 0.92))
	_desc_label.position = Vector2(64, 110)
	_desc_label.size = Vector2(1152, 80)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_desc_label)

	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(215, 265)
	_choice_box.size = Vector2(850, 350)
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 10)
	add_child(_choice_box)

	_result_panel = Control.new()
	_result_panel.visible = false
	_result_panel.position = Vector2(64, 160)
	_result_panel.size = Vector2(1152, 500)
	add_child(_result_panel)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 20)
	_result_label.position = Vector2(0, 0)
	_result_label.size = Vector2(1152, 400)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_result_panel.add_child(_result_label)

	_continue_button = Button.new()
	_continue_button.text = "继续探索"
	_continue_button.position = Vector2(0, 420)
	_continue_button.size = Vector2(1152, 70)
	_continue_button.add_theme_font_size_override("font_size", 22)
	FontHelper.style_primary(_continue_button)
	_continue_button.pressed.connect(_continue_after_result)
	_result_panel.add_child(_continue_button)

	_refresh()


func _refresh() -> void:
	var event: Dictionary = Run.current_event
	if event.is_empty():
		_title.text = "事件暂时无法触发"
		_desc_label.text = "请返回地图继续探索。"
		return
	_title.text = event.get("title", "未知奇遇")
	_desc_label.text = event.get("text", "")
	for child in _choice_box.get_children():
		child.queue_free()
	var choices: Array = event.get("choices", [])
	for choice in choices:
		if not _is_choice_valid(choice):
			continue
		var button := Button.new()
		button.text = choice.get("text", "选择")
		button.custom_minimum_size = Vector2(790, 80)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", 17)
		button.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		button.clip_text = true
		var accent := Color(0.26, 0.44, 0.66)
		if choice.has("risk"):
			accent = Color(0.72, 0.32, 0.28)
		elif choice.has("reward"):
			accent = Color(0.28, 0.62, 0.44)
		FontHelper.style_card(button, accent)
		button.pressed.connect(_on_choice.bind(choice))
		_choice_box.add_child(button)



func _is_choice_valid(choice: Dictionary) -> bool:
	var condition: Dictionary = choice.get("condition", {})
	if condition.is_empty():
		return true
	return _evaluate_condition(condition)

func _evaluate_condition(_condition: Dictionary) -> bool:
	return Run.event_condition_met(_condition)


func _on_choice(choice: Dictionary) -> void:
	if _resolved:
		return
	var resolution: Dictionary = Run.resolve_event_choice(choice)
	if not resolution.get("valid", false):
		return
	_resolved = true
	_pending_result = Run.apply_event(resolution.get("effect", {}))
	var resolved_effect: Dictionary = resolution.get("effect", {})
	var event_xp: int = int(resolution.get("exploration_xp", 0))
	if event_xp > 0:
		Run.gain_exploration_xp(event_xp, "奇遇探索")
	_result_label.text = resolution.get("text", "奇遇结果已经揭晓。")
	if resolved_effect.has("item"):
		_result_label.text += "\n\n" + Run.item_detail(resolved_effect["item"])
	if resolved_effect.has("reward"):
		_result_label.text += "\n\n奖励详情：" + Run.reward_text(resolved_effect["reward"])
	if not _pending_result.get("gained_cards", []).is_empty():
		_result_label.text += "\n\n获得节点卡：" + Run.node_card_list_text(_pending_result["gained_cards"])
	if event_xp > 0:
		_result_label.text += "\n探索经验 +%d" % event_xp
		var xp_notice := Run.take_exploration_notice()
		if xp_notice.contains("提升至"):
			_result_label.text += "\n" + xp_notice
	_choice_box.visible = false
	_result_panel.visible = true
	if Run.player["hp"] <= 0:
		_continue_button.text = "查看结算"
	elif _pending_result.get("battle", false):
		_continue_button.text = "准备迎战"


func _continue_after_result() -> void:
	if Run.player["hp"] <= 0:
		Run.run_started = false
		get_tree().change_scene_to_file("res://scenes/settle.tscn")
		return
	if _pending_result.get("battle", false):
		get_tree().change_scene_to_file("res://scenes/equipment.tscn")
		return
	Run.set_notice("奇遇结果：" + _result_label.text)
	Run.advance()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
func _evaluate_any(conditions: Array) -> bool:
	for cond in conditions:
		if _evaluate_condition(cond):
			return true
	return false

func _evaluate_all(conditions: Array) -> bool:
	for cond in conditions:
		if not _evaluate_condition(cond):
			return false
	return true
