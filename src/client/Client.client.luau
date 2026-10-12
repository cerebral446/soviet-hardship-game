-- Norilsk: Last Shift. Client entry point.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
ReplicatedStorage:WaitForChild("WorldReady")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Ui = require(script.Parent.Ui)
local Audio = require(script.Parent.Audio)
local Ambience = require(script.Parent.Ambience)
local People = require(script.Parent.People)
local Entity = require(script.Parent.Entity)

player.CameraMode = Enum.CameraMode.LockFirstPerson
workspace.CurrentCamera.FieldOfView = 72
for _, kind in { Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health, Enum.CoreGuiType.EmotesMenu } do
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, kind, false)
end

Ui.init()
Ui.black("")

-- Flashlight: a pocket torch at first, the helmet lamp once you have collected it.
local lamp = Instance.new("Part")
lamp.Name = "Flashlight"
lamp.Anchored = true
lamp.CanCollide = false
lamp.CanQuery = false
lamp.CanTouch = false
lamp.Transparency = 1
lamp.Size = Vector3.new(0.2, 0.2, 0.2)
lamp.Parent = workspace
local beam = Instance.new("SpotLight")
beam.Face = Enum.NormalId.Front
beam.Shadows = true
beam.Color = Color3.fromRGB(255, 226, 180)
beam.Enabled = false
beam.Parent = lamp
local lampOn = false
local flicker = 0
local introPlaying = true

local function lampStats()
	if player:GetAttribute("HasLamp") then
		return 60, 2.4, 62
	end
	return 38, 1.5, 44
end

local function setLamp(on)
	lampOn = on
	beam.Enabled = on
	Audio.play("Click")
end

-- Sprinting.
local stamina = 1
local exhausted = false
local sprintHeld = false
local sprinting = false
local frozen = false

-- Camera shake and head bob go through Humanoid.CameraOffset.
local shakeUntil, shakeStrength = 0, 0
local bobT = 0

local ctx = {
	Ui = Ui,
	Ambience = Ambience,
	People = People,
	Entity = Entity,
}
function ctx.isSprinting()
	return sprinting
end
function ctx.shake(duration, strength)
	shakeUntil = os.clock() + duration
	shakeStrength = strength
end
function ctx.freeze(on)
	frozen = on
end
function ctx.flashlightFlicker(level)
	flicker = level
end

Ambience.init(ctx)
People.init()
Entity.init(ctx)

-- Prompts only show when they matter.
local PROMPT_STAGE = { leaveHome = 1, clockIn = 2, lamp = 3, cageDown = 4, seam = 5, cageUp = 6, coupon = 7, eat = 8, unlock = 9 }
local function refreshPrompts()
	local stage = player:GetAttribute("Stage") or 1
	for _, prompt in CollectionService:GetTagged("StagePrompt") do
		local action = prompt:GetAttribute("Action")
		local want = PROMPT_STAGE[action]
		if action == "note" then
			prompt.Enabled = true
			local found = string.find("," .. (player:GetAttribute("NotesFound") or "") .. ",", "," .. tostring(prompt:GetAttribute("NoteId")) .. ",", 1, true)
			prompt.ActionText = found and "Read again" or "Read"
		elseif action == "seam" then
			prompt.Enabled = stage == 5 and not prompt:GetAttribute("Done")
		elseif action == "cageDown" then
			prompt.Enabled = stage >= 2 and stage <= 4
		elseif action == "cageUp" then
			prompt.Enabled = stage == 5 or stage == 6
		elseif want then
			prompt.Enabled = stage == want
		end
	end
end

local lastStage = 0
local function onStage()
	local stage = player:GetAttribute("Stage") or 1
	local data = Config.Stages[stage]
	if stage == 5 then
		local count = player:GetAttribute("SeamCount") or 0
		Ui.setObjective(("%s · %d / %d"):format(data.ru, count, Config.SeamCount), data.en)
	else
		Ui.setObjective(data.ru, data.en)
	end
	Ui.setClock(("НОРИЛЬСК · 12 ДЕКАБРЯ 1984 · %s · −41 °C"):format(data.clock))
	Ambience.onStage(stage)
	People.onStage(stage)
	Entity.setMode(data.threat)
	refreshPrompts()
	-- Inner voice at key moments.
	if stage ~= lastStage then
		if stage == 6 then
			task.delay(2, function()
				Ui.say("The lamps are going out, one by one, from the far end. Something is walking in the dark. Get to the cage.", 7)
			end)
			setLamp(true)
		elseif stage == 9 then
			task.delay(4, function()
				Ui.say("No one on the street. No one at all. Don't stop walking. If you must look back — don't look for long.", 8)
			end)
		elseif stage == 2 and lastStage == 1 then
			task.delay(3, function()
				Ui.say("Others from the block are already trudging to the mine. Follow them north.", 6)
			end)
		end
	end
	lastStage = stage
