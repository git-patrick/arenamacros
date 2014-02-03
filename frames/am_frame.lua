local NUM_AMFRAME_TABS = 2

UIPanelWindows["AMFrame"] = { area = "left", pushable = 1, whileDead = 1 };

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