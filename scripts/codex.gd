extends Control
## 梦境图鉴：数据驱动展示角色、技能、道具、心魔与节点。

const BG := Color(0.035, 0.043, 0.075)
const PANEL := Color(0.075, 0.09, 0.14)
const ACCENT := Color(0.95, 0.78, 0.36)

var _tabs: TabContainer

func _ready() -> void:
	AudioMan.use_theme_music()
	var fallback := get_node_or_null("Fallback")
	FontHelper.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Color(BG, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "梦境图鉴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ACCENT)
	title.position = Vector2(0, 18)
	title.size = Vector2(1152, 48)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "所有数值来自 game_data.gd，后续调整会自动同步到这里"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.63, 0.72))
	subtitle.position = Vector2(0, 62)
	subtitle.size = Vector2(1152, 28)
	add_child(subtitle)

	_tabs = TabContainer.new()
	_tabs.position = Vector2(32, 102)
	_tabs.size = Vector2(1216, 620)
	add_child(_tabs)
	_build_characters_tab()
	_build_items_tab()
	_build_enemies_tab()
	_build_nodes_tab()

	var back := Button.new()
	back.text = "返回标题"
	back.position = Vector2(1120, 18)
	back.size = Vector2(128, 42)
	back.add_theme_font_size_override("font_size", 16)
	FontHelper.style_card(back, Color(0.38, 0.72, 0.86))
	back.pressed.connect(_on_back)
	add_child(back)
	if fallback != null:
		fallback.visible = false

func _scroll_tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1140, 0)
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	_tabs.add_child(scroll)
	return box

func _build_characters_tab() -> VBoxContainer:
	var box := _scroll_tab("入梦师")
	box.add_child(_make_card(
		"成长\nLv.1 → Lv.2 → Lv.3 → MAX。每级提升属性、解锁技能或被动。",
		Color(0.24, 0.20, 0.36)))
	var synergy_lines := []
	for synergy in GameData.TEAM_SYNERGIES:
		if synergy.get("id", "") not in GameData.ACTIVE_TEAM_SYNERGY_IDS:
			continue
		var member_names := []
		for member_key in synergy["members"]:
			member_names.append(GameData.CHARACTERS[member_key]["name"])
		synergy_lines.append("%s（%s）：%s" % [
			synergy["name"], " + ".join(member_names), synergy["desc"]])
	box.add_child(_make_card(
		"队伍联动\n" + "\n".join(synergy_lines),
		Color(0.16, 0.25, 0.36)))
	for key in GameData.ACTIVE_CHARACTER_KEYS:
		var ch: Dictionary = GameData.CHARACTERS[key]
		var skill: Dictionary = GameData.SKILLS[ch["skill"]]
		var growth_skills := []
		for extra_skill_key in GameData.CHARACTER_EXTRA_SKILLS.get(key, []):
			var extra_skill: Dictionary = GameData.SKILLS[extra_skill_key]
			growth_skills.append("%s：%s" % [extra_skill["name"], extra_skill["desc"]])
		var passive: Dictionary = ch.get("starter_passive", {})
		var role_text := "前台输出" if ch.get("role", "front") == "front" else "后台辅助"
		var passive_text: String = (
			passive.get("name", "无") + "：" + passive.get("desc", "该角色只能通过招募获得")
			if key in GameData.INITIAL_CHARACTERS
			else "无（招募角色不携带入梦被动）"
		)
		var growth_passive_text := []
		for growth_passive in GameData.CHARACTER_GROWTH_PASSIVES.get(key, []):
			growth_passive_text.append("%s：%s" % [
				growth_passive["name"], growth_passive["desc"]])
		var origin_text := "初始角色" if key in GameData.INITIAL_CHARACTERS else "仅招募获得"
		var text := "%s　[%s｜%s｜%s]\n生命 %d　攻击 %d　体力 %d　魔力 %d\n初始技能：%s（消耗 %d %s）\n%s\n培养技能：%s\n培养被动：%s\n入梦被动：%s" % [
			ch["name"], role_text, ch.get("action_mode", "标准行动"), origin_text,
			ch["max_hp"], ch["atk"],
			ch["max_stamina"], ch["max_mana"], skill["name"], skill.get("cost", 0),
			"体力" if skill.get("cost_type", "stamina") == "stamina" else "魔力",
			skill["desc"], "；".join(growth_skills), "；".join(growth_passive_text), passive_text]
		var synergy_hints: Array = Run.character_synergy_hints(key)
		if not synergy_hints.is_empty():
			text += "\n联动提示：\n" + "\n".join(synergy_hints)
		box.add_child(_make_card(text, Color(0.16, 0.22, 0.32), key, "character"))
	return box

