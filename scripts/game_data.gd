class_name GameData
## 游戏数据层（占位数值，随时可改）
## 角色 / 技能 / 敌人 全部数据驱动：改这里即可调整游戏内容
## 注意：当前数值是"能通关"的占位值，v3 奖励系统接入后按你的设计再调

## 只有以下 4 名角色可作为初始入梦师：2 名前台、2 名后台。
## 其余角色只能在招募节点中出现；初始被动仅对开局选择的角色生效。
const INITIAL_CHARACTERS := ["warrior", "ranger", "cleric", "channeler"]
## 正式内容规模：9 名角色。其余旧角色数据保留，仅用于兼容旧存档。
const ACTIVE_CHARACTER_KEYS := [
	"warrior", "ranger", "mage", "cleric", "guardian",
	"assassin", "channeler", "alchemist", "blade_dancer",
]
## 联动、专属装备和事件约缩减 25%，仅以下条目进入新局随机池与图鉴。
const ACTIVE_TEAM_SYNERGY_IDS := [
	"soul_line", "blood_hunt", "shadow_rhythm", "crimson_chord",
	"vanguard_hymn", "holy_bastion",
]
const ACTIVE_EQUIPMENT_SYNERGY_IDS := ["warbrand", "silent_execution"]
const ACTIVE_EVENT_IDS := [
	"lost_caravan", "cracked_mirror_hall", "dream_orchard", "echo_library",
	"nameless_gatekeeper", "forgotten_station", "last_train", "sleeping_theater",
	"inverted_ward", "deep_dream_well", "false_awakening_room", "memory_auction",
]
const ACTIVE_REWARD_EVENT_COUNT := 5
const ACTIVE_RECRUIT_EVENT_COUNT := 5
const ACTIVE_SHOP_OFFER_COUNT := 13
const ACTIVE_ITEM_KEYS := [
	"potion_small", "potion_big", "stamina_tonic", "mana_tonic",
	"scroll", "bleed_needle", "thunder_rune", "ward_orb",
	"cleansing_incense", "dream_bomb",
	"rage_blade", "moon_staff", "shadow_bow", "ward_cloak",
	"iron_armor", "dreamweave_robe", "rage_charm", "echo_ring",
	"guardian_badge", "traveler_boots", "blood_contract",
	"healing_lantern", "mirror_blade", "resonant_core",
]
const MAX_CHARACTER_LEVEL := 4
const BREAKTHROUGH_LEVEL := 3
const CHARACTER_LEVEL_GROWTH := {
	2: {"hp": 6, "atk": 3, "resource": 1},
	3: {"hp": 8, "atk": 3, "resource": 2},
	4: {"hp": 12, "atk": 5, "resource": 2},
}

const CHARACTERS := {
	"warrior": {"name": "镇魇武者", "role": "front", "action_mode": "蓄力爆发", "max_hp": 32, "atk": 9, "max_stamina": 6, "max_mana": 2, "skill": "heavy_strike", "starter_passive": {"type": "first_action_discount", "amount": 1, "name": "入梦先锋", "desc": "每场战斗第一次行动的资源消耗 -1"}},
	"ranger": {"name": "逐影猎手", "role": "front", "action_mode": "连续射击", "max_hp": 28, "atk": 8, "max_stamina": 8, "max_mana": 2, "skill": "double_shot", "starter_passive": {"type": "first_attack_bonus", "amount": 8, "starter_shield": 16, "name": "猎梦标记", "desc": "每场战斗开始获得 16 点护盾；第一次攻击额外造成 8 点伤害"}},
	"mage": {"name": "织梦术士", "role": "front", "action_mode": "高费法术", "max_hp": 18, "atk": 12, "max_stamina": 5, "max_mana": 5, "skill": "fireball"},
	"cleric": {"name": "引魂医者", "role": "back", "action_mode": "治疗支援", "max_hp": 28, "atk": 8, "max_stamina": 3, "max_mana": 8, "skill": "heal", "starter_passive": {"type": "first_support_shield", "amount": 7, "name": "引魂余辉", "desc": "每场战斗第一次支援行动额外为目标提供 7 点护盾"}},
	"guardian": {"name": "梦盾守卫", "role": "front", "action_mode": "护盾承伤", "max_hp": 44, "atk": 6, "max_stamina": 7, "max_mana": 3, "skill": "aegis_guard", "damage_reduction": 1, "start_shield": 8},
	"assassin": {"name": "血梦刺客", "role": "front", "action_mode": "流血处决", "max_hp": 23, "atk": 12, "max_stamina": 9, "max_mana": 2, "skill": "blood_cut", "bleed_bonus": 1},
	"channeler": {"name": "灵脉乐师", "role": "back", "action_mode": "资源循环", "max_hp": 30, "atk": 6, "max_stamina": 4, "max_mana": 10, "skill": "battle_hymn", "starter_passive": {"type": "team_regen_bonus", "amount": 1, "team_start_shield": 7, "name": "入梦和声", "desc": "全队开战获得 7 点护盾；每回合从探索等级获得的体力与魔力恢复额外 +1"}},
	"alchemist": {"name": "梦药炼金师", "role": "back", "action_mode": "净化炼金", "max_hp": 27, "atk": 7, "max_stamina": 5, "max_mana": 8, "skill": "purifying_mist", "item_power": 4},
	"blade_dancer": {"name": "裂梦剑客", "role": "front", "action_mode": "残影连舞", "max_hp": 29, "atk": 10, "max_stamina": 8, "max_mana": 3, "skill": "crescent_combo", "low_hp_damage_bonus": 0.10},
	"oracle": {"name": "星痕先知", "role": "back", "action_mode": "预言支援", "max_hp": 25, "atk": 7, "max_stamina": 4, "max_mana": 10, "skill": "fate_thread", "heal_bonus": 2},
	"dreamsmith": {"name": "铸梦工匠", "role": "front", "action_mode": "锻造护阵", "max_hp": 38, "atk": 7, "max_stamina": 7, "max_mana": 4, "skill": "forge_guard", "shield_gain_bonus": 2},
	"veil_scribe": {"name": "帷幕书记", "role": "back", "action_mode": "墨痕控场", "max_hp": 24, "atk": 9, "max_stamina": 4, "max_mana": 9, "skill": "echo_pulse", "spell_damage_bonus": 0.10},
}

