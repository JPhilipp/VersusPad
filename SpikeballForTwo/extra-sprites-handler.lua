module(..., package.seeall)
local moduleGroup = 'extra'

function extraSpritesHandlerClass()
local self = {}

function self:createExtraSelectionDialog()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appResumeGame()
            if self.id == 'cancel' then
                app.extra:doEnd()
            else
                app.extra:doStart( math.random(1, app.playerMax), self.id )
            end
            appRemoveSpritesByGroup('menu')
        end
    end

    local back = spriteModule.spriteClass('rectangle', 'extraButtonsDialog', nil, nil, false, 140, app.maxY / 2, 240, app.maxY - 90)
    back:setRgb(9, 63, 86, 150)
    back:setFillColorBySelf()
    appAddSprite(back, nil, 'menu')

    local ySpacing = 37
    local yStart = 80
    local i = 0
    for name, title in orderedPairs(app.extra.titles) do
        i = i + 1
        local self = spriteModule.spriteClass('text', 'extraButton', nil, nil, false, 140, yStart + (i - 1) * ySpacing)
        self.id = name
        self.listenToTouch = true
        self.text = i .. '. ' .. title
        self.size = 17
        appAddSprite(self, handle, 'menu')
    end

    i = i + 1 
    local self = spriteModule.spriteClass('text', 'extraButton', nil, nil, false, 140, yStart + (i - 1) * ySpacing)
    self.id = 'cancel'
    self.listenToTouch = true
    self.text = '[ x ]'
    self.size = 17
    appAddSprite(self, handle, 'menu')
end

function self:createDiamond(x, y, isSensor, doMirrorXY)
    local function handle(self)
        if self.collisionWith ~= nil and self.collisionWith.type == 'wormPart' and self.collisionWith.subtype == 'head' and
                self.collisionWith.phase.name ~= 'poisoned' then
            app.extra.playerScore[self.collisionWith.parentPlayer] = app.extra.playerScore[self.collisionWith.parentPlayer] + 1
            self.gone = true

            if misc.inArray( {'collectMania', 'rooms'}, app.extra.name ) then
                local label = appGetSpriteById('extraCounter' .. self.collisionWith.parentPlayer)
                if label ~= nil then label.text = app.extra.playerScore[self.collisionWith.parentPlayer] end
            end

            appPlaySound('collect-item.mp3')
            if appGetSpriteCountByType('diamond') == 0 then
                if app.extra.name == 'training' then
                    local timeNowInSeconds = appGetTimeInSeconds()
                    local secondsThisExtraRan = timeNowInSeconds - app.extra.timeLastStartedOrEndedSeconds
                    app.extra.timeLastStartedOrEndedSeconds = timeNowInSeconds
                    app.spritesHandler:createAnnouncement(app.extra.playerWhoCollected, 'trainingAnnouncement', secondsThisExtraRan .. ' SECONDS')
                    appPlaySound('winner.mp3')
                else
                    app.extra:doEnd()
                end
            end
        end
    end

    if doMirrorXY == nil then doMirrorXY = false end
    if isSensor == nil then isSensor = true end
    local width = 42
    local height = 51
    local shape = {21, 2,
            39, 24,
            21, 46,
            2, 24}
    local self = spriteModule.spriteClass('rectangle', 'diamond', nil, 'extra/diamond', true, x, y, width, height,
            nil, shape, nil, isSensor)
    self.emphasizeAppearance = misc.getChance(35)
    self.emphasizeDisappearance = true
    if doMirrorXY then self:mirrorXY(false) end
    if isSensor then
        self.listenToCollision = true
    else
        self.linearDamping = .6
        self.listenToPostCollision = true
    end
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createTrainingWalls()
    appRemoveSpritesByType('mazeWall')
    self:createFieldWall(258, 133, 'short', 'horizontal')
    self:createFieldWall(361, 133, 'short', 'horizontal')
    self:createFieldWall(349, 147, 'long', 'vertical')
    self:createFieldWall(182, 302, 'long', 'horizontal')
    self:createFieldWall(464, 134, 'short', 'vertical')
    self:createFieldWall(464, 228, 'long', 'vertical')
    self:createFieldWall(312, 395, 'long', 'horizontal')
    self:createFieldWall(471, 220, 'short', 'horizontal')
    self:createFieldWall(572, 225, 'long', 'vertical')
    self:createFieldWall(580, 379, 'long', 'horizontal')

    self:createFieldWall(106, 402, 'short', 'horizontal')
    self:createFieldWall(107, 415, 'long', 'vertical')
    self:createFieldWall(107, 583, 'short', 'horizontal', nil, false)
    self:createFieldWall(210, 582, 'long', 'vertical', nil, false)

    self:createFieldWall(215, 490, 'short', 'horizontal')
    self:createFieldWall(319, 490, 'long', 'horizontal', true)
    self:createFieldWall(487, 490, 'long', 'horizontal')
    self:createFieldWall(324, 505, 'long', 'vertical')
    self:createFieldWall(324, 673, 'long', 'vertical')

    self:createFieldWall(438, 584, 'long', 'vertical')
    self:createFieldWall(438, 752, 'long', 'vertical')
    self:createFieldWall(453, 854, 'short', 'horizontal')
    self:createFieldWall(542, 586, 'long', 'vertical')
    self:createFieldWall(542, 753, 'short', 'vertical')
    self:createFieldWall(550, 743, 'short', 'horizontal')
    self:createFieldWall(649, 589, 'long', 'vertical')
    self:createFieldWall(649, 586, 'short', 'horizontal')
