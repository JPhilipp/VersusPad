module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createWoodsAndStones()
    appRemoveSpritesByType('wood')
    appRemoveSpritesByType('stone')

    local randomize = true -- true

    local rotationOffset = 20
    local minY = app.minY + 100
    local maxY = app.maxY - 300
    local marginToPreventSideHorizontals = 50

    for direction = 1, 2 do
        for bridge = 1, 6 do
            local lastX = nil
            local lastY = nil
            for bridgePart = 1, 6 do
                if lastX == nil then
                    lastX = -100
                    lastY = (bridge - 1) * 120
                end
                local x = lastX + 112
                local y = lastY + 38
                local rotation = rotationOffset
                lastX = x
                lastY = y

                if randomize then
                    x = misc.distortValue(x, 15)
                    y = misc.distortValue(y, 15)
                    rotation = misc.distortValue(rotation, 5)
                end

                if direction == 2 then
                    rotation = -rotation
                    x = app.maxX - x
                end
    
                if y >= 60 and y <= 680 and ( misc.getChance(85) or not randomize ) and appGetSpriteCountByType('wood') < 48 then
                    local isNearSide = x <= app.minX + marginToPreventSideHorizontals or x >= app.maxX - marginToPreventSideHorizontals
                    if randomize and misc.getChance(5) and not isNearSide then rotation = 0 end
                    if misc.getChance(23) and x >= 75 then app.spritesHandler:createStone(x, y, rotation)
                    else app.spritesHandler:createWood(x, y, rotation)
                    end
                end
            end
        end
    end

    if randomize then
        local rotationOffsetStrong = 50
        for i = 1, 8 do
            local margin = 50
            local x = math.random(app.minX + margin, app.maxX - margin)
            local y = math.random(50, 700)
            local rotation = math.random(-rotationOffsetStrong, rotationOffsetStrong)
            if i <= 1 and misc.getChance(85) then rotation = misc.getIfChance(nil, -rotationOffsetStrong, rotationOffsetStrong) end
            if misc.getChance(23) and x >= 75 then app.spritesHandler:createStone(x, y, rotation)
            else app.spritesHandler:createWood(x, y, rotation)
            end
        end
    end

    for side = 1, 2 do
        local height = 900
        local x = -40
        local y = height / 2 - 150
        if side == 2 then x = app.maxX - x end
        local self = spriteModule.spriteClass('rectangle', 'wood', nil, nil, true, x, y, 20, height)
        self.isHitTestable = true
        self.isVisible = false
        self.bodyType = 'static'
        self.doDieOutsideField = false
        appAddSprite(self, handle, moduleGroup)
    end

    appRemoveTooCloseStonesOfSameParent()
    -- appShowStoneCount()
end

function self:createFontImageForFreedMessage(x, y, text, subtype)
    if subtype == nil then subtype = 'message' end

    local letterWidth = 23
    local letterWidths = {
            letter_0 = 21,
            letter_1 = 13,
            letter_2 = 16,
            letter_3 = 16,
            letter_4 = 17,
            letter_5 = 16,
            letter_6 = 16,
            letter_7 = 15,
            letter_8 = 17,
            letter_9 = 17,
            letter_o = 17,
            letter_f = 10,
            letter_percent = 22,
            letter_blank = 10
    }

    appRemoveSpritesByType('fontImage', subtype)
    appRemoveSpritesByType('fontImageBackground', subtype)

    local backgroundOffsetX = 38
    local self = spriteModule.spriteClass('rectangle', 'fontImageBackground', subtype, 'freed', false, x, y, 171, 25)
    appAddSprite(self, handle, moduleGroup)

    local baseX = 0
    local widthAll = 0
    local widthAllCalculationRound = 1
    local letterCount = string.len(text)
    for round = widthAllCalculationRound, 2 do

        for i = 1, letterCount do
            local letter = string.sub(text, i, i)
            local letterName = letter
            if letter == '%' then letterName = 'percent'
            elseif letter == ' ' then letterName = 'blank'
            end
            local imageName = letterName
            letterName = 'letter_' .. letterName

            if letterWidths[letterName] ~= nil then
                local letterWidth = letterWidths[letterName]

                if round == widthAllCalculationRound then
                    widthAll = widthAll + letterWidth
                else
                    if letter ~= ' ' then
                        local thisX = math.floor(baseX + letterWidth / 2)
                        local self = spriteModule.spriteClass('rectangle', 'fontImage', subtype, 'font/' .. imageName, false, thisX, y, letterWidth, letterWidth)
                        appAddSprite(self, handle, moduleGroup)
                    end
                    baseX = baseX + letterWidth
                end
            else
                appPrint('Letter "' .. letter .. '" not supported')
            end

        end

        if round == widthAllCalculationRound then
            baseX = backgroundOffsetX + math.floor(x - widthAll / 2)
        end

    end
