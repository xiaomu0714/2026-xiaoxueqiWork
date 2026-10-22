extends Control
## 棋盘式战斗界面：敌方位于上方，我方位于下方；角色模型暂用高识别度色块卡面。

const NODE_TITLES := {"battle": "心魔遭遇", "elite": "精英心魔", "boss": "首领：虚无"}
const POTION_HEAL := 5
const BG := Color(0.025, 0.035, 0.065)
const BOARD := Color(0.075, 0.095, 0.14)
const GOLD := Color(0.95, 0.78, 0.36)
const BarView = preload("res://scripts/ui_bar_view.gd")
const BattleFx = preload("res://scripts/battle_effects.gd")
const FxTexView = preload("res://scripts/ui_texture_view.gd")

const CHARACTER_COLORS := {
	"镇魇武者": Color(0.50, 0.20, 0.18),
	"逐影猎手": Color(0.18, 0.42, 0.28),
	"织梦术士": Color(0.30, 0.22, 0.55),
	"引魂医者": Color(0.20, 0.42, 0.52),
	"梦盾守卫": Color(0.24, 0.34, 0.48),
	"血梦刺客": Color(0.54, 0.14, 0.28),
	"灵脉乐师": Color(0.22, 0.48, 0.46),
	"梦药炼金师": Color(0.46, 0.36, 0.16),
	"裂梦剑客": Color(0.50, 0.24, 0.42),
	"星痕先知": Color(0.26, 0.38, 0.62),
	"铸梦工匠": Color(0.50, 0.34, 0.20),
	"帷幕书记": Color(0.22, 0.30, 0.44),
}
const ENEMY_COLORS := {
	"slime": Color(0.62, 0.18, 0.20),
	"archer": Color(0.50, 0.22, 0.48),
	"golem": Color(0.40, 0.32, 0.24),
	"wisp": Color(0.42, 0.22, 0.55),
	"spider": Color(0.24, 0.30, 0.42),
	"sentinel": Color(0.26, 0.38, 0.48),
	"knight": Color(0.46, 0.16, 0.20),
	"boss": Color(0.25, 0.10, 0.30),
}

var _node_type := "battle"
var _enemy := {}
var _enemies: Array = []
var _active_enemy_index := 0
var _round := 1
var _phase := "player"
var _battle_over := false
var _potion_used := false
var _log_text := ""
var _active_index := 0
var _turn_locked: Array = []
var _actions_taken: Array = []
var _last_enemy_target_index := -1
var _victory_node_cards: Array = []

var _title_label: Label
var _phase_label: Label
var _player_label: Label
var _enemy_label: Label
var _player_bar: Control
var _enemy_bar: ProgressBar
var _enemy_status_label: Label
var _enemy_intent_label: Label
var _equipment_label: Label
var _log_label: Label
var _party_box: Control
var _party_card_nodes: Array = []
var _front_party_box: HBoxContainer
var _back_party_box: HBoxContainer
var _action_box: HBoxContainer
var _item_box: HBoxContainer
var _enemy_card: Control
var _passives_label: Label
var _enemy_box: HBoxContainer
var _enemy_cards: Array = []
var _enemy_labels: Array = []
var _enemy_bars: Array = []
var _enemy_statuses: Array = []
var _inspect_overlay: ColorRect
var _inspect_tabs: TabContainer