end

function self:createTrainingDiamonds()
    appRemoveSpritesByType('diamond')

    local doMirrorXY = app.extra.playerWhoCollected == 2
    self:createDiamond(58, 503, nil, doMirrorXY)
    self:createDiamond(304, 193, nil, doMirrorXY)
    self:createDiamond(413, 193, nil, doMirrorXY)
    self:createDiamond(525, 285, nil, doMirrorXY)
    self:createDiamond(274, 450, nil, doMirrorXY)
    self:createDiamond(525, 444, nil, doMirrorXY)
    self:createDiamond(165, 503, nil, doMirrorXY)
    self:createDiamond(274, 547, nil, doMirrorXY)
    self:createDiamond(702, 495, nil, doMirrorXY)
    self:createDiamond(274, 696, nil, doMirrorXY)
    self:createDiamond(390, 696, nil, doMirrorXY)
    self:createDiamond(603, 696, nil, doMirrorXY)
    self:createDiamond(499, 806, nil, doMirrorXY)
end

function self:putWormInStartingPosition(sprite)
    sprite:resetSpin()
    sprite.x = 165
    sprite.y = 649
    if app.extra.name == 'rooms' then sprite.y = 793 end
    sprite.rotation = 225
    sprite.targetRotation = nil
    if sprite.parentPlayer == 2 then sprite:mirrorXY() end
end

