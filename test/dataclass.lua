
require("utility.lua")
require("dataclass.lua")

--[[
 --------------------------------------------
 DATA CLASS TEST CODE!!!!!!!!!!!!
 --------------------------------------------
]]--

local tblcond = {
    ["name"] = "Location",
    ["relation"] = "is",
    ["relation_data"] = { "awer", 234, "fewa" },
    ["value"] = "VALUE",
    ["value_data"] = { "gawfaweg", 3121, 1212 }
}

local tblmod = {
    ["text"] = "macro text goes hurrrr",
    ["modstring"] = "modstring herp derp",
    ["conditions"] = {
        tblcond,
    }
}
local tblmacro = {
    ["name"] = "test name!",
    ["icon"] = "INV_Misc_QuestionMark",
    ["modifiers"] = {
        tblmod,
    }
}

local simple_macro = dc.macro.simple:create(tblmacro)
local simple_macro2 = dc.macro.simple:create()

simple_macro2:am_set(simple_macro)

simple_macro:am_print()
simple_macro2:am_print()