func _ready() -> void:
	AudioMan.use_battle_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "battle")
	UITheme.add_top_right_status(self)
	if not Run.run_started or Run.player.is_empty():
		Run.start_run()
		Run.choose_node_card(0)
		Run.enter_battle()
	if Run.battle_enemies.is_empty():
		Run.prepare_battle_for_key(Run.battle_enemy_key, Run.battle_level, "battle")
	_node_type = Run.current_node()
	_enemies = Run.battle_enemies.duplicate(true)
	_active_enemy_index = 0
	_enemy = _enemies[0] if not _enemies.is_empty() else {}
	for ally in Run.party:
		ally["shield"] = int(ally.get("start_shield", 0))
	_log_text = "选择下方入梦师，再使用攻击、技能或背包道具。"
	var synergy_names: Array = Run.active_synergy_names()
	if not synergy_names.is_empty():
		_log_text += "\n本场联动：" + "、".join(synergy_names)
	_active_index = _first_alive_index()
	_build_ui()
	_start_player_turn()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(BG, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := ColorRect.new()
	header.color = Color(0.045, 0.065, 0.12, 0.92)
	header.position = Vector2(16, 6)
	header.size = Vector2(1248, 70)
	add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.add_theme_color_override("font_color", GOLD)
	_title_label.position = Vector2(34, 18)
	_title_label.size = Vector2(724, 24)
	_title_label.clip_text = false
	_title_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_title_label.text = "%s　Lv.%d / 压力%d / 强度%d" % [
		NODE_TITLES.get(_node_type, "心魔遭遇"),
		Run.battle_level, Run.dream_pressure, Run.battle_effective_tier]
	_title_label.text += "　探索Lv.%d　金币%d" % [
		Run.exploration_level, Run.gold]
	add_child(_title_label)

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_phase_label.add_theme_font_size_override("font_size", 12)
	_phase_label.position = Vector2(34, 46)
	_phase_label.size = Vector2(724, 24)
	_phase_label.clip_text = false
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_phase_label)


	var board_panel := ColorRect.new()
	board_panel.color = Color(BOARD, 0.14)
	board_panel.position = Vector2(16, 80)
	board_panel.size = Vector2(1248, 552)
	add_child(board_panel)

	var enemy_lane := Label.new()
	enemy_lane.text = "敌方战场"
	enemy_lane.add_theme_font_size_override("font_size", 15)
	enemy_lane.add_theme_color_override("font_color", Color(0.88, 0.55, 0.58))
	enemy_lane.position = Vector2(34, 90)
	enemy_lane.size = Vector2(180, 28)
	add_child(enemy_lane)

	_enemy_intent_label = Label.new()
	_enemy_intent_label.position = Vector2(38, 128)
	_enemy_intent_label.size = Vector2(260, 150)
	_enemy_intent_label.add_theme_font_size_override("font_size", 16)
	_enemy_intent_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_enemy_intent_label.clip_text = true
	add_child(_enemy_intent_label)

	_enemy_box = HBoxContainer.new()
	_enemy_box.position = Vector2(270, 88)
	_enemy_box.size = Vector2(560, 196)
	_enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_box.add_theme_constant_override("separation", 12)
	add_child(_enemy_box)
	_enemy_card = _enemy_box

	var log_panel := ColorRect.new()
	log_panel.color = Color(0.035, 0.05, 0.095, 0.92)
	log_panel.position = Vector2(838, 100)
	log_panel.size = Vector2(402, 190)
	add_child(log_panel)

	var log_title := Label.new()
	log_title.text = "战斗记录"
	log_title.add_theme_font_size_override("font_size", 15)
	log_title.add_theme_color_override("font_color", GOLD)
	log_title.position = Vector2(850, 110)
	log_title.size = Vector2(200, 24)
	add_child(log_title)

	var inspect := Button.new()
	inspect.text = "敌方 / 队伍详情"
	inspect.position = Vector2(1080, 102)
	inspect.size = Vector2(150, 34)
	inspect.add_theme_font_size_override("font_size", 13)
	FontHelper.style_card(inspect, Color(0.72, 0.40, 0.62))
	inspect.pressed.connect(_toggle_inspect)
	add_child(inspect)

	var log_scroll := ScrollContainer.new()
	log_scroll.position = Vector2(850, 136)
	log_scroll.size = Vector2(378, 142)
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(log_scroll)

	_log_label = Label.new()
	_log_label.add_theme_font_size_override("font_size", 13)
	_log_label.custom_minimum_size = Vector2(360, 0)
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_log_label.clip_text = true
	log_scroll.add_child(_log_label)

	var divider := ColorRect.new()
	divider.color = Color(0.30, 0.34, 0.46)
	divider.position = Vector2(34, 314)
	divider.size = Vector2(1212, 2)
	add_child(divider)

	# 右侧：当前角色的被动（含自身与装备被动）
	var passive_panel := Panel.new()
	passive_panel.position = Vector2(862, 320)
	passive_panel.size = Vector2(402, 238)
	passive_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	passive_panel.add_theme_stylebox_override(
		"panel",
		FontHelper.panel_style(Color(0.045, 0.06, 0.115, 0.94), Color(0.36, 0.46, 0.66), 12))
	add_child(passive_panel)

	var passive_title := Label.new()
	passive_title.text = "被动"
	passive_title.add_theme_font_size_override("font_size", 15)
	passive_title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.38))
	passive_title.position = Vector2(16, 10)
	passive_title.size = Vector2(120, 24)
	passive_panel.add_child(passive_title)

	_passives_label = Label.new()
	_passives_label.add_theme_font_size_override("font_size", 12)
	_passives_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	_passives_label.position = Vector2(18, 40)
	_passives_label.size = Vector2(370, 188)
	_passives_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_passives_label.clip_text = true
	_passives_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	passive_panel.add_child(_passives_label)

	_party_box = Control.new()
	_party_box.position = Vector2(34, 316)
	_party_box.size = Vector2(820, 290)
	add_child(_party_box)

	var front_label := Label.new()
	front_label.text = "前台阵线（最多 3）"
	front_label.add_theme_font_size_override("font_size", 15)
	front_label.add_theme_color_override("font_color", Color(0.95, 0.58, 0.48))
	front_label.position = Vector2(0, 4)
	front_label.size = Vector2(110, 26)
	_party_box.add_child(front_label)

	_front_party_box = HBoxContainer.new()
	_front_party_box.position = Vector2(112, 0)
	_front_party_box.size = Vector2(700, 142)
	_front_party_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_front_party_box.add_theme_constant_override("separation", 12)
	_party_box.add_child(_front_party_box)

	var back_label := Label.new()
	back_label.text = "后台支援（最多 3）"
	back_label.add_theme_font_size_override("font_size", 15)
	back_label.add_theme_color_override("font_color", Color(0.48, 0.78, 0.95))
	back_label.position = Vector2(0, 148)
	back_label.size = Vector2(110, 26)
	_party_box.add_child(back_label)

	_back_party_box = HBoxContainer.new()
	_back_party_box.position = Vector2(112, 146)
	_back_party_box.size = Vector2(700, 142)
	_back_party_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_back_party_box.add_theme_constant_override("separation", 12)
	_party_box.add_child(_back_party_box)

	_equipment_label = Label.new()
	_equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equipment_label.add_theme_font_size_override("font_size", 13)
	_equipment_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
	_equipment_label.position = Vector2(34, 620)
	_equipment_label.size = Vector2(1212, 44)
	_equipment_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_equipment_label.clip_text = true
	_equipment_label.clip_text = false
	add_child(_equipment_label)

	var action_scroll := ScrollContainer.new()
	action_scroll.position = Vector2(18, 668)
	action_scroll.size = Vector2(1244, 82)
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(action_scroll)

	_action_box = HBoxContainer.new()
	_action_box.custom_minimum_size = Vector2(1228, 78)
	_action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_box.add_theme_constant_override("separation", 8)
	action_scroll.add_child(_action_box)

	var inventory_label := Label.new()
	inventory_label.text = "战斗道具"
	inventory_label.add_theme_font_size_override("font_size", 13)
	inventory_label.position = Vector2(18, 756)
	inventory_label.size = Vector2(132, 22)
	add_child(inventory_label)

	var item_scroll := ScrollContainer.new()
	item_scroll.position = Vector2(150, 748)
	item_scroll.size = Vector2(1114, 48)
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	item_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(item_scroll)

	_item_box = HBoxContainer.new()
	_item_box.custom_minimum_size = Vector2(1090, 52)
	_item_box.add_theme_constant_override("separation", 8)
	item_scroll.add_child(_item_box)


func _rebuild_enemy_cards() -> void:
	_clear_container(_enemy_box)
	_enemy_cards.clear()
	_enemy_labels.clear()
	_enemy_bars.clear()
	_enemy_statuses.clear()
	if _enemies.is_empty():
		return
	for index in _enemies.size():
		var enemy: Dictionary = _enemies[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(160, 184)
		card.text = ""
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(_select_enemy.bind(index))
		_enemy_box.add_child(card)
		_enemy_cards.append(card)
		var base_color: Color = ENEMY_COLORS.get(enemy.get("key", Run.battle_enemy_key), Color(0.5, 0.18, 0.22))
		card.add_theme_stylebox_override("normal", _card_style(base_color, index == _active_enemy_index))
		card.add_theme_stylebox_override("hover", _card_style(base_color.lightened(0.08), index == _active_enemy_index))
		card.add_theme_stylebox_override("pressed", _card_style(base_color.darkened(0.08), true))

		var content := Control.new()
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)

		var portrait := ArtAssets.add_texture(
			content,
			ArtAssets.enemy(enemy.get("key", Run.battle_enemy_key)),
			Rect2(Vector2(22, 6), Vector2(88, 88)))
		if portrait.texture == null:
			portrait.queue_free()

		var placeholder := Label.new()
		placeholder.text = "■ 心魔"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 11)
		placeholder.position = Vector2(0, 96)
		placeholder.size = Vector2(160, 14)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(placeholder)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.position = Vector2(5, 110)
		label.size = Vector2(150, 50)
		label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		_enemy_labels.append(label)

		var bar := ProgressBar.new()
		bar.position = Vector2(14, 162)
		bar.size = Vector2(132, 7)
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", _resource_track_style())
		bar.add_theme_stylebox_override("fill", _resource_fill_style(Color(0.86, 0.28, 0.36)))
		content.add_child(bar)
		_enemy_bars.append(bar)

		var status := Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 11)
		status.position = Vector2(5, 172)
		status.size = Vector2(150, 12)
		status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(status)
		_enemy_statuses.append(status)


func _select_enemy(index: int) -> void:
	if index < 0 or index >= _enemies.size():
		return
	if int(_enemies[index].get("hp", 0)) <= 0:
		return
	_active_enemy_index = index
	_enemy = _enemies[index]
	_refresh()


func _toggle_inspect() -> void:
	if _inspect_overlay != null and is_instance_valid(_inspect_overlay):
		_inspect_overlay.queue_free()
		_inspect_overlay = null
		return
	_build_inspect_overlay()