function self:createFieldWall(x, y, shortOrLong, horizontalOrVertical, optionalDoesRotate, optionalHasSpikes, optionalBoundary)
    local function handle(self)
        if self.collisionWith ~= nil and self.collisionWith.type == 'wormPart' and self.collisionWith.subtype == 'head' and self.subtype == 'default' then
            app.extra.spritesHandler:putWormInStartingPosition(self.collisionWith)
            app.spritesHandler:createEmphasizeAppearanceEffect(self.collisionWith.x, self.collisionWith.y)
            appResetWormTail(self.collisionWith.parentPlayer, self.collisionWith.x, self.collisionWith.y)
            appPlaySound('wall-collision')
            if app.extra.name == 'training' then
                app.extra.spritesHandler:createTrainingDiamonds()
                app.extra.timeLastStartedOrEndedSeconds = nil
            end
        end
        if self.data.boundary ~= nil then self:bounceOffBoundary(self.data.boundary) end
    end

    if shortOrLong == 's' then shortOrLong = 'short'
    elseif shortOrLong == 'l' then shortOrLong = 'long'
    end
    if horizontalOrVertical == 'h' then horizontalOrVertical = 'horizontal'
    elseif horizontalOrVertical == 'v' then horizontalOrVertical = 'vertical'
    end

    if optionalDoesRotate == nil then optionalDoesRotate = false end
    if optionalHasSpikes == nil then optionalHasSpikes = true end

    local width = 104
    local height = 26
    if shortOrLong == 'long' then width = 168 end

    local spikeLength = 6
    if horizontalOrVertical == 'horizontal' then
        y = y - spikeLength
    else
        x = x - spikeLength
        local temp = width
        width = height
        height = temp
    end

    local filename = 'extra/field-wall/' .. shortOrLong .. '-' .. horizontalOrVertical
    local shape = nil
    if horizontalOrVertical == 'horizontal' then
        shape = {0, 6,
                width, 6,
                width, 19,
                0, 19}
    else
        shape = {6, 0,
                19, 0,
                19, height,
                6, height}
    end

    local subtype = 'default'
    if not optionalHasSpikes then
        subtype = 'spikeless'
        filename = filename .. '-spikeless'
    end
    
    local self = spriteModule.spriteClass('rectangle', 'mazeWall', subtype, filename, true, x + width / 2, y + height / 2, width, height,
            nil, shape)
    self.emphasizeAppearance = misc.getChance(10)
    self.emphasizeDisappearance = self.emphasizeAppearance
    self.bodyType = 'static'
    self.listenToPostCollision = true
    self:setPosFromLeftTop(x, y)
    if app.extra.playerWhoCollected == 2 and app.extra.name == 'training' then self:mirrorXY() end
    if optionalDoesRotate then self.rotationSpeed = 1.25 end

    self.data.boundary = optionalBoundary
    if self.data.boundary ~= nil then
        self.speedLimit = 3
        self.speedX = 0
        self.speedY = 0
        if self.data.boundary.x1 ~= nil then self.speedX = misc.getIf(self.y < app.maxY / 2, -self.speedLimit, self.speedLimit) end
        if self.data.boundary.y1 ~= nil then self.speedY = misc.getIf(self.x < app.maxX / 2, -self.speedLimit, self.speedLimit) end
    end
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createExtraPill()
    local function handle(self)
        if not self.inited then
            self.data.startTimeSeconds = appGetTimeInSeconds()
        end

        if self.collisionWith ~= nil and self.collisionWith.type == 'wormPart' and self.collisionWith.subtype == 'head' then
            app.extra:doStart(self.collisionWith.parentPlayer)
            self.gone = true
        end

        if not self.gone then
            local secondsAge = appGetTimeInSeconds() - self.data.startTimeSeconds

            if self.phase.name == 'default' then
                if secondsAge > 5 then
                    self.phase:set('autoExplosionCountdown', 125, 'autoExplode')
                end

            elseif self.phase.name == 'autoExplosionCountdown' then
                if not self.phase:isInited() then
                    self.targetX = self.x - 4
                    self.targetY = self.y + 7
                    self.speedLimit = 7
                    self.doFollowTarget = true
                end
                local color = {red = 244, green = 235, blue = 51}
                if misc.getChance(30) then app.spritesHandler:createSparks(self.x, self.y, nil, nil, nil, nil, color ) end

            elseif self.phase.name == 'autoExplode' then
                self.emphasizeDisappearance = true
                app.extra:doStart( math.random(1, app.playerMax) )
                self.gone = true
            end
        end
    end

    local marginX = 135
    local marginY = 267
    local x = math.random(app.minX + marginX, app.maxX - marginX)
    local y = math.random(app.minY + marginY, app.maxY - marginY)
    local isSensor = true
    local self = spriteModule.spriteClass('rectangle', 'extraPill', nil, 'extra/pill', true, x, y, 35, 35,
            nil, nil, nil, isSensor)
    self.emphasizeAppearance = true
    self.rotationSpeed = 4
    self.listenToCollision = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createIcon(name, titles, iconShowsOnlyFor)
    for playerI = 1, app.playerMax do
        local isSelf = app.extra.playerWhoCollected == playerI
        if iconShowsOnlyFor[name] == nil or (iconShowsOnlyFor[name] == 'self' and isSelf) or (iconShowsOnlyFor[name] == 'other' and not isSelf) then
            local width = 155
            local x = width / 2
            local y = 856
            local labelX = x
            local labelY = y + 64 + misc.getIf(app.isAndroid, -1, 0)

            if playerI == 2 then
                x = app.maxX - x
                y = app.maxY - y
                labelX = app.maxX - labelX
                labelY = app.maxY - labelY
            end

            if app.leftHandedControl[playerI] then
                labelX = app.maxX - labelX
                x = app.maxX - x
            end

            local self = spriteModule.spriteClass('rectangle', 'extraIcon', nil, 'extra/icon/' .. name, false, x, y, width, 147)
            if playerI == 2 then self.rotation = 180 end
            self.parentPlayer = playerI
            self.energy = 10
            self.energySpeed = 2
            self.alphaChangesWithEnergy = true
            self.emphasizeAppearance = true
            self.emphasizeDisappearance = true
            appAddSprite(self, handle, moduleGroup, handleWhenGone)

            local label = spriteModule.spriteClass('text', 'iconText', nil, nil, nil, labelX, labelY)
            label.parentId = self.id
            label.parentPlayer = playerI
            label.text = titles[name]
            if playerI == 2 then
                label.rotation = 180
            end
            label:setRgbWhite()
            label.energy = 10
            label.energySpeed = 2
            label.alphaChangesWithEnergy = true
            appAddSprite(label, handle, moduleGroup)
        end
    end