end

function self:createWarningMessage(x, y, subtype)
    if appGetSpriteCountByType('warningMessage', subtype) == 0 then
        local marginX = 8
        local marginY = 18
        local fingerSize = 40
        local width = 186
        local height = 72

        local minX = app.minX + width / 2 + marginX
        local maxX = app.maxX - width / 2 - marginX
        local minY = app.minY + height / 2 + marginY
        local maxY = app.maxY - height / 2 - marginY

        y = y - fingerSize
        if x < minX then x = minX
        elseif x > maxX then x = maxX
        end
        if y < minY then y = minY
        elseif y > maxY then y = maxY
        end

        local self = spriteModule.spriteClass('rectangle', 'warningMessage', subtype, 'warning-' .. subtype, false, x, y, width, height)
        self.energy = 320
        self.alphaChangesWithEnergy = true
        self.energySpeed = -8
        self.speedY = -.5
        self:makeSound('cannot-do-this')
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createWood(x, y, rotation)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            if app.phase.name == 'playerCanMakeTurn' then
                self:makeSound('wood-explodes')
                app.spritesHandler:createSparks(self.x, self.y, nil, nil, true)
                app.phase:set('playerJustMadeturn')
                self.gone = true
            else
                app.spritesHandler:createWarningMessage(self.touchedX, self.touchedY, 'waitUntilHalting')
            end
        end
    end

    local width = 109
    local height = 43
    local imageName = 'wood'
    local padding = 2
    local shape = {
            0, 10 + padding,
            width, 10 + padding,
            width, 32 - padding,
            0, 32 - padding
            }
    local self = spriteModule.spriteClass('rectangle', 'wood', nil, imageName, true, x, y, width, height,
            nil, shape)
    self.bodyType = 'static'
    self.listenToTouch = true
    self.rotation = rotation
    if misc.getChance(50) then self:toBack() end
    appAddSprite(self, handle, moduleGroup)
end

function self:createTestRectangle(baseRect)
    local self = spriteModule.spriteClass('rectangle', 'testRectangle', nil, nil, false, baseRect.x, baseRect.y, baseRect.width, baseRect.height)
    self.rotation = baseRect.rotation
    self.parentPlayer = baseRect.parentPlayer
    if self.parentPlayer == 1 then self:setRgbWhite()
    else self:setRgbBlack()
    end
    self.energy = 500
    -- self.energySpeed = -1
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createStone(x, y, rotation)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            app.spritesHandler:createWarningMessage(self.touchedX, self.touchedY, 'stonesCannotBeRemoved')
        end
    end

    local parentI = math.random(2)
    local count1 = appGetSpriteCountByType('stone', nil, 1)
    local count2 = appGetSpriteCountByType('stone', nil, 2)
    local unfair = math.abs(count1 - count2) >= 2
    if unfair and count1 > count2 and parentI == 1 then parentI = 2
    elseif unfair and count2 > count1 and parentI == 2 then parentI = 1
    end

    local minRotation = 4
    if math.abs(rotation) < minRotation then rotation = misc.getIf(nil, -minRotation, minRotation) end

    local width = 109
    local height = 23
    local imageName = 'stone-' .. parentI
    if app.mode == 'training' and parentI == app.enemyPlayer then imageName = imageName .. '-during-training' end

    local self = spriteModule.spriteClass('rectangle', 'stone', nil, imageName, true, x, y, width, height,
            nil, nil, parentI)
    self.bodyType = 'static'
    self.rotation = rotation
    self.listenToTouch = true
    if misc.getChance(50) then self:toBack() end
    appAddSprite(self, handle, moduleGroup)
