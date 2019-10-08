module(..., package.seeall)

function phaseClass()
local self = {}
self.name = 'default'
self.counter = nil
self.nameNext = nil
self.inited = false

function self:set(name, counter, optionalNameNext)
    self.name = name
    self.counter = counter
    self.nameNext = optionalNameNext
    self.inited = false
end

function self:setNext(nameNext, counter)
    self.counter = counter
    self.nameNext = nameNext
end

function self:handleCounter()
    if self.counter ~= nil and self.nameNext ~= nil and self.counter > 0 then
        self.counter = self.counter - 1
        if self.counter == 0 then
            if self.nameNext ~= nil then
                self.name = self.nameNext
                self.inited = false
            end
        end
    end
end

function self:isInited()
    local wasInited = self.inited
    self.inited = true
    return wasInited
end

function self:getInfo()
    local s = 'Phase: ' .. self.name
    if self.counter ~= nil and self.counter ~= 0 then s = s .. ' (' ..  tostring(self.counter) .. ')' end
    if self.nameNext ~= nil then s = s .. ' -> ' ..  tostring(self.nameNext) end
    return s
end

return self
end