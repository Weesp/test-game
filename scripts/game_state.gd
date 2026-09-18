extends RefCounted

const World = preload("res://scripts/world_data.gd")
const SAVE_PATH = "user://campaign.json"
var data: Dictionary = {}
var last_message := ""
var persistence_enabled := true

func _init() -> void:
	reset(false)

func reset(write_save := true) -> void:
	data = {"version": 1, "location": "camp", "last_camp": "camp", "visited": ["camp"], "resolved": [], "flags": [], "scenes": [], "xp": 0, "level": 1, "heroes": [], "combat": {}, "journal": ["Найдите уголёк в старой часовне и принесите его в убежище у переправы."]}
	for spec in World.HEROES:
		data.heroes.append({"id": spec.id, "hp": spec.max_hp, "uses": spec.max_uses, "advanced_uses": 0})
	last_message = "Отряд готов к первому походу."
	if write_save:
		save_game()

func known(id: String) -> bool:
	return World.NODES[id].known or id in data.visited

func in_combat() -> bool:
	return not data.combat.is_empty()

func living() -> Array:
	return data.heroes.filter(func(h): return h.hp > 0)

func get_hero(id: String) -> Dictionary:
	for h in data.heroes:
		if h.id == id:
			return h
	return {}

func record(message: String) -> void:
	last_message = message
	data.journal.append(message)
	while data.journal.size() > 35:
		data.journal.pop_front()

func can_travel(id: String) -> bool:
	return not in_combat() and id in World.neighbors(data.location)

func travel(id: String) -> bool:
	if not can_travel(id):
		return false
	data.location = id
	if id not in data.visited:
		data.visited.append(id)
	if World.NODES[id].kind == "camp":
		data.last_camp = id
	record("Прибытие: " + World.NODES[id].name + ".")
	save_game()
	return true

func rest() -> bool:
	if in_combat() or World.NODES[data.location].kind != "camp":
		return false
	_restore_party()
	var scene_id := ""
	var story := "Огонь потрескивает. Отряд восстановил здоровье и все заряды способностей."
	if "relic" in data.flags and data.location == "haven" and "relic_scene" not in data.scenes:
		scene_id = "relic_scene"
		data.flags.append("quest_complete")
		story = "Смотритель ставит ваш фонарь над воротами. Впервые за долгие годы туман отступает от переправы. Мира тихо говорит: «Значит, мы всё-таки можем что-то изменить». Поручение завершено."
	elif "helped_traveler" in data.flags and "traveler_scene" not in data.scenes:
		scene_id = "traveler_scene"
		story = "Веста узнаёт у костра спасённого путника. Он оставляет ей вырезанную из дерева птицу: «Думал, никому уже нет дела». Ивар молча пододвигает ему кружку."
	elif "first_rest" not in data.scenes:
		scene_id = "first_rest"
		story = "Ивар смотрит на угли: «До часовни дойдём. Вопрос — что принесём обратно». Веста укрывает фонарь плащом. Мира делает вид, что спит, но слушает каждое слово."
	if not scene_id.is_empty():
		data.scenes.append(scene_id)
	record(story)
	save_game()
	return true

func _restore_party() -> void:
	for h in data.heroes:
		var spec := World.hero(h.id)
		h.hp = spec.max_hp
		h.uses = spec.max_uses
		h.advanced_uses = 1 if data.level >= 2 else 0

func resolve_event(choice := "take") -> bool:
	if in_combat() or data.location in data.resolved:
		return false
	var kind: String = World.NODES[data.location].kind
	match kind:
		"herbs":
			for h in living():
				h.hp = mini(int(World.hero(h.id).max_hp), int(h.hp) + 6)
			record("Лечебный запас найден: живые герои восстановили по 6 здоровья. Заряды способностей не изменились.")
		"traveler":
			if choice == "help":
				var healer := get_hero("vesta")
				if healer.uses <= 0 or healer.hp <= 0:
					return false
				healer.uses -= 1
				data.flags.append("helped_traveler")
				record("Веста потратила заряд исцеления. Путник поднялся на ноги и отправился к ближайшему убежищу.")
			elif choice == "leave":
				data.flags.append("left_traveler")
				record("Вы оставили путнику дорогу к убежищу, но не смогли помочь с раной. Он молча смотрит вам вслед.")
			else:
				return false
		"relic":
			data.flags.append("relic")
			record("Веста бережно поднимает неугасающий уголёк. Отнесите фонарь в убежище у переправы и отдохните там.")
		_:
			return false
	data.resolved.append(data.location)
	save_game()
	return true