end

function self:createBoxes()
    local margin = 180
    for xGrid = -1, 1 do
        for yGrid = -1, 1 do
            local x = app.maxX / 2 + xGrid * margin
            local y = app.maxY / 2 + yGrid * margin
            local self = spriteModule.spriteClass('rectangle', 'box', nil, 'extra/box', true, x, y, 44, 44)
            self.emphasizeAppearance = true
            self.emphasizeDisappearance = true
            appAddSprite(self, handle, moduleGroup, handleWhenGone)
        end
    end
end

function self:createRowCollectible(playerI, number)
    local function handle(self)
        if self.collisionWith ~= nil and self.collisionWith.type == 'wormPart' and self.collisionWith.subtype == 'head' and
                self.collisionWith.phase.name ~= 'poisoned' then
            if self.data.isCollectibleNow and self.parentPlayer == self.collisionWith.parentPlayer then
                self.gone = true
                appPlaySound('collect-item.mp3')

                local nextNumber = self.data.number + 1
                local nextCollectible = appGetSpriteById('collectible-' .. self.parentPlayer .. '-' .. nextNumber)
                if nextCollectible ~= nil then
                    nextCollectible.data.isCollectibleNow = true
                    nextCollectible.phase:set('shake')
                else
                    appGoalScored( misc.getIf(self.parentPlayer == 1, 2, 1) )
                    app.extra:doEnd()
                end
            end
        end

        if self.phase.name == 'shake' then
            if not self.phase:isInited() then
                self.data.isCollectibleNowInited = true
                self.targetX = self.x - 2
                self.targetY = self.y + 3
                self.speedLimit = 3
                self.doFollowTarget = true
            end
        end
    end

    local marginX = 120
    local marginY = 260
    local width = 50
    local height = 55
    local x = nil
    local y = nil

    local n = 1
    -- below doesn't work, why?!
    local hasSpriteNearby = true
    while hasSpriteNearby do
        x = math.random(app.minX + marginX, app.maxX - marginX)
        y = math.random(app.minY + marginY, app.maxY - marginY)
        hasSpriteNearby = appHasSpriteNearby('collectible', x, y, 120)

        n = n + 1
        if n >= 1000 then
            appDebug('broken')
            break
        end
    end

    local filename = 'extra/rowCollectible/' .. playerI .. '-' .. number
    local shape = {25, 5,
            44, 27,
            25, 48,
            5, 27}
    local isSensor = true
    local self = spriteModule.spriteClass('rectangle', 'collectible', nil, filename, true, x, y, width, height,
            nil, shape, playerI, isSensor)
    self.id = 'collectible-' .. self.parentPlayer .. '-' .. number
    self.emphasizeAppearance = true
    self.emphasizeDisappearance = true
    self.listenToCollision = true
    self.parentPlayer = playerI
    self.data.number = number
    self.data.isCollectibleNow = number == 1
    if misc.getChance(50) then self:toFront() end
    if self.data.isCollectibleNow then self.phase:set('shake') end
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createJail()
    local jailFloor = spriteModule.spriteClass('rectangle', 'jailFloor', nil, 'extra/jail-floor', false, app.maxX / 2, app.maxY / 2, 315, 258)
    jailFloor:toBack()
    appAddSprite(jailFloor, handle, moduleGroup, handleWhenGone)
    appPutBackgroundToBack()

    local jailRoof = spriteModule.spriteClass('rectangle', 'jailRoof', nil, 'extra/jail-roof', false, app.maxX / 2, app.maxY / 2, 247, 204)
    jailRoof.emphasizeAppearance = true
    jailRoof.emphasizeDisappearance = true
    jailRoof:toFront()
    appAddSprite(jailRoof, handle, moduleGroup, handleWhenGone)

    local rectangles = {
            {246, 395, 526, 402},
            {246, 402, 253, 608},
            {519, 402, 526, 608},
            {246, 608, 526, 615}
            }
    for rectangleI = 1, #rectangles do
        local x1 = rectangles[rectangleI][1]
        local y1 = rectangles[rectangleI][2] + 8
        local x2 = rectangles[rectangleI][3]
        local y2 = rectangles[rectangleI][4] + 8
        local self = spriteModule.spriteClass('rectangle', 'wall', 'jailWall', nil, true, x1, x2, x2 - x1, y2 - y1)
        self.bodyType = 'static'
        self:setPosFromLeftTop(x1, y1, width, height)
        self.isHitTestable = true
        self.isVisible = false
        appAddSprite(self, handle, moduleGroup, handleWhenGone)
    end
