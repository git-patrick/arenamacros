local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

local c = e:lib("container")

 = { mt = { __index = setmetatable({ }, e.util.create_search_indexmetatable(e.dataclass.modifier.li, e.contained.mt)) } }

local mod = e.contained.modifier

function mod.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame or UIParent, "amModifierTemplate"), mod.mt)
    
    return f
end

function mod.mt.__index:am_setindex(i)
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

function mod.mt.__index:am_compare(other)
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
