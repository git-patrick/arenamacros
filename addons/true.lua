local addon_name, e = ...

local libwow		= e:lib("wow")
local libutility	= e:lib("utility")
local libextension	= e:lib("extension")

local extension		= libextension:class("extension")

local true_pool		= libutility:class("pool"):new({ function() return CreateFrame("Button", UIParent, nil, "amExtensionTrueTemplate") end })
local true			= extension:new({ "true", true_pool, nil }))

function true:get_value()
    return true
end

function amExtensionTrue_OnLoad(self)
	libextension:class("extension_frame"):new({ true }, self)
end