local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

local function onload()
	print("WE ARE LOADED YAY")
end

local am = addon:new({ addon = { "Arena Macros", "2.0.0", onload } }, e)

print("WTF")