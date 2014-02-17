-- The purpose of these classes is to wrap up a couple WoW objects I want to inherit from using my standard class inheritance method.

local addon_name, e = ...

local libutil	= e:lib("utility")

local libwow	= e:addlib(lib:new({ "wow", "1.0" }))
local frame		= libwow:addclass(class.create("frame"))

-- copy over all of UIParent's (which is just a Frame object) methods into our class
-- this has to be a copy, and I can't just set my _methods.__index to getmetatable because
-- you can't edit wow's frame metatable, and adding methods to frame class would attempt to do just that

-- merging directly into methods, because table_merge checks if the index exists
-- which creates a datagroup if it doesnt.  That is not what we want.
libutil.table_merge(frame.methods, nil, nil, getmetatable(UIParent).__index)

local button	= libwow:addclass(class.create("button"))

-- make a button to get its metatable below.
-- can't get rid of this thing unfortunately.  if I can find a button guaranteed to always exist
-- similar to UIParent, I should probaby just sue thaet
local wowbutton	= CreateFrame("Button", UIParent, nil)

libutil.table_merge(button.methods, nil, nil, getmetatable(wowbutton).__index)


function libwow.create_or_rename_macro(old_name, new_name)
    if (not old_name or GetMacroIndexByName(old_name) == 0) then
        -- macro doesn't already exist, try to create it.
        
        if (not pcall(function() CreateMacro(new_name, "INV_Misc_QuestionMark", "", 1) end)) then
            -- macro creation failed!  I believe this can only happen if the macro list is full
            
            return false
        end
    else
        EditMacro(old_name, new_name, nil, nil, 1, 1)
    end
    
    return true
end

function libwow.delete_macro(name)
    if (GetMacroIndexByName(name) > 0) then
        DeleteMacro(name)
    end
end