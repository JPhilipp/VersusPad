module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createDragParts(playerToHandle)
    local sequenceSubtypes = app.spritesHandler:getDragPartsSequenceSubtypes()

    local padding = 20
    local lastX = 0
    local lastY = 0
    local lastWidth = 0
    local highestThisRow = nil

    if app.settingsUseMorePartsPerWagon then
        padding = 5
    end

    for i = 1, #sequenceSubtypes do
        local subtype = sequenceSubtypes[i]

        local width, height, shapeOrShapesBase = appGetPartWidthHeightShape(subtype)
        local x = lastX + width / 2 + padding
        local y = lastY + height / 2 + padding
        if highestThisRow == nil or height > highestThisRow then highestThisRow = height end
        local rotation = math.random( 0, math.floor(app.maxRotation / app.rotationStep - 1) ) * app.rotationStep

        local baseDirection = math.random(1, 2)
        local part = app.partSubtypes[subtype]
        if part.isCannon or part.alwaysFacesForward then baseDirection = 1 end
        local aiBoxCount = 2

        for playerI = 1, app.playerMax do
            local isAiOwned = app.mode == 'training' and playerI == app.enemyPlayer
            local thisX = x
            local thisY = y
            local direction = baseDirection
            if playerI == 2 then direction = misc.getIf(direction == 1, 2, 1) end
            local shapeOrShapes = misc.cloneTable(shapeOrShapesBase)

            if isAiOwned and i <= aiBoxCount then
                subtype = 'box'
                width, height, shapeOrShapes = appGetPartWidthHeightShape(subtype)
            end

            if direction == 2 and not part.flipLocked then
                if shapeOrShapes ~= nil then
                    if misc.getType(shapeOrShapes[1]) == 'table' then
                        for n = 1, #shapeOrShapes do
                            shapeOrShapes[n] = misc.mirrorPolygonHorizontally(shapeOrShapes[n], width)
                        end
                    else
                        shapeOrShapes = misc.mirrorPolygonHorizontally(shapeOrShapes, width)
                    end
                end
            end

            if playerI == 2 then thisX = app.maxX - thisX end

            if isAiOwned then
                if i <= aiBoxCount then
                    thisX = 630 + i * 120
                    thisY = 585
                else
                    local boundary = appGetAiBuildingBoundary()
                    if boundary ~= nil then
                        thisX = math.random(boundary.x1, boundary.x2)
                        thisY = math.random(boundary.y1, boundary.y2)
    
                        if app.partSubtypes[subtype].isCannon then
                            thisX = math.random(boundary.x1, boundary.x2 - 150)
                        end
                    end
                end
            end

            local skipCreation = playerToHandle ~= nil and playerI ~= playerToHandle
            lastX = app.spritesHandler:createDragPart(subtype, thisX, thisY, direction, isAiOwned, width, height, shapeOrShapes, rotation, playerI, nil, skipCreation)
        end

        lastWidth = width
        if lastX > app.maxXHalf - 230 then
            lastX = 0
            lastWidth = 0
            lastY = lastY + highestThisRow + padding
            highestThisRow = nil
        end
    end
end

