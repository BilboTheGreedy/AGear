local _, ns = ...
local UI = ns.UI
local C = UI.colors

local Window = {}
ns.Window = Window

local frame
local state = { tab = "character", group = "ALL", type = "ALL", level = 60 }
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local QUALITY = {
	[0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 }, [2] = { 0.12, 1, 0 }, [3] = { 0, 0.44, 0.87 },
	[4] = { 0.64, 0.21, 0.93 }, [5] = { 1, 0.5, 0 },
}

local function step(v)
	if math.abs(v) >= 5 then return 1 end
	if math.abs(v) >= 1 then return 0.1 end
	return 0.05
end

local function characterRows()
	local rows = {}
	local levels = {}
	for _, s in ipairs(ns.SLOTS) do
		local item, id = ns.Equipped(s[1])
		local row = { kind = "slot", slot = s[1], label = s[2], item = item, id = id }
		if item then
			local info = ns.ItemInfo(item)
			row.info = info
			row.score = ns.Score(item)
			if info and info.ilvl and s[1] ~= 13 and s[1] ~= 14 then levels[#levels + 1] = { info.ilvl, row } end
		end
		rows[#rows + 1] = row
	end
	table.sort(levels, function(a, b) return a[1] < b[1] end)
	for i = 1, math.min(3, #levels) do
		if levels[#levels][1] - levels[i][1] >= 3 then levels[i][2].weak = true end
	end
	local total = 0
	for _, r in ipairs(rows) do total = total + (r.score or 0) end
	table.insert(rows, 1, { kind = "note", text = ns.ActiveSet().name .. string.format("   total score %.1f", total), accent = true })
	return rows
end

local function upgradeRows()
	local Up = ns.Upgrades
	if not Up.Available() then
		return { { kind = "note", text = "The upgrade list needs ALoot. Tooltips and the other tabs work without it." } }
	end
	Up.wanted = true
	if #Up.rows == 0 and not Up.running and not Up.started then
		Up.started = true
		Up.Start()
	end
	local rows = Up.Rows({ group = state.group, type = state.type, level = state.level })
	if Up.running then
		table.insert(rows, 1, { kind = "note", text = "Scoring items " .. Up.progress .. " / " .. Up.total, dim = true })
	elseif Up.missing > 0 then
		table.insert(rows, 1, { kind = "note", text = Up.missing .. " items are still loading from the server", dim = true })
	end
	if #rows == 0 then rows[1] = { kind = "note", text = "No upgrades match these filters." } end
	return rows
end

local function weightRows()
	local rows = { { kind = "note", text = ns.ActiveSet().name .. (ns.Edited() and "   (edited)" or ""), accent = true } }
	local w = ns.Weights()
	for _, s in ipairs(ns.STATS) do
		rows[#rows + 1] = { kind = "weight", stat = s[1], label = s[2], value = w[s[1]] or 0 }
	end
	return rows
end

local function showTip(row)
	local d = row.data
	if not d then return end
	local item = d.item or d.id
	if not item or (d.kind ~= "slot" and d.kind ~= "upgrade") then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	local link = type(item) == "string" and item or ("item:" .. item)
	local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
	if ok then GameTooltip:Show() end
end

local function createRow(list)
	local row = CreateFrame("Button", nil, list)
	row.hl = UI.Fill(row, C.hover, "HIGHLIGHT")
	row.band = UI.Fill(row, { 1, 0.3, 0.3, 0.1 })
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(22, 22)
	row.icon:SetPoint("LEFT", 8, 0)
	row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	row.right = UI.Text(row, "GameFontHighlightSmall", "RIGHT", C.dim)
	row.right:SetPoint("RIGHT", -8, 0)
	row.text = UI.Text(row, "GameFontHighlight")
	row.text:SetPoint("LEFT", 38, 0)
	row.text:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
	row.plus = UI.Button(row, "+", function()
		local d = row.data
		if d and d.kind == "weight" then ns.SetWeight(d.stat, d.value + step(d.value)) end
	end)
	row.plus:SetPoint("RIGHT", -8, 0)
	row.plus:SetWidth(24)
	row.minus = UI.Button(row, "-", function()
		local d = row.data
		if d and d.kind == "weight" then ns.SetWeight(d.stat, d.value - step(d.value)) end
	end)
	row.minus:SetPoint("RIGHT", row.plus, "LEFT", -4, 0)
	row.minus:SetWidth(24)
	row.value = UI.Button(row, "0", function()
		local d = row.data
		if d and d.kind == "weight" then
			UI.Prompt("Weight for " .. d.label, tostring(d.value), function(text)
				local v = tonumber((tostring(text or ""):gsub(",", ".")))
				if v then ns.SetWeight(d.stat, v) end
			end)
		end
	end)
	row.value:SetPoint("RIGHT", row.minus, "LEFT", -4, 0)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetScript("OnEnter", showTip)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row:SetScript("OnClick", function(self)
		local d = self.data
		if not d or d.kind ~= "upgrade" or type(ALoot) ~= "table" then return end
		if IsShiftKeyDown and IsShiftKeyDown() then
			if type(ALoot.WishToggle) == "function" then
				pcall(ALoot.WishToggle, d.id)
				Window.Refresh()
			end
		elseif type(ALoot.Open) == "function" then
			pcall(ALoot.Open, d.id)
		end
	end)
	return row
end

local function itemText(row, info, id)
	local q = QUALITY[info and info.quality or 1] or QUALITY[1]
	row.text:SetText(info and info.name or ("Item " .. tostring(id)))
	row.text:SetTextColor(q[1], q[2], q[3])
	row.icon:SetTexture(info and info.icon or QUESTION)
	row.icon:Show()
end

local function updateRow(row, d)
	row.band:Hide()
	row.icon:Hide()
	row.plus:Hide()
	row.minus:Hide()
	row.value:Hide()
	row.right:ClearAllPoints()
	row.right:SetPoint("RIGHT", -8, 0)
	row.right:SetText("")
	row.hl:SetShown(d.kind ~= "note")
	if d.kind == "slot" then
		if d.item then
			itemText(row, d.info, d.id)
			local ilvl = d.info and d.info.ilvl and ("ilvl " .. d.info.ilvl .. "   ") or ""
			row.right:SetText(d.label .. "   " .. ilvl .. (d.score and string.format("%.1f", d.score) or "..."))
		else
			row.text:SetText("Empty")
			row.text:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
			row.icon:SetTexture(QUESTION)
			row.icon:Show()
			row.right:SetText(d.label)
		end
		row.band:SetShown(d.weak or (not d.item and d.slot ~= 17 and d.slot ~= 18))
	elseif d.kind == "upgrade" then
		local info = ns.ItemInfo(d.id)
		itemText(row, info, d.id)
		local src = d.source ~= "" and ("   " .. d.source) or ""
		row.right:SetText(string.format("|cff40e640+%.1f|r   %s%s", d.delta, d.group or "", src))
	elseif d.kind == "weight" then
		row.text:SetText(d.label)
		local c = d.value ~= 0 and C.text or C.dim
		row.text:SetTextColor(c[1], c[2], c[3])
		row.plus:Show()
		row.minus:Show()
		row.value:SetLabel(tostring(d.value))
		row.value:Show()
	else
		row.text:SetText(d.text or "")
		local c = d.accent and C.accent or (d.dim and C.dim or C.text)
		row.text:SetTextColor(c[1], c[2], c[3])
	end
end

local function pick(anchor, list, key)
	local entries = {}
	for _, e in ipairs(list) do
		entries[#entries + 1] = {
			text = e[2], checked = state[key] == e[1],
			func = function()
				state[key] = e[1]
				Window.Refresh()
			end,
		}
	end
	UI.Menu(anchor, entries)
end

local function setMenu(anchor)
	local entries = { { text = "Stat weights", title = true } }
	local active = ns.ActiveSet().key
	for _, s in ipairs(ns.ClassSets(ns.playerClass)) do
		entries[#entries + 1] = { text = s.name, checked = s.key == active, func = function() ns.SetActive(s.key) end }
	end
	entries[#entries + 1] = { text = "Other classes", title = true }
	for _, s in ipairs(ns.SETS) do
		if s.class and s.class ~= ns.playerClass then
			entries[#entries + 1] = { text = s.name, checked = s.key == active, func = function() ns.SetActive(s.key) end }
		end
	end
	entries[#entries + 1] = { text = "Options", title = true }
	entries[#entries + 1] = UI.Check(ns.db, "tooltip", "Scores in item tooltips")
	UI.Menu(anchor, entries)
end

local TABS = { { "character", "Character" }, { "upgrades", "Upgrades" }, { "weights", "Weights" } }
local LEVELS = { { 60, "Up to level 60" }, { 50, "Up to level 50" }, { 40, "Up to level 40" }, { 30, "Up to level 30" }, { 20, "Up to level 20" } }

local function build()
	frame = UI.Window("AGearFrame", "AGear", 760, 560, ns.db.window)
	local bar = frame.bar
	frame.tabs = {}
	local anchor
	for i, t in ipairs(TABS) do
		local b = UI.Button(bar, t[2], function()
			state.tab = t[1]
			Window.Refresh()
		end)
		if anchor then
			b:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
		else
			b:SetPoint("LEFT", 100, 0)
		end
		anchor = b
		frame.tabs[i] = b
	end
	local set = UI.Button(bar, "Weights", function(self) setMenu(self) end)
	set:SetPoint("RIGHT", frame.close, "LEFT", -6, 0)
	frame.setButton = set

	local body = frame.body
	local tools = CreateFrame("Frame", nil, body)
	tools:SetPoint("TOPLEFT")
	tools:SetPoint("TOPRIGHT")
	tools:SetHeight(32)
	UI.Fill(tools, { 0.075, 0.08, 0.1, 1 })
	frame.info = UI.Text(tools, "GameFontDisableSmall", "LEFT", C.dim)
	frame.info:SetPoint("LEFT", 10, 0)
	frame.slotButton = UI.Button(tools, "All slots", function(self) pick(self, ns.GROUPS, "group") end)
	frame.slotButton:SetPoint("RIGHT", -10, 0)
	frame.typeButton = UI.Button(tools, "Any source", function(self) pick(self, ns.KINDS, "type") end)
	frame.typeButton:SetPoint("RIGHT", frame.slotButton, "LEFT", -6, 0)
	frame.levelButton = UI.Button(tools, "Up to level 60", function(self) pick(self, LEVELS, "level") end)
	frame.levelButton:SetPoint("RIGHT", frame.typeButton, "LEFT", -6, 0)
	frame.resetButton = UI.Button(tools, "Reset to default", function() ns.ResetWeights() end)
	frame.resetButton:SetPoint("RIGHT", -10, 0)
	frame.info:SetPoint("RIGHT", frame.levelButton, "LEFT", -8, 0)

	local list = UI.List(body, 28, createRow, updateRow)
	list:SetPoint("TOPLEFT", 0, -34)
	list:SetPoint("BOTTOMRIGHT", 0, 2)
	frame.list = list
end

local function label(list, value)
	for _, e in ipairs(list) do
		if e[1] == value then return e[2] end
	end
	return list[1][2]
end

function Window.Refresh()
	if not frame or not frame:IsShown() then return end
	local rows, info
	if state.tab == "upgrades" then
		rows = upgradeRows()
		info = "Click: open in ALoot    Shift-click: wishlist"
	elseif state.tab == "weights" then
		rows = weightRows()
		info = "Score = each stat times its weight. Click a value to type it."
	else
		rows = characterRows()
		info = "Red rows are your weakest slots by item level."
	end
	for i, t in ipairs(TABS) do frame.tabs[i]:SetActive(state.tab == t[1]) end
	local up = state.tab == "upgrades"
	frame.slotButton:SetShown(up)
	frame.typeButton:SetShown(up)
	frame.levelButton:SetShown(up)
	frame.resetButton:SetShown(state.tab == "weights")
	frame.slotButton:SetLabel(label(ns.GROUPS, state.group))
	frame.slotButton:SetActive(state.group ~= "ALL")
	frame.typeButton:SetLabel(label(ns.KINDS, state.type))
	frame.typeButton:SetActive(state.type ~= "ALL")
	frame.levelButton:SetLabel(label(LEVELS, state.level))
	frame.levelButton:SetActive(state.level ~= 60)
	frame.setButton:SetLabel(ns.ActiveSet().name)
	frame.info:SetText(info)
	frame.list:SetData(rows, frame.lastTab == state.tab)
	frame.lastTab = state.tab
end

function Window.Show(tab)
	if not frame then build() end
	if tab then state.tab = tab end
	frame:Show()
	Window.Refresh()
end

function Window.Hide()
	if frame then frame:Hide() end
end

function Window.Toggle()
	if frame and frame:IsShown() then
		Window.Hide()
	else
		Window.Show()
	end
end

ns:Listen("WEIGHTS", function() Window.Refresh() end)
ns:Listen("GEAR", function() Window.Refresh() end)
ns:Listen("ITEMS", function() Window.Refresh() end)
ns:Listen("UPGRADES", function() Window.Refresh() end)
ns:Listen("LAYOUT_RESET", function()
	if frame then frame:Restore() end
end)
