module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createRoom()
    local map, roofHeight, groundHeight, backgroundImage, backgroundIsAnimated = appGetRandomRoomMap()
    map = appUniteAdjacentFloorsAndWalls(map)

    app.spritesHandler:createBackground(backgroundImage, backgroundIsAnimated)
    app.spritesHandler:createRoofAndGround(roofHeight, groundHeight)

    local gridPlaceMaxX = #map
    local gridPlaceMaxY = #map[1]

    for gridX = 1, #map do
        for gridY = 1, #map[gridX] do
            local part = map[gridX][gridY]
            local centerPoint = {x = part.x + part.width / 2, y = part.y + part.height / 2}

            if part.backgroundItem == 'window' then app.spritesHandler:createWindow(centerPoint)
            elseif part.backgroundItem == 'breakingWindow' then app.spritesHandler:createWindow(centerPoint, true)
            end

            local wallOffsetY = -3
            if part.hasWallLeft then
                app.spritesHandler:createWall( {x = part.x + app.wallWidth / 2, y = part.y + wallOffsetY}, part.wallLengthLeft, gridY )
            end
            if part.hasWallRight then
                app.spritesHandler:createWall( {x = part.x + part.width - app.wallWidth / 2, y = part.y + wallOffsetY}, part.wallLengthRight, gridY )
            end

            local lowestPoint = {x = part.x + part.width / 2, y = part.y + part.height - app.floorHeight}
            if part.hasBlock then lowestPoint.y = lowestPoint.y - app.blockHeight end
            local highestPoint = {x = part.x + part.width / 2, y = part.y - 2}

            local items = misc.toTable(part.item)
            for i = 1, #items do
                local item = items[i]
                if item == 'vases' then
                    app.spritesHandler:createStackedVases(lowestPoint)
    
                elseif item == 'table' then
                    local plateTop = app.spritesHandler:createTable(lowestPoint)

                elseif item == 'tableLong' then
                    local plateTop = app.spritesHandler:createTable(lowestPoint, true)

                elseif item == 'tableHighLong' then
                    local plateTop = app.spritesHandler:createTable(lowestPoint, true, true, false, false)
    
                elseif item == 'tableWithVases' then
                    local plateTop = app.spritesHandler:createTable(lowestPoint)
                    app.spritesHandler:createStackedVases( {x = lowestPoint.x, y = plateTop} )
    
                elseif item == 'highTableWithVases' then
                    local plateTop = app.spritesHandler:createTable(lowestPoint)
                    plateTop = app.spritesHandler:createTable({x = lowestPoint.x, y = plateTop} )
                    app.spritesHandler:createStackedVases( {x = lowestPoint.x, y = plateTop}, 1 )

                elseif item == 'highTableWithVasesAndBladeBlocks' then
                    app.spritesHandler:createStackedVasesWithBladeBlocks( {x = app.maxXHalf, y = lowestPoint.y} )

                elseif item == 'smallWallRight' then
                    app.spritesHandler:createSmallWall( {x = part.x + part.width - app.wallWidth / 2, y = lowestPoint.y } )

                elseif item == 'stackedBladeBlocksWithVase' then
                    app.spritesHandler:createStackedBladeBlocksWithVase(lowestPoint)
    
                elseif item == 'sectorArrowUp' then
                    app.spritesHandler:createSectorArrow(nil, highestPoint, 'up', 'topTunnel')
                elseif item == 'sectorArrowDown' then
                    app.spritesHandler:createSectorArrow(lowestPoint, nil, 'down', 'water')
                elseif item == 'sectorArrowDownFromTopTunnel' then
                    app.spritesHandler:createSectorArrow(lowestPoint, nil, 'down', 'default')
                elseif item == 'sectorArrowUpFromWater' then
                    app.spritesHandler:createSectorArrow(nil, highestPoint, 'up', 'default')

                elseif misc.inArray( {'fallDoor', 'fallDoorLeft', 'fallDoorRight', 'fallBlade', 'fallBladeLeft', 'fallBladeRight'}, item ) then
                    local fallThingPoint = highestPoint
                    if item == 'fallDoorLeft' or item == 'fallBladeLeft' then
                        fallThingPoint.x = part.x + app.fallThingWidth / 2 + 2
                    elseif item == 'fallDoorRight' or item == 'fallBladeRight' then
                        fallThingPoint.x = part.x + part.width - app.fallThingWidth / 2 - 2
                    end
                    local isDoor = misc.inArray( {'fallDoor', 'fallDoorLeft', 'fallDoorRight'}, item )
                    app.spritesHandler:createFallThing( misc.getIf(isDoor, 'fallDoor', 'fallBlade'), fallThingPoint )

                elseif item == 'cannonTowardsLeft' then app.spritesHandler:createCannon(lowestPoint, -1)
                elseif item == 'cannonTowardsRight' then app.spritesHandler:createCannon(lowestPoint, 1)

                elseif item == 'guard' then app.spritesHandler:createGuard(lowestPoint)
                elseif item == 'diamond' then app.spritesHandler:createDiamonds(lowestPoint)
                elseif item == 'diamonds' then app.spritesHandler:createDiamonds(lowestPoint, 2)
                elseif item == 'bladeTop' then app.spritesHandler:createBlade(highestPoint, nil, 'top')
                elseif item == 'bladeBottom' then app.spritesHandler:createBlade(nil, lowestPoint, 'bottom')
                elseif item == 'fish' then app.spritesHandler:createFish(centerPoint)
                elseif item == 'fish-slow' then app.spritesHandler:createFish(centerPoint, true)
                elseif item == 'doorButtonOpen' then app.spritesHandler:createDoorButton('open', lowestPoint, true)
                elseif item == 'doorButtonClose' then app.spritesHandler:createDoorButton('close', lowestPoint, true)
                elseif item == 'clock' then app.spritesHandler:createClock(centerPoint)
                elseif item == 'randomItem' then app.spritesHandler:createItem(lowestPoint)
                end
            end

            if part.hasGirl then
                local lowestGirlPoint = {x = lowestPoint.x, y = lowestPoint.y - 30}
                if gridX == 1 then lowestGirlPoint.x = app.minX - app.girlWidth / 2
                elseif gridX == 2 then lowestGirlPoint.x = app.minX + 50
                else lowestGirlPoint.x = app.maxX + app.girlWidth / 2
                end
                app.spritesHandler:createGirl(lowestGirlPoint)
            end
        end
    end

    for gridX = 1, #map do
        for gridY = 1, #map[gridX] do
            local part = map[gridX][gridY]
            local centerPoint = {x = part.x + part.width / 2, y = part.y + part.height / 2}

            if part.hasFloor and not part.isGround then
                app.spritesHandler:createFloor( {x = part.x, y = part.y + part.height - app.floorHeight / 2}, part.floorLength )
            end

            if part.hasBlock then
                app.spritesHandler:createBlock(
                        { x = part.x + part.width / 2,
                          y = part.y + part.height - app.floorHeight - app.blockHeight / 2 + app.blockOffsetY + misc.getIf(gridY == 3, 2, 0) } )
            end

            local items = misc.toTable(part.item)
            for i = 1, #items do
                local item = items[i]
                if item == 'introHelp' then app.spritesHandler:createIntroHelp(centerPoint)
                elseif item == 'destroyHelp' then app.spritesHandler:createDestroyHelp(centerPoint)
                end
            end

        end
    end

    for gridX = 1, #map do
        for gridY = 1, #map[gridX] do
            local part = map[gridX][gridY]
            local lowestPoint = {x = part.x + part.width / 2, y = part.y + part.height - app.floorHeight + app.blockOffsetY}
            local items = misc.toTable(part.item)
            for i = 1, #items do
                local item = items[i]
                if item == 'spikeball' then app.spritesHandler:createSpikeball(lowestPoint)
                elseif item == 'spikeball-slow' then app.spritesHandler:createSpikeball(lowestPoint, 'slow')
                elseif item == 'spikeball-fast' then app.spritesHandler:createSpikeball(lowestPoint, 'fast')
                end
            end
        end
    end
end

