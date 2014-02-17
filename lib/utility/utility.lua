local addon_name, e = ...

local libutil = e:addlib(lib:new({ "utility", "1.0" }))

-- all these prints because the WoW UI has trouble displaying prints of very large strings
-- so just creating a string to print doesn't really work for large dumps
function libutil.dump(o, max_recursion, current_recursion)
	current_recursion = current_recursion or 0
	local indent = string.rep(" ", current_recursion)
	
    if (type(o) == "table" and (not max_recusion or current_recursion <= max_recursion)) then
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





local pool = libutil:addclass(class.create("pool"))


-- The point of this object is to allow you to reuse frames that you have previously created.
-- the reason for that is, there is no way to tell WoW to release frames you have created, so if you don't reuse the ones you have,
-- you just keep increasing memory consumption, or so the wiki says.
function pool:init(create_frame_function)
    self.create_frame = create_frame_function
    self.free = { }
end

function pool:release()
	self.create_frame = nil
	self.free = nil
end

-- grabs either a new frame, or one from the used pool
function pool:get()
    local f
    local pool_index = table.getn(self.free)
    
    if (pool_index > 0) then
        f = self.free[pool_index]
        
        table.remove(self.free, pool_index)
    else
        f = self.create_frame()
    end
    
    return f
end

-- gives a frame back to the pool
-- make sure you only give us the appropriate frames!  doesn't check to make sure it came from this pool, or even is the appropriate subclass etc.
function pool:give(frame)
    frame:am_release()
    
    table.insert(self.free, frame)
end









local bind	= libutil:addclass(class.create("bind"))

-- simple bind implementation 
-- used mostly for callbacks to class methods

function bind:init(func, ...)
	self.func	= func
	self.params	= { ... }
end

function bind:release()
	self.params = nil
	self.func = nil
end

function bind:call(...)
	return self.func(unpack(self.params), ...)
end