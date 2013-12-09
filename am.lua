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
    
    am_conditions_initialize()
    
    am.macros      = am_container.create(AMMacroList, am_macro.create, "name")  -- name is the unique identifier in macro creation objects
    am.modifiers   = am_container.create(AMMacroModifierList, am_modifier.create)
    am.conditions  = am_container.create(AMMacroModifierConditionList, am_condition.create)
    
    if not AM_MACRO_DATABASE then
        AM_MACRO_DATABASE = { }
    end
    
    am.events.UPDATE_MACROS()
    
    -- this can trigger before player_entering_world, so I want it put here to ensure AM_MACRO_DATABASE is atleast { }
    am:RegisterEvent("UPDATE_MACROS")
end

function am.initialize()
    am:SetScript("OnEvent", function(frame, event, ...) frame.events[event](...) end)

    am:RegisterEvent("PLAYER_ENTERING_WORLD")
end

am.initialize()