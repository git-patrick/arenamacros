am_location = am_addon.create("Location", { "GROUP_ROSTER_UPDATE", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" })

function am_location._select(self, arg1, arg2, checked)
    am_location.button.am_data[self.value] = checked or nil
    
    am_location._setmenuchecks(am_location.menu, am_location.button.am_data)
end

function am_location._setmenuchecks(menu, data)
    for i, v in ipairs(menu) do
        if (v.value and data[v.value]) then
            v.checked = "true"
        else
            v.checked = nil
        end
        
        if (v.menuList) then
            am_location._setmenuchecks(v.menuList, data)
        end
    end
end

function am_location._settext(button)
    if (type(button.am_data) == "table") then
        button:SetText("...")
    else
        button:SetText(button.am_data)
    end
end





-- value_init and relation_init may to exist, and if they do, are called when the condition is selected
function am_location.relation_init(button)
    button.am_data = "is"
    
    am_location._settext(button)
end

function am_location.value_init(button)
    button.am_data = { ["none"] = true }
    
    am_location._settext(button)
end


-- value_onclick and relation_onclick are required to exist, and are called when the value and relation buttons are pressed with your addon selected
function am_location.value_onclick(button)
    am_location._setmenuchecks(am_location.menu, button.am_data)
    am_location.button = button

    AMConditionMenuFrame:SetPoint("CENTER", button, "CENTER")
                        
    EasyMenu(am_location.menu, AMConditionMenuFrame, AMConditionMenuFrame, 0, 0, "MENU", 1)
end
function am_location.relation_onclick(button)
    if (button.am_data == "is") then
        button.am_data = "is not"
    else
        button.am_data = "is"
    end
    
    am_location._settext(button)
end

-- .test() is required for all addons, it is used to test the state of the condition.  should return true / false!  .init() is called if it exists once the parent addon is setup
function am_location.test(relation, value)
    local ret = false
    
    if (value.data[am_location.get_value()]) then
        ret = true
    end
    
    if (relation.data ~= "is") then
        ret = not ret
    end

    return ret
end

function am_location.get_value()
    local inst, type = IsInInstance()
    
    if (type ~= "arena") then
        return type
    end
    
    local num = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
    
    return type .. " - " .. num .. "v" .. num
end

function am_location:init()
    self:set_storedvalue(self.get_value())
end

am_location.main_menu = { text = "Location", value = "Location", func = am.addons.select, leftPadding="10", notCheckable = true }

am_location.menu = {
    {   text = "Locations",
        isTitle = "true",
        notCheckable = true
    },
    {
        text = "Arena",
        hasArrow = true,
        notCheckable = true,

        menuList = {
            { text = "2v2", value = "arena - 2v2", func = am_location._select, leftPadding="5", keepShownOnClick="1" },
            { text = "3v3", value = "arena - 3v3", func = am_location._select, leftPadding="5", keepShownOnClick="1" },
            { text = "5v5", value = "arena - 5v5", func = am_location._select, leftPadding="5", keepShownOnClick="1" }
        }
    },
    { text = "World", value = "none", func = am_location._select, leftPadding="5", keepShownOnClick="1" },
    { text = "Battleground", value = "battleground", func = am_location._select, leftPadding="5", keepShownOnClick="1" },
    { text = "Instance", value = "party", func = am_location._select, leftPadding="5", keepShownOnClick="1" },
    { text = "Raid Instance", value = "raid", func = am_location._select, leftPadding="5", keepShownOnClick="1" }
}

am.addons.add(am_location)