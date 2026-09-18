extends SceneTree

const State = preload("res://scripts/game_state.gd")
const World = preload("res://scripts/world_data.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func expect(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + name)

func fresh():
	var game = State.new()
	game.persistence_enabled = false
	return game

func reach_grove(game) -> void:
	game.travel("fork")
	game.travel("grove")

func win(game) -> void:
	var steps := 0
	while game.in_combat() and game.data.combat.status == "active" and steps < 100:
		steps += 1
		var target := 0
		for i in range(game.data.combat.enemies.size()):
			if game.data.combat.enemies[i].hp > 0:
				target = i
				break
		for h in game.data.heroes:
			if game.can_act(h.id):
				var action := "ability" if h.id in ["ivar", "mira"] and h.uses > 0 else "attack"
				game.act(h.id, action, target)
				break
	expect(game.data.combat.status == "victory", "Encounter can be won with ordinary and limited actions")

func _run() -> void:
	var g = fresh()
	expect(g.data.heroes.size() == 3, "Initial party")
	expect(not g.travel("chapel"), "No teleport to non-neighbor")
	expect(not g.travel("missing"), "Reject unknown route")
	expect(g.travel("fork"), "Connected travel")
	expect(not g.rest(), "No rest outside refuge")
	expect(not g.known("grove"), "Unvisited mystery remains hidden")
	expect(g.travel("grove") and g.known("grove"), "Visit reveals mystery")
	expect(g.start_combat(), "Encounter starts")
	expect(not g.travel("lookout") and not g.rest(), "No travel or rest during combat")
	var snapshot := JSON.stringify(g.data)
	expect(not g.act("mira", "ability", 99), "Reject invalid target")
	expect(JSON.stringify(g.data) == snapshot, "Rejected action spends no charge")
	expect(not g.act("ivar", "advanced"), "Second-level ability locked")
	expect(g.act("ivar", "ability"), "Limited ability usable")
	expect(g.get_hero("ivar").uses == 1, "Charge spent")
	expect(not g.act("ivar", "attack"), "Only one action per hero per round")
	expect(g.act("mira", "ability", 0), "Targeted spell")
	expect(not g.act("vesta", "attack", 0), "Cannot attack dead enemy")
	win(g)
	expect(g.data.xp == 40 and g.data.level == 1, "First victory awards 40 XP")
	expect(not g.start_combat(), "Cannot start another battle during result")
	expect(g.leave_combat(), "Return to map after victory")
	expect(not g.start_combat(), "Resolved encounter cannot farm XP")
	var used := int(g.get_hero("ivar").uses)
	g.travel("lookout")
	expect(g.resolve_event(), "One-time healing location")
	expect(g.get_hero("ivar").uses == used, "Field healing never restores charges")
	expect(not g.resolve_event(), "Event cannot be repeated")
	g.travel("bridge")
	g.start_combat()
	win(g)
	expect(g.data.level == 2 and g.data.xp == 80, "Two victories raise level")
	expect(g.data.heroes.all(func(h): return h.advanced_uses == 1), "New abilities have one charge")
	g.leave_combat()
	g.travel("haven")
	expect(g.rest(), "Rest available at second refuge")
	expect(g.data.heroes.all(func(h): return h.hp == World.hero(h.id).max_hp and h.uses == World.hero(h.id).max_uses), "Rest restores party")
	var scene_count: int = g.data.scenes.size()
	g.rest()
	expect(g.data.scenes.size() == scene_count, "Camp scene never repeats")
	g.travel("sentinel")
	g.start_combat()
	expect(g.act("mira", "advanced"), "Level-two action works")
	expect(g.get_hero("mira").advanced_uses == 0, "Level-two charge spent")
	win(g)
	g.leave_combat()
	g.travel("chapel")
	expect(g.resolve_event(), "Relic discovered")
	g.travel("sentinel")
	g.travel("haven")
	g.rest()
	expect("quest_complete" in g.data.flags, "Quest completed by camp scene")
	expect(g.get_hero("mira").advanced_uses == 1, "Rest restores advanced charge")

	var guards = fresh()
	reach_grove(guards)
	guards.start_combat()
	for id in ["ivar", "mira", "vesta"]:
		guards.act(id, "guard")
	expect(guards.data.combat.round == 2, "Enemy phase advances round")
	expect(guards.data.heroes.all(func(h): return h.hp == World.hero(h.id).max_hp), "Guard absorbs damage")
	expect(guards.data.combat.guard.is_empty(), "Guard expires after enemy phase")
	guards.get_hero("ivar").uses = 0
	expect(not guards.act("ivar", "ability"), "Exhausted ability rejected")
	guards.get_hero("ivar").hp = 0
	expect(not guards.act("ivar", "attack"), "Fallen hero cannot act")
	guards.get_hero("mira").hp = 2
	expect(guards.act("vesta", "ability"), "Healer can act")
	expect(guards.get_hero("mira").hp == 16, "Healer targets lowest health ratio")
	expect(guards.get_hero("ivar").hp == 0, "Combat healing does not revive fallen hero")

	var defeat = fresh()
	reach_grove(defeat)
	defeat.start_combat()
	for h in defeat.data.heroes:
		h.hp = 1
	for e in defeat.data.combat.enemies:
		e.hp = 999
		e.max_hp = 999
		e.attack = 99
	for step in range(12):
		if defeat.data.combat.status != "active":
			break
		for h in defeat.data.heroes:
			if defeat.can_act(h.id):
				defeat.act(h.id, "attack", 0)
				break
	expect(defeat.data.combat.status == "defeat", "Full defeat detected")
	expect(defeat.leave_combat() and defeat.data.location == "camp", "Defeat returns to last camp")
	expect(not defeat.in_combat() and defeat.living().size() == 3, "Recovery removes combat and revives party")
	expect("grove" not in defeat.data.resolved, "Defeated encounter remains available")

	var traveler = fresh()
	for id in ["fork", "ford", "hermit"]:
		traveler.travel(id)
	expect(not traveler.resolve_event("invalid"), "Invalid story choice rejected")
	expect(traveler.resolve_event("help"), "Traveler helped")
	expect(traveler.get_hero("vesta").uses == 2, "Story choice shares combat charges")
	expect(not traveler.resolve_event("help"), "Story choice cannot repeat")
	for id in ["ford", "bridge", "haven"]:
		traveler.travel(id)
	traveler.rest()
	expect("traveler_scene" in traveler.data.scenes, "Choice unlocks camp scene")

	var saved = fresh()
	reach_grove(saved)
	saved.start_combat()
	saved.act("mira", "ability", 1)
	saved.persistence_enabled = true
	var path := "res://verification/test-save.json"
	expect(saved.save_game(path), "Atomic save writes")
	expect(saved.save_game(path), "Atomic save replaces existing file on Windows")
	var loaded = fresh()
	expect(loaded.load_game(path), "Load succeeds")
	if not loaded.in_combat():
		print("GAME TESTS ABORTED: saved battle was not loaded")
		quit(1)
		return
	expect(JSON.stringify(loaded.data) == JSON.stringify(JSON.parse_string(JSON.stringify(saved.data))), "Combat and all state round-trip")
	expect(loaded.data.combat.acted == ["mira"], "Spent turn persists")
	expect(not loaded.act("mira", "attack"), "Reload cannot grant extra action")
	var bad := FileAccess.open("res://verification/bad-save.json", FileAccess.WRITE)
	bad.store_string('{"version":1,"heroes":"broken"}')
	bad.close()
	expect(not loaded.load_game("res://verification/bad-save.json"), "Malformed save rejected")
	expect(not loaded._valid_save(null), "Null save rejected")
	var invalid: Dictionary = saved.data.duplicate(true)
	invalid.heroes[0].hp = "bad"
	expect(not loaded._valid_save(invalid), "Wrong health type rejected safely")
	invalid = saved.data.duplicate(true)
	for h in invalid.heroes:
		h.hp = 0
	expect(not loaded._valid_save(invalid), "Inconsistent active battle rejected")
	print("GAME TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
