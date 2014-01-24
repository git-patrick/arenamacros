am_database = { mt = { __index = { } } }

function am_database.create(object, property_key)
    local t = setmetatable(object or { }, pat.create_index_metatable({ _key = property_key }, am_database.mt.__index))
    
    return t
end

function am_database.mt.__index:add(database_object)
    self[database_object:am_getproperty(self._key)] = database_object
end

function am_database.mt.__index:rm(database_object)
    self[database_object:am_getproperty(self._key)] = nil
end

function am_database.mt.__index:contains(database_object)
    return self[database_object:am_getproperty(self._key)] ~= nil
end
