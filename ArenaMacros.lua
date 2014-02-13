local addon_name, am = ...

local function initialize()
	local libcontainer	= am:lib("container")
	local libutil		= am:lib("utility")
	local libdc			= am:lib("dataclass")
	
	local frame			= CreateFrame("Frame", nil, UIParent)

	local pool			= libutil:class("pool"):new({ function () return CreateFrame("Button", UIParent, nil, "amContainedModifierTemplate") end })
	local container		= libcontainer:class("container"):new({ "modifier", pool }, frame)
	
	container:SetPoint("CENTER")
	container:SetWidth(400)
	container:SetHeight(200)
	container:ClearAllPoints()
	container:SetBackdrop(StaticPopup1:GetBackdrop())
	container:SetPoint("CENTER",UIParent)
	container:SetScale(1)
	
	local mod_db		= { text = "TEST MACRO TEXT", modstring = "YOYOYO, Modstring here", conditions = { } }
	local mod			= libdc:class("modifier_simple"):new(nil, mod_db)
	
	container:add(mod)
	container:add(mod)
end

addon:new({ initialize }, am)
