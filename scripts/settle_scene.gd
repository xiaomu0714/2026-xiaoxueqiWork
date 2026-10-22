extends Control
## 结算界面（v6 UI 改造：0号框 + 1号对话框）

func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "title")
	var gained := 30 if Run.finished else 8
	Meta.add_shards(gained)

	var title := Label.new()
	title.text = "梦境已净化！" if Run.finished else "入梦中断"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override(
		"font_color",
		Color(0.98, 0.82, 0.40) if Run.finished else Color(0.92, 0.48, 0.58))
	title.position = Vector2(0, 220)
	title.size = Vector2(1280, 60)
	add_child(title)

	var unlocked_text := "、".join(PackedStringArray(Meta.unlocked))
	var info := Label.new()
	info.text = "本次获得 %d 枚回声碎片\n累计：%d 枚\n\n已解锁入梦师：%s" % [
		gained, Meta.shards, unlocked_text]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 22)
	info.position = Vector2(260, 300)
	info.size = Vector2(760, 200)
	info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	add_child(info)

	var button := Button.new()
	button.text = "返回标题"
	button.position = Vector2(560, 510)
	button.size = Vector2(160, 60)
	button.add_theme_font_size_override("font_size", 20)
	FontHelper.style_primary(button)
	button.pressed.connect(_on_back)
	add_child(button)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")