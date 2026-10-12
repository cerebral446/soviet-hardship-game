-- Norilsk: Last Shift. Shared settings, places and story text.
-- Positions are in studs. North is -Z. The avenue runs north from the housing to the mine.

local Config = {}

Config.Title = "НОРИЛЬСК: ПОСЛЕДНЯЯ СМЕНА"
Config.TitleEnglish = "NORILSK: LAST SHIFT"

Config.WalkSpeed = 10
Config.SprintSpeed = 16
Config.StaminaSeconds = 6 -- how long a full sprint lasts
Config.StaminaRegen = 7 -- seconds to refill from empty

-- Places the builders and the game logic agree on.
Config.Places = {
	Apartment = Vector3.new(0, -150, 0), -- the player's flat (interior, reached through the door)
	HomeDoor = Vector3.new(-90.5, 0, 30), -- Building 14, entrance 2 (courtyard side)
	MineGate = Vector3.new(0, 0, -200),
	CageHouse = Vector3.new(0, 0, -280),
	Underground = Vector3.new(0, -300, -280), -- floor centre of the cage landing, horizon -300
	CanteenDoor = Vector3.new(70, 0, -105),
	CanteenWindowSpot = Vector3.new(58, 0, -124),
}

-- Indoor areas (min corner, max corner). No snow, calmer air.
Config.Interiors = {
	{ Vector3.new(-14, -152, -11), Vector3.new(14, -138, 11) }, -- apartment
	{ Vector3.new(70, -2, -135), Vector3.new(110, 15, -75) }, -- canteen
	{ Vector3.new(-55, -2, -245), Vector3.new(-25, 13, -225) }, -- lamp room
	{ Vector3.new(-13, -2, -292), Vector3.new(13, 17, -268) }, -- cage house
	{ Vector3.new(15, -2, -209), Vector3.new(25, 9, -199) }, -- checkpoint booth
}
Config.UndergroundBelow = -200 -- y below this counts as the mine

-- Story stages. "spot" is where you come back after being caught or respawning.
-- "threat" picks what the entity does: none, glimpse, mineIdle, mineHunt, canteen, hunt.
Config.Stages = {
	{ ru = "Собирайся на смену", en = "Get dressed and leave for your shift.", clock = "05:50", spot = "aptStart", threat = "none" },
	{ ru = "Отметься на проходной шахты № 6", en = "Clock in at the Mine No. 6 checkpoint. Follow the avenue north.", clock = "06:10", spot = "homeDoorOut", threat = "glimpse" },
	{ ru = "Получи лампу в ламповой", en = "Collect your lamp from the lamp room, left of the yard.", clock = "06:25", spot = "gate", threat = "glimpse" },
	{ ru = "Спустись в клети", en = "Ride the cage down to horizon −300.", clock = "06:35", spot = "gate", threat = "none" },
	{ ru = "Выполни норму", en = "Meet the quota: break ore from the five marked seams.", clock = "07:00", spot = "ugLanding", threat = "mineIdle" },
	{ ru = "Вернись к клети", en = "The lamps are dying. Get back to the cage.", clock = "15:40", spot = "ugNorth", threat = "mineHunt" },
	{ ru = "Иди в столовую № 3", en = "Go to Stolovaya No. 3 and hand in your meal coupon.", clock = "18:20", spot = "cageTop", threat = "glimpse" },
	{ ru = "Поешь", en = "Sit at your table and eat.", clock = "18:45", spot = "canteenInside", threat = "canteen" },
	{ ru = "Иди домой", en = "Walk home. Building 14, entrance 2, through the courtyard.", clock = "23:10", spot = "canteenDoor", threat = "hunt" },
	{ ru = "Ты дома", en = "You are home.", clock = "23:40", spot = "aptEnd", threat = "none" },
}
Config.FinalStage = #Config.Stages
Config.SeamCount = 5
Config.NightFrom = 9 -- from this stage the town is empty and pitch dark

