extends Control
## 战前装备准备：每名角色拥有 3 个通用装备位，装备按前台/后台/通用限制。

const BG := Color(0.03, 0.04, 0.075)
const PANEL := Color(0.075, 0.09, 0.14)
const GOLD := Color(0.95, 0.78, 0.36)

var _stats_label: Label
var _enemy_label: Label
var _member_box: HBoxContainer
var _slot_box: HBoxContainer
var _inventory_grid: GridContainer
var _notice_label: Label
var _selected_key := ""
var _selected_slot := -1


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "equipment")
	UITheme.add_top_right_status(self)
	if not Run.run_started or Run.player.is_empty():
		Run.start_run()
		Run.choose_node_card(0)
		Run.enter_battle()
	_selected_key = Run.character_key
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(BG, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := ColorRect.new()
	header.color = Color(PANEL, 0.90)
	header.position = Vector2(24, 18)
	header.size = Vector2(1232, 96)
	add_child(header)

	var title := Label.new()
	title.text = "战前装备准备"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", GOLD)
	title.position = Vector2(48, 30)
	title.size = Vector2(480, 40)
	add_child(title)

	var help := Label.new()
	help.text = "选中角色后，先点击装备位，再点击背包装备；三件装备可以自由搭配给任意角色。"
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
	help.position = Vector2(48, 72)
	help.size = Vector2(560, 40)
	help.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(help)

	_enemy_label = Label.new()
	_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_label.add_theme_font_size_override("font_size", 15)
	_enemy_label.position = Vector2(640, 66)
	_enemy_label.size = Vector2(448, 46)
	_enemy_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_enemy_label)

	var enemy_detail := Button.new()
	enemy_detail.text = "查看敌方阵容"
	enemy_detail.position = Vector2(1098, 66)
	enemy_detail.size = Vector2(134, 40)
	enemy_detail.add_theme_font_size_override("font_size", 14)
	FontHelper.style_card(enemy_detail, Color(0.82, 0.38, 0.36))
	enemy_detail.pressed.connect(_show_enemy_roster)
	add_child(enemy_detail)

	var member_title := Label.new()
	member_title.text = "队伍成员"
	member_title.add_theme_font_size_override("font_size", 18)
	member_title.position = Vector2(36, 120)
	member_title.size = Vector2(150, 28)
	add_child(member_title)

	_member_box = HBoxContainer.new()
	_member_box.position = Vector2(180, 116)
	_member_box.size = Vector2(1036, 48)
	_member_box.add_theme_constant_override("separation", 10)
	add_child(_member_box)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.position = Vector2(36, 172)
	_stats_label.size = Vector2(1200, 40)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_stats_label)

	var slot_title := Label.new()
	slot_title.text = "三件装备"
	slot_title.add_theme_font_size_override("font_size", 20)
	slot_title.position = Vector2(36, 218)
	slot_title.size = Vector2(300, 30)
	add_child(slot_title)

	_slot_box = HBoxContainer.new()
	_slot_box.position = Vector2(36, 250)
	_slot_box.size = Vector2(1200, 148)
	_slot_box.add_theme_constant_override("separation", 18)
	add_child(_slot_box)

	var inventory_title := Label.new()
	inventory_title.text = "备用装备（点击放入选中的装备位）"
	inventory_title.add_theme_font_size_override("font_size", 20)
	inventory_title.position = Vector2(36, 408)
	inventory_title.size = Vector2(900, 30)
	add_child(inventory_title)

	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.position = Vector2(36, 442)
	inventory_scroll.size = Vector2(1200, 150)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(inventory_scroll)

	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 3
	_inventory_grid.custom_minimum_size = Vector2(1170, 0)
	_inventory_grid.add_theme_constant_override("h_separation", 12)
	_inventory_grid.add_theme_constant_override("v_separation", 10)
	inventory_scroll.add_child(_inventory_grid)

	_notice_label = Label.new()
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.add_theme_font_size_override("font_size", 16)
	_notice_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	_notice_label.position = Vector2(36, 604)
	_notice_label.size = Vector2(1200, 32)
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_notice_label)

	var confirm := Button.new()
	confirm.text = "确认装备，进入战斗"
	confirm.position = Vector2(490, 646)
	confirm.size = Vector2(300, 56)
	confirm.add_theme_font_size_override("font_size", 20)
	FontHelper.style_primary(confirm)
	confirm.pressed.connect(_enter_battle)
	add_child(confirm)


