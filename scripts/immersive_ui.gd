extends Control

const State = preload("res://scripts/game_state.gd")
const World = preload("res://scripts/world_data.gd")
const MapView = preload("res://scripts/world_map.gd")
const BattleView = preload("res://scripts/battle_view.gd")
const Ornate = preload("res://scripts/ornate_panel.gd")
const Portrait = preload("res://scripts/portrait_button.gd")
const INK = Color("ded5ba")
const MUTED = Color("aba58f")
const GOLD = Color("c6ab70")
var game = State.new()
var selected := "camp"
var active_hero := "ivar"
var enemy_target := 0
var map_view
var battle_view
var root_layout: Control
var popup_layer: Control
var overlay_mode := ""
var capture_path := ""
var map_origin := Vector2.ZERO
var animate_next := false
var toast := ""
var toast_timer: Timer

func _ready() -> void:
	get_window().min_size = Vector2i(1000, 650)
	var args := OS.get_cmdline_user_args()
	var index := args.find("--capture")
	if index >= 0 and index + 1 < args.size():
		capture_path = args[index + 1]
		game.persistence_enabled = false
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1600, 900)
	elif game.persistence_enabled:
		game.load_game()
	if "--demo-battle" in args:
		game.persistence_enabled = false
		game.reset(false)
		game.travel("fork")
		game.travel("grove")
		game.start_combat()
	if "--demo-popup" in args:
		overlay_mode = "location"
	if "--demo-actions" in args:
		overlay_mode = "actions"
	selected = game.data.location
	_apply_theme()
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.timeout.connect(func(): toast = ""; _refresh_hud())
	add_child(toast_timer)
	build_ui()
	if not capture_path.is_empty():
		_capture.call_deferred()

func _apply_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 17
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color("fff0c8"))
	t.set_color("font_disabled_color", "Button", Color("645f50"))
	t.set_stylebox("normal", "Button", _style(Color("25271d"), Color("655a3e"), 12))
	t.set_stylebox("hover", "Button", _style(Color("37372a"), GOLD, 12))
	t.set_stylebox("pressed", "Button", _style(Color("45402b"), GOLD, 12))
	t.set_stylebox("disabled", "Button", _style(Color("171a15"), Color("34362b"), 12))
	t.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, GOLD, 12))
	t.set_stylebox("panel", "TooltipPanel", _style(Color("121710"), GOLD, 12))
	t.set_color("font_color", "TooltipLabel", INK)
	theme = t

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE: _open("menu" if overlay_mode.is_empty() else "")
		KEY_J: _open("journal" if overlay_mode != "journal" else "")
		KEY_P: _open("party" if overlay_mode != "party" else "")
		KEY_F11: _toggle_fullscreen()

func _toggle_fullscreen() -> void:
	get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func build_ui() -> void:
	if is_instance_valid(root_layout):
		remove_child(root_layout)
		root_layout.queue_free()
	root_layout = Control.new()
	root_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_layout)
	if game.in_combat():
		if not game.can_act(active_hero):
			active_hero = _first_actor()
		if enemy_target >= game.data.combat.enemies.size() or game.data.combat.enemies[enemy_target].hp <= 0:
			for i in range(game.data.combat.enemies.size()):
				if game.data.combat.enemies[i].hp > 0:
					enemy_target = i
					break
		battle_view = BattleView.new()
		battle_view.game = game
		battle_view.selected_enemy = enemy_target
		battle_view.active_hero = active_hero
		battle_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root_layout.add_child(battle_view)
		battle_view.hero_selected.connect(_choose_hero)
		battle_view.enemy_selected.connect(_select_enemy)
	else:
		map_view = MapView.new()
		map_view.game = game
		map_view.selected = selected
		map_view.clip_contents = true
		map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root_layout.add_child(map_view)
		map_view.location_selected.connect(func(id): selected = id; _open("location"))
		if animate_next:
			map_view.marker = map_origin
			map_view.set_location(game.data.location)
			animate_next = false
		else:
			map_view.set_location(game.data.location, false)
	_refresh_hud()

