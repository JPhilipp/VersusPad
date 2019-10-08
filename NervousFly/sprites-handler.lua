module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createFly()
    local function handle(self)
        local speedX, speedY = self:getLinearVelocity()

        local flyUpwards = self.y > app.maxY / 5 and speedY >= 0 and
                ( ( misc.getChance(5) or self.data.forcedDestination == 'top') and self.data.forcedDestination ~= 'bottom' )
        if flyUpwards then self:applyLinearImpulse(0, -25, self.x, self.y) end

        local rotationStep = 2
        if self.animationFrame == 'right1' or self.animationFrame == 'right2' then
            local rotationMin = -8
            local rotationMax = 6
            if self.rotation < rotationMin then self.rotation = rotationMin
            elseif self.rotation > rotationMax then self.rotation = rotationMax
            end
            if speedY < 0 then
                if self.rotation > rotationMin then self.rotation = self.rotation - rotationStep end
            else
                if self.rotation < rotationMax then self.rotation = self.rotation + rotationStep end
            end
        else
            local rotationMin = -6
            local rotationMax = 8
            if self.rotation < rotationMin then self.rotation = rotationMin
            elseif self.rotation > rotationMax then self.rotation = rotationMax
            end
            if speedY < 0 then
                if self.rotation < rotationMax then self.rotation = self.rotation + rotationStep end
            else
                if self.rotation > rotationMin then self.rotation = self.rotation - rotationStep end
            end
        end

        if speedY < 0 and misc.getChance(75) then
            if self.animationFrame == 'right1' then self.animationFrame = 'right2'
            elseif self.animationFrame == 'right2' then self.animationFrame = 'right1'
            elseif self.animationFrame == 'left1' then self.animationFrame = 'left2'
            elseif self.animationFrame == 'left2' then self.animationFrame = 'left1'
            end
        end

        if speedX < 0 and (self.animationFrame == 'right1' or self.animationFrame == 'right2') then self.animationFrame = 'left1'
        elseif speedX > 0 and (self.animationFrame == 'left1' or self.animationFrame == 'left2') then self.animationFrame = 'right1'
        end

        self:updateAnimationFrame()

        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] then
                if other.type == 'cube' then
                    local flyInnerHeightHalf = 11
                    local height = other.height
                    if height ~= nil then
                        local isAbove = other.y + height * .5 - 25 < self.y - flyInnerHeightHalf
                        local isBelow = other.y - height * .5 + 8 > self.y + flyInnerHeightHalf
                        if isAbove then
                            self.data.lastTimeNearTopOrCollision = appGetTimeInSeconds()
                        elseif isBelow then
                            self.data.lastTimeNearBottomOrCollision = appGetTimeInSeconds()
                        end
                    end
                end

                if (other.type == 'ground' or other.type == 'wall') and self.collisionForce[i] >= 30 then
                    self:makeSound('bump.wav')
                end
            end
        end

        if self.extraPhase.name == 'default' then
            if not self.extraPhase:isInited() then
                self.extraPhase:set('createClone', 5, 'default')
            end

        elseif self.extraPhase.name == 'createClone' then
            if not self.extraPhase:isInited() then
                local minSpeed = 25
                if math.abs(speedX) >= minSpeed or math.abs(speedY) >= minSpeed then
                    app.spritesHandler:createCloneEffect(self.x, self.y)
                    if self.animationFrames[self.animationFrame] ~= nil then
                        self.animationFrames[self.animationFrame]:toFront()
                    end
                end
            end
        end

        self.data.handleIfTooLongAwayFromTopOrBottom(self)
    end

    function handleIfTooLongAwayFromTopOrBottom(self)
        local secondsNow = appGetTimeInSeconds()
        if self.y < 150 then
            self.data.lastTimeNearTopOrCollision = secondsNow
            if self.data.forcedDestination == 'top' then self.data.forcedDestination = nil end
        elseif self.y > app.maxY - 140 then
            self.data.lastTimeNearBottomOrCollision = secondsNow
            if self.data.forcedDestination == 'bottom' then self.data.forcedDestination = nil end
        end

        local consideredLongInSeconds = 5
        local secondsSinceNearTop = secondsNow - self.data.lastTimeNearTopOrCollision
        local secondsSinceNearBottom = secondsNow - self.data.lastTimeNearBottomOrCollision

        if secondsSinceNearTop >= consideredLongInSeconds then
            if self.data.forcedDestination ~= 'top' then
                self.data.forcedDestination = 'top'
            end
        elseif secondsSinceNearBottom >= consideredLongInSeconds then
            if self.data.forcedDestination ~= 'bottom' then
                self.data.forcedDestination = 'bottom'
            end
        else
            self.data.forcedDestination = nil
        end
    end

    local friction = 0
    local density = 8
    local imageName = 'fly'
    local x = 61
    local width = 72
    local height = 48
    local shape = {25,22, 44,22, 44,42, 25,42}
    local self = spriteModule.spriteClass('rectangle', 'fly', nil, nil, true, x, app.maxYHalf, width, height,
            1, 4, shape, nil, nil, density, nil, friction)
    -- self.alpha = .5
    self.isVisible = false
    self.speedLimitX = 10
    self.speedLimitY = 2
    self.speedStep = 1.5 -- .5
    self.doDieOutsideField = false
    self.targetSpeedX = 0
    self.alsoAllowsExtendedNonPhysicalHandling = false
    self.isFixedRotation = true
    self.listenToPostCollision = true
    self.data.lastTimeNearTopOrCollision = appGetTimeInSeconds()
    self.data.lastTimeNearBottomOrCollision = appGetTimeInSeconds()
    self.data.forcedDestination = nil
    self.data.handleIfTooLongAwayFromTopOrBottom = handleIfTooLongAwayFromTopOrBottom

    self.animationFrames = {}
    self.animationFrameNames = {'right1', 'right2', 'left1', 'left2'}
    for i = 1, #self.animationFrameNames do
        local frameName = self.animationFrameNames[i]
        local frame = spriteModule.spriteClass('rectangle', 'flyAnimationFrame', frameName, 'fly/' .. frameName, false, self.x, self.y, self.width, self.height)
        frame.parentId = self.id
        frame.movesWithParent = true
        frame.isVisible = true
        appAddSprite(frame, nil, moduleGroup)
        self.animationFrames[frameName] = frame
    end
    self.animationFrame = 'right1'

    appAddSprite(self, handle, moduleGroup)

    app.playerSprite = appGetSpriteByType('fly')