func _refresh() -> void:
	var actor: Dictionary = Run._actor_for_key(_selected_key)
	if actor.is_empty():
		_selected_key = Run.character_key
		actor = Run.player
	_refresh_member_buttons()
	var role_name := "前台" if actor.get("role", "front") == "front" else "后台"
	_stats_label.text = "%s　[%s]　生命 %d/%d　攻击 %d　体力 %d/%d　魔力 %d/%d　减伤 %d" % [
		actor["name"], role_name, actor["hp"], actor["max_hp"], actor["atk"],
		actor.get("stamina", 0), actor.get("max_stamina", 0),
		actor.get("mana", 0), actor.get("max_mana", 0),
		actor.get("damage_reduction", 0)]
	var synergy_names: Array = Run.active_synergy_names()
	if not synergy_names.is_empty():
		_stats_label.text += "\n当前联动：" + "、".join(synergy_names)

	var enemy_names := []
	for enemy in Run.battle_enemies:
		enemy_names.append("%s（HP%d/攻%d）" % [enemy["name"], enemy["max_hp"], enemy["atk"]])
	_enemy_label.text = "节点 Lv.%d｜压力 %d｜强度 %d｜探索 Lv.%d\n%s" % [
		maxi(1, Run.battle_level), Run.dream_pressure, Run.battle_effective_tier,
		Run.exploration_level,
		"、".join(enemy_names) if not enemy_names.is_empty() else "未知心魔"]

	_clear_container(_slot_box)
	for slot_index in 3:
		var item_key := Run.equipment_in_slot(slot_index, _selected_key)
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(300, 142)
		button.add_theme_font_size_override("font_size", 15)
		button.clip_contents = true
		var color := Color(0.32, 0.37, 0.55) if slot_index == _selected_slot else Color(0.22, 0.30, 0.44)
		FontHelper.style_card(button, color.lightened(0.22))
		if item_key == "":
			var empty_label := Label.new()
			empty_label.text = "装备位 %d\n空位\n点击选择此位置" % (slot_index + 1)
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			empty_label.add_theme_font_size_override("font_size", 14)
			empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			empty_label.offset_left = 8
			empty_label.offset_right = -8
			empty_label.offset_top = 4
			empty_label.offset_bottom = -4
			button.add_child(empty_label)
		else:
			var item: Dictionary = GameData.ITEMS[item_key]
			var portrait := ArtAssets.add_texture(
				button,
				ArtAssets.item(item_key),
				Rect2(Vector2(8, 12), Vector2(72, 72)))
			if portrait.texture == null:
				portrait.queue_free()
			var item_label := Label.new()
			item_label.text = "%s\n%s" % [item["name"], item["desc"]]
			item_label.position = Vector2(88, 8)
			item_label.size = Vector2(200, 108)
			item_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			item_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			item_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			item_label.add_theme_font_size_override("font_size", 11)
			item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(item_label)
			button.tooltip_text = "装备位 %d · %s\n点击卸下" % [
				slot_index + 1, item["name"]]
		button.pressed.connect(_select_or_unequip_slot.bind(slot_index, item_key))
		_slot_box.add_child(button)

	_clear_container(_inventory_grid)
	var counts := {}
	for item_key in Run.inventory:
		if GameData.ITEMS[item_key].get("kind", "consumable") == "equipment":
			counts[item_key] = int(counts.get(item_key, 0)) + 1
	var has_equipment := false
	for item_key in GameData.ACTIVE_ITEM_KEYS:
		var count: int = int(counts.get(item_key, 0))
		if count <= 0:
			continue
		has_equipment = true
		var item: Dictionary = GameData.ITEMS[item_key]
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(370, 88)
		button.clip_contents = true
		FontHelper.style_card(button, Color(0.38, 0.76, 0.68))
		var portrait := ArtAssets.add_texture(
			button,
			ArtAssets.item(item_key),
			Rect2(Vector2(8, 10), Vector2(64, 64)))
		if portrait.texture == null:
			portrait.queue_free()
		var item_label := Label.new()
		item_label.text = "%s ×%d\n%s" % [item["name"], count, item["desc"]]
		item_label.position = Vector2(84, 6)
		item_label.size = Vector2(278, 76)
		item_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		item_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		item_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		item_label.add_theme_font_size_override("font_size", 12)
		item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(item_label)
		button.pressed.connect(_equip.bind(item_key))
		_inventory_grid.add_child(button)
	if not has_equipment:
		var empty := Label.new()
		empty.text = "背包中暂时没有备用装备。战斗奖励和商店可以获得新装备。"
		empty.custom_minimum_size = Vector2(1120, 60)
		empty.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		empty.add_theme_font_size_override("font_size", 17)
		_inventory_grid.add_child(empty)


