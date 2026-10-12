-- Sounds from Config.Audio: 2D one-shots, 3D one-shots at a point, and loops.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Audio = {}

function Audio.make(name, parent, opts)
	local data = Config.Audio[name]
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = data.id
	s.Volume = (opts and opts.volume) or data.volume or 1
	s.PlaybackSpeed = (opts and opts.pitch) or data.pitch or 1
	s.Looped = data.looped or false
	s.RollOffMaxDistance = (opts and opts.range) or 120
	s.RollOffMinDistance = 6
	s.Parent = parent or SoundService
	return s
end

function Audio.play(name, opts)
	local s = Audio.make(name, SoundService, opts)
	s:Play()
	Debris:AddItem(s, 15)
	return s
end

function Audio.at(name, position, opts)
	local holder = Instance.new("Attachment")
	holder.WorldPosition = position
	holder.Parent = workspace.Terrain
	local s = Audio.make(name, holder, opts)
	s:Play()
	Debris:AddItem(holder, (opts and opts.life) or 10)
	return s
end

return Audio
