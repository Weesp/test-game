extends SceneTree

const Main = preload("res://scenes/main.tscn")
var app
var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PRESENTATION FAIL: " + label)

func settle() -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while app.combat_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	expect(not app.combat_busy, "Animation releases input within timeout")
	await process_frame

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 900)
	app = Main.instantiate()
	app.game.persistence_enabled = false
	app.animation_speed = 15
	root.add_child(app)
	await process_frame
	app._demo_encounter("grove")
	await process_frame
	var before: Dictionary = app.game.data.duplicate(true)
	app._perform("attack")
	expect(app.combat_busy and app.battle_view.busy, "Presentation locks while attack runs")
	expect(app.overlay_mode.is_empty(), "Actions disappear during attack")
	expect(app.battle_view.display_data.combat.enemies[0].hp == before.combat.enemies[0].hp, "Health shown before impact")
	var resolved := JSON.stringify(app.game.data)
	app._perform("attack")
	app._choose_hero("mira")
	app._select_enemy(1)
	app._open("menu")
	expect(JSON.stringify(app.game.data) == resolved, "Double input cannot spend another action")
	expect(app.active_hero == "ivar" and app.enemy_target == 0 and app.overlay_mode.is_empty(), "No selection or destructive menus during playback")
	await settle()
	expect(app.battle_view.display_data.is_empty(), "Visual state returns to authoritative state")
	expect(app.game.combat_events.size() == 1, "One event for hero action")
	expect(app.game.combat_events[0].changes[0].before - app.game.combat_events[0].changes[0].after == 9, "Damage event records exact level-two hit")
	var time_before: float = app.battle_view.clock
	await process_frame
	expect(app.battle_view.clock > time_before, "Idle movement advances")

	app._choose_hero("mira")
	await app._perform("guard")
	app._choose_hero("vesta")
	await app._perform("guard")
	expect(app.game.combat_events.size() == 3, "Hero then each living enemy animate separately")
	expect(app.game.combat_events[1].actor == "enemy_0" and app.game.combat_events[2].actor == "enemy_1", "Enemy playback preserves order")
	expect(app.game.combat_events[2].changes[0].before == app.game.combat_events[2].changes[0].after, "Blocked damage still has a visible event")
	expect(app.game.data.combat.round == 2, "Enemy playback does not change rules")

	app._demo_encounter("sentinel")
	expect(app.game.data.combat.enemies.size() == 3, "Final battle includes all three chosen creatures")
	for enemy in app.game.data.combat.enemies:
		enemy.hp = 1
	app.active_hero = "ivar"
	app._perform("ability")
	expect(app.game.data.combat.status == "victory" and app.overlay_mode.is_empty(), "Victory waits for lethal impact")
	await settle()
	expect(app.overlay_mode == "result", "Victory popup appears after animation")

	app._demo_encounter("grove")
	for h in app.game.data.heroes:
		h.hp = 1
	for e in app.game.data.combat.enemies:
		e.attack = 99
	for turn in range(6):
		if app.game.data.combat.status != "active":
			break
		await app._perform("guard")
	expect(app.game.data.combat.status == "defeat" and app.overlay_mode == "result", "Defeat playback finishes before result")
	app._leave_battle()
	expect(not app.game.in_combat(), "Can leave after defeat")

	var seen: Array = []
	for location in ["grove", "bridge", "sentinel"]:
		app._demo_encounter(location)
		await process_frame
		for i in range(app.game.data.combat.enemies.size()):
			var id: String = app.battle_view.enemy_art(i)
			seen.append(id)
			var rect: Rect2 = app.battle_view.hit_rect("enemy_" + str(i), id)
			expect(rect.position.x >= 0 and rect.end.x <= 1600 and rect.position.y > 0 and rect.end.y < 800, "Creature fits unobscured field: " + id)
	# Compatibility with saves made before art IDs existed.
	app.game.data.combat.enemies[0].erase("art")
	expect(app.battle_view.enemy_art(0) == "mimic_shield", "Legacy save gets art without changing health")
	expect(seen.size() == 7, "All seven selected monsters are in encounters")
	print("PRESENTATION TESTS: %d checks, %d failures" % [checks, failures])
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

