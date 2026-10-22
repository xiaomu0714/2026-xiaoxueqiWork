extends SceneTree
## 平衡探针：用三人队伍、装备、培养和资源决策跑多组遭遇。

var _runs := 100
var _cases := [
	{"name": "普通 Lv1（裸装）", "node": "battle", "level": 1, "pressure": 0, "team": "bare"},
	{"name": "普通 Lv1（均衡）", "node": "battle", "level": 1, "pressure": 0, "team": "balanced"},
	{"name": "普通 Lv2（均衡）", "node": "battle", "level": 2, "pressure": 0, "team": "balanced"},
	{"name": "精英 压力1（均衡）", "node": "elite", "level": 1, "pressure": 1, "team": "balanced"},
	{"name": "精英 压力1（流血）", "node": "elite", "level": 1, "pressure": 1, "team": "bleed"},
	{"name": "Boss 压力2（均衡）", "node": "boss", "level": 1, "pressure": 2, "team": "balanced"},
	{"name": "Boss 压力2（流血）", "node": "boss", "level": 1, "pressure": 2, "team": "bleed"},
	{"name": "Boss 压力2（控制）", "node": "boss", "level": 1, "pressure": 2, "team": "control"},
]


func _initialize() -> void:
	for battle_case in _cases:
		_probe_case(battle_case)
	for initial_key in GameData.INITIAL_CHARACTERS:
		_probe_campaign(initial_key)
	quit()


func _probe_case(battle_case: Dictionary) -> void:
	var wins := 0
	var total_turns := 0
	var total_hp := 0
	var total_enemies := 0
	for i in _runs:
		var run = load("res://scripts/run_state.gd").new()
		run.character_key = "ranger" if battle_case["team"] == "bleed" else "warrior"
		run.start_run()
		_setup_party(run, battle_case["team"])
		run.dream_pressure = battle_case["pressure"]
		run.nodes[0] = battle_case["node"]
		run.node_levels[0] = battle_case["level"]
		run.node_pos = 0
		var primary_key: String = {
			"battle": "slime",
			"elite": "knight",
			"boss": "boss",
		}.get(battle_case["node"], "slime")
		run.prepare_battle_for_key(primary_key, battle_case["level"], battle_case["node"])
		var result := _fight(run)
		if result["win"]:
			wins += 1
			total_hp += result["hp"]
		total_turns += result["turns"]
		total_enemies += result["enemy_count"]
	print("%s：胜率 %d%%，平均回合 %.1f，平均敌人 %.2f，胜利剩余 HP %.1f" % [
		battle_case["name"], int(round(100.0 * wins / _runs)),
		float(total_turns) / _runs, float(total_enemies) / _runs,
		float(total_hp) / maxi(1, wins)])


