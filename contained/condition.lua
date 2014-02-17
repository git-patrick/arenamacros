local addon_name, e = ...

local libutil		= e:lib("utility")

local libcontainer	= e:lib("container")
local libwow		= e:lib("wow")

local property		= class.proeprty

local condition = libcontainer:addclass(class.create("modifier", libcontainer:class("contained")))

condition.condition.name = property.custom(
	function (self) return self.amName:GetText() end,
	function (self, value) self.amName:SetText(value) end,
)
condition.condition.relation = property.custom(
	function (self) return self.amRelation:GetText() end,
	function (self, value) self.amRelation:SetText(value); end
)
condition.condition.value = property.custom(
	function (self) return self.amValue:GetText() end,
	function (self, value) self.amValue:SetText(value) end
)
condition.condition.data = property.scalar("am_data")

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

function condition:am_getextension()
	return self.am_extension
end

function condition:am_setextension(extension)
	self.am_extension = extension
end



-- XML EVENT CALLBACKS

function amContainedCondition_OnLoad(self)
	condition:new(nil, self)
end

function amContainedCondition_Delete(self, button, down)
    self:GetParent():am_remove()
end