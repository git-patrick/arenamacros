local addon_name, e = ...

local libwow		= e:lib("wow")
local libutil		= e:lib("utility")
local libextension	= e:addlib(lib:new({ "extension", "1.0" }))

local extension		= libextension:addclass(class.create("extension"))

local erray			= libutil:class("erray")
local class_pool	= libutil:class("pool")

local extension_pool= class_pool:new({ function() return CreateFrame("Frame", UIParent) end })

function extension:init(name, pool, event_list)
	self.name = name
	self.pool = pool
	self.hooks = erray:new()
	
	if (event_list) then
		self.frame = extension_pool:get()
		self.frame.am_extension = self
		
		self.frame:SetScript("OnEvent", function (frame, ...) frame.am_extension:onevent(...) end)
		
		for i,event in ipairs(event_list) do
			self.frame:RegisterEvent(event)
		end
	end
end

function extension:release()
	if (self.frame) then
		self.frame:UnRegisterAllEvents()
		self.frame:SetScript("OnEvent", nil)
		self.frame.am_extension = nil
		
		extension_pool:give(self.frame)
		
		self.frame = nil
	end
end

function extension:onevent()
    local v = self:get_value()
    
    if (v ~= self:get_storedvalue()) then
		self:onchange(self:get_storedvalue(), v)
        
        self:set_storedvalue(v)
    end
end

function extension:attach(contained_condition)
	local a = contained_condition:am_getamaddon()
	
	if (a) then
		a:detach(contained_condition)
	end
	
	contained_condition:am_setamaddon(self)
end

function extension:detach(contained_condition)
	
end

function extension:onchange(from, to)
	for i,v in ipairs(self.hooks) do
		v(self, from, to)
	end
end





-- this should be overridden to give the appropriate value of whatever the condition is currently
function extension:get_value()
    return nil
end





function extension:set_storedvalue(v)
    self.stored_value = v
end
function extension:get_storedvalue()
    return self.stored_value
end
function extension:get_name()
    return self.name
end






local extension_frame = libextension:addclass(class.create("extension_frame", libwow:class("button")))

function extension_frame:init(ext)
	self.am_extension = ext
	self.am_callback = libutil:class("bind"):new(self.am_onchange, self)
	self.am_extension.hooks:add(self.am_callback)
end

function extension_frame:release()
	self.am_extension.hooks:rm(self.am_callback)
end

function extension_frame:am_onchange(ext, from, to)
	print("VALUE CHANGED OMG")
end