func _build_inspect_overlay() -> void:
	_inspect_overlay = ColorRect.new()
	_inspect_overlay.color = Color(0.01, 0.015, 0.03, 0.94)
	_inspect_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inspect_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_inspect_overlay)

	var panel := PanelContainer.new()
	panel.position = Vector2(60, 36)
	panel.size = Vector2(1160, 690)
	panel.add_theme_stylebox_override("panel", _inspect_panel_style())
	_inspect_overlay.add_child(panel)

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(content)

	var title := Label.new()
	title.text = "战斗详情"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", GOLD)
	title.position = Vector2(24, 16)
	title.size = Vector2(400, 36)
	content.add_child(title)

	var close := Button.new()
	close.text = "关闭"
	close.position = Vector2(1058, 12)
	close.size = Vector2(82, 34)
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(_toggle_inspect)
	content.add_child(close)

	_inspect_tabs = TabContainer.new()
	_inspect_tabs.position = Vector2(20, 58)
	_inspect_tabs.size = Vector2(1120, 610)
	content.add_child(_inspect_tabs)
	_inspect_tabs.add_child(_build_inspect_items_tab())
	_inspect_tabs.add_child(_build_inspect_party_tab())
	_inspect_tabs.add_child(_build_inspect_enemy_tab())


func _build_inspect_items_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "道具"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1060, 0)
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	var counts := {}
	for item_key in Run.inventory:
		counts[item_key] = int(counts.get(item_key, 0)) + 1
	if counts.is_empty():
		var empty := Label.new()
		empty.text = "当前背包没有可查看的道具。"
		empty.add_theme_font_size_override("font_size", 16)
		box.add_child(empty)
	else:
		for item_key in GameData.ACTIVE_ITEM_KEYS:
			var count: int = int(counts.get(item_key, 0))
			if count <= 0:
				continue
			var item: Dictionary = GameData.ITEMS[item_key]
			var kind := "装备" if item.get("kind", "consumable") == "equipment" else "消耗品"
			var detail := "%s ×%d　[%s]\n%s" % [
				item["name"], count, kind, item["desc"]]
			box.add_child(_inspect_card(detail, Color(0.16, 0.28, 0.25)))
		var hint := Label.new()
		hint.text = "消耗品会在我方回合使用；装备请在进入战斗前的装备准备页调整。"
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(0.70, 0.76, 0.86))
		box.add_child(hint)
	return scroll


func _build_inspect_party_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "我方角色"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1060, 0)
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	for i in Run.party.size():
		var actor: Dictionary = Run.party[i]
		var role_name := "前台输出" if actor.get("role", "front") == "front" else "后台辅助"
		var skill_details := []
		for skill_key in actor.get("skills", [actor.get("skill", "")]):
			var skill: Dictionary = GameData.SKILLS.get(skill_key, {})
			skill_details.append("%s（消耗 %d %s）：%s" % [
				skill.get("name", "未知技能"),
				skill.get("cost", 0),
				"体力" if skill.get("cost_type", "stamina") == "stamina" else "魔力",
				skill.get("desc", "暂无说明")])
		var actor_key: String = actor.get("key", Run.character_key)
		var equipment_text := Run.equipment_summary(actor_key)
		var equipped_details := []
		for slot_index in 3:
			var item_key := Run.equipment_in_slot(slot_index, actor_key)
			if item_key == "":
				continue
			var item: Dictionary = GameData.ITEMS[item_key]
			equipped_details.append("装备%d：%s" % [slot_index + 1, item["desc"]])
		if not equipped_details.is_empty():
			equipment_text += "\n" + "\n".join(equipped_details)
		var passive_details := []
		if actor.get("starter_passive_active", false) and actor.has("starter_passive"):
			passive_details.append("入梦被动【%s】：%s" % [
				actor["starter_passive"].get("name", ""),
				actor["starter_passive"].get("desc", "")])
		for passive in actor.get("growth_passives", []):
			passive_details.append("培养被动【%s】：%s" % [
				passive.get("name", ""), passive.get("desc", "")])
		var passive_text := "无" if passive_details.is_empty() else "\n".join(passive_details)
		var synergy_hints: Array = Run.character_synergy_hints(actor_key)
		var synergy_text := "无" if synergy_hints.is_empty() else "\n".join(synergy_hints)
		var detail := "%s　Lv.%d　[%s]\n技能：\n%s\n战斗被动：%s\n穿戴装备：%s\n联动提示：\n%s\n当前状态：%s" % [
			actor["name"], actor.get("level", 1), role_name,
			"\n".join(skill_details),
			passive_text,
			equipment_text,
			synergy_text,
			_status_text(actor)]
		box.add_child(_inspect_card(detail, CHARACTER_COLORS.get(actor["name"], Color(0.20, 0.38, 0.52))))
	return scroll


func _build_inspect_enemy_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "敌方心魔"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1060, 0)
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	for enemy in _enemies:
		var pattern: String = enemy.get("pattern", "attack")
		var skill_name := "普通攻击"
		var skill_desc := "随机攻击一名存活角色，基础攻击为 %d。" % enemy.get("atk", 0)
		match pattern:
			"heavy_every_3":
				skill_name = "蓄力重击"
				skill_desc = "每 3 回合发动一次，伤害约为普通攻击的 2 倍。"
			"bleed_every_2":
				skill_name = "撕裂攻击"
				skill_desc = "每 2 回合攻击并施加 2 层流血。"
			"stun_every_3":
				skill_name = "震慑打击"
				skill_desc = "每 3 回合攻击并施加 1 回合晕眩。"
			"shield_every_2":
				skill_name = "守护屏障"
				skill_desc = "每 2 回合为自己获得 6 点护盾。"
			"shield_ally_every_2":
				skill_name = "同伴屏障"
				skill_desc = "每 2 回合为生命比例最低的心魔提供 9 点护盾。"
			"heal_every_3":
				skill_name = "暗影修复"
				skill_desc = "每 3 回合回复 6 点生命。"
			"heal_ally_every_2":
				skill_name = "缝补梦躯"
				skill_desc = "每 2 回合治疗生命比例最低的心魔 10 点。"
		var detail := "%s　【%s】%s\n生命 %d/%d　攻击 %d\n技能：%s\n技能效果：%s\n当前状态：%s\n下一行动：%s" % [
			enemy["name"], enemy.get("emotion", "未知"),
			"　【当前目标】" if enemy == _enemy else "",
			enemy["hp"], enemy["max_hp"], enemy["atk"],
			skill_name, skill_desc, _status_text(enemy),
			_intent_text(Battle.enemy_intent(enemy, _round))]
		box.add_child(_inspect_card(
			detail,
			ENEMY_COLORS.get(enemy.get("key", ""), Color(0.5, 0.18, 0.22))))
	return scroll