function self:createStackedVases(lowestPoint, rows)
    if rows == nil then rows = 2 end
    local subtype = misc.getIfChance(75, 'silver', 'gold')
    for rowI = 1, rows do
        local point = { x = lowestPoint.x, y = lowestPoint.y - (app.vaseHeight) * (rowI - 1) - (app.vaseHeight / 2 + 1) }
        app.spritesHandler:createVase(point, subtype)
    end
end

function self:createStackedVasesWithBladeBlocks(lowestPoint)
    local min = {x = lowestPoint.x - 40, y = lowestPoint.y - 168}

    app.spritesHandler:createTableLeg( {x = min.x + 9, y = min.y + 152} )
    app.spritesHandler:createTableLeg( {x = min.x + 40, y = min.y + 152} )
    app.spritesHandler:createTableLeg( {x = min.x + 70, y = min.y + 152} )

    app.spritesHandler:createTablePlate( {x = min.x + 41, y = min.y + 126}, true, false )

    app.spritesHandler:createBladeBlock( {x = min.x + 15, y = min.y + 106} )
    app.spritesHandler:createBladeBlock( {x = min.x + 64, y = min.y + 106} )

    app.spritesHandler:createTablePlate( {x = min.x + 41, y = min.y + 86}, true, false )

    app.spritesHandler:createVase( {x = min.x + 20, y = min.y + 68}, 'gold' )
    app.spritesHandler:createVase( {x = min.x + 58, y = min.y + 68}, 'gold' )

    app.spritesHandler:createVase( {x = min.x + 20, y = min.y + 41}, 'gold' )
    app.spritesHandler:createVase( {x = min.x + 58, y = min.y + 41}, 'gold' )

    app.spritesHandler:createTablePlate( {x = min.x + 41, y = min.y + 20}, true, false )

    app.spritesHandler:createBladeBlock( {x = min.x + 39, y = min.y + 6} )
end

function self:createStackedBladeBlocksWithVase(lowestPoint)
    local vaseRowMin = math.random(3, 6)
    local vaseRowMax = vaseRowMin + 1
    for row = 1, 10 do
        local y = lowestPoint.y - app.bladeBlockHeight * row + 16
        if row >= vaseRowMin and row <= vaseRowMax then
            app.spritesHandler:createVase( {x = lowestPoint.x + 15, y = y}, 'gold' )
        elseif row ~= vaseRowMax + 1 and row ~= vaseRowMax + 2 then
            app.spritesHandler:createBladeBlock( {x = lowestPoint.x + 15, y = y}, true )
        end
    end
end

function self:createBladeBlock(point, isStatic)
    local function handle(self)
        if math.random(0, 10000) <= 10 and appGetSpriteCountByType('glow') <= 3 then app.spritesHandler:createGlow(self) end
        if app.extraPhase.name == 'slowMotion' then app.spritesHandler:createCloneImage(self, 'bladeBlock') end
    end

    if isStatic == nil then isStatic = false end
    local self = spriteModule.spriteClass('rectangle', 'bladeBlock', nil, 'bladeBlock', true, point.x, point.y, 33, app.bladeBlockHeight,
            nil, nil, nil, nil, nil, nil, nil, friction)
    if isStatic then self.bodyType = 'static' end
    appAddSprite(self, handle, moduleGroup)
end

function self:createVase(point, subtype)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] >= 2.5 then
                app.spritesHandler:createShards(self, true)
                appAddDestructionToScore(self)
                appPlaySound( 'glassBreaking-' .. math.random(1, 3) )
                local guards = appGetSpritesByType('guard')
                for i = 1, #guards do
                    local guard = guards[i]
                    local phaseName = misc.getIf(guard.x < self.x, 'shock-right', 'shock-left')
                    if phaseName ~= guard.phase.name then guard.phase:set(phaseName) end
                end
                self.gone = true
            end
        end

        if math.random(0, 10000) <= 10 and appGetSpriteCountByType('glow') <= 3 then
            app.spritesHandler:createGlow(self)
        end

        if app.extraPhase.name == 'slowMotion' then app.spritesHandler:createCloneImage(self, 'vase/' .. subtype) end
    end

    local friction = 5
    local self = spriteModule.spriteClass('rectangle', 'vase', subtype, 'vase/' .. subtype, true, point.x + 1, point.y, 24, app.vaseHeight,
            nil, nil, nil, nil, nil, density, nil, friction)
    self.rotation = app.actualPlaneRotation
    self.listenToPostCollision = true
    appAddSprite(self, handle, moduleGroup, appShowMessageIfRoomFullyCleared)
end

function self:createCloneImage(sprite, image)
    local width = sprite.width; local height = sprite.height
    if sprite.displayType == 'circle' then
        width = sprite.radius * 2
        height = width
    end

    local self = spriteModule.spriteClass('rectangle', 'cloneImage', nil, image, false, sprite.x, sprite.y, width, height)
    self.rotation = sprite.rotation
    self.energy = 65
    self.energySpeed = -2
    self.alphaChangesWithEnergy = true
    appAddSprite(self)
end

function self:createFloor(centerLeftPoint, floorLength)
    local friction = 2
    local baseWidth = 119
    local width = baseWidth * floorLength; local height = 16
    local x = centerLeftPoint.x + width / 2
    local self = spriteModule.spriteClass('rectangle', 'floor', nil, 'floor/' .. floorLength, true, x, centerLeftPoint.y, width, height,
            nil, nil, nil, nil, nil, nil, nil, friction)
    self.bodyType = 'static'
    self.rotation = app.actualPlaneRotation
    appAddSprite(self, handle, moduleGroup)
end

function self:createWindow(point, isImmediatelyBreaking)
    local function handle(self)
        if self.subtype == 'whole' then
            for i, other in pairs(self.collisionWith) do
                if other.type == 'girl' or other.type == 'bombShard' then
                    appPlaySound( 'windowBreaking-' .. math.random(1, 2) )
                    self.frameImage = 'window-broken'
                    app.spritesHandler:createShards(self)
                    appAddDestructionToScore(self)
                    self.subtype = 'broken'
                    appShowMessageIfRoomFullyCleared()
                end
            end
        end
    end

    if isImmediatelyBreaking == nil then isImmediatelyBreaking = false end
    local isSensor = true
    local self = spriteModule.spriteClass('rectangle', 'window', 'whole', nil, true, point.x, point.y, 53, 40,
            nil, nil, nil, nil, isSensor)
    self.bodyType = 'static'
    self.frameImage = 'window'
    self.frameImageZ = 'background'
    if isImmediatelyBreaking then
        self.frameImage = 'window-broken'
        for i = 1, 3 do app.spritesHandler:createShards(self) end
        self.subtype = 'broken'
    else
        self.listenToCollision = true
    end
    appAddSprite(self, handle, moduleGroup)
end

function self:createFallThing(thisType, highestPointOrPoint, phaseName)
    local function handle(self)

        local framesItTakesBeforeDown = 15
        for i, other in pairs(self.collisionWith) do
            if other.type == 'girl' then
                self.phase:setNext('moving-down', framesItTakesBeforeDown)

                local speedX, speedY = other:getLinearVelocity()
                if self.type == 'fallBlade' and (speedY <= -8 or self.phase.name == 'down') then
                    appGirlIsHit()
                end

            elseif other.type == 'spikeball' and self.type == 'fallBlade' then
                self.phase:set('moving-down', framesItTakesBeforeDown)
            end
        end

        if self.phase.name == 'moving-down' then
            if not self.phase:isInited() then
                appPlaySound('fallThingDown')
                self.phase:setNext('down', 5)
            end

        elseif self.phase.name == 'moving-up' then
            if not self.phase:isInited() then
                appPlaySound('fallThingUp')
                self.phase:setNext('up', 3)
            end

        elseif self.phase.name == 'down' then
            if not self.phase:isInited() then
                for i = 1, 4 do
                    app.spritesHandler:createShard('ground', self.x, self.y + self.height / 2)
                end
                app.spritesHandler:createFallThingDown(self.type, {x = self.x, y = self.y} )
                self.gone = true
            end
        end

        local isHalfway = misc.inArray( {'moving-down', 'moving-up'}, self.phase.name )
        self.frameImage = 'fallThing/' .. self.type .. '-' .. misc.getIf(isHalfway, 'halfway', self.phase.name)
    end

    if phaseName == nil then phaseName = 'up' end
    local isSensor = true
    local width = 20; local height = 90
    local x = highestPointOrPoint.x; local y = highestPointOrPoint.y + height / 2
    if phaseName ~= 'up' then x = highestPointOrPoint.x; y = highestPointOrPoint.y end
    local self = spriteModule.spriteClass('rectangle', thisType, nil, nil, true, x, y, width, height,
            nil, nil, nil, nil, isSensor)
    self.bodyType = 'static'
    self.listenToCollision = true
    self.phase:set(phaseName)
    self.frameImage = 'fallThing/' .. self.type .. '-' .. self.phase.name
    appAddSprite(self, handle, moduleGroup)
