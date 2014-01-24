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
am.blank_macro = am_database_macro.create({
    name = "UntitledMacro",
    icon = "Interface\\ICONS\\INV_Misc_QuestionMark",
    modifiers = {
        am.blank_modifier
    }
}, nil)



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
    
    return false
    --[[
    for i = 37,54 do
        local name, icon, body = GetMacroInfo(i)
        
        if name ~= nil then
            if (not am.macro_map:contains(name)) then
                local m = am_database_macro.create({
                    ["name"] = name,
                    ["icon"] = icon,
                    ["modifiers"] = { {
                        ["text"] = body,
                        ["conditions"] = { am.blank_condition }
                    } }
                }, am.db)
                
                am.macros:add(m)
            end
        end
    end
    
    AMMacroActive:SetText("Enabled Macros " .. select(2,GetNumMacros()) .. "/" .. MAX_CHARACTER_MACROS)
    ]]--
end

function am.events.PLAYER_ENTERING_WORLD()
    if (am.initialized) then
        return
    end
    
    am.initialized = true
    
    -- make sure this is loaded, since we don't want the arena frames to be nil as the tokens queue tries to hook OnClick
    LoadAddOn("Blizzard_ArenaUI")
    
    am.tokens:init()
    
    am.macro_map   = am_uidmap.create("name")
    
    am.macros      = am_container.create(amMacroList, am_pool.create(am_macro.create), am.macro_map)
    am.modifiers   = am_container.create(amModifierList, am_pool.create(am_modifier.create))
    am.conditions  = am_container.create(amConditionList, am_pool.create(am_condition.create))
    
    am.addons.initialize()
    
    if not AM_MACRO_DATABASE then
        AM_MACRO_DATABASE = { }
    end
    
    am.db = am_database.create(AM_MACRO_DATABASE, "name")
    
    -- setup the database table entries as the database_objects we expect them to be...
    -- this basically just sets up the metatables for these and the modifiers / conditions inside them.
    for i, v in pairs(am.db) do
        am_database_macro.create(v, am.db)
    end
    
    am.macros:addall(am.db)
    
    am.events.UPDATE_MACROS()
    
    -- this can trigger before player_entering_world, so I want it put here to ensure AM_MACRO_DATABASE is atleast { } before register it.
    am:RegisterEvent("UPDATE_MACROS")
end

function am.initialize()
    am:SetScript("OnEvent", function(frame, event, ...) frame.events[event](...) end)

    am:RegisterEvent("PLAYER_ENTERING_WORLD")
end

--[[ INLINE TOKEN SECTION!~ ]]--

am.tokens = {
    ["db"]      = {
        ["arena"] = { },
        ["party"] = { }
    }
}

function am.tokens:init()
    self.queue = queue.create()
end

function am.tokens:_gettoken(bank, msg, uid_list, token_name, callback)
    if (not bank[token_name]) then
        bank[token_name] = token.create(token_name, callback)
        
        self.queue:add(request.create(token, msg, uid_list, function(uid) bank[token_name]:set_value(uid) end))
        
        return "none"
    end
    
    if (bank[token_name]:waiting()) then
        bank[token_name]:push_callback(callback)
        
        return "none"
    end
    
    return bank[token_name]:get_value()
end

function am.tokens:arena(token_name, macro)
    return self:_gettoken(self.db.arena, "Choose arena(\"" .. token_name .. "\")!", { ["arena1"] = true, ["arena2"] = true, ["arena3"] = true, ["arena4"] = true, ["arena5"] = true }, token_name, function () macro:am_checkconditions() end)
end

function am.tokens:party(token_name, macro)
    return self:_gettoken(self.db.party, "Choose party(\"" .. token_name .. "\")!", { ["party1"] = true, ["party2"] = true, ["party3"] = true, ["party4"] = true, ["player"] = true }, token_name, function () macro:am_checkconditions() end)
end

function am.tokens:clear()
    self.queue:clear()
    
    self.db.arena = { }
    self.db.party = { }
end




------------------------------------------------------------------------------------------
--[[  ADDON CONDITIONS SECTION -- any condition addons will need to use this interface!    ]]--

-- TODO: this whole section should be redone with classes and etc etc.  maybe later.
------------------------------------------------------------------------------------------


am.addons = {
    conditions = { },
    menu = { { text = "Conditions", isTitle = "true", notCheckable = true } },
}

function am.addons.check()
    -- this is setup to be called by the addons onchange callback.  whenever a condition's value changes, we recheck everything

    -- forget everything we used to know about the cruel, cruel world
    am.tokens:clear()
    
    for i, v in ipairs(am.macros.frames) do
		v:am_checkconditions()
	end
end

function am.addons.select(self, arg1, arg2, checked)
    am.selected_condition.am_name:SetText(self.value)
    
    am.addons.conditions[self.value].value_init(am.selected_condition.am_value)
    am.addons.conditions[self.value].relation_init(am.selected_condition.am_relation)
end

function am.addons.initialize()
    CreateFrame("Frame", "AMConditionMenuFrame", UIParent, "UIDropDownMenuTemplate")
end

function am.addons.add(addon)
    local name = addon:get_name()
    
    if (am.addons.conditions[name]) then
        print("ERROR:  Multiple addons share the name " .. name)
        
        return
    end
    
    am.addons.conditions[name] = addon
    addon.onchange = am.addons.check
    
    table.insert(am.addons.menu, addon.main_menu)
    
    if (addon.init) then
        addon:init()
    end
end

am.initialize()