func _inspect_card(text: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1060, 0)
	card.add_theme_stylebox_override("panel", _inspect_panel_style(color))
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; label.clip_text = true
	label.custom_minimum_size = Vector2(1020, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_child(label)
	return card


func _inspect_panel_style(color := Color(0.11, 0.15, 0.23)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _active_actor() -> Dictionary:
	if Run.party.is_empty():
		return Run.player
	return Run.party[_active_index]


func _first_alive_index() -> int:
	for i in Run.party.size():
		if Run.party[i].get("hp", 0) > 0:
			return i
	return 0


func _start_player_turn() -> void:
	_phase = "player"
	_turn_locked.clear()
	_actions_taken.clear()
	var start_messages := []
	var recovery_messages := []
	var any_alive := false
	for i in Run.party.size():
		var ally: Dictionary = Run.party[i]
		_actions_taken.append(0)
		if int(ally.get("hp", 0)) <= 0:
			_turn_locked.append(i)
			continue
		var turn_start: Dictionary = Battle.resolve_turn_start(ally)
		if not turn_start["log"].is_empty():
			start_messages.append("%s：%s" % [ally["name"], _damage_text(turn_start["log"])])
		if turn_start["skip"]:
			_turn_locked.append(i)
		if int(ally.get("hp", 0)) > 0:
			any_alive = true
			var recovered: Dictionary = Run.restore_turn_resources(ally)
			if int(recovered["stamina"]) > 0 or int(recovered["mana"]) > 0:
				recovery_messages.append("%s：体力 +%d，魔力 +%d" % [
					ally["name"], recovered["stamina"], recovered["mana"]])
			if not turn_start["skip"] and ally.get("charging_skill", "") != "":
				_release_charged_skill(i, ally)
				if _battle_over:
					return
	if not start_messages.is_empty():
		_log_text += "\n" + "\n".join(start_messages)
	if not recovery_messages.is_empty():
		_log_text += "\n探索恢复（Lv.%d）：\n%s" % [
			Run.exploration_level, "\n".join(recovery_messages)]
	if not any_alive:
		_lose()
		return
	_active_index = _first_actionable_index()
	_refresh()


func _first_actionable_index() -> int:
	for i in Run.party.size():
		if Run.party[i].get("hp", 0) > 0 and not _turn_locked.has(i):
			return i
	return _first_alive_index()


func _refresh() -> void:
	var active := _active_actor()
	_title_label.text = "%s　角色Lv.%d　节点Lv.%d　探索Lv.%d　金币%d　压力%d　强度%d" % [
		NODE_TITLES.get(_node_type, "心魔遭遇"),
		int(Run.player.get("level", 1)), Run.battle_level,
		Run.exploration_level, Run.gold,
		Run.dream_pressure, Run.battle_effective_tier]
	if _phase == "player":
		var regen: Dictionary = Run.exploration_regen()
		_phase_label.text = "第 %d 回合　我方行动　探索 Lv.%d（体力/魔力 +%d）" % [
			_round, Run.exploration_level, regen["stamina"]]
		_phase_label.add_theme_color_override("font_color", Color(0.50, 0.80, 1.0))
	else:
		_phase_label.text = "第 %d 回合　心魔行动" % _round
		_phase_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.56))

	if _enemies.is_empty():
		return
	_active_enemy_index = clampi(_active_enemy_index, 0, _enemies.size() - 1)
	_enemy = _enemies[_active_enemy_index]
	_rebuild_enemy_cards()
	for index in _enemies.size():
		var foe: Dictionary = _enemies[index]
		_enemy_labels[index].text = "%s\n生命 %d/%d\n攻击 %d" % [
			foe["name"], foe["hp"], foe["max_hp"], foe["atk"]]
		_enemy_bars[index].max_value = foe["max_hp"]
		_enemy_bars[index].value = foe["hp"]
		_enemy_statuses[index].text = _status_text(foe)
	_enemy_label = _enemy_labels[_active_enemy_index]
	_enemy_bar = _enemy_bars[_active_enemy_index]
	_enemy_status_label = _enemy_statuses[_active_enemy_index]
	_enemy_intent_label.text = "当前目标：%s\n下一行动\n%s" % [
		_enemy["name"], _intent_text(Battle.enemy_intent(_enemy, _round))]
	_log_label.text = _log_text
	_equipment_label.text = Run.equipment_summary(active.get("key", Run.character_key))
	if int(active.get("damage_reduction", 0)) > 0:
		_equipment_label.text += "　｜减伤 %d" % active["damage_reduction"]
	if int(active.get("item_power", 0)) > 0:
		_equipment_label.text += "　｜道具强化 +%d" % active["item_power"]
	var synergy_names: Array = Run.active_synergy_names()
	if not synergy_names.is_empty():
		_equipment_label.text += "　｜联动：" + "、".join(synergy_names)
	_passives_label.text = _passives_text(active)

	_rebuild_party_cards()
	_clear_container(_action_box)
	_clear_container(_item_box)
	if _battle_over:
		return
	if _phase == "player":
		_add_player_buttons(active)


func _rebuild_party_cards() -> void:
	_clear_container(_front_party_box)
	_clear_container(_back_party_box)
	_party_card_nodes.clear()
	for i in Run.party.size():
		var actor: Dictionary = Run.party[i]
		var active := i == _active_index
		var action_count: int = int(_actions_taken[i]) if i < _actions_taken.size() else 0
		var locked := _turn_locked.has(i)
		var dead := int(actor.get("hp", 0)) <= 0
		var card := Button.new()
		_party_card_nodes.append(card)
		card.custom_minimum_size = Vector2(218, 136)
		card.text = ""
		card.focus_mode = Control.FOCUS_NONE
		var color: Color = CHARACTER_COLORS.get(actor.get("name", ""), Color(0.20, 0.38, 0.52))
		if dead:
			color = color.darkened(0.65)
		elif locked:
			color = color.darkened(0.35)
		var normal_style := _card_style(color, active)
		card.add_theme_stylebox_override("normal", normal_style)
		card.add_theme_stylebox_override("hover", _card_style(color.lightened(0.08), active))
		card.add_theme_stylebox_override("pressed", _card_style(color.darkened(0.08), active))
		card.pressed.connect(_on_switch.bind(i))
		if actor.get("role", "front") == "front":
			_front_party_box.add_child(card)
		else:
			_back_party_box.add_child(card)

		var portrait := ArtAssets.add_texture(
			card,
			ArtAssets.character(actor.get("key", "")),
			Rect2(Vector2(6, 14), Vector2(92, 114)))
		if portrait.texture == null:
			portrait.queue_free()

		var placeholder := Label.new()
		var actor_level: int = int(actor.get("level", 1))
		var level_text := (
			"MAX" if actor_level >= GameData.MAX_CHARACTER_LEVEL
			else "Lv.%d" % actor_level)
		placeholder.text = "%s · %s" % [
			"前台" if actor.get("role", "front") == "front" else "后台",
			level_text]
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 10)
		placeholder.position = Vector2(96, 2)
		placeholder.size = Vector2(116, 16)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(placeholder)

		var info := Label.new()
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 12)
		info.position = Vector2(96, 20)
		info.size = Vector2(116, 24)
		info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.text = "%s　攻 %d" % [
			actor["name"],
			actor["atk"]]
		card.add_child(info)

		# —— 生命 / 体力 / 魔力 三条独立细条（约 3px 高，数值在左、细条在右，互不重叠）——
		# 生命条末端直接叠白色护盾尾；文字显示如「生命 28/28（12）」。
		var shield_val := int(actor.get("shield", 0))
		var stat_rows := [
			{
				"label": "生命  %d/%d" % [actor["hp"], actor["max_hp"]] + ("" if shield_val <= 0 else "（%d）" % shield_val),
				"tip": "生命：%d / %d　护盾：%d" % [actor["hp"], actor["max_hp"], shield_val],
				"max": actor["max_hp"], "cur": actor["hp"],
				"color": Color(0.28, 0.78, 0.48), "shield": shield_val,
			},
			{
				"label": "体力  %d/%d" % [actor.get("stamina", 0), actor.get("max_stamina", 0)],
				"tip": "体力：%d / %d" % [actor.get("stamina", 0), actor.get("max_stamina", 0)],
				"max": maxi(1, int(actor.get("max_stamina", 1))), "cur": actor.get("stamina", 0),
				"color": Color(0.94, 0.66, 0.24), "shield": 0,
			},
			{
				"label": "魔力  %d/%d" % [actor.get("mana", 0), actor.get("max_mana", 0)],
				"tip": "魔力：%d / %d" % [actor.get("mana", 0), actor.get("max_mana", 0)],
				"max": maxi(1, int(actor.get("max_mana", 1))), "cur": actor.get("mana", 0),
				"color": Color(0.32, 0.58, 0.96), "shield": 0,
			},
		]
		for row_index in stat_rows.size():
			var row: Dictionary = stat_rows[row_index]
			var row_y := 48 + row_index * 28
			var val := Label.new()
			val.text = row["label"]
			val.add_theme_font_size_override("font_size", 10)
			val.add_theme_color_override("font_color", Color(0.90, 0.93, 0.98))
			val.position = Vector2(96, row_y)
			val.size = Vector2(72, 18)
			val.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(val)
			var bar := BarView.new()
			bar.position = Vector2(170, row_y + 7)
			bar.size = Vector2(40, 3)
			bar.setup(row["cur"], row["max"], row["color"], row["shield"])
			bar.tooltip_text = row["tip"]
			card.add_child(bar)
			if row_index == 0:
				_player_bar = bar

		var status := Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 11)
		status.position = Vector2(94, 124)
		status.size = Vector2(118, 16)
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status.text = "本回合无法行动" if locked and not dead else _status_text(actor)
		card.add_child(status)


