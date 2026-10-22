class_name Battle
## 双方回合制结算逻辑（纯逻辑，不涉及 UI）。
## 速度不再参与战斗；由界面控制“我方回合 → 心魔回合”。

## 结算一次行动。action 示例：
##   {"effect": "attack", "multiplier": 1.6}          普通/倍率攻击
##   {"effect": "attack", "multiplier": 0.6, "hits": 2} 多次攻击
##   {"effect": "heal", "amount": 8}                   治疗
##   {"effect": "restore", "resource": "mana", "amount": 4} 回复资源
##   {"effect": "shield", "amount": 10}                 获得护盾
##   {"effect": "cleanse", "amount": 5}                 净化并治疗
## 返回本次行动的日志（供 UI 展示）
static func resolve_turn(actor: Dictionary, action: Dictionary, target: Dictionary) -> Array:
	var log := []
	_prepare_actor(actor)
	_prepare_actor(target)
	var is_cleanse: bool = action.get("effect", "") == "cleanse"
	if not action.get("skip_start_status", false) and not is_cleanse:
		var turn_start := resolve_turn_start(actor)
		log.append_array(turn_start["log"])
		if turn_start["skip"]:
			return log
	var cost_type: String = action.get("cost_type", "")
	var cost: int = int(action.get("cost", 0))
	if cost_type != "":
		var resource_key := "stamina" if cost_type == "stamina" else "mana"
		if int(actor.get(resource_key, 0)) < cost:
			return [{"error": "资源不足"}]
		actor[resource_key] -= cost
	match action["effect"]:
		"attack":
			var hits: int = action.get("hits", 1)
			for i in hits:
				var flat: int = action.get("flat", 0)
				var item_bonus: int = int(actor.get("item_power", 0)) if action.get("is_item", false) else 0
				var damage_multiplier: float = float(action.get("multiplier", 1.0))
				if int(actor.get("shield", 0)) > 0:
					damage_multiplier *= 1.0 + float(actor.get("shielded_damage_bonus", 0.0))
				if int(target.get("bleed", 0)) > 0:
					damage_multiplier *= 1.0 + float(actor.get("bleed_damage_bonus", 0.0))
				if int(actor.get("hp", 0)) * 2 < int(actor.get("max_hp", 1)):
					damage_multiplier *= 1.0 + float(actor.get("low_hp_damage_bonus", 0.0))
				if action.get("cost_type", "") == "mana":
					damage_multiplier *= 1.0 + float(actor.get("spell_damage_bonus", 0.0))
				# 百分比伤害使用四舍五入。直接 int() 会向下截断，
				# 对低攻击、多段技能影响尤其明显（例如 8×70% 会错误压成 5）。
				var raw_dmg: int = int(round(float(actor["atk"]) * damage_multiplier)) + flat + item_bonus
				var dmg: int = maxi(1, raw_dmg - int(target.get("damage_reduction", 0)))
				var blocked: int = mini(int(target.get("shield", 0)), dmg)
				target["shield"] = maxi(0, int(target.get("shield", 0)) - blocked)
				var hp_dmg: int = dmg - blocked
				target["hp"] = maxi(0, target["hp"] - hp_dmg)
				log.append({"dmg": hp_dmg, "blocked": blocked, "target_hp": target["hp"]})
			var status_name: String = action.get("status", "")
			if status_name == "bleed":
				var bleed_amount: int = int(action.get("status_amount", 2)) + int(actor.get("bleed_bonus", 0))
				target["bleed"] = maxi(int(target.get("bleed", 0)), bleed_amount)
				log.append({"status": "流血"})
			elif status_name == "stun":
				if int(target.get("stun_guard", 0)) > 0:
					target["stun_guard"] = 0
					log.append({"status": "晕眩抵抗"})
				else:
					target["stunned"] = maxi(int(target.get("stunned", 0)), int(action.get("status_amount", 1)))
					log.append({"status": "晕眩"})
		"heal":
			var amount: int = int(action.get("amount", 0)) + int(actor.get("heal_bonus", 0))
			if action.get("is_item", false):
				amount += int(actor.get("item_power", 0))
			var receiver: Dictionary = action.get("ally_target", target) if action.get("target", "self") == "ally" else actor
			var before: int = int(receiver["hp"])
			receiver["hp"] = mini(receiver["max_hp"], receiver["hp"] + amount)
			var actual_heal: int = int(receiver["hp"]) - before
			var overheal: int = maxi(0, amount - actual_heal)
			if overheal > 0 and float(actor.get("overheal_shield", 0.0)) > 0.0:
				var converted: int = maxi(1, int(round(overheal * float(actor["overheal_shield"]))))
				receiver["shield"] = int(receiver.get("shield", 0)) + converted
				log.append({"shield": converted, "source": "overheal"})
			log.append({"heal": actual_heal, "hp": receiver["hp"]})
		"restore":
			var resource_key: String = action.get("resource", "stamina")
			var maximum_key := "max_" + resource_key
			var restore_amount: int = int(action.get("amount", 0)) + int(actor.get("resource_bonus", 0))
			if action.get("is_item", false):
				restore_amount += int(actor.get("item_power", 0))
			var receiver: Dictionary = action.get("ally_target", actor) if action.get("target", "self") == "ally" else actor
			var before: int = int(receiver.get(resource_key, 0))
			receiver[resource_key] = mini(int(receiver.get(maximum_key, before)), before + restore_amount)
			log.append({"restore": int(receiver[resource_key]) - before, "resource": resource_key})
		"shield":
			var shield_amount: int = int(action.get("amount", 0)) + int(actor.get("shield_gain_bonus", 0))
			if action.get("is_item", false):
				shield_amount += int(actor.get("item_power", 0))
			var receiver: Dictionary = action.get("ally_target", actor) if action.get("target", "self") == "ally" else actor
			receiver["shield"] = int(receiver.get("shield", 0)) + shield_amount
			log.append({"shield": shield_amount})
		"cleanse":
			var receiver: Dictionary = action.get("ally_target", actor) if action.get("target", "self") == "ally" else actor
			var removed := []
			if int(receiver.get("bleed", 0)) > 0:
				removed.append("流血")
			if int(receiver.get("stunned", 0)) > 0:
				removed.append("晕眩")
			receiver["bleed"] = 0
			receiver["stunned"] = 0
			var cleanse_heal: int = int(action.get("amount", 0))
			if action.get("is_item", false):
				cleanse_heal += int(actor.get("item_power", 0))
			var before: int = int(receiver["hp"])
			receiver["hp"] = mini(int(receiver["max_hp"]), int(receiver["hp"]) + cleanse_heal)
			log.append({"cleanse": removed, "heal": int(receiver["hp"]) - before})
	return log