end

function self:createFallThingDown(thisType, point)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if other.type == 'girl' then appGirlIsHit() end
        end

        if self.phase.name == 'moving-up' then
            if not self.phase:isInited() then
                app.spritesHandler:createFallThing( self.type, {x = self.x, y = self.y}, 'moving-up' )
                self.gone = true
            end
        end
    end

    local width = 20; local height = 90
    local image = 'fallThing/' .. thisType .. '-down'
    local self = spriteModule.spriteClass('rectangle', thisType, 'down', image, true, point.x, point.y, width, height)
    self.bodyType = 'static'
    self.listenToPostCollision = self.type == 'fallBlade'
    self.phase:set('down')
    appAddSprite(self, handle, moduleGroup)
end

function self:createDoorButton(subtype, lowestPoint)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if other.type == 'girl' then self.phase:set('pressed', 15, 'default') end
        end

        if self.phase.name == 'pressed' then
            if not self.phase:isInited() then
                appPlaySound('click')
                local fallThings = appGetSpritesByType( {'fallDoor', 'fallBlade'} )
                for i = 1, #fallThings do
                    local fallThing = fallThings[i]
                    if self.subtype == 'open' and fallThing.phase.name ~= 'up' then
                        fallThing.phase:set('moving-up')
                    elseif self.subtype == 'close' and fallThing.phase.name ~= 'down' then
                        fallThing.phase:set('moving-down')
                    end
                end
            end
        end

        self.frameImage = self.type .. '/' .. self.subtype .. '-' .. self.phase.name
    end

    local isSensor = true
    local width = 43; local height = 16
    local self = spriteModule.spriteClass('rectangle', 'doorButton', subtype, nil, true, lowestPoint.x - width / 2, lowestPoint.y - height / 2, width, height,
            nil, nil, nil, nil, isSensor)
    self.bodyType = 'static'
    self.listenToCollision = true
    self.phase:set('default')
    self.frameImage = self.type .. '/' .. self.subtype .. '-' .. self.phase.name
    appAddSprite(self, handle, moduleGroup)
end

function self:createCannon(lowestPoint, directionX)
    local function handle(self)
        if self.phase.name == 'default' then
            if not self.phase:isInited() then
                self.phase:setNext('countDown', self.data.framesPerCount)

                local text = spriteModule.spriteClass('text', 'cannonText', nil, nil, false, self.x - self.data.directionX * 6 + 2, self.y - 8)
                text:setRgb(198, 0, 0)
                text.text = self.data.shootCount
                text:setFontSize(34)
                text.alphaChangesWithEnergy = true
                text.energy = 150
                text.energySpeed = -5
                appAddSprite(text, nil, moduleGroup)
            end

        elseif self.phase.name == 'countDown' then
            if not self.phase:isInited() then
                self.data.shootCount = self.data.shootCount - 1
                if self.data.shootCount == 0 then
                    appPlaySound('shoot')
                    app.spritesHandler:createCannonBall(self)
                    self.data.shootCount = self.data.shootCountOriginal
                    self.phase:setNext('default', self.data.framesPerCount)
                    self:toFront()
                else
                    self.phase:set('default')
                end

            end

        end
    end

    local isSensor = true
    local width = 74; height = 53
    local image = 'cannon/towards' .. misc.getIf(directionX == -1, 'Left', 'Right')
    local self = spriteModule.spriteClass('rectangle', 'cannon', nil, image, true, lowestPoint.x, lowestPoint.y - height / 2, width, height,
            nil, nil, nil, nil, isSensor)
    self.data.directionX = directionX
    self.data.framesPerCount = 20
    self.data.shootCount = math.random(3, 7)
    self.data.shootCountOriginal = self.data.shootCount
    self.bodyType = 'static'
    self.phase:set('default')
    appAddSprite(self, handle, moduleGroup)
end

function self:createCannonBall(cannonSprite)
    local function handle(self)
        local speedX, speedY = self:getLinearVelocity()
        self:setLinearVelocity(self.data.directionX * 250, -8)
        if misc.getChance(20) then app.spritesHandler:createGirlDust(self) end
    end

    local directionX = cannonSprite.data.directionX
    local image = 'cannon/ball/towards' .. misc.getIf(directionX == -1, 'Left', 'Right')
    local self = spriteModule.spriteClass('rectangle', 'cannonBall', nil, image, true, cannonSprite.x + directionX * 20, cannonSprite.y - 14, 36, 24)
    self.isFixedRotation = true
    self.data.directionX = directionX
    appAddSprite(self, handle, moduleGroup)
end

function self:createDiamonds(lowestPoint, amount)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if other.type == 'girl' then
                appPlaySound('bling')
                app.spritesHandler:createBling(self)
                appAddDestructionToScore(self)
                self.gone = true
                app.diamondsOwned = app.diamondsOwned + 1
            end
        end

        if math.random(0, 10000) <= 100 and appGetSpriteCountByType('glow') <= 10 then
            app.spritesHandler:createGlow(self)
        end
    end

    if amount == nil then amount = 1 end

    local width = 30; local height = 33
    for i = 1, amount do
        local isSensor = true
        local offsetX = 31
        local x = lowestPoint.x
        if amount == 2 then x = misc.getIf(i == 1, lowestPoint.x - offsetX, lowestPoint.x + offsetX) end
        local self = spriteModule.spriteClass('rectangle', 'diamond', nil, 'diamond', true, x, lowestPoint.y - height / 2, width, height,
                nil, nil, nil, nil, isSensor)
        self.bodyType = 'static'
        self.listenToCollision = true
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createSectorArrow(lowestPoint, highestPoint, upOrDown, leadsToSector)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if other.type == 'girl' then
                app.sectorNext = self.subtype
                app.spritesHandler:createGirlSuckedInSector(other, self.data.upOrDown)
                other.gone = true
                app.phase:set('changingSector', 40, 'newRoom')
            end
        end
    end

    local width = 50; local height = 96
    local image = 'sectorArrow/' .. upOrDown

    local x = nil; local y = nil
    if upOrDown == 'up' then
        x = highestPoint.x
        y = highestPoint.y + height / 2 - 29
    else
        x = lowestPoint.x
        y = lowestPoint.y - height / 2 + 33
    end

    if app.sector == 'topTunnel' then
        width = 51; height = 177
        image = 'sectorArrow/' .. upOrDown .. 'FromTopTunnel'
        y = lowestPoint.y + 26
    elseif app.sector == 'water' then
        width = 52; height = 320
        image = 'sectorArrow/' .. upOrDown .. 'FromWater'
        y = app.maxYHalf
    end

    local isSensor = true
    local self = spriteModule.spriteClass('rectangle', 'sectorArrow', leadsToSector, image, true, x, y, width, height,
            nil, nil, nil, nil, isSensor)
    self.bodyType = 'static'
    self.data.upOrDown = upOrDown
    self.listenToCollision = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createSmallWall(lowestPoint)
    local width = 16; local height = 76
    local self = spriteModule.spriteClass('rectangle', 'wall', nil, 'wall/small', true, lowestPoint.x, lowestPoint.y - height / 2, width, height)
    self.bodyType = 'static'
    self.doDieOutsideField = false
    appAddSprite(self, handle, moduleGroup)
end

