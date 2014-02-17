local addon_name, am = ...

local function initialize()
	print("INITIALIZE")
	
	local MyFrame = CreateFrame("Frame")
	MyFrame:ClearAllPoints()
	MyFrame:SetBackdrop(StaticPopup1:GetBackdrop())
	MyFrame:SetHeight(300)
	MyFrame:SetWidth(300)
	MyFrame:SetPoint("CENTER")
	
	local pool = am:lib("utility"):class("pool"):new({ function () return CreateFrame("Button", UIParent, nil, "amContainedModifierTemplate") end })
	
	local container = am:lib("container"):class("container"):new({ "modifier", pool }, MyFrame)
	
	local mod_simple = am:class("modifier_simple")
	
	MyFrame:Show()
	
	container:add(mod_simple:new({ "TEXT", "MODSTRING", nil }))
end

addon:new({ initialize }, am, nil, true)