func _setup_party(run, preset: String) -> void:
	if preset == "bare":
		run.recruit_character("cleric")
		run.recruit_character("guardian")
		return
	if preset == "bleed":
		run.recruit_character("assassin")
		run.recruit_character("channeler")
		run.inventory = [
			"shadow_bow", "blood_contract", "rage_charm",
			"rage_blade", "guardian_badge", "iron_armor",
			"moon_staff", "echo_ring", "ward_cloak",
			"potion_big", "potion_big", "potion_big",
			"stamina_tonic", "mana_tonic",
			"ward_orb", "ward_orb", "cleansing_incense",
		]
		run.equip_item("shadow_bow", "ranger", 0)
		run.equip_item("blood_contract", "ranger", 1)
		run.equip_item("guardian_badge", "ranger", 2)
		run.equip_item("rage_blade", "assassin", 0)
		run.equip_item("iron_armor", "assassin", 1)
		run.equip_item("rage_charm", "assassin", 2)
		run.equip_item("moon_staff", "channeler", 0)
		run.equip_item("echo_ring", "channeler", 1)
		run.equip_item("ward_cloak", "channeler", 2)
		run.upgrade_character("assassin")
		run.upgrade_character("channeler")
		return
	if preset == "control":
		run.recruit_character("guardian")
		run.recruit_character("alchemist")
		run.inventory = [
			"rage_blade", "guardian_badge", "traveler_boots",
			"iron_armor", "shadow_bow", "rage_charm",
			"moon_staff", "healing_lantern", "echo_ring",
			"potion_big", "potion_big", "stamina_tonic", "mana_tonic",
			"ward_orb", "cleansing_incense",
		]
		run.equip_item("rage_blade", "warrior", 0)
		run.equip_item("guardian_badge", "warrior", 1)
		run.equip_item("traveler_boots", "warrior", 2)
		run.equip_item("iron_armor", "guardian", 0)
		run.equip_item("shadow_bow", "guardian", 1)
		run.equip_item("rage_charm", "guardian", 2)
		run.equip_item("moon_staff", "alchemist", 0)
		run.equip_item("healing_lantern", "alchemist", 1)
		run.equip_item("echo_ring", "alchemist", 2)
		run.upgrade_character("guardian")
		run.upgrade_character("alchemist")
		return
	run.recruit_character("cleric")
	run.recruit_character("guardian")
	run.inventory = [
		"rage_blade", "guardian_badge", "traveler_boots",
		"moon_staff", "ward_cloak", "healing_lantern",
		"iron_armor", "shadow_bow",
		"potion_big", "potion_big", "stamina_tonic", "mana_tonic",
		"ward_orb", "cleansing_incense",
	]
	run.equip_item("rage_blade", "warrior", 0)
	run.equip_item("guardian_badge", "warrior", 1)
	run.equip_item("traveler_boots", "warrior", 2)
	run.equip_item("moon_staff", "cleric", 0)
	run.equip_item("ward_cloak", "cleric", 1)
	run.equip_item("healing_lantern", "cleric", 2)
	run.equip_item("iron_armor", "guardian", 0)
	run.equip_item("shadow_bow", "guardian", 1)
	run.upgrade_character("cleric")
	run.upgrade_character("guardian")


func _fight(run) -> Dictionary:
	var enemies: Array = run.battle_enemies.duplicate(true)
	var turns := 0
	var last_enemy_target_key := ""
	while _any_alive(enemies) and _any_alive(run.party) and turns < 80:
		turns += 1
		var locked := []
		for i in run.party.size():
			var actor: Dictionary = run.party[i]
			if actor.get("hp", 0) <= 0:
				locked.append(i)
				continue
			var start := Battle.resolve_turn_start(actor)
			if start["skip"]:
				locked.append(i)
				continue
			run.restore_turn_resources(actor)

		for i in run.party.size():
			if i in locked:
				continue
			var actor: Dictionary = run.party[i]
			if actor.get("hp", 0) <= 0:
				continue
			var action: Dictionary
			if actor.get("charging_skill", "") != "":
				action = GameData.SKILLS[actor["charging_skill"]].duplicate()
				action["cost"] = 0
				action["charge_turns"] = 0
				actor["charging_skill"] = ""
			else:
				action = _choose_action(run, actor, enemies)
				if action.get("charge_turns", 0) > 0:
					var resource_key := "stamina" if action.get("cost_type", "stamina") == "stamina" else "mana"
					var charge_cost: int = int(action.get("cost", 0))
					if int(actor.get(resource_key, 0)) >= charge_cost:
						actor[resource_key] -= charge_cost
						actor["charging_skill"] = action["_skill_key"]
					continue
			if action.has("_item_key"):
				run.inventory.erase(action["_item_key"])
				action.erase("_item_key")
				action["is_item"] = true
			var target: Dictionary = _choose_enemy(enemies)
			if action.get("target", "self") == "ally":
				action["ally_target"] = _lowest_hp_ally(run.party)
				target = action["ally_target"]
			if action.get("target_mode", "") == "all_allies":
				action["target"] = "ally"
			var targets: Array = run.party if action.get("target_mode", "") == "all_allies" else [target]
			for target_entry in targets:
				if target_entry.get("hp", 0) <= 0:
					continue
				var local_action: Dictionary = action.duplicate()
				local_action["skip_start_status"] = true
				local_action["cost"] = action.get("cost", 0) if target_entry == targets[0] else 0
				var before_hp: int = int(target_entry.get("hp", 0))
				var target_was_bleeding := int(target_entry.get("bleed", 0)) > 0
				Battle.resolve_turn(actor, local_action, target_entry)
				_check_phase(target_entry)
				if action.get("effect", "") == "attack" and target_was_bleeding:
					actor["hp"] = mini(
						int(actor.get("max_hp", actor.get("hp", 0))),
						int(actor.get("hp", 0)) + int(actor.get("bleed_hit_heal", 0)))
				if before_hp > 0 and target_entry.get("hp", 0) <= 0:
					actor["hp"] = mini(
						int(actor.get("max_hp", actor.get("hp", 0))),
						int(actor.get("hp", 0)) + int(actor.get("on_kill_heal", 0)))
			if _choose_enemy(enemies).is_empty():
				break
		if not _any_alive(enemies):
			break
		var round_target_keys := []
		for enemy in enemies:
			if enemy.get("hp", 0) <= 0:
				continue
			var target := _random_alive_ally(run.party, last_enemy_target_key, round_target_keys)
			if target.is_empty():
				break
			last_enemy_target_key = target.get("key", target.get("name", ""))
			round_target_keys.append(last_enemy_target_key)
			var intent: Dictionary = Battle.enemy_intent(enemy, turns)
			if intent.get("target", "self") == "ally":
				var support_target: Dictionary = _choose_enemy(enemies)
				intent["ally_target"] = support_target
				Battle.resolve_turn(enemy, intent, support_target)
			else:
				Battle.resolve_turn(enemy, intent, target)
	if _any_alive(enemies):
		return {"win": false, "turns": turns, "enemy_count": enemies.size(), "hp": 0}
	return {"win": true, "turns": turns, "enemy_count": enemies.size(), "hp": _party_hp(run.party)}


