local _, ns = ...

local Rewards = {}
ns.Rewards = Rewards

local GREEN, RED, GREY, GOLD = { 0.25, 0.9, 0.25 }, { 1, 0.3, 0.3 }, { 0.6, 0.6, 0.6 }, { 1, 0.82, 0 }

function Rewards.Verdict(link)
	if not link then return nil end
	local score, delta, slot, _, usable = ns.Compare(link)
	if not score then return nil end
	if usable == false then return { text = "can't use", short = "x", color = GREY, kind = "unusable" } end
	if not delta then return nil end
	local where = slot and ns.SLOTNAME[slot] or nil
	if delta > 0.05 then
		return { text = string.format("upgrade +%.1f", delta), short = string.format("+%.1f", delta), color = GREEN, kind = "up", delta = delta, slot = where }
	elseif delta < -0.05 then
		return { text = string.format("downgrade %.1f", delta), short = string.format("%.1f", delta), color = RED, kind = "down", delta = delta, slot = where }
	end
	return { text = "same as equipped", short = "=", color = GREY, kind = "same", delta = 0, slot = where }
end

local badges = setmetatable({}, { __mode = "k" })
local labels = setmetatable({}, { __mode = "k" })
Rewards.badges, Rewards.labels = badges, labels

local function badge(button)
	if badges[button] then return badges[button] end
	local b = CreateFrame("Frame", nil, button)
	b:SetAllPoints(button)
	b:SetFrameLevel((button.GetFrameLevel and button:GetFrameLevel() or 1) + 5)
	b.back = b:CreateTexture(nil, "ARTWORK")
	b.back:SetColorTexture(0, 0, 0, 0.75)
	b.back:SetPoint("BOTTOMLEFT", 2, 2)
	b.back:SetSize(38, 13)
	b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.text:SetPoint("CENTER", b.back, "CENTER", 0, 0)
	b.best = b:CreateTexture(nil, "OVERLAY")
	b.best:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
	b.best:SetSize(14, 14)
	b.best:SetPoint("TOPLEFT", -3, 3)
	b.coin = b:CreateTexture(nil, "OVERLAY")
	b.coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
	b.coin:SetSize(12, 12)
	b.coin:SetPoint("TOPLEFT", -2, 2)
	badges[button] = b
	return b
end

local function mark(button, verdict, best, coin)
	if not button then return end
	local b = badge(button)
	if not verdict and not coin then
		b:Hide()
		return
	end
	if verdict then
		b.text:SetText(verdict.short)
		b.text:SetTextColor(verdict.color[1], verdict.color[2], verdict.color[3])
		b.back:Show()
		b.text:Show()
	else
		b.back:Hide()
		b.text:Hide()
	end
	b.best:SetShown(best and true or false)
	b.coin:SetShown(coin and not best or false)
	b:Show()
end

local function rewardButton(kind, index, choices)
	local frame = QuestInfoRewardsFrame
	if frame and type(frame.RewardButtons) == "table" then
		for _, b in ipairs(frame.RewardButtons) do
			if b.IsShown and b:IsShown() and b.type == kind and b.GetID and b:GetID() == index then return b end
		end
	end
	local n = kind == "choice" and index or (choices + index)
	return _G["QuestInfoRewardsFrameQuestInfoItem" .. n] or _G["QuestInfoItem" .. n]
end

local function sellPrice(link)
	local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if not get then return 0 end
	local ok, _, _, _, _, _, _, _, _, _, _, price = pcall(get, link)
	if ok and type(price) == "number" then return price end
	return 0
end

