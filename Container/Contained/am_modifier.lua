am_modifier = { mt = { __index = { } } }
setmetatable(am_modifier.mt.__index, am_contained.mt)

function am_modifier.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierTemplate"), am_modifier.mt)
    
    return f
end

function am_modifier.mt.__index:am_setproperty(name, value)
    if (name == "modstring") then
        self.am_modstring:SetText(value)
    elseif (name == "text") then
        self.am_text = value
    elseif (name == "conditions") then
        self.am_conditions = value
        self:am_updatemodstring()
    end
end

function am_modifier.mt.__index:am_setindex(i)
    self.am_index = i
    self.am_moveto = nil
    
    if (i <= 1) then
        self.am_moveup:Disable()
    else
        self.am_moveup:Enable()
    end
    
    if (i >= self.am_container:count()) then
        self.am_movedown:Disable()
    else
        self.am_movedown:Enable()
    end
    
    self.am_modid:SetText(i)
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
    
    for i,v in ipairs(self.am_conditions) do
        s = s .. v.name .. " " .. v.relation.text .. " " .. v.value.text .. " and "
    end
    
    s = s:sub(1, s:len() - 4) .. "then ..."

    self.am_modstring:SetText(s)
end










function amModifier_OnClick(self, button, down)
    local v2 = AMFrameTab1FrameView2
    local v3 = AMFrameTab1FrameView3
    
    am.conditions:clear()
    am.conditions:addall(self.am_conditions)
    
    v3.am_inputsf.EditBox:SetText(self.am_text or "")        -- it must be called editbox for InputScrollFrame_OnLoad
    v3.am_name:SetText(v2.am_name:GetText() .. " - Modifier " .. self:am_getindex())
    
    am.selected_modifier = self
    
    v2:Hide()
    v3:Show()
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
