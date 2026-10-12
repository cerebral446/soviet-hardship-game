-- Stolovaya No. 3: the state canteen. Tiled floor, green-painted walls, a serving line,
-- a kitchen, and tired people eating shchi and drinking compote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Build = require(Shared.Build)
local Figure = require(Shared.Figure)
local Config = require(Shared.Config)

local rgb = Build.rgb
local block, detail = Build.block, Build.detail

local Canteen = {}

local SNOW = rgb(222, 228, 234)
local WALL = rgb(214, 208, 192)
local PAINT = rgb(128, 164, 140)
local STEEL = rgb(176, 178, 176)

local function show(model)
	model:SetAttribute("ShowFrom", 7)
	model:SetAttribute("ShowTo", 8)
	Build.tag(model, "StagedPerson")
	return model
end

local function plate(parent, at, food)
	detail(Build.cylinder(parent, "Plate", 0.12, 1.3, CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2), rgb(236, 234, 226), Enum.Material.SmoothPlastic))
	if food then
		detail(Build.cylinder(parent, "Food", 0.1, 0.95, CFrame.new(at + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2), food, Enum.Material.SmoothPlastic))
	end
end

local function glass(parent, at, drink)
	local g = detail(Build.column(parent, "Faceted glass", 0.6, 0.45, at, drink or rgb(150, 70, 50), Enum.Material.Glass))
	g.Transparency = 0.25
end

local FOODS = { rgb(170, 60, 40), rgb(200, 180, 130), rgb(120, 80, 50), rgb(220, 210, 170), rgb(150, 110, 60) }

local function steam(parent, at, rate)
	local p = detail(block(parent, "Steam", Vector3.new(1, 0.2, 1), at, rgb(255, 255, 255)))
	p.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = rate or 4
	e.Lifetime = NumberRange.new(1.5, 2.5)
	e.Speed = NumberRange.new(0.8, 1.5)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.8) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
end

local function table4(parent, x, z, rng)
	block(parent, "Table", Vector3.new(4, 0.25, 3.4), Vector3.new(x, 3.3, z), rgb(170, 186, 190), Enum.Material.SmoothPlastic)
	detail(block(parent, "Table leg", Vector3.new(0.5, 2.9, 0.5), Vector3.new(x, 1.85, z), rgb(80, 80, 80), Enum.Material.Metal))
	detail(block(parent, "Table foot", Vector3.new(2.4, 0.15, 1.6), Vector3.new(x, 0.48, z), rgb(80, 80, 80), Enum.Material.Metal))
	-- Salt, napkins.
	detail(Build.column(parent, "Salt", 0.5, 0.3, Vector3.new(x + 1.5, 3.42, z), rgb(236, 236, 236), Enum.Material.Glass))
	detail(block(parent, "Napkin holder", Vector3.new(0.7, 0.6, 0.3), Vector3.new(x + 1.5, 3.72, z + 0.6), rgb(200, 200, 196), Enum.Material.Metal))
	local seats = {}
	for _, s in { { -1, -2.3, 1 }, { 1, -2.3, 1 }, { -1, 2.3, -1 }, { 1, 2.3, -1 } } do
		local cx, cz, facing = x + s[1], z + s[2], s[3]
		block(parent, "Chair seat", Vector3.new(1.8, 0.25, 1.8), Vector3.new(cx, 2.1, cz), rgb(110, 76, 50), Enum.Material.Wood)
		detail(block(parent, "Chair leg", Vector3.new(0.3, 1.7, 0.3), Vector3.new(cx, 1.25, cz), rgb(70, 70, 70), Enum.Material.Metal))
		detail(block(parent, "Chair back", Vector3.new(1.8, 2.2, 0.2), Vector3.new(cx, 3.3, cz - facing * 0.85), rgb(110, 76, 50), Enum.Material.Wood))
		table.insert(seats, { pos = Vector3.new(cx, 0.4, cz), facing = Vector3.new(0, 0, facing), plate = Vector3.new(cx, 3.47, z - facing * 0.75) })
	end
	if rng:NextNumber() < 0.6 then
		detail(block(parent, "Bread", Vector3.new(1, 0.35, 0.7), Vector3.new(x - 1.5, 3.6, z), rgb(150, 100, 60), Enum.Material.Sand))
	end
	return seats
