extends Control

const State = preload("res://scripts/game_state.gd")
const World = preload("res://scripts/world_data.gd")
const MapView = preload("res://scripts/world_map.gd")
const BattleView = preload("res://scripts/battle_view.gd")
const INK = Color("ded9c5")
const MUTED = Color("9ba598")
const GOLD = Color("d3b77b")
var game = State.new()
var selected := "camp"
var active_hero := "ivar"
var enemy_target := 0
var map_view
var root_layout: VBoxContainer
var confirmation: ConfirmationDialog
var capture_path := ""
var map_origin := Vector2.ZERO
var animate_next := false

func _ready() -> void:
	get_window().min_size = Vector2i(1000, 650)
	var args := OS.get_cmdline_user_args()
	var capture_index := args.find("--capture")
	if capture_index >= 0 and capture_index + 1 < args.size():
		capture_path = args[capture_index + 1]
		game.persistence_enabled = false
	elif game.persistence_enabled:
		game.load_game()
	if "--demo-battle" in args:
		game.persistence_enabled = false
		game.reset(false)
		game.travel("fork")
		game.travel("grove")
		game.start_combat()
	selected = game.data.location
	_apply_theme()
	build_ui()
	if not capture_path.is_empty():
		_capture.call_deferred()

func _apply_theme() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 16
	ui_theme.set_color("font_color", "Label", INK)
	ui_theme.set_color("font_color", "Button", INK)
	ui_theme.set_color("font_hover_color", "Button", Color("fff0cb"))
	ui_theme.set_color("font_disabled_color", "Button", Color("657065"))
	ui_theme.set_stylebox("normal", "Button", _style(Color("26352e"), Color("485543"), 6, 13))
	ui_theme.set_stylebox("hover", "Button", _style(Color("374738"), GOLD, 6, 13))
	ui_theme.set_stylebox("pressed", "Button", _style(Color("48533c"), GOLD, 6, 13))
	ui_theme.set_stylebox("disabled", "Button", _style(Color("1a2420"), Color("303a31"), 6, 13))
	ui_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), GOLD, 6, 13))
	ui_theme.set_stylebox("panel", "TooltipPanel", _style(Color("1d2923"), GOLD, 4, 12))
	ui_theme.set_color("font_color", "TooltipLabel", INK)
	theme = ui_theme

func build_ui() -> void:
	if is_instance_valid(root_layout):
		remove_child(root_layout)
		root_layout.queue_free()
	if is_instance_valid(confirmation):
		remove_child(confirmation)
		confirmation.queue_free()
	root_layout = VBoxContainer.new()
	root_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_layout.add_theme_constant_override("separation", 0)
	add_child(root_layout)
	_header()
	var page := MarginContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		page.add_theme_constant_override("margin_" + side, 24)
	page.add_theme_constant_override("margin_top", 16)
	page.add_theme_constant_override("margin_bottom", 16)
	root_layout.add_child(page)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	page.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 330
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	if game.in_combat():
		_build_battle(left, right)
	else:
		_build_map(left, right)
	_party_strip(left)
	_journal(right)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 18)
	left.add_child(foot)
	foot.add_child(_label("ПРОТОТИП 0.1", 11, MUTED))
	var caption := _label("Мышь · выбор точки и действий     /     Автосохранение после каждого действия", 12, MUTED)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.add_child(caption)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Начать новый поход?"
	confirmation.dialog_text = "Текущее сохранение будет заменено. Начать заново?"
	confirmation.ok_button_text = "Начать заново"
	confirmation.cancel_button_text = "Продолжить поход"
	confirmation.confirmed.connect(func(): game.reset(); selected = "camp"; active_hero = "ivar"; enemy_target = 0; build_ui())
	add_child(confirmation)

