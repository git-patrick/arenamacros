local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

local l = e:mklib("dataclass", "1.0")

-- the dataclass class is used to create other classes based on a list of properties at runtime.
local dataclass = l:mkclass("dataclass")

-- used for some supporting tables and other functions required to make dataclasses work.

-- the varargs are a set of tables to add to the metatable search list for the newly created factory's products.
function dataclass.create(property_list, ...)
    local t = dataclass:class("instance"):create()
    
    -- this metatable is here instead of in :create below so the table is reused by each call to that :create
    t._metatable = e.util.create_search_indexmetatable(..., { ["_properties"] = property_list }, dc._support.product)
    
    return t
end

local instance = dataclass:mkclass("instance")

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
    
    -- if the value did not change, we skip all hook calls, and the set call!!!!
    if (my_value == to_value) then
        return true
    end
    
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
    
    return true
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



-- some reused property getters / setters




local function xmlname_get(self)
    return self.amName:GetText()
end

local function xmlname_set(self, value)
    self.amName:SetText(value)
end


local function modstring_get(self)
    local s = "if "

    for i,v in pairs(self:am_getproperty("conditions"):get()) do
        s = s .. v:am_getproperty("name"):get() .. " " .. v:am_getproperty("relation"):get() .. " " .. v:am_getproperty("value"):get() .. " and "
    end

    s = s:sub(1, s:len() - 4) .. "then ..."

    return s
end
 
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
 ["name"]           = property.custom(xmlname_get, xmlname_set),
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
 ["modstring"]   = property.custom(modstring_get, function (self, value) self.am_modstring = value end),
 ["conditions"]  = nil -- NEED CUSTOM REFERENCE TO GLOBAL CONTAINER HERE....
 })

t.li = dc.create
({
 ["text"]        = property.scalar("am_text"),
 ["modstring"]   = property.custom(function (self, value) return self.amModString:GetText() end, function (self, value) self.amModString:SetText(value)),
 ["conditions"]  = property.array("am_conditions", dc.condition.simple)
 })


dc.macro = { }

t = dc.macro

t.simple = dc.create
({
 ["name"]       = property.scalar("name"),
 ["icon"]       = property.scalar("icon"),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple),
 ["enabled"]    = property.scalar("enabled")
})

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





t.li = dc.create
({
 ["name"]       = property.macro_name,
 ["icon"]       = property.custom(function (self) return self.amIcon:GetTexture() end, function (self, value) self.amIcon:SetTexture(value) end),
 ["modifiers"]  = property.array("modifiers", dc.modifier.simple),
 ["enabled"]    = property.custom
    (function (self)
        return self.am_enabled
     end,

     function (self, value)
        self.am_enabled = value
     
        self.amName:SetFontObject(value and "GameFontNormal" or "GameFontDisable")
        self.amIcon:SetDesaturated(not value and 1 or nil)
        self.amNumModifiers:SetFontObject(value and "GameFontHighlightSmall" or "GameFontDisableSmall")
     end
    )
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