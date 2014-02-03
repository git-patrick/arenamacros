local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.views.macrolist = AMFrameTab1FrameView1

function amMacroListFrame_New(self, button, down)
    am.blank_macro:am_setproperty("name", "UntitledMacro")
    
    local r, f
    
    for i=1,99 do
        r, f = am.macros:add(am.blank_macro)
        
        if (not r) then
            break
        end
        
        am.blank_macro:am_setproperty("name", "UntitledMacro " .. i)
    end
    
    if (f) then
        f:Click()
    end
end

function amMacroListFrame_Refresh()
    am.check()
end