-- The thing that follows you.
Config.Entity = {
	-- Night walk: it walks your exact footsteps.
	Speed = 11.5, -- studs/s while nobody is looking at it (you walk at 10)
	StillSpeed = 20, -- when you stand still
	StartDelay = 45, -- how far you get from the canteen door before it comes out
	MaxLag = 80, -- it never falls further behind than this
	DoorFloor = 40, -- when you reach your door it is at least this far behind
	CatchDistance = 4.5,
	-- Looking at it freezes it, but staring is dangerous.
	StareLimit = 3, -- seconds of staring before it blinks closer
	BlinkJump = 16,
	ViewDot = 0.82, -- how close to the centre of the screen counts as looking
	-- Underground.
	MineSpeed = 8.5,
	-- Glimpses in the morning and evening.
	GlimpseEvery = { 30, 55 },
	GlimpseVanishDistance = 38,
	GlimpseVanishStare = 1.3,
}

-- Underground route graph for the entity (local to Places.Underground).
Config.MineNodes = {
	landing = Vector3.new(0, 0, -6),
	westJunction = Vector3.new(0, 0, -70),
	westMid = Vector3.new(-55, 0, -70),
	westStope = Vector3.new(-125, 0, -70),
	eastJunction = Vector3.new(0, 0, -140),
	eastMid = Vector3.new(50, 0, -140),
	eastStope = Vector3.new(115, 0, -140),
	north = Vector3.new(0, 0, -213),
	oldGallery = Vector3.new(-70, 0, -213),
}
Config.MineEdges = {
	{ "landing", "westJunction" },
	{ "westJunction", "westMid" },
	{ "westMid", "westStope" },
	{ "westJunction", "eastJunction" },
	{ "eastJunction", "eastMid" },
	{ "eastMid", "eastStope" },
	{ "eastJunction", "north" },
	{ "north", "oldGallery" },
}
Config.MineLairs = { "oldGallery", "westStope", "eastStope" }

-- People walking in the town (client side). Points are on the ground.
-- Everyone is gone from Config.NightFrom on.
Config.Walkers = {
	{
		stages = { 1, 2, 3, 4 },
		count = 9,
		routes = {
			{ Vector3.new(-96, 0, 0), Vector3.new(-100, 0, -40), Vector3.new(-40, 0, -40), Vector3.new(-20, 0, -41), Vector3.new(-7, 0, -60), Vector3.new(-6, 0, -200), Vector3.new(-2, 0, -262) },
			{ Vector3.new(-96, 0, 60), Vector3.new(-104, 0, -42), Vector3.new(-40, 0, -43), Vector3.new(-20, 0, -44), Vector3.new(-8, 0, -80), Vector3.new(-5, 0, -200), Vector3.new(2, 0, -262) },
			{ Vector3.new(58, 0, 0), Vector3.new(40, 0, -20), Vector3.new(19.5, 0, -25), Vector3.new(19.5, 0, -185), Vector3.new(6, 0, -200), Vector3.new(4, 0, -262) },
			{ Vector3.new(58, 0, 60), Vector3.new(19.5, 0, 50), Vector3.new(19.5, 0, -185), Vector3.new(5, 0, -200), Vector3.new(-1, 0, -262) },
			{ Vector3.new(0, 0, 105), Vector3.new(-18.5, 0, 90), Vector3.new(-18.5, 0, -185), Vector3.new(-6, 0, -200), Vector3.new(-3, 0, -262) },
			{ Vector3.new(-96, 0, -110), Vector3.new(-100, 0, -175), Vector3.new(-40, 0, -185), Vector3.new(-8, 0, -198), Vector3.new(-6, 0, -206), Vector3.new(-22, 0, -235) },
		},
	},
	{
		stages = { 7, 8 },
		count = 4,
		routes = {
			{ Vector3.new(0, 0, -262), Vector3.new(5, 0, -205), Vector3.new(19.5, 0, -185), Vector3.new(19.5, 0, 50), Vector3.new(58, 0, 60) },
			{ Vector3.new(2, 0, -262), Vector3.new(-5, 0, -205), Vector3.new(-7, 0, -60), Vector3.new(-12, 0, -44), Vector3.new(-40, 0, -43), Vector3.new(-100, 0, -40), Vector3.new(-96, 0, 0) },
			{ Vector3.new(-3, 0, -262), Vector3.new(-6, 0, -205), Vector3.new(-18.5, 0, -185), Vector3.new(-18.5, 0, 90), Vector3.new(0, 0, 105) },
		},
	},
}

