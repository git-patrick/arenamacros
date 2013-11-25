function search_remove(arr, value)
    for i, v in arr do
        if (v == value) then
            table.remove(arr, i)
            
            return true
        end
    end
    
    return false
end




-- OBJECTS EXPECTED TO BE INSIDE AN am_container MUST INHERT FROM am_contained OR PROVIDE ITS METHODS AND Frames methods
am_contained = { __index = CreateFrame("Frame", nil, UIParent) }

function am_contained.__index:am_setindex(i)
    self.am_index = i
end

function am_contained.__index:am_getindex()
    return self.am_index
end

function am_contained.__index:am_set(obj)
    print("am: this should be virtual")
end

-- container class!

am_container = {
    colors = {
        bg1 = { r = 1, g = 1, b = 1, a = 0.08 },
        bg2 = { r = 0, g = 0, b = 0, a = 0 }
    }
}

function am_container.create(parent_frame, create_frame_function)
    print("am_container.create")
    
    local c         = { }
    
    setmetatable(c, am_container.mt)
    
    c.create_frame  = create_frame_function
    c.parent_frame  = parent_frame
    c.pool          = { }           -- frame pool to draw from and dump into
    c.frames        = { }           -- child frames
    
    return c
end

am_container.mt = { __index = { } }

function am_container.mt.__index:fix(start_index)
    for i = start_index or 1, table.getn(self.frames) do
        self.frames[i]:am_setindex(i)
        
        self:fixbg(i)
    end
end

function am_container.mt.__index:fixbg(index)
    local c = (index % 2) == 1 and am_container.colors.bg1 or am_container.colors.bg2
    
    self.frames[index].am_background:SetTexture(c.r, c.g, c.b, c.a)
end
function am_container.mt.__index:addall(objects)
    for i, v in pairs(objects) do
        self:add(v)
    end
end
function am_container.mt.__index:add(object)
    print("t.container.mt.__index:add")
    
    local f
    local i = table.getn(self.pool)
    
    if (i > 0) then
        f = self.pool[i]
        
        table.remove(self.pool, i)
        else
        f = self.create_frame(self.parent_frame)
    end
    
    i = table.getn(self.frames)
    
    f:SetParent(self.parent_frame)
    
    if (i > 0) then
        f:SetPoint("TOPLEFT", self.frames[i], "BOTTOMLEFT")
        else
        f:SetPoint("TOPLEFT", self.parent_frame)
    end
    
    table.insert(self.frames, f)
    
    f:am_set(object)
    
    self:fix()
    
    f:Show()
    
    return f, i + 1
end

function am_container.mt.__index:remove(index)
    print("t.container.mt.__index:remove")
    
    self.frames[index]:Hide()
    
    if (self.frames[index + 1]) then
        self.frames[index + 1]:ClearAllPoints()
        
        for i = 1, self.frames[index]:GetNumPoints() do
            self.frames[index + 1]:SetPoint(self.frames[index]:GetPoint(i))
        end
    end
    
    self.frames[index]:SetParent(UIParent)
    
    table.insert(self.pool, self.frames[index])
    table.remove(self.frames, index)
    
    self:fix()
end

function am_container.mt.__index:clear()
    print("am_container.mt.__index:clear")
    
    for i = table.getn(self.frames), 1, -1 do
        self:remove(i)
    end
end

function am_container.mt.__index:search_remove(f)
    for i,v in ipairs(self.frames) do
        if (v == f) then
            self:remove(i)
        end
    end
end

function am_container.mt.__index:count()
    return table.getn(self.frames)
end




am_macro = { mt = { __index = { } } }
setmetatable(am_macro.mt.__index, am_contained)

function am_macro.create(parent_frame)
    print("am_macro.create")

    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroTemplate"), am_macro.mt)

    return f
end

function am_macro.mt.__index:am_set(object)
    if (object.macroid) then self.am_macroid:SetText(object.macroid) end
    if (object.name) then self.am_name:SetText(object.name) end
    if (object.icon) then self.am_icon:SetTexture(object.icon) end
    if (object.modifiers) then self.am_modifiers = object.modifiers end                -- treat this reference as read only!  don't think lua can actually do that

    local n = self.am_modifiers and table.getn(self.am_modifiers) or 0

    self.am_nummodifiers:SetText(n .. " mod")
end











am_modifier = { mt = { __index = { } } }
setmetatable(am_modifier.mt.__index, am_contained)

function am_modifier.create(parent_frame)
    print("am_modifier.create")

    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierTemplate"), am_modifier.mt)

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


-- this thing needs to accept both lists of frames for when I am saving changes made to conditions lists for the modifier, and the basic object loaded from saved variables.
--[[ I am making the interface for both standard then...

    they have .am_name, .am_relation, and .am_value members

]]--

function am_modifier.mt.__index:am_setindex(i)
    self.am_index = i
    
    self.am_modid:SetText(i)
end
    
function am_modifier.mt.__index:am_updatemodstring()
    local s = "if "
    
    for i,v in pairs(self.am_conditions) do
        s = s .. v.name .. " " .. v.relation .. " " .. v.value .. " and "
    end
    
    s = s:sub(1, s:len() - 4) .. "then ..."

    self.am_modstring:SetText(s)
end












am_condition = { mt = { __index = { } } }
setmetatable(am_condition.mt.__index, am_contained)

function am_condition.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierConditionTemplate"), am_condition.mt)
    
    return f
end

function am_condition.mt.__index:am_set(object)
    print("am_condition.mt.__index:am_set")
    
    -- I need to make sure all conditions exist, and all relations and values are valid.  I also need to create dropdowns for each condition and store them in some global array as well.

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