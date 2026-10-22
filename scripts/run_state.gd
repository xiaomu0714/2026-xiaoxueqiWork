extends Node
## 全局运行状态（自动加载单例）：单局数据 + 节点地图生成 + 战斗衔接
## run_state.gd：使用独立文件名，避免旧版 run.gd 缓存。

## 当前采用“一层 13 节点、边走边构筑”方案。
## 普通位置抵达时才从节点卡组选择一张；第 4、8 格精英与第 13 格首领固定。
const LAYER_COMPOSITIONS := [
	{"battle": 3, "event": 2, "reward": 2, "recruit": 1, "shop": 1, "rest": 1, "elite": 2, "boss": 1},
]
# 旧版地图按钮仍可能引用这两个常量，保留作兼容；新牌组默认不生成 branch。
const BRANCH_LEFT := ["battle", "battle"]
const BRANCH_RIGHT := ["event", "rest"]
const MAX_PARTY_SIZE := 6
const MAX_ROLE_SIZE := 3

var run_started := false
var character_key := "warrior"   # 当前角色（v3 做成可选）
var player := {}                 # 玩家当前属性（跨战斗保留）
var party: Array = []            # 前台/后台队伍；前台最多 3 人，后台最多 3 人
var equipment: Array = []        # 主控角色的 3 件装备（兼容旧界面）
var equipment_by_character: Dictionary = {} # 角色 key -> ["", "", ""] 三个通用装备位
var layer_index := 0
var nodes := []                  # 当前层节点序列
var node_pos := 0                # 指向"即将处理"的节点；== nodes.size() 表示本层走完
var finished := false            # 是否通关
var battle_enemy_key := "slime"  # 当前战斗的敌人
var battle_enemies: Array = []   # 当前战斗的敌方编队，每项为完整敌人字典
var inventory := []              # 道具背包（战斗中可消耗）
var gold := 0                    # 局内金币（商店使用）
var current_event := {}          # 当前事件内容（v4）
var last_notice := ""            # 跨场景显示上一节点的结算结果
var planning := false           # 当前是否需要为普通路线格选择节点牌
var available_nodes: Array = [] # 兼容旧逻辑：节点卡类型镜像
var available_cards: Array = [] # 玩家节点卡组，元素为 {"type": String, "level": int}
var planned_nodes: Array = []   # 已经放置过的节点类型
var planned_slots: Array = []   # 13 格路线；未来普通位置为 null
var planning_history: Array = [] # 保留字段，兼容旧缓存
var node_levels: Array = []
var battle_level := 1
var battle_effective_tier := 1
var dream_pressure := 0          # 每击败一名精英 +1，后续战斗与奖励同步增强
var elite_victories := 0
var dream_corruption := 0        # 梦蚀：奇遇中的长期风险资源
var memory_fragments := 0        # 记忆残片：部分高阶奇遇的交换资源
var event_flags: Dictionary = {} # 连续事件和隐藏选项的状态
var last_event_id := ""
var exploration_level := 1       # 本局探索等级，决定战斗中每回合资源恢复量
var exploration_xp := 0
var last_exploration_notice := ""
var recruit_visit_index := 0
var last_recruit_candidates: Array = []


func start_run() -> void:
	run_started = true
	layer_index = 0
	node_pos = 0
	finished = false
	battle_enemies = []
	battle_level = 1
	battle_effective_tier = 1
	dream_pressure = 0
	elite_victories = 0
	dream_corruption = 0
	memory_fragments = 0
	event_flags = {}
	last_event_id = ""
	exploration_level = 1
	exploration_xp = 0
	last_exploration_notice = ""
	recruit_visit_index = 0
	last_recruit_candidates = []
	nodes = []
	available_nodes = []
	available_cards = []
	for type_name in generate_starter_node_deck():
		available_cards.append({"type": type_name, "level": 1})
		available_nodes.append(type_name)
	planned_nodes = []
	planned_slots = []
	for i in 13:
		planned_slots.append(null)
	planned_slots[3] = {"type": "elite", "level": 1, "locked": true}
	planned_slots[7] = {"type": "elite", "level": 1, "locked": true}
	planned_slots[12] = {"type": "boss", "level": 1, "locked": true}
	nodes = []
	node_levels = []
	for card in planned_slots:
		if card == null:
			nodes.append("")
			node_levels.append(0)
		else:
			nodes.append(card["type"])
			node_levels.append(card.get("level", 1))
	planning_history = []
	planning = needs_node_selection()
	inventory = []
	party = []
	equipment = []
	equipment_by_character = {character_key: ["", "", ""]}
	gold = 0
	current_event = {}
	last_notice = ""
	var base: Dictionary = GameData.CHARACTERS[character_key]
	player = base.duplicate()
	player["key"] = character_key
	player["level"] = 1
	player["skills"] = [base["skill"]]
	player["growth_passives"] = []
	player["starter_passive_active"] = true
	player["hp"] = base["max_hp"]
	player["stamina"] = base["max_stamina"]
	player["mana"] = base["max_mana"]
	_apply_starter_passive(player, base.get("starter_passive", {}))
	party = [player]


func generate_starter_node_deck() -> Array:
	# 保底：初始手牌至少包含一张镇守(battle)和一张招募(recruit)，其余随机。
	var count := GameData.STARTER_NODE_CARD_COUNT
	var cards := ["battle", "recruit"]
	while cards.size() < count:
		cards.append(_roll_weighted_starter_node())
	cards.shuffle()
	return cards


func _roll_weighted_starter_node() -> String:
	var total_weight := 0
	for weight in GameData.STARTER_NODE_WEIGHTS.values():
		total_weight += int(weight)
	var roll := randi_range(1, total_weight)
	var cursor := 0
	for type_name in GameData.STARTER_NODE_WEIGHTS:
		cursor += int(GameData.STARTER_NODE_WEIGHTS[type_name])
		if roll <= cursor:
			return type_name
	return "battle"


func _apply_starter_passive(actor: Dictionary, passive: Dictionary) -> void:
	if passive.is_empty():
		return
	actor["starter_passive"] = passive.duplicate(true)
	match passive.get("type", ""):
		"first_action_discount":
			actor["first_action_discount"] = int(passive.get("amount", 0))
		"first_attack_bonus":
			actor["first_attack_bonus"] = int(passive.get("amount", 0))
		"first_support_shield":
			actor["first_support_shield"] = int(passive.get("amount", 0))
		"team_regen_bonus":
			actor["team_regen_bonus"] = int(passive.get("amount", 0))
	actor["starter_shield_bonus"] = int(passive.get("starter_shield", 0))
	actor["team_start_shield"] = int(passive.get("team_start_shield", 0))


func next_layer() -> void:
	layer_index += 1
	node_pos = 0
	if layer_index >= LAYER_COMPOSITIONS.size():
		finished = true
	else:
		nodes = _generate_layer()


