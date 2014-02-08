local addon_name, e = ...

local libutil = e:addlib(lib:new({ "utility", "1.0" }))

-- all these prints because the WoW UI has trouble displaying prints of very large strings
-- so just creating a string to print doesn't really work for large dumps
function libutil.dump(o, max_recursion, current_recursion)
	current_recursion = current_recursion or 0
	local indent = string.rep(" ", current_recursion)
	
    if (type(o) == "table" and (max_recursion and current_recursion <= max_recursion)) then
		print(indent, "{")
		
        for k,v in pairs(o) do
			print(indent, " [", k, "] = ")
			
			libutil.dump(v, max_recursion, current_recursion + 1)
        end
        
        print(indent, "}")
    else
        print(indent, " ", tostring(o))
    end
end

-- copy references to my globals.lua global functions into this library.
-- this is how I want all downstream stuff from lib util (which is all other libs and the addon itself)
-- to access these functions.
-- the globals are only global for the references here, and since they are required for some core setup stuff.
libutil.table_merge = table_merge
libutil.array_append = array_append
libutil.apply = apply




-- this just adds a couple simple things to lua arrays that I use on occasion
-- erray stands for enhanced array
local erray = libutil:addclass(class.create("erray"))

function erray:add(what)
    table.insert(self, what)
end

function erray:rm(what)
    for i,v in ipairs(self) do
        if v == what then
            table.remove(self, i)
        end
    end
end







-- IM GOING TO MOVE THESE OUT OF HERE, I don't like wow related stuff in this general lua related lib
function libutil.create_or_rename_macro(old_name, new_name)
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

function libutil.delete_macro(name)
    if (GetMacroIndexByName(name) > 0) then
        DeleteMacro(name)
    end
end