function self:createWall(topCenterPoint, wallLength, gridY)
    if wallLength >= 1 then
        local baseHeight = 100
        local width = 16; local height = baseHeight * wallLength
        local y = topCenterPoint.y + height / 2 - ( (gridY - 1) * 2 )
        local self = spriteModule.spriteClass('rectangle', 'wall', nil, 'wall/' .. wallLength, true, topCenterPoint.x, y, app.wallWidth, height)
        self.bodyType = 'static'
        self.doDieOutsideField = false
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createBlock(point)
    local self = spriteModule.spriteClass('rectangle', 'block', nil, 'block', true, point.x, point.y, 63, app.blockHeight)
    self.bodyType = 'static'
    appAddSprite(self, handle, moduleGroup)
end

function self:createControls()
    local function handleTouchThrowBomb(event)
        if app.runs then
            local self = event.target

            if event.phase == 'began' then
                local girl = appGetSpriteByType('girl')
                if girl ~= nil and app.bombsLeft > 0 then
                    app.bombsLeft = app.bombsLeft - 1
                    app.spritesHandler:createBomb(girl)

                    if app.bombsLeft == 0 then
                        local emptyButton = spriteModule.spriteClass('rectangle', 'control', 'throwBombEmpty', 'control/throwBombEmpty', false,
                                self.x, self.y, self.width, self.height)
                        emptyButton.alpha = self.alpha
                        appAddSprite(emptyButton, nil, moduleGroup)
                        self.gone = true
                    end

                    if misc.getChance(4) then appStartSlowMotionIfMeetsRequirements() end
                end
            end

        end
    end

    local function handleTouchJump(event)
        if app.runs then
            local self = event.target

            if event.phase == 'began' then
                local girl = appGetSpriteByType('girl')
                if girl ~= nil then
                    local speedX, speedY = girl:getLinearVelocity()
                    if speedY >= -5 then -- and girl.data.collidedSinceJump
                        girl.data.collidedSinceJump = false
                        local speedY = misc.getIf(app.sector == 'water', -5, -9)
                        local referencePoint = {x = math.random(app.minX, app.maxX), y = math.random(app.minY, app.maxY) }
                        girl:applyLinearImpulse(0, speedY, referencePoint.x, referencePoint.y)
                        girl.phase:set('justJumped', 25, 'default')
                    end
                end
            end

        end
    end

    local width = app.maxXHalf - 1; local height = width
    local offset = 0
    if app.isAndroid then
        offset = 34
        width = width + offset + 1
    end
    local alpha = .45
    local y = app.maxY - height / 2 + 21

    local throwBombButton = spriteModule.spriteClass('rectangle', 'control', 'throwBomb', 'control/throwBomb', false, width / 2 - offset, y, width, height)
    throwBombButton.alpha = alpha
    throwBombButton:addEventListener('touch', handleTouchThrowBomb)
    appAddSprite(throwBombButton, nil, moduleGroup)

    local jumpButton = spriteModule.spriteClass('rectangle', 'control', 'jump', 'control/jump', false, app.maxX - width / 2 + 1 + offset, y, width, height)
    jumpButton.alpha = alpha
    jumpButton:addEventListener('touch', handleTouchJump)
    appAddSprite(jumpButton, nil, moduleGroup)
end

function self:createGirl(lowestPoint)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] ~= 0 then
                self.data.collidedSinceJump = true

                if misc.inArray( {'wall', 'block', 'bomb', 'fallDoor'}, other.type ) then
                    self.phase:set('justCollidedWithWallOrFloor', 5, 'default')
                    self.data.speedX = nil
                    appPlaySound('colliding')
                    if other.type == 'bomb' and other.phase.name == 'default' then other.phase:set('onFire') end
                
                elseif other.type == 'floor' or other.type == 'ground' then
                    self.phase:set('justCollidedWithWallOrFloor', 5, 'default')
                    if not (self.x >= other.x - other.width / 2 and self.x <= other.x + other.width / 2) then
                        self.data.speedX = nil
                    end
                    if not audio.isChannelPlaying(app.soundChannelFootsteps) then
                        appPlaySound('footsteps', app.soundChannelFootsteps)
                    end
                    if self.collisionForce[i] >= 7 then appPlaySound('colliding') end

                elseif other.type == 'vase' then
                    local isSpecialRoom = app.specialRoomShownAtRoomNumber == app.roomNumber
                    local speedX, speedY = self:getLinearVelocity()
                    if math.abs(speedY) >= 10 and ( misc.getChance(6) or isSpecialRoom ) then appStartSlowMotionIfMeetsRequirements() end

                elseif misc.inArray( {'blade', 'bladeBlock', 'spikeball', 'fish', 'cannonBall'}, other.type ) then
                    appGirlIsHit()

                elseif other.type == 'guard' and other.energySpeed >= 0 then
                    appGirlIsHit()

                end
            end
        end

        if self.data.speedX == nil then
            local speedX, speedY = self:getLinearVelocity()
            self.data.speedX = misc.getIf(speedX < 0, -self.data.speedXMax, self.data.speedXMax)
        end
        local speedX, speedY = self:getLinearVelocity()
        self:setLinearVelocity(self.data.speedX, speedY)

        if self.phase.name == 'default' then
            if not self.phase:isInited() then
                self.isFixedRotation = true
                self.rotation = 0
            end

        elseif self.phase.name == 'justJumped' then
            if not self.phase:isInited() then
                audio.stop(app.soundChannelFootsteps)

                if not app.hadBattleCryThisRoom then
                    appPlaySound('battleCryAndWhoosh')
                    app.hadBattleCryThisRoom = true
                elseif misc.getChance(85) then
                    appPlaySound('whoosh')
                end

                self.extraPhase:set('run-1')
                self.isFixedRotation = false
            end

        end

        if app.sector == 'water' then
            if misc.getChance(10) then app.spritesHandler:createWaterBubble(self) end
        else
            if misc.getChance(10) then app.spritesHandler:createGirlDust(self) end
        end

        if (self.data.speedX ~= nil and self.data.speedX > 0 and self.x - self.width / 2 > app.maxX) or
                (self.data.speedX ~= nil and self.data.speedX < 0 and self.x - self.width / 2 < app.minX) then
            app.lastGirlPosition = {x = self.x, y = self.y}
            self.gone = true
        end

        if self.extraPhase.name == 'run-1' then
            if not self.extraPhase:isInited() then
                self.extraPhase:setNext('run-2', 3)
            end

        elseif self.extraPhase.name == 'run-2' then
            if not self.extraPhase:isInited() then
                self.extraPhase:setNext('run-1', 3)
            end
        end

        if app.extraPhase.name == 'slowMotion' then app.spritesHandler:createCloneImage(self, self.frameImage) end

        self.frameImage = 'girl/' .. appGetGirlDressName(self) .. '/' .. self.extraPhase.name .. '-' .. misc.getIf(self.data.speedX < 0, 'left', 'right')
        
    end

    local width = 36; local height = width
    local radius = width / 2
    local speedX = 150


    local self = spriteModule.spriteClass('circle', 'girl', nil, nil, true, lowestPoint.x, lowestPoint.y - height / 2, radius)
    self.alsoAllowsExtendedNonPhysicalHandling = false
    self.angularDamping = 2
    self.data.wearsSwimsuit = false

    if app.sector == 'water' then
        speedX = 100
        self.angularDamping = 15
        self.alpha = app.underwaterAlpha
        self.data.wearsSwimsuit = true
    end
    if lowestPoint.x > app.maxXHalf then speedX = speedX * -1 end

    self.data.speedX = speedX
    self.data.speedXMax = math.abs(speedX)
    self.listenToPostCollision = true
    self.data.collidedSinceJump = true
    self.extraPhase:set('run-1')
    if app.roomNumber == 1 then
        appPlaySound('battleCryAndWhoosh')
        appPlaySound( 'windowBreaking-' .. math.random(1, 2) )
    end
    self.frameImage = 'girl/' .. appGetGirlDressName(self) .. '/' .. self.extraPhase.name .. '-' .. misc.getIf(self.data.speedX < 0, 'left', 'right')
    appAddSprite(self, handle, moduleGroup, appCheckIfRoomNeedsToBeLeft)
end

