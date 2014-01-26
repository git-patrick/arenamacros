-- The purpose of this table is to encapsulate the useful inline scripting portion of the addon
-- the scripting works basically like this...

--[[ 
 
 EXAMPLE MACROS...
 
#showtooltip
/cast [@focus,harm,nodead][@{ ams.arena("CC") }] Polymorph

#showtooltip
/cast [@focus,harm,nodead][@{ ams.arena("CC") }] Counterspell
 
#showtooltip
/cast [@focus,harm,nodead][@{ ams.arena("CC") }] Deep Freeze

#showtooltip
/tar [noexists][dead] { ams.arena("Kill") }
/cast [harm,nodead][{ ams.arena("Kill") }] Ice Lance
 
 the "CC" and "Kill" text can be changed to anything you want.  When the arena starts, you will get an alert asking you to click on which enemy you want to be "CC" and then on which
 you want to be "Kill". to choose you simply click on their arena prep frame.
 
 what the macros do is cast CC on your focus target if it exists, otherwise it defaults to the chosen CC target for you.  this is useful for enemies that can stealth and cause you to drop focus
 you could also have these automatically refocus the chosen CC target if you don't have a current focus thanks to stealthing.
 
 the kill macro retargets your chosen kill target if you dont have a current target on cast.  if you have a friendly selected, it automatically just casts on your kill target.
 this is especially useful for healers who want to help burst while maintaining their current friendly target for healing.
 
]]--

request = { mt = { __index = { } } }

function request.create(token, text, pool, callback)
    local t = setmetatable({ }, request.mt)
    
    t.text = text
    t.token = token
    t.callback = callback
    
    -- pool is a table containing keys with any of the following values "arena", "raid", and/or "party"
    -- it selects which types of frames can be clicked to select the token value
    
    t.pool = pool
    
    return t
end

function request.mt.__index:get_description()
    return self.text
end
function request.mt.__index:get_token()
    return self.token
end
function request.mt.__index:fulfill(uid)
    if (self.pool[uid] ~= nil) then
        self.callback(uid)
        
        return true
    end
    
    return false
end


-- wow doesn't use multiple threads of execution, so I don't have to worry about locks and all the other thread related concerns.

queue = { mt = { __index = { } } }
queue.state = {
    ["inactive"] = false,       -- not waiting for any user interaction
    ["processing"] = 1,         -- processing a request
    ["fading"] = 2              -- fading out the text of the previous request, not going to worry about this right now, but shouldnt be too hard to add later.
}
queue.uidfromframe = { }

function queue._addframes(uid, prefix, count, suffix, start, diff)
    start = start or 1
    diff = diff or 0
    suffix = suffix or ""
    
    for i = start, count do
        if (not queue.uidfromframe[prefix .. i .. suffix]) then
            queue.uidfromframe[prefix .. i .. suffix] = uid .. (i + diff)
        end
    end
end

function queue._init()
    queue._addframes("arena", "ArenaPrepFrame", 5)
    queue._addframes("arena", "ArenaEnemyFrame", 5)
    queue._addframes("party", "PartyMemberFrame", 4)
    -- queue._addframes("CompactRaidFrame", "raid", 40)
    queue.uidfromframe["PlayerFrame"] = "player"
    queue.uidfromframe["ElvUF_Player"] = "player"
    
    queue._addframes("party", "ElvUF_PartyGroup1UnitButton", nil, 5, 2, -1)
    queue._addframes("arena", "ElvUF_Arena", 5, "PrepFrame")
    queue._addframes("arena", "ElvUF_Arena", 5)
end

function queue.create()
    local t = setmetatable({ }, queue.mt)
    
    -- this frame is for OnUpdate stuff to process our queue, and display our message to the world
    t.frame = CreateFrame("Frame", nil, UIParent, "AMQueueNotification")
    t.state = queue.state["inactive"]
    t.queue = { }
   
    for name, uid in pairs(queue.uidfromframe) do
        if (_G[name]) then
            _G[name]:HookScript("OnClick", function (frame) t:_hook(frame) end)
        end
    end
    
    t.frame:SetScript("OnUpdate", pat.create_onupdate(t, .1, t._trigger))
    t.frame:Show()
    
    return t
end

function queue.mt.__index:_hook(frame)
    if (self.state ~= queue.state["processing"]) then
        return
    end
    
    local uid = queue.uidfromframe[frame:GetName()]
    
    if (not self:last():fulfill(uid)) then
        return
    end
    
    -- token has been set successfully
    
    self.frame.am_text:SetText("")
    self.state = queue.state["inactive"]
    
    self:pop()
end

function queue.mt.__index:_trigger()
    local n = self:count()
    
    if (self.state ~= queue.state["inactive"] or
        n < 1) then
        return
    end
    
    self:_process()
end

function queue.mt.__index:_process()    
    self.state = queue.state["processing"]
    self.frame.am_text:SetText(self:last():get_description())
end

function queue.mt.__index:clear()
    self.queue = { }
    
    self.state = queue.state["inactive"]
    self.frame.am_text:SetText("")
end

function queue.mt.__index:count()
    return table.getn(self.queue)
end

function queue.mt.__index:last()
    return self.queue[self:count()]
end

function queue.mt.__index:pop()
    table.remove(self.queue,self:count())
end

function queue.mt.__index:add(req)
    table.insert(self.queue, 1, req)
end

queue._init()