end

function self:createFobbles()
    appRemoveSpritesByType('fobble')
    for playerI = 1, app.playerMax do
        for i = 1, app.fobblesPerPlayer do
            local margin = 40
            local x = math.random(app.minX + margin, app.maxX - margin)
            local y = math.random(-50, 150) -- math.random(-120, -10)
            local rotation = math.random(0, app.maxRotation)
            app.spritesHandler:createFobble(x, y, playerI, rotation)
        end
    end
end

function self:createFobble(x, y, playerI, rotation)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] >= 9 then
                if self.collisionForce[i] <= 16 then self:makeSound('fobble-bump-soft')
                else self:makeSound('fobble-bump')
                end

                if other.type == 'wood' and other.subtype == nil and self.collisionForce[i] >= 11 then
                    app.spritesHandler:createSparks(self.x, self.y, 4)
                elseif other.type == 'ground' and self.collisionForce[i] >= 12 then
                    app.spritesHandler:createSparks( self.x, self.y, 6, {red = 119, green = 155, blue = 31} )
                end
            end

        end

        local speedX, speedY = self:getLinearVelocity()
        if speedY >= 250 then self:makeSound('fobble-falling') end

        if self.y >= 789 and self.phase.name ~= 'free' then
            self.type = 'freedFobble'
            self.phase:set('free')
            self.doDieOutsideField = true
            self:makeSound('fobble-freed', true)
            local parentPlayerSecureCopy = self.parentPlayer
            if appGetSpriteCountByType('fobble', nil, parentPlayerSecureCopy) <= 0 and app.phase.name ~= 'announceWinner' then
                app.winner = parentPlayerSecureCopy
                app.phase:set('announceWinner')
            end
        end
        if self.y ~= nil and app.maxY ~= nil and self.y > app.maxY then self.gone = true end

        if self.extraPhase.name == 'default' then
            if not self.extraPhase:isInited() then
                if self.data.blinkedBefore then self.extraPhase:setNext( 'blink', 360 + math.random(30) )
                else self.extraPhase:setNext( 'blink', math.random(360) )
                end
            end

            local isFast = math.abs(self.speedX) >= 1 or math.abs(self.speedY) >= 1
            local willBlinkSoon = self.extraPhase.counter == nil or self.extraPhase.counter <= 30
            if willBlinkSoon or isFast then self.frameName = 'default'
            elseif math.random(1000) <= 15 then self.frameName = misc.getIf(self.frameName == 'default', 'variation', 'default')
            end

        elseif self.extraPhase.name == 'blink' then
            if not self.extraPhase:isInited() then
                self.data.blinkedBefore = true
                self.extraPhase:setNext('default', 6)
            end
        end

    end

    local radius = app.fobbleRadius
    local imageName = 'fobble-' .. playerI
    if app.mode == 'training' and playerI == app.enemyPlayer then imageName = imageName .. '-during-training' end

    local framesData = {
            image = {width = 117, height = 39, count = 3},
            names = {
            {name = 'default', start = 1},
            {name = 'blink', start = 2},
            {name = 'variation', start = 3},
            }
            }

    local self = spriteModule.spriteClass('circle', 'fobble', nil, imageName, true, x, y, radius, nil,
            framesData, nil, playerI)
    self.parentPlayer = playerI
    self.doDieOutsideField = false
    self.listenToPostCollision = true
    if rotation == nil then rotation = math.random(0, app.maxRotation) end
    self.rotation = rotation
    self.frameName = 'default'
    self.phase:set('default')
    self.extraPhasesWithFrameNames = {'default', 'blink'}
    self.extraPhase:set('default')
    self.data.blinkedBefore = false
    appAddSprite(self, handle, moduleGroup)
