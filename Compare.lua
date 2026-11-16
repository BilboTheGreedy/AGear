local _, ns = ...

ns.SLOTS = {
	{ 1, "Head" }, { 2, "Neck" }, { 3, "Shoulder" }, { 15, "Back" }, { 5, "Chest" }, { 9, "Wrist" },
	{ 10, "Hands" }, { 6, "Waist" }, { 7, "Legs" }, { 8, "Feet" }, { 11, "Ring 1" }, { 12, "Ring 2" },
	{ 13, "Trinket 1" }, { 14, "Trinket 2" }, { 16, "Main hand" }, { 17, "Off hand" }, { 18, "Ranged" },
}

local SLOTNAME = {}
for _, s in ipairs(ns.SLOTS) do SLOTNAME[s[1]] = s[2] end
ns.SLOTNAME = SLOTNAME

local LOCSLOTS = {
	INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
	INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
	INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
	INVTYPE_WEAPON = { 16 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
	INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
	INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}

ns.GROUPS = {
	{ "ALL", "All slots" }, { "Head", "Head" }, { "Neck", "Neck" }, { "Shoulder", "Shoulder" }, { "Back", "Back" },
	{ "Chest", "Chest" }, { "Wrist", "Wrist" }, { "Hands", "Hands" }, { "Waist", "Waist" }, { "Legs", "Legs" },
	{ "Feet", "Feet" }, { "Ring", "Rings" }, { "Trinket", "Trinkets" }, { "Weapon", "Weapons" },
	{ "Off hand", "Off hand" }, { "Ranged", "Ranged" },
}

local LOCGROUP = {
	INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder", INVTYPE_CHEST = "Chest",
	INVTYPE_ROBE = "Chest", INVTYPE_WAIST = "Waist", INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet",
	INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands", INVTYPE_FINGER = "Ring", INVTYPE_TRINKET = "Trinket",
	INVTYPE_CLOAK = "Back", INVTYPE_WEAPON = "Weapon", INVTYPE_2HWEAPON = "Weapon", INVTYPE_WEAPONMAINHAND = "Weapon",
	INVTYPE_WEAPONOFFHAND = "Off hand", INVTYPE_SHIELD = "Off hand", INVTYPE_HOLDABLE = "Off hand",
	INVTYPE_RANGED = "Ranged", INVTYPE_RANGEDRIGHT = "Ranged", INVTYPE_THROWN = "Ranged", INVTYPE_RELIC = "Ranged",
}

function ns.Group(loc)
	return LOCGROUP[loc or ""]
end

local ARMOR = {
	WARRIOR = 4, PALADIN = 4, HUNTER = 3, SHAMAN = 3, ROGUE = 2, DRUID = 2, PRIEST = 1, MAGE = 1, WARLOCK = 1,
}

local EXTRA = {
	WARRIOR = { [6] = true },
	PALADIN = { [6] = true, [7] = true },
	SHAMAN = { [6] = true, [9] = true },
	DRUID = { [8] = true },
}

local WEAPON = {
	WARRIOR = { [0] = 1, [1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [10] = 1, [13] = 1, [15] = 1, [16] = 1, [18] = 1 },
	PALADIN = { [0] = 1, [1] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1 },
	HUNTER = { [0] = 1, [1] = 1, [2] = 1, [3] = 1, [6] = 1, [7] = 1, [8] = 1, [10] = 1, [13] = 1, [15] = 1, [16] = 1, [18] = 1 },
	ROGUE = { [2] = 1, [3] = 1, [4] = 1, [7] = 1, [13] = 1, [15] = 1, [16] = 1, [18] = 1 },
	PRIEST = { [4] = 1, [10] = 1, [15] = 1, [19] = 1 },
	SHAMAN = { [0] = 1, [1] = 1, [4] = 1, [5] = 1, [10] = 1, [13] = 1, [15] = 1 },
	MAGE = { [7] = 1, [10] = 1, [15] = 1, [19] = 1 },
	WARLOCK = { [7] = 1, [10] = 1, [15] = 1, [19] = 1 },
	DRUID = { [4] = 1, [5] = 1, [10] = 1, [13] = 1, [15] = 1 },
}

local DUAL = { WARRIOR = true, ROGUE = true, HUNTER = true }

function ns.Usable(info, class)
	class = class or ns.playerClass
	if not info or not LOCSLOTS[info.equipLoc or ""] then return false end
	if info.classID == 4 then
		local sub = info.subclassID or 0
		if sub == 0 or info.equipLoc == "INVTYPE_CLOAK" then return true end
		if sub >= 1 and sub <= 4 then return sub <= (ARMOR[class] or 4) end
		local extra = EXTRA[class]
		return extra and extra[sub] or false
	elseif info.classID == 2 then
		local w = WEAPON[class]
		if not w then return true end
		if info.equipLoc == "INVTYPE_WEAPONOFFHAND" and not DUAL[class] then return false end
		return w[info.subclassID or -1] ~= nil
	end
	return true
end

function ns.Equipped(slot)
	local link
	if GetInventoryItemLink then
		local ok, l = pcall(GetInventoryItemLink, "player", slot)
		if ok and type(l) == "string" and not ns.IsSecret(l) then link = l end
	end
	if link then return link, tonumber(link:match("item:(%d+)")) end
	if GetInventoryItemID then
		local ok, id = pcall(GetInventoryItemID, "player", slot)
		if ok and type(id) == "number" and not ns.IsSecret(id) then return id, id end
	end
	return nil
end

local function slotScore(slot)
	local item = ns.Equipped(slot)
	if not item then return 0, nil end
	return ns.Score(item) or 0, item
end

local function twoHanded()
	local item = ns.Equipped(16)
	if not item then return false end
	local info = ns.ItemInfo(item)
	return info and info.equipLoc == "INVTYPE_2HWEAPON"
end

function ns.Compare(item)
	local info = ns.ItemInfo(item)
	if not info or not LOCSLOTS[info.equipLoc or ""] then return nil end
	local score = ns.Score(item)
	if not score then return nil end
	if not ns.Usable(info) then return score, nil, nil, nil, false end
	local loc = info.equipLoc
	if loc == "INVTYPE_2HWEAPON" then
		local main, mainItem = slotScore(16)
		local off = slotScore(17)
		if twoHanded() then off = 0 end
		return score, score - main - off, 16, mainItem, true
	end
	local slots = LOCSLOTS[loc]
	if loc == "INVTYPE_WEAPON" and DUAL[ns.playerClass] then slots = { 16, 17 } end
	if slots[1] == 17 and twoHanded() then return score, nil, 17, nil, true end
	local best, bestSlot, bestItem
	for _, slot in ipairs(slots) do
		local item, curId = ns.Equipped(slot)
		if curId and curId == info.id then return score, 0, slot, item, true end
	end
	for _, slot in ipairs(slots) do
		if not (slot == 17 and twoHanded()) then
			local cur, curItem = slotScore(slot)
			local delta = score - cur
			if not best or delta > best then best, bestSlot, bestItem = delta, slot, curItem end
		end
	end
	return score, best, bestSlot, bestItem, true
end

function AGear.Score(item)
	if not ns.db then return nil end
	local info = ns.ItemInfo(item)
	if not info or not LOCSLOTS[info.equipLoc or ""] then return nil end
	return ns.Score(item)
end

function AGear.IsUpgrade(item)
	if not ns.db then return false end
	local _, delta = ns.Compare(item)
	if delta and delta > 0.05 then return true, delta end
	return false, delta
end

local function changed()
	ns.Debounce("gear", 0.3, function() ns:Fire("GEAR") end)
end

ns:On("PLAYER_EQUIPMENT_CHANGED", changed)
ns:On("UNIT_INVENTORY_CHANGED", function(unit)
	if unit == "player" then changed() end
end)