func _resource_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	style.shadow_color = Color(color, 0.16)
	style.shadow_size = 1
	return style


func _resource_track_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.06, 0.92)
	style.border_color = Color(0.42, 0.48, 0.60, 0.56)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _add_player_buttons(active: Dictionary) -> void:
	var can_act: bool = not _turn_locked.has(_active_index) and int(active.get("hp", 0)) > 0
	var attack := _add_button(
		_action_box,
		"普通攻击\n消耗 1 体力｜对当前目标造成 100% 攻击",
		_on_attack,
		200)
	attack.disabled = not can_act or active.get("stamina", 0) < 1

	var skill_keys: Array = active.get("skills", [active["skill"]])
	for skill_key in skill_keys:
		var skill: Dictionary = GameData.SKILLS[skill_key]
		var resource_key: String = "stamina" if skill.get("cost_type", "stamina") == "stamina" else "mana"
		var charge_text := "【蓄力 %d 回合】" % skill.get("charge_turns", 0) if skill.get("charge_turns", 0) > 0 else ""
		var skill_button := _add_button(
			_action_box,
			"%s%s\n%s" % [skill["name"], charge_text, skill["desc"]],
			_on_skill.bind(skill_key),
			225)
		skill_button.disabled = not can_act or active.get(resource_key, 0) < int(skill.get("cost", 0))

	var emergency := _add_button(
		_action_box,
		"应急包\n本场限 1 次｜回复 %d 点生命" % POTION_HEAL,
		_on_potion,
		180)
	emergency.disabled = not can_act or _potion_used

	_add_button(_action_box, "结束我方回合\n所有存活心魔依次行动", _on_end_turn, 190)
	_rebuild_inventory_buttons(can_act)


func _rebuild_inventory_buttons(can_act: bool) -> void:
	var counts := {}
	for item_key in Run.inventory:
		counts[item_key] = int(counts.get(item_key, 0)) + 1
	for item_key in GameData.ACTIVE_ITEM_KEYS:
		var count: int = int(counts.get(item_key, 0))
		if count <= 0:
			continue
		var item: Dictionary = GameData.ITEMS[item_key]
		if item.get("kind", "consumable") == "equipment":
			continue
		var button := _add_button(
			_item_box,
			"%s ×%d\n%s" % [item["name"], count, item["desc"]],
			_on_item.bind(item_key),
			245, 46)
		button.disabled = not can_act


func _add_button(
	box: HBoxContainer,
	text: String,
	callable: Callable,
	width: float = 245.0,
	height: float = 72.0
) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, height)
	button.add_theme_font_size_override("font_size", 12)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.tooltip_text = text
	button.pressed.connect(callable)
	box.add_child(button)
	return button


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_switch(index: int) -> void:
	if _phase != "player" or _battle_over:
		return
	if index < 0 or index >= Run.party.size():
		return
	if _turn_locked.has(index) or Run.party[index].get("hp", 0) <= 0:
		return
	_active_index = index
	_refresh()


func _on_attack() -> void:
	_player_act({"effect": "attack", "multiplier": 1.0, "cost_type": "stamina", "cost": 1})


func _on_skill(skill_key: String = "") -> void:
	if skill_key == "":
		skill_key = _active_actor()["skill"]
	var action: Dictionary = GameData.SKILLS[skill_key].duplicate()
	if int(action.get("charge_turns", 0)) > 0:
		_start_charging(skill_key, action)
		return
	if action.get("target", "self") == "ally":
		action["ally_target"] = _best_ally_target(action)
	action["_skill_key"] = skill_key
	_player_act(action)


func _start_charging(skill_key: String, action: Dictionary) -> void:
	if _phase != "player" or _battle_over or _turn_locked.has(_active_index):
		return
	var actor: Dictionary = _active_actor()
	var resource_key := "stamina" if action.get("cost_type", "stamina") == "stamina" else "mana"
	var cost: int = int(action.get("cost", 0))
	if actor.get("battle_first_action_available", false):
		cost = maxi(0, cost - int(actor.get("first_action_discount", 0)))
	if int(actor.get(resource_key, 0)) < cost:
		_log_text = "%s：资源不足，无法开始蓄力。" % actor["name"]
		_refresh()
		return
	actor[resource_key] -= cost
	actor["battle_first_action_available"] = false
	actor["charging_skill"] = skill_key
	actor["charge_target_index"] = _active_enemy_index
	actor["charge_started_round"] = _round
	if _active_index < _actions_taken.size():
		_actions_taken[_active_index] = 1
	if not _turn_locked.has(_active_index):
		_turn_locked.append(_active_index)
	_log_text = "%s 开始蓄力【%s】。\n下一个我方回合将自动释放；蓄力期间仍可能受到攻击。" % [
		actor["name"], action["name"]]
	_refresh()


func _release_charged_skill(actor_index: int, actor: Dictionary) -> void:
	var skill_key: String = actor.get("charging_skill", "")
	if skill_key == "" or not GameData.SKILLS.has(skill_key):
		return
	var action: Dictionary = GameData.SKILLS[skill_key].duplicate()
	action["cost"] = 0
	action["charge_turns"] = 0
	action["charged_release"] = true
	var target_index: int = int(actor.get("charge_target_index", _active_enemy_index))
	if target_index >= 0 and target_index < _enemies.size() and int(_enemies[target_index].get("hp", 0)) > 0:
		_active_enemy_index = target_index
		_enemy = _enemies[target_index]
	elif _first_alive_enemy_index() >= 0:
		_active_enemy_index = _first_alive_enemy_index()
		_enemy = _enemies[_active_enemy_index]
	actor["charging_skill"] = ""
	_execute_action(actor_index, action, false)


func _best_ally_target(action: Dictionary) -> Dictionary:
	var result: Dictionary = _active_actor()
	var best_ratio := 2.0
	var resource_key: String = action.get("resource", "")
	for ally in Run.party:
		if int(ally.get("hp", 0)) <= 0:
			continue
		var ratio: float
		if action.get("effect", "") == "restore" and resource_key != "":
			var maximum: int = maxi(1, int(ally.get("max_" + resource_key, 1)))
			ratio = float(ally.get(resource_key, 0)) / float(maximum)
		elif action.get("effect", "") == "cleanse":
			if int(ally.get("bleed", 0)) > 0 or int(ally.get("stunned", 0)) > 0:
				return ally
			ratio = float(ally.get("hp", 0)) / float(maxi(1, int(ally.get("max_hp", 1))))
		else:
			ratio = float(ally.get("hp", 0)) / float(maxi(1, int(ally.get("max_hp", 1))))
		if ratio < best_ratio:
			best_ratio = ratio
			result = ally
	return result


