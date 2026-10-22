extends Control
## 按比例缩放绘制一张贴图到自身矩形内（居中、保比例、不变形）。
## 用自定义 _draw 而非 TextureRect，是为了避开 TextureRect 的
## minimum_size 等于贴图原始尺寸（如角色 798x819）会把节点撑爆的问题。

var texture: Texture2D
var tint: Color = Color.WHITE


func _init(p_texture: Texture2D, p_rect: Rect2, p_tint: Color = Color.WHITE) -> void:
	texture = p_texture
	tint = p_tint
	position = p_rect.position
	size = p_rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	if texture == null:
		return
	var tex_size := texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	# 保比例缩放，并在矩形内居中
	var scale_factor := minf(size.x / tex_size.x, size.y / tex_size.y)
	var draw_size := tex_size * scale_factor
	var offset := (size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(offset, draw_size), false, tint)
