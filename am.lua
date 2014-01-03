--[[

    The addon design has expanded.  It currently manages all your character specific macros (even if another addon messes with them, 
    it can still properly manage them all).  It automatically modifies your macros when conditions that you specify are met.
 
    for example if you have a macro with 2 modifiers, and the first modifier is satisified if you are in an arena, while the second
    is satisified if true is true (which is, obviously, always satisified) then the macro text you specify for the first modifier
    will automatically be set whenever you enter an arena, and in all other circumstances, the second modifiers text will be used for
    your macro.
 
    modifiers are checked from first to last, the first one satisified is used.
 
]]--


am = CreateFrame("Frame", nil, UIParent)
am.events = { }
am.frames = { }     -- condition addon frames are added to this.

am.blank_condition = {
    value = {
        text = "true",
        data = "true"
    },
    relation = {
        text = "is",
        data = "is"
    },
    name = "true"
}
am.blank_modifier = {
    text = "",
    conditions = {
        am.blank_condition
    }
}
am.blank_macro = { 
    name = "UntitledMacro",
    icon = "Interface\\ICONS\\INV_Misc_QuestionMark",
    modifiers = {
        am.blank_modifier
    }
}

function am.slashcmd(msg, editbox)
    ShowUIPanel(AMFrame)
end

-- ADD OUR SLASH COMMANDS HERE!
SLASH_ARENAMACROS1 = "/am"
SlashCmdList["ARENAMACROS"] = am.slashcmd

function am.events.UPDATE_MACROS()
    -- OKAY SO, here is what I want to happen here.
    --[[
        On every UPDATE_MACRO I need to recheck all the macros, make sure I have
        everyone of them in my database and on my list.

        if there are some that are present that are NOT in my list, create them
    ]]--
    
    local db = { }
    
    for i = 37,54 do
        local name, icon, body = GetMacroInfo(i)
        
        if name ~= nil then
            if (not am.macros:contains(name)) then
                db[name] = {
                    ["name"] = name,
                    ["icon"] = icon,
                    ["modifiers"] = { {
                        ["text"] = body,
                        ["conditions"] = { am.blank_condition }
                    } }
                }
            end
        end
    end
    
    am.macros:addall(db)
    
    AMMacroActive:SetText("Enabled Macros " .. select(2,GetNumMacros()) .. "/" .. MAX_CHARACTER_MACROS)
end

function am.events.PLAYER_ENTERING_WORLD()
    if (am.initialized) then
        return
    end
    
    am.initialized = true
    
    am.macros      = am_container.create(AMMacroList, am_macro.create, "name")  -- name is the unique identifier in macro creation objects
    am.modifiers   = am_container.create(AMMacroModifierList, am_modifier.create)
    am.conditions  = am_container.create(AMMacroModifierConditionList, am_condition.create)
    
    am.tokens.selector = am_container.create(AMTokenSelectorList, am_token.selector.create)
    
    am.addons.initialize()
    
    if not AM_MACRO_DATABASE then
        AM_MACRO_DATABASE = { }
    end
    
    am.macros:addall(AM_MACRO_DATABASE)
    
    am.events.UPDATE_MACROS()
    
    -- this can trigger before player_entering_world, so I want it put here to ensure AM_MACRO_DATABASE is atleast { }
    am:RegisterEvent("UPDATE_MACROS")
end

function am.check(tbl, event)
    for i, v in ipairs(am.macros.frames) do
		v:am_checkconditions()
	end
end

function am.initialize()
    am:SetScript("OnEvent", function(frame, event, ...) frame.events[event](...) end)

    am:RegisterEvent("PLAYER_ENTERING_WORLD")
end


------------------------------------------------------------------------------------------
--[[  ADDON CONDITIONS SECTION -- any condition addons will need to use this interface!    ]]--
------------------------------------------------------------------------------------------

am.addons = {
    conditions = { },
    menu = { { text = "Conditions", isTitle = "true", notCheckable = true } }
}

function am.addons.select(self, arg1, arg2, checked)
    am.selected_condition.am_name:SetText(self.value)
    
    am.addons.conditions[self.value].value_init(am.selected_condition.am_value)
    am.addons.conditions[self.value].relation_init(am.selected_condition.am_relation)
end

function am.addons.initialize()
    CreateFrame("Frame", "AMConditionMenuFrame", UIParent, "UIDropDownMenuTemplate")
    CreateFrame("Frame", "AMConditionTriggerFrame", UIParent)
    
    am.addons.add("true",
        {
            test = function (relation, value)
                return value.data == "true"
            end,
            
            value_init = function (button)
                button.am_data = "true"
                button:SetText(button.am_data)
            end,
                  
            relation_init = function (button)
                button.am_data = "is"
                button:SetText(button.am_data)
            end,
            
            value_onclick = function (button)
                if (button.am_data == "true") then
                  button.am_data = "false"
                else
                  button.am_data = "true"
                end
                
                button:SetText(button.am_data)
            end,
            
            relation_onclick = function (button) end,
            
            main_menu = { text = "true", notCheckable = "true", value = "true", leftPadding = "10", func = am.addons.select }
        }
    )
    
    for i,v in pairs(am.addons.conditions) do
        if (v.init) then
            v.init()
        end
    end
    
    AMConditionTriggerFrame:SetScript("OnEvent", am.check)
end

function am.addons.add(name, condition_table)
    if (am.addons.conditions[name]) then
        print("ERROR:  Multiple conditions share the name " .. name)
        
        return
    end
    
    am.addons.conditions[name] = condition_table
    
    table.insert(am.addons.menu, condition_table.main_menu)
end






am.initialize()