func _choose_action(run, actor: Dictionary, enemies: Array) -> Dictionary:
	var lowest_ally: Dictionary = _lowest_hp_ally(run.party)
	var lowest_ratio := float(lowest_ally.get("hp", 0)) / maxi(1.0, float(lowest_ally.get("max_hp", 1)))
	var target_enemy: Dictionary = _choose_enemy(enemies)
	var self_ratio := float(actor.get("hp", 0)) / maxi(1.0, float(actor.get("max_hp", 1)))
	if (actor.get("bleed", 0) > 0 or actor.get("stunned", 0) > 0) and run.inventory.has("cleansing_incense"):
		var cleanse_item: Dictionary = GameData.ITEMS["cleansing_incense"].duplicate()
		cleanse_item["_item_key"] = "cleansing_incense"
		return cleanse_item
	if self_ratio < 0.38 and run.inventory.has("potion_big"):
		var potion: Dictionary = GameData.ITEMS["potion_big"].duplicate()
		potion["_item_key"] = "potion_big"
		return potion
	if self_ratio < 0.58 and actor.get("shield", 0) <= 0 and run.inventory.has("ward_orb"):
		var ward: Dictionary = GameData.ITEMS["ward_orb"].duplicate()
		ward["_item_key"] = "ward_orb"
		return ward
	var skills: Array = actor.get("skills", [actor.get("skill", "")])
	for skill_key in skills:
		var skill: Dictionary = GameData.SKILLS[skill_key]
		var resource_key := "stamina" if skill.get("cost_type", "stamina") == "stamina" else "mana"
		if int(actor.get(resource_key, 0)) < int(skill.get("cost", 0)):
			continue
		if skill.get("charge_turns", 0) > 0:
			var should_charge: bool = (
				(skill.get("target_mode", "") == "all_enemies" and _alive_count(enemies) >= 2)
				or (float(skill.get("multiplier", 0.0)) >= 3.0 and _enemy_hp_total(enemies) >= 100)
				or (skill.get("target_mode", "") == "all_allies" and lowest_ratio < 0.48)
			)
			if should_charge:
				var charge_action := skill.duplicate()
				charge_action["_skill_key"] = skill_key
				return charge_action
			continue
		if skill.get("effect", "") == "heal" and lowest_ratio < 0.68:
			return skill.duplicate()
		if skill.get("effect", "") == "cleanse" and (
			lowest_ally.get("bleed", 0) > 0 or lowest_ally.get("stunned", 0) > 0):
			return skill.duplicate()
		if skill.get("effect", "") == "shield" and actor.get("shield", 0) < 8:
			return skill.duplicate()
		if skill.get("effect", "") == "restore":
			var restore_resource: String = skill.get("resource", "stamina")
			var lowest_resource_ratio := 2.0
			for ally in run.party:
				if ally.get("hp", 0) <= 0:
					continue
				var maximum := maxi(1, int(ally.get("max_" + restore_resource, 1)))
				lowest_resource_ratio = minf(
					lowest_resource_ratio,
					float(ally.get(restore_resource, 0)) / float(maximum))
			if lowest_resource_ratio < 0.55:
				return skill.duplicate()
			continue
		if skill.get("effect", "") == "attack":
			if skill.get("status", "") == "bleed" and target_enemy.get("bleed", 0) <= 0:
				return skill.duplicate()
			if skill.get("status", "") == "stun" and target_enemy.get("stunned", 0) <= 0:
				return skill.duplicate()
			if float(skill.get("multiplier", 0.0)) >= 1.4 or int(skill.get("flat", 0)) >= 12:
				return skill.duplicate()
	return {"effect": "attack", "multiplier": 1.0, "cost_type": "stamina", "cost": 1}


