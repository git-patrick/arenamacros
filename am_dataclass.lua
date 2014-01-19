--[[ okay, so I am abstracting away properties...

I now have two objects capable of storing the same data properties...

that is the database table object, and my interface frame object.  I want them both to have some defined "property" list, and then to get/set a property you just do

am_getproperty(name)
am_setproperty(name, value)

so I want them to inherit from some common thing...

would need multiple inheritance on the frame objects since they are already inheritting from am_contained

]]--

am_dataclass = { mt = { __index = { } } }

function am_dataclass.create(obj, property_list)
    local t = setmetatable(obj or {}, am_dataobject.mt)
    
    t.am_properties = property_list
    
    return t
end
function am_dataclass.mt.__index:am_getproperties()
    return self.am_properties
end
function am_dataclass.mt.__index:am_getproperty(name)
    print("am_dataobject: error!  am_getproperty should be virtual")
end
function am_dataclass.mt.__index:am_setproperty(name, value)
    print("am_dataobject: error!  am_setproperty should be virtual")
end
function am_dataclass.mt.__index:am_set(to)
    for i, v in pairs(self:am_getproperties()) do
        self:am_setproperty(v, to:am_getproperty(i))
    end
end

dataclass_macro       = am_dataclass.create({ "name", "icon", "modifiers" })
dataclass_modifier    = am_dataclass.create({ "modstring", "text", "conditions" })
dataclass_condition   = am_dataclass.create({ "name", "relation", "value" })