local ADDON, ns = ...

local defaults = {
	tooltip = true,
	custom = {},
	window = { scale = 1 },
}

local charDefaults = {
	set = false,
}

ACore.New(ADDON, ns, { db = "AGearDB", defaults = defaults, profile = true, char = "AGearCharDB", charDefaults = charDefaults })

ACore.Register({
	name = "AGear",
	title = "AGear",
	slash = "/agear",
	desc = "gear scores and upgrades",
	toggle = function() ns.Window.Toggle() end,
	options = function() return ns.Rewards.Options() end,
})

AGear = {}

SLASH_AGEAR1 = "/agear"
SLASH_AGEAR2 = "/ag"
SlashCmdList["AGEAR"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "tooltip" then
		ns.db.tooltip = not ns.db.tooltip
		ns.Print("tooltip scores " .. (ns.db.tooltip and "on" or "off"))
	elseif msg == "reset" then
		ns.db.window.pos = nil
		ns:Fire("LAYOUT_RESET")
	elseif msg == "upgrades" or msg == "weights" or msg == "character" then
		ns.Window.Show(msg)
	else
		ns.Window.Toggle()
	end
end

BINDING_HEADER_AGEAR = "AGear"
BINDING_NAME_AGEAR_TOGGLE = "Toggle AGear"
function AGear_ToggleBinding()
	ns.Window.Toggle()
end
