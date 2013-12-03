-- OBJECTS EXPECTED TO BE INSIDE AN am_container MUST INHERT FROM am_contained OR PROVIDE ITS METHODS AND Frames methods

am_contained = { __index = CreateFrame("Frame", nil, UIParent) }

function am_contained.__index:am_getuid()
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

-- container class!

am_container = {
    colors = {
        bg1 = { r = 1, g = 1, b = 1, a = 0.08 },
        bg2 = { r = 0, g = 0, b = 0, a = 0 }
    }
}

function am_container.create(parent_frame, create_frame_function, unique_identifier)
    print("am_container.create")
    
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
    for i = start_index or 1, table.getn(self.frames) do
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
    print("t.container.mt.__index:add")
    
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
        f = self.create_frame(self.parent_frame, self)
    end
    
    -- check if adding our object works!  this will try to actually createmacro the macro for macro objects
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
    
    local insert_index = table.getn(self.frames) + 1
    
    if (f.am_compare) then
        -- the object has custom sorting requirements, do it here...
        for i,v in ipairs(self.frames) do
            if (v:am_compare(f) > 0) then
                insert_index = i
                
                break
            end
        end
    end
    
    -- put it into our actual frame list
    table.insert(self.frames, insert_index, f)
    
    -- update all the frame indices
    self:set_indexes()
    
    f:SetParent(self.parent_frame)
    
    local f_index = f:am_getindex()
    
    -- set our anchor point
    if (f_index > 1) then
        f:SetPoint("TOPLEFT", self.frames[f_index - 1], "BOTTOMLEFT")
    else
        f:SetPoint("TOPLEFT", self.parent_frame)
    end
    
    -- push what is below down
    if (f_index < table.getn(self.frames)) then
        self.frames[f_index + 1]:SetPoint("TOPLEFT", self.frames[f_index], "BOTTOMLEFT")
    end
    
    self:updatebgs()
    
    f:Show()
    
    return nil -- for success
end

function am_container.mt.__index:remove(index)
    print("t.container.mt.__index:remove")
    
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
    self.frames[index]:SetParent(UIParent)
    
    table.insert(self.pool, self.frames[index])
    table.remove(self.frames, index)
    
    self:set_indexes()
    self:updatebgs()
end

function am_container.mt.__index:clear()
    print("am_container.mt.__index:clear")
    
    for i = table.getn(self.frames), 1, -1 do
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
















am_macro = { mt = { __index = { } } }
setmetatable(am_macro.mt.__index, am_contained)

function am_macro.create(parent_frame, parent_container)
    print("am_macro.create")
    
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroTemplate"), am_macro.mt)

    f:SetScript("OnEvent", function(event, self, ...) self:am_event(event, ...) end)

    f.am_container = parent_container
    
    return f
end

function am_macro.mt.__index:am_getuid()
    return self.am_name:GetText()
end

function am_macro.mt.__index:am_remove()
    print("am_macro.mt.__index:am_remove()")
    
    local name = self.am_name:GetText()
    
    DeleteMacro(name)
    AM_MACRO_DATABASE[name] = nil
end

function am_macro.mt.__index:am_add(object)
    -- this is called everytime I insert into the container, so for New Macro button, and on load when I am initializing from the DB
    -- return value of true continues the add, and nil/false stops the add into the container.
    
    if (not GetMacroBody(object.name)) then
        print("MAKING A NEW MACRO")
        
        local icon_filename = object.icon:lower():match("interface\\icons\\([_%a]+)")
        
        if (not pcall(function() CreateMacro(object.name, icon_filename or "INV_Misc_QuestionMark", "", 1) end)) then
            -- macro creation failed!  I believe this can only happen if the macro list is full.  either way, needs to stop insertion.
            
            return 1
        end
    end
    
    -- okay, so the macro should exist at this point
    
    self:am_updateframe(object)
    self:am_updatedb()
    
    return nil      -- for success
end


function am_macro.mt.__index:am_event(event, ...)
    -- currently the only event that can be caught is PLAYER_REGEN_ENABLED
    -- which happens when the macro frame tried to modify the actual macro, but you were in combat.
    -- once combat turns off this event is fired, we turn off this event catch, and recheck conditions
    
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    
    self:am_checkconditions()
end

function am_macro.mt.__index:am_updateframe(object)
    print("am_updateframe")
    
    if (object.name) then self.am_name:SetText(object.name) end
    if (object.icon) then self.am_icon:SetTexture(object.icon) end
    if (object.modifiers) then
        self.am_modifiers = object.modifiers
    end
    
    local n = self.am_modifiers and table.getn(self.am_modifiers) or 0
    
    self.am_nummodifiers:SetText(n .. " mod")