end

function self:createMazeWall(x1, y1, x2, y2)
    local function handle(self)
        if self.collisionWith ~= nil and self.collisionWith.type == 'wormPart' and self.collisionWith.subtype == 'head' then
            self.collisionWith:resetSpin()
            self.collisionWith.x = 80
            self.collisionWith.y = 609
            if self.collisionWith.parentPlayer == 2 then
                self.collisionWith.x = app.maxX - self.collisionWith.x
                self.collisionWith.y = app.maxY - self.collisionWith.y
            end
            app.spritesHandler:createEmphasizeAppearanceEffect(self.collisionWith.x, self.collisionWith.y)
            appResetWormTail(self.collisionWith.parentPlayer, self.collisionWith.x, self.collisionWith.y)
            appPlaySound('wall-collision')
        end
    end

    local temp = nil
    if x1 > x2 then temp = x1; x1 = x2; x2 = temp; end
    if y1 > y2 then temp = y1; y1 = y2; y2 = temp; end

    local isSensor = true
    local width = x2 - x1
    local height = y2 - y1

    local self = spriteModule.spriteClass('rectangle', 'mazeWall', nil, nil, true, x1, y1, width, height)
    self:setPosFromLeftTop(x1, y1, width, height)
    self.bodyType = 'static'
    self.isHitTestable = true
    self.listenToPostCollision = true
    self.isVisible = false
    self:toFront()
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createCannons()
    local function handle(self)
        -- periodically shoot bullets here...
        if self.phase.name == 'default' then
            if not self.phase:isInited() then
                self.phase.nameNext = 'shoot'
                self.phase.counter = 75 * (5 + 1)
            end
        elseif self.phase.name == 'shoot' then
            if not self.phase:isInited() then
                self.phase.nameNext = 'default'
                self.phase.counter = 1
                app.extra.spritesHandler:createBullet(self.x, self.y, self.rotation)
                self:toFront()
                appPlaySound('shoot.mp3')
            end
        end
    end

    local coords = {
        {5, app.maxY / 2, 0},
        {169 / 2, 550 / 2, 45},
        {app.maxX - 169 / 2, 550 / 2, 135},
        {app.maxX - 5, app.maxY / 2, 180},
        {app.maxX - 169 / 2, app.maxY - 550 / 2, 225},
        {169 / 2, app.maxY - 550 / 2, 315}
    }
    for i = 1, #coords do
        local x = coords[i][1]
        local y = coords[i][2]
        local rotation = coords[i][3]
        local self = spriteModule.spriteClass('rectangle', 'cannon', nil, 'extra/cannon', false, x, y, 141, 54)
        self.emphasizeAppearance = true
        self.emphasizeDisappearance = true
        self.rotation = rotation
        self.phase:set('default', i * 75, 'shoot')
        self.phase.inited = true
        appAddSprite(self, handle, moduleGroup, handleWhenGone)
    end