## 技能效果模板：attack=攻击（multiplier 倍率，hits 次数） / heal=治疗（amount 数值）
const SKILLS := {
	"heavy_strike": {"name": "镇魇重击", "effect": "attack", "multiplier": 1.6, "cost_type": "stamina", "cost": 3, "desc": "消耗 3 体力，造成 160% 攻击"},
	"double_shot": {"name": "逐影连射", "effect": "attack", "multiplier": 0.7, "hits": 2, "cost_type": "stamina", "cost": 4, "desc": "消耗 4 体力，连续攻击 2 次，每次 70% 攻击"},
	"fireball": {"name": "梦火", "effect": "attack", "multiplier": 1.8, "cost_type": "stamina", "cost": 3, "desc": "消耗 3 体力，造成 180% 攻击"},
	"heal": {"name": "安魂术", "effect": "heal", "target": "ally", "amount": 9, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，治疗生命比例最低的队友 9 点"},
	"guard_stance": {"name": "镇守架势", "effect": "shield", "amount": 10, "cost_type": "stamina", "cost": 2, "desc": "消耗 2 体力，获得 10 点护盾"},
	"earth_breaker": {"name": "裂地斩", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 1.9, "cost_type": "stamina", "cost": 6, "desc": "消耗 6 体力蓄力 1 回合，随后对所有敌人造成 190% 攻击"},
	"piercing_arrow": {"name": "穿心箭", "effect": "attack", "multiplier": 1.3, "flat": 3, "cost_type": "stamina", "cost": 2, "desc": "消耗 2 体力，造成 130% 攻击并追加 3 点伤害"},
	"snare_shot": {"name": "缚影箭", "effect": "attack", "multiplier": 0.8, "status": "stun", "status_amount": 1, "cost_type": "stamina", "cost": 4, "desc": "消耗 4 体力，造成 80% 攻击并晕眩目标"},
	"frost_bolt": {"name": "霜梦术", "effect": "attack", "multiplier": 1.2, "status": "stun", "status_amount": 1, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，造成 120% 攻击并晕眩目标"},
	"meditation": {"name": "冥想", "effect": "restore", "resource": "mana", "amount": 4, "cost_type": "stamina", "cost": 1, "desc": "消耗 1 体力，回复 4 点魔力"},
	"greater_heal": {"name": "大安魂术", "effect": "heal", "target": "ally", "target_mode": "all_allies", "charge_turns": 1, "amount": 14, "cost_type": "mana", "cost": 7, "desc": "消耗 7 魔力蓄力 1 回合，随后治疗所有存活队友 14 点"},
	"sanctuary": {"name": "梦境庇护", "effect": "shield", "target": "ally", "amount": 14, "cost_type": "mana", "cost": 4, "desc": "消耗 4 魔力，为生命比例最低的队友提供 14 点护盾"},
	"aegis_guard": {"name": "守梦壁垒", "effect": "shield", "amount": 14, "cost_type": "stamina", "cost": 2, "desc": "消耗 2 体力，获得 14 点护盾"},
	"shield_bash": {"name": "盾击", "effect": "attack", "multiplier": 1.0, "status": "stun", "status_amount": 1, "cost_type": "stamina", "cost": 3, "desc": "消耗 3 体力，造成 100% 攻击并晕眩目标"},
	"fortress": {"name": "不动堡垒", "effect": "shield", "target": "ally", "target_mode": "all_allies", "charge_turns": 1, "amount": 20, "cost_type": "stamina", "cost": 6, "desc": "消耗 6 体力蓄力 1 回合，随后为全队提供 20 点护盾"},
	"blood_cut": {"name": "血痕切割", "effect": "attack", "multiplier": 0.9, "status": "bleed", "status_amount": 3, "cost_type": "stamina", "cost": 2, "desc": "消耗 2 体力，造成 90% 攻击并施加流血"},
	"execution": {"name": "梦隙处决", "effect": "attack", "charge_turns": 1, "multiplier": 3.2, "cost_type": "stamina", "cost": 7, "desc": "消耗 7 体力蓄力 1 回合，随后对单个目标造成 320% 攻击"},
	"shadow_step": {"name": "影遁", "effect": "shield", "amount": 12, "cost_type": "stamina", "cost": 1, "desc": "消耗 1 体力，获得 12 点护盾"},
	"battle_hymn": {"name": "奋战旋律", "effect": "restore", "target": "ally", "resource": "stamina", "amount": 4, "cost_type": "mana", "cost": 2, "desc": "消耗 2 魔力，为体力比例最低的队友回复 4 点体力"},
	"mana_hymn": {"name": "回梦旋律", "effect": "restore", "target": "ally", "resource": "mana", "amount": 4, "cost_type": "stamina", "cost": 1, "desc": "消耗 1 体力，为魔力比例最低的队友回复 4 点魔力"},
	"resonance_burst": {"name": "共鸣震波", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 2.0, "cost_type": "mana", "cost": 6, "desc": "消耗 6 魔力蓄力 1 回合，随后对所有敌人造成 200% 攻击"},
	"purifying_mist": {"name": "净化雾剂", "effect": "cleanse", "target": "ally", "amount": 6, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，为队友清除流血和晕眩并治疗 6 点"},
	"volatile_flask": {"name": "烈性烧瓶", "effect": "attack", "multiplier": 0, "flat": 16, "status": "bleed", "status_amount": 2, "cost_type": "mana", "cost": 2, "desc": "消耗 2 魔力，造成 16 点伤害并施加流血"},
	"panacea": {"name": "万用灵药", "effect": "cleanse", "target": "ally", "target_mode": "all_allies", "charge_turns": 1, "amount": 12, "cost_type": "mana", "cost": 7, "desc": "消耗 7 魔力蓄力 1 回合，随后净化全队并治疗 12 点"},
	"war_oath": {"name": "战誓", "effect": "shield", "amount": 16, "cost_type": "stamina", "cost": 3, "desc": "消耗 3 体力，获得 16 点护盾；本回合后续伤害仍会受护盾增幅"},
	"apocalypse_blade": {"name": "终焉斩", "effect": "attack", "charge_turns": 1, "multiplier": 2.8, "cost_type": "stamina", "cost": 7, "desc": "消耗 7 体力蓄力 1 回合，造成 280% 攻击"},
	"rain_of_arrows": {"name": "梦雨箭阵", "effect": "attack", "target_mode": "all_enemies", "multiplier": 0.9, "cost_type": "stamina", "cost": 5, "desc": "消耗 5 体力，对所有敌人造成 90% 攻击"},
	"perfect_shot": {"name": "无声必中", "effect": "attack", "charge_turns": 1, "multiplier": 2.5, "flat": 8, "cost_type": "stamina", "cost": 6, "desc": "消耗 6 体力蓄力 1 回合，造成 250% 攻击并追加 8 点伤害"},
	"meteor": {"name": "陨梦坠落", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 2.3, "cost_type": "mana", "cost": 6, "desc": "消耗 6 魔力蓄力 1 回合，对所有敌人造成 230% 攻击"},
	"astral_form": {"name": "星界护体", "effect": "shield", "amount": 15, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，获得 15 点护盾"},
	"soul_link": {"name": "魂线联结", "effect": "restore", "target": "ally", "target_mode": "all_allies", "resource": "mana", "amount": 4, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，为全队回复 4 点魔力"},
	"resurrection": {"name": "回魂祷言", "effect": "heal", "target": "ally", "charge_turns": 1, "amount": 24, "cost_type": "mana", "cost": 6, "desc": "消耗 6 魔力蓄力 1 回合，治疗目标 24 点生命"},
	"bulwark": {"name": "全域壁垒", "effect": "shield", "target": "ally", "target_mode": "all_allies", "amount": 12, "cost_type": "stamina", "cost": 4, "desc": "消耗 4 体力，为全队提供 12 点护盾"},
	"iron_heart": {"name": "铁心守望", "effect": "shield", "amount": 24, "cost_type": "stamina", "cost": 3, "desc": "消耗 3 体力，获得 24 点护盾"},
	"hemorrhage": {"name": "大出血", "effect": "attack", "multiplier": 1.4, "status": "bleed", "status_amount": 5, "cost_type": "stamina", "cost": 4, "desc": "消耗 4 体力，造成 140% 攻击并施加 5 层流血"},
	"death_mark": {"name": "死梦刻印", "effect": "attack", "charge_turns": 1, "multiplier": 3.8, "cost_type": "stamina", "cost": 8, "desc": "消耗 8 体力蓄力 1 回合，造成 380% 攻击"},
	"chorus": {"name": "万象合唱", "effect": "restore", "target": "ally", "target_mode": "all_allies", "resource": "stamina", "amount": 3, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，为全队回复 3 点体力"},
	"world_echo": {"name": "世界回响", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 2.4, "cost_type": "mana", "cost": 7, "desc": "消耗 7 魔力蓄力 1 回合，对所有敌人造成 240% 攻击"},
	"catalyst": {"name": "催化爆瓶", "effect": "attack", "target_mode": "all_enemies", "multiplier": 0, "flat": 12, "status": "bleed", "status_amount": 2, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，对所有敌人造成 12 点伤害并施加流血"},
	"transmute": {"name": "炼金转化", "effect": "restore", "target": "ally", "target_mode": "all_allies", "resource": "stamina", "amount": 4, "cost_type": "mana", "cost": 5, "desc": "消耗 5 魔力，为全队回复 4 点体力"},
	"crescent_combo": {"name": "月弧连舞", "effect": "attack", "multiplier": 0.75, "hits": 3, "cost_type": "stamina", "cost": 5, "desc": "消耗 5 体力，连续攻击 3 次"},
	"afterimage_guard": {"name": "残影护身", "effect": "shield", "amount": 10, "cost_type": "stamina", "cost": 1, "desc": "消耗 1 体力，获得 10 点护盾"},
	"phantom_flurry": {"name": "幻步千斩", "effect": "attack", "multiplier": 0.65, "hits": 4, "cost_type": "stamina", "cost": 6, "desc": "消耗 6 体力，连续攻击 4 次"},
	"limit_break": {"name": "裂界终式", "effect": "attack", "multiplier": 2.4, "cost_type": "stamina", "cost": 5, "desc": "突破技：消耗 5 体力，造成 240% 攻击"},
	"mirror_step": {"name": "镜界步", "effect": "shield", "amount": 18, "cost_type": "stamina", "cost": 2, "desc": "极限技：消耗 2 体力，获得 18 点护盾"},
	"fate_thread": {"name": "命运缝线", "effect": "heal", "target": "ally", "amount": 8, "cost_type": "mana", "cost": 2, "desc": "消耗 2 魔力，治疗生命比例最低的队友 8 点"},
	"starfall": {"name": "星痕坠落", "effect": "attack", "multiplier": 1.5, "cost_type": "mana", "cost": 4, "desc": "消耗 4 魔力，造成 150% 攻击"},
	"shared_vision": {"name": "共享视界", "effect": "restore", "target": "ally", "target_mode": "all_allies", "resource": "mana", "amount": 3, "cost_type": "mana", "cost": 4, "desc": "消耗 4 魔力，为全队回复 3 点魔力"},
	"fate_rewrite": {"name": "改写命途", "effect": "heal", "target": "ally", "target_mode": "all_allies", "charge_turns": 1, "amount": 18, "cost_type": "mana", "cost": 6, "desc": "消耗 6 魔力蓄力 1 回合，治疗全队 18 点"},
	"oracle_sanctum": {"name": "预言圣所", "effect": "shield", "target": "ally", "target_mode": "all_allies", "charge_turns": 1, "amount": 16, "cost_type": "mana", "cost": 5, "desc": "消耗 5 魔力蓄力 1 回合，为全队提供 16 点护盾"},
	"forge_guard": {"name": "铸梦护阵", "effect": "shield", "target": "ally", "amount": 11, "cost_type": "stamina", "cost": 3, "desc": "消耗 3 体力，为生命比例最低的队友提供 11 点护盾"},
	"forge_barrier": {"name": "群星锻壁", "effect": "shield", "target": "ally", "target_mode": "all_allies", "amount": 8, "cost_type": "stamina", "cost": 4, "desc": "消耗 4 体力，为全队提供 8 点护盾"},
	"heated_edge": {"name": "灼梦锤锋", "effect": "attack", "multiplier": 1.4, "status": "bleed", "status_amount": 2, "cost_type": "stamina", "cost": 4, "desc": "消耗 4 体力，造成 140% 攻击并施加流血"},
	"masterwork": {"name": "大师铸式", "effect": "shield", "target": "ally", "amount": 24, "cost_type": "stamina", "cost": 5, "desc": "突破技：消耗 5 体力，为队友提供 24 点护盾"},
	"perfect_form": {"name": "完美构型", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 1.7, "cost_type": "stamina", "cost": 7, "desc": "极限技：消耗 7 体力蓄力 1 回合，对所有敌人造成 170% 攻击"},
	"echo_pulse": {"name": "回声脉冲", "effect": "attack", "target_mode": "all_enemies", "multiplier": 1.15, "cost_type": "mana", "cost": 4, "desc": "消耗 4 魔力，对所有敌人造成 115% 攻击"},
	"ink_bind": {"name": "墨缚", "effect": "attack", "multiplier": 1.0, "status": "stun", "status_amount": 1, "cost_type": "mana", "cost": 3, "desc": "消耗 3 魔力，造成 100% 攻击并晕眩目标"},
	"deep_ink": {"name": "深墨潮汐", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 2.2, "cost_type": "mana", "cost": 6, "desc": "消耗 6 魔力蓄力 1 回合，对所有敌人造成 220% 攻击"},
	"blank_page": {"name": "空白新页", "effect": "cleanse", "target": "ally", "target_mode": "all_allies", "charge_turns": 1, "amount": 16, "cost_type": "mana", "cost": 6, "desc": "极限技：消耗 6 魔力蓄力 1 回合，净化全队并治疗 16 点"},
	"ink_collapse": {"name": "墨界坍缩", "effect": "attack", "target_mode": "all_enemies", "charge_turns": 1, "multiplier": 2.6, "cost_type": "mana", "cost": 7, "desc": "极限技：消耗 7 魔力蓄力 1 回合，对所有敌人造成 260% 攻击"},
}

## 队伍中同时存在对应角色时激活，效果仅在当场战斗中生效。
const TEAM_SYNERGIES := [
	{
		"id": "soul_line",
		"name": "镇魂阵线",
		"members": ["warrior", "cleric"],
		"desc": "镇魇武者开战护盾 +8；引魂医者治疗 +2",
		"effects": [
			{"target": "warrior", "field": "start_shield", "amount": 8},
			{"target": "cleric", "field": "heal_bonus", "amount": 2},
		],
	},
	{
		"id": "blood_hunt",
		"name": "血迹追猎",
		"members": ["ranger", "assassin"],
		"desc": "两人对流血目标的伤害 +25%，开战各获得 4 点护盾；命中流血目标回复 2 点生命，击杀敌人回复 4 点生命",
		"effects": [
			{"target": "ranger", "field": "bleed_damage_bonus", "amount": 0.25},
			{"target": "ranger", "field": "start_shield", "amount": 4},
			{"target": "ranger", "field": "on_kill_heal", "amount": 4},
			{"target": "ranger", "field": "bleed_hit_heal", "amount": 2},
			{"target": "assassin", "field": "bleed_damage_bonus", "amount": 0.25},
			{"target": "assassin", "field": "start_shield", "amount": 4},
			{"target": "assassin", "field": "on_kill_heal", "amount": 4},
			{"target": "assassin", "field": "bleed_hit_heal", "amount": 2},
		],
	},
	{
		"id": "shadow_rhythm",
		"name": "逐影节拍",
		"members": ["ranger", "channeler"],
		"desc": "逐影猎手开战护盾 +6；灵脉乐师支援技能返还 1 魔力",
		"effects": [
			{"target": "ranger", "field": "start_shield", "amount": 6},
			{"target": "channeler", "field": "support_refund_mana", "amount": 1},
		],
	},
	{
		"id": "crimson_chord",
		"name": "血色和弦",
		"members": ["assassin", "channeler"],
		"desc": "血梦刺客开战护盾 +6；灵脉乐师资源回复 +1",
		"effects": [
			{"target": "assassin", "field": "start_shield", "amount": 6},
			{"target": "channeler", "field": "resource_bonus", "amount": 1},
		],
	},
	{
		"id": "dream_resonance",
		"name": "梦脉共鸣",
		"members": ["mage", "channeler"],
		"desc": "织梦术士魔力攻击伤害 +25%；灵脉乐师资源回复 +2",
		"effects": [
			{"target": "mage", "field": "spell_damage_bonus", "amount": 0.25},
			{"target": "channeler", "field": "resource_bonus", "amount": 2},
		],
	},
	{
		"id": "fortified_formula",
		"name": "壁垒配方",
		"members": ["guardian", "alchemist"],
		"desc": "梦盾守卫获得护盾时额外 +5；炼金师净化额外提供 5 护盾",
		"effects": [
			{"target": "guardian", "field": "shield_gain_bonus", "amount": 5},
			{"target": "alchemist", "field": "cleanse_shield", "amount": 5},
		],
	},
	{
		"id": "vanguard_hymn",
		"name": "先锋战歌",
		"members": ["warrior", "channeler"],
		"desc": "武者击杀额外回复 1 体力；乐师资源回复 +1",
		"effects": [
			{"target": "warrior", "field": "on_kill_restore_stamina", "amount": 1},
			{"target": "channeler", "field": "resource_bonus", "amount": 1},
		],
	},
	{
		"id": "holy_bastion",
		"name": "圣盾回响",
		"members": ["guardian", "cleric"],
		"desc": "守卫减伤 +1；医者支援技能返还 1 魔力",
		"effects": [
			{"target": "guardian", "field": "damage_reduction", "amount": 1},
			{"target": "cleric", "field": "support_refund_mana", "amount": 1},
		],
	},
	{
		"id": "crafting_line",
		"name": "锻造协奏",
		"members": ["dreamsmith", "alchemist"],
		"desc": "铸梦工匠获得护盾时额外 +3；炼金师消耗品效果 +2",
		"effects": [
			{"target": "dreamsmith", "field": "shield_gain_bonus", "amount": 3},
			{"target": "alchemist", "field": "item_power", "amount": 2},
		],
	},
	{
		"id": "oracle_thread",
		"name": "星魂缝线",
		"members": ["oracle", "cleric"],
		"desc": "星痕先知支援技能返还 1 魔力；引魂医者治疗 +3",
		"effects": [
			{"target": "oracle", "field": "support_refund_mana", "amount": 1},
			{"target": "cleric", "field": "heal_bonus", "amount": 3},
		],
	},
	{
		"id": "phantom_arsenal",
		"name": "幻刃铸阵",
		"members": ["blade_dancer", "dreamsmith"],
		"desc": "裂梦剑客拥有护盾时伤害 +20%；铸梦工匠开战护盾 +6",
		"effects": [
			{"target": "blade_dancer", "field": "shielded_damage_bonus", "amount": 0.20},
			{"target": "dreamsmith", "field": "start_shield", "amount": 6},
		],
	},
	{
		"id": "ink_resonance",
		"name": "墨潮共鸣",
		"members": ["veil_scribe", "channeler"],
		"desc": "帷幕书记魔力攻击伤害 +20%；灵脉乐师资源回复 +2",
		"effects": [
			{"target": "veil_scribe", "field": "spell_damage_bonus", "amount": 0.20},
			{"target": "channeler", "field": "resource_bonus", "amount": 2},
		],
	},
	{
		"id": "six_person_formation",
		"name": "六芒梦阵",
		"members": ["warrior", "guardian", "cleric"],
		"desc": "三角前排减伤 +1；引魂医者开战护盾 +5",
		"effects": [
			{"target": "warrior", "field": "damage_reduction", "amount": 1},
			{"target": "guardian", "field": "damage_reduction", "amount": 1},
			{"target": "cleric", "field": "start_shield", "amount": 5},
		],
	},
]

## 角色穿戴指定装备时激活，效果叠加在普通装备属性与队伍联动之上。
const EQUIPMENT_SYNERGIES := [
	{
		"id": "warbrand",
		"name": "战痕共振",
		"character": "warrior",
		"equipment": "rage_blade",
		"desc": "镇魇武者装备怒痕长刃：击杀额外回复 1 体力，拥有护盾时伤害 +15%",
		"effects": [
			{"target": "warrior", "field": "on_kill_restore_stamina", "amount": 1},
			{"target": "warrior", "field": "shielded_damage_bonus", "amount": 0.15},
		],
	},
	{
		"id": "silent_execution",
		"name": "静默处决",
		"character": "assassin",
		"equipment": "shadow_bow",
		"desc": "血梦刺客装备逐影长弓：对流血目标伤害 +20%，击杀回复 1 体力",
		"effects": [
			{"target": "assassin", "field": "bleed_damage_bonus", "amount": 0.20},
			{"target": "assassin", "field": "on_kill_restore_stamina", "amount": 1},
		],
	},
	{
		"id": "oracle_lens",
		"name": "星镜预言",
		"character": "oracle",
		"equipment": "oracle_lens",
		"desc": "星痕先知装备星镜：支援技能返还 2 魔力，治疗效果 +3",
		"effects": [
			{"target": "oracle", "field": "support_refund_mana", "amount": 2},
			{"target": "oracle", "field": "heal_bonus", "amount": 3},
		],
	},
	{
		"id": "forge_core",
		"name": "工匠核心",
		"character": "dreamsmith",
		"equipment": "forge_gauntlet",
		"desc": "铸梦工匠装备锻梦护手：获得护盾额外 +4，开战护盾 +4",
		"effects": [
			{"target": "dreamsmith", "field": "shield_gain_bonus", "amount": 4},
			{"target": "dreamsmith", "field": "start_shield", "amount": 4},
		],
	},
	{
		"id": "ink_collar",
		"name": "墨印回路",
		"character": "veil_scribe",
		"equipment": "ink_collar",
		"desc": "帷幕书记装备墨印项圈：魔力攻击伤害 +18%，消耗品效果 +2",
		"effects": [
			{"target": "veil_scribe", "field": "spell_damage_bonus", "amount": 0.18},
			{"target": "veil_scribe", "field": "item_power", "amount": 2},
		],
	},
]

const CHARACTER_EXTRA_SKILLS := {
	"warrior": ["earth_breaker"],
	"ranger": ["piercing_arrow"],
	"mage": ["meteor"],
	"cleric": ["greater_heal"],
	"guardian": ["fortress"],
	"assassin": ["execution"],
	"channeler": ["resonance_burst"],
	"alchemist": ["panacea"],
	"blade_dancer": ["phantom_flurry"],
}
const CHARACTER_GROWTH_PASSIVES := {
	"warrior": [
		{"name": "盾势反击", "desc": "有护盾时伤害 +25%", "field": "shielded_damage_bonus", "amount": 0.25},
		{"name": "战意回流", "desc": "击败敌人回复 2 体力", "field": "on_kill_restore_stamina", "amount": 2},
	],
	"ranger": [
		{"name": "猎杀标记", "desc": "对流血目标伤害 +30%", "field": "bleed_damage_bonus", "amount": 0.30},
		{"name": "连猎", "desc": "击败敌人回复 2 体力", "field": "on_kill_restore_stamina", "amount": 2},
	],
	"mage": [
		{"name": "法术共鸣", "desc": "魔力攻击伤害 +25%", "field": "spell_damage_bonus", "amount": 0.25},
		{"name": "梦火回收", "desc": "击败敌人回复 2 魔力", "field": "on_kill_restore_mana", "amount": 2},
	],
	"cleric": [
		{"name": "余辉护佑", "desc": "过量治疗转为护盾", "field": "overheal_shield", "amount": 1},
		{"name": "祷告回响", "desc": "支援后回复 1 魔力", "field": "support_refund_mana", "amount": 1},
	],
	"guardian": [
		{"name": "厚重壁垒", "desc": "获得护盾额外 +4", "field": "shield_gain_bonus", "amount": 4},
		{"name": "守御本能", "desc": "受伤害 -1", "field": "damage_reduction", "amount": 1},
	],
	"assassin": [
		{"name": "嗜血追猎", "desc": "对流血目标伤害 +35%", "field": "bleed_damage_bonus", "amount": 0.35},
		{"name": "无声收割", "desc": "击败敌人回复 3 体力", "field": "on_kill_restore_stamina", "amount": 3},
	],
	"channeler": [
		{"name": "和声增幅", "desc": "资源回复额外 +2", "field": "resource_bonus", "amount": 2},
		{"name": "回声共振", "desc": "支援后回复 1 魔力", "field": "support_refund_mana", "amount": 1},
	],
	"alchemist": [
		{"name": "精炼配方", "desc": "消耗品效果 +3", "field": "item_power", "amount": 3},
		{"name": "净化护膜", "desc": "净化时额外提供 8 护盾", "field": "cleanse_shield", "amount": 8},
	],
	"blade_dancer": [
		{"name": "残影猎步", "desc": "对流血目标伤害 +25%", "field": "bleed_damage_bonus", "amount": 0.25},
		{"name": "回身斩", "desc": "击败敌人回复 2 体力", "field": "on_kill_restore_stamina", "amount": 2},
	],
}

## 敌人：pattern 为行动模式（普通镇守可随机出现 1~2 个，精英/Boss 带随从）
const ENEMIES := {
	"slime": {"name": "暴怒", "emotion": "暴怒", "max_hp": 24, "atk": 6, "pattern": "attack"},
	"archer": {"name": "嫉妒", "emotion": "嫉妒", "max_hp": 22, "atk": 7, "pattern": "bleed_every_2"},
	"golem": {"name": "傲慢", "emotion": "傲慢", "max_hp": 34, "atk": 8, "pattern": "heavy_every_3", "damage_reduction": 1},
	"wisp": {"name": "贪食幽光", "emotion": "贪食", "max_hp": 19, "atk": 5, "pattern": "bleed_every_2"},
	"spider": {"name": "疑惧蛛影", "emotion": "疑惧", "max_hp": 26, "atk": 6, "pattern": "stun_every_3"},
	"sentinel": {"name": "守梦傀儡", "emotion": "守序", "max_hp": 30, "atk": 6, "pattern": "shield_ally_every_2", "damage_reduction": 1},
	"mender": {"name": "缝梦医师", "emotion": "依赖", "max_hp": 22, "atk": 4, "pattern": "heal_ally_every_2"},
	"knight": {"name": "贪婪（精英）", "emotion": "贪婪", "max_hp": 62, "atk": 11, "pattern": "heavy_every_3", "damage_reduction": 1},
	"boss": {"name": "虚无（首领）", "emotion": "虚无", "max_hp": 94, "atk": 14, "pattern": "stun_every_3", "damage_reduction": 1, "phase_threshold": 0.45, "phase_atk": 3, "phase_shield": 20},
}

## 节点类型 → 敌人池（battle 节点从池中随机抽 1 个）
const NODE_ENEMY_MAP := {
	"battle": ["slime", "archer", "golem", "wisp", "spider", "sentinel", "mender"],
	"elite": ["knight"],
	"boss": ["boss"],
}

## 旧版完整路线构成，保留给图鉴与兼容逻辑使用。
const NODE_DECK := [
	"battle", "battle", "battle",
	"event", "event", "reward", "reward", "recruit", "shop", "rest",
	"elite", "elite", "boss",
]

## 开局只生成 6 张启动节点卡；之后主要依靠战斗、奖励和奇遇补充。
## 四类启动节点完全按权重独立抽取，不使用固定卡组或最低保底。
const STARTER_NODE_CARD_COUNT := 6
const STARTER_NODE_WEIGHTS := {
	"battle": 30,
	"event": 30,
	"reward": 20,
	"recruit": 20,
}

## 战斗、奖励和事件中可获得的普通节点卡类型。
const NODE_CARD_DROP_POOL := ["battle", "event", "reward", "recruit", "shop", "rest"]
## 良性节点掉落池：奖励与招募占主要部分，商店与恢复作为少量补充。
const BENEFICIAL_NODE_CARD_POOL := [
	"reward", "reward", "reward", "reward",
	"recruit", "recruit", "recruit", "recruit",
	"shop", "rest",
]

## 道具与装备。消耗品在战斗中使用；每名角色拥有 3 个通用装备位。
const ITEMS := {
	# 消耗品
	"potion_small": {"name": "微光药剂", "kind": "consumable", "effect": "heal", "amount": 8, "desc": "回复 8 点生命"},
	"potion_big": {"name": "浓缩梦露", "kind": "consumable", "effect": "heal", "amount": 15, "desc": "回复 15 点生命"},
	"stamina_tonic": {"name": "醒神茶", "kind": "consumable", "effect": "restore", "resource": "stamina", "amount": 3, "desc": "回复 3 点体力"},
	"mana_tonic": {"name": "星辉墨水", "kind": "consumable", "effect": "restore", "resource": "mana", "amount": 4, "desc": "回复 4 点魔力"},
	"scroll": {"name": "梦火卷轴", "kind": "consumable", "effect": "attack", "multiplier": 0, "flat": 20, "desc": "对敌人造成 20 点伤害"},
	"bleed_needle": {"name": "猩红梦针", "kind": "consumable", "effect": "attack", "multiplier": 0, "flat": 5, "status": "bleed", "status_amount": 3, "desc": "造成 5 点伤害并施加 3 层流血"},
	"thunder_rune": {"name": "惊雷符", "kind": "consumable", "effect": "attack", "multiplier": 0, "flat": 8, "status": "stun", "status_amount": 1, "desc": "造成 8 点伤害并使敌人晕眩 1 回合"},
	"ward_orb": {"name": "守梦晶球", "kind": "consumable", "effect": "shield", "amount": 10, "desc": "获得 10 点护盾"},
	"cleansing_incense": {"name": "净心香", "kind": "consumable", "effect": "cleanse", "amount": 5, "desc": "清除流血与晕眩，并回复 5 点生命"},
	"dream_bomb": {"name": "破梦炸弹", "kind": "consumable", "effect": "attack", "multiplier": 0, "flat": 30, "desc": "对敌人造成 30 点伤害"},

	# 装备：每名角色拥有 3 个通用装备位，所有角色都可自由搭配。
	"rage_blade": {"name": "怒痕长刃", "kind": "equipment", "role": "all", "atk": 3, "on_kill_restore_stamina": 1, "desc": "攻击 +3；击败敌人回复 1 体力"},
	"moon_staff": {"name": "月纹法杖", "kind": "equipment", "role": "all", "atk": 1, "mana": 3, "spell_damage_bonus": 0.20, "desc": "攻击 +1、魔力上限 +3；魔力攻击伤害 +20%"},
	"shadow_bow": {"name": "逐影长弓", "kind": "equipment", "role": "all", "atk": 2, "stamina": 2, "bleed_damage_bonus": 0.20, "desc": "攻击 +2、体力上限 +2；对流血目标伤害 +20%"},
	"ward_cloak": {"name": "护梦披风", "kind": "equipment", "role": "all", "hp": 6, "mana": 2, "support_refund_mana": 1, "desc": "生命上限 +6、魔力上限 +2；支援技能返还 1 魔力"},
	"iron_armor": {"name": "镇魇重甲", "kind": "equipment", "role": "all", "hp": 10, "damage_reduction": 1, "shield_gain_bonus": 3, "desc": "生命上限 +10、减伤 +1；获得护盾时额外 +3"},
	"dreamweave_robe": {"name": "织梦长袍", "kind": "equipment", "role": "all", "hp": 4, "mana": 4, "overheal_shield": 1, "desc": "生命上限 +4、魔力上限 +4；过量治疗转化为护盾"},
	"rage_charm": {"name": "暴怒护符", "kind": "equipment", "role": "all", "atk": 2, "low_hp_damage_bonus": 0.25, "desc": "攻击 +2；生命低于 50% 时伤害 +25%"},
	"echo_ring": {"name": "回声指环", "kind": "equipment", "role": "all", "mana": 2, "item_power": 3, "desc": "魔力上限 +2；消耗品效果 +3"},
	"guardian_badge": {"name": "守夜徽章", "kind": "equipment", "role": "all", "hp": 5, "start_shield": 6, "desc": "生命上限 +5；每场战斗开始获得 6 点护盾"},
	"traveler_boots": {"name": "逐梦行靴", "kind": "equipment", "role": "all", "stamina": 2, "first_action_discount": 1, "desc": "体力上限 +2；每场第一次行动消耗 -1"},
	"blood_contract": {"name": "血契面具", "kind": "equipment", "role": "all", "atk": 2, "bleed_bonus": 1, "desc": "攻击 +2；施加流血额外 +1 层"},
	"healing_lantern": {"name": "引魂灯", "kind": "equipment", "role": "all", "heal_bonus": 3, "cleanse_shield": 5, "desc": "治疗 +3；净化队友时额外提供 5 护盾"},
	"mirror_blade": {"name": "镜裂双刃", "kind": "equipment", "role": "all", "atk": 3, "low_hp_damage_bonus": 0.15, "on_kill_restore_stamina": 1, "desc": "攻击 +3；低生命时伤害 +15%，击杀回复 1 体力"},
	"star_compass": {"name": "星轨罗盘", "kind": "equipment", "role": "all", "mana": 3, "support_refund_mana": 1, "spell_damage_bonus": 0.15, "desc": "魔力上限 +3；支援返还 1 魔力，魔力攻击伤害 +15%"},
	"forge_gauntlet": {"name": "锻梦护手", "kind": "equipment", "role": "all", "hp": 8, "shield_gain_bonus": 5, "character_bonuses": {"dreamsmith": {"atk": 2}}, "desc": "生命上限 +8；获得护盾时额外 +5，铸梦工匠装备时攻击再 +2"},
	"ink_collar": {"name": "墨印项圈", "kind": "equipment", "role": "all", "mana": 3, "item_power": 2, "spell_damage_bonus": 0.12, "character_bonuses": {"veil_scribe": {"spell_damage_bonus": 0.18}}, "desc": "魔力上限 +3、消耗品效果 +2；帷幕书记装备时魔力攻击进一步强化"},
	"oracle_lens": {"name": "星镜棱片", "kind": "equipment", "role": "all", "hp": 4, "mana": 2, "heal_bonus": 2, "character_bonuses": {"oracle": {"support_refund_mana": 1}}, "desc": "生命上限 +4、魔力上限 +2、治疗 +2；星痕先知装备时支援效率提升"},
	"resonant_core": {"name": "共鸣核心", "kind": "equipment", "role": "all", "hp": 5, "start_shield": 5, "resource_bonus": 2, "character_bonuses": {"channeler": {"resource_bonus": 2}}, "desc": "生命上限 +5、开战护盾 +5、资源回复 +2；灵脉乐师装备时再强化"},
}

const REWARD_ITEM_POOL := [
	"potion_small", "potion_big", "stamina_tonic", "mana_tonic",
	"scroll", "bleed_needle", "thunder_rune", "ward_orb",
	"cleansing_incense", "dream_bomb",
	"rage_blade", "moon_staff", "shadow_bow",
	"ward_cloak", "iron_armor", "dreamweave_robe",
	"rage_charm", "echo_ring", "guardian_badge", "traveler_boots",
	"blood_contract", "healing_lantern", "mirror_blade", "star_compass",
	"forge_gauntlet", "ink_collar", "oracle_lens", "resonant_core",
]

## 奖励节点的梦境叙事外壳。具体三选一奖励仍按节点强度生成。
const REWARD_EVENTS := [
	{
		"title": "梦匣回廊",
		"text": "三只梦匣中，只能带走一份。",
		"choice_prefix": "选择",
	},
	{
		"title": "被遗忘的祭台",
		"text": "祭台浮现三份赐福。",
		"choice_prefix": "选择",
	},
	{
		"title": "梦魂的谢礼",
		"text": "梦魂留下三段力量。",
		"choice_prefix": "选择",
	},
	{
		"title": "漂浮宝库",
		"text": "宝库中只能取走一件物品。",
		"choice_prefix": "选择",
	},
	{
		"title": "六芒熔炉",
		"text": "熔炉只为真正理解队伍联动的人点火。每一件材料都记录着一名入梦师的成长方向。",
		"choice_prefix": "锻造突破",
	},
	{
		"title": "星海回收舱",
		"text": "回收舱从深层梦海打捞出几件失落装备，舱门只会开启一次。",
		"choice_prefix": "拆封回收",
	},
]

## 招募节点的叙事模板。每次进入仍重新随机抽取最多 4 名未入队候选。
const RECRUIT_EVENTS := [
	{
		"title": "锚定新的入梦师",
		"text": "选择一名入梦师加入队伍。",
	},
	{
		"title": "回声信标",
		"text": "信标只能连接一名入梦师。",
	},
	{
		"title": "共享梦境",
		"text": "招募新成员，或培养已有成员。",
	},
	{
		"title": "梦魂接驳站",
		"text": "这里是不同梦层短暂重叠的接驳站。本批候选不会停留太久，请决定要锚定谁。",
	},
	{
		"title": "六席回声厅",
		"text": "六个席位同时亮起，前台与后台各有三道稳定光环。队伍编制已扩展，但每个位置仍需谨慎安排。",
	},
	{
		"title": "突破观测台",
		"text": "观测台记录着角色越过 Lv.3 后的极限。高阶招募可以直接把新成员培养到突破阶段。",
	},
]

## 奇遇事件：每次只经历一个事件；选项可能带来奖励、战斗、卡牌或负面效果。
const EVENTS := [
	{
		"id": "lost_caravan",
		"title": "迷途商队",
		"text": "一支被梦雾困住的商队停在路边，封闭的货箱里传来轻微响动。",
		"choices": [
			{"text": "保持距离，离开商队", "result_text": "你没有卷入商队的麻烦。", "effect": {}},
			{"text": "打开一只封闭货箱", "outcomes": [
				{"weight": 40, "text": "货箱里装满补给，你获得浓缩梦露与 15 金币。", "effect": {"item": "potion_big", "gold": 15}},
				{"weight": 35, "text": "货箱里藏着一张指向安全梦层的路线图，你获得良性节点卡。", "effect": {"random_beneficial_node_card": true}},
				{"weight": 25, "text": "货箱是心魔的诱饵，嫉妒从阴影中现身！", "effect": {"battle": "archer", "battle_level": 1}}
			]},
			{"text": "【回声指环】聆听箱内回声，挑出真正的宝箱", "condition": {"type": "equipment", "key": "echo_ring"}, "result_text": "回声指环帮你避开陷阱。你获得 35 金币和一张 Lv.2 奖励节点卡。", "effect": {"gold": 35, "node_card": {"type": "reward", "level": 2}}},
		],
	},
	{
		"id": "cracked_mirror_hall",
		"title": "裂纹镜厅",
		"text": "镜中倒影做出了与你不同的动作，几面镜子同时伸出手。",
		"choices": [
			{"text": "不触碰镜面，沿墙离开", "result_text": "你避开了镜厅，没有任何事情发生。", "effect": {}},
			{"text": "触碰其中一面镜子", "outcomes": [
				{"weight": 40, "text": "倒影将力量交还给你，攻击 +3。", "effect": {"atk": 3}},
				{"weight": 30, "text": "镜面碎裂，你被割伤并获得 3 层流血。", "effect": {"hp_cost": 8, "bleed": 3}},
				{"weight": 30, "text": "傲慢从镜后跨出，战斗开始！", "effect": {"battle": "golem", "battle_level": 1}}
			]},
			{"text": "【织梦术士】识破真镜，取走镜中的法术", "condition": {"type": "character", "key": "mage"}, "result_text": "术士锁定了安全的真镜，你获得梦火卷轴和 Lv.2 奖励节点卡。", "effect": {"item": "scroll", "node_card": {"type": "reward", "level": 2}}},
		],
	},
	{
		"id": "dream_orchard",
		"title": "梦果园",
		"text": "树上结着颜色各异的梦果。普通人很难判断哪一颗已经成熟。",
		"choices": [
			{"text": "不冒险，离开果园", "result_text": "你没有采摘陌生的果实。", "effect": {}},
			{"text": "摘下一颗梦果品尝", "outcomes": [
				{"weight": 45, "text": "果实甘甜而温暖。生命上限 +5，并获得 12 点探索经验。", "effect": {"max_hp_delta": 5, "exploration_xp": 12}},
				{"weight": 35, "text": "果实味道普通，但果核可以制成净心香。", "effect": {"item": "cleansing_incense"}},
				{"weight": 20, "text": "果实尚未成熟，苦涩汁液侵入血液。你失去 10 点生命并获得 4 层流血。", "effect": {"hp_cost": 10, "bleed": 4}}
			]},
			{"text": "【逐影猎手】辨认果实品质，摘取成熟梦果", "condition": {"type": "character", "key": "ranger"}, "result_text": "猎手根据气味与虫痕找到了最成熟的果实。生命上限 +6，并获得 18 点探索经验。", "effect": {"max_hp_delta": 6, "exploration_xp": 18}},
		],
	},
	{
		"id": "echo_library",
		"title": "回声图书馆",
		"text": "书页会自动翻动，但其中一些文字被心魔篡改。",
		"choices": [
			{"text": "合上书本，离开图书馆", "result_text": "你没有阅读来历不明的文字。", "effect": {}},
			{"text": "随机抽取一本书阅读", "outcomes": [
				{"weight": 40, "text": "你读到了一篇实用战术，攻击 +2。", "effect": {"atk": 2}},
				{"weight": 35, "text": "书页化为梦火卷轴和一张良性节点卡。", "effect": {"item": "scroll", "random_beneficial_node_card": true, "node_card_max_level": 2}},
				{"weight": 25, "text": "禁书抽走了你的精神，失去 3 点魔力并晕眩 1 回合。", "effect": {"mana_cost": 3, "stun": 1}}
			]},
			{"text": "【织梦术士或回声指环】校正被篡改的目录", "condition": {"type": "any", "conditions": [{"type": "character", "key": "mage"}, {"type": "equipment", "key": "echo_ring"}]}, "result_text": "你找到了真正的秘典，获得月纹法杖。", "effect": {"item": "moon_staff"}},
		],
	},
	{
		"id": "nameless_gatekeeper",
		"title": "无名守门人",
		"text": "守门人挡住去路，要求你证明勇气，但没有说明试炼内容。",
		"choices": [
			{"text": "拒绝试炼，原路离开", "result_text": "守门人没有追赶你。", "effect": {}},
			{"text": "接受未知试炼", "outcomes": [
				{"weight": 35, "text": "守门人认可了你的勇气，赠予 30 金币。", "effect": {"gold": 30}},
				{"weight": 30, "text": "试炼要求承受梦压。你失去 10 点生命，但体力上限 +1。", "effect": {"hp_cost": 10, "reward": {"type": "max_stamina", "amount": 1}}},
				{"weight": 35, "text": "守门人的影子化为贪婪精英，战斗开始！", "effect": {"battle": "knight", "battle_level": 1}}
			]},
			{"text": "【镇魇武者或镇魇重甲】正面承受试炼", "condition": {"type": "any", "conditions": [{"type": "character", "key": "warrior"}, {"type": "equipment", "key": "iron_armor"}]}, "result_text": "你稳稳承受住梦压，生命上限 +6，攻击 +2。", "effect": {"max_hp_delta": 6, "atk": 2}},
		],
	},
	{
		"id": "forgotten_station",
		"title": "遗忘车站",
		"text": "月台没有时钟，列车广播却反复念出队伍成员早已忘记的名字。远处列车亮起一盏苍白车灯。",
		"choices": [
			{"text": "离开月台，不回应广播", "result_text": "广播声逐渐远去，但你隐约觉得漏掉了一段重要记忆。", "effect": {}},
			{"text": "沿铁轨寻找名字的主人", "outcomes": [
				{"weight": 40, "text": "你在枕木下找到一段被封存的记忆。获得 2 枚记忆残片。", "effect": {"memory": 2, "set_flag": "heard_last_train"}},
				{"weight": 30, "text": "轨道延伸进更深层梦境。梦蚀 +2，并获得稀有奖励节点卡。", "effect": {"dream_corruption": 2, "node_card": {"type": "reward", "level": 2}, "set_flag": "heard_last_train"}},
				{"weight": 30, "text": "检票员撕下面孔，化作梦魇拦住归路！", "effect": {"battle": "sentinel", "battle_level": 2, "encounter_type": "nightmare", "memory": 1, "set_flag": "heard_last_train"}}
			]},
			{"text": "【灵脉乐师】循广播的回声找到安全记忆", "condition": {"type": "character", "key": "channeler"}, "result_text": "乐师复原了名字原本的旋律。获得 3 枚记忆残片，并清除 1 点梦蚀。", "effect": {"memory": 3, "dream_corruption": -1, "set_flag": "heard_last_train"}},
		],
	},
	{
		"id": "last_train",
		"title": "驶向无名之梦的列车",
		"text": "那辆列车终于进站。车窗里坐着无数个没有面孔的你，终点站写着“醒来之前”。",
		"followup": true,
		"requires": {"type": "flag", "key": "heard_last_train"},
		"choices": [
			{"text": "不登车，烧掉手中的车票", "result_text": "列车带走了错误的记忆。梦蚀 -2。", "effect": {"dream_corruption": -2, "clear_flag": "heard_last_train", "set_flag": "refused_last_train"}},
			{"text": "支付 2 枚记忆残片，寻找真实车厢", "condition": {"type": "memory_min", "amount": 2}, "outcomes": [
				{"weight": 55, "text": "你找到仍保留姓名的车厢。攻击 +3，并锚定一名待救援的入梦师。获得 Lv.2 招募节点卡。", "effect": {"memory_cost": 2, "atk": 3, "node_card": {"type": "recruit", "level": 2}, "clear_flag": "heard_last_train"}},
				{"weight": 45, "text": "车厢尽头是吞噬记忆的列车长。击败它才能下车！", "effect": {"memory_cost": 2, "battle": "knight", "battle_level": 2, "encounter_type": "nightmare", "clear_flag": "heard_last_train"}}
			]},
			{"text": "【梦盾守卫】挡住车门，强行救出被困梦魂", "condition": {"type": "character", "key": "guardian"}, "result_text": "守卫承受住列车的梦压。全队生命上限 +4，获得 35 金币。", "effect": {"party_max_hp_delta": 4, "gold": 35, "clear_flag": "heard_last_train"}},
		],
	},
	{
		"id": "sleeping_theater",
		"title": "沉睡剧院",
		"text": "舞台正在重演一位梦魂最痛苦的记忆。台下观众全都戴着与你相同的面具。",
		"choices": [
			{"text": "在谢幕前离开剧院", "result_text": "你拒绝成为记忆的一部分。", "effect": {}},
			{"text": "戴上面具，代替梦魂完成演出", "outcomes": [
				{"weight": 35, "text": "你为梦魂改写了结局。获得 2 枚记忆残片，生命上限 +4。", "effect": {"memory": 2, "max_hp_delta": 4}},
				{"weight": 35, "text": "观众承认了你的表演，向台上投来金币和装备。", "effect": {"gold": 30, "item": "guardian_badge"}},
				{"weight": 30, "text": "你忘记了自己只是演员。梦蚀 +3，嫉妒与疑惧同时登台！", "effect": {"dream_corruption": 3, "battle": "spider", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【血梦刺客】从幕布后杀死操纵剧目的梦魇", "condition": {"type": "character", "key": "assassin"}, "result_text": "刺客切断了连接观众与舞台的血线。攻击 +3，获得猩红梦针。", "effect": {"atk": 3, "item": "bleed_needle"}},
		],
	},
	{
		"id": "inverted_ward",
		"title": "倒悬病房",
		"text": "病床固定在天花板上，心电图记录的是梦境本身的脉搏。每当警报响起，队伍的影子就少一个。",
		"choices": [
			{"text": "关闭病房电源，立即离开", "result_text": "警报停止了，病房重新沉入黑暗。", "effect": {}},
			{"text": "读取一份没有姓名的病例", "outcomes": [
				{"weight": 40, "text": "病例记录了心魔的弱点。获得 2 枚记忆残片，攻击 +2。", "effect": {"memory": 2, "atk": 2}},
				{"weight": 30, "text": "病例属于队伍中的某个未来版本。梦蚀 +2，生命上限 +6。", "effect": {"dream_corruption": 2, "max_hp_delta": 6}},
				{"weight": 30, "text": "病床上的影子睁开眼睛，梦魇战斗开始！", "effect": {"battle": "spider", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【梦药炼金师】分析输液中的梦蚀成分", "condition": {"type": "character", "key": "alchemist"}, "result_text": "炼金师调配出稳定药剂。梦蚀 -2，获得万用灵药对应的净心香与浓缩梦露。", "effect": {"dream_corruption": -2, "item": "cleansing_incense", "gold": 15}},
		],
	},
	{
		"id": "deep_dream_well",
		"title": "层叠梦井",
		"text": "井水倒映出更深一层梦境。越靠近井口，周围时间越慢，远处心魔的脚步却越来越快。",
		"requires": {"type": "pressure_min", "amount": 1},
		"choices": [
			{"text": "封住井口，拒绝继续下潜", "result_text": "你用现实中的记忆固定了这一层梦境。梦蚀 -1。", "effect": {"dream_corruption": -1}},
			{"text": "投入一段记忆，观察井底回应", "condition": {"type": "memory_min", "amount": 1}, "outcomes": [
				{"weight": 45, "text": "井底浮出一件被遗忘的装备。", "effect": {"memory_cost": 1, "item": "echo_ring"}},
				{"weight": 30, "text": "更深层的你回应了呼唤。节点卡组获得 Lv.2 奖励卡。", "effect": {"memory_cost": 1, "node_card": {"type": "reward", "level": 2}}},
				{"weight": 25, "text": "井中倒影试图取代你。梦蚀 +2，梦魇战斗开始！", "effect": {"memory_cost": 1, "dream_corruption": 2, "battle": "golem", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【织梦术士】稳定梦层后主动下潜", "condition": {"type": "character", "key": "mage"}, "result_text": "术士在梦层坍塌前带回了珍贵回声。魔力上限 +2、获得 2 枚记忆残片和 Lv.3 奖励节点卡。", "effect": {"reward": {"type": "max_mana", "amount": 2}, "memory": 2, "node_card": {"type": "reward", "level": 3}}},
		],
	},
	{
		"id": "false_awakening_room",
		"title": "伪醒公寓",
		"text": "你在熟悉的房间中睁开眼，窗外却仍是梦境。每次推开卧室门，都会回到同一张床上。",
		"requires": {"type": "corruption_min", "amount": 3},
		"choices": [
			{"text": "停止挣扎，在房间里等待梦境松动", "result_text": "循环逐渐变慢。梦蚀 -1，但你失去了继续搜索的机会。", "effect": {"dream_corruption": -1}},
			{"text": "不断尝试不同的醒来方式", "outcomes": [
				{"weight": 35, "text": "你找到一处逻辑裂缝并逃出循环。梦蚀 -3，获得 2 枚记忆残片。", "effect": {"dream_corruption": -3, "memory": 2}},
				{"weight": 35, "text": "你在循环中锻炼出辨识梦境的能力。生命上限 +8，但梦蚀 +1。", "effect": {"max_hp_delta": 8, "dream_corruption": 1}},
				{"weight": 30, "text": "床下爬出一个声称自己才是真实的你。梦魇战斗开始！", "effect": {"battle": "golem", "battle_level": 2, "encounter_type": "nightmare", "dream_corruption": 1}}
			]},
			{"text": "【回声指环或灵脉乐师】用稳定节奏验证现实", "condition": {"type": "any", "conditions": [{"type": "equipment", "key": "echo_ring"}, {"type": "character", "key": "channeler"}]}, "result_text": "稳定的回声打破了伪醒循环。梦蚀 -3，魔力上限 +1。", "effect": {"dream_corruption": -3, "reward": {"type": "max_mana", "amount": 1}}},
		],
	},
	{
		"id": "memory_auction",
		"title": "记忆拍卖会",
		"text": "无脸宾客用童年、姓名和遗憾竞拍梦中遗物。拍卖师宣布：这里只接受真正属于你的记忆。",
		"requires": {"type": "memory_min", "amount": 2},
		"choices": [
			{"text": "旁观拍卖，不交出任何记忆", "result_text": "你记住了几件遗物的去向，但没有参与竞价。", "effect": {}},
			{"text": "交出 2 枚记忆残片参与盲拍", "condition": {"type": "memory_min", "amount": 2}, "outcomes": [
				{"weight": 40, "text": "你拍得一件守梦遗物。", "effect": {"memory_cost": 2, "item": "guardian_badge"}},
				{"weight": 35, "text": "你拍得一枚稳定的意识锚点。获得 35 金币和 Lv.2 招募节点卡。", "effect": {"memory_cost": 2, "gold": 35, "node_card": {"type": "recruit", "level": 2}}},
				{"weight": 25, "text": "拍卖品里封着贪婪心魔。击败它才能取回记忆！", "effect": {"memory_cost": 2, "battle": "knight", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【梦药炼金师】鉴定赝品，只竞拍真实遗物", "condition": {"type": "character", "key": "alchemist"}, "result_text": "炼金师识破了记忆赝品。消耗 1 枚记忆残片，获得回声指环和 Lv.3 招募节点卡。", "effect": {"memory_cost": 1, "item": "echo_ring", "node_card": {"type": "recruit", "level": 3}}},
		],
	},
	{
		"id": "six_seat_archive",
		"title": "六席档案馆",
		"text": "档案馆为每一名入梦师保留一页未来记录。六席全部点亮时，书架会显露真正的成长路线。",
		"choices": [
			{"text": "只读取自己的档案", "outcomes": [
				{"weight": 45, "text": "你找到了可执行的战术。攻击 +2，获得 15 点探索经验。", "effect": {"atk": 2, "exploration_xp": 15}},
				{"weight": 30, "text": "档案中的警告成真。梦蚀 +1，但获得 2 枚记忆残片。", "effect": {"dream_corruption": 1, "memory": 2}},
				{"weight": 25, "text": "书架后传出翻页声，缝梦医师与守梦傀儡同时苏醒！", "effect": {"battle": "mender", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【铸梦工匠】修复六席档案的断页", "condition": {"type": "character", "key": "dreamsmith"}, "result_text": "工匠补齐了断页。获得锻梦护手与 Lv.3 招募节点卡。", "effect": {"item": "forge_gauntlet", "node_card": {"type": "recruit", "level": 3}}},
			{"text": "【星痕先知】读取所有人的未来分支", "condition": {"type": "character", "key": "oracle"}, "result_text": "先知看见了队伍的共同终点。全队生命上限 +3，获得 2 枚记忆残片。", "effect": {"party_max_hp_delta": 3, "memory": 2}},
		],
	},
	{
		"id": "star_observatory",
		"title": "坠星观测台",
		"text": "观测台把每一场战斗记录成星图。只要校准正确，下一次突破就不会迷失。",
		"choices": [
			{"text": "校准最亮的星", "outcomes": [
				{"weight": 40, "text": "星图落入掌心。魔力上限 +2，获得 18 点探索经验。", "effect": {"reward": {"type": "max_mana", "amount": 2}, "exploration_xp": 18}},
				{"weight": 35, "text": "星光反射出装备轮廓。获得星轨罗盘。", "effect": {"item": "star_compass"}},
				{"weight": 25, "text": "观测镜里出现陌生的自己。梦蚀 +2，梦魇战斗开始！", "effect": {"dream_corruption": 2, "battle": "golem", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【星痕先知】预读星图的坠落轨迹", "condition": {"type": "character", "key": "oracle"}, "result_text": "先知提前看见了安全窗口。全队魔力上限 +1，并获得 Lv.2 奖励节点卡。", "effect": {"party_max_mana_delta": 1, "node_card": {"type": "reward", "level": 2}}},
			{"text": "【星轨罗盘】锁定不会坠落的坐标", "condition": {"type": "equipment", "key": "star_compass"}, "result_text": "罗盘指向稳定星门。梦蚀 -2，获得 30 金币。", "effect": {"dream_corruption": -2, "gold": 30}},
		],
	},
	{
		"id": "ink_archive",
		"title": "黑墨禁库",
		"text": "禁库中的文字会主动寻找读者。越是想理解它，越容易成为下一页的内容。",
		"choices": [
			{"text": "封存禁库，立即离开", "result_text": "你把危险知识留在了梦里。", "effect": {"dream_corruption": -1}},
			{"text": "撕下一页黑墨", "outcomes": [
				{"weight": 40, "text": "黑墨凝成一枚消耗品。获得净心香与 10 金币。", "effect": {"item": "cleansing_incense", "gold": 10}},
				{"weight": 35, "text": "文字灼伤了你的意识。失去 8 点生命，但获得 Lv.2 奖励节点卡。", "effect": {"hp_cost": 8, "node_card": {"type": "reward", "level": 2}}},
				{"weight": 25, "text": "黑墨聚成帷幕，梦魇战斗开始！", "effect": {"battle": "spider", "battle_level": 2, "encounter_type": "nightmare"}}
			]},
			{"text": "【帷幕书记】重写禁库索引", "condition": {"type": "character", "key": "veil_scribe"}, "result_text": "书记将危险段落改写成可控咒式。获得墨印项圈与 2 枚记忆残片。", "effect": {"item": "ink_collar", "memory": 2}},
		],
	},
	{
		"id": "breakthrough_gate",
		"title": "越界之门",
		"text": "门上刻着 Lv.3 之后的空白等级。只有承受过梦压的人，才能看见门后的 MAX。",
		"requires": {"type": "pressure_min", "amount": 2},
		"choices": [
			{"text": "触摸空白等级", "outcomes": [
				{"weight": 40, "text": "门后传来新的战斗节奏。获得 Lv.3 招募节点卡。", "effect": {"node_card": {"type": "recruit", "level": 3}}},
				{"weight": 35, "text": "你的极限被重新定义。攻击 +4、生命上限 +8。", "effect": {"atk": 4, "max_hp_delta": 8}},
				{"weight": 25, "text": "门后是守着 MAX 的虚无投影！", "effect": {"battle": "boss", "battle_level": 3, "encounter_type": "nightmare"}}
			]},
			{"text": "【铸梦工匠或星痕先知】校准突破门", "condition": {"type": "any", "conditions": [{"type": "character", "key": "dreamsmith"}, {"type": "character", "key": "oracle"}]}, "result_text": "队伍看见了共同的终点。全队生命上限 +5，获得 Lv.3 奖励节点卡。", "effect": {"party_max_hp_delta": 5, "node_card": {"type": "reward", "level": 3}}},
		],
	},
]

## 商店货物：战斗结束后会完全整备，因此商店不再售卖局外即时回血。
const SHOP_OFFERS := [
	{"name": "微光药剂", "cost": 8, "item": "potion_small"},
	{"name": "浓缩梦露", "cost": 15, "item": "potion_big"},
	{"name": "醒神茶", "cost": 12, "item": "stamina_tonic"},
	{"name": "星辉墨水", "cost": 12, "item": "mana_tonic"},
	{"name": "猩红梦针", "cost": 16, "item": "bleed_needle"},
	{"name": "守梦晶球", "cost": 18, "item": "ward_orb"},
	{"name": "怒痕长刃", "cost": 34, "item": "rage_blade"},
	{"name": "护梦披风", "cost": 32, "item": "ward_cloak"},
	{"name": "回声指环", "cost": 36, "item": "echo_ring"},
	{"name": "锻梦护手", "cost": 42, "item": "forge_gauntlet"},
	{"name": "墨印项圈", "cost": 40, "item": "ink_collar"},
	{"name": "星镜棱片", "cost": 42, "item": "oracle_lens"},
	{"name": "共鸣核心", "cost": 38, "item": "resonant_core"},
	{"name": "攻击 +1", "cost": 12, "atk": 1},
	{"name": "探索经验 +12", "cost": 14, "exploration_xp": 12},
	{"name": "奇遇节点卡 Lv.1", "cost": 10, "node_card": {"type": "event", "level": 1}},
	{"name": "突破训练", "cost": 45, "breakthrough": 1},
]
