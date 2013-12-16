-- this is the base class for frames expected to function inside an am_container
am_contained = { __index = CreateFrame("Button", nil, UIParent) }

function am_contained.__index:am_getuid()
    return nil
end

function am_contained.__index:am_setuid(to)
    if (self:am_getuid() and self.am_container:change_uid(self:am_getuid(), to)) then
        return 1
    end
    
    return nil
end

function am_contained.__index:am_setindex(i)
    self.am_index = i
end

function am_contained.__index:am_getindex()
    return self.am_index
end

function am_contained.__index:am_set(obj)
    print("am: this should be virtual")
end

function am_contained.__index:am_add(object)
    -- this is called by the container once the object is added.  can be overriden as required
    
    self:am_set(object)
    
    return nil  -- for success
end
function am_contained.__index:am_remove()
    -- this is called by the container when the object is being removed.  can be overridden if action is required (for example in macros, need to delete the actual macro)
end

function am_contained.__index:am_detach()
    self:SetPoint("TOPLEFT")
end

function am_contained.__index:am_attach(to)
    if (to) then
        self:SetPoint("TOPLEFT", to, "BOTTOMLEFT")
    else
        self:SetPoint("TOPLEFT")
    end
end









-- container class!

am_container = {
    colors = {
        bg1 = { r = 1, g = 1, b = 1, a = 0.08 },
        bg2 = { r = 0, g = 0, b = 0, a = 0 }
    }
}

function am_container.create(parent_frame, create_frame_function, unique_identifier)
    local c         = { }
    
    setmetatable(c, am_container.mt)
    
    c.create_frame  = create_frame_function
    c.parent_frame  = parent_frame
    c.pool          = { }           -- frame pool to draw from and dump into
    c.frames        = { }           -- child frames
    
    -- unique identifier is the property name of creation objects passed to container:add
    -- that property value will be used as a UNIQUE identifier in a map to indicate whether or not
    -- the id is already in the container.  add will FAIL if that property is not specified.
    
    c.uid           = unique_identifier
    c.uid_map       = { }
    
    return c
end

am_container.mt = { __index = { } }

function am_container.mt.__index:set_indexes(start_index)
    for i = start_index or 1, self:count(self.frames) do
        self.frames[i]:am_setindex(i)
    end
end

function am_container.mt.__index:updatebgs()
    for i,v in ipairs(self.frames) do
        local c = (i % 2) == 1 and am_container.colors.bg1 or am_container.colors.bg2
        
        v.am_background:SetTexture(c.r, c.g, c.b, c.a)
    end
end

function am_container.mt.__index:addall(objects)
    for i, v in pairs(objects) do
        self:add(v)
    end
end

function am_container.mt.__index:add(object)
    -- if our container specifies a uniqued identifier, the object must have it, and our container must not already contain that object otherwise we fail.
    if (self.uid) then
        if (not object[self.uid] or self.uid_map[object[self.uid]]) then
            return 1
        end
    
        self.uid_map[object[self.uid]] = true
    end
    
    -- create a new frame or grab one from the "used" pool
    local f
    local pool_index = table.getn(self.pool)
    
    if (pool_index > 0) then
        f = self.pool[pool_index]
    else
        f = self.create_frame(self.parent_frame)
        
        -- not exactly sure why this is needed.  I think it might have something to do with my metatable setup
        f:SetParent(self.parent_frame)
    end
    
    f.am_container = self
    
    -- check if adding our object works!
    if (f:am_add(object)) then
        if (pool_index == 0) then
            table.insert(self.pool, f)
        end
        
        return 2
    end
    
    -- we have succeeded, so remove the frame from the used pool if that's where we got it
    if (pool_index > 0) then
        table.remove(self.pool, pool_index)
    end
    
    -- put it into our actual frame list
    table.insert(self.frames, f)
    
    self:refresh(self:count())
    
    f:Show()
    
    return nil, f -- for success
end

-- this takes a frame from our list and moves it to the appropriate place based on custom sorting requirements if they exist
function am_container.mt.__index:refresh(index)
    local f = self.frames[index]
    local f_next = nil
    
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
    
    -- update all the frame indices
    self:set_indexes()
    
    -- shuffle the frames anchors based on new setup.  detach first so we don't get a loop of frame references
    for i,v in ipairs(self.frames) do
        v:am_detach()
    end
    
    for i,v in ipairs(self.frames) do
        v:am_attach(self.frames[i - 1])
    end
    
    self:updatebgs()
end

function am_container.mt.__index:remove(index)
    if (self.uid) then
        -- I don't check the index return on getuid because every created frame MUST have a uid specified to container:add, 
        -- and it must provide this method to access that uid.  failure to do so is a precondition issue.
        
        self.uid_map[self.frames[index]:am_getuid()] = nil
    end
    
    self.frames[index]:Hide()
    
    if (self.frames[index + 1]) then
        self.frames[index + 1]:ClearAllPoints()
        
        for i = 1, self.frames[index]:GetNumPoints() do
            self.frames[index + 1]:SetPoint(self.frames[index]:GetPoint(i))
        end
    end
    
    self.frames[index]:am_remove()
    
    table.insert(self.pool, self.frames[index])
    table.remove(self.frames, index)
    
    self:set_indexes()
    self:updatebgs()
end

function am_container.mt.__index:clear()
    for i = self:count(), 1, -1 do
        self:remove(i)
    end
end

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

function am_container.mt.__index:contains(uid)
    return (self.uid_map[uid] ~= nil)
end

function am_container.mt.__index:count()
    return table.getn(self.frames)
end