func _build_items_tab() -> VBoxContainer:
	var box := _scroll_tab("道具")
	box.add_child(_make_card(
		"装备\n每名角色有 3 个通用装备位。装备提供属性或战斗效果。",
		Color(0.14, 0.24, 0.28)))
	var synergy_lines := []
	for synergy in GameData.EQUIPMENT_SYNERGIES:
		if synergy.get("id", "") not in GameData.ACTIVE_EQUIPMENT_SYNERGY_IDS:
			continue
		synergy_lines.append("%s：%s" % [synergy["name"], synergy["desc"]])
	box.add_child(_make_card(
		"角色 × 装备联动\n" + "\n".join(synergy_lines),
		Color(0.24, 0.22, 0.34)))
	for key in GameData.ACTIVE_ITEM_KEYS:
		var item: Dictionary = GameData.ITEMS[key]
		var kind := "绑定装备" if item.get("kind", "") == "equipment" else "消耗品"
		var extra := ""
		if item.get("kind", "") == "equipment":
			extra = "　任意角色可装备"
		var stats := []
		var stat_names := {
			"hp": "生命上限", "atk": "攻击", "stamina": "体力上限", "mana": "魔力上限",
			"damage_reduction": "受到伤害降低", "heal_bonus": "治疗加成",
			"item_power": "消耗品加成", "start_shield": "开战护盾",
		}
		for stat in stat_names:
			if item.has(stat):
				stats.append("%s +%d" % [stat_names[stat], item[stat]])
		var stats_text := ""
		if stats.size() > 0:
			stats_text = "\n属性： " + "、".join(stats)
		var text := "%s　[%s]%s\n%s%s" % [item["name"], kind, extra, item["desc"], stats_text]
		if item.get("kind", "") == "equipment":
			var synergy_hints: Array = Run.item_synergy_hints(key)
			if not synergy_hints.is_empty():
				text += "\n联动提示：\n" + "\n".join(synergy_hints)
		box.add_child(_make_card(text, Color(0.18, 0.28, 0.24), key, "item"))
	return box

func _build_enemies_tab() -> VBoxContainer:
	var box := _scroll_tab("心魔")
	for key in GameData.ENEMIES:
		var enemy: Dictionary = GameData.ENEMIES[key]
		var pattern := _pattern_text(enemy.get("pattern", "attack"))
		var text := "%s　【%s】\n生命 %d　攻击 %d\n行动模式：%s" % [
			enemy["name"], enemy.get("emotion", "未知"), enemy["max_hp"],
			enemy["atk"], pattern]
		box.add_child(_make_card(text, Color(0.3, 0.16, 0.22), key, "enemy"))
	return box