end

function self:createCube(x, y, subtype)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] then

                if self.type == other.type then
                    if self.subtype == other.subtype then
                        if not app.gameOver then
                            self.data.originatedCollision = true
                            self.gone = true
                            other.gone = true
                        end
                    else
                        if self.collisionForce[i] >= 15 then
                            self:makeSound( 'cube-to-cube-' .. math.random(1, 2) )
                            if self.collisionForce[i] >= 25 and misc.getChance(2) then
                                app.spritesHandler:createCubeCrumbles(self.subtype, self.x, self.y, false)
                            end
                        end
                    end
                elseif other.type == 'ground' or other.type == 'wall' then
                    if self.collisionForce[i] >= 30 then
                        self:makeSound('cube-to-glass')
                    end
                elseif other.type == 'fly' then
                    if self.collisionForce[i] >= 10 then
                        self:makeSound('bump.wav')
                        if self.collisionForce[i] >= 25 and misc.getChance(2) then
                            app.spritesHandler:createCubeCrumbles(self.subtype, self.x, self.y, false)
                        end
                    end
                end

            end
        end

        if not self.gone then
            local sanityCheckMaxY = app.maxY * 2
            if self.y > sanityCheckMaxY then self.gone = true end

            if self.phase.name == 'thrown' then
                if not self.phase:isInited() then
                    self:makeSound('falling.wav')
                end
    
            elseif self.phase.name == 'afterThrown' then
                if self.y < 15 and app.extraPhase.name ~= 'cherryJustExploded' and not app.gameOver then
                    app.gameOverCauserX = self.x
                    app.phase:set('showGameOver')
                    app.gameOver = true
                end
            end
    
            if self.extraPhase.name == 'default' then
                if not self.extraPhase:isInited() then
                    self.extraPhase:set('createClone', 5, 'default')
                end

            elseif self.extraPhase.name == 'createClone' then
                if not self.extraPhase:isInited() then
                    if not app.gameOver then
                        local speedX, speedY = self:getLinearVelocity()
                        local minSpeed = 35
                        if math.abs(speedX) >= minSpeed or math.abs(speedY) >= minSpeed and self.y > 0 then
                            app.spritesHandler:createCloneEffect(self.x, self.y)
                            self:toFront()
                        end
                    end
                end
            end
        end
    end

    local function handleWhenGone(self)
        if not app.gameOver then
            if self.data.originatedCollision then
                self:makeSound( 'crush-' .. math.random(1, 3) )
            end

            app.highestThisRound.iceCubes = app.highestThisRound.iceCubes + 1
            app.highestThisRound.score = app.highestThisRound.iceCubes * app.highestThisRound.glass
            app.spritesHandler:createCubeCrumbles(self.subtype, self.x, self.y)
        end
    end

    local width = 79 -- inner size that was good: 51x51
    local height = width
    local fuzzy = 2
    if x == nil then x = app.maxXHalf + math.random(-fuzzy, fuzzy) end

    if y == nil then y = -height * 1.5 end
    if subtype == nil then subtype = math.random(1, app.maxCubeTypes) end
    local bounce = 0.05
    local density = 0.8
    local shape = {14,14, 64,14, 64,64, 14,64}
    local self = spriteModule.spriteClass('rectangle', 'cube', subtype, 'cube/' .. subtype, true, x, y, width, height,
            nil, nil, shape, nil, nil, density, bounce, friction)
    self.doDieOutsideField = false
    self.isFixedRotation = true
    self.listenToPostCollision = true
    self.alsoAllowsExtendedNonPhysicalHandling = false
    self.phase:set('thrown', 50, 'afterThrown')
    appAddSprite(self, handle, moduleGroup, handleWhenGone)

    app.lastCubeSubtype = subtype
