amConditionFrame = setmetatable({ }, pat.create_index_metatable(AMFrameTab1FrameView3, dataclass_modifier))

function amConditionFrame:am_setproperty(name, value)
    if (name == "modstring") then
        -- ignored
    elseif (name == "text") then
        self.amInput.EditBox:SetText(value)
    elseif (name == "conditions") then
        am.conditions:clear()
        am.conditions:addall(value)
    end
    
    return value
end

function amConditionFrame:am_getproperty(name)
    if (name == "modstring") then
        return self.amName:GetText()
    elseif (name == "text") then
        return { text = self.amRelation:GetText(), data = self.amRelation.am_data }
    elseif (name == "conditions") then
        return am.conditions:get_frames()
    end
    
    return nil
end

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