function self:createDragPart(subtype, thisX, thisY, direction, isAiOwned, width, height, shapeOrShapes, rotation, playerI, wasTouched, skipCreation)
    local function handle(self)
        local energyMin = 62
        local energyMax = 96
        if self.energy < energyMin and self.energySpeed < 0 then
            self.energy = energyMin
            self.energySpeed = self.data.energySpeedDefault
        elseif self.energy > energyMax and self.energySpeed > 0 then
            self.energy = energyMax
            self.energySpeed = -self.data.energySpeedDefault
        end

        if self.data.isTouched then
            if self.data.isTouchedCounter ~= nil then
                self.data.isTouchedCounter = self.data.isTouchedCounter + 1
            end
        end
    end

    local function handleTouch(event)
        if app.gameRuns then
            local self = event.target
            appDragBody(self, event)
    
            if event.phase == 'began' then
                self.data.isTouchedCounter = 0
                self.data.isTouched = true
                self.data.touchStartPosition = {x = event.x, y = event.y}
            elseif event.phase == 'ended' or event.phase == 'cancelled' then
                self.data.isTouched = false
                local wasShortTap = self.data.isTouchedCounter == nil or self.data.isTouchedCounter < 10
                local wasDrag = false
                if self.data.touchStartPosition and event.x and event.y then
                    wasDrag = misc.getDistance(self.data.touchStartPosition, event) >= 8
                end
                self.data.touchStartPosition = nil
                self.data.isTouchedCounter = 0
    
                if wasShortTap and not wasDrag then
                    if not app.partSubtypes[self.subtype].rotationLocked then
                        self:makeSound('rotate', true)
                        self.targetRotation = self.rotation + misc.getIf(self.parentPlayer == 1, app.rotationStep, -app.rotationStep)
                    end
    
                    if self.subtype == 'amuletOfFate' or self.subtype == 'amuletOfFullFate' then
                        appReplaceUnusedParts(self.subtype, self.parentPlayer)
                        self.gone = true
                    end
                end
            end
    
            self.data.wasTouched = true

        end

        local continueEventPropagation = true
        return continueEventPropagation
    end

    local imageName = 'part-' .. direction .. '/' .. subtype
    local isAutoPhysical = true
    local physicsBody = 'rectangle'
    if subtype == 'wheel' then
        physicsBody = 'circle'
        width = width / 2
        height = nil
    end

    local self = spriteModule.spriteClass(physicsBody, 'dragPart', subtype, imageName, isAutoPhysical, thisX, thisY, width, height,
            nil, shapeOrShapes, playerI)
    self.bodyType = 'static'
    self.data.isAiOwned = isAiOwned
    self.isBullet = true
    self.isSleepingAllowed = false
    self.isFixedRotation = true
    self.data.wasTouched = false
    if wasTouched ~= nil then self.data.wasTouched = wasTouched end
    self.emphasizeAppearance = true

    self.data.shapeOrShapes = misc.cloneTable(shapeOrShapes)

    self.data.imageName = imageName
    self.data.isTouchedCounter = 0
    self.rotationSpeedLimit = app.rotationStep / 2

    self.rotation = 0
    local part = app.partSubtypes[subtype]
    if app.drawMode ~= 'hybrid' and not (part.rotationLocked or part.isCannon or part.alwaysFacesForward) then
        self.rotation = rotation
        if playerI == 2 then self.rotation = -self.rotation end
    end

    if self.data.isAiOwned then
        self.data.wasTouched = true
        local boundary = appGetAiBuildingBoundary()
        if boundary ~= nil then
            local rotationStepAi = app.rotationStep * 2
            self.rotation = math.random( 0, math.floor(app.maxRotation / rotationStepAi - 1) ) * rotationStepAi
            self.alpha = .5
            if app.partSubtypes[self.subtype].isCannon then self.rotation = 0 end
        end

    else
        self.alphaChangesWithEnergy = true
        self.data.energySpeedDefault = 2
        self.energy = 100 - self.data.energySpeedDefault * 2
        self.energySpeed = -self.data.energySpeedDefault
        self:addEventListener('touch', handleTouch)
    end

    if playerI == 1 then lastX = self.contentBounds.xMax end

    appAddSprite(self, handle, moduleGroup)
    if skipCreation then self.gone = true end

    return lastX
end

