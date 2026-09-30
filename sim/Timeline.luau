--!strict
-- Timeline.luau — hold fraction and the hold multiplier (GAME_SPEC §3 *Held aim*, §8 timeline).
--
-- h = the fraction of the run-up (start of charge → aim lock) that the final aim was held. How the
-- slow-motion beat (3.0–4.5 s, 0.4× speed) counts is a §11 open question; switches.slowmo picks a
-- reading:
--   wall      every wall-clock second counts the same (run-up 7.7 s)
--   game      slow motion counts at its game speed, 0.4× (run-up 6.8 s)
--   excluded  slow motion doesn't count (run-up 6.2 s)
-- Pass 1 has no reveal and so no slow motion (§8); every reading agrees there.

local Timeline = {}

local function slowWeight(mode: string, speed: number): number
	if mode == "wall" then
		return 1
	elseif mode == "game" then
		return speed
	elseif mode == "excluded" then
		return 0
	end
	error("unknown slowmo reading " .. mode)
end

-- Counted run-up time between t0 and t1 (seconds from the start of the charge).
local function counted(t0: number, t1: number, cfg: any, hasReveal: boolean): number
	if t1 <= t0 then
		return 0
	end
	if not hasReveal then
		return t1 - t0
	end
	local tl = cfg.spec.timeline
	local a, b = tl.reveal, tl.slowEnd
	local slow = math.max(0, math.min(t1, b) - math.max(t0, a))
	local w = slowWeight(cfg.switches.slowmo, tl.slowSpeed)
	return (t1 - t0 - slow) + w * slow
end

-- Hold fraction for an aim committed at time t and kept to aim lock. Neutral (nil) holds nothing.
function Timeline.hold(t: number?, cfg: any, hasReveal: boolean): number
	if t == nil then
		return 0
	end
	local lock = cfg.spec.timeline.lock
	return counted(t, lock, cfg, hasReveal) / counted(0, lock, cfg, hasReveal)
end

-- Strike power and Guard armor multiplier: floor + (1 − floor)·h. §11: 0.4 + 0.6 × h.
function Timeline.mult(h: number, cfg: any): number
	local f = cfg.spec.holdFloor
	return f + (1 - f) * h
end

return Timeline
