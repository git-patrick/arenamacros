local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.views = { }
e.views.macro       = setmetatable(AMFrameTab1FrameView2, e.util.create_search_indexmetatable(e.dataclass.macro.frame, CreateFrame("Frame", nil, UIParent)))
e.views.modifier    = setmetatable(AMFrameTab1FrameView3, e.util.create_search_indexmetatable(e.dataclass.modifier.frame, CreateFrame("Frame", nil, UIParent)))






function amMacroFrame_Cancel(self, button, down)
    e.views.macro:Hide()
    e.views.macro_list:Show()
end

function amMacroFrame_Save(self, button, down)
    e.views.macro_list.selected_macro:am_set(e.views.macro)
    
    e.views.macro:Hide()
    e.views.macro_list:Show()
end

function amMacroFrame_New(self, button, down)
    am.modifiers:add(am.blank_modifier)
end

function amMacroFrame_Setup(macro)
    e.views.macro:am_set(macro)
    
    e.views.modifier:Show()
    e.views.macro:Hide()
end
