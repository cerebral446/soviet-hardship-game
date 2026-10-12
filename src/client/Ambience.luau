-- The world's mood: lighting and fog per place and time, falling snow, breath, wind,
-- flickering lights, posters that change at night, the canteen radio and the mine lamps.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Audio = require(script.Parent.Audio)

local Ambience = {}

local rgb = Color3.fromRGB
local stage = 1
local region = "outdoor"
local ctx
local atmosphere, colour, bloom
local snowFar, snowNear, snowPart, nearPart
local breathPart, breath
local wind, hum
local profileKey
local tvWindows, tvScreens = {}, {}

local PROFILES = {
	outdoor = {
		lighting = { ClockTime = 23.4, Brightness = 0.45, Ambient = rgb(22, 26, 34), OutdoorAmbient = rgb(48, 56, 72), EnvironmentDiffuseScale = 0.25, EnvironmentSpecularScale = 0.3, ExposureCompensation = 0.1 },
		atmosphere = { Density = 0.38, Offset = 0.15, Color = rgb(104, 116, 134), Decay = rgb(56, 64, 82), Glare = 0, Haze = 1.6 },
		colour = { Saturation = -0.3, Contrast = 0.12, Brightness = 0, TintColor = rgb(214, 224, 240) },
	},
	night = {
		lighting = { ClockTime = 0.3, Brightness = 0.18, Ambient = rgb(10, 12, 16), OutdoorAmbient = rgb(24, 28, 38), EnvironmentDiffuseScale = 0.15, EnvironmentSpecularScale = 0.2, ExposureCompensation = 0 },
		atmosphere = { Density = 0.48, Offset = 0.1, Color = rgb(58, 66, 82), Decay = rgb(28, 32, 44), Glare = 0, Haze = 2 },
		colour = { Saturation = -0.45, Contrast = 0.18, Brightness = -0.02, TintColor = rgb(200, 212, 236) },
	},
	indoor = {
		lighting = { ClockTime = 23.4, Brightness = 0.3, Ambient = rgb(34, 32, 30), OutdoorAmbient = rgb(30, 34, 44), EnvironmentDiffuseScale = 0.3, EnvironmentSpecularScale = 0.3, ExposureCompensation = 0.1 },
		atmosphere = { Density = 0.22, Offset = 0, Color = rgb(70, 76, 86), Decay = rgb(40, 44, 54), Glare = 0, Haze = 0.5 },
		colour = { Saturation = -0.2, Contrast = 0.1, Brightness = 0, TintColor = rgb(236, 232, 222) },
	},
	nightIndoor = {
		lighting = { ClockTime = 0.3, Brightness = 0.15, Ambient = rgb(20, 18, 18), OutdoorAmbient = rgb(16, 18, 24), EnvironmentDiffuseScale = 0.2, EnvironmentSpecularScale = 0.2, ExposureCompensation = 0 },
		atmosphere = { Density = 0.25, Offset = 0, Color = rgb(40, 44, 52), Decay = rgb(20, 22, 28), Glare = 0, Haze = 0.5 },
		colour = { Saturation = -0.35, Contrast = 0.15, Brightness = -0.02, TintColor = rgb(226, 222, 214) },
	},
	underground = {
		lighting = { ClockTime = 0, Brightness = 0, Ambient = rgb(7, 7, 8), OutdoorAmbient = rgb(0, 0, 0), EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0.2, ExposureCompensation = 0.15 },
		atmosphere = { Density = 0.42, Offset = 0, Color = rgb(10, 9, 9), Decay = rgb(4, 4, 4), Glare = 0, Haze = 0 },
		colour = { Saturation = -0.25, Contrast = 0.15, Brightness = 0, TintColor = rgb(240, 228, 210) },
	},
}

local function inBox(p, box)
	local a, b = box[1], box[2]
	return p.X >= a.X and p.X <= b.X and p.Y >= a.Y and p.Y <= b.Y and p.Z >= a.Z and p.Z <= b.Z
end

function Ambience.regionAt(p)
	if p.Y < Config.UndergroundBelow then
		return "underground"
	end
	for _, box in Config.Interiors do
		if inBox(p, box) then
			return "indoor"
		end
	end
	return "outdoor"
end

function Ambience.region()
	return region
end

function Ambience.night()
	return stage >= Config.NightFrom
end

local function applyProfile(key, time)
	if key == profileKey then
		return
	end
	profileKey = key
	local p = PROFILES[key]
	local info = TweenInfo.new(time or 1.2, Enum.EasingStyle.Sine)
	-- ClockTime can't tween across midnight nicely; set it directly.
	Lighting.ClockTime = p.lighting.ClockTime
	local goal = table.clone(p.lighting)
	goal.ClockTime = nil
	TweenService:Create(Lighting, info, goal):Play()
	TweenService:Create(atmosphere, info, p.atmosphere):Play()
	TweenService:Create(colour, info, p.colour):Play()
