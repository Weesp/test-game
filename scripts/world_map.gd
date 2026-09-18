extends Control

signal location_selected(id: String)
const World = preload("res://scripts/world_data.gd")
const Art = preload("res://scripts/ink_art.gd")
var game
var selected := "camp"
var hover_id := ""
var marker := Vector2(140, 520)
var animating := false
var move_tween: Tween

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): hover_id = ""; queue_redraw())

func set_location(id: String, animate := true) -> void:
	var destination: Vector2 = World.NODES[id].pos
	if move_tween:
		move_tween.kill()
	if animate:
		animating = true
		move_tween = create_tween()
		move_tween.tween_method(func(p): marker = p; queue_redraw(), marker, destination, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		move_tween.tween_callback(func(): animating = false)
	else:
		marker = destination
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var p: Vector2 = event.position / (size / Vector2(960, 650))
		var found := ""
		for id in World.NODES:
			if p.distance_to(World.NODES[id].pos) < 28:
				found = id
				break
		if hover_id != found:
			hover_id = found
			queue_redraw()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not found.is_empty():
			selected = found
			location_selected.emit(found)
			queue_redraw()

func _draw() -> void:
	if game == null:
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(960, 650))
	draw_rect(Rect2(0, 0, 960, 650), Color("141f1e"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4031
	for i in range(60):
		var p := Vector2(rng.randf_range(0, 960), rng.randf_range(0, 650))
		var col := Color("293c33") if i % 2 == 0 else Color("405044")
		col.a = 0.025
		Art.glow(self, p, rng.randf_range(60, 200), col * Color(1, 1, 1, 12))
	var river := PackedVector2Array([Vector2(362, 0), Vector2(413, 92), Vector2(392, 200), Vector2(420, 302), Vector2(361, 386), Vector2(396, 493), Vector2(363, 650), Vector2(451, 650), Vector2(475, 498), Vector2(433, 385), Vector2(497, 304), Vector2(476, 199), Vector2(492, 96), Vector2(441, 0)])
	draw_colored_polygon(river, Color("111c20"))
	for i in range(75):
		var y := rng.randf_range(0, 650)
		var x := 426 + sin(y / 63) * 23
		draw_line(Vector2(x - rng.randf_range(5, 30), y), Vector2(x + rng.randf_range(4, 22), y - 2), Color(0.3, 0.43, 0.44, 0.13), 1, true)
	for edge in World.EDGES:
		var a: Vector2 = World.NODES[edge[0]].pos
		var b: Vector2 = World.NODES[edge[1]].pos
		var accessible: bool = game.data.location in edge
		var path := _curve(a, b)
		draw_polyline(path, Color(0.05, 0.07, 0.06, 0.65), 9, true)
		draw_polyline(path, Color("8c825a") if accessible else Color("50574a"), 1.8 if accessible else 1.1, true)
	for i in range(190):
		var p := Vector2(rng.randf_range(20, 935), rng.randf_range(35, 650))
		var near := false
		for node in World.NODES.values():
			if p.distance_to(node.pos) < 68:
				near = true
		if not near and (p.x < 345 or p.x > 505):
			Art.tree(self, p, rng.randf_range(0.65, 1.35), Color("202c26").lightened(rng.randf_range(0, 0.065)))
	# Weathered planks along the crossing.
	for i in range(11):
		var x := 395.0 + i * 8
		draw_line(Vector2(x, 270 + sin(i) * 3), Vector2(x - 4, 302 + sin(i) * 2), Color("6a6950"), 5, true)
	for id in World.NODES:
		var node: Dictionary = World.NODES[id]
		var p: Vector2 = node.pos
		var is_known: bool = game.known(id)
		var tint := Color("b9b8a1")
		if is_known:
			match node.kind:
				"camp":
					Art.camp(self, p + Vector2(0, -22), 1.5)
					if id == "haven":
						Art.ruin(self, p + Vector2(42, -22), 0.65)
					else:
						draw_colored_polygon(PackedVector2Array([p + Vector2(-70, -17), p + Vector2(-44, -60), p + Vector2(-14, -17)]), Color("525746"))
					tint = Color("e5bd76")
				"relic":
					Art.ruin(self, p + Vector2(0, -16), 0.8, true)
				"fight":
					if id not in game.data.resolved:
						Art.monster(self, p + Vector2(0, -23), 0.40, Color("747560"), 0)
						tint = Color("c38e72")
				"herbs":
					Art.ruin(self, p + Vector2(0, -18), 0.55)
				"traveler":
					Art.person(self, p + Vector2(0, -20), 0.55, Color("868473"), "vesta")
		var radius := 7.0 if is_known else 6.0
		if id == selected or id == hover_id:
			Art.glow(self, p, 34, Color("e9c981"))
			draw_arc(p, 15, 0, TAU, 32, Color("b99a61"), 1.0, true)
		draw_circle(p, radius + 3, Color("101815"))
		draw_circle(p, radius, tint, false, 1.7, true)
		if id in game.data.resolved:
			draw_line(p + Vector2(-3, 0), p + Vector2(0, 3), Color("b8c494"), 1.5, true)
			draw_line(p + Vector2(0, 3), p + Vector2(5, -3), Color("b8c494"), 1.5, true)
		elif not is_known:
			draw_string(ThemeDB.fallback_font, p + Vector2(-3.5, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, tint)
		if id == selected or id == hover_id or node.kind == "camp":
			var title: String = node.name if is_known else "Неизвестное место"
			var width := ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_style_box(_label_box(), Rect2(p + Vector2(-width / 2 - 9, 18), Vector2(width + 18, 25)))
			draw_string(ThemeDB.fallback_font, p + Vector2(-width / 2, 35), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d9d5bd"))
	# A small compass and hand-lettered region annotations.
	draw_string(ThemeDB.fallback_font, Vector2(57, 77), "С Е Р Ы Й   Л Е С", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.62, 0.66, 0.55, 0.46))
	draw_string(ThemeDB.fallback_font, Vector2(650, 625), "З А Т О П Л Е Н Н Ы Й   Т Р А К Т", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.66, 0.55, 0.4))
	draw_line(Vector2(900, 40), Vector2(900, 82), Color("747966"), 1, true)
	draw_line(Vector2(882, 61), Vector2(918, 61), Color("747966"), 1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(900, 42), Vector2(895, 64), Vector2(900, 60), Vector2(905, 64)]), Color("adad8b"))
	draw_string(ThemeDB.fallback_font, Vector2(896, 32), "С", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("adad8b"))
	Art.glow(self, marker + Vector2(14, -28), 27, Color("e8b25f"))
	Art.person(self, marker + Vector2(16, -9), 0.42, Color("d1b577"), "vesta")
	draw_set_transform(Vector2.ZERO)

func _curve(a: Vector2, b: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var normal := (b - a).orthogonal().normalized()
	for i in range(21):
		var t := i / 20.0
		points.append(a.lerp(b, t) + normal * sin(t * PI) * 13)
	return points

func _label_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.09, 0.08, 0.90)
	box.set_corner_radius_all(3)
	return box
