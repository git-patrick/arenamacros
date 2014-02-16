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
	end,
	nil
})

local b = { name = "TESTING" }
local a = some_class:new({ "HEHEHEHEHE" }, b)

print(a.fewa.name)		-- should print("TESTING")

a.fewa.name	= "POOP"	-- I want this to call the property.set of fewa's name property with "POOP" as value

print(a.fewa.name)		-- this calls property.get of fewa's name property

table.insert(a.fewa:property("name").prehook, function (t, from, to) print("PROPERTY NAME PREHOOK!!!") end)

a.fewa.name = "BLERP"

