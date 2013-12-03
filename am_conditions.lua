AM_CONDITIONS_GLOBAL = { }

-- builtin condition test for fallback modifiers, also allows disabling modifiers with if true is false then ... conditions
AM_CONDITIONS_GLOBAL["true"] = {
    test = function (relation, value)
        return value == "true"
    end,
    relations = {
        ["is"] = { },
    },
    values = {
        ["true"] = { },
        ["false"] = { }
    }
}

function am_makemenu(frame_name, populatefunction)
    local frame = CreateFrame("Frame", frame_name, UIParent, "UIDropDownMenuTemplate")
    
    UIDropDownMenu_Initialize(frame, populatefunction, "MENU")
    
    return frame
end

function am_conditions_populatemenu(self, data, func, width)
    local menu_item = { }
    
    for name, v in pairs(data) do
        menu_item.text          = name
        menu_item.value         = name
        menu_item.func          = nil
        menu_item.padding       = 10
        menu_item.minWidth      = width or 95
        menu_item.notCheckable  = "true"
        menu_item.func          = func
        
        UIDropDownMenu_AddButton(menu_item);
    end
end

function am_conditions_createmenus()
    am_makemenu("AMConditionNameMenu",
                function()
                    am_conditions_populatemenu(self, AM_CONDITIONS_GLOBAL,
                       function(self, arg1, arg2, checked)
                           am.selected_condition.am_name:SetText(self:GetText())
                       end
                    )
                end)

    for condition_name, cond in pairs(AM_CONDITIONS_GLOBAL) do
        am_makemenu("AMCondition-" .. condition_name .. "-ValueMenu",
                    function()
                        am_conditions_populatemenu(self, AM_CONDITIONS_GLOBAL[condition_name].values,
                            function(self, arg1, arg2, checked)
                                am.selected_condition.am_value:SetText(self.value)
                            end
                        )
                    end)
        am_makemenu("AMCondition-" .. condition_name .. "-RelationMenu",
                    function()
                        am_conditions_populatemenu(self, AM_CONDITIONS_GLOBAL[condition_name].relations,
                           function(self, arg1, arg2, checked)
                                am.selected_condition.am_relation:SetText(self.value)
                           end,
                           50
                        )
                    end)
    end
end