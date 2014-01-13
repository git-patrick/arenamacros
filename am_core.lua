-- am_macro, am_modifier, and am_condition are all designed to be used with am_container.

if MAX_CHARACTER_MACROS == nil then
    MAX_CHARACTER_MACROS = 18
end

-- OBJECTS EXPECTED TO BE INSIDE AN am_container MUST INHERIT FROM am_contained OR PROVIDE ITS METHODS AND Frames methods
am_macro = { uid = 0, mt = { __index = { } } }
setmetatable(am_macro.mt.__index, am_contained.mt)

function am_macro.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroTemplate"), am_macro.mt)

    f:SetScript("OnEvent", function(self, event, ...) self:am_event(event, ...) end)
    f:RegisterEvent("UPDATE_MACROS")
    
    -- the purpose of this frame is to override the 255 character limit placed on macros.  
    -- it stores our chosen macro text, and can be run with a /click FrameName from the actual macro
    
    f.am_securemacrobtn = CreateFrame("Button", "AMSecureMacroButtonFrame" .. am_macro.uid, UIParent, "SecureActionButtonTemplate")
    
    f.am_securemacrobtn:SetAttribute("type", "macro")
    f.am_securemacrobtn:SetAttribute("macrotext", "")

    am_macro.uid = am_macro.uid + 1
    
    return f
end

-- setup our am_contained:am_getuid() override, this defines what property makes us unique in the container.  changes to this property must go through am_setuid() from am_contained
function am_macro.mt.__index:am_getuid()
    return self.am_name:GetText()
end
-- this is used by the container to sort our macros automatically.
function am_macro.mt.__index:am_compare(other)
    local me = self.am_name:GetText():lower()
    local yu = other.am_name:GetText():lower()
    
    return (me <= yu) and ((me < yu) and -1 or 0) or 1
end

function am_macro.mt.__index:am_onremove()
    -- disable ourselves first (this will delete the wow macro)
    self:am_disable()
    
    -- remove the reference in our database
    AM_MACRO_DATABASE[self.am_name:GetText()] = nil
end

function am_macro.mt.__index:am_onadd(object)
    -- this is called everytime I insert into the container, so for New Macro button, and on load when I am initializing from the DB
    -- or whenever UPDATE_MACROS is fired and we find a new macro that was added in some other way.
    
    self:am_setdata(object)
    self:am_updatedb()
    
    -- attempt to create the wow macro
    self:am_createwowmacro()

    -- check our status (is the macro created, set our enabled flag etc)
    self:am_checkstatus()
end

function am_macro.mt.__index:am_setdata(object)
    if (object.name) then self.am_name:SetText(object.name) end
    if (object.icon) then self.am_icon:SetTexture(object.icon) end
    if (object.modifiers) then
        self.am_modifiers = object.modifiers
    end
    
    local n = self.am_modifiers and table.getn(self.am_modifiers) or 0
    
    self.am_nummodifiers:SetText(n .. " mod")
end

function am_macro.mt.__index:am_checkstatus()
    local enable
    
    if (GetMacroIndexByName(self.am_name:GetText()) > 0) then
        enable = true
    else
        enable = false
    end
    
    self.am_name:SetFontObject(enable and "GameFontNormal" or "GameFontDisable")
    self.am_icon:SetDesaturated(not enable and 1 or nil)
    self.am_nummodifiers:SetFontObject(enable and "GameFontHighlightSmall" or "GameFontDisableSmall")
    self.amEnabled:SetChecked(enable)
    
    if (enable and enable ~= self.am_enabled) then
        self.am_enabled = enable
        
        self:am_checkconditions()
    end
end

function am_macro.mt.__index:am_updateicon()
    local name = self.am_name:GetText()
    
    if (GetMacroIndexByName(name) > 0) then
        self.am_icon:SetTexture(select(2, GetMacroInfo(name)))
    end
end

function am_macro.mt.__index:am_updatedb()
    local name = self.am_name:GetText()
    
    if (not AM_MACRO_DATABASE[name]) then
        AM_MACRO_DATABASE[name] = { }
    end
    
    local dbob = AM_MACRO_DATABASE[name]
    
    dbob.name = self.am_name:GetText()
    dbob.icon = self.am_icon:GetTexture()
    dbob.modifiers = self.am_modifiers
end



function am_macro.mt.__index:am_set(object)
    local name = self.am_name:GetText()
    
    if (object.name ~= name) then
        -- attempt to change my uid (name) to the new one in the parent container.  will fail if the new one exists.
        if (self:am_setuid(object.name)) then
            return 1
        end
    end

    self:am_setdata(object)
    self:am_updatedb()

    if (object.name ~= name) then
        -- rename the macro
        if (self.am_enabled) then
            EditMacro(name, object.name, nil, nil, 1, 1)
        end

        -- delete the old macro from our DB
        AM_MACRO_DATABASE[name] = nil
        
        -- since my name has changed, I probably need to get resorted.  do that here
        self.am_container:resort(self:am_getindex())
    end
    
    self:am_checkconditions()
    
    return nil
end

