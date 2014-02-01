local addon_name, addon_table = ...

local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

e.util = { }

function e.util._tostr(o)
    if type(o) == 'table' then
        local s = '{ '
        
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            
            s = s .. '['..k..'] = ' .. dc._tostr(v) .. ','
        end
        
        return s .. '} '
    else
        return tostring(o)
    end
end

function e.util.create_search_indexmetatable(...)
    local table_list = { ... }
    
    return { __index = function(object, key)
        for i,v in pairs(table_list) do
            if (v[key]) then
                return v[key]
            elseif (v.__index and v.__index[key]) then
                return v.__index[key]
            end
        end
        
        return nil
    end }
end