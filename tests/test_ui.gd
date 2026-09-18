extends SceneTree

const Main = preload("res://scenes/main.tscn")
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
	for i in range(4):
		await process_frame
	var deadline := Time.get_ticks_msec() + 10000
	while app.combat_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	expect(not app.combat_busy, "Animation finishes and releases input")

func buttons(node: Node) -> Array:
	var found: Array = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(buttons(child))
	return found

func press(text_or_name: String) -> void:
	for button in buttons(app.root_layout):
		if (button.text.begins_with(text_or_name) or button.name == text_or_name) and not button.disabled:
			button.pressed.emit()
			await settle()
			return
	expect(false, "Missing enabled button: " + text_or_name)

func click_map(id: String) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = app.map_view.node_position(id)
	app.map_view._gui_input(event)
	await settle()

func move_to(id: String) -> void:
	await click_map(id)
	expect(app.selected == id and app.overlay_mode == "location", "Map click opens place " + id)
	await press("Отправиться")
	expect(app.game.data.location == id and app.overlay_mode.is_empty(), "Travel closes popup " + id)
	await settle()

func interact(prefix: String) -> void:
	await click_map(app.game.data.location)
	await press(prefix)

func close_story() -> void:
	expect(app.overlay_mode == "story", "Event opens narrative popup")
	await press("Продолжить")
	expect(app.overlay_mode.is_empty(), "Narrative popup dismisses")

func fight() -> void:
	await interact("Вступить в бой")
	expect(app.game.in_combat() and app.overlay_mode.is_empty(), "Battle opens unobscured")
	expect(app.battle_view.size.is_equal_approx(app.root_layout.size), "Battle occupies whole viewport")
	await press("mira")
	expect(app.active_hero == "mira" and app.overlay_mode == "actions", "Portrait opens action tray")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = app.battle_view.enemy_position(1) - Vector2(0, 180)
	app.battle_view._gui_input(event)
	await settle()
	expect(app.enemy_target == 1, "Clicking creature selects target")
	if "--capture" in OS.get_cmdline_user_args() and app.game.data.level == 2:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://verification/battle-actions-v2.png")
	for step in range(90):
		if app.game.data.combat.status != "active":
			break
		if app.overlay_mode != "actions":
			await press(app.active_hero)
		var hero: Dictionary = app.game.get_hero(app.active_hero)
		var spec: Dictionary = app.World.hero(app.active_hero)
		if hero.id in ["ivar", "mira"] and hero.uses > 0:
			await press(spec.ability)
		else:
			await press("Атака")
	expect(app.game.data.combat.status == "victory" and app.overlay_mode == "result", "Victory opens result popup")
	await press("Продолжить путь")
	expect(not app.game.in_combat() and app.overlay_mode.is_empty(), "Victory returns to full map")

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	app._unhandled_key_input(event)
	await settle()

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 900)
	app = Main.instantiate()
	app.animation_speed = 20.0
	app.game.persistence_enabled = false
	root.add_child(app)
	await settle()
	expect(app.overlay_mode.is_empty(), "No permanent sidebar or initial modal")
	expect(app.map_view.size.is_equal_approx(app.root_layout.size), "Map occupies whole viewport")
	await key(KEY_J)
	expect(app.overlay_mode == "journal", "Journal hotkey")
	await key(KEY_ESCAPE)
	expect(app.overlay_mode.is_empty(), "Escape closes popup")
	await press("party")
	expect(app.overlay_mode == "party", "Party icon opens stats")
	await press("close_popup")
	await interact("Отдохнуть")
	expect("first_rest" in app.game.data.scenes, "Rest opens first camp story")
	await close_story()
	await move_to("fork")
	await move_to("grove")
	await fight()
	await move_to("lookout")
	await interact("Восстановить")
	await close_story()
	await move_to("bridge")
	await fight()
	expect(app.game.data.level == 2, "UI campaign reaches level 2")
	await move_to("haven")
	await interact("Отдохнуть")
	await close_story()
	await move_to("sentinel")
	await fight()
	await move_to("chapel")
	await interact("Забрать")
	await close_story()
	await move_to("sentinel")
	await move_to("haven")
	await interact("Отдохнуть")
	expect("quest_complete" in app.game.data.flags, "Quest completed through popups")
	await close_story()
	await press("menu")
	await press("Новый поход")
	expect(app.overlay_mode == "confirm", "Reset requires confirmation")
	expect("quest_complete" in app.game.data.flags, "Opening reset preserves save")
	await press("Отмена")
	expect("quest_complete" in app.game.data.flags, "Cancel reset preserves progress")
	await key(KEY_ESCAPE)
	expect(app.overlay_mode.is_empty(), "Menu dismissed")
	for button in buttons(app.root_layout):
		if button.is_visible_in_tree():
			var rect: Rect2 = button.get_global_rect()
			expect(rect.position.x >= 0 and rect.end.x <= 1601 and rect.position.y >= 0 and rect.end.y <= 901, "HUD button fits viewport")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://verification/map-complete-v2.png")
	print("UI TESTS: %d checks, %d failures" % [checks, failures])
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