func _alive_count(enemies: Array) -> int:
	var result := 0
	for enemy in enemies:
		if enemy.get("hp", 0) > 0:
			result += 1
	return result


func _enemy_hp_total(enemies: Array) -> int:
	var result := 0
	for enemy in enemies:
		result += maxi(0, int(enemy.get("hp", 0)))
	return result


func _choose_enemy(enemies: Array) -> Dictionary:
	var result: Dictionary = {}
	for enemy in enemies:
		if enemy.get("hp", 0) <= 0:
			continue
		if result.is_empty() or enemy["hp"] < result["hp"]:
			result = enemy
	return result


func _lowest_hp_ally(allies: Array) -> Dictionary:
	var result: Dictionary = {}
	for ally in allies:
		if ally.get("hp", 0) <= 0:
			continue
		if result.is_empty() or ally["hp"] < result["hp"]:
			result = ally
	return result


func _random_alive_ally(
	allies: Array,
	last_target_key: String = "",
	excluded_keys: Array = []
	) -> Dictionary:
	var alive := []
	for ally in allies:
		if ally.get("hp", 0) > 0:
			alive.append(ally)
	var candidates: Array = alive.duplicate()
	if candidates.size() > 1:
		for ally in alive:
			var ally_key: String = ally.get("key", ally.get("name", ""))
			if ally_key == last_target_key and candidates.size() > 1:
				candidates.erase(ally)
		for excluded_key in excluded_keys:
			for ally in candidates.duplicate():
				if candidates.size() > 1 and ally.get("key", ally.get("name", "")) == excluded_key:
					candidates.erase(ally)
	if candidates.is_empty():
		candidates = alive
	return {} if candidates.is_empty() else candidates[randi() % candidates.size()]


func _any_alive(actors: Array) -> bool:
	for actor in actors:
		if actor.get("hp", 0) > 0:
			return true
	return false


func _party_hp(party: Array) -> int:
	var result := 0
	for actor in party:
		result += int(actor.get("hp", 0))
	return result


func _check_phase(enemy: Dictionary) -> void:
	if enemy.is_empty() or enemy.get("hp", 0) <= 0:
		return
	if enemy.get("phase_triggered", false) or not enemy.has("phase_threshold"):
		return
	if float(enemy["hp"]) > float(enemy["max_hp"]) * float(enemy["phase_threshold"]):
		return
	enemy["phase_triggered"] = true
	enemy["atk"] += int(enemy.get("phase_atk", 0))
	enemy["shield"] = int(enemy.get("shield", 0)) + int(enemy.get("phase_shield", 0))


