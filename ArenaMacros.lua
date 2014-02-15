local addon_name, am = ...

local function initialize()

end

-- addon:new({ initialize }, am)


local test = class.create("test")

function test:test()
	print("POO")
end

test.dgtest.name = "wtf is gonna happen"
test.dgtest.text = "OMG OGM OMG"

local newtest = test:new()

newtest:test()
