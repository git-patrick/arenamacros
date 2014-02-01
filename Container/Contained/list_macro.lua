local addon_name, addon_table = "ArenaMacros", { { }, { }, { }, { }, { } } -- ...

local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.contained.macro = { uid = 0, mt = { __index = setmetatable({ }, e.util.create_search_indexmetatable(e.dataclass.macro.li, e.contained.mt)) } }

local mac = e.contained.macro





if MAX_CHARACTER_MACROS == nil then
    MAX_CHARACTER_MACROS = 18
end

function mac.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame or UIParent, "AMMacroTemplate"), mac.mt)

    f:SetScript("OnEvent", function(self, event, ...) self:am_event(event, ...) end)
    f:RegisterEvent("UPDATE_MACROS")
    
    -- the purpose of this frame is to override the 255 character limit placed on macros.  
    -- it stores our chosen macro text, and can be run with a /click FrameName from the actual macro
    
    f.am_securemacrobtn = CreateFrame("Button", "AMSecureMacroButtonFrame" .. mac.uid, UIParent, "SecureActionButtonTemplate")
    
    f.am_securemacrobtn:SetAttribute("type", "macro")
    f.am_securemacrobtn:SetAttribute("macrotext", "")

    mac.uid = mac.uid + 1
    
    return f
end










-- setup our am_contained:am_getuid() override, this defines what property makes us unique in the container.  changes to this property must call am_setuid() from am_contained to notify the container of our UID changes
function am_macro.mt.__index:am_getuid()
    return self:am_getproperty("name")
end
-- this is used by the container to sort our macros automatically.
function am_macro.mt.__index:am_compare(other)
    local me = self:am_getproperty("name"):lower()
    local yu = other:am_getproperty("name"):lower()
    
    return (me <= yu) and ((me < yu) and -1 or 0) or 1
end

function am_macro.mt.__index:am_onremove()
    self:am_deletewowmacro()
    
    self.am_dbref:am_delete()
end

function am_macro.mt.__index:am_onadd(object)
    -- this is called everytime I insert into the container, so for New Macro button, and on load when I am initializing from the DB
    -- or whenever UPDATE_MACROS is fired and we find a new macro that was added in some other way.
    
    self.am_dbref = object
    self:am_set(object)

    -- check our status (is the macro created, set our enabled flag etc)
    self:am_checkstatus()
end

function am_macro.mt.__index:am_checkstatus()
    local enable
    
    if (GetMacroIndexByName(self:am_getproperty("name")) > 0) then
        enable = true
    else
        enable = false
    end
    
    self.amName:SetFontObject(enable and "GameFontNormal" or "GameFontDisable")
    self.amIcon:SetDesaturated(not enable and 1 or nil)
    self.amNumModifiers:SetFontObject(enable and "GameFontHighlightSmall" or "GameFontDisableSmall")
    self.amEnabled:SetChecked(enable)
    
    if (enable and enable ~= self.am_enabled) then
        self:am_checkconditions()
    end
    
    self.am_enabled = enable
end



function am_macro.mt.__index:am_setactivemod(mod)
    if (InCombatLockdown()) then
        print("AM: Unable to setup macro " .. self:am_getproperty("name") .. ":  You are in combat!  Changes queued for when combat ends...")
        
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        
        return false
    end
    
    local text = mod:am_getproperty("text")
    local name = self:am_getproperty("name")
    
    -- okay, need to process the inline scripts here!
    -- both gsubs are necessary because something like (arena|party) is not supported in lua D:
    
    text = text:gsub("arena[%s]*%([%s]*\"([%w%s]*)\"[%s]*%)", function (token_name) return am.tokens:arena(token_name, self) end)
    text = text:gsub("party[%s]*%([%s]*\"([%w%s]*)\"[%s]*%)", function (token_name) return am.tokens:party(token_name, self) end)
    
    if (text:len() > 255) then
        self.am_securemacrobtn:SetAttribute("macrotext", text)
    
        -- this is here is because the icon will not show properly if we put the entire macro into a button and have only /click reference
        -- to that button.  the way around it is the standard #showtooltip at the beginning of the macro, and we extract that and put
        -- it at the beginning of the one we generate as well.
        
        text = text:match("(#showtooltip[^\r\n]*)") .. "\n" or ""
        text = text .. "/click " .. self.am_securemacrobtn:GetName()
    end
    
    if (not pcall(function() EditMacro(name, nil, "INV_Misc_QuestionMark", text, 1, 1) end)) then
        return false
    end

    if (self.am_activemod) then
        self.am_activemod.active = nil
    end
    
    self.am_activemod = mod
    self.am_activemod.active = true
    
    self:am_setproperty("icon", select(2, GetMacroInfo(name)))
    
    return true
end

function am_macro.mt.__index:am_checkconditions()
    if (not self.am_enabled) then
        return nil
    end
    
    print("checking ", self:am_getproperty("name"))
    
    for i,m in ipairs(self:am_getproperty("modifiers")) do
        local found = true
        
        for j,c in ipairs(m:am_getproperty("conditions")) do
            if (not am.addons.conditions[c:am_getproperty("name")].test(c:am_getproperty("relation"), c:am_getproperty("value"))) then
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
        PickupMacro(self:am_getproperty("name"))
    end
end

function am_macro.mt.__index:am_createwowmacro()
    local name = self:am_getproperty("name")
    
    if (GetMacroIndexByName(name) == 0) then
        local _, num = GetNumMacros()
        
        if (num >= MAX_CHARACTER_MACROS) then
            return false
        end
        
        if (not pcall(function() CreateMacro(name, "INV_Misc_QuestionMark", "", 1) end)) then
            -- macro creation failed!  I believe this can only happen if the macro list is full, but just in case
            -- I enclosed this in a pcall so it doesn't throw errors.
            
            return false
        end
    end
    
    return true
end

function am_macro.mt.__index:am_deletewowmacro()
    local name = self:am_getproperty("name")
    
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
    end
end





-- XML EVENTS ...

function amMacro_OnClick(self, button, down)
    amModifierFrame_Setup(self)
end

function amMacro_Delete(self, button, down)
    am.macros:remove(self:GetParent():am_getindex())
end

function amMacro_Enabled(self, button, down)
    if (self:GetParent().am_enabled) then
        self:GetParent():am_deletewowmacro()
    else
        print("UHHHUHUHU")
        
        self:GetParent():am_createwowmacro()
    end
end

function amMacro_Pickup(self, button, down)
    self:GetParent():am_pickup()
end