-- Built-in Roblox sounds so the game works with no uploads. Swap any id for your own
-- "rbxassetid://..." audio to make it scarier (wind, a drone, a real scream...).
Config.Audio = {
	Wind = { id = "rbxasset://sounds/action_falling.mp3", volume = 0.35, pitch = 0.35, looped = true },
	MineHum = { id = "rbxasset://sounds/action_swim.mp3", volume = 0.25, pitch = 0.3, looped = true },
	Footsteps = { id = "rbxasset://sounds/action_footsteps_plastic.mp3", volume = 1.4, pitch = 0.55, looped = true },
	Heartbeat = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.9, pitch = 0.45 },
	Sting = { id = "rbxasset://sounds/action_falling.mp3", volume = 1.2, pitch = 0.18 },
	Scream = { id = "rbxasset://sounds/uuhhh.mp3", volume = 3, pitch = 0.55 },
	ScreamLow = { id = "rbxasset://sounds/action_falling.mp3", volume = 3, pitch = 0.12 },
	Pick = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 1.2, pitch = 1.7 },
	Knock = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 2.5, pitch = 0.6 },
	Click = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.6, pitch = 2.2 },
	Drip = { id = "rbxasset://sounds/impact_water.mp3", volume = 0.35, pitch = 2.5 },
	Groan = { id = "rbxasset://sounds/uuhhh.mp3", volume = 1.5, pitch = 0.3 },
}

-- Posters. At night the slogans change.
Config.Posters = {
	{ title = "СЛАВА ТРУДУ!", sub = "Glory to labour", night = "НЕ СМОТРИ НА НЕГО ДОЛГО", nightSub = "Do not look at it for long", bg = Color3.fromRGB(150, 30, 26), fg = Color3.fromRGB(236, 222, 186) },
	{ title = "ПЯТИЛЕТКУ — ДОСРОЧНО!", sub = "The Five-Year Plan ahead of schedule", night = "ОН ТОЖЕ ВЫПОЛНЯЕТ ПЛАН", nightSub = "It fulfils its quota too", bg = Color3.fromRGB(226, 208, 160), fg = Color3.fromRGB(140, 24, 22) },
	{ title = "НИКЕЛЬ — РОДИНЕ!", sub = "Nickel for the Motherland", night = "ОН ВОЗВРАЩАЕТСЯ ЗА КАЖДОЙ СМЕНОЙ", nightSub = "It comes back for every shift", bg = Color3.fromRGB(40, 44, 48), fg = Color3.fromRGB(220, 60, 45) },
	{ title = "НЕ БОЛТАЙ!", sub = "Loose talk helps the enemy", night = "МОЛЧИ. ОН СЛЫШИТ.", nightSub = "Be quiet. It hears.", bg = Color3.fromRGB(230, 220, 190), fg = Color3.fromRGB(30, 30, 30) },
	{ title = "ТЕХНИКА БЕЗОПАСНОСТИ — ЗАКОН!", sub = "Safety rules are law", night = "ЛАМПА № 117 НЕ ВОЗВРАЩЕНА", nightSub = "Lamp No. 117 was never returned", bg = Color3.fromRGB(210, 160, 30), fg = Color3.fromRGB(25, 25, 25) },
	{ title = "ХЛЕБ — БОГАТСТВО НАШЕ", sub = "Bread is our wealth. Treasure it.", night = "ТЫ ПОСЛЕДНИЙ", nightSub = "You are the last one", bg = Color3.fromRGB(196, 120, 40), fg = Color3.fromRGB(250, 240, 210) },
	{ title = "ВПЕРЁД, К ПОБЕДЕ КОММУНИЗМА!", sub = "Forward to the victory of communism", night = "ИДИ. НЕ ОСТАНАВЛИВАЙСЯ.", nightSub = "Walk. Do not stop.", bg = Color3.fromRGB(160, 28, 30), fg = Color3.fromRGB(250, 214, 90) },
}