func _refresh_hud() -> void:
	var old := root_layout.get_node_or_null("HUD")
	if old:
		root_layout.remove_child(old)
		old.queue_free()
	var hud := Control.new()
	hud.name = "HUD"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_layout.add_child(hud)
	var region := VBoxContainer.new()
	region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region.position = Vector2(36, 28)
	hud.add_child(region)
	region.add_child(_label(World.NODES[game.data.location].name if game.in_combat() else "Земли погасших огней", 21, INK))
	region.add_child(_label("Раунд %d · выберите героя" % game.data.combat.round if game.in_combat() and game.data.combat.status == "active" else "Окрестности переправы", 12, MUTED))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	_place(hud, bar, Vector2(0.5, 0), Vector2(-92, 20), Vector2(184, 48))
	for item in [["♜", "party", "Отряд · P"], ["≡", "journal", "Журнал · J"], ["☷", "menu", "Меню · Esc"]]:
		var button := _button(item[0], _open.bind(item[1]))
		button.name = item[1]
		button.tooltip_text = item[2]
		button.custom_minimum_size = Vector2(48, 44)
		button.add_theme_font_size_override("font_size", 23)
		button.add_theme_stylebox_override("normal", _style(Color(0.04, 0.045, 0.03, 0.42), Color(0.65, 0.55, 0.35, 0.32), 9))
		bar.add_child(button)
	var portraits := HBoxContainer.new()
	portraits.add_theme_constant_override("separation", 13)
	_place(hud, portraits, Vector2(0.5, 1), Vector2(-118, -112), Vector2(236, 90))
	for spec in World.HEROES:
		var h: Dictionary = game.get_hero(spec.id)
		var portrait := Portrait.new()
		portrait.name = spec.id
		portrait.hero_id = spec.id
		portrait.tint = spec.color
		portrait.health = float(h.hp) / spec.max_hp
		portrait.chosen = game.in_combat() and active_hero == spec.id and game.can_act(spec.id)
		portrait.tooltip_text = "%s · %d/%d здоровья\n%s: %d/%d" % [spec.name, h.hp, spec.max_hp, spec.ability, h.uses, spec.max_uses]
		portrait.pressed.connect(_choose_hero.bind(spec.id))
		portraits.add_child(portrait)
	var hint := _label("J · журнал     P · отряд     F11 · полный экран", 11, MUTED)
	_place(hud, hint, Vector2(0, 1), Vector2(28, -34), Vector2(400, 20))
	if not toast.is_empty() and overlay_mode.is_empty():
		var note := _label(toast, 15, INK, true)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(hud, note, Vector2(0.5, 0), Vector2(-360, 82), Vector2(720, 65))
	if game.in_combat() and game.data.combat.status != "active" and overlay_mode.is_empty():
		overlay_mode = "result"
	if not overlay_mode.is_empty():
		_popup(hud)

func _open(mode: String) -> void:
	overlay_mode = mode
	_refresh_hud()

func _popup(hud: Control) -> void:
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(popup_layer)
	var actions := overlay_mode == "actions"
	if not actions:
		var dim := ColorRect.new()
		dim.color = Color(0.015, 0.02, 0.015, 0.5)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _open(""))
		popup_layer.add_child(dim)
	var panel := Ornate.new()
	panel.name = "Popup"
	if actions:
		_place(popup_layer, panel, Vector2(0.5, 1), Vector2(-400, -340), Vector2(800, 208))
	else:
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup_layer.add_child(center)
		panel.custom_minimum_size.x = 570 if overlay_mode in ["journal", "party", "story"] else 460
		center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var emblem := _label("◆", 16, GOLD)
	emblem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(emblem)
	var close := _button("×", _open.bind(""))
	close.name = "close_popup"
	close.custom_minimum_size = Vector2(30, 28)
	top.add_child(close)
	match overlay_mode:
		"location": _location_content(box)
		"actions": _actions_content(box)
		"journal": _journal_content(box)
		"party": _party_content(box)
		"story":
			box.add_child(_label("У огня" if World.NODES[game.data.location].kind == "camp" else "В дороге", 32, GOLD))
			box.add_child(_label(game.last_message, 21, INK, true))
			box.add_child(_button("Продолжить", _open.bind("")))
		"result":
			box.add_child(_label("Победа" if game.data.combat.status == "victory" else "Отряд пал", 34, GOLD))
			box.add_child(_label(game.last_message, 18, INK, true))
			box.add_child(_button("Продолжить путь" if game.data.combat.status == "victory" else "Вернуться в убежище", _leave_battle))
		"menu":
			box.add_child(_label("Тропа углей", 34, GOLD))
			box.add_child(_button("Продолжить поход", _open.bind("")))
			box.add_child(_button("Полный экран · F11", _toggle_fullscreen))
			box.add_child(_button("Новый поход", _open.bind("confirm")))
			box.add_child(_button("Выйти из игры", func(): get_tree().quit()))
		"confirm":
			box.add_child(_label("Новый поход", 30, GOLD))
			box.add_child(_label("Текущее сохранение будет заменено. Начать заново?", 18, INK, true))
			box.add_child(_button("Начать заново", func(): game.reset(); selected = "camp"; active_hero = "ivar"; enemy_target = 0; overlay_mode = ""; build_ui()))
			box.add_child(_button("Отмена", _open.bind("menu")))

