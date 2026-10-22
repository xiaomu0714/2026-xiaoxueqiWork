extends SceneTree
## 开发自检脚本（仅供开发验证用，不影响游戏本体）
## 用法: godot --headless --path . --script res://scripts/dev_test.gd

var _failures := 0


func _initialize() -> void:
	_run_tests()


func _run_tests() -> void:
	print("=== 回声地牢 v1 自检开始 ===")

	# 确保 Run 单例存在（--script 模式下自动加载不一定生效）
	var run_autoload = root.get_node_or_null("Run")
	if run_autoload == null:
		run_autoload = load("res://scripts/run_state.gd").new()
		run_autoload.name = "Run"
		root.add_child(run_autoload)

	# --- 边走边构筑 + 节点卡组三合一 ---
	var run = load("res://scripts/run_state.gd").new()
	run.start_run()
	_expect(run.nodes.size() == 13, "单层路线骨架固定为 13 格")
	_expect(run.nodes[3] == "elite" and run.nodes[7] == "elite", "第 4、8 格固定为精英")
	_expect(run.nodes[12] == "boss", "第 13 格固定为首领")
	_expect(run.nodes[0] == "" and run.planning, "开局第 1 格等待玩家选择节点")
	_expect(run.available_cards.size() == GameData.STARTER_NODE_CARD_COUNT, "随机初始节点卡组已发放")
	_expect(GameData.STARTER_NODE_CARD_COUNT == 6, "开局节点卡数量限制为 6 张")
	_expect(
		GameData.STARTER_NODE_WEIGHTS == {
			"battle": 30, "event": 30, "reward": 20, "recruit": 20},
		"开局节点权重为镇守/奇遇 30%、奖励/招募 20%")
	var deck_signatures := {}
	var starter_totals := {
		"battle": 0, "event": 0, "reward": 0, "recruit": 0,
	}
	var starter_types_valid := true
	for sample_index in 400:
		var sample_deck: Array = run.generate_starter_node_deck()
		var signature := sample_deck.duplicate()
		signature.sort()
		deck_signatures["|".join(signature)] = true
		for type_name in sample_deck:
			if starter_totals.has(type_name):
				starter_totals[type_name] += 1
			else:
				starter_types_valid = false
	_expect(deck_signatures.size() > 1, "连续开局会生成不同的节点卡组")
	_expect(starter_types_valid, "开局只会抽到镇守、奇遇、奖励和招募")
	var starter_draw_total := 400.0 * GameData.STARTER_NODE_CARD_COUNT
	var weight_distribution_valid := true
	for type_name in GameData.STARTER_NODE_WEIGHTS:
		var actual_ratio: float = starter_totals[type_name] / starter_draw_total
		var expected_ratio: float = GameData.STARTER_NODE_WEIGHTS[type_name] / 100.0
		if absf(actual_ratio - expected_ratio) > 0.05:
			weight_distribution_valid = false
	_expect(weight_distribution_valid, "多轮抽取结果符合 30/30/20/20 权重")
	_expect(run.exploration_level == 1
		and run.exploration_xp == 0
		and run.exploration_regen()["stamina"] == 1,
		"开局探索等级为 1，每回合恢复 1 点资源")
	var exploration_probe: Dictionary = run.gain_exploration_xp(30, "测试")
	_expect(exploration_probe["levels_gained"] == 1
		and run.exploration_level == 2
		and run.exploration_regen()["stamina"] == 2,
		"探索经验达到阈值后升级并提高每回合恢复量")
	run.node_pos = 11
	run.available_cards = []
	run._sync_available_nodes()
	for i in 3:
		run.add_node_card("battle", 1)
	var deck_size_before: int = run.available_cards.size()
	_expect(run.can_merge_node_cards("battle", 1), "三张同类型同等级节点可合成")
	_expect(run.merge_node_cards("battle", 1), "执行镇守 Lv.1 三合一成功")
	_expect(run.available_cards.size() == deck_size_before - 2, "三合一后卡组净减少 2 张")
	var level_two_battles := 0
	for card in run.available_cards:
		if card["type"] == "battle" and card.get("level", 1) == 2:
			level_two_battles += 1
	_expect(level_two_battles == 1, "合成产出 1 张同类型 Lv.2 节点")
	var level_one_party: Array = run._build_enemy_party("slime", 1, "battle")
	var level_two_party: Array = run._build_enemy_party("slime", 2, "battle")
	_expect(level_two_party[0]["max_hp"] >= int(level_one_party[0]["max_hp"] * 1.35)
		and level_two_party[0]["atk"] > level_one_party[0]["atk"],
		"节点 Lv.2 对敌人生命与攻击的提升足够明显")
	var level_one_reward_pool: Array = run.build_reward_pool(1)
	var level_two_reward_pool: Array = run.build_reward_pool(2)
	var level_one_gold := 0
	var level_two_gold := 0
	for reward in level_one_reward_pool:
		if reward["type"] == "gold":
			level_one_gold = reward["amount"]
	for reward in level_two_reward_pool:
		if reward["type"] == "gold":
			level_two_gold = reward["amount"]
	_expect(level_two_gold >= level_one_gold + 15,
		"节点 Lv.2 对奖励数值的提升足够明显")
	var elite_level_before: int = run.node_levels[3]
	run.register_elite_victory()
	_expect(run.node_levels[3] == elite_level_before
		and run.dream_pressure == 1 and run.effective_tier(1) == 2,
		"击败精英不改变节点等级，但提升全局梦境压力")
	var pressure_party: Array = run._build_enemy_party("slime", 1, "battle")
	_expect(pressure_party[0]["max_hp"] > level_one_party[0]["max_hp"],
		"梦境压力会强化后续同等级战斗")
	var pressure_reward_pool: Array = run.build_reward_pool(1)
	var pressure_gold := 0
	for reward in pressure_reward_pool:
		if reward["type"] == "gold":
			pressure_gold = reward["amount"]
	_expect(pressure_gold > level_one_gold, "梦境压力会强化后续同等级奖励")
	_expect(GameData.REWARD_EVENTS.size() >= 3 and GameData.RECRUIT_EVENTS.size() >= 3,
		"奖励节点与招募节点均拥有多套梦境事件模板")

	# --- 模拟逐格选牌并走完整层 ---
	run = load("res://scripts/run_state.gd").new()
	run.start_run()
	var steps := 0
	var last_type := ""
	while not run.at_layer_end() and steps < 100:
		if run.planning:
			_expect(run.choose_node_card(0), "为第 %d 格选择节点卡" % (run.node_pos + 1))
		last_type = run.current_node()
		if last_type in ["battle", "elite", "boss"]:
			var route_level: int = int(run.node_levels[run.node_pos])
			run.grant_battle_node_cards(
				route_level, last_type, run.effective_tier(route_level))
			if last_type == "elite":
				run.register_elite_victory()
		run.advance()
		steps += 1
	_expect(run.at_layer_end(), "模拟推进能走完整层")
	_expect(last_type == "boss", "末尾节点为首领")
	_expect(run.nodes.count("") == 0, "走完整层后所有普通位置都已放置")
	_expect(run.nodes[3] == "elite" and run.nodes[7] == "elite", "推进时精英节点无需选牌")

	# --- 节点卡组与地图界面能正常构建 ---
	run_autoload.character_key = "warrior"
	run_autoload.start_run()
	var planning_scene = load("res://scenes/planning.tscn").instantiate()
	root.add_child(planning_scene)
	await self.process_frame
	_expect(planning_scene._card_grid.get_child_count() > 0, "节点卡组界面显示可选卡组")
	_expect(planning_scene._merge_box.get_child_count() > 0, "节点卡组界面显示三合一选项")
	planning_scene.queue_free()
	_expect(run_autoload.choose_node_card(0), "地图测试前放置当前节点")
	var map_scene = load("res://scenes/map.tscn").instantiate()
	root.add_child(map_scene)
	await self.process_frame
	_expect(map_scene._layer_label.text.contains("梦境航线"), "地图界面标题正确显示")
	_expect(map_scene._node_box.get_child_count() == 13, "地图界面渲染完整 13 格路线")
	map_scene.queue_free()

	# --- 战斗逻辑与数据完整性 ---
	var data_ok := GameData.ACTIVE_CHARACTER_KEYS.size() == 9
	for key in GameData.ACTIVE_CHARACTER_KEYS:
		if not GameData.SKILLS.has(GameData.CHARACTERS[key]["skill"]):
			data_ok = false
		for extra_skill in GameData.CHARACTER_EXTRA_SKILLS.get(key, []):
			if not GameData.SKILLS.has(extra_skill):
				data_ok = false
	_expect(data_ok, "正式角色池为 9 人且技能引用完整")
	_expect(GameData.INITIAL_CHARACTERS.size() == 4
		and GameData.INITIAL_CHARACTERS.count("warrior") == 1
		and GameData.INITIAL_CHARACTERS.count("ranger") == 1
		and GameData.INITIAL_CHARACTERS.count("cleric") == 1
		and GameData.INITIAL_CHARACTERS.count("channeler") == 1,
		"初始角色固定为 2 名前台与 2 名后台")
	var initial_front_count := 0
	var initial_back_count := 0
	for initial_key in GameData.INITIAL_CHARACTERS:
		if GameData.CHARACTERS[initial_key]["role"] == "front":
			initial_front_count += 1
		else:
			initial_back_count += 1
	_expect(initial_front_count == 2 and initial_back_count == 2,
		"四名初始角色的前后台数量为 2:2")
	_expect(GameData.MAX_CHARACTER_LEVEL == 4
		and run_autoload.MAX_PARTY_SIZE == 6
		and run_autoload.MAX_ROLE_SIZE == 3,
		"角色可突破至 MAX，队伍支持前台3人+后台3人")
	_expect(GameData.CHARACTERS["guardian"]["start_shield"] == 8
		and GameData.CHARACTERS["assassin"]["bleed_bonus"] == 1
		and GameData.CHARACTERS["channeler"]["starter_passive"]["type"] == "team_regen_bonus"
		and GameData.CHARACTERS["alchemist"]["item_power"] == 4,
		"四名新角色拥有独立战斗定位")

	var actor := {"name": "镇魇武者", "max_hp": 30, "atk": 8, "hp": 30, "stamina": 3, "mana": 0}
	var target := {"name": "暴怒", "max_hp": 15, "atk": 5, "hp": 15}
	Battle.resolve_turn(actor, {"effect": "attack", "multiplier": 1.6}, target)
	_expect(target["hp"] < 15, "攻击结算正确（剩余 %d）" % target["hp"])
	# 逐影猎手专项：锁定单段、多段、固定追加和全体技能的真实倍率。
	var ranger_probe := {
		"name": "逐影猎手测试", "max_hp": 30, "hp": 30, "atk": 10,
		"stamina": 99, "max_stamina": 99, "mana": 2, "max_mana": 2,
	}
	var ranger_normal_target := {"name": "普通靶", "max_hp": 200, "hp": 200, "atk": 1}
	var ranger_double_target := {"name": "连射靶", "max_hp": 200, "hp": 200, "atk": 1}
	var ranger_pierce_target := {"name": "穿心靶", "max_hp": 200, "hp": 200, "atk": 1}
	var ranger_snare_target := {"name": "缚影靶", "max_hp": 200, "hp": 200, "atk": 1}
	var ranger_perfect_target := {"name": "必中靶", "max_hp": 200, "hp": 200, "atk": 1}
	var ranger_normal_log: Array = Battle.resolve_turn(
		ranger_probe.duplicate(true),
		{"effect": "attack", "multiplier": 1.0},
		ranger_normal_target)
	var ranger_double_log: Array = Battle.resolve_turn(
		ranger_probe.duplicate(true), GameData.SKILLS["double_shot"], ranger_double_target)
	var ranger_pierce_log: Array = Battle.resolve_turn(
		ranger_probe.duplicate(true), GameData.SKILLS["piercing_arrow"], ranger_pierce_target)
	var ranger_snare_log: Array = Battle.resolve_turn(
		ranger_probe.duplicate(true), GameData.SKILLS["snare_shot"], ranger_snare_target)
	var ranger_perfect_action: Dictionary = GameData.SKILLS["perfect_shot"].duplicate(true)
	ranger_perfect_action["cost"] = 0
	var ranger_perfect_log: Array = Battle.resolve_turn(
		ranger_probe.duplicate(true), ranger_perfect_action, ranger_perfect_target)
	_expect(200 - ranger_normal_target["hp"] == 10
		and ranger_normal_log.size() == 1,
		"逐影猎手普通攻击按 100% 攻击结算")
	_expect(200 - ranger_double_target["hp"] == 14
		and ranger_double_log.size() == 2,
		"逐影连射按 70% ×2 结算，而不是 100%")
	_expect(200 - ranger_pierce_target["hp"] == 16
		and ranger_pierce_log.size() == 1,
		"穿心箭按 130% +3 结算")
	_expect(200 - ranger_snare_target["hp"] == 8
		and ranger_snare_target.get("stunned", 0) == 1,
		"缚影箭按 80% 并附加晕眩结算")
	_expect(200 - ranger_perfect_target["hp"] == 33
		and ranger_perfect_log.size() == 1,
		"无声必中按 250% +8 结算")
	var ranger_initial_normal_target := {
		"name": "减伤普通靶", "max_hp": 100, "hp": 100, "atk": 1,
		"damage_reduction": 1,
	}
	var ranger_initial_double_target := {
		"name": "减伤连射靶", "max_hp": 100, "hp": 100, "atk": 1,
		"damage_reduction": 1,
	}
	var ranger_initial_actor := {
		"name": "初始逐影猎手", "max_hp": 28, "hp": 28, "atk": 8,
		"stamina": 8, "max_stamina": 8, "mana": 2, "max_mana": 2,
	}
	Battle.resolve_turn(
		ranger_initial_actor.duplicate(true),
		{"effect": "attack", "multiplier": 1.0},
		ranger_initial_normal_target)
	Battle.resolve_turn(
		ranger_initial_actor.duplicate(true),
		GameData.SKILLS["double_shot"],
		ranger_initial_double_target)
	_expect(100 - ranger_initial_normal_target["hp"] == 7
		and 100 - ranger_initial_double_target["hp"] == 10,
		"初始逐影连射面对减伤敌人仍明显高于普通攻击（10 > 7）")
	_expect(Battle.turn_order([target, actor])[0]["name"] == "暴怒", "回合顺序由阶段控制，不依赖速度")
	var shield_target := {"name": "护盾测试", "max_hp": 20, "hp": 20, "shield": 6, "damage_reduction": 1}
	Battle.resolve_turn(actor, {"effect": "attack", "multiplier": 1.0}, shield_target)
	_expect(shield_target["shield"] == 0 and shield_target["hp"] == 19,
		"护盾优先吸收伤害，护甲减伤生效")
	var resource_actor := {"name": "资源测试", "max_hp": 20, "hp": 20, "atk": 1,
		"stamina": 0, "max_stamina": 6, "mana": 0, "max_mana": 4}
	Battle.resolve_turn(resource_actor, {"effect": "restore", "resource": "stamina", "amount": 3}, {})
	_expect(resource_actor["stamina"] == 3, "体力回复道具效果正确")
	resource_actor["bleed"] = 3
	resource_actor["stunned"] = 1
	Battle.resolve_turn(resource_actor, {"effect": "cleanse", "amount": 5}, {})
	_expect(resource_actor["bleed"] == 0 and resource_actor["stunned"] == 0,
		"净化道具可清除流血与晕眩")
	var ally_resource := {"name": "队友", "max_hp": 20, "hp": 10, "atk": 2,
		"stamina": 0, "max_stamina": 6, "mana": 0, "max_mana": 4}
	Battle.resolve_turn(
		resource_actor,
		{"effect": "restore", "target": "ally", "ally_target": ally_resource,
			"resource": "stamina", "amount": 4, "skip_start_status": true},
		{})
	_expect(ally_resource["stamina"] == 4, "资源辅助技能可以恢复队友体力")
	var bleed_target := {"name": "流血目标", "max_hp": 30, "hp": 30, "atk": 1}
	var bleed_actor := {"name": "刺客测试", "max_hp": 20, "hp": 20, "atk": 10,
		"stamina": 5, "mana": 0, "bleed_bonus": 1}
	Battle.resolve_turn(bleed_actor, GameData.SKILLS["blood_cut"], bleed_target)
	_expect(bleed_target["bleed"] == 4, "血梦刺客被动强化流血层数")
	var normal_damage_target := {"name": "普通目标", "max_hp": 100, "hp": 100, "atk": 1}
	var shield_damage_target := {"name": "带盾目标", "max_hp": 100, "hp": 100, "atk": 1}
	var normal_damage_actor := {"name": "普通攻击者", "max_hp": 20, "hp": 20, "atk": 10}
	var shield_damage_actor := {"name": "带盾攻击者", "max_hp": 20, "hp": 20, "atk": 10,
		"shield": 5, "shielded_damage_bonus": 0.5}
	Battle.resolve_turn(normal_damage_actor, {"effect": "attack", "multiplier": 1.0}, normal_damage_target)
	Battle.resolve_turn(shield_damage_actor, {"effect": "attack", "multiplier": 1.0}, shield_damage_target)
	_expect(shield_damage_target["hp"] < normal_damage_target["hp"],
		"带盾增伤被动会提高实际伤害")
	var healer_probe := {"name": "治疗者", "max_hp": 20, "hp": 20, "atk": 1, "overheal_shield": 1.0}
	var healed_probe := {"name": "受疗者", "max_hp": 20, "hp": 18, "atk": 1}
	Battle.resolve_turn(
		healer_probe,
		{"effect": "heal", "target": "ally", "ally_target": healed_probe, "amount": 8},
		{})
	_expect(healed_probe["hp"] == 20 and healed_probe["shield"] == 6,
		"过量治疗转护盾被动会结算剩余治疗量")

	# --- 模拟一场完整战斗（镇魇武者 vs 暴怒） ---
	run_autoload.character_key = "warrior"
	run_autoload.start_run()
	_expect(run_autoload.player.get("starter_passive_active", false)
		and run_autoload.player.get("first_action_discount", 0) == 1,
		"初始出战角色携带入梦被动")
	var foe: Dictionary = GameData.ENEMIES["slime"].duplicate()
	foe["hp"] = foe["max_hp"]
	var round_count := 0
	while foe["hp"] > 0 and run_autoload.player["hp"] > 0 and round_count < 50:
		Battle.resolve_turn(run_autoload.player, {"effect": "attack", "multiplier": 1.0}, foe)
		if foe["hp"] > 0:
			Battle.resolve_turn(foe, Battle.enemy_intent(foe, round_count + 1), run_autoload.player)
		round_count += 1
	_expect(foe["hp"] <= 0 and run_autoload.player["hp"] > 0,
		"镇魇武者能单挑击败暴怒（%d 回合）" % round_count)

	# --- 战斗场景能正常构建 + 药品机制 ---
	run_autoload.character_key = "warrior"
	run_autoload.start_run()
	run_autoload.player["stamina"] = 0
	run_autoload.player["mana"] = 0
	run_autoload.enter_battle()
	_expect(run_autoload.player["stamina"] == run_autoload.player["max_stamina"]
		and run_autoload.player["mana"] == run_autoload.player["max_mana"],
		"进入新战斗时体力与魔力自动回满")
	_expect(run_autoload.battle_enemies.size() >= 1, "镇守战生成敌方编队")
	run_autoload.battle_enemy_key = "slime"
	var battle_scene = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle_scene)
	await self.process_frame
	_expect(battle_scene._enemy_label.text.contains("暴怒"), "战斗界面显示敌人信息")
	_expect(battle_scene._player_label.text.contains("镇魇武者"), "战斗界面显示玩家信息")
	_expect(battle_scene._enemy_card.position.y < battle_scene._party_box.position.y,
		"战斗界面采用敌方在上、我方在下的布局")
	_expect(battle_scene._front_party_box.get_child_count()
		+ battle_scene._back_party_box.get_child_count() == run_autoload.party.size(),
		"战斗界面将前台与后台角色分区显示")
	_expect(battle_scene._enemy_box.get_child_count() == run_autoload.battle_enemies.size(),
		"战斗界面显示敌方全部单位并支持选中目标")
	battle_scene._toggle_inspect()
	await self.process_frame
	_expect(battle_scene._inspect_overlay != null
		and battle_scene._inspect_tabs.get_tab_count() == 3,
		"战斗中可打开道具、我方角色、敌方详情")
	battle_scene._toggle_inspect()
	await self.process_frame
	_expect(battle_scene._inspect_overlay == null, "战斗详情弹窗可关闭")
	run_autoload.player["hp"] = 5
	battle_scene._on_potion()
	_expect(run_autoload.player["hp"] > 0, "用药品后玩家存活（HP=%d）" % run_autoload.player["hp"])
	_expect(battle_scene._potion_used, "药品每场只能用一次")
	_expect(battle_scene._action_box.get_child(0).disabled,
		"角色每回合行动一次后正确锁定")
	run_autoload.player["stamina"] = 0
	run_autoload.player["mana"] = 0
	battle_scene._enemy_turn()
	var expected_regen: Dictionary = run_autoload.exploration_regen()
	_expect(run_autoload.player["stamina"] == expected_regen["stamina"]
		and run_autoload.player["mana"] == expected_regen["mana"],
		"新回合按探索等级恢复体力与魔力")
	# 药品回复量直接验证（不经过敌人回合，避免数值耦合）
	var probe := {"name": "测试", "max_hp": 100, "hp": 5}
	Battle.resolve_turn(probe, {"effect": "heal", "amount": 5}, {})
	_expect(probe["hp"] == 10, "药品回复 5 点生命")
	battle_scene.queue_free()

	run_autoload.start_run()
	run_autoload.recruit_character("cleric")
	run_autoload.prepare_battle_for_key("slime", 1, "battle")
	var target_scene = load("res://scenes/battle.tscn").instantiate()
	root.add_child(target_scene)
	await self.process_frame
	target_scene._last_enemy_target_index = 0
	var switched_target: int = target_scene._random_alive_ally_index([])
	target_scene._last_enemy_target_index = switched_target
	var switched_back: int = target_scene._random_alive_ally_index([])
	_expect(switched_target == 1 and switched_back == 0,
		"敌方会在所有存活角色中随机选择，并避免连续攻击同一人")
	target_scene.queue_free()

	# --- v3：奖励与道具 ---
	run_autoload.character_key = "warrior"
	run_autoload.start_run()
	var rewards: Array = run_autoload.roll_rewards()
	_expect(rewards.size() == 3, "奖励三选一（%d 项）" % rewards.size())
	var reward_pool_with_xp: Array = run_autoload.build_reward_pool(1)
	var has_exploration_reward := false
	var has_invalid_recovery_reward := false
	for reward in reward_pool_with_xp:
		if reward["type"] == "exploration_xp":
			has_exploration_reward = true
		if reward["type"] in ["heal", "full_restore"]:
			has_invalid_recovery_reward = true
		if reward["type"] in ["atk", "max_hp", "max_stamina", "max_mana"]:
			has_invalid_recovery_reward = true
	_expect(has_exploration_reward, "奖励池包含探索经验奖励")
	_expect(not has_invalid_recovery_reward,
		"奖励池不再包含即时恢复或归属模糊的个人属性奖励")
	var reward_types := {}
	var allowed_reward_types := ["gold", "exploration_xp", "item"]
	var only_core_resources := true
	for i in 30:
		for reward in run_autoload.roll_rewards():
			reward_types[reward["type"]] = true
			if reward["type"] not in allowed_reward_types:
				only_core_resources = false
	_expect(reward_types.size() == 3, "战斗三选一包含金币、经验与装备/道具（%d 类）" % reward_types.size())
	_expect(only_core_resources, "节点卡不再占用战斗胜利三选一位置")
	var battle_card_deck_before: int = run_autoload.available_cards.size()
	var normal_battle_cards: Array = run_autoload.grant_battle_node_cards(1, "battle", 1)
	_expect(normal_battle_cards.size() == 2
		and run_autoload.available_cards.size() == battle_card_deck_before + 2,
		"普通低强度战斗胜利独立获得 2 张节点卡")
	battle_card_deck_before = run_autoload.available_cards.size()
	var difficult_battle_cards: Array = run_autoload.grant_battle_node_cards(2, "elite", 3)
	_expect(difficult_battle_cards.size() == 3
		and run_autoload.available_cards.size() == battle_card_deck_before + 3,
		"高等级或精英战斗胜利独立获得 3 张节点卡")
	var high_tier_rewards: Array = run_autoload.roll_rewards(2)
	var high_tier_equipment_count := 0
	for reward in high_tier_rewards:
		if reward["type"] == "item" and GameData.ITEMS[reward["item"]].get("kind", "") == "equipment":
			high_tier_equipment_count += 1
	_expect(high_tier_equipment_count >= 2, "高强度战斗奖励至少提供两件装备供比较")
	var reward_node_rewards: Array = run_autoload.roll_reward_node_rewards(3)
	var beneficial_reward_card_found := false
	for reward in reward_node_rewards:
		if reward["type"] == "node_card":
			var card_type: String = reward["card"]["type"]
			beneficial_reward_card_found = card_type in ["reward", "recruit", "shop", "rest"]
	_expect(beneficial_reward_card_found,
		"奖励节点三选一包含偏良性的节点卡")
	var old_max: int = run_autoload.player["max_hp"]
	run_autoload.apply_reward({"type": "max_hp", "amount": 5})
	_expect(run_autoload.player["max_hp"] == old_max + 5, "生命上限奖励生效")
	var old_gold: int = run_autoload.gold
	run_autoload.apply_reward({"type": "gold", "amount": 20})
	_expect(run_autoload.gold == old_gold + 20, "金币奖励生效")
	var old_stamina_cap: int = run_autoload.player["max_stamina"]
	run_autoload.apply_reward({"type": "max_stamina", "amount": 1})
	_expect(run_autoload.player["max_stamina"] == old_stamina_cap + 1, "体力上限奖励生效")
	run_autoload.apply_reward({"type": "item", "item": "scroll"})
	_expect(run_autoload.inventory.has("scroll"), "道具奖励进入背包")
	_expect(GameData.ACTIVE_ITEM_KEYS.size() == 24, "正式道具装备池精简为 24 种")
	var base_atk: int = run_autoload.player["atk"]
	run_autoload.apply_reward({"type": "item", "item": "rage_blade"})
	_expect(run_autoload.equipment_in_slot(0) == ""
		and run_autoload.inventory.has("rage_blade")
		and run_autoload.player["atk"] == base_atk,
		"装备奖励进入背包，不再默认分配给某个角色")
	_expect(run_autoload.equip_item("rage_blade", "", 0)
		and run_autoload.equipment_in_slot(0) == "rage_blade"
		and run_autoload.player["atk"] == base_atk + 3
		and int(run_autoload.player["on_kill_restore_stamina"]) >= 1,
		"战前自由分配装备后被动生效")
	run_autoload.apply_reward({"type": "item", "item": "guardian_badge"})
	run_autoload.apply_reward({"type": "item", "item": "traveler_boots"})
	_expect(run_autoload.equip_item("guardian_badge", "", 1)
		and run_autoload.equip_item("traveler_boots", "", 2),
		"玩家可以将背包装备分配到指定装备位")
	_expect(run_autoload.equipment.size() == 3
		and run_autoload.equipment_in_slot(1) == "guardian_badge"
		and run_autoload.equipment_in_slot(2) == "traveler_boots",
		"每名角色可自由搭配三件通用装备")
	run_autoload.inventory.append("moon_staff")
	_expect(run_autoload.can_equip_item("moon_staff", "warrior"),
		"所有装备都可以给前台或后台角色穿戴")
	_expect(run_autoload.recruit_character("cleric"), "可自主招募指定角色")
	_expect(not run_autoload.party[1].get("starter_passive_active", false)
		and run_autoload.party[1].get("first_support_shield", 0) == 0,
		"后续招募角色不会继承入梦被动")
	_expect(run_autoload.can_equip_item("moon_staff", "cleric")
		and run_autoload.equip_item("moon_staff", "cleric", 0)
		and run_autoload.equipment_in_slot(0, "cleric") == "moon_staff",
		"后台角色可以独立穿戴后台装备")
	var high_recruit_run = load("res://scripts/run_state.gd").new()
	high_recruit_run.character_key = "warrior"
	high_recruit_run.start_run()
	var high_recruit_result: Dictionary = high_recruit_run.recruit_character_at_level(
		"assassin", 3)
	var high_recruit_actor: Dictionary = high_recruit_result.get("actor", {})
	_expect(not high_recruit_result.is_empty()
		and high_recruit_actor.get("level", 0) == 3
		and high_recruit_actor.get("skills", []).size() == 2
		and high_recruit_actor.get("growth_passives", []).size() == 2,
		"Lv.3 招募节点可让新角色高等级入队并解锁技能与被动")
	var max_recruit_run = load("res://scripts/run_state.gd").new()
	max_recruit_run.character_key = "warrior"
	max_recruit_run.start_run()
	var max_recruit_result: Dictionary = max_recruit_run.recruit_character_at_level(
		"blade_dancer", GameData.MAX_CHARACTER_LEVEL)
	var max_recruit_actor: Dictionary = max_recruit_result.get("actor", {})
	_expect(max_recruit_actor.get("level", 0) == GameData.MAX_CHARACTER_LEVEL
		and max_recruit_actor.get("skills", []).size() == 2
		and max_recruit_actor.get("growth_passives", []).size() == 2,
		"角色可培养至 Lv.4（MAX）")
	var synergy_run = load("res://scripts/run_state.gd").new()
	synergy_run.character_key = "warrior"
	synergy_run.start_run()
	synergy_run.inventory.append("rage_blade")
	_expect(synergy_run.equip_item("rage_blade", "warrior", 0)
		and synergy_run.active_synergy_names().has("战痕共振"),
		"角色与装备联动会在战斗前激活")
	synergy_run.prepare_battle_for_key("slime", 1, "battle")
	_expect(synergy_run.active_synergy_names().has("战痕共振"),
		"装备联动进入战斗后保持生效")
	var capped_party_run = load("res://scripts/run_state.gd").new()
	capped_party_run.character_key = "warrior"
	capped_party_run.start_run()
	_expect(capped_party_run.recruit_character("guardian")
		and capped_party_run.recruit_character("mage")
		and not capped_party_run.recruit_character("blade_dancer")
		and capped_party_run.recruit_character("cleric")
		and capped_party_run.recruit_character("alchemist")
		and capped_party_run.recruit_character("channeler")
		and not capped_party_run.recruit_character("alchemist"),
		"前台与后台各自最多容纳 3 名角色")
	var recruit_candidates: Array = run_autoload.roll_recruit_candidates(4)
	_expect(recruit_candidates.size() == 4
		and not recruit_candidates.has("warrior")
		and not recruit_candidates.has("cleric"),
		"招募节点从未入队角色中随机抽取 4 名候选")
	var first_recruit_batch: Array = run_autoload.begin_recruit_visit(4)
	var second_recruit_batch: Array = run_autoload.begin_recruit_visit(4)
	var first_signature := first_recruit_batch.duplicate()
	var second_signature := second_recruit_batch.duplicate()
	first_signature.sort()
	second_signature.sort()
	_expect(run_autoload.recruit_visit_index == 2
		and first_signature != second_signature,
		"每次进入招募节点都会生成新的四人候选批次")
	var item_detail_text: String = run_autoload.item_detail("rage_blade")
	_expect(item_detail_text.contains("自由分配")
		and item_detail_text.contains("击败敌人回复 1 体力"),
		"装备奖励详情包含适配定位与完整被动效果")
	var skill_detail_text: String = run_autoload.skill_detail("piercing_arrow")
	_expect(skill_detail_text.contains("消耗 2 体力")
		and skill_detail_text.contains("130%"),
		"培养技能详情包含资源消耗与具体效果")
	var node_deck_before: int = run_autoload.available_cards.size()
	run_autoload.apply_reward({"type": "node_card", "card": {"type": "event", "level": 1}})
	_expect(run_autoload.available_cards.size() == node_deck_before + 1,
		"奖励效果可获得节点卡")
	# 道具在战斗中生效（火球卷轴 20 点固定伤害）
	run_autoload.battle_enemy_key = "slime"
	var battle_scene2 = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle_scene2)
	await self.process_frame
	var target_enemy: Dictionary = battle_scene2._enemy
	var slime_hp: int = target_enemy["hp"]
	battle_scene2._on_item("scroll")
	_expect(target_enemy["hp"] == maxi(0, slime_hp - 20),
		"火球卷轴对选中敌人造成 20 点伤害（%d -> %d）" % [slime_hp, target_enemy["hp"]])
	battle_scene2.queue_free()
	run_autoload.add_node_card("reward", 1)
	var reward_card_index := -1
	for i in run_autoload.available_cards.size():
		if run_autoload.available_cards[i]["type"] == "reward":
			reward_card_index = i
			break
	_expect(reward_card_index >= 0 and run_autoload.choose_node_card(reward_card_index),
		"奖励节点可从卡组放置")
	var reward_scene = load("res://scenes/reward.tscn").instantiate()
	root.add_child(reward_scene)
	await self.process_frame
	_expect(reward_scene._choice_box.get_child_count() == 3, "奖励节点显示三项可选奖励")
	var reward_scene_has_beneficial_card := false
	for reward in reward_scene._rewards:
		if reward["type"] == "node_card":
			reward_scene_has_beneficial_card = (
				reward["card"]["type"] in ["reward", "recruit", "shop", "rest"])
	_expect(reward_scene_has_beneficial_card,
		"奖励节点会展示偏良性的节点卡选项")
	reward_scene.queue_free()
	# 角色选择界面能构建
	var select_scene = load("res://scenes/select.tscn").instantiate()
	root.add_child(select_scene)
	await self.process_frame
	var select_buttons := 0
	for child in select_scene.get_children():
		if child is ScrollContainer:
			var select_box = child.get_child(0)
			select_buttons = select_box.get_child_count()
	_expect(select_buttons == 4, "角色选择界面只显示 4 名初始角色")
	select_scene.queue_free()
	var codex_scene = load("res://scenes/codex.tscn").instantiate()
	root.add_child(codex_scene)
	await self.process_frame
	_expect(codex_scene._tabs.get_tab_count() == 4, "图鉴已加载角色、道具、心魔与节点资料")
	codex_scene.queue_free()

	# --- v4：金币 / 商店 / 事件 ---
	run_autoload.gold = 0
	_expect(not run_autoload.shop_buy({"cost": 10, "item": "potion_big"}), "金币不足不能购买")
	run_autoload.gold = 50
	var bought: bool = run_autoload.shop_buy({"cost": 10, "item": "potion_big"})
	_expect(bought and run_autoload.gold == 40 and run_autoload.inventory.has("potion_big"),
		"商店购买成功并扣款")
	run_autoload.pick_event()
	_expect(run_autoload.current_event.size() > 0, "事件内容加载成功")
	var dream_orchard: Dictionary = GameData.EVENTS[2]
	var risky_choice: Dictionary = dream_orchard["choices"][1]
	_expect(risky_choice.has("outcomes") and risky_choice["text"] == "摘下一颗梦果品尝",
		"梦果园风险选项不提前暴露负面结果")
	var ranger_choice: Dictionary = dream_orchard["choices"][2]
	_expect(not run_autoload.event_condition_met(ranger_choice["condition"]),
		"缺少逐影猎手时条件洞察不可用")
	run_autoload.recruit_character("ranger")
	_expect(run_autoload.event_condition_met(ranger_choice["condition"]),
		"招募逐影猎手后可辨认梦果品质")
	var random_resolution: Dictionary = run_autoload.resolve_event_choice(risky_choice)
	_expect(random_resolution.get("valid", false)
		and random_resolution.has("text")
		and random_resolution.has("effect")
		and random_resolution.get("exploration_xp", 0) > 0,
		"未知尝试会在选择后按概率揭晓结果")
	run_autoload.apply_event({"memory": 2, "dream_corruption": 3, "set_flag": "heard_last_train"})
	_expect(run_autoload.memory_fragments == 2
		and run_autoload.dream_corruption == 3
		and run_autoload.event_condition_met({"type": "flag", "key": "heard_last_train"}),
		"奇遇可积累梦蚀、记忆残片与连续事件旗标")
	var last_train_event: Dictionary = {}
	for event in GameData.EVENTS:
		if event.get("id", "") == "last_train":
			last_train_event = event
			break
	_expect(not last_train_event.is_empty()
		and run_autoload.event_condition_met(last_train_event["requires"]),
		"前置旗标可以解锁连续奇遇")
	_expect(GameData.ACTIVE_EVENT_IDS.size() == 12, "正式奇遇池精简为 12 个")
	var hp_before: int = run_autoload.player["hp"]
	var atk_before: int = run_autoload.player["atk"]
	run_autoload.apply_event({"hp_cost": 5, "atk": 3})
	_expect(run_autoload.player["hp"] == maxi(0, hp_before - 5)
		and run_autoload.player["atk"] == atk_before + 3, "事件效果生效（扣血+加攻）")
	node_deck_before = run_autoload.available_cards.size()
	run_autoload.apply_event({"node_card": {"type": "rest", "level": 1}})
	_expect(run_autoload.available_cards.size() == node_deck_before + 1,
		"奇遇事件可获得节点卡")
	node_deck_before = run_autoload.available_cards.size()
	var high_level_event_result: Dictionary = run_autoload.apply_event(
		{"node_card": {"type": "recruit", "level": 3}})
	var gained_high_level_cards: Array = high_level_event_result.get("gained_cards", [])
	_expect(run_autoload.available_cards.size() == node_deck_before + 1
		and gained_high_level_cards.size() == 1
		and gained_high_level_cards[0]["type"] == "recruit"
		and gained_high_level_cards[0]["level"] == 3,
		"特殊奇遇可以直接获得 Lv.3 招募节点卡")
	run_autoload.gold = 50
	node_deck_before = run_autoload.available_cards.size()
	_expect(run_autoload.shop_buy({"cost": 10, "node_card": {"type": "shop", "level": 1}})
		and run_autoload.available_cards.size() == node_deck_before + 1,
		"商店可购买节点卡")
	var event_battle_result: Dictionary = run_autoload.apply_event({"battle": "archer", "battle_level": 1})
	_expect(event_battle_result.get("battle", false)
		and run_autoload.battle_enemy_key == "archer", "奇遇可触发独立战斗")
	var event_scene = load("res://scenes/event.tscn").instantiate()
	root.add_child(event_scene)
	await self.process_frame
	_expect(event_scene.get_child_count() > 0
		and event_scene._choice_box.get_child_count() > 0
		and event_scene._choice_box.get_child(0) is Button
		and event_scene._title.text != "",
		"事件界面直接提供三项抉择，不提前泄露随机结果")
	event_scene.queue_free()
	var shop_scene = load("res://scenes/shop.tscn").instantiate()
	root.add_child(shop_scene)
	await self.process_frame
	_expect(shop_scene.get_child_count() > 0, "商店界面构建成功")
	shop_scene.queue_free()
	var equipment_scene = load("res://scenes/equipment.tscn").instantiate()
	root.add_child(equipment_scene)
	await self.process_frame
	_expect(equipment_scene._slot_box.get_child_count() == 3,
		"战前装备界面显示三个通用装备位")
	_expect(equipment_scene._member_box.get_child_count() == run_autoload.party.size(),
		"战前装备界面可切换所有队伍成员")
	equipment_scene.queue_free()
	run_autoload.node_levels[run_autoload.node_pos] = 3
	var recruit_scene = load("res://scenes/recruit.tscn").instantiate()
	root.add_child(recruit_scene)
	await self.process_frame
	_expect(recruit_scene._candidate_box.get_child_count() > 0
		and recruit_scene._node_level == 3
		and recruit_scene._title.text.contains("Lv.3")
		and recruit_scene._candidate_box.get_child(0) is HBoxContainer
		and recruit_scene._candidate_box.get_child(0).get_child_count() == 2,
		"招募节点显示选择与独立详情按钮，并正确识别高等级节点")
	recruit_scene.queue_free()
	var ranger_before: Dictionary = run_autoload._actor_for_key("ranger")
	var ranger_level_before: int = int(ranger_before.get("level", 1))
	var upgrade_result: Dictionary = run_autoload.upgrade_character("ranger")
	_expect(upgrade_result.get("level", 0) == ranger_level_before + 1
		and ranger_before["skills"].size() == 2
		and not upgrade_result["passive"].is_empty()
		and ranger_before.get("bleed_damage_bonus", 0.0) > 0.0,
		"招募节点培养可解锁额外技能与复杂战斗被动")

	run_autoload.start_run()
	run_autoload.nodes[run_autoload.node_pos] = "boss"
	run_autoload.node_levels[run_autoload.node_pos] = 1
	run_autoload.enter_battle()
	_expect(run_autoload.battle_enemies.size() == 3, "Boss 战包含首领与两名随从")
	_expect(run_autoload.battle_enemies[0]["max_hp"] > GameData.ENEMIES["boss"]["max_hp"],
		"Boss 本体获得额外生命与攻击强化")
	run_autoload.nodes[run_autoload.node_pos] = "elite"
	run_autoload.enter_battle()
	_expect(run_autoload.battle_enemies.size() == 2, "精英战包含一名随从")

	# --- 蓄力、多目标与角色联动 ---
	run_autoload.start_run()
	run_autoload.upgrade_character("warrior")
	run_autoload.upgrade_character("warrior")
	run_autoload.prepare_battle_for_key("slime", 1, "nightmare")
	var charge_scene = load("res://scenes/battle.tscn").instantiate()
	root.add_child(charge_scene)
	await self.process_frame
	var charge_actor: Dictionary = run_autoload.player
	charge_actor["hp"] = 999
	charge_actor["max_hp"] = 999
	var enemy_hp_before_charge := []
	for enemy in charge_scene._enemies:
		enemy_hp_before_charge.append(enemy["hp"])
	charge_scene._on_skill("earth_breaker")
	_expect(charge_actor["charging_skill"] == "earth_breaker"
		and charge_scene._turn_locked.has(0),
		"蓄力技能先消耗本回合并进入蓄力状态")
	charge_scene._enemy_turn()
	var all_enemies_damaged := true
	for i in charge_scene._enemies.size():
		if charge_scene._enemies[i]["hp"] >= enemy_hp_before_charge[i]:
			all_enemies_damaged = false
	_expect(charge_actor["charging_skill"] == "" and all_enemies_damaged,
		"蓄力完成后自动释放并同时命中所有敌人")
	charge_scene.queue_free()

	run_autoload.start_run()
	run_autoload.recruit_character("cleric")
	run_autoload.prepare_battle_for_key("slime", 1, "battle")
	var first_shield_bonus: int = run_autoload.player.get("start_shield", 0)
	var first_heal_bonus: int = run_autoload.party[1].get("heal_bonus", 0)
	_expect(run_autoload.active_synergy_names().has("镇魂阵线")
		and first_shield_bonus == 8
		and first_heal_bonus == 2,
		"指定角色组合会激活队伍联动")
	run_autoload.prepare_battle_for_key("slime", 1, "battle")
	_expect(run_autoload.player.get("start_shield", 0) == first_shield_bonus
		and run_autoload.party[1].get("heal_bonus", 0) == first_heal_bonus,
		"队伍联动每场重新计算，不会重复叠加")
	run_autoload.player["hp"] = 1
	run_autoload.player["stamina"] = 0
	run_autoload.player["mana"] = 0
	run_autoload.player["bleed"] = 4
	run_autoload.player["stunned"] = 1
	run_autoload.player["shield"] = 12
	run_autoload.fully_recover_party_after_battle()
	_expect(run_autoload.player["hp"] == run_autoload.player["max_hp"]
		and run_autoload.player["stamina"] == run_autoload.player["max_stamina"]
		and run_autoload.player["mana"] == run_autoload.player["max_mana"]
		and run_autoload.player["bleed"] == 0
		and run_autoload.player["stunned"] == 0
		and run_autoload.player["shield"] == 0,
		"战斗结束后生命、体力、魔力回满并清除临时状态")

	# --- v5：局外成长（用独立实例测试，不落盘，避免污染真实存档） ---
	var meta_probe = load("res://scripts/meta.gd").new()
	meta_probe.shards = 0
	meta_probe.unlocked = ["warrior"]
	meta_probe.add_shards(25, false)
	_expect(meta_probe.shards == 25, "回声碎片累计（25）")
	_expect(not meta_probe.try_unlock("mage", false), "碎片不足无法解锁（25 < 30）")
	meta_probe.add_shards(10, false)
	_expect(meta_probe.try_unlock("mage", false), "碎片充足时解锁成功")
	_expect(meta_probe.is_unlocked("mage"), "解锁角色可用")

	# --- 全局效果详情：所有主界面自动挂载统一入口 ---
	var global_detail_scenes := [
		"main", "select", "planning", "map", "equipment", "battle",
		"event", "reward", "recruit", "shop", "settle", "codex",
	]
	var all_detail_entries_present := true
	for scene_name in global_detail_scenes:
		if scene_name == "event":
			run_autoload.pick_event()
		var detail_scene = load("res://scenes/%s.tscn" % scene_name).instantiate()
		root.add_child(detail_scene)
		await self.process_frame
		if detail_scene.find_child("GlobalDetailButton", true, false) == null:
			all_detail_entries_present = false
		detail_scene.queue_free()
		await self.process_frame
	_expect(all_detail_entries_present, "所有游戏界面都提供统一的效果详情入口")

	var detail_probe = load("res://scenes/main.tscn").instantiate()
	root.add_child(detail_probe)
	await self.process_frame
	var detail_button: Button = detail_probe.get_node_or_null("GlobalDetailButton")
	if detail_button != null:
		detail_button.emit_signal("pressed")
	await self.process_frame
	var detail_overlay = detail_probe.get_node_or_null("GlobalDetailOverlay")
	var detail_tabs = (
		detail_overlay.find_child("GlobalDetailTabs", true, false)
		if detail_overlay != null
		else null
	)
	_expect(detail_overlay != null and detail_tabs != null
		and detail_tabs.get_tab_count() == 6,
		"全局效果详情可打开并展示队伍、技能、装备、心魔、节点和机制六个分页")
	detail_probe.queue_free()

	print("=== 自检结束：%s ===" % ("全部通过" if _failures == 0 else "失败 %d 项" % _failures))
	quit(0 if _failures == 0 else 1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("[通过] " + msg)
	else:
		_failures += 1
		printerr("[失败] " + msg)
