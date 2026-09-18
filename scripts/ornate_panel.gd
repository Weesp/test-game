extends PanelContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.052, 0.057, 0.047, 0.97)
	skin.border_color = Color("7d7252")
	skin.set_border_width_all(1)
	skin.shadow_color = Color(0, 0, 0, 0.6)
	skin.shadow_size = 24
	skin.set_content_margin_all(26)
	add_theme_stylebox_override("panel", skin)
	resized.connect(queue_redraw)

func _draw() -> void:
	var gold := Color("9a8960")
	draw_rect(Rect2(Vector2(7, 7), size - Vector2(14, 14)), Color(0.48, 0.43, 0.3, 0.3), false, 1)
	for p in [Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), size]:
		var dx := 1.0 if p.x == 0 else -1.0
		var dy := 1.0 if p.y == 0 else -1.0
		draw_polyline(PackedVector2Array([p + Vector2(0, 22 * dy), p, p + Vector2(22 * dx, 0)]), gold, 2, true)
		var center: Vector2 = p + Vector2(7 * dx, 7 * dy)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -3), center + Vector2(3, 0), center + Vector2(0, 3), center + Vector2(-3, 0)]), gold)
	var mid := size.x / 2
	draw_polyline(PackedVector2Array([Vector2(mid - 18, 0), Vector2(mid, 7), Vector2(mid + 18, 0)]), gold, 1, true)
