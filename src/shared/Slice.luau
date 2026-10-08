--!strict
-- Slice.luau — the playable slice's own values (0097): everything the slice needs that is not a
-- rule of the hand. The rules' values are sim/Config.luau (ReplicatedStorage.Rules.Config), used
-- as-is: the sim's values are where the build starts (0096), and no §11 value is changed here.
-- Each block names the decision behind it.

local Slice = {}

-- The opponent (0100): the sim's scripted rider, as a rider profile from Rules.Config.riders.
Slice.bot = {
	profile = "average",
	showProfile = true, -- its nameplate names the profile, like the tourney's house riders (§9)
	-- Bets after a short think, never instantly (0107): seconds into its betting window.
	thinkMin = 1.0,
	thinkMax = 2.5,
	-- The betting rider's odds (Rules.Odds) are calibrated at server start, in the background:
	-- checking the clock every `calibrateBatch` hands and yielding a frame once `calibrateBudget`
	-- seconds have run, so the hand being played never stalls. Until they are ready the bot bets
	-- with the sim's script.
	calibrateBatch = 5,
	calibrateBudget = 0.008, -- half a 60 Hz frame
}

-- The deal (0099): only numeric hands. The server redeals until neither rider can make a straight
-- or better by the river, so every hand the slice plays is one GAME_SPEC specifies in full.
Slice.deal = {
	numericOnly = true,
	maxRedeals = 200,
}

-- Seats. The human is seat 1, the bot seat 2; the button is a coin flip, shown to both (§2, 0084).
Slice.seats = { human = 1, bot = 2 }

-- Beats after contact, in seconds from contact (0106): the hits land at once, the ♥ heal is its own
-- beat (0093), then the post-pass reveal (§7) opens for `revealHold`. Then the next bet.
Slice.beats = {
	heal = 0.6,
	reveal = 1.2,
	revealHold = 2.0,
	-- The showdown (§8): the hole cards flip, each hand bonus pours into the bar, then the knockdown.
	showdownCards = 0.8,
	showdownBonus = 1.6,
	knockdown = 1.2,
	-- An unhorse on Passes 1–3 or a Yield: the hand-end card holds this long, then a new hand.
	handEnd = 4.0,
}

-- The betting window (§2: 5 s, timeout defaults to Stay). spec.betTimer would be a §11 value; the
-- sim has no clock, so the slice carries it here at §11's value.
Slice.betTimer = 5.0

-- The cue log (0101): one JSON record per hand, printed to Output on one line behind `prefix`, and
-- in a live server (not Studio) also written to this DataStore under the hand id.
Slice.log = {
	prefix = "CUELOG ",
	dataStore = "PokerJoustingCueLog",
	version = 1,
}

-- The wheel's screen mapping (0104, 0105): Up at the top, the sweep clockwise, so Out is on the
-- right and In on the left. A label at every direction (every second aim position); ticks between.
Slice.wheel = {
	labelEvery = 2,
	clockwise = true,
}

return Slice
