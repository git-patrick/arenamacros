local addon_name, e = ...

local libcontainer	= e:addlib(lib:new({ "container", "1.0" }))
local libwow		= e:lib("wow")
local libutil		= e:lib("utility")

local uidmap = libcontainer:addclass(class.create("uidmap"))

-- this object is used to record a chosen property of dataclass objects, and is used by containers to fail add if the property is already in use.
-- for example, it demands macro names be unique.  seperated from the container itself so multiple containers can use the same map

function uidmap:init(uid_class, unique_identifier)
    -- unique identifier is the property name of creation objects passed to container:add
    -- that property value will be used as a UNIQUE identifier in a map to indicate whether or not
    -- the id is already in the container.  add will FAIL if that property is not specified.
    
	-- the property uses dataclasses, and so we must define which dataclass the property belongs to
	self.uid_class	   = uid_class
    self.uid           = unique_identifier
    self.map           = { }

	-- this a prehook the dataclass objects set of the chosen uid property!
	-- pretty sweet way to make sure our map is consistent as the UID property changes.
	-- can fail and cancel the change by returning false
    
    
    self.prehook       = function (self, from, to) return self:change_uid(from, to) end
    self.prehook_bind  = libutil:class("bind"):new({ self.prehook, self })
end




-- object is expected to be the product of a dataclass instance with a property the same as self.uid
function uidmap:contains(o)
    if (type(o) == "string") then
        return (self.map[o] ~= nil)
    elseif (type(o) == "table") then
        return (self.map[o:dc_get(self.uid_class,self.uid)] ~= nil)
    end
    
    return false
end

function uidmap:add(object)
    local p = object:dc_getclass(self.uid_class)[self.uid]
    
    if (not p or self:contains(object)) then
        return false
    end
    
    -- set our mapping to true!
    self.map[p:get()] = true
    
    -- this hooks any changes to this property.  return values of false stop the change, true continues it.
    p.prehook:add(self.prehook_bind)
    
    return true
end

function uidmap:rm(object)
    local p = object:dc_getclass(self.uid_class)[self.uid]
    
    if (not object[p] or not self:contains(object)) then
        return false
    end
    
    p.prehook:rm(self.prehook_bind)
    
    self.map[p] = nil

    return true
end

-- altering the value of our child frames UID property must call this somehow to notify the map of changes.
-- to properly alter the UID value, you can use the set_uid() function inherited from am_contained
-- this is now called automatically by prehooks in the dataclass property object set calls.

function uidmap:change_uid(from, to)
    if (not self.uid_map:contains(from) or self.uid_map:contains(to)) then
        return false    -- failure
    end
    
    self.uid_map[from] = nil
    self.uid_map[to] = true
    
    return true
end






-- container class! for lists of WoW Frames!
local container = libcontainer:addclass(class.create("container", libwow:class("frame")))

function container:init(dataclass, frame_pool, uid_map)
	-- this is the expected dataclass of the objects passed to :add
	-- this is what is used in the set
	self.dataclass	   = dataclass
	
    self.frame_pool    = frame_pool
    self.uid_map       = uid_map
	
	-- I should consider getting rid of self.frames here and just using the WoW method :GetChildren
	-- the only reason this is here is this class predates my overall class implementation,
	-- in particular, libwow:class("frame")
	
    self.frames        = { }           -- child frames
end

-- this is called whenever a frame is resorted or removed (resort is called by add).
-- this has the default behavior from contained of updating the background color by index or highlight if it is set.
-- that behavior can be overridden in subclasses of contained
function container:update()
    for i,v in ipairs(self.frames) do
        v:am_update(i)
        v:am_detach()
    end
    
    -- shuffle the frames anchors based on new setup.  detach first so we don't get a loop of frame references
    for i,v in ipairs(self.frames) do
        v:am_attach(self.frames[i - 1])
    end
end

function container:addall(objects)
    for i, v in pairs(objects) do
        self:add(v)
    end
end

function container:add(dcobject)
    if (self.uid_map and self.uid_map:contains(dcobject)) then
        return 1
    end
    
    local f = self.frame_pool:get()

    table.insert(self.frames, f)
    
    f:SetParent(self)
    
    -- I'm not sure why these are necessary.  You would think SetParent and the XML defined anchors from amListItemTemplate would be enough, but they arent.
    f:SetPoint("RIGHT")
    f:SetPoint("TOPLEFT")
    
    f:am_init(self)
    f:am_update(self:count())
    
    -- check if adding our object works!
    if (not f:am_onadd(dcobject)) then
        table.remove(self.frames, self:count())
        self.frame_pool:give(f)
        
        return 2
    end
	
	f:am_resort()
    f:am_show()
    
    return nil, f -- for success
end

function container:highlight(index)
    if (self.am_highlighted) then
        self.am_highlighted:am_unhighlight()
    end
    
    self.am_highlighted = self.frames[index]
    
    if (self.am_highlighted) then
        self.am_highlighted:am_highlight()
    end
end

-- this takes a frame from our list and moves it to the appropriate place based on custom sorting requirements if they exist
-- assumes all other frames in the list are already in their appropriate sorted position with the possible exception of the frame at index
function container:resort(index)
    local f = self.frames[index]
    
    if (f.am_compare) then
        -- the object has custom sorting requirements, do it here...
        for i,v in ipairs(self.frames) do
            if (v:am_compare(f) > 0) then
                table.remove(self.frames, index)
                table.insert(self.frames, i, f)
                
                break
            end
        end
    end
    
    self:update()
end

function container:remove(index)
    local f = self.frames[index]
    
    if (self.uid_map) then
        self.uid_map:rm(self.frames[index])
    end
    
    f:am_onremove()

    self.frame_pool:give(f)
    table.remove(self.frames, index)
    
    self:update()
end

function container:clear()
    -- go backwards so the auto indexes dont have to shuffle.  aka, faster
    for i = self:count(), 1, -1 do
        self:remove(i)
    end
end

function container:get_uidmap()
    return self.uid_map
end

function container:get_frames()
    return self.frames
end

function container:count()
    return table.getn(self.frames)
end
