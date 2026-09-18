extends RefCounted

static func glow(c: CanvasItem, p: Vector2, radius: float, color: Color) -> void:
	for i in range(12, 0, -1):
		var shade := color
		shade.a *= 0.035
		c.draw_circle(p, radius * i / 12.0, shade)

static func tree(c: CanvasItem, p: Vector2, scale: float, tint: Color) -> void:
	c.draw_line(p + Vector2(0, 8) * scale, p + Vector2(-2, -40) * scale, tint.darkened(0.35), 3 * scale)
	for i in range(3):
		var y := -12.0 - 13.0 * i
		var width := 20.0 - 4.0 * i
		var points := PackedVector2Array([p + Vector2(-width, y + 10) * scale, p + Vector2(-3, y - 22) * scale, p + Vector2(width * 0.8, y + 8) * scale, p + Vector2(1, y + 3) * scale])
		c.draw_colored_polygon(points, tint.lightened(i * 0.025))
		c.draw_polyline(PackedVector2Array([points[0], points[1], points[2]]), tint.lightened(0.10), 0.8, true)

static func person(c: CanvasItem, p: Vector2, scale: float, tint: Color, role: String, fallen := false) -> void:
	var shadow := Rect2(p + Vector2(-25, -4) * scale, Vector2(50, 12) * scale)
	ellipse(c, shadow, Color(0, 0, 0, 0.34))
	if fallen:
		c.draw_line(p + Vector2(-20, -8) * scale, p + Vector2(20, -5) * scale, tint.darkened(0.5), 12 * scale)
		return
	var cloak := PackedVector2Array([p + Vector2(-11, -62) * scale, p + Vector2(10, -62) * scale, p + Vector2(24, -5) * scale, p + Vector2(-23, -7) * scale])
	c.draw_colored_polygon(cloak, tint.darkened(0.60))
	c.draw_colored_polygon(PackedVector2Array([cloak[0], cloak[1], p + Vector2(6, -6) * scale, p + Vector2(-15, -7) * scale]), tint.darkened(0.24))
	c.draw_line(p + Vector2(-8, -8) * scale, p + Vector2(-10, 0) * scale, Color("242822"), 6 * scale)
	c.draw_line(p + Vector2(9, -8) * scale, p + Vector2(13, 0) * scale, Color("242822"), 6 * scale)
	c.draw_circle(p + Vector2(0, -72) * scale, 10 * scale, Color("b3a087"))
	c.draw_arc(p + Vector2(0, -73) * scale, 11 * scale, PI, TAU, 10, tint.darkened(0.45), 6 * scale, true)
	c.draw_line(p + Vector2(-10, -40) * scale, p + Vector2(12, -38) * scale, Color("b29a67"), 3 * scale)
	if role == "ivar":
		c.draw_line(p + Vector2(18, -25) * scale, p + Vector2(25, -84) * scale, Color("a6aaa0"), 4 * scale)
		c.draw_line(p + Vector2(13, -29) * scale, p + Vector2(28, -27) * scale, Color("b99b62"), 3 * scale)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-30, -49) * scale, p + Vector2(-13, -52) * scale, p + Vector2(-14, -28) * scale, p + Vector2(-23, -22) * scale, p + Vector2(-31, -32) * scale]), tint.darkened(0.2))
	elif role == "mira":
		c.draw_line(p + Vector2(23, 0) * scale, p + Vector2(21, -84) * scale, Color("71634c"), 3 * scale)
		glow(c, p + Vector2(21, -85) * scale, 22 * scale, Color("78bdc8"))
		c.draw_circle(p + Vector2(21, -85) * scale, 4 * scale, Color("b6e0df"))
	else:
		glow(c, p + Vector2(-20, -40) * scale, 22 * scale, Color("eac27f"))
		c.draw_rect(Rect2(p + Vector2(-25, -45) * scale, Vector2(10, 14) * scale), Color("d9b579"))
	c.draw_line(p + Vector2(0, -58) * scale, p + Vector2(-5, -15) * scale, tint.lightened(0.10), 1.2 * scale, true)

