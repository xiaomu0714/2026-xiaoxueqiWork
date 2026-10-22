extends Control
## 角色选择界面（v6 UI 改造：0号框 + 1号对话框 + 两列可滚动）

var _title: Label


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "title")

	_title = Label.new()
	_title.text = "选择入梦师"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.35))
	_title.position = Vector2(0, 30)
	_title.size = Vector2(1280, 44)
	add_child(_title)

	var codex := Button.new()
	codex.text = "查看图鉴"
	codex.position = Vector2(1120, 32)
	codex.size = Vector2(140, 44)
	codex.add_theme_font_size_override("font_size", 16)
	FontHelper.style_card(codex, Color(0.36, 0.72, 0.86))
	codex.pressed.connect(_on_codex_pressed)
	add_child(codex)

	var shards := Label.new()
	shards.text = "回声碎片：%d　（通关 +30，失败 +8）" % Meta.shards
	shards.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shards.add_theme_font_size_override("font_size", 18)
	shards.add_theme_color_override("font_color", Color(0.95, 0.78, 0.36))
	shards.position = Vector2(48, 120)
	shards.size = Vector2(1184, 28)
	add_child(shards)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(48, 164)
	scroll.size = Vector2(1184, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var box := GridContainer.new()
	box.columns = 2
	box.custom_minimum_size = Vector2(1168, 0)
	box.add_theme_constant_override("h_separation", 16)
	box.add_theme_constant_override("v_separation", 16)
	scroll.add_child(box)

	for key in GameData.INITIAL_CHARACTERS:
		var ch: Dictionary = GameData.CHARACTERS[key]
		var skill: Dictionary = GameData.SKILLS[ch["skill"]]
		var passive: Dictionary = ch.get("starter_passive", {})
		var text := "%s　[%s]　HP %d　攻 %d　体 %d　魔 %d\n%s：%s\n被动：%s" % [
			ch["name"], "前台" if ch["role"] == "front" else "后台",
			ch["max_hp"], ch["atk"], ch["max_stamina"], ch["max_mana"],
			skill["name"], skill["desc"], passive.get("desc", "无")]
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(576, 220)
		button.clip_contents = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		var accent := Color(0.72, 0.33, 0.32) if ch["role"] == "front" else Color(0.28, 0.60, 0.78)
		FontHelper.style_card(button, accent)
		var portrait := ArtAssets.add_texture(
			button,
			ArtAssets.character(key),
			Rect2(Vector2(12, 14), Vector2(108, 196)))
		if portrait.texture == null:
			portrait.queue_free()
		var info := Label.new()
		info.text = text
		# 用锚点让文字区自适应卡片宽度：右侧留固定留白，超长自动换行收进卡内。
		info.anchor_left = 0.24
		info.anchor_right = 0.99
		info.anchor_top = 0.05
		info.anchor_bottom = 0.92
		info.offset_left = 0
		info.offset_top = 0
		info.offset_right = 0
		info.offset_bottom = 0
		info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_theme_font_size_override("font_size", 14)
		button.add_child(info)
		button.pressed.connect(_on_pick.bind(key))
		box.add_child(button)

	var help := Label.new()
	help.text = "4 名初始角色可选，其余 5 名在招募节点出现。\n队伍最多 6 人；只有初始角色拥有入梦被动。"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	help.position = Vector2(48, 710)
	help.size = Vector2(1184, 60)
	help.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(help)


func _on_pick(key: String) -> void:
	if key not in GameData.INITIAL_CHARACTERS:
		_title.text = "该角色只能在本局探索中招募"
		return
	Run.character_key = key
	Run.start_run()
	var error := get_tree().change_scene_to_file("res://scenes/planning.tscn")
	if error != OK:
		_title.text = "节点卡组界面加载失败（错误码 %d）" % error

func _on_codex_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/codex.tscn")
