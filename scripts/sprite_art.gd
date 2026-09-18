extends RefCounted

const WARRIOR = preload("res://art/ivar-painted-v5.png")
const CAST = preload("res://art/cast-draft.png")

static func texture_for(id: String) -> Texture2D:
	if id == "ivar":
		return WARRIOR
	var atlas := AtlasTexture.new()
	atlas.atlas = CAST
	var cell := Vector2(CAST.get_width() / 5.0, CAST.get_height())
	var index := 1
	match id:
		"vesta": index = 2
		"root": index = 3
		"guard": index = 4
	atlas.region = Rect2(Vector2(cell.x * index, 0), cell)
	return atlas

static func draw_figure(c: CanvasItem, id: String, foot: Vector2, height: float, tint := Color.WHITE) -> void:
	var texture := texture_for(id)
	var width := height * texture.get_width() / texture.get_height()
	c.draw_texture_rect(texture, Rect2(foot - Vector2(width / 2, height), Vector2(width, height)), false, tint)

static func portrait(id: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	if id == "ivar":
		atlas.atlas = WARRIOR
		atlas.region = Rect2(WARRIOR.get_width() * 0.28, WARRIOR.get_height() * 0.01, WARRIOR.get_width() * 0.45, WARRIOR.get_height() * 0.30)
	else:
		atlas.atlas = CAST
		var cell := Vector2(CAST.get_width() / 5.0, CAST.get_height())
		atlas.region = Rect2(cell.x * (2.14 if id == "vesta" else 1.17), cell.y * 0.17, cell.x * 0.64, cell.y * 0.35)
	return atlas
