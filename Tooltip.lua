local _, ns = ...

local function addLines(tooltip, item)
	if not ns.db or not ns.db.tooltip or not item then return end
	local score, delta, slot, current, usable = ns.Compare(item)
	if not score then return end
	local right = ""
	local r, g, b = 0.58, 0.6, 0.65
	if usable == false then
		right = "not usable"
	elseif delta then
		if delta > 0.05 then
			right = string.format("+%.1f", delta)
			r, g, b = 0.25, 0.9, 0.25
		elseif delta < -0.05 then
			right = string.format("%.1f", delta)
			r, g, b = 1, 0.3, 0.3
		else
			right = "same"
		end
		if slot and ns.SLOTNAME[slot] and right ~= "same" then right = right .. " vs " .. ns.SLOTNAME[slot] end
	end
	tooltip:AddDoubleLine(string.format("AGear score %.1f", score), right, 1, 0.82, 0, r, g, b)
	tooltip:Show()
end

local function fromData(tooltip, data)
	if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
	local item
	if tooltip.GetItem then
		local ok, _, link = pcall(tooltip.GetItem, tooltip)
		if ok and type(link) == "string" and not ns.IsSecret(link) then item = link end
	end
	if not item and data and type(data.id) == "number" and not ns.IsSecret(data.id) then item = data.id end
	addLines(tooltip, item)
end

ns:Listen("LOGIN", function()
	local hooked = false
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		hooked = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, function(tooltip, data)
			pcall(fromData, tooltip, data)
		end)
	end
	if not hooked and GameTooltip and GameTooltip.HookScript then
		pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", function(tooltip)
			pcall(fromData, tooltip, nil)
		end)
	end
end)
