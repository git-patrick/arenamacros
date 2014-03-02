local addon_name, am = ...

SLASH_ARENAMACROS1 = "/am"

function slashcmd(msg, editbox)
    ShowUIPanel(amFrame)
end


-- If I had infinite time, I would setup some interface class hierachy with event bubbling etc
-- but I don't plan on ever writing another WoW addon, so I am not going to worry about that.
local function initialize()
	SlashCmdList["ARENAMACROS"] = slashcmd
	
	local libutil = am:lib("utility")
	local libcontainer = am:lib("container")

	local pool = libutil:class("pool")
	local uidmap = libcontainer:class("uidmap")
	local container = am:lib("container"):class("container")
	
	am.macro_map = uidmap:new({ "macro", "name" })
	
	local macro_pool = pool:new({
		function () return CreateFrame("Button", UIParent, nil, "amContainedMacroTemplate") end
	})
	local mod_pool = pool:new({
		function () return CreateFrame("Button", UIParent, nil, "amContainedModifierTemplate") end
	})
	local cond_pool = pool:new({
		function () return CreateFrame("Button", UIParent, nil, "amContainedConditionTemplate") end
	})
	
	am.macros = container:new({ "macro", macro_pool, am.macro_map }, amFrameView1List.amSCFrame)
	am.modifiers = container:new({ "modifier", modifier_pool }, amFrameView2List.amSCFrame)
	am.conditions = container:new({ "condition", cond_pool }, amFrameView3List.amSCFrame)
	
	am:register("UPDATE_MACROS", update_macros)
end

local function update_macros()
    --[[
        On every UPDATE_MACRO I need to recheck all the macros, make sure I have
        everyone of on my list.

        if there are some that are present that are NOT in my list, create them
    ]]--
    
    for i = 1,54 do
        local name, icon, body = GetMacroInfo(i)
        
        if name ~= nil then
            if (not am.macro_map:contains(name)) then
                am.macros:add(e:class("macro_simple"):new(name, icon, { { ["text"] = body, ["conditions"] = { } } }, true))
            end
        end
    end
    
    amMacroActive:SetText("Enabled Macros " .. select(2,GetNumMacros()) .. "/" .. MAX_CHARACTER_MACROS)
end

addon:new({ initialize }, am)