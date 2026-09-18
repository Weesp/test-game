# Генерация иллюстраций

Режим: встроенный ImageGen (built-in), без CLI/API. Файлы сохранены в этой папке и используются проектом. Материалы референса в игру не включены.

## Утверждённые спутницы

Выбраны Мира М2 «Ледяное стекло» (`approved/mira.png`) и Веста В1 «Последний фонарь» (`approved/vesta.png`). У Весты удалена седая прядь, сохранены зрелое лицо и каштановая коса. Оба оригинала подключены к бою и портретам без перерисовки. Полные промпты и происхождение: `APPROVED_ASSETS.json`; отдельные маски для прозрачного отображения и их запросы: `MASK_GENERATION.json`. Режим генерации масок — встроенный ImageGen.

## world-map-v2.png

Статус: Черновик карты.

Промпт:

```text
Use case: stylized-concept. INPUT IMAGE IS STYLE REFERENCE ONLY: use its stylized simplified painted game art, NOT its UI. Create an original 16:9 full-bleed 2D dark fantasy world map background asset. Match reference's strongly stylized hand-painted game illustration: LARGE CHUNKY ANGULAR FORMS, rough visible broad brush strokes, exaggerated crooked silhouettes, bold hand-painted value planes, minimal tiny detail, graphic storybook shapes, flat illustrative surfaces, simple sharp angular roofs and trees, intentionally distorted fairy tale proportions. The forms must read as painted game art at thumbnail size. This is NOT realistic scenery, NOT 3D rendering, NOT photographic textures, NOT fine etched engraving, NOT highly intricate detail. Muted charcoal olive grey, dark near-black woods, restrained ochre brushwork, isolated orange campfire and cold grey-green ground. View elevated oblique top-down, no horizon, no sky. A continuous compact explorable landscape: clearing with tiny campfire and ragged tent at lower left; crooked bare tree on center-left fork; spiky dead grove upper left; tiny roofless cottage further north; narrow black swamp river down center with an exaggerated crooked wooden bridge in middle; low ford south of bridge; overturned small boat lower right; broken well mid-right; simple ruined gothic chapel upper right; tiny shelter with orange fire in upper middle. Curving pale thin footpaths between clearings, deep shadowed islands of angular fir trees, black negative spaces, painterly fog smudges. Leave open ground around landmarks for interactive markers. No UI, no written words, no letters, no circles, no map nodes, no cards, no portraits, no characters, no monsters. Entire frame is the illustrated game world. Reference is only style inspiration; make original assets.
```

## cast-draft.png

Статус: Временные спутники и враги; первый столбец не используется.

Промпт:

```text
Use case: stylized-concept. Asset type: transparent sprite atlas for a static 2D dark fantasy RPG. Input image is STYLE REFERENCE ONLY for angular hand-painted rendering and palette. Genuine transparent alpha background, no coloured or checkerboard background, no floor, no scene, no cast shadows outside figures. Exactly FIVE separated full-body standing figures in ONE horizontal row of FIVE equally wide cells, each centered in its own cell, same baseline, generous transparent margins between. Wide landscape sprite sheet. Cell 1: weary stocky male warrior in ragged russet cloak, angular iron shoulder armour, dark beard, sword held pointed downward; faces three-quarters RIGHT. Cell 2: lean female mage with sharp features, dark blue-grey hooded cloak, pale face, gnarled staff with small cold blue light; faces three-quarters RIGHT. Cell 3: female lantern bearer in faded olive robe, pale shawl, tired resolute face, brass lantern in one hand; faces three-quarters RIGHT. Cell 4: grotesque lanky tree-root undead with crooked branch antlers, hunched shoulders and long claws, pale wood face, tiny dim ochre eyes; faces LEFT toward party. Cell 5: tall hollow rusted gothic suit of armour with ragged mossy dark mantle and long spear, narrow empty helmet and faint ember eyes; faces LEFT. All five figures completely visible from head to boots, no overlap. Exaggerated expressive jagged silhouettes, rough large brush strokes, hard graphic shadows, asymmetrical storybook proportions, grim and serious, excellent readable 2D painted game sprites. Not photorealistic, not cute cartoon, not 3D, not tiny intricate textures. Match reference stylisation. No text, no labels, no boxes, no UI. Transparent background.
```