## 生成单层牌组：13 张固定构成洗牌，首领固定在末尾。
func _generate_layer() -> Array:
	var pool: Array = GameData.NODE_DECK.duplicate()
	pool.shuffle()
	pool.erase("boss")
	pool.append("boss")
	return pool


func needs_node_selection() -> bool:
	return (
		node_pos >= 0
		and node_pos < planned_slots.size()
		and planned_slots[node_pos] == null
	)


func remaining_choice_slots() -> int:
	var count := 0
	for i in range(node_pos, planned_slots.size()):
		if planned_slots[i] == null:
			count += 1
	return count


func choose_node_card(hand_index: int) -> bool:
	if not planning or not needs_node_selection():
		return false
	if hand_index < 0 or hand_index >= available_cards.size():
		return false
	var card: Dictionary = available_cards[hand_index].duplicate()
	planned_slots[node_pos] = card
	nodes[node_pos] = card["type"]
	node_levels[node_pos] = int(card.get("level", 1))
	planned_nodes.append(card["type"])
	available_cards.remove_at(hand_index)
	_sync_available_nodes()
	planning = false
	return true


## 三张同类型、同等级节点卡，合成一张高一级节点卡。
func merge_node_cards(type_name: String, level: int) -> bool:
	var matching_indices: Array = []
	for i in available_cards.size():
		var card: Dictionary = available_cards[i]
		if card["type"] == type_name and int(card.get("level", 1)) == level:
			matching_indices.append(i)
	if matching_indices.size() < 3:
		return false
	# 合成会让卡组净减少 2 张，不能因此让剩余路线必然断档。
	if available_cards.size() - 2 < remaining_choice_slots():
		return false
	for offset in range(2, -1, -1):
		available_cards.remove_at(matching_indices[offset])
	available_cards.append({"type": type_name, "level": level + 1})
	_sync_available_nodes()
	return true


func can_merge_node_cards(type_name: String, level: int) -> bool:
	var count := 0
	for card in available_cards:
		if card["type"] == type_name and int(card.get("level", 1)) == level:
			count += 1
	return count >= 3 and available_cards.size() - 2 >= remaining_choice_slots()


func add_node_card(type_name: String, level: int = 1) -> Dictionary:
	if type_name not in GameData.NODE_CARD_DROP_POOL:
		return {}
	var card := {"type": type_name, "level": maxi(1, level)}
	available_cards.append(card)
	_sync_available_nodes()
	return card.duplicate()


func roll_node_card(max_level: int = 1) -> Dictionary:
	var type_name: String = GameData.NODE_CARD_DROP_POOL[randi() % GameData.NODE_CARD_DROP_POOL.size()]
	return {"type": type_name, "level": _roll_node_card_level(max_level, false)}


func roll_beneficial_node_card(max_level: int = 1) -> Dictionary:
	var pool: Array = GameData.BENEFICIAL_NODE_CARD_POOL
	var type_name: String = pool[randi() % pool.size()]
	return {"type": type_name, "level": _roll_node_card_level(max_level, true)}


func _roll_node_card_level(max_level: int, favorable: bool) -> int:
	var capped_level := clampi(max_level, 1, 3)
	var roll := randf()
	if capped_level >= 3:
		if roll < (0.25 if favorable else 0.12):
			return 3
		if roll < (0.70 if favorable else 0.42):
			return 2
	elif capped_level >= 2 and roll < (0.50 if favorable else 0.25):
		return 2
	return 1


func node_card_max_level_for_tier(tier: int, _favorable: bool = false) -> int:
	tier = maxi(1, tier)
	if tier >= 3:
		return 3
	if tier >= 2:
		return 2
	return 1


func battle_node_card_count(
		level: int = 1,
		encounter_type: String = "battle",
		defeated_tier: int = -1) -> int:
	var tier := defeated_tier if defeated_tier > 0 else effective_tier(level)
	if encounter_type in ["elite", "boss"] or level >= 2 or tier >= 2:
		return 3
	return 2


func grant_battle_node_cards(
		level: int = 1,
		encounter_type: String = "battle",
		defeated_tier: int = -1) -> Array:
	var tier := defeated_tier if defeated_tier > 0 else effective_tier(level)
	var max_card_level := node_card_max_level_for_tier(tier)
	var gained_cards := []
	for i in battle_node_card_count(level, encounter_type, tier):
		var rolled_card := roll_node_card(max_card_level)
		var gained := add_node_card(rolled_card["type"], int(rolled_card["level"]))
		if not gained.is_empty():
			gained_cards.append(gained)
	return gained_cards


func node_card_text(card: Dictionary) -> String:
	return "%s Lv.%d" % [
		node_type_name(card.get("type", "")),
		int(card.get("level", 1)),
	]


func node_card_list_text(cards: Array) -> String:
	var texts := []
	for card in cards:
		texts.append(node_card_text(card))
	return "、".join(texts)


func node_type_name(type_name: String) -> String:
	return {
		"battle": "镇守", "event": "奇遇", "reward": "奖励",
		"recruit": "招募", "shop": "商店", "rest": "恢复",
		"elite": "精英", "boss": "首领",
	}.get(type_name, type_name)


func set_notice(text: String) -> void:
	last_notice = text


func take_notice() -> String:
	var text := last_notice
	last_notice = ""
	return text


func _sync_available_nodes() -> void:
	available_nodes = []
	for card in available_cards:
		available_nodes.append(card["type"])


# 旧接口兼容：为“当前一步”选择指定类型节点。
func pick_planned_node(type_name: String) -> bool:
	for i in available_cards.size():
		if available_cards[i]["type"] == type_name:
			return choose_node_card(i)
	return false


func finish_planning() -> bool:
	# 旧界面曾调用此接口；新流程在选择一张卡后即完成本次放置。
	return not planning


## 推进到下一个节点（处理完当前节点后调用）
func advance() -> void:
	node_pos = mini(node_pos + 1, nodes.size())
	planning = needs_node_selection()


## 选择路线后：把该路线的节点插入岔路之后，并跳过岔路标记
func choose_route(option_nodes: Array) -> void:
	# 兼容旧存档/旧界面；新 Demo 不再使用 branch 节点。
	if is_branch():
		var before: Array = nodes.slice(0, node_pos + 1)
		var after: Array = nodes.slice(node_pos + 1)
		nodes = before + option_nodes + after
		node_pos += 1


func current_node() -> String:
	if node_pos >= nodes.size():
		return ""
	return nodes[node_pos]


func at_layer_end() -> bool:
	return node_pos >= nodes.size()


func is_branch() -> bool:
	return current_node() == "branch"


## 进入战斗：按当前节点类型从敌人池随机选一个敌人
func enter_battle() -> void:
	var pool: Array = GameData.NODE_ENEMY_MAP.get(current_node(), ["slime"])
	battle_enemy_key = pool[randi() % pool.size()]
	battle_level = node_levels[node_pos] if node_pos < node_levels.size() else 1
	battle_effective_tier = effective_tier(battle_level)
	battle_enemies = _build_enemy_party(battle_enemy_key, battle_level, current_node())
	_prepare_battle_resources()


