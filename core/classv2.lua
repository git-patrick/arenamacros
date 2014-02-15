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
	
	t.static		= { }

	t.datagroups	= table_merge(nil, nil, nil, apply(function (v) return rawget(v,"datagroups") end, ...))
	
	t.inits			= table_merge(nil, nil, nil, apply(function (v) return rawget(v,"inits") end, ...))
	t.releases		= table_merge(nil, nil, nil, apply(function (v) return rawget(v,"releases") end, ...))
	t.methods		= table_merge(nil, nil, nil, apply(function (v) return rawget(v,"methods") end, ...))
	
	t.name			= name

	return setmetatable(t, class.mt)
end

class.base = { }

function class.base:new(...)

end
function class.base:init()

end
function class.base:release()

end

class.mt = {
	__index = function (t, k)
		return	class.base[k] or
				t.static[k]
	end,
	
	__newindex = function (t, k, v)
		
	end
}

































-- this is an INSTANCE of a class created by class:new()
class.instance = { }

function class.instance:new(param)
	local t = { }
	
	-- object is the actual instance object.  this is what the existing table becomes if you pass one
	-- stores member variables and the results of property sets etc.
	t.object = { }
	
	-- this is the instance object's information table.  it stores the reference the creating class
	-- has the property hook information etc.
	t.info = { }
	
	return t
end

class.instance.mt = {
	__index = function (t, k)
		return	class.instance.base[k] or
		
				t:info().class.methods[k] or
				t:info().data[k] or
				
				t:object()[k]
	end,
	__newindex = function (t, k, v)
		t:object()[k] = v
	end
}

class.instance.base = { }

-- this returns our reference to the information table for our instance.
-- avoids the __index which would return nil for standard indexing.
function class.instance.base:info()
	return rawget(self, "info")
end

function class.instance.base:object()
	return rawget(self, "object")
end







-- this is the datagroup object for class instances!
-- it automatically calls the appropriate get and set functions for our defined property objects
-- and passes the correct instance object as well.

class.instance_datagroup = { }

function class.instance_datagroup:new(params)
	local t = { }
	local datagroup, instance = unpack(params)
	
	t.datagroup = datagroup
	t.instance = instance
	
	t.properties = datagroup:generate()
	
	return setmetatable(t, class.instance_datagroup.mt)
end

class.instance_datagroup.mt = {
	__index = function (t, k)
		return	a.instance_datagroup.base[k] or
				t.properties[k] and t.properties[k]:get(t.instance)
	end,
	__newindex = function (t, k, v)
		if (t.properties[k]) then
			t.properties[k]:set(t.instance, v)
		end
	end
}

class.instance_datagroup.base = { }

-- this returns the actual property instance object
function class.instance_datagroup.base:property(prop)
	return rawget(self, "properties")[prop]
end











class.property = { }

function class.property:new(params)
	local t = setmetatable({ }, property.mt)
	
	t.instance_mt = { __index = {
		get, _set, init = unpack(params)
	} }
	
	return t
end

function class.property:_makemt(get, _set, init)
	return { __index = {
		get = get,
		
class.property.base = { }

function class.property.base:new(params, existing_table)
	local t = setmetatable(existing_table or { }, self.instance_mt)
	
	t.prehooks = { }
	t.psthooks = { }
	
	return t
end



class.property.mt = {
	__index = class.property.base
}

local a = class:new()

a:info()			-- grabs the instance's info table
a:object()			-- grabs the object table

a:awefawef()		-- going to be inside the class _methods table.
					-- self passed to these methods MUST BE the object table.
					-- actually maybe not, I think I will actually leave it as the instance object
					-- and use a __newindex that redirects everything to object.

a.fewa				-- THIS MUST REFERENCE THE CLASSES DATAGROUP fewa if it exists


a.fewa.name			= "POOP" -- I want this to call the property.set of fewa's name property with


a.fewa.name					 -- this calls property.get of fewa's name property

a.fewa:property("name").prehooks:add(func)
a.fewa:property("name").prehooks:rm(func)

a.awef				-- gets a.object["awef"] if there is no datagroup called awef
a.awef = "fawefw"	-- i want this to just set a.object["awef"] = ...  IF the class does not have a datagroup called awef




