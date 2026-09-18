extends Button

const Art = preload("res://scripts/sprite_art.gd")
var hero_id := "ivar"
var tint := Color("b9a077")
var health := 1.0
var chosen := false

func _ready() -> void:
	custom_minimum_size = Vector2(70, 90)
	clip_contents = true
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.07, 0.06, 0.92)
	box.border_color = Color("877654")
	box.set_border_width_all(1)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, box)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 12)), tint.darkened(0.78))
	draw_texture_rect(Art.portrait(hero_id), Rect2(4, 4, size.x - 8, size.y - 16), false)
	draw_rect(Rect2(5, size.y - 12, size.x - 10, 7), Color("191310"))
	draw_rect(Rect2(5, size.y - 12, (size.x - 10) * health, 7), Color("a84836") if health < 0.4 else Color("9c8353"))
	if chosen or is_hovered():
		draw_rect(Rect2(Vector2(0, 0), size), Color("d5bd83"), false, 2)
