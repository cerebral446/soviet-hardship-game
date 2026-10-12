-- Small helpers for building the world out of parts.

local CollectionService = game:GetService("CollectionService")

local Build = {}

function Build.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function toCFrame(at)
	if typeof(at) == "Vector3" then
		return CFrame.new(at)
	end
	return at
end

local function setup(p, parent, name, size, at, color, material)
	p.Name = name
	p.Size = size
	p.CFrame = toCFrame(at)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color or Color3.fromRGB(120, 120, 118)
	p.Material = material or Enum.Material.Concrete
	p.Parent = parent
	return p
end

function Build.block(parent, name, size, at, color, material)
	return setup(Instance.new("Part"), parent, name, size, at, color, material)
end

function Build.wedge(parent, name, size, at, color, material)
	return setup(Instance.new("WedgePart"), parent, name, size, at, color, material)
end

-- A cylinder whose axis runs along the CFrame's X axis.
function Build.cylinder(parent, name, length, diameter, at, color, material)
	local p = setup(Instance.new("Part"), parent, name, Vector3.new(length, diameter, diameter), at, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- A cylinder standing upright, base at `base`.
function Build.column(parent, name, height, diameter, base, color, material)
	return Build.cylinder(parent, name, height, diameter, CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), color, material)
end

-- CFrame at `from` looking at `to`; safe when the direction is straight up or down.
function Build.look(from, to)
	local dir = to - from
	if dir.Magnitude > 0 and math.abs(dir.Unit.Y) > 0.99 then
		-- Straight up or down: lookAt would be degenerate, so tip the Z axis explicitly.
		return CFrame.new(from) * CFrame.Angles(dir.Y > 0 and math.pi / 2 or -math.pi / 2, 0, 0)
	end
	return CFrame.lookAt(from, to)
end

-- A cylinder between two points.
function Build.pipe(parent, name, a, b, diameter, color, material)
	local length = (b - a).Magnitude
	local cf = Build.look((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
	return Build.cylinder(parent, name, length, diameter, cf, color, material)
end

-- A block stretched between two points (beams, cables, rails).
function Build.beam(parent, name, a, b, thickness, color, material)
	local length = (b - a).Magnitude
	return Build.block(parent, name, Vector3.new(thickness, thickness, length), Build.look((a + b) / 2, b), color, material)
end

function Build.ball(parent, name, diameter, at, color, material)
	local p = setup(Instance.new("Part"), parent, name, Vector3.new(diameter, diameter, diameter), at, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Decorative: no collisions, no shadow, ignored by raycasts.
function Build.detail(p)
	p.CanCollide = false
	p.CastShadow = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

function Build.tag(instance, tag)
	CollectionService:AddTag(instance, tag)
	return instance
end

function Build.light(parent, color, range, brightness, shadows)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.fromRGB(255, 190, 120)
	l.Range = range or 16
	l.Brightness = brightness or 1
	l.Shadows = shadows or false
	l.Parent = parent
	return l
end

function Build.surfaceLight(parent, face, color, range, brightness, angle)
	local l = Instance.new("SurfaceLight")
	l.Face = face
	l.Color = color
	l.Range = range or 16
	l.Brightness = brightness or 1
	l.Angle = angle or 120
	l.Parent = parent
	return l
end

-- Text on one face of a part.
function Build.sign(part, face, text, opts)
	opts = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.ppS or 40
	gui.LightInfluence = opts.lightInfluence or 1
	gui.Brightness = opts.brightness or 1
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = opts.bg or Color3.fromRGB(120, 28, 24)
	label.BackgroundTransparency = opts.bgTransparency or 0
	label.BorderSizePixel = 0
	label.TextColor3 = opts.fg or Color3.fromRGB(232, 220, 186)
	label.Font = opts.font or Enum.Font.Oswald
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = opts.align or Enum.TextXAlignment.Center
	label.Text = text
	label.Parent = gui
	if opts.padding then
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(opts.padding, 0)
		pad.PaddingRight = UDim.new(opts.padding, 0)
		pad.PaddingTop = UDim.new(opts.padding, 0)
		pad.PaddingBottom = UDim.new(opts.padding, 0)
		pad.Parent = label
	end
	return gui, label
end

-- A constructivist propaganda poster. `design` comes from Config.Posters.
-- Facing: the poster's front face is the CFrame's LookVector.
function Build.poster(parent, at, design, size)
	size = size or Vector2.new(5, 7)
	local part = Build.detail(Build.block(parent, "Poster", Vector3.new(size.X, size.Y, 0.12), at, design.bg, Enum.Material.SmoothPlastic))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 1
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = design.bg
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Parent = gui
	local band = Instance.new("Frame")
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.42)
	band.Size = UDim2.fromScale(1.8, 0.16)
	band.Rotation = -24
	band.BackgroundColor3 = design.fg
	band.BackgroundTransparency = 0.25
	band.BorderSizePixel = 0
	band.Parent = bg
	local star = Instance.new("TextLabel")
	star.Name = "Star"
	star.BackgroundTransparency = 1
	star.Position = UDim2.fromScale(0.05, 0.03)
	star.Size = UDim2.fromScale(0.9, 0.42)
	star.Text = "★"
	star.TextScaled = true
	star.TextColor3 = design.fg
	star.Font = Enum.Font.GothamBlack
	star.Parent = bg
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.06, 0.5)
	title.Size = UDim2.fromScale(0.88, 0.3)
	title.Text = design.title
	title.TextScaled = true
	title.TextWrapped = true
	title.TextColor3 = design.fg
	title.Font = Enum.Font.Oswald
	title.Parent = bg
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0.08, 0.82)
	sub.Size = UDim2.fromScale(0.84, 0.12)
	sub.Text = design.sub
	sub.TextScaled = true
	sub.TextWrapped = true
	sub.TextColor3 = design.fg
	sub.TextTransparency = 0.15
	sub.Font = Enum.Font.Oswald
	sub.Parent = bg
	part:SetAttribute("NightTitle", design.night)
	part:SetAttribute("NightSub", design.nightSub)
	part:SetAttribute("DayTitle", design.title)
	part:SetAttribute("DaySub", design.sub)
	Build.tag(part, "Poster")
	return part
