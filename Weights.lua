local _, ns = ...

ns.STATS = {
	{ "str", "Strength" },
	{ "agi", "Agility" },
	{ "sta", "Stamina" },
	{ "int", "Intellect" },
	{ "spi", "Spirit" },
	{ "ap", "Attack power" },
	{ "rap", "Ranged attack power" },
	{ "feralap", "Feral attack power" },
	{ "hit", "Hit %" },
	{ "crit", "Crit %" },
	{ "dps", "Melee weapon DPS" },
	{ "rdps", "Ranged weapon DPS" },
	{ "speed", "Melee weapon speed" },
	{ "sp", "Spell damage and healing" },
	{ "heal", "Healing only" },
	{ "fire", "Fire damage" },
	{ "frost", "Frost damage" },
	{ "arcane", "Arcane damage" },
	{ "shadow", "Shadow damage" },
	{ "nature", "Nature damage" },
	{ "holy", "Holy damage" },
	{ "spellhit", "Spell hit %" },
	{ "spellcrit", "Spell crit %" },
	{ "mp5", "Mana per 5 sec" },
	{ "hp5", "Health per 5 sec" },
	{ "armor", "Armor" },
	{ "def", "Defense" },
	{ "dodge", "Dodge %" },
	{ "parry", "Parry %" },
	{ "block", "Block %" },
	{ "blockvalue", "Block value" },
}

ns.STATNAME = {}
for _, s in ipairs(ns.STATS) do ns.STATNAME[s[1]] = s[2] end

ns.SETS = {
	{ key = "WARRIOR_FURY", class = "WARRIOR", name = "Warrior: Fury", w = { str = 1, agi = 0.6, ap = 0.5, hit = 10, crit = 14, dps = 3, sta = 0.1, armor = 0.005 } },
	{ key = "WARRIOR_ARMS", class = "WARRIOR", name = "Warrior: Arms", w = { str = 1, agi = 0.55, ap = 0.5, hit = 10, crit = 13, dps = 3.5, speed = 2, sta = 0.2, armor = 0.005 } },
	{ key = "WARRIOR_PROT", class = "WARRIOR", name = "Warrior: Protection", w = { sta = 1, def = 1.2, armor = 0.08, dodge = 12, parry = 12, block = 6, blockvalue = 0.3, str = 0.4, agi = 0.5, hit = 6, ap = 0.15, dps = 1.2 } },
	{ key = "PALADIN_HOLY", class = "PALADIN", name = "Paladin: Holy", w = { int = 1, heal = 0.9, sp = 0.9, spellcrit = 12, mp5 = 2.5, sta = 0.2, spi = 0.2 } },
	{ key = "PALADIN_RET", class = "PALADIN", name = "Paladin: Retribution", w = { str = 1, ap = 0.45, agi = 0.5, crit = 12, hit = 9, dps = 3.5, speed = 2, sp = 0.3, holy = 0.3, int = 0.15, sta = 0.2 } },
	{ key = "PALADIN_PROT", class = "PALADIN", name = "Paladin: Protection", w = { sta = 1, def = 1.2, armor = 0.07, dodge = 10, parry = 10, block = 6, blockvalue = 0.4, sp = 0.4, holy = 0.4, int = 0.3, str = 0.3, hit = 4 } },
	{ key = "HUNTER", class = "HUNTER", name = "Hunter", w = { agi = 1, rap = 0.45, ap = 0.45, hit = 12, crit = 14, rdps = 3, dps = 0.2, int = 0.1, sta = 0.15, mp5 = 0.5 } },
	{ key = "ROGUE", class = "ROGUE", name = "Rogue", w = { agi = 1, str = 0.55, ap = 0.5, hit = 11, crit = 14, dps = 3.5, sta = 0.15 } },
	{ key = "PRIEST_HOLY", class = "PRIEST", name = "Priest: Holy", w = { heal = 1, sp = 1, int = 0.7, spi = 0.6, mp5 = 2.6, spellcrit = 6, sta = 0.2 } },
	{ key = "PRIEST_SHADOW", class = "PRIEST", name = "Priest: Shadow", w = { sp = 1, shadow = 1, spellhit = 12, spellcrit = 5, int = 0.3, spi = 0.3, mp5 = 1.5, sta = 0.2 } },
	{ key = "SHAMAN_ELE", class = "SHAMAN", name = "Shaman: Elemental", w = { sp = 1, nature = 1, spellhit = 11, spellcrit = 9, int = 0.4, mp5 = 1.8, sta = 0.2 } },
	{ key = "SHAMAN_ENH", class = "SHAMAN", name = "Shaman: Enhancement", w = { str = 1, ap = 0.5, agi = 0.6, crit = 13, hit = 10, dps = 3.5, speed = 2, int = 0.2, sta = 0.2 } },
	{ key = "SHAMAN_RESTO", class = "SHAMAN", name = "Shaman: Restoration", w = { heal = 1, sp = 1, int = 0.7, mp5 = 3, spellcrit = 5, sta = 0.2 } },
	{ key = "MAGE", class = "MAGE", name = "Mage", w = { sp = 1, fire = 0.9, frost = 0.9, arcane = 0.9, spellhit = 12, spellcrit = 9, int = 0.4, spi = 0.15, sta = 0.15 } },
	{ key = "WARLOCK", class = "WARLOCK", name = "Warlock", w = { sp = 1, shadow = 0.95, fire = 0.4, spellhit = 12, spellcrit = 8, int = 0.3, sta = 0.4 } },
	{ key = "DRUID_BALANCE", class = "DRUID", name = "Druid: Balance", w = { sp = 1, nature = 0.6, arcane = 0.6, spellhit = 11, spellcrit = 9, int = 0.4, mp5 = 1.5, sta = 0.2 } },
	{ key = "DRUID_CAT", class = "DRUID", name = "Druid: Feral cat", w = { str = 1, agi = 0.9, ap = 0.45, feralap = 0.45, crit = 13, hit = 10, sta = 0.2 } },
	{ key = "DRUID_BEAR", class = "DRUID", name = "Druid: Feral bear", w = { sta = 1, armor = 0.1, agi = 0.7, def = 0.8, dodge = 12, str = 0.4, ap = 0.2, feralap = 0.2, hit = 5 } },
	{ key = "DRUID_RESTO", class = "DRUID", name = "Druid: Restoration", w = { heal = 1, sp = 1, int = 0.6, spi = 0.6, mp5 = 2.8, sta = 0.2 } },
	{ key = "CUSTOM", name = "Custom", w = {} },
}

