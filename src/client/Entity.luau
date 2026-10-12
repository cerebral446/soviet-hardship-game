-- БРИГАДИР — "the Foreman". A tall, faceless figure in a greatcoat and ushanka, wearing
-- miner's lamp No. 117. It never runs. It walks your footsteps.
--
-- Rules the player can learn (the notes and night posters hint at them):
--   * While you look at it, it does not move.
--   * Stare too long and it is suddenly closer.
--   * Stand still and it closes the distance fast.
--   * Lights die when it passes.
--
-- Modes (from the stage's "threat"): glimpse, mineIdle, mineHunt, canteen, hunt, none.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Build = require(Shared.Build)
local Audio = require(script.Parent.Audio)
local Rig = require(script.Parent.Rig)

local Entity = {}

local E = Config.Entity
local rgb = Color3.fromRGB
local player = Players.LocalPlayer
local ctx
local model, rig, lampLight, lampPart, footsteps, torso, head
local mode = "none"
local visibleNow = false
local caught = false
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- State shared by the modes.
local pos = Vector3.zero -- feet
local stare = 0
local stillTime = 0
local heartTimer = 0

-- Night hunt: your trail.
local trail = { pts = {}, cum = {} }
local sEntity = 0
local huntActive = false
local doorFloorUsed = false

-- Underground.
local nodes, nodeNames, distM, nextM, edges = {}, {}, {}, {}, {}
local path = {}
local repathTimer = 0
local mineSpawnDelay = 0

-- Glimpses.
local glimpseTimer = 20
local glimpseLife = 0
local glimpseStare = 0
local showUntil = 0

local function build()
	local m = Instance.new("Model")
	m.Name = "Бригадир"
	local root = Build.detail(Build.block(m, "Root", Vector3.new(1, 1, 1), CFrame.new(), rgb(0, 0, 0)))
	root.Transparency = 1
	m.PrimaryPart = root
	local coat = rgb(16, 16, 18)
	local skin = rgb(168, 170, 164)
	local function part(name, size, at, color, material, group, shape)
		local p = Build.detail(Build.block(m, name, size, at, color, material or Enum.Material.Fabric))
		p.CastShadow = true
		if shape then
			p.Shape = shape
		end
		if group then
			p:SetAttribute("Group", group)
		end
		return p
	end
	-- Legs.
	for i, x in { -0.45, 0.45 } do
		local g = i == 1 and "LegL" or "LegR"
		m:SetAttribute("Joint_" .. g, CFrame.new(x, 5.2, 0))
		part("Leg", Vector3.new(0.5, 5.2, 0.5), CFrame.new(x, 2.6, 0), coat, nil, g)
		part("Boot", Vector3.new(0.65, 0.5, 1.2), CFrame.new(x, 0.25, -0.2), rgb(10, 10, 10), Enum.Material.Leather, g)
	end
	-- Greatcoat, too long, hunched shoulders.
	part("Coat skirt", Vector3.new(2.6, 3, 1.5), CFrame.new(0, 4.6, 0.05), coat)
	torso = part("Torso", Vector3.new(2.3, 3.4, 1.25), CFrame.new(0, 7.3, 0.1) * CFrame.Angles(-0.12, 0, 0), coat)
	part("Shoulders", Vector3.new(3.1, 0.8, 1.4), CFrame.new(0, 8.9, 0.25) * CFrame.Angles(-0.2, 0, 0), coat)
	part("Belt", Vector3.new(2.4, 0.3, 1.35), CFrame.new(0, 5.9, 0.05), rgb(30, 24, 20), Enum.Material.Leather)
	-- Neck and head lean forward, tilted.
	m:SetAttribute("Joint_Head", CFrame.new(0, 9.3, -0.1))
	part("Neck", Vector3.new(0.4, 1.4, 0.4), CFrame.new(0, 9.9, -0.35) * CFrame.Angles(-0.35, 0, 0), skin, Enum.Material.SmoothPlastic, "Head")
	head = part("Head", Vector3.new(1.15, 1.5, 1.1), CFrame.new(0, 10.9, -0.6) * CFrame.Angles(-0.1, 0, 0.18), skin, Enum.Material.SmoothPlastic, "Head")
	local face = head.CFrame
	for _, x in { -0.27, 0.27 } do
		part("Eye socket", Vector3.new(0.34, 0.26, 0.08), face * CFrame.new(x, 0.12, -0.54), rgb(0, 0, 0), Enum.Material.SmoothPlastic, "Head")
	end
	part("Mouth", Vector3.new(0.75, 0.16, 0.08), face * CFrame.new(0, -0.42, -0.54), rgb(0, 0, 0), Enum.Material.SmoothPlastic, "Head")
	part("Ushanka", Vector3.new(1.5, 0.7, 1.4), face * CFrame.new(0, 0.95, 0.05), rgb(28, 24, 20), Enum.Material.Fabric, "Head")
	part("Ushanka brim", Vector3.new(1.5, 0.35, 0.35), face * CFrame.new(0, 0.75, -0.65), rgb(28, 24, 20), Enum.Material.Fabric, "Head")
	for _, x in { -0.78, 0.78 } do
		part("Ear flap", Vector3.new(0.22, 0.9, 1), face * CFrame.new(x, 0.25, 0.05), rgb(28, 24, 20), Enum.Material.Fabric, "Head")
	end
	-- Lamp No. 117.
	lampPart = part("Lamp 117", Vector3.new(0.5, 0.42, 0.22), face * CFrame.new(0, 0.9, -0.78), rgb(255, 190, 110), Enum.Material.Neon, "Head")
	lampLight = Instance.new("PointLight")
	lampLight.Color = rgb(255, 170, 90)
	lampLight.Range = 11
	lampLight.Brightness = 0.7
	lampLight.Parent = lampPart
	-- Arms that hang past the knees, long fingers.
	for i, x in { -1.55, 1.55 } do
		local g = i == 1 and "ArmL" or "ArmR"
		local shoulder = CFrame.new(x, 8.8, 0.1)
		m:SetAttribute("Joint_" .. g, shoulder)
		part("Arm", Vector3.new(0.42, 6.4, 0.45), shoulder * CFrame.new(0, -3.1, 0), coat, nil, g)
		part("Hand", Vector3.new(0.45, 0.7, 0.28), shoulder * CFrame.new(0, -6.6, 0), skin, Enum.Material.SmoothPlastic, g)
		for f = -1, 1 do
			part("Finger", Vector3.new(0.08, 1.3, 0.08), shoulder * CFrame.new(f * 0.14, -7.6, -0.05) * CFrame.Angles(0.15, 0, f * 0.08), skin, Enum.Material.SmoothPlastic, g)
		end
	end
	footsteps = Audio.make("Footsteps", torso, { range = 90 })
	return m
end

local function ground()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return nil, nil
	end
	local offset = humanoid.RigType == Enum.HumanoidRigType.R6 and 3 or humanoid.HipHeight + root.Size.Y / 2
	return root.Position - Vector3.new(0, offset, 0), humanoid
end

local function show(on)
	visibleNow = on
	model.Parent = on and workspace or nil
	if not on then
		footsteps:Stop()
	end
end

local function place(feet, faceTo, t, walking)
	local flat = Vector3.new(faceTo.X, feet.Y, faceTo.Z)
	if (flat - feet).Magnitude < 0.05 then
		flat = feet + Vector3.new(0, 0, -1)
	end
	local sway = walking and math.sin(t * 4) * 0.05 or 0
	local pivot = CFrame.lookAt(feet, flat) * CFrame.Angles(0, 0, sway)
	local stride = walking and math.sin(t * 4) or 0
	local twitch = (math.noise(t * 1.3, 7) > 0.45) and (math.random() - 0.5) * 0.5 or 0
	rig:pose(pivot, {
		LegL = CFrame.Angles(stride * 0.35, 0, 0),
		LegR = CFrame.Angles(-stride * 0.35, 0, 0),
		ArmL = CFrame.Angles(-stride * 0.12 + 0.05, 0, 0.04),
		ArmR = CFrame.Angles(stride * 0.12 + 0.05, 0, -0.04),
		Head = CFrame.Angles(0, twitch, math.sin(t * 0.7) * 0.08),
	})
end

-- Is the player looking at it, with a clear line of sight?
local function seen(maxDistance)
	local camera = workspace.CurrentCamera
	local camPos = camera.CFrame.Position
	local filter = { model }
	if player.Character then
		table.insert(filter, player.Character)
	end
	rayParams.FilterDescendantsInstances = filter
	for _, p in { head, torso } do
		local to = p.Position - camPos
		local d = to.Magnitude
		if d < maxDistance and d > 0.1 and camera.CFrame.LookVector:Dot(to / d) > E.ViewDot then
			if not workspace:Raycast(camPos, to, rayParams) then
				return true
			end
		end
	end
	return false
end

-- Trail ------------------------------------------------------------------------------------

local function trailReset(start)
	trail.pts = { start }
	trail.cum = { 0 }
end

local function trailAdd(p)
	local pts = trail.pts
	local last = pts[#pts]
	local d = (p - last).Magnitude
	if d >= 1.5 then
		table.insert(pts, p)
		table.insert(trail.cum, trail.cum[#trail.cum] + d)
	end
end

local function trailLength(current)
	local pts = trail.pts
	return trail.cum[#trail.cum] + (current - pts[#pts]).Magnitude
end

local function trailAt(s, current)
	local pts, cum = trail.pts, trail.cum
	if s <= 0 then
		return pts[1], pts[2] or current
	end
	if s >= cum[#cum] then
		local last = pts[#pts]
		local remain = (current - last).Magnitude
		local t = remain > 0 and math.clamp((s - cum[#cum]) / remain, 0, 1) or 1
		return last:Lerp(current, t), current
	end
	local lo, hi = 1, #cum
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if cum[mid] <= s then
			lo = mid
		else
			hi = mid
		end
	end
	local t = (s - cum[lo]) / math.max(cum[hi] - cum[lo], 0.001)
	return pts[lo]:Lerp(pts[hi], t), pts[hi]
end

-- Mine graph -------------------------------------------------------------------------------

local function setupGraph()
	local O = Config.Places.Underground
	for name, p in Config.MineNodes do
		nodes[name] = O + p
		table.insert(nodeNames, name)
	end
	for _, a in nodeNames do
		distM[a], nextM[a] = {}, {}
		for _, b in nodeNames do
			distM[a][b] = a == b and 0 or math.huge
		end
	end
	for _, e in Config.MineEdges do
		local a, b = e[1], e[2]
		local d = (nodes[a] - nodes[b]).Magnitude
		distM[a][b], distM[b][a] = d, d
		nextM[a][b], nextM[b][a] = b, a
		table.insert(edges, { a, b })
	end
	for _, k in nodeNames do
		for _, i in nodeNames do
			for _, j in nodeNames do
				if distM[i][k] + distM[k][j] < distM[i][j] then
					distM[i][j] = distM[i][k] + distM[k][j]
					nextM[i][j] = nextM[i][k]
				end
			end
		end
	end
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function closestEdge(p)
	local best, bestD = nil, math.huge
	for _, e in edges do
		local a, b = flat(nodes[e[1]]), flat(nodes[e[2]])
		local ab = b - a
		local t = math.clamp((flat(p) - a):Dot(ab) / ab:Dot(ab), 0, 1)
		local d = (flat(p) - (a + ab * t)).Magnitude
		if d < bestD then
			best, bestD = e, d
		end
	end
	return best
end

local function repath(target)
	local ee, pe = closestEdge(pos), closestEdge(target)
	if ee == pe then
		path = { target }
		return
	end
	local bestCost, bestA, bestB = math.huge, nil, nil
	for _, a in ee do
		for _, b in pe do
			local cost = (pos - nodes[a]).Magnitude + distM[a][b] + (nodes[b] - target).Magnitude
			if cost < bestCost then
				bestCost, bestA, bestB = cost, a, b
			end
		end
	end
	path = {}
	local cur = bestA
	table.insert(path, nodes[cur])
	while cur ~= bestB do
		cur = nextM[cur][bestB]
		table.insert(path, nodes[cur])
	end
	table.insert(path, target)
end

local function walkPath(distance)
	while distance > 0 and #path > 0 do
		local target = Vector3.new(path[1].X, pos.Y, path[1].Z)
		local to = target - pos
		local d = to.Magnitude
		if d <= distance then
			pos = target
			distance -= d
			table.remove(path, 1)
		else
			pos += to.Unit * distance
			distance = 0
		end
	end
end

local function spawnInLair(playerPos)
	local best, bestD = nil, -1
	for _, name in Config.MineLairs do
		local d = (nodes[name] - playerPos).Magnitude
		if d > bestD then
			best, bestD = name, d
		end
	end
	pos = nodes[best]
	path = {}
	repathTimer = 0
end

-- Jumpscare ------------------------------------------------------------------------------------

local function catch()
	if caught then
		return
	end
	caught = true
	show(true)
	local camera = workspace.CurrentCamera
	local camCF = camera.CFrame
	local look = flat(camCF.LookVector)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
	local feet = camCF.Position + look * 2.3 - Vector3.new(0, 10.6, 0)
	rig:pose(CFrame.lookAt(feet, feet - look), { Head = CFrame.Angles(0.25, 0, 0.3), ArmL = CFrame.Angles(1.3, 0, 0.3), ArmR = CFrame.Angles(1.3, 0, -0.3) })
	lampLight.Brightness = 4
	lampLight.Range = 16
	Audio.play("Scream")
	Audio.play("ScreamLow")
	ctx.Ui.redFlash()
	ctx.Ui.static(0.8, 0.8)
	ctx.shake(1, 0.7)
	ctx.freeze(true)
	task.delay(0.85, function()
		show(false)
		lampLight.Brightness = 0.7
		lampLight.Range = 11
		ctx.Ui.missing()
		ctx.flashlightFlicker(0)
		ReplicatedStorage.Remotes.Caught:FireServer()
	end)
end

-- Modes ------------------------------------------------------------------------------------

local function heartbeatFor(distance, dt)
	if distance > 45 then
		return
	end
	heartTimer -= dt
	if heartTimer <= 0 then
		heartTimer = math.clamp(distance / 30, 0.35, 1.4)
		Audio.play("Heartbeat", { volume = math.clamp(1.4 - distance / 40, 0.2, 1.2) })
	end
end

local function stepHunt(dt, feet, humanoid, t)
	local walking = humanoid.MoveDirection.Magnitude > 0.1
	stillTime = walking and 0 or stillTime + dt
	trailAdd(feet)
	local sPlayer = trailLength(feet)
	if not huntActive then
		if (feet - Config.Places.CanteenDoor).Magnitude > E.StartDelay then
			huntActive = true
			sEntity = 0
			Audio.at("Groan", Config.Places.CanteenDoor + Vector3.new(0, 5, 0), { range = 160 })
			ctx.Ui.say("Behind you, the canteen door bangs open. Then nothing. Then footsteps.", 6)
		else
			return
		end
	end
	local observed = visibleNow and seen(130)
	if observed then
		stare += dt
	else
		stare = math.max(0, stare - dt * 0.5)
	end
	local speed = observed and 0 or (stillTime > 1.5 and E.StillSpeed or E.Speed)
	sEntity += speed * dt
	if stare > E.StareLimit then
		stare = 0
		sEntity += E.BlinkJump
		ctx.Ui.static(0.25, 0.7)
		Audio.play("Sting")
	end
	if sPlayer - sEntity > E.MaxLag then
		sEntity = sPlayer - E.MaxLag
	end
	if not doorFloorUsed and (feet - Config.Places.HomeDoor).Magnitude < 16 then
		doorFloorUsed = true
		if sPlayer - sEntity < E.DoorFloor then
			sEntity = sPlayer - E.DoorFloor
		end
	end
	local behind = sPlayer - sEntity
	local p = trailAt(sEntity, feet)
	pos = p
	show(true)
	place(pos, feet, t, speed > 0)
	if speed > 0 and not footsteps.IsPlaying then
		footsteps:Play()
	elseif speed == 0 and footsteps.IsPlaying then
		footsteps:Stop()
	end
	ctx.Ambience.killLightsNear(pos, 15, 30)
	local real = (pos - feet).Magnitude
	heartbeatFor(math.min(behind, real), dt)
	ctx.flashlightFlicker(real < 32 and (1 - real / 32) or 0)
	if real < E.CatchDistance or behind < E.CatchDistance then
		catch()
	end
end

local function stepMine(dt, feet, humanoid, t)
	if mineSpawnDelay > 0 then
		mineSpawnDelay -= dt
		if mineSpawnDelay <= 0 then
			spawnInLair(feet)
			show(true)
			Audio.at("Groan", pos + Vector3.new(0, 6, 0), { range = 200 })
		end
		return
	end
	local walking = humanoid.MoveDirection.Magnitude > 0.1
	stillTime = walking and 0 or stillTime + dt
	local observed = seen(95)
	if observed then
		stare += dt
	else
		stare = math.max(0, stare - dt * 0.5)
	end
	repathTimer -= dt
	if repathTimer <= 0 then
		repathTimer = 0.3
		repath(feet)
	end
	local speed = observed and 0 or (stillTime > 1.5 and E.MineSpeed * 1.8 or E.MineSpeed)
	walkPath(speed * dt)
	if stare > E.StareLimit then
		stare = 0
		walkPath(E.BlinkJump * 0.8)
		ctx.Ui.static(0.25, 0.7)
		Audio.play("Sting")
	end
	pos = Vector3.new(pos.X, Config.Places.Underground.Y, pos.Z)
	place(pos, feet, t, speed > 0)
	if speed > 0 and not footsteps.IsPlaying then
		footsteps:Play()
	elseif speed == 0 and footsteps.IsPlaying then
		footsteps:Stop()
	end
	local real = (flat(pos) - flat(feet)).Magnitude
	heartbeatFor(real, dt)
	ctx.flashlightFlicker(real < 30 and (1 - real / 30) or 0)
	if real < E.CatchDistance then
		catch()
	end
end

local GROUND = { Snow = true, Road = true, Sidewalk = true, Rut = true, Path = true, Yard = true, Plaza = true }

local function tryGlimpse(feet)
	local camera = workspace.CurrentCamera
	local look = flat(camera.CFrame.LookVector)
	if look.Magnitude < 0.1 then
		return false
	end
	look = look.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, model }
	for _ = 1, 10 do
		local yaw = math.rad(math.random(-40, 40))
		local dir = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(look)
		local p = feet + dir * math.random(65, 100)
		local hit = workspace:Raycast(Vector3.new(p.X, 200, p.Z), Vector3.new(0, -260, 0), params)
		if hit and GROUND[hit.Instance.Name] then
			pos = hit.Position
			glimpseLife = 14
			glimpseStare = 0
			show(true)
			return true
		end
	end
	return false
end

local function stepGlimpse(dt, feet, t)
	if visibleNow then
		place(pos, feet, t, false)
		if seen(140) then
			glimpseStare += dt
		end
		glimpseLife -= dt
		local d = (flat(pos) - flat(feet)).Magnitude
		if d < E.GlimpseVanishDistance or glimpseStare > E.GlimpseVanishStare or glimpseLife <= 0 then
			if glimpseStare > 0.2 or d < E.GlimpseVanishDistance then
				ctx.Ui.static(0.12, 0.4)
				Audio.play("Sting", { volume = 0.5 })
			end
			show(false)
			glimpseTimer = math.random(E.GlimpseEvery[1], E.GlimpseEvery[2])
		end
		return
	end
	if ctx.Ambience.region() ~= "outdoor" then
		return
	end
	glimpseTimer -= dt
	if glimpseTimer <= 0 then
		if not tryGlimpse(feet) then
			glimpseTimer = 5
		end
	end
end

local idleTimer = 25
local function stepMineIdle(dt, feet)
	idleTimer -= dt
	if idleTimer <= 0 then
		idleTimer = math.random(25, 45)
		-- Distant footsteps somewhere in the dark, then silence.
		local far, farD = nil, 0
		for _, name in nodeNames do
			local d = (nodes[name] - feet).Magnitude
			if d > farD and d < 140 then
				far, farD = nodes[name], d
			end
		end
		if far then
			local s = Audio.at("Footsteps", far + Vector3.new(0, 4, 0), { range = 160, life = 4 })
			task.delay(2.5, function()
				s:Stop()
			end)
		end
	end
	if math.random() < dt * 0.2 then
		Audio.play("Drip", { pitch = 2 + math.random() })
	end
end

local function update(dt)
	if caught then
		return
	end
	local feet, humanoid = ground()
	if not feet then
		return
	end
	local t = os.clock()
	if os.clock() < showUntil then
		place(pos, feet, t, false)
		if seen(80) then
			glimpseStare += dt
			if glimpseStare > 1.5 then
				showUntil = 0
				show(false)
				Audio.play("Sting", { volume = 0.6 })
			end
		end
		return
	elseif showUntil > 0 then
		showUntil = 0
		show(false)
	end
	if mode == "hunt" then
		stepHunt(dt, feet, humanoid, t)
	elseif mode == "mineHunt" then
		stepMine(dt, feet, humanoid, t)
	elseif mode == "glimpse" then
		stepGlimpse(dt, feet, t)
	elseif mode == "mineIdle" then
		stepMineIdle(dt, feet)
	end
end

function Entity.init(context)
	ctx = context
	model = build()
	rig = Rig.new(model)
	setupGraph()
	RunService.Heartbeat:Connect(update)
end

-- Called on every stage change and after respawning.
function Entity.reset(newMode)
	mode = newMode or mode
	caught = false
	show(false)
	stare = 0
	stillTime = 0
	path = {}
	huntActive = false
	doorFloorUsed = false
	showUntil = 0
	ctx.flashlightFlicker(0)
	ctx.Ambience.restoreAllLights()
	local feet = ground()
	if mode == "hunt" then
		trailReset(feet or Config.Places.CanteenDoor)
	elseif mode == "mineHunt" then
		mineSpawnDelay = 5
	elseif mode == "glimpse" then
		glimpseTimer = math.random(12, 25)
	end
end

function Entity.setMode(newMode)
	if newMode ~= mode then
		Entity.reset(newMode)
	end
end

-- Stand somewhere for a while (the canteen window). Vanishes if stared at.
function Entity.showAt(cf, duration)
	pos = cf.Position
	glimpseStare = 0
	showUntil = os.clock() + duration
	show(true)
end

function Entity.isCaught()
	return caught
end

return Entity
