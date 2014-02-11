local addon_name, addon_table = ...

local function initialize()
	local test = CreateFrame("Button", UIParent, nil, "amContainedModifierTemplate")
end

local am = addon:new({ initialize }, addon_table)