function self:getDragPartsSequenceSubtypes(useLongerSequence, subtypeToTryAvoid)
    local sequenceSubtypes = {}

    local subtypesWithHigherChance = appGetPartSubtypesWithHigherChance()
    local subtypesToEmphasizeSometimes = appGetPartSubtypesToEmphasizeSometimes()

    local testSequenceSubtypes = {}
    if not app.isLocalTest then testSequenceSubtypes = {} end

    local approximatePartsPerWagon = misc.getIf(app.settingsUseMorePartsPerWagon, 14, 8)
    local partsPerWagon = math.random(approximatePartsPerWagon - 1, approximatePartsPerWagon + 1)
    if useLongerSequence then partsPerWagon = partsPerWagon * 2 end

    for i = 1, partsPerWagon do
        local subtype = appGetRandomPartSubtype()
        local counterI = 1
        while subtype == subtypeToTryAvoid do
            subtype = appGetRandomPartSubtype()
            counterI = counterI + 1
            if counterI >= 10 then break end
        end
        
        if #subtypesWithHigherChance >= 1 and misc.getChance(5) then
            subtype = misc.getRandomEntry(subtypesWithHigherChance)
        end

        if app.isLocalTest and testSequenceSubtypes ~= nil then
            if testSequenceSubtypes[i] ~= nil then subtype = testSequenceSubtypes[i] end
        end

        sequenceSubtypes[#sequenceSubtypes + 1] = subtype
    end

    if app.partSubtypes.cannon.selected and not misc.inArray(sequenceSubtypes, 'cannon') and ( misc.getChance(75) or app.roundsPlayedSinceAppStart <= 2 ) then
        sequenceSubtypes[ math.random(1, #sequenceSubtypes) ] = 'cannon'
    end

    if ( misc.getChance(25) or useLongerSequence ) and app.roundsPlayedSinceAppStart >= 1 and #subtypesToEmphasizeSometimes >= 1 then
        local additionalSubtypesMax = 3
        for i = 1, additionalSubtypesMax do
            if misc.getChance(85) or useLongerSequence then
                sequenceSubtypes[#sequenceSubtypes + 1] = misc.getRandomEntry(subtypesToEmphasizeSometimes)
            end
        end
    end

    sequenceSubtypes = misc.shuffleArray(sequenceSubtypes)
    return sequenceSubtypes
end

function self:createPart(subtype, x, y, width, height, rotation, parentPlayer, shapeOrShapes, imageName)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.collisionForce[i] >= 6 then
                if self.collisionForce[i] <= 15 then
                    self:makeSound('wood-bump-soft')
                else
                    self:makeSound( 'wood-bump-' .. math.random(1, 2) )
                end
            end
        end

        if self.y >= app.visualGroundY + 10 then
            self:makeSound('explode')
            if not app.partSubtypes[self.subtype].explodesSparkFree then
                app.spritesHandler:createSparks(self.x, self.y, nil, self.data.baseColor, true)
            end
            app.spritesHandler:createShards(self)
            self.gone = true
        end

        if app.phase.name == 'battle' then

            if app.partSubtypes[self.subtype].isCannon then
                local hasBattleLion = appGetSpriteCountByType('part', 'battleLion', parentPlayer) >= 1
                if self.phase.name == 'default' then
                    if not self.phase:isInited() then
                        local averageTime = misc.getIf(hasBattleLion, 40, 80)
                        if self.subtype == 'blackCannon' and self.data.shotsFired >= 1 then
                            averageTime = averageTime * 2
                        end
                        local baseDelay = misc.getIf(self.subtype == 'twinCannon', averageTime / 2, averageTime)
                        if self.subtype == 'twinCannon' then
                            self.data.useTopCannon = not self.data.useTopCannon
                        end
                        self.phase:setNext( 'shoot', baseDelay + math.random(10) )
                    end
    
                elseif self.phase.name == 'shoot' then
                    if not self.phase:isInited() then
                        if app.phase:getSecondsPassed() >= 4 then
                            local y = self.y
                            if self.subtype == 'twinCannon' then
                                y = y + misc.getIf(self.data.useTopCannon, -28, -8)
                            elseif self.subtype == 'blackCannon' then
                                y = y -20
                            end
                            local cannonSpeedX, cannonSpeedY = app.spritesHandler:createCannonBall(self.x, y, self.rotation,
                                    self.parentPlayer, self.subtype)
                            local factor = .001
                            self:applyLinearImpulse(cannonSpeedX * -factor, 0)
                            self:toFront()
                            appSetToFrontByType('cloud', 'dust')
                            appSetToFrontByType('letterboxBar')
                            self:makeSound( 'cannon-shot-' .. math.random(1, 2) )
                            self.data.shotsFired = self.data.shotsFired + 1
                        end

                        if self.subtype == 'blackCannon' then
                            local shotsToFire = misc.getIf(hasBattleLion, 2, 1)
                            if self.data.shotsFired < shotsToFire then self.phase:set('default') end
                        else
                            self.phase:set('default')
                        end
                    end
                end
            end

            if self.subtype == 'stormVessel' then
                if misc.getChance(15) then
                    local enemyPlayer = misc.getIf(self.parentPlayer == 1, 2, 1)
                    local part = appGetSpriteByType('part', nil, enemyPlayer)
                    if part ~= nil then
                        local force = .3
                        local bodyOffset = 2
                        local xForce = misc.randomFloat(-force, force)
                        local yForce = misc.randomFloat(-force, force)
                        local xBody = part.width / 2 + misc.randomFloat(-bodyOffset, bodyOffset)
                        local yBody = part.height / 2 + misc.randomFloat(-bodyOffset, bodyOffset)
                        part:applyLinearImpulse(xForce, yForce, xBody, yBody)
                        if not self.data.didCauseStorm then
                            self.data.didCauseStorm = true
                            appPlaySound('storm')
                        end
                    end
                end

            elseif self.subtype == 'magpieStone' then
                if misc.getChance(3) and app.phase:getSecondsPassed() >= 3 and not self.data.didSteal then
                    local enemyPlayer = misc.getIf(self.parentPlayer == 1, 2, 1)
                    local ownWagon = appGetSpriteByType('wagon', nil, self.parentPlayer)
                    local part = appGetSpriteByType('part', nil, enemyPlayer)
                    if ownWagon ~= nil and part ~= nil then
                        app.spritesHandler:createPuffs(part)
                        self.data.didSteal = true
                        part.parentPlayer = self.parentPlayer
                        if part.subtype == 'rasEye' then
                            local rasBeam = appGetSpriteByParentId(part.parentId)
                            if rasBeam then rasBeam.gone = true end
                        end
                        part.x = ownWagon.x
                        part.y = 40
                        appPlaySound('whoosh')
                    end

                end

            elseif self.subtype == 'statueOfGenerosity' then
                if misc.getChance(3) and app.phase:getSecondsPassed() >= 4 then
                    local enemyPlayer = misc.getIf(self.parentPlayer == 1, 2, 1)
                    local wagon = appGetSpriteByType('wagon', nil, enemyPlayer)
                    if wagon ~= nil then
                        app.spritesHandler:createMeteor( wagon.x + math.random(-wagon.width / 2, wagon.width / 2), -30, 'silver' )
                    end
                end

            elseif self.subtype == 'statueOfProsperity' then
                if misc.getChance(3) and app.phase:getSecondsPassed() >= 4 then
                    local wagon = appGetSpriteByType('wagon', nil, self.parentPlayer)
                    if wagon ~= nil then
                        app.spritesHandler:createMeteor( wagon.x + math.random(-wagon.width / 2, wagon.width / 2), -30, 'gold' )
                    end
                end

            elseif self.subtype == 'rasEye' then
                if misc.getChance(1) and app.phase:getSecondsPassed() >= 4 and appGetChild(self.id) == nil then
                    local enemyPlayer = misc.getIf(self.parentPlayer == 1, 2, 1)
                    local part = misc.getRandomEntry( appGetSpritesByType('part', nil, enemyPlayer) )
                    if part ~= nil then
                        app.spritesHandler:createRasBeam(self, part)
                    end
                end

            end

        end

        if not self.isAwake then self.isAwake = true end
    end

    local density = nil
    local bounce = nil
    local friction = nil
    if subtype == 'bouncingLinen' then
        bounce = 1
        friction = 5
    end
    local part = app.partSubtypes[subtype]
    if part.hasHigherDensity then density = 3 end

    local physicsBody = 'rectangle'
    if subtype == 'wheel' then
        physicsBody = 'circle'
        width = width / 2 - 7
        height = nil
    end

    local self = spriteModule.spriteClass(physicsBody, 'part', subtype, imageName, true, x, y, width, height,
            nil, shapeOrShapes, parentPlayer, nil, density, bounce, friction)
    self.isBullet = true
    self.rotation = rotation
    self.data.imageName = imageName
    if part.isCannon then self.data.shotsFired = 0 end
    self.isSleepingAllowed = false

    local ironColor = {red = 160, green = 148, blue = 198}
    local woodColor = {red = 183, green = 119, blue = 64}
    self.data.baseColor = misc.getIf(part.isMostlyIron, ironColor, woodColor)

    self.listenToPostCollision = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createRasBeam(ras, part)
    local function handle(self)
        if self.energy >= 100 then self.energySpeed = -.5 end

        local parent = appGetSpriteByParentId(self.parentId)
        local target = appGetSpriteById(self.targetId)
        if not target then
            self.energySpeed = -2
            self.speedY = -5
        end

        if parent then
            if target then
                self.x = target.x
                self.height = target.y

                if misc.getChance(15) then app.spritesHandler:createPuffs(target, 1, 50) end

                target:setFillColor(1, .7, .7)

                if not misc.inArray( {'metalBarrier', 'metalSquare'}, target.subtype ) then
                    target.energy = target.energy - 2
                    if target.energy <= 0 then
                        app.spritesHandler:createShards(target)
                        appPlaySound('explode')
                    end
                end
            end

            if math.random(15) then
                self:setRgb( math.random(235, 255), math.random(186, 226), math.random(95, 135) )
            end

        else
            self.gone = true
        end
    end

    local points = {ras.x, ras.y, part.x, part.y}

    local height = part.y - part.height / 2 + 4
    local y = 0 + height / 2

    local self = spriteModule.spriteClass('rectangle', 'rasBeam', nil, nil, false, part.x, y, 10, height)
    self.alphaChangesWithEnergy = true
    self.energy = 1
    self.energySpeed = 2
    self.parentId = ras.id
    self.targetId = part.id
    self.doDieOutsideField = false
    self:setRgb(255,206,115)
    appAddSprite(self, handle, moduleGroup)

    appPlaySound('ras-beam')

    self:toBack()
    appPutBackgroundToBack()
end

function self:createMeteor(x, y, metalType)
    local function handle(self)
        if misc.getChance(20) then app.spritesHandler:createPuff(nil, self.x, self.y) end
    end

    local density = 13
    local self = spriteModule.spriteClass('rectangle', metalType .. 'Meteor', nil, 'meteor/' .. metalType, true, x, y, 21, 21,
            nil, nil, parentPlayer, nil, density)
    self.energy = 900
    self.parentPlayer = parentPlayer
    self.energySpeed = -10
    self.alphaChangesWithEnergy = true
    self.isBullet = true
    self.isSleepingAllowed = false
    self.speedLimit = 140
    self.doDieOutsideField = false
    self.rotation = math.random(0, 359)

    self:setLinearVelocity( 0, 150 + math.random(20) )
    appAddSprite(self, handle, moduleGroup)
    appPlaySound('whoosh')
end

function self:createCannonBall(cannonX, cannonY, rotation, parentPlayer, cannonSubtype)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if self.subtype == 'blackCannon' and other.type == 'part' and (other.subtype ~= 'bouncingLinen' and other.subtype ~= 'metalBarrier') then
                other:makeSound('explode')
                if not app.partSubtypes[other.subtype].explodesSparkFree then
                    app.spritesHandler:createSparks(other.x, other.y, nil, other.data.baseColor, true)
                end
                app.spritesHandler:createShards(other)
                other.gone = true
            end

            if other.type ~= 'cannonBall' then
                app.data.lastTimeCannonBallHit = app.phase:getSecondsPassed()
            end
        end

        if misc.getChance(20) then app.spritesHandler:createPuff(nil, self.x, self.y) end
    end

    local radius = 11.5
    local density = 7
    if cannonSubtype == 'goldenCannon' then density = 12 end
    
    local self = spriteModule.spriteClass('circle', 'cannonBall', cannonSubtype, 'cannonBall', true, cannonX, cannonY, radius, nil,
            nil, nil, parentPlayer, nil, density)
    self.energy = 900
    self.parentPlayer = parentPlayer
    self.energySpeed = -10
    self.alphaChangesWithEnergy = true
    self.isBullet = true
    self.isSleepingAllowed = false
    self.speedLimit = 85
    if cannonSubtype == 'goldenCannon' then self.speedLimit = 150 end

    self.rotation = rotation
    if cannonSubtype == 'twinCannon' then
        self.rotationImageOffset = misc.getIf(parentPlayer == 2, -180, 0)
    elseif cannonSubtype == 'blackCannon' then
        self.rotationImageOffset = misc.getIf(parentPlayer == 2, -170, -10)
    else
        self.rotationImageOffset = misc.getIf(parentPlayer == 2, -150, -30)
    end

    self.listenToPostCollision = true

    local speedX, speedY = self:adjustSpeedToRotation()
    appAddSprite(self, handle, moduleGroup)

    if cannonSubtype == 'goldenCannon' then
        speedX = speedX * .7
        speedY = speedY * .7
    end

    return speedX, speedY
end

function self:createWagon()
    local function handle(self)

        if self.phase.name == 'default' then
            for i, other in pairs(self.collisionWith) do
                if other.type == 'wagon' then
                    self.phase:set('stopSoon', 5, 'stop')
                    self:makeSound('wood-bump-1')
                    self.data.apparentlyUnderHeavyLoad = false
                end
            end
        end

        if app.phase.name == 'battle' and app.phase.inited and app.phase:getSecondsPassed() >= 5 and self.phase.name ~= 'stop' then
            local speedX = misc.getIf(self.parentPlayer == 1, self.speedLimitX, -self.speedLimitX)

            if not self.data.apparentlyUnderHeavyLoad then
                -- appDebug( math.floor(self.x) .. ' vs ' .. math.floor(self.originX) )
                local fuzzy = 4
                self.data.apparentlyUnderHeavyLoad = app.phase:getSecondsPassed() >= 6 and self.x >= self.originX - fuzzy and self.x <= self.originX + fuzzy
            end
            if self.data.apparentlyUnderHeavyLoad then
                self:setLinearVelocity(speedX * 1.5, 0)
            else
                self:setLinearVelocity(speedX, 0)
            end

            if not app.data.wagonMovementStarted then
                app.data.wagonMovementStarted = true
                self:makeSound('wheels')
            end
        end
    end

    appRemoveSpritesByType( {'wagon', 'wagonWheel', 'wagonShade'} )
    for playerI = 1, app.playerMax do
        local width = 279
        local height = 30
        local x = 208
        local y = app.physicalGroundY - height / 2
        if playerI == 2 then x = app.maxX - x end
        local self = spriteModule.spriteClass('rectangle', 'wagon', nil, 'wagon/base', true, x, y, width, height)
        self.parentPlayer = playerI
        self.doDieOutsideField = false
        self.isSleepingAllowed = false
        self.speedLimitX = 120 + math.random(20)
        self.listenToPostCollision = true
        appAddSprite(self, handle, moduleGroup)

        app.spritesHandler:createWagonWheels(self.x, self.y, self.id, self.parentPlayer)
        app.spritesHandler:createWagonShade(self.x, self.y, self.id, self.parentPlayer)
    end
end

function self:createWagonWheels(parentX, parentY, parentId, parentPlayer)
    local function handle(self)
        local distanceRolledSinceStart = math.floor(self.data.originX - self.x)
        local rotationOld = self.rotation
        self.rotation = -math.floor(distanceRolledSinceStart * 2.3)
        local rotationDistance = rotationOld - self.rotation
        if math.abs(rotationDistance) >= 1 then
            if misc.getChance(5) then
                local directionX = misc.getIf(rotationDistance < 0, -1, 1)
                local speedX = 3 * directionX
                app.spritesHandler:createPuff('dust', self.x - 8 * directionX, self.y + 11, speedX)
            end
        end
    end

    for wheelI = -1, 1 do
        local radius = 27
        local x = parentX + wheelI * 106
        local y = parentY + 14
        local self = spriteModule.spriteClass('circle', 'wagonWheel', nil, 'wagon/wheel', false, x, y, radius)
        self.rotation = math.random(0, 180)
        self.parentPlayer = parentPlayer
        self.parentId = parentId
        self.movesWithParent = true
        self.movesWithParentIsRelativeToOrigin = true
        self.doDieOutsideField = false
        self.data.originX = self.x
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createWagonShade(parentX, parentY, parentId, parentPlayer)
    local self = spriteModule.spriteClass('circle', 'wagonShade', nil, 'wagon/shade', false, parentX, parentY + 34, 339, 23)
    self.parentPlayer = parentPlayer
    self.parentId = parentId
    self.movesWithParent = true
    self.doDieOutsideField = false
    self.movesWithParentIsRelativeToOrigin = true
    self:toBack()
    appAddSprite(self, handle, moduleGroup)
end

function self:createPuffs(sprite, amount, startEnergy)
    if amount == nil then amount = 10 end
    for i = 1, amount do
        local x = sprite.x + math.random(-sprite.width / 2, sprite.width / 2)
        local y = sprite.y + math.random(-sprite.height / 2, sprite.height / 2)
        app.spritesHandler:createPuff(nil, x, y, 0, startEnergy)
    end
end

function self:createPuff(subtype, x, y, speedX, startEnergy)
    local function handle(self)
        if misc.getChance(5) then self:scale(.9, .9) end
    end

    if subtype == nil then subtype = 'smoke' end
    local radius = 9
    local imageName = 'puff-' .. subtype
    local self = spriteModule.spriteClass('circle', 'puff', subtype, imageName, false, x, y, radius)
    self.radius = radius
    self.energy = misc.getIf(startEnergy == nil, 70, startEnergy)
    self.energySpeed = -3
    self.alphaChangesWithEnergy = true
    self.speedX = speedX
    if subtype == 'dust' then self:scale(2.5, 2.5) end
    appAddSprite(self, handle, moduleGroup)
end

function self:createKnights()
    local function handle(self)
        if self.phase.name == 'default' then
            if not self.phase:isInited() then
                self.frameName = self.data.directionName .. '-default'
                self.speedX = 0
            end

            if self.subtype == 'pusher' then
                if misc.getChance(15) and app.data.wagonMovementStarted and app.phase:getSecondsPassed() <= 6 then
                    self.phase:set('push', 15, 'default')
                end
            elseif misc.getChance(1) then
                self.phase:set('walk', 15, 'default')
            end

        elseif self.phase.name == 'walk' then
            if not self.phase:isInited() then
                self.frameName = self.data.directionName .. '-walk'
                self.speedX = .2 * self.data.direction
                if misc.getChance(50) then self.speedX = self.speedX * -1 end
            end

        elseif self.phase.name == 'push' then
            if not self.phase:isInited() then
                self.frameName = self.data.directionName .. '-push'
            end

        elseif self.phase.name == 'cheer' then
            if not self.phase:isInited() then
                self.frameName = self.data.directionName .. '-cheer'
                self.speedX = 0
            end
            if misc.getChance(10) then self.phase:set('cheer2') end

        elseif self.phase.name == 'cheer2' then
            if not self.phase:isInited() then
                self.frameName = self.data.directionName .. '-cheer2'
                if misc.getChance(25) then self.frameName = self.data.directionName .. '-default' end
                self.speedX = 0
            end
            if misc.getChance(10) then self.phase:set('cheer') end

        elseif self.phase.name == 'retreat' or self.phase.name == 'stormCastle' then
            if not self.phase:isInited() then
                self.data.direction = misc.getIf(self.parentPlayer == 1, -1, 1)
                if self.phase.name == 'stormCastle' then self.data.direction = self.data.direction * -1 end

                self.data.directionName = misc.getIf(self.data.direction == -1, 'left', 'right')
                self.frameName = self.data.directionName .. '-default'
                self.speedX = ( 1 + math.random(0, 10) * .1 ) * self.data.direction

                self.data.walkCounterMax = 30
                self.data.walkCounter = self.data.walkCounterMax + math.random(15)
            end

            if self.data.walkCounter ~= nil and self.data.walkCounterMax ~= nil then
                self.data.walkCounter = self.data.walkCounter - 1
                if self.data.walkCounter == 20 then
                    self.frameName = self.data.directionName .. '-walk'
                elseif self.data.walkCounter <= 0 then
                    self.frameName = self.data.directionName .. '-default'
                    self.data.walkCounter = self.data.walkCounterMax
                end
            end

            if misc.getChance(5) then
                app.spritesHandler:createPuff('dust', self.x, self.y + 20, self.speedX * -1)
            end

        end
    end

    appRemoveSpritesByType('knight')
    local knightsPerPlayer = 8
    local width = 62; local height = 71
    local framesData = {
            image = {width = 372, height = 142, count = 12},
            names = {
            {name = 'right-default', start = 1},
            {name = 'right-cheer', start = 2},
            {name = 'right-cheer2', start = 3},
            {name = 'right-walk', start = 4},
            {name = 'right-push', start = 5},

            {name = 'left-default', start = 7},
            {name = 'left-cheer', start = 8},
            {name = 'left-cheer2', start = 9},
            {name = 'left-walk', start = 10},
            {name = 'left-push', start = 11}
            }
            }

    for playerI = 1, app.playerMax do
        for knightI = 1, knightsPerPlayer do
            local x = app.minX + math.random(400)
            if playerI == 2 then x = app.maxX - x end
            local y = 672 + math.random(-3, 3)
            local self = spriteModule.spriteClass('rectangle', 'knight', nil, 'knight-' .. playerI, false, x, y, width, height, framesData)
            self.parentPlayer = playerI
            self.doDieOutsideField = false
        
            self.data.direction = misc.getIf(self.parentPlayer == 1, 1, -1)
            self.data.directionName = misc.getIf(self.data.direction == -1, 'left', 'right')
            self.frameName = self.data.direction .. '-default'

            if knightI == 1 then
                local wagon = appGetSpriteByType('wagon', nil, self.parentPlayer)
                if wagon ~= nil then
                    self.parentId = wagon.id
                    self.subtype = 'pusher'
                    self.movesWithParent = true
                    self.disappearsWithParent = false
                    self.movesWithParentIsRelativeToOrigin = true
                    local offset = 10
                    self.x = misc.getIf(self.parentPlayer == 1, wagon.x - wagon.width / 2 - offset, wagon.x + wagon.width / 2 + offset)
                    self.y = 670
                end
            end
    
            appAddSprite(self, handle, moduleGroup)
        end
    end
end

function self:createGround()
    appRemoveSpritesByType('ground')
    local margin = 30
    local height = 40
    local self = spriteModule.spriteClass('rectangle', 'ground', nil, nil, true, app.maxXHalf, app.physicalGroundY + height / 2, app.maxX + margin * 2, height)
    self.bodyType = 'static'
    self.isVisible = false
    self.parentPlayer = playerI
    appAddSprite(self, handle, moduleGroup)
end

function self:createBorderWall()
    appRemoveSpritesByType('borderWall')
    local self = spriteModule.spriteClass('rectangle', 'borderWall', nil, nil, true, app.maxXHalf, app.maxYHalf, 40, app.maxY)
    self.bodyType = 'static'
    self.isBullet = true
    self.isSleepingAllowed = false
    self.isVisible = false -- self:setRgb(255, 255, 255, 50)
    appAddSprite(self, handle, moduleGroup)
end

function self:createShards(sprite)
    --[[
    if not app.isVeryOldAndPossiblySlowIPad then
        local padding = 1; local speed = 8; rotationSpeed = 2
        local maskMax = 5
        for i = 1, 8 do
            local self = spriteModule.spriteClass('rectangle', 'graphicShard', nil, sprite.originalImage, false,
                    sprite.x, sprite.y, sprite.width, sprite.height)
            self.energy = 200
            self.energySpeed = -4
            self.alphaChangesWithEnergy = true
            self.speedX = math.random(-speed, speed)
            self.speedY = math.random(-speed, speed)
            self.targetSpeedY = 20
            self.rotationSpeed = math.random(-rotationSpeed, rotationSpeed)
            appAddSprite(self, handle)

            local maskI = math.random(1, maskMax)
            local mask = graphics.newMask( 'image/mask/' .. maskI .. '.png' )
            self:setMask(mask)
            self.maskX = math.random(padding, self.width - padding)
            self.maskY = math.random(padding, self.height - padding)
            self.maskScaleX = display.contentScaleX
            self.maskScaleY = display.contentScaleY
        end
    end
    --]]
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
            self.speedY = math.random(-speedLimit, speedLimit / 2) + 3

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

function self:createEmphasizeAppearanceEffect(x, y)
    local function handle(self)
        self:adjustRadius(-1)
    end
    
    local radius = 40
    local self = spriteModule.spriteClass('circle', 'emphasis', nil, nil, false, x, y, radius)
    self.radius = radius
    self.energy = 70
    self.energySpeed = -4
    self.alphaChangesWithEnergy = true
    self:setRgbWhite()
    appAddSprite(self, handle, moduleGroup)
end

function self:createEmphasizeDisappearanceEffect(x, y)
    local function handle(self)
        self:adjustRadius(1)
    end

    local radius = 15
    local self = spriteModule.spriteClass('circle', 'emphasis', nil, nil, false, x, y, radius)
    self.radius = radius
    self.energy = 90
    self.energySpeed = -3
    self.alphaChangesWithEnergy = true
    self:setRgbWhite()
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
                self.targetY = math.random(app.horizonY - 120, app.horizonY + 5)
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
    local maxBirds = 5
    local swarmX = math.random(app.minX + 250, app.maxX - 250)
    local swarmY = math.random(app.horizonY - 120, app.horizonY + 5)
    local spriteSheetWidth = 66; local spriteSheetHeight = 14
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

function self:createTestRectangle(baseRect)
    local self = spriteModule.spriteClass('rectangle', 'testRectangle', nil, nil, false, baseRect.x, baseRect.y, baseRect.width, baseRect.height)
    if baseRect.rotation ~= nil then self.rotation = baseRect.rotation end
    self:setRgbWhite()
    self.alpha = .65
    appAddSprite(self, handle, moduleGroup)
end

function self:createSunTransition()
    local size = 688
    local self = spriteModule.spriteClass('rectangle', 'sunTransition', nil, 'sun', false, app.maxXHalf, 296, size, size)
    self.rotationSpeed = 3
    self.energySpeed = -2
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createClouds()
    local function handle(self)
        local margin = misc.getIf(subtype == 'dust', 300, 900)
        if self:bounceOffAppBoundary(margin) then
            self.speedX = math.random(self.data.speedMin, self.speedLimit) * misc.getDirection(self.speedX)
        end
    end

    local subtypes = {'dust', 'sky'}
    local dustX = -100
    if misc.getChance() then dustX = app.maxX - dustX end
    for i = 1, #subtypes do
        local subtype = subtypes[i]
        local x = misc.getIf(subtype == 'dust', dustX, app.maxX - dustX)
        local y = misc.getIf(subtype == 'dust', 630, 200)
        y = y + appGetSpriteCountByType('cloud', subtype) * 80
        local self = spriteModule.spriteClass('rectangle', 'cloud', subtype, 'cloud-' .. subtype, false, x, y, 795, 382)
        self.doDieOutsideField = false
        self.data.speedMin = 1
        self.speedLimit = 3
        self.speedX = math.random(self.data.speedMin, self.speedLimit)
        if misc.getChance() then self.speedX = self.speedX * -1 end
        -- self:setRgbRandom()

        if subtype == 'sky' then self:toBack() end
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createScoreShields()
    appRemoveSpritesByType('scoreShield')
    for playerI = 1, app.playerMax do
        for scoreI = 1, app.scoreMax do
            local hasPoint = app.score[playerI] >= scoreI

            local startX = misc.getIf(playerI == 1, 252, 952)
            if app.language == 'zh' and playerI == 1 then startX = 132 end
            local width = 15
            local height = 17
            local x = startX + (scoreI - 1) * 19 + width / 2
            local y = 750
            local imageName = 'scoreShield/empty'
            if hasPoint then imageName = 'scoreShield/full-' .. playerI end
            local self = spriteModule.spriteClass('rectangle', 'scoreShield', nil, imageName, false, x, y, width, height)
            self.parentPlayer = playerI
            self.emphasizeAppearance = hasPoint
            appAddSprite(self, handle, moduleGroup)
        end
    end
end

function self:createMessageImage(imageName, x, y, width, height, shakeSpeedX, shakeSpeedY, doFadeIn)
    if doFadeIn == nil then doFadeIn = false end

    local self = spriteModule.spriteClass('rectangle', 'message', nil, 'message-' .. imageName, false, x, y, width, height)
    self:pushIntoAppBorders()
    if doFadeIn then
        self.energy = 1
        self.energySpeed = .5
        self.alphaChangesWithEnergy = true
    end
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
    appAddSprite(self, handle, moduleGroup)
end

function self:createSetPartsButton()
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'ended' then
            app.menu:prepareCreateDialogSetParts()
        end
        return false
    end

    local self = spriteModule.spriteClass('rectangle', 'setPartsButton', nil, 'set-parts-button', false, app.maxXHalf, 320, 146, 18)
    self:addEventListener('touch', handleTouch)

    appAddSprite(self, handle, moduleGroup)
end

function self:createSecondsText()
    local function handle(self)
        local secondsLeft = app.phase:getSecondsLeft()
        if secondsLeft ~= self.text then
            self.text = secondsLeft
        end
    end

    local secondsLeft = app.phase:getSecondsLeft()
    local frontSprite = nil
    for xOff = -2, 2 do
        for yOff = -2, 2 do
            local x = app.maxXHalf + xOff
            local y = 284 + yOff
            local self = spriteModule.spriteClass('text', 'text', 'secondsText', nil, false, x, y)
            self:setFontSize(26)
            self.text = secondsLeft
            self.alpha = .6
            self:setRgb(78, 144, 223)
            if math.abs(xOff) == 2 or math.abs(xOff) == 2 then
                self.alpha = .15
            elseif xOff == 0 and yOff == 0 then
                self:setRgb(237, 255, 168)
                self.alpha = 1
                frontSprite = self
            end

            appAddSprite(self, handle, moduleGroup)
        end
    end
    frontSprite:toFront()
end

function self:createText(subtype, x, y, fontSize, fontColor)
    if fontSize == nil then fontSize = 26 end
    if fontColor == nil then fontColor = {red = 237, green = 255, blue = 168} end
    local self = spriteModule.spriteClass('text', 'text', subtype, nil, false, x, y)
    self:setFontSize(fontSize)
    self:setRgbByColorTriple(fontColor)
    appAddSprite(self, handle, moduleGroup)
end

return self
end