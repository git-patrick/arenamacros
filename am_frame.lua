local NUM_AMFRAME_TABS = 2

UIPanelWindows["AMFrame"] = { area = "left", pushable = 1, whileDead = 1 };

amMacroFrame = AMFrameTab1FrameView1

function amMacroFrame_New(self, button, down)
    -- find the lowest number for which UntitledMacro ## is not already in the container.
    -- this will generally succeed immediately or almost immediately.  Additionally, the maximum macro count
    
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

function amMacroFrame_Refresh()
    am.addons.check()
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


function amFrameTab_OnClick(self, button, down)
    for i = 1, NUM_AMFRAME_TABS do
        _G["AMFrameTab" .. i .. "Frame"]:Hide()
    end
    
    _G[self:GetName() .. "Frame"]:Show()
end