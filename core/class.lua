local addon_name, addon_table = ...

-- class object.  this has a static member (.create) to create a new class
class = { }

function class.create(name, ...)
	-- the vararg is a list of classes this inherits from.
	-- copy all those class methods into a new table and set its metatable to search class table.
	-- functions are all by reference, and this actually results in the fastest implementation I've come up with
	
	-- the reason we can't share a name with any superclass is because of class.base:init below.  you need to be
	-- able to distinguish the init functions merged into t._inits from each other for parameter passing in class.base:init
	for i, v in pairs { ... } do
		if (v.name == name) then
			print("class.lua: Error! Class \"", name, "\" cannot share its name with a superclass.")
			
			return nil
		end
	end

	local t = { }

	-- methods is the metatable that :new uses to create instances of the class.
	t._methods = { __index = { } }
	
	
	--
	t._properties = table_merge(nil, nil, nil, apply(function (v) return v._properties end, ...))
	
	-- this is an array of init/release functions for our class and any superclasses.
	-- these are all called in class.base:init() and class.base:release() respectively but the order of calling is NOT DEFINED!
	-- I might change that later, but we shall see if it is necessary.
	t._inits	= table_merge(nil, nil, nil, apply(function (v) return v._inits end, ...))
	t._releases = table_merge(nil, nil, nil, apply(function (v) return v._releases end, ...))
		
	t.name = name

	-- this metatable does the following
	-- all functions added to the returned class are treated as instance functions and put in the __index of _methods
	-- all data object added to the returned class are treated as static class memberes
	-- instance data should be initialized in a function called :init added to the returned class object
    -- init is automatically called in the class method :new for this class and all subclasses
	setmetatable(t, class.metatable)
	
	-- every class instance has a method called "free" which will its class' static release method to cycle through all class release methods
	-- add that method here...
	function t:free()
		t:release(self)
	end

	-- now that the metatable is set, all the functions added will go in methods..
	-- so merge all of our parent classes methods into ourselves, and they goto the appropriate place!
	return table_merge(t, nil, nil, apply(function (v) return v._methods.__index end, ...))
end

-- provides the :new method which creates an instance of the class object and calls :init, which goes through all inherited
-- :init and calls them with appropriate parameters from :new
class.base = { }

function class.base:new(initparam, existing_table, baseclass_initparam)
	local t = setmetatable(existing_table or { }, self._methods)

	self:init(t, initparam, baseclass_initparam)

	return t
end

function class.base:release(instance)
	for name,v in pairs(self._releases) do
		v(instance)
	end
end
function class.base:init(t, initparam, baseclass_initparam)
	for name,v in pairs(self._inits) do
		if (name == self.name) then
			p = initparam
		else
			p = baseclass_initparam and baseclass_initparam[name] or nil
		end
		
		v(t, unpack(p or { }))
	end
end

-- This method is useful for adding STATIC class functions to the class.
-- Why is it useful?  Because, by default, all functions added to the class are treated as methods for class instance objects
-- this is because of the __newindex metamethod below.  so to actually add a static function to our class, you use this.

-- note: I am not checking to make sure you don't screw up any important class members like name, _methods, _inits, etc.
-- so it is up to you not to break them.
function class.base:add_static(name, value)
	rawset(self, name, value)
end

class.metatable = {
	__index = class.base,
	__newindex = function (t,k,v)
		-- all functions are treated as methods of this class' instances
		if (type(v) == "function") then
			if (k == "init") then
				t._inits[t.name] = v
			elseif (k == "release") then
				t._releases[t.name] = v
				
			-- this is used to set the call metamethod of the class incase it is a functor or something.
			elseif (k == "call") then
				t._methods.__call = v
			else
				t._methods.__index[k] = v
			end
		else
			rawset(t, k, v)
		end
	end
}

--[[
--SAMPLE CODE

local class_A = class.create("class_A")

function class_A:init(...)
	print("class_A: ", ...)
	self.instance_var = 1
end

function class_A:class_a_function()
	self.instance_var = 5
end

local class_B = class.create("class_B")

function class_B:init(...)
	print("class_B: ", ...)
end

local class_C = class.create("class_C", class_A, class_B)

function class_C:init(...)
	print("class_C: ", ...)
end

local class_D = class.create("class_D")
	
function class_D:init(...)
	print("class_D: ", ...)
end
function class_D:class_d_function(what)
	print("CLASS_D ", what)
end

local class_E = class.create("class_E", class_C, class_D)

function class_E:init(...)
	print("class_E: ", ...)
end

local c = class_C:new()

c:class_a_function()

print(c.instance_var)
-- the { 1, 2, 3 } and {4, 5, 6} tables are unpacked and passed as parameters to the appropriate classes :init function
local t = class_E:new({ ["class_E"] = { 1, 2, 3 },
						["class_D"] = { 4, 5, 6 } })

print(t.instance_var)

t:class_d_function("DUDUUDUDUDUE")

]]--