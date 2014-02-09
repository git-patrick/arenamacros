local addon_name, e = ...

local libutil = e:lib("utility")

local libcontainer = e:lib("container")
local libdc = e:lib("dataclass")


-- setup the properties list here.....
local mod_dataclass = libcontainer:addclass(libdc:new("modifier_dataclass", PROPERTIES_LIST_HERE))
local modifier		= libcontainer:addclass(class.create("modifier"), libcontainer:class("contained"), mod_dataclass)

function modifier:init()
	
end

function modifier:am_setindex(i)
    self.am_index = i
    self.am_moveto = nil
    
    if (i <= 1) then
        self.amMoveUp:Disable()
    else
        self.amMoveUp:Enable()
    end
    
    if (i >= self.am_container:count()) then
        self.amMoveDown:Disable()
    else
        self.amMoveDown:Enable()
    end
    
    self.amModID:SetText(i)
end

function modifier:am_compare(other)
    if not other.am_moveto then
        return 0
    end
    
    if (self:am_getindex() == other.am_moveto) then
        return 1
    end
    
    return 0
end






function amModifier_OnLoad(self)
	-- turn me into a modifier class object!
	modifier:new(nil, self)
end


function amModifier_OnClick(self, button, down)
    amConditionFrame_Setup(self)
end

function amModifier_MoveUp(self, button, down)
    local mod = self:GetParent()
    
    mod.am_moveto = math.max(mod:am_getindex() - 1, 1)
    mod:am_resort()
end

function amModifier_MoveDown(self, button, down)
    local mod = self:GetParent()
    
    mod.am_moveto = math.min(mod:am_getindex() + 1, mod.am_container:count())
    mod:am_resort()
end

function amModifier_Delete(self, button, down)
    am.modifiers:remove(self:GetParent():am_getindex())
end
