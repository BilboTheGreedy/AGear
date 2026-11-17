local _, ns = ...

local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local GetStats = (C_Item and C_Item.GetItemStats) or GetItemStats
local RequestLoad = C_Item and C_Item.RequestLoadItemDataByID

local API = {
	ITEM_MOD_STRENGTH_SHORT = "str",
	ITEM_MOD_AGILITY_SHORT = "agi",
	ITEM_MOD_STAMINA_SHORT = "sta",
	ITEM_MOD_INTELLECT_SHORT = "int",
	ITEM_MOD_SPIRIT_SHORT = "spi",
	RESISTANCE0_NAME = "armor",
	ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "dps",
	ITEM_MOD_ATTACK_POWER_SHORT = "ap",
	ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "rap",
	ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "feralap",
	ITEM_MOD_SPELL_POWER_SHORT = "sp",
	ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "sp",
	ITEM_MOD_SPELL_HEALING_DONE_SHORT = "heal",
	ITEM_MOD_HIT_RATING_SHORT = "hit",
	ITEM_MOD_CRIT_RATING_SHORT = "crit",
	ITEM_MOD_HIT_SPELL_RATING_SHORT = "spellhit",
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "spellcrit",
	ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
	ITEM_MOD_POWER_REGEN0_SHORT = "mp5",
	ITEM_MOD_HEALTH_REGEN_SHORT = "hp5",
	ITEM_MOD_HEALTH_REGENERATION_SHORT = "hp5",
	ITEM_MOD_HIT_MELEE_RATING_SHORT = "hit",
	ITEM_MOD_HIT_RANGED_RATING_SHORT = "hit",
	ITEM_MOD_CRIT_MELEE_RATING_SHORT = "crit",
	ITEM_MOD_CRIT_RANGED_RATING_SHORT = "crit",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "def",
	ITEM_MOD_DODGE_RATING_SHORT = "dodge",
	ITEM_MOD_PARRY_RATING_SHORT = "parry",
	ITEM_MOD_BLOCK_RATING_SHORT = "block",
	ITEM_MOD_BLOCK_VALUE_SHORT = "blockvalue",
}

local SCHOOLS = { fire = "fire", frost = "frost", arcane = "arcane", shadow = "shadow", nature = "nature", holy = "holy" }

local PATTERNS = {
	{ "damage and healing done by magical spells and effects by up to (%d+)", "sp" },
	{ "increases healing done by spells and effects by up to (%d+)", "heal" },
	{ "attack power in cat, bear,? and dire bear forms only", "feralap", "%+(%d+) attack power" },
	{ "%+(%d+) ranged attack power", "rap" },
	{ "%+(%d+) attack power", "ap" },
	{ "increases attack power by (%d+)", "ap" },
	{ "chance to hit with spells by (%d+)%%", "spellhit" },
	{ "critical strike with spells by (%d+)%%", "spellcrit" },
	{ "chance to hit by (%d+)%%", "hit" },
	{ "chance to get a critical strike by (%d+)%%", "crit" },
	{ "restores (%d+) mana per 5 sec", "mp5" },
	{ "restores (%d+) health per 5 sec", "hp5" },
	{ "increased defense %+(%d+)", "def" },
	{ "chance to dodge an attack by (%d+)%%", "dodge" },
	{ "chance to parry an attack by (%d+)%%", "parry" },
	{ "chance to block attacks with a shield by (%d+)%%", "block" },
	{ "block value of your shield by (%d+)", "blockvalue" },
}

