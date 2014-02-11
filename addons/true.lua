local addon_name, e = ...

local libwow	= e:lib("wow")

local amaddon	= e:class("amaddon")
local true		= e.amaddons

(amaddon:new({ "true", "Frame", nil }))

function true:get_value()
    return true
end

local frame = class.create("frame", e:class("amaddon_frame"), libwow:class("button"))

function amAddonTrue_OnLoad(self)
	frame:new(nil, self)
end