db_macro

am_dbobject = { mt = { __index = setmetatable({ }, am_dataobject.mt) } }

function am_dbobject.create(obj, dataclass)
    return setmetatable({ }, pat.multiple_metatable(am_dbobject.mt, dataclass)
end
function am_dbobject.mt.__index:am_getproperty(name)
    return self[name]
end
function am_dbobject.mt.__index:am_setproperty(name, value)
    self[name] = value
    
    return value
end