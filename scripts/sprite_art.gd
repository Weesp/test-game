extends RefCounted

const WARRIOR = preload("res://art/approved/ivar.png")
const CAST = preload("res://art/cast-draft.png")
const CREATURES = {
	"griffin": preload("res://art/approved/griffin.png"),
	"troll": preload("res://art/approved/troll.png"),
	"dryad": preload("res://art/approved/dryad.png"),
	"wyvern": preload("res://art/approved/wyvern.png"),
	"mimic_shield": preload("res://art/approved/mimic_shield.png"),
	"mimic_chest": preload("res://art/approved/mimic_chest.png"),
	"kelpie": preload("res://art/approved/kelpie.png"),
}
const SILHOUETTE = preload("res://scripts/silhouette.gdshader")
const FOOT_ANCHORS = {"ivar": 0.945, "troll": 0.965, "dryad": 0.93, "griffin": 0.96, "kelpie": 0.95, "wyvern": 0.81, "mimic_shield": 0.96, "mimic_chest": 0.96}
static var prepared: Dictionary = {}

static func prepare(parent: Node) -> void:
	prepared.clear()
	var originals := CREATURES.duplicate()
	originals["ivar"] = WARRIOR
	for id in originals:
		var texture: Texture2D = originals[id]
		var viewport := SubViewport.new()
		viewport.name = "Silhouette_" + id
		viewport.size = Vector2i(texture.get_size())
		viewport.transparent_bg = true
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		parent.add_child(viewport)
		var figure := Sprite2D.new()
		figure.centered = false
		figure.texture = texture
		var material := ShaderMaterial.new()
		material.shader = SILHOUETTE
		material.set_shader_parameter("silhouette", load("res://art/masks/" + id + ".png"))
		figure.material = material
		viewport.add_child(figure)
		prepared[id] = viewport.get_texture()

static func texture_for(id: String) -> Texture2D:
	if prepared.has(id):
		return prepared[id]
	if id == "ivar":
		return WARRIOR
	if CREATURES.has(id):
		return CREATURES[id]
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
	c.draw_texture_rect(texture, Rect2(foot - Vector2(width / 2, height * float(FOOT_ANCHORS.get(id, 1.0))), Vector2(width, height)), false, tint)

static func portrait(id: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	if id == "ivar":
		atlas.atlas = texture_for("ivar")
		atlas.region = Rect2(WARRIOR.get_width() * 0.28, WARRIOR.get_height() * 0.01, WARRIOR.get_width() * 0.45, WARRIOR.get_height() * 0.30)
	else:
		atlas.atlas = CAST
		var cell := Vector2(CAST.get_width() / 5.0, CAST.get_height())
		atlas.region = Rect2(cell.x * (2.14 if id == "vesta" else 1.17), cell.y * 0.17, cell.x * 0.64, cell.y * 0.35)
	return atlas
