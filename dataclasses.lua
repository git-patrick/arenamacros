local addon_name, e = ...

-- this file just contains some very simple implementations of these three abstract objects "modifier", "condition", and "macro"

local property = class.property

local condition_simple = e:addclass(class.create("condition_simple"))

function condition_simple:init(name, relation, value, data)
	self.condition.name = name
	self.condition.relation = relation
	self.condition.value = value
	self.condition.data = data
end

condition_simple.condition.name		= property.scalar("name")
condition_simple.condition.relation	= property.scalar("relation")
condition_simple.condition.value	= property.scalar("value")
condition_simple.condition.data		= property.scalar("data")


function condition_simple:satisified()
	-- THIS IS THE LINK TO THE ADDON PORTION OF THE PROGRAM!
end

local modifier_simple = e:addclass(class.create("modifier_simple"))

function modifier_simple:init(text, modstring, conditions)
	self.modifier.text = text
	self.modifier.modstring = modstring
	self.modifier.conditions = conditions
end

modifier_simple.modifier.text		= property.scalar("text")
modifier_simple.modifier.modstring	= property.scalar("modstring")
modifier_simple.modifier.conditions	= property.array("conditions", e:class("condition_simple"))

function modifier_simple:checkconditions()
	for i,c in ipairs(self.modifier.conditions) do
        if not c:satisfied() then
			return false
		end
    end
	
	return true
end

local macro_simple = e:addclass(class.create("macro_simple"))

function macro_simple:init(name, icon, modifiers, enabled)
	self.macro.name = name
	self.macro.icon = icon
	self.macro.modifiers = modifiers
	self.macro.enabled = enabled
end


macro_simple.macro.name		= property.scalar("name")
macro_simple.macro.icon		= property.scalar("icon")
macro_simple.macro.modifiers= property.array("modifiers", e:class("modifier_simple"))
macro_simple.macro.enabled	= property.scalar("enabled")