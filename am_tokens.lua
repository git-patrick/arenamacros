am_token = { mt = { __index = { } } }
setmetatable(am_token.mt.__index, am_contained.mt)

--[[ 
 token update events...
    - arena enemies loaded
    - arena allies loaded
    - party changed
]]--


-- the available tokens in game are, arena1-5, arenapet1-5, party1-5, partypet1-5, raid1-40, raidpet1-40, 
-- target, focus, mouseover, none, boss1-4, playername (for friendly party/raid), targettarget, focustarget, etcetc..

-- I can't decide how I want this to go...
-- I feel like the only situation where you would want/need auto updating of tokens is when you join an arena.
-- so, I'm thinking that is the only time I will attempt to update ?
-- that seems very limited, but I really can't think of a place where you would want to use this otherwise.
-- therefore, I guess I can include

function am_token.create(parent_frame)
    local f = setmetatable(CreateFrame("Button", nil, parent_frame, "AMTokenTemplate"), am_token.mt)
    
    f:SetScript("OnEvent", function(self, event, ...) self:am_event(event, ...) end)
    
    return f
end

function am_token.mt.__index:am_set(object)
    
end

function am_token.mt.__index:am_

