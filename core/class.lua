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

	-- data is a map with keys equal to the name of the data categories, and value an array of property objects
	t._data		= table_merge(nil, nil, nil, apply(function (v) return v._data end, ...))
	
	-- this is an array of init/release functions for our class and any superclasses.
	-- these are all called in class.base:init() and class.base:release() respectively but the order of calling is NOT DEFINED!
	-- I might change that later, but we shall see if it is necessary.
	t._inits	= table_merge(nil, nil, nil, apply(function (v) return v._inits end, ...))
	t._releases = table_merge(nil, nil, nil, apply(function (v) return v._releases end, ...))
	
	-- merge in our inherited methods
	t._methods	= table_merge(nil, nil, nil, apply(function (v) return v._methods end, ...))
	
	t.name = name

	-- this metatable does the following
	-- all functions added to the returned class are treated as instance functions and put in the __index of _methods
	-- instance data should be initialized in a function called :init added to the returned class object
    -- init is automatically called in the class method :new for this class and all subclasses
	setmetatable(t, class.class_metatable)
	
	-- every class instance has a method called "free" which will its class' static release method to cycle through all class release methods
	-- add that method here...
	function t:free()
		t:release(self)
	end
	
	function t:get_instance()
		return rawget(self, "_instance")
	end
	
	return t
end

-- provides the :new method which creates an instance of the class object and calls :init, which goes through all inherited
-- :init and calls them with appropriate parameters from :new
class.base = { }

function class.base:new(initparam, existing_table, baseclass_initparam)
	local t = existing_table or { }
	
	t._instance	= { }
	
	t._instance.class = self
	t._instance.data = { }
	
	for dgname, dg in pairs(self._data) do
		t._instance.data[dgname] = { }
		
		for pname, prop in dg.next, dg do
			t._instance.data[dgname][dg.name] = prop:new({ t })
		end
	end
	
	setmetatable(t, class.instance_metatable)

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

-- This method is useful for adding STATIC members to the class.
-- Why is it useful?  Because, by default, all functions added to the class are treated as methods for class instance objects,
-- and all non function indexes are treated as indexes in the _data member!
-- this is because of the __newindex, and __index metamethods below.  so to actually add a static function to our class, you use this.

-- note: I am not checking to make sure you don't screw up any important class members like name, _methods, _inits, etc.
-- so it is up to you not to break them.
function class.base:add_static(name, value)
	rawset(self, name, value)
end






class.instance_metatable = {
	__index = function (t, k)
		local instance = rawget(t, "_instance")
		
		if (k == "_instance") then
			return nil
		end
		
		if (instance._methods[k]) then
			return instance._methods[k]
		end
		
		return rawget(t, k)
	end,
	__newindex = function (t, k, v)
		if (k == "_instance") then
			return
		end
		
		rawset(t, k, v)
	end
}







class.class_metatable = {
	__index = function (t,k)
		print("class_metatable, __index ", t.name, " ", k)
		
		local a =	rawget(t,k) or
					class.base[k] or
					t._data[k]
					
		if (a) then
			return a
		end
		
		-- ANY OTHER INDEX IS TREATED AS A NEW DATA GROUP.
		t._data[k] = class.datagroup:new({ k })
		
		return t._data[k]
	end,
	__newindex = function (t,k,v)
		print("class_metatable, __newindex, ",  t.name, " ", k, " ", type(v))
		
		-- all functions are treated as methods of this class' instances
		if (type(v) == "function") then
			if (k == "init") then
				t._inits[t.name] = v
			elseif (k == "release") then
				t._releases[t.name] = v
			elseif (k == "call") then
				t._methods.__call = v
			else
				t._methods.__index[k] = v
			end
		else
			t:add_static(k, v)
		end
	end
}



class.datagroup = { }

-- this new is designed to mimic the standard class.base:new parameter situtation, just so this isn't different
-- even though it is not actually using the class.create class setup.
function class.datagroup:new(params)
	local t = { }
	
	t._name = select(1, params)
	t._prop = { }
	
	return setmetatable(t, class.datagroup_metatable)
end

class.datagroup_metatable = {
	__index = function (t,k)
		print("datagroup_metatable.__index ", k)
		
		-- first check our static class members.
		local a = rawget(t,k)
		
		if (a) then
			return a
		end
		
		-- now check our class functions
		if (class.datagroup.base[k]) then
			return class.datagroup.base[k]
		end
		
		-- finally, assume the index is a property, and return whatever we have.
		return t._prop[k]
	end,
	__newindex = function (t, k, v)
		-- all new indexes are treated as properties, and they MUST be property objects for everything to work properly.
		print("datagroup_metatable.__newindex ", k, " ", type(v))
		
		t._prop[k] = v
	end
}

class.datagroup.base = { }

function class.datagroup.base:set(to)
	for i, v in ppairs(self) do
		v:set(to[self._name][i]:get())
	end
end

-- iterator for use in foreach
-- used by ppairs
function class.datagroup.base:next(index)
	return next(self._prop, index)
end