func _probe_campaign(initial_key: String) -> void:
	var campaign_runs := 60
	var wins := 0
	var first_elite_losses := 0
	var second_elite_losses := 0
	var boss_losses := 0
	var total_turns := 0
	var boss_reached := 0
	var boss_gear_total := 0
	var boss_exploration_total := 0
	var boss_level_total := 0
	var boss_hp_total := 0
	var boss_atk_total := 0
	var boss_reduction_total := 0
	var boss_heal_bonus_total := 0
	for i in campaign_runs:
		var run = load("res://scripts/run_state.gd").new()
		run.character_key = initial_key
		run.start_run()
		var recruits: Array = _campaign_recruits(initial_key)
		run.recruit_character(recruits[0])
		run.recruit_character(recruits[1])
		_grant_campaign_reward(run, 1, true)
		var first_elite := _campaign_battle(run, "elite", 1)
		total_turns += first_elite["turns"]
		if not first_elite["win"]:
			first_elite_losses += 1
			continue
		run.register_elite_victory()
		run.gain_exploration_xp(34, "精英")
		run.fully_recover_party_after_battle()
		run.upgrade_character(_campaign_upgrade_key(initial_key, 0))
		_grant_campaign_reward(run, 1, false)
		_grant_campaign_reward(run, 2, true)
		var normal := _campaign_battle(run, "battle", 2)
		total_turns += normal["turns"]
		if not normal["win"]:
			second_elite_losses += 1
			continue
		run.gain_exploration_xp(38, "镇守")
		run.fully_recover_party_after_battle()
		_grant_campaign_reward(run, 2, false)
		var second_elite := _campaign_battle(run, "elite", 1)
		total_turns += second_elite["turns"]
		if not second_elite["win"]:
			second_elite_losses += 1
			continue
		run.register_elite_victory()
		run.gain_exploration_xp(42, "精英")
		run.fully_recover_party_after_battle()
		run.upgrade_character(_campaign_upgrade_key(initial_key, 1))
		_grant_campaign_reward(run, 2, false)
		_grant_campaign_reward(run, 2, true)
		_buy_campaign_supplies(run)
		boss_reached += 1
		boss_gear_total += _campaign_gear_count(run)
		boss_exploration_total += run.exploration_level
		for actor in run.party:
			boss_level_total += int(actor.get("level", 1))
			boss_hp_total += int(actor.get("max_hp", 0))
			boss_atk_total += int(actor.get("atk", 0))
			boss_reduction_total += int(actor.get("damage_reduction", 0))
			boss_heal_bonus_total += int(actor.get("heal_bonus", 0))
		var boss := _campaign_battle(run, "boss", 1)
		total_turns += boss["turns"]
		if not boss["win"]:
			boss_losses += 1
			continue
		wins += 1
	print("整局（%s）：通关 %d%%，首精英失败 %d，二精英前失败 %d，Boss失败 %d，平均回合 %.1f，装备 %.1f，探索Lv %.1f，角色总Lv %.1f，总HP %.1f，总攻 %.1f，减伤 %.1f，治疗加成 %.1f" % [
		GameData.CHARACTERS[initial_key]["name"],
		int(round(100.0 * wins / campaign_runs)),
		first_elite_losses, second_elite_losses, boss_losses,
		float(total_turns) / campaign_runs,
		float(boss_gear_total) / maxi(1, boss_reached),
		float(boss_exploration_total) / maxi(1, boss_reached),
		float(boss_level_total) / maxi(1, boss_reached),
		float(boss_hp_total) / maxi(1, boss_reached),
		float(boss_atk_total) / maxi(1, boss_reached),
		float(boss_reduction_total) / maxi(1, boss_reached),
		float(boss_heal_bonus_total) / maxi(1, boss_reached)])


func _campaign_recruits(initial_key: String) -> Array:
	match initial_key:
		"warrior":
			return ["cleric", "guardian"]
		"ranger":
			return ["cleric", "guardian"]
		"cleric":
			return ["guardian", "warrior"]
		"channeler":
			return ["warrior", "cleric"]
	return ["cleric", "guardian"]


func _campaign_upgrade_key(initial_key: String, stage: int) -> String:
	var recruits: Array = _campaign_recruits(initial_key)
	return recruits[mini(stage, recruits.size() - 1)]


func _campaign_battle(run, node_type: String, level: int) -> Dictionary:
	var primary: String = {
		"battle": "slime",
		"elite": "knight",
		"boss": "boss",
	}.get(node_type, "slime")
	run.prepare_battle_for_key(primary, level, node_type)
	return _fight(run)


