--!strict
-- CueLog.luau — the cue log (0097, 0101): one JSON record per hand, so a playtest can be compared
-- with the sim's readers (docs/sim/RESULTS.md, *What the bar's information is worth*). The field
-- names are the reader's cue names (§7): color, stance, timing, hit, heal, bets.
--
-- Written to Output on one line behind Slice.log.prefix (copy it out of Studio), and in a live
-- server also to the Slice.log.dataStore DataStore under the hand id.
--
-- Record (version 1):
--   { v, handId, placeId, time, bot = { profile }, button, seats = { human, bot },
--     hole = { {c, c}, {c, c} }, board = { 5 cards }, redeals,
--     color = { { lance, shield }, { lance, shield } },        -- "red" | "black" per rider (§7)
--     passes = { { pass, riders = { { commits = { {t, aim} ... }, firstExit, aim, tAim, h,
--                   tier, hit, heal, cleanBlock, battered, before, after } x2 } ... },
--     bets = { { round, seat, action, t, facing, bands } ... },
--     finish = { winner, how, pass, units, contributed, bonus = { b1, b2 }, category = { c1, c2 } } }
-- Per pass and rider: `commits` is every aim change with its time in seconds from the start of the
-- charge (aim nil is Neutral): the stance, any re-stance and any late switch. `firstExit` is the
-- first exit from Neutral, `aim` and `tAim` the aim at contact and when it was set, `h` the hold
-- fraction. `tier` is where this rider's strike landed; `hit` the half hearts this rider lost at
-- contact (negative: a clean block's restore), `heal` the ♥ heal after it; `cleanBlock` that this
-- rider's Guard stopped the opponent's strike; `battered` that this rider went into contact
-- Battered. Per bet: `t` is seconds into the 5 s window (5 is a timeout, which Stays); `bands` is
-- set for the bot: true when it bet as the betting rider, false while its odds were still being
-- calibrated and it bet with the sim's script.
-- Cards are the sim's integers (sim/Cards.luau): rank = c // 4 + 2, suit = c % 4 + 1 (♣ ♠ ♥ ♦).
-- Aim positions are sim/Dial.luau's: 0 Up, 4 Out, 8 Down, 12 In, odd numbers the half steps.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Slice = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Slice"))

local CueLog = {}

local store: DataStore? = nil
if not RunService:IsStudio() then
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore(Slice.log.dataStore)
	end)
	if ok then
		store = s
	else
		warn("CueLog: no DataStore (" .. tostring(s) .. "); logging to Output only")
	end
end

function CueLog.write(record: { [string]: any })
	record.v = Slice.log.version
	local json = HttpService:JSONEncode(record)
	print(Slice.log.prefix .. json)
	if store then
		task.spawn(function()
			local ok, err = pcall(function()
				(store :: DataStore):SetAsync(tostring(record.handId), json)
			end)
			if not ok then
				warn("CueLog: DataStore write failed: " .. tostring(err))
			end
		end)
	end
end

return CueLog
