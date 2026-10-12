-- Everyone who isn't you: diners, staff and miners (built by the server, animated here),
-- and coworkers walking to and from the mine (spawned locally). Nobody is out at night.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Figure = require(Shared.Figure)
local Rig = require(script.Parent.Rig)

local People = {}

local staged = {}
local walkers = {}
local stage = 1
local staring = false
local folder

local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- 0..1 envelope: rise, hold, fall, then rest for the remainder of the cycle.
local function lift(u, up, hold, down)
	if u < up then
		return smooth(u / up)
	elseif u < up + hold then
		return 1
	elseif u < up + hold + down then
		return 1 - smooth((u - up - hold) / down)
	end
	return 0
end

local function actionAngles(entry, t)
	local model = entry.model
	local action = entry.action
	local restR = model:GetAttribute("Rest_ArmR") or 0
	local a = {}
	t += entry.phase
	if action == "eat" then
		local k = lift((t % 4.6) / 4.6, 0.13, 0.1, 0.13)
		a.ArmR = CFrame.Angles(math.rad(128) - restR, 0, 0):Lerp(CFrame.identity, 1 - k)
		a.Head = CFrame.Angles(-0.25 + 0.15 * k, 0, 0)
	elseif action == "drink" then
		local k = lift((t % 7.5) / 7.5, 0.12, 0.2, 0.12)
		a.ArmR = CFrame.Angles(math.rad(150) - restR, 0, 0):Lerp(CFrame.identity, 1 - k)
		a.Head = CFrame.Angles(-0.1 + 0.35 * k, 0, 0)
	elseif action == "smoke" then
		local k = lift((t % 6.5) / 6.5, 0.15, 0.15, 0.15)
		a.ArmR = CFrame.Angles(math.rad(140) - restR, 0, 0):Lerp(CFrame.identity, 1 - k)
		a.Head = CFrame.Angles(0.1 * k, math.sin(t * 0.3) * 0.3, 0)
	elseif action == "read" then
		a.Head = CFrame.Angles(-0.35 + math.sin(t * 0.7) * 0.03, math.sin(t * 0.2) * 0.1, 0)
		a.ArmL = CFrame.Angles(0.15 * lift((t % 9) / 9, 0.05, 0.05, 0.05), 0, 0)
	elseif action == "stir" then
		a.ArmR = CFrame.Angles(math.sin(t * 3) * 0.3, 0, math.cos(t * 3) * 0.25)
		a.Head = CFrame.Angles(-0.35, 0, 0)
	elseif action == "dig" then
		local u = (t % 1.7) / 1.7
		local swing = u < 0.6 and smooth(u / 0.6) or 1 - smooth((u - 0.6) / 0.4)
		local delta = math.rad(70) * swing - math.rad(40)
		a.ArmR = CFrame.Angles(delta, 0, 0)
		a.ArmL = CFrame.Angles(delta, 0, 0)
		a.Head = CFrame.Angles(-0.2, 0, 0)
	elseif action == "walk" then
		local s = math.sin(t * entry.stride)
		a.LegL = CFrame.Angles(s * 0.45, 0, 0)
		a.LegR = CFrame.Angles(-s * 0.45, 0, 0)
		a.ArmL = CFrame.Angles(-s * 0.3, 0, 0)
		a.ArmR = CFrame.Angles(s * 0.3, 0, 0)
		a.Head = CFrame.Angles(-0.12, 0, 0)
	else
		a.Head = CFrame.Angles(math.sin(t * 0.17) * 0.06, math.sin(t * 0.23) * 0.5, 0)
	end
	return a
end

local function addStaged(model)
	if not model:IsA("Model") then
		return
	end
	local entry = {
		model = model,
		rig = Rig.new(model),
		action = model:GetAttribute("Action") or "idle",
		from = model:GetAttribute("ShowFrom") or 1,
		to = model:GetAttribute("ShowTo") or 99,
		phase = (model:GetAttribute("Seed") or 0) % 100 / 7,
	}
	entry.base = entry.rig.pivot
	table.insert(staged, entry)
	entry.rig:setVisible(stage >= entry.from and stage <= entry.to)
end

local function routeLength(route)
	local total, cum = 0, { 0 }
	for i = 2, #route do
		total += (route[i] - route[i - 1]).Magnitude
		cum[i] = total
	end
	return total, cum
