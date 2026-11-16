local _, ns = ...

local Up = { rows = {}, running = false, progress = 0, total = 0, missing = 0 }
ns.Upgrades = Up

local BATCH = 40
local token = 0

local KINDS = {
	{ "ALL", "Any source" }, { "dungeon", "Dungeons" }, { "raid", "Raids" }, { "craft", "Crafted" },
	{ "quest", "Quests" }, { "pvp", "PvP" }, { "reputation", "Reputation" },
}
ns.KINDS = KINDS

local WORDS = {
	{ "craft", { "craft", "tailoring", "leatherworking", "blacksmithing", "engineering", "alchemy", "enchanting" } },
	{ "pvp", { "pvp", "honor", "battleground", "warsong", "arathi", "alterac" } },
	{ "reputation", { "reputation", "exalted", "revered", "honored", "friendly" } },
	{ "quest", { "quest" } },
	{ "raid", { "molten core", "blackwing", "onyxia", "zul'gurub", "ahn'qiraj", "naxxramas", "raid" } },
}

local function kindOf(text, kind)
	if type(kind) == "string" then return kind:lower() end
	local l = (text or ""):lower()
	for _, k in ipairs(WORDS) do
		for _, word in ipairs(k[2]) do
			if l:find(word, 1, true) then return k[1] end
		end
	end
	return "dungeon"
end

function Up.Available()
	return type(ALoot) == "table" and type(ALoot.AllItems) == "function"
end

local function source(id)
	if type(ALoot.SourceText) ~= "function" then return "", "dungeon" end
	local ok, text, kind = pcall(ALoot.SourceText, id)
	if not ok or type(text) ~= "string" then text = "" end
	return text, kindOf(text, kind)
end

function Up.Start()
	if not Up.Available() then
		Up.rows = {}
		return
	end
	local ok, ids = pcall(ALoot.AllItems)
	if not ok or type(ids) ~= "table" then return end
	token = token + 1
	local mine = token
	local found = {}
	local missing = 0
	local index = 1
	Up.running = true
	Up.total = #ids
	Up.progress = 0
	local function step()
		if mine ~= token then return end
		local stop = math.min(index + BATCH - 1, #ids)
		for i = index, stop do
			local id = ids[i]
			if type(id) == "number" then
				local info = ns.ItemInfo(id)
				if info and ns.Group(info.equipLoc) and ns.Usable(info) then
					local score, delta, slot = ns.Compare(id)
					if not score then
						missing = missing + 1
					elseif delta and delta > 0.05 then
						local text, kind = source(id)
						found[#found + 1] = {
							kind = "upgrade", id = id, score = score, delta = delta, slot = slot,
							group = ns.Group(info.equipLoc), source = text, type = kind, minLevel = info.minLevel or 0,
						}
					end
				end
			end
		end
		index = stop + 1
		Up.progress = stop
		if index > #ids then
			table.sort(found, function(a, b)
				if a.delta ~= b.delta then return a.delta > b.delta end
				return a.id < b.id
			end)
			Up.rows = found
			Up.missing = missing
			Up.running = false
			ns:Fire("UPGRADES")
		else
			ns.After(0.02, step)
		end
	end
	step()
end

function Up.Rows(filter)
	local out = {}
	filter = filter or {}
	for _, r in ipairs(Up.rows) do
		if (not filter.group or filter.group == "ALL" or r.group == filter.group)
			and (not filter.type or filter.type == "ALL" or r.type == filter.type)
			and (not filter.level or r.minLevel <= filter.level) then
			out[#out + 1] = r
			if #out >= 400 then break end
		end
	end
	return out
end

local function restart()
	if not Up.wanted then return end
	ns.Debounce("upgrades", 1.5, Up.Start)
end

ns:Listen("WEIGHTS", restart)
ns:Listen("GEAR", restart)
ns:Listen("ITEMS", function()
	if Up.missing > 0 and not Up.running then restart() end
end)
