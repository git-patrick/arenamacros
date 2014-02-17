


--[[

THIS FILE IS BASICALLY NO LONGER NEEDED.  I ADDED ALL THIS FUNCTIONALITY DIRECTLY TO CLASSES

This is only here incase I need something.  I will delete this file later.



local addon_name, e = ...

local libutil   = e:lib("utility")
local libdc     = e:addlib(lib:new({ "dataclass", "1.0" }))


local dataclass_object = libdc:addclass(class.create("dataclass_object"))

function dataclass_object:init()
	self.dc_classes = { }
end

function dataclass_object:dc_add(dcname, property_map)
	-- property map is just an associate map where the key is the propery name, and value is a property class instance
	-- that has the gets / sets / hooks for property changes
	
	self.dc_classes[dcname] = property_map
end

function dataclass_object:dc_rm(dcname)
	self.dc_classes[dcname] = nil
end

-- returns the property value
function dataclass_object:dc_get(dcname, propname)
	return self:dc_getclass(dcname)[propname].get(self)
end

function dataclass_object:dc_getclass(dcname)
	return self.dc_classes[dcname]
end

-- sets all our properties equal to their equivalent properties
-- any prehook failure, set failure, or post hook failure (return value of false) stops the set WHERE IT IS
-- it does NOT revert it back to the start.  if this is a problem in the future, its not too terrible a fix
-- but as it is, there are not too many instances where any of those should fail (except a property being a
-- unique identifier in a container, but since there is only one such property, and the properties are checked in the order
-- they were specified to the dataclass creation, if the prehook on that fails, nothing will change anyways.)
function dataclass_object:dc_set(dcname, to)
	for name, prop in pairs(self:dc_getclass(dcname)) do
        if (not prop:set(self, to:dc_get(dcname, name))) then

            return false
        end
    end
	
	return true
end





-- the only purpose of this is wrap up the passing of the properties list parameter.
function libdc:create_dataclass(class_name, dataclass_name, properties)
	local c = class.create(class_name, dataclass_object)
	
	function c:init()
		self:dc_add(dataclass_name, properties)
		
		for i, v in pairs(properties) do
			if (v.init) then
				v.init(self)
			end
		end
	end
	
	return c
end





local property = libdc:addclass(class.create("property"))

function property:init(get, _set, init)
    local erray = libutil:class("erray")
    
    -- _set changes the actual value, while :set below cycles through all my pre and post hooks.
    -- you should not call _set directly.
    self._set = _set
    self.get = get
    self.init = init
    
    self.prehook = erray:new()
    self.psthook = erray:new()
end

function property:clear_pre()
    self.prehook = libutil:class("erray"):new()
end

function property:clear_pst()
    self.psthook = libutil:class("erray"):new()
end

function property:set(owning_table, to_value)
    local my_value = self.get(owning_table)
    
    -- if the value did not change, we skip all hook calls, and the set call!!!!
    if (my_value == to_value) then
        return true
    end
    
    for j,f in ipairs(self.prehook) do
        if (not f(owning_table, my_value, to_value)) then
            return false
        end
    end

    if (self._set(owning_table, to_value)) then
        return false
    end
	
    -- post hooks can no longer cause failure of set.
	-- all post hooks will be run no matter what previous posts have determined.
    for j,f in ipairs(self.psthook) do
        f(owning_table, my_value, to_value)
    end
    
    return true
end










--[[

-- some reused property getters / setters
local function xmlname_get(self)
    return self.amName:GetText()
end

local function xmlname_set(self, value)
    self.amName:SetText(value)
end
 
-- instance classes (or lists of them) of our dataclass class!
dc.condition = { }

local t = dc.condition





dc.modifier = { }

t = dc.modifier





t.li = dc.create
({
 ["text"]        = property.scalar("am_text"),
 ["modstring"]   = property.custom(function (self, value) return self.amModString:GetText() end, function (self, value) self.amModString:SetText(value)),
 ["conditions"]  = property.array("am_conditions", dc.condition.simple)
 })


dc.macro = { }

t = dc.macro

t.frame = dc.create
({
 ["name"]       = property.custom(xmlname_get, xmlname_set),
 ["icon"]       = property.custom(function (self) print("FRAME ICON GET");
                                    return "INV_Misc_QuestionMark";
                                  end,
                                  function (self, value)
                                    print("SetPortraitToTexture ", value)
                                    --SetPortraitToTexture(AMFrame.amPortrait, value)
                                 end),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple),
 ["enabled"]    = property.scalar("am_enabled")
})

























t.db = dc.create
({
 ["name"]       = property.custom
 (
  function (self) return self["name"] end,
  function (self, value)
      local old = self["name"]
      
      self["name"] = value
      
      if (self._database) then
          self._database:rm(old)
          self._database:add(self)
      end
  end
  ),
 ["icon"]       = property.scalar("icon"),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple),
 ["enabled"]    = property.scalar("enabled")
 },
 { _database = AM_MACRO_DATABASE_V2 })
 
]]--




-- NOW I WANT database_macro.db to be a factory that pumps out objects of that type.
-- dc.create is a factory to produce factories.
-- property_custom(...) and the other property_* functions also return factories that can be used to create properties of those types... i think

-- ultimately what I want to be able to do is...
--[[

    local m = dataclass_macro.simple:create()
    local n = dataclass_macro.frame:create(existing_frame) -- attaches itself to the existing frame.

    local o = dataclass_macro.li:create(existing_frame)

    o:am_set(m)
    n:am_set(n)

 
    and I think that is it...... !  that's pretty fricking simple RIGHTW!?!?!?!?
]]--

























-- GONNA CHANGE THIS ALL, I WANT TO JUST MAKE PROPERTIES A DEFAULT PART OF CLASSES NOW.
--[[

	so, I want properties to have all the same hooks / get / set / init stuff, but I want to be able to access them very easily
	
	and set them very easily like this...
	
	class creation!!!
	
	local some_class = class.create("some_class")
	
	function some_class:derp()
	
	end
	
	how do I want to set this up ...
	
		option 1...
		some_class.modifier.name.get = function () ... end
		some_class.modifier.name.set = function () ... end
		
		option 2...
		some_class.modifier.name = { get = function() ... end, set = function () ... end, init = function () ... end }
		
		option 3...
		some_class.modifier.name = class.property:new({ function () ... end, function () ... end, function () ... end })
		
		
		option 3 hides less, but is more clear in what is happening.  I would need fancy metatable shenanigans to make the others work
		which might be a bit more confusing.  I'm going to go option 3.
	
	
	local object = some_class:new()
	local other = some_class:new()
	
	
	object.modifier.name:set("POOO") -- sets the property "name" for the property group "modifier" to  POOO
	object.modifier:set(other) -- sets all properties in property group "modifier" to the equivalent in other
	object:set(other) -- sets all property groups to the equivalent in other
	
	THIS IS BEAUTIFUL
	
	that means my class index metamethod is going to have to change.  it is first going to check a list _properties for that property and return it
	and then it can just check the table itself and return that.




	how are classes going to get properties?  I need to specify them to class creation and inherit them from base classes as well.
	
	HOOKS are instance specific?  where can I store them that won't muddy up anything if I want to save the instance table...
	
	I could setup a metatable where I can store property specific data, and all access goes through that.  in fact, all instance specific class information
	should go into this metatable for sure.
	
	
	
	
	
]]--