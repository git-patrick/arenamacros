am_modifier = { mt = { __index = setmetatable({ }, pat.create_index_metatable(dataclass_modifier, am_contained.mt.__index)) } }

function am_modifier.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame or UIParent, "amModifierTemplate"), am_modifier.mt)
    
    return f
end

function am_modifier.mt.__index:am_setproperty(name, value)
    if (name == "modstring") then
        self.amModString:SetText(value or "")
    elseif (name == "text") then
        self.am_text = value
    elseif (name == "conditions") then
        self.am_conditions = value
        self:am_updatemodstring()
    end
    
    return true
end

function am_modifier.mt.__index:am_getproperty(name)
    if (name == "modstring") then
        return self.amModstring:GetText()
    elseif (name == "text") then
        return self.am_text
    elseif (name == "conditions") then
        return self.am_conditions
    end
end

function am_modifier.mt.__index:am_setindex(i)
    self.am_index = i
    self.am_moveto = nil
    
    if (i <= 1) then
        self.amMoveUp:Disable()
    else
        self.amMoveUp:Enable()
    end
    
    if (i >= self.am_container:count()) then
        self.amMoveDown:Disable()
    else
        self.amMoveDown:Enable()
    end
    
    self.amModID:SetText(i)
end

function am_modifier.mt.__index:am_compare(other)
    if not other.am_moveto then
        return 0
    end
    
    if (self:am_getindex() == other.am_moveto) then
        return 1
    end
    
    return 0
end


function am_modifier.mt.__index:am_updatemodstring()
    local s = "if "
    
    for i,v in pairs(self:am_getproperty("conditions")) do
        s = s .. v:am_getproperty("name") .. " " .. v:am_getproperty("relation").text .. " " .. v:am_getproperty("value").text .. " and "
    end
    
    s = s:sub(1, s:len() - 4) .. "then ..."
    
    self:am_setproperty("modstring", s)
end










function amModifier_OnClick(self, button, down)
    amConditionFrame_Setup(self)
end

function amModifier_MoveUp(self, button, down)
    local mod = self:GetParent()
    
    mod.am_moveto = math.max(mod:am_getindex() - 1, 1)
    mod:am_resort()
end

function amModifier_MoveDown(self, button, down)
    local mod = self:GetParent()
    
    mod.am_moveto = math.min(mod:am_getindex() + 1, mod.am_container:count())
    mod:am_resort()
end

function amModifier_Delete(self, button, down)
    am.modifiers:remove(self:GetParent():am_getindex())
end