func start_combat() -> bool:
	var node: Dictionary = World.NODES[data.location]
	if in_combat() or node.kind != "fight" or data.location in data.resolved or living().is_empty():
		return false
	var enemies: Array = []
	for spec in World.ENCOUNTERS[node.encounter]:
		enemies.append({"name": spec.name, "hp": spec.hp, "max_hp": spec.hp, "attack": spec.attack})
	data.combat = {"enemies": enemies, "round": 1, "acted": [], "guard": {}, "status": "active"}
	record("Бой: " + node.name + ". Выберите героя, цель и действие.")
	save_game()
	return true

func can_act(id: String) -> bool:
	return in_combat() and data.combat.status == "active" and not get_hero(id).is_empty() and get_hero(id).hp > 0 and id not in data.combat.acted

func act(id: String, action: String, target := 0) -> bool:
	if not can_act(id) or action not in ["attack", "guard", "ability", "advanced"]:
		return false
	var h := get_hero(id)
	var spec := World.hero(id)
	var battle: Dictionary = data.combat
	if action == "ability" and h.uses <= 0:
		return false
	if action == "advanced" and (data.level < 2 or h.advanced_uses <= 0):
		return false
	if action == "attack" or (action == "ability" and id == "mira"):
		if target < 0 or target >= battle.enemies.size() or battle.enemies[target].hp <= 0:
			return false
	var result := ""
	match action:
		"attack":
			var damage := int(spec.attack) + (2 if data.level >= 2 else 0)
			battle.enemies[target].hp = maxi(0, int(battle.enemies[target].hp) - damage)
			result = "%s → %s: %d урона." % [spec.name, battle.enemies[target].name, damage]
		"guard":
			battle.guard[id] = int(battle.guard.get(id, 0)) + 9
			result = spec.name + ": защита поглотит 9 урона в этом раунде."
		"ability":
			h.uses -= 1
			if id == "ivar":
				_damage_all(8)
			elif id == "mira":
				battle.enemies[target].hp = maxi(0, int(battle.enemies[target].hp) - 15)
			else:
				var wounded: Array = living()
				wounded.sort_custom(func(a, b): return (float(a.hp) / World.hero(a.id).max_hp) < (float(b.hp) / World.hero(b.id).max_hp))
				var patient: Dictionary = wounded[0]
				patient.hp = mini(int(World.hero(patient.id).max_hp), int(patient.hp) + 14)
			result = spec.name + ": " + spec.ability + ". " + spec.ability_hint + "."
		"advanced":
			h.advanced_uses -= 1
			if id == "mira":
				_damage_all(10)
			else:
				for ally in living():
					battle.guard[ally.id] = int(battle.guard.get(ally.id, 0)) + (8 if id == "ivar" else 4)
					if id == "vesta":
						ally.hp = mini(int(World.hero(ally.id).max_hp), int(ally.hp) + 7)
			result = spec.name + ": " + spec.advanced + ". " + spec.advanced_hint + "."
	battle.acted.append(id)
	record(result)
	if battle.enemies.all(func(e): return e.hp <= 0):
		_victory()
	elif living().all(func(ally): return ally.id in battle.acted):
		_enemy_phase()
	save_game()
	return true

func _damage_all(amount: int) -> void:
	for e in data.combat.enemies:
		e.hp = maxi(0, int(e.hp) - amount)

func _enemy_phase() -> void:
	var battle: Dictionary = data.combat
	var reports: Array[String] = []
	for index in range(battle.enemies.size()):
		var enemy: Dictionary = battle.enemies[index]
		if enemy.hp <= 0:
			continue
		var targets := living()
		if targets.is_empty():
			break
		var target: Dictionary = targets[(int(battle.round) - 1 + index) % targets.size()]
		var shield := int(battle.guard.get(target.id, 0))
		var damage := maxi(0, int(enemy.attack) - shield)
		battle.guard[target.id] = maxi(0, shield - int(enemy.attack))
		target.hp = maxi(0, int(target.hp) - damage)
		reports.append("%s → %s: %d" % [enemy.name, World.hero(target.id).name, damage])
	if living().is_empty():
		battle.status = "defeat"
		record("Отряд пал. Можно вернуться в последнее убежище и попробовать другой путь.")
	else:
		battle.round += 1
		battle.acted.clear()
		battle.guard.clear()
		record("Враги: " + "; ".join(reports) + ". Раунд %d — ваш ход." % battle.round)