func _build_nodes_tab() -> VBoxContainer:
	var box := _scroll_tab("节点")
	box.add_child(_make_card(
		"节点构筑规则\n每到普通路线格时，从卡组选择 1 张节点卡放置后进入；"
		+ "3 张同类型、同等级节点可合成 1 张高一级节点。"
		+ "节点等级显著提高敌方生命、攻击、减伤、编队规模和奖励品质。\n"
		+ "每击败一名精英，节点等级保持不变，但梦境压力 +1；"
		+ "后续所有战斗与奖励的综合强度等于节点等级 + 梦境压力。"
		+ "每场战斗胜利会在三选一奖励之外直接获得 2–3 张节点卡。",
		Color(0.15, 0.24, 0.34)))
	box.add_child(_make_card(
		"奇遇资源\n梦蚀代表入梦师逐渐被深层梦境侵染：高梦蚀会强化部分梦魇，"
		+ "也会解锁伪醒等危险事件。记忆残片来自净化梦魂和探索异常空间，"
		+ "可在连续奇遇与记忆交易中换取高阶收益。",
		Color(0.24, 0.18, 0.32)))
	box.add_child(_make_card(
		"探索等级\n战斗胜利、奖励节点和奇遇结果都会提供探索经验。"
		+ "探索等级越高，每个我方回合开始时全体存活角色恢复的体力与魔力越多。"
		+ "角色仍然每回合只能行动一次，资源恢复用于维持长战斗中的技能循环。",
		Color(0.16, 0.30, 0.30)))
	box.add_child(_make_card(
		(
			"随机初始卡组\n每局只随机生成 %d 张启动节点卡，不使用固定卡组或最低保底。"
			+ "镇守/奇遇各占 30%%，奖励/招募各占 20%%。"
			+ "之后主要通过战斗胜利补充节点卡，奖励与奇遇也可能提供高阶良性节点。"
		) % [
			GameData.STARTER_NODE_CARD_COUNT,
		],
		Color(0.18, 0.25, 0.38)))
	for node_type in GameData.NODE_CARD_DROP_POOL:
		var text := _node_name(node_type)
		if GameData.STARTER_NODE_WEIGHTS.has(node_type):
			text += "　开局随机权重 %d%%" % int(GameData.STARTER_NODE_WEIGHTS[node_type])
		else:
			text += "　开局不出现，可在探索中获得"
		if node_type == "elite":
			text += "\n固定在第 4、8 格，不消耗节点卡；高难度战斗，奖励更丰厚"
		elif node_type == "recruit":
			text += "\n随机展示最多 4 名未入队候选，或培养已有角色；Lv.2/Lv.3 可高等级入队，Lv.3 后还能突破至 MAX"
		elif node_type == "reward":
			text += "\n从成长资源与良性节点卡中选择一项，高强度时可直接出现 Lv.2/Lv.3"
		elif node_type == "event":
			text += "\n奇遇可能改变梦蚀、记忆残片和事件旗标，并解锁连续剧情或隐藏梦魇"
		box.add_child(_make_card(text, Color(0.22, 0.24, 0.3)))
	box.add_child(_make_card(
		"固定节点\n精英固定在第 4、8 格，首领固定在第 13 格；"
		+ "它们不进入玩家节点卡组，也不参与开局随机生成。",
		Color(0.30, 0.18, 0.24)))
	return box

func _make_card(text: String, color: Color, icon_key: String = "", icon_kind := "item") -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1120, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.custom_minimum_size = Vector2(1080, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if icon_key == "":
		card.add_child(label)
		return card
	var tex: Texture2D = null
	match icon_kind:
		"character": tex = ArtAssets.character(icon_key)
		"enemy": tex = ArtAssets.enemy(icon_key)
		_: tex = ArtAssets.item(icon_key)
	if tex == null:
		card.add_child(label)
		return card
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)
	var icon := ArtAssets.add_texture(row, tex, Rect2(Vector2(0, 0), Vector2(94, 94)))
	icon.custom_minimum_size = Vector2(94, 94)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.custom_minimum_size = Vector2(940, 0)
	row.add_child(icon)
	row.add_child(label)
	return card

func _passive_text(passive: Dictionary) -> String:
	match passive.get("type", ""):
		"stamina_start":
			return "开局体力额外 +%d" % passive.get("amount", 0)
		"first_hit":
			return "首次命中额外造成 %d 点伤害（下一版接入）" % passive.get("amount", 0)
		"node_reward":
			return "奖励节点品质 +%d（下一版接入）" % passive.get("amount", 0)
		"heal_bonus":
			return "治疗效果额外 +%d" % passive.get("amount", 0)
		"battle_shield":
			return "每场战斗开始获得 %d 点护盾" % passive.get("amount", 0)
		"bleed_bonus":
			return "施加的流血层数额外 +%d" % passive.get("amount", 0)
		"resource_bonus":
			return "资源回复技能效果额外 +%d" % passive.get("amount", 0)
		"item_power":
			return "使用消耗品时效果额外 +%d" % passive.get("amount", 0)
		_:
			return "暂无"

func _pattern_text(pattern: String) -> String:
	match pattern:
		"heavy_every_3":
			return "每 3 回合发动一次重击"
		"bleed_every_2":
			return "每 2 回合攻击并施加流血"
		"stun_every_3":
			return "每 3 回合攻击并施加晕眩"
		"shield_every_2":
			return "每 2 回合为自己获得 6 点护盾"
		"heal_every_3":
			return "每 3 回合回复 6 点生命"
		_:
			return "普通攻击"

func _node_name(node_type: String) -> String:
	return {
		"battle": "镇守", "event": "奇遇", "reward": "奖励",
		"recruit": "招募", "shop": "商店", "rest": "恢复",
		"elite": "精英", "boss": "首领",
	}.get(node_type, node_type)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