func prepare_battle_for_key(enemy_key: String = "", level: int = 1, encounter_type: String = "event") -> void:
	if enemy_key != "":
		battle_enemy_key = enemy_key
	battle_level = maxi(1, level)
	battle_effective_tier = effective_tier(battle_level)
	battle_enemies = _build_enemy_party(battle_enemy_key, battle_level, encounter_type)
	_prepare_battle_resources()


func _build_enemy_party(primary_key: String, level: int, encounter_type: String) -> Array:
	var keys: Array = [primary_key]
	var follower_pool := ["slime", "archer", "wisp", "spider", "sentinel", "mender"]
	var tier := effective_tier(level)
	var party_size := party.size()
	match encounter_type:
		"battle":
			var follower_chance := minf(
				0.95,
				0.32 + 0.30 * maxi(0, party_size - 1) + 0.08 * maxi(0, tier - 1))
			if randf() < follower_chance:
				var follower: String = follower_pool[randi() % follower_pool.size()]
				if follower != primary_key:
					keys.append(follower)
			if party_size >= 3 and tier >= 2 and randf() < 0.38:
				keys.append(follower_pool[randi() % follower_pool.size()])
		"elite":
			var elite_followers := (
				["slime", "archer"]
				if dream_pressure == 0
				else ["archer", "sentinel", "mender", "wisp"]
			)
			keys.append(elite_followers[randi() % elite_followers.size()])
			if tier >= 2 and party_size >= 3 and randf() < 0.55:
				keys.append(["wisp", "spider", "mender"][randi() % 3])
		"boss":
			keys.append(["sentinel", "mender"][randi() % 2])
			keys.append(["wisp", "spider", "archer"][randi() % 3])
		"nightmare":
			keys.append(["wisp", "spider", "sentinel"][randi() % 3])
		_:
			pass
	var enemies: Array = []
	for key in keys:
		if not GameData.ENEMIES.has(key):
			continue
		var enemy: Dictionary = GameData.ENEMIES[key].duplicate(true)
		enemy["key"] = key
		var node_steps := maxi(0, level - 1)
		var pressure_steps := dream_pressure
		var party_steps := maxi(0, party_size - 1)
		var party_hp_scale := 0.04 if encounter_type == "boss" else (0.16 if encounter_type == "elite" else 0.18)
		var hp_multiplier := 1.0 + node_steps * 0.38 + pressure_steps * 0.18 + party_steps * party_hp_scale
		var atk_multiplier := 1.0 + node_steps * 0.18 + pressure_steps * 0.08 + party_steps * 0.025
		if encounter_type == "elite":
			hp_multiplier += 0.24
			atk_multiplier += 0.06
		elif encounter_type == "boss":
			hp_multiplier += 0.12
			atk_multiplier += 0.06
		elif encounter_type == "nightmare":
			hp_multiplier += 0.20
			atk_multiplier += 0.08
		enemy["max_hp"] = maxi(1, int(round(float(enemy["max_hp"]) * hp_multiplier)))
		enemy["atk"] = maxi(1, int(round(float(enemy["atk"]) * atk_multiplier)))
		enemy["damage_reduction"] = (
			int(enemy.get("damage_reduction", 0))
			+ int(floor(float(node_steps) / 2.0))
			+ int(floor(float(pressure_steps) / 2.0))
		)
		if encounter_type == "boss" and key != primary_key:
			enemy["max_hp"] = maxi(1, int(round(float(enemy["max_hp"]) * 0.78)))
			enemy["atk"] = maxi(1, int(round(float(enemy["atk"]) * 0.82)))
		if encounter_type == "boss" and key == primary_key:
			enemy["max_hp"] += 14 + dream_pressure * 7
			enemy["atk"] += 2 + dream_pressure
		if dream_corruption >= 4:
			enemy["max_hp"] += dream_corruption * 2
		enemy["hp"] = enemy["max_hp"]
		enemy["shield"] = maxi(0, pressure_steps + node_steps * 2)
		enemy["tier"] = tier
		enemy["phase_triggered"] = false
		enemies.append(enemy)
	return enemies


func effective_tier(node_level: int = 1) -> int:
	return maxi(1, node_level + dream_pressure)


func reward_quality_name(tier: int) -> String:
	if tier >= 6:
		return "传说"
	if tier >= 4:
		return "史诗"
	if tier >= 3:
		return "稀有"
	if tier >= 2:
		return "精良"
	return "普通"


func exploration_xp_to_next(level: int = -1) -> int:
	if level < 0:
		level = exploration_level
	return 30 + maxi(0, level - 1) * 20


func exploration_regen(level: int = -1) -> Dictionary:
	if level < 0:
		level = exploration_level
	var amount: int = 1 + int(floor(float(level) / 2.0))
	if player.get("starter_passive_active", false):
		amount += int(player.get("team_regen_bonus", 0))
	return {"stamina": amount, "mana": amount}


func exploration_progress_text() -> String:
	var regen: Dictionary = exploration_regen()
	return "探索 Lv.%d　经验 %d/%d　每回合体力/魔力 +%d" % [
		exploration_level, exploration_xp, exploration_xp_to_next(),
		regen["stamina"]]


func gain_exploration_xp(amount: int, source: String = "探索") -> Dictionary:
	amount = maxi(0, amount)
	var old_level := exploration_level
	exploration_xp += amount
	while exploration_xp >= exploration_xp_to_next():
		exploration_xp -= exploration_xp_to_next()
		exploration_level += 1
	var levels_gained := exploration_level - old_level
	var text := "%s：探索经验 +%d" % [source, amount]
	if levels_gained > 0:
		var regen: Dictionary = exploration_regen()
		text += "，探索等级提升至 Lv.%d！每回合体力/魔力恢复 %d 点" % [
			exploration_level, regen["stamina"]]
	last_exploration_notice = text
	return {
		"amount": amount,
		"old_level": old_level,
		"level": exploration_level,
		"levels_gained": levels_gained,
		"text": text,
	}


func restore_turn_resources(actor: Dictionary) -> Dictionary:
	var regen: Dictionary = exploration_regen()
	var stamina_before: int = int(actor.get("stamina", 0))
	var mana_before: int = int(actor.get("mana", 0))
	actor["stamina"] = mini(
		int(actor.get("max_stamina", stamina_before)),
		stamina_before + int(regen["stamina"]))
	actor["mana"] = mini(
		int(actor.get("max_mana", mana_before)),
		mana_before + int(regen["mana"]))
	return {
		"stamina": int(actor["stamina"]) - stamina_before,
		"mana": int(actor["mana"]) - mana_before,
	}


