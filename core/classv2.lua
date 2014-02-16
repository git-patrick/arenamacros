--[[ 
	What I would absolutely love is if I could create a class... then create a class from that class . . . . . . 
	
	situations where I think this might apply ...
	
	describe a property with get / set / init ... then create instances of this thing ..,.
	
	basically, what I want to do is create a class with some :new(PROPERTIES) set some properties, THEN i want to be able to 
	use this instance of the previous class to create instances of this new instance object where the properties that have been
	set are now accessable by the instance of instance objects, but they are treated more as class objects...
	
	how can I make that happen ?
	
	I have this new concept of a class.instance object
	
	how about this ...
	
]]--



class = { }

-- lets redo the class.create ....

function class.create(name, ...)
	for i, v in pairs { ... } do
		if (v.name == name) then
			print("class.lua: Error! Class \"", name, "\" cannot share its name with a superclass.")
			
			return nil
		end
	end

	local t = { }
	
	t.datagroups	= table_merge(nil, nil, nil, apply(function (v) return v.datagroups end, ...))
	
	t.inits			= table_merge(nil, nil, nil, apply(function (v) return v.inits end, ...))
	t.releases		= table_merge(nil, nil, nil, apply(function (v) return v.releases end, ...))
	t.methods		= table_merge(nil, nil, nil, apply(function (v) return v.methods end, ...))
	
	-- this is only here as a reminder not to use this as a static variable name.
	-- this is used by the class instance as the CALL method of the instance table
	t.call			= nil
	
	t.name			= name

	return setmetatable(t, class.mt)
end

class.base = { }

function class.base:new(initparam, existing_table, baseclass_initparam)
	local t = class.instance:new(self, existing_table)

	self:init(t, initparam, baseclass_initparam)

	return t
end
function class.base:init(t, initparam, baseclass_initparam)
	for name,v in pairs(self.inits) do
		if (name == self.name) then
			p = initparam
		else
			p = baseclass_initparam and baseclass_initparam[name] or nil
		end
		
		v(t, unpack(p or { }))
	end
end
function class.base:release(instance)
	for name,v in pairs(self.releases) do
		v(instance)
	end
end

function class.base:add_static(key, value)
	rawset(self, key, value)
end

class.mt = {
	__index = function (t,k)
		local a =	class.base[k] or
					t.datagroups[k]
					
		if (a) then
			return a
		end
		
		-- ANY OTHER INDEX IS TREATED AS A NEW DATA GROUP.
		t.datagroups[k] = { }
		
		return t.datagroups[k]
	end,
	__newindex = function (t,k,v)
		-- all functions are treated as methods of this class' instances
		if (type(v) == "function") then
			if (k == "init") then
				t.inits[t.name] = v
			elseif (k == "release") then
				t.releases[t.name] = v
			elseif (k == "call") then
				t.call = v
			else
				t.methods[k] = v
			end
		else
			t:add_static(k, v)
		end
	end
}





-- this is an INSTANCE of a class created by class:new()
class.instance = { }

-- params are passed like this
function class.instance:new(cls, existing_table)
	local t = { }
	
	-- object is the actual instance object.  this is what the existing table becomes if you pass one
	-- stores member variables and the results of property sets etc.
	t.object = existing_table or { }
	
	-- this is the instance object's information table.  it stores the reference the creating class
	-- has the property hook information etc.
	t.info = { }
	
	setmetatable(t, class.instance.mt)
	
	t:init(cls)
	
	return t
end

class.instance.mt = {
	__index = function (t, k)
		return	class.instance.base[k] or		-- do we have a class instance method
				
				t.info.class.methods[k] or	-- does our class have a method
				t.info.datagroups[k] or		-- do we have a datagroup
				
				t.object[k]					-- check the object for member variables
												-- this will also return member variables from
												-- the instance this instance was created from, if there is one
												-- how that works is just a metatable set on .object to search the
												-- creating instances .object
	end,
	__newindex = function (t, k, v)
		t.object[k] = v						-- all newindexes are ALWAYS put directly into our object as member variables.
	end,
	__call = function (t, ...)
		t.info.class.call(t, ...)
	end
}

class.instance.base = { }

-- this is used to create a new instance object from our existing instance object! 
-- the existing objects member variables are readable from the new, but cannot be changed from it.
-- all newindexes are just overrides for the parents if you assign to them

function class.instance.base:new()
	local t = { }
	
	t.object = setmetatable({ }, { __index = self.object })
	t.info = { }
	
	setmetatable(t, class.instance.mt)
	
	t:init(self.info.class)
	
	return t
end

function class.instance.base:init(cls)
	-- HERE is where I need to setup instance specific information generated from the class.
	-- datagroup instances etc all need to be setup here.
	
	-- use class.instance.datagroup below, which is purty.

	self.info.class = cls
	self.info.datagroups = { }
	
	for name, dg in pairs(cls.datagroups) do
		self.info.datagroups[name] = class.instance.datagroup:new(dg, self)
	end
end









-- this is the datagroup object for class instances!
-- it automatically calls the appropriate get and set functions for our defined property objects
-- and passes the correct instance object as well.

class.instance.datagroup = { }

function class.instance.datagroup:new(datagroup, instance)
	local t = { }
	
	t.datagroup = datagroup
	t.instance = instance
	
	t.properties = { }
	
	for name, prop in pairs(datagroup) do
		t.properties[name] = prop:new()
		
		-- really dont like this.
		-- property:new() is going to have to return a class.
		-- need a more general concept like a class factory to combine standard class.create and other more custom factories.
		t.properties[name].prehook = { }
		t.properties[name].psthook = { }
	end
	
	return setmetatable(t, class.instance.datagroup.mt)
end

class.instance.datagroup.mt = {
	__index = function (t, k)
		return	class.instance.datagroup.base[k] or
				t.properties[k] and t.properties[k].get(t.instance)
	end,
	__newindex = function (t, k, v)
		if (t.properties[k]) then
			t.properties[k]:set(t.instance, v)
		end
	end
}

class.instance.datagroup.base = { }

function class.instance.datagroup.base:property(prop)
	return self.properties[prop]
end














-- I think I might be able to make property a class object ... despite it being necessary for classes to function
-- as long as I don't use any datagroups in it...
class.property = class.create("property")

function class.property:init(get, _set, init)
	self.get = get
	self._set = _set
	self.init = init
	
	self.prehook = { }
	self.psthook = { }
end

function class.property:set(instance, to_value)
	local my_value = self.get(instance)
    
    -- if the value did not change, we skip all hook calls, and the set call!!!!
    if (my_value == to_value) then
        return true
    end
    
    for j,f in ipairs(self.prehook) do
        if (not f(instance, my_value, to_value)) then
            return false
        end
    end

    if (self._set(instance, to_value)) then
        return false
    end
	
    -- post hooks can no longer cause failure of set.
	-- all post hooks will be run no matter what previous posts have determined.
    for j,f in ipairs(self.psthook) do
        f(instance, my_value, to_value)
    end
    
    return true
end

function class.property:clear_pre()
    self.prehook = { }
end

function class.property:clear_pst()
    self.psthook = { }
end