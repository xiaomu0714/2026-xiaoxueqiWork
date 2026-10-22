extends Control
## 临时截图工具：按顺序渲染各主界面，输出到 _shot/*.png 供视觉检查。

const OUT := "res://_shot/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run_autoload_init()
	await _capture("res://scenes/main.tscn", "01_title")
	await _capture("res://scenes/select.tscn", "02_select")

	# 进入一局，便于渲染后续游玩界面
	Run.character_key = "warrior"
	Run.start_run()
	Run.choose_node_card(0)
	await _capture("res://scenes/planning.tscn", "03_planning")
	Run.choose_node_card(0)
	await _capture("res://scenes/map.tscn", "04_map")

	# 装备准备 + 战斗
	Run.choose_node_card(0)
	Run.enter_battle()
	await _capture("res://scenes/equipment.tscn", "05_equipment")
	await _capture("res://scenes/battle.tscn", "06_battle")

	# 事件
	Run.nodes[0] = "event"
	Run.node_levels[0] = 2
	Run.pick_event()
	await _capture("res://scenes/event.tscn", "07_event")

	# 奖励
	Run.nodes[0] = "reward"
	Run.node_levels[0] = 2
	await _capture("res://scenes/reward.tscn", "08_reward")

	# 招募
	Run.nodes[0] = "recruit"
	Run.node_levels[0] = 2
	await _capture("res://scenes/recruit.tscn", "09_recruit")

	# 商店
	Run.nodes[0] = "shop"
	Run.node_levels[0] = 2
	await _capture("res://scenes/shop.tscn", "10_shop")

	await _capture("res://scenes/settle.tscn", "11_settle")
	await _capture("res://scenes/codex.tscn", "12_codex")

	get_tree().quit()


func _run_autoload_init() -> void:
	# 确保 autoload 已就绪；直接启动时由各场景 fallback 兜底
	if Run == null or Run.player.is_empty():
		Run.start_run()


func _capture(path: String, name: String) -> void:
	var scene = load(path)
	if scene == null:
		return
	var instance = scene.instantiate()
	add_child(instance)
	# 等几帧，等 _ready 与布局全部完成
	for i in 4:
		await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(OUT + name + ".png")
	instance.queue_free()
	await get_tree().process_frame
