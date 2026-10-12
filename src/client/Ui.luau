-- On-screen interface: objective, clock, subtitles, fades, notes, stamina and effects.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Ui = {}

local rgb = Color3.fromRGB
local PAPER = rgb(226, 218, 194)
local INK = rgb(214, 208, 190)

local gui
local objectiveRu, objectiveEn, clockLabel, notesLabel, sayLabel, hintLabel
local fadeFrame, fadeText, flashFrame, staticFrame
local noteFrame, noteTitle, noteBody
local staminaBack, staminaFill
local sayToken = 0

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function text(parent, props)
	local base = {
		BackgroundTransparency = 1,
		TextColor3 = INK,
		Font = Enum.Font.Code,
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	local label = make("TextLabel", base, parent)
	make("UIStroke", { Thickness = 1, Transparency = 0.55, Color = rgb(0, 0, 0) }, label)
	return label
end

local function tween(inst, time, goal, style)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Sine), goal)
	t:Play()
	return t
end

function Ui.init()
	local player = Players.LocalPlayer
	gui = make("ScreenGui", { Name = "LastShift", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5 }, player:WaitForChild("PlayerGui"))

	-- Vignette: dark edges.
	for _, side in { { 0, 0.5, 0.5, 1, 0 }, { 1, 0.5, 0.5, 1, 180 }, { 0.5, 0, 1, 0.5, 90 }, { 0.5, 1, 1, 0.5, 270 } } do
		local f = make("Frame", {
			AnchorPoint = Vector2.new(side[1], side[2]),
			Position = UDim2.fromScale(side[1], side[2]),
			Size = UDim2.fromScale(side[3], side[4]),
			BackgroundColor3 = rgb(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, gui)
		make("UIGradient", {
			Rotation = side[5],
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(0.45, 0.85),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, f)
	end

	clockLabel = text(gui, { Position = UDim2.new(0, 28, 0, 28), Size = UDim2.new(0, 520, 0, 22), TextSize = 16, TextTransparency = 0.15, ZIndex = 3 })
	objectiveRu = text(gui, { Position = UDim2.new(0, 28, 0, 54), Size = UDim2.new(0.6, 0, 0, 30), TextSize = 24, Font = Enum.Font.Oswald, ZIndex = 3 })
	objectiveEn = text(gui, { Position = UDim2.new(0, 28, 0, 86), Size = UDim2.new(0.5, 0, 0, 44), TextSize = 16, TextTransparency = 0.2, ZIndex = 3 })
	notesLabel = text(gui, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 28), Size = UDim2.new(0, 260, 0, 22), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = 0.3, ZIndex = 3 })
	sayLabel = text(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -70),
		Size = UDim2.new(0.62, 0, 0, 64),
		TextSize = 19,
		Font = Enum.Font.Merriweather,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextTransparency = 1,
		ZIndex = 4,
	})
	hintLabel = text(gui, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 28, 1, -24), Size = UDim2.new(0, 520, 0, 20), TextSize = 14, TextTransparency = 0.45, ZIndex = 3 })

	staminaBack = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.new(0, 220, 0, 4), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.6, BorderSizePixel = 0, Visible = false, ZIndex = 3 }, gui)
	staminaFill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3 }, staminaBack)

	flashFrame = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(140, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8 }, gui)
	staticFrame = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 9, Visible = false }, gui)
	for _ = 1, 40 do
		make("Frame", { BackgroundColor3 = rgb(230, 230, 230), BorderSizePixel = 0, BackgroundTransparency = 0.5, ZIndex = 9 }, staticFrame)
	end

	fadeFrame = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 10 }, gui)
	fadeText = text(fadeFrame, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.7, 0, 0.6, 0),
		TextSize = 24,
		Font = Enum.Font.Merriweather,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = 1,
		ZIndex = 11,
	})

	noteFrame = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 520, 0, 560), BackgroundColor3 = PAPER, BorderSizePixel = 0, Visible = false, ZIndex = 12, Rotation = -1.5 }, gui)
	make("UIPadding", { PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 30), PaddingTop = UDim.new(0, 26), PaddingBottom = UDim.new(0, 26) }, noteFrame)
	make("UISizeConstraint", { MaxSize = Vector2.new(520, 560) }, noteFrame)
	noteTitle = make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Font = Enum.Font.Oswald, TextSize = 22, TextColor3 = rgb(120, 24, 20), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 13 }, noteFrame)
	noteBody = make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 1, -80), Font = Enum.Font.SpecialElite, TextSize = 17, TextColor3 = rgb(40, 34, 28), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 13 }, noteFrame)
	make("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.Code, TextSize = 14, TextColor3 = rgb(110, 100, 86), Text = "[E] / [Esc] / click — put it away", TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 13 }, noteFrame)
	local closer = make("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 14 }, noteFrame)
	closer.Activated:Connect(function()
		Ui.hideNote()
	end)
end

function Ui.setObjective(ru, en)
	objectiveRu.Text = ru or ""
	objectiveEn.Text = en or ""
	objectiveRu.TextTransparency = 1
	objectiveEn.TextTransparency = 1
	tween(objectiveRu, 1.2, { TextTransparency = 0 })
	tween(objectiveEn, 1.6, { TextTransparency = 0.2 })
end

function Ui.setClock(s)
	clockLabel.Text = s
end

function Ui.setNotes(n, total)
	notesLabel.Text = n > 0 and ("ЗАПИСКИ · NOTES  %d / %d"):format(n, total) or ""
end

function Ui.hint(s)
	hintLabel.Text = s or ""
end

-- A line of subtitle / thought at the bottom of the screen.
function Ui.say(s, duration)
	sayToken += 1
	local token = sayToken
	sayLabel.Text = s
	tween(sayLabel, 0.4, { TextTransparency = 0 })
	task.delay(duration or math.clamp(#s / 14, 3, 9), function()
		if token == sayToken then
			tween(sayLabel, 1, { TextTransparency = 1 })
		end
	end)
end

function Ui.stamina(frac)
	staminaBack.Visible = frac < 0.995
	staminaFill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
	staminaFill.BackgroundColor3 = frac < 0.25 and rgb(170, 60, 50) or INK
end

-- Fade to black, show text, hold, fade back. Yields until fully back.
function Ui.fade(s, hold)
	fadeText.Text = s or ""
	tween(fadeFrame, 0.8, { BackgroundTransparency = 0 }).Completed:Wait()
	if s and s ~= "" then
		tween(fadeText, 0.6, { TextTransparency = 0 })
	end
	task.wait(hold or 2)
	tween(fadeText, 0.6, { TextTransparency = 1 })
	task.wait(0.3)
	tween(fadeFrame, 1.2, { BackgroundTransparency = 1 }).Completed:Wait()
end

function Ui.black(s)
	fadeText.Text = s or ""
	fadeFrame.BackgroundTransparency = 0
	fadeText.TextTransparency = (s and s ~= "") and 0 or 1
end

function Ui.toBlack(time, s)
	fadeText.Text = s or ""
	fadeText.TextTransparency = 1
	tween(fadeFrame, time or 1, { BackgroundTransparency = 0 }).Completed:Wait()
	if s and s ~= "" then
		tween(fadeText, 0.8, { TextTransparency = 0 })
	end
end

function Ui.fadeIn(time)
	tween(fadeText, 0.5, { TextTransparency = 1 })
	tween(fadeFrame, time or 1.2, { BackgroundTransparency = 1 })
end

function Ui.redFlash()
	flashFrame.BackgroundTransparency = 0.2
	tween(flashFrame, 0.9, { BackgroundTransparency = 1 })
end

-- TV static bursts.
function Ui.static(duration, strength)
	strength = strength or 0.5
	staticFrame.Visible = true
	local stop = os.clock() + (duration or 0.2)
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if os.clock() > stop then
			staticFrame.Visible = false
			conn:Disconnect()
			return
		end
		for _, line in staticFrame:GetChildren() do
			line.Position = UDim2.fromScale(math.random(), math.random())
			line.Size = UDim2.new(math.random() * 0.6, 0, 0, math.random(1, 6))
			line.BackgroundTransparency = 1 - strength * math.random()
		end
	end)
end

function Ui.showNote(note)
	noteTitle.Text = note.title
	noteBody.Text = note.text
	noteFrame.Visible = true
end

function Ui.hideNote()
	noteFrame.Visible = false
end

function Ui.noteOpen()
	return noteFrame.Visible
end

function Ui.missing()
	Ui.black("")
	fadeText.Font = Enum.Font.Oswald
	fadeText.TextColor3 = rgb(180, 30, 26)
	fadeText.Text = "ПРОПАЛ БЕЗ ВЕСТИ\nMISSING"
	fadeText.TextTransparency = 1
	tween(fadeText, 1, { TextTransparency = 0 })
	task.delay(2.5, function()
		fadeText.Font = Enum.Font.Merriweather
		fadeText.TextColor3 = INK
	end)
end

-- Opening titles. Yields.
function Ui.intro(lines, title, subtitle)
	Ui.black("")
	task.wait(1)
	for _, line in lines do
		fadeText.Text = line
		tween(fadeText, 1, { TextTransparency = 0 }).Completed:Wait()
		task.wait(1.8)
		tween(fadeText, 0.8, { TextTransparency = 1 }).Completed:Wait()
	end
	fadeText.Font = Enum.Font.Oswald
	fadeText.TextSize = 40
	fadeText.TextColor3 = rgb(200, 40, 32)
	fadeText.Text = title .. "\n" .. subtitle
	tween(fadeText, 1.5, { TextTransparency = 0 }).Completed:Wait()
	task.wait(2.5)
	tween(fadeText, 1, { TextTransparency = 1 }).Completed:Wait()
	fadeText.Font = Enum.Font.Merriweather
	fadeText.TextSize = 24
	fadeText.TextColor3 = INK
	Ui.fadeIn(2)
end

return Ui
