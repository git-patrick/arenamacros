am_condition = { mt = { __index = setmetatable({ }, { __index = pat.multiply_inherit_index(dataclass_condition, am_contained.mt.__index) }) } }

function am_condition.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "amConditionTemplate"), am_condition.mt)
    
    return f
end

function am_condition.mt.__index:am_setproperty(name, value)
    if (name == "name") then
        self.amName:SetText(value)
    elseif (name == "relation") then
        self.am_relation = value
        self.amRelation:SetText(value.text)
    elseif (name == "value") then
        self.am_value = value
        self.amValue:SetText(value.text)
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
    
    self.amIntroString:SetText(intro)
    self.amOutroString:SetText(outro)
end







-- XML EVENT CALLBACKS, THESE REFERENCE THE GLOBAL am ELEMENT

function amCondition_Delete(self, button, down)
    am.conditions:remove(self:GetParent():am_getindex())
end