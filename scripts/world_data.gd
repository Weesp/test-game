extends RefCounted

const NODES = {
	"camp": {"name": "Старый костёр", "kind": "camp", "pos": Vector2(140, 520), "text": "Каменная ограда ещё держит тьму на расстоянии. Здесь можно перевести дух перед дорогой.", "known": true},
	"fork": {"name": "Развилка у вяза", "kind": "road", "pos": Vector2(265, 402), "text": "Северная тропа уходит в лес. На востоке слышна вода. Обе дороги ведут к старой переправе.", "known": true},
	"grove": {"name": "Голодная роща", "kind": "fight", "pos": Vector2(145, 258), "text": "Между стволами шевелятся фигуры. Они загораживают заброшенную стоянку, но пока не замечают отряд.", "encounter": "grove", "known": false},
	"lookout": {"name": "Дом травницы", "kind": "herbs", "pos": Vector2(310, 125), "text": "На подоконнике пустого дома сохнут лечебные травы. Их хватит, чтобы немного залечить раны отряда.", "known": false},
	"bridge": {"name": "Сломанный мост", "kind": "fight", "pos": Vector2(470, 285), "text": "У затопленного подхода к мосту рыщут два сросшихся чудовища. За водой виден свет убежища.", "encounter": "bridge", "known": true},
	"ford": {"name": "Тихий брод", "kind": "road", "pos": Vector2(452, 490), "text": "Вода скрывает старую дорогу. Отсюда можно повернуть к мосту или обойти болото с юга.", "known": true},
	"hermit": {"name": "Раненый путник", "kind": "traveler", "pos": Vector2(648, 530), "text": "У перевёрнутой лодки сидит раненый. Веста может потратить один заряд исцеления, чтобы помочь ему.", "known": false},
	"shrine": {"name": "Колодец тишины", "kind": "herbs", "pos": Vector2(810, 396), "text": "Из-под каменной плиты бьёт чистая вода. Один раз здесь можно восстановить по 6 здоровья, но отдохнуть небезопасно.", "known": false},
	"sentinel": {"name": "Страж часовни", "kind": "fight", "pos": Vector2(669, 247), "text": "Перед святилищем шевелятся пустые доспехи. Из щита раскрывается пасть, а с каменного свода спускается крылатое существо.", "encounter": "sentinel", "known": true},
	"chapel": {"name": "Погасшая часовня", "kind": "relic", "pos": Vector2(821, 119), "text": "Под обрушенным куполом уцелел фонарь. В его стекле тлеет уголёк, который не гаснет уже много лет.", "known": true},
	"haven": {"name": "Убежище у переправы", "kind": "camp", "pos": Vector2(554, 88), "text": "За частоколом горят фонари. Здесь отряд может отдохнуть и рассказать смотрителю о находке в часовне.", "known": true},
}

const EDGES = [
	["camp", "fork"], ["fork", "grove"], ["grove", "lookout"],
	["lookout", "bridge"], ["fork", "ford"], ["ford", "bridge"],
	["ford", "hermit"], ["hermit", "shrine"], ["shrine", "sentinel"],
	["bridge", "haven"], ["bridge", "sentinel"], ["haven", "sentinel"],
	["sentinel", "chapel"],
]

const HEROES = [
	{"id": "ivar", "name": "Ивар", "role": "ВОИН", "max_hp": 36, "attack": 7, "ability": "Рассечение", "ability_hint": "8 урона всем врагам", "max_uses": 2, "advanced": "Несокрушимость", "advanced_hint": "8 защиты всему отряду", "color": Color("c18b60")},
	{"id": "mira", "name": "Мира", "role": "ЧАРОДЕЙКА", "max_hp": 25, "attack": 5, "ability": "Огненное копьё", "ability_hint": "15 урона выбранному врагу", "max_uses": 3, "advanced": "Ледяная волна", "advanced_hint": "10 урона всем врагам", "color": Color("819eac")},
	{"id": "vesta", "name": "Веста", "role": "ХРАНИТЕЛЬНИЦА", "max_hp": 29, "attack": 5, "ability": "Исцеление", "ability_hint": "+14 здоровья самому раненому живому герою", "max_uses": 3, "advanced": "Оберег", "advanced_hint": "+7 здоровья и 4 защиты живым героям", "color": Color("a4ae84")},
]

const ENCOUNTERS = {
	"grove": [{"name": "Тролль-корневик", "art": "troll", "hp": 20, "attack": 5}, {"name": "Дриада-арахна", "art": "dryad", "hp": 23, "attack": 5}],
	"bridge": [{"name": "Грифон-василиск", "art": "griffin", "hp": 28, "attack": 7}, {"name": "Кельпи-гидра", "art": "kelpie", "hp": 22, "attack": 6}],
	"sentinel": [{"name": "Мимик-щитоносец", "art": "mimic_shield", "hp": 26, "attack": 5}, {"name": "Мимик-пожиратель", "art": "mimic_chest", "hp": 14, "attack": 4}, {"name": "Горгулья-виверна", "art": "wyvern", "hp": 16, "attack": 5}],
}

static func neighbors(id: String) -> Array:
	var result: Array = []
	for edge in EDGES:
		if edge[0] == id:
			result.append(edge[1])
		elif edge[1] == id:
			result.append(edge[0])
	return result

static func hero(id: String) -> Dictionary:
	for item in HEROES:
		if item.id == id:
			return item
	return {}
