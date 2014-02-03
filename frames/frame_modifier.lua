local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

-- called by modifier's onclick
function amModifierFrame_Setup(modifier)
    e.views.modifier:am_set(modifier)
    e.views.macro.selected_modifier = modifier
    
    e.views.macro:Hide()
    e.views.modifier:Show()
end

function amModifierFrame_New(self, button, down)
    
    e.views.modifier.list:add(am.blank_condition)
    am.conditions:add(am.blank_condition)
end

function amModifierFrame_Save(self, button, down)
    CloseDropDownMenus()
    
    e.views.macro.selected_modifier:am_set(e.views.modifier)
    e.views.macro.selected_modifier = nil
    
    e.views.macro:Show()
    e.views.modifier:Hide()
end

function amModifierFrame_Cancel(self, button, down)
    CloseDropDownMenus()
    
    e.views.macro.selected_modifier = nil
    
    e.views.macro:Show()
    e.views.modifier:Hide()
end