func _victory() -> void:
	data.combat.status = "victory"
	data.resolved.append(data.location)
	data.xp += 40
	var message := "Победа! +40 опыта. Здоровье и оставшиеся заряды сохраняются до отдыха."
	if data.level == 1 and data.xp >= 80:
		data.level = 2
		for h in data.heroes:
			h.advanced_uses = 1
		message += " УРОВЕНЬ 2: каждому герою открыта новая способность, обычные атаки усилены на 2."
	record(message)

func leave_combat() -> bool:
	if not in_combat() or data.combat.status == "active":
		return false
	if data.combat.status == "defeat":
		data.location = data.last_camp
		_restore_party()
		record("Отряд вернулся в убежище. Раны залечены; незавершённая встреча всё ещё ждёт на дороге.")
	data.combat = {}
	save_game()
	return true

func save_game(path := SAVE_PATH) -> bool:
	if not persistence_enabled:
		return true
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_message = "Не удалось записать сохранение. Прогресс пока хранится только в текущем сеансе."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	if error != OK:
		last_message = "Не удалось обновить файл сохранения."
	return error == OK

func load_game(path := SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _valid_save(parsed):
		last_message = "Сохранение повреждено или имеет другой формат. Начат новый поход."
		return false
	data = parsed
	last_message = "Поход продолжен. " + str(data.journal.back() if not data.journal.is_empty() else "")
	return true

func _valid_save(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in ["version", "location", "last_camp", "visited", "resolved", "flags", "scenes", "xp", "level", "heroes", "combat", "journal"]:
		if not value.has(key):
			return false
	if value.version != 1 or not value.location is String or not World.NODES.has(value.location):
		return false
	if value.last_camp not in ["camp", "haven"] or not _number(value.level) or int(value.level) not in [1, 2] or not _number(value.xp) or value.xp < 0:
		return false
	for key in ["visited", "resolved", "flags", "scenes", "journal"]:
		if not value[key] is Array:
			return false
		for item in value[key]:
			if not item is String:
				return false
	for id in value.visited + value.resolved:
		if not World.NODES.has(id):
			return false
	if value.location not in value.visited or value.last_camp not in value.visited:
		return false
	if not value.heroes is Array or value.heroes.size() != 3 or not value.combat is Dictionary:
		return false
	for i in range(3):
		var h = value.heroes[i]
		var spec: Dictionary = World.HEROES[i]
		if not h is Dictionary or h.get("id") != spec.id:
			return false
		for key in ["hp", "uses", "advanced_uses"]:
			if not _number(h.get(key)) or h[key] < 0:
				return false
		if h.hp > spec.max_hp or h.uses > spec.max_uses or h.advanced_uses > 1:
			return false
	var combat: Dictionary = value.combat
	var any_hero_alive: bool = value.heroes.any(func(h): return h.hp > 0)
	if not combat.is_empty():
		if World.NODES[value.location].kind != "fight":
			return false
		if combat.get("status") not in ["active", "victory", "defeat"] or not _number(combat.get("round")) or combat.round < 1:
			return false
		if not combat.get("acted") is Array or not combat.get("guard") is Dictionary or not combat.get("enemies") is Array or combat.enemies.is_empty():
			return false
		for id in combat.acted:
			if id not in ["ivar", "mira", "vesta"]:
				return false
		for id in combat.guard:
			if id not in ["ivar", "mira", "vesta"] or not _number(combat.guard[id]) or combat.guard[id] < 0:
				return false
		for e in combat.enemies:
			if not e is Dictionary or not e.get("name") is String:
				return false
			for key in ["hp", "max_hp", "attack"]:
				if not _number(e.get(key)) or e[key] < 0:
					return false
			if e.max_hp <= 0 or e.hp > e.max_hp:
				return false
		var any_enemy_alive: bool = combat.enemies.any(func(e): return e.hp > 0)
		if combat.status == "active" and (not any_hero_alive or not any_enemy_alive):
			return false
		if combat.status == "victory" and (any_enemy_alive or not any_hero_alive or value.location not in value.resolved):
			return false
		if combat.status == "defeat" and (any_hero_alive or not any_enemy_alive):
			return false
	elif not any_hero_alive:
		return false
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))
