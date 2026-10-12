-- Norilsk: Last Shift. Server: builds the world and walks each player through the shift.
-- The entity itself runs on each player's client (it hunts every player separately);
-- the server decides stages, checkpoints and what happens when it catches you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Town = require(script.Parent.Town)
local Mine = require(script.Parent.Mine)
local Canteen = require(script.Parent.Canteen)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local fxRemote = Instance.new("RemoteEvent")
fxRemote.Name = "Fx"
fxRemote.Parent = remotes
local caughtRemote = Instance.new("RemoteEvent")
caughtRemote.Name = "Caught"
caughtRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

-- Build the world. Clear the default baseplate if the place has one.
for _, name in { "Baseplate", "SpawnLocation" } do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
local world = Instance.new("Folder")
world.Name = "Norilsk"
world.Parent = workspace
local spots = {}
for _, builder in { Town, Mine, Canteen } do
	for k, v in builder.build(world) do
		spots[k] = v
	end
end
local ready = Instance.new("BoolValue")
ready.Name = "WorldReady"
ready.Value = true
ready.Parent = ReplicatedStorage

Players.RespawnTime = 2

local states = {}

local function fx(player, kind, ...)
	fxRemote:FireClient(player, kind, ...)
end

local function root(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleport(player, cf)
	local character = player.Character
	local r = root(player)
	if character and r and cf then
		character:PivotTo(cf)
		r.AssemblyLinearVelocity = Vector3.zero
	end
end

local function spotFor(stage)
	return spots[Config.Stages[stage].spot] or spots.aptStart
end

local function setStage(player, stage)
	local st = states[player]
	if not st then
		return
	end
	st.stage = stage
	player:SetAttribute("Stage", stage)
end

local function clearProgress(player, st)
	st.seams = {}
	player:SetAttribute("SeamCount", 0)
	player:SetAttribute("SeamsDone", "")
	player:SetAttribute("HasLamp", false)
end

-- Fade to black with a line of text, move the player, then fade back in.
local function transition(player, text, cf, nextStage, hold)
	local st = states[player]
	if not st or st.busy then
		return
	end
	st.busy = true
	fx(player, "fade", text, hold or 2)
	task.wait(0.9)
	if states[player] ~= st then
		return
	end
	if cf then
		teleport(player, cf)
	end
	if nextStage then
		setStage(player, nextStage)
	end
	task.wait(hold or 2)
	st.busy = false
end

local function list(set)
	local out = {}
	for k in set do
		table.insert(out, tostring(k))
	end
	return table.concat(out, ",")
end

local actions = {}

actions.leaveHome = function(player, st)
	if st.stage == 1 then
		transition(player, "06:10. Минус сорок один.\nThe stairwell smells of cabbage and frost.", spots.homeDoorOut, 2, 2.5)
	elseif st.stage == Config.FinalStage then
		fx(player, "say", "Not again. Not tonight.")
	end
end

actions.clockIn = function(player, st)
	if st.stage == 2 then
		setStage(player, 3)
		fx(player, "say", "The time clock bites your card. 06:31. The watchman does not look up.")
	end
end

actions.lamp = function(player, st)
	if st.stage == 3 then
		setStage(player, 4)
		player:SetAttribute("HasLamp", true)
		fx(player, "say", "Lamp No. 116. The attendant won't let go of it for a moment. \"Bring it back,\" she says.")
	end
end

actions.cageDown = function(player, st)
	if st.stage == 4 then
		transition(player, "The cage drops for four minutes.\nHorizon −300.", spots.ugLanding, 5, 2.5)
	elseif st.stage < 4 then
		fx(player, "say", "Not without a lamp. Check in, then get your lamp.")
	end
end

actions.seam = function(player, st, prompt)
	if st.stage ~= 5 then
		return
	end
	local n = prompt:GetAttribute("Seam")
	if not n or st.seams[n] then
		return
	end
	st.seams[n] = true
	local count = 0
	for _ in st.seams do
		count += 1
	end
	player:SetAttribute("SeamsDone", list(st.seams))
	player:SetAttribute("SeamCount", count)
	if count >= Config.SeamCount then
		fx(player, "say", "The quota is met. Somewhere behind you, the lamps begin to go out.")
		task.delay(1.5, function()
			if states[player] == st and st.stage == 5 then
				setStage(player, 6)
			end
		end)
	else
		fx(player, "say", ("Seam %d done. %d of %d."):format(n, count, Config.SeamCount))
	end
end

actions.cageUp = function(player, st)
	if st.stage == 6 then
		transition(player, "The cage rises out of the dark.\n18:20. The shift is over.", spots.cageTop, 7, 2.5)
	elseif st.stage == 5 then
		fx(player, "say", "Not until the quota is met. Five seams.")
	end
end

actions.coupon = function(player, st)
	if st.stage == 7 then
		setStage(player, 8)
		fx(player, "say", "The cashier tears your coupon without a word. Your tray is at the corner table by the wall.")
	end
end

actions.eat = function(player, st)
	if st.stage == 8 then
		transition(player, "You eat slowly. Too slowly.\nWhen you look up, the clock says 23:10.\nEveryone is gone.", nil, 9, 3.5)
	end
end

actions.unlock = function(player, st)
	if st.stage ~= 9 then
		if st.stage < 9 and st.stage > 1 then
			fx(player, "say", "Home is for tonight. The shift comes first.")
		end
		return
	end
	transition(player, "", spots.aptEnd, Config.FinalStage, 0.5)
	fx(player, "ending")
	task.delay(45, function()
		if states[player] == st and st.stage == Config.FinalStage then
			clearProgress(player, st)
			st.day += 1
			player:SetAttribute("Day", st.day)
			transition(player, ("Day %d.\nThe alarm rings at 05:50."):format(st.day), spots.aptStart, 1, 2.5)
		end
	end)
end

actions.note = function(player, st, prompt)
	local id = prompt:GetAttribute("NoteId")
	if not id or not Config.Notes[id] then
		return
	end
	if not st.notes[id] then
		st.notes[id] = true
		local count = 0
		for _ in st.notes do
			count += 1
		end
		player:SetAttribute("NotesFound", list(st.notes))
		player:SetAttribute("NoteCount", count)
	end
	fx(player, "note", id)
end

local function wire(prompt)
	prompt.Triggered:Connect(function(player)
		local st = states[player]
		local r = root(player)
		local part = prompt.Parent
		if not st or st.busy or not r or not part:IsA("BasePart") then
			return
		end
		if (r.Position - part.Position).Magnitude > prompt.MaxActivationDistance + 8 then
			return
		end
		local handler = actions[prompt:GetAttribute("Action")]
		if handler then
			handler(player, st, prompt)
		end
	end)
end
for _, prompt in CollectionService:GetTagged("StagePrompt") do
	wire(prompt)
end

caughtRemote.OnServerEvent:Connect(function(player)
	local st = states[player]
	if not st or st.busy then
		return
	end
	local threat = Config.Stages[st.stage].threat
	if threat ~= "hunt" and threat ~= "mineHunt" then
		return
	end
	if os.clock() - st.lastCaught < 5 then
		return
	end
	st.lastCaught = os.clock()
	st.busy = true
	task.wait(2.6)
	if states[player] ~= st then
		return
	end
	teleport(player, spotFor(st.stage))
	fx(player, "respawn")
	st.busy = false
end)

local function onCharacter(player, character)
	local st = states[player]
	local humanoid = character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	humanoid.WalkSpeed = Config.WalkSpeed
	task.wait()
	if st and states[player] == st then
		st.busy = false
		teleport(player, spotFor(st.stage))
		fx(player, "respawn")
	end
end

Players.PlayerAdded:Connect(function(player)
	local st = { stage = 1, seams = {}, notes = {}, busy = false, lastCaught = 0, day = 1 }
	states[player] = st
	clearProgress(player, st)
	player:SetAttribute("Stage", 1)
	player:SetAttribute("Day", 1)
	player:SetAttribute("NoteCount", 0)
	player:SetAttribute("NotesFound", "")
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	-- Testing shortcut in Studio: type "/stage 9" in chat.
	if RunService:IsStudio() then
		player.Chatted:Connect(function(message)
			local n = tonumber(message:match("^/stage%s+(%d+)"))
			if n and Config.Stages[n] then
				st.busy = false
				if n >= 6 then
					for i = 1, Config.SeamCount do
						st.seams[i] = true
					end
					player:SetAttribute("SeamsDone", list(st.seams))
					player:SetAttribute("SeamCount", Config.SeamCount)
				else
					clearProgress(player, st)
				end
				player:SetAttribute("HasLamp", n >= 4)
				setStage(player, n)
				teleport(player, spotFor(n))
				fx(player, "respawn")
			end
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)
