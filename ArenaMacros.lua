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

some_class.fewa.name = class.property.create(
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

other_class.fewa.text = class.property.create(
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

-- STILL NEED TO MAKE PRE AND PST HOOK ARRAYS MORE USER FRIENDLY