func take_exploration_notice() -> String:
	var text := last_exploration_notice
	last_exploration_notice = ""
	return text


func register_elite_victory() -> void:
	elite_victories += 1
	dream_pressure += 1
	battle_effective_tier = effective_tier(battle_level)
	set_notice(
		"精英已净化：梦境压力提升至 %d，后续战斗与奖励同步强化。"
		% dream_pressure)


func _prepare_battle_resources() -> void:
	_clear_team_synergies()
	apply_team_synergies()
	var team_shield_bonus := (
		int(player.get("team_start_shield", 0))
		if player.get("starter_passive_active", false)
		else 0
	)
	for actor in party:
		if int(actor.get("hp", 0)) <= 0:
			continue
		actor["stamina"] = actor.get("max_stamina", 0)
		actor["mana"] = actor.get("max_mana", 0)
		actor["shield"] = (
			int(actor.get("start_shield", 0))
			+ int(actor.get("starter_shield_bonus", 0))
			+ team_shield_bonus
		)
		actor["battle_first_action_available"] = true
		actor["battle_first_attack_available"] = true
		actor["battle_first_support_available"] = true
		actor["charging_skill"] = ""


func apply_team_synergies() -> void:
	var keys := []
	for actor in party:
		keys.append(actor.get("key", ""))
	for synergy in GameData.TEAM_SYNERGIES:
		if not synergy.get("id", "") in GameData.ACTIVE_TEAM_SYNERGY_IDS:
			continue
		var active := true
		for required_key in synergy["members"]:
			if not keys.has(required_key):
				active = false
				break
		if not active:
			continue
		for effect in synergy["effects"]:
			for actor in party:
				if actor.get("key", "") == effect["target"]:
					var field: String = effect["field"]
					var amount = effect["amount"]
					if amount is float:
						actor[field] = float(actor.get(field, 0.0)) + float(amount)
					else:
						actor[field] = int(actor.get(field, 0)) + int(amount)
					actor["synergy_modifiers"][field] = float(
						actor["synergy_modifiers"].get(field, 0.0)) + float(amount)
		for actor in party:
			actor["active_synergies"].append(synergy["name"])
	for synergy in GameData.EQUIPMENT_SYNERGIES:
		if not synergy.get("id", "") in GameData.ACTIVE_EQUIPMENT_SYNERGY_IDS:
			continue
		var target_key: String = synergy.get("character", "")
		if target_key == "" or not keys.has(target_key):
			continue
		if not _has_equipped_item(
			str(synergy.get("equipment", "")), target_key):
			continue
		for effect in synergy["effects"]:
			for actor in party:
				if actor.get("key", "") != effect["target"]:
					continue
				var field: String = effect["field"]
				var amount = effect["amount"]
				if amount is float:
					actor[field] = float(actor.get(field, 0.0)) + float(amount)
				else:
					actor[field] = int(actor.get(field, 0)) + int(amount)
				actor["synergy_modifiers"][field] = float(
					actor["synergy_modifiers"].get(field, 0.0)) + float(amount)
		for actor in party:
			if actor.get("key", "") == target_key:
				actor["active_synergies"].append(synergy["name"])


func _has_equipped_item(item_key: String, target_key: String = "") -> bool:
	if item_key == "":
		return false
	if target_key != "":
		return _equipment_list_for(target_key).has(item_key)
	for character_equipment in equipment_by_character.values():
		var equipped_values: Array = (
			character_equipment.values()
			if character_equipment is Dictionary
			else character_equipment
		)
		if equipped_values.has(item_key):
			return true
	return false


func _clear_team_synergies() -> void:
	for actor in party:
		for field in actor.get("synergy_modifiers", {}):
			var amount = actor["synergy_modifiers"][field]
			if amount is float:
				actor[field] = maxf(0.0, float(actor.get(field, 0.0)) - float(amount))
			else:
				actor[field] = maxi(0, int(actor.get(field, 0)) - int(amount))
		actor["synergy_modifiers"] = {}
		actor["active_synergies"] = []


func active_synergy_names() -> Array:
	var names := []
	for actor in party:
		for synergy_name in actor.get("active_synergies", []):
			if not names.has(synergy_name):
				names.append(synergy_name)
	return names


func character_synergy_hints(character_key: String) -> Array:
	var hints := []
	for synergy in GameData.TEAM_SYNERGIES:
		if not synergy.get("id", "") in GameData.ACTIVE_TEAM_SYNERGY_IDS:
			continue
		if not synergy.get("members", []).has(character_key):
			continue
		var partner_names := []
		for member_key in synergy["members"]:
			if member_key == character_key:
				continue
			partner_names.append(GameData.CHARACTERS.get(member_key, {}).get("name", member_key))
		var trigger := "、".join(partner_names) if not partner_names.is_empty() else "指定队友"
		hints.append("队伍联动：与%s同队 → %s" % [
			trigger, synergy.get("desc", "触发额外效果")])
	for synergy in GameData.EQUIPMENT_SYNERGIES:
		if not synergy.get("id", "") in GameData.ACTIVE_EQUIPMENT_SYNERGY_IDS:
			continue
		if synergy.get("character", "") != character_key:
			continue
		var item_key: String = synergy.get("equipment", "")
		var item_name: String = GameData.ITEMS.get(item_key, {}).get("name", item_key)
		hints.append("装备联动：装备【%s】→ %s" % [
			item_name, synergy.get("desc", "触发额外效果")])
	return hints


func item_synergy_hints(item_key: String) -> Array:
	var hints := []
	for synergy in GameData.EQUIPMENT_SYNERGIES:
		if not synergy.get("id", "") in GameData.ACTIVE_EQUIPMENT_SYNERGY_IDS:
			continue
		if synergy.get("equipment", "") != item_key:
			continue
		var character_key: String = synergy.get("character", "")
		var character_name: String = GameData.CHARACTERS.get(
			character_key, {}).get("name", character_key)
		hints.append("角色联动：由【%s】装备时触发 → %s" % [
			character_name, synergy.get("desc", "触发额外效果")])
	return hints


## 战斗胜利三选一：只包含金币、探索经验和装备/消耗品。
## 节点卡由 grant_battle_node_cards() 在胜利时独立发放，不占三选一位置。
func roll_rewards(level: int = 1) -> Array:
	var pool := build_reward_pool(level)
	var equipment_rewards := []
	var progression_rewards := []
	var utility_rewards := []
	for reward in pool:
		if reward["type"] == "item" and GameData.ITEMS[reward["item"]].get("kind", "") == "equipment":
			equipment_rewards.append(reward)
		elif reward["type"] in ["exploration_xp", "gold"]:
			progression_rewards.append(reward)
		else:
			utility_rewards.append(reward)
	equipment_rewards.shuffle()
	progression_rewards.shuffle()
	utility_rewards.shuffle()
	var result := []
	var tier: int = effective_tier(level)
	var guaranteed_equipment := 2 if tier >= 2 else 1
	while result.size() < guaranteed_equipment and not equipment_rewards.is_empty():
		result.append(equipment_rewards.pop_front())
	if not progression_rewards.is_empty():
		result.append(progression_rewards.pop_front())
	var remaining := equipment_rewards + progression_rewards + utility_rewards
	remaining.shuffle()
	while result.size() < 3 and not remaining.is_empty():
		result.append(remaining.pop_front())
	return result


