local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

local addon = { mt = { __index = { } } }

function addon.create(engine, name)
    setmetatable(engine, addon.mt)
    
    engine.name     = name
    engine.libs     = { }
    
    return engine
end

function addon.mt.__index:create_library(name)
    assert(not self.libs[name])
    
    self.libs[name]   = { }
    
    return self
end

function addon.mt.__index:lib(name)
    return self.libs[name]
end




local library = { mt = { __index = { } } }

function library.create(name, version)
    local t = { }
    
    t.name = name
    t.version = version
    
    end
end