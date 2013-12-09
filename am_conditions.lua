-- this is both the object used to initialize the conditions menu ! (by avoiding namespace conflict issues)
-- and it contains the menu creation info for each relation and value menu as well
AM_CONDITIONS_GLOBAL = { }
AM_CONDITIONS_MENU = { }

function am_conditions_selectvalue(self, arg1, arg2, checked)
    am.selected_condition.am_value:SetText(self.value)
end

function am_conditions_selectrelation(self, arg1, arg2, checked)
    am.selected_condition.am_relation:SetText(self.value)
end

function am_conditions_selectname(self, arg1, arg2, checked)
    am.selected_condition.am_name:SetText(self.value)
    am.selected_condition.am_relation:SetText(AM_CONDITIONS_GLOBAL[self.value].default_relation)
    am.selected_condition.am_value:SetText(AM_CONDITIONS_GLOBAL[self.value].default_value)
end

function am_conditions_initialize(frame_name, populatefunction)
    CreateFrame("Frame", "AMConditionMenuFrame", UIParent, "UIDropDownMenuTemplate")
end

-- builtin condition test for fallback modifiers, also allows disabling modifiers with if true is false then ... conditions
AM_CONDITIONS_GLOBAL["true"] = {
    test = function (relation, value)
        return value == "true"
    end,
    
    default_relation = "is",
    default_value = "true",
    
    relations = {
        { text = "is", value = "is", func = am_conditions_selectrelation, notCheckable = true }
    },
    values = {
        { text = "true", value = "true", func = am_conditions_selectvalue, notCheckable = true  },
        { text = "false", value = "false", func = am_conditions_selectvalue, notCheckable = true }
    }
}

table.insert(AM_CONDITIONS_MENU, { text = "Conditions", isTitle = "true", notCheckable = true } )
table.insert(AM_CONDITIONS_MENU, { text = "true", func = am_conditions_selectname, notCheckable = true })