local scanner
local function tooltipLines(link)
	local out = {}
	if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
		local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
		if ok and type(data) == "table" and type(data.lines) == "table" then
			for _, l in ipairs(data.lines) do
				if type(l.leftText) == "string" and not ns.IsSecret(l.leftText) then out[#out + 1] = l.leftText end
				if type(l.rightText) == "string" and not ns.IsSecret(l.rightText) then out[#out + 1] = l.rightText end
			end
			return out
		end
	end
	if not scanner then
		local ok, tip = pcall(CreateFrame, "GameTooltip", "AGearScanTip", nil, "GameTooltipTemplate")
		if not ok or not tip then return out end
		scanner = tip
	end
	if not scanner.SetOwner or not scanner.SetHyperlink then return out end
	scanner:SetOwner(UIParent, "ANCHOR_NONE")
	local ok = pcall(scanner.SetHyperlink, scanner, link)
	if not ok then return out end
	for i = 1, (scanner.NumLines and scanner:NumLines() or 0) or 0 do
		for _, side in ipairs({ "Left", "Right" }) do
			local fs = _G["AGearScanTipText" .. side .. i]
			local text = fs and fs.GetText and fs:GetText()
			if type(text) == "string" and text ~= "" then out[#out + 1] = text end
		end
	end
	return out
end

local function escape(s)
	return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function template(name, fallback)
	local t = type(_G[name]) == "string" and _G[name] ~= "" and _G[name] or fallback
	t = escape(t:lower())
	t = t:gsub("%%%%%d?%$?[sd]", function() return "([%d%.,]+)" end)
	return t
end

local function word(name, fallback)
	local t = type(_G[name]) == "string" and _G[name] ~= "" and _G[name] or fallback
	return t:lower()
end

local function whole(v)
	if not v then return nil end
	return tonumber((v:gsub("[%.,]", "")))
end

local function decimal(v)
	if not v then return nil end
	return tonumber((v:gsub(",", ".")))
end

local matchers
local function build()
	matchers = {
		speed = "^" .. escape(word("SPEED", "Speed")) .. " ([%d%.,]+)",
		armor = "^" .. template("ARMOR_TEMPLATE", "%s Armor") .. "$",
		block = "^" .. template("SHIELD_BLOCK_TEMPLATE", "%d Block") .. "$",
		dps = template("DPS_TEMPLATE", "(%s damage per second)"),
		equip = word("ITEM_SPELL_TRIGGER_ONEQUIP", "Equip:"),
	}
	return matchers
end

local function parse(stats, lines)
	local found = {}
	local m = matchers or build()
	for _, raw in ipairs(lines) do
		local text = raw:lower()
		local speed = decimal(text:match(m.speed))
		if speed and not stats.speed then stats.speed = speed end
		local armor = whole(text:match(m.armor))
		if armor then found.armor = (found.armor or 0) + armor end
		local block = whole(text:match(m.block))
		if block then found.blockvalue = (found.blockvalue or 0) + block end
		local dps = decimal(text:match(m.dps))
		if dps then found.dps = dps end
		if text:sub(1, #m.equip) == m.equip then
			local school, amount = text:match("increases damage done by (%a+) spells and effects by up to (%d+)")
			if school and SCHOOLS[school] then
				found[school] = (found[school] or 0) + tonumber(amount)
			else
				for _, p in ipairs(PATTERNS) do
					if text:find(p[1]) then
						local v = text:match(p[3] or p[1])
						if tonumber(v) then found[p[2]] = (found[p[2]] or 0) + tonumber(v) end
						break
					end
				end
			end
		end
	end
	for k, v in pairs(found) do
		if not stats[k] then stats[k] = v end
	end
end

local cache = {}
local requested = {}
ns.pending = 0

local function linkFor(item)
	if type(item) == "number" then return "item:" .. item, item end
	if type(item) ~= "string" or ns.IsSecret(item) then return nil end
	local body = item:match("(item:[%-%d:]+)")
	local id = tonumber(item:match("item:(%d+)"))
	if not body or not id then return nil end
	return body, id
end

ns.LinkFor = linkFor

function ns.ItemInfo(item)
	local link, id = linkFor(item)
	if not id then return nil end
	local info = { id = id }
	if GetInstant then
		local ok, _, _, _, loc, icon, classID, subclassID = pcall(GetInstant, id)
		if ok then
			info.equipLoc, info.icon, info.classID, info.subclassID = loc, icon, classID, subclassID
		end
	end
	if GetInfo then
		local ok, name, full, quality, ilvl, minLevel, _, _, _, loc, icon, _, classID, subclassID = pcall(GetInfo, link)
		if ok and name then
			info.name, info.link, info.quality, info.ilvl, info.minLevel = name, full, quality, ilvl, minLevel
			info.equipLoc = info.equipLoc or loc
			info.icon = info.icon or icon
			info.classID = info.classID or classID
			info.subclassID = info.subclassID or subclassID
		end
	end
	return info
end

function ns.Stats(item)
	local link, id = linkFor(item)
	if not link then return nil end
	local c = cache[link]
	if c then return c end
	local name
	if GetInfo then
		local ok, n = pcall(GetInfo, link)
		if ok then name = n end
	end
	if not name then
		if not requested[id] then
			requested[id] = true
			ns.pending = ns.pending + 1
			if RequestLoad then pcall(RequestLoad, id) end
		end
		return nil
	end
	local stats = {}
	if GetStats then
		local ok, t = pcall(GetStats, link)
		if ok and type(t) == "table" then
			for k, v in pairs(t) do
				local key = API[k]
				if key and type(v) == "number" and not ns.IsSecret(v) then stats[key] = (stats[key] or 0) + v end
			end
		end
	end
	parse(stats, tooltipLines(link))
	if GetInstant then
		local ok, _, _, _, loc = pcall(GetInstant, id)
		if ok and (loc == "INVTYPE_RANGED" or loc == "INVTYPE_RANGEDRIGHT" or loc == "INVTYPE_THROWN") then
			stats.rdps, stats.dps, stats.speed = stats.dps, nil, nil
		end
	end
	cache[link] = stats
	return stats
end

function ns.ScoreStats(stats, weights)
	local total = 0
	for k, w in pairs(weights or ns.Weights()) do
		local v = stats[k]
		if v then total = total + v * w end
	end
	return total
end

local scores = {}
function ns.Score(item)
	local link = linkFor(item)
	if not link then return nil end
	local s = scores[link]
	if s then return s end
	local stats = ns.Stats(item)
	if not stats then return nil end
	s = ns.ScoreStats(stats)
	scores[link] = s
	return s
end

function ns.StatText(item)
	local stats = ns.Stats(item)
	if not stats then return "" end
	local w = ns.Weights()
	local parts = {}
	for _, s in ipairs(ns.STATS) do
		local v = stats[s[1]]
		if v and w[s[1]] then
			parts[#parts + 1] = { v * w[s[1]], (v % 1 == 0 and tostring(v) or string.format("%.1f", v)) .. " " .. s[2] }
		end
	end
	table.sort(parts, function(a, b) return a[1] > b[1] end)
	local out = {}
	for i = 1, math.min(#parts, 4) do out[i] = parts[i][2] end
	return table.concat(out, ", ")
end

ns:Listen("WEIGHTS", function() scores = {} end)

ns:On("GET_ITEM_INFO_RECEIVED", function(id, ok)
	if not id or ns.IsSecret(id) then return end
	if requested[id] then
		requested[id] = nil
		ns.pending = math.max(0, ns.pending - 1)
	end
	if ok == false then return end
	ns.Debounce("items", 0.5, function() ns:Fire("ITEMS") end)
end)
