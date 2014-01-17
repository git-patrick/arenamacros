am_dbobject = { mt = { __index = setmetatable({ }, am_dataobject.mt) } }

function am_dbobject.create(property_list)
    return setmetatable(am_dataobject.create(property_list), am_dbobject.mt)
end
function am_dbobject.mt.__index:am_getproperty(name)
    return self[name]
end
function am_dbobject.mt.__index:am_setproperty(name, value)
    self[name] = value
    
    return value
end