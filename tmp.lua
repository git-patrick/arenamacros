

dataclass = { }

function dataclass.create_index_metatable(...)
    local arg = { ... }
    
    return { __index = function(object, key)
        for i,v in pairs(arg) do
            if (v[key]) then
                return v[key]
            end
        end
        
        return nil
    end }
end


-- the varargs are a set of tables to add to the metatable search list for the newly created factory's products.
function dataclass.create(property_list, ...)
    local t = setmetatable({ }, dataclass.factory)
    
    -- this metatable is here instead of in :create below so the table is reused by each call to that :create
    t._metatable = dataclass.create_index_metatable(unpack(...), { ["_properties"] = property_list }, dataclass.product)
    
    return t
end

-- this is used as part of the metatable __index for the factories returned by dataclass.create
dataclass.factory = { __index = { } }

function dataclass.factory.__index:create(obj)
    local t = setmetatable(obj or {}, self._metatable)
    
    return t
end

-- this is used as the base metatable for the objects returned by the factories returned by dataclass.create
dataclass.product = { __index = { } }

function dataclass.product.__index:am_set(to)
    for i, v in pairs(self._properties) do
        v.set(self, to._properties[i].get(to))
    end
    
    return self
end


property = { }

function property.create(name, prop_class)
    local t = setmetatable({ }, { __index = prop_class })
    
    t._name = name

    return t
end

property.scalar = { }

function property.scalar:get()
    return self[self._property]
end
function property.scalar:set(value)
    self._value = value
end


property_array = { base = { __index = { } } }

function property_array.create(factory)
    local t = setmetatable({ }, property_array.base)
    
    t._factory = factory
    
    return t
end
function property_array.base.__index:get(parent)
    return self._value
end

function property_array.base.__index:set(parent, value)
    self._value = { }
    
    for i, v in pairs(value) do
        table.insert(self._value, self._factory.create():am_set(v))
    end
end







dataclass_macro = { }

dataclass_macro.simple  = dataclass.create({ ["name"] = property_scalar, ["icon"] = property_scalar, ["modifiers"] = property_array(...) })
dataclass_macro.frame   = dataclass.create({ ["name"] = property_custom(), ["icon"] = property_scalar, ["modifiers"] = property_array(dataclass_modifier.simple) })
dataclass_macro.li      = dataclass.create({ ["name"] = property_custom(), ["icon"] = property_scalar, ["modifiers"] = property_array(database_modifier) })
dataclass_macro.db      = dataclass.create({ ["name"] = property_custom(), ["icon"] = property_scalar, ["modifiers"] = property_array(database_modifier) })


-- NOW I WANT database_macro.db to be a factory that pumps out objects of that type.
-- dataclass.create is a factory to produce factories.
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



