am_pool = { mt = { __index = { } } }

function am_pool.create(create_frame_function)
    local c = setmetatable({ }, am_pool.mt)
    
    c.create_frame = create_frame_function
    c.free = { }

    return c
end

function am_pool.mt.__index:get()
    local f
    local pool_index = table.getn(self.free)
    
    if (pool_index > 0) then
        f = self.free[pool_index]
        
        table.remove(self.free, pool_index)
    else
        f = self.create_frame()
    end
    
    return f
end

-- make sure you only give us the appropriate frames!  doesn't check to make sure it came from this pool, or even is the appropriate type.
function am_pool.mt.__index:give(frame)
    frame:am_release()
    
    table.insert(self.free, frame)
end







am_uidmap = { mt = { __index = { } } }

function am_uidmap.create(unique_identifier)
    local t         = setmetatable({ }, am_uidmap.mt)
    
    -- unique identifier is the property name of creation objects passed to container:add
    -- that property value will be used as a UNIQUE identifier in a map to indicate whether or not
    -- the id is already in the container.  add will FAIL if that property is not specified.
    
    t.uid           = unique_identifier
    t.map           = { }
    
    return          t
end

-- object is expected to be an am_dataobject with a property the same as self.uid
function am_uidmap.mt.__index:contains(o)
    if (type(o) == "string") then
        return (self.map[o] ~= nil)
    elseif (type(o) == "table") then
        return (self.map[o:am_getproperty(self.uid)] ~= nil)
    end
    
    return false
end

function am_uidmap.mt.__index:add(object)
    local p = object:am_getproperty(self.uid)
    
    if (not p or self:contains(p)) then
        return false
    end
    
    self.map[p] = true
    
    return true
end

function am_uidmap.mt.__index:rm(object)
    local p = object:am_getproperty(self.uid)
    
    if (not object[p] or not self:contains(object)) then
        return false
    end
    
    self.map[p] = nil
    
    return true
end

-- altering the value of our child frames UID property must call this somehow to notify the map of changes.
-- to properly alter the UID value, you can use the set_uid() function inherited from am_contained

function am_uidmap.mt.__index:change_uid(from, to)
    if (not self.uid_map:contains(from) or self.uid_map:contains(to)) then
        return 1    -- failure
    end
    
    self.uid_map[from] = nil
    self.uid_map[to] = true
    
    return nil
end






-- container class!

am_container = { }

function am_container.create(parent_frame, frame_pool, uid_map)
    local c         = { }
    
    setmetatable(c, am_container.mt)

    c.parent_frame  = parent_frame
    c.frame_pool    = frame_pool
    c.uid_map       = uid_map
    c.frames        = { }           -- child frames
    
    return c
end

am_container.mt = { __index = { } }

-- this is called whenever a frame is resorted or removed (resort is called by add).
-- this has the default behavior from am_contained of updating the background color by index or highlight if it is set.
-- that behavior can be overridden in subclasses.
function am_container.mt.__index:update()
    for i,v in ipairs(self.frames) do
        v:am_update(i)
        v:am_detach()
    end
    
    -- shuffle the frames anchors based on new setup.  detach first so we don't get a loop of frame references
    for i,v in ipairs(self.frames) do
        v:am_attach(self.frames[i - 1])
    end
end

function am_container.mt.__index:addall(objects)
    for i, v in pairs(objects) do
        self:add(v)
    end
end

function am_container.mt.__index:add(object)
    if (self.uid_map and self.uid_map:contains(object)) then
        return 1
    end
    
    local f = self.frame_pool:get()

    table.insert(self.frames, f)
    
    f:SetParent(self.parent_frame)
    
    -- I'm not sure why these are necessary.  You would think SetParent and the XML defined anchors from amListItemTemplate would be enough, but they arent.
    f:SetPoint("RIGHT")
    f:SetPoint("TOPLEFT")
    
    f:am_init(self)
    f:am_update(self:count())
    
    -- check if adding our object works!
    if (f:am_onadd(object)) then
        table.remove(self.frames, self:count())
        self.frame_pool:give(f)
        
        return 2
    end
    
    f:am_show()
    
    return nil, f -- for success
end

function am_container.mt.__index:highlight(index)
    if (self.am_highlighted) then
        self.am_highlighted:am_unhighlight()
    end
    
    self.am_highlighted = self.frames[index]
    
    if (self.am_highlighted) then
        self.am_highlighted:am_highlight()
    end
end

-- this takes a frame from our list and moves it to the appropriate place based on custom sorting requirements if they exist
function am_container.mt.__index:resort(index)
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

function am_container.mt.__index:remove(index)
    local f = self.frames[index]
    
    if (self.uid_map) then
        self.uid_map:rm(self.frames[index])
    end
    
    f:am_onremove()

    self.frame_pool:give(f)
    table.remove(self.frames, index)
    
    self:update()
end

function am_container.mt.__index:clear()
    -- go backwards so the auto indexes dont have to shuffle.  aka, faster
    for i = self:count(), 1, -1 do
        self:remove(i)
    end
end

function am_container.mt.__index:get_uidmap()
    return self.uid_map
end

function am_container.mt.__index:get_frames()
    return self.frames
end

function am_container.mt.__index:count()
    return table.getn(self.frames)
end