end

function self:createSparks(x, y, maxSparks, optionalColorTriple, optionalExtraBig)
    if maxSparks == nil then maxSparks = 30 end
    if optionalExtraBig == nil then optionalExtraBig = false end

    local maxSparksAll = 60
    local sparkCount = appGetSpriteCountByType('spark')

    for sparkI = 1, maxSparks, 1 do
        if sparkCount < maxSparksAll then
            sparkCount = sparkCount + 1
            local width = math.random(2, 6)
            local height = math.random(10, 14)
            if optionalExtraBig then width = width * 1.6; height = height * 1.6 end

            local thisX = misc.distortValue(x, 15)
            local thisY = misc.distortValue(y, 5)

            local self = spriteModule.spriteClass('rectangle', 'spark', subtype, nil, false, thisX, thisY, width, height)
            self.targetSpeedY = 9
            local speedLimit = 7
            self.rotationSpeed = math.random(-10, 10)
            self.speedX = math.random(-speedLimit, speedLimit)
            self.speedY = math.random(-speedLimit, speedLimit / 2)

            local darker = math.random(-100, -30)

            if optionalColorTriple == nil then optionalColorTriple = {red = 235, green = 161, blue = 77} end
            self:setRgb(
                    misc.distortValue(optionalColorTriple.red + darker),
                    misc.distortValue(optionalColorTriple.green + darker),
                    misc.distortValue(optionalColorTriple.blue + darker) )

            self.energy = 130
            if optionalExtraBig then self.energy = self.energy + 15 end
            self.energySpeed = -5
            self.alphaChangesWithEnergy = true

            appAddSprite(self, handle, moduleGroup)
        end
    end
end

function self:createTurnMessage()
    local function handle(self)
        self.rotation = self.rotation + self.data.rotationSpeed
        if self.rotation < self.data.rotationMin then
            self.rotation = self.data.rotationMin
            self.data.rotationSpeed = self.data.rotationSpeed * -1
        elseif self.rotation > self.data.rotationMax then
            self.data.rotation = self.data.rotationMax
            self.data.rotationSpeed = self.data.rotationSpeed * -1
        end
    end

    appRemoveSpritesByType('message')
    local x = 220

    local y = 900
    if app.currentPlayer == 2 then
        x = app.maxX - x
    end
    local imageName = 'player-' .. app.currentPlayer .. '-turn'

    local width = 372
    local height = 90
    if app.mode == 'training' then
        x = app.maxXHalf
        y = y - 10
        imageName = imageName .. '-during-training'
        width = 440
        height = 87
    end

    local self = spriteModule.spriteClass('rectangle', 'message', nil, imageName, false, x, y, width, height)
    self.data.rotationSpeed = .4
    self.data.rotationMin = -5
    self.data.rotationMax = math.abs(self.data.rotationMin)
    appAddSprite(self, handle, moduleGroup)
end

function self:createWinMessage(winnerI)
    local function handle(self)
        if self.data.scale < self.data.scaleTarget then self.data.scaleSpeed = self.data.scaleSpeed + self.data.scaleStep
        elseif self.data.scale > self.data.scaleTarget then self.data.scaleSpeed = self.data.scaleSpeed - self.data.scaleStep
        end

        if self.data.scaleSpeed < -self.data.scaleSpeedLimit then self.data.scaleSpeed = -self.data.scaleSpeedLimit
        elseif self.data.scaleSpeed > self.data.scaleSpeedLimit then self.data.scaleSpeed = self.data.scaleSpeedLimit
        end

        self.data.scale = self.data.scale + self.data.scaleSpeed
        self:scale(self.data.scale, self.data.scale)
    end

    appRemoveSpritesByType('message')
    if app.mode == 'default' or (app.mode == 'training' and app.winner == app.currentPlayer) then appPlaySound('win')
    -- elseif app.mode == 'training' then appPlaySound('lose')
    end

    local imageName = 'player-' .. winnerI .. '-wins'
    local width = 289
    local height = 72

    if app.mode == 'training' then
        imageName = imageName .. '-during-training'
        width = 276
        height = 71
    end
    local self = spriteModule.spriteClass('rectangle', 'message', nil, imageName, false, app.maxXHalf, 800, width, height)

    self.data.scale = 1.07
    self.data.scaleTarget = 1.005
    self.data.scaleSpeed = 0
    self.data.scaleStep = .001
    self.data.scaleSpeedLimit = .01

    self.energy = 570
    self.energySpeed = -2
    self.alphaChangesWithEnergy = true

    appAddSprite(self, handle, moduleGroup)
