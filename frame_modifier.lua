local addon_name, addon_table = ...

local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.views = e.views or { }
e.views.modifier = setmetatable({ }, e.util.create_search_indexmetatable(e.dataclass.modifier.frame, AMFrameTab1FrameView3))



--[[
-- called by modifier's onclick
function amConditionFrame_Setup(modifier)
    amConditionFrame:am_set(modifier)
    amConditionFrame.am_modifier = modifier
    
    amModifierFrame:Hide()
    amConditionFrame:Show()
end

function amConditionFrame_New(self, button, down)
    am.conditions:add(am.blank_condition)
end



-- WHAT AM I WORKING ON HERE!!!
-- im making these Frame objects dataclass objects to easily set / get their properties for saving.
-- what else do I need to do !?   there is an issue with how I am dealing with properties that are lists of tables.
-- they are currently just references, but that is all wrong.  I need to make copies.

function amConditionFrame_Save(self, button, down)
    CloseDropDownMenus()
    
    if (not am.selected_modifier) then
        print("am: error should never happen")
        
        return
    end
    
    local conds = { }
    
    for i,v in ipairs(am.conditions.frames) do
        local t = {
            name = v.am_name:GetText(),
            relation = {
                text = v.am_relation:GetText(),
                data = v.am_relation.am_data
            },
            value = {
                text = v.am_value:GetText(),
                data = v.am_value.am_data
            }
        }
        
        table.insert(conds, t)
    end
    
    am.selected_modifier:am_set({
        text = v3.am_inputsf.EditBox:GetText(),
        conditions = conds
    })
    
    am.selected_modifier = nil
end

function amConditionFrame_Cancel(self, button, down)
    local v2 = AMFrameTab1FrameView2
    local v3 = AMFrameTab1FrameView3
    
    am.selected_modifier = nil
    
    CloseDropDownMenus()
    
    v3:Hide()
    v2:Show()
end
]]--