func _grant_campaign_reward(run, level: int, is_reward_node: bool) -> void:
	var rewards: Array = (
		run.roll_reward_node_rewards(level)
		if is_reward_node
		else run.roll_rewards(level)
	)
	var chosen: Dictionary = rewards[0]
	var best_equipment_score := -99999.0
	for reward in rewards:
		if reward["type"] == "item" and GameData.ITEMS[reward["item"]].get("kind", "") == "equipment":
			var equipment_score := -99999.0
			for actor in run.party:
				equipment_score = maxf(
					equipment_score,
					_equipment_score(actor, GameData.ITEMS[reward["item"]]))
			if equipment_score > best_equipment_score:
				best_equipment_score = equipment_score
				chosen = reward
		elif reward["type"] == "exploration_xp" and best_equipment_score <= -99990.0:
			chosen = reward
	run.apply_reward(chosen)
	if is_reward_node:
		run.gain_exploration_xp(10 + run.effective_tier(level) * 5, "奖励节点")
	if chosen["type"] == "item" and GameData.ITEMS[chosen["item"]].get("kind", "") == "equipment":
		_auto_equip_campaign(run, chosen["item"])


func _auto_equip_campaign(run, item_key: String) -> void:
	var best_actor: Dictionary = {}
	var best_slot := -1
	var best_gain := -99999.0
	for actor in run.party:
		var actor_key: String = actor.get("key", "")
		var slots: Array = run._equipment_list_for(actor_key)
		var new_score: float = _equipment_score(actor, GameData.ITEMS[item_key])
		for slot_index in 3:
			var old_item_key: String = str(slots[slot_index])
			var old_score := 0.0
			if old_item_key != "":
				old_score = _equipment_score(actor, GameData.ITEMS[old_item_key])
			var gain := new_score - old_score
			if gain > best_gain:
				best_gain = gain
				best_actor = actor
				best_slot = slot_index
	if not best_actor.is_empty() and run.inventory.has(item_key):
		if best_gain > 0.0 or run.equipment_in_slot(best_slot, best_actor.get("key", "")) == "":
			run.equip_item(item_key, best_actor.get("key", ""), best_slot)


func _equipment_score(actor: Dictionary, item: Dictionary) -> float:
	var score := 0.0
	var role: String = actor.get("role", "front")
	var key: String = actor.get("key", "")
	score += float(item.get("atk", 0)) * (2.0 + float(actor.get("atk", 0)) * 0.08)
	score += float(item.get("hp", 0)) * (1.3 if key == "guardian" else 0.7)
	score += float(item.get("stamina", 0)) * (2.2 if role == "front" else 0.5)
	score += float(item.get("mana", 0)) * (2.2 if role == "back" else 0.8)
	score += float(item.get("damage_reduction", 0)) * (8.0 if key == "guardian" else 4.0)
	score += float(item.get("heal_bonus", 0)) * (7.0 if key in ["cleric", "alchemist"] else 1.0)
	score += float(item.get("spell_damage_bonus", 0.0)) * (30.0 if key in ["mage", "channeler"] else 5.0)
	score += float(item.get("bleed_damage_bonus", 0.0)) * (30.0 if key in ["ranger", "assassin"] else 4.0)
	score += float(item.get("bleed_bonus", 0)) * (8.0 if key in ["ranger", "assassin"] else 1.0)
	score += float(item.get("shield_gain_bonus", 0)) * (5.0 if key == "guardian" else 2.0)
	score += float(item.get("support_refund_mana", 0)) * (7.0 if role == "back" else 1.0)
	score += float(item.get("item_power", 0)) * (6.0 if key == "alchemist" else 2.0)
	return score


func _buy_campaign_supplies(run) -> void:
	run.gold += 90
	var shop_equipment := ["guardian_badge", "ward_cloak", "rage_blade", "echo_ring", "iron_armor"]
	var bought_equipment := 0
	for item_key in shop_equipment:
		if bought_equipment >= 2:
			break
		if run.inventory.has(item_key) or _party_has_equipment(run, item_key):
			continue
		run.inventory.append(item_key)
		_auto_equip_campaign(run, item_key)
		bought_equipment += 1
	for item_key in ["potion_big", "ward_orb", "cleansing_incense", "stamina_tonic", "mana_tonic"]:
		if not run.inventory.has(item_key):
			run.inventory.append(item_key)


func _campaign_gear_count(run) -> int:
	var result := 0
	for actor in run.party:
		for item_key in run._equipment_list_for(actor.get("key", "")):
			if str(item_key) != "":
				result += 1
	return result


func _party_has_equipment(run, item_key: String) -> bool:
	for actor in run.party:
		if run._equipment_list_for(actor.get("key", "")).has(item_key):
			return true
	return false