end

function self:createCelebratingFobbles(winnerI)
    local function handle(self)
        local gravity = .4
        local groundY = 920

        if self.phase.name == 'active' then
            if not self.phase:isInited() then
                self.phase:setNext('leave', 300)
                self.speedY = 0
                self.speedLimitX = 4
                self.targetX = self.x + 665 * self.data.direction
                self.targetFuzziness = 3
            end
            self.speedY = self.speedY + gravity
            if math.random(250) <= 1 then self:makeSound('fobble-freed') end

        elseif self.phase.name == 'leave' then
            if not self.phase:isInited() then
                self.doDieOutsideField = true
                self.targetX = self.x + 900 * self.data.direction
            end
            self.speedY = self.speedY + gravity

        end

        if self.y > groundY then
            self.y = groundY
            self.speedY = self.speedY * -1
            app.spritesHandler:createSparks( self.x, self.y, 6, {red = 119, green = 155, blue = 31} )
            self:makeSound('fobble-bump-soft')
        end

        if self.extraPhase.name == 'default' then
            if not self.extraPhase:isInited() then
                if self.data.blinkedBefore then self.extraPhase:setNext( 'blink', 100 + math.random(30) )
                else self.extraPhase:setNext( 'blink', math.random(100) )
                end
            end
        elseif self.extraPhase.name == 'blink' then
            if not self.extraPhase:isInited() then
                self.data.blinkedBefore = true
                self.extraPhase:setNext('default', 6)
            end
        end
    end

    local framesData = {
            image = {width = 117, height = 39, count = 3},
            names = {
            {name = 'default', start = 1},
            {name = 'blink', start = 2},
            {name = 'variation', start = 3},
            }
            }

    local fobblesMax = 8
    for i = 1, fobblesMax do
        local radius = 20
        local imageName = 'fobble-' .. winnerI
        if app.mode == 'training' and winnerI == app.enemyPlayer then imageName = imageName .. '-during-training' end

        local x = app.minX - 550 + (i - 1) * 75
        if winnerI == 2 then
            x = app.maxX + 550 - (i - 1) * 75
        end

        local y = 780
        local self = spriteModule.spriteClass('circle', 'celebratingFobble', nil, imageName, false, x, y, radius, nil,
                framesData, nil, playerI)
        self.parentPlayer = winnerI
        self.data.direction = misc.getIf(winnerI == 1, 1, -1)
        self.frameName = 'default'

        self.rotation = -33 + math.random(-2, 2)
        self.phase:set('default', 2 + (i - 1) * 10, 'active')

        self.extraPhasesWithFrameNames = {'default', 'blink'}
        self.extraPhase:set('default')
        self.data.blinkedBefore = false
        self.doDieOutsideField = false

        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createClouds()
    local function handle(self)
        if self:isOutside() then
            self.speedX = self.speedX * -1
            self.x = self.x + self.speedX
        end
    end

    appRemoveSpritesByType('cloud')
    local cloudsMax = 3
    for i = 1, cloudsMax do
        local x = math.random(app.maxX)
        local y = math.random(600, 800)
        local self = spriteModule.spriteClass('rectangle', 'cloud', nil, 'cloud', false, x, y, 362, 90)
        self.speedX = .6 + i * .2
        if i > cloudsMax / 2 then self.speedX = self.speedX * -1 end
        self.doDieOutsideField = false
        self:toBack()
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createGround()
    local width = 822
    local height = 133
    local shape = {
        0, 78,
        97, 43,
        408, 0,
        726, 43,
        width, 78,
        width, height,
        0, height
    }
    local self = spriteModule.spriteClass('rectangle', 'ground', nil, nil, true, app.maxXHalf, app.maxY - height / 2, width, height,
            nil, shape)
    self.isHitTestable = true
    self.isVisible = false
    self.bodyType = 'static'
    appAddSprite(self, handle, moduleGroup)
