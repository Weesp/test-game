extends Control

signal location_selected(id: String)
const World = preload("res://scripts/world_data.gd")
const Sprites = preload("res://scripts/sprite_art.gd")
const BACKGROUND = preload("res://art/world-map-v2.png")
const POINTS = {
	"camp": Vector2(188, 502), "fork": Vector2(290, 365),
	"grove": Vector2(145, 173), "lookout": Vector2(287, 153),
	"bridge": Vector2(536, 304), "ford": Vector2(542, 492),
	"hermit": Vector2(741, 564), "shrine": Vector2(803, 402),
	"sentinel": Vector2(696, 257), "chapel": Vector2(826, 225),
	"haven": Vector2(585, 98)
}
var game
var selected := "camp"
var hover_id := ""
var marker := POINTS.camp
var move_tween: Tween

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): hover_id = ""; queue_redraw())

func node_position(id: String) -> Vector2:
	return POINTS[id] * size / Vector2(960, 650)

func set_location(id: String, animate := true) -> void:
	if move_tween:
		move_tween.kill()
	if animate:
		move_tween = create_tween()
		move_tween.tween_method(func(p): marker = p; queue_redraw(), marker, POINTS[id], 0.65).set_trans(Tween.TRANS_SINE)
	else:
		marker = POINTS[id]
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion or event is InputEventMouseButton):
		return
	var found := ""
	for id in POINTS:
		if event.position.distance_to(node_position(id)) < 26:
			found = id
			break
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not found.is_empty() else Control.CURSOR_ARROW
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
	draw_texture_rect(BACKGROUND, Rect2(Vector2.ZERO, size), false)
	for edge in World.EDGES:
		var a := node_position(edge[0])
		var b := node_position(edge[1])
		var path := PackedVector2Array()
		for i in range(25):
			var t := i / 24.0
			path.append(a.lerp(b, t) + (b - a).orthogonal().normalized() * sin(t * PI) * 15)
		var adjacent: bool = game.data.location in edge
		draw_polyline(path, Color(0.03, 0.035, 0.025, 0.25), 3.0, true)
		draw_polyline(path, Color(0.77, 0.70, 0.46, 0.48 if adjacent else 0.18), 1.1, true)
	for id in POINTS:
		var p := node_position(id)
		var known: bool = game.known(id)
		var tint := Color("dbd5bd")
		if World.NODES[id].kind == "camp":
			tint = Color("d9b16d")
		if id == hover_id or id == game.data.location:
			draw_arc(p, 12, 0, TAU, 32, Color(0.85, 0.72, 0.43, 0.7), 1, true)
		draw_circle(p, 6, Color("181a11"))
		draw_circle(p, 4.5, tint, false, 1.4, true)
		if id in game.data.resolved:
			draw_circle(p, 2.2, Color("a8b18a"))
		if not known:
			draw_string(ThemeDB.fallback_font, p + Vector2(-3, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tint)
		if id == hover_id:
			var title: String = World.NODES[id].name if known else "Неизвестное место"
			var width := ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_rect(Rect2(p + Vector2(-width / 2 - 13, 17), Vector2(width + 26, 32)), Color(0.035, 0.045, 0.028, 0.93))
			draw_string(ThemeDB.fallback_font, p + Vector2(-width / 2, 39), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e0d4af"))
	var foot: Vector2 = marker * size / Vector2(960, 650) + Vector2(18, -7)
	Sprites.draw_figure(self, "ivar", foot, 57)
