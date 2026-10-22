extends SceneTree
## 全流程模拟（开发用）：用简单策略跑完整局，统计各角色胜率与强度数据
## 用法: godot --headless --path . --script res://scripts/sim_run.gd

var _runs := 40
var _chars := [
	"warrior", "ranger", "mage", "cleric",
	"guardian", "assassin", "channeler", "alchemist",
]
var _wins := 0
var _final_hps: Array = []


func _initialize() -> void:
	_run_sim()


func _run_sim() -> void:
	var run_node = root.get_node_or_null("Run")
	if run_node == null:
		run_node = load("res://scripts/run_state.gd").new()
		run_node.name = "Run"
		root.add_child(run_node)

	for char_key in _chars:
		_wins = 0
		_final_hps.clear()
		run_node.character_key = char_key
		for i in _runs:
			run_node.start_run()
			var remaining: int = _play_run(run_node)
			if remaining >= 0:
				_wins += 1
				_final_hps.append(remaining)
		var avg_hp := 0.0
		if _final_hps.size() > 0:
			for hp in _final_hps:
				avg_hp += hp
			avg_hp /= _final_hps.size()
		print("模拟 %d 局（%s）：胜利 %d，胜率 %.0f%%，平均通关剩余 HP %.1f" % [
			_runs, char_key, _wins, 100.0 * _wins / _runs, avg_hp])
	quit(0)


## 返回通关时剩余 HP；失败返回 -1
func _play_run(run_node) -> int:
	var guard := 0
	while not run_node.finished and guard < 1000:
		guard += 1
		if run_node.at_layer_end():
			run_node.next_layer()
			continue
		if run_node.planning:
			if not run_node.choose_node_card(0):
				return -1
		var node_type: String = run_node.current_node()
		match node_type:
			"battle", "elite", "boss":
				run_node.enter_battle()
				if not _play_battle(run_node, node_type):
					return -1
				run_node.advance()
			"event":
				run_node.pick_event()
				var choice: Dictionary = _pick_safe_choice(run_node.current_event)
				var event_result: Dictionary = run_node.apply_event(choice.get("effect", {}))
				if run_node.player["hp"] <= 0:
					return -1
				if event_result.get("battle", false):
					if not _play_battle(run_node, "event"):
						return -1
				run_node.advance()
			"reward":
				var reward_level: int = int(run_node.node_levels[run_node.node_pos])
				var reward_choices: Array = run_node.roll_reward_node_rewards(reward_level)
				run_node.apply_reward(reward_choices[0])
				run_node.advance()
			"shop":
				var offers := []
				for offer in GameData.SHOP_OFFERS:
					if offer.has("item") and offer["item"] not in GameData.ACTIVE_ITEM_KEYS:
						continue
					offers.append(offer)
					if offers.size() >= GameData.ACTIVE_SHOP_OFFER_COUNT:
						break
				for offer in offers:
					if offer.has("atk"):
						run_node.shop_buy(offer)
				run_node.advance()
			"rest":
				var healed: int = int(run_node.player["max_hp"] * 0.35)
				run_node.player["hp"] = mini(run_node.player["max_hp"], run_node.player["hp"] + healed)
				run_node.advance()
			_:
				run_node.advance()
	return run_node.player["hp"]


func _pick_safe_choice(event: Dictionary) -> Dictionary:
	for choice in event["choices"]:
		if choice.has("condition"):
			continue
		if choice.get("effect", {}).is_empty() and not choice.has("outcomes"):
			return choice
	return event["choices"][0]


## 战斗模拟：卷轴打高血、低血吃药、治疗型角色适时自疗、其余输出；胜利拿奖励
func _play_battle(run_node, encounter_type: String = "battle") -> bool:
	if run_node.battle_enemies.is_empty():
		run_node.prepare_battle_for_key(run_node.battle_enemy_key, run_node.battle_level, "battle")
	var enemies: Array = run_node.battle_enemies.duplicate(true)
	var potion_used := false
	var turn := 0
	var skill: Dictionary = GameData.SKILLS[run_node.player["skill"]]
	var is_healer: bool = skill["effect"] == "heal"
	while _any_enemy_alive(enemies) and run_node.player["hp"] > 0 and turn < 200:
		turn += 1
		# 我方回合：每名角色只行动一次；资源不会自然恢复。
		var enemy: Dictionary = _lowest_hp_enemy(enemies)
		if enemy.is_empty():
			break
		if enemy["hp"] >= 20 and run_node.inventory.has("scroll"):
			run_node.inventory.erase("scroll")
			Battle.resolve_turn(run_node.player, GameData.ITEMS["scroll"], enemy)
		if run_node.player["hp"] <= 8 and not potion_used:
			potion_used = true
			Battle.resolve_turn(run_node.player, {"effect": "heal", "amount": 5}, enemy)
		elif is_healer and run_node.player["hp"] <= int(run_node.player["max_hp"] * 0.6) and run_node.player["mana"] >= skill.get("cost", 0):
			Battle.resolve_turn(run_node.player, skill, enemy)
		elif run_node.player.get("stamina", 0) > 0:
			enemy = _lowest_hp_enemy(enemies)
			var action: Dictionary = {"effect": "attack", "multiplier": 1.0, "cost_type": "stamina", "cost": 1}
			if skill["effect"] == "attack" and run_node.player.get("stamina", 0) >= skill.get("cost", 0):
				action = skill
			Battle.resolve_turn(run_node.player, action, enemy)
		if not _any_enemy_alive(enemies):
			break
		# 结束我方回合：所有存活敌人依次行动。
		for foe in enemies:
			if foe.get("hp", 0) <= 0:
				continue
			Battle.resolve_turn(foe, Battle.enemy_intent(foe, turn), run_node.player)
			if run_node.player["hp"] <= 0:
				return false

	if _any_enemy_alive(enemies):
		return false
	# 胜利：节点卡独立入组，再从金币/经验/装备道具中选择奖励。
	run_node.gold += 10
	run_node.grant_battle_node_cards(
		run_node.battle_level, encounter_type, run_node.battle_effective_tier)
	if encounter_type == "elite":
		run_node.register_elite_victory()
	var rewards: Array = run_node.roll_rewards(run_node.battle_level)
	var best: Dictionary = rewards[0]
	for reward in rewards:
		if reward["type"] == "item":
			best = reward
			break
		elif reward["type"] == "exploration_xp":
			best = reward
	run_node.apply_reward(best)
	run_node.fully_recover_party_after_battle()
	return true


func _any_enemy_alive(enemies: Array) -> bool:
	for enemy in enemies:
		if enemy.get("hp", 0) > 0:
			return true
	return false


func _lowest_hp_enemy(enemies: Array) -> Dictionary:
	var result: Dictionary = {}
	for enemy in enemies:
		if enemy.get("hp", 0) <= 0:
			continue
		if result.is_empty() or enemy["hp"] < result["hp"]:
			result = enemy
	return result