function self:createGirlGhost(sprite)
    local self = spriteModule.spriteClass('rectangle', 'girlGhost', nil, sprite.frameImage, false, sprite.x, sprite.y, sprite.width, sprite.height)
    self.speedX = misc.getIf(sprite.data.speedX ~= nil and sprite.data.speedX > 0, 2, -2)
    self.speedY = -8
    self.targetSpeedY = 6
    self.energy = 60
    self.energySpeed = -.5
    self.rotationSpeed = -6
    if misc.getChance() then self.rotationSpeed = self.rotationSpeed * -1 end
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createGirlSuckedInSector(sprite, upOrDown)
    local speedYMax = 6
    local speedXMax = 3
    local speedY = misc.getIf(upOrDown == 'up', -speedYMax, speedYMax)
    local self = spriteModule.spriteClass('rectangle', 'girlSuckedInSector', nil, sprite.frameImage, false, sprite.x, sprite.y, sprite.width, sprite.height)
    if sprite.data.speedX ~= nil then self.speedX = misc.getIf(sprite.data.speedX < 0, -speedXMax, speedXMax) end
    self.speedY = speedY * .4
    self.targetSpeedY = speedY
    self.alpha = sprite.alpha
    appAddSprite(self, handle, moduleGroup)
end

function self:createGirlEscapesFromNinjas(sprite, direction)
    local self = spriteModule.spriteClass('rectangle', 'girlEscapes', nil, sprite.frameImage, false, sprite.x, sprite.y, sprite.width, sprite.height)
    self.speedX = direction * 6
    self.rotationSpeed = direction * 10
    self.targetSpeedY = misc.getIf(sprite.y < app.maxYHalf, 4, -4)
    appAddSprite(self, handle, moduleGroup)
end

function self:createNinjas(direction)
    local function handle(self)

        if self.phase.name == 'throwing' then
            if not self.phase:isInited() then
                self.phase:setNext('default', 20)
                local throwingStarPoint = {x = self.x + self.data.direction * 4, y = self.y - 4}
                app.spritesHandler:createNinjaThrowingStar(throwingStarPoint, self.data.direction )
            end

        end

        local maxY = app.maxY - self.height / 2 - 15
        if self.y > maxY then
            self.y = maxY
            if self.speedY > 0 then self.speedY = self.speedY * -1 end
            self.targetSpeedY = 2
            self.rotationSpeed = self.data.direction * 10
        end

        self.frameImage = 'ninja/' .. self.phase.name .. '-' .. misc.getIf(self.data.direction == -1, 'left', 'right')
    end

    local ninjaMax = 5
    local x = misc.getIf(direction == 1, app.minX, app.maxX)
    for i = 1, ninjaMax do
        local y = math.random(app.minY, app.maxYHalf + 120)
        local self = spriteModule.spriteClass('rectangle', 'ninja', nil, nil, false, x, y, 37, 37)
        self.data.direction = direction
        self.speedX = direction * math.random(4, 6)
        self.speedY = -4
        self.targetSpeedY = 3
        self.phase:set('default', math.random(30, 50), 'throwing')
        self.frameImage = 'ninja/' .. self.phase.name .. '-' .. misc.getIf(self.data.direction == -1, 'left', 'right')
        if i == ninjaMax or misc.getChance(20) then self.rotationSpeed = self.data.direction * 10 end
        appAddSprite(self, handle, moduleGroup)
    end
    appPlaySound('whoosh')
end

function self:createNinjaThrowingStar(point, direction)
    local self = spriteModule.spriteClass('rectangle', 'ninjaThrowingStar', nil, 'ninja/throwingStar', false, point.x, point.y, 16, 16)
    self.rotationSpeed = 4 * direction
    self.speedX = direction * 8
    appAddSprite(self, handle, moduleGroup)
    appPlaySound('whooshFast', nil, nil, nil, nil, true) 
end

function self:createTable(lowestPoint, isLong, isHigh, legIsBreakable, plateIsBreakable)
    if plateIsBreakable == nil then plateIsBreakable = true end

    local legTopY = nil
    for i = 1, 2 do
        local xOffset = misc.getIf(isHigh, 30, 14)
        local height = misc.getIf(isHigh, 80, app.tableLegHeight)
        legTopY = app.spritesHandler:createTableLeg(
                {x = lowestPoint.x + misc.getIf(i == 1, -xOffset, xOffset), y = lowestPoint.y - height / 2 - 4}, isHigh, legIsBreakable )
    end

    local backwardsCompatibleManualY = lowestPoint.y - app.tableLegHeight - app.tablePlateHeight / 2 - 6
    local y = misc.getIf(isHigh, legTopY - app.tablePlateHeight / 2, backwardsCompatibleManualY)
    local plateY = app.spritesHandler:createTablePlate( {x = lowestPoint.x + 2, y = y}, isLong, plateIsBreakable )

    return plateY - app.tablePlateHeight / 2
end

function self:createTableLeg(point, isHigh, isBreakable)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] >= 5 then
                appPlaySound( 'woodBreaking-' .. math.random(1, 2) )
                app.spritesHandler:createShards(self)
                appAddDestructionToScore(self)
                self.gone = true
            end
        end
    end

    if isHigh == nil then isHigh = false end
    if isBreakable == nil then isBreakable = true end

    local image = 'table/leg'
    local height = app.tableLegHeight; local width = app.tableLegWidth
    if isHigh then
        width = 18; height = 80
        image = image .. 'High'
    end
    if not isBreakable then image = image .. 'Unbreakable' end

    local friction = 10
    local self = spriteModule.spriteClass('rectangle', 'table', 'leg', image, true, point.x, point.y, width, height,
            nil, nil, nil, nil, nil, nil, nil, friction)
    if isBreakable then self.listenToPostCollision = true end
    if isHigh then self.angularDamping = 10 end
    appAddSprite(self, handle, moduleGroup, appShowMessageIfRoomFullyCleared)

    return self.y - self.height / 2
end

function self:createTablePlate(point, isLong, isBreakable)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] >= 5 then
                appPlaySound( 'woodBreaking-' .. math.random(1, 2) )
                app.spritesHandler:createShards(self)
                appAddDestructionToScore(self)
                self.gone = true
            end
        end
    end

    if isLong == nil then isLong = false end
    if isBreakable == nil then isBreakable = true end

    local friction = 10
    local width = app.tablePlateWidth; local image = 'table/plate'
    if isLong then width = 80; image = image .. 'Long' end
    if not isBreakable then image = image .. 'Unbreakable' end

    local self = spriteModule.spriteClass('rectangle', 'table', 'plate', image, true, point.x, point.y, width, app.tablePlateHeight,
            nil, nil, nil, nil, nil, nil, nil, friction)
    if isBreakable then self.listenToPostCollision = true end
    appAddSprite(self, handle, moduleGroup, appShowMessageIfRoomFullyCleared)
    return self.y
end

function self:createGirlDust(girl)
    local image = 'girl/dust'
    local self = spriteModule.spriteClass( 'rectangle', 'girlDust', nil, 'girl/dust', false, girl.x, girl.y + math.random(-2, 2), 6, 7 )
    self.energy = 150
    self.energySpeed = -4
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createWaterBubble(sprite)
    local function handle(self)
        local topWaterLine = 30
        if self.y - self.height / 2 <= topWaterLine then self.gone = true end
    end

    local self = spriteModule.spriteClass( 'rectangle', 'waterBubble', nil, 'water-bubble', false, sprite.x, sprite.y + math.random(-2, 2), 6, 6 )
    self.energy = 200
    self.energySpeed = -2
    self.speedY = 0
    self.targetSpeedY = -2
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createGuard(lowestPoint)
    local function handle(self)
        if self.energySpeed == 0 then
            for i, other in pairs(self.collisionWith) do
                if self.collisionForce[i] > 0 and other.type == 'bombShard' then
                    self.energySpeed = -6
                    app.spritesHandler:createShards(self)
                    local phaseName = 'shock-' .. misc.getIf(other.x < self.x, 'left', 'right')
                    self.phase:set(phaseName)
                end
            end
        end

        if self.phase.name == 'shock-left' or self.phase.name == 'shock-right' then
            if not self.phase:isInited() then
                self.phase:setNext('default', 100)
            end
        end
        self.frameImage = 'guard/' .. self.phase.name
    end

    local width = 43; local height = 47
    local self = spriteModule.spriteClass('rectangle', 'guard', nil, nil, true, lowestPoint.x, lowestPoint.y - height / 2, width, height,
            nil, nil, nil, nil, nil, nil, nil, friction)
    self.alphaChangesWithEnergy = true
    self.rotation = app.actualPlaneRotation
    self.listenToPostCollision = true
    self.alphaChangesWithEnergy = true
    self.phase:set('default')
    self.energy = 250
    self.frameImage = 'guard/' .. self.phase.name
    appAddSprite(self, handle, moduleGroup)