end
player:GetAttributeChangedSignal("Stage"):Connect(onStage)
player:GetAttributeChangedSignal("SeamCount"):Connect(onStage)
player:GetAttributeChangedSignal("SeamsDone"):Connect(function()
	Ambience.updateSeams(player:GetAttribute("SeamsDone"))
	refreshPrompts()
end)
player:GetAttributeChangedSignal("NotesFound"):Connect(refreshPrompts)
player:GetAttributeChangedSignal("NoteCount"):Connect(function()
	Ui.setNotes(player:GetAttribute("NoteCount") or 0, #Config.Notes)
end)
player:GetAttributeChangedSignal("HasLamp"):Connect(function()
	if player:GetAttribute("HasLamp") then
		Ui.hint("F — helmet lamp · Shift — run · E — interact")
	end
end)

-- Ending: you are home. Something knocks.
local function ending()
	local door = Config.Places.Apartment + Vector3.new(8, 4, 9.6)
	task.wait(2)
	Ui.say("The latch catches. You are home.", 4)
	task.wait(6)
	for _ = 1, 3 do
		Audio.at("Knock", door, { range = 60 })
		task.wait(0.8)
	end
	Ui.say("тук.   тук.   тук.", 3)
	task.wait(5)
	for _ = 1, 3 do
		Audio.at("Knock", door, { range = 60, volume = 3.5 })
		task.wait(0.6)
	end
	Ui.say("«Товарищ. Ты не сдал лампу.»\n\"Comrade. You did not return your lamp.\"", 6)
	task.wait(7)
	Ui.static(0.4, 0.6)
	local notes = player:GetAttribute("NoteCount") or 0
	Ui.toBlack(2, ("КОНЕЦ СМЕНЫ · END OF SHIFT\n\nYou survived day %d.\nNotes found: %d / %d\n\nThe alarm will ring at 05:50."):format(player:GetAttribute("Day") or 1, notes, #Config.Notes))
	task.wait(10)
end

Remotes.Fx.OnClientEvent:Connect(function(kind, a, b)
	if kind == "fade" then
		task.spawn(Ui.fade, a, b)
	elseif kind == "say" then
		Ui.say(a)
	elseif kind == "note" then
		local note = Config.Notes[a]
		if note then
			Ui.showNote(note)
			Audio.play("Click", { pitch = 1.2 })
		end
	elseif kind == "respawn" then
		frozen = false
		if not introPlaying then
			Ui.fadeIn(1.2)
		end
		Entity.reset()
		onStage()
	elseif kind == "ending" then
		task.spawn(ending)
	end
end)

-- Input.
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		sprintHeld = true
	end
	if processed then
		return
	end
	if Ui.noteOpen() and (input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Q) then
		Ui.hideNote()
	elseif input.KeyCode == Enum.KeyCode.F then
		setLamp(not lampOn)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		sprintHeld = false
	end
end)

-- Per-frame: lamp follows the camera, stamina, bob, shake.
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local range, brightness, angle = lampStats()
	local hasLamp = player:GetAttribute("HasLamp")
	lamp.CFrame = camera.CFrame * (hasLamp and CFrame.new(0, 0.4, 0) or CFrame.new(0.7, -0.6, 0))
	beam.Range = range
	beam.Angle = angle
	local level = brightness
	if flicker > 0 and math.random() < flicker * 0.6 then
		level = brightness * math.random() * 0.4
	end
	beam.Brightness = level
	-- The helmet lamp comes on by itself underground.
	if hasLamp and not lampOn and Ambience.region() == "underground" and not beam:GetAttribute("AutoDone") then
		beam:SetAttribute("AutoDone", true)
		setLamp(true)
	end

	if not humanoid then
		return
	end
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	sprinting = sprintHeld and moving and not exhausted and not frozen
	if sprinting then
		stamina -= dt / Config.StaminaSeconds
		if stamina <= 0 then
			stamina = 0
			exhausted = true
		end
	else
		stamina = math.min(1, stamina + dt / Config.StaminaRegen)
		if exhausted and stamina > 0.35 then
			exhausted = false
		end
	end
	Ui.stamina(stamina)
	if frozen then
		humanoid.WalkSpeed = 0
	else
		humanoid.WalkSpeed = sprinting and Config.SprintSpeed or (exhausted and Config.WalkSpeed * 0.75 or Config.WalkSpeed)
	end

	local offset = Vector3.zero
	if moving and not frozen then
		bobT += dt * (sprinting and 13 or 8.5)
		local amp = sprinting and 0.22 or 0.11
		offset += Vector3.new(math.cos(bobT * 0.5) * amp * 0.6, math.abs(math.sin(bobT)) * amp, 0)
	end
	if os.clock() < shakeUntil then
		local s = shakeStrength * (shakeUntil - os.clock())
		offset += Vector3.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0)
	end
	humanoid.CameraOffset = humanoid.CameraOffset:Lerp(offset, math.min(dt * 12, 1))
end)

-- Reset the lamp auto-on flag when you leave the mine.
task.spawn(function()
	while true do
		task.wait(1)
		if Ambience.region() ~= "underground" then
			beam:SetAttribute("AutoDone", nil)
		end
	end
end)

-- Opening.
if not player.Character then
	player.CharacterAdded:Wait()
end
onStage()
Ui.setNotes(player:GetAttribute("NoteCount") or 0, #Config.Notes)
Ui.hint("F — flashlight · Shift — run · E — interact")
Ui.intro({
	"НОРИЛЬСК, КРАСНОЯРСКИЙ КРАЙ\nNorilsk, Krasnoyarsk Krai",
	"12 ДЕКАБРЯ 1984 · ПОЛЯРНАЯ НОЧЬ\n12 December 1984 · the polar night",
	"The sun will not rise for another five weeks.",
	"You are a miner at Mine No. 6.\nThe shift begins at 06:30.",
}, Config.Title, Config.TitleEnglish)
introPlaying = false
Ui.say("Five-fifty. The radiator is barely warm. Read Mother's letter, then go.", 6)