## ivar-painted-v5.png

Статус: Принят пользователем как начальная база.

Промпт:

```text
Create ONE full-body hand-painted 2D DARK FANTASY RPG warrior illustration, isolated on actual transparent background, facing three-quarters RIGHT in an experienced ready stance. Input image is reference for DRAWN PAINTERLY GAME STYLE, not photorealism. Strong expressive stylized silhouette, bold controlled brushwork, illustrated face, simplified light and shadow planes. NOT a photograph, NOT a realistic 3D render, NOT live-action costume, NO photographic skin pores or material noise.
The design itself is highly developed FANTASY: armour forged from overlapping broad dark blue-black plates in an invented angular leaf-like pattern, a high segmented neck guard to fend off monster bites, one large asymmetric shoulder guard built around a SINGLE pale curved beast carapace plate, bronze ward inlay embedded in the chest in the shape of a broken sun with three rays. This is a recognisable invented order of monster hunters. Purposeful detailed construction at joins, edges and buckles, cloth embroidered with a few large protective angular motifs rather than generic historical knight clothing. A battered wine-red half-cloak shows a large repaired slash and an old faded order emblem.
Believable history expressed through designed visual details: one shoulder replaced with salvaged metal, a visibly reforged crack near the armour edge, different leather colour on a repaired strap. Scar crossing eyebrow, grey streak in short black beard, narrowed watchful illustrated eyes. Broad physical weight, slightly exaggerated shoulder silhouette, clear readable form.
Main weapon: unusual fantasy greatsword with a dark broad blade, asymmetric hooked guard and a few wide bronze glyphs near the hilt. Backup short war axe clearly held at belt behind the left hip, plus an easily reached straight dagger in front sheath. All attached purposefully; left hand ready, legs in grounded veteran stance. These objects tell how he survives disarming and close fighting. No decorative junk, no dangling skulls, no forest of tiny spikes, no excessive belts, no all-over grunge, no shredded fringe. Rich detail in fantasy DESIGN, not microtextures. Limit palette to charcoal steel, muted bone, worn bronze, oxblood cloth. Painted dark-fantasy illustration like a carefully designed RPG character, visibly an artwork. Full body visible with margin, no ground, no background scene, no frame, no labels, no text. Transparent alpha background.
```

## battle-painted-v6.png

Статус: Черновик после замечаний о дороге, геометрии святилища и пятнах на земле.

Промпт:

```text
Use case: precise-object-edit. Edit the provided battlefield illustration for a 2D painted dark fantasy RPG. The second image is a crop identifying the REJECTED angular road treatment, not a style reference. Keep the full first image's wide 16:9 layout, forest atmosphere, large left tree, shrine in upper right, and empty lower half for gameplay. Substantially repaint the ground and shrine architecture.
The entire ground must read as ONE continuous surface of muted brown compacted earth. Broad softly merged paint strokes follow the lay of the land. Very low texture contrast, only sparse small naturally rounded stones at the margins. Remove all square, polygonal, colourful, patchwork-like brush fragments. No paving or tile pattern. No mosaic, facets, hard geometric brush polygons. The pilgrim footpath goes from between the two left background standing stones toward the front of the shrine in ONE direct, gently curved passage across the back of the clearing, with natural soft grassy edges and coherent perspective. No sharp bends, no zigzags or stairs in the dirt path.
Rebuild the shrine as a clear structurally coherent fantasy stone canopy: exactly FOUR weather-worn curved stone ribs stand on the four corners of a simple low round stone plinth and join together at ONE common solid stone crown at the top. The ribs visibly physically connect at their upper ends into this crown. One iron chain hangs VERTICALLY from the CENTER UNDERSIDE of this joined crown. That chain supports ONE modest bronze brazier suspended centrally beneath the canopy, centered between its supports, with small amber flame. Do not hang it from a separate side rib. Show the structure clearly in three-quarter view with natural rounded eroded edges and simple restrained fantasy carving. No spiky obelisks or disconnected uprights. Keep shrine subordinate in size to the open playable clearing.
Repaint angular foreground stones, roots and branches into organic asymmetric flowing contours. Leave foreground mostly unobstructed. Broader simplified masses of foliage fading into mist. Painterly variation within coherent tonal masses rather than chunks. Hand-painted dark fantasy illustration with readable silhouettes and natural drawing; NOT a photograph, NOT realism, NOT 3D, NOT low-poly, NOT cut-paper. The image should convey an old maintained pilgrimage clearing gradually reclaimed by the forest, with sensible functional construction. Do not add clutter, characters, UI, text, symbols in the dirt, vignette frame, or dramatic new props. Restrained harmonious olive-grey and earth-brown palette, soft illustrated light, one warm flame accent.
```

