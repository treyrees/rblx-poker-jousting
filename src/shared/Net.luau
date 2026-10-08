--!strict
-- Net.luau — the slice's two remotes. The server creates them under ReplicatedStorage.Net; the
-- client waits for them. Server → client carries only what GAME_SPEC §3 *Public vs hidden* lists
-- (the client's own hole cards aside); client → server carries input only.
--
-- Update (server → client), (kind: string, payload: table):
--   hand      a hand begins: id, seats, button, your hole cards, both riders' colors and Posture
--   bet       a betting spot: round, pot, who acts, whether they face a raise, the deadline
--   betAction a rider's Stay / Raise / Yield
--   pass      a pass begins: pass, server start time, the board known, the reveal's cards and time
--   aim       a rider's public aim changed: seat, aim position (or Neutral), time into the pass
--   contact   both strikes resolved: tiers, hits, heals, holds, aims (the post-pass reveal)
--   showdown  Pass 4's showdown: hole cards, categories, bonuses, who is knocked down
--   handEnd   winner, how, units
-- Input (client → server), (kind: string, value):
--   aim   number 0..15 or nil (Neutral)
--   bet   "stay" | "raise" | "yield"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.FOLDER = "Net"
Net.UPDATE = "Update"
Net.INPUT = "Input"

function Net.server(): (RemoteEvent, RemoteEvent)
	assert(RunService:IsServer(), "Net.server on the client")
	local folder = Instance.new("Folder")
	folder.Name = Net.FOLDER
	local update = Instance.new("RemoteEvent")
	update.Name = Net.UPDATE
	update.Parent = folder
	local input = Instance.new("RemoteEvent")
	input.Name = Net.INPUT
	input.Parent = folder
	folder.Parent = ReplicatedStorage
	return update, input
end

function Net.client(): (RemoteEvent, RemoteEvent)
	local folder = ReplicatedStorage:WaitForChild(Net.FOLDER)
	return folder:WaitForChild(Net.UPDATE) :: RemoteEvent, folder:WaitForChild(Net.INPUT) :: RemoteEvent
end

return Net
