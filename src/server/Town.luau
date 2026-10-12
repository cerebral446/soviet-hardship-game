-- The town: panel housing, the avenue, the courtyard, the plaza, the player's flat
-- and the ruins of the old camp. Returns named spawn spots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Build = require(Shared.Build)
local Figure = require(Shared.Figure)
local Config = require(Shared.Config)

local rgb = Build.rgb
local block, wedge, detail = Build.block, Build.wedge, Build.detail

local Town = {}

local SNOW = rgb(222, 228, 234)
local CONCRETE = { rgb(146, 144, 136), rgb(156, 150, 138), rgb(132, 136, 136), rgb(150, 140, 130), rgb(124, 130, 138) }
local WARM = { rgb(150, 102, 52), rgb(160, 118, 66), rgb(130, 92, 56), rgb(150, 112, 80), rgb(120, 80, 44) }
local rng = Random.new(1984)

local function face(pos, dir)
	return CFrame.lookAt(pos, pos + dir)
end

-- A five-storey Khrushchyovka on short piles, as they are built on permafrost.
-- cf: ground centre, LookVector = the front (street side). Entrances are on the back (courtyard).
local function apartmentBlock(parent, name, cf, length, opts)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local floors = opts.floors or 5
	local depth = 30
	local floorH = 7.5
	local plinth = 3
	local h = floors * floorH
	local color = opts.color or CONCRETE[rng:NextInteger(1, #CONCRETE)]
	local lit = opts.lit or 0.22

	block(m, "Piles", Vector3.new(length - 1.5, plinth, depth - 1.5), cf * CFrame.new(0, plinth / 2, 0), rgb(44, 44, 46))
	for x = -length / 2 + 4, length / 2 - 4, 8 do
		for _, z in { -depth / 2 + 1.2, depth / 2 - 1.2 } do
			detail(block(m, "Pile", Vector3.new(1, plinth, 1), cf * CFrame.new(x, plinth / 2, z), rgb(90, 90, 88)))
		end
	end
	block(m, "Body", Vector3.new(length, h, depth), cf * CFrame.new(0, plinth + h / 2, 0), color)
	block(m, "Roof snow", Vector3.new(length + 0.6, 0.8, depth + 0.6), cf * CFrame.new(0, plinth + h + 0.4, 0), SNOW, Enum.Material.Snow)
	for f = 1, floors - 1 do
		detail(block(m, "Panel seam", Vector3.new(length + 0.15, 0.25, depth + 0.15), cf * CFrame.new(0, plinth + f * floorH, 0), color:Lerp(rgb(30, 30, 30), 0.3)))
	end
	for x = -length / 2 + 12, length / 2 - 6, 12 do
		detail(block(m, "Panel seam", Vector3.new(0.25, h, depth + 0.15), cf * CFrame.new(x, plinth + h / 2, 0), color:Lerp(rgb(30, 30, 30), 0.25)))
	end

	-- Windows on both long faces. Some are lit: somebody is still awake.
	local entrances = opts.entrances or {}
	local function nearEntrance(x)
		for _, ex in entrances do
			if math.abs(ex - x) < 3.5 then
				return true
			end
		end
		return false
	end
	local column = 0
	for x = -length / 2 + 4, length / 2 - 4, 6 do
		column += 1
		for _, side in { -1, 1 } do
			if side == 1 and nearEntrance(x) then
				continue
			end
			for f = 1, floors do
				if opts.shopFrom and side == -1 and f == 1 and x >= opts.shopFrom and x <= opts.shopTo then
					continue
				end
				local y = plinth + (f - 1) * floorH + 3.8
				local pos = cf * CFrame.new(x, y, side * (depth / 2 + 0.1))
				local w = detail(block(m, "Window", Vector3.new(3.2, 3.8, 0.25), pos, rgb(22, 28, 34), Enum.Material.Glass))
				w.Reflectance = 0.08
				local r = rng:NextNumber()
				if r < lit then
					w.Material = Enum.Material.Neon
					w.Color = WARM[rng:NextInteger(1, #WARM)]
					w.Name = "Lit window"
					if rng:NextNumber() < 0.08 then
						w.Color = rgb(60, 78, 112)
						Build.tag(w, "TVWindow")
					end
					if rng:NextNumber() < 0.35 then
						local glow = detail(block(m, "Window glow", Vector3.new(0.2, 0.2, 0.2), pos * CFrame.new(0, 0, side * 1.2), w.Color))
						glow.Transparency = 1
						Build.light(glow, w.Color:Lerp(rgb(255, 200, 140), 0.5), 11, 0.55)
					end
					-- A curtain half drawn.
					if rng:NextNumber() < 0.5 then
						detail(block(m, "Curtain", Vector3.new(1.3, 3.8, 0.1), pos * CFrame.new(rng:NextNumber() < 0.5 and -0.95 or 0.95, 0, side * 0.12), rgb(120, 60, 40):Lerp(rgb(160, 150, 110), rng:NextNumber()), Enum.Material.Fabric))
					end
				end
				detail(block(m, "Sill", Vector3.new(3.6, 0.2, 0.5), pos * CFrame.new(0, -2, side * 0.2), SNOW, Enum.Material.Snow))
				-- Balconies on the street side.
				if side == -1 and f >= 2 and column % 2 == 0 then
					local base = pos * CFrame.new(0, -2.2, -1.2)
					detail(block(m, "Balcony", Vector3.new(4.4, 0.35, 2.4), base, color:Lerp(rgb(0, 0, 0), 0.1)))
					local rail = ({ rgb(120, 70, 50), rgb(70, 100, 100), rgb(140, 130, 110), rgb(90, 90, 96) })[rng:NextInteger(1, 4)]
					detail(block(m, "Balcony rail", Vector3.new(4.4, 1.7, 0.18), base * CFrame.new(0, 1, -1.1), rail, Enum.Material.CorrodedMetal))
					detail(block(m, "Balcony snow", Vector3.new(4.3, 0.25, 2.3), base * CFrame.new(0, 0.3, 0), SNOW, Enum.Material.Snow))
					if rng:NextNumber() < 0.3 then
						detail(block(m, "Stored junk", Vector3.new(1.4, 1.2, 1), base * CFrame.new(rng:NextNumber(-1.2, 1.2), 0.8, -0.2), rgb(90, 80, 66), Enum.Material.WoodPlanks))
					end
				end
			end
		end
	end

	-- Entrances (podyezds) on the courtyard side.
	local doors = {}
	for i, x in entrances do
		local back = depth / 2
		block(m, "Entrance steps", Vector3.new(8, 0.8, 4), cf * CFrame.new(x, 0.4, back + 2), rgb(110, 110, 106))
		local door = block(m, "Entrance door", Vector3.new(3.6, 5.4, 0.3), cf * CFrame.new(x, 3.5, back + 0.15), rgb(70, 52, 38), Enum.Material.WoodPlanks)
		table.insert(doors, door)
		block(m, "Canopy", Vector3.new(8, 0.5, 4.5), cf * CFrame.new(x, 7.3, back + 2.2), color)
		detail(block(m, "Canopy snow", Vector3.new(7.8, 0.4, 4.3), cf * CFrame.new(x, 7.7, back + 2.2), SNOW, Enum.Material.Snow))
		local bulb = detail(Build.ball(m, "Entrance lamp", 0.7, cf * CFrame.new(x, 6.7, back + 1.2), rgb(255, 196, 120), Enum.Material.Neon))
		if rng:NextNumber() < 0.85 then
			Build.light(bulb, rgb(255, 180, 110), 17, 0.9, true)
			Build.tag(bulb, "EntranceLamp")
		else
			bulb.Color = rgb(60, 56, 50)
			bulb.Material = Enum.Material.Glass
		end
		local plate = detail(block(m, "Entrance sign", Vector3.new(2.6, 1, 0.1), cf * CFrame.new(x + 3, 5, back + 0.08) * CFrame.Angles(0, math.pi, 0), rgb(40, 60, 110)))
		Build.sign(plate, Enum.NormalId.Front, ("ПОДЪЕЗД %d\nкв. %d–%d"):format(i, (i - 1) * 20 + 1, i * 20), { bg = rgb(36, 56, 104), fg = rgb(236, 236, 230), font = Enum.Font.Arimo })
		for f = 1, floors do
			local w = detail(block(m, "Stairwell window", Vector3.new(2, 2.6, 0.25), cf * CFrame.new(x, plinth + f * floorH - 0.6, back + 0.1), rgb(24, 30, 34), Enum.Material.Glass))
			if rng:NextNumber() < 0.55 then
				w.Material = Enum.Material.Neon
				w.Color = rgb(96, 110, 84)
			end
		end
		-- Bench with snow on it.
		local bench = cf * CFrame.new(x + 6, 0, back + 3.5)
		detail(block(m, "Bench", Vector3.new(4, 0.3, 1.2), bench * CFrame.new(0, 1.5, 0), rgb(90, 60, 40), Enum.Material.WoodPlanks))
		detail(block(m, "Bench snow", Vector3.new(3.9, 0.3, 1.1), bench * CFrame.new(0, 1.75, 0), SNOW, Enum.Material.Snow))
		for _, bx in { -1.6, 1.6 } do
			detail(block(m, "Bench leg", Vector3.new(0.3, 1.5, 1), bench * CFrame.new(bx, 0.75, 0), rgb(60, 60, 60), Enum.Material.Metal))
		end
		local board = detail(block(m, "Notice board", Vector3.new(2.2, 1.6, 0.1), cf * CFrame.new(x - 3.2, 4.2, back + 0.08) * CFrame.Angles(0, math.pi, 0), rgb(200, 190, 160)))
		Build.sign(board, Enum.NormalId.Front, "ОБЪЯВЛЕНИЕ\nЖильцам: отопление будет отключено 14.12 с 8:00 до 20:00.\nЖЭК № 3", { bg = rgb(214, 204, 172), fg = rgb(30, 30, 30), font = Enum.Font.Arimo, padding = 0.05 })
	end

	-- Shop on the ground floor of the street side.
	if opts.shop then
		local mid = (opts.shopFrom + opts.shopTo) / 2
		local width = opts.shopTo - opts.shopFrom + 4
		local front = -depth / 2
		local display = detail(block(m, "Shop window", Vector3.new(width - 4, 3.6, 0.3), cf * CFrame.new(mid, plinth + 3.6, front - 0.1), rgb(110, 116, 100), Enum.Material.Neon))
		display.Transparency = 0.2
		local inside = detail(block(m, "Shop glow", Vector3.new(1, 1, 1), cf * CFrame.new(mid, plinth + 3.6, front - 2), rgb(255, 255, 255)))
		inside.Transparency = 1
		Build.light(inside, rgb(200, 220, 200), 18, 0.6)
		local sign = detail(block(m, "Shop sign", Vector3.new(width, 2.2, 0.4), cf * CFrame.new(mid, plinth + 6.7, front - 0.3), rgb(30, 30, 30)))
		Build.sign(sign, Enum.NormalId.Front, opts.shop, { bg = rgb(30, 22, 22), fg = rgb(255, 70, 50), lightInfluence = 0, brightness = 1.4 })
		Build.sign(display, Enum.NormalId.Front, opts.shopWindow or "", { bg = rgb(0, 0, 0), bgTransparency = 1, fg = rgb(40, 40, 30), font = Enum.Font.Arimo })
	end

	-- House number plate.
	local plate = detail(block(m, "Address", Vector3.new(5, 1.3, 0.1), cf * CFrame.new(length / 2 - 4, plinth + 2, -depth / 2 - 0.08), rgb(36, 56, 104)))
	Build.sign(plate, Enum.NormalId.Front, opts.address or "", { bg = rgb(36, 56, 104), fg = rgb(240, 240, 232), font = Enum.Font.Arimo })

	-- Television aerials.
	for _ = 1, 3 do
		local base = cf * CFrame.new(rng:NextNumber(-length / 2 + 5, length / 2 - 5), plinth + h + 0.8, rng:NextNumber(-8, 8))
		detail(block(m, "Aerial", Vector3.new(0.15, 5, 0.15), base * CFrame.new(0, 2.5, 0), rgb(60, 60, 60), Enum.Material.Metal))
		for k = 0, 2 do
			detail(block(m, "Aerial bar", Vector3.new(2.6 - k * 0.6, 0.1, 0.1), base * CFrame.new(0, 3.4 + k * 0.7, 0) * CFrame.Angles(0, rng:NextNumber(0, 0.3), 0), rgb(60, 60, 60), Enum.Material.Metal))
		end
	end

	-- A huge slogan on one gable end.
	if opts.gablePoster then
		local design = Config.Posters[opts.gablePoster]
		local side = opts.gableSide or 1
		local pos = (cf * CFrame.new(side * (length / 2 + 0.2), plinth + h / 2 + 2, 0)).Position
		Build.poster(m, face(pos, cf.RightVector * side), design, Vector2.new(20, 28))
	end

	-- Snowdrifts against the walls.
	for _ = 1, math.floor(length / 14) do
		local side = rng:NextNumber() < 0.5 and -1 or 1
		local x = rng:NextNumber(-length / 2, length / 2)
		local d = wedge(m, "Snowdrift", Vector3.new(rng:NextNumber(5, 10), rng:NextNumber(1.5, 3), 3), cf * CFrame.new(x, 1, side * (depth / 2 + 1.5)) * CFrame.Angles(0, side == 1 and 0 or math.pi, 0), SNOW, Enum.Material.Snow)
		detail(d)
	end

	return m, doors
end

local function streetlight(parent, base, armDir, working)
	local pole = block(parent, "Streetlight pole", Vector3.new(0.6, 15, 0.6), base + Vector3.new(0, 7.5, 0), rgb(70, 74, 72), Enum.Material.Metal)
	local tip = base + Vector3.new(0, 14.6, 0) + armDir * 4
	detail(Build.beam(parent, "Streetlight arm", base + Vector3.new(0, 14.6, 0), tip, 0.35, rgb(70, 74, 72), Enum.Material.Metal))
	local head = detail(block(parent, "Streetlight head", Vector3.new(1.6, 0.5, 0.9), CFrame.lookAt(tip, tip + armDir) * CFrame.Angles(0, math.pi / 2, 0), rgb(255, 170, 90), Enum.Material.Neon))
	if working then
		local light = Build.light(head, rgb(255, 168, 92), 34, 1.5, true)
		light.Name = "Light"
		Build.tag(head, "Streetlight")
	else
		head.Color = rgb(60, 52, 44)
		head.Material = Enum.Material.Glass
	end
	return pole, head
end

local function lada(parent, cf, color)
	local m = Instance.new("Model")
	m.Name = "Zhiguli"
	m.Parent = parent
	block(m, "Body", Vector3.new(4.6, 1.6, 10), cf * CFrame.new(0, 1.6, 0), color, Enum.Material.SmoothPlastic)
	block(m, "Cabin", Vector3.new(4.2, 1.5, 5), cf * CFrame.new(0, 3.1, 0.5), color, Enum.Material.SmoothPlastic)
	for _, z in { -2.2, 3 } do
		local win = detail(block(m, "Windscreen", Vector3.new(3.8, 1.2, 0.1), cf * CFrame.new(0, 3.1, z - 0.05 + (z < 0 and 0 or 0)), rgb(30, 36, 40), Enum.Material.Glass))
		win.Transparency = 0.2
	end
	detail(block(m, "Roof snow", Vector3.new(4.1, 0.5, 4.9), cf * CFrame.new(0, 4.05, 0.5), SNOW, Enum.Material.Snow))
	detail(block(m, "Bonnet snow", Vector3.new(4.4, 0.4, 2.6), cf * CFrame.new(0, 2.6, -3.6), SNOW, Enum.Material.Snow))
	for _, x in { -2.2, 2.2 } do
		for _, z in { -3.2, 3.2 } do
			detail(Build.cylinder(m, "Wheel", 0.8, 2, cf * CFrame.new(x, 1, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
	for _, x in { -1.6, 1.6 } do
		detail(Build.ball(m, "Headlight", 0.6, cf * CFrame.new(x, 1.8, -5), rgb(200, 200, 180), Enum.Material.Glass))
	end
	local plate = detail(block(m, "Plate", Vector3.new(2, 0.5, 0.05), cf * CFrame.new(0, 1.2, -5.03) * CFrame.Angles(0, math.pi, 0), rgb(230, 230, 230)))
	Build.sign(plate, Enum.NormalId.Front, "К 12-48 КЯ", { bg = rgb(232, 232, 228), fg = rgb(20, 20, 20), font = Enum.Font.Arimo })
	wedge(m, "Snow heap", Vector3.new(5.5, 1.6, 4), cf * CFrame.new(0, 0.8, 6) * CFrame.Angles(0, math.pi, 0), SNOW, Enum.Material.Snow)
	return m
end

local function apartmentInterior(parent, origin, spots)
	local m = Instance.new("Model")
	m.Name = "Flat 23"
	m.Parent = parent
	local function at(x, y, z)
		return CFrame.new(origin + Vector3.new(x, y, z))
	end
	local wallpaper = rgb(176, 160, 118)
	block(m, "Floor", Vector3.new(28, 1, 22), at(0, -0.5, 0), rgb(120, 78, 46), Enum.Material.WoodPlanks)
	block(m, "Ceiling", Vector3.new(28, 1, 22), at(0, 10.5, 0), rgb(220, 216, 204), Enum.Material.SmoothPlastic)
	local o = origin
	Build.wall(m, o + Vector3.new(-13, 0, -10), o + Vector3.new(13, 0, -10), Vector3.new(0, 0, -1), 10, 1, { { at = 9, width = 6, bottom = 3, top = 8 } }, wallpaper, Enum.Material.Fabric)
	Build.wall(m, o + Vector3.new(-13, 0, 10), o + Vector3.new(13, 0, 10), Vector3.new(0, 0, 1), 10, 1, {}, wallpaper, Enum.Material.Fabric)
	Build.wall(m, o + Vector3.new(-13, 0, -11), o + Vector3.new(-13, 0, 11), Vector3.new(-1, 0, 0), 10, 1, {}, wallpaper, Enum.Material.Fabric)
	Build.wall(m, o + Vector3.new(13, 0, -11), o + Vector3.new(13, 0, 11), Vector3.new(1, 0, 0), 10, 1, {}, wallpaper, Enum.Material.Fabric)
	detail(block(m, "Skirting", Vector3.new(26, 0.5, 0.2), at(0, 0.25, 9.9), rgb(90, 60, 40), Enum.Material.Wood))
	detail(block(m, "Skirting", Vector3.new(26, 0.5, 0.2), at(0, 0.25, -9.9), rgb(90, 60, 40), Enum.Material.Wood))

	-- Frosted window and the snow beyond it.
	local glass = detail(block(m, "Frosted window", Vector3.new(6, 5, 0.2), at(-4, 5.5, -10.4), rgb(170, 190, 205), Enum.Material.Glass))
	glass.Transparency = 0.55
	detail(block(m, "Window frame", Vector3.new(0.3, 5, 0.4), at(-4, 5.5, -10.4), rgb(230, 230, 222), Enum.Material.Wood))
	detail(block(m, "Window frame", Vector3.new(6, 0.3, 0.4), at(-4, 6.5, -10.4), rgb(230, 230, 222), Enum.Material.Wood))
	detail(block(m, "Window sill", Vector3.new(6.6, 0.3, 1), at(-4, 2.9, -9.6), rgb(230, 230, 222), Enum.Material.Wood))
	detail(block(m, "Radiator", Vector3.new(5, 2, 0.5), at(-4, 1.6, -9.6), rgb(200, 196, 186), Enum.Material.Metal))
	local outside = detail(block(m, "Outside", Vector3.new(8, 1, 8), at(-4, 12, -16), rgb(0, 0, 0)))
	outside.Transparency = 1
	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/smoke_main.dds"
	snow.Rate = 60
	snow.Lifetime = NumberRange.new(4, 6)
	snow.Speed = NumberRange.new(2, 4)
	snow.Size = NumberSequence.new(0.15)
	snow.Acceleration = Vector3.new(3, -4, 0)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.LightInfluence = 0.4
	snow.Parent = outside
	local farLamp = detail(Build.ball(m, "Distant streetlight", 0.8, at(-14, 4, -60), rgb(255, 170, 90), Enum.Material.Neon))
	farLamp.Transparency = 0.2

	-- Wall carpet: every flat in the Union had one.
	local carpet = detail(block(m, "Wall carpet", Vector3.new(0.15, 6, 9), at(-12.4, 5.6, -1), rgb(120, 26, 32), Enum.Material.Fabric))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = carpet
	local function frame(px, py, sx, sy, color, rot)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(px, py)
		f.Size = UDim2.fromScale(sx, sy)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Rotation = rot or 0
		f.Parent = gui
		return f
	end
	frame(0.5, 0.5, 1, 1, rgb(122, 24, 30))
	frame(0.5, 0.5, 0.92, 0.88, rgb(30, 30, 60))
	frame(0.5, 0.5, 0.86, 0.78, rgb(150, 36, 40))
	frame(0.5, 0.5, 0.3, 0.45, rgb(214, 170, 90), 45)
	frame(0.5, 0.5, 0.2, 0.3, rgb(30, 30, 60), 45)
	frame(0.5, 0.5, 0.1, 0.15, rgb(230, 220, 190), 45)
	for _, p in { { 0.2, 0.25 }, { 0.8, 0.25 }, { 0.2, 0.75 }, { 0.8, 0.75 } } do
		frame(p[1], p[2], 0.1, 0.15, rgb(214, 170, 90), 45)
		frame(p[1], p[2], 0.05, 0.07, rgb(30, 30, 60), 45)
	end

	-- Sofa bed under the carpet.
	block(m, "Sofa", Vector3.new(3.6, 1.6, 8.5), at(-10.8, 0.8, -1), rgb(84, 70, 60), Enum.Material.Fabric)
	block(m, "Sofa back", Vector3.new(1, 2.6, 8.5), at(-12.4, 2.1, -1), rgb(84, 70, 60), Enum.Material.Fabric)
	detail(block(m, "Blanket", Vector3.new(3.2, 0.3, 5), at(-10.6, 1.75, 0.5), rgb(70, 90, 70), Enum.Material.Fabric))
	detail(block(m, "Pillow", Vector3.new(2, 0.6, 1.4), at(-10.8, 1.9, -4.2), rgb(236, 232, 220), Enum.Material.Fabric))

	-- Sideboard with crystal and the radio.
	block(m, "Sideboard", Vector3.new(6, 3.4, 2), at(8, 1.7, -8.8), rgb(66, 40, 26), Enum.Material.Wood)
	local upper = block(m, "Sideboard glass", Vector3.new(6, 3.6, 1.6), at(8, 5.2, -9), rgb(150, 160, 160), Enum.Material.Glass)
	upper.Transparency = 0.6
	detail(block(m, "Sideboard top", Vector3.new(6.2, 0.3, 2.1), at(8, 7.1, -8.8), rgb(66, 40, 26), Enum.Material.Wood))
	for i = 0, 4 do
		local c = detail(Build.column(m, "Crystal", 0.7, 0.5, origin + Vector3.new(5.8 + i * 1.1, 3.5, -9), rgb(220, 230, 240), Enum.Material.Glass))
		c.Transparency = 0.3
	end
	local radio = detail(block(m, "Radio VEF", Vector3.new(2.4, 1.3, 0.8), at(8, 7.9, -9), rgb(40, 40, 40), Enum.Material.SmoothPlastic))
	Build.sign(radio, Enum.NormalId.Back, "ВЭФ", { bg = rgb(50, 46, 40), fg = rgb(220, 200, 150) })

	-- Rubin television.
	block(m, "TV Rubin", Vector3.new(2.4, 2.6, 3.2), at(11.4, 2.9, 1), rgb(70, 46, 30), Enum.Material.Wood)
	local screen = detail(block(m, "TV screen", Vector3.new(0.1, 1.9, 2.4), at(10.17, 3.05, 1), rgb(38, 46, 44), Enum.Material.Glass))
	Build.tag(screen, "TVScreen")
	for _, z in { -0.2, 2.2 } do
		detail(block(m, "TV leg", Vector3.new(0.25, 1.6, 0.25), at(11.4, 0.8, z), rgb(30, 30, 30), Enum.Material.Metal))
	end

	-- Table, tea, the letter.
	block(m, "Table", Vector3.new(5, 0.3, 3.6), at(0, 2.8, 1), rgb(236, 230, 214), Enum.Material.Fabric)
	for _, x in { -2.2, 2.2 } do
		for _, z in { -0.4, 2.4 } do
			detail(block(m, "Table leg", Vector3.new(0.3, 2.65, 0.3), at(x, 1.33, z), rgb(80, 50, 30), Enum.Material.Wood))
		end
	end
	for _, z in { -1.5, 3.5 } do
		block(m, "Chair", Vector3.new(1.8, 0.3, 1.8), at(0, 1.8, z), rgb(90, 60, 40), Enum.Material.Wood)
		detail(block(m, "Chair back", Vector3.new(1.8, 2.2, 0.25), at(0, 3, z + (z > 1 and 0.8 or -0.8)), rgb(90, 60, 40), Enum.Material.Wood))
	end
	local tea = detail(Build.column(m, "Glass of tea", 0.7, 0.45, origin + Vector3.new(-1.6, 2.95, 1.2), rgb(150, 70, 30), Enum.Material.Glass))
	tea.Transparency = 0.2
	detail(Build.column(m, "Tea glass holder", 0.4, 0.55, origin + Vector3.new(-1.6, 2.95, 1.2), rgb(170, 150, 100), Enum.Material.Metal))
	local paper = detail(block(m, "Pravda", Vector3.new(1.6, 0.05, 2.2), at(1.4, 2.98, 1.6) * CFrame.Angles(0, 0.3, 0), rgb(220, 214, 196), Enum.Material.SmoothPlastic))
	Build.sign(paper, Enum.NormalId.Top, "ПРАВДА\n12 декабря 1984\nТРУДОВЫЕ ПОБЕДЫ ЗАПОЛЯРЬЯ", { bg = rgb(222, 216, 198), fg = rgb(40, 30, 30), font = Enum.Font.Merriweather })
	local clock = detail(block(m, "Alarm clock", Vector3.new(0.8, 0.8, 0.4), at(-0.3, 3.35, 0) * CFrame.Angles(0, math.pi, 0), rgb(180, 40, 40), Enum.Material.SmoothPlastic))
	Build.sign(clock, Enum.NormalId.Front, "05:50", { bg = rgb(230, 226, 210), fg = rgb(20, 20, 20), font = Enum.Font.Code })
	Build.note(m, 1, at(0.3, 2.98, 0.6) * CFrame.Angles(0, -0.2, 0))

	-- Lampshade.
	local shade = detail(Build.ball(m, "Lampshade", 2.2, at(0, 8.6, 1), rgb(220, 140, 70), Enum.Material.Neon))
	shade.Transparency = 0.3
	detail(block(m, "Lamp cord", Vector3.new(0.1, 1.6, 0.1), at(0, 9.6, 1), rgb(30, 30, 30)))
	Build.light(shade, rgb(255, 196, 130), 26, 0.9, true)

	-- Calendar, portrait, rug, coats, stove.
	local cal = detail(block(m, "Calendar", Vector3.new(0.1, 2.4, 1.7), at(12.45, 6, 6), rgb(230, 225, 210)))
	Build.sign(cal, Enum.NormalId.Left, "1984\nДЕКАБРЬ\n\n12", { bg = rgb(236, 230, 214), fg = rgb(150, 30, 30), font = Enum.Font.Oswald })
	local portrait = detail(block(m, "Portrait", Vector3.new(2.6, 3.2, 0.2), at(-4, 6.2, 9.4), rgb(120, 90, 50), Enum.Material.Wood))
	Build.sign(portrait, Enum.NormalId.Back, "★\nВ. И. ЛЕНИН", { bg = rgb(140, 120, 90), fg = rgb(50, 36, 24), padding = 0.1 })
	detail(block(m, "Rug", Vector3.new(9, 0.06, 6), at(0, 0.03, 1), rgb(140, 40, 40), Enum.Material.Fabric))
	detail(block(m, "Rug border", Vector3.new(8, 0.07, 5), at(0, 0.035, 1), rgb(60, 50, 80), Enum.Material.Fabric))
	detail(block(m, "Coat rack", Vector3.new(0.3, 6, 0.3), at(11, 3, 8.6), rgb(80, 50, 30), Enum.Material.Wood))
	detail(block(m, "Hanging coat", Vector3.new(1.6, 3.6, 0.9), at(11, 4, 8.1), rgb(60, 62, 58), Enum.Material.Fabric))
	detail(block(m, "Stove", Vector3.new(2.6, 3, 2.4), at(-11, 1.5, 7.8), rgb(232, 232, 226), Enum.Material.SmoothPlastic))
	detail(Build.column(m, "Kettle", 1, 1.2, origin + Vector3.new(-11, 3, 7.6), rgb(90, 120, 150), Enum.Material.SmoothPlastic))

	-- The door: padded leatherette, a peephole.
	local door = block(m, "Flat door", Vector3.new(4, 7, 0.3), at(8, 3.5, 9.4), rgb(92, 34, 30), Enum.Material.Leather)
	for y = 1.2, 6.2, 1.25 do
		for x = -1.4, 1.4, 1.4 do
			detail(Build.ball(m, "Door stud", 0.18, at(8 + x, y, 9.24), rgb(190, 170, 110), Enum.Material.Metal))
		end
	end
	detail(Build.ball(m, "Peephole", 0.25, at(8, 5.4, 9.22), rgb(20, 20, 20), Enum.Material.Metal))
	Build.interact(door, "leaveHome", "Leave for work", "Front door", 1.2)

	spots.aptStart = CFrame.lookAt(origin + Vector3.new(-3, 3, -4), origin + Vector3.new(1, 3, 2))
	spots.aptEnd = CFrame.lookAt(origin + Vector3.new(8, 3, 6.6), origin + Vector3.new(8, 3, -4))
	return m
end

local function playground(parent, at)
	local metal = rgb(150, 60, 50)
	-- Swings.
	for _, x in { -4, 4 } do
		for _, z in { -1.5, 1.5 } do
			detail(Build.beam(parent, "Swing frame", at + Vector3.new(x, 0, z * 1.5), at + Vector3.new(x, 8, 0), 0.3, metal, Enum.Material.CorrodedMetal))
		end
	end
	detail(Build.beam(parent, "Swing bar", at + Vector3.new(-4.2, 8, 0), at + Vector3.new(4.2, 8, 0), 0.35, metal, Enum.Material.CorrodedMetal))
	for _, x in { -0.8, 0.8 } do
		detail(block(parent, "Swing chain", Vector3.new(0.08, 6, 0.08), at + Vector3.new(x, 5, 0), rgb(60, 60, 60), Enum.Material.Metal))
	end
	local seat = detail(block(parent, "Swing seat", Vector3.new(2, 0.2, 1), at + Vector3.new(0, 2, 0), rgb(90, 60, 40), Enum.Material.WoodPlanks))
	Build.tag(seat, "Swing")
	-- Carousel.
	local c = at + Vector3.new(14, 0, 6)
	detail(Build.cylinder(parent, "Carousel", 0.4, 7, CFrame.new(c + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.pi / 2), rgb(60, 110, 150), Enum.Material.CorrodedMetal))
	detail(Build.column(parent, "Carousel post", 3, 0.4, c, rgb(60, 60, 60), Enum.Material.Metal))
	-- Climbing rocket: the playground staple.
	local r = at + Vector3.new(-12, 0, 10)
	detail(Build.column(parent, "Rocket", 12, 3.4, r, rgb(170, 60, 50), Enum.Material.CorrodedMetal))
	detail(Build.column(parent, "Rocket nose", 2, 2, r + Vector3.new(0, 12, 0), rgb(200, 200, 190), Enum.Material.CorrodedMetal))
	for i = 0, 2 do
		local a = i * math.pi * 2 / 3
		detail(Build.wedge(parent, "Rocket fin", Vector3.new(0.3, 3, 2.4), CFrame.new(r + Vector3.new(math.cos(a) * 2.6, 1.5, math.sin(a) * 2.6)) * CFrame.Angles(0, -a + math.pi / 2, 0), rgb(200, 200, 190), Enum.Material.CorrodedMetal))
	end
	-- Sandbox under snow and an abandoned sled.
	block(parent, "Sandbox", Vector3.new(7, 1, 7), at + Vector3.new(10, 0.5, -10), rgb(110, 80, 50), Enum.Material.WoodPlanks)
	detail(block(parent, "Sandbox snow", Vector3.new(6.4, 0.3, 6.4), at + Vector3.new(10, 1.05, -10), SNOW, Enum.Material.Snow))
	detail(block(parent, "Sled", Vector3.new(1.4, 0.4, 3), CFrame.new(at + Vector3.new(3, 0.3, -6)) * CFrame.Angles(0, 0.6, 0), rgb(140, 40, 40), Enum.Material.Metal))
end

local function garages(parent, start, count)
	for i = 0, count - 1 do
		local p = start + Vector3.new(i * 8.5, 0, 0)
		local color = ({ rgb(90, 100, 90), rgb(110, 80, 60), rgb(70, 80, 100), rgb(120, 116, 100) })[rng:NextInteger(1, 4)]
		block(parent, "Garage", Vector3.new(8, 7, 14), p + Vector3.new(0, 3.5, 0), color, Enum.Material.CorrodedMetal)
		local door = detail(block(parent, "Garage door", Vector3.new(6.6, 5.6, 0.2), p + Vector3.new(0, 2.8, 7.05), color:Lerp(rgb(0, 0, 0), 0.2), Enum.Material.CorrodedMetal))
		Build.sign(door, Enum.NormalId.Back, tostring(17 + i), { bg = rgb(0, 0, 0), bgTransparency = 1, fg = rgb(230, 230, 220) })
		detail(block(parent, "Garage snow", Vector3.new(8.2, 0.6, 14.2), p + Vector3.new(0, 7.3, 0), SNOW, Enum.Material.Snow))
	end
end

local function heatingPipes(parent, points)
	-- Norilsk runs its heating mains above ground, wrapped in silver insulation.
	local insulation = rgb(178, 180, 176)
	local lastPerp = Vector3.xAxis
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local dir = (b - a).Unit
		local perp = math.abs(dir.Y) > 0.9 and lastPerp or dir:Cross(Vector3.yAxis).Unit
		lastPerp = perp
		for k, off in { -1, 1 } do
			local o = perp * off * 1
			Build.pipe(parent, "Heating main", a + o, b + o, 1.5, k == 1 and insulation or insulation:Lerp(rgb(120, 100, 80), 0.2), Enum.Material.Foil)
			detail(Build.ball(parent, "Pipe joint", 1.5, a + o, insulation, Enum.Material.Foil))
		end
		if math.abs(dir.Y) < 0.1 then
			local length = (b - a).Magnitude
			for s = 4, length - 2, 10 do
				local p = a + dir * s
				-- No posts in the roadway under the arch.
				if math.abs(p.X) < 24 then
					continue
				end
				block(parent, "Pipe support", Vector3.new(0.8, p.Y, 0.8), Vector3.new(p.X, p.Y / 2 - 0.6, p.Z), rgb(120, 118, 112))
				detail(block(parent, "Pipe saddle", Vector3.new(3.4, 0.4, 0.9), CFrame.lookAt(p - Vector3.new(0, 0.95, 0), p - Vector3.new(0, 0.95, 0) + perp) * CFrame.Angles(0, math.pi / 2, 0), rgb(90, 90, 86), Enum.Material.Metal))
			end
		end
	end
end

local function steamLeak(parent, at)
	local p = detail(block(parent, "Steam leak", Vector3.new(0.5, 0.5, 0.5), at, rgb(255, 255, 255)))
	p.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 14
	e.Lifetime = NumberRange.new(2, 4)
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(25, 25)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 6) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	e.Acceleration = Vector3.new(2, 2, 0)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
end

local function lenin(parent, at)
	local bronze = rgb(58, 54, 48)
	local cf = CFrame.lookAt(at, at + Vector3.new(-1, 0, 0))
	block(parent, "Plinth", Vector3.new(7, 9, 7), cf * CFrame.new(0, 4.5, 0), rgb(90, 50, 48), Enum.Material.Granite)
	detail(block(parent, "Plinth snow", Vector3.new(7.3, 0.4, 7.3), cf * CFrame.new(0, 9.1, 0), SNOW, Enum.Material.Snow))
	local plate = detail(block(parent, "Inscription", Vector3.new(4.6, 1.2, 0.1), cf * CFrame.new(0, 6, -3.56), rgb(90, 50, 48)))
	Build.sign(plate, Enum.NormalId.Front, "В. И. ЛЕНИН", { bg = rgb(90, 50, 48), fg = rgb(214, 180, 100), font = Enum.Font.Oswald })
	-- The figure.
	block(parent, "Lenin legs", Vector3.new(2.4, 4, 1.6), cf * CFrame.new(0, 11.2, 0), bronze, Enum.Material.Metal)
	block(parent, "Lenin coat", Vector3.new(3.4, 5, 2.2), cf * CFrame.new(0, 15.2, 0.1), bronze, Enum.Material.Metal)
	detail(Build.wedge(parent, "Coat tail", Vector3.new(3.4, 3, 2), cf * CFrame.new(0, 11.8, 1.6), bronze, Enum.Material.Metal))
	detail(Build.ball(parent, "Lenin head", 2, cf * CFrame.new(0, 18.7, 0), bronze, Enum.Material.Metal))
	detail(block(parent, "Lenin cap", Vector3.new(2, 0.6, 2.3), cf * CFrame.new(0, 19.6, -0.1), bronze, Enum.Material.Metal))
	detail(block(parent, "Lenin arm", Vector3.new(0.8, 0.8, 4.6), cf * CFrame.new(1.4, 16.8, -2.2) * CFrame.Angles(0.35, 0, 0), bronze, Enum.Material.Metal))
	detail(block(parent, "Lenin arm", Vector3.new(0.8, 3.6, 0.8), cf * CFrame.new(-1.9, 15, 0), bronze, Enum.Material.Metal))
	detail(block(parent, "Snow on shoulders", Vector3.new(3.3, 0.3, 2), cf * CFrame.new(0, 17.8, 0.1), SNOW, Enum.Material.Snow))
	-- Flags and floodlight.
	for _, z in { -7, 7 } do
		local base = (cf * CFrame.new(z, 0, 3)).Position
		block(parent, "Flagpole", Vector3.new(0.3, 16, 0.3), base + Vector3.new(0, 8, 0), rgb(160, 160, 160), Enum.Material.Metal)
		detail(block(parent, "Red flag", Vector3.new(0.1, 2.6, 4), base + Vector3.new(0, 14.6, -2.1), rgb(160, 24, 24), Enum.Material.Fabric))
	end
	local floodPos = (cf * CFrame.new(0, 0.6, -8)).Position
	local flood = detail(block(parent, "Monument floodlight", Vector3.new(1.2, 0.8, 1.2), CFrame.lookAt(floodPos, (cf * CFrame.new(0, 15, 0)).Position), rgb(255, 230, 190), Enum.Material.Neon))
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = 40
	spot.Range = 30
	spot.Brightness = 2
	spot.Color = rgb(255, 220, 180)
	spot.Parent = flood
end

local function boardOfHonour(parent, at, facing)
	local cf = CFrame.lookAt(at, at + facing)
	block(parent, "Board of honour", Vector3.new(18, 9, 0.6), cf * CFrame.new(0, 5.5, 0), rgb(130, 30, 28))
	for _, x in { -8.6, 8.6 } do
		block(parent, "Board post", Vector3.new(0.6, 10, 0.6), cf * CFrame.new(x, 5, 0), rgb(80, 80, 80), Enum.Material.Metal)
	end
	local head = detail(block(parent, "Board title", Vector3.new(17, 1.6, 0.1), cf * CFrame.new(0, 9, -0.36), rgb(130, 30, 28)))
	Build.sign(head, Enum.NormalId.Front, "ДОСКА ПОЧЁТА · ШАХТА № 6", { bg = rgb(130, 30, 28), fg = rgb(240, 214, 120) })
	local names = { "Кузьмин А.", "Остапенко В.", "Волков Г.", "Ибрагимов Р.", "Лебедев С.", "Петренко Н.", "Сидоров П.", "Ткач М.", "Белова Л.", "Орлов Д." }
	for i, n in names do
		local col, row = (i - 1) % 5, math.floor((i - 1) / 5)
		local photo = detail(block(parent, "Photo", Vector3.new(2.4, 3, 0.1), cf * CFrame.new(-6.4 + col * 3.2, 6.4 - row * 3.6, -0.36), rgb(150, 150, 140)))
		local missing = n == "Волков Г." or n == "Сидоров П."
		Build.sign(photo, Enum.NormalId.Front, missing and "✕\n" .. n or "☺\n" .. n, {
			bg = missing and rgb(30, 30, 30) or rgb(170, 166, 150),
			fg = missing and rgb(180, 30, 30) or rgb(60, 56, 50),
			font = Enum.Font.Arimo,
		})
	end
end

local function kiosk(parent, at, facing)
	local cf = CFrame.lookAt(at, at + facing)
	block(parent, "Soyuzpechat kiosk", Vector3.new(6, 6.5, 5), cf * CFrame.new(0, 3.25, 0), rgb(60, 100, 140), Enum.Material.SmoothPlastic)
	local glass = detail(block(parent, "Kiosk window", Vector3.new(5, 2.6, 0.2), cf * CFrame.new(0, 4, -2.55), rgb(40, 50, 56), Enum.Material.Glass))
	Build.sign(glass, Enum.NormalId.Front, "ПРАВДА   ИЗВЕСТИЯ   ТРУД   ЗАПОЛЯРНАЯ ПРАВДА", { bg = rgb(200, 196, 180), bgTransparency = 0.3, fg = rgb(30, 30, 30), font = Enum.Font.Merriweather })
	local sign = detail(block(parent, "Kiosk sign", Vector3.new(6, 1, 0.2), cf * CFrame.new(0, 6, -2.6), rgb(40, 60, 100)))
	Build.sign(sign, Enum.NormalId.Front, "СОЮЗПЕЧАТЬ", { bg = rgb(36, 56, 104), fg = rgb(240, 240, 230) })
	detail(block(parent, "Kiosk snow", Vector3.new(6.4, 0.5, 5.4), cf * CFrame.new(0, 6.75, 0), SNOW, Enum.Material.Snow))
	local shutter = detail(block(parent, "Closed sign", Vector3.new(2, 0.7, 0.1), cf * CFrame.new(0, 2.2, -2.56), rgb(220, 220, 210)))
	Build.sign(shutter, Enum.NormalId.Front, "ЗАКРЫТО", { bg = rgb(230, 226, 214), fg = rgb(170, 30, 30) })
end

local function phoneBooth(parent, at, facing)
	local cf = CFrame.lookAt(at, at + facing)
	local red = rgb(160, 50, 40)
	block(parent, "Phone booth back", Vector3.new(4, 8, 0.3), cf * CFrame.new(0, 4, 1.85), red, Enum.Material.Metal)
	for _, x in { -1.85, 1.85 } do
		local side = block(parent, "Phone booth glass", Vector3.new(0.3, 7, 3.6), cf * CFrame.new(x, 4, 0), rgb(150, 160, 160), Enum.Material.Glass)
		side.Transparency = 0.5
	end
	block(parent, "Phone booth roof", Vector3.new(4.4, 0.5, 4.2), cf * CFrame.new(0, 8.2, 0), red, Enum.Material.Metal)
	local sign = detail(block(parent, "Phone sign", Vector3.new(3.6, 0.7, 0.1), cf * CFrame.new(0, 7.5, -1.9), red))
	Build.sign(sign, Enum.NormalId.Front, "ТАКСОФОН · 2 коп.", { bg = red, fg = rgb(240, 236, 220) })
	detail(block(parent, "Payphone", Vector3.new(1.4, 2, 0.8), cf * CFrame.new(0, 4.6, 1.3), rgb(80, 80, 84), Enum.Material.Metal))
	detail(block(parent, "Receiver", Vector3.new(0.3, 1.4, 0.3), cf * CFrame.new(0.9, 3.4, 1.1), rgb(20, 20, 20)))
	local bulb = detail(Build.ball(parent, "Booth bulb", 0.5, cf * CFrame.new(0, 7.6, 0), rgb(220, 230, 255), Enum.Material.Neon))
	Build.light(bulb, rgb(210, 220, 255), 9, 0.5)
	Build.tag(bulb, "FlickerLamp")
end

local function busStop(parent, at, facing)
	local cf = CFrame.lookAt(at, at + facing)
	block(parent, "Bus shelter back", Vector3.new(10, 7, 0.6), cf * CFrame.new(0, 3.5, 2.4), rgb(150, 150, 146))
	block(parent, "Bus shelter roof", Vector3.new(11, 0.6, 5.6), cf * CFrame.new(0, 7.3, 0.4), rgb(140, 140, 136))
	detail(block(parent, "Shelter roof snow", Vector3.new(10.8, 0.5, 5.4), cf * CFrame.new(0, 7.85, 0.4), SNOW, Enum.Material.Snow))
	for _, x in { -5, 5 } do
		block(parent, "Bus shelter side", Vector3.new(0.6, 7, 5), cf * CFrame.new(x, 3.5, 0.2), rgb(150, 150, 146))
	end
	-- Mosaic of a heroic miner on the back wall.
	local mosaic = detail(block(parent, "Mosaic", Vector3.new(8.6, 4.6, 0.1), cf * CFrame.new(0, 4, 2.05), rgb(90, 120, 150)))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = mosaic
	local tiles = { rgb(70, 110, 150), rgb(90, 130, 160), rgb(200, 170, 70), rgb(170, 60, 40), rgb(230, 220, 190), rgb(60, 90, 120) }
	local r2 = Random.new(6)
	for x = 0, 15 do
		for y = 0, 8 do
			local f = Instance.new("Frame")
			f.Position = UDim2.fromScale(x / 16, y / 9)
			f.Size = UDim2.fromScale(1 / 16 - 0.004, 1 / 9 - 0.006)
			local c = tiles[r2:NextInteger(1, 2)]
			local dx, dy = x - 8, y - 4
			if dx * dx / 9 + dy * dy / 12 < 1 then
				c = tiles[r2:NextInteger(3, 5)]
			end
			f.BackgroundColor3 = c
			f.BorderSizePixel = 0
			f.Parent = gui
		end
	end
	block(parent, "Bus shelter bench", Vector3.new(7, 0.4, 1.4), cf * CFrame.new(0, 1.6, 1.4), rgb(90, 60, 40), Enum.Material.WoodPlanks)
	local sign = detail(block(parent, "Bus stop sign", Vector3.new(2.4, 2.4, 0.15), cf * CFrame.new(-6.5, 7, -1.5), rgb(230, 230, 220)))
	Build.sign(sign, Enum.NormalId.Front, "А\nАВТОБУС № 2\nГОРОД — РУДНИК", { bg = rgb(240, 236, 220), fg = rgb(30, 50, 110), font = Enum.Font.Arimo })
	detail(block(parent, "Bus stop pole", Vector3.new(0.25, 8, 0.25), cf * CFrame.new(-6.5, 4, -1.4), rgb(80, 80, 80), Enum.Material.Metal))
	Build.note(parent, 2, cf * CFrame.new(3.5, 4.2, 1.97) * CFrame.Angles(-math.pi / 2, 0, 0))
end

local function pazBus(parent, cf)
	local body = rgb(190, 160, 70)
	block(parent, "PAZ bus", Vector3.new(7, 6.5, 20), cf * CFrame.new(0, 4.2, 0), body, Enum.Material.SmoothPlastic)
	detail(block(parent, "Bus stripe", Vector3.new(7.1, 0.8, 20.1), cf * CFrame.new(0, 3.2, 0), rgb(150, 40, 30), Enum.Material.SmoothPlastic))
	for z = -7, 7, 3.5 do
		for _, x in { -3.55, 3.55 } do
			detail(block(parent, "Bus window", Vector3.new(0.1, 2, 3), cf * CFrame.new(x, 5.6, z), rgb(30, 36, 40), Enum.Material.Glass))
		end
	end
	detail(block(parent, "Bus windscreen", Vector3.new(6.4, 2.6, 0.1), cf * CFrame.new(0, 5.4, -10.05), rgb(30, 36, 40), Enum.Material.Glass))
	detail(block(parent, "Bus roof snow", Vector3.new(6.8, 0.6, 19.6), cf * CFrame.new(0, 7.75, 0), SNOW, Enum.Material.Snow))
	for _, z in { -6, 6 } do
		for _, x in { -3.4, 3.4 } do
			detail(Build.cylinder(parent, "Bus wheel", 1, 2.6, cf * CFrame.new(x, 1.3, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
	local route = detail(block(parent, "Route board", Vector3.new(4, 0.8, 0.1), cf * CFrame.new(0, 7, -10.07) * CFrame.Angles(0, math.pi, 0), rgb(240, 240, 230)))
	Build.sign(route, Enum.NormalId.Front, "2  РУДНИК", { bg = rgb(240, 236, 220), fg = rgb(20, 20, 20), font = Enum.Font.Arimo })
end

local function camp(parent, at)
	-- What is left of the Norillag camp the city was built on.
	local wood = rgb(66, 56, 46)
	local tower = at + Vector3.new(0, 0, 0)
	for _, x in { -3, 3 } do
		for _, z in { -3, 3 } do
			detail(Build.beam(parent, "Watchtower leg", tower + Vector3.new(x * 1.3, 0, z * 1.3), tower + Vector3.new(x, 20, z), 0.7, wood, Enum.Material.Wood)).CanCollide = true
		end
	end
	block(parent, "Watchtower floor", Vector3.new(8, 0.6, 8), tower + Vector3.new(0, 20, 0), wood, Enum.Material.WoodPlanks)
	block(parent, "Watchtower rail", Vector3.new(8, 2.4, 0.4), tower + Vector3.new(0, 21.5, -3.8), wood, Enum.Material.WoodPlanks)
	block(parent, "Watchtower rail", Vector3.new(0.4, 2.4, 8), tower + Vector3.new(3.8, 21.5, 0), wood, Enum.Material.WoodPlanks)
	wedge(parent, "Watchtower roof", Vector3.new(9, 3, 4.5), CFrame.new(tower + Vector3.new(0, 25.5, -2.25)), wood, Enum.Material.WoodPlanks)
	wedge(parent, "Watchtower roof", Vector3.new(9, 3, 4.5), CFrame.new(tower + Vector3.new(0, 25.5, 2.25)) * CFrame.Angles(0, math.pi, 0), wood, Enum.Material.WoodPlanks)
	detail(block(parent, "Watchtower roof snow", Vector3.new(9, 0.4, 9), tower + Vector3.new(0, 27.1, 0), SNOW, Enum.Material.Snow))
	local lamp = detail(Build.ball(parent, "Camp lamp", 0.6, tower + Vector3.new(0, 22.5, -3.6), rgb(255, 60, 40), Enum.Material.Neon))
	Build.light(lamp, rgb(255, 60, 40), 14, 0.8)
	Build.tag(lamp, "FlickerLamp")
	-- Fence posts and wire.
	local posts = {}
	for i = 0, 10 do
		local p = at + Vector3.new(10 + i * 6, 0, 12 + math.sin(i) * 1.5)
		local lean = CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), 0, math.rad(rng:NextNumber(-12, 12)))
		detail(block(parent, "Fence post", Vector3.new(0.5, 8, 0.5), CFrame.new(p + Vector3.new(0, 4, 0)) * lean, wood, Enum.Material.Wood)).CanCollide = true
		table.insert(posts, p)
	end
	for i = 1, #posts - 1 do
		if i ~= 5 then
			for _, y in { 2.5, 4.5, 6.5 } do
				detail(Build.beam(parent, "Barbed wire", posts[i] + Vector3.new(0, y, 0), posts[i + 1] + Vector3.new(0, y - 0.3, 0), 0.08, rgb(60, 56, 50), Enum.Material.CorrodedMetal))
			end
		end
	end
	-- A collapsed barrack.
	local b = CFrame.new(at + Vector3.new(30, 0, -16)) * CFrame.Angles(0, 0.2, 0)
	block(parent, "Barrack wall", Vector3.new(30, 6, 0.8), b * CFrame.new(0, 3, -6), wood, Enum.Material.WoodPlanks)
	block(parent, "Barrack wall", Vector3.new(0.8, 6, 12), b * CFrame.new(-15, 3, 0), wood, Enum.Material.WoodPlanks)
	block(parent, "Barrack wall", Vector3.new(14, 4, 0.8), b * CFrame.new(-8, 2, 6) * CFrame.Angles(0.3, 0, 0), wood, Enum.Material.WoodPlanks)
	block(parent, "Collapsed roof", Vector3.new(30, 0.6, 13), b * CFrame.new(0, 3, 0) * CFrame.Angles(0.35, 0, 0.08), wood, Enum.Material.WoodPlanks)
	detail(block(parent, "Roof snow", Vector3.new(29, 0.5, 12), b * CFrame.new(0, 3.5, 0) * CFrame.Angles(0.35, 0, 0.08), SNOW, Enum.Material.Snow))
	-- The plaque and the note.
	local stone = block(parent, "Memorial stone", Vector3.new(3, 3.2, 1.4), CFrame.new(at + Vector3.new(6, 1.6, -6)) * CFrame.Angles(0, 0.4, 0.05), rgb(80, 80, 84), Enum.Material.Granite)
	Build.sign(stone, Enum.NormalId.Front, "НОРИЛЬЛАГ\n1935–1956", { bg = rgb(70, 70, 74), fg = rgb(200, 200, 190), font = Enum.Font.Merriweather })
	Build.note(parent, 6, CFrame.new(at + Vector3.new(6, 3.25, -6)) * CFrame.Angles(0, 0.4, 0.05))
	Build.note(parent, 8, CFrame.new(at + Vector3.new(16, 0.1, -12)) * CFrame.Angles(0, -0.6, 0))
	Build.graffiti(parent, b * CFrame.new(4, 3.2, -5.55) * CFrame.Angles(0, math.pi, 0), "Л-128 НЕ БЕЖАЛ", { color = rgb(60, 40, 30), size = Vector2.new(6, 1.6), rotation = -2 })
	-- Graves: rows of numbered stakes.
	for i = 0, 11 do
		local p = at + Vector3.new(-20 + (i % 4) * 4, 0, -10 - math.floor(i / 4) * 5)
		local stake = detail(block(parent, "Grave stake", Vector3.new(0.4, 2.6, 0.2), CFrame.new(p + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-10, 10))), wood, Enum.Material.Wood))
		local plate = detail(block(parent, "Number plate", Vector3.new(0.8, 0.5, 0.05), CFrame.new(p + Vector3.new(0, 2.2, -0.13)), rgb(110, 100, 80), Enum.Material.Metal))
		Build.sign(plate, Enum.NormalId.Front, ("Л-%d"):format(100 + i * 7), { bg = rgb(110, 100, 80), fg = rgb(30, 30, 30), font = Enum.Font.Code })
		stake.CanCollide = true
	end
end

local function staged(model, from, to)
	model:SetAttribute("ShowFrom", from)
	model:SetAttribute("ShowTo", to)
	Build.tag(model, "StagedPerson")
	return model
end

-- Soda water machine: 1 kopeck plain, 3 with syrup, one shared glass.
local function sodaMachine(parent, cf)
	block(parent, "Soda machine", Vector3.new(2.6, 5.6, 2), cf * CFrame.new(0, 2.8, 0), rgb(200, 40, 34), Enum.Material.SmoothPlastic)
	local top = detail(block(parent, "Soda sign", Vector3.new(2.5, 1.2, 0.1), cf * CFrame.new(0, 4.9, -1.02), rgb(236, 232, 220)))
	Build.sign(top, Enum.NormalId.Front, "ГАЗИРОВАННАЯ\nВОДА", { bg = rgb(236, 232, 220), fg = rgb(180, 30, 26), lightInfluence = 0.4 })
	local prices = detail(block(parent, "Soda prices", Vector3.new(1.4, 0.8, 0.1), cf * CFrame.new(-0.4, 3.6, -1.02), rgb(236, 232, 220)))
	Build.sign(prices, Enum.NormalId.Front, "1 коп. — без сиропа\n3 коп. — с сиропом", { bg = rgb(236, 232, 220), fg = rgb(20, 20, 20), font = Enum.Font.Arimo })
	detail(block(parent, "Soda niche", Vector3.new(1, 1.2, 0.3), cf * CFrame.new(0.5, 2.4, -0.9), rgb(30, 30, 30), Enum.Material.Metal))
	local glass = detail(Build.column(parent, "Shared glass", 0.6, 0.45, (cf * CFrame.new(0.5, 1.85, -0.9)).Position, rgb(200, 210, 210), Enum.Material.Glass))
	glass.Transparency = 0.3
	local glow = detail(block(parent, "Soda light", Vector3.new(2.3, 0.3, 0.1), cf * CFrame.new(0, 5.65, -1.02), rgb(255, 236, 200), Enum.Material.Neon))
	Build.light(glow, rgb(255, 230, 200), 8, 0.4)
	detail(block(parent, "Soda snow", Vector3.new(2.6, 0.4, 2), cf * CFrame.new(0, 5.8, 0), SNOW, Enum.Material.Snow))
end

local function kvassBarrel(parent, cf)
	detail(Build.cylinder(parent, "Kvass barrel", 6, 3.6, cf * CFrame.new(0, 3, 0), rgb(220, 180, 40), Enum.Material.SmoothPlastic)).CanCollide = true
	local label = detail(block(parent, "Kvass label", Vector3.new(3, 1.2, 0.1), cf * CFrame.new(0, 3, -1.82), rgb(220, 180, 40)))
	Build.sign(label, Enum.NormalId.Front, "КВАС", { bg = rgb(220, 180, 40), fg = rgb(160, 30, 26) })
	for _, x in { -2, 2 } do
		detail(Build.cylinder(parent, "Barrel wheel", 0.5, 1.8, cf * CFrame.new(x, 0.9, 0) * CFrame.Angles(0, math.pi / 2, 0), rgb(24, 24, 24), Enum.Material.Rubber))
	end
	detail(block(parent, "Barrel snow", Vector3.new(5.6, 0.7, 2.4), cf * CFrame.new(0, 4.9, 0), SNOW, Enum.Material.Snow))
	detail(block(parent, "Closed for winter", Vector3.new(1.4, 0.6, 0.05), cf * CFrame.new(1.8, 2.2, -1.85), rgb(240, 240, 230)))
end

-- An advertising pillar with the cinema and the House of Culture.
local function afisha(parent, at)
	detail(Build.column(parent, "Advertising pillar", 7, 3.6, at, rgb(200, 196, 186))).CanCollide = true
	detail(Build.column(parent, "Pillar cap", 0.6, 4.2, at + Vector3.new(0, 7, 0), rgb(60, 64, 60), Enum.Material.Metal))
	detail(Build.column(parent, "Pillar snow", 0.4, 4, at + Vector3.new(0, 7.6, 0), SNOW, Enum.Material.Snow))
	local bills = {
		{ "КИНОТЕАТР «ПОЛЯРНЫЙ»\n«МОСКВА СЛЕЗАМ НЕ ВЕРИТ»\nнач. 18:00 и 20:30", rgb(236, 226, 180), rgb(40, 30, 90) },
		{ "«ПИРАТЫ XX ВЕКА»\nДети до 16 лет не допускаются", rgb(40, 110, 160), rgb(250, 240, 220) },
		{ "ДК ГОРНЯКОВ\nТАНЦЫ · суббота 19:00\nВИА «Заполярье»", rgb(200, 60, 60), rgb(250, 240, 220) },
		{ "НОВОГОДНИЙ ВЕЧЕР\n31 декабря\nДля детей горняков — ёлка в ДК", rgb(40, 120, 70), rgb(250, 230, 120) },
	}
	for i, b in bills do
		local a = (i - 1) * math.pi / 2
		local p = at + Vector3.new(math.cos(a) * 1.82, 3.6, math.sin(a) * 1.82)
		local bill = detail(block(parent, "Bill", Vector3.new(2.2, 3, 0.05), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))), b[2]))
		Build.sign(bill, Enum.NormalId.Front, b[1], { bg = b[2], fg = b[3], font = Enum.Font.Oswald, padding = 0.05 })
	end
end

-- A Soviet New Year tree with a red star, December 1984.
local function newYearTree(parent, at)
	detail(Build.column(parent, "Tree trunk", 3, 1, at, rgb(70, 50, 34), Enum.Material.Wood)).CanCollide = true
	local tiers = { { 9, 3 }, { 7.4, 6.5 }, { 5.8, 10 }, { 4, 13.2 }, { 2.4, 16 } }
	local r = Random.new(85)
	for i, t in tiers do
		for k = 0, 1 do
			detail(block(parent, "Tree tier", Vector3.new(t[1], 3.4, t[1]), CFrame.new(at + Vector3.new(0, t[2] + 1, 0)) * CFrame.Angles(0, k * math.pi / 4 + i * 0.3, 0), rgb(30, 70, 44), Enum.Material.Grass))
		end
		for _ = 1, 6 - i do
			local a = r:NextNumber(0, math.pi * 2)
			local p = at + Vector3.new(math.cos(a) * t[1] * 0.55, t[2] + r:NextNumber(0, 2), math.sin(a) * t[1] * 0.55)
			local colors = { rgb(255, 60, 50), rgb(255, 210, 60), rgb(80, 140, 255), rgb(80, 255, 120) }
			local bulb = detail(Build.ball(parent, "Garland bulb", 0.45, p, colors[r:NextInteger(1, #colors)], Enum.Material.Neon))
			Build.tag(bulb, "Garland")
		end
		detail(block(parent, "Tree snow", Vector3.new(t[1] * 0.8, 0.3, t[1] * 0.8), CFrame.new(at + Vector3.new(0, t[2] + 2.8, 0)) * CFrame.Angles(0, 0.4, 0), SNOW, Enum.Material.Snow))
	end
	local star = detail(block(parent, "Tree star", Vector3.new(2.4, 2.4, 0.2), at + Vector3.new(0, 19.4, 0), rgb(0, 0, 0)))
	star.Transparency = 1
	for _, f in { Enum.NormalId.Front, Enum.NormalId.Back } do
		Build.sign(star, f, "★", { bgTransparency = 1, fg = rgb(255, 40, 30), lightInfluence = 0, brightness = 2, font = Enum.Font.GothamBlack })
	end
	local glow = detail(Build.ball(parent, "Star glow", 0.4, at + Vector3.new(0, 19.4, 0), rgb(255, 40, 30), Enum.Material.Neon))
	Build.light(glow, rgb(255, 70, 50), 18, 0.8)
end

local function smallCar(parent, cf, color, name, length)
	length = length or 8
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	block(m, "Body", Vector3.new(4.2, 1.6, length), cf * CFrame.new(0, 1.5, 0), color, Enum.Material.SmoothPlastic)
	block(m, "Cabin", Vector3.new(3.8, 1.4, length * 0.5), cf * CFrame.new(0, 2.95, 0.4), color, Enum.Material.SmoothPlastic)
	detail(block(m, "Windscreen", Vector3.new(3.4, 1.1, 0.1), cf * CFrame.new(0, 2.95, 0.4 - length * 0.25 - 0.02), rgb(30, 36, 40), Enum.Material.Glass))
	detail(block(m, "Roof snow", Vector3.new(3.7, 0.5, length * 0.5), cf * CFrame.new(0, 3.9, 0.4), SNOW, Enum.Material.Snow))
	for _, x in { -2, 2 } do
		for _, z in { -length * 0.32, length * 0.32 } do
			detail(Build.cylinder(m, "Wheel", 0.7, 1.8, cf * CFrame.new(x, 0.9, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
	wedge(m, "Snow heap", Vector3.new(5, 1.4, 3), cf * CFrame.new(0, 0.7, length / 2 + 1.5) * CFrame.Angles(0, math.pi, 0), SNOW, Enum.Material.Snow)
	return m
end

-- Army GAZ-66, cab-over truck with a canvas-covered bed. Engine left running, lights on.
local function gaz66(parent, cf)
	local green = rgb(66, 78, 54)
	local m = Instance.new("Model")
	m.Name = "GAZ-66"
	m.Parent = parent
	block(m, "Cab", Vector3.new(6, 5, 4.5), cf * CFrame.new(0, 4.6, -6), green, Enum.Material.SmoothPlastic)
	detail(block(m, "Cab window", Vector3.new(5, 1.8, 0.1), cf * CFrame.new(0, 5.6, -8.27), rgb(30, 36, 40), Enum.Material.Glass))
	block(m, "Bed", Vector3.new(6.4, 1, 10), cf * CFrame.new(0, 2.8, 2), rgb(50, 54, 44), Enum.Material.Metal)
	block(m, "Bumper", Vector3.new(6.6, 0.5, 0.8), cf * CFrame.new(0, 2.2, -8.6), rgb(40, 44, 36), Enum.Material.Metal)
	block(m, "Canvas", Vector3.new(6.4, 4.5, 10), cf * CFrame.new(0, 5.6, 2), rgb(84, 90, 66), Enum.Material.Fabric)
	detail(block(m, "Canvas snow", Vector3.new(6.2, 0.5, 9.8), cf * CFrame.new(0, 8.1, 2), SNOW, Enum.Material.Snow))
	detail(block(m, "Cab snow", Vector3.new(5.8, 0.4, 4.3), cf * CFrame.new(0, 7.3, -6), SNOW, Enum.Material.Snow))
	for _, z in { -6, 4 } do
		for _, x in { -3, 3 } do
			detail(Build.cylinder(m, "Wheel", 1.2, 3.4, cf * CFrame.new(x, 1.7, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
	for _, x in { -2.2, 2.2 } do
		local lamp = detail(Build.ball(m, "Headlight", 0.7, cf * CFrame.new(x, 3.2, -8.3), rgb(255, 236, 190), Enum.Material.Neon))
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Range = 40
		spot.Angle = 45
		spot.Brightness = 1.2
		spot.Color = rgb(255, 230, 180)
		spot.Parent = lamp
		lamp.CFrame = CFrame.lookAt(lamp.CFrame.Position, lamp.CFrame.Position + cf.LookVector)
	end
	local plate = detail(block(m, "Army plate", Vector3.new(2.2, 0.6, 0.05), cf * CFrame.new(0, 2.4, -8.3) * CFrame.Angles(0, math.pi, 0), rgb(20, 20, 20)))
	Build.sign(plate, Enum.NormalId.Back, "45-17 ЛЕ", { bg = rgb(20, 20, 20), fg = rgb(236, 236, 230), font = Enum.Font.Arimo })
	local star = detail(block(m, "Door star", Vector3.new(0.05, 1.4, 1.4), cf * CFrame.new(3.03, 4.6, -6), green))
	Build.sign(star, Enum.NormalId.Right, "★", { bgTransparency = 1, fg = rgb(170, 30, 26), font = Enum.Font.GothamBlack })
	-- Driver's door hanging open.
	detail(block(m, "Open door", Vector3.new(0.2, 3, 2.6), cf * CFrame.new(4.1, 4.4, -6.8) * CFrame.Angles(0, 0.9, 0), green, Enum.Material.SmoothPlastic))
	return m
end

-- Militia UAZ: yellow with the blue stripe.
local function militiaCar(parent, cf)
	local yellow = rgb(214, 180, 70)
	block(parent, "Militia UAZ", Vector3.new(5, 2.4, 10), cf * CFrame.new(0, 2.2, 0), yellow, Enum.Material.SmoothPlastic)
	block(parent, "Militia UAZ cabin", Vector3.new(4.8, 2.6, 6.5), cf * CFrame.new(0, 4.6, 1), yellow, Enum.Material.SmoothPlastic)
	for _, x in { -2.52, 2.52 } do
		local stripe = detail(block(parent, "Blue stripe", Vector3.new(0.05, 0.8, 9.6), cf * CFrame.new(x, 2.4, 0), rgb(40, 70, 150)))
		Build.sign(stripe, x < 0 and Enum.NormalId.Left or Enum.NormalId.Right, "МИЛИЦИЯ", { bg = rgb(40, 70, 150), fg = rgb(240, 240, 230) })
	end
	local beacon = detail(Build.ball(parent, "Blue beacon", 0.8, cf * CFrame.new(0, 6.2, 1.5), rgb(60, 110, 255), Enum.Material.Neon))
	Build.light(beacon, rgb(60, 110, 255), 18, 0.8)
	Build.tag(beacon, "Beacon")
	detail(block(parent, "Militia snow", Vector3.new(4.6, 0.5, 6.3), cf * CFrame.new(0, 6.05, 1), SNOW, Enum.Material.Snow))
	for _, x in { -2.5, 2.5 } do
		for _, z in { -3.4, 3.4 } do
			detail(Build.cylinder(parent, "Wheel", 1, 2.6, cf * CFrame.new(x, 1.3, z), rgb(24, 24, 24), Enum.Material.Rubber))
		end
	end
end

local function urn(parent, at)
	detail(Build.column(parent, "Concrete urn", 2.2, 1.6, at, rgb(150, 150, 144))).CanCollide = true
	detail(Build.column(parent, "Urn snow", 0.3, 1.5, at + Vector3.new(0, 2.2, 0), SNOW, Enum.Material.Snow))
end

local function milkCrate(parent, cf)
	detail(block(parent, "Milk crate", Vector3.new(2.4, 1.2, 1.6), cf * CFrame.new(0, 0.6, 0), rgb(90, 96, 100), Enum.Material.DiamondPlate))
	for x = -0.8, 0.8, 0.8 do
		for z = -0.4, 0.4, 0.8 do
			detail(Build.column(parent, "Milk bottle", 1.3, 0.55, (cf * CFrame.new(x, 0.6, z)).Position, rgb(236, 236, 230), Enum.Material.Glass))
			detail(Build.column(parent, "Foil cap", 0.12, 0.4, (cf * CFrame.new(x, 1.9, z)).Position, rgb(200, 200, 205), Enum.Material.Foil))
		end
	end
end

local function eraDressing(folder)
	-- Gastronom frontage: soda machines and milk crates.
	sodaMachine(folder, CFrame.lookAt(Vector3.new(57.6, 0.4, 6), Vector3.new(50, 0.4, 6)))
	sodaMachine(folder, CFrame.lookAt(Vector3.new(57.6, 0.4, 2.6), Vector3.new(50, 0.4, 2.6)))
	milkCrate(folder, CFrame.new(57.4, 0.4, 24))
	milkCrate(folder, CFrame.new(57.6, 1.6, 24.3) * CFrame.Angles(0, 0.2, 0))
	kvassBarrel(folder, CFrame.lookAt(Vector3.new(30, 0.3, -68), Vector3.new(30, 0.3, -60)))
	afisha(folder, Vector3.new(32, 0.3, -34))
	newYearTree(folder, Vector3.new(42, 0.3, -46))
	for _, p in { Vector3.new(20.5, 0.4, -157), Vector3.new(-20.5, 0.4, -73), Vector3.new(-96, 0, 38), Vector3.new(-96, 0, 8), Vector3.new(66, 0.4, -112) } do
		urn(folder, p)
	end
	-- New Year banner across the avenue.
	local banner = detail(block(folder, "New Year banner", Vector3.new(32, 2.6, 0.2), Vector3.new(0, 12.5, -20), rgb(160, 26, 24), Enum.Material.Fabric))
	Build.sign(banner, Enum.NormalId.Back, "С НОВЫМ 1985 ГОДОМ, ТОВАРИЩИ!", { bg = rgb(160, 26, 24), fg = rgb(250, 220, 120) })
	Build.sign(banner, Enum.NormalId.Front, "НОРИЛЬСК — ГОРОД ГОРНЯКОВ И МЕТАЛЛУРГОВ", { bg = rgb(160, 26, 24), fg = rgb(250, 220, 120) })
	-- More cars of the period.
	smallCar(folder, CFrame.new(-140, 0, -6) * CFrame.Angles(0, -0.4, 0), rgb(90, 130, 90), "Zaporozhets", 7.5)
	smallCar(folder, CFrame.new(10.5, 0, -95) * CFrame.Angles(0, math.pi, 0), rgb(200, 110, 40), "Moskvich 412", 9)

	-- Army truck by the mine fence: soldiers in the morning, an empty running truck at night.
	gaz66(folder, CFrame.lookAt(Vector3.new(-70, 0, -192), Vector3.new(-60, 0, -192)))
	Build.note(folder, 7, CFrame.new(-61.4, 2.5, -192.8) * CFrame.Angles(0, 0.3, 0))
	staged(Figure.build(folder, CFrame.lookAt(Vector3.new(-60, 0, -185), Vector3.new(-66, 0, -183)), { hat = "army", held = "rifle", armR = 0, armL = 5, action = "idle", name = "Soldier", seed = 31 }), 2, 4)
	staged(Figure.build(folder, CFrame.lookAt(Vector3.new(-66, 0, -183.5), Vector3.new(-60, 0, -185)), { hat = "army", held = "cigarette", armR = 20, action = "smoke", name = "Soldier", seed = 32 }), 2, 4)

	-- Militia car on the plaza.
	militiaCar(folder, CFrame.lookAt(Vector3.new(38, 0.3, -30), Vector3.new(30, 0.3, -30)) * CFrame.Angles(0, math.pi / 2, 0))
	Build.note(folder, 9, CFrame.new(38.5, 6.4, -30.5) * CFrame.Angles(0, 0.5, 0))
	staged(Figure.build(folder, CFrame.lookAt(Vector3.new(31.5, 0.3, -27), Vector3.new(20, 0.3, -27)), { hat = "militia", held = "papers", armR = 60, armL = 10, action = "read", name = "Militiaman", seed = 33 }), 2, 4)

	-- The conscript's letter, left in the payphone booth.
	detail(block(folder, "Phone shelf", Vector3.new(0.8, 0.15, 1.6), Vector3.new(-22.4, 3.35, -120), rgb(80, 80, 84), Enum.Material.Metal))
	Build.note(folder, 10, CFrame.new(-22.4, 3.45, -120) * CFrame.Angles(0, 0.3, 0))

	-- Graffiti: football, rock bands, love, and lately other things.
	local g = Build.graffiti
	local white, red, black = rgb(232, 232, 226), rgb(190, 40, 34), rgb(24, 24, 24)
	g(folder, CFrame.lookAt(Vector3.new(-142, 3.8, 81.2), Vector3.new(-142, 3.8, 90)), "СПАРТАК — ЧЕМПИОН!", { color = red, size = Vector2.new(6, 2), rotation = -4 })
	g(folder, CFrame.lookAt(Vector3.new(-125, 3, 81.2), Vector3.new(-125, 3, 90)), "КИНО", { color = black, size = Vector2.new(4, 2), rotation = 3 })
	g(folder, CFrame.lookAt(Vector3.new(-116.5, 4, 81.2), Vector3.new(-116.5, 4, 90)), "здесь был Вася", { color = white, size = Vector2.new(5, 1.6), rotation = -2, font = Enum.Font.IndieFlower })
	g(folder, CFrame.lookAt(Vector3.new(-103.8, 4, 74), Vector3.new(-90, 4, 74)), "Петя + Лена = ♥", { color = rgb(220, 90, 130), size = Vector2.new(5, 2), rotation = 5, font = Enum.Font.IndieFlower })
	g(folder, CFrame.lookAt(Vector3.new(-133.5, 3.2, 81.2), Vector3.new(-133.5, 3.2, 90)), "ОН ЗА ТОБОЙ", { color = rgb(140, 20, 20), size = Vector2.new(6, 2.2), rotation = -8, night = true })
	g(folder, CFrame.lookAt(Vector3.new(-90.2, 4.2, 10), Vector3.new(-100, 4.2, 10)), "AC/DC", { color = black, size = Vector2.new(4, 1.4), rotation = -3 })
	g(folder, CFrame.lookAt(Vector3.new(-90.2, 4.2, 51), Vector3.new(-100, 4.2, 51)), "НЕ ОГЛЯДЫВАЙСЯ", { color = rgb(150, 20, 20), size = Vector2.new(6, 1.4), rotation = 2, night = true })
	g(folder, CFrame.lookAt(Vector3.new(24, 3.6, -170.4), Vector3.new(24, 3.6, -180)), "Где Гена?", { color = white, size = Vector2.new(4, 1.6), rotation = -6, font = Enum.Font.IndieFlower })
	g(folder, CFrame.lookAt(Vector3.new(24, 3.6, -159.6), Vector3.new(24, 3.6, -150)), "АКВАРИУМ", { color = rgb(60, 90, 160), size = Vector2.new(4.5, 1.6), rotation = 4 })
	g(folder, CFrame.lookAt(Vector3.new(-22.5, 3.4, -74.9), Vector3.new(-22.5, 3.4, -60)), "Машина Времени", { color = black, size = Vector2.new(4.5, 1.5), rotation = -3 })
	g(folder, CFrame.lookAt(Vector3.new(-137, 4.5, 36.8), Vector3.new(-137, 4.5, 50)), "Ю. ГАГАРИН", { color = white, size = Vector2.new(2.6, 1), rotation = 0 })
	g(folder, CFrame.lookAt(Vector3.new(-59.8, 4.2, -70), Vector3.new(-50, 4.2, -70)), "ЦСКА", { color = red, size = Vector2.new(3, 1.3), rotation = 6 })
	g(folder, CFrame.lookAt(Vector3.new(-59.8, 4.2, -125), Vector3.new(-50, 4.2, -125)), "ИДИ", { color = rgb(150, 20, 20), size = Vector2.new(3, 1.3), rotation = -5, night = true })
	g(folder, CFrame.lookAt(Vector3.new(59.8, 4.2, 62), Vector3.new(50, 4.2, 62)), "Металл — это сила!", { color = black, size = Vector2.new(5, 1.3), rotation = -2 })
	g(folder, CFrame.lookAt(Vector3.new(-149.8, 4.2, -10), Vector3.new(-140, 4.2, -10)), "Таня, я тебя жду", { color = white, size = Vector2.new(5, 1.2), rotation = 3, font = Enum.Font.IndieFlower })

	-- More posters: on the courtyard walls, the avenue and the far blocks.
	for _, p in {
		{ Vector3.new(-90.2, 6, -10), -Vector3.xAxis, 8 },
		{ Vector3.new(-149.8, 6, 55), Vector3.xAxis, 11 },
		{ Vector3.new(59.8, 6, -12), -Vector3.xAxis, 9 },
		{ Vector3.new(-59.8, 6, -158), Vector3.xAxis, 13 },
		{ Vector3.new(59.8, 6, 80), -Vector3.xAxis, 10 },
		{ Vector3.new(-90.2, 6, 72), -Vector3.xAxis, 12 },
	} do
		Build.poster(folder, face(p[1], p[2]), Config.Posters[p[3]])
	end
end

function Town.build(world)
	local spots = {}
	local folder = Instance.new("Folder")
	folder.Name = "Town"
	folder.Parent = world

	-- Ground, avenue, sidewalks.
	block(folder, "Snow", Vector3.new(1000, 2, 1000), Vector3.new(0, -1, -100), SNOW, Enum.Material.Snow)
	block(folder, "Road", Vector3.new(28, 0.2, 330), Vector3.new(0, 0.1, -55), rgb(150, 154, 160), Enum.Material.Snow)
	for _, x in { -9, -4, 4, 9 } do
		detail(block(folder, "Rut", Vector3.new(1.3, 0.05, 330), Vector3.new(x, 0.22, -55), rgb(96, 98, 102), Enum.Material.Asphalt))
	end
	for _, x in { -18, 18 } do
		block(folder, "Sidewalk", Vector3.new(8, 0.4, 330), Vector3.new(x, 0.2, -55), rgb(196, 202, 208), Enum.Material.Snow)
		for z = 105, -205, -12 do
			detail(wedge(folder, "Plowed snow", Vector3.new(1.6, 1.4, 10), CFrame.new(x + (x < 0 and 4.6 or -4.6), 0.7, z) * CFrame.Angles(0, x < 0 and math.pi / 2 or -math.pi / 2, 0) * CFrame.Angles(0, 0, 0), SNOW, Enum.Material.Snow))
		end
	end
	-- Courtyard and side paths (trodden snow).
	block(folder, "Path", Vector3.new(90, 0.2, 14), Vector3.new(-60, 0.1, -40), rgb(190, 196, 202), Enum.Material.Snow)
	block(folder, "Path", Vector3.new(12, 0.2, 130), Vector3.new(-100, 0.1, 15), rgb(190, 196, 202), Enum.Material.Snow)

	-- Panel housing.
	local _, w1doors = apartmentBlock(folder, "Building 14", CFrame.lookAt(Vector3.new(-75, 0, 30), Vector3.new(-74, 0, 30)), 110, {
		entrances = { -30, 0, 30 },
		address = "ЛЕНИНСКИЙ ПР., 14",
		gablePoster = 1,
		gableSide = -1,
		color = CONCRETE[1],
	})
	apartmentBlock(folder, "Building 16", CFrame.lookAt(Vector3.new(-75, 0, -110), Vector3.new(-74, 0, -110)), 110, {
		entrances = { -30, 0, 30 },
		address = "ЛЕНИНСКИЙ ПР., 16",
		gablePoster = 3,
		gableSide = -1,
		color = CONCRETE[2],
	})
	apartmentBlock(folder, "Building 15", CFrame.lookAt(Vector3.new(75, 0, 30), Vector3.new(74, 0, 30)), 110, {
		entrances = { -30, 0, 30 },
		address = "ЛЕНИНСКИЙ ПР., 15",
		shop = "ГАСТРОНОМ",
		shopWindow = "КОНСЕРВЫ · ХЛЕБ · МОЛОКО\n(полки пусты)",
		shopFrom = -20,
		shopTo = 20,
		gablePoster = 2,
		gableSide = 1,
		color = CONCRETE[3],
	})
	apartmentBlock(folder, "Building 12", CFrame.lookAt(Vector3.new(-165, 0, 30), Vector3.new(-166, 0, 30)), 110, {
		entrances = { -30, 0, 30 },
		address = "УЛ. ГОРНЯКОВ, 12",
		gablePoster = 10,
		gableSide = 1,
		color = CONCRETE[4],
	})
	apartmentBlock(folder, "Building 9", CFrame.lookAt(Vector3.new(0, 0, 150), Vector3.new(0, 0, 149)), 140, {
		entrances = { -40, 0, 40 },
		address = "ЛЕНИНСКИЙ ПР., 9",
		gablePoster = 7,
		gableSide = 1,
		color = CONCRETE[5],
	})
	apartmentBlock(folder, "Building 21", CFrame.lookAt(Vector3.new(165, 0, -40), Vector3.new(164, 0, -40)), 120, {
		entrances = { -35, 0, 35 },
		address = "УЛ. ЗАВЕНЯГИНА, 21",
		gablePoster = 12,
		gableSide = 1,
		lit = 0.15,
		color = CONCRETE[2],
	})
	apartmentBlock(folder, "Building 18", CFrame.lookAt(Vector3.new(-165, 0, -110), Vector3.new(-166, 0, -110)), 110, {
		entrances = { -30, 0, 30 },
		address = "ЛЕНИНСКИЙ ПР., 18",
		gablePoster = 9,
		gableSide = -1,
		lit = 0.12,
		color = CONCRETE[1],
	})
	-- Make the home entrance obvious: a hand-painted number on the door.
	local homeDoor = w1doors[2]
	Build.sign(homeDoor, Enum.NormalId.Back, "2", { bg = rgb(70, 52, 38), bgTransparency = 1, fg = rgb(220, 210, 180) })
	spots.homeDoorOut = CFrame.lookAt(Config.Places.HomeDoor + Vector3.new(-7, 3, 0), Config.Places.HomeDoor + Vector3.new(-20, 3, -25))
	Build.interact(homeDoor, "unlock", "Unlock the door", "Building 14, entrance 2", 3)

	-- Posters along the street.
	local posterSpots = {
		{ Vector3.new(-59.8, 6, 10), Vector3.xAxis, 1 },
		{ Vector3.new(-59.8, 6, 55), Vector3.xAxis, 4 },
		{ Vector3.new(59.8, 6, 70), -Vector3.xAxis, 6 },
		{ Vector3.new(-59.8, 6, -90), Vector3.xAxis, 7 },
		{ Vector3.new(-59.8, 6, -140), Vector3.xAxis, 5 },
		{ Vector3.new(-90.2, 6, 45), -Vector3.xAxis, 4 },
		{ Vector3.new(-149.8, 6, 15), Vector3.xAxis, 3 },
	}
	for _, p in posterSpots do
		Build.poster(folder, face(p[1], p[2]), Config.Posters[p[3]])
	end

	-- Street lights. Some are dead.
	local i = 0
	for z = 100, -190, -30 do
		for _, x in { -16, 16 } do
			i += 1
			streetlight(folder, Vector3.new(x, 0, z), Vector3.new(x < 0 and 1 or -1, 0, 0), i % 5 ~= 3)
		end
	end
	streetlight(folder, Vector3.new(-120, 0, 0), Vector3.new(1, 0, 0), true)
	streetlight(folder, Vector3.new(-120, 0, 62), Vector3.new(1, 0, 0), false)
	streetlight(folder, Vector3.new(-60, 0, -48), Vector3.new(0, 0, 1), true)

	-- Courtyard.
	playground(folder, Vector3.new(-125, 0, 25))
	garages(folder, Vector3.new(-142, 0, 74), 5)
	lada(folder, CFrame.new(-110, 0, -8) * CFrame.Angles(0, 0.3, 0), rgb(150, 60, 50))
	lada(folder, CFrame.new(-10.5, 0, 45), rgb(220, 214, 190))
	lada(folder, CFrame.new(10.5, 0, -30) * CFrame.Angles(0, math.pi, 0), rgb(70, 110, 90))
	-- Washing line nobody took in.
	detail(Build.beam(folder, "Washing line", Vector3.new(-140, 7, 50), Vector3.new(-110, 7, 50), 0.06, rgb(200, 200, 200)))
	for k = 0, 3 do
		detail(block(folder, "Frozen shirt", Vector3.new(1.8, 2.4, 0.1), Vector3.new(-134 + k * 6, 5.7, 50), ({ rgb(200, 200, 190), rgb(90, 110, 140), rgb(160, 60, 60), rgb(200, 200, 190) })[k + 1], Enum.Material.Fabric))
	end
	for _, x in { -140, -110 } do
		block(folder, "Line post", Vector3.new(0.4, 7.5, 0.4), Vector3.new(x, 3.75, 50), rgb(90, 90, 90), Enum.Material.Metal)
	end

	-- Heating mains, with the iconic arch over the avenue.
	heatingPipes(folder, {
		Vector3.new(-28, 2.6, 100),
		Vector3.new(-28, 2.6, -22),
		Vector3.new(-28, 10, -22),
		Vector3.new(-28, 10, -58),
		Vector3.new(-28, 2.6, -58),
		Vector3.new(-28, 2.6, -140),
		Vector3.new(-28, 15, -140),
		Vector3.new(30, 15, -140),
		Vector3.new(30, 2.6, -140),
		Vector3.new(30, 2.6, -196),
	})
	steamLeak(folder, Vector3.new(-28, 3.4, 64))
	steamLeak(folder, Vector3.new(10, 15.6, -140))

	-- Plaza, monument, kiosk, booth, bus stop, board of honour.
	block(folder, "Plaza", Vector3.new(50, 0.3, 46), Vector3.new(48, 0.15, -50), rgb(176, 180, 186), Enum.Material.Snow)
	lenin(folder, Vector3.new(58, 0.3, -50))
	kiosk(folder, Vector3.new(-22.5, 0.4, -78), Vector3.xAxis)
	phoneBooth(folder, Vector3.new(-21.5, 0.4, -120), Vector3.xAxis)
	busStop(folder, Vector3.new(24, 0.4, -165), -Vector3.xAxis)
	pazBus(folder, CFrame.new(9, 0, -168))
	boardOfHonour(folder, Vector3.new(26, 0, -5), -Vector3.xAxis)

	-- Things people left in the snow.
	local r = Random.new(41)
	for _ = 1, 40 do
		local p = Vector3.new(r:NextNumber(-140, 140), 0, r:NextNumber(-190, 110))
		if math.abs(p.X) > 30 and (math.abs(p.X) < 55 or math.abs(p.X) > 95) then
			detail(Build.ball(folder, "Snow mound", r:NextNumber(3, 7), p - Vector3.new(0, 1.2, 0), SNOW, Enum.Material.Snow))
		end
	end

	eraDressing(folder)
	apartmentInterior(folder, Config.Places.Apartment, spots)
	camp(folder, Vector3.new(-230, 0, -150))

	-- Keep people inside the map.
	for _, w in {
		{ Vector3.new(4, 80, 900), Vector3.new(-320, 40, -100) },
		{ Vector3.new(4, 80, 900), Vector3.new(320, 40, -100) },
		{ Vector3.new(700, 80, 4), Vector3.new(0, 40, 240) },
		{ Vector3.new(700, 80, 4), Vector3.new(0, 40, -440) },
	} do
		local wall = block(folder, "Boundary", w[1], w[2])
		wall.Transparency = 1
	end

	return spots
end

return Town