func _location_content(box: VBoxContainer) -> void:
	var node: Dictionary = World.NODES[selected]
	var current: bool = selected == game.data.location
	box.add_child(_label(node.name if game.known(selected) else "Неизвестное место", 30, GOLD, true))
	box.add_child(_label(node.text if game.known(selected) else "За туманом виднеется тропа. Узнать, что ждёт там, можно только в пути.", 18, INK, true))
	if not current:
		if game.can_travel(selected):
			box.add_child(_button("Отправиться →", _travel))
		else:
			box.add_child(_label("Прямой дороги отсюда нет. Выберите соседнюю точку.", 15, MUTED, true))
		return
	if selected in game.data.resolved:
		box.add_child(_label("Это место уже исследовано.", 15, MUTED))
	else:
		match node.kind:
			"fight": box.add_child(_button("Вступить в бой", _start_battle))
			"herbs": box.add_child(_button("Восстановить здоровье +6", _event.bind("take")))
			"traveler":
				var h: Dictionary = game.get_hero("vesta")
				box.add_child(_button("Помочь · 1 заряд Весты", _event.bind("help"), h.uses <= 0 or h.hp <= 0))
				box.add_child(_button("Оставить путника", _event.bind("leave")))
			"relic": box.add_child(_button("Забрать неугасающий уголёк", _event.bind("take")))
	if node.kind == "camp":
		box.add_child(_label("УБЕЖИЩЕ · здесь можно отдохнуть", 12, MUTED))
		box.add_child(_button("Отдохнуть у огня", _rest))
	else:
		box.add_child(_label("Для отдыха нужно безопасное место.", 13, MUTED))

