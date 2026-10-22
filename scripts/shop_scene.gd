extends Control
## 商店节点界面（v6 UI 改造：0号框 + 1号对话框）

var _gold_label: Label
var _offers_box: VBoxContainer


func _ready() -> void:
	AudioMan.use_theme_music()
	FontHelper.apply_to(self)
	UITheme.add_asset_background(self, "shop")

	var title := Label.new()
	title.text = "神秘商店"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.36))
	title.position = Vector2(0, 40)
	title.size = Vector2(1280, 44)
	add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 24)
	_gold_label.position = Vector2(48, 100)
	_gold_label.size = Vector2(1184, 40)
	add_child(_gold_label)

	var offer_scroll := ScrollContainer.new()
	offer_scroll.position = Vector2(96, 160)
	offer_scroll.size = Vector2(1088, 448)
	offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(offer_scroll)

	_offers_box = VBoxContainer.new()
	_offers_box.custom_minimum_size = Vector2(1060, 0)
	_offers_box.add_theme_constant_override("separation", 14)
	offer_scroll.add_child(_offers_box)

	var leave := Button.new()
	leave.text = "离开商店"
	leave.position = Vector2(560, 620)
	leave.size = Vector2(160, 56)
	leave.add_theme_font_size_override("font_size", 20)
	FontHelper.style_primary(leave)
	leave.pressed.connect(_on_leave)
	add_child(leave)

	_refresh()


func _refresh() -> void:
	_gold_label.text = "金币 %d　｜　节点牌 %d" % [Run.gold, Run.available_cards.size()]
	for child in _offers_box.get_children():
		child.queue_free()
	var active_offers := []
	for offer in GameData.SHOP_OFFERS:
		if offer.has("item") and offer["item"] not in GameData.ACTIVE_ITEM_KEYS:
			continue
		active_offers.append(offer)
		if active_offers.size() >= GameData.ACTIVE_SHOP_OFFER_COUNT:
			break
	for offer in active_offers:
		var button := Button.new()
		var detail: String = str(offer["name"])
		if offer.has("item"):
			detail = Run.item_detail(offer["item"])
		elif offer.has("atk"):
			detail = "永久攻击 +%d" % offer["atk"]
		elif offer.has("exploration_xp"):
			detail = "探索经验 +%d" % offer["exploration_xp"]
		elif offer.has("node_card"):
			detail = "获得节点卡：%s" % Run.node_card_text(offer["node_card"])
		elif offer.has("breakthrough"):
			detail = "当前角色成长 1 次"
		button.text = "%s\n%d 金币" % [detail, offer["cost"]]
		button.custom_minimum_size = Vector2(0, 100)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		button.clip_text = true
		# 道具类给左侧配图（缩略图）
		if offer.has("item"):
			var item_tex := ArtAssets.item(offer["item"])
			if item_tex != null:
				button.icon = _scaled_icon(item_tex, 52)
				button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = (
			Run.gold < offer["cost"]
			or (offer.has("breakthrough")
				and int(Run.player.get("level", 1)) >= GameData.MAX_CHARACTER_LEVEL))
		var accent := Color(0.38, 0.76, 0.62) if offer.has("item") else Color(0.76, 0.58, 0.28)
		FontHelper.style_card(button, accent)
		button.pressed.connect(_on_buy.bind(offer))
		_offers_box.add_child(button)


func _on_buy(offer: Dictionary) -> void:
	if Run.shop_buy(offer):
		_refresh()


func _on_leave() -> void:
	Run.advance()
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _scaled_icon(tex: Texture2D, wpx: int) -> ImageTexture:
	var img := tex.get_image()
	var sw := wpx
	var sh := maxi(1, int(round(img.get_height() * float(sw) / float(maxi(1, img.get_width())))))
	img.resize(sw, sh)
	return ImageTexture.create_from_image(img)
