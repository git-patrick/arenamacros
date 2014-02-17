local addon_name, am = ...

local function initialize()

end

-- addon:new({ initialize }, am)


local some_class = class.create("some_class")

function some_class:init(huh)
	print("some_class:init")
end
function some_class:awefawef()
	print("some_class:awefawef")
end

some_class.fewa.name = class.property:new({
	function(instance)
		print("name:get");
		return instance.name
	end,
	function (instance, value)
		print("name:_set ", value);
		instance.name = value
	end
})


local other_class = class.create("other_class", some_class)

function other_class:init()
	print("other_class:init()")
end

other_class.fewa.text = class.property:new({
	function (instance)
		print("GET TEXT")
		return instance.text
	end,
	function (instance, value)
		print("SET TEXT")
		instance.text = value
	end
})

-- AT THIS POINT other_class.fewa.name should not be accessible, since the new fewa overrides it

local b = { name = "TESTING" }
local a = some_class:new({ "HEHEHEHEHE" }, b)

local c = other_class:new()

c.fewa.name = "TEST"
c.fewa.text = "DOUblE TEST"

print(a.fewa.name)		-- should print("TESTING")

a.fewa.name	= "POOP"	-- I want this to call the property.set of fewa's name property with "POOP" as value

print(a.fewa.name)		-- this calls property.get of fewa's name property

table.insert(a.fewa:property("name").prehook, function (t, from, to) print("PROPERTY NAME PREHOOK!!!"); return true end)

a.fewa.name = "BLERP"


local c = some_class:new()

c.fewa:set(a)

print(c.fewa.name)