func build_reward_pool(level: int = 1) -> Array:
	level = maxi(1, level)
	var tier := effective_tier(level)
	var pool := [
		{"type": "gold", "amount": 15 + tier * 15, "tier": tier},
		{"type": "exploration_xp", "amount": 16 + tier * 10, "tier": tier},
	]
	if tier >= 3 and int(player.get("level", 1)) < GameData.MAX_CHARACTER_LEVEL:
		pool.append({"type": "breakthrough", "amount": 1, "tier": tier})
	var equipment_pool := []
	var consumable_pool := []
	for item_key in GameData.REWARD_ITEM_POOL:
		if item_key not in GameData.ACTIVE_ITEM_KEYS:
			continue
		if GameData.ITEMS[item_key].get("kind", "consumable") == "equipment":
			equipment_pool.append(item_key)
		else:
			consumable_pool.append(item_key)
	equipment_pool.shuffle()
	consumable_pool.shuffle()
	var equipment_count := mini(
		equipment_pool.size(), 2 + int(floor(float(tier) / 3.0)))
	var consumable_count := mini(consumable_pool.size(), 2)
	for item_key in equipment_pool.slice(0, equipment_count):
		pool.append({"type": "item", "item": item_key, "tier": tier})
	for item_key in consumable_pool.slice(0, consumable_count):
		pool.append({"type": "item", "item": item_key, "tier": tier})
	return pool


## 奖励节点仍可把良性节点卡作为三选一的一项；综合强度越高，越可能直接出现 Lv.2/Lv.3。
func roll_reward_node_rewards(level: int = 1) -> Array:
	var result := roll_rewards(level)
	var tier := effective_tier(level)
	var card := roll_beneficial_node_card(node_card_max_level_for_tier(tier, true))
	var card_reward := {"type": "node_card", "card": card, "tier": tier}
	if result.size() >= 3:
		result[result.size() - 1] = card_reward
	else:
		result.append(card_reward)
	result.shuffle()
	return result


func reward_text(reward: Dictionary) -> String:
	var prefix := "【%s】" % reward_quality_name(int(reward.get("tier", 1)))
	match reward["type"]:
		"max_hp":
			return prefix + "全队生命上限 +%d" % reward["amount"]
		"atk":
			return prefix + "全队攻击 +%d" % reward["amount"]
		"max_stamina":
			return prefix + "全队体力上限 +%d" % reward["amount"]
		"max_mana":
			return prefix + "全队魔力上限 +%d" % reward["amount"]
		"gold":
			return prefix + "获得 %d 金币" % reward["amount"]
		"exploration_xp":
			return prefix + "探索经验 +%d" % reward["amount"]
		"item":
			return prefix + item_detail(reward["item"])
		"node_card":
			return prefix + "获得节点卡：%s" % node_card_text(reward["card"])
		"breakthrough":
			return prefix + "当前选中的入梦师成长 1 段（Lv.3 后可突破，最高 MAX）"
	return "？"


func item_detail(item_key: String) -> String:
	if not GameData.ITEMS.has(item_key):
		return "未知道具"
	var item: Dictionary = GameData.ITEMS[item_key]
	if item.get("kind", "consumable") == "equipment":
		var detail := "获得装备：%s\n效果：%s\n进入背包，可在战前自由分配给任意角色" % [
			item["name"], item["desc"]]
		var hints := item_synergy_hints(item_key)
		if not hints.is_empty():
			detail += "\n联动提示：\n" + "\n".join(hints)
		return detail
	return "获得道具：%s [战斗消耗品]\n效果：%s" % [item["name"], item["desc"]]


func skill_detail(skill_key: String) -> String:
	if not GameData.SKILLS.has(skill_key):
		return "未知技能"
	var skill: Dictionary = GameData.SKILLS[skill_key]
	var resource_name := "体力" if skill.get("cost_type", "stamina") == "stamina" else "魔力"
	return "%s（消耗 %d %s）\n效果：%s" % [
		skill["name"], skill.get("cost", 0), resource_name, skill.get("desc", "暂无说明")]


func passive_detail(passive: Dictionary) -> String:
	if passive.is_empty():
		return "无"
	return "%s\n效果：%s" % [passive.get("name", "未知被动"), passive.get("desc", "暂无说明")]


func apply_reward(reward: Dictionary) -> void:
	match reward["type"]:
		"max_hp":
			for actor in [player] + party:
				actor["max_hp"] += reward["amount"]
			player["hp"] = player["max_hp"]
		"atk":
			for actor in [player] + party:
				actor["atk"] += reward["amount"]
		"max_stamina":
			for actor in [player] + party:
				actor["max_stamina"] += reward["amount"]
			player["stamina"] = player["max_stamina"]
		"max_mana":
			for actor in [player] + party:
				actor["max_mana"] += reward["amount"]
			player["mana"] = player["max_mana"]
		"gold":
			gold += reward["amount"]
		"exploration_xp":
			gain_exploration_xp(int(reward["amount"]), "奖励")
		"item":
			inventory.append(reward["item"])
		"node_card":
			var card: Dictionary = reward.get("card", {})
			var gained := add_node_card(card.get("type", ""), int(card.get("level", 1)))
			if not gained.is_empty():
				set_notice("获得节点卡：%s" % node_card_text(gained))
		"breakthrough":
			var result := upgrade_character(character_key)
			if not result.is_empty():
				set_notice("%s 成长至 Lv.%d" % [
					player.get("name", "角色"), result["level"]])


func fully_recover_party_after_battle() -> void:
	for actor in party:
		if int(actor.get("max_hp", 0)) <= 0:
			continue
		actor["hp"] = actor["max_hp"]
		actor["stamina"] = actor.get("max_stamina", 0)
		actor["mana"] = actor.get("max_mana", 0)
		actor["bleed"] = 0
		actor["stunned"] = 0
		actor["shield"] = 0
		actor["battle_first_action_available"] = false
		actor["battle_first_attack_available"] = false
		actor["battle_first_support_available"] = false
		actor["charging_skill"] = ""
	_clear_team_synergies()