-- Lore notes hidden around town and the mine.
Config.Notes = {
	{
		title = "Письмо от матери / A letter from Mother",
		text = "Красноярск, 2 декабря 1984\n\nMy son,\nYou write that the money is good, but you do not write that you are well. Come home in the summer. The north eats people, your father always said so.\n\nAnd what about your neighbour, Pyotr — did they ever find him? His wife wrote to his sister that the militia stopped looking after one week.\n\nWalk home with the others. Do not walk alone.\n— Mama",
	},
	{
		title = "Объявление / Missing person notice",
		text = "РАЗЫСКИВАЕТСЯ — MISSING\n\nВОЛКОВ Геннадий Петрович, b. 1949. Underground miner, Mine No. 6.\nLast seen 14 November, walking home alone from Stolovaya No. 3 after 23:00.\nWearing a grey padded coat and a rabbit-fur ushanka.\n\nAnyone with information, contact the militia, Leninsky Prospekt 9.\n\n(Someone has written underneath in pencil: \"Он не один. Их уже семь.\" — \"He is not the only one. That makes seven.\")",
	},
	{
		title = "Журнал ламповой / Lamp room ledger",
		text = "Lamp issued / returned:\n\n№ 112 — Kuzmin — returned\n№ 113 — Ostapenko — returned\n№ 117 — ??? — NOT RETURNED\n...\n12.12.1984  № 117 — NOT RETURNED\n13.03.1971  № 117 — NOT RETURNED\n04.01.1962  № 117 — NOT RETURNED\n19.11.1953  № 117 — NOT RETURNED\n\nThe pages go back thirty years. The same hand wrote every line.",
	},
	{
		title = "Надпись на досках / Scratched into the boards",
		text = "1952. Шахта Норильлага.\n\nОн ходит за последним. Ему нужен тот, кто идёт один.\nIt walks behind the last man. It wants the one who walks alone.\n\nКогда смотришь — стоит. Смотришь долго — подходит ближе.\nWhile you look, it stands. Look too long and it comes closer.\n\nНе останавливайся. Do not stop.\n\n(The rest is worn away by hands.)",
	},
	{
		title = "Секретно / Secret memorandum",
		text = "КГБ СССР — Норильский отдел\nСЕКРЕТНО\n\nRe: disappearances on Leninsky Prospekt, sector 4.\n\n1. Do not discuss outside the department.\n2. Workers of the second shift are to walk home in groups after 22:00.\n3. The streetlights in sector 4 keep failing. Electricians refuse to go out at night. Replace them.\n4. The lamp issue journal of Mine No. 6 is to be confiscated.\n\nNobody is to say the word \"бригадир\" (foreman).",
	},
	{
		title = "Табличка у вышки / Plaque by the watchtower",
		text = "НОРИЛЬЛАГ, 1935–1956.\n\nHere, prisoners built the city and the mines.\n\nBelow, someone scratched a list of names into the metal, and next to the last one a single word:\n\nБРИГАДИР. He kept the count. He always walked behind the column, so that nobody fell behind.\n\nHe is still counting.",
	},
}

-- What the radio in the canteen says (subtitles).
Config.Radio = {
	"Радио «Маяк»: Норильские горняки перевыполнили план на сто двенадцать процентов…",
	"Радио «Маяк»: …температура в Норильске минус сорок один градус. Ветер северный…",
	"Радио «Маяк»: …товарищ Черненко принял делегацию…",
	"Радио «Маяк»: …Never walk home alone. Never stop. Never look for long…",
}

return Config