end

function self:createBomb(girlSprite)
    local function handle(self)
        if self.phase.name == 'onFire' then
            if not self.phase:isInited() then
                app.spritesHandler:createFireAndSmoke(self)
                self.phase:setNext('explode', 60)
            end
            if misc.getChance(25) then
                app.spritesHandler:createFireAndSmoke(self)
            end

        elseif self.phase.name == 'explode' then
            if not self.phase:isInited() then
                appPlaySound('explosion')
                app.spritesHandler:createBombShards(self)
                self.gone = true
            end

        end
        self:toFront()
    end

    local width = 24; local radius = width / 2
    local self = spriteModule.spriteClass('circle', 'bomb', nil, 'bomb', true, girlSprite.x, girlSprite.y, radius, nil)
    self.alphaChangesWithEnergy = true
    local speedX, speedY = girlSprite:getLinearVelocity()
    self.phase:set('onFire')
    self:applyLinearImpulse(speedX * .04, speedY * .02, girlSprite.x, girlSprite.y)
    appAddSprite(self, handle, moduleGroup, appCheckIfRoomNeedsToBeLeft)
end

function self:createBlade(highestPoint, lowestPoint, topOrBottom)
    local function handle(self)
        if self.phase.name == 'moving-1' then
            if not self.phase:isInited() then self.phase:setNext('moving-2', self.data.animationDelay) end
        elseif self.phase.name == 'moving-2' then
            if not self.phase:isInited() then self.phase:setNext('moving-1', self.data.animationDelay) end
        end
        self.frameImage = 'blade/' .. self.subtype .. '-' .. self.phase.name

        if math.random(0, 10000) <= 10 and appGetSpriteCountByType('glow') <= 3 then
            app.spritesHandler:createGlow(self)
        end
    end

    local x = nil; y = nil0
    local width = 19; local height = 30

    if topOrBottom == 'top' then x = highestPoint.x; y = highestPoint.y + height / 2
    else x = lowestPoint.x; y = lowestPoint.y - height / 2
    end

    local self = spriteModule.spriteClass('rectangle', 'blade', topOrBottom, nil, true, x, y, width, height)
    self.bodyType = 'static'
    self.data.animationDelay = 7
    self.phase:set('moving-1')
    self.frameImage = 'blade/' .. self.subtype .. '-' .. self.phase.name
    self.frameImageZ = 'background'
    appAddSprite(self, handle, moduleGroup)
end

