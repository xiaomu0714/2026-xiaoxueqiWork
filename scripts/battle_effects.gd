class_name BattleFx
extends RefCounted
## 纯代码战斗特效。当前仅保留仍在使用的「卡牌前冲回弹」；其余（飘字/闪白/震动）
## 已被 `_play_hit_vfx`（爆裂+伤害数字）/ `_play_float_vfx`（治疗/护盾贴图）取代，故移除。

const ENABLED := true   # 总开关：false 时全部调用变成空操作


## 卡牌前冲再回弹（攻击出手动作）
static func card_lunge(node: Control, dir: Vector2 = Vector2.ZERO) -> void:
	if not ENABLED or node == null:
		return
	var start := node.position
	var off := Vector2(26, 0) if dir == Vector2.ZERO else dir * 26
	var tween := node.create_tween()
	tween.tween_property(node, "position", start + off, 0.10).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", start, 0.16).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if is_instance_valid(node):
			node.position = start)