end

function Canteen.build(world)
	local spots = {}
	local m = Instance.new("Model")
	m.Name = "Stolovaya No. 3"
	m.Parent = world
	local rng = Random.new(3)

	-- Shell.
	local x0, x1, z0, z1, h = 70, 110, -135, -75, 14
	Build.wall(m, Vector3.new(x0, 0, z0), Vector3.new(x0, 0, z1), Vector3.new(-1, 0, 0), h, 1, {
		{ at = 12, width = 16, bottom = 2.5, top = 10 },
		{ at = 30, width = 6, top = 8 },
		{ at = 48, width = 16, bottom = 2.5, top = 10 },
	}, WALL, Enum.Material.Concrete)
	Build.wall(m, Vector3.new(x1, 0, z0), Vector3.new(x1, 0, z1), Vector3.new(1, 0, 0), h, 1, {}, WALL, Enum.Material.Concrete)
	Build.wall(m, Vector3.new(x0 - 1, 0, z0), Vector3.new(x1 + 1, 0, z0), Vector3.new(0, 0, -1), h, 1, {}, WALL, Enum.Material.Concrete)
	Build.wall(m, Vector3.new(x0 - 1, 0, z1), Vector3.new(x1 + 1, 0, z1), Vector3.new(0, 0, 1), h, 1, {}, WALL, Enum.Material.Concrete)
	block(m, "Roof", Vector3.new(42.6, 1, 62.6), Vector3.new(90, h + 0.5, -105), rgb(150, 146, 140))
	detail(block(m, "Roof snow", Vector3.new(42.4, 0.7, 62.4), Vector3.new(90, h + 1.35, -105), SNOW, Enum.Material.Snow))
	block(m, "Floor", Vector3.new(40, 0.4, 60), Vector3.new(90, 0.2, -105), rgb(200, 190, 170), Enum.Material.Slate)
	for ix = 0, 9 do
		for iz = 0, 14 do
			if (ix + iz) % 2 == 0 then
				detail(block(m, "Floor tile", Vector3.new(4, 0.04, 4), Vector3.new(x0 + 2 + ix * 4, 0.42, z0 + 2 + iz * 4), rgb(120, 60, 50), Enum.Material.Slate))
			end
		end
	end
	-- Painted dado: the lower walls are green, like every canteen and hospital in the Union.
	detail(block(m, "Wall paint", Vector3.new(40, 5, 0.08), Vector3.new(90, 2.9, z0 + 0.05), PAINT, Enum.Material.SmoothPlastic))
	detail(block(m, "Wall paint", Vector3.new(40, 5, 0.08), Vector3.new(90, 2.9, z1 - 0.05), PAINT, Enum.Material.SmoothPlastic))
	detail(block(m, "Wall paint", Vector3.new(0.08, 5, 60), Vector3.new(x1 - 0.05, 2.9, -105), PAINT, Enum.Material.SmoothPlastic))
	for _, seg in { { -135, -108 }, { -102, -75 } } do
		detail(block(m, "Wall paint", Vector3.new(0.08, 2.1, seg[2] - seg[1]), Vector3.new(x0 + 0.05, 1.45, (seg[1] + seg[2]) / 2), PAINT, Enum.Material.SmoothPlastic))
	end

	-- Big windows onto the street.
	for _, z in { -123, -87 } do
		local pane = block(m, "Canteen window", Vector3.new(0.2, 7.5, 16), Vector3.new(69.5, 6.25, z), rgb(170, 190, 196), Enum.Material.Glass)
		pane.Transparency = 0.45
		for dz = -4, 4, 4 do
			detail(block(m, "Window mullion", Vector3.new(0.4, 7.5, 0.25), Vector3.new(69.5, 6.25, z + dz), rgb(90, 86, 80), Enum.Material.Metal))
		end
		detail(block(m, "Window sill snow", Vector3.new(1, 0.4, 16.4), Vector3.new(68.6, 2.6, z), SNOW, Enum.Material.Snow))
		local frost = detail(block(m, "Frost", Vector3.new(0.1, 2, 16), Vector3.new(69.35, 3.5, z), rgb(236, 244, 250), Enum.Material.Glass))
		frost.Transparency = 0.5
	end

	-- Entrance.
	for _, z in { -108.2, -101.8 } do
		detail(block(m, "Open door", Vector3.new(3, 7.6, 0.25), CFrame.new(70.5 + 1.4, 3.8 + 0.2, z) * CFrame.Angles(0, 0, 0), rgb(110, 80, 50), Enum.Material.Wood))
	end
	block(m, "Entrance step", Vector3.new(6, 0.4, 10), Vector3.new(66, 0.2, -105), rgb(150, 150, 146))
	block(m, "Entrance canopy", Vector3.new(6, 0.5, 10), Vector3.new(66, 9.2, -105), rgb(150, 146, 140))
	detail(block(m, "Canopy snow", Vector3.new(5.8, 0.4, 9.8), Vector3.new(66, 9.6, -105), SNOW, Enum.Material.Snow))
	local lamp = detail(Build.ball(m, "Entrance lamp", 0.8, Vector3.new(66, 8.5, -105), rgb(255, 200, 130), Enum.Material.Neon))
	Build.light(lamp, rgb(255, 190, 120), 20, 1.1, true)
	Build.tag(lamp, "EntranceLamp")
	local sign = detail(block(m, "Canteen sign", Vector3.new(0.4, 3, 26), Vector3.new(68.8, 11.8, -105), rgb(236, 226, 200)))
	Build.sign(sign, Enum.NormalId.Left, "СТОЛОВАЯ № 3", { bg = rgb(236, 226, 200), fg = rgb(180, 30, 26), lightInfluence = 0.25, brightness = 1.3 })
	local sub = detail(block(m, "Canteen subsign", Vector3.new(0.3, 1, 14), Vector3.new(68.8, 9.9, -105), rgb(36, 56, 104)))
	Build.sign(sub, Enum.NormalId.Left, "ОБЩЕСТВЕННОЕ ПИТАНИЕ · 7:00–23:00", { bg = rgb(36, 56, 104), fg = rgb(240, 240, 230) })
	local signGlow = detail(block(m, "Sign glow", Vector3.new(0.2, 0.2, 0.2), Vector3.new(66, 12, -105), rgb(255, 255, 255)))
	signGlow.Transparency = 1
	Build.light(signGlow, rgb(255, 120, 100), 12, 0.6)
	local board = detail(block(m, "Menu stand", Vector3.new(0.3, 3.5, 2.6), Vector3.new(63, 2.4, -113), rgb(40, 50, 44)))
	Build.sign(board, Enum.NormalId.Left, "МЕНЮ\n12.12.84\nЩи · котлета\nкомпот", { bg = rgb(36, 48, 40), fg = rgb(236, 236, 226), font = Enum.Font.PermanentMarker, padding = 0.05 })
	spots.canteenDoor = CFrame.lookAt(Vector3.new(63, 3, -105), Vector3.new(30, 3, -105))
	spots.canteenInside = CFrame.lookAt(Vector3.new(75, 3, -105), Vector3.new(100, 3, -105))

	-- Lights.
	for _, x in { 80, 92 } do
		for _, z in { -125, -105, -85 } do
			local tube = detail(block(m, "Ceiling light", Vector3.new(1, 0.3, 7), Vector3.new(x, 13.7, z), rgb(226, 240, 230), Enum.Material.Neon))
			Build.surfaceLight(tube, Enum.NormalId.Bottom, rgb(216, 236, 224), 20, 1.1, 150)
			Build.tag(tube, "CanteenLight")
		end
	end

	-- Serving line.
	block(m, "Counter", Vector3.new(3, 3.2, 45), Vector3.new(101.5, 2, -108.5), STEEL, Enum.Material.Metal)
	detail(block(m, "Counter top", Vector3.new(3.4, 0.2, 45), Vector3.new(101.5, 3.7, -108.5), rgb(210, 210, 206), Enum.Material.Metal))
	detail(block(m, "Tray rail", Vector3.new(1, 0.12, 45), Vector3.new(99.4, 3.1, -108.5), rgb(200, 200, 196), Enum.Material.Metal))
	for z = -129, -89, 8 do
		detail(block(m, "Rail bracket", Vector3.new(0.6, 0.2, 0.2), Vector3.new(99.8, 2.9, z), rgb(160, 160, 156), Enum.Material.Metal))
	end
	for i = 0, 9 do
		detail(block(m, "Tray", Vector3.new(1.6, 0.08, 2.2), Vector3.new(101.5, 3.85 + i * 0.09, -129.5), rgb(150, 120, 90), Enum.Material.SmoothPlastic))
	end
	local hot = { rgb(170, 60, 40), rgb(200, 180, 130), rgb(120, 80, 50), rgb(230, 220, 180), rgb(110, 140, 80) }
	for i, food in hot do
		local z = -125 + (i - 1) * 5
		detail(block(m, "Food tray", Vector3.new(2.4, 0.6, 3.6), Vector3.new(101.5, 4.1, z), STEEL, Enum.Material.Metal))
		detail(block(m, "Food", Vector3.new(2.1, 0.1, 3.3), Vector3.new(101.5, 4.42, z), food, Enum.Material.SmoothPlastic))
		if i <= 3 then
			steam(m, Vector3.new(101.5, 4.6, z), 3)
		end
	end
	for i = 0, 5 do
		glass(m, Vector3.new(100.6 + (i % 2) * 0.7, 3.8, -99 + math.floor(i / 2) * 0.8), rgb(160, 70, 60))
	end
	for i = 0, 3 do
		plate(m, Vector3.new(101.5, 3.86, -95 + i * 0.6), nil)
	end
	local register = block(m, "Cash register", Vector3.new(1.6, 1.4, 1.4), Vector3.new(101.5, 4.5, -89), rgb(70, 70, 66), Enum.Material.Metal)
	Build.sign(register, Enum.NormalId.Left, "КАССА", { bg = rgb(60, 60, 56), fg = rgb(120, 255, 140), font = Enum.Font.Code })
	Build.interact(register, "coupon", "Hand in your meal coupon", "Cashier", 1)
	local radio = detail(block(m, "Radio", Vector3.new(1.2, 1, 2), Vector3.new(102, 4.3, -120), rgb(80, 56, 36), Enum.Material.Wood))
	Build.sign(radio, Enum.NormalId.Left, "≋ РАДИО ≋", { bg = rgb(80, 56, 36), fg = rgb(230, 210, 160) })
	Build.tag(radio, "Radio")

	-- Kitchen.
	block(m, "Stove", Vector3.new(4, 3, 10), Vector3.new(107.5, 1.9, -114), rgb(40, 40, 40), Enum.Material.Metal)
	for i, z in { -117, -113 } do
		detail(Build.column(m, "Pot", 2.4, 2.8, Vector3.new(107.5, 3.4, z), rgb(180, 180, 176), Enum.Material.Metal))
		steam(m, Vector3.new(107.5, 5.9, z), 6 + i)
	end
	for y = 6, 9, 3 do
		detail(block(m, "Shelf", Vector3.new(1.2, 0.2, 14), Vector3.new(109.3, y, -100), rgb(120, 100, 80), Enum.Material.Wood))
		for z = -106, -94, 2.4 do
			detail(Build.column(m, "Shelf pot", 1, 1, Vector3.new(109.3, y + 0.1, z), rgb(170, 170, 166), Enum.Material.Metal))
		end
	end
	local menu = detail(block(m, "Menu board", Vector3.new(0.2, 6, 12), Vector3.new(109.4, 9.5, -122), rgb(30, 40, 34)))
	Build.sign(menu, Enum.NormalId.Left, "МЕНЮ\nЩи суточные ........ 18 к.\nКотлета с пюре .... 32 к.\nКаша гречневая ...... 9 к.\nХлеб ................ 2 к.\nКомпот .............. 7 к.\nЧай с сахаром ....... 3 к.", { bg = rgb(34, 46, 38), fg = rgb(236, 236, 226), font = Enum.Font.Code, padding = 0.04, align = Enum.TextXAlignment.Left })
	local dishes = detail(block(m, "Dish return sign", Vector3.new(8, 1.2, 0.1), Vector3.new(92, 8, -75.6), rgb(236, 230, 214)))
	Build.sign(dishes, Enum.NormalId.Front, "ПОЕЛ — УБЕРИ ЗА СОБОЙ ПОСУДУ!", { bg = rgb(236, 230, 214), fg = rgb(30, 60, 120) })
	detail(block(m, "Dish hatch", Vector3.new(6, 3, 0.1), Vector3.new(92, 4.8, -75.6), rgb(30, 30, 30)))

	-- Wall dressing.
	local clock = detail(Build.cylinder(m, "Wall clock", 0.3, 3, CFrame.new(90, 11, -134.4) * CFrame.Angles(0, math.pi / 2, 0), rgb(236, 236, 230), Enum.Material.SmoothPlastic))
	local face = detail(block(m, "Clock face", Vector3.new(2, 1, 0.05), Vector3.new(90, 11, -134.2), rgb(236, 236, 230)))
	Build.sign(face, Enum.NormalId.Back, "18:45", { bg = rgb(236, 236, 230), fg = rgb(20, 20, 20), font = Enum.Font.Code })
	Build.tag(face, "WallClock")
	clock.CastShadow = false
	Build.poster(m, CFrame.lookAt(Vector3.new(80, 7, -134.4), Vector3.new(80, 7, -120)), Config.Posters[6])
	Build.poster(m, CFrame.lookAt(Vector3.new(100, 7, -75.6), Vector3.new(100, 7, -90)), Config.Posters[4])
	local portrait = detail(block(m, "Portrait", Vector3.new(3, 4, 0.2), Vector3.new(80, 8, -75.6), rgb(120, 90, 50), Enum.Material.Wood))
	Build.sign(portrait, Enum.NormalId.Front, "★\nСЛАВА\nКПСС", { bg = rgb(150, 30, 28), fg = rgb(250, 220, 120), padding = 0.1 })
	detail(block(m, "Coat rack", Vector3.new(0.3, 7, 0.3), Vector3.new(72, 3.9, -96), rgb(80, 60, 40), Enum.Material.Wood))
	for i = 0, 2 do
		detail(block(m, "Hanging coat", Vector3.new(1.4, 3.4, 0.8), Vector3.new(72.6, 4.6, -97.5 + i * 1.5), ({ rgb(60, 62, 58), rgb(70, 60, 50), rgb(40, 40, 44) })[i + 1], Enum.Material.Fabric))
		detail(block(m, "Hanging ushanka", Vector3.new(1.2, 0.7, 1.2), Vector3.new(72.3, 7.6, -97.5 + i * 1.5), rgb(60, 46, 36), Enum.Material.Fabric))
	end

	-- Tables and the people at them.
	local tables = {}
	for _, x in { 78, 88 } do
		for _, z in { -128, -118, -92, -82 } do
			tables[x .. "," .. z] = table4(m, x, z, rng)
		end
	end
	local function diner(key, seat, opts)
		local s = tables[key][seat]
		opts.pose = "sit"
		opts.seatHeight = 1.8
		opts.name = "Diner"
		local model = show(Figure.build(m, CFrame.lookAt(s.pos, s.pos + s.facing), opts))
		plate(m, s.plate, FOODS[rng:NextInteger(1, #FOODS)])
		if opts.action == "drink" then
			glass(m, s.plate + Vector3.new(0.8, 0, 0), rgb(150, 70, 50))
		end
		return model
	end
	diner("78,-128", 1, { action = "eat", held = "spoon", armR = 55, armL = 45, hat = nil, seed = 1 })
	diner("78,-128", 4, { action = "drink", held = "glass", armR = 45, armL = 45, hat = "kerchief", seed = 2 })
	diner("78,-118", 1, { action = "eat", held = "spoon", armR = 55, armL = 45, seed = 3 })
	diner("78,-118", 2, { action = "eat", held = "spoon", armR = 55, armL = 45, seed = 4 })
	diner("78,-118", 3, { action = "drink", held = "mug", armR = 45, armL = 40, seed = 5 })
	diner("88,-118", 2, { action = "eat", held = "spoon", armR = 55, armL = 45, hat = "kerchief", seed = 6 })
	diner("88,-118", 4, { action = "read", held = "papers", armR = 70, armL = 60, seed = 7 })
	diner("78,-92", 2, { action = "eat", held = "spoon", armR = 55, armL = 45, seed = 8 })
	diner("78,-92", 3, { action = "drink", held = "glass", armR = 45, armL = 45, seed = 9 })
	diner("88,-92", 1, { action = "eat", held = "spoon", armR = 55, armL = 45, coat = rgb(80, 80, 76), seed = 10 })
	diner("88,-82", 3, { action = "drink", held = "mug", armR = 45, armL = 40, hat = "kerchief", seed = 11 })
	diner("88,-82", 4, { action = "eat", held = "spoon", armR = 55, armL = 45, seed = 12 })

	-- Your place: a tray of shchi waiting at the corner table.
	local mine = tables["88,-128"][2]
	local tray = block(m, "Your tray", Vector3.new(1.8, 0.1, 1.4), mine.plate + Vector3.new(0, -0.05, 0), rgb(150, 120, 90), Enum.Material.SmoothPlastic)
	plate(m, mine.plate + Vector3.new(-0.3, 0.05, 0), rgb(170, 60, 40))
	glass(m, mine.plate + Vector3.new(0.6, 0.05, 0.3), rgb(160, 70, 60))
	detail(block(m, "Your bread", Vector3.new(0.6, 0.15, 0.4), mine.plate + Vector3.new(0.5, 0.12, -0.35), rgb(150, 100, 60), Enum.Material.Sand))
	Build.interact(tray, "eat", "Eat your shchi", "Your table", 6).MaxActivationDistance = 7

	-- The memo, under an abandoned tray in the far corner.
	Build.note(m, 5, CFrame.new(77.4, 3.46, -82.3) * CFrame.Angles(0, 0.5, 0))

	-- Two men at a standing table by the window.
	block(m, "Standing table top", Vector3.new(3, 0.3, 3), Vector3.new(74, 4.2, -86), rgb(170, 186, 190), Enum.Material.SmoothPlastic)
	detail(block(m, "Standing table leg", Vector3.new(0.4, 3.8, 0.4), Vector3.new(74, 2.3, -86), rgb(80, 80, 80), Enum.Material.Metal))
	glass(m, Vector3.new(74.4, 4.35, -86.3), rgb(200, 190, 160))
	show(Figure.build(m, CFrame.lookAt(Vector3.new(74, 0.4, -88.4), Vector3.new(74, 0.4, -86)), { action = "drink", held = "glass", armR = 60, armL = 10, name = "Diner", seed = 13 }))
	show(Figure.build(m, CFrame.lookAt(Vector3.new(74, 0.4, -83.6), Vector3.new(74, 0.4, -86)), { action = "smoke", held = "cigarette", armR = 20, armL = 10, name = "Diner", seed = 14 }))

	-- People in the queue and the staff.
	show(Figure.build(m, CFrame.lookAt(Vector3.new(97.5, 0.4, -95), Vector3.new(97.5, 0.4, -90)), { action = "idle", held = "papers", armR = 75, armL = 75, hat = "ushanka", name = "Queue", seed = 15 }))
	show(Figure.build(m, CFrame.lookAt(Vector3.new(97.5, 0.4, -99), Vector3.new(97.5, 0.4, -94)), { action = "idle", armR = 5, armL = 5, hat = "kerchief", name = "Queue", seed = 16 }))
	show(Figure.build(m, CFrame.lookAt(Vector3.new(105, 0.4, -89), Vector3.new(100, 0.4, -89)), { action = "idle", armR = 40, armL = 30, hat = "chef", coat = rgb(230, 230, 224), name = "Cashier", seed = 17 }))
	show(Figure.build(m, CFrame.lookAt(Vector3.new(104.2, 0.4, -115), Vector3.new(110, 0.4, -115)), { action = "stir", held = "ladle", armR = 80, armL = 20, hat = "chef", coat = rgb(232, 232, 226), name = "Cook", seed = 18 }))

	return spots
end

return Canteen
