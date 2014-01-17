am_condition = {
    mt = { __index = setmetatable({ }, am_contained.mt) }
}

function am_condition.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMMacroModifierConditionTemplate"), am_condition.mt)
    
    return f
end

function am_condition.mt.__index:am_set(object)
    -- I need to make sure all conditions exist, and all relations and values are valid.
    
    if (object.name) then self.am_name:SetText(object.name) end
    
    if (object.relation) then
        self.am_relation.am_data = object.relation.data
        self.am_relation:SetText(object.relation.text)
    end
    
    if (object.value) then
        self.am_value.am_data = object.value.data
        self.am_value:SetText(object.value.text)
    end
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







-- XML EVENT CALLBACKS, THESE REFERENCE THE GLOBAL am ELEMENT

function amCondition_Delete(self, button, down)
    am.conditions:remove(self:GetParent():am_getindex())
end