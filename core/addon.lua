local addon_name, addon_table = ...

class_container = class.create("class_container")

function class_container:init()
	self.classes = { }
end
function class_container:addclass(c)
	assert(not self.classes[c.name])

	self.classes[c.name] = c

	return self.classes[c.name]
end
function class_container:class(name)
	return self.classes[name]
end

-- this is a class, but the intention is to only ever create one per addon.
-- I won't rely on this fact, but performance and memory decisions have this in mind
addon = class.create("addon", class_container)

function addon:init(onload)
    self.name     = addon_name
    self.title    = GetAddOnMetadata(self.name, "Title")
	self.version  = GetAddOnMetadata(self.name, "Version")
    
    self.libs     = { }

	self.initialized = false
	self.onload = onload

	self.frame = CreateFrame("Frame", UIParent, nil)
	self.frame._addon = self
    
    self.frame:SetScript("OnEvent", function (frame, e, ...) frame._addon:onevent(e,...) end)
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("ADDON_LOADED")
end

-- this is the event handler for the addon's primary frame used for load processing
function addon:onevent(e, ...)
    if (e == "PLAYER_ENTERING_WORLD") then
        print("PLAYER_ENTERING_WORLD")
    elseif (e == "PLAYER_LOGIN") then
        print("PLAYER_LOGIN")
        
        if (self.initialized) then
            return
        end
        
        if (self.onload) then
            self.onload()
        end
        
        self.initialized = true
    elseif (e == "ADDON_LOADED") then
        local name = select(1, ...)
        
        if (name == addon_name) then
            print("ADDON_LOADED")
        end
    end
end

function addon:addlib(lib)
	assert(not self.libs[lib.name])

	self.libs[lib.name] = lib

	return self.libs[lib.name]
end
function addon:lib(name)
	return self.libs[name]
end



lib = class.create("lib", class_container)

function lib:init(name, version, onload)
	self.name = name
	self.version = version
	self.onload = onload
end