function am_macro.mt.__index:am_setactivemod(mod)
    if (InCombatLockdown()) then
        print("AM: Unable to setup macro " .. self.am_name:GetText() .. ":  You are in combat!  Changes queued for when combat ends...")
        
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        
        return false
    end
    
    local text = mod.text
    
    -- okay, need to process the inline scripts here!
    
    text = text:gsub("arena[%s]*%([%s]*\"([%w]*)\"[%s]*%)", function (token_name) return am.tokens:arena(token_name, self) end)
    text = text:gsub("party[%s]*%([%s]*\"([%w]*)\"[%s]*%)", function (token_name) return am.tokens:party(token_name, self) end)
    
    if (text:len() > 255) then
        self.am_securemacrobtn:SetAttribute("macrotext", text)
    
        -- this is here is because the icon will not show properly if we put the entire macro into a button and have only /click reference
        -- to that button.  the way around it is the standard #showtooltip at the beginning of the macro, and we extract that and put
        -- it at the beginning of the one we generate as well.
        
        text = text:match("(#showtooltip[^\r\n]*)") .. "\n" or ""
        text = text .. "/click " .. self.am_securemacrobtn:GetName()
    end
    
    if (not pcall(function() EditMacro(self.am_name:GetText(), nil, "INV_Misc_QuestionMark", text, 1, 1) end)) then
        return false
    end

    if (self.am_activemod) then
        self.am_activemod.active = nil
    end
    
    self.am_activemod = mod
    self.am_activemod.active = true
    
    return true
end

function am_macro.mt.__index:am_checkconditions()
    if (not self.am_enabled) then
        return nil
    end
    
    for i,m in ipairs(self.am_modifiers) do
        local found = true
        
        for j,c in ipairs(m.conditions) do
            if (not am.addons.conditions[c.name].test(c.relation, c.value)) then
                found = false
                break
            end
        end
        
        if (found) then
            return (not self:am_setactivemod(m))
        end
    end
    
    -- no modifiers are satisified.  set macro text to empty, and icon to QuestionMark
end

function am_macro.mt.__index:am_pickup()
    if (self.am_enabled) then
        PickupMacro(self.am_name:GetText())
    end
end

function am_macro.mt.__index:am_createwowmacro()
    if (GetMacroIndexByName(self.am_name:GetText()) == 0) then
        local _, num = GetNumMacros()
        
        if (num >= MAX_CHARACTER_MACROS) then
            return false
        end
        
        if (not pcall(function() CreateMacro(self.am_name:GetText(), "INV_Misc_QuestionMark", "", 1) end)) then
            -- macro creation failed!  I believe this can only happen if the macro list is full, but just in case
            -- I enclosed this in a pcall so it doesn't throw errors.
            
            return false
        end
    end
    
    return true
end

function am_macro.mt.__index:am_disable()
    local name = self.am_name:GetText()
    
    if (GetMacroIndexByName(name) > 0) then
        DeleteMacro(name)
    end
end


function am_macro.mt.__index:am_event(event, ...)
    if (event == "PLAYER_REGEN_ENABLED") then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    
        self:am_checkconditions()
    elseif (event == "UPDATE_MACROS") then
        self:am_checkstatus()
        self:am_updateicon()
    end
end










am_modifier = { mt = { __index = { } } }
setmetatable(am_modifier.mt.__index, am_contained.mt)

function am_modifier.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierTemplate"), am_modifier.mt)
    
    return f
end

function am_modifier.mt.__index:am_set(object)
    if (object.modstring) then
        self.am_modstring:SetText(object.modstring)
    end

    if (object.text) then self.am_text = object.text end
    
    if (object.active) then self:am_highlight() end
    
    -- there likely needs to be a condition check here to see if all of our conditions are installed !  if they are not, just disable the modifier and make it clear it is disabled graphically
    if (object.conditions) then
        self.am_conditions = object.conditions      -- treat this as read only ... I don't want to change anything in the object until we click "save"
        self:am_updatemodstring()
    end
end

function am_modifier.mt.__index:am_setindex(i)
    self.am_index = i
    
    self.am_modid:SetText(i)
end
    
function am_modifier.mt.__index:am_updatemodstring()
    local s = "if "
    
    for i,v in ipairs(self.am_conditions) do
        s = s .. v.name .. " " .. v.relation.text .. " " .. v.value.text .. " and "
    end
    
    s = s:sub(1, s:len() - 4) .. "then ..."

    self.am_modstring:SetText(s)
end









am_condition = { mt = { __index = { } } }
setmetatable(am_condition.mt.__index, am_contained.mt)

function am_condition.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierConditionTemplate"), am_condition.mt)
    
    return f
end

function am_condition.mt.__index:am_set(object)
    -- I need to make sure all conditions exist, and all relations and values are valid.
    
    if (object.name) then self.am_name:SetText(object.name) end
    
    if (object.relation) then
        self.am_relation.am_data = object.relation.data
        self.am_relation:SetText(object.relation.text)
    end
    
    if (object.value) then
        self.am_value.am_data = object.value.data
        self.am_value:SetText(object.value.text)
    end
end

function am_condition.mt.__index:am_setindex(i)
    self.am_index = i
    
    local intro = "and"
    local outro = ""
    
    if (i == 1) then
        intro = "if"
    end
    
    if (i == am.conditions:count()) then
        outro = "then"
    end
    
    self.am_introstring:SetText(intro)
    self.am_outrostring:SetText(outro)
end