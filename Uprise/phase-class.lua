module(..., package.seeall)

function phaseClass()
local self = {}
self.name = 'default'
self.counter = nil
self.nameNext = nil
self.inited = false
self.startTimeInSeconds = nil
self.maxSeconds = nil

function self:set(name, counter, optionalNameNext, optionalMaxSeconds)
    self.name = name
    self.counter = counter
    self.nameNext = optionalNameNext
    self.inited = false
    self.startTimeInSeconds = getTimeInSeconds()
    self.maxSeconds = optionalMaxSeconds
end

function self:setNext(nameNext, counter, maxSeconds)
    self.nameNext = nameNext
    self.counter = counter
    self.maxSeconds = maxSeconds
end

function self:handleCounter()
    if self.counter ~= nil and self.nameNext ~= nil and self.counter > 0 then
        self.counter = self.counter - 1
        if self.counter == 0 and self.nameNext ~= nil then
            self.name = self.nameNext
            self.nameNext = nil
            self.inited = false
            self.startTimeInSeconds = getTimeInSeconds()
        end
    end

    if self.maxSeconds ~= nil and self.startTimeInSeconds ~= nil then
        if self:getSecondsPassed() > self.maxSeconds and self.nameNext ~= nil then
            self.maxSeconds = nil
            self.name = self.nameNext
            self.nameNext = nil
            self.inited = false
            self.startTimeInSeconds = getTimeInSeconds()
        end
    end
end

function self:isInited()
    local wasInited = self.inited
    self.inited = true
    return wasInited
end

function self:getSecondsLeft()
    local secondsLeft = 0
    if self.maxSeconds ~= nil and self.startTimeInSeconds ~= nil then
        secondsLeft = self.maxSeconds - self:getSecondsPassed()
        if secondsLeft < 0 then secondsLeft = 0 end
    end
    return secondsLeft
end

function self:getSecondsPassed()
    local secondsPassed = 0
    if self.startTimeInSeconds ~= nil then
        secondsPassed = getTimeInSeconds() - self.startTimeInSeconds
        if secondsPassed < 0 then secondsPassed = 0 end
    end
    return secondsPassed
end

function self:getInfo()
    local s = 'Phase: ' .. self.name
    if self.counter ~= nil and self.counter ~= 0 then s = s .. ' (c: ' ..  tostring(self.counter) .. ') ' end
    if self.maxSeconds ~= nil and self.startTimeInSeconds ~= nil then s = s .. ' (s: ' ..  tostring( self:getSecondsLeft() ) .. ') ' end
    if self.nameNext ~= nil then s = s .. ' -> ' ..  tostring(self.nameNext) end
    return s
end

return self
end