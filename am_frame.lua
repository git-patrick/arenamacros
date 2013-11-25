local NUM_AMFRAME_TABS = 4

UIPanelWindows["AMFrame"] = { area = "left", pushable = 1, whileDead = 1 };

function amMacroFrame_New(self, button, down)
    -- need to check if there is still room for another macro!  if so, create it, and get the ID of the newly created macro, and set it here.

    am.macros:add(am.blank_macro)
end

function amModifierFrame_New(self, button, down)
    am.modifiers:clear()
    am.modifiers:add(am.blank_modifier)
end

function amModifierFrame_Cancel(self, button, down)
    local v1 = AMFrameTab1FrameView1
    local v2 = AMFrameTab1FrameView2
    
    v2:Hide()
    v1:Show()
end

function amModifierFrame_Save(self, button, down)

    -- need to go through all the modifiers and put them into the appropriate macro, then conditions need to get rechecked and actual macros updated.
    -- lets create the table that we are replacing the macros modifiers with

    local v1 = AMFrameTab1FrameView1
    local v2 = AMFrameTab1FrameView2
    
    v2:Hide()
    v1:Show()
    
    if (not am.selected_macro) then
        print("am: error should never happen")
        
        return
    end
    
    local mods = { }
    
    for i,v in ipairs(am.modifiers.frames) do
        local t = {
            modstring = v.am_modstring:GetText(),
            conditions = v.am_conditions
        }

        table.insert(mods, t)
    end

    am.selected_macro:am_set({
        name = v2.am_name:GetText(),
         -- need to change the icon, still need to create a frame to select it.  also, probably want this on a per modifier basis!??! maybe
        modifiers = mods
    })
end

function amModifierFrame_New(self, button, down)
    am.modifiers:add(am.blank_modifier)
end

function amModifierFrame_Delete(self, button, down)
    -- this actually deletes the macro!  so, need to do something about that.
    
    am.macros:remove(am.selected_macro:am_getindex())
    
    local v1 = AMFrameTab1FrameView1
    local v2 = AMFrameTab1FrameView2
    
    v2:Hide()
    v1:Show()
end

function amConditionFrame_New(self, button, down)
    am.conditions:add(am.blank_condition)
end
function amConditionFrame_Save(self, button, down)
    local v2 = AMFrameTab1FrameView2
    local v3 = AMFrameTab1FrameView3
    
    v3:Hide()
    v2:Show()
    
    if (not am.selected_modifier) then
        print("am: error should never happen")
        
        return
    end
    
    local conds = { }
    
    for i,v in ipairs(am.conditions.frames) do
        local t = {
            name = v.am_name:GetText(),
            relation = v.am_relation:GetText(),
            value = v.am_value:GetText()
        }
        
        table.insert(conds, t)
    end
    
    am.selected_modifier:am_set({
        text = v3.am_inputsf.EditBox:GetText(),
        conditions = conds
    })
end

function amConditionFrame_Cancel(self, button, down)
    local v2 = AMFrameTab1FrameView2
    local v3 = AMFrameTab1FrameView3
    
    v3:Hide()
    v2:Show()
end

function amConditionFrame_Delete(self, button, down)
    -- actually deleting the selected modifier from the macro
    
    am.modifiers:remove(am.selected_modifier:am_getindex())
    
    local v2 = AMFrameTab1FrameView2
    local v3 = AMFrameTab1FrameView3
    
    v3:Hide()
    v2:Show()
end

function amMacro_OnClick(self, button, down)
    SetPortraitToTexture(AMFrame.amPortrait, self.am_icon:GetTexture())
    
    local v1 = AMFrameTab1FrameView1
    local v2 = AMFrameTab1FrameView2

    v2.am_name:SetText(self.am_name:GetText())

    am.modifiers:clear()
    am.modifiers:addall(self.am_modifiers)
    
    am.selected_macro = self

    v1:Hide()
    v2:Show()
end

function amMacroModifier_OnClick(self, button, down)
    local v2 = AMFrameTab1FrameView2
    local v3 = AMFrameTab1FrameView3

    am.conditions:clear()
    am.conditions:addall(self.am_conditions)
    
    v3.am_inputsf.EditBox:SetText(self.am_text)        -- it must be called editbox for InputScrollFrame_OnLoad
    v3.am_name:SetText(am.selected_macro.am_name:GetText() .. " - Modifier " .. self:am_getindex())
    
    am.selected_modifier = self

    v2:Hide()
    v3:Show()
end

function amMacroModifierCondition_Delete(self, button, down)
    am.conditions:remove(self:GetParent():am_getindex())
end

function amMacroModifier_Delete(self, button, down)
    am.modifiers:remove(self:GetParent():am_getindex())
end

function amMacro_Delete(self, button, down)
    am.macros:remove(self:GetParent():am_getindex())
end


function amFrame_Show()
    ShowUIPanel(AMFrame)
end

function amFrame_OnLoad(self)
	PanelTemplates_SetNumTabs(self, NUM_AMFRAME_TABS);
	PanelTemplates_SetTab(self, 1);
end

function amFrame_OnShow(self)
    PlaySound("igCharacterInfoOpen");
end

function amFrame_OnHide(self)
    PlaySound("igCharacterInfoClose");
end

function amFrame_OnEvent(self, event, ...)

end