local byKey = {}
for _, s in ipairs(ns.SETS) do byKey[s.key] = s end

function ns.ClassSets(class)
	local out = {}
	for _, s in ipairs(ns.SETS) do
		if s.class == class or not s.class then out[#out + 1] = s end
	end
	return out
end

function ns.ActiveSet()
	local key = ns.chardb and ns.chardb.set
	local s = key and byKey[key]
	if s then return s end
	for _, set in ipairs(ns.SETS) do
		if set.class == ns.playerClass then return set end
	end
	return ns.SETS[1]
end

function ns.SetActive(key)
	if not byKey[key] then return end
	ns.chardb.set = key
	ns:Fire("WEIGHTS")
end

function ns.Weights()
	local s = ns.ActiveSet()
	return ns.db.custom[s.key] or s.w
end

function ns.Edited()
	return ns.db.custom[ns.ActiveSet().key] ~= nil
end

function ns.SetWeight(stat, value)
	local s = ns.ActiveSet()
	local w = ns.db.custom[s.key]
	if not w then
		w = {}
		for k, v in pairs(s.w) do w[k] = v end
		ns.db.custom[s.key] = w
	end
	value = tonumber(value)
	if not value or value == 0 then
		w[stat] = nil
	else
		w[stat] = math.floor(value * 1000 + 0.5) / 1000
	end
	ns:Fire("WEIGHTS")
end

function ns.ResetWeights()
	ns.db.custom[ns.ActiveSet().key] = nil
	ns:Fire("WEIGHTS")
end
