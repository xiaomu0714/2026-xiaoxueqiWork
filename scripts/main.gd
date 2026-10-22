extends Control
## 回声地牢 · 标题界面（v6 UI 改造）

func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "title")

	var sigil := Label.new()
	sigil.text = "◈"
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.add_theme_font_size_override("font_size", 48)
	sigil.add_theme_color_override("font_color", Color(0.42, 0.76, 0.92, 0.28))
	sigil.position = Vector2(0, 100)
	sigil.size = Vector2(1280, 52)
	add_child(sigil)

	var title := Label.new()
	title.text = "梦境回声"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.36))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0.18, 0.09, 0.20, 0.85))
	title.position = Vector2(0, 152)
	title.size = Vector2(1280, 80)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "入梦 · 构筑 · 净化心魔"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	subtitle.position = Vector2(0, 240)
	subtitle.size = Vector2(1280, 36)
	add_child(subtitle)

	var button := Button.new()
	button.text = "开始游戏"
	button.position = Vector2(535.0, 390.0)
	button.size = Vector2(210, 64)
	button.add_theme_font_size_override("font_size", 24)
	FontHelper.style_primary(button)
	button.pressed.connect(_on_start_pressed)
	add_child(button)

	var codex := Button.new()
	codex.text = "查看图鉴"
	codex.position = Vector2(535.0, 466.0)
	codex.size = Vector2(210, 48)
	codex.add_theme_font_size_override("font_size", 18)
	FontHelper.style_card(codex, Color(0.38, 0.72, 0.88))
	codex.pressed.connect(_on_codex_pressed)
	add_child(codex)

	var hint := Label.new()
	hint.text = "Enter 开始 · 鼠标操作"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	hint.position = Vector2(0, 540)
	hint.size = Vector2(1280, 28)
	add_child(hint)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/select.tscn")

func _on_codex_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/codex.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		_on_start_pressed()