end

function self:createBullet(x, y, rotation)
    local function handle(self)
        if self.collisionWith ~= nil then
            if self.collisionWith.phase.name ~= 'justRecoveredFromPoison' then
                self.collisionWith.phase:set('poisoned', app.timeFramesToPoisonShort, 'justRecoveredFromPoison')
            end
            if self.phase.name == 'default' then self.gone = true end
        end
    end

    local isSensor = true
    local self = spriteModule.spriteClass('rectangle', 'bullet', nil, 'extra/bullet', true, x, y, 25, 25,
            nil, nil, nil, isSensor)
    self.rotation = rotation
    self.speedLimit = 24
    self.listenToCollision = true
    self.isBullet = true
    self:adjustSpeedToRotation()
    self.emphasizeAppearance = true
    self.phase:set('protectedLaunch', 50, 'default')
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createConfusion()
    local function handle(self)
        local radiusMax = 70

        if misc.getChance(80) then self:adjustRadius(self.data.radiusSpeed) end
        if self.radius <= 20 then
            self.data.radiusSpeed = self.data.radiusSpeedLimit
        elseif self.radius >= radiusMax then
            self.data.radiusSpeed = -self.data.radiusSpeedLimit
        end

        if self.data.rotateColors and misc.getChance(10) then
            local colorSpeedLimit = 15
            self.green = self.green + math.random(-colorSpeedLimit, colorSpeedLimit)
            self.blue = self.blue + math.random(-colorSpeedLimit, colorSpeedLimit)
            self:pushRgbIntoLimits()
            self:setFillColorBySelf()
        end
    end

    local marginX = 120
    local marginY = 150
    for i = 1, 14 do
        local x = math.random(app.minX + marginX, app.maxX - marginX)
        local y = math.random(app.minY + marginY, app.maxY - marginY)
        local self = spriteModule.spriteClass( 'circle', 'confusion', nil, nil, false, x, y, math.random(5, 30) )
        self.emphasizeAppearance = i <= 5
        self.emphasizeDisappearance = self.emphasizeAppearance
        self.data.radiusSpeed = 5

        self.data.rotateColors = misc.getChance(60)
        if self.data.rotateColors then
            self:setRgbRandom()
            self.red = math.random(200, 255)
        else
            self:setRgbWhite()
        end
        self:setFillColorBySelf()

        self.data.radiusSpeedLimit = math.random(1, 5)
        self.alpha = .8
        self:toFront()

        local offset = 180
        self.targetX = x + math.random(-offset, offset)
        self.targetY = y + math.random(-offset, offset)
        self.doFollowTarget = true
        self.doDieOutsideField = false

        appAddSprite(self, handle, moduleGroup, handleWhenGone)
    end
