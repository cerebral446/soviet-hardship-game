-- Poses part-built people (shared/Figure.luau) by rotating limb groups around their joints.

local Rig = {}
Rig.__index = Rig

function Rig.new(model)
	local self = setmetatable({}, Rig)
	self.model = model
	self.pivot = model:GetPivot()
	self.free = {}
	self.groups = {}
	self.parts = {}
	for _, p in model:GetDescendants() do
		if not p:IsA("BasePart") then
			continue
		end
		table.insert(self.parts, { part = p, transparency = p.Transparency })
		local rel = self.pivot:ToObjectSpace(p.CFrame)
		local g = p:GetAttribute("Group")
		local joint = g and model:GetAttribute("Joint_" .. g)
		if joint then
			local group = self.groups[g]
			if not group then
				group = { joint = joint, parts = {} }
				self.groups[g] = group
			end
			table.insert(group.parts, { part = p, rel = joint:ToObjectSpace(rel) })
		else
			table.insert(self.free, { part = p, rel = rel })
		end
	end
	return self
end

-- angles: { GroupName = CFrame rotation applied at the joint }.
function Rig:pose(pivot, angles)
	self.pivot = pivot
	for _, e in self.free do
		e.part.CFrame = pivot * e.rel
	end
	for name, g in self.groups do
		local j = pivot * g.joint * (angles[name] or CFrame.identity)
		for _, e in g.parts do
			e.part.CFrame = j * e.rel
		end
	end
end

function Rig:setVisible(visible)
	if self.visible == visible then
		return
	end
	self.visible = visible
	for _, e in self.parts do
		e.part.Transparency = visible and e.transparency or 1
	end
end

-- Head rotation that makes the person look at a world point.
function Rig:lookAngles(worldPoint)
	local head = self.groups.Head
	if not head then
		return CFrame.identity
	end
	local local_ = (self.pivot * head.joint):PointToObjectSpace(worldPoint)
	local yaw = math.clamp(math.atan2(-local_.X, -local_.Z), -1.7, 1.7)
	local flat = math.sqrt(local_.X * local_.X + local_.Z * local_.Z)
	local pitch = math.clamp(math.atan2(local_.Y, flat), -0.6, 0.6)
	return CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
end

return Rig
