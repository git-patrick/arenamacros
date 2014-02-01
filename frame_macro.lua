local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.views = e.views or { }
e.views.macro = setmetatable({ }, e.util.create_search_indexmetatable(e.dataclass.macro.frame, AMFrameTab1FrameView2))


--[[
function amModifierFrame_Cancel(self, button, down)
    e.views.modifier:Hide()
    e.views.macro:Show()
end

function amModifierFrame_Save(self, button, down)
    if (not amModifierFrame.am_macro) then
        print("AM: Selected Macro doesn't exist.  Error should never happen.")
        
        return
    end
    
    amModifierFrame.am_macro:am_set(amModifierFrame)
    amModifierFrame.am_macro = nil

    e.views.modifier:Hide()
    e.views.macro:Show()
end

function amModifierFrame_New(self, button, down)
    am.modifiers:add(am.blank_modifier)
end

function amModifierFrame_Setup(macro)
    e.views.macro:am_set(macro)
    e.views.macro.am_macro = macro
    
    e.views.modifier:Show()
    e.views.macro:Hide()
end
]]--