func recruit_character(key: String) -> bool:
	if not GameData.CHARACTERS.has(key):
		return false
	if party.size() >= MAX_PARTY_SIZE or key == character_key or equipment_by_character.has(key):
		return false
	var recruit: Dictionary = GameData.CHARACTERS[key].duplicate()
	var recruit_role: String = recruit.get("role", "front")
	if _party_role_count(recruit_role) >= MAX_ROLE_SIZE:
		return false
	recruit["key"] = key
	recruit["level"] = 1
	recruit["skills"] = [recruit["skill"]]
	recruit["growth_passives"] = []
	recruit["starter_passive_active"] = false
	recruit["hp"] = recruit["max_hp"]
	recruit["stamina"] = recruit["max_stamina"]
	recruit["mana"] = recruit["max_mana"]
	recruit["recruited"] = true
	party.append(recruit)
	equipment_by_character[key] = ["", "", ""]
	return true


func recruit_character_at_level(key: String, target_level: int = 1) -> Dictionary:
	if not recruit_character(key):
		return {}
	var growth_results := upgrade_character_steps(
		key, clampi(target_level, 1, GameData.MAX_CHARACTER_LEVEL) - 1)
	return {
		"actor": _actor_for_key(key),
		"growth": growth_results,
	}


func upgrade_character_steps(key: String, steps: int = 1) -> Array:
	var results := []
	for i in maxi(0, steps):
		var result := upgrade_character(key)
		if result.is_empty():
			break
		results.append(result)
	return results


func roll_recruit_candidates(count: int = 4) -> Array:
	var recruited := {}
	for actor in party:
		recruited[actor.get("key", "")] = true
	var pool := []
	for key in GameData.ACTIVE_CHARACTER_KEYS:
		if not recruited.has(key):
			var role: String = GameData.CHARACTERS[key].get("role", "front")
			if _party_role_count(role) >= MAX_ROLE_SIZE:
				continue
			pool.append(key)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


func _party_role_count(role: String) -> int:
	var count := 0
	for actor in party:
		if actor.get("role", "front") == role:
			count += 1
	return count


func begin_recruit_visit(count: int = 4) -> Array:
	recruit_visit_index += 1
	var candidates: Array = roll_recruit_candidates(count)
	if candidates.size() == count and pool_can_reroll_recruit(count):
		var previous_signature := last_recruit_candidates.duplicate()
		previous_signature.sort()
		for attempt in 8:
			var signature := candidates.duplicate()
			signature.sort()
			if signature != previous_signature:
				break
			candidates = roll_recruit_candidates(count)
	last_recruit_candidates = candidates.duplicate()
	return candidates


func pool_can_reroll_recruit(count: int) -> bool:
	var available := 0
	for key in GameData.ACTIVE_CHARACTER_KEYS:
		if not _actor_for_key(key).is_empty():
			continue
		if _party_role_count(GameData.CHARACTERS[key].get("role", "front")) >= MAX_ROLE_SIZE:
			continue
		available += 1
	return available > count


func upgrade_character(key: String) -> Dictionary:
	var actor: Dictionary = _actor_for_key(key)
	if actor.is_empty():
		return {}
	var old_level: int = int(actor.get("level", 1))
	if old_level >= GameData.MAX_CHARACTER_LEVEL:
		return {}
	var new_level := old_level + 1
	actor["level"] = new_level
	var growth: Dictionary = GameData.CHARACTER_LEVEL_GROWTH.get(
		new_level, {"hp": 5, "atk": 2, "resource": 1})
	var hp_gain: int = int(growth.get("hp", 5))
	var atk_gain: int = int(growth.get("atk", 2))
	var stamina_gain := 1 if actor.get("role", "front") == "front" else 0
	var mana_gain := 1 if actor.get("role", "front") == "back" else 0
	if new_level >= GameData.BREAKTHROUGH_LEVEL:
		stamina_gain += int(growth.get("resource", 1)) if actor.get("role", "front") == "front" else 0
		mana_gain += int(growth.get("resource", 1)) if actor.get("role", "front") == "back" else 0
	actor["max_hp"] += hp_gain
	actor["hp"] += hp_gain
	actor["atk"] += atk_gain
	actor["max_stamina"] += stamina_gain
	actor["stamina"] += stamina_gain
	actor["max_mana"] += mana_gain
	actor["mana"] += mana_gain
	var unlocked_skill := ""
	var unlocked_passive: Dictionary = {}
	var extra_skills: Array = GameData.CHARACTER_EXTRA_SKILLS.get(key, [])
	var unlock_index := new_level - 2
	if unlock_index >= 0 and unlock_index < extra_skills.size():
		unlocked_skill = extra_skills[unlock_index]
		if not actor["skills"].has(unlocked_skill):
			actor["skills"].append(unlocked_skill)
	var growth_passives: Array = GameData.CHARACTER_GROWTH_PASSIVES.get(key, [])
	if unlock_index >= 0 and unlock_index < growth_passives.size():
		unlocked_passive = growth_passives[unlock_index].duplicate(true)
		_apply_combat_passive(actor, unlocked_passive, 1)
		actor["growth_passives"].append(unlocked_passive)
	return {
		"level": new_level,
		"breakthrough": new_level >= GameData.BREAKTHROUGH_LEVEL,
		"hp": hp_gain,
		"atk": atk_gain,
		"stamina": stamina_gain,
		"mana": mana_gain,
		"skill": unlocked_skill,
		"passive": unlocked_passive,
	}


func equip_item(item_key: String, target_key: String = "", slot_index: int = -1) -> bool:
	if not GameData.ITEMS.has(item_key):
		return false
	var item: Dictionary = GameData.ITEMS[item_key]
	if item.get("kind", "") != "equipment":
		return false
	if not inventory.has(item_key):
		return false
	if target_key == "":
		target_key = character_key
	var target_actor: Dictionary = _actor_for_key(target_key)
	if target_actor.is_empty():
		return false
	if not can_equip_item(item_key, target_key):
		return false
	var target_equipment: Array = _equipment_list_for(target_key)
	if slot_index < 0:
		slot_index = target_equipment.find("")
	if slot_index < 0 or slot_index >= 3:
		return false
	var old_item_key: String = str(target_equipment[slot_index])
	inventory.erase(item_key)
	if old_item_key != "":
		var old_item: Dictionary = GameData.ITEMS[old_item_key]
		_apply_equipment_stats(target_actor, old_item, -1)
		inventory.append(old_item_key)
	target_equipment[slot_index] = item_key
	_apply_equipment_stats(target_actor, item, 1)
	if target_key == character_key:
		equipment = _equipped_values(target_equipment)
	_clear_team_synergies()
	apply_team_synergies()
	return true


func can_equip_item(item_key: String, target_key: String) -> bool:
	if not GameData.ITEMS.has(item_key):
		return false
	var actor: Dictionary = _actor_for_key(target_key)
	return not actor.is_empty()


func equipment_in_slot(slot_index: int, target_key: String = "") -> String:
	if target_key == "":
		target_key = character_key
	var items: Array = _equipment_list_for(target_key)
	if slot_index < 0 or slot_index >= items.size():
		return ""
	return str(items[slot_index])


