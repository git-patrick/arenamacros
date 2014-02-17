--[[
	My Lua Class implementation.
	
	DESCRIPTION:
		TODO
		
		
		
	GOD SAKES, this implementation isnt going to work.
	
	I need the passed existng_table to be the core table that every works off of............
	this is because WoW must keep track of the tables that it has created and what not, and I can't just mess around
	with it.........
	
	that means my class instance implementation has to change.
	
	I have to make the "object" just BE the instance table, and I have to find a way to make the info table
	accessible otherwise.
	
	this will also fix a few other for each / table.insert and table.remove related concerns that I had otherwise...
	
	still a pretty enormous pain in the rear end.
]]--

local addon_name, e = ...

class = { }

function class.create(name, ...)
	for i, v in pairs { ... } do
		if (v.name == name) then
			print("class.lua: Error! Class \"", name, "\" cannot share its name with a superclass.")
			
			return nil
		end
	end

	local t = { }
	
	t.datagroups	= table_merge(
		nil,	-- make me a new table, don't use an existing.
		function (t, dgname, newmemberarray)
			-- conflict resolution.  merges the new table into the one we already have
			table_merge(t[dgname], nil, nil, newmemberarray)
		end,
		function (t)
			-- our copy function.  could generalize this into a table copy with recursion limits etc,
			-- but not sure I need it
			
			local r = { }
			
			for k,v in pairs(t) do
				r[k] = v
			end
			
			return r
		end,
		apply(function (v) return v.datagroups end, ...)
	)
	
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

function class.base:new(initparam, existing_table, baseclass_initparam, existing_table_asinstance)
	-- OKAY, so the existing table that you pass defaults to being used as the instance's OBJECT table
	-- that way if you have properties set in it, those properties are used appropriately.
	-- however, there is one situation where you want the existing table to actually be the INSTANCE table itself
	-- this is for the single table that WoW passes to all of our files, and that the ADDON class attaches itself to
	-- that is the purpose of the existing_table_asinstance parameter, which tells us to use the table as the instance
	-- table, and not as the object table.
	-- this is a bit ugly, and I don't really like it, but there is no real alternative without changing the entire
	-- way I do classes, which isn't happening because I like my class implementation
	
	local t = class.instance:new(self, existing_table, existing_table_asinstance)

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
				rawset(t,k,v)
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

function class.instance:new(cls, existing_table)
	local t	= existing_table or { }
	local i = { }
	
	setmetatable(t, self:create_metatable(i))
	
	t:init(cls)
	
	return t
end

function class.instance:create_metatable(info_table)
	return {
		info = info_table,
		
		__index = function (t, k)
			if (k == "info") then
				return getmetatable(t).info
			end
			
			return	class.instance.base[k] or	-- do we have a class instance method
					t.info.class.methods[k] or	-- does our class have a method
					t.info.datagroups[k]			-- do we have a datagroup
		end,
		__call = function (t, ...)
			t.info.class.call(t, ...)
		end
	}
end

class.instance.base = { }

function class.instance.base:init(cls)
	-- HERE is where I need to setup instance specific information generated from the class.
	-- datagroup instances etc all need to be setup here.
	
	-- use class.instance.datagroup below, which is purty.

	self.info.class = cls
	self.info.datagroups = { }
	
	for name, dg in pairs(cls.datagroups) do
		self.info.datagroups[name] = class.instance.datagroup:new(name, dg, self)
	end
end








-- this is the datagroup object for class instances!
-- it automatically calls the appropriate get and set functions for our defined property objects
-- and passes the correct instance object as well.

class.instance.datagroup = { }

function class.instance.datagroup:new(datagroup_name, datagroup, instance)
	local t = { }
	
	t.datagroup_name = datagroup_name

	t.datagroup = datagroup
	t.instance = instance
	
	t.properties = { }
	
	for name, prop in pairs(datagroup) do
		t.properties[name] = prop:new()
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

function class.instance.datagroup.base:set(from_instance)
	for name, prop in pairs(self.properties) do
		if (not prop:set(self.instance, from_instance[self.datagroup_name][name])) then
			return false
		end
	end
	
	return true
end



-- im concerned that table.remove is not going to work for class instances
-- i am not certain how it will behave with my custom metatables. need to check.

class.property = { }

class.property.hooks = class.create("property_hooklist")

function class.property.hooks:add(what)
    table.insert(self, what)
end

function class.property.hooks:rm(what)
    for i,v in ipairs(self) do
        if v == what then
            table.remove(self, i)
        end
    end
end

function class.property.hooks:clear()
	for i = #self, 1 do
		table.remove(self, i)
	end
end


class.property.base = class.create("property_base")

function class.property.base:init()
	self.prehook = class.property.hooks:new()
	self.psthook = class.property.hooks:new()
end

function class.property.base:set(instance, to_value)
	local my_value = self.get(instance)
	
	-- if the value did not change, we skip all hook calls, and the set call!!!!
	if (my_value == to_value) then
		return true
	end
	
	for j,f in pairs(self.prehook) do
		if (not f(instance, my_value, to_value)) then
			return false
		end
	end

	if (self._set(instance, to_value)) then
		return false
	end
	
	-- post hooks can no longer cause failure of set.
	-- all post hooks will be run no matter what previous posts have determined.
	for j,f in pairs(self.psthook) do
		f(instance, my_value, to_value)
	end
	
	return true
end









function class.property.custom(get, _set, _init)
	local p = class.create("property", class.property.base)
	
	p.get = get
	p._set = _set
	p._init = _init
	
	return p
end

function class.property.scalar(name)
    return class.property.custom(
		function (t) return t[name] end,            -- get
		function (t, value) t[name] = value end     -- _set
	)
end

function class.property.array(datagroup, cls)
    return class.property.custom(
		function (t) return t[name] end,			-- get
		function (t, value)							-- _set
			t[name] = { }
		
			for i, v in pairs(value) do
				table.insert(t[name], cls:new()[datagroup]:set(v))
			end
		end,
		function (t)								-- init
			-- since classes can be created on existing objects (for example, the WoW stored variables table), we check if our property is set
			-- if it is, we basically tell all of the objects in the array that they are dc objects (since they were likely just tables before
			-- this amounts to setting their metatable up to have access to dataclass members)

			if (t[name]) then
				for i,v in pairs(t[name]) do
					cls:new(nil, v)
				end
			else
				t[name] = { }
			end
		end
    )
end










--[[

local some_class = class.create("some_class")

function some_class:init(huh)
	print("some_class:init")
end
function some_class:awefawef()
	print("some_class:awefawef")
end

some_class.fewa.name = class.property.custom(
	"some_class.fewa.name",
	function(instance)
		print("name:get");
		return instance.name
	end,
	function (instance, value)
		print("name:_set ", value);
		instance.name = value
	end
)


local other_class = class.create("other_class")

function other_class:init()
	print("other_class:init()")
end

other_class.fewa.text = class.property.custom(
	"other_class.fewa.text",
	function (instance)
		print("GET TEXT")
		return instance.text
	end,
	function (instance, value)
		print("SET TEXT")
		instance.text = value
	end
)


local another_class = class.create("another_class", some_class, other_class)


]]--