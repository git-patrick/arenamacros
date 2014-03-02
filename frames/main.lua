local addon_name, e = ...

UIPanelWindows["amFrame"] = { area = "left", pushable = 1, whileDead = 1 };


function amFrame_Show()
    ShowUIPanel(amFrame)
end




function amFrame_OnShow(self)
    PlaySound("igCharacterInfoOpen");
end
function amFrame_OnHide(self)
    PlaySound("igCharacterInfoClose");
end





function amFrameView1_OnShow(self)
	amFrame.amPortrait:SetTexture("Interface\\MacroFrame\\MacroFrame-Icon")
end

function amFrameView1_amNew_OnClick(button)

end
function amFrameView1_amRefresh_OnClick(button)

end







function amFrameView2_amCancel_OnClick(button)

end
function amFrameView2_amSave_OnClick(button)

end
function amFrameView2_amRename_OnClick(button)

end








function amFrameView3_amCancel_OnClick(button)

end
function amFrameView3_amSave_OnClick(button)

end
function amFrameView3_amNew_OnClick(button)

end