function self:createSpikeball(lowestPoint, subtype)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] ~= 0 and misc.inArray( {'wall', 'block', 'spikeball', 'guard', 'fallBlade', 'fallDoor'}, other.type ) then
                self.data.speedX = nil
            end
        end

        if self.data.speedX == nil then
            local speedX, speedY = self:getLinearVelocity()
            self.data.speedX = misc.getIf(speedX < 0, -self.data.speedXMax, self.data.speedXMax)
        end
        local speedX, speedY = self:getLinearVelocity()
        self:setLinearVelocity(self.data.speedX, speedY)
    end

    local width = 43; local radius = width / 2
    local self = spriteModule.spriteClass('circle', 'spikeball', subtype, 'spikeball', true, lowestPoint.x, lowestPoint.y - radius - 10, radius)
    self.data.speedXMax = 100
    if subtype == 'slow' then self.data.speedXMax = 15
    elseif subtype == 'fast' then self.data.speedXMax = 150
    end
    self.data.speedX = misc.getIf(self.x > app.maxXHalf, -self.data.speedXMax, self.data.speedXMax)
    self.listenToPostCollision = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createItem(lowestPoint, itemIndex, isWhole)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if not self.gone and other.type == 'girl' or other.type == 'bombShard' then
                appPlaySound( 'woodBreaking-' .. math.random(1, 2) )
                app.spritesHandler:createShards(self)
                appAddDestructionToScore(self)
                app.spritesHandler:createItem(self.data.lowestPoint, self.data.itemIndex, false)
                self.gone = true
                appShowMessageIfRoomFullyCleared()
            end
        end
    end

    if isWhole == nil then isWhole = true end
    if itemIndex == nil then itemIndex = math.random(1, #app.items) end
    local item = app.items[itemIndex]
    local image = 'item/' .. item.name .. misc.getIf(isWhole, '', '-broken')
    local width = item.width; local height = item.height
    local isSensor = true
    local subtype = misc.getIf(isWhole, 'whole', 'broken')
    local self = spriteModule.spriteClass('rectangle', 'item', subtype, image, true, lowestPoint.x, lowestPoint.y - height / 2, width, height,
            nil, nil, nil, nil, isSensor)
    self.bodyType = 'static'
    self.listenToCollision = isWhole
    self.data.itemIndex = itemIndex
    self.data.lowestPoint = lowestPoint
    appAddSprite(self, handle, moduleGroup)
end

function self:createClock(point)
    local function handle(self)
        if app.phase.name == 'newRoom' then
            for i, other in pairs(self.collisionWith) do
                if not self.gone and other.type == 'girl' then
                    appPlaySound('bling')
                    app.spritesHandler:createBling(self)
                    local bonusSeconds = 5
                    app.spritesHandler:createScoredText( self:getPoint(), 'T+' .. bonusSeconds, true, true )
                    app.gameClock.secondsLeft = app.gameClock.secondsLeft + bonusSeconds
                    self.gone = true
                end
            end
        end
    end

    local isSensor = true
    local self = spriteModule.spriteClass('rectangle', 'clock', nil, 'clock', true, point.x, point.y, 30, 30,
            nil, nil, nil, nil, isSensor)
    self.bodyType = 'static'
    self.listenToCollision = true
    if app.sector == 'water' then self.alpha = app.underwaterAlpha end
    appAddSprite(self, handle, moduleGroup)
end

function self:createFireAndSmoke(sprite)
    if appGetSpriteCountByType( {'fire', 'smoke'} ) <= 18 then
        local center = misc.getOffsetPointByRotation( {x = sprite.x, y = sprite.y}, sprite.rotation, 15, 135 )
    
        local smoke = spriteModule.spriteClass('rectangle', 'smoke', nil, 'smoke', false, center.x, center.y, 6, 6)
        smoke.speedX = 0
        smoke.speedY = math.random(-5, -1) * .1
        smoke.energy = 70
        smoke.energySpeed = -1
        smoke.alphaChangesWithEnergy = true
        appAddSprite(smoke, handle, moduleGroup)
    
        local fire = spriteModule.spriteClass('rectangle', 'fire', nil, 'fire', false, center.x, center.y, 9, 9)
        fire.speedX = math.random(-1, 1) * .5
        fire.speedY = math.random(-2, 1) * .5
        fire.energySpeed = -2.5
        fire.rotationSpeed = 5
        fire.alphaChangesWithEnergy = true
        appAddSprite(fire, handle, moduleGroup)
    end
end

function self:createGlow(vase)
    if app.phase.name == 'newRoom' then
        local xOff = math.random(vase.width / 4, vase.width / 2)
        local yOff = math.random(vase.height / 4, vase.height / 2)
        local x = vase.x + misc.getIfChance(nil, -xOff, xOff)
        local y = vase.y + misc.getIfChance(nil, -yOff, yOff)
        local self = spriteModule.spriteClass('rectangle', 'glow', nil, 'glow', false, x, y, 17, 17)
        self.parentId = vase.id
        self.movesWithParent = true
        self.movesWithParentIsRelativeToOrigin = true
        self.rotationSpeed = -2
        self.energy = 200
        self.energySpeed = -4
        self.alphaChangesWithEnergy = true
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createBackground(image, isAnimated)
    local function handle(self)
        if self.extraPhase.name == 'moving-1' then
            if not self.extraPhase:isInited() then self.extraPhase:setNext('moving-2', self.data.animationDelay) end
        elseif self.extraPhase.name == 'moving-2' then
            if not self.extraPhase:isInited() then self.extraPhase:setNext('moving-1', self.data.animationDelay) end
        end
        if self.extraPhase.name ~= 'default' then
            self.frameImage = 'background/' .. app.sector .. '/' .. self.extraPhase.name
        end
    end

    if isAnimated == nil then isAnimated = false end

    local self = spriteModule.spriteClass('rectangle', 'background', nil, nil, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self.frameImage = image
    self.frameImageZ = 'background'
    if isAnimated then
        self.data.animationDelay = 20
        self.extraPhase:set('moving-1')
        self.frameImage = 'background/' .. app.sector .. '/' .. self.extraPhase.name
    end
    appAddSprite(self, handle, moduleGroup)
end

function self:createRoofAndGround(roofHeight, groundHeight)
    local margin = 30

    local roof = spriteModule.spriteClass('rectangle', 'roof', nil, nil, true, app.maxXHalf, roofHeight / 2, app.maxX + margin * 2, roofHeight)
    roof.bodyType = 'static'
    roof.isVisible = false
    roof.isHitTestable = true
    appAddSprite(roof, handle, moduleGroup)

    local friction = 1
    local ground = spriteModule.spriteClass('rectangle', 'ground', nil, nil, true, app.maxXHalf, app.maxY - groundHeight / 2, app.maxX + margin * 2, groundHeight,
            nil, nil, nil, nil, nil, density, nil, friction)
    ground.bodyType = 'static'
    ground.isVisible = false
    ground.isHitTestable = true
    ground.rotation = app.actualPlaneRotation
    appAddSprite(ground, handle, moduleGroup)
end

function self:createFish(point, isSlow)
    local function handle(self)
        if self.energySpeed == 0 then
            for i, other in pairs(self.collisionWith) do
                if self.collisionForce[i] > 0 and other.type == 'bombShard' then
                    self.energySpeed = -2
                    self.phase:set('mouthOpen')
                    self.rotationSpeed = 2
                    app.spritesHandler:createShards(self)
                end
            end
        end

        if self.phase.name == 'mouthClosed' then
            if not self.phase:isInited() then
                self.phase:setNext('mouthOpen', 10)
                appPlaySound('fishbite')
            end

        elseif self.phase.name == 'mouthOpen' then
            if not self.phase:isInited() then
                if self.energySpeed == 0 then
                    self.phase:setNext('mouthClosed', 10)
                end
            end

        end

        self:setLinearVelocity(self.data.speedX, 0, self.x, self.y)
        self.y = self.originY
        self.frameImage = 'fish/' .. self.subtype .. '-' .. self.phase.name
    end

    local subtype = misc.getIf(point.x < app.maxXHalf, 'right', 'left')

    local self = spriteModule.spriteClass('rectangle', 'fish', subtype, nil, true, point.x, point.y, 63, 43)
    self.isFixedRotation = true
    self.alpha = app.underwaterAlpha
    self.data.speedX = -math.random(40, 150)
    if isSlow then self.data.speedX = -20 end
    if self.subtype == 'right' then self.data.speedX = self.data.speedX * -1 end
    self.phase:set('mouthClosed')
    self.frameImage = 'fish/' .. self.subtype.. '-' .. self.phase.name
    self.alphaChangesWithEnergy = true
    self.energy = 75
    self.listenToPostCollision = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createShards(sprite, includeSubtypeInImagePath, isImportant)
    if includeSubtypeInImagePath == nil then includeSubtypeInImagePath = false end
    local width = 6; local height = width
    local image = sprite.type
    if includeSubtypeInImagePath and sprite.subtype ~= nil then image = image .. '-' .. sprite.subtype end
    if isImportant == nil then isImportant = false end

    local max = 1; local step = 2
    if isImportant then max = 2; step = 1 end
    for gridX = -max, max, step do
        for gridY = -max, max, step do
            if not (gridX == 0 or gridY == 0) then
                local x = sprite.x + gridX * width
                local y = sprite.y + gridY * height
                app.spritesHandler:createShard(image, x, y, width, height, isImportant)
            end
        end
    end
end

function self:createShard(image, x, y, width, height, isImportant)
    if isImportant == nil then isImportant = false end
    if appGetSpriteCountByType('shard') <= 10 or isImportant then
        if width == nil then width = 6 end
        if height == nil then height = width end
    
        local self = spriteModule.spriteClass('rectangle', 'shard', image, 'shard/' .. image, false, x, y, width, height)
        self.targetSpeedY = 6
        local speedLimit = 4
        self.rotationSpeed = math.random(-10, 10)
        self.speedX = math.random(-speedLimit, speedLimit)
        self.speedY = math.random(-speedLimit, speedLimit / 2) - 2
        self.energy = 130
        self.energySpeed = -4
        if isImportant then self.energySpeed = -2 end
        self.alphaChangesWithEnergy = false
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createBombShards(sprite)
    local width = 10; local height = width
    local image = sprite.type
    if sprite.subtype ~= nil then image = image .. '-' .. sprite.subtype end

    for gridX = -1, 1 do
        for gridY = -1, 1 do
            local x = sprite.x + gridX * width
            local y = sprite.y + gridY * height
            app.spritesHandler:createBombShard(image, x, y, width, height)
        end
    end
end

function self:createBombShard(image, x, y, width, height)
    local density = 50
    local self = spriteModule.spriteClass('rectangle', 'bombShard', image, 'shard/' .. image, true, x, y, width, height,
            nil, nil, nil, nil, nil, density)
    self.energy = 400
    self.energySpeed = -6
    self.alphaChangesWithEnergy = true

    local forceMax = 200
    local forceX = math.random(50, forceMax)
    local forceY = math.random(50, forceMax)
    if misc.getChance() then forceX = forceX * -1 end
    if misc.getChance() then forceY = forceY * -1 end

    self:applyLinearImpulse(forceX, forceY, x, y)

    appAddSprite(self, handle, moduleGroup, appCheckIfRoomNeedsToBeLeft)
end

function self:createIntroHelp(point)
    local fontSize = 25
    local energy = 3000
    local y = 140

    app.spritesHandler:createTextsWithShadow( {'TAP LEFT', 'TO THROW', 'ONE BOMB', 'PER ROOM'}, {x = 24, y = y}, fontSize, energy, true )
    app.spritesHandler:createTextsWithShadow( {'TAP RIGHT', 'TO JUMP ...', 'MANY TAPS', 'GO HIGHER'}, {x = 325, y = y}, fontSize, energy, true )
end

function self:createDestroyHelp(point)
    app.spritesHandler:createTextWithShadow('DESTROY AS MUCH AS YOU CAN!', {x = app.maxXHalf, y = app.maxYHalf}, 25, 900)
end

function self:createScoredText(point, text, doShowLong, isImportant)
    if isImportant == nil then isImportant = false end

    if app.showScoredText and ( isImportant or appGetSpriteCountByType('scoredText') <= 12 ) then
        for i = 1, 2 do
            local isShadow = i == 1
            local x = point.x; y = point.y - 40
            if isShadow then y = y + 1
            else y = y - 1
            end
                
            local self = spriteModule.spriteClass('text', 'scoredText', nil, nil, false, x, y, 100, 30)
            self.text = text
            if isShadow then self:setRgbBlack() else self:setRgbWhite() end
            self:setFontSize(34)
            self.speedY = -1
            self.energy = misc.getIf(doShowLong, 300, 220)
            self.energySpeed = misc.getIf(isShadow, -8, -7)
            self.alphaChangesWithEnergy = true
            appAddSprite(self, handle, moduleGroup)
        end
    end
end

function self:createScore()
    local function handle(self)
        if self.data.scoreOld ~= app.score or self.data.secondsLeftOld ~= app.gameClock.secondsLeft then
            self.text = 'T:' .. misc.padWithZero(app.gameClock.secondsLeft) .. ' $' .. app.score
            self:topLeftAlign()
            self.data.scoreOld = app.score
            self.data.secondsLeftOld = app.gameClock.secondsLeft
            self:toFront()
        end
    end

    local self = spriteModule.spriteClass('text', 'score', nil, nil, false, 20, 0, 150, 32)
    self:setRgbWhite()
    self:setFontSize(32)
    self.text = ''
    self:topLeftAlign()
    self.data.scoreOld = nil
    self.data.secondsLeftOld = nil
    appAddSprite(self, handle, moduleGroup)
end

function self:createGameOverScreen()
    local function handlePlayAgain(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appRestart()
        end
    end

    local function handleChangeClothes(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            app.restartWhenResumed = true
            appRemoveSpritesByTypeNow(app.temporaryTypes)
            appPause()
            app.menu:createPageChangeClothes()
        end
    end

    local function handleText(self)
        local blinkFadeLength = 20; local blinkSpeed = 2.5

        if self.phase.name == 'blinkFadeOut' then
            if not self.phase:isInited() then
                self.phase:setNext('blinkFadeIn', blinkFadeLength)
                self.energySpeed = -blinkSpeed
            end

        elseif self.phase.name == 'blinkFadeIn' then
            if not self.phase:isInited() then
                self.phase:setNext('blinkFadeOut', blinkFadeLength)
                self.energySpeed = blinkSpeed
            end

        end
    end

    local largeScreenYMarginSum = 40
    local darkOverlay = spriteModule.spriteClass('rectangle', 'gameOverOverlay', 'darkOverlay', nil, false,
            app.maxXHalf, app.maxYHalf, app.maxX, app.maxY + largeScreenYMarginSum)
    darkOverlay:setRgbBlack()
    darkOverlay.alpha = .45
    appAddSprite(darkOverlay, handle, moduleGroup)

    local lines = {
            misc.getIf(app.wasTimeOut, 'Time Out', 'Game Over') .. '! Congrats,',
            'You scored $' .. app.score .. ' and',
            'now own ' .. misc.addCommasToNumber(app.diamondsOwned) .. ' diamond' .. misc.getIf(app.diamondsOwned == 1, '', 's') .. '.'}
    local highscoreI = nil
    if app.score > app.highestAllTimeScore then
        highscoreI = #lines + 1
        lines[highscoreI] = 'New highscore!'
    end

    local lineHeight = 28
    for lineI = 1, #lines do
        local text = spriteModule.spriteClass('text', 'gameOverText', nil, nil, false, app.maxXHalf, 50 + lineI * lineHeight)
        text.text = lines[lineI]
        text:setFontSize(35)
        if highscoreI ~= nil and lineI == highscoreI then text.subtype = 'highscore' end
        if text.subtype then
            text:setRgb(251, 251, 170)
            text.alphaChangesWithEnergy = true
            text.phase:set('blinkFadeOut')
        end
        appAddSprite(text, handleText, moduleGroup)
    end

    local x = 361; y = 226; width = 217; height = 163
    local playAgainButton = spriteModule.spriteClass('rectangle', 'gameOverButton', nil, 'playAgainButton', false, x, y, width, height)
    playAgainButton.listenToTouch = true
    appAddSprite(playAgainButton, handlePlayAgain, moduleGroup)

    local changeClothesButton = spriteModule.spriteClass('rectangle', 'gameOverButton', nil, 'changeClothesButton', false, app.maxX - x, y, width, height)
    changeClothesButton.listenToTouch = true
    appAddSprite(changeClothesButton, handleChangeClothes, moduleGroup)
end

function self:showIntroStoryPage(number)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            app.phase:set('newRoom')
        end
    end

    appRemoveSpritesByType('introStoryPage')
    appRemoveSpritesByType('textMessage', 'subtitle')
    local image = 'introStory/' .. number
    local self = spriteModule.spriteClass('rectangle', 'introStoryPage', number, image, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self.listenToTouch = true
    self:toBack()
    appAddSprite(self, handle, moduleGroup)

    local texts = {
            'DADDY HAD A POPULAR KARATE DOJO',
            {'THEN THE CROOKS CAME', 'AND STOLE THE HUMPTERDINK SWORD'},
            'THE SUCCESS OF THE DOJO FADED',
            'DADDY GOT SICK',
            {'I STARTED GETTING BAD', 'GRADES IN SCHOOL'},
            'NINJA DOG STOPPED EATING',
            'I SWORE REVENGE!'
            }
    if number <= #texts then
        local text = misc.toTable(texts[number])
        app.spritesHandler:createTextsWithShadow( text, {x = app.maxXHalf, y = app.maxY - #text * 20 - 20}, 27, nil, nil, nil, 'subtitle', true)
    end
end

function self:createTextsWithShadow(texts, point, fontSize, energy, doLeftAlign, lineHeight, subtype, useMoreShadow)
    if lineHeight == nil then lineHeight = 18 end
    local y = point.y
    texts = misc.toTable(texts)
    for i = 1, #texts do
        self:createTextWithShadow( texts[i], {x = point.x, y = y}, fontSize, energy, doLeftAlign, subtype, useMoreShadow )
        y = y + lineHeight
    end
end

function self:createCenteredBuddhaQuote()
    local quote = appGetRandomBuddhaQuote()
    quote = '"' .. quote .. '"'
    local textArray = misc.getWrappedTextArray(quote, 30)
    textArray[#textArray + 1] = '-Buddha'

    local lineHeight = 18
    local y = app.maxYHalf - lineHeight * (#textArray * .5)
    for i = 1, #textArray do
        local self = spriteModule.spriteClass('text', 'introQuote', nil, nil, false, app.maxXHalf, y)
        self:setFontSize(24)
        self.text = textArray[i]
        appAddSprite(self, handle, moduleGroup)

        y = y + lineHeight
    end
end

function self:createTextWithShadow(text, point, fontSize, energy, doLeftAlign, subtype, useMoreShadow)
    if point == nil then point = {x = app.maxXHalf, y = app.maxY - 20 } end
    if fontSize == nil then fontSize = 30 end
    if energy == nil then energy = 550 end
    if doLeftAlign == nil then doLeftAlign = false end
    if useMoreShadow == nil then useMoreShadow = false end

    local textPrints = {}
    textPrints[#textPrints + 1] = {isShadow = true, xOff = 0, yOff = 1}
    if useMoreShadow then
        textPrints[#textPrints + 1] = {isShadow = true, xOff = -2, yOff = 0}
        textPrints[#textPrints + 1] = {isShadow = true, xOff = 2, yOff = 0}
        textPrints[#textPrints + 1] = {isShadow = true, xOff = 0, yOff = -3}
    end
    textPrints[#textPrints + 1] = {isShadow = false, xOff = 0, yOff = -1}

    for i = 1, #textPrints do
        local textPrint = textPrints[i]
        local x = point.x + textPrint.xOff; local y = point.y + textPrint.yOff

        local self = spriteModule.spriteClass('text', 'textMessage', subtype, nil, false, x, y)
        self:setFontSize(fontSize)
        self.text = text
        if textPrint.isShadow then self:setRgbBlack()
        else self:setRgbWhite()
        end
        self.energy = energy
        self.energySpeed = misc.getIf(textPrint.isShadow, -8, -7)
        self.alphaChangesWithEnergy = true
        if doLeftAlign then self:topLeftAlign() end

        local whenGoneFunction = misc.getIf(subtype == 'allDestroyed', appCheckIfRoomNeedsToBeLeft, nil)
        appAddSprite(self, handle, moduleGroup, whenGoneFunction)
    end
end

function self:createCountDownMessage(secondsLeft)
    appRemoveSpritesByType('countDownMessage')
    local self = spriteModule.spriteClass('text', 'countDownMessage', nil, nil, false, app.maxXHalf, app.maxYHalf, 100, 100)
    self:setFontSize(100)
    self.text = secondsLeft
    self.energy = 160
    self.energySpeed = -8
    self.alphaChangesWithEnergy = true
    self:setRgb(190, 5, 5)
    appAddSprite(self, handle, moduleGroup)
end

function self:createBling(sprite)
    local function handle(self)
        local scaleFactor = 1.03
        self:scale(scaleFactor, scaleFactor)
    end

    local self = spriteModule.spriteClass('rectangle', 'bling', nil, 'bling', false, sprite.x, sprite.y, 27, 27)
    self.energy = 100
    self.energySpeed = -4
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

return self
end
