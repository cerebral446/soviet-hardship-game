-- Mine No. 6: the fenced yard, checkpoint, lamp room, cage house, headframe and plant on
-- the surface, and horizon -300 underground: drifts, crosscuts, stopes and the sealed
-- Norillag gallery.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Build = require(Shared.Build)
local Figure = require(Shared.Figure)
local Config = require(Shared.Config)

local rgb = Build.rgb
local block, wedge, detail = Build.block, Build.wedge, Build.detail

local Mine = {}

local SNOW = rgb(222, 228, 234)
local STEEL = rgb(70, 72, 74)
local rng = Random.new(6)

local function face(pos, dir)
	return CFrame.lookAt(pos, pos + dir)
end

local function show(model, from, to)
	model:SetAttribute("ShowFrom", from)
	model:SetAttribute("ShowTo", to)
	Build.tag(model, "StagedPerson")
	return model
end

local function fluorescent(parent, at, length)
	local tube = detail(block(parent, "Fluorescent tube", Vector3.new(length or 5, 0.3, 0.7), at, rgb(220, 236, 226), Enum.Material.Neon))
	Build.surfaceLight(tube, Enum.NormalId.Bottom, rgb(214, 232, 220), 18, 1.1, 150)
	return tube
end

-- A box room built from walls with gaps. gaps = { north = {...}, south = ..., east = ..., west = ... }
-- Gap positions run west→east on north/south walls and north→south on east/west walls.
local function room(parent, center, sx, sz, h, gaps, wallColor, material, opts)
	opts = opts or {}
	local x0, x1 = center.X - sx / 2, center.X + sx / 2
	local z0, z1 = center.Z - sz / 2, center.Z + sz / 2
	local y = center.Y
	local t = opts.thickness or 1
	local walls = {}
	-- East/west walls run past the corners, so shift their gaps by the wall thickness.
	local function shifted(list)
		local out = {}
		for _, g in list or {} do
			table.insert(out, { at = g.at + t, width = g.width, bottom = g.bottom, top = g.top })
		end
		return out
	end
	local function add(list)
		for _, p in list do
			table.insert(walls, p)
		end
	end
	add(Build.wall(parent, Vector3.new(x0, y, z0), Vector3.new(x1, y, z0), Vector3.new(0, 0, -1), h, t, gaps.north, wallColor, material))
	add(Build.wall(parent, Vector3.new(x0, y, z1), Vector3.new(x1, y, z1), Vector3.new(0, 0, 1), h, t, gaps.south, wallColor, material))
	add(Build.wall(parent, Vector3.new(x0, y, z0 - t), Vector3.new(x0, y, z1 + t), Vector3.new(-1, 0, 0), h, t, shifted(gaps.west), wallColor, material))
	add(Build.wall(parent, Vector3.new(x1, y, z0 - t), Vector3.new(x1, y, z1 + t), Vector3.new(1, 0, 0), h, t, shifted(gaps.east), wallColor, material))
	if not opts.noFloor then
		block(parent, "Floor", Vector3.new(sx, 0.4, sz), Vector3.new(center.X, y + 0.2, center.Z), opts.floorColor or rgb(120, 116, 108), opts.floorMaterial or Enum.Material.Concrete)
	end
	if not opts.noRoof then
		block(parent, "Roof", Vector3.new(sx + t * 2 + 0.6, 1, sz + t * 2 + 0.6), Vector3.new(center.X, y + h + 0.5, center.Z), opts.roofColor or wallColor, material)
		if opts.snowRoof ~= false then
			detail(block(parent, "Roof snow", Vector3.new(sx + t * 2 + 0.4, 0.6, sz + t * 2 + 0.4), Vector3.new(center.X, y + h + 1.3, center.Z), SNOW, Enum.Material.Snow))
		end
	end
	return walls
end

local function cage(parent, base, facing, action, actionText)
	-- The mine cage: a steel box open at the front.
	local cf = face(base, facing)
	local plate = rgb(96, 98, 100)
	block(parent, "Cage floor", Vector3.new(8, 0.4, 8), cf * CFrame.new(0, 0.6, 0), plate, Enum.Material.DiamondPlate)
	block(parent, "Cage roof", Vector3.new(8, 0.4, 8), cf * CFrame.new(0, 9.8, 0), plate, Enum.Material.DiamondPlate)
	for _, x in { -4, 4 } do
		local side = block(parent, "Cage side", Vector3.new(0.2, 9, 8), cf * CFrame.new(x, 5.2, 0), plate, Enum.Material.DiamondPlate)
		side.Transparency = 0.15
	end
	local back = block(parent, "Cage back", Vector3.new(8, 9, 0.2), cf * CFrame.new(0, 5.2, 4), plate, Enum.Material.DiamondPlate)
	detail(block(parent, "Cage gate (open)", Vector3.new(8, 2, 0.15), cf * CFrame.new(0, 9, -4), STEEL, Enum.Material.Metal))
	local bulb = detail(Build.ball(parent, "Cage bulb", 0.6, cf * CFrame.new(0, 9.2, 0), rgb(255, 214, 160), Enum.Material.Neon))
	Build.light(bulb, rgb(255, 206, 150), 14, 0.8, true)
	local sign = detail(block(parent, "Cage sign", Vector3.new(4, 1.4, 0.1), cf * CFrame.new(0, 7.4, 3.85), rgb(230, 200, 60)))
	Build.sign(sign, Enum.NormalId.Front, "КЛЕТЬ · НЕ БОЛЕЕ 20 ЧЕЛ.", { bg = rgb(220, 190, 50), fg = rgb(20, 20, 20) })
	local bell = detail(block(parent, "Signal box", Vector3.new(1.2, 1.6, 0.6), cf * CFrame.new(2.6, 4.6, 3.6), rgb(150, 40, 30), Enum.Material.Metal))
	bell.CanQuery = true
	Build.interact(bell, action, actionText, "Signal bell", 1.5).MaxActivationDistance = 11
	return back
end

local function lampRack(parent, cf)
	block(parent, "Lamp rack", Vector3.new(1, 9, 6), cf * CFrame.new(0, 4.5, 0), rgb(70, 74, 70), Enum.Material.Metal)
	for level = 0, 3 do
		local y = 1.5 + level * 2
		detail(block(parent, "Rack shelf", Vector3.new(1.6, 0.15, 6), cf * CFrame.new(-0.8, y, 0), rgb(80, 84, 80), Enum.Material.Metal))
		for k = 0, 4 do
			local slot = cf * CFrame.new(-0.9, y + 0.55, -2.4 + k * 1.2)
			local number = 100 + level * 5 + k
			if number == 117 then
				local tag = detail(block(parent, "Empty slot", Vector3.new(0.05, 0.5, 0.8), slot * CFrame.new(-0.6, 0, 0), rgb(30, 30, 30)))
				Build.sign(tag, Enum.NormalId.Left, "117", { bg = rgb(30, 30, 30), fg = rgb(200, 40, 30), font = Enum.Font.Code })
				continue
			end
			detail(block(parent, "Lamp battery", Vector3.new(0.5, 0.9, 0.4), slot, rgb(40, 40, 40), Enum.Material.SmoothPlastic))
			detail(Build.cylinder(parent, "Lamp head", 0.3, 0.5, slot * CFrame.new(-0.1, 0.6, 0), rgb(150, 150, 140), Enum.Material.Metal))
			detail(block(parent, "Charge light", Vector3.new(0.08, 0.12, 0.12), slot * CFrame.new(-0.27, 0.2, 0), rng:NextNumber() < 0.8 and rgb(60, 255, 80) or rgb(255, 60, 40), Enum.Material.Neon))
		end
	end