func _on_potion() -> void:
	if _potion_used:
		return
	_potion_used = true
	_player_act({"effect": "heal", "amount": POTION_HEAL})


func _on_item(item_key: String) -> void:
	if not Run.inventory.has(item_key) or _turn_locked.has(_active_index):
		return
	var item: Dictionary = GameData.ITEMS[item_key]
	if item.get("kind", "consumable") == "equipment":
		return
	Run.inventory.erase(item_key)
	var action: Dictionary = item.duplicate()
	action["is_item"] = true
	_player_act(action)


func _player_act(action: Dictionary, consume_action: bool = true) -> void:
	if _phase != "player" or _battle_over:
		return
	_execute_action(_active_index, action, consume_action)


func _execute_action(actor_index: int, action: Dictionary, consume_action: bool = true) -> void:
	if actor_index < 0 or actor_index >= Run.party.size():
		return
	var actor: Dictionary = Run.party[actor_index]
	var original_cost: int = int(action.get("cost", 0))
	if actor.get("battle_first_action_available", false):
		action["cost"] = maxi(0, original_cost - int(actor.get("first_action_discount", 0)))
	action["skip_start_status"] = true
	var targets: Array = _targets_for_action(actor, action)
	if targets.is_empty():
		_log_text = "%s：没有有效目标。" % actor["name"]
		_refresh()
		return
	var action_messages := []
	var total_kills := 0
	var first_resolution := true
	var first_support_target: Dictionary = {}
	for target in targets:
		var target_before_hp: int = int(target.get("hp", 0))
		var target_was_bleeding := int(target.get("bleed", 0)) > 0
		var local_action: Dictionary = action.duplicate()
		if not first_resolution:
			local_action["cost"] = 0
		if action.get("target", "self") == "ally" or action.get("target_mode", "") == "all_allies":
			local_action["target"] = "ally"
			local_action["ally_target"] = target
			if first_support_target.is_empty():
				first_support_target = target
		var log: Array = Battle.resolve_turn(actor, local_action, target)
		if first_resolution and log.size() > 0 and log[0].has("error"):
			action["cost"] = original_cost
			_log_text = "%s：%s" % [actor["name"], _damage_text(log)]
			_refresh()
			return
		if action.get("effect", "") == "attack" and actor.get("battle_first_attack_available", false):
			var bonus: int = int(actor.get("first_attack_bonus", 0))
			if bonus > 0:
				target["hp"] = maxi(0, int(target["hp"]) - bonus)
				log.append({"dmg": bonus, "source": "starter_passive"})
			actor["battle_first_attack_available"] = false
		var phase_message := _check_enemy_phase(target)
		if phase_message != "":
			action_messages.append(phase_message)
		action_messages.append("%s：%s" % [target.get("name", actor["name"]), _damage_text(log)])
		var action_effect = action.get("effect", "")
		if BattleFx.ENABLED and action_effect == "attack" and _enemies.has(target):
			var hit_dmg := _fx_log_damage(log)
			if hit_dmg > 0:
				var t_idx := _enemies.find(target)
				if t_idx >= 0 and t_idx < _enemy_cards.size():
					var t_card: Control = _enemy_cards[t_idx]
					_play_hit_vfx(t_card, hit_dmg)
		elif BattleFx.ENABLED and action_effect in ["heal", "restore", "cleanse"] and Run.party.has(target):
			_play_heal_vfx(_party_card_nodes[Run.party.find(target)] if Run.party.find(target) < _party_card_nodes.size() else null)
		elif BattleFx.ENABLED and action_effect == "shield" and Run.party.has(target):
			_play_shield_vfx(_party_card_nodes[Run.party.find(target)] if Run.party.find(target) < _party_card_nodes.size() else null)
		if BattleFx.ENABLED and action_effect == "attack" and actor_index < _party_card_nodes.size():
			BattleFx.card_lunge(_party_card_nodes[actor_index] as Control)
		if target_before_hp > 0 and int(target.get("hp", 0)) <= 0 and _enemies.has(target):
			total_kills += 1
		if action.get("effect", "") == "attack" and target_was_bleeding:
			actor["hp"] = mini(
				int(actor.get("max_hp", actor.get("hp", 0))),
				int(actor.get("hp", 0)) + int(actor.get("bleed_hit_heal", 0)))
		first_resolution = false
	actor["battle_first_action_available"] = false
	var is_support: bool = action.get("effect", "") in ["heal", "shield", "cleanse", "restore"]
	if is_support:
		if actor.get("battle_first_support_available", false):
			var passive_shield: int = int(actor.get("first_support_shield", 0))
			if passive_shield > 0:
				var support_target := first_support_target if not first_support_target.is_empty() else actor
				support_target["shield"] = int(support_target.get("shield", 0)) + passive_shield
				action_messages.append("%s：入梦被动额外提供 %d 护盾" % [
					support_target["name"], passive_shield])
			actor["battle_first_support_available"] = false
		if int(actor.get("support_refund_mana", 0)) > 0:
			actor["mana"] = mini(
				int(actor.get("max_mana", actor.get("mana", 0))),
				int(actor.get("mana", 0)) + int(actor["support_refund_mana"]))
		if action.get("effect", "") == "cleanse" and int(actor.get("cleanse_shield", 0)) > 0:
			for target in targets:
				target["shield"] = int(target.get("shield", 0)) + int(actor["cleanse_shield"])
	if total_kills > 0:
		actor["stamina"] = mini(
			int(actor.get("max_stamina", actor.get("stamina", 0))),
			int(actor.get("stamina", 0)) + int(actor.get("on_kill_restore_stamina", 0)) * total_kills)
		actor["mana"] = mini(
			int(actor.get("max_mana", actor.get("mana", 0))),
			int(actor.get("mana", 0)) + int(actor.get("on_kill_restore_mana", 0)) * total_kills)
		actor["hp"] = mini(
			int(actor.get("max_hp", actor.get("hp", 0))),
			int(actor.get("hp", 0)) + int(actor.get("on_kill_heal", 0)) * total_kills)
	_log_text = "%s%s：\n%s" % [
		actor["name"],
		" 释放蓄力技能" if action.get("charged_release", false) else "",
		"\n".join(action_messages)]
	if consume_action and actor_index < _actions_taken.size():
		_actions_taken[actor_index] = int(_actions_taken[actor_index]) + 1
		if not _turn_locked.has(actor_index):
			_turn_locked.append(actor_index)
	var next_enemy := _first_alive_enemy_index()
	if next_enemy < 0:
		_win()
		return
	if int(_enemy.get("hp", 0)) <= 0:
		_active_enemy_index = next_enemy
		_enemy = _enemies[next_enemy]
	_refresh()


func _targets_for_action(actor: Dictionary, action: Dictionary) -> Array:
	match action.get("target_mode", ""):
		"all_enemies":
			var enemies := []
			for enemy in _enemies:
				if int(enemy.get("hp", 0)) > 0:
					enemies.append(enemy)
			return enemies
		"all_allies":
			var allies := []
			for ally in Run.party:
				if int(ally.get("hp", 0)) > 0:
					allies.append(ally)
			return allies
	if action.get("target", "self") == "ally":
		return [action.get("ally_target", _best_ally_target(action))]
	if action.get("effect", "") == "attack":
		return [_enemy]
	return [actor]


