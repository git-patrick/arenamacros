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
    local t         = setmetatable(t, am_uidmap.mt)
    
    -- unique identifier is the property name of creation objects passed to container:add
    -- that property value will be used as a UNIQUE identifier in a map to indicate whether or not
    -- the id is already in the container.  add will FAIL if that property is not specified.
    
    t.uid           = unique_identifier
    t.map           = { }
    
    return          t
end

function am_uidmap.mt.__index:contains(object)
    return (self.map[object[self.uid]] ~= nil)
end

function am_uidmap.mt.__index:add(object)
    if (not object[self.uid] or self:contains(object)) then
        return false
    end
    
    self.map[object[self.uid]] = true
    
    return true
end

function am_uidmap.mt.__index:rm(object)
    if (not object[self.uid] or not self:contains(object)) then
        return false
    end
    
    self.map[object[self.uid]] = nil
    
    return true
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
    end
end

function am_container.mt.__index:addall(objects)
    for i, v in pairs(objects) do
        self:add(v)
    end
end

function am_container.mt.__index:add(object)
    if (self.uid_map:contains(object)) then
        return 1
    end
    
    local f = self.frame_pool:get()
    
    f:am_init(self)
    
    -- check if adding our object works!
    if (f:am_onadd(object)) then
        self.frame_pool:give(f)
        
        return 2
    end
    
    -- succeeded
    -- put it into our actual frame list
    table.insert(self.frames, f)
    
    f:SetParent(self.parent_frame)
    
    -- reposition the new frame based on any of its custom sorting requirements.
    -- can't use f:am_resort() because no self:update has been called yet, so the frame does not know its index etc etc.
    -- this call does the self:update() for us.
    self:resort(self:count())
    
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
    
    -- shuffle the frames anchors based on new setup.  detach first so we don't get a loop of frame references
    for i,v in ipairs(self.frames) do
        v:am_detach()
    end
    
    for i,v in ipairs(self.frames) do
        v:am_attach(self.frames[i - 1])
    end
end

function am_container.mt.__index:remove(index)
    local f = self.frames[index]
    
    if (self.uid_map) then
        self.uid_map:rm(self.frames[index])
    end
    
    if (self.frames[index + 1]) then
        self.frames[index + 1]:SetPoint(f:am_getpoint("TOP"))
    end

    f:am_onremove()

    self.frame_pool:give(f)
    table.remove(self.frames, index)
    
    self:update()
end

function am_container.mt.__index:clear()
    for i = self:count(), 1, -1 do
        self:remove(i)
    end
end

-- altering the value of our child frames UID property must call this somehow to notify the container that the value has changed.
-- to properly alter the UID value, you can use the set_uid() function inherited from am_contained

function am_container.mt.__index:change_uid(from, to)
    if (not self:contains(from)) then
        return nil
    end
    
    if (self:contains(to)) then
        return 1
    end
    
    self.uid_map[from] = nil
    self.uid_map[to] = true
    
    return nil
end

function am_container.mt.__index:count()
    return table.getn(self.frames)
end