func unequip_slot(slot_index: int, target_key: String = "") -> bool:
	if target_key == "":
		target_key = character_key
	var item_key := equipment_in_slot(slot_index, target_key)
	if item_key == "":
		return false
	var item: Dictionary = GameData.ITEMS[item_key]
	var target_actor: Dictionary = _actor_for_key(target_key)
	_apply_equipment_stats(target_actor, item, -1)
	var target_equipment: Array = _equipment_list_for(target_key)
	target_equipment[slot_index] = ""
	inventory.append(item_key)
	if target_key == character_key:
		equipment = _equipped_values(target_equipment)
	_clear_team_synergies()
	apply_team_synergies()
	return true


func equipment_summary(target_key: String = "") -> String:
	if target_key == "":
		target_key = character_key
	var parts := []
	for slot_index in 3:
		var item_key := equipment_in_slot(slot_index, target_key)
		parts.append("装备%d：%s" % [
			slot_index + 1,
			GameData.ITEMS[item_key]["name"] if item_key != "" else "无",
		])
	return "　".join(parts)


func _actor_for_key(target_key: String) -> Dictionary:
	if target_key == character_key:
		return player
	for actor in party:
		if actor.get("key", "") == target_key:
			return actor
	return {}


func _equipment_list_for(target_key: String) -> Array:
	if target_key == "":
		target_key = character_key
	if not equipment_by_character.has(target_key):
		equipment_by_character[target_key] = ["", "", ""]
	var stored = equipment_by_character[target_key]
	if stored is Dictionary:
		var migrated := []
		for value in stored.values():
			if str(value) != "":
				migrated.append(value)
		while migrated.size() < 3:
			migrated.append("")
		equipment_by_character[target_key] = migrated.slice(0, 3)
	return equipment_by_character[target_key]


func _equipped_values(items: Array) -> Array:
	var result := []
	for item_key in items:
		if str(item_key) != "":
			result.append(item_key)
	return result


func _apply_equipment_stats(actor: Dictionary, item: Dictionary, direction: int) -> void:
	if actor.is_empty():
		return
	var hp_delta: int = int(item.get("hp", 0)) * direction
	var stamina_delta: int = int(item.get("stamina", 0)) * direction
	var mana_delta: int = int(item.get("mana", 0)) * direction
	actor["max_hp"] = maxi(1, int(actor.get("max_hp", 1)) + hp_delta)
	actor["atk"] = maxi(0, int(actor.get("atk", 0)) + int(item.get("atk", 0)) * direction)
	actor["max_stamina"] = maxi(0, int(actor.get("max_stamina", 0)) + stamina_delta)
	actor["max_mana"] = maxi(0, int(actor.get("max_mana", 0)) + mana_delta)
	if direction > 0:
		actor["hp"] = mini(actor["max_hp"], int(actor.get("hp", 0)) + maxi(0, hp_delta))
		actor["stamina"] = mini(actor["max_stamina"], int(actor.get("stamina", 0)) + maxi(0, stamina_delta))
		actor["mana"] = mini(actor["max_mana"], int(actor.get("mana", 0)) + maxi(0, mana_delta))
	else:
		actor["hp"] = mini(int(actor.get("hp", 0)), int(actor["max_hp"]))
		actor["stamina"] = mini(int(actor.get("stamina", 0)), int(actor["max_stamina"]))
		actor["mana"] = mini(int(actor.get("mana", 0)), int(actor["max_mana"]))
	for stat in [
		"damage_reduction", "heal_bonus", "item_power", "start_shield",
		"on_kill_restore_stamina", "on_kill_restore_mana",
		"shield_gain_bonus", "support_refund_mana", "cleanse_shield",
		"first_action_discount", "bleed_bonus", "resource_bonus",
	]:
		actor[stat] = maxi(0, int(actor.get(stat, 0)) + int(item.get(stat, 0)) * direction)
	for stat in [
		"shielded_damage_bonus", "bleed_damage_bonus", "spell_damage_bonus",
		"low_hp_damage_bonus", "overheal_shield",
	]:
		actor[stat] = maxf(0.0, float(actor.get(stat, 0.0)) + float(item.get(stat, 0.0)) * direction)
	var character_key_for_bonus: String = actor.get("key", "")
	var character_bonus: Dictionary = item.get("character_bonuses", {}).get(
		character_key_for_bonus, {})
	for stat in character_bonus:
		var bonus = character_bonus[stat]
		if bonus is float:
			actor[stat] = maxf(0.0, float(actor.get(stat, 0.0)) + float(bonus) * direction)
		else:
			actor[stat] = maxi(0, int(actor.get(stat, 0)) + int(bonus) * direction)


func _apply_combat_passive(actor: Dictionary, passive: Dictionary, direction: int) -> void:
	var field: String = passive.get("field", "")
	if field == "":
		return
	var amount = passive.get("amount", 0)
	if amount is float:
		actor[field] = maxf(0.0, float(actor.get(field, 0.0)) + float(amount) * direction)
	else:
		actor[field] = maxi(0, int(actor.get(field, 0)) + int(amount) * direction)


## 随机选一个事件（v4）
func pick_event() -> void:
	var candidates := []
	var followups := []
	for event in GameData.EVENTS:
		if not event.get("id", "") in GameData.ACTIVE_EVENT_IDS:
			continue
		if event.has("requires") and not event_condition_met(event["requires"]):
			continue
		if event.has("blocks") and event_condition_met(event["blocks"]):
			continue
		if event.get("id", "") == last_event_id and GameData.EVENTS.size() > 1:
			continue
		candidates.append(event)
		if event.get("followup", false):
			followups.append(event)
	var pool: Array = followups if not followups.is_empty() else candidates
	if pool.is_empty():
		for event in GameData.EVENTS:
			if event.get("id", "") in GameData.ACTIVE_EVENT_IDS:
				pool.append(event)
	current_event = pool[randi() % pool.size()]
	last_event_id = current_event.get("id", "")


func event_condition_met(condition: Dictionary) -> bool:
	if condition.is_empty():
		return true
	match condition.get("type", ""):
		"character":
			for actor in party:
				if actor.get("key", "") == condition.get("key", ""):
					return true
			return false
		"equipment":
			for character_equipment in equipment_by_character.values():
				var equipped_values: Array = (
					character_equipment.values()
					if character_equipment is Dictionary
					else character_equipment
				)
				if equipped_values.has(condition.get("key", "")):
					return true
			return false
		"flag":
			return bool(event_flags.get(condition.get("key", ""), false))
		"no_flag":
			return not bool(event_flags.get(condition.get("key", ""), false))
		"pressure_min":
			return dream_pressure >= int(condition.get("amount", 0))
		"corruption_min":
			return dream_corruption >= int(condition.get("amount", 0))
		"corruption_max":
			return dream_corruption <= int(condition.get("amount", 0))
		"memory_min":
			return memory_fragments >= int(condition.get("amount", 0))
		"any":
			for nested_condition in condition.get("conditions", []):
				if event_condition_met(nested_condition):
					return true
			return false
		"all":
			for nested_condition in condition.get("conditions", []):
				if not event_condition_met(nested_condition):
					return false
			return true
	return false