func _on_end_turn() -> void:
	if _phase != "player" or _battle_over:
		return
	_enemy_turn()


func _enemy_turn() -> void:
	_phase = "enemy"
	var enemy_messages := []
	var round_targets: Array = []
	for enemy in _enemies:
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var target_index := _random_alive_ally_index(round_targets)
		if target_index < 0:
			_lose()
			return
		round_targets.append(target_index)
		_last_enemy_target_index = target_index
		var target: Dictionary = Run.party[target_index]
		var intent: Dictionary = Battle.enemy_intent(enemy, _round)
		var action_target: String = str(target["name"])
		var resolution_target: Dictionary = target
		if intent.get("target", "self") == "ally":
			resolution_target = _lowest_ratio_enemy()
			intent["ally_target"] = resolution_target
			action_target = resolution_target.get("name", enemy["name"])
		var log: Array = Battle.resolve_turn(enemy, intent, resolution_target)
		if intent.get("effect", "") in ["shield", "heal"] and intent.get("target", "self") != "ally":
			action_target = enemy["name"]
		enemy_messages.append("%s → %s：%s" % [enemy["name"], action_target, _damage_text(log)])
		if BattleFx.ENABLED and Run.party.has(resolution_target):
			var p_idx := Run.party.find(resolution_target)
			if p_idx >= 0 and p_idx < _party_card_nodes.size():
				var p_card: Control = _party_card_nodes[p_idx]
				var e_dmg := _fx_log_damage(log)
				if e_dmg > 0:
					_play_hit_vfx(p_card, e_dmg)
	if not enemy_messages.is_empty():
		_log_text += "\n敌方行动：\n" + "\n".join(enemy_messages)
	_active_index = _first_alive_index()
	if _random_alive_ally_index([]) < 0:
		_lose()
		return
	_round += 1
	_start_player_turn()


func _first_alive_enemy_index() -> int:
	for i in _enemies.size():
		if int(_enemies[i].get("hp", 0)) > 0:
			return i
	return -1


func _lowest_ratio_enemy() -> Dictionary:
	var result: Dictionary = {}
	var lowest_ratio := 2.0
	for enemy in _enemies:
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var ratio := float(enemy.get("hp", 0)) / float(maxi(1, int(enemy.get("max_hp", 1))))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			result = enemy
	return result


func _check_enemy_phase(enemy: Dictionary) -> String:
	if enemy.is_empty() or int(enemy.get("hp", 0)) <= 0:
		return ""
	if enemy.get("phase_triggered", false) or not enemy.has("phase_threshold"):
		return ""
	var threshold: float = float(enemy["phase_threshold"])
	if float(enemy["hp"]) > float(enemy["max_hp"]) * threshold:
		return ""
	enemy["phase_triggered"] = true
	enemy["atk"] += int(enemy.get("phase_atk", 0))
	enemy["shield"] = int(enemy.get("shield", 0)) + int(enemy.get("phase_shield", 0))
	return "%s 进入第二阶段：攻击 +%d，获得 %d 点护盾" % [
		enemy["name"], enemy.get("phase_atk", 0), enemy.get("phase_shield", 0)]


func _random_alive_ally_index(excluded_indices: Array = []) -> int:
	var alive := []
	for i in Run.party.size():
		if int(Run.party[i].get("hp", 0)) > 0:
			alive.append(i)
	var candidates: Array = alive.duplicate()
	# 有多个存活角色时，优先排除上一名目标和本轮已经被选过的目标，
	# 让火力自然分散；只剩一个可选角色时才会继续攻击他。
	if candidates.size() > 1:
		if _last_enemy_target_index in candidates:
			candidates.erase(_last_enemy_target_index)
		for index in excluded_indices:
			if candidates.size() > 1 and index in candidates:
				candidates.erase(index)
	if candidates.is_empty():
		candidates = alive
	if candidates.is_empty():
		return -1
	return candidates[randi() % candidates.size()]


func _damage_text(log: Array) -> String:
	if log.size() > 0 and log[0].has("error"):
		return log[0]["error"]
	var dmg := 0
	var blocked := 0
	var hit_damages := []
	var statuses := []
	for entry in log:
		if entry.has("dmg"):
			dmg += entry["dmg"]
			if entry.get("source", "") != "starter_passive":
				hit_damages.append(int(entry["dmg"]))
		if entry.has("blocked"):
			blocked += entry["blocked"]
		if entry.has("status"):
			statuses.append(entry["status"])
		if entry.has("restore"):
			return "回复 %d 点%s" % [
				entry["restore"], "体力" if entry["resource"] == "stamina" else "魔力"]
		if entry.has("shield"):
			return "获得 %d 点护盾" % entry["shield"]
		if entry.has("cleanse"):
			var removed: Array = entry["cleanse"]
			if removed.is_empty():
				return "完成净化，并回复 %d 点生命" % entry.get("heal", 0)
			return "清除%s，并回复 %d 点生命" % [
				"、".join(removed), entry.get("heal", 0)]
	var suffix := ""
	if blocked > 0:
		suffix += "，护盾抵挡 %d" % blocked
	if statuses.size() > 0:
		suffix += "，附加" + "、".join(statuses)
	if dmg > 0 or blocked > 0:
		if hit_damages.size() > 1:
			var hit_texts := []
			for hit_damage in hit_damages:
				hit_texts.append(str(hit_damage))
			return "%d 段命中（%s），总计 %d 点伤害%s" % [
				hit_damages.size(), "+".join(hit_texts), dmg, suffix]
		return "造成 %d 点伤害%s" % [dmg, suffix]
	if statuses.size() > 0:
		return "附加" + "、".join(statuses)
	if log.size() > 0 and log[0].has("heal"):
		return "回复 %d 点生命" % log[0]["heal"]
	return "无事发生"


## 当前角色的被动说明：自身被动（入梦被动 + 培养被动）与穿戴装备的被动/效果。
func _passives_text(actor: Dictionary) -> String:
	if actor.is_empty():
		return "无"
	var lines: Array = []
	var has_any := false
	# 自身被动：入梦被动（只要角色持有即显示）与培养被动
	if actor.has("starter_passive"):
		var sp: Dictionary = actor["starter_passive"]
		lines.append("入梦【%s】%s" % [sp.get("name", ""), sp.get("desc", "")])
		has_any = true
	for passive in actor.get("growth_passives", []):
		lines.append("培养【%s】%s" % [passive.get("name", ""), passive.get("desc", "")])
		has_any = true
	# 装备被动（装备类物品的效果即为其被动）
	var key: String = actor.get("key", Run.character_key)
	for slot_index in 3:
		var item_key: String = Run.equipment_in_slot(slot_index, key)
		if item_key == "":
			continue
		var item: Dictionary = GameData.ITEMS.get(item_key, {})
		if kind_of_item_is_equipment(item):
			lines.append("装备【%s】%s" % [item.get("name", ""), item.get("desc", "")])
			has_any = true
	if not has_any:
		return "无"
	return "\n".join(lines)


func kind_of_item_is_equipment(item: Dictionary) -> bool:
	return str(item.get("kind", "consumable")) == "equipment"


## 给指定卡播放「治愈光环」（绿色治疗光，贴图版）。
func _play_heal_vfx(target: Control) -> void:
	AudioMan.play_sfx("res://audio/heal")
	_play_float_vfx(target, "res://art/ready_v2/effects/heal_glow.png")


