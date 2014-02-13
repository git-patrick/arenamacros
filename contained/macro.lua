local addon_name, e = ...

local libutil		= e:lib("utility")

local libcontainer	= e:lib("container")
local libdc			= e:lib("dataclass")
local libwow		= e:lib("wow")

local property		= libdc:class("property")

-- setup the properties list here.....
local macro_properties = {
	["name"]       = property.custom(
		function (self) return self.amName:GetText() end,
		function (self, value) self.amName:SetText(value) end,
	),
	["icon"]       = property.custom(
		function (self) return self.amIcon:GetTexture() end,
		function (self, value) self.amIcon:SetTexture(value) end
	),
	["modifiers"]  = property.array("modifiers", libdc:class("modifier_simple")),
	["enabled"]    = property.custom(
		function (self) return self.am_enabled end,
		function (self, value) self.am_enabled = value end
	)
})

libdc:addclass(libdc:create_dataclass("macro_contained", "macro", macro_properties))

local macro = libcontainer:addclass(class.create("macro", libcontainer:class("contained"), libdc:class("macro_contained")))

-- This is used as an identifier for a globally named secureactionbuttontemplate object which allows for Secure WoW functionality
-- to be coded and acted upon by my addon as long as there is user interaction.
-- ultimately, this means that you can make macros of longer length (I am not actually sure what the limit is for these buttons, but it is much longer than standard)

macro.securebtn_identifier = 0

function macro:init()

    -- setup our property hooks!
    -- attempts to change name already are checked by the uidmap for the container, so if the new name is already taken,
    -- property set will fail from that, and we will never even get called.
    self:am_getproperty("name").psthook:add(
		function (o, from, to)
			o:am_resort()
		end
	)
    
    self:am_getproperty("modifiers").psthook:add(
		function (o, from, to)
			o.amNumModifiers:SetText(to and table.getn(to) or "0")
		 
			if (o:am_getproperty("enabled"):get()) then
				o:am_checkmodifiers()
			end
		end
	)
    self:am_getproperty("enabled").prehook:add(
		function (o, from, to)
			local name = self:am_getproperty("name"):get()
		 
			if (to) then
				if not e.util.create_or_rename_macro(nil, name) then
					return false
				end
			else
				e.util.delete_macro(name)
			end
		 
			return true
		end
	)
    self:am_getproperty("enabled").psthook:add(
		function (o, from, to)
			o.amEnabled:SetChecked(to)
			
			o.amName:SetFontObject(to and "GameFontNormal" or "GameFontDisable")
			o.amIcon:SetDesaturated(not to and 1 or nil)
			o.amNumModifiers:SetFontObject(to and "GameFontHighlightSmall" or "GameFontDisableSmall")
			
			if (to) then
				o:am_checkmodifiers()
			end
		end
	)
	
    -- setup our events!
	
	f:SetScript("OnEvent", function(self, event, ...) self:am_event(event, ...) end)
    f:RegisterEvent("UPDATE_MACROS")
    
	
    -- the purpose of this frame is to override the 255 character limit placed on macros.
    -- it stores our chosen macro text, and can be run with a /click FrameName from the actual macro
    -- i don't need to pool this createframe, because there is already a pool controlling the macro frame itself
    -- so this frame is indirectly pooled as a result.
    
    self.am_securemacrobtn = CreateFrame("Button", "AMSecureMacroButtonFrame" .. macro.securebtn_identifier, UIParent, "SecureActionButtonTemplate")
    
    self.am_securemacrobtn:SetAttribute("type", "macro")
    self.am_securemacrobtn:SetAttribute("macrotext", "")

    -- increment the unique frame identifier used to create the secure buttons above.
    macro.securebtn_identifier = macro.securebtn_identifier + 1
end





-- this is used by the container to sort our macros automatically.
function macro:am_compare(other)
    local me = self:am_getproperty("name"):get():lower()
    local yu = other:am_getproperty("name"):get():lower()
    
    return (me <= yu) and ((me < yu) and -1 or 0) or 1
end

function macro:am_onremove()
    self:am_getproperty("enabled"):set(self, false)
    
    -- need to delete the database reference here!
end




-- this basically checks if the wow macro exists, and sets our enabled accordingly.
function macro:am_checkstatus()
    local enable
    
    if (GetMacroIndexByName(self:am_getproperty("name"):get()) > 0) then
        enable = true
    else
        enable = false
    end
    
    self:am_getproperty("enabled"):set(self, enable)
end



function macro:am_setactivemod(mod)
    if (InCombatLockdown()) then
        print("AM: Unable to setup macro " .. self:am_getproperty("name"):get() .. ":  You are in combat!  Changes queued for when combat ends...")
        
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        
        return false
    end
    
    local text = mod:am_getproperty("text"):get()
    local name = self:am_getproperty("name"):get()
    
    -- okay, need to process the inline scripts here!
    
	-- TEMPORARILY DISABLING INLINE REPLACEMENT UNTIL I REWRITE THAT PART.
	
    -- text = text:gsub("arena[%s]*%([%s]*\"([%w%s]*)\"[%s]*%)", function (token_name) return am.tokens:arena(token_name, self) end)
    -- text = text:gsub("party[%s]*%([%s]*\"([%w%s]*)\"[%s]*%)", function (token_name) return am.tokens:party(token_name, self) end)
    
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
  
    -- change our icon to the macros auto determined icon.
    self:am_getproperty("icon"):set(self, select(2, GetMacroInfo(name)))
    
    return true
end

function macro:am_checkmodifiers()
    if (not self:am_getproperty("enabled"):get()) then
        return nil
    end
    
    for i,m in ipairs(self:am_getproperty("modifiers"):get()) do
        if (m:checkconditions()) then
			return (not self:am_setactivemod(m))
        end
    end
    
    -- no modifiers are satisified.
	-- should do something here...
end

function macro:am_pickup()
    if (self:am_getproperty("enabled"):get()) then
        PickupMacro(self:am_getproperty("name"))
    end
end

function macro:am_event(event, ...)
    if (event == "PLAYER_REGEN_ENABLED") then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    
        self:am_checkmodifiers()
    elseif (event == "UPDATE_MACROS") then
        self:am_checkstatus()
    end
end





-- XML EVENTS ...

function amContainedMacro_OnLoad(self)
	macro:new(nil, self)
end
function amcontainedMacro_OnClick(self, button, down)
	print("DO THIS")
end
function amContainedMacro_Delete(self, button, down)
	self:GetParent():am_remove()
end

function amContainedMacro_Enabled(self, button, down)
	-- DO THISSssss
end

function amContainedMacro_Pickup(self, button, down)
    self:GetParent():am_pickup()
end