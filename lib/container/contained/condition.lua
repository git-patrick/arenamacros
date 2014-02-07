local addon_name, addon_table = ...

local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

-- Create our namespace in the engine.
e.contained.condition = { mt = { __index = setmetatable({ }, e.util.create_search_indexmetatable(e.dataclass.condition.li, e.contained.mt)) } }

local cond = e.contained.condition

function cond.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame or UIParent, "amConditionTemplate"), cond.mt)
    
    return f
end

function cond.mt.__index:am_setindex(i)
    self.am_index = i
    
    local intro = "and"
    local outro = ""
    
    if (i == 1) then
        intro = "if"
    end
    
    if (i == am.conditions:count()) then
        outro = "then"
    end
    
    self.amIntroString:SetText(intro)
    self.amOutroString:SetText(outro)
end







-- XML EVENT CALLBACKS, THESE REFERENCE THE GLOBAL am ELEMENT

function amCondition_Delete(self, button, down)
    am.conditions:remove(self:GetParent():am_getindex())
end