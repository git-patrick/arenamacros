local addon_name, e = ...

-- this file just contains some very simple implementations of these three abstract objects "modifier", "condition", and "macro"

local libdc		= e:lib("dataclass")
local property	= libdc:class("property")

local condition_simple_properties = {
	["name"]    = property.scalar("name"),
	["relation"]= property.scalar("relation"),
	["value"]	= property.scalar("value"),
	["data"]	= property.scalar("data")
}

local condition_simple = libdc:addclass(libdc:create_dataclass("condition_simple", "condition", condition_simple_properties))

function condition_simple:satisified()
	-- THIS IS THE LINK TO THE ADDON PORTION OF THE PROGRAM!
end

local modifier_simple_properties = {
	["text"]        = property.scalar("text"),
	["modstring"]   = property.scalar("modstring"),
	["conditions"]  = property.array("conditions", libdc:class("condition_simple"))
}

local modifier_simple = libdc:addclass(libdc:create_dataclass("modifier_simple", "modifier", modifier_simple_properties))

function modifier_simple:checkconditions()
	for i,c in ipairs(self:am_getproperty("conditions"):get()) do
        if not c:satisfied() then
			return false
		end
    end
	
	return true
end

local macro_simple_properties = {
	["name"]       = property.scalar("name"),
	["icon"]       = property.scalar("icon"),
	["modifiers"]  = property.array("modifiers", libdc:class("modifier_simple")),
	["enabled"]    = property.scalar("enabled")
}

libdc:addclass(libdc:create_dataclass("macro_simple", "macro", macro_simple_properties))