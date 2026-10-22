extends Control
## 招募节点：玩家从候选入梦师中自主选择一名加入队伍。

const BG := Color(0.035, 0.043, 0.075)
const PANEL := Color(0.075, 0.09, 0.14)
const ACCENT := Color(0.45, 0.86, 0.84)

var _title: Label
var _candidate_box: VBoxContainer
var _recruit_candidates: Array = []
var _recruit_event: Dictionary = {}
var _node_level := 1


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "recruit")
	_node_level = int(Run.node_levels[Run.node_pos]) if Run.node_pos < Run.node_levels.size() else 1
	_node_level = clampi(_node_level, 1, 3)
	_recruit_candidates = Run.begin_recruit_visit(4)
	var recruit_event_count: int = mini(
		GameData.ACTIVE_RECRUIT_EVENT_COUNT, GameData.RECRUIT_EVENTS.size())
	_recruit_event = GameData.RECRUIT_EVENTS[randi() % recruit_event_count]
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(BG, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := FontHelper.make_panel(
		Vector2(32, 32), Vector2(1216, 736),
		Color(0.34, 0.76, 0.73, 0.78),
		Color(0.045, 0.07, 0.12, 0.93))
	add_child(panel)

	_title = Label.new()
	_title.text = "%s Lv.%d · 第 %d 批信号　｜　队伍 %d/%d（前台 %d/3，后台 %d/3）" % [
		_recruit_event["title"], _node_level, Run.recruit_visit_index,
		Run.party.size(), Run.MAX_PARTY_SIZE,
		Run._party_role_count("front"), Run._party_role_count("back")]
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", ACCENT)
	_title.position = Vector2(0, 58)
	_title.size = Vector2(1280, 52)
	add_child(_title)

	var help := Label.new()
	help.text = _recruit_event["text"]
	if _node_level >= 2:
		help.text += "　本次锚定可让新角色以 Lv.%d 入队，也可连续培养已有角色。" % _node_level
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", Color(0.74, 0.80, 0.89))
	help.position = Vector2(48, 122)
	help.size = Vector2(1184, 54)
	help.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(help)

	var candidate_scroll := ScrollContainer.new()
	candidate_scroll.position = Vector2(48, 188)
	candidate_scroll.size = Vector2(1184, 532)
	candidate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(candidate_scroll)

	_candidate_box = VBoxContainer.new()
	_candidate_box.custom_minimum_size = Vector2(1168, 0)
	_candidate_box.add_theme_constant_override("separation", 12)
	candidate_scroll.add_child(_candidate_box)


func _refresh() -> void:
	for child in _candidate_box.get_children():
		child.queue_free()
	var recruited := {}
	for actor in Run.party:
		recruited[actor.get("key", "")] = true
	var has_candidate := false
	var has_art := ArtAssets.enabled()
	for actor in Run.party:
		var key: String = actor.get("key", "")
		var level: int = int(actor.get("level", 1))
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(1168, 204)
		row.add_theme_constant_override("separation", 10)
		_candidate_box.add_child(row)
		var button := Button.new()
		var training_steps := mini(
			_node_level, maxi(0, GameData.MAX_CHARACTER_LEVEL - level))
		var target_level := level + training_steps
		var unlock_text := _growth_preview(key, level, training_steps)
		var resource_text := (
			"体力上限 +%d" % training_steps
			if actor.get("role", "front") == "front"
			else "魔力上限 +%d" % training_steps
		)
		button.text = ""
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(980, 204)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_contents = true
		button.add_theme_font_size_override("font_size", 15)
		button.disabled = training_steps <= 0
		FontHelper.style_card(button, Color(0.65, 0.48, 0.84))
		var upgrade_portrait := ArtAssets.add_texture(
			button,
			ArtAssets.character(key),
			Rect2(Vector2(12, 12), Vector2(156, 156)))
		if upgrade_portrait.texture == null:
			upgrade_portrait.queue_free()
		var upgrade_info := Label.new()
		var target_name := (
			"MAX" if target_level >= GameData.MAX_CHARACTER_LEVEL
			else "Lv.%d" % target_level)
		if training_steps <= 0:
			upgrade_info.text = "%s　已达到 MAX（Lv.%d）\n本角色本局已完成全部培养与突破。" % [
				actor["name"], level]
		else:
			upgrade_info.text = "培养 %s　Lv.%d → %s（连续 %d 段）\n生命与攻击将按突破阶段成长　%s\n%s" % [
				actor["name"], level, target_name, training_steps,
				resource_text,
				unlock_text]
		upgrade_info.position = Vector2(188, 16) if has_art else Vector2(16, 16)
		upgrade_info.size = Vector2(768, 172) if has_art else Vector2(948, 172)
		upgrade_info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		upgrade_info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		upgrade_info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		upgrade_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		upgrade_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_info.add_theme_font_size_override("font_size", 15)
		button.add_child(upgrade_info)
		button.pressed.connect(_upgrade.bind(key))
		row.add_child(button)

		var detail := Button.new()
		detail.text = "培养详情"
		detail.custom_minimum_size = Vector2(170, 204)
		detail.add_theme_font_size_override("font_size", 15)
		FontHelper.style_card(detail, Color(0.76, 0.62, 0.32))
		detail.pressed.connect(_show_upgrade_detail.bind(key, training_steps))
		row.add_child(detail)

	for key in _recruit_candidates:
		var candidate_role: String = GameData.CHARACTERS[key].get("role", "front")
		var role_full := Run._party_role_count(candidate_role) >= Run.MAX_ROLE_SIZE
		if recruited.has(key) or Run.party.size() >= Run.MAX_PARTY_SIZE or role_full:
			continue
		has_candidate = true
		var character: Dictionary = GameData.CHARACTERS[key]
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(1168, 196)
		row.add_theme_constant_override("separation", 10)
		_candidate_box.add_child(row)
		var button := Button.new()
		var recruit_level := _node_level
		var level_steps := recruit_level - 1
		var recruit_hp: int = int(character["max_hp"]) + 6 * level_steps + (2 if level_steps >= 3 else 0)
		var recruit_atk: int = int(character["atk"]) + 3 * level_steps
		var recruit_stamina: int = int(character["max_stamina"]) + (
			level_steps if character["role"] == "front" else 0)
		var recruit_mana: int = int(character["max_mana"]) + (
			level_steps if character["role"] == "back" else 0)
		var recruit_growth_text := "基础技能：%s" % GameData.SKILLS[character["skill"]]["name"]
		if level_steps > 0:
			recruit_growth_text += "\n" + _growth_preview(key, 1, level_steps)
		button.text = ""
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(980, 196)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_contents = true
		button.add_theme_font_size_override("font_size", 15)
		FontHelper.style_card(
			button,
			Color(0.76, 0.35, 0.34) if character["role"] == "front" else Color(0.30, 0.65, 0.82))
		var recruit_portrait := ArtAssets.add_texture(
			button,
			ArtAssets.character(key),
			Rect2(Vector2(12, 10), Vector2(156, 154)))
		if recruit_portrait.texture == null:
			recruit_portrait.queue_free()
		var recruit_info := Label.new()
		recruit_info.text = "锚定：%s　[%s]　以 Lv.%d 入队\nHP %d　攻击 %d　体力 %d　魔力 %d\n%s" % [
			character["name"],
			"前台" if character["role"] == "front" else "后台",
			recruit_level,
			recruit_hp, recruit_atk, recruit_stamina, recruit_mana,
			recruit_growth_text]
		recruit_info.position = Vector2(188, 14) if has_art else Vector2(16, 14)
		recruit_info.size = Vector2(768, 166) if has_art else Vector2(948, 166)
		recruit_info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		recruit_info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		recruit_info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		recruit_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		recruit_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		recruit_info.add_theme_font_size_override("font_size", 15)
		button.add_child(recruit_info)
		button.pressed.connect(_recruit.bind(key))
		row.add_child(button)

		var detail := Button.new()
		detail.text = "角色详情"
		detail.custom_minimum_size = Vector2(170, 196)
		detail.add_theme_font_size_override("font_size", 15)
		FontHelper.style_card(detail, Color(0.76, 0.62, 0.32))
		detail.pressed.connect(_show_recruit_detail.bind(key, recruit_level))
		row.add_child(detail)
	if not has_candidate:
		var empty := Label.new()
		empty.text = "队伍已满或没有可招募角色。\n点击下方按钮继续探索。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 19)
		empty.custom_minimum_size = Vector2(1168, 90)
		_candidate_box.add_child(empty)
	var leave := Button.new()
	leave.text = "暂不招募，继续探索"
	leave.custom_minimum_size = Vector2(1168, 54)
	leave.add_theme_font_size_override("font_size", 18)
	FontHelper.style_card(leave, Color(0.42, 0.52, 0.68))
	leave.pressed.connect(_leave)
	_candidate_box.add_child(leave)


func _show_upgrade_detail(key: String, training_steps: int) -> void:
	var actor: Dictionary = Run._actor_for_key(key)
	var level: int = int(actor.get("level", 1))
	var target_level := mini(GameData.MAX_CHARACTER_LEVEL, level + training_steps)
	var lines := [
		"培养对象：%s　当前 Lv.%d → %s" % [
			actor.get("name", key),
			level,
			"MAX" if target_level >= GameData.MAX_CHARACTER_LEVEL else "Lv.%d" % target_level,
		],
		"角色定位：%s｜%s" % [
			"前台" if actor.get("role", "front") == "front" else "后台",
			GameData.CHARACTERS[key].get("action_mode", "标准行动"),
		],
	]
	if training_steps <= 0:
		lines.append("\n该角色已经完成全部培养与突破。")
	else:
		lines.append(
			"\n本次连续培养 %d 段。每段提升生命、攻击与资源上限；突破后成长更高。"
			% training_steps)
		lines.append("\n本次解锁内容：\n" + _growth_preview(key, level, training_steps))
	lines.append("\n当前已拥有技能：")
	for skill_key in actor.get("skills", [actor.get("skill", "")]):
		lines.append("• " + Run.skill_detail(skill_key).replace("\n", "；"))
	lines.append("\n当前已拥有被动：")
	var passive_count := 0
	if actor.get("starter_passive_active", false) and actor.has("starter_passive"):
		lines.append("• 入梦被动：" + Run.passive_detail(actor["starter_passive"]).replace("\n", "；"))
		passive_count += 1
	for passive in actor.get("growth_passives", []):
		lines.append("• " + Run.passive_detail(passive).replace("\n", "；"))
		passive_count += 1
	if passive_count == 0:
		lines.append("• 暂无已解锁培养被动")
	_append_equipment_and_synergy_details(lines, key)
	GlobalDetails.show_text_popup(self, "培养详情", "\n".join(lines))


func _show_recruit_detail(key: String, recruit_level: int) -> void:
	var character: Dictionary = GameData.CHARACTERS[key]
	var level_steps := maxi(0, recruit_level - 1)
	var hp: int = int(character["max_hp"]) + 6 * level_steps + (2 if level_steps >= 3 else 0)
	var atk: int = int(character["atk"]) + 3 * level_steps
	var stamina: int = int(character["max_stamina"]) + (
		level_steps if character["role"] == "front" else 0)
	var mana: int = int(character["max_mana"]) + (
		level_steps if character["role"] == "back" else 0)
	var lines := [
		"候选入梦师：%s　[%s]　以 Lv.%d 入队" % [
			character["name"],
			"前台" if character["role"] == "front" else "后台",
			recruit_level,
		],
		"战斗定位：%s" % character.get("action_mode", "标准行动"),
		"入队属性：生命 %d　攻击 %d　体力 %d　魔力 %d" % [
			hp, atk, stamina, mana],
		"\n入队后立即拥有：",
		"• " + Run.skill_detail(character["skill"]).replace("\n", "；"),
	]
	if level_steps > 0:
		lines.append("\n高等级入队同步解锁：\n" + _growth_preview(key, 1, level_steps))
	else:
		lines.append("\nLv.1 入队不会提前解锁培养技能和培养被动。")
	lines.append("\n后续完整成长路线：")
	var extra_skills: Array = GameData.CHARACTER_EXTRA_SKILLS.get(key, [])
	var passives: Array = GameData.CHARACTER_GROWTH_PASSIVES.get(key, [])
	for index in maxi(extra_skills.size(), passives.size()):
		var level_name := (
			"MAX"
			if index + 2 >= GameData.MAX_CHARACTER_LEVEL
			else "Lv.%d" % (index + 2))
		if index < extra_skills.size():
			lines.append(
				"• %s 技能：" % level_name
				+ Run.skill_detail(extra_skills[index]).replace("\n", "；"))
		if index < passives.size():
			lines.append(
				"• %s 被动：" % level_name
				+ Run.passive_detail(passives[index]).replace("\n", "；"))
	_append_equipment_and_synergy_details(lines, key)
	GlobalDetails.show_text_popup(self, "招募候选详情", "\n".join(lines))


func _append_equipment_and_synergy_details(lines: Array, key: String) -> void:
	var synergy_hints: Array = Run.character_synergy_hints(key)
	lines.append("\n队伍联动：")
	if synergy_hints.is_empty():
		lines.append("• 暂无已配置的角色或装备联动")
	else:
		for hint in synergy_hints:
			lines.append("• " + str(hint))
	var exclusive_items := []
	for item_key in GameData.ACTIVE_ITEM_KEYS:
		var item: Dictionary = GameData.ITEMS[item_key]
		if item.get("exclusive_character", "") == key or item.get("character_bonuses", {}).has(key):
			exclusive_items.append("• 【%s】：%s" % [item["name"], item["desc"]])
	lines.append("\n专属或适配装备：")
	lines.append("暂无专属装备" if exclusive_items.is_empty() else "\n".join(exclusive_items))


func _recruit(key: String) -> void:
	var result: Dictionary = Run.recruit_character_at_level(key, _node_level)
	if not result.is_empty():
		var actor: Dictionary = result["actor"]
		var message := "招募了 %s，以 Lv.%d 加入队伍。" % [
			actor["name"], actor["level"]]
		message += _growth_result_text(result["growth"])
		Run.set_notice(message)
		Run.advance()
		get_tree().change_scene_to_file("res://scenes/map.tscn")


func _upgrade(key: String) -> void:
	var results: Array = Run.upgrade_character_steps(key, _node_level)
	if results.is_empty():
		return
	var actor: Dictionary = Run._actor_for_key(key)
	var hp_gain := 0
	var atk_gain := 0
	for result in results:
		hp_gain += int(result["hp"])
		atk_gain += int(result["atk"])
	var message := "%s 连续培养 %d 段，提升至 Lv.%d：生命 +%d，攻击 +%d" % [
		actor["name"], results.size(), actor["level"], hp_gain, atk_gain]
	message += _growth_result_text(results)
	Run.set_notice(message)
	Run.advance()
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _growth_preview(key: String, from_level: int, steps: int) -> String:
	if steps <= 0:
		return "已完成全部培养"
	var lines := []
	var extra_skills: Array = GameData.CHARACTER_EXTRA_SKILLS.get(key, [])
	var growth_passives: Array = GameData.CHARACTER_GROWTH_PASSIVES.get(key, [])
	for offset in steps:
		var target_level := from_level + offset + 1
		var unlock_index := target_level - 2
		var target_name := (
			"MAX" if target_level >= GameData.MAX_CHARACTER_LEVEL
			else "Lv.%d" % target_level)
		if unlock_index < extra_skills.size():
			var skill: Dictionary = GameData.SKILLS[extra_skills[unlock_index]]
			lines.append("%s 技能【%s】：%s" % [
				target_name, skill["name"], skill.get("desc", "暂无说明")])
		if unlock_index < growth_passives.size():
			var passive: Dictionary = growth_passives[unlock_index]
			lines.append("%s 被动【%s】：%s" % [
				target_name, passive.get("name", "未知被动"),
				passive.get("desc", "暂无说明")])
	return "\n".join(lines)


func _growth_result_text(results: Array) -> String:
	var text := ""
	for result in results:
		if result.get("breakthrough", false):
			text += "\n【突破】进入 %s 阶段。" % (
				"MAX" if int(result.get("level", 1)) >= GameData.MAX_CHARACTER_LEVEL
				else ("Lv.%d" % int(result.get("level", 1))))
		if result["skill"] != "":
			text += "\n解锁技能：\n" + Run.skill_detail(result["skill"])
		if not result["passive"].is_empty():
			text += "\n解锁被动：\n" + Run.passive_detail(result["passive"])
	return text


func _leave() -> void:
	Run.set_notice("你暂时没有招募新的入梦师")
	Run.advance()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
