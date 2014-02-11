local addon_name, e = ...

local libutil   = e:lib("utility")
local libdc     = e:addlib(lib:new({ "dataclass", "1.0" }))

function libdc:new(name, properties)
    local c = class.create(name, dataclass)

    c.am_properties = properties
    
    return c
end



local dataclass = class.create("dataclass")

-- the reason for the am_ prefix in the functions below is that these will be added to WoW Frame objects namespace, and I don't want collisions

-- gets the property object of the chosen name
function dataclass:am_getproperty(name)
    return self.am_properties[name]
end
-- gets the value of the property object of the chosen name
function dataclass:am_get(name)
    return self:am_getproperty(name):get()
end

-- sets all our properties equal to their equivalent properties
-- any prehook failure, set failure, or post hook failure (return value of false) stops the set WHERE IT IS
-- it does NOT revert it back to the start.  if this is a problem in the future, its not too terrible a fix
-- but as it is, there are not too many instances where any of those should fail (except a property being a
-- unique identifier in a container, but since there is only one such property, and the properties are checked in the order
-- they were specified to the dataclass creation, if the prehook on that fails, nothing will change anyways.)

function dataclass:am_set(to)
    for i, v in pairs(self.am_properties) do
        if (not v:set(self, to.am_properties[i].get(to))) then
            return false
        end
    end
end

-- dump me to screen
function dataclass:am_print()
    for i, v in pairs(self.am_properties) do
        print(i, " ", libutil.tostring(v.get(self)))
    end
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
    
    if (not self._set(owning_table, to_value)) then
        return false
    end
    
    -- post hooks can no longer cause failure of set.
	-- all post hooks will be run no matter what previous posts have determined.
    for j,f in ipairs(self.psthook) do
        f(owning_table, my_value, to_value)
    end
    
    return true
end




property:add_static("scalar", function (name)
    return property:new({ property =
        {
            function (t) return t[name] end,            -- get
            function (t, value) t[name] = value end     -- _set
        }
    })
end)

-- this is an array of dataclass objects !  the dataclass type is passed in dc
property:add_static("array", function (name, dc)
    return property:new({ property =
        {
			function (t) return t[name] end,			-- get
			function (t, value)							-- _set
				t[name] = { }
			
				for i, v in pairs(value) do
					table.insert(t[name], dc:new():am_set(v))
				end
			end,
            function (t)								-- init
				-- since classes can be created on existing objects (for example, the WoW stored variables table), we check if our property is set
				-- if it is, we basically tell all of the objects in the array that they are dc objects (since they were likely just tables before
				-- this amounts to setting their metatable up to have access to dataclass members)
				if (t[name]) then
					for i,v in pairs(t[name]) do
						dc:new(v)
					end
				end
			end,
        }
    })
end)

property:add_static("custom", function(get, _set, init)
	return property:new({ property = { get, _set, init } })
end)





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