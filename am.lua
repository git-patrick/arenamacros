--[[

    The purpose of this addon is to detect where I am in one of three situations, and modify all macros I have to deal with
    those situations.
    
    1) 2v2 Arena = all healing and beneficial spells target party1
    2) 3v3 Arena = all healing and beneficial spells auto target chosen party member, and mod:shift of the same target the other
    3) in both situations, targeted CC must auto target a chosen enemy player.
    4) everywhere else = mostly mouseover stuff for beneficial spells and default target self, and standard target stuff for harmful casts
    
    
    
    
    TODO;;;;;;;;;;;;;;;
        1) instead of automatically changing the macros, I need to create a popup if in arena where you can choose the UIDs for the tokens
        2) need to add support for different arena types (2v2, 3v3, 5v5)
]]--

am = CreateFrame("Frame", nil, UIParent)
am.events = { }

am.blank_condition = {
    name = "true",
    relation = "is",
    value = "true"
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

function am.events.PLAYER_ENTERING_WORLD()
    print("PLAYER_ENTERING_WORLD")
    
    if (am.initialized) then
        return
    end
    
    am.initialized = true
    
    am_conditions_createmenus()
    
    am.macros      = am_container.create(AMMacroList, am_macro.create, "name")  -- name is the unique identifier in macro creation objects
    am.modifiers   = am_container.create(AMMacroModifierList, am_modifier.create)
    am.conditions  = am_container.create(AMMacroModifierConditionList, am_condition.create)
    
    if not AM_MACRO_DATABASE then
        AM_MACRO_DATABASE = am.first_time_initialize()
    end
    
    am.macros:addall(AM_MACRO_DATABASE)
end

-- the first time the addon is loaded for this character we need to save all current macros as macros with single modifiers that evaluate to true.
function am.first_time_initialize()
    -- I NEED TO DEAL WITH MACROS THAT SHARE A NAME.  Must modify them to change duplicate names
    
    local db = { }
    
    for i = 37,54 do
        local name, icon, body = GetMacroInfo(i)
        
        if name ~= nil then
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
    
    return db
end

function am.initialize()
    am:SetScript("OnEvent", function(frame, event, ...) frame.events[event](...) end)

    am:RegisterEvent("PLAYER_ENTERING_WORLD")
end

am.initialize()