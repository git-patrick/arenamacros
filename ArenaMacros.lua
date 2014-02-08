local addon_name, addon_table = ...

local function initialize()
	local test = CreateFrame("Button", UIParent, nil, "amModifier_ListItemTemplate")
end

local am = addon:new({ initialize }, addon_table)