func _equip(item_key: String) -> void:
	var slot_index := _selected_slot
	if slot_index < 0:
		var equipment_list: Array = Run._equipment_list_for(_selected_key)
		slot_index = equipment_list.find("")
	if slot_index < 0:
		_notice_label.text = "三件装备已满，请先卸下一件"
		return
	if Run.equip_item(item_key, _selected_key, slot_index):
		_notice_label.text = "已为 %s 装备：%s" % [
			Run._actor_for_key(_selected_key)["name"], GameData.ITEMS[item_key]["name"]]
		_selected_slot = -1
		_refresh()


func _select_or_unequip_slot(slot_index: int, item_key: String) -> void:
	if item_key != "":
		if Run.unequip_slot(slot_index, _selected_key):
			_notice_label.text = "已卸下：%s；装备位 %d 已选中" % [
				GameData.ITEMS[item_key]["name"], slot_index + 1]
	else:
		_notice_label.text = "已选择装备位 %d" % (slot_index + 1)
	_selected_slot = slot_index
	_refresh()


func _refresh_member_buttons() -> void:
	if _member_box == null:
		return
	_clear_container(_member_box)
	for actor in Run.party:
		var key: String = actor.get("key", Run.character_key)
		var role_name := "前台" if actor.get("role", "front") == "front" else "后台"
		var button := Button.new()
		button.text = "%s [%s]　HP %d/%d" % [
			actor["name"], role_name,
			actor.get("hp", 0), actor.get("max_hp", 0)]
		button.custom_minimum_size = Vector2(286, 44)
		button.add_theme_font_size_override("font_size", 15)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		button.clip_text = true
		var ch_tex := ArtAssets.character(key)
		if ch_tex != null:
			button.icon = _scaled_icon(ch_tex, 32)
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = key == _selected_key
		button.pressed.connect(_select_member.bind(key))
		_member_box.add_child(button)


func _select_member(key: String) -> void:
	_selected_key = key
	_selected_slot = -1
	_notice_label.text = "正在调整：%s" % Run._actor_for_key(key).get("name", "角色")
	_refresh()


func _enter_battle() -> void:
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _show_enemy_roster() -> void:
	var lines := []
	if Run.battle_enemies.is_empty():
		lines.append("当前尚未进入战斗，敌方信息会在战斗前刷新。")
	else:
		lines.append("—— 敌方阵容（共 %d 个）——" % Run.battle_enemies.size())
		for enemy in Run.battle_enemies:
			lines.append("")
			lines.append("%s　【%s】　生命 %d/%d　攻击 %d" % [
				enemy.get("name", "未知心魔"),
				enemy.get("emotion", "未知情绪"),
				enemy.get("hp", 0), enemy.get("max_hp", 0),
				enemy.get("atk", 0)])
			lines.append("模式：%s" % _enemy_pattern_text(enemy))
		lines.append("")
		lines.append("提示：血量与攻击会随节点等级、梦境压力与队伍人数变化。")
	GlobalDetails.show_text_popup(self, "敌方阵容", "\n".join(lines))


func _enemy_pattern_text(enemy: Dictionary) -> String:
	match str(enemy.get("pattern", "attack")):
		"heavy_every_3":
			return "每 3 回合发动约 200% 攻击的蓄力重击"
		"bleed_every_2":
			return "每 2 回合攻击并施加 2 层流血"
		"stun_every_3":
			return "每 3 回合攻击并施加 1 回合晕眩"
		"shield_every_2":
			return "每 2 回合为自己获得 6 点护盾"
		"shield_ally_every_2":
			return "每 2 回合为生命比例最低的心魔提供 9 点护盾"
		"heal_every_3":
			return "每 3 回合为自己回复 6 点生命"
		"heal_ally_every_2":
			return "每 2 回合治疗生命比例最低的心魔 10 点"
	return "普通攻击：随机攻击一名存活角色"


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color.lightened(0.30)
	return style


func _scaled_icon(tex: Texture2D, wpx: int) -> ImageTexture:
	var img := tex.get_image()
	var sw := wpx
	var sh := maxi(1, int(round(img.get_height() * float(sw) / float(maxi(1, img.get_width())))))
	img.resize(sw, sh)
	return ImageTexture.create_from_image(img)