end

function self:createSpikes()
    local marginX = 168
    local marginY = 150
    for xGrid = -1, 1, 2 do
        for yGrid = -1, 1, 2 do
            local x = app.maxX / 2 + xGrid * marginX
            local y = app.maxY / 2 + yGrid * marginY
            local self = spriteModule.spriteClass('rectangle', 'spike', nil, 'extra/spike', true, x, y, 60, 90)
            self.emphasizeAppearance = true
            self.emphasizeDisappearance = true

            local offset = 4
            self.targetX = self.x + math.random(-offset, offset)
            self.targetY = self.y + math.random(-offset, offset)

            appAddSprite(self, handle, moduleGroup, handleWhenGone)
        end
    end
end

function self:createExtraCounters(optionalOnlyForPlayerWhoCollected)
    if optionalOnlyForPlayerWhoCollected == nil then optionalOnlyForPlayerWhoCollected = false end

    for playerI = 1, app.playerMax do
        if app.extra.playerWhoCollected == playerI or not optionalOnlyForPlayerWhoCollected then
            local x = 78
            local y = 850
            if playerI == 2 then
                x = app.maxX - x
                y = app.maxY - y
            end
            if app.leftHandedControl[playerI] then x = app.maxX - x end
            local self = spriteModule.spriteClass('text', 'extraCounter', nil, nil, false, x, y)
            self.parentPlayer = playerI
            self.id = 'extraCounter' .. playerI
            self.text = '0'
            self.size = 25
            if playerI == 2 then self.rotation = 180 end
            appAddSprite(self, handle, moduleGroup, handleWhenGone)
        end
    end
end

function self:createHunter()
    local function handle(self)
        if self.targetSprite ~= nil and self.targetSprite.phase ~= nil then
            if self.targetSprite.phase.name == 'default' or self.targetSprite.phase.name == 'boost' then
                self:directTowardsTargetSprite()
                self.doFollowTarget = true
            else
                app.extra:doEnd()
            end
        end
    end

    local self = spriteModule.spriteClass('rectangle', 'hunter', nil, 'extra/hunter', true, app.maxX / 2, app.maxY / 2, 118, 59)
    self.emphasizeAppearance = true
    self.emphasizeDisappearance = true
    local targetPlayerI = misc.getIf(app.extra.playerWhoCollected == 1, 2, 1)
    self.targetSprite = appGetSpriteByType('wormPart', 'head', targetPlayerI)
    self.speedLimit = 2.5
    self.speedLimitX = self.speedLimit
    self.speedLimitY = self.speedLimit
    self.speedStep = .5
    self.isBullet = true
    appAddSprite(self, handle, moduleGroup, handleWhenGone)
end

function self:createFakeBalls()
    local function handle(self)
        if misc.getChance(10) and self.energySpeed == 0 then app.spritesHandler:createSparks(self.x, self.y, 1) end
    end

    local function handleWhenGone(self)
        app.extra:doEnd()
    end

    local gridOffset = 1
    local maxGridPositions = (gridOffset * 2 + 1) * (gridOffset * 2 + 1)
    local randomRealBallGridPosition = math.random(1, maxGridPositions)
    local i = 0
    local marginX = 165
    local marginY = 150

    for xGrid = -gridOffset, gridOffset do
        for yGrid = -gridOffset, gridOffset do
            i = i + 1
            local x = app.maxX / 2 + xGrid * marginX
            local y = app.maxY / 2 + yGrid * marginY

            if i == randomRealBallGridPosition then
                local realBall = appGetSpriteByType('ball')
                if realBall ~= nil then
                    realBall.x = x
                    realBall.y = y
                    realBall:resetSpin()
                    realBall:stop()
                    app.spritesHandler:createEmphasizeAppearanceEffect(realBall.x, realBall.y)
                end
            else
                local self = spriteModule.spriteClass('circle', 'fakeBall', nil, nil, true, x, y, 13)
                self.phase:set('positionAtStart')
                self:setRgb(255, 0, 255, 50)
                self:setFillColorBySelf()
                self.isHitTestable = true
                self.isVisible = false
                self.emphasizeAppearance = true
                self.handle = handle
                self.bodyType = 'static'
                appAddSprite(self, handle, moduleGroup, handleWhenGone)
            
                local glow = spriteModule.spriteClass( 'rectangle', 'fakeBall', 'glow', 'ball-and-glow', false, self.x, self.y, 62, 62)
                glow.parentId = self.id
                glow.movesWithParent = true
                glow.disappearsWithParent = true
                glow.alphaChangesWithEnergy = true
                appAddSprite(glow, nil, moduleGroup)
            end
        end
    end