Для карты, атласа и воина использован предоставленный скриншот как ориентир рисованной подачи. Для поля v6 входами служили отклонённое поле v5 и присланный пользователем фрагмент проблемной дороги. Фрагмент обозначен как пример ошибки, а не желаемый стиль.

## concepts/griffin-basilisk-v1.png

Статус: проба смешения фэнтезийной анатомии; не утверждена, в игру не подключена. Не считать готовым спрайтом. Режим: встроенный ImageGen. Вход: принятый рисунок воина как ориентир рисованной подачи.

```text
Use case: stylized-concept. Create one original monster concept for a hand-painted dark fantasy RPG. Input warrior image is a reference for illustrative rendering and level of meaningful design detail ONLY. No warrior in result. Actual transparent alpha background, full creature visible, facing three-quarters LEFT, feet aligned on one implied ground plane, margin around silhouette.
Creative idea: uncanny biological interpenetration inspired by the mutating ecology of Annihilation, but the organisms being intermingled are FANTASY CREATURES: a griffin being rewritten by a basilisk. Not merely a classic intact griffin with a snake tail. One coherent living body whose anatomy has changed.
Strong memorable readable silhouette: crouching heavy griffin hindquarters and one tall folded feathered wing contrasted with an elongated arched basilisk neck and low watchful head. The other wing has partially transformed into a weight-bearing reptilian forelimb; long flight-feather shafts smoothly thicken into the three bony digits of that new limb. Feathers along its shoulder progressively widen and fuse into a small number of broad overlapping basilisk scales, with clear organic transitions rather than sewn-on parts. One skull where a curved avian upper beak flows into an unsettling extended reptilian lower jaw. One restrained amber eye, a second dormant eye just beneath the translucent eyelid ridge, subtle rather than a pile of eyeballs. Musculature and stance must plausibly support its distorted weight. Not symmetrical, not a collection of attached animal heads. A faint weathered opalescence confined to the feather-scale transition makes it strangely beautiful and wrong.
Painterly 2D illustration, expressive organic contours, confidently painted broad shadows, controlled detail around the transformative anatomy and face; simplify the rest. Desaturated bone, deep umber, faded blue-green scales, tiny muted amber eye. Avoid photorealism, 3D rendering, random all-over grunge, tiny spikes, excessive ornament, gore, exposed viscera, multiple unrelated motifs, busy fractal texture, glowing neon. No armour, equipment, ruins, scenic background, text, labels, UI, grid, floor shadow, or checkerboard. The creature itself must tell the story of two fantasy life forms becoming one.
```

Последнее замечание автора после генераций: местность всё ещё рябит из-за мелкой контрастной фактуры. Поле v6 не принято. Для последующих генераций руководствоваться `docs/АРТ-НАПРАВЛЕНИЕ.md`; старые промпты сохранены как история полученных файлов, а не как окончательный стиль.