func resolve_event_choice(choice: Dictionary) -> Dictionary:
	if choice.has("condition") and not event_condition_met(choice["condition"]):
		return {"valid": false, "text": "当前条件不足，无法选择。", "effect": {}}
	if choice.has("outcomes"):
		var outcomes: Array = choice["outcomes"]
		var total_weight := 0
		for outcome in outcomes:
			total_weight += maxi(0, int(outcome.get("weight", 0)))
		if total_weight <= 0:
			return {"valid": true, "text": "什么也没有发生。", "effect": {}}
		var roll := randi_range(1, total_weight)
		var cursor := 0
		for outcome in outcomes:
			cursor += maxi(0, int(outcome.get("weight", 0)))
			if roll <= cursor:
				return {
					"valid": true,
					"text": outcome.get("text", "结果已经揭晓。"),
					"effect": outcome.get("effect", {}),
					"exploration_xp": int(outcome.get(
						"exploration_xp", 12 + dream_pressure * 2)),
				}
	return {
		"valid": true,
		"text": choice.get("result_text", "你做出了选择。"),
		"effect": choice.get("effect", {}),
		"exploration_xp": int(choice.get(
			"exploration_xp",
			4 if choice.get("effect", {}).is_empty() else 10)),
	}


## 事件效果结算（v4）
func apply_event(effect: Dictionary) -> Dictionary:
	var gained_card: Dictionary = {}
	var result := {"battle": false, "gained_cards": []}
	if effect.has("hp_cost"):
		player["hp"] = maxi(0, player["hp"] - effect["hp_cost"])
	if effect.has("max_hp_delta"):
		player["max_hp"] = maxi(1, player["max_hp"] + int(effect["max_hp_delta"]))
		player["hp"] = mini(player["hp"], player["max_hp"])
	if effect.has("party_max_hp_delta"):
		for actor in party:
			var gain: int = int(effect["party_max_hp_delta"])
			actor["max_hp"] = maxi(1, int(actor["max_hp"]) + gain)
			actor["hp"] = mini(actor["max_hp"], int(actor["hp"]) + maxi(0, gain))
	if effect.has("party_max_mana_delta"):
		for actor in party:
			var mana_gain: int = int(effect["party_max_mana_delta"])
			actor["max_mana"] = maxi(0, int(actor["max_mana"]) + mana_gain)
			actor["mana"] = mini(
				actor["max_mana"], int(actor.get("mana", 0)) + maxi(0, mana_gain))
	if effect.has("heal"):
		player["hp"] = mini(player["max_hp"], player["hp"] + effect["heal"])
	if effect.has("atk"):
		player["atk"] += effect["atk"]
	if effect.has("stamina_cost"):
		player["stamina"] = maxi(0, player.get("stamina", 0) - int(effect["stamina_cost"]))
	if effect.has("mana_cost"):
		player["mana"] = maxi(0, player.get("mana", 0) - int(effect["mana_cost"]))
	if effect.has("gold_cost"):
		gold = maxi(0, gold - int(effect["gold_cost"]))
	if effect.has("gold"):
		gold += int(effect["gold"])
	if effect.has("exploration_xp"):
		gain_exploration_xp(int(effect["exploration_xp"]), "奇遇")
	if effect.has("dream_corruption"):
		dream_corruption = maxi(0, dream_corruption + int(effect["dream_corruption"]))
	if effect.has("memory"):
		memory_fragments = maxi(0, memory_fragments + int(effect["memory"]))
	if effect.has("memory_cost"):
		memory_fragments = maxi(0, memory_fragments - int(effect["memory_cost"]))
	if effect.has("set_flag"):
		event_flags[str(effect["set_flag"])] = true
	if effect.has("clear_flag"):
		event_flags.erase(str(effect["clear_flag"]))
	if effect.has("bleed"):
		player["bleed"] = maxi(int(player.get("bleed", 0)), int(effect["bleed"]))
	if effect.has("stun"):
		player["stunned"] = maxi(int(player.get("stunned", 0)), int(effect["stun"]))
	if effect.has("item"):
		inventory.append(effect["item"])
	if effect.has("reward"):
		apply_reward(effect["reward"])
	if effect.has("node_card"):
		var card: Dictionary = effect["node_card"]
		gained_card = add_node_card(card.get("type", ""), int(card.get("level", 1)))
	if effect.get("random_node_card", false):
		var random_card := roll_node_card(int(effect.get("node_card_max_level", 1)))
		gained_card = add_node_card(random_card["type"], random_card["level"])
	if effect.get("random_beneficial_node_card", false):
		var beneficial_card := roll_beneficial_node_card(
			int(effect.get("node_card_max_level", 1)))
		gained_card = add_node_card(beneficial_card["type"], beneficial_card["level"])
	if not gained_card.is_empty():
		result["gained_cards"].append(gained_card)
		set_notice("奇遇中获得节点卡：%s" % node_card_text(gained_card))
	if effect.has("battle"):
		var battle_key: String = effect["battle"]
		if not GameData.ENEMIES.has(battle_key):
			battle_key = "slime"
		battle_enemy_key = battle_key
		battle_level = maxi(1, int(effect.get("battle_level", 1)))
		var encounter_type: String = effect.get("encounter_type", "nightmare")
		battle_effective_tier = effective_tier(battle_level)
		battle_enemies = _build_enemy_party(battle_enemy_key, battle_level, encounter_type)
		_prepare_battle_resources()
		result["battle"] = true
	return result


## 商店购买（v4）：金币足够则扣款并给货，返回是否成功
func shop_buy(offer: Dictionary) -> bool:
	if offer.has("breakthrough") and int(player.get("level", 1)) >= GameData.MAX_CHARACTER_LEVEL:
		return false
	if gold < offer["cost"]:
		return false
	gold -= offer["cost"]
	if offer.has("item"):
		inventory.append(offer["item"])
	if offer.has("atk"):
		player["atk"] += offer["atk"]
	if offer.has("heal"):
		player["hp"] = mini(player["max_hp"], player["hp"] + offer["heal"])
	if offer.has("exploration_xp"):
		gain_exploration_xp(int(offer["exploration_xp"]), "商店训练")
	if offer.has("node_card"):
		var card: Dictionary = offer["node_card"]
		var gained := add_node_card(card.get("type", ""), int(card.get("level", 1)))
		if not gained.is_empty():
			set_notice("商店购得节点卡：%s" % node_card_text(gained))
	if offer.has("breakthrough"):
		var result := upgrade_character(character_key)
		if not result.is_empty():
			set_notice("%s 通过突破训练提升至 Lv.%d" % [
				player.get("name", "角色"), result["level"]])
	return true