local announced
function Rewards.Quest(final)
	if not ns.db or ns.db.rewards == false then return end
	if not GetQuestItemLink then return end
	local choices = GetNumQuestChoices and GetNumQuestChoices() or 0
	local rewards = GetNumQuestRewards and GetNumQuestRewards() or 0
	if type(choices) ~= "number" then choices = 0 end
	if type(rewards) ~= "number" then rewards = 0 end
	local list, missing = {}, false
	local best, bestDelta, rich, richPrice
	for i = 1, choices do
		local link = GetQuestItemLink("choice", i)
		if not link then missing = true end
		local v = Rewards.Verdict(link)
		local price = link and sellPrice(link) or 0
		list[i] = { link = link, verdict = v, price = price }
		if v and v.kind == "up" and (not bestDelta or v.delta > bestDelta) then best, bestDelta = i, v.delta end
		if price > 0 and (not richPrice or price > richPrice) then rich, richPrice = i, price end
	end
	for i = 1, choices do
		mark(rewardButton("choice", i, choices), list[i].verdict, i == best, choices > 1 and i == rich)
	end
	for i = 1, rewards do
		local link = GetQuestItemLink("reward", i)
		mark(rewardButton("reward", i, choices), Rewards.Verdict(link), false, false)
	end
	if final and choices > 1 and ns.db.rewardChat ~= false then
		local key = tostring(best) .. ":" .. tostring(rich) .. ":" .. tostring(list[1] and list[1].link)
		if key ~= announced then
			announced = key
			if best then
				ns.Print("best reward: " .. list[best].link .. "  " .. list[best].verdict.text .. (list[best].verdict.slot and (" vs " .. list[best].verdict.slot) or ""))
			elseif rich and not missing then
				ns.Print("no upgrade here, worth most to a vendor: " .. list[rich].link)
			end
		end
	end
	return list, best, rich, missing
end

local function questSoon()
	ns.Debounce("quest", 0.1, function()
		local _, _, _, missing = Rewards.Quest(true)
		if missing then ns.After(0.6, function() Rewards.Quest(true) end) end
	end)
end

local function rollFrames()
	local out = {}
	for i = 1, 8 do
		local f = _G["GroupLootFrame" .. i]
		if f then out[#out + 1] = f end
	end
	if GroupLootContainer and type(GroupLootContainer.rollFrames) == "table" then
		for _, f in ipairs(GroupLootContainer.rollFrames) do out[#out + 1] = f end
	end
	return out
end

local function rollLabel(frame)
	if labels[frame] then return labels[frame] end
	local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	fs:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 6, 1)
	local back = frame:CreateTexture(nil, "ARTWORK")
	back:SetColorTexture(0, 0, 0, 0.75)
	back:SetPoint("TOPLEFT", fs, "TOPLEFT", -4, 2)
	back:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 4, -2)
	fs.back = back
	labels[frame] = fs
	return fs
end

local seen = {}
function Rewards.Roll(rollID, quiet)
	if not ns.db or ns.db.rolls == false then return end
	if not GetLootRollItemLink or not rollID then return end
	local ok, link = pcall(GetLootRollItemLink, rollID)
	if not ok or type(link) ~= "string" then return end
	local v = Rewards.Verdict(link)
	for _, f in ipairs(rollFrames()) do
		if f.rollID == rollID then
			local fs = rollLabel(f)
			if v then
				fs:SetText(v.text .. (v.slot and (v.kind == "up" or v.kind == "down") and (" vs " .. v.slot) or ""))
				fs:SetTextColor(v.color[1], v.color[2], v.color[3])
				fs:Show()
				fs.back:Show()
			else
				fs:Hide()
				fs.back:Hide()
			end
		end
	end
	if v and not quiet and not seen[rollID] and ns.db.rollChat ~= false then
		seen[rollID] = true
		if v.kind == "up" or v.kind == "down" then
			ns.Print(link .. "  " .. v.text .. (v.slot and (" vs " .. v.slot) or ""))
		end
	end
	return v
end

function Rewards.Options()
	local UI = ns.UI
	local db = ns.db
	local function on(key)
		return {
			text = key[2], checked = db[key[1]] ~= false,
			func = function() db[key[1]] = db[key[1]] == false end,
		}
	end
	return {
		{ text = "Upgrade hints", title = true },
		UI.Check(db, "tooltip", "Score and gain in item tooltips"),
		on({ "rewards", "Mark upgrades on quest rewards" }),
		on({ "rewardChat", "Say the best quest reward in chat" }),
		on({ "rolls", "Mark upgrades on loot rolls" }),
		on({ "rollChat", "Say roll upgrades in chat" }),
	}
end

ns:On("QUEST_COMPLETE", questSoon)
ns:On("QUEST_DETAIL", questSoon)
ns:On("QUEST_ITEM_UPDATE", questSoon)
ns:On("START_LOOT_ROLL", function(rollID)
	if type(rollID) ~= "number" then return end
	ns.After(0.1, function() Rewards.Roll(rollID) end)
	ns.After(0.8, function() Rewards.Roll(rollID, true) end)
end)
ns:On("GET_ITEM_INFO_RECEIVED", function()
	if QuestFrame and QuestFrame.IsShown and QuestFrame:IsShown() then questSoon() end
end)
