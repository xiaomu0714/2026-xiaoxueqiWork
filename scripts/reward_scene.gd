extends Control
## 奖励节点（v6 UI 改造：0号框 + 1号对话框 + 淡化背景）

var _title: Label
var _status: Label
var _choice_box: HBoxContainer
var _rewards: Array = []
var _claimed := false
var _reward_event: Dictionary = {}


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "reward")

	var reward_event_count: int = mini(
		GameData.ACTIVE_REWARD_EVENT_COUNT, GameData.REWARD_EVENTS.size())
	_reward_event = GameData.REWARD_EVENTS[randi() % reward_event_count]

	_title = Label.new()
	var node_level: int = int(Run.node_levels[Run.node_pos]) if Run.node_pos < Run.node_levels.size() else 1
	var reward_tier: int = Run.effective_tier(node_level)
	_title.text = "%s · %s品质" % [
		_reward_event["title"], Run.reward_quality_name(reward_tier)]
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color(0.98, 0.72, 0.28))
	_title.position = Vector2(0, 70)
	_title.size = Vector2(1280, 54)
	add_child(_title)

	var help := Label.new()
	help.text = _reward_event["text"]
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 20)
	help.add_theme_color_override("font_color", Color(0.76, 0.80, 0.9))
	help.position = Vector2(64, 132)
	help.size = Vector2(1152, 54)
	help.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(help)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 17)
	_status.position = Vector2(48, 194)
	_status.size = Vector2(1184, 38)
	_status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(_status)

	_choice_box = HBoxContainer.new()
	_choice_box.position = Vector2(64, 250)
	_choice_box.size = Vector2(1152, 360)
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 18)
	add_child(_choice_box)

	var level: int = int(Run.node_levels[Run.node_pos]) if Run.node_pos < Run.node_levels.size() else 1
	_rewards = Run.roll_reward_node_rewards(level)
	_refresh()


func _refresh() -> void:
	_status.text = "Lv.%d　压力 %d　｜　HP %d/%d　金币 %d" % [
		Run.node_levels[Run.node_pos] if Run.node_pos < Run.node_levels.size() else 1,
		Run.dream_pressure,
		Run.player["hp"], Run.player["max_hp"],
		Run.gold]
	for child in _choice_box.get_children():
		child.queue_free()
	for reward in _rewards:
		var button := Button.new()
		button.text = "%s\n\n%s" % [
			_reward_event.get("choice_prefix", "选择"),
			Run.reward_text(reward)]
		button.custom_minimum_size = Vector2(352, 304)
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		# 道具/装备奖励给左侧配图（缩略图）
		if reward.get("type", "") == "item":
			var item_tex := ArtAssets.item(str(reward.get("item", "")))
			if item_tex != null:
				button.icon = _scaled_icon(item_tex, 64)
				button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_stylebox_override("normal", _style_for_reward(reward))
		button.add_theme_stylebox_override("hover", _style_for_reward(reward, true))
		button.add_theme_stylebox_override("pressed", _style_for_reward(reward, true))
		button.pressed.connect(_claim.bind(reward))
		_choice_box.add_child(button)


func _claim(reward: Dictionary) -> void:
	if _claimed:
		return
	_claimed = true
	Run.apply_reward(reward)
	var node_level: int = int(Run.node_levels[Run.node_pos]) if Run.node_pos < Run.node_levels.size() else 1
	var xp_gain := 10 + Run.effective_tier(node_level) * 5
	var xp_result: Dictionary = Run.gain_exploration_xp(xp_gain, "奖励节点")
	Run.set_notice("%s；%s" % [Run.reward_text(reward), xp_result["text"]])
	Run.advance()
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _style_for_reward(reward: Dictionary, hover := false) -> StyleBoxFlat:
	# 用深色半透明卡底 + 类型色描边/微光，替代原来高饱和实底，
	# 既保留「品质 / 类型」色彩编码，又不与全局暗色梦境风格割裂。
	var quality := Color(0.56, 0.68, 0.86)
	match reward.get("type", ""):
		"item": quality = Color(0.30, 0.72, 0.50)
		"node_card": quality = Color(0.42, 0.62, 0.94)
		"gold": quality = Color(0.94, 0.74, 0.32)
		"max_hp", "atk", "max_stamina", "max_mana": quality = Color(0.70, 0.42, 0.86)
	if hover: quality = quality.lightened(0.18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.065, 0.12, 0.92).lerp(quality.darkened(0.35), 0.16)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = quality.darkened(0.05)
	style.shadow_color = Color(quality, 0.30 if hover else 0.20)
	style.shadow_size = 14 if hover else 10
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _scaled_icon(tex: Texture2D, wpx: int) -> ImageTexture:
	var img := tex.get_image()
	var sw := wpx
	var sh := maxi(1, int(round(img.get_height() * float(sw) / float(maxi(1, img.get_width())))))
	img.resize(sw, sh)
	return ImageTexture.create_from_image(img)