end

local function belaz(parent, cf)
	local yellow = rgb(180, 150, 50)
	block(parent, "BelAZ chassis", Vector3.new(10, 3, 22), cf * CFrame.new(0, 4.5, 0), rgb(40, 40, 40), Enum.Material.Metal)
	block(parent, "BelAZ dump body", Vector3.new(11, 6, 15), cf * CFrame.new(0, 9, 3), yellow, Enum.Material.CorrodedMetal)
	detail(block(parent, "Ore load", Vector3.new(10, 1, 13), cf * CFrame.new(0, 12.3, 3), rgb(60, 54, 46), Enum.Material.Slate))
	detail(block(parent, "Load snow", Vector3.new(9.6, 0.5, 12.6), cf * CFrame.new(0, 12.9, 3), SNOW, Enum.Material.Snow))
	block(parent, "BelAZ cab", Vector3.new(4.5, 4, 4.5), cf * CFrame.new(-2.5, 8, -8.5), yellow, Enum.Material.CorrodedMetal)
	detail(block(parent, "Cab window", Vector3.new(4, 1.8, 0.1), cf * CFrame.new(-2.5, 8.6, -10.8), rgb(30, 36, 40), Enum.Material.Glass))
	for _, x in { -5.5, 5.5 } do
		for _, z in { -7, 7 } do
			detail(Build.cylinder(parent, "BelAZ tyre", 3, 7, cf * CFrame.new(x, 3.5, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
	local plate = detail(block(parent, "BelAZ badge", Vector3.new(3, 0.8, 0.1), cf * CFrame.new(2, 5, -11.05) * CFrame.Angles(0, math.pi, 0), rgb(40, 40, 40)))
	Build.sign(plate, Enum.NormalId.Front, "БелАЗ", { bg = rgb(40, 40, 40), fg = rgb(220, 200, 90) })
end

local function uaz(parent, cf)
	local khaki = rgb(82, 92, 66)
	block(parent, "UAZ body", Vector3.new(5, 2.4, 10), cf * CFrame.new(0, 2.2, 0), khaki, Enum.Material.SmoothPlastic)
	block(parent, "UAZ cabin", Vector3.new(4.8, 2.6, 6.5), cf * CFrame.new(0, 4.6, 1), khaki, Enum.Material.Fabric)
	detail(block(parent, "UAZ snow", Vector3.new(4.6, 0.5, 6.3), cf * CFrame.new(0, 6.1, 1), SNOW, Enum.Material.Snow))
	detail(block(parent, "UAZ windscreen", Vector3.new(4.4, 1.6, 0.1), cf * CFrame.new(0, 4.8, -2.3), rgb(30, 36, 40), Enum.Material.Glass))
	for _, x in { -2.5, 2.5 } do
		for _, z in { -3.4, 3.4 } do
			detail(Build.cylinder(parent, "UAZ wheel", 1, 2.6, cf * CFrame.new(x, 1.3, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
end

local function smokestack(parent, base, height)
	local stack = Build.column(parent, "Smokestack", height, 9, base, rgb(110, 104, 98))
	for _, y in { height - 6, height - 18 } do
		detail(Build.column(parent, "Stack band", 4, 9.3, base + Vector3.new(0, y, 0), rgb(170, 40, 34)))
	end
	for _, y in { height + 0.5, height * 0.6 } do
		local beacon = detail(Build.ball(parent, "Aircraft warning light", 1.2, base + Vector3.new(4.7, y, 0), rgb(255, 40, 30), Enum.Material.Neon))
		Build.light(beacon, rgb(255, 40, 30), 22, 1.2)
		Build.tag(beacon, "Beacon")
	end
	local top = detail(block(parent, "Stack smoke", Vector3.new(6, 1, 6), base + Vector3.new(0, height + 1, 0), rgb(0, 0, 0)))
	top.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 5
	e.Lifetime = NumberRange.new(10, 16)
	e.Speed = NumberRange.new(3, 5)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 30) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(70, 66, 62))
	e.Acceleration = Vector3.new(4, 0.5, 1)
	e.EmissionDirection = Enum.NormalId.Top
	e.LightInfluence = 0.6
	e.Parent = top
	return stack
end

local function floodMast(parent, base, target)
	block(parent, "Floodlight mast", Vector3.new(0.9, 26, 0.9), base + Vector3.new(0, 13, 0), STEEL, Enum.Material.Metal)
	local head = detail(block(parent, "Floodlight", Vector3.new(2.2, 1.4, 1), CFrame.lookAt(base + Vector3.new(0, 26, 0), target), rgb(255, 236, 200), Enum.Material.Neon))
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = 70
	spot.Range = 60
	spot.Brightness = 1.6
	spot.Color = rgb(255, 226, 180)
	spot.Shadows = true
	spot.Parent = head
	Build.tag(head, "Floodlight")
end

local function surface(folder, spots)
	-- Yard surface.
	block(folder, "Yard", Vector3.new(250, 0.2, 160), Vector3.new(0, 0.1, -280), rgb(170, 174, 178), Enum.Material.Snow)

	-- Concrete fence (the classic diamond-pattern panels) with barbed wire.
	local function fenceRun(x0, x1)
		for x = x0, x1 - 6, 6 do
			local p = block(folder, "Fence panel", Vector3.new(5.9, 7, 0.6), Vector3.new(x + 3, 3.5, -200), rgb(150, 148, 140))
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Back
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 20
			gui.Parent = p
			for i = 0, 3 do
				local d = Instance.new("Frame")
				d.AnchorPoint = Vector2.new(0.5, 0.5)
				d.Position = UDim2.fromScale(0.125 + i * 0.25, 0.5)
				d.Size = UDim2.fromOffset(18, 18)
				d.Rotation = 45
				d.BackgroundColor3 = rgb(126, 124, 118)
				d.BorderSizePixel = 0
				d.Parent = gui
			end
		end
		detail(Build.beam(folder, "Barbed wire", Vector3.new(x0, 7.4, -200), Vector3.new(x1, 7.4, -200), 0.1, rgb(60, 56, 50), Enum.Material.CorrodedMetal))
		detail(Build.beam(folder, "Barbed wire", Vector3.new(x0, 7.9, -200), Vector3.new(x1, 7.9, -200), 0.1, rgb(60, 56, 50), Enum.Material.CorrodedMetal))
	end
	fenceRun(-130, -14)
	fenceRun(26, 132)

	-- Gate arch.
	for _, x in { -15, 15 } do
		block(folder, "Gate pillar", Vector3.new(2, 13, 2), Vector3.new(x, 6.5, -200), rgb(150, 146, 138))
	end
	local beam = block(folder, "Gate beam", Vector3.new(32, 3, 1.2), Vector3.new(0, 14.5, -200), rgb(140, 30, 28))
	Build.sign(beam, Enum.NormalId.Back, "ШАХТА № 6 · СЛАВА ШАХТЁРСКОМУ ТРУДУ!", { bg = rgb(140, 30, 28), fg = rgb(250, 220, 120) })
	Build.sign(beam, Enum.NormalId.Front, "ПОКИДАЯ ШАХТУ — СДАЙ ЛАМПУ", { bg = rgb(140, 30, 28), fg = rgb(250, 220, 120) })
	local star = detail(block(folder, "Gate star", Vector3.new(4, 4, 0.2), Vector3.new(0, 18, -200), rgb(0, 0, 0)))
	star.Transparency = 1
	Build.sign(star, Enum.NormalId.Back, "★", { bgTransparency = 1, fg = rgb(255, 50, 40), lightInfluence = 0, brightness = 2, font = Enum.Font.GothamBlack })
	for _, x in { -1, 1 } do
		local leaf = block(folder, "Gate leaf", Vector3.new(12, 7, 0.3), CFrame.new(x * 14, 3.6, -200) * CFrame.Angles(0, -x * math.rad(80), 0) * CFrame.new(-x * 6, 0, 0), rgb(60, 80, 70), Enum.Material.CorrodedMetal)
		Build.sign(leaf, Enum.NormalId.Back, "★", { bg = rgb(60, 80, 70), fg = rgb(170, 40, 34), font = Enum.Font.GothamBlack })
	end
	spots.gate = CFrame.lookAt(Vector3.new(0, 3, -212), Vector3.new(0, 3, -260))

	-- Checkpoint booth with the watchman and the time clock.
	local booth = Instance.new("Model")
	booth.Name = "Checkpoint"
	booth.Parent = folder
	room(booth, Vector3.new(20, 0, -204), 10, 10, 8, {
		west = { { at = 5, width = 6, bottom = 3, top = 6.5 } },
	}, rgb(170, 166, 150), Enum.Material.Concrete)
	local glass = block(booth, "Booth window", Vector3.new(0.2, 3.5, 6), Vector3.new(14.6, 4.75, -204), rgb(150, 170, 160), Enum.Material.Glass)
	glass.Transparency = 0.5
	fluorescent(booth, Vector3.new(20, 7.6, -204), 3)
	local sign = detail(block(booth, "Booth sign", Vector3.new(0.1, 1.2, 6), Vector3.new(14.4, 7.3, -204), rgb(36, 56, 104)))
	Build.sign(sign, Enum.NormalId.Left, "ПРОХОДНАЯ", { bg = rgb(36, 56, 104), fg = rgb(240, 240, 230) })
	block(booth, "Booth desk", Vector3.new(2, 2.8, 6), Vector3.new(16.5, 1.4, -204), rgb(90, 66, 44), Enum.Material.Wood)
	show(Figure.build(booth, CFrame.lookAt(Vector3.new(19.5, 0.4, -204), Vector3.new(10, 0.4, -204)), { pose = "sit", hat = "cap", held = "papers", armR = 70, armL = 60, action = "read", coat = rgb(50, 60, 50), name = "Watchman" }), 1, 8)
	block(booth, "Watchman chair", Vector3.new(2, 1.9, 2), Vector3.new(19.6, 0.95, -204), rgb(80, 60, 40), Enum.Material.Wood)
	local clock = block(booth, "Time clock", Vector3.new(0.8, 2.2, 1.6), Vector3.new(14.1, 4, -208), rgb(130, 120, 100), Enum.Material.Metal)
	Build.sign(clock, Enum.NormalId.Left, "ТАБЕЛЬ\n06:31", { bg = rgb(200, 190, 160), fg = rgb(20, 20, 20), font = Enum.Font.Code })
	local cards = detail(block(booth, "Card rack", Vector3.new(0.4, 2.4, 2.2), Vector3.new(14.3, 4, -201), rgb(90, 66, 44), Enum.Material.Wood))
	Build.sign(cards, Enum.NormalId.Left, "▮▮▮▮▮▮\n▮▮▮▮▮▮\n▮▮▮▮ ▮", { bg = rgb(90, 66, 44), fg = rgb(220, 210, 180), font = Enum.Font.Code })
	Build.interact(clock, "clockIn", "Punch your time card", "Time clock", 1).MaxActivationDistance = 10

	-- Lamp room.
	local lamps = Instance.new("Model")
	lamps.Name = "Lamp room"
	lamps.Parent = folder
	room(lamps, Vector3.new(-40, 0, -235), 30, 20, 12, {
		east = { { at = 10, width = 5, top = 7.5 } },
		north = { { at = 8, width = 4, bottom = 5, top = 9 }, { at = 22, width = 4, bottom = 5, top = 9 } },
	}, rgb(160, 150, 120), Enum.Material.Concrete)
	for _, x in { -48, -34 } do
		local w = detail(block(lamps, "Lamp room window", Vector3.new(4, 4, 0.2), Vector3.new(x, 7, -245.5), rgb(160, 150, 100), Enum.Material.Neon))
		w.Transparency = 0.3
	end
	local nameplate = detail(block(lamps, "Lamp room sign", Vector3.new(0.1, 1.4, 8), Vector3.new(-23.9, 9, -235), rgb(36, 56, 104)))
	Build.sign(nameplate, Enum.NormalId.Right, "ЛАМПОВАЯ", { bg = rgb(36, 56, 104), fg = rgb(240, 240, 230) })
	Build.poster(lamps, face(Vector3.new(-23.9, 5.5, -242), Vector3.xAxis), Config.Posters[5])
	block(lamps, "Counter", Vector3.new(2, 3.4, 18), Vector3.new(-37, 1.9, -235), rgb(100, 76, 50), Enum.Material.Wood)
	block(lamps, "Counter top", Vector3.new(2.4, 0.2, 18), Vector3.new(-37, 3.7, -235), rgb(130, 100, 70), Enum.Material.Wood)
	local hatch = detail(block(lamps, "Hatch sign", Vector3.new(0.1, 1.2, 6), Vector3.new(-37.5, 9, -235), rgb(220, 200, 60)))
	Build.sign(hatch, Enum.NormalId.Right, "ВЫДАЧА ЛАМП", { bg = rgb(220, 196, 60), fg = rgb(20, 20, 20) })
	detail(block(lamps, "Hatch frame", Vector3.new(0.6, 0.6, 18), Vector3.new(-37.5, 8.1, -235), rgb(100, 76, 50), Enum.Material.Wood))
	local issue = detail(block(lamps, "Issued lamp", Vector3.new(0.6, 1, 0.5), Vector3.new(-36.6, 4.3, -234), rgb(40, 40, 40), Enum.Material.SmoothPlastic))
	issue.CanQuery = true
	detail(Build.cylinder(lamps, "Issued lamp head", 0.3, 0.6, CFrame.new(-36.6, 5, -234), rgb(160, 160, 150), Enum.Material.Metal))
	Build.interact(issue, "lamp", "Take lamp No. 116", "Lamp counter", 1)
	Build.note(lamps, 3, CFrame.new(-36.8, 3.83, -239) * CFrame.Angles(0, 0.4, 0))
	for _, z in { -242, -235, -228 } do
		lampRack(lamps, CFrame.new(-53.5, 0.4, z))
	end
	fluorescent(lamps, Vector3.new(-45, 11.6, -235), 6)
	fluorescent(lamps, Vector3.new(-31, 11.6, -235), 6)
	show(Figure.build(lamps, CFrame.lookAt(Vector3.new(-40, 0.4, -234), Vector3.new(-30, 0.4, -234)), { hat = "kerchief", armR = 30, armL = 10, action = "idle", coat = rgb(70, 80, 100), name = "Lamp attendant" }), 1, 8)

	-- Cage house and headframe.
	local house = Instance.new("Model")
	house.Name = "Cage house"
	house.Parent = folder
	room(house, Vector3.new(0, 0, -280), 26, 24, 16, {
		south = { { at = 13, width = 8, top = 9 } },
		east = { { at = 10, width = 4, bottom = 9, top = 13 } },
	}, rgb(120, 112, 100), Enum.Material.Brick)
	cage(house, Vector3.new(0, 0, -286), Vector3.new(0, 0, 1), "cageDown", "Ring for the cage")
	fluorescent(house, Vector3.new(0, 15.6, -276), 6)
	local hs = detail(block(house, "Cage house sign", Vector3.new(10, 1.6, 0.1), Vector3.new(0, 11, -266.9), rgb(140, 30, 28)))
	Build.sign(hs, Enum.NormalId.Back, "КОПЁР · СТВОЛ № 1", { bg = rgb(140, 30, 28), fg = rgb(250, 220, 120) })
	Build.poster(house, face(Vector3.new(-9, 6, -266.9), Vector3.zAxis), Config.Posters[2])
	local board = detail(block(house, "Shift board", Vector3.new(6, 4, 0.2), Vector3.new(-8, 5, -291.85), rgb(30, 40, 30)))
	Build.sign(board, Enum.NormalId.Back, "СМЕНА № 1\nГоризонт −300\nНорма: 5 забоев на человека\nТ/Б: каска, лампа, самоспасатель", { bg = rgb(34, 48, 36), fg = rgb(230, 230, 220), font = Enum.Font.Code, padding = 0.05 })
	block(house, "Bench", Vector3.new(1.6, 2.2, 8), Vector3.new(11.5, 1.1, -278), rgb(90, 66, 44), Enum.Material.Wood)
	spots.cageTop = CFrame.lookAt(Vector3.new(0, 3, -262), Vector3.new(0, 3, -220))

	-- Miners waiting for the cage in the morning.
	show(Figure.build(house, CFrame.lookAt(Vector3.new(-6, 0.4, -276), Vector3.new(-2, 0.4, -284)), { hat = "helmet", armR = 10, armL = 5, action = "idle", name = "Miner" }), 1, 4)
	show(Figure.build(house, CFrame.lookAt(Vector3.new(6, 0.4, -274), Vector3.new(2, 0.4, -280)), { hat = "helmet", held = "cigarette", armR = 20, action = "smoke", name = "Miner" }), 1, 4)
	show(Figure.build(house, CFrame.lookAt(Vector3.new(11.5, 0.4, -281), Vector3.new(4, 0.4, -281)), { pose = "sit", seatHeight = 1.8, hat = "helmet", armR = 40, armL = 40, action = "idle", name = "Miner" }), 1, 4)
	show(Figure.build(folder, CFrame.lookAt(Vector3.new(-14, 0.2, -262), Vector3.new(-10, 0.2, -258)), { hat = "ushanka", held = "cigarette", armR = 20, action = "smoke", name = "Miner" }), 1, 4)
	show(Figure.build(folder, CFrame.lookAt(Vector3.new(-10, 0.2, -259), Vector3.new(-14, 0.2, -262)), { hat = "ushanka", armR = 5, action = "idle", name = "Miner" }), 1, 4)
	-- A tired pair in the evening.
	show(Figure.build(folder, CFrame.lookAt(Vector3.new(12, 0.2, -258), Vector3.new(16, 0.2, -262)), { hat = "ushanka", held = "cigarette", armR = 20, action = "smoke", name = "Miner" }), 7, 8)

	local steel = rgb(60, 64, 66)
	local legs = {
		{ Vector3.new(-12, 17, -268), Vector3.new(-4, 62, -276) },
		{ Vector3.new(12, 17, -268), Vector3.new(4, 62, -276) },
		{ Vector3.new(-12, 17, -292), Vector3.new(-4, 62, -284) },
		{ Vector3.new(12, 17, -292), Vector3.new(4, 62, -284) },
	}
	for _, l in legs do
		Build.beam(folder, "Headframe leg", l[1], l[2], 1.2, steel, Enum.Material.CorrodedMetal)
	end
	for k = 1, 4 do
		local t0, t1 = (k - 1) / 4, k / 4
		for i, l in legs do
			local other = legs[i % 4 + 1]
			local a = l[1]:Lerp(l[2], t0)
			local b = other[1]:Lerp(other[2], t1)
			detail(Build.beam(folder, "Headframe brace", a, b, 0.4, steel, Enum.Material.CorrodedMetal))
		end
	end
	block(folder, "Headframe deck", Vector3.new(12, 1, 12), Vector3.new(0, 62, -280), steel, Enum.Material.DiamondPlate)
	for _, x in { -3.5, 3.5 } do
		local wheel = Build.cylinder(folder, "Sheave wheel", 0.8, 12, CFrame.new(x, 67, -280), rgb(80, 40, 36), Enum.Material.CorrodedMetal)
		detail(wheel)
		detail(Build.cylinder(folder, "Sheave hub", 1.2, 2, CFrame.new(x, 67, -280), steel, Enum.Material.Metal))
		Build.tag(wheel, "Sheave")
		Build.beam(folder, "Hoist cable", Vector3.new(x, 67, -286), Vector3.new(x * 0.6, 16, -336), 0.25, rgb(30, 30, 30), Enum.Material.Metal)
		detail(Build.beam(folder, "Shaft cable", Vector3.new(x, 61, -274), Vector3.new(x, 16, -274), 0.25, rgb(30, 30, 30), Enum.Material.Metal))
	end
	local bigStar = detail(block(folder, "Headframe star", Vector3.new(8, 8, 0.3), Vector3.new(0, 78, -280), rgb(0, 0, 0)))
	bigStar.Transparency = 1
	for _, f in { Enum.NormalId.Front, Enum.NormalId.Back } do
		Build.sign(bigStar, f, "★", { bgTransparency = 1, fg = rgb(255, 40, 30), lightInfluence = 0, brightness = 3, font = Enum.Font.GothamBlack })
	end
	local starGlow = detail(Build.ball(folder, "Star glow", 0.5, Vector3.new(0, 78, -279), rgb(255, 40, 30), Enum.Material.Neon))
	Build.light(starGlow, rgb(255, 40, 30), 26, 1.4)
	Build.tag(starGlow, "Beacon")

	-- Hoist house.
	block(folder, "Hoist house", Vector3.new(30, 18, 20), Vector3.new(0, 9, -346), rgb(130, 120, 108), Enum.Material.Brick)
	detail(block(folder, "Hoist house snow", Vector3.new(30.4, 0.6, 20.4), Vector3.new(0, 18.3, -346), SNOW, Enum.Material.Snow))
	for _, x in { -9, 0, 9 } do
		detail(block(folder, "Hoist window", Vector3.new(5, 6, 0.2), Vector3.new(x, 10, -335.9), rgb(150, 140, 96), Enum.Material.Neon))
	end

	-- Concentrator plant and smokestacks.
	block(folder, "Concentrator", Vector3.new(60, 42, 70), Vector3.new(80, 21, -300), rgb(108, 102, 96))
	detail(block(folder, "Concentrator snow", Vector3.new(60.4, 0.6, 70.4), Vector3.new(80, 42.3, -300), SNOW, Enum.Material.Snow))
	for y = 6, 36, 10 do
		for z = -330, -270, 8 do
			local lit = rng:NextNumber() < 0.25
			detail(block(folder, "Plant window", Vector3.new(0.2, 4, 5), Vector3.new(49.9, y, z), lit and rgb(150, 130, 80) or rgb(24, 28, 30), lit and Enum.Material.Neon or Enum.Material.Glass))
		end
	end
	local banner = detail(block(folder, "Plant banner", Vector3.new(0.2, 5, 50), Vector3.new(49.8, 45, -300), rgb(140, 30, 28)))
	Build.sign(banner, Enum.NormalId.Left, "НОРИЛЬСКИЙ ГМК им. А. П. ЗАВЕНЯГИНА — РОДИНЕ!", { bg = rgb(140, 30, 28), fg = rgb(250, 220, 120) })
	for _, x in { 64, 82, 100 } do
		smokestack(folder, Vector3.new(x, 0, -360), 130)
	end
	Build.beam(folder, "Conveyor gallery", Vector3.new(13, 14, -282), Vector3.new(50, 32, -290), 4, rgb(120, 116, 104), Enum.Material.CorrodedMetal)
	for t = 0.25, 0.75, 0.25 do
		local p = Vector3.new(13, 14, -282):Lerp(Vector3.new(50, 32, -290), t)
		block(folder, "Gallery support", Vector3.new(1, p.Y, 1), Vector3.new(p.X, p.Y / 2, p.Z), steel, Enum.Material.Metal)
	end

	-- Yard dressing.
	floodMast(folder, Vector3.new(-30, 0, -258), Vector3.new(-10, 0, -240))
	floodMast(folder, Vector3.new(32, 0, -250), Vector3.new(10, 0, -260))
	floodMast(folder, Vector3.new(-20, 0, -318), Vector3.new(0, 0, -300))
	belaz(folder, CFrame.new(-75, 0, -290) * CFrame.Angles(0, 0.4, 0))
	uaz(folder, CFrame.new(38, 0, -216) * CFrame.Angles(0, -0.3, 0))
	for i = 0, 3 do
		wedge(folder, "Slag heap", Vector3.new(30, 18 + i * 3, 26), CFrame.new(-120 + i * 8, 9 + i * 1.5, -330 - i * 20) * CFrame.Angles(0, math.rad(i * 70), 0), rgb(46, 42, 40), Enum.Material.Slate)
	end
	local slogan = detail(block(folder, "Yard slogan", Vector3.new(24, 3, 0.4), Vector3.new(-60, 12, -201), rgb(140, 30, 28)))
	Build.sign(slogan, Enum.NormalId.Front, "ШАХТЁР! СОБЛЮДАЙ ТЕХНИКУ БЕЗОПАСНОСТИ!", { bg = rgb(140, 30, 28), fg = rgb(250, 220, 120) })
	for _, x in { -70, -50 } do
		block(folder, "Slogan post", Vector3.new(0.4, 12, 0.4), Vector3.new(x, 6, -201), STEEL, Enum.Material.Metal)
	end
end

-- Underground ----------------------------------------------------------------------------

local WALL = rgb(72, 66, 60)
local FLOOR = rgb(58, 52, 46)
local TIMBER = rgb(96, 70, 44)

local function lumps(parent, a, b, out, h, gaps)
	local dir = (b - a).Unit
	local length = (b - a).Magnitude
	for s = 2.5, length - 2.5, 4.5 do
		local skip = false
		for _, g in gaps or {} do
			if math.abs(s - g.at) < g.width / 2 + 1.5 then
				skip = true
			end
		end
		if not skip then
			local p = a + dir * s + out * rng:NextNumber(-0.2, 0.6) + Vector3.new(0, rng:NextNumber(0.5, h - 0.5), 0)
			local c = WALL:Lerp(rgb(40, 36, 32), rng:NextNumber(0, 0.6))
			detail(block(parent, "Rock", Vector3.new(rng:NextNumber(1.5, 3), rng:NextNumber(1.5, 4), rng:NextNumber(2, 5)), CFrame.new(p) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)), c, Enum.Material.Rock))
		end
	end
end

local function mineLamp(parent, at, order)
	detail(block(parent, "Lamp wire", Vector3.new(0.08, 0.8, 0.08), at + Vector3.new(0, 0.6, 0), rgb(20, 20, 20)))
	local bulb = detail(Build.ball(parent, "Mine lamp", 0.55, at, rgb(255, 206, 140), Enum.Material.Neon))
	Build.light(bulb, rgb(255, 196, 130), 22, 0.9, order % 2 == 0)
	bulb:SetAttribute("Order", order)
	Build.tag(bulb, "MineLamp")
	for _, r in { 0, math.pi / 2 } do
		detail(block(parent, "Lamp cage", Vector3.new(0.75, 0.75, 0.06), CFrame.new(at) * CFrame.Angles(0, r, 0), rgb(40, 40, 40), Enum.Material.Metal)).Transparency = 0.5
	end
end

-- A straight tunnel between two floor points (world). opts: gapsL/gapsR, rails, lamps, old, capEnd.
local function drift(parent, a, b, w, h, opts)
	opts = opts or {}
	local dir = (b - a).Unit
	local length = (b - a).Magnitude
	local left = Vector3.new(dir.Z, 0, -dir.X)
	local mid = (a + b) / 2
	local frame = CFrame.lookAt(mid, mid + dir)
	block(parent, "Drift floor", Vector3.new(w + 4, 1, length), frame * CFrame.new(0, -0.5, 0), FLOOR, Enum.Material.Ground)
	block(parent, "Drift roof", Vector3.new(w + 4, 2, length), frame * CFrame.new(0, h + 1, 0), WALL:Lerp(rgb(0, 0, 0), 0.2), Enum.Material.Slate)
	Build.wall(parent, a + left * (w / 2), b + left * (w / 2), left, h, 2, opts.gapsL, WALL, Enum.Material.Slate, "Rock wall")
	Build.wall(parent, a - left * (w / 2), b - left * (w / 2), -left, h, 2, opts.gapsR, WALL, Enum.Material.Slate, "Rock wall")
	lumps(parent, a + left * (w / 2), b + left * (w / 2), left, h, opts.gapsL)
	lumps(parent, a - left * (w / 2), b - left * (w / 2), -left, h, opts.gapsR)
	if opts.capEnd then
		block(parent, "Dead end", Vector3.new(w + 4, h, 2), CFrame.lookAt(b + dir + Vector3.new(0, h / 2, 0), b + dir * 2 + Vector3.new(0, h / 2, 0)), WALL, Enum.Material.Slate)
	end

	local function inGap(s)
		for _, list in { opts.gapsL or {}, opts.gapsR or {} } do
			for _, g in list do
				if math.abs(s - g.at) < g.width / 2 + 0.6 then
					return true
				end
			end
		end
		return false
	end

	-- Timber sets.
	local wood = opts.old and rgb(70, 54, 40) or TIMBER
	local count = 0
	for s = 3, length - 2, opts.old and 6 or 8 do
		if inGap(s) then
			continue
		end
		count += 1
		local p = a + dir * s
		local tilt = opts.old and rng:NextNumber(-0.12, 0.12) or 0
		for _, side in { -1, 1 } do
			block(parent, "Timber post", Vector3.new(0.8, h - 0.8, 0.8), CFrame.lookAt(p + left * side * (w / 2 - 0.5) + Vector3.new(0, (h - 0.8) / 2, 0), p + left * side * (w / 2 - 0.5) + Vector3.new(0, (h - 0.8) / 2, 0) + dir) * CFrame.Angles(0, 0, tilt * side), wood, Enum.Material.Wood)
		end
		local cap = detail(block(parent, "Timber cap", Vector3.new(w, 0.8, 0.8), CFrame.lookAt(p + Vector3.new(0, h - 0.4, 0), p + Vector3.new(0, h - 0.4, 0) + dir) * CFrame.Angles(0, 0, tilt), wood, Enum.Material.Wood))
		if opts.old and rng:NextNumber() < 0.35 then
			cap.CFrame = cap.CFrame * CFrame.Angles(0, 0, rng:NextNumber(0.2, 0.5)) * CFrame.new(0, -1, 0)
		end
		if opts.lamps and count % 2 == 0 then
			mineLamp(parent, p + Vector3.new(0, h - 1.6, 0), opts.lampOrder and opts.lampOrder(p) or 0)
		end
	end

	-- Rails and sleepers.
	if opts.rails then
		for _, side in { -1, 1 } do
			detail(block(parent, "Rail", Vector3.new(0.25, 0.3, length), frame * CFrame.new(side * 1.3, 0.15, 0), rgb(90, 80, 70), Enum.Material.CorrodedMetal))
		end
		for s = 1, length - 1, 2.6 do
			detail(block(parent, "Sleeper", Vector3.new(3.8, 0.15, 0.6), CFrame.lookAt(a + dir * s + Vector3.new(0, 0.05, 0), a + dir * (s + 1) + Vector3.new(0, 0.05, 0)), rgb(70, 54, 40), Enum.Material.Wood))
		end
	end

	-- Ventilation duct and cables.
	if not opts.old then
		local off = left * (w / 2 - 1.1) + Vector3.new(0, h - 1.9, 0)
		detail(Build.pipe(parent, "Vent duct", a + off, b + off, 1.5, rgb(190, 160, 70), Enum.Material.Fabric))
		local coff = -left * (w / 2 - 0.25) + Vector3.new(0, h - 2.5, 0)
		detail(Build.beam(parent, "Power cable", a + coff, b + coff, 0.18, rgb(20, 20, 20), Enum.Material.Rubber))
	end

	-- Puddles.
	for _ = 1, math.floor(length / 30) do
		local p = a + dir * rng:NextNumber(4, length - 4) + left * rng:NextNumber(-w / 3, w / 3)
		local puddle = detail(block(parent, "Puddle", Vector3.new(rng:NextNumber(2, 4), 0.05, rng:NextNumber(2, 5)), p + Vector3.new(0, 0.03, 0), rgb(30, 40, 46), Enum.Material.Glass))
		puddle.Reflectance = 0.3
		puddle.Transparency = 0.2
	end
end

local function chamber(parent, center, sx, sz, h, gaps)
	room(parent, center, sx, sz, h, gaps, WALL, Enum.Material.Slate, { thickness = 2, floorColor = FLOOR, floorMaterial = Enum.Material.Ground, roofColor = WALL:Lerp(rgb(0, 0, 0), 0.2), snowRoof = false })
	local x0, x1 = center.X - sx / 2, center.X + sx / 2
	local z0, z1 = center.Z - sz / 2, center.Z + sz / 2
	lumps(parent, Vector3.new(x0, center.Y, z0), Vector3.new(x1, center.Y, z0), Vector3.new(0, 0, -1), h, gaps.north)
	lumps(parent, Vector3.new(x0, center.Y, z1), Vector3.new(x1, center.Y, z1), Vector3.new(0, 0, 1), h, gaps.south)
	lumps(parent, Vector3.new(x0, center.Y, z0), Vector3.new(x0, center.Y, z1), Vector3.new(-1, 0, 0), h, gaps.west)
	lumps(parent, Vector3.new(x1, center.Y, z0), Vector3.new(x1, center.Y, z1), Vector3.new(1, 0, 0), h, gaps.east)
	-- Roof bolts and props.
	for _ = 1, 4 do
		local p = center + Vector3.new(rng:NextNumber(-sx / 2 + 3, sx / 2 - 3), 0, rng:NextNumber(-sz / 2 + 3, sz / 2 - 3))
		block(parent, "Prop", Vector3.new(0.8, h, 0.8), p + Vector3.new(0, h / 2, 0), TIMBER, Enum.Material.Wood)
	end
end

local function seam(parent, n, pos, normal)
	local cf = CFrame.lookAt(pos, pos + normal)
	local ore = block(parent, "Ore seam", Vector3.new(6, 5, 1.6), cf, rgb(110, 92, 52), Enum.Material.Rock)
	ore:SetAttribute("Seam", n)
	Build.tag(ore, "Seam")
	for _ = 1, 9 do
		detail(block(parent, "Sulphide", Vector3.new(rng:NextNumber(0.3, 0.8), rng:NextNumber(0.2, 0.6), 0.3), cf * CFrame.new(rng:NextNumber(-2.6, 2.6), rng:NextNumber(-2.2, 2.2), -0.75), rgb(210, 180, 90), Enum.Material.Foil))
	end
	local mark = detail(block(parent, "Seam mark", Vector3.new(4, 2.4, 0.05), cf * CFrame.new(0, 0.4, -0.85), rgb(0, 0, 0)))
	mark.Transparency = 1
	mark:SetAttribute("Seam", n)
	Build.tag(mark, "SeamMark")
	Build.sign(mark, Enum.NormalId.Front, "✕ " .. n, { bgTransparency = 1, fg = rgb(220, 40, 30), font = Enum.Font.PermanentMarker })
	Build.interact(ore, "seam", "Break ore", "Seam No. " .. n, 2.5, { Seam = n })
	local pick = detail(block(parent, "Leaning pick", Vector3.new(0.25, 3.4, 0.25), cf * CFrame.new(3.6, -1, -1.2) * CFrame.Angles(0, 0, 0.3), rgb(110, 80, 50), Enum.Material.Wood))
	detail(block(parent, "Pick head", Vector3.new(2.2, 0.3, 0.3), pick.CFrame * CFrame.new(0, 1.7, 0), rgb(70, 70, 72), Enum.Material.Metal))
end

local function wallSign(parent, at, normal, text, color)
	local p = detail(block(parent, "Mine sign", Vector3.new(5, 1.8, 0.1), CFrame.lookAt(at, at + normal), color or rgb(220, 190, 50)))
	Build.sign(p, Enum.NormalId.Front, text, { bg = color or rgb(220, 190, 50), fg = rgb(20, 20, 20), font = Enum.Font.Oswald, padding = 0.04 })
	return p
end

local function cart(parent, cf, loaded)
	block(parent, "Mine cart", Vector3.new(3.2, 2.4, 5), cf * CFrame.new(0, 1.9, 0), rgb(90, 70, 50), Enum.Material.CorrodedMetal)
	if loaded then
		detail(block(parent, "Ore", Vector3.new(2.8, 0.8, 4.6), cf * CFrame.new(0, 3.2, 0), rgb(70, 62, 48), Enum.Material.Slate))
	end
	for _, x in { -1.3, 1.3 } do
		for _, z in { -1.6, 1.6 } do
			detail(Build.cylinder(parent, "Cart wheel", 0.3, 1.2, cf * CFrame.new(x, 0.6, z), rgb(40, 40, 40), Enum.Material.Metal))
		end
	end
end

local function underground(folder, spots)
	local O = Config.Places.Underground
	local ug = Instance.new("Model")
	ug.Name = "Horizon -300"
	ug.Parent = folder
	local function L(x, y, z)
		return O + Vector3.new(x, y, z)
	end
	-- Lamps die from the far end towards the cage.
	local function order(p)
		return math.floor((p - O).Magnitude)
	end

	-- Cage landing.
	chamber(ug, L(0, 0, 0), 28, 28, 14, { north = { { at = 14, width = 10, top = 11 } } })
	cage(ug, L(0, 0, 9), Vector3.new(0, 0, -1), "cageUp", "Ring for the cage")
	mineLamp(ug, L(-8, 12, -4), order(L(-8, 12, -4)))
	mineLamp(ug, L(8, 12, -4), order(L(8, 12, -4)))
	wallSign(ug, L(0, 12.5, -13.9), Vector3.new(0, 0, 1), "ГОРИЗОНТ −300 · ОКОЛОСТВОЛЬНЫЙ ДВОР")
	local chalk = detail(block(ug, "Quota board", Vector3.new(0.2, 4, 7), L(-13.85, 5, 0), rgb(30, 40, 32)))
	Build.sign(chalk, Enum.NormalId.Right, "НОРМА СМЕНЫ: 5 ЗАБОЕВ\n№ 1, 2 — западный квершлаг\n№ 3, 4 — восточный квершлаг\n№ 5 — северный забой\nВ СТАРУЮ ВЫРАБОТКУ НЕ ХОДИТЬ!", { bg = rgb(34, 48, 36), fg = rgb(236, 236, 226), font = Enum.Font.Code, padding = 0.04 })
	local phone = detail(block(ug, "Dispatcher phone", Vector3.new(1.4, 2, 0.8), L(13.5, 4.5, -4), rgb(60, 70, 60), Enum.Material.Metal))
	Build.sign(phone, Enum.NormalId.Left, "☎\nДИСПЕТЧЕР", { bg = rgb(60, 70, 60), fg = rgb(230, 230, 220) })
	local aid = detail(block(ug, "First aid", Vector3.new(0.6, 1.6, 2), L(13.6, 4, 4), rgb(230, 230, 226), Enum.Material.Metal))
	Build.sign(aid, Enum.NormalId.Left, "✚ АПТЕЧКА", { bg = rgb(236, 236, 230), fg = rgb(200, 30, 30) })
	block(ug, "Bench", Vector3.new(1.6, 1.8, 8), L(-12, 0.9, 6), TIMBER, Enum.Material.Wood)
	Build.poster(ug, CFrame.lookAt(L(-13.8, 6, 9), L(0, 6, 9)), Config.Posters[5])
	detail(Build.column(ug, "Extinguisher", 2, 0.8, L(-12.5, 0.4, -10), rgb(200, 30, 30), Enum.Material.Metal))
	spots.ugLanding = CFrame.lookAt(L(0, 3, 2), L(0, 3, -20))

	-- Main haulage drift north.
	drift(ug, L(0, 0, -14), L(0, 0, -200), 10, 11, {
		gapsL = { { at = 56, width = 9 } },
		gapsR = { { at = 126, width = 9 } },
		rails = true,
		lamps = true,
		lampOrder = order,
	})
	-- A cart train parked along the landing's east wall, out of the way.
	for _, x in { -1.3, 1.3 } do
		detail(block(ug, "Siding rail", Vector3.new(0.25, 0.3, 24), L(9 + x, 0.55, -1), rgb(90, 80, 70), Enum.Material.CorrodedMetal))
	end
	cart(ug, CFrame.new(L(9, 0.4, 7)), false)
	cart(ug, CFrame.new(L(9, 0.4, 1)), true)
	cart(ug, CFrame.new(L(9, 0.4, -5)), true)
	block(ug, "Electric locomotive", Vector3.new(3.6, 4, 6), L(9, 2.4, -10.5), rgb(50, 70, 56), Enum.Material.CorrodedMetal)
	wallSign(ug, L(4.9, 5, -64), Vector3.new(-1, 0, 0), "← ЗАБОИ № 1, 2   ·   КЛЕТЬ: НА ЮГ ↓")
	wallSign(ug, L(-4.9, 5, -134), Vector3.new(1, 0, 0), "ЗАБОИ № 3, 4 →   ·   № 5: НА СЕВЕР ↑")
	wallSign(ug, L(-4.9, 5, -100), Vector3.new(1, 0, 0), "↓ К КЛЕТИ", rgb(60, 160, 70))
	wallSign(ug, L(4.9, 5, -180), Vector3.new(-1, 0, 0), "↓ К КЛЕТИ", rgb(60, 160, 70))
	local crate = block(ug, "Explosives crate", Vector3.new(2.4, 1.6, 1.6), L(3.5, 0.8, -150), rgb(110, 80, 50), Enum.Material.WoodPlanks)
	Build.sign(crate, Enum.NormalId.Left, "ВВ · ОПАСНО", { bg = rgb(110, 80, 50), fg = rgb(220, 40, 30) })
	for i = 0, 4 do
		detail(block(ug, "Timber stack", Vector3.new(0.8, 0.8, 6), L(-3.4, 0.4 + i * 0.8, -110), TIMBER, Enum.Material.Wood))
	end

	-- West crosscut and stope.
	drift(ug, L(-5, 0, -70), L(-110, 0, -70), 9, 10, { rails = true, lamps = true, lampOrder = order })
	chamber(ug, L(-125, 0, -70), 30, 36, 16, { east = { { at = 18, width = 9 } } })
	mineLamp(ug, L(-125, 13, -70), order(L(-125, 13, -70)))
	seam(ug, 1, L(-55, 3.5, -74.3), Vector3.new(0, 0, 1))
	seam(ug, 2, L(-139.8, 4, -70), Vector3.new(1, 0, 0))
	wallSign(ug, L(-100, 5, -65.6), Vector3.new(0, 0, -1), "← КЛЕТЬ", rgb(60, 160, 70))

	-- East crosscut and stope.
	drift(ug, L(5, 0, -140), L(100, 0, -140), 9, 10, { rails = true, lamps = true, lampOrder = order })
	chamber(ug, L(115, 0, -140), 30, 36, 16, { west = { { at = 18, width = 9 } } })
	mineLamp(ug, L(115, 13, -140), order(L(115, 13, -140)))
	seam(ug, 3, L(50, 3.5, -135.7), Vector3.new(0, 0, -1))
	seam(ug, 4, L(129.8, 4, -140), Vector3.new(-1, 0, 0))
	wallSign(ug, L(90, 5, -144.4), Vector3.new(0, 0, 1), "КЛЕТЬ →", rgb(60, 160, 70))

	-- North working face.
	chamber(ug, L(0, 0, -213), 32, 26, 14, {
		south = { { at = 16, width = 10 } },
		west = { { at = 13, width = 7, top = 8 } },
	})
	mineLamp(ug, L(4, 12, -213), order(L(4, 12, -213)))
	seam(ug, 5, L(6, 4, -225.8), Vector3.new(0, 0, 1))
	spots.ugNorth = CFrame.lookAt(L(0, 3, -205), L(0, 3, -150))

	-- The old Norillag gallery, boarded up in 1956.
	drift(ug, L(-16, 0, -213), L(-80, 0, -213), 7, 8, { old = true, capEnd = true })
	for i, y in { 4.4, 5.6, 6.8, 7.6 } do
		local board = block(ug, "Boarding", Vector3.new(0.3, 0.5, 8), CFrame.new(L(-17, y, -213)) * CFrame.Angles(math.rad((i % 2 == 0) and 6 or -5), 0, 0), rgb(80, 64, 46), Enum.Material.WoodPlanks)
		board.CanCollide = false
	end
	block(ug, "Broken board", Vector3.new(0.3, 0.5, 6), CFrame.new(L(-17.5, 1.2, -211)) * CFrame.Angles(0.9, 0, 0.3), rgb(80, 64, 46), Enum.Material.WoodPlanks).CanCollide = false
	local warn = wallSign(ug, L(-16.2, 5.6, -213), Vector3.new(1, 0, 0), "ВХОД ЗАПРЕЩЁН · 1956", rgb(200, 40, 30))
	warn.Size = Vector3.new(4, 1.2, 0.1)
	local tally = detail(block(ug, "Tally marks", Vector3.new(8, 3, 0.1), L(-50, 4, -209.6), WALL))
	Build.sign(tally, Enum.NormalId.Front, "IIII IIII IIII IIII IIII\nIIII IIII IIII IIII IIII\nIIII IIII IIII II", { bgTransparency = 1, fg = rgb(170, 160, 140), font = Enum.Font.PermanentMarker })
	detail(block(ug, "Wheelbarrow", Vector3.new(2, 1.2, 3.4), CFrame.new(L(-40, 0.8, -215)) * CFrame.Angles(0, 0.5, 0.4), rgb(70, 60, 50), Enum.Material.CorrodedMetal))
	for i = 0, 5 do
		detail(block(ug, "Old boot", Vector3.new(0.8, 0.9, 1.4), CFrame.new(L(-72 + (i % 3) * 1.1, 0.45, -215 + math.floor(i / 3) * 1.6)) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), rgb(36, 30, 26), Enum.Material.Leather))
	end
	local plank = detail(block(ug, "Inscription board", Vector3.new(0.2, 3, 4), L(-79.85, 3.5, -213), rgb(80, 64, 46), Enum.Material.WoodPlanks))
	Build.sign(plank, Enum.NormalId.Right, "ОН ХОДИТ ЗА ПОСЛЕДНИМ", { bgTransparency = 1, fg = rgb(60, 40, 30), font = Enum.Font.PermanentMarker })
	Build.note(ug, 4, CFrame.new(L(-77, 0.1, -213)) * CFrame.Angles(0, 0.3, 0))

	-- Coworkers on shift (gone when the lamps die).
	show(Figure.build(ug, CFrame.lookAt(L(-12, 0, 4), L(0, 0, 4)), { pose = "sit", seatHeight = 1.8, hat = "helmet", held = "mug", armR = 50, armL = 40, action = "drink", name = "Miner" }), 5, 5)
	show(Figure.build(ug, CFrame.lookAt(L(-30, 0, -73), L(-30, 0, -80)), { hat = "helmet", held = "pick", armR = 100, armL = 90, action = "dig", name = "Miner" }), 5, 5)
	show(Figure.build(ug, CFrame.lookAt(L(80, 0, -137), L(80, 0, -132)), { hat = "helmet", held = "pick", armR = 100, armL = 90, action = "dig", name = "Miner" }), 5, 5)
	show(Figure.build(ug, CFrame.lookAt(L(2.5, 0, -46), L(2.5, 0, -40)), { hat = "helmet", armR = 10, action = "idle", name = "Miner" }), 5, 5)
end

function Mine.build(world)
	local spots = {}
	local folder = Instance.new("Folder")
	folder.Name = "Mine No. 6"
	folder.Parent = world
	surface(folder, spots)
	underground(folder, spots)
	return spots
end

return Mine
