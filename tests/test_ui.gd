extends SceneTree

const Main = preload("res://scenes/main.tscn")
const World = preload("res://scripts/world_data.gd")
var app
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func expect(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("UI FAIL: " + name)

func settle() -> void:
	for i in range(3):
		await process_frame

func buttons(node: Node) -> Array:
	var found: Array = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(buttons(child))
	return found

func press(prefix: String) -> void:
	for button in buttons(app.root_layout):
		if button.text.begins_with(prefix) and not button.disabled:
			button.pressed.emit()
			await settle()
			return
	expect(false, "Missing enabled button: " + prefix)

func move_to(id: String) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = World.NODES[id].pos * app.map_view.size / Vector2(960, 650)
	app.map_view._gui_input(event)
	await settle()
	expect(app.selected == id, "Map click selects " + id)
	await press("Отправиться")
	expect(app.game.data.location == id, "Travel button moves to " + id)
	await settle()

func fight() -> void:
	await press("Вступить в бой")
	expect(app.game.in_combat(), "UI enters battle")
	await press("Мира")
	expect(app.active_hero == "mira", "Hero selection")
	await press(app.game.data.combat.enemies[1].name)
	expect(app.enemy_target == 1, "Enemy target selection")
	if app.game.data.level == 2 and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://verification/level2-battle.png")
	for step in range(80):
		if app.game.data.combat.status != "active":
			break
		var hero: Dictionary = app.game.get_hero(app.active_hero)
		var spec: Dictionary = World.hero(app.active_hero)
		if hero.id in ["ivar", "mira"] and hero.uses > 0:
			await press(spec.ability)
		else:
			await press("Атака")
	expect(app.game.data.combat.status == "victory", "Battle completed through buttons")
	await press("Продолжить путь")
	expect(not app.game.in_combat(), "Victory returns to map")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	app = Main.instantiate()
	app.game.persistence_enabled = false
	root.add_child(app)
	await settle()
	await press("Отдохнуть")
	expect("first_rest" in app.game.data.scenes, "Rest button triggers scene")
	await move_to("fork")
	await move_to("grove")
	await fight()
	await move_to("lookout")
	await press("Восстановить")
	await move_to("bridge")
	await fight()
	expect(app.game.data.level == 2, "UI campaign reaches level 2")
	await move_to("haven")
	await press("Отдохнуть")
	await move_to("sentinel")
	await fight()
	await move_to("chapel")
	await press("Забрать")
	await move_to("sentinel")
	await move_to("haven")
	await press("Отдохнуть")
	expect("quest_complete" in app.game.data.flags, "Entire quest completed through UI")
	await press("Новый поход")
	expect(app.confirmation.visible, "Reset asks confirmation")
	expect("quest_complete" in app.game.data.flags, "Opening reset dialog keeps campaign")
	app.confirmation.get_cancel_button().pressed.emit()
	app.confirmation.hide()
	await settle()
	expect("quest_complete" in app.game.data.flags, "Cancel reset preserves progress")
	expect(app.root_layout.size.x <= 1440 and app.root_layout.size.y <= 900, "Main layout fits viewport")
	for button in buttons(app.root_layout):
		if button.is_visible_in_tree():
			var rect: Rect2 = button.get_global_rect()
			expect(rect.position.x >= 0 and rect.end.x <= 1441 and rect.position.y >= 0 and rect.end.y <= 901, "Button fits viewport: " + button.text)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://verification/quest-complete.png")
	print("UI TESTS: %d checks, %d failures" % [checks, failures])
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
