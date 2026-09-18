extends Control

signal hero_selected(id: String)
signal enemy_selected(index: int)
const World = preload("res://scripts/world_data.gd")
const Art = preload("res://scripts/sprite_art.gd")
const GARDEN = preload("res://art/approved/garden.png")
const SHRINE = preload("res://art/approved/shrine.png")
var game
var active_hero := "ivar"
var selected_enemy := 0
var hovered := ""
var busy := false
var animation_speed := 1.0
var clock := 0.0
var display_data: Dictionary = {}
var current_event: Dictionary = {}
var progress := 0.0
var impact_applied := false

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): hovered = "")

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func hero_position(index: int) -> Vector2:
	return size * Vector2([0.38, 0.235, 0.11][index], [0.77, 0.73, 0.765][index])

func enemy_position(index: int) -> Vector2:
	var count: int = game.data.combat.enemies.size()
	return size * Vector2((0.60 + index * 0.145) if count > 2 else (0.635 + index * 0.235), 0.765 - 0.025 * (index % 2))

func enemy_art(index: int) -> String:
	var enemies: Array = game.data.combat.enemies
	# Old saves retain their original stats and receive a matching local visual.
	var defaults: Array = World.ENCOUNTERS[World.NODES[game.data.location].encounter]
	return str(enemies[index].get("art", defaults[index % defaults.size()].art))

func figure_height(id: String) -> float:
	if id.begins_with("enemy_"):
		var art := enemy_art(int(id.trim_prefix("enemy_")))
		if art == "griffin":
			return size.y * 0.305
		return size.y * (0.36 if game.data.combat.enemies.size() > 2 else 0.43)
	return size.y * (0.405 if id == "ivar" else 0.345)

func position_for(id: String) -> Vector2:
	if id.begins_with("enemy_"):
		return enemy_position(int(id.trim_prefix("enemy_")))
	for i in range(3):
		if World.HEROES[i].id == id:
			return hero_position(i)
	return Vector2.ZERO

func hit_rect(id: String, art: String) -> Rect2:
	var height := figure_height(id)
	var texture := Art.texture_for(art)
	var width := height * texture.get_width() / texture.get_height()
	return Rect2(position_for(id) - Vector2(width / 2, height * float(Art.FOOT_ANCHORS.get(art, 1.0))), Vector2(width, height + 20))

func _gui_input(event: InputEvent) -> void:
	if busy or not (event is InputEventMouseMotion or event is InputEventMouseButton) or game.data.combat.status != "active":
		return
	var found := ""
	for i in range(3):
		var id: String = World.HEROES[i].id
		if hit_rect(id, id).has_point(event.position) and game.data.heroes[i].hp > 0:
			found = id
	for i in range(game.data.combat.enemies.size()):
		var id := "enemy_" + str(i)
		if hit_rect(id, enemy_art(i)).has_point(event.position) and game.data.combat.enemies[i].hp > 0:
			found = id
	hovered = found
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not found.is_empty() else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if found.begins_with("enemy_"):
			enemy_selected.emit(int(found.trim_prefix("enemy_")))
		elif not found.is_empty():
			hero_selected.emit(found)

func play_events(events: Array, before: Dictionary) -> void:
	busy = true
	hovered = ""
	display_data = before.duplicate(true)
	for event in events:
		current_event = event
		progress = 0.0
		impact_applied = false
		var tween := create_tween()
		tween.tween_method(_advance, 0.0, 1.0, 0.95 / maxf(animation_speed, 0.1))
		await tween.finished
		display_data = event.after
	current_event = {}
	display_data = {}
	busy = false
	queue_redraw()

func _advance(value: float) -> void:
	progress = value
	if value >= 0.46 and not impact_applied:
		display_data = current_event.after
		impact_applied = true
	queue_redraw()

func _draw() -> void:
	if game == null or not game.in_combat():
		return
	var state: Dictionary = display_data if not display_data.is_empty() else game.data
	draw_texture_rect(SHRINE if game.data.location == "sentinel" else GARDEN, Rect2(Vector2.ZERO, size), false)
	for i in range(3):
		var h: Dictionary = state.heroes[i]
		var p := hero_position(i)
		var active: bool = active_hero == h.id and game.can_act(h.id) and not busy
		_shadow(p, 48)
		if active:
			var ring := PackedVector2Array()
			for step in range(33):
				ring.append(p + Vector2(cos(step * TAU / 32) * 51, sin(step * TAU / 32) * 11))
			draw_polyline(ring, Color(0.86, 0.75, 0.47, 0.65), 1.5, true)
		_figure(h.id, h.id, p, h.hp > 0, i)
		_bar(p + Vector2(-40, 15), float(h.hp) / World.HEROES[i].max_hp, Color("9f6246"))
		if hovered == h.id:
			_caption(p - Vector2(0, figure_height(h.id) + 12), "%s · %d/%d" % [World.HEROES[i].name, h.hp, World.HEROES[i].max_hp])
	for i in range(state.combat.enemies.size()):
		var e: Dictionary = state.combat.enemies[i]
		var id := "enemy_" + str(i)
		var p := enemy_position(i)
		_shadow(p, 62)
		_figure(id, enemy_art(i), p, e.hp > 0, i + 3)
		_bar(p + Vector2(-40, 15), float(e.hp) / e.max_hp, Color("a24f3c"))
		if selected_enemy == i and e.hp > 0 and not busy:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 35), p + Vector2(6, 35), p + Vector2(0, 28)]), Color("d7be88"))
		if hovered == id:
			_caption(p - Vector2(0, figure_height(id) + 12), "%s · %d/%d" % [e.name, e.hp, e.max_hp])
	if not current_event.is_empty():
		_effects()