end

local function placeWalker(w, initial)
	local group = w.group
	w.route = group.routes[math.random(1, #group.routes)]
	w.total, w.cum = routeLength(w.route)
	w.s = initial and math.random() * w.total * 0.85 or 0
	w.offset = (math.random() - 0.5) * 3
	w.speed = 5 + math.random() * 2
end

local HATS = { "ushanka", "ushanka", "ushanka", "kerchief", "shawl", "furhat", "cap", "helmet" }

local function spawnWalker(group, initial)
	-- Morning: some carry a briefcase. Evening: the string bag from the shop.
	local evening = table.find(group.stages, 7) ~= nil
	local held = nil
	if math.random() < (evening and 0.45 or 0.2) then
		held = evening and "avoska" or "briefcase"
	end
	local model = Figure.build(folder, CFrame.new(0, -500, 0), {
		hat = HATS[math.random(1, #HATS)],
		held = held,
		armR = 0,
		armL = 5,
		seed = math.random(1, 1e6),
		name = "Coworker",
	})
	local w = {
		group = group,
		model = model,
		rig = Rig.new(model),
		action = "walk",
		phase = math.random() * 10,
		speed = 6,
		stride = 6,
		route = {},
		total = 0,
		cum = {},
		s = 0,
		offset = 0,
	}
	placeWalker(w, initial)
	w.stride = w.speed * 0.95
	table.insert(walkers, w)
end

local function syncWalkers()
	for _, group in Config.Walkers do
		local active = table.find(group.stages, stage) ~= nil
		local count = 0
		for i = #walkers, 1, -1 do
			local w = walkers[i]
			if w.group == group then
				if active then
					count += 1
				else
					w.model:Destroy()
					table.remove(walkers, i)
				end
			end
		end
		if active then
			for _ = count + 1, group.count do
				spawnWalker(group, true)
			end
		end
	end
end

local function positionOn(w)
	local route, cum = w.route, w.cum
	for i = 2, #route do
		if w.s <= cum[i] then
			local a, b = route[i - 1], route[i]
			local t = (w.s - cum[i - 1]) / math.max(cum[i] - cum[i - 1], 0.01)
			local dir = (b - a).Unit
			local side = Vector3.new(-dir.Z, 0, dir.X)
			return a:Lerp(b, t) + side * w.offset, dir
		end
	end
	local last = route[#route]
	return last, (last - route[#route - 1]).Unit
end

local accumulator = 0
local function update(dt)
	accumulator += dt
	if accumulator < 1 / 30 then
		return
	end
	local step = accumulator
	accumulator = 0
	local camera = workspace.CurrentCamera
	local camPos = camera.CFrame.Position
	local t = os.clock()

	for _, e in staged do
		local visible = stage >= e.from and stage <= e.to
		e.rig:setVisible(visible)
		if visible and (e.base.Position - camPos).Magnitude < 110 then
			local angles = actionAngles(e, t)
			if staring and (e.base.Position - camPos).Magnitude < 60 then
				angles = { Head = e.rig:lookAngles(camPos) }
			end
			e.rig:pose(e.base, angles)
		end
	end

	for _, w in walkers do
		w.s += w.speed * step
		if w.s >= w.total then
			placeWalker(w, false)
		end
		local pos, dir = positionOn(w)
		local pivot = CFrame.lookAt(pos + Vector3.new(0, 0.25, 0), pos + Vector3.new(0, 0.25, 0) + dir)
		if (pos - camPos).Magnitude < 160 then
			w.rig:pose(pivot, actionAngles(w, t))
		else
			w.rig:pose(pivot, {})
		end
	end
end

function People.init()
	folder = Instance.new("Folder")
	folder.Name = "Townsfolk (local)"
	folder.Parent = workspace
	for _, m in CollectionService:GetTagged("StagedPerson") do
		addStaged(m)
	end
	CollectionService:GetInstanceAddedSignal("StagedPerson"):Connect(addStaged)
	RunService.Heartbeat:Connect(update)
end

function People.onStage(s)
	stage = s
	syncWalkers()
end

-- Everyone in the room turns to look at you.
function People.stare(on)
	staring = on
end

function People.folder()
	return folder
end

return People
