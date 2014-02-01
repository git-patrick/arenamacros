local addon_name, addon_table = "ArenaMacros", { { }, { }, { }, { }, { } } -- ...

local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

-- Create our namespace and an alternative in the engine.
e.dc = { }
e.dataclass = e.dc

local dc = e.dc

-- used for some supporting tables and other functions required to make dataclasses work.
dc._support = { }

-- the varargs are a set of tables to add to the metatable search list for the newly created factory's products.
function dc.create(property_list, ...)
    local t = setmetatable({ }, dc._support.factory)
    
    -- this metatable is here instead of in :create below so the table is reused by each call to that :create
    t._metatable = e.util.create_search_indexmetatable(..., { ["_properties"] = property_list }, dc._support.product)
    
    return t
end

-- this is used as the metatable for factories returned by dc.create
dc._support.factory = { __index = { } }

function dc._support.factory.__index:create(obj)
    local t = setmetatable(obj or {}, self._metatable)
    
    for i,v in pairs(t._properties) do
        if (v.init) then
            v.init(t)
        end
    end
    
    return t
end

-- this is used as part of the search table list for the objects returned by the factories returned by dc.create
-- these are prefixed by am_ because these objects can also be frames or other objects, and I want to avoid
-- namespace conflicts

dc._support.product = { }

-- gets the property object of the chosen name
function dc._support.product:am_getproperty(name)
    return self._properties[name]
end

-- gets the value of the property object of the chosen name
function dc._support.product:am_get(name)
    return self:am_getproperty(name):get()
end

-- sets all our properties equal to their equivalent properties
-- any prehook failure, set failure, or post hook failure (return value of false) stops the set WHERE IT IS
-- it does NOT revert it back to the start.  if this is a problem in the future, its not too terrible a fix
-- but as it is, there are not too many instances where any of those should fail (except a property being a
-- unique identifier in a container, but since there is only one such property, and the properties are checked in the order
-- they were specified to the dataclass creation, if the prehook on that fails, nothing will change anyways.)

function dc._support.product:am_set(to)
    for i, v in pairs(self._properties) do
        if (not v:set(self, to._properties[i].get(to))) then
            return false
        end
    end
end

-- dump me to screen
function dc._support.product:am_print()
    for i, v in pairs(self._properties) do
        print(i, " ", dc._tostr(v.get(self)))
    end
end


dc._support.prop = { }
local property = dc._support.prop

-- OKAY so this object maintains a list of pre and post change callbacks for when the property changes!
property.metatable = { __index = { } }

function property.metatable.__index:clear_pre()
    self.prehook = setmetatable({ }, e.util.erray)
end

function property.metatable.__index:clear_pst()
    self.psthook = setmetatable({ }, e.util.erray)
end

function property.metatable.__index:set(owning_table, to_value)
    local my_value = self.get(owning_table)
    
    for j,f in ipairs(self.prehook) do
        if (not f(my_value, to_value)) then
            return false
        end
    end
    
    if (not self._set(owning_table, to_value)) then
        return false
    end
    
    for j,f in ipairs(self.psthook) do
        if (not f(my_value, to_value)) then
            return false
        end
    end
end

-- each of these return a property object that is used by the instances of the dataclass instance classes to get/set their respective properties,
-- or initialize them upon creation of the class (if init is non nil)

function property.scalar(name)
    return setmetatable({
        ["get"] = function (self) return self[name] end,
        ["_set"] = function (self, value) self[name] = value end,
        ["init"] = nil,
        ["prehook"] = setmetatable({ }, e.util.erray),
        ["psthook"] = setmetatable({ }, e.util.erray)
    }, property.metatable)
end

function property.array(name, dataclass_factory)
    return setmetatable({
        ["get"] = function (self) return self[name] end,
        ["_set"] = function (self, value)
            self[name] = { }
            
            for i, v in pairs(value) do
                table.insert(self[name], dataclass_factory:create():am_set(v))
            end
        end,
        ["init"] = function (self)
            if (self[name]) then
                for i,v in pairs(self[name]) do
                    dataclass_factory:create(v)
                end
            end
        end,
        ["prehook"] = setmetatable({ }, e.util.erray),
        ["psthook"] = setmetatable({ }, e.util.erray)
    }, property.metatable)
end

function property.custom(get, set, init)
    return setmetatable({
        ["get"] = get,
        ["_set"] = set,
        ["init"] = init,
        ["prehook"] = setmetatable({ }, e.util.erray),
        ["psthook"] = setmetatable({ }, e.util.erray)
    }, property.metatable)
end

-- PROPERTY OBJECTS HERE!  These are reused a few times below.



property.scalar_name     =
property.xml_name        = property.custom(function (self) return self.amName:GetText() end, function (self, value) self.amName:SetText(value) end)
property.modstring       = property.custom
(
    function (self)
        local s = "if "

        for i,v in pairs(self:am_getproperty("conditions"):get()) do
            s = s .. v:am_getproperty("name"):get() .. " " .. v:am_getproperty("relation"):get():am_getproperty("text"):get() .. " " .. v:am_getproperty("value"):get():am_getproperty("text"):get() .. " and "
        end
 
        s = s:sub(1, s:len() - 4) .. "then ..."
 
        return s
    end,
 
    function (self, value)
        self.am_modstring = value
    end
)





