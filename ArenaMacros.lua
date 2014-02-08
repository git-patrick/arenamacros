local addon_name, addon_table = ...

local function initialize()
	print("WE ARE LOADED YAY")
end

local am = addon:new({ initialize }, addon_table)
