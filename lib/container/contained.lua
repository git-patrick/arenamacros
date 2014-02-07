local addon_name, addon_table = ...
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

-- this is the base class for frames expected to function inside an am_container
local contained = e:lib("container"):mkclass("contained")

-- override the default mt, and setup some class static variables.
contained.mt		= { __index = CreateFrame("Button", nil, UIParent) }
contained.colors	= {
    bg1 = { r = 1, g = 1, b = 1, a = 0.08 },
    bg2 = { r = 0, g = 0, b = 0, a = 0 },
    bghl = { r = 0, g = 1, b = 0, a = 0.08 }
}

----------------------------------------------------------------------------------------
-- APPEARANCE AND POSITION RELATED STUFF
----------------------------------------------------------------------------------------

function contained.mt.__index:am_unhighlight()
    self.am_highlighted = nil
end
function contained.mt.__index:am_highlight()
    self.am_highlighted = true
end
function contained.mt.__index:am_detach()
    self:SetPoint("TOPLEFT")
end
function contained.mt.__index:am_attach(to)
    if (to) then
        self:SetPoint("TOPLEFT", to, "BOTTOMLEFT")
    else
        self:SetPoint("TOPLEFT")
    end
end

------------------------------------------------------------------------------------------
-- INITIALIZATION SEQUENCE
------------------------------------------------------------------------------------------

-- called first thing once the frame is retrieved from the pool
function contained.mt.__index:am_init(container)
    self.am_container = container
end

function contained.mt.__index:am_onadd(dataobject)
    -- this is called by the container in an attempt to add the object.  adding can be canceled by returning non nil
    
    self:am_set(dataobject)
    
    return nil  -- for success
end
-- called after the frame is successfully added
function contained.mt.__index:am_show()
    self:Show()
end
function contained.mt.__index:am_onremove()
    -- this is called by the container when the object is being removed.  can be overridden if action is required (for example in macros, need to delete the actual macro)
    -- removing cannot be canceled.
end
-- this is called when the frame is no longer needed, and is being given back to the pool.  this should be used to clean up the frame for future reuse
function contained.mt.__index:am_release()
    self:Hide()
    self:SetParent(UIParent)
    
    self:am_unhighlight()
    self:am_detach()
end


------------------------------------------------------------------------------------------
-- RUNNING SEQUENCE
------------------------------------------------------------------------------------------

-- am_update is called on every am_contained in a container whenever an object is resorted or removed from the container.
-- a resort happens on every insert.
-- the index into the container is passed
function contained.mt.__index:am_update(i)
    local c
    
    if (self.am_highlighted) then
        c = am_contained.colors.bghl
    else
        c = (i % 2) == 1 and am_contained.colors.bg1 or am_contained.colors.bg2
    end
    
    self:am_setindex(i)
    self.amBackground:SetTexture(c.r, c.g, c.b, c.a)
end

-- used by am_update to record our index in the container.
function contained.mt.__index:am_setindex(i)
    self.am_index = i
end
function contained.mt.__index:am_getindex()
    return self.am_index
end

----------------------------------------------------------------------------------------
-- DATABASE FUNCTIONS
----------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
-- OTHER
----------------------------------------------------------------------------------------

-- this depends on several properties defined by functions above.  if you override some above, you may need to change this.
function contained.mt.__index:am_resort()
    return self.am_container:resort(self:am_getindex())
end

--[[
 
 this function can be used to custom sort the objects.
 if it is defined, it is called on insert of new elements to compare it with the existing.  a return value of > 0 inserts at the position of with, otherwise it continues checking.
 
    function am_contained.mt.__index:am_compare(with)
     
    end
     
]]--

-- this is just a little utility function since a wow Frame's GetPoint function takes an index for some dumb reason.
function contained.mt.__index:am_getpoint(what)
    for i = 1, self:GetNumPoints() do
        local pt = { self:GetPoint(i) }
        
        if (pt[1] == what) then
            return unpack(what)
        end
    end
    
    return nil
end
