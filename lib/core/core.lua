local addon_name, addon_table = ... --"TEST", { { }, { }, { }, { }, { } }
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

local class_container = class.create("class_container")

function class_container:init()
	self.classes = { }
end
function class_container:addclass(c)
	assert(not self.classes[c.name])

	self.classes[c.name] = c

	return self.classes[name]
end
function class_container:class(name)
	return self.classes[name]
end

addon = class.create("addon", class_container)

function addon:init(name, version, onload)
    self.name     = name
	self.version  = version
    self.libs     = { }

	self.initialized = false
	self.onload = onload

	self.frame = CreateFrame("Frame", UIParent, nil)
	self.events = { }

	function self.events.PLAYER_ENTERING_WORLD()
		if (self.initialized) then
			return
		end

		self.onload()
	end

	self.frame:SetScript("OnEvent", function (event, ...) return self.events[event](...) end)
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:addlib(lib)
	assert(not self.libs[lib.name])

	self.libs[name] = lib

	return self.libs[name]
end

function addon:lib(name)
	return self.libs[name]
end

lib = class.create("lib", class_container)

function lib:init(name, version)
	self.name = name
	self.version = version
end