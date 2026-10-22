class_name GlobalDetails
extends RefCounted
## 所有界面共用的“效果详情”入口与百科弹窗。

const GOLD := Color(0.96, 0.76, 0.32)
const CYAN := Color(0.38, 0.78, 0.88)
const MUTED := Color(0.70, 0.75, 0.84)


static func attach(root: Control) -> void:
	if root.get_node_or_null("GlobalDetailButton") != null:
		return
	var button := Button.new()
	button.name = "GlobalDetailButton"
	button.text = "效果详情"
	button.tooltip_text = "查看角色、技能、装备、节点、资源与状态的完整效果"
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_left = -294.0
	button.offset_right = -170.0
	button.offset_top = 10.0
	button.offset_bottom = 48.0
	button.z_index = 900
	button.add_theme_font_size_override("font_size", 14)
	FontHelper.style_card(button, CYAN)
	button.pressed.connect(toggle.bind(root))
	root.add_child(button)


static func toggle(root: Control) -> void:
	var existing := root.get_node_or_null("GlobalDetailOverlay")
	if existing != null:
		existing.queue_free()
		return
	_build_overlay(root)


static func show_text_popup(root: Control, popup_title: String, detail_text: String) -> void:
	var existing := root.get_node_or_null("ContextDetailOverlay")
	if existing != null:
		existing.queue_free()
		return
	var overlay := ColorRect.new()
	overlay.name = "ContextDetailOverlay"
	overlay.color = Color(0.008, 0.012, 0.028, 0.96)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1100
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.position = Vector2(150, 76)
	panel.size = Vector2(980, 640)
	panel.add_theme_stylebox_override(
		"panel",
		FontHelper.panel_style(
			Color(0.045, 0.058, 0.105, 0.99),
			Color(0.46, 0.78, 0.90, 0.92),
			16))
	overlay.add_child(panel)

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(content)

	var title := Label.new()
	title.text = popup_title
	title.position = Vector2(24, 18)
	title.size = Vector2(790, 40)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GOLD)
	content.add_child(title)

	var close := Button.new()
	close.text = "关闭"
	close.position = Vector2(870, 14)
	close.size = Vector2(82, 38)
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(show_text_popup.bind(root, popup_title, detail_text))
	content.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 72)
	scroll.size = Vector2(932, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var label := Label.new()
	label.text = detail_text
	label.custom_minimum_size = Vector2(890, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(label)


static func _build_overlay(root: Control) -> void:
	var overlay := ColorRect.new()
	overlay.name = "GlobalDetailOverlay"
	overlay.color = Color(0.008, 0.012, 0.028, 0.96)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1000
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.position = Vector2(54, 34)
	panel.size = Vector2(1172, 716)
	panel.add_theme_stylebox_override(
		"panel",
		FontHelper.panel_style(
			Color(0.045, 0.058, 0.105, 0.98),
			Color(0.40, 0.72, 0.88, 0.90),
			16))
	overlay.add_child(panel)

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(content)

	var title := Label.new()
	title.text = "效果详情 · 梦境规则总览"
	title.position = Vector2(24, 14)
	title.size = Vector2(700, 38)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", GOLD)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "这里展示当前局内状态以及游戏中所有可出现效果；数值以当前版本为准。"
	subtitle.position = Vector2(26, 48)
	subtitle.size = Vector2(850, 24)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", MUTED)
	content.add_child(subtitle)

	var close := Button.new()
	close.text = "关闭"
	close.position = Vector2(1062, 16)
	close.size = Vector2(82, 36)
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(toggle.bind(root))
	content.add_child(close)

	var tabs := TabContainer.new()
	tabs.name = "GlobalDetailTabs"
	tabs.position = Vector2(20, 82)
	tabs.size = Vector2(1132, 610)
	content.add_child(tabs)
	tabs.add_child(_party_tab())
	tabs.add_child(_skills_tab())
	tabs.add_child(_items_tab())
	tabs.add_child(_enemies_tab())
	tabs.add_child(_nodes_tab())
	tabs.add_child(_mechanics_tab())


static func _party_tab() -> ScrollContainer:
	var scroll := _make_scroll("当前队伍")
	var box: VBoxContainer = scroll.get_child(0)
	if Run.player.is_empty() or Run.party.is_empty():
		_add_card(box, "当前尚未开始探索。\n选择初始入梦师后，这里会实时显示队伍属性、技能、被动、装备和联动。", CYAN)
		return scroll
	for actor in Run.party:
		var key: String = actor.get("key", "")
		var role := "前台" if actor.get("role", "front") == "front" else "后台"
		var skills := []
		for skill_key in actor.get("skills", [actor.get("skill", "")]):
			skills.append("• " + Run.skill_detail(skill_key).replace("\n", "；"))
		var passives := []
		if actor.get("starter_passive_active", false) and actor.has("starter_passive"):
			passives.append("入梦被动：" + Run.passive_detail(actor["starter_passive"]).replace("\n", "；"))
		for passive in actor.get("growth_passives", []):
			passives.append("培养被动：" + Run.passive_detail(passive).replace("\n", "；"))
		var equipment_details := []
		for slot in 3:
			var item_key: String = Run.equipment_in_slot(slot, key)
			if item_key == "":
				equipment_details.append("装备位 %d：空" % (slot + 1))
			else:
				equipment_details.append(
					"装备位 %d：%s——%s" % [
						slot + 1,
						GameData.ITEMS[item_key]["name"],
						GameData.ITEMS[item_key]["desc"]])
		var synergy_hints: Array = Run.character_synergy_hints(key)
		var text := (
			"%s　Lv.%s　[%s]\n"
			+ "生命 %d/%d　攻击 %d　体力 %d/%d　魔力 %d/%d\n"
			+ "技能：\n%s\n被动：\n%s\n穿戴：\n%s\n联动：\n%s"
		) % [
			actor.get("name", "未知角色"),
			str(actor.get("level", 1)),
			role,
			actor.get("hp", 0), actor.get("max_hp", 0),
			actor.get("atk", 0),
			actor.get("stamina", 0), actor.get("max_stamina", 0),
			actor.get("mana", 0), actor.get("max_mana", 0),
			"\n".join(skills),
			"无" if passives.is_empty() else "\n".join(passives),
			"\n".join(equipment_details),
			"暂无可用联动" if synergy_hints.is_empty() else "\n".join(synergy_hints),
		]
		_add_card(box, text, Color(0.18, 0.30, 0.40), key, "character")
	return scroll


static func _skills_tab() -> ScrollContainer:
	var scroll := _make_scroll("全部技能")
	var box: VBoxContainer = scroll.get_child(0)
	for character_key in GameData.ACTIVE_CHARACTER_KEYS:
		var character: Dictionary = GameData.CHARACTERS[character_key]
		var skill_keys := [character["skill"]]
		for skill_key in GameData.CHARACTER_EXTRA_SKILLS.get(character_key, []):
			skill_keys.append(skill_key)
		var details := []
		for skill_key in skill_keys:
			details.append(Run.skill_detail(skill_key).replace("\n", "；"))
		var passive_details := []
		if character.has("starter_passive"):
			passive_details.append(
				"初始入梦被动：" + Run.passive_detail(character["starter_passive"]).replace("\n", "；"))
		for passive in GameData.CHARACTER_GROWTH_PASSIVES.get(character_key, []):
			passive_details.append(
				"培养被动：" + Run.passive_detail(passive).replace("\n", "；"))
		_add_card(
			box,
			"%s　[%s]\n%s\n%s" % [
				character["name"],
				"前台" if character["role"] == "front" else "后台",
				"\n".join(details),
				"无额外被动" if passive_details.is_empty() else "\n".join(passive_details),
			],
			Color(0.20, 0.25, 0.42))
	return scroll


static func _items_tab() -> ScrollContainer:
	var scroll := _make_scroll("装备道具")
	var box: VBoxContainer = scroll.get_child(0)
	var inventory_counts := {}
	for item_key in Run.inventory:
		inventory_counts[item_key] = int(inventory_counts.get(item_key, 0)) + 1
	for item_key in GameData.ACTIVE_ITEM_KEYS:
		var item: Dictionary = GameData.ITEMS[item_key]
		var kind := "装备" if item.get("kind", "consumable") == "equipment" else "战斗消耗品"
		var owned := int(inventory_counts.get(item_key, 0))
		var owned_text := "　背包持有 ×%d" % owned if owned > 0 else ""
		var extra := ""
		if item.has("exclusive_character"):
			var character_key: String = item["exclusive_character"]
			extra = "\n专属角色：%s" % GameData.CHARACTERS.get(character_key, {}).get("name", character_key)
		_add_card(
			box,
			"%s　[%s]%s\n效果：%s%s" % [
				item["name"], kind, owned_text, item.get("desc", "暂无说明"), extra],
			Color(0.18, 0.34, 0.28) if kind == "装备" else Color(0.25, 0.28, 0.38),
			item_key, "item")
	return scroll


static func _enemies_tab() -> ScrollContainer:
	var scroll := _make_scroll("心魔效果")
	var box: VBoxContainer = scroll.get_child(0)
	for enemy_key in GameData.ENEMIES:
		var enemy: Dictionary = GameData.ENEMIES[enemy_key]
		var pattern_detail := _enemy_pattern_detail(
			enemy.get("pattern", "attack"),
			int(enemy.get("atk", 0)))
		var extra_details := []
		if int(enemy.get("damage_reduction", 0)) > 0:
			extra_details.append(
				"固定减伤：每次受到伤害时减少 %d 点。" % enemy["damage_reduction"])
		if enemy.has("phase_threshold"):
			extra_details.append(
				"首领二阶段：生命降至约 %d%% 时触发，攻击 +%d，并获得 %d 点护盾。"
				% [
					int(round(float(enemy["phase_threshold"]) * 100.0)),
					int(enemy.get("phase_atk", 0)),
					int(enemy.get("phase_shield", 0)),
				])
		var text := (
			"%s　【%s】\n基础生命 %d　基础攻击 %d\n行动效果：%s"
			% [
				enemy["name"], enemy.get("emotion", "未知"),
				enemy.get("max_hp", 0), enemy.get("atk", 0),
				pattern_detail,
			])
		if not extra_details.is_empty():
			text += "\n" + "\n".join(extra_details)
		_add_card(box, text, Color(0.36, 0.18, 0.26), enemy_key, "enemy")
	return scroll


static func _enemy_pattern_detail(pattern: String, attack: int) -> String:
	match pattern:
		"heavy_every_3":
			return "通常进行随机目标攻击；每 3 回合发动约 200% 攻击的蓄力重击。"
		"bleed_every_2":
			return "通常进行随机目标攻击；每 2 回合攻击并施加 2 层流血。"
		"stun_every_3":
			return "通常进行随机目标攻击；每 3 回合攻击并使目标晕眩 1 回合。"
		"shield_every_2":
			return "通常进行随机目标攻击；每 2 回合为自己获得 6 点护盾。"
		"shield_ally_every_2":
			return "通常进行随机目标攻击；每 2 回合为生命比例最低的心魔提供 9 点护盾。"
		"heal_every_3":
			return "通常进行随机目标攻击；每 3 回合为自己回复 6 点生命。"
		"heal_ally_every_2":
			return "通常进行随机目标攻击；每 2 回合治疗生命比例最低的心魔 10 点。"
	return "每回合从所有存活角色中随机选择目标，造成基于 %d 点基础攻击的普通伤害。" % attack


static func _nodes_tab() -> ScrollContainer:
	var scroll := _make_scroll("节点与资源")
	var box: VBoxContainer = scroll.get_child(0)
	var resource_text := (
		"金币：局内交易资源，用于商店购买装备、道具、训练或节点卡。\n"
		+ "探索经验：提高探索等级；探索等级越高，我方每回合开始恢复的体力和魔力越多。\n"
		+ "节点卡组：用于在普通路线格放置下一节点；3 张同类型同等级卡可合成高一级节点。\n"
		+ "梦境压力：每击败一名精英 +1；强化之后的敌人、奖励和节点卡品质。\n"
		+ "梦蚀：奇遇中的长期风险值；可能解锁危险事件和隐藏结果。\n"
		+ "记忆残片：奇遇交换资源，可用于连续事件和高阶收益。\n"
		+ "回声碎片：结算获得的局外资源，用于永久解锁角色。"
	)
	if Run.run_started:
		resource_text += (
			"\n\n当前数值：金币 %d｜探索 Lv.%d（%d/%d）｜压力 %d｜梦蚀 %d｜记忆残片 %d｜节点卡 %d 张"
			% [
				Run.gold, Run.exploration_level, Run.exploration_xp,
				Run.exploration_xp_to_next(), Run.dream_pressure,
				Run.dream_corruption, Run.memory_fragments, Run.available_cards.size()])
	_add_card(box, resource_text, Color(0.18, 0.30, 0.38))

	var node_details := {
		"battle": "镇守：进入常规战斗。胜利后独立获得 2–3 张节点卡，并从金币、经验、装备/道具中三选一。",
		"event": "奇遇：发生梦境事件。可安全离开、承担未知结果，或利用特定角色/装备洞察；可能获益、受罚或触发战斗。",
		"reward": "奖励：从事件化的成长奖励中选择一项；通常包含金币、经验、装备道具或偏良性的节点卡。",
		"recruit": "招募：每次进入重新抽取最多 4 名候选，也可培养已有角色；高等级节点可高等级入队或连续培养。",
		"shop": "商店：消耗金币购买装备、消耗品、训练或节点卡。",
		"rest": "恢复：当前版本回复生命；战斗结束仍会完成全队整备。",
		"elite": "精英：固定在第 4、8 格，不消耗节点卡；敌人带随从，胜利后梦境压力提升。",
		"boss": "首领：固定在第 13 格。Boss 带两名随从，并在半血附近进入二阶段。",
	}
	for type_name in node_details:
		_add_card(box, node_details[type_name], Color(0.30, 0.22, 0.34))
	return scroll


static func _mechanics_tab() -> ScrollContainer:
	var scroll := _make_scroll("状态机制")
	var box: VBoxContainer = scroll.get_child(0)
	var sections := [
		"生命：降至 0 时角色或敌人倒下。战斗胜利后存活队伍生命、体力和魔力回满。",
		"体力：主要用于物理攻击、连续攻击、防御和部分蓄力技能。每场战斗开始回满；战斗中按探索等级逐回合恢复。",
		"魔力：主要用于法术、治疗、净化和资源支援。每场战斗开始回满；战斗中按探索等级逐回合恢复。",
		"行动限制：每名角色每回合只能行动一次。切换角色不会重置行动机会。",
		"护盾：优先于生命吸收伤害；通常在战斗结束时清除。部分装备和被动会提高护盾收益或带盾伤害。",
		"减伤：每次受到伤害时减少固定数值，结算顺序早于生命扣除。",
		"流血：持续负面状态；在行动结算时造成额外伤害。部分角色与装备会强化流血层数或对流血目标增伤。",
		"晕眩：使目标失去行动机会；可通过净化类技能或道具移除。",
		"蓄力：先支付完整资源并消耗本回合，经过指定回合后自动释放更强效果；可能攻击单体、全体或支援全队。",
		"净化：移除流血与晕眩。部分被动会在净化时附加治疗或护盾。",
		"过量治疗：治疗超过生命上限的部分通常浪费；拥有对应被动时可转化为护盾。",
		"前台/后台：用于明确队伍视觉和角色定位；敌人仍会从所有存活角色中随机选择目标，并尽量避免连续攻击同一人。",
		"队伍联动：指定角色组合同时在队时自动生效，每场战斗重新计算，不会永久重复叠加。",
		"装备：每名角色有 3 个通用装备位，不区分武器、护甲或饰品；装备可同时提供属性和复杂战斗被动。",
		"战斗道具：在我方回合使用并消耗库存；治疗、回复资源、伤害、流血、晕眩、护盾和净化类效果均可出现。",
		"奖励品质：节点等级与梦境压力共同构成综合强度；强度越高，金币/经验数值、装备选择和高阶节点卡概率越高。",
	]
	for text in sections:
		_add_card(box, text, Color(0.24, 0.22, 0.36))

	for synergy in GameData.TEAM_SYNERGIES:
		if synergy.get("id", "") not in GameData.ACTIVE_TEAM_SYNERGY_IDS:
			continue
		_add_card(
			box,
			"队伍联动【%s】\n%s" % [synergy["name"], synergy["desc"]],
			Color(0.18, 0.36, 0.38))
	return scroll


static func _make_scroll(tab_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1070, 0)
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	return scroll


static func _add_card(box: VBoxContainer, text: String, color: Color, icon_key: String = "", icon_kind := "item") -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1070, 0)
	card.add_theme_stylebox_override(
		"panel",
		FontHelper.panel_style(
			Color(color, 0.78),
			color.lightened(0.26),
			10))
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(1025, 0)
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if icon_key == "":
		card.add_child(label)
		box.add_child(card)
		return
	var tex: Texture2D = null
	match icon_kind:
		"character": tex = ArtAssets.character(icon_key)
		"enemy": tex = ArtAssets.enemy(icon_key)
		_: tex = ArtAssets.item(icon_key)
	if tex == null:
		card.add_child(label)
		box.add_child(card)
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var icon := ArtAssets.add_texture(row, tex, Rect2(Vector2(0, 0), Vector2(82, 82)))
	icon.custom_minimum_size = Vector2(82, 82)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.custom_minimum_size = Vector2(900, 0)
	row.add_child(icon)
	row.add_child(label)
	box.add_child(card)
