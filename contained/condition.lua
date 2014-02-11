local addon_name, e = ...

local libutil		= e:lib("utility")

local libcontainer	= e:lib("container")
local libdc			= e:lib("dataclass")
local libwow		= e:lib("wow")

local property		= libdc:class("property")

-- This part sets up our dataclass class for this "condition" representation.
-- this is used for inheriting purposes in the condition list frame

-- setup the properties list here.....

local condition_properties = {
	["name"]           = property.custom(
		function (self) return self.amName:GetText() end,
		function (self, value) self.amName:SetText(value) end,
	),
	["relation"]       = property.custom(
		function (self) return self.amRelation:GetText() end,
		function (self, value) self.amRelation:SetText(value); end
	),
	["value"]          = property.custom(
		function (self) return self.amValue:GetText() end,
		function (self, value) self.amValue:SetText(value) end
	),
	-- data is where the condition addon stores any of its addon specific information
	["data"]     = property.scalar("am_data")
}

libdc:addclass(libdc:new("condition_contained", condition_properties))

local condition = libcontainer:addclass(class.create("modifier", libcontainer:class("contained"), libdc:class("condition_contained"), libwow:class("button")))

function condition:am_setindex(i)
    self.am_index = i
    
    local intro = "and"
    local outro = ""
    
    if (i == 1) then
        intro = "if"
    end
    
    if (i == self.am_container:count()) then
        outro = "then"
    end
    
    self.amIntroString:SetText(intro)
    self.amOutroString:SetText(outro)
end



-- XML EVENT CALLBACKS

function amContainedCondition_OnLoad(self)
	condition:new(nil, self)
end

function amContainedCondition_Delete(self, button, down)
    self:GetParent():am_remove()
end