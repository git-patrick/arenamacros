-- to properly use the database stuff above, we need to make a slightly more complicated implementation of the dataclass_macro than dataobject_macro
-- though not much more complicated.  can still use the dataobject_modifier and condition stuff though.

database_macro = { mt = { __index = setmetatable({ }, dataobject_macro) } }

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

function database_macro.mt.__index:am_setproperty(name, value)
    if (name == "name") then
        -- this DOES NOT CHECK to see if we are overriding another database entry.  you need to worry about that somewhere else.
        
        if (self._database) then
            self._database:rm(self)
        end
        
        dataobject_macro.am_setproperty(self, name, value)
        
        if (self._database) then
            self._database:add(self)
        end
    else
        dataobject_macro.am_setproperty(self, name, value)
    end
    
    return true
end

function database_macro.mt.__index:am_delete()
    if (self._database) then
        self._database:rm(self)
    end
end