end

function am_macro.mt.__index:am_updatedb()
    print("am_updatedb")
    
    local name = self.am_name:GetText()
    
    if (not AM_MACRO_DATABASE[name]) then
        AM_MACRO_DATABASE[name] = { }
    end
    
    local dbob = AM_MACRO_DATABASE[name]
    
    dbob.name = self.am_name:GetText()
    dbob.icon = self.am_icon:GetTexture()
    dbob.modifiers = self.am_modifiers
end

function am_macro.mt.__index:am_set(object)
    if (object.name ~= self.am_name:GetText()) then
        
        -- attempt to change my uid (name) to the new one in the parent container.  will fail if the new one exists.
        if (self.am_container:change_uid(self:am_getuid(), object.name)) then
            return 1
        end

        -- rename the macro
        EditMacro(self.am_name:GetText(), object.name, nil, nil, 1, 1)
    end
    
    self:am_updateframe(object)
    self:am_updatedb()
    
    self:am_checkconditions()
        
    return nil
end


function am_macro.mt.__index:am_setmacro(text)
    if (InCombatLockdown()) then
        print("am:  error! unable to setup macro " .. self.am_name:GetText() .. ", in combat!")
        
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        
        return
    end

    local tex = self.am_icon:GetTexture()

    if (not pat.make_macro(self.am_name:GetText(), icon_filename or "INV_Misc_QuestionMark", text, 1)) then
        print("am:  error! unable to setup macro " .. self.am_name:GetText())
        
        return false
    end
    
    return true
end

function am_macro.mt.__index:am_checkconditions()
    for i,m in ipairs(self.am_modifiers) do
        local found = true
        
        for j,c in ipairs(m.conditions) do
            if (not AM_CONDITIONS_GLOBAL[c.name].test(c.relation, c.value)) then
                found = false
                break
            end
        end
        
        if (found) then
            self:am_setmacro(m.text)
            
            return nil  -- for success
        end
    end
    
    -- no modifiers are satisified.  set macro text to empty, and icon to QuestionMark
end

function am_macro.mt.__index:am_compare(other)
    -- they should never be equal by precondition
    return (self.am_name:GetText():lower() < other.am_name:GetText():lower()) and -1 or 1
end















am_modifier = { mt = { __index = { } } }
setmetatable(am_modifier.mt.__index, am_contained)

function am_modifier.create(parent_frame, parent_container)
    print("am_modifier.create")

    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierTemplate"), am_modifier.mt)

    f.am_container = parent_container
    
    return f
end

function am_modifier.mt.__index:am_set(object)
    print("am_modifier.mt.__index:am_set")

    if (object.modstring) then
        self.am_modstring:SetText(object.modstring)
    end

    if (object.text) then self.am_text = object.text end
    
    -- there likely needs to be a condition check here to see if all of our conditions are installed !  if they are not, just disable the modifier and make it clear it is disabled graphically
    if (object.conditions) then
        self.am_conditions = object.conditions      -- treat this as read only ... I don't want to change anything in the object until we click "save"
        self:am_updatemodstring()
    end
end

function am_modifier.mt.__index:am_setindex(i)
    self.am_index = i
    
    self.am_modid:SetText(i)
end
    
function am_modifier.mt.__index:am_updatemodstring()
    local s = "if "
    
    for i,v in ipairs(self.am_conditions) do
        s = s .. v.name .. " " .. v.relation .. " " .. v.value .. " and "
    end
    
    s = s:sub(1, s:len() - 4) .. "then ..."

    self.am_modstring:SetText(s)
end












am_condition = { mt = { __index = { } } }
setmetatable(am_condition.mt.__index, am_contained)

function am_condition.create(parent_frame, parent_container)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierConditionTemplate"), am_condition.mt)
    
    f.am_container = parent_container
    
    return f
end

function am_condition.mt.__index:am_set(object)
    print("am_condition.mt.__index:am_set")
    
    -- I need to make sure all conditions exist, and all relations and values are valid.
    
    if (object.name) then self.am_name:SetText(object.name) end
    if (object.relation) then self.am_relation:SetText(object.relation) end
    if (object.value) then self.am_value:SetText(object.value) end
end

function am_condition.mt.__index:am_setindex(i)
    self.am_index = i
    
    local intro = "and"
    local outro = ""
    
    if (i == 1) then
        intro = "if"
    end
    
    if (i == am.conditions:count()) then
        outro = "then"
    end
    
    self.am_introstring:SetText(intro)
    self.am_outrostring:SetText(outro)
end