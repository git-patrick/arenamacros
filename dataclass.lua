--[[
    I now have two objects capable of storing the same data properties...

    that is the database table object, and my interface frame object.  I want them both to have some defined "property" list, and then to get/set a property you just do

    am_getproperty(name)
    am_setproperty(name, value)

    so I want them to inherit from some common thing...

    would need multiple inheritance on the frame objects since they are already inheritting from am_contained

]]--


-- am_dataclass is used to create classes of property lists that I can inherit from.
dataclass = { mt = { __index = { } } }

function dataclass.create(property_list, obj)
    local t = setmetatable(obj or {}, dataclass.mt)
    
    t._properties = property_list
    
    return t
end

function dataclass.copy(value)
    if (type(value) ~= "table") then
        -- this is an array of dataclass objects....
        
end
function dataclass.copy(from, to, factory)
    to = { }
    
    for i,v in pairs(from) do
        table.insert(to, factory.create():am_set(v))
    end
end



function dataclass.mt.__index:am_property(name)
    return self._properties[name]
end
function dataclass.mt.__index:am_set(to)
    for i, v in pairs(self:am_getproperties()) do
        self:am_property(i):set(to:am_property(i))
    end
end

-- here are the 3 classes I need
dataclass_macro       = dataclass.create({ ["name"] = nil, ["icon"] = nil, ["modifiers"] = "array" })
dataclass_modifier    = dataclass.create({ "modstring", "text", "conditions" })
dataclass_condition   = dataclass.create({ "name", "relation", "value" })


dataclass_property = { property_base = { __index = { } } }

function dataclass_property.create(name)
    local t = setmetatable({ }, dataclass_property.property_base)
    
    self._property = name
    
    return t
end

function dataclass_property.property_base.__index:get()
    return self[self._property]
end
function dataclass_property.property_base.__index:set(value)
    self[self._property] = value
end




macro_list = { }
macro_list.name = dataclass_property.create("name")


-- here are the most basic implementation of those classes.
-- these basically store all properties as entries in the table.
-- for the classes above, we need to override macro and modifier atleast because the modifiers and conditions lists must be copied via am_set, not stored as a reference.

dataobject_condition = { mt = { __index = setmetatable({ }, pat.create_index_metatable(dataobject, dataclass_modifier)) } }

function dataobject_modifier.create(object)
    local t = setmetatable(object or { }, dataobject_modifier)
    
    for i,v in pairs(t:am_getproperty("conditions")) do
        dataobject_condition.create(v)
    end
    
    return t
end

function dataobject_modifier.mt.__index:am_setproperty(name, value)
    if (name == "conditions") then
        dataclass.array_copy(value, self:am_getproperty("conditions"), dataobject_condition)
    else
        dataobject.am_setproperty(self, name, value)
    end
    
    return true
end

dataobject_condition = { mt = { __index = setmetatable({ }, pat.create_index_metatable(dataobject, dataclass_condition)) } }

function dataobject_condition.create(object)
    return setmetatable(object or { }, dataobject_condition.mt)
end