end

local function profileFor()
	local night = stage >= Config.NightFrom
	if region == "underground" then
		return "underground"
	elseif region == "indoor" then
		return night and "nightIndoor" or "indoor"
	end
	return night and "night" or "outdoor"
end

local function setupEffects()
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 100000
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("PostEffect") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end
	local sky = Instance.new("Sky")
	sky.StarCount = 800
	sky.MoonAngularSize = 9
	sky.SunAngularSize = 0
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
	colour = Instance.new("ColorCorrectionEffect")
	colour.Parent = Lighting
	bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 30
	bloom.Threshold = 0.92
	bloom.Parent = Lighting
	local sun = Instance.new("SunRaysEffect")
	sun.Intensity = 0
	sun.Parent = Lighting
end

local function emitter(part, rate, size, speed)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = rate
	e.Lifetime = NumberRange.new(5, 8)
	e.Speed = NumberRange.new(speed[1], speed[2])
	e.SpreadAngle = Vector2.new(20, 20)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.7) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0.15), NumberSequenceKeypoint.new(0.85, 0.25), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(240, 244, 250))
	e.LightInfluence = 0.75
	e.LightEmission = 0.15
	e.Brightness = 1.4
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Acceleration = Vector3.new(6, -2, 2)
	e.Parent = part
	return e
end

local function setupSnow()
	local function holder(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = size
		p.Parent = workspace
		return p
	end
	snowPart = holder("Snowfall", Vector3.new(170, 1, 170))
	nearPart = holder("Snowfall near", Vector3.new(36, 1, 36))
	snowFar = emitter(snowPart, 450, 0.16, { 7, 11 })
	snowNear = emitter(nearPart, 140, 0.22, { 9, 13 })
	snowNear.Lifetime = NumberRange.new(1.5, 2.5)

	breathPart = holder("Breath", Vector3.new(0.4, 0.4, 0.4))
	breath = Instance.new("ParticleEmitter")
	breath.Texture = "rbxasset://textures/particles/smoke_main.dds"
	breath.Rate = 0
	breath.Lifetime = NumberRange.new(1, 1.6)
	breath.Speed = NumberRange.new(1.2, 2)
	breath.SpreadAngle = Vector2.new(15, 15)
	breath.EmissionDirection = Enum.NormalId.Front
	breath.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1.4) })
	breath.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
	breath.LightInfluence = 0.6
	breath.Acceleration = Vector3.new(0, 0.6, 0)
	breath.Parent = breathPart
end

-- Light registry: everything that can flicker or be switched off by the entity.
local lamps = {}
local function register(part, kind)
	local light = part:FindFirstChildWhichIsA("Light")
	local entry = { part = part, light = light, kind = kind, color = part.Color, material = part.Material, brightness = light and light.Brightness or 0, off = false, phase = math.random() * 100 }
	lamps[part] = entry
	return entry
end

function Ambience.setLamp(entry, on, level)
	level = level or 1
	if entry.light then
		entry.light.Enabled = on
		entry.light.Brightness = entry.brightness * level
	end
	if on then
		entry.part.Color = entry.color
		entry.part.Material = entry.material
	else
		entry.part.Color = rgb(40, 36, 32)
		entry.part.Material = Enum.Material.Glass
	end
end

function Ambience.lampsOfKind(kind)
	local out = {}
	for _, e in lamps do
		if e.kind == kind then
			table.insert(out, e)
		end
	end
	return out
end

local function setupLamps()
	for _, kind in { "Streetlight", "EntranceLamp", "FlickerLamp", "MineLamp", "CanteenLight", "Beacon" } do
		for _, part in CollectionService:GetTagged(kind) do
			register(part, kind)
		end
	end
	-- A few streetlights in "sector 4" (near the canteen) never work properly.
	for _, e in Ambience.lampsOfKind("Streetlight") do
		local z = e.part.Position.Z
		e.bad = (z < -95 and z > -175) or math.random() < 0.1
	end
end

-- Mine lamps die one after another, from the far end towards the cage.
local mineDead = false
function Ambience.killMineLamps()
	if mineDead then
		return
	end
	mineDead = true
	local list = Ambience.lampsOfKind("MineLamp")
	table.sort(list, function(a, b)
		return (a.part:GetAttribute("Order") or 0) > (b.part:GetAttribute("Order") or 0)
	end)
	task.spawn(function()
		for i, e in list do
			if not mineDead then
				return
			end
			e.dying = true
			task.delay(0.6, function()
				e.dying = false
				if mineDead then
					e.off = true
					Ambience.setLamp(e, false)
				end
			end)
			if i % 3 == 0 then
				task.wait(0.35)
			end
		end
	end)