func _figure(id: String, art: String, foot: Vector2, alive: bool, phase: int) -> void:
	var breath := sin(clock * 1.7 + phase * 1.4) if alive else 0.0
	var scale_y := 1.0 + breath * 0.006
	var offset := Vector2.ZERO
	var rotation := 0.0
	var tint := Color.WHITE if alive else Color(0.35, 0.33, 0.34, 0.24)
	if not current_event.is_empty():
		if current_event.actor == id:
			var pulse := sin(clampf(progress / 0.65, 0.0, 1.0) * PI)
			var direction := -1.0 if id.begins_with("enemy_") else 1.0
			if current_event.effect in ["strike", "cleave"]:
				offset.x = direction * pulse * size.x * 0.027
				rotation = pulse * direction * 0.045
			else:
				scale_y += pulse * 0.012
		for change in current_event.changes:
			if change.id == id and change.after < change.before and progress >= 0.46:
				var hit := clampf((progress - 0.46) / 0.54, 0.0, 1.0)
				offset.x += sin(hit * PI * 5) * (1 - hit) * 13
				if hit < 0.18:
					tint = Color(1.35, 1.15, 1.0, 1.0)
				if not alive:
					rotation = 0.10 * hit
					tint = Color(1, 1, 1, lerpf(1.0, 0.24, hit))
	draw_set_transform(foot + offset, rotation, Vector2(1.0, scale_y))
	Art.draw_figure(self, art, Vector2.ZERO, figure_height(id), tint)
	draw_set_transform(Vector2.ZERO)

func _effects() -> void:
	var effect: String = current_event.effect
	var color := Color("eadbb2")
	match effect:
		"fire": color = Color("f5a65e")
		"ice": color = Color("99d5e2")
		"heal": color = Color("b3dba3")
		"guard": color = Color("d8ba77")
	var source := position_for(current_event.actor) - Vector2(0, figure_height(current_event.actor) * 0.56)
	var changes: Array = current_event.changes
	if changes.is_empty():
		changes = [{"id": current_event.actor, "before": 0, "after": 0, "guard": 0}]
	for change in changes:
		var target := position_for(change.id) - Vector2(0, figure_height(change.id) * 0.56)
		if effect in ["fire", "ice"] and progress < 0.46:
			var travel := clampf((progress - 0.10) / 0.36, 0.0, 1.0)
			var point := source.lerp(target, travel)
			draw_line(point - (target - source).normalized() * 55, point, Color(color, 0.6), 7, true)
			draw_circle(point, 17, Color(color, 0.10))
			draw_circle(point, 7, color)
		if progress < 0.46:
			continue
		var hit := (progress - 0.46) / 0.54
		var fade := 1.0 - hit
		if effect in ["strike", "cleave"]:
			var a := target + Vector2(-38, 44)
			var b := target + Vector2(50, -48)
			draw_line(a, a.lerp(b, minf(hit * 4, 1.0)), Color(color, fade), 4 * fade + 1, true)
			if effect == "cleave":
				draw_arc(target, 50 + hit * 16, -1.5, 1.2, 28, Color(color, fade * 0.7), 3, true)
		else:
			draw_arc(target, 16 + hit * 55, 0, TAU, 40, Color(color, fade * 0.8), 2, true)
			draw_circle(target, 26 + hit * 24, Color(color, fade * 0.08))
			if effect in ["heal", "guard"]:
				for i in range(3):
					var p := target + Vector2((i - 1) * 24, 45 - hit * 90)
					draw_line(p, p - Vector2(0, 18), Color(color, fade * 0.7), 2, true)
		var delta: int = change.after - change.before
		var text := str(delta) if delta < 0 else ("+" + str(delta) if delta > 0 or effect == "heal" else "Защита")
		if change.guard > 0 and delta == 0:
			text = "+%d защиты" % change.guard
		var text_color := Color("efb0a0") if delta < 0 else color
		text_color.a = minf(fade * 2, 1.0)
		var p := target - Vector2(15, 65 + hit * 45)
		draw_string(ThemeDB.fallback_font, p + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.04, 0.03, 0.04, text_color.a))
		draw_string(ThemeDB.fallback_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, text_color)

func _bar(p: Vector2, ratio: float, tint: Color) -> void:
	draw_rect(Rect2(p, Vector2(80, 4)), Color("171710"))
	draw_rect(Rect2(p, Vector2(80 * ratio, 4)), tint)

func _shadow(p: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		points.append(p + Vector2(cos(i * TAU / 32) * radius, sin(i * TAU / 32) * 9))
	draw_colored_polygon(points, Color(0.02, 0.018, 0.012, 0.4))

func _caption(p: Vector2, text: String) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_rect(Rect2(p - Vector2(width / 2 + 12, 23), Vector2(width + 24, 32)), Color(0.04, 0.045, 0.03, 0.9))
	draw_string(ThemeDB.fallback_font, p - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e0d4af"))
