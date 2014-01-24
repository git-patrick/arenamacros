amModifierFrame = setmetatable({ }, pat.create_index_metatable(AMFrameTab1FrameView2, dataclass_macro))

function amModifierFrame:am_setproperty(name,value)
    if (name == "name") then
        self.amName:SetText(value)
    elseif (name == "icon") then
        SetPortraitToTexture(AMFrame.amPortrait, value)
    elseif (name == "modifiers") then
        am.modifiers:clear()
        am.modifiers:addall(value)
    end
    
    return value
end

function amModifierFrame:am_getproperty(name)
    if (name == "name") then
        return self.amName:GetText()
    elseif (name == "icon") then
        return AMFrame.amPortrait:GetTexture()
    elseif (name == "modifiers") then
        return am.modifiers:get_frames()
    end

    return nil
end

function amModifierFrame_Cancel(self, button, down)
    amModifierFrame:Hide()
    amMacroFrame:Show()
end

function amModifierFrame_Save(self, button, down)
    if (not amModifierFrame.am_macro) then
        print("AM: Selected Macro doesn't exist.  Error should never happen.")
        
        return
    end
    
    amModifierFrame.am_macro:am_set(amModifierFrame)
    amModifierFrame.am_macro = nil

    amModifierFrame:Hide()
    amMacroFrame:Show()
end

function amModifierFrame_New(self, button, down)
    am.modifiers:add(am.blank_modifier)
end

function amModifierFrame_Setup(macro)
    amModifierFrame:am_set(macro)
    amModifierFrame.am_macro = macro
    
    amMacroFrame:Hide()
    amModifierFrame:Show()
end