end

function Ambience.restoreMineLamps()
	mineDead = false
	for _, e in Ambience.lampsOfKind("MineLamp") do
		e.off = false
		e.dying = false
		Ambience.setLamp(e, true)
	end
end

local function setPosters(night)
	for _, part in CollectionService:GetTagged("Poster") do
		local gui = part:FindFirstChildWhichIsA("SurfaceGui")
		local title = gui and gui:FindFirstChild("Title", true)
		local sub = gui and gui:FindFirstChild("Sub", true)
		if title and sub then
			title.Text = night and part:GetAttribute("NightTitle") or part:GetAttribute("DayTitle")
			sub.Text = night and part:GetAttribute("NightSub") or part:GetAttribute("DaySub")
		end
	end
end

local function setClocks()
	local clock = Config.Stages[stage].clock
	for _, part in CollectionService:GetTagged("WallClock") do
		local label = part:FindFirstChild("Text", true)
		if label then
			label.Text = clock
		end
	end
end

function Ambience.updateSeams(done)
	local set = {}
	for n in string.gmatch(done or "", "%d+") do
		set[tonumber(n)] = true
	end
	for _, mark in CollectionService:GetTagged("SeamMark") do
		local gui = mark:FindFirstChildWhichIsA("SurfaceGui")
		if gui then
			gui.Enabled = not set[mark:GetAttribute("Seam")]
		end
	end
	for _, ore in CollectionService:GetTagged("Seam") do
		local n = ore:GetAttribute("Seam")
		ore.Color = set[n] and Color3.fromRGB(52, 46, 40) or Color3.fromRGB(110, 92, 52)
		local prompt = ore:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt then
			prompt:SetAttribute("Done", set[n] == true)
		end
	end
end

-- The canteen scare: the lights fail, everyone turns to look at you, something is at the window.
local canteenTime = 0
local canteenScared = false
local radioTimer = 4
local radioIndex = 0

local function canteenScare()
	canteenScared = true
	local tubes = Ambience.lampsOfKind("CanteenLight")
	task.spawn(function()
		for _ = 1, 8 do
			for _, e in tubes do
				Ambience.setLamp(e, math.random() < 0.5)
			end
			task.wait(0.08)
		end
		for _, e in tubes do
			Ambience.setLamp(e, false)
		end
		ctx.People.stare(true)
		ctx.Ui.static(0.3, 0.4)
		ctx.Ui.say("Радио «Маяк»: …ш-ш-ш… не оглядывайся… он уже здесь…", 4)
		local spot = Config.Places.CanteenWindowSpot
		ctx.Entity.showAt(CFrame.lookAt(spot, spot + Vector3.new(1, 0, 0)), 7)
		Audio.play("Sting", { volume = 0.8 })
		task.wait(2.6)
		for _, e in tubes do
			Ambience.setLamp(e, true)
		end
		task.wait(2.5)
		ctx.People.stare(false)
	end)
end

function Ambience.onStage(s)
	local wasNight = stage >= Config.NightFrom
	stage = s
	local night = s >= Config.NightFrom
	if night ~= wasNight or s == 1 then
		setPosters(night)
	end
	setClocks()
	if s < 6 then
		Ambience.restoreMineLamps()
	elseif s == 6 then
		Ambience.killMineLamps()
	end
	if s ~= 8 then
		canteenTime = 0
		canteenScared = false
	end
	profileKey = nil
	applyProfile(profileFor(), 0.5)
	-- At night the snow comes down harder.
	snowFar.Rate = night and 650 or 450
	snowNear.Rate = night and 200 or 140
end

