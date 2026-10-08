--!strict
-- Main.server.luau — the playable slice's server (0097): one hand at a time against the bot for
-- each player who joins. The rules are the sim's (ReplicatedStorage.Rules = sim/), their values
-- Rules.Config.defaults() as-is (0096); the betting rider's odds are calibrated at start.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = ReplicatedStorage:WaitForChild("Rules")
local Config = require(Rules:WaitForChild("Config"))
local Hand = require(Rules:WaitForChild("Hand"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Slice = require(Shared:WaitForChild("Slice"))

local HandRunner = require(script.Parent:WaitForChild("HandRunner"))

local cfg = Config.defaults()
Config.set(cfg, "switches.betting", "bands") -- the bot is the betting rider (0100)
local update, input = Net.server()

-- The betting rider's odds (Rules.Odds): calibrated in the background, yielding between batches so
-- the server keeps serving. Until it lands the bot bets with the sim's script.
local oddsRef: { table: any? } = { table = nil }
task.spawn(function()
	local t0 = os.clock()
	local slice = os.clock()
	oddsRef.table = Hand.calibrate(cfg, Slice.bot.calibrateBatch, function()
		if os.clock() - slice >= Slice.bot.calibrateBudget then
			task.wait()
			slice = os.clock()
		end
	end)
	print(string.format("Odds calibrated: %d hands in %.1f s", cfg.sim.oddsHands, os.clock() - t0))
end)

local runners: { [Player]: any } = {}

Players.PlayerAdded:Connect(function(player)
	local runner = HandRunner.new(player, update, cfg, oddsRef)
	runners[player] = runner
	runner:run()
end)

Players.PlayerRemoving:Connect(function(player)
	local runner = runners[player]
	if runner then
		runner:stop()
		runners[player] = nil
	end
end)

input.OnServerEvent:Connect(function(player, kind, value)
	local runner = runners[player]
	if runner and typeof(kind) == "string" then
		runner:onInput(kind, value)
	end
end)
