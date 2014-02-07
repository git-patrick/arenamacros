local addon_name, addon_table = ... -- "TEST", { { }, { }, { }, { }, { } }
local e, L, V, P, G = unpack(addon_table) -- Engine, Locales, PrivateDB, ProfileDB, GlobalDB

-- conflict is a function which takes three parameters, table, key, and new value
-- it is called when table[key] already has a value, but we have a new value for that key from another table.
-- conflict is expected to resolve the issue itself, and the merge continues
-- note: if nil is passed for conflict, the default behaviour is to maintain the current value and ignore the new

local function table_merge(object, conflict, copy, ...)
	local t = object or { }

	for i, v in ipairs({ ... }) do
		for j, k in pairs(v) do
			if not t[j] then
				t[j] = copy and copy(k) or k
			else
				if conflict then
					conflict(j, t[j], k)
				end
			end
		end
	end

	return t
end

local function array_append(...)
	local t = { }

	for i, v in ipairs({ ... }) do
		for j, k in ipairs(v) do
			table.insert(t, k)
		end
	end

	return t
end


local function apply(what, ...)
	local t = { ... }

	for i, v in ipairs(t) do
		t[i] = what(v)
	end

	return unpack(t)
end




-- class object.  this has a static member (.create) to create a new class
local class = { }

function class.create(name, ...)
	-- the vararg is a list of classes this inherits from.
	-- copy all those class methods into a new table and set its metatable to search class table.
	-- functions are all by reference, and this actually results in the fastest implementation I've come up with

	local t = { }

	-- methods is the metatable that :new uses to create instances of the class.

	t._methods = { __index = { } }

	-- this is an array of init functions for our class and any superclasses.
	-- these are all called in class.base:new(), but the order of calling is NOT DEFINED!
	-- I might change that later, but we shall see if it is necessary.
	t._inits = table_merge(nil, nil, nil, apply(function (v) return v._inits end, ...))

	t.name = name

	-- this metatable does the following
	-- all functions added to the returned class are treated as instance functions and put in the __index of _methods
	-- all data object added to the returned class are treated as static class memberes
	-- instance data should be initialized in a function called :init added to the returned class object
	setmetatable(t, class.metatable)

	-- now that the metatable is set, all the functions added will go in methods..
	-- so merge all of our parent classes methods into ourselves, and they goto the appropriate place!
	return table_merge(t, nil, nil, apply(function (v) return v._methods.__index end, ...))
end

-- provides the :new method which creates an instance of the class object and calls :init, which goes through all inherited 
-- :init and calls them with appropriate parameters from :new

class.base = { }

function class.base:new(param, existing_table)
	local t = setmetatable(existing_table or { }, self._methods)

	self:init(t, param)

	return t
end

function class.base:init(t, param)
	for name,v in pairs(self._inits) do
		v(t, unpack(param and param[name] or { }))
	end
end

class.metatable = {	
	__index = class.base,
	__newindex = function (t,k,v)
		-- all functions are treated as methods of this class' instances
		if (type(v) == "function") then
			if (k == "init") then
				t._inits[t.name] = v
			else
				t._methods.__index[k] = v
			end
		else
			t[k] = v
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