end

function self:createMovingWalls()
    local function handle(self)
        if self.collisionWith ~= nil and self.collisionWith.type == 'wall' then
            if self.collisionWith.x < self.x then
                self.speedX = self.speedLimit
            else
                self.speedX = -self.speedLimit
            end
        end
        self.y = self.data.originalY
    end

    local marginX = 220
    local marginY = 140
    for i = -1, 1, 2 do
        local x = app.maxX / 2 + i * marginX
        local y = app.maxY / 2 + i * marginY
        local self = spriteModule.spriteClass('rectangle', 'movingWall', nil, 'extra/movingWall', true, x, y, 220, 20)
        self.speedLimit = 3
        self.speedX = self.speedLimit
        self.listenToPostCollision = true
        self.isFixedRotation = true
        self.linearDamping = 1000
        self.data.originalY = self.y
        appAddSprite(self, handle, moduleGroup, handleWhenGone)
    end
end

function self:createCover()
    local self = spriteModule.spriteClass('rectangle', 'cover', nil, 'extra/cover', false, app.maxX / 2, app.maxY / 2, 513, 393)
    self.emphasizeAppearance = true
    self.emphasizeDisappearance = true
    appAddSprite(self, handle, moduleGroup, handleWhenGone)

    local glow = spriteModule.spriteClass('rectangle', 'coverGlow', nil, 'extra/cover-glow', false, app.maxX / 2, app.maxY / 2, 584, 464)
    glow:toBack()
    appAddSprite(glow, handle, moduleGroup, handleWhenGone)

    appPutBackgroundToBack()
end

function self:createMagnet()
    local function handle(self)
        if self.targetSprite ~= nil then self.targetSprite:magneticTowards(self.x, self.y) end
    end

    local self = spriteModule.spriteClass('rectangle', 'magnet', nil, 'extra/magnet', false, app.maxX / 2, app.maxY / 2, 197, 214)
    self.emphasizeAppearance = true
    self.emphasizeDisappearance = true
    self:toBack()
    self.targetSprite = appGetSpriteByType('ball')
    self.doFollowTarget = false
    appAddSprite(self, handle, moduleGroup, handleWhenGone)

    appPutBackgroundToBack()
end

function self:createBigWheel(xOffset)
    local function handle(self)
        self.x = self.data.originalX
        self.y = self.data.originalY
    end

    local lastSelf = nil
    for i = 1, 2 do
        local self = spriteModule.spriteClass('rectangle', 'wheel', nil, 'extra/wheel', true, app.maxX / 2 - xOffset, app.maxY / 2,  574, 41)
        self.emphasizeAppearance = true
        self.emphasizeDisappearance = true
        self.rotation = 45
        self.data.originalX = self.x
        self.data.originalY = self.y
        if i == 2 then self.rotation = 135 end
        appAddSprite(self, handle, moduleGroup, handleWhenGone)

        if lastSelf ~= nil then
            local joint = physics.newJoint('weld', self, lastSelf, self.x, self.y)
            appAddJoint(joint)
        end
        lastSelf = self
    end
end

return self
end