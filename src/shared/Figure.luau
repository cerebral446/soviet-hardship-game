-- Builds a person out of parts: miners, diners, canteen staff, people on the street.
-- Limbs are grouped around joints so the client can animate them (see client/Rig.luau).
-- The model's pivot is on the ground (or floor) under the person, facing its LookVector.

local Build = require(script.Parent.Build)

local Figure = {}

local rgb = Color3.fromRGB
local SKIN = { rgb(226, 190, 160), rgb(214, 172, 138), rgb(232, 204, 180), rgb(198, 160, 128) }
local COATS = { rgb(62, 64, 60), rgb(74, 66, 56), rgb(48, 52, 58), rgb(86, 78, 64), rgb(58, 62, 70), rgb(40, 40, 40) }
local PANTS = { rgb(38, 38, 42), rgb(50, 48, 46), rgb(30, 34, 40) }
local KERCHIEFS = { rgb(150, 40, 40), rgb(60, 90, 140), rgb(200, 170, 90), rgb(110, 60, 90) }

Figure.Coats = COATS

local function pick(list, rng)
	return list[rng:NextInteger(1, #list)]
end

-- opts: pose ("stand"|"sit"), hat, held, coat, pants, skin, armR, armL (rest angles in degrees,
-- 0 = hanging, 90 = pointing forward), action (animation name for the client), seed, name.
function Figure.build(parent, pivot, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or math.random(1, 1e6))
	local model = Instance.new("Model")
	model.Name = opts.name or "Person"
	local coat = opts.coat or pick(COATS, rng)
	local pants = opts.pants or pick(PANTS, rng)
	local skin = opts.skin or pick(SKIN, rng)
	local seated = opts.pose == "sit"
	local seatH = opts.seatHeight or 1.9

	local root = Build.block(model, "Root", Vector3.new(1, 1, 1), pivot, coat)
	root.Transparency = 1
	Build.detail(root)
	model.PrimaryPart = root

	local function part(name, size, rel, color, material, group)
		local p = Build.detail(Build.block(model, name, size, pivot * rel, color, material or Enum.Material.Fabric))
		if group then
			p:SetAttribute("Group", group)
		end
		return p
	end
	local function joint(name, rel)
		model:SetAttribute("Joint_" .. name, rel)
	end

	-- Legs
	for i, side in { -1, 1 } do
		local g = i == 1 and "LegL" or "LegR"
		if seated then
			local hip = CFrame.new(side * 0.5, seatH + 0.4, 0.2)
			joint(g, hip)
			part("Thigh", Vector3.new(0.9, 0.8, 2.2), CFrame.new(side * 0.5, seatH + 0.4, -0.9), pants, nil, g)
			part("Shin", Vector3.new(0.85, seatH + 0.45, 0.9), CFrame.new(side * 0.5, (seatH + 0.45) / 2, -1.9), pants, nil, g)
			part("Boot", Vector3.new(1, 0.6, 1.3), CFrame.new(side * 0.5, 0.3, -2.1), rgb(28, 26, 24), Enum.Material.Leather, g)
		else
			joint(g, CFrame.new(side * 0.5, 2.8, 0))
			part("Leg", Vector3.new(0.9, 2.8, 0.9), CFrame.new(side * 0.5, 1.4, 0), pants, nil, g)
			part("Boot", Vector3.new(1, 0.7, 1.3), CFrame.new(side * 0.5, 0.35, -0.12), rgb(28, 26, 24), Enum.Material.Leather, g)
		end
	end

	local up = seated and Vector3.new(0, seatH + 0.1 - 2.8, 0.2) or Vector3.zero
	local function at(x, y, z)
		return CFrame.new(Vector3.new(x, y, z) + up)
	end

	part("Torso", Vector3.new(2.2, 2.7, 1.2), at(0, 4.15, 0), coat)
	part("CoatSkirt", Vector3.new(2.3, seated and 0.6 or 1, 1.3), at(0, seated and 2.9 or 2.45, 0), coat)
	part("Collar", Vector3.new(1.6, 0.35, 1.25), at(0, 5.45, 0), coat:Lerp(rgb(0, 0, 0), 0.25))

	-- Head and hat turn together around the neck.
	joint("Head", at(0, 5.5, 0))
	part("Head", Vector3.new(1.1, 1.2, 1.05), at(0, 6.1, 0), skin, Enum.Material.SmoothPlastic, "Head")
	for _, x in { -0.25, 0.25 } do
		part("Eye", Vector3.new(0.18, 0.12, 0.05), at(x, 6.22, -0.53), rgb(25, 22, 20), Enum.Material.SmoothPlastic, "Head")
	end
	part("Nose", Vector3.new(0.18, 0.3, 0.16), at(0, 6.02, -0.58), skin, Enum.Material.SmoothPlastic, "Head")
	local hat = opts.hat
	if hat == "ushanka" then
		local fur = rng:NextNumber() < 0.5 and rgb(70, 52, 38) or rgb(40, 38, 36)
		part("Hat", Vector3.new(1.35, 0.6, 1.3), at(0, 6.85, 0.02), fur, Enum.Material.Fabric, "Head")
		part("Hat", Vector3.new(1.4, 0.3, 0.3), at(0, 6.7, -0.62), fur, Enum.Material.Fabric, "Head")
		for _, x in { -0.72, 0.72 } do
			part("Hat", Vector3.new(0.2, 0.8, 0.95), at(x, 6.3, 0.05), fur, Enum.Material.Fabric, "Head")
		end
	elseif hat == "kerchief" then
		local c = pick(KERCHIEFS, rng)
		part("Hat", Vector3.new(1.25, 0.95, 1.2), at(0, 6.5, 0.08), c, Enum.Material.Fabric, "Head")
		part("Hat", Vector3.new(0.5, 0.4, 0.3), at(0, 5.75, -0.45), c, Enum.Material.Fabric, "Head")
	elseif hat == "chef" then
		part("Hat", Vector3.new(1.15, 0.9, 1.1), at(0, 7.05, 0), rgb(236, 236, 228), Enum.Material.Fabric, "Head")
	elseif hat == "helmet" then
		part("Hat", Vector3.new(1.35, 0.55, 1.45), at(0, 6.85, 0), rgb(40, 40, 38), Enum.Material.SmoothPlastic, "Head")
		local lamp = part("Hat", Vector3.new(0.45, 0.4, 0.2), at(0, 6.85, -0.78), rgb(255, 214, 140), Enum.Material.Neon, "Head")
		lamp.Name = "HelmetLamp"
	elseif hat == "cap" then
		part("Hat", Vector3.new(1.25, 0.35, 1.2), at(0, 6.85, 0.02), rgb(46, 52, 46), Enum.Material.Fabric, "Head")
		part("Hat", Vector3.new(1.2, 0.12, 0.6), at(0, 6.72, -0.7), rgb(30, 30, 30), Enum.Material.Leather, "Head")
	end

	-- Arms hang from the shoulders; rest angle rotates them forward.
	for i, side in { -1, 1 } do
		local g = i == 1 and "ArmL" or "ArmR"
		local rest = math.rad((i == 1 and opts.armL or opts.armR) or 0)
		local shoulder = at(side * 1.4, 5.2, 0)
		joint(g, shoulder)
		model:SetAttribute("Rest_" .. g, rest)
		local bent = shoulder * CFrame.Angles(rest, 0, 0)
		part("Arm", Vector3.new(0.6, 2.5, 0.65), bent * CFrame.new(0, -1.15, 0), coat, nil, g)
		part("Hand", Vector3.new(0.5, 0.5, 0.5), bent * CFrame.new(0, -2.6, 0), skin, Enum.Material.SmoothPlastic, g)
		if i == 2 and opts.held then
			local hand = bent * CFrame.new(0, -2.75, 0) * CFrame.Angles(-rest, 0, 0)
			local held = opts.held
			if held == "mug" then
				part("Held", Vector3.new(0.6, 0.55, 0.55), hand * CFrame.new(0, 0.2, -0.2) * CFrame.Angles(0, 0, math.pi / 2), rgb(222, 222, 210), Enum.Material.SmoothPlastic, g).Shape = Enum.PartType.Cylinder
			elseif held == "glass" then
				local p = part("Held", Vector3.new(0.65, 0.48, 0.48), hand * CFrame.new(0, 0.25, -0.2) * CFrame.Angles(0, 0, math.pi / 2), rgb(200, 205, 190), Enum.Material.Glass, g)
				p.Shape = Enum.PartType.Cylinder
				p.Transparency = 0.35
			elseif held == "spoon" then
				part("Held", Vector3.new(0.12, 0.08, 1), hand * CFrame.new(0, 0, -0.5), rgb(190, 190, 186), Enum.Material.Metal, g)
			elseif held == "cigarette" then
				part("Held", Vector3.new(0.08, 0.08, 0.45), hand * CFrame.new(0.1, 0.2, -0.3), rgb(236, 232, 220), Enum.Material.SmoothPlastic, g)
				part("Held", Vector3.new(0.09, 0.09, 0.08), hand * CFrame.new(0.1, 0.2, -0.55), rgb(255, 120, 40), Enum.Material.Neon, g)
			elseif held == "pick" then
				part("Held", Vector3.new(0.22, 0.22, 3.2), hand * CFrame.new(0, 0, -1.2), rgb(110, 80, 50), Enum.Material.Wood, g)
				part("Held", Vector3.new(2.4, 0.3, 0.3), hand * CFrame.new(0, 0, -2.7), rgb(70, 70, 72), Enum.Material.Metal, g)
			elseif held == "ladle" then
				part("Held", Vector3.new(0.15, 2.6, 0.15), hand * CFrame.new(0, -1.1, -0.2), rgb(180, 180, 176), Enum.Material.Metal, g)
			elseif held == "papers" then
				part("Held", Vector3.new(1, 0.08, 1.3), hand * CFrame.new(0, 0, -0.5), rgb(226, 220, 196), Enum.Material.SmoothPlastic, g)
			end
		end
	end

	if opts.action then
		model:SetAttribute("Action", opts.action)
	end
	model:SetAttribute("Seed", rng:NextInteger(1, 1e6))
	model:SetAttribute("Seated", seated)
	model.Parent = parent
	return model
end

return Figure
