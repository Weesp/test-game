extends Control

signal hero_selected(id: String)
signal enemy_selected(index: int)
const World = preload("res://scripts/world_data.gd")
const Art = preload("res://scripts/sprite_art.gd")
const BACKGROUND = preload("res://art/battle-painted-v6.png")
var game
var active_hero := "ivar"
var selected_enemy := 0
var hovered := ""

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): hovered = ""; queue_redraw())

func hero_position(index: int) -> Vector2:
	return size * Vector2(0.16 + index * 0.125, 0.72 + (0.02 if index == 1 else 0.0))

func enemy_position(index: int) -> Vector2:
	return size * Vector2(0.68 + index * 0.16, 0.735 - index * 0.025)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion or event is InputEventMouseButton) or game.data.combat.status != "active":
		return
	var found := ""
	var enemy := -1
	for i in range(3):
		var p := hero_position(i)
		if Rect2(p - Vector2(65, size.y * 0.37), Vector2(130, size.y * 0.39)).has_point(event.position):
			found = World.HEROES[i].id
	for i in range(game.data.combat.enemies.size()):
		var p := enemy_position(i)
		if Rect2(p - Vector2(85, size.y * 0.4), Vector2(170, size.y * 0.43)).has_point(event.position):
			enemy = i
			found = "enemy_" + str(i)
	if hovered != found:
		hovered = found
		queue_redraw()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not found.is_empty() else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if enemy >= 0:
			enemy_selected.emit(enemy)
		elif not found.is_empty():
			hero_selected.emit(found)

func _draw() -> void:
	if game == null or not game.in_combat():
		return
	draw_texture_rect(BACKGROUND, Rect2(Vector2.ZERO, size), false)
	for i in range(3):
		var h: Dictionary = game.data.heroes[i]
		var spec: Dictionary = World.HEROES[i]
		var p := hero_position(i)
		var is_active: bool = active_hero == h.id and game.can_act(h.id)
		_shadow(p, 54)
		if is_active:
			draw_arc(p + Vector2(0, -2), 42, 0, PI, 24, Color(0.86, 0.75, 0.47, 0.7), 2, true)
		Art.draw_figure(self, h.id, p, size.y * 0.37, Color.WHITE if h.hp > 0 else Color(0.35, 0.35, 0.35, 0.35))
		_bar(p + Vector2(-40, 15), float(h.hp) / spec.max_hp, Color("9f6246"))
		if hovered == h.id:
			_caption(p + Vector2(0, -size.y * 0.39), "%s · %d/%d" % [spec.name, h.hp, spec.max_hp])
	for i in range(game.data.combat.enemies.size()):
		var e: Dictionary = game.data.combat.enemies[i]
		var p := enemy_position(i)
		_shadow(p, 59)
		Art.draw_figure(self, "root" if i == 0 else "guard", p, size.y * 0.40, Color.WHITE if e.hp > 0 else Color(0.35, 0.35, 0.35, 0.25))
		_bar(p + Vector2(-40, 15), float(e.hp) / e.max_hp, Color("a24f3c"))
		if selected_enemy == i and e.hp > 0:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 35), p + Vector2(6, 35), p + Vector2(0, 28)]), Color("d7be88"))
		if hovered == "enemy_" + str(i):
			_caption(p + Vector2(0, -size.y * 0.42), "%s · %d/%d · атака %d" % [e.name, e.hp, e.max_hp, e.attack])

func _bar(p: Vector2, ratio: float, tint: Color) -> void:
	draw_rect(Rect2(p, Vector2(80, 4)), Color("171710"))
	draw_rect(Rect2(p, Vector2(80 * ratio, 4)), tint)

func _shadow(p: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		points.append(p + Vector2(cos(i * TAU / 32) * radius, sin(i * TAU / 32) * 10))
	draw_colored_polygon(points, Color(0.02, 0.018, 0.012, 0.5))

func _caption(p: Vector2, text: String) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_rect(Rect2(p - Vector2(width / 2 + 12, 23), Vector2(width + 24, 32)), Color(0.04, 0.045, 0.03, 0.9))
	draw_string(ThemeDB.fallback_font, p - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e0d4af"))
