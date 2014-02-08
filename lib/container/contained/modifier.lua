local addon_name, e = ...

local libcontainer = e:lib("container")
local libdc = e:lib("dataclass")

local modifier = libcontainer:addclass(class.create("modifier"), libcontainer:class("contained"), libdc:class("dataclass"))

-- so when creating these things I need to do the following....
-- modifier:new({ modifier = { parent_frame } }, CreateFrame("Button", nil, UIParent, "amModifierTemplate"))


function modifier:init(parent_frame)
    if (parent_frame) then
        self:SetParent(parent_frame)
    end
end

function mod:am_setindex(i)
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

function mod:am_compare(other)
    if not other.am_moveto then
        return 0
    end
    
    if (self:am_getindex() == other.am_moveto) then
        return 1
    end
    
    return 0
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
