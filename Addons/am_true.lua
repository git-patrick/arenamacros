am_true = am_addon.create("true")

function am_true.test(relation, value)
    return value.data == "true"
end

function am_true.value_init(button)
    button.am_data = "true"
    button:SetText(button.am_data)
end
      
function am_true.relation_init(button)
    button.am_data = "is"
    button:SetText(button.am_data)
end

function am_true.value_onclick(button)
    if (button.am_data == "true") then
      button.am_data = "false"
    else
      button.am_data = "true"
    end
    
    button:SetText(button.am_data)
end

function am_true.relation_onclick(button) end

am_true.main_menu = { text = "true", notCheckable = "true", value = "true", leftPadding = "10", func = am.addons.select }

am.addons.add(am_true)