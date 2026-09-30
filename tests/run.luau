--!strict
-- run.luau — test entry point. Run from the repo root:  lune run tests/run.luau
--
-- Loads every *.spec.luau in tests/ (each self-registers via testkit) and exits non-zero on any
-- failure. Borrowed from rblx-joust-tourney (main, tests/run.luau), minus its Roblox shim: the sim
-- is plain Luau.

local fs = require("@lune/fs")
local process = require("@lune/process")

local kit = require("./lib/testkit")

local specs = {}
for _, entry in fs.readDir("./tests") do
	if entry:match("%.spec%.luau$") then
		table.insert(specs, entry)
	end
end
table.sort(specs)
for _, spec in specs do
	require("./" .. spec:gsub("%.luau$", ""))
end

process.exit(kit.summary())