func _header() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("111a17"), Color("354134"), 0, 22))
	root_layout.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", 1)
	row.add_child(brand)
	brand.add_child(_label("Т Р О П А   У Г Л Е Й", 27, INK))
	brand.add_child(_label("ГЛАВА I    /    СВЕТ ПО ТУ СТОРОНУ БОЛОТА", 11, GOLD))
	var progression := VBoxContainer.new()
	progression.custom_minimum_size.x = 185
	row.add_child(progression)
	progression.add_child(_label("УРОВЕНЬ ОТРЯДА  %d" % game.data.level, 12, GOLD))
	progression.add_child(_label("Опыт  %d / 80" % game.data.xp if game.data.level == 1 else "Новые способности открыты", 13, MUTED))
	var new_button := _button("Новый поход", func(): confirmation.popup_centered(Vector2i(430, 160)))
	new_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(new_button)

func _build_map(left: VBoxContainer, right: VBoxContainer) -> void:
	var heading := HBoxContainer.new()
	left.add_child(heading)
	var name_label := _label("Окрестности переправы", 21, INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(name_label)
	heading.add_child(_label("●  УБЕЖИЩЕ     ◇  ВСТРЕЧА     ?  НЕИЗВЕСТНОЕ", 11, MUTED))
	var border := PanelContainer.new()
	border.size_flags_vertical = Control.SIZE_EXPAND_FILL
	border.add_theme_stylebox_override("panel", _style(Color("15201b"), Color("47523f"), 8, 2))
	left.add_child(border)
	map_view = MapView.new()
	map_view.game = game
	map_view.clip_contents = true
	map_view.selected = selected
	map_view.custom_minimum_size = Vector2(500, 410)
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	border.add_child(map_view)
	map_view.location_selected.connect(func(id): selected = id; build_ui())
	if animate_next:
		map_view.marker = map_origin
		map_view.set_location(game.data.location)
		animate_next = false
	else:
		map_view.set_location(game.data.location, false)
	_location_panel(right)

func _location_panel(right: VBoxContainer) -> void:
	var box := _card(right, Color("1b2720"))
	var node: Dictionary = World.NODES[selected]
	var current: bool = selected == game.data.location
	var is_known: bool = game.known(selected)
	box.add_child(_label("ТЕКУЩЕЕ МЕСТО" if current else "ВЫБРАННЫЙ МАРШРУТ", 11, GOLD))
	box.add_child(_label(node.name if is_known else "Неизвестное место", 25, INK, true))
	box.add_child(_label(node.text if is_known else "На карте здесь только отметка. Что скрывает туман, станет ясно, когда отряд доберётся до этого места.", 16, MUTED, true))
	_separator(box)
	if not current:
		if game.can_travel(selected):
			box.add_child(_label("Дорога доступна · один переход", 13, GOLD, true))
			box.add_child(_button("Отправиться →", _travel))
		else:
			box.add_child(_label("Прямой дороги отсюда нет. Выберите соседнюю точку, соединённую тропой.", 14, MUTED, true))
		box.add_child(_button("К отряду", func(): selected = game.data.location; build_ui()))
	else:
		if selected in game.data.resolved:
			box.add_child(_label("✓  Место исследовано", 14, Color("b8c694")))
		else:
			match node.kind:
				"fight":
					box.add_child(_label("Встреча · +40 опыта за победу", 13, Color("c89779"), true))
					box.add_child(_button("Вступить в бой", func(): game.start_combat(); active_hero = _first_actor(); enemy_target = 0; build_ui()))
				"herbs":
					box.add_child(_button("Восстановить здоровье +6", func(): game.resolve_event(); build_ui()))
				"traveler":
					var h: Dictionary = game.get_hero("vesta")
					box.add_child(_button("Помочь · 1 заряд Весты", func(): game.resolve_event("help"); build_ui(), h.uses <= 0 or h.hp <= 0))
					box.add_child(_button("Оставить путника", func(): game.resolve_event("leave"); build_ui()))
				"relic":
					box.add_child(_button("Забрать неугасающий уголёк", func(): game.resolve_event(); build_ui()))
		if node.kind == "camp":
			box.add_child(_label("БЕЗОПАСНОЕ МЕСТО", 12, GOLD))
			box.add_child(_button("Отдохнуть у огня", func(): game.rest(); build_ui()))
			box.add_child(_label("Полное здоровье и все заряды. У костра могут открыться новые разговоры.", 13, MUTED, true))
		else:
			box.add_child(_label("Отдых здесь недоступен. Выберите следующую точку на карте.", 13, MUTED, true))
	var quest := _card(right, Color("161f1b"))
	quest.add_child(_label("ПОРУЧЕНИЕ  /  НЕУГАСАЮЩИЙ", 11, GOLD))
	var text := "Найдите уголёк в погасшей часовне."
	if "quest_complete" in game.data.flags:
		text = "✓ Уголёк зажжён над переправой. Первое поручение завершено. Можно исследовать оставшиеся дороги."
	elif "relic" in game.data.flags:
		text = "Вернитесь в убежище у переправы и отдохните, чтобы передать находку смотрителю."
	quest.add_child(_label(text, 15, INK, true))

func _travel() -> void:
	map_origin = World.NODES[game.data.location].pos
	if game.travel(selected):
		animate_next = true
	build_ui()

func _build_battle(left: VBoxContainer, right: VBoxContainer) -> void:
	var battle: Dictionary = game.data.combat
	if not game.can_act(active_hero):
		active_hero = _first_actor()
	if enemy_target >= battle.enemies.size() or battle.enemies[enemy_target].hp <= 0:
		for i in range(battle.enemies.size()):
			if battle.enemies[i].hp > 0:
				enemy_target = i
				break
	var heading := HBoxContainer.new()
	left.add_child(heading)
	var title := _label(World.NODES[game.data.location].name, 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_label("РАУНД %d  /  ВАШ ХОД" % battle.round if battle.status == "active" else "БОЙ ОКОНЧЕН", 12, GOLD))
	var arena := BattleView.new()
	arena.game = game
	arena.clip_contents = true
	arena.custom_minimum_size = Vector2(500, 250)
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(arena)
	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 10)
	left.add_child(target_row)
	for i in range(battle.enemies.size()):
		var enemy: Dictionary = battle.enemies[i]
		var title_text: String = ("◎  " if i == enemy_target and enemy.hp > 0 else "") + enemy.name
		var button := _button("%s\n%d / %d здоровья  ·  атака %d" % [title_text, enemy.hp, enemy.max_hp, enemy.attack], _select_enemy.bind(i), enemy.hp <= 0 or battle.status != "active")
		button.custom_minimum_size.y = 66
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_row.add_child(button)
	left.add_child(_label("Выберите героя внизу, затем цель и действие справа. Каждый герой действует один раз за раунд.", 13, MUTED, true))
	var box := _card(right, Color("1c2821"))
	if battle.status != "active":
		box.add_child(_label("ПОБЕДА" if battle.status == "victory" else "ОТРЯД ПАЛ", 27, GOLD))
		box.add_child(_label(game.last_message, 16, INK, true))
		box.add_child(_button("Продолжить путь" if battle.status == "victory" else "Вернуться в убежище", func(): game.leave_combat(); selected = game.data.location; build_ui()))
		return
	var spec := World.hero(active_hero)
	var h: Dictionary = game.get_hero(active_hero)
	box.add_child(_label("ДЕЙСТВИЕ ГЕРОЯ", 11, GOLD))
	box.add_child(_label(spec.name, 27, spec.color))
	box.add_child(_label("Цель: " + battle.enemies[enemy_target].name, 14, MUTED, true))
	_separator(box)
	box.add_child(_button("Атака · %d урона" % (spec.attack + (2 if game.data.level >= 2 else 0)), _perform.bind("attack")))
	box.add_child(_button("Защита · поглотить 9 урона", _perform.bind("guard")))
	var special := _button("%s · %d/%d" % [spec.ability, h.uses, spec.max_uses], _perform.bind("ability"), h.uses <= 0)
	special.tooltip_text = spec.ability_hint
	box.add_child(special)
	box.add_child(_label(spec.ability_hint + ". Заряды до отдыха.", 13, MUTED, true))
	var advanced := _button(("%s · %d/1" % [spec.advanced, h.advanced_uses]) if game.data.level >= 2 else "Откроется на уровне 2", _perform.bind("advanced"), game.data.level < 2 or h.advanced_uses <= 0)
	box.add_child(advanced)
	box.add_child(_label(spec.advanced_hint if game.data.level >= 2 else "Две победы откроют новую способность каждому герою.", 13, MUTED, true))