## 每名角色每回合只结算一次的状态：晕眩跳过本回合，流血扣血并衰减。
static func resolve_turn_start(actor: Dictionary) -> Dictionary:
	_prepare_actor(actor)
	var log := []
	var stunned: int = int(actor.get("stunned", 0))
	if stunned > 0:
		actor["stunned"] = stunned - 1
		actor["stun_guard"] = 1
		return {"log": [{"error": "被晕眩，本回合无法行动"}], "skip": true}
	var bleed: int = int(actor.get("bleed", 0))
	if bleed > 0:
		actor["hp"] = maxi(0, int(actor["hp"]) - bleed)
		log.append({"status": "流血", "dmg": bleed})
		actor["bleed"] = maxi(0, bleed - 1)
	return {"log": log, "skip": int(actor.get("hp", 0)) <= 0}


static func _prepare_actor(actor: Dictionary) -> void:
	if not actor.has("bleed"):
		actor["bleed"] = 0
	if not actor.has("stunned"):
		actor["stunned"] = 0
	if not actor.has("shield"):
		actor["shield"] = 0
	if not actor.has("stun_guard"):
		actor["stun_guard"] = 0


## 兼容旧调用：现在不排序，战斗顺序由回合阶段决定。
static func turn_order(fighters: Array) -> Array:
	return fighters.duplicate()


## 敌人意图：每回合敌人要做什么
static func enemy_intent(enemy: Dictionary, turn_count: int) -> Dictionary:
	match enemy["pattern"]:
		"heavy_every_3":
			if turn_count % 3 == 0:
				return {"effect": "attack", "multiplier": 2.0}
			return {"effect": "attack", "multiplier": 1.0}
		"bleed_every_2":
			if turn_count % 2 == 0:
				return {"effect": "attack", "multiplier": 1.0, "status": "bleed", "status_amount": 2}
			return {"effect": "attack", "multiplier": 1.0}
		"stun_every_3":
			if turn_count % 3 == 0:
				return {"effect": "attack", "multiplier": 1.0, "status": "stun", "status_amount": 1}
			return {"effect": "attack", "multiplier": 1.0}
		"shield_every_2":
			if turn_count % 2 == 0:
				return {"effect": "shield", "amount": 6}
			return {"effect": "attack", "multiplier": 1.0}
		"shield_ally_every_2":
			if turn_count % 2 == 0:
				return {"effect": "shield", "target": "ally", "amount": 9}
			return {"effect": "attack", "multiplier": 1.0}
		"heal_every_3":
			if turn_count % 3 == 0:
				return {"effect": "heal", "amount": 6}
			return {"effect": "attack", "multiplier": 1.0}
		"heal_ally_every_2":
			if turn_count % 2 == 0:
				return {"effect": "heal", "target": "ally", "amount": 10}
			return {"effect": "attack", "multiplier": 1.0}
		_:
			return {"effect": "attack", "multiplier": 1.0}