## 给指定卡播放「护盾光罩」（青蓝罩，贴图版）。
func _play_shield_vfx(target: Control) -> void:
	AudioMan.play_sfx("res://audio/heal")
	_play_float_vfx(target, "res://art/ready_v2/effects/shield_aura.png")


## 在目标卡上叠加一张特效贴图（加法混合，淡入→保持→淡出）。用于治疗/护盾。
func _play_float_vfx(target: Control, tex_path: String) -> void:
	if target == null:
		return
	var tex := load(tex_path)
	if tex == null:
		return
	var c = target.global_position - global_position + target.size * 0.5
	var size = Vector2(target.size.x * 1.5, target.size.y * 1.5)
	var fx := FxTexView.new(tex, Rect2(c - size * 0.5, size))
	var fx_mat := CanvasItemMaterial.new()
	fx_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = fx_mat
	fx.z_index = 998
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	fx.modulate.a = 0.0
	var tw := fx.create_tween()
	tw.tween_property(fx, "modulate:a", 1.0, 0.08)
	tw.tween_interval(0.22)
	tw.tween_property(fx, "modulate:a", 0.0, 0.22)
	tw.tween_callback(fx.queue_free)


## 受击爆裂特效（炉石式）：放射光图标 + 中心伤害数字，淡入→放大→淡出。
func _play_hit_vfx(target: Control, amount: int) -> void:
	if target == null:
		return
	AudioMan.play_sfx("res://audio/hit")
	var hittex := load("res://art/ready_v2/effects/hit_burst.png")
	if hittex == null:
		return
	var c = target.global_position - global_position + target.size * 0.5
	var size = Vector2(185, 185)
	var fx := FxTexView.new(hittex, Rect2(c - size * 0.5, size))
	var fx_mat := CanvasItemMaterial.new()
	fx_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = fx_mat
	fx.z_index = 1001
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	fx.pivot_offset = size * 0.5
	fx.scale = Vector2(0.5, 0.5)
	fx.modulate.a = 0.0
	# 白色亮核上放大号伤害数字：深色字 + 浅描边，保证可读
	var label = Label.new()
	label.text = "-%d" % amount
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.16, 0.10, 0.26))
	label.add_theme_color_override("font_outline_color", Color(0.99, 0.96, 0.90, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	label.position = c + Vector2(-44, -26)
	label.size = Vector2(88, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 1002
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tw := fx.create_tween()
	tw.tween_property(fx, "modulate:a", 1.0, 0.05)
	tw.tween_property(fx, "scale", Vector2(1.15, 1.15), 0.12)
	tw.tween_interval(0.05)
	tw.tween_property(fx, "modulate:a", 0.0, 0.20)
	tw.tween_callback(fx.queue_free)
	var tw2 = label.create_tween()
	label.modulate.a = 0.0
	tw2.tween_property(label, "modulate:a", 1.0, 0.05)
	tw2.tween_interval(0.10)
	tw2.tween_property(label, "modulate:a", 0.0, 0.24)
	tw2.tween_callback(label.queue_free)


## 从战斗结算日志中求出总伤害值（用于特效飘字）。
func _fx_log_damage(log: Array) -> int:
	var total := 0
	for entry in log:
		if entry.has("dmg"):
			total += int(entry["dmg"])
	return total


func _status_text(actor: Dictionary) -> String:
	var parts := []
	if actor.get("charging_skill", "") != "":
		var skill_key: String = actor["charging_skill"]
		parts.append("蓄力：%s" % GameData.SKILLS.get(skill_key, {}).get("name", skill_key))
	if int(actor.get("shield", 0)) > 0:
		parts.append("护盾 %d" % actor["shield"])
	if int(actor.get("bleed", 0)) > 0:
		parts.append("流血 %d" % actor["bleed"])
	if int(actor.get("stunned", 0)) > 0:
		parts.append("晕眩")
	if int(actor.get("damage_reduction", 0)) > 0:
		parts.append("减伤 %d" % actor["damage_reduction"])
	return "　".join(parts) if not parts.is_empty() else "状态正常"


func _intent_text(intent: Dictionary) -> String:
	if intent.get("effect", "") == "shield":
		if intent.get("target", "self") == "ally":
			return "同伴屏障\n保护生命比例最低的心魔"
		return "守护屏障\n为自己获得护盾"
	if intent.get("effect", "") == "heal":
		if intent.get("target", "self") == "ally":
			return "梦躯缝补\n治疗生命比例最低的心魔"
		return "暗影修复\n为自己回复生命"
	if intent.get("status", "") == "bleed":
		return "流血攻击\n造成伤害并施加流血"
	if intent.get("status", "") == "stun":
		return "震慑攻击\n造成伤害并施加晕眩"
	if float(intent.get("multiplier", 1.0)) >= 1.8:
		return "蓄力重击\n预计造成高额伤害"
	return "普通攻击\n随机攻击一名存活角色"


func _card_style(color: Color, active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 4 if active else 2
	style.border_width_top = 4 if active else 2
	style.border_width_right = 4 if active else 2
	style.border_width_bottom = 4 if active else 2
	style.border_color = GOLD if active else color.lightened(0.28)
	return style


func _win() -> void:
	_battle_over = true
	var gold_gain := 10
	if _node_type == "elite":
		gold_gain = 15
	elif _node_type == "boss":
		gold_gain = 30
	var defeated_tier := Run.battle_effective_tier
	gold_gain = int(round(gold_gain * (1.0 + 0.35 * maxi(0, defeated_tier - 1))))
	Run.gold += gold_gain
	var xp_gain := 14 + defeated_tier * 8
	if _node_type == "elite":
		xp_gain += 12
	elif _node_type == "boss":
		xp_gain += 24
	var xp_result: Dictionary = Run.gain_exploration_xp(xp_gain, "战斗胜利")
	_victory_node_cards = Run.grant_battle_node_cards(
		Run.battle_level, _node_type, defeated_tier)
	if _node_type == "elite":
		Run.register_elite_victory()
	Run.fully_recover_party_after_battle()
	Run.advance()
	_log_text += "\n胜利！击破强度 %d 的梦魇，获得 %d 金币。" % [
		defeated_tier, gold_gain]
	_log_text += "\n" + xp_result["text"]
	_log_text += "\n额外获得 %d 张节点卡：%s。" % [
		_victory_node_cards.size(), Run.node_card_list_text(_victory_node_cards)]
	_log_text += "\n节点卡已直接收入卡组；请再从金币、经验或装备道具中选择一份奖励。"
	_log_text += "\n战斗整备完成：全队生命、体力与魔力已回满，负面状态已清除。"
	if _node_type == "elite":
		_log_text += "\n梦境压力已提升：后续战斗与奖励更强。"
	_refresh()
	for reward in Run.roll_rewards(Run.battle_level):
		_add_button(_action_box, Run.reward_text(reward), _on_reward.bind(reward), 340)


func _on_reward(reward: Dictionary) -> void:
	Run.apply_reward(reward)
	var notice := "战斗奖励：%s\n额外节点卡：%s" % [
		Run.reward_text(reward), Run.node_card_list_text(_victory_node_cards)]
	if _node_type == "elite":
		notice += "\n精英已净化，梦境压力提升至 %d。" % Run.dream_pressure
	Run.set_notice(notice)
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _lose() -> void:
	_battle_over = true
	Run.run_started = false
	_log_text += "\n所有入梦师倒下了……"
	_refresh()
	_add_button(_action_box, "查看结算", _back_to_settle, 260)


func _back_to_settle() -> void:
	get_tree().change_scene_to_file("res://scenes/settle.tscn")