func _first_actor() -> String:
	for h in game.data.heroes:
		if game.can_act(h.id):
			return h.id
	return "ivar"

func _select_enemy(index: int) -> void:
	enemy_target = index
	build_ui()

func _perform(action: String) -> void:
	game.act(active_hero, action, enemy_target)
	active_hero = _first_actor()
	build_ui()

func _party_strip(left: VBoxContainer) -> void:
	var heading := HBoxContainer.new()
	left.add_child(heading)
	var title := _label("ВАШ ОТРЯД", 11, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_label("Здоровье и заряды восстанавливаются в убежищах", 12, MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	left.add_child(row)
	for spec in World.HEROES:
		var h: Dictionary = game.get_hero(spec.id)
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var border := GOLD if game.in_combat() and active_hero == spec.id and game.can_act(spec.id) else Color("3b493b")
		panel.add_theme_stylebox_override("panel", _style(Color("1a261f"), border, 6, 13))
		row.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 5)
		panel.add_child(column)
		var hero_name := "%s  /  %s" % [spec.name, spec.role]
		if game.in_combat():
			var can_use: bool = game.can_act(spec.id)
			var actor := _button(hero_name + ("  ✓" if spec.id in game.data.combat.acted else ""), _choose_hero.bind(spec.id), not can_use)
			actor.add_theme_font_size_override("font_size", 12)
			actor.custom_minimum_size.y = 30
			column.add_child(actor)
		else:
			column.add_child(_label(hero_name, 13, spec.color))
		var bar := ProgressBar.new()
		bar.max_value = spec.max_hp
		bar.value = h.hp
		bar.show_percentage = false
		bar.custom_minimum_size.y = 5
		bar.add_theme_stylebox_override("background", _style(Color("101914"), Color.TRANSPARENT, 2, 0))
		bar.add_theme_stylebox_override("fill", _style(spec.color, Color.TRANSPARENT, 2, 0))
		column.add_child(bar)
		var hp_text := "%d / %d здоровья" % [h.hp, spec.max_hp]
		if game.in_combat() and game.data.combat.guard.get(spec.id, 0) > 0:
			hp_text += " · щит %d" % game.data.combat.guard[spec.id]
		column.add_child(_label(hp_text, 13, INK))
		column.add_child(_label("%s  %d/%d" % [spec.ability, h.uses, spec.max_uses], 12, MUTED))
		if game.data.level >= 2:
			column.add_child(_label("%s  %d/1" % [spec.advanced, h.advanced_uses], 12, GOLD))

func _choose_hero(id: String) -> void:
	active_hero = id
	build_ui()

func _journal(right: VBoxContainer) -> void:
	var box := _card(right, Color("141e19"))
	box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_label("У КОСТРА И В ДОРОГЕ", 11, GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 110
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var messages := VBoxContainer.new()
	messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages.add_theme_constant_override("separation", 15)
	scroll.add_child(messages)
	messages.add_child(_label(game.last_message, 15, INK, true))
	var history: Array = game.data.journal.duplicate()
	history.reverse()
	var count := 0
	for entry in history:
		if entry == game.last_message:
			continue
		messages.add_child(_label(entry, 13, MUTED, true))
		count += 1
		if count == 5:
			break

func _card(parent: Container, color: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, Color("3a4738"), 7, 18))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box

func _separator(parent: Container) -> void:
	var line := HSeparator.new()
	line.add_theme_color_override("color", Color("46503d"))
	parent.add_child(line)

func _label(text: String, font_size := 16, color := INK, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, callback: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 43
	button.disabled = disabled
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(callback)
	return button

func _style(fill: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

func _capture() -> void:
	for i in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	var result := screenshot.save_png(capture_path)
	print("CAPTURE_RESULT=", result, " PATH=", capture_path)
	get_tree().quit(0 if result == OK else 1)
