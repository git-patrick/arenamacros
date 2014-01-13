
token = { mt = { __index = { } } }

function token.create(name, callback)
    local t = setmetatable({ }, token.mt)
    
    t.callbacks = { callback }
    
    t.name = name
    t.status = "pending"
    -- t.value = nil
    
    return t
end

function token.mt.__index:set_value(value)
    self.value = value
    self.status = "finished"
    
    for i, v in pairs(self.callbacks) do
        v(value)
    end
end

function token.mt.__index:get_name()
    return self.name
end

function token.mt.__index:get_value()
    return self.value
end

function token.mt.__index:waiting()
    return self.status == "pending"
end

function token.mt.__index:push_callback(callback)
    table.insert(self.callbacks, callback)
end