end

-- A stage interaction. Game.server wires every tagged prompt.
function Build.interact(part, action, actionText, objectText, hold, extra)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText or ""
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Action", action)
	if extra then
		for k, v in extra do
			prompt:SetAttribute(k, v)
		end
	end
	prompt.Parent = part
	Build.tag(prompt, "StagePrompt")
	return prompt
end

-- A scrap of paper with a lore note on it.
function Build.note(parent, id, at)
	local paper = Build.detail(Build.block(parent, "Note", Vector3.new(1.1, 0.05, 1.5), at, Color3.fromRGB(226, 216, 186), Enum.Material.SmoothPlastic))
	paper.CanQuery = true
	local prompt = Build.interact(paper, "note", "Read", "Note", 0, { NoteId = id })
	prompt.MaxActivationDistance = 7
	Build.light(paper, Color3.fromRGB(255, 230, 190), 4, 0.35)
	return paper
end

-- A wall split into solid pieces around openings.
-- a, b: ends of the wall's inner face line (on the floor). out: unit vector pointing out of the room.
-- gaps: list of { at = distance from a, width = w, bottom = y (default 0), top = y (default height) }.
function Build.wall(parent, a, b, out, height, thickness, gaps, color, material, name)
	thickness = thickness or 1
	local dir = (b - a).Unit
	local length = (b - a).Magnitude
	local pieces = {}
	local function piece(s0, s1, y0, y1)
		if s1 - s0 < 0.05 or y1 - y0 < 0.05 then
			return
		end
		local mid = a + dir * ((s0 + s1) / 2) + out * (thickness / 2) + Vector3.new(0, (y0 + y1) / 2, 0)
		local p = Build.block(parent, name or "Wall", Vector3.new(thickness, y1 - y0, s1 - s0), CFrame.lookAt(mid, mid + dir), color, material)
		table.insert(pieces, p)
	end
	table.sort(gaps or {}, function(x, y)
		return x.at < y.at
	end)
	local cursor = 0
	for _, gap in gaps or {} do
		local g0, g1 = gap.at - gap.width / 2, gap.at + gap.width / 2
		piece(cursor, g0, 0, height)
		piece(g0, g1, 0, gap.bottom or 0)
		piece(g0, g1, gap.top or height, height)
		cursor = g1
	end
	piece(cursor, length, 0, height)
	return pieces
end

return Build