func _actions_content(box: VBoxContainer) -> void:
	if not game.can_act(active_hero):
		box.add_child(_label("Герой уже действовал. Выберите другого.", 17))
		return
	var h: Dictionary = game.get_hero(active_hero)
	var spec: Dictionary = World.hero(active_hero)
	box.add_child(_label("%s  →  %s" % [spec.name, game.data.combat.enemies[enemy_target].name], 19, GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var actions := [
		["Атака", "attack", "%d урона выбранному противнику" % (spec.attack + (2 if game.data.level >= 2 else 0)), false],
		["Защита", "guard", "Поглощает 9 урона до конца раунда", false],
		["%s · %d" % [spec.ability, h.uses], "ability", spec.ability_hint, h.uses <= 0],
		["%s · %d" % [spec.advanced, h.advanced_uses] if game.data.level >= 2 else "Уровень II", "advanced", spec.advanced_hint, game.data.level < 2 or h.advanced_uses <= 0]
	]
	for a in actions:
		var button := _button(a[0], _perform.bind(a[1]), a[3])
		button.tooltip_text = a[2]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	box.add_child(_label("Цель — клик по противнику. Подробности способности — при наведении.", 12, MUTED))

func _journal_content(box: VBoxContainer) -> void:
	box.add_child(_label("Путевой журнал", 32, GOLD))
	var quest := "Найдите уголёк в погасшей часовне."
	if "quest_complete" in game.data.flags:
		quest = "Поручение завершено. Уголёк горит над переправой."
	elif "relic" in game.data.flags:
		quest = "Принесите уголёк в убежище у переправы и отдохните."
	box.add_child(_label("Неугасающий", 20))
	box.add_child(_label(quest, 16, GOLD, true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 310
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var history := VBoxContainer.new()
	history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history.add_theme_constant_override("separation", 20)
	scroll.add_child(history)
	var entries: Array = game.data.journal.duplicate()
	entries.reverse()
	for entry in entries:
		history.add_child(_label(entry, 16, INK, true))

func _party_content(box: VBoxContainer) -> void:
	box.add_child(_label("Спутники", 32, GOLD))
	box.add_child(_label("Уровень %d · опыт %d" % [game.data.level, game.data.xp], 14, MUTED))
	for spec in World.HEROES:
		var h: Dictionary = game.get_hero(spec.id)
		box.add_child(_label(spec.name + "  /  " + spec.role, 20, spec.color))
		box.add_child(_label("Здоровье %d/%d · %s %d/%d" % [h.hp, spec.max_hp, spec.ability, h.uses, spec.max_uses], 16, INK, true))
		if game.data.level >= 2:
			box.add_child(_label("%s %d/1 · %s" % [spec.advanced, h.advanced_uses, spec.advanced_hint], 14, MUTED, true))

func _travel() -> void:
	map_origin = MapView.POINTS[game.data.location]
	if game.travel(selected):
		animate_next = true
		overlay_mode = ""
	build_ui()

func _rest() -> void:
	if game.rest():
		overlay_mode = "story"
	build_ui()

func _event(choice: String) -> void:
	if game.resolve_event(choice):
		overlay_mode = "story"
	build_ui()

func _start_battle() -> void:
	if game.start_combat():
		active_hero = _first_actor()
		enemy_target = 0
		overlay_mode = ""
	build_ui()

func _leave_battle() -> void:
	game.leave_combat()
	selected = game.data.location
	overlay_mode = ""
	build_ui()

func _first_actor() -> String:
	for h in game.data.heroes:
		if game.can_act(h.id):
			return h.id
	return "ivar"

func _select_enemy(index: int) -> void:
	if game.in_combat() and game.data.combat.status == "active" and game.data.combat.enemies[index].hp > 0:
		enemy_target = index
		battle_view.selected_enemy = index
		battle_view.queue_redraw()
		_refresh_hud()

func _choose_hero(id: String) -> void:
	if game.in_combat() and not game.can_act(id):
		return
	active_hero = id
	if game.in_combat():
		if game.can_act(id):
			battle_view.active_hero = id
			battle_view.queue_redraw()
			_open("actions")
	else:
		_open("party")

func _perform(action: String) -> void:
	if game.act(active_hero, action, enemy_target):
		toast = game.last_message
		toast_timer.start(6)
		active_hero = _first_actor()
		overlay_mode = "" if game.data.combat.status == "active" else "result"
	build_ui()

func _place(parent: Control, child: Control, anchor: Vector2, offset: Vector2, extent: Vector2) -> void:
	parent.add_child(child)
	child.anchor_left = anchor.x
	child.anchor_right = anchor.x
	child.anchor_top = anchor.y
	child.anchor_bottom = anchor.y
	child.offset_left = offset.x
	child.offset_top = offset.y
	child.offset_right = offset.x + extent.x
	child.offset_bottom = offset.y + extent.y

func _label(text: String, font_size := 16, color := INK, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	if font_size >= 20:
		var display_font := SystemFont.new()
		display_font.font_names = PackedStringArray(["Georgia", "Noto Serif"])
		label.add_theme_font_override("font", display_font)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, callback: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.disabled = disabled
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(callback)
	return button

func _style(fill: Color, border: Color, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0 else 0)
	box.set_content_margin_all(padding)
	return box

func _capture() -> void:
	for i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(capture_path)
	print("CAPTURE_RESULT=", result)
	get_tree().quit(0 if result == OK else 1)
