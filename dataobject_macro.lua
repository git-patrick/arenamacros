-- setting the list properties of dataobject_* objects automatically creates the necessary copy objects, and copies the list object's values
dataobject_macro = { mt = { __index = setmetatable({ }, pat.create_index_metatable(dataobject, dataclass_macro)) } }

-- pass either nil for object or have a table with the necessary properties already setup (used for initializing from stored variables between runs)
function dataobject_macro.create(from)
    local t = setmetatable(from or { }, dataobject_macro)
    
    for i,v in pairs(t:am_getproperty("modifiers")) do
        dataobject_modifier.create(v)
    end
    
    return t
end

function dataobject_macro.mt.__index:am_setproperty(name, value)
    if (name == "modifiers") then
        dataclass.array_copy(value, self:am_getproperty("modifiers"), dataobject_modifier)
    else
        dataobject.am_setproperty(self, name, value)
    end
    
    return true
end
