local addon_name, addon_table = "ArenaMacros", { { }, { }, { }, { }, { } } -- ...

local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.contained.macro = { uid = 0, mt = { __index = setmetatable({ }, e.util.create_search_indexmetatable(e.dataclass.macro.li, e.contained.mt)) } }

local mac = e.contained.macro

function mac.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame or UIParent, "AMMacroTemplate"), mac.mt)

    -- setup our events!
    f:SetScript("OnEvent", function(self, event, ...) self:am_event(event, ...) end)
    f:RegisterEvent("UPDATE_MACROS")
    
    -- setup our property hooks!
    -- attempts to change name already are checked by the uidmap for the container, so if the new name is already taken,
    -- property set will fail from that, and we will never even get called.
    f:am_getproperty("name").psthook:add
    (function (from, to)
        f:am_resort()
    end)
    
    f:am_getproperty("modifiers").psthook:add
    (function (from, to)
        f.amNumModifiers:SetText(to and table.getn(to) or "0")
     
        if (f:am_getproperty("enabled"):get()) then
            f:am_checkconditions()
        end
    end)
    
    f:am_getproperty("enabled").prehook:add
    (function (from, to)
        local name = self:am_getproperty("name"):get()
     
        if (to) then
            if not e.util.create_or_rename_macro(nil, name) then
                return false
            end
        else
            e.util.delete_macro(name)
        end
     
        return true
    end)
    f:am_getproperty("enabled").psthook:add
    (function (from, to)
        self.amEnabled:SetChecked(to)
     
        if (to) then
            f:am_checkconditions()
        end
    end)
  
    -- the purpose of this frame is to override the 255 character limit placed on macros.
    -- it stores our chosen macro text, and can be run with a /click FrameName from the actual macro
    -- i don't need to pool this createframe, because there is already a pool controlling the macro frame itself
    -- so this frame is indirectly pooled as a result.
    
    f.am_securemacrobtn = CreateFrame("Button", "AMSecureMacroButtonFrame" .. mac.uid, UIParent, "SecureActionButtonTemplate")
    
    f.am_securemacrobtn:SetAttribute("type", "macro")
    f.am_securemacrobtn:SetAttribute("macrotext", "")

    -- increment the unique frame identifier used to create the secure buttons above.
    mac.uid = mac.uid + 1
    
    return f
end





-- this is used by the container to sort our macros automatically.
function mac.mt.__index:am_compare(other)
    local me = self:am_getproperty("name"):get():lower()
    local yu = other:am_getproperty("name"):get():lower()
    
    return (me <= yu) and ((me < yu) and -1 or 0) or 1
end

function mac.mt.__index:am_onremove()
    self:am_getproperty("enabled"):set(self, false)
    
    -- need to delete the database reference here!
end




-- this basicalled checks if the wow macro exists, updates our frame appearance accordingly, and if our state has changed from not exists to exists, checks modifiers to determine the active macro text.
function mac.mt.__index:am_checkstatus()
    local enable
    
    if (GetMacroIndexByName(self:am_getproperty("name")) > 0) then
        enable = true
    else
        enable = false
    end
    
    self:am_getproperty("enabled"):set(self, enable)
end



function mac.mt.__index:am_setactivemod(mod)
    if (InCombatLockdown()) then
        print("AM: Unable to setup macro " .. self:am_getproperty("name") .. ":  You are in combat!  Changes queued for when combat ends...")
        
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        
        return false
    end
    
    local text = mod:am_getproperty("text"):get()
    local name = self:am_getproperty("name"):get()
    
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
    
    -- set the macro with the new text.
    if (not pcall(function() EditMacro(name, nil, "INV_Misc_QuestionMark", text, 1, 1) end)) then
        return false
    end

    -- not sure what I use this for, might remove this ...
    if (self.am_activemod) then
        self.am_activemod.active = nil
    end
    
    self.am_activemod = mod
    self.am_activemod.active = true
    
    -- change our icon to the macros auto determined icon.
    self:am_getproperty("icon"):set(self, select(2, GetMacroInfo(name)))
    
    return true
end

function mac.mt.__index:am_checkconditions()
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

function mac.mt.__index:am_pickup()
    if (self.am_enabled) then
        PickupMacro(self:am_getproperty("name"))
    end
end

function mac.mt.__index:am_event(event, ...)
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