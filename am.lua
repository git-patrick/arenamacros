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
    name = "Untitled Macro",
    icon = "Interface\\ICONS\\INV_Misc_QuestionMark",
    modifiers = {
        am.blank_modifier
    }
}

function am.events.PLAYER_REGEN_ENABLED()
    am:UnregisterEvent("PLAYER_REGEN_ENABLED")

    am.events.PLAYER_ENTERING_WORLD()
end

function am.events.PLAYER_ENTERING_WORLD()

end

function am.events.ADDON_LOADED(name)
    if (name ~= "ArenaMacros") then
        return
    end

    am.macros      = am_container.create(AMMacroList, am_macro.create)
    am.modifiers   = am_container.create(AMMacroModifierList, am_modifier.create)
    am.conditions  = am_container.create(AMMacroModifierConditionList, am_condition.create)

    local db = {
        am.blank_macro,
        am.blank_macro
    }
    
    am.macros:addall(db)
end

function am.make_macros(tbl)
    for n, obj in pairs(tbl) do
        if (type(obj) == "string") then
            am.make_macro(n, obj)
        end
    end
end

function am.make_macro(name, arenamacro_string)
    -- replace my tokens, trim the beginning and end of whitespace, and the beginning and end of lines of whitespace
    local ret = ""
    
    for line in arenamacro_string:gmatch("[^\r\n]+") do
        ret = ret .. pat.trim(line) .. "\n"
    end

    for token, uid in pairs(am.tokens) do
        ret = ret:gsub(token, uid)
    end

    pat.make_macro(name, "INV_MISC_QUESTIONMARK", ret, 1)
end

function am.initialize()
    am:SetScript("OnEvent", function(frame, event, ...) frame.events[event](...) end)

    am:RegisterEvent("ADDON_LOADED")
    am:RegisterEvent("PLAYER_ENTERING_WORLD")
end

am.initialize()