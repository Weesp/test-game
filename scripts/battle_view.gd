extends Control

const World = preload("res://scripts/world_data.gd")
const Art = preload("res://scripts/ink_art.gd")
var game

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if game == null or not game.in_combat():
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(960, 380))
	draw_rect(Rect2(0, 0, 960, 380), Color("182220"))
	Art.glow(self, Vector2(505, 130), 300, Color("83918a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in range(38):
		Art.tree(self, Vector2(i * 28 - 15, rng.randf_range(180, 290)), rng.randf_range(1.5, 3.0), Color("202d27"))
	Art.ruin(self, Vector2(570, 235), 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 277), Vector2(180, 266), Vector2(425, 284), Vector2(720, 255), Vector2(960, 269), Vector2(960, 380), Vector2(0, 380)]), Color("242b23"))
	for i in range(80):
		var p := Vector2(rng.randf_range(0, 960), rng.randf_range(275, 380))
		draw_line(p, p + Vector2(rng.randf_range(4, 22), -2), Color(0.48, 0.49, 0.38, 0.15), 1, true)
	for i in range(3):
		var h: Dictionary = game.data.heroes[i]
		var spec: Dictionary = World.HEROES[i]
		var p := Vector2(125 + i * 112, 294 + (16 if i == 1 else 0))
		Art.person(self, p, 1.8 if i == 0 else 1.6, spec.color, spec.id, h.hp <= 0)
		_bar(p + Vector2(-40, 17), float(h.hp) / spec.max_hp, Color("a5b87d"), spec.name)
	for i in range(game.data.combat.enemies.size()):
		var e: Dictionary = game.data.combat.enemies[i]
		var p := Vector2(680 + i * 150, 302)
		Art.monster(self, p, 1.85 if i == 0 else 1.4, Color("92917c"), i, e.hp <= 0)
		_bar(p + Vector2(-40, 17), float(e.hp) / e.max_hp, Color("bd8065"), e.name)
	draw_set_transform(Vector2.ZERO)

func _bar(p: Vector2, ratio: float, tint: Color, title: String) -> void:
	draw_rect(Rect2(p, Vector2(80, 4)), Color("101512"))
	draw_rect(Rect2(p, Vector2(80 * ratio, 4)), tint)
	var width := ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(ThemeDB.fallback_font, p + Vector2(40 - width / 2, 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ded8c1"))
