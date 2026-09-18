extends SceneTree

const Main = preload("res://scenes/main.tscn")
var app

func _initialize() -> void:
	_run.call_deferred()

func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://verification/" + name + ".png")
	if error != OK:
		push_error("Could not capture " + name)
		quit(1)

func pause(seconds: float) -> void:
	await create_timer(seconds).timeout

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 900)
	app = Main.instantiate()
	app.game.persistence_enabled = false
	root.add_child(app)
	for i in range(10):
		await process_frame
	for place in ["grove", "bridge", "sentinel"]:
		app._demo_encounter(place)
		await pause(0.6)
		await snapshot("art-" + place)
		app.active_hero = "ivar"
		app._perform("attack")
		await pause(0.57)
		await snapshot("impact-" + place)
		while app.combat_busy:
			await process_frame
		await pause(0.2)
		app.active_hero = "mira"
		app.enemy_target = 1
		app._perform("ability")
		await pause(0.29)
		await snapshot("spell-" + place)
		while app.combat_busy:
			await process_frame
		app.active_hero = "vesta"
		await app._perform("guard")
		await pause(0.5)
	print("ART CAPTURES COMPLETE")
	quit()

