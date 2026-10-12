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
local FUFAIKA = { rgb(38, 40, 46), rgb(30, 32, 30), rgb(46, 50, 60), rgb(52, 48, 40) }
local WOOL = { rgb(74, 66, 56), rgb(58, 62, 70), rgb(86, 78, 64), rgb(60, 50, 54), rgb(70, 74, 66) }
local FURS = { rgb(92, 64, 44), rgb(70, 50, 36), rgb(120, 92, 64), rgb(48, 40, 36) }
local SCARVES = { rgb(150, 40, 40), rgb(200, 190, 160), rgb(60, 80, 120), rgb(90, 110, 70), rgb(170, 130, 60) }
local SHAWLS = { rgb(214, 206, 188), rgb(170, 164, 150), rgb(130, 60, 60) }

-- Era clothing:
--   fufaika  quilted cotton work jacket, quilted trousers, valenki (felt boots)
--   coat     wool overcoat with a fur collar
--   furcoat  long fur coat (shuba), usually with a shawl or fur hat
--   shinel   Soviet Army greatcoat: belt, brass buttons, red shoulder boards, kirza boots
--   militia  grey-blue militia greatcoat
--   miner    canvas work suit, battery pack and self-rescuer on the belt, rubber boots
--   white    white kitchen coat
Figure.Outfits = { "fufaika", "coat", "furcoat", "shinel", "militia", "miner", "white" }

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
	local hat = opts.hat
	local outfit = opts.outfit
	if not outfit then
		if hat == "helmet" then
			outfit = "miner"
		elseif hat == "chef" then
			outfit = "white"
		elseif hat == "army" then
			outfit = "shinel"
		elseif hat == "militia" then
			outfit = "militia"
		elseif hat == "kerchief" or hat == "shawl" or hat == "furhat" then
			local r = rng:NextNumber()
			outfit = r < 0.5 and "furcoat" or (r < 0.8 and "coat" or "fufaika")
		else
			outfit = rng:NextNumber() < 0.55 and "fufaika" or "coat"
		end
	end
	local coatColors = ({
		fufaika = FUFAIKA,
		coat = WOOL,
		furcoat = FURS,
		shinel = { rgb(100, 92, 74) },
		militia = { rgb(82, 90, 104) },
		miner = { rgb(96, 88, 66) },
		white = { rgb(234, 234, 226) },
	})[outfit] or COATS
	local coat = opts.coat or pick(coatColors, rng)
	local pants = opts.pants or (outfit == "miner" and coat or pick(PANTS, rng))
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

	-- Footwear: felt valenki, army kirza, rubber mine boots or leather shoes.
	local bootColor, bootMaterial, bootHeight = rgb(28, 26, 24), Enum.Material.Leather, 0.7
	if outfit == "fufaika" or (outfit == "furcoat" and rng:NextNumber() < 0.5) then
		bootColor, bootMaterial, bootHeight = pick({ rgb(70, 68, 64), rgb(40, 38, 36), rgb(110, 104, 96) }, rng), Enum.Material.Fabric, 1.6
	elseif outfit == "shinel" or outfit == "militia" then
		bootColor, bootHeight = rgb(18, 18, 18), 1.5
	elseif outfit == "miner" then
		bootColor, bootMaterial, bootHeight = rgb(20, 20, 20), Enum.Material.Rubber, 1.4
	end

	-- Legs
	for i, side in { -1, 1 } do
		local g = i == 1 and "LegL" or "LegR"
		if seated then
			local hip = CFrame.new(side * 0.5, seatH + 0.4, 0.2)
			joint(g, hip)
			part("Thigh", Vector3.new(0.9, 0.8, 2.2), CFrame.new(side * 0.5, seatH + 0.4, -0.9), pants, nil, g)
			part("Shin", Vector3.new(0.85, seatH + 0.45, 0.9), CFrame.new(side * 0.5, (seatH + 0.45) / 2, -1.9), pants, nil, g)
			part("Boot", Vector3.new(1, math.min(bootHeight, seatH), 1.05), CFrame.new(side * 0.5, math.min(bootHeight, seatH) / 2, -1.9), bootColor, bootMaterial, g)
			part("Toe", Vector3.new(0.95, 0.5, 0.5), CFrame.new(side * 0.5, 0.25, -2.55), bootColor, bootMaterial, g)
		else
			joint(g, CFrame.new(side * 0.5, 2.8, 0))
			part("Leg", Vector3.new(0.9, 2.8, 0.9), CFrame.new(side * 0.5, 1.4, 0), pants, nil, g)
			part("Boot", Vector3.new(1, bootHeight, 1.05), CFrame.new(side * 0.5, bootHeight / 2, 0), bootColor, bootMaterial, g)
			part("Toe", Vector3.new(0.95, 0.5, 0.5), CFrame.new(side * 0.5, 0.25, -0.65), bootColor, bootMaterial, g)
		end
	end

	local up = seated and Vector3.new(0, seatH + 0.1 - 2.8, 0.2) or Vector3.zero
	local function at(x, y, z)
		return CFrame.new(Vector3.new(x, y, z) + up)
	end

	local coatMaterial = outfit == "furcoat" and Enum.Material.Fabric or Enum.Material.Fabric
	part("Torso", Vector3.new(2.2, 2.7, 1.2), at(0, 4.15, 0), coat, coatMaterial)
	-- How far down the coat hangs.
	local skirt = ({ fufaika = 0.7, coat = 1.7, furcoat = 2.3, shinel = 2.2, militia = 2.1, miner = 0.8, white = 1.6 })[outfit] or 1
	if seated then
		part("CoatSkirt", Vector3.new(2.3, 0.6, 1.3), at(0, 2.9, 0), coat, coatMaterial)
		if skirt > 1.2 then
			-- The coat drapes over the lap.
			part("CoatLap", Vector3.new(2.2, 0.25, 1.6), at(0, 3.15, -0.9), coat, coatMaterial)
		end
	else
		part("CoatSkirt", Vector3.new(outfit == "furcoat" and 2.55 or 2.35, skirt, outfit == "furcoat" and 1.45 or 1.32), at(0, 2.8 - skirt / 2 + 0.05, 0.02), coat, coatMaterial)
	end
	local trim = coat:Lerp(rgb(0, 0, 0), 0.3)
	if outfit == "fufaika" then
		-- Quilting: the stitched rows that make a vatnik a vatnik.
		for k = 0, 4 do
			for _, z in { -0.61, 0.61 } do
				part("Quilting", Vector3.new(2.22, 0.06, 0.04), at(0, 3.1 + k * 0.5, z), trim)
			end
		end
		part("Collar", Vector3.new(1.6, 0.35, 1.25), at(0, 5.45, 0), trim)
		for k = 0, 3 do
			part("Button", Vector3.new(0.16, 0.16, 0.06), at(0, 3.4 + k * 0.55, -0.62), rgb(20, 20, 20), Enum.Material.SmoothPlastic)
		end
	elseif outfit == "coat" then
		part("Fur collar", Vector3.new(1.95, 0.55, 1.42), at(0, 5.38, 0.02), pick(FURS, rng))
		for k = 0, 2 do
			part("Button", Vector3.new(0.18, 0.18, 0.06), at(0.35, 3.3 + k * 0.7, -0.62), rgb(30, 26, 22), Enum.Material.SmoothPlastic)
		end
	elseif outfit == "furcoat" then
		part("Fur collar", Vector3.new(2, 0.6, 1.5), at(0, 5.35, 0.02), coat:Lerp(rgb(255, 255, 255), 0.12))
		part("Fur trim", Vector3.new(0.3, 2.6, 0.08), at(0, 4.1, -0.62), coat:Lerp(rgb(255, 255, 255), 0.1))
	elseif outfit == "shinel" or outfit == "militia" then
		local board = outfit == "shinel" and rgb(150, 30, 26) or rgb(150, 30, 26)
		part("Collar", Vector3.new(1.7, 0.45, 1.3), at(0, 5.42, 0), coat)
		for _, x in { -0.45, 0.45 } do
			part("Collar tab", Vector3.new(0.3, 0.2, 0.05), at(x, 5.3, -0.66), board)
		end
		for _, x in { -0.85, 0.85 } do
			part("Shoulder board", Vector3.new(0.5, 0.1, 0.85), at(x, 5.48, 0), board)
		end
		part("Belt", Vector3.new(2.3, 0.32, 1.3), at(0, 3.35, 0), rgb(70, 46, 28), Enum.Material.Leather)
		part("Buckle", Vector3.new(0.4, 0.34, 0.06), at(0, 3.35, -0.67), rgb(200, 170, 70), Enum.Material.Metal)
		for k = 0, 2 do
			for _, x in { -0.45, 0.45 } do
				part("Brass button", Vector3.new(0.15, 0.15, 0.06), at(x, 3.85 + k * 0.5, -0.62), rgb(200, 170, 70), Enum.Material.Metal)
			end
		end
		if outfit == "militia" then
			part("Armband", Vector3.new(0.68, 0.4, 0.7), at(-1.4, 4.4, 0), rgb(160, 30, 28))
		end
	elseif outfit == "miner" then
		part("Collar", Vector3.new(1.6, 0.35, 1.25), at(0, 5.45, 0), trim)
		part("Belt", Vector3.new(2.3, 0.3, 1.3), at(0, 3.2, 0), rgb(40, 34, 28), Enum.Material.Leather)
		part("Lamp battery", Vector3.new(1, 0.9, 0.45), at(0.4, 3.2, 0.85), rgb(26, 26, 26), Enum.Material.SmoothPlastic)
		part("Self-rescuer", Vector3.new(0.5, 0.8, 0.5), at(-1.25, 3.1, 0.1), rgb(150, 150, 140), Enum.Material.Metal)
		part("Lamp cable", Vector3.new(0.08, 2.9, 0.08), at(0.4, 5, 0.75), rgb(15, 15, 15), Enum.Material.Rubber)
		part("Reflective tape", Vector3.new(2.22, 0.15, 1.22), at(0, 4.6, 0), rgb(200, 170, 80), Enum.Material.SmoothPlastic)
	elseif outfit == "white" then
		part("Collar", Vector3.new(1.6, 0.35, 1.25), at(0, 5.45, 0), coat)
		part("Apron", Vector3.new(1.8, 2.6, 0.05), at(0, 3.4, -0.63), rgb(220, 220, 214))
	end
	-- A knitted scarf on many civilians.
	if (outfit == "fufaika" or outfit == "coat") and rng:NextNumber() < 0.5 then
		local scarf = pick(SCARVES, rng)
		part("Scarf", Vector3.new(1.75, 0.45, 1.4), at(0, 5.42, 0), scarf)
		part("Scarf end", Vector3.new(0.4, 1.2, 0.12), at(0.45, 4.7, -0.68), scarf)
	end

	-- Head and hat turn together around the neck.
	joint("Head", at(0, 5.5, 0))
	part("Head", Vector3.new(1.1, 1.2, 1.05), at(0, 6.1, 0), skin, Enum.Material.SmoothPlastic, "Head")
	for _, x in { -0.25, 0.25 } do
		part("Eye", Vector3.new(0.18, 0.12, 0.05), at(x, 6.22, -0.53), rgb(25, 22, 20), Enum.Material.SmoothPlastic, "Head")
	end
	part("Nose", Vector3.new(0.18, 0.3, 0.16), at(0, 6.02, -0.58), skin, Enum.Material.SmoothPlastic, "Head")
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
	elseif hat == "army" or hat == "militia" then
		-- Grey ushanka with the flaps tied up and a cap badge.
		local fur = hat == "army" and rgb(88, 84, 74) or rgb(76, 80, 88)
		part("Hat", Vector3.new(1.35, 0.6, 1.3), at(0, 6.85, 0.02), fur, Enum.Material.Fabric, "Head")
		part("Hat", Vector3.new(1.4, 0.38, 0.32), at(0, 6.72, -0.62), fur, Enum.Material.Fabric, "Head")
		part("Hat", Vector3.new(1.45, 0.25, 1.2), at(0, 7.1, 0.05), fur, Enum.Material.Fabric, "Head")
		part("Cap badge", Vector3.new(0.26, 0.26, 0.05), at(0, 6.75, -0.8), hat == "army" and rgb(190, 30, 26) or rgb(210, 180, 70), Enum.Material.SmoothPlastic, "Head")
	elseif hat == "shawl" then
		-- An Orenburg down shawl over head and shoulders.
		local c = pick(SHAWLS, rng)
		part("Hat", Vector3.new(1.3, 1, 1.25), at(0, 6.5, 0.08), c, Enum.Material.Fabric, "Head")
		part("Shawl", Vector3.new(2.3, 0.45, 1.45), at(0, 5.4, 0.02), c)
		part("Shawl", Vector3.new(1.2, 1.2, 0.1), at(0, 4.9, 0.68), c)
	elseif hat == "furhat" then
		part("Hat", Vector3.new(1.35, 1, 1.3), at(0, 7.05, 0.02), pick(FURS, rng):Lerp(rgb(0, 0, 0), 0.15), Enum.Material.Fabric, "Head")
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
			elseif held == "avoska" then
				-- The string shopping bag, with milk and a loaf.
				local bag = part("Held", Vector3.new(0.9, 1.3, 0.55), hand * CFrame.new(0, -0.8, 0), rgb(180, 120, 60), Enum.Material.Fabric, g)
				bag.Transparency = 0.45
				part("Held", Vector3.new(0.9, 0.35, 0.35), hand * CFrame.new(0.1, -0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), rgb(236, 236, 230), Enum.Material.Glass, g).Shape = Enum.PartType.Cylinder
				part("Held", Vector3.new(0.6, 0.4, 0.4), hand * CFrame.new(-0.15, -1.1, 0), rgb(150, 100, 60), Enum.Material.Sand, g)
			elseif held == "briefcase" then
				part("Held", Vector3.new(0.35, 1, 1.5), hand * CFrame.new(0, -0.6, 0), rgb(70, 46, 30), Enum.Material.Leather, g)
			elseif held == "rifle" then
				-- AK slung on the shoulder strap, held by the strap.
				part("Held", Vector3.new(0.18, 3, 0.3), hand * CFrame.new(0, 1.1, 0.35), rgb(40, 34, 30), Enum.Material.Metal, g)
				part("Held", Vector3.new(0.2, 1.1, 0.4), hand * CFrame.new(0, 0, 0.35), rgb(110, 70, 40), Enum.Material.Wood, g)
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