end

function self:createWorm()
    local function handle(self)
        local margin = 50
        if self.phase.name == 'default' then
            if not self.phase:isInited() then
                if self.x < app.minX then self.speedX = self.speedLimit
                elseif self.x > app.maxX then self.speedX = -self.speedLimit
                end
            end

            if (self.x <= app.minX - margin and self.speedX < 0) or (self.x >= app.maxX + margin and self.speedX > 0) then
                self.speedX = 0
                self.phase:set('sleep', 5000 + math.random(5000), 'default')
            end
        end
    end

    local width = 37; local height = 16
    local framesData = {
            image = {width = width * 2, height = height, count = 2},
            names = {
            {name = 'default', start = 1, count = 2, time = 1100, loopDirection = 'forward', loopCount = 0}
            }
            }

    local self = spriteModule.spriteClass('rectangle', 'worm', nil, 'worm', false, -width / 2, 958, width, height,
            framesData)
    self.frameName = 'default'
    self.speedLimit = .75
    self.doDieOutsideField = false
    self.phase.name = 'sleep'
    self.phase:setNext( 'default', 5000 + math.random(5000) )
    appAddSprite(self, handle, moduleGroup)
end

function self:createBirds()
    local function handle(self)
        self.speedX = self.speedX + misc.randomFloat(-.5, .5)
        self.speedY = self.speedY + misc.randomFloat(-.5, .5)
        self.frameName = misc.getIf(self.speedX < 0, 'left', 'right')
    
        if self.subtype == 'swarmLeader' then
    
            if misc.getChance(1) or self.targetX == nil then
                local margin = 300
                self.targetX = math.random(app.minX - margin, app.maxX + margin)
                self.targetY = math.random(750, 850)
            end
    
        else
    
            if self.phase.name == 'followSwarmLeader' then
                if misc.getChance(1) then self.phase.name = 'default' end
                if self.targetSprite == nil then
                    self.targetSprite = appGetSpriteByType('bird', 'swarmLeader')
                end
            else
                if misc.getChance(1) then self.phase.name = 'followSwarmLeader' end
                self.targetSprite = nil
            end
    
        end
    end

    appRemoveSpritesByType('bird')
    local maxBirds = 8
    local swarmX = math.random(app.minX + 50, app.maxX - 50); local swarmY = math.random(750, 850)
    local frameSpeed = 550
    local framesData = {
            image = {width = 66, height = 14, count = 6},
            names = {
            {name = 'right', frames = {1, 2, 3}, time = frameSpeed, loopDirection = 'bounce', start = 1, count = 3, loopCount = 0},
            {name = 'left', frames = {4, 5, 6}, time = frameSpeed, loopDirection = 'bounce', start = 4, count = 3, loopCount = 0}
            }
            }

    for i = 1, maxBirds do
        local x = swarmX + math.random(-100, 100)
        local y = swarmY + math.random(-70, 70)
        local self = spriteModule.spriteClass('rectangle', 'bird', nil, 'bird', false, x, y, 11, 14, framesData)
        self.id = 'bird' .. i
        self.speedLimitX = 2
        self.speedLimitY = 1
        self.doDieOutsideField = false
        self.speedStep = .1

        if i == 1 then self.subtype = 'swarmLeader'
        else self.phase:set('followSwarmLeader')
        end

        self.frameName = misc.getIf(self.speedX < 0, 'left', 'right')
        self.alpha = .18
        appAddSprite(self, handle, moduleGroup)
    end
end

return self
end