end

function self:createCherry()
    local function handle(self)
        if app.gameOver then
            self.energySpeed = 0
        elseif self.energy <= 70 then
            local chanceForMovement = 75
            if misc.getChance(chanceForMovement) then self.x = self.x + math.random(-3, 3) end
            if misc.getChance(chanceForMovement) then self.y = self.y + math.random(-4, 4) end
        end
    end

    local function handleWhenGone(self)
        if not app.gameOver then
            app.extraPhase:set('cherryJustExploded', 100, 'default')
            self:makeSound('explode')
            system.vibrate()
            app.spritesHandler:createCherryCrumbles(self.x, self.y)
        end
    end

    local width = 79; local height = width; local bounce = 0.05; local density = 0.8 -- values cloned from cube
    local shape = {16,16, 62,16, 62,62, 16,62}
    local self = spriteModule.spriteClass('rectangle', 'cherry', nil, 'cherry', true, app.maxXHalf, -height * 1.5, width, height,
            nil, nil, shape, nil, nil, density, bounce, friction)
    self.doDieOutsideField = false
    self.energy = 225
    self.energySpeed = -1
    self.angularDamping = 200
    self.alsoAllowsExtendedNonPhysicalHandling = false
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createOlive()
    local function handleWhenGone(self)
        if not app.gameOver then
            app.spritesHandler:createOliveCrumbles(self.x, self.y)
        end
    end

    local width = 51; local height = width
    local radius = math.floor(width / 2)
    local bounce = 0.05

    local self = spriteModule.spriteClass('circle', 'olive', nil, 'olive', true, app.maxXHalf, -height * 1.5, radius, nil,
            nil, nil, nil, nil, nil, nil, bounce, friction)
    self.doDieOutsideField = false
    self.angularDamping = 200
    self.alsoAllowsExtendedNonPhysicalHandling = false
    appAddSprite(self, handle, moduleGroup, handleWhenGone)

    local numberOfOlives = appGetSpriteCountByType('olive')
    if numberOfOlives >= 1 and app.highestThisRound.olives == nil or numberOfOlives > app.highestThisRound.olives then
        app.highestThisRound.olives = numberOfOlives
    end
end

function self:createCherryCrumbles(centerX, centerY)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if other.type == 'cube' or other.type == 'olive' then
                if other.data then other.data.originatedCollision = true end
                other.gone = true
                self.gone = true
            end
        end
    end

    local width = 18; local height = 17
    for gridX = -1, 1 do
        for gridY = -1, 1 do
            local x = centerX + gridX * width
            local y = centerY + gridY * height
            local self = spriteModule.spriteClass('rectangle', 'cherryCrumble', nil, 'cherry-crumble', true, x, y, width, height)
            self.energy = 200
            self.energySpeed = -10
            self.alphaChangesWithEnergy = true
            local force = 10
            self:applyLinearImpulse(gridX * force, gridY * force, x, y)
            self.listenToPostCollision = true
            appAddSprite(self, handle, moduleGroup)
        end
    end
end

function self:createOliveCrumbles(centerX, centerY)
    local width = 17; local height = width
    for gridX = -1, 1 do
        for gridY = -1, 1 do
            local x = centerX + gridX * width
            local y = centerY + gridY * height
            local self = spriteModule.spriteClass('rectangle', 'oliveCrumble', nil, 'olive-crumble', true, x, y, width, height)
            self.energy = 200
            self.energySpeed = -10
            self.alphaChangesWithEnergy = true
            local force = 10
            self:applyLinearImpulse(gridX * force, gridY * force, x, y)
            appAddSprite(self, handle, moduleGroup)
        end
    end 
end

function self:createCloneEffect(x, y)
    if appGetSpriteCountByType('cloneEffect') <= 15 then
        local self = spriteModule.spriteClass('rectangle', 'cloneEffect', nil, 'cloneEffect', false, x, y, 37, 38)
        self.energySpeed = -1
        self.energy = 60
        self.alphaChangesWithEnergy = true
        appAddSprite(self, handle, moduleGroup, handleWhenGone)
    end
end

function self:createTouchArea()
    local function handle(self)
        if self.data.direction ~= nil then
            app.playerSprite:setLinearVelocity(self.data.direction * 260, 0)
        end
    end

    local function handleTouch(event)
        local self = event.target

        if misc.inArray( {'began', 'moved', 'stationary'}, event.phase ) then
            if event.id ~= self.data.latestTouchId then
                self.data.latestTouchId = event.id
                self.data.direction = nil
                self.data.swipeDirection = nil
                self.data.touchedXOld = nil
                app.playerSprite:setLinearVelocity(0, 0)
            end

            if self.data.touchedXOld == nil then self.data.touchedXOld = event.x end
            local direction = nil

            local distance = event.x - self.data.touchedXOld
            local doesSwipe = math.abs(distance) >= 10 -- was 3, later 7

            if self.data.swipeDirection ~= nil then
                if doesSwipe then
                    direction = misc.getIf(distance < 0, -1, 1)
                    self.data.swipeDirection = direction
                else
                    direction = self.data.swipeDirection
                end

            elseif doesSwipe then
                direction = misc.getIf(distance < 0, -1, 1)
                self.data.swipeDirection = direction

            else
                direction = misc.getIf(event.x < app.maxXHalf, -1, 1)

            end

            self.data.direction = direction
            self.data.touchedXOld = event.x

        elseif misc.inArray( {'ended', 'cancelled'}, event.phase ) then
            if event.id == self.data.latestTouchId then
                self.data.latestTouchId = nil
                self.data.direction = nil
                self.data.swipeDirection = nil
                self.data.touchedXOld = nil
                app.playerSprite:setLinearVelocity(0, 0)
            end

        end

    end

    local self = spriteModule.spriteClass('rectangle', 'touchArea', nil, nil, false, 10, 10, 10, 10)
    self.isHitTestable = true
    self.isVisible = false
    -- self:setRgb( 200, math.random(0, 255), 255, 70 )
    local y = 30
    self.doDieOutsideField = false

    if app.device == 'iPad' then self:setPosFromLeftTop(-20, y, app.maxX + 40, app.maxY - y)
    else self:setPosFromLeftTop(0, y, app.maxX, app.maxY - y)
    end

    self.data.touchedXOld = nil
    self.data.latestTouchId = nil
    self.data.swipeDirection = nil

    self:addEventListener('touch', handleTouch)
    appAddSprite(self, handle, moduleGroup)
end

function self:createBackground()
    local self = spriteModule.spriteClass('rectangle', 'background', nil, 'background', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self:toBack()
    appAddSprite(self, handle, moduleGroup)
end

function self:createGround()
    local height = 46
    local self = spriteModule.spriteClass('rectangle', 'ground', nil, nil, true, app.maxXHalf, app.maxY - height / 2, app.maxX, height)
    self.bodyType = 'static'
    self.isHitTestable = true
    self.isVisible = false
    -- self:setRgb( 0, math.random(0, 255), 255, 70 )
    appAddSprite(self, handle, moduleGroup)
end

function self:createWalls()
    local width = 40
    local marginTop = 50
    for i = 1, 2 do
        local x = misc.getIf(i == 1, -width / 2, app.maxX + width / 2)
        local self = spriteModule.spriteClass('rectangle', 'wall', nil, nil, true, x, app.maxYHalf - marginTop / 2, width, app.maxY + marginTop)
        self.bodyType = 'static'
        self.isHitTestable = true
        self.isVisible = false
        -- self:setRgb( 200, 0, 55, 70 )
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createCubeCrumbles(subtype, centerX, centerY, bigCrumbling)
    if bigCrumbling == nil then bigCrumbling = true end
    local width = 15
    local height = width

    local lotsOfCrumbles = appGetSpriteCountByType('cubeCrumble') >= 30

    if bigCrumbling and not lotsOfCrumbles then
        for gridX = -1, 1 do
            for gridY = -1, 1 do
                local x = centerX + gridX * width
                local y = centerY + gridY * height
                app.spritesHandler:createCubeCrumble(subtype, x, y, width, height)
            end
        end

    else
        local gridX = misc.getIfChance(nil, -1, 1)
        local gridY = misc.getIfChance(nil, -1, 1)
        local x = centerX + gridX * width
        local y = centerY + gridY * height
        app.spritesHandler:createCubeCrumble(subtype, x, y, width, height, 70)
    end
end

function self:createCubeCrumble(subtype, x, y, width, height, optionalEnergy)
    if optionalEnergy == nil then optionalEnergy = 130 end
    local self = spriteModule.spriteClass('rectangle', 'cubeCrumble', subtype, 'cube/crumble/' .. subtype, false, x, y, width, height)
    self.targetSpeedY = 9
    local speedLimit = 7
    self.rotationSpeed = math.random(-10, 10)
    self.speedX = math.random(-speedLimit, speedLimit)
    self.speedY = math.random(-speedLimit, speedLimit / 2) + 3
    self.energy = optionalEnergy
    self.energySpeed = -3
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createScore()
    local function handle(self)
        if self.data.scoreOld ~= app.highestThisRound.score then
            self.text = tostring(app.highestThisRound.iceCubes) .. ' CUBES x GLASS ' .. tostring(app.highestThisRound.glass) .. ' = ' ..
                    tostring(app.highestThisRound.score)
            self.data.scoreOld = app.highestThisRound.score
            self:toFront()
            self:setReferencePoint(display.CenterLeftReferencePoint)
            self.x = self.originX
        end
    end

    local self = spriteModule.spriteClass('text', 'score', nil, nil, false, 20, 14, 20, 18)
    self.data.scoreOld = nil
    self:setReferencePoint(display.CenterLeftReferencePoint)
    self.x = self.originX
    self:setRgb(255, 255, 255)
    self.size = 14
    self.data.scoreOld = nil
    appAddSprite(self, handle, moduleGroup)
end

function self:createGlowEffect()
    local function handle(self)
        if math.random(1, 1000) == 1 then self.rotationSpeed = self.rotationSpeed * -1 end
    end
    local self = spriteModule.spriteClass('rectangle', 'glowEffect', nil, 'glow', false, app.maxXHalf, app.maxYHalf, 544, 680)
    self.rotationSpeed = 1
    appAddSprite(self, handle, moduleGroup)
end

function self:createPurchaseMessage()
    local function cancelPurchase()
        app.phase:set('showScore')
    end

    appRemoveSpritesByType('menuButton')

    local purchaseText = spriteModule.spriteClass('rectangle', 'purchaseText', nil, 'purchaseText', nil, app.maxXHalf, 384, 347, 99)
    appAddSprite(purchaseText, handle, moduleGroup)

    local buttonY = 423
    app.menu:createButton(74, buttonY, 'purchaseNo', cancelPurchase, 88, 39)
    app.menu:createButton(219, buttonY, 'purchaseYes', appStartPurchase, 148, 39)

    appStopBackgroundMusic()
    store.loadProducts( {app.products[1].id}, appLoadProductsCallback )
end

function self:createGlassMessage(glassNumber, cubesThatWereNeeded)
    local glass = app.glasses[glassNumber]
    local fontSize = language.getByArray( { en = 14, de = 13 } )

    local group = spriteModule.spriteClass('group', 'glassMessage', nil, nil, nil, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    group.doDieOutsideField = false

    local glassBack = spriteModule.spriteClass('rectangle', 'glassMessage', nil, 'glass-won-back', nil, 0, 0, 320, 350)
    glassBack.doDieOutsideField = false
    glassBack.doDieOutsideField = false
    appAddSprite(glassBack, nil, moduleGroup)
    group:insert(glassBack)

    local glassImage = spriteModule.spriteClass('rectangle', 'glassMessage', nil, 'glass/' .. glass.filename, nil, 0, 0,
            app.glassSize.width, app.glassSize.height)
    appAddSprite(glassImage, nil, moduleGroup)
    group:insert(glassImage)

    local textHeader = spriteModule.spriteClass('text', 'glassMessage', nil, nil, nil, 0, -94)
    textHeader.text = language.get('congratsYouCrushed')
    textHeader.size = fontSize
    textHeader:setRgbBlack()
    textHeader:toFront()
    textHeader.doDieOutsideField = false
    appAddSprite(textHeader, nil, moduleGroup)
    group:insert(textHeader)

    local textSubHeader = spriteModule.spriteClass('text', 'glassMessage', nil, nil, nil, 0, -75)
    textSubHeader.text = language.get( 'overXCubes', { cubesThatWereNeeded = tostring(cubesThatWereNeeded) } )
    textSubHeader.size = fontSize
    textSubHeader:setRgbBlack()
    textSubHeader.doDieOutsideField = false
    appAddSprite(textSubHeader, nil, moduleGroup)
    group:insert(textSubHeader)

    local textFooter = spriteModule.spriteClass('text', 'glassMessage', nil, nil, nil, 0, 75)
    textFooter.size = fontSize
    textFooter.text = glass.title
    textFooter:setRgbBlack()
    textFooter.doDieOutsideField = false
    appAddSprite(textFooter, nil, moduleGroup)
    group:insert(textFooter)

    local textSubFooter = spriteModule.spriteClass('text', 'glassMessage', nil, nil, nil, 0, 94)
    textSubFooter.size = fontSize - 3
    textSubFooter.text = language.get( 'scoreMultiplier', {multiplier = glassNumber} )
    textSubFooter:setRgb(77, 77, 77)
    textSubFooter.doDieOutsideField = false
    appAddSprite(textSubFooter, nil, moduleGroup)
    group:insert(textSubFooter)

    local fuzzy = 8
    group.targetX = group.x + math.random(-fuzzy, fuzzy)
    group.speedX = .5 * misc.getIfChance(nil, -1, 1)
    group.targetY = group.y + math.random(-fuzzy, fuzzy)
    group.speedY = .5 * misc.getIfChance(nil, -1, 1)

    group:toFront()
    appAddSprite(group, handle, moduleGroup)

    appPlaySound('won-glass')
end

function self:createPriceText(price)
    if app.phase.name == 'showGlasWon' or appGetSpriteCountByType('menuPage', 'unlockStorage') >= 1 then
        appRemoveSpritesByType('price')
        local self = spriteModule.spriteClass('text', 'price', nil, nil, false, 20, 14, 20, 18)
        if app.phase.name == 'showGlasWon' then
            self.x = 220; self.y = 458
            self:setRgb(0, 25, 6)
        else
            self.x = app.maxXHalf; self.y = 229
            self:setRgb(0, 25, 6)
            self.alpha = .7
        end
        self.size = 16
        self.text = price
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createMessageImage(imageName, x, y, width, height, shakeSpeedX, shakeSpeedY, doFadeIn, doFadeOut, framesBeforeFadeOut, doPushIntoBorders)
    local function handle(self)
        if self.phase.name == 'remove' then
            if not self.phase:isInited() then
                self.energySpeed = -5
            end
        end
    end

    local subtype = imageName
    if appGetSpriteCountByType('message', subtype) == 0 then
        if doFadeIn == nil then doFadeIn = false end
        if doFadeOut == nil then doFadeOut = true end
        if doPushIntoBorders == nil then doPushIntoBorders = true end

        local self = spriteModule.spriteClass('rectangle', 'message', subtype, imageName, false, x, y, width, height)
        if doFadeIn then
            self.energy = 1
            self.energySpeed = 5
            self.alphaChangesWithEnergy = true
        end

        if doFadeOut then
            if framesBeforeFadeOut == nil then framesBeforeFadeOut = 200 end
            self.phase:set('default', framesBeforeFadeOut, 'remove')
            self.alphaChangesWithEnergy = true
        end

        if doPushIntoBorders then self:pushIntoAppBorders() end

        if shakeSpeedX ~= nil or shakeSpeedY ~= nil then
            local fuzzy = 8
            if shakeSpeedX ~= nil then
                self.targetX = self.x + math.random(-fuzzy, fuzzy)
                self.speedX = shakeSpeedX * misc.getIfChance(nil, -1, 1)
            end
            if shakeSpeedY ~= nil then
                self.targetY = self.y + math.random(-fuzzy, fuzzy)
                self.speedY = shakeSpeedY * misc.getIfChance(nil, -1, 1)
            end
        end
        self.doDieOutsideField = false
        self:toFront()
        appAddSprite(self, handle, moduleGroup)
    end
end

return self
end