-- to properly use the database stuff above, we need to make a slightly more complicated implementation of the dataclass_macro than dataobject_macro
-- though not much more complicated.  can still use the dataobject_modifier and condition stuff though.

database_macro.name = setmetatable({ }, property_scalar.base)

function database_macro.name:set(parent, value)
    if (parent._database) then
        --    parent._database:rm(self)
        --    parent._database:add(self)
    end
    
    property_scalar.base.set(self,parent,value)
end

function database_macro.mt.__index:am_delete()
    if (self._database) then
        self._database:rm(self)
    end
end

database_macro = dataclass.create(["name"] = property_custom.create(database_macro.name), ["icon"] = property_scalar.create(), ["modifiers"] = property_array.create(database_modifier))

function database_macro.create(object, database)
    local t = setmetatable(object or { }, pat.create_index_metatable({ _database = database }, database_macro.mt))

    for i,v in pairs(t:am_getproperty("modifiers")) do
        dataobject_modifier.create(v)
    end
    
    if (database) then
        database:add(t)
    end
    
    return t
end




