local breathTimer = 0
local gust = 0
local function update(dt)
	local camera = workspace.CurrentCamera
	local camCF = camera.CFrame
	local camPos = camCF.Position
	local t = os.clock()

	local newRegion = Ambience.regionAt(camPos)
	if newRegion ~= region then
		region = newRegion
		SoundService.AmbientReverb = region == "underground" and Enum.ReverbType.Cave or (region == "indoor" and Enum.ReverbType.Room or Enum.ReverbType.Mountains)
	end
	applyProfile(profileFor())

	-- Snow follows the camera, drifting with the wind.
	local outside = region == "outdoor"
	snowFar.Enabled = outside
	snowNear.Enabled = outside
	gust = math.sin(t * 0.21) * 0.5 + math.sin(t * 0.67) * 0.3 + 0.6
	local windVec = Vector3.new(6 + gust * 7, -2, 2 + gust)
	snowFar.Acceleration = windVec
	snowNear.Acceleration = windVec
	snowPart.CFrame = CFrame.new(camPos + Vector3.new(-windVec.X * 2.5, 38, -windVec.Z * 2.5))
	nearPart.CFrame = CFrame.new(camPos + Vector3.new(-windVec.X * 0.8, 12, 0) + camCF.LookVector * 8)

	-- Your breath in the cold.
	breathPart.CFrame = camCF * CFrame.new(0, -0.6, -1.2)
	breathTimer -= dt
	if breathTimer <= 0 then
		local running = ctx.isSprinting and ctx.isSprinting()
		breathTimer = running and 1.4 or 3.2
		if outside or region == "underground" then
			breath:Emit(running and 6 or 4)
		end
	end

	-- Wind and the hum of the mine.
	local windTarget = outside and (0.25 + gust * 0.2) * (stage >= Config.NightFrom and 1.5 or 1) or (region == "indoor" and 0.06 or 0)
	wind.Volume += (windTarget - wind.Volume) * math.min(dt * 2, 1)
	wind.PlaybackSpeed = 0.3 + gust * 0.08
	local humTarget = region == "underground" and (stage == 6 and 0.12 or 0.3) or 0
	hum.Volume += (humTarget - hum.Volume) * math.min(dt * 2, 1)

	-- Lights.
	for _, e in lamps do
		if e.off or e.killed then
			continue
		end
		if e.kind == "Beacon" then
			local on = (t + e.phase * 0.01) % 2 < 1
			Ambience.setLamp(e, on)
		elseif e.dying then
			Ambience.setLamp(e, math.random() < 0.4, math.random())
		elseif e.kind == "FlickerLamp" or (e.kind == "Streetlight" and e.bad) then
			local n = math.noise(t * 3, e.phase)
			Ambience.setLamp(e, n > -0.25, 0.6 + n * 0.5)
		elseif e.kind == "MineLamp" and math.noise(t * 2, e.phase) > 0.42 then
			Ambience.setLamp(e, math.random() < 0.7, 0.5 + math.random() * 0.5)
		elseif e.kind == "MineLamp" then
			Ambience.setLamp(e, true)
		end
	end
	for _, w in tvWindows do
		local n = math.noise(t * 4, w.Position.X)
		w.Color = rgb(50 + n * 30, 70 + n * 40, 110 + n * 50)
	end
	for _, s in tvScreens do
		local on = stage == 1 or stage == Config.FinalStage
		s.Material = on and Enum.Material.Neon or Enum.Material.Glass
		local n = math.random()
		s.Color = on and rgb(60 + n * 40, 64 + n * 40, 70 + n * 40) or rgb(38, 46, 44)
	end
	if stage >= Config.NightFrom then
		for _, seat in CollectionService:GetTagged("Swing") do
			local base = seat:GetAttribute("Base")
			if not base then
				base = seat.CFrame
				seat:SetAttribute("Base", base)
			end
			local pivot = base * CFrame.new(0, 6, 0)
			seat.CFrame = pivot * CFrame.Angles(math.sin(t * 1.1) * 0.35, 0, 0) * CFrame.new(0, -6, 0)
		end
	end

	-- The canteen: radio chatter, and once per evening, the scare.
	if region == "indoor" and stage >= 7 and stage <= 8 and inBox(camPos, Config.Interiors[2]) then
		radioTimer -= dt
		if radioTimer <= 0 then
			radioIndex = radioIndex % (#Config.Radio - 1) + 1
			local line = Config.Radio[radioIndex]
			if stage == 8 and canteenScared then
				line = Config.Radio[#Config.Radio]
			end
			ctx.Ui.say(line, 6)
			radioTimer = 14
		end
		if stage == 8 then
			canteenTime += dt
			if canteenTime > 9 and not canteenScared then
				canteenScare()
			end
		end
	end
end

function Ambience.init(context)
	ctx = context
	setupEffects()
	setupSnow()
	setupLamps()
	tvWindows = CollectionService:GetTagged("TVWindow")
	tvScreens = CollectionService:GetTagged("TVScreen")
	wind = Audio.make("Wind")
	wind.Volume = 0
	wind:Play()
	hum = Audio.make("MineHum")
	hum.Volume = 0
	hum:Play()
	applyProfile("indoor", 0)
	RunService.RenderStepped:Connect(update)
end

-- Used by the entity: switch off lights near it, restore them when it has passed.
function Ambience.killLightsNear(position, radius, restoreRadius)
	for _, e in lamps do
		if e.kind ~= "Streetlight" and e.kind ~= "EntranceLamp" and e.kind ~= "FlickerLamp" then
			continue
		end
		local offset = e.part.Position - position
		local d = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if not e.killed and d < radius then
			e.killed = true
			Ambience.setLamp(e, false)
		elseif e.killed and d > restoreRadius then
			e.killed = false
			Ambience.setLamp(e, true)
		end
	end
end

function Ambience.restoreAllLights()
	for _, e in lamps do
		if e.killed then
			e.killed = false
			Ambience.setLamp(e, true)
		end
	end
end

return Ambience