static func monster(c: CanvasItem, p: Vector2, scale: float, tint: Color, variant: int, fallen := false) -> void:
	ellipse(c, Rect2(p + Vector2(-35, -4) * scale, Vector2(70, 15) * scale), Color(0, 0, 0, 0.4))
	if fallen:
		c.draw_line(p + Vector2(-23, -7) * scale, p + Vector2(23, -9) * scale, tint.darkened(0.4), 10 * scale)
		return
	var body := PackedVector2Array([p + Vector2(-12, -73) * scale, p + Vector2(14, -67) * scale, p + Vector2(24, -21) * scale, p + Vector2(8, -9) * scale, p + Vector2(-22, -16) * scale])
	c.draw_colored_polygon(body, tint.darkened(0.5))
	c.draw_polyline(body, tint.darkened(0.10), 2 * scale, true)
	for side in [-1, 1]:
		c.draw_polyline(PackedVector2Array([p + Vector2(12 * side, -17) * scale, p + Vector2(17 * side, -6) * scale, p + Vector2(28 * side, 0) * scale]), tint, 4 * scale, true)
		c.draw_polyline(PackedVector2Array([p + Vector2(10 * side, -59) * scale, p + Vector2(31 * side, -40) * scale, p + Vector2(39 * side, -18) * scale]), tint.darkened(0.12), 4 * scale, true)
	c.draw_circle(p + Vector2(0, -83) * scale, 11 * scale, tint)
	for side in [-1, 1]:
		c.draw_line(p + Vector2(5 * side, -91) * scale, p + Vector2(15 * side, -111 - variant * 7) * scale, tint.darkened(0.1), 3 * scale, true)
		c.draw_circle(p + Vector2(4 * side, -84) * scale, 2 * scale, Color("ffca84"))
	for i in range(4):
		c.draw_line(p + Vector2(-10, -60 + i * 7) * scale, p + Vector2(10, -56 + i * 7) * scale, tint, 1.5 * scale, true)

static func camp(c: CanvasItem, p: Vector2, scale: float) -> void:
	glow(c, p, 55 * scale, Color("e7ae57"))
	c.draw_line(p + Vector2(-13, 5) * scale, p + Vector2(13, -1) * scale, Color("786045"), 4 * scale)
	c.draw_line(p + Vector2(-11, -1) * scale, p + Vector2(11, 6) * scale, Color("786045"), 4 * scale)
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 1) * scale, p + Vector2(-4, -14) * scale, p + Vector2(2, -25) * scale, p + Vector2(3, -10) * scale, p + Vector2(9, 1) * scale]), Color("db984b"))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 2) * scale, p + Vector2(2, -14) * scale, p + Vector2(5, 2) * scale]), Color("f4d998"))

static func ellipse(c: CanvasItem, rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		points.append(rect.get_center() + Vector2(cos(i * TAU / 32), sin(i * TAU / 32)) * rect.size / 2)
	c.draw_colored_polygon(points, color)

static func ruin(c: CanvasItem, p: Vector2, scale: float, chapel := false) -> void:
	var stone := Color("414943")
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-30, 0) * scale, p + Vector2(-30, -45) * scale, p + Vector2(-7, -57) * scale, p + Vector2(3, -45) * scale, p + Vector2(27, -43) * scale, p + Vector2(30, 0) * scale]), stone)
	c.draw_rect(Rect2(p + Vector2(-12, -28) * scale, Vector2(21, 28) * scale), Color("161e1c"))
	c.draw_arc(p + Vector2(-1, -28) * scale, 11 * scale, PI, TAU, 16, stone.lightened(0.16), 4 * scale, true)
	for i in range(3):
		c.draw_line(p + Vector2(-27, -7 - 13 * i) * scale, p + Vector2(-14, -7 - 13 * i) * scale, stone.lightened(0.12), 1, true)
	if chapel:
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-40, -44) * scale, p + Vector2(0, -82) * scale, p + Vector2(39, -44) * scale]), Color("303d3a"))
		c.draw_line(p + Vector2(0, -78) * scale, p + Vector2(0, -99) * scale, Color("8a8a6c"), 2 * scale)
		c.draw_line(p + Vector2(-7, -91) * scale, p + Vector2(7, -91) * scale, Color("8a8a6c"), 2 * scale)
