extends Control
## 细条：数值填充 + 末端白色护盾尾（segs）。
## 生命条用：value=hp、max_value=max_hp、fill_color=绿色、shield=护盾值，
## 则绿色填生命、白条压在生命槽末端表示护盾；文字显示如 「28/28（12）」。
## 体力/魔力条直接用 shield=0 即可。

var value := 0.0
var max_value := 1.0
var fill_color := Color.WHITE
var shield := 0.0


func _init(p_value := 0.0, p_max := 1.0, p_color := Color.WHITE, p_shield := 0.0) -> void:
	value = p_value
	max_value = p_max
	fill_color = p_color
	shield = p_shield
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(p_value: float, p_max: float, p_color: Color, p_shield := 0.0) -> void:
	value = p_value
	max_value = p_max
	fill_color = p_color
	shield = p_shield
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# 底槽
	draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.05, 0.09, 0.95))
	var total := max_value + shield
	if total <= 0.0:
		return
	# 填充（生命/体力/魔力）
	var fw := clampf(w * (value / total), 0.0, w)
	draw_rect(Rect2(0, 0, fw, h), fill_color)
	# 护盾白色尾（压在最右端的生命槽后面）
	if shield > 0.0:
		var life_end := w * (max_value / total)
		var sw := w * (shield / total)
		life_end = clampf(life_end, 0.0, w)
		sw = minf(sw, w - life_end)
		draw_rect(Rect2(life_end, 0, sw, h), Color(0.95, 0.97, 1.0))
