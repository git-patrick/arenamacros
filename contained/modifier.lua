local addon_name, e = ...

local libutil		= e:lib("utility")

local libcontainer	= e:lib("container")
local libdc			= e:lib("dataclass")
local libwow		= e:lib("wow")

local property		= libdc:class("property")

-- This part sets up our dataclass class for this "modifier" representation.
-- this is used for inheriting purposes in the modifier

-- setup the properties list here.....
local modifier_properties = {
	["text"]        = property.scalar("am_text"),
	["modstring"]   = property.custom(
		function (self) return self.amModString:GetText() end,
		function (self, value) self.amModString:SetText(value) end
	),
	["conditions"]  = property.array("am_conditions", libdc:class("condition_simple"))
}

libdc:addclass(libdc:create_dataclass("modifier_contained", "modifier", modifier_properties))

-- This is our "contained" version of the modifier for use inside the container list.
-- is also the dataclass to allow for quick and easy get / set.
-- you don't ever need to call modifier:new to create the object
-- it is automatically attached to the modifier frame intended for containment when you CreateFrame(...) with the
-- appropriate inherited frame name in modifier.xml
-- that works becaues of the frames OnLoad function below!

local modifier = libcontainer:addclass(class.create("modifier", libcontainer:class("contained"), libdc:class("modifier_contained")))

-- override for contained:am_setindex
function modifier:am_setindex(i)
    self.am_index = i
    self.am_moveto = nil
    
    if (i <= 1) then
        self.amMoveUp:Disable()
    else
        self.amMoveUp:Enable()
    end
    
    if (i >= self.am_container:count()) then
        self.amMoveDown:Disable()
    else
        self.amMoveDown:Enable()
    end
    
    self.amModID:SetText(i)
end

-- override for contained:am_compare, bit of a sneaky way of moving things around the container.
-- how it works it, when you press up or down, it changes your am_moveto and then resorts you
-- which calls this for comparison, and allows you to move that element.
function modifier:am_compare(other)
    if not other.am_moveto then
        return 0
    end
    
    if (self:am_getindex() == other.am_moveto) then
        return 1
    end
    
    return 0
end




function amContainedModifier_OnLoad(self)
	-- nil because we don't have any parameters to pass to a modifier init function
	-- self tells it that we don't need a new table, use ourselves as the table.
	modifier:new(nil, self)
end

function amContainedModifier_MoveUp(self, button, down)
    local mod = self:GetParent()
    
    mod.am_moveto = math.max(mod:am_getindex() - 1, 1)
    mod:am_resort()
end

function amContainedModifier_MoveDown(self, button, down)
    local mod = self:GetParent()
    
    mod.am_moveto = math.min(mod:am_getindex() + 1, mod.am_container:count())
    mod:am_resort()
end

function amContainedModifier_Delete(self, button, down)
    self:GetParent():am_remove()
end
