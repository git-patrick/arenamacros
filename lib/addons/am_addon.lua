am_addon = { mt = { __index = { } } }

function am_addon.create(name, event_list)
    local t = setmetatable({ }, am_addon.mt)
    
    t.name = name
    
    if (event_list) then
        t.frame = CreateFrame("Frame", nil, UIParent)
        t.frame:SetScript("OnEvent", function (...) t:onevent(...) end)
        
        for i, v in pairs(event_list) do
            t.frame:RegisterEvent(v)
        end
    end
    
    return t
end

function am_addon.mt.__index:onevent()
    local v = self:get_value()
    
    if (v ~= self:get_storedvalue()) then
        if (self.onchange) then
            self.onchange(self:get_storedvalue(), v)
        end
        
        self:set_storedvalue(v)
    end
end

function am_addon.mt.__index:set_storedvalue(v)
    self._v = v
end
function am_addon.mt.__index:get_storedvalue()
    return self._v
end

function am_addon.mt.__index.get_value()
    return nil
end

function am_addon.mt.__index:get_name()
    return self.name
end

function am_addon.mt.__index.value_onclick(button)
    
end

function am_addon.mt.__index.relation_onclick(button)
    
end

function am_addon.mt.__index.test(relation, value)
    return false
end