-- instance classes (or lists of them) of our dataclass class!
dc.condition = { }

local t = dc.condition

t.simple = dc.create
({
 ["name"]           = property.scalar("name"),
 ["relation"]       = property.scalar("relation"),
 ["relation_data"]  = property.scalar("relation_data"),
 ["value"]          = property.scalar("value"),
 ["value_data"]     = property.scalar("value_data")
 })

t.li = dc.create
({
 ["name"]           = property.xml_name,
 ["relation"]       = property.custom(function (self) return self.amRelation:GetText() end, function (self, value) self.amRelation:SetText(value); end),
 ["relation_data"]  = property.scalar("am_relation_data"),
 ["value"]          = property.custom(function (self) return self.amValue:GetText() end, function (self, value) self.amValue:SetText(value); end),
 ["value_data"]     = property.scalar("am_value_data")
 })

dc.modifier = { }

t = dc.modifier

t.simple = dc.create
({
 ["text"]        = property.scalar("text"),
 ["modstring"]   = property.scalar("modstring"),
 ["conditions"]  = property.array("conditions", dc.condition.simple)
 })

t.frame = dc.create
({
 ["text"]        = property.custom(function (self) return self.amInput.EditBox:GetText() end, function (self, value) self.amInput.EditBox:SetText(value) end),
 ["modstring"]   = property.modstring,
 ["conditions"]  = nil -- NEED CUSTOM REFERENCE TO GLOBAL CONTAINER HERE....
 })

t.li = dc.create
({
 ["text"]        = property.scalar("am_text"),
 ["modstring"]   = property.modstring,
 ["conditions"]  = property.array("am_conditions", dc.condition.simple)
 })


dc.macro = { }

t = dc.macro

t.simple = dc.create
({
 ["name"]       = property.scalar("name"),
 ["icon"]       = property.scalar("icon"),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple)
})

t.frame = dc.create
({
 ["name"]       = property.xml_name,
 ["icon"]       = property.custom(function (self) print("FRAME ICON GET"); return "INV_Misc_QuestionMark"; end, function (self, value)
                                    print("SetPortraitToTexture ", value)
                                 --SetPortraitToTexture(AMFrame.amPortrait, value)
                                 end),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple)           -- array.create("am_modifiers", am.modifiers:get_frames()), this needs to change, might change how containers work with dataclasses.
})


property.macroli_name = property.custom
(
 function (self) -- get
    return self.amName:GetText()
 end,
 
 function (self, value) -- set
     local current = self:am_getproperty(name)
     
     if (value == current) then
        return true  -- for success
     end
     
     -- tell the container of our intention to change the UID.  if it fails, we fail
     if (self:am_setuid(value)) then
        return false
     end
     
     -- succeeded (name isn't in use by another macro), so make the necessary changes...
     
     -- change our DB reference object to match us.  this is redundant on our inital am_set call, but afterwords it is required.
     -- this handles moving the object around in our database etc.
     self.am_dbref:am_setproperty(name, value)
     
     -- set our actual value
     self.amName:SetText(value)
     
     -- rename or create the macro.
     -- current ~= nil implies we are not a newly created macro object, and an existing macro could exist / a database entry already exists
     if (current ~= nil) then
         if (self.am_enabled) then
            EditMacro(current, value, nil, nil, 1, 1)
         end
     else
        self:am_createwowmacro()
     end
     
     -- resort myself in the parent container
     self:am_resort()
 end
)


t.li = dc.create
({
 ["name"]       = property.macro_name,
 ["icon"]       = property.custom(function (self) return self.amIcon:GetTexture() end, function (self, value) self.amIcon:SetTexture(value) end),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple)
})







function mac.mt.__index:am_setproperty(name, value)
    if (name == "name") then
        local current = self:am_getproperty(name)
        
        if (value == current) then
            return true  -- for success
        end
        
        -- tell the container of our intention to change the UID.  if it fails, we fail
        if (self:am_setuid(value)) then
            return false
        end
        
        -- succeeded (name isn't in use by another macro), so make the necessary changes...
        
        -- change our DB reference object to match us.  this is redundant on our inital am_set call, but afterwords it is required.
        -- this handles moving the object around in our database etc.
        self.am_dbref:am_setproperty(name, value)
        
        -- set our actual value
        self.amName:SetText(value)
        
        -- rename or create the macro.
        -- current ~= nil implies we are not a newly created macro object, and an existing macro could exist / a database entry already exists
        if (current ~= nil) then
            if (self.am_enabled) then
                EditMacro(current, value, nil, nil, 1, 1)
            end
        else
            self:am_createwowmacro()
        end
        
        -- resort myself in the parent container
        self:am_resort()
    elseif (name == "icon") then
        self.amIcon:SetTexture(value)
        
        self.am_dbref:am_setproperty(name,value)
    elseif (name == "modifiers") then
        self.amNumModifiers:SetText(self.am_modifiers and table.getn(self.am_modifiers) or "0")
        
        self.am_dbref:am_setproperty(name,value)
        
        self:am_checkconditions()
    end
    
    return true   -- for success
end











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
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple)
 },
 { _database = AM_MACRO_DATABASE_V2 })





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