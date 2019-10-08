module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createRebelObject(subtype, x, y, rotation)
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'began' then
            if not appASpriteIsDragged() then
                self.data.xBeforeDrag, self.data.yBeforeDrag = self.x, self.y

                self.data.touchOffsetX = self.x - event.x
                self.data.touchOffsetY = self.y - event.y

                display.getCurrentStage():setFocus(self)
                self.isDragged = true
                self.x = event.x + self.data.touchOffsetX
                self.y = event.y + self.data.touchOffsetY + self.data.fingerDraggingOffsetY
                local glow = appGetSpriteByTypeAndParentId('rebelObjectGlow', self.id)
                if glow ~= nil then glow.data.adjustPosition = true end
                appPlaySound('pickUp')
                appHandleRotationRing(self)
            end

        elseif event.phase == 'moved' then
            if self.isDragged then
                self.x = event.x + self.data.touchOffsetX
                self.y = event.y + self.data.touchOffsetY + self.data.fingerDraggingOffsetY

                local glow = appGetSpriteByTypeAndParentId('rebelObjectGlow', self.id)
                if glow ~= nil then glow.data.adjustPosition = true end
                appHandleRotationRing(self)
            end

        elseif event.phase == 'ended' or event.phase == 'cancelled' then
            if self.isDragged then
                self.x = event.x + self.data.touchOffsetX
                self.y = event.y + self.data.touchOffsetY

                self.isDragged = false
                appPlaySound('putDown')
                display.getCurrentStage():setFocus(nil)
                appHandleRotationRing(self)

                self.data.dragCounter = 0
                self.data.touchOffsetX = nil
                self.data.touchOffsetX = nil
            end

        end
    end

    local function handle(self)
        for i, other in pairs(self.collisionWith) do

            if self.subtype == 'multiplier' then
                if not other.data.wasClonedAt[self.id] then
                    other.data.wasClonedAt[self.id] = true
                    local oldOther = self.collisionWithPreState[i]
                    local factor = .15
                    local bulletClone = app.spritesHandler:createBullet(
                            oldOther.x + oldOther.speedX * factor,
                            oldOther.y + oldOther.speedY * factor,
                            oldOther.rotation, true)
                    bulletClone:setLinearVelocity(oldOther.speedX, oldOther.speedY)
                    bulletClone.energy = other.energy * .5
                    bulletClone.energySpeed = other.energySpeed
                    if other.group ~= 'interface' then appPlaySound('multiply') end
                    appHandleGeneralCollideBehavior(self, other)
                end

            elseif self.subtype == 'portal' then
                if other.data.touchJoint == nil and not self.data.didTeleportBullet[other.id] then
                    local targetPortal = appGetTargetPortal(self, other)
                    if targetPortal ~= nil then
                        other.data.oldPoint = nil
                        self.data.didTeleportBullet[other.id] = true
                        targetPortal.data.didTeleportBullet[other.id] = true
                        other.x, other.y = targetPortal.x, targetPortal.y
                        if other.group ~= 'interface' then appPlaySound('teleport') end
                        appHandleGeneralCollideBehavior(self, other)
                        appHandleGeneralCollideBehavior(targetPortal, other)
                        other.data.trailId = nil
                    end
                end

            elseif self.subtype == 'charger' then
                if not self.data.didChargeBullet[other.id] then
                    self.data.didChargeBullet[other.id] = true
                    other.energy = other.energyMax
                    other.energySpeed = 5
                    other.alpha = 1
                    if other.group ~= 'interface' then appPlaySound('charge') end
                    appHandleGeneralCollideBehavior(self, other)
                end

            elseif self.subtype == 'bumper' then
                if other.group ~= 'interface' then appPlaySound('bump') end
                appHandleGeneralCollideBehavior(self, other)

            end
        end

    end

    local function handleMagnetCollision(self, event)
        local function onDelay(timerEvent)
            local rebelObject = app.sprites[timerEvent.source.rebelObjectId]
            local bullet = app.sprites[timerEvent.source.bulletId]

            if timerEvent.source.action == 'makeJoint' then
                if rebelObject ~= nil and bullet ~= nil and not bullet.data.wasMagneticTowards[rebelObject.id] then
                    bullet.data.wasMagneticTowards[rebelObject.id] = true

                    if bullet.data.maxVelocity == nil then
                        local speedXBefore, speedYBefore = bullet:getLinearVelocity()
                        local lenBefore = math.sqrt(speedXBefore * speedXBefore + speedYBefore * speedYBefore)
                        bullet.data.maxVelocity = math.floor(lenBefore)
                    end

                    rebelObject.data.touchJoint = physics.newJoint('touch', bullet, bullet.x, bullet.y)
                    rebelObject.data.touchJoint.frequency = .3
                    rebelObject.data.touchJoint.dampingRatio = 0.0
                    rebelObject.data.touchJoint:setTarget(rebelObject.x, rebelObject.y)
                end

            elseif timerEvent.source.action == 'removeJoint' then
                if rebelObject ~= nil and bullet ~= nil and rebelObject.data.touchJoint ~= nil then
                    if rebelObject.data.touchJoint then
                        if rebelObject.data.touchJoint.removeSelf then rebelObject.data.touchJoint:removeSelf() end
                        rebelObject.data.touchJoint = nil
                    end

                    local speedX, speedY = bullet:getLinearVelocity()
                    local len = math.sqrt(speedX * speedX + speedY * speedY)
                    local factor = bullet.data.maxVelocity / len
                    speedX = speedX * factor; speedY = speedY * factor
                    bullet:setLinearVelocity(speedX, speedY)
                end
            end
        end

        if event.phase == 'began' then
            local thisTimer = timer.performWithDelay(10, onDelay)
            thisTimer.rebelObjectId = self.id
            thisTimer.bulletId = event.other.id
            thisTimer.action = 'makeJoint'

            appHandleGeneralCollideBehavior(self, event.other)
            if app.runs then appPlaySound('magnet') end

        elseif event.phase == 'ended' then
            local thisTimer = timer.performWithDelay(10, onDelay)
            thisTimer.rebelObjectId = self.id
            thisTimer.bulletId = event.other.id
            thisTimer.action = 'removeJoint'

        end
    end

    if rotation == nil then rotation = 0 end
    local image = 'rebelObject/' .. subtype
    local self = nil
    local isPhysical = true
    local defaultSize = 72

    if subtype == 'bumper' then
        local thisSize = 61
        self = spriteModule.spriteClass('rectangle', 'rebelObject', subtype, image, isPhysical, x, y, thisSize, thisSize,
                nil, nil, nil, density, bounce, friction)
        self.listenToPostCollision = true
        self.data.isRotateable = true

    elseif subtype == 'portal' then
        local isSensor = true
        self = spriteModule.spriteClass('circle', 'rebelObject', subtype, image, isPhysical, x, y, defaultSize * .25, nil,
                nil, nil, isSensor)
        self.width = defaultSize
        self.height = self.width
        self.listenToCollision = true
        self.data.connectionGroup = app.creationObjectIndex - 1

        local count = appGetOtherPortalGroupCount(self.data.connectionGroup)
        if count == 0 then self.rotationSpeed = .5
        elseif count == 1 then self.rotationSpeed = -.5
        elseif count == 2 then self.rotationSpeed = 0
        elseif count == 3 then self.rotationSpeed = 4
        elseif count == 4 then self.rotationSpeed = -4
        end

        app.spritesHandler:createPortalInner(self)

    elseif subtype == 'charger' then
        local isSensor = true
        self = spriteModule.spriteClass('circle', 'rebelObject', subtype, image, isPhysical, x, y, defaultSize * .5, nil,
                nil, nil, isSensor)
        self.width = defaultSize
        self.height = self.width
        self.listenToCollision = true
        self.alpha = .5
        app.spritesHandler:createChargerInner(self)

    elseif subtype == 'multiplier' then
        local width, height = 73, 73
        local halfWidth, halfHeight = width / 2, height / 2
        local halfInnerWidth, halfInnerHeight = 49 / 2, 13 / 2
        local shape = {
                math.floor(halfWidth - halfInnerWidth), math.floor(halfHeight - halfInnerHeight),
                math.floor(halfWidth + halfInnerWidth), math.floor(halfHeight - halfInnerHeight),
                math.floor(halfWidth + halfInnerWidth), math.floor(halfHeight + halfInnerHeight),
                math.floor(halfWidth - halfInnerWidth), math.floor(halfHeight + halfInnerHeight)
                }
        self = spriteModule.spriteClass('rectangle', 'rebelObject', subtype, image, isPhysical, x, y, width, height,
                nil, shape, nil, density, bounce, friction)
        self.listenToPreCollision = true
        self.data.isRotateable = true

    elseif subtype == 'magnet' then
        local isSensor = true
        local radius = 125
        self = spriteModule.spriteClass('circle', 'rebelObject', subtype, image, isPhysical, x, y, radius, nil,
                nil, nil, isSensor)
        self.width = defaultSize
        self.height = defaultSize
        self.collision = handleMagnetCollision
        self:addEventListener('collision', self)
        app.spritesHandler:createMagnetRing(self)
        app.spritesHandler:createMagnetRadius(self)

    end

    self.bodyType = 'static'
    self:addEventListener('touch', handleTouch)
    self.data.fingerDraggingOffsetY = 0 -- -50
    self.data.didTeleportBullet = {}
    self.data.didChargeBullet = {}
    self.blendMode = 'add'
    self.rotation = rotation
    self.data.isMagneticTowards = {}
    self.isSleepingAllowed = true
    self:initPhase()
    appAddSprite(self, handle, 'interface')

    app.spritesHandler:createRebelObjectGlow(self)
    self:toFront()

    appHandleGeneralCollideBehavior(self)

    return self
end

function self:createRotationRing(parent)
    local function handleTouch(event)

        local self = event.target
        if event.phase == 'began' then
            local fuzzy = 18
            local distanceFromRingCenter = misc.getDistance( {x = self.x, y = self.y}, {x = event.x, y = event.y} )
            local isActuallyOnRingGraphic = distanceFromRingCenter >= 127 - fuzzy and distanceFromRingCenter <= 170 + fuzzy

            if not appASpriteIsDragged() and isActuallyOnRingGraphic then
                display.getCurrentStage():setFocus(self)
                self.isDragged = true
                self.data.rotationOld = self.rotation
                self.data.xOld, self.data.yOld = event.x, event.y
                self.data.rotationBeforeDrag = self.rotation
                self.energy = self.energyMax
                if self.energySpeed < 0 then self.energySpeed = 0 end
                self.phase:set('beingRotated')
            end

        elseif event.phase == 'moved' then
            if self.isDragged then
                self.data.x, self.data.y = event.x, event.y

                local angle1 = 180 / math.pi * math.atan2(self.data.yOld - self.y , self.data.xOld - self.x)
                local angle2 = 180 / math.pi * math.atan2(self.data.y - self.y , self.data.x - self.x)
                local rotationAmount = angle1 - angle2

                self.rotation = self.rotation - rotationAmount
                
                local rebelObject = self:getParent()
                if rebelObject ~= nil then
                    rebelObject.rotation = self.rotation
                    appPlaySound('click')
                end

                self.data.xOld, self.data.yOld = self.data.x, self.data.y
                self.energy = self.energyMax
                if self.energySpeed < 0 then self.energySpeed = 0 end
            end

        elseif event.phase == 'ended' or event.phase == 'cancelled' then
            if self.isDragged then
                app.didUseRotationRing = true
                self.rotation = misc.normalizeRotationAngle(self.rotation)
                display.getCurrentStage():setFocus(nil)
                self.data.rotationOld = nil

                local rebelObject = self:getParent()
                if rebelObject ~= nil then
                    rebelObject.rotation = self.rotation
                    appPlaySound('click')
                end
                self.isDragged = false
                self.energy = self.energyMax
                self.energySpeed = self.data.energySpeedDefault
                self.phase:set('default')
            end

        end

    end

    local function handle(self)

        if self.phase.name == 'default' then
            if self.energySpeed >= 0 and self.energy >= self.energyMax then
                self.energySpeed = self.data.energySpeedDefault
            end
            if self.energySpeed == self.data.energySpeedDefault and self.energy <= 25 then
                self.energySpeed = self.data.energySpeedDefault * 6
            end

        elseif self.phase.name == 'showRotation' then

            self.rotation = self.rotation + 3
            local maxRotation = 90
            if self.rotation >= maxRotation then
                self.rotation = maxRotation
                self.phase:set('default')
            end

            local rebelObject = self:getParent()
            if rebelObject ~= nil then
                rebelObject.rotation = self.rotation
            end

        end
    end

    local radius = 186
    appRemoveSpritesByType('rotationRing')
    local image = misc.getIf(app.didUseRotationRing, 'rotationRing', 'rotationRingWithHelp')
    local self = spriteModule.spriteClass('rectangle', 'rotationRing', nil, image, false, parent.x, parent.y, radius, nil)
    self.width = radius * 2
    self.height = self.width
    self.parentId = parent.id
    self.movesWithParent = true
    self.blendMode = 'add'
    self.energyMax = 60
    self.data.energySpeedDefault = -.35
    self.energy = 1
    self.energySpeed = 5
    self.alphaChangesWithEnergy = true
    self:initPhase()
    if not app.didUseRotationRing then self.phase:set('showRotation') end
    self.data.rotationBeforeDrag = self.rotation
    self.rotation = parent.rotation
    self.data.rotationOld = nil
    self.data.x, self.data.y = nil, nil
    self.data.xOld, self.data.yOld = nil, nil
    self:addEventListener('touch', handleTouch)
    appAddSprite(self, handle, 'interface')

    self:toBack()
    appBackgroundToBack()
end

function self:createMagnetRing(parent)
    local function handle(self)
        self.data.scale = self.data.scale - .02
            self.alpha = self.alpha - .005

        if self.data.scale <= .1 then
            self.data.scale = 1
            self.alpha = .6
        end

        self.xScale, self.yScale = self.data.scale, self.data.scale
    end

    local self = spriteModule.spriteClass('rectangle', 'magnetRing', nil, parent.originalImage, false, parent.x, parent.y, parent.width, parent.height)
    self.parentId = parent.id
    self.movesWithParent = true
    self.blendMode = 'add'
    self.data.scale = 1
    self.alpha = .4
    self.group = 'interface'
    appAddSprite(self, handle)
end

function self:createMagnetRadius(parent)
    local self = spriteModule.spriteClass('rectangle', 'magnetRadius', nil, 'rebelObject/magnetRadius', false, parent.x, parent.y, parent.radius, nil)
    self.width = parent.radius * 2
    self.height = self.width
    self.parentId = parent.id
    self.movesWithParent = true
    self.alpha = .3
    self.group = 'interface'
    appAddSprite(self, handle)    
end

function self:createPortalInner(parent)
    local self = spriteModule.spriteClass('rectangle', 'portalInner', nil, 'portalInner', false, parent.x, parent.y, parent.width, parent.height)
    self.parentId = parent.id
    self.movesWithParent = true
    self.blendMode = 'add'
    self.rotationSpeed = -2
    self.group = 'interface'
    appAddSprite(self, handle)    
end

function self:createChargerInner(parent)
    local self = spriteModule.spriteClass('rectangle', 'chargerInner', nil, 'chargerInner', false, parent.x, parent.y, parent.width, parent.height)
    self.parentId = parent.id
    self.movesWithParent = true
    self.rotationSpeed = 1
    self.group = 'interface'
    appAddSprite(self, handle)    
end

function self:createRebelObjectGlow(parent)
    local function handle(self)
        local parent = self:getParent()
        if parent ~= nil then

            if self.data.adjustPosition then
                local x = math.abs(parent.x + app.maxXHalf) * .5
                local y = math.abs(parent.y + app.maxYHalf) * .5

                for i = 1, 3 do
                    x = math.abs(parent.x + x) * .5
                    y = math.abs(parent.y + y) * .5
                end
                self.x, self.y = x, y

                self.data.adjustPosition = false
            end

        else
            self.gone = true

        end
    end

    local self = spriteModule.spriteClass('rectangle', 'rebelObjectGlow', parent.subtype, parent.originalImage, false, parent.x, parent.y, parent.width, parent.height)
    self.parentId = parent.id
    self.rotation = parent.rotation
    self.blendMode = parent.blendMode
    self.alpha = parent.alpha * .3
    self.data.adjustPosition = true
    local scale = .8 * misc.getIf(parent.data.scale ~= nil, parent.data.scale, 1)
    self.data.scale = scale
    self.rotatesWithParent = true
    self:scale(scale, scale)
    appAddSprite(self, handle, 'interface')
end

function self:createTowers()
    for i = 1, #app.mapData[app.mapNumber].towers do
        local tower = app.mapData[app.mapNumber].towers[i]
        app.spritesHandler:createTower(tower.x, tower.y, tower.rotation)
    end
end

function self:createTower(x, y, rotation)
    local function handle(self)
        if self.phase.name == 'default' then
            if not self.phase:isInited() then
                local frequency = misc.getIf(app.runs, 55, 15)
                self.phase:setNext('shoot', frequency)
            end

        elseif self.phase.name == 'shoot' then
            if not self.phase:isInited() then
                app.spritesHandler:createBullet(self.x, self.y, self.rotation)
                if app.runs then
                    app.spritesHandler:createTowerShootGlow(self)
                    if self.data.isLeadTower then appPlaySound('shoot') end
                end
                self.phase:set('default')
            end

        end
    end

    local size = 94
    local thisX = x + size / 2
    local thisY = y + size / 2
    local self = spriteModule.spriteClass('rectangle', 'tower', nil, 'tower/base', false, thisX, thisY, size, size)
    self.rotation = rotation
    self.data.isLeadTower = appGetSpriteCountByType('tower') == 0
    -- self.isVisible = false
    -- self.isVisible = true; self.alpha = .5 --
    self:initPhase()
    appAddSprite(self, handle, 'interface')
end

function self:createTowerShootGlow(tower)
    local self = spriteModule.spriteClass('rectangle', 'towerShootGlow', nil, 'tower/glow', false, tower.x, tower.y, tower.width, tower.height)
    self.rotation = tower.rotation
    self.energySpeed = -5
    self.scaleSpeed = 1.05
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, tower.group)
end

function self:createBullet(x, y, rotation, isCloned)
    local function handle(self)

        if self.energySpeed >= 0 and self.energy >= self.energyMax then
            self.energySpeed = -1
            self.energy = self.energyMax
        end

        if self.energy >= 15 then
            local trail = nil
            if self.data.trailId ~= nil then trail = app.sprites[self.data.trailId] end
            if trail ~= nil then
                trail:append(self.x, self.y)
                trail.data.points = trail.data.points + 1
                if trail.data.points >= 15 then
                    self.data.trailId = nil
                end
    
            else
                local rgb = misc.getIf( self.subtype == 'clone', {red = 89, green = 128, blue = 177}, {red = 255, green = 182, blue = 202} )
                if not app.runs then rgb = {red = 255, green = 255, blue = 255} end

                if self.data.oldPoint ~= nil then
                    local points = {self.data.oldPoint.x, self.data.oldPoint.y, self.x, self.y}
                    self.data.trailId = app.spritesHandler:createTrailLine(self.id, points, self.data.radius, 120, rgb)
                end
    
            end
    
            self.data.oldPoint = {x = self.x, y = self.y}
        end

        self:toFront()
    end

    if isCloned == nil then isCloned = false end

    local image = 'bullet' .. misc.getIf(isCloned, 'Clone', '')
    local subtype = misc.getIf(isCloned, 'clone', nil)
    local density = 1; local friction = 0; local bounce = 1

    local radius = 12
    local self = spriteModule.spriteClass('circle', 'bullet', subtype, image, true, x, y, radius, nil,
        nil, nil, nil, density, bounce, friction)
    self.data.radius = radius
    self.width = 57
    self.height = self.width
    self:initPhase()

    self.energySpeed = 0
    self.energyMax = 175
    if not isCloned then
        self.energy = 5
        self.energySpeed = 5
        self.alpha = 0
    end
    self.isSleepingAllowed = false
    self.data.wasClonedAt = {}
    self.data.wasMagneticTowards = {}
    self.data.oldVelocityX, self.data.oldVelocityY = 0, 0
    self.alphaChangesWithEnergy = true
    self.doDieOutsideField = true
    self.data.maxVelocity = nil
    self.isBullet = true
    local group = nil
    if not app.runs then
        group = 'interface'
        self.isVisible = false
        self.isHitTestable = true --
    end

    appAddSprite(self, handle, group)

    self.speedLimit = .05
    if not isCloned then
        self:pushTowardsDirection(rotation, true)
    end
    self.data.oldPoint = {x = self.x, y = self.y}

    local towers = appGetSpritesByType('tower')
    for i = 1, #towers do
        local tower = towers[i]
        app.spritesHandler:createReflection(tower.id, self.id)
    end

    return self
end

function self:createReflection(parentId, reflectionSourceId)
    local function handle(self)
        local reflectionSource = app.sprites[self.data.reflectionSourceId]
        if reflectionSource ~= nil then
            local centerPoint = {x = self.originX, y = self.originY}
            local targetPoint = reflectionSource:getPoint()
            local offsetX, offsetY = misc.getNeededSpeedByTargetPoint(self.data.offset, centerPoint, targetPoint)
            if offsetX ~= nil and offsetY ~= nil and not ( misc.isNan(offsetX) or misc.isNan(offsetY) ) then
                self.x = self.originX + offsetX
                self.y = self.originY + offsetY
                self.alpha = reflectionSource.alpha * .8
                local scale = .8 - misc.getDistance(centerPoint, targetPoint) * .002
                if scale > 0 then
                    local maxScale = misc.keepInLimits(scale, .2, .6)
                    self.xScale, self.yScale = scale, scale
                end
            end
        else
            self.gone = true

        end

        self:toFront()
    end

    local reflectionSource = app.sprites[reflectionSourceId]
    local parent = app.sprites[parentId]
    if reflectionSource ~= nil and parent ~= nil then
        local width, height = reflectionSource.width, reflectionSource.height
        local self = spriteModule.spriteClass('rectangle', 'reflection', reflectionSource.type, reflectionSource.originalImage, false, parent.x, parent.y, width, height)
        self.parentId = parent.id
        self.data.parentRadius = parent.radius
        self.alpha = 0
        self.data.reflectionSourceId = reflectionSourceId
        self.data.offset = math.floor( misc.getIf(parent.radius ~= nil, parent.radius, parent.width) * .15 )
        local scale = .3
        self:scale(scale, scale)
        appAddSprite(self, handle)
    end
end

function self:createTrailLine(parentId, points, originalObjectRadius, startEnergy, rgb)
    local self = spriteModule.spriteClass('line', 'trailLine', nil, nil, false, points)
    self.parentId = parentId
    self.width = math.floor(originalObjectRadius * .75)
    self.energy = startEnergy * .8
    self:setRgbByColorTriple(rgb)
    self.energySpeed = -2
    self.alphaChangesWithEnergy = true
    if app.runs then
        self:toBack()
    else
        self:toFront()
    end
    local group = nil
    if not app.runs then group = 'interface' end
    appAddSprite(self, handle, group)
    self.data.points = 2
    appBackgroundToBack()

    return self.id
end

function self:createDrone(subtype, offset, droneI)
    local function handle(self)

        for i, other in pairs(self.collisionWith) do
            if other.type == 'bullet' and other.group ~= 'interface' then
                appHandleDamage(self, other)
            end
        end

        if self.phase.name == 'foundTarget' then
            if not self.phase:isInited() then
                self.data.pathTarget = self.data.pathTarget + 1

                if self.data.pathTarget <= #self.data.path then
                    local target = self.data.path[self.data.pathTarget]
                    self.targetX, self.targetY = target[1], target[2]

                    self.targetRotation = misc.angleBetween( self:getPoint(), {x = self.targetX, y = self.targetY} )
                    self.targetRotation = misc.normalizeRotationAngle(self.targetRotation)
                    if self.subtype == 'default' then
                        self.targetRotation = self.targetRotation - 8
                    end

                else
                    self.doDieOutsideField = true
                    -- self.gone = true

                end
            end

        end

        if self.subtype == 'strong' then
            self:toFront()
        end

    end

    local function handleWhenGone(self)
        if app.phase.name == 'mainGame' then
            if self.energy == 0 then
                local ghost = app.spritesHandler:createGhost(self)
                ghost:setFillColor(255, 50, 50, 100)
                ghost.energy = 120
                ghost.energySpeed = -2
                ghost.scaleSpeed = 1.02
                ghost:toFront()
                app.spritesHandler:createSparks(self.x, self.y, 20)
                appPlaySound('explosion')
    
            elseif app.phase.name == 'mainGame' then
                app.lifeCount = app.lifeCount - 1
                system.vibrate()
    
            end
        end
    end

    local data = appGetDroneData(subtype)

    local path = nil
    if app.mapData[app.mapNumber].dronePathOther and math.mod(droneI, 2) == 0 then
        path = misc.cloneTable(app.mapData[app.mapNumber].dronePathOther)
    else
        path = misc.cloneTable(app.mapData[app.mapNumber].dronePath)
    end

    local pathIndex = 1
    local radius = 21

    local startX = path[1][1]
    local startY = path[1][2]
    if startX <= app.minX then startX = startX - radius
    elseif startY <= app.minY then startY = startY - radius
    end
    table.insert( path, 1, {startX, startY} )

    local endX = path[#path][1]
    local endY = path[#path][2]

    --[[
    if endX <= app.minX then endX = endX - radius * 2
    elseif endY <= app.minY then endY = endY - radius * 2
    elseif endX >= app.maxX then endX = endX + radius * 2
    elseif endY >= app.maxY then endY = endY + radius * 2
    end
    table.insert( path, #path + 1, {endX, endY} )
    --]]

    local x, y = path[pathIndex][1], path[pathIndex][2]

    if y >= app.minY and y <= app.maxY then x = x + misc.getIf(x < app.maxXHalf, -offset, offset)
    else y = y + misc.getIf(y < app.maxYHalf, -offset, offset)
    end

    local isSensor = true
    local self = spriteModule.spriteClass('circle', 'drone', subtype, 'drone/' .. subtype, true, x, y, radius, nil,
            nil, nil, isSensor)
    self.bodyType = 'static'
    self.width = 75
    self.height = self.width

    self.data.path = path
    self.data.pathTarget = pathIndex

    local energyMultiplier = 1 + (app.wave - 1) * (.2 * app.difficulty)
    self.energy = data.baseEnergy * energyMultiplier
    self.data.energyAtStart = self.energy

    self.data.speedFactor = data.speedFactor
    self.speedLimitX = 2.1 * self.data.speedFactor
    self.speedLimitY = self.speedLimitX
    self.speedStep = .075

    self.targetFuzziness = 4
    self.doSetPhaseWhenFoundTarget = true
    -- self.listenToPreCollision = true
    self.listenToCollision = true

    self.rotationSpeedLimit = 2.5

    self:initPhase('foundTarget')

    appAddSprite(self, handle, nil, handleWhenGone)

    if self.subtype == 'default' then
        app.spritesHandler:createFlare(self.id, self.x, self.y, true)
    end
end

function self:createDronePathLine(points)
    if points then
        for i = 1, #points - 1 do
            local point1 = points[i]; local point2 = points[i + 1]
            local pointsTable = {point1[1], point1[2], point2[1], point2[2]}
            local self = spriteModule.spriteClass('line', 'dronePath', nil, nil, false, pointsTable)
            appAddSprite(self, handle)
        end
    end
end

function self:createBackground()
    local image = 'map-' .. app.mapPack ..'/' .. app.mapNumber
    local self = spriteModule.spriteClass('rectangle', 'background', nil, image, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    appAddSprite(self, handle)

    app.spritesHandler:createBackgroundDecoObey()
    app.spritesHandler:createBackgroundHouseLights()
    -- app.spritesHandler:createStageShaker()
end

function self:createStageShaker()
    local function handle(self)
        if self.phase.name == 'shake' then
            if not self.phase:isInited() then
                self.targetX, self.targetY = app.maxXHalf, app.maxYHalf
                self.speedX, self.speedY = .25, .15
                self.speedStep = .005
                self.doFollowTargetOneOfXY = true
                self.phase:setNext( 'static', math.random(100, 200) )
            end

        elseif self.phase.name == 'static' then
            if not self.phase:isInited() then
                local factor = .25
                self.speedX, self.speedY = .25 * factor, .15 * factor
                self.speedStep = .005 * factor
                self.phase:setNext( 'shake', math.random(400, 500) )
            end

        end

        local x, y = math.floor(self.x), math.floor(self.y)
        if true or self.data.oldPoint.x ~= x or self.data.oldPoint.y ~= y then
            local stage = display.getCurrentStage()
            if stage ~= nil then
                stage.x, stage.y = self.x, self.y
            end
            self.data.oldPoint = {x = x, y = y}
        end

    end

    local self = spriteModule.spriteClass('rectangle', 'stage', nil, nil, false, app.maxXHalf, app.maxYHalf, 1, 1)
    self.isVisible = false
    self.targetX = self.x
    self.targetY = self.y
    self:initPhase('shake')
    self.data.oldPoint = {x = self.x, y = self.y}
    appAddSprite(self, handle)

    local stage = display.getCurrentStage()
    if stage ~= nil then
        stage.xReference = app.maxXHalf
        stage.yReference = app.maxYHalf
    end
end

function self:createBackgroundHouseLights()
    local function handle(self)
        if self.phase.name == 'off' then
            if not self.phase:isInited() then
                self.energy = 1
                self.phase:setNext( 'on', math.random(100, 450) )
            end

        elseif self.phase.name == 'on' then
            if not self.phase:isInited() then
                self.energy = math.random(20, 50)
                self.phase:setNext( 'off', math.random(100, 450) )
            end
        end
    end

    for i = 1, 80 do
        local x, y = math.random(app.minX, app.maxX), math.random(app.minY, app.maxY)
        local self = spriteModule.spriteClass('rectangle', 'houseLight', nil, 'deco/houseLight', false, x, y, 5, 5)
        self:initPhase( misc.getIfChance(50, 'on', 'off') )
        self.energy = 1
        self.alphaChangesWithEnergy = true
        self.alpha = .01
        self.isIndexed = false
        appAddSprite(self, handle)
    end
end

function self:createBackgroundDecoObey()
    local function handle(self)
        if self.phase.name == 'off' then
            if not self.phase:isInited() then
                self.energy = 10
                self.energySpeed = 0
                self.phase:setNext( 'energize', misc.distort(300, 40) )
            end

        elseif self.phase.name == 'energize' then
            if not self.phase:isInited() then
                self.phase:setNext('fullEnergy', 25)
                appPlaySound('crackle')
            end

            if misc.getChance(90) then
                self.energy = math.random(1, 100)
            end

        elseif self.phase.name == 'fullEnergy' then
            if not self.phase:isInited() then
                self.phase:setNext( 'turnOff', misc.distort(200, 30) )
            end

            self.energy = math.random(90, 100)

        elseif self.phase.name == 'turnOff' then
            if not self.phase:isInited() then
                self.phase:setNext( 'off', 20 )
                self.energy = 95
                self.energySpeed = -2
            end

            if self.energy < 10 then
                self.energySpeed = 0
                self.energy = 10
            end

        end
    end

    local width, height = 120, 110
    local image = 'deco/obey-' .. app.mapPack
    local self = spriteModule.spriteClass('rectangle', 'backgroundDeco', 'obey', image, false, 893 + width / 2, 23 + height / 2, width, height)
    self.energy = 10
    self.alphaChangesWithEnergy = true
    self.alpha = self.energy * .01
    self:initPhase('off')
    appAddSprite(self, handle)
end

function self:createBackgroundParticles()
    local function handle(self)
        self:reappearOppositeIfOffAppBoundary(true)

        if self.energySpeed > 0 then
            if self.energy >= self.data.maxEnergy then
                self.energy = self.data.maxEnergy
                self.energySpeed = self.energySpeed * -1
            end
        else
            if self.energy <= self.data.minEnergy then
                self.energy = self.data.minEnergy
                self.energySpeed = self.energySpeed * -1
            end
        end
    end

    local lowSpeed = .5; local highSpeed = 1
    for i = 1, 30 do
        local point = misc.getRandomPointInRectangle( appGetRectangle() )
        local self = spriteModule.spriteClass('rectangle', 'backgroundParticle', nil, 'backgroundParticle', false, point.x, point.y, 21, 21)

        self.speedX, self.speedY = 0, 0
        while self.speedX == 0 and self.speedY == 0 do
            self.speedX = misc.randomFloat(lowSpeed, highSpeed) * math.random(-1, 1)
            self.speedY = misc.randomFloat(lowSpeed, highSpeed) * math.random(-1, 1)
        end

        self.data.minEnergy, self.data.maxEnergy = 5, 90
        self.energy = misc.randomFloat(self.data.minEnergy + 5, self.data.maxEnergy - 5)
        self.energySpeed = misc.randomNonZero(-2, 2)
        self.alphaChangesWithEnergy = true
        self.isIndexed = false
        local scale = misc.randomFloat(.4, 1)
        self:scale(scale, scale)
        appAddSprite(self, handle)
    end
end

function self:createSkyLights()
    app.spritesHandler:createSkyLight(50, 70, 2, 1, -1)
    app.spritesHandler:createSkyLight(app.maxXHalf + 100, app.maxYHalf, 3, -1.5, .5)
end

function self:createSkyLight(x, y, speedX, speedY, rotationSpeed)
    local function handle(self)
        self:reappearOppositeIfOffAppBoundary()
    end

    local self = spriteModule.spriteClass('rectangle', 'skyLight', nil, 'skyLight', false, x, y, 542, 627)
    self.speedX = speedX
    self.speedY = speedY
    self.rotationSpeed = rotationSpeed
    self.isIndexed = false
    self.blendMode = 'add'
    appAddSprite(self, handle)
end

function self:createFlare(parentId, x, y, doesSpawnShortFlare)
    local function handle(self)
        local distance = misc.getDistance( self:getPoint(), {x = app.maxXHalf, y = app.maxYHalf} )
        local alphaPercent = math.abs(distance - 500) * .25
        self.alpha = misc.keepInLimits(alphaPercent, 0, 100) * .01
        if distance <= 300 and self.data.doesSpawnShortFlare and not self.data.didCreateShortFlare then
            self.data.didCreateShortFlare = true
            app.spritesHandler:createShortFlare(self.parentId)
        end
    end

    if doesSpawnShortFlare == nil then doesSpawnShortFlare = false end

    local self = spriteModule.spriteClass('rectangle', 'flare', nil, 'flare', false, x, y, 673, 105)
    self.data.doesSpawnShortFlare = doesSpawnShortFlare
    self.data.didCreateShortFlare = false
    self.parentId = parentId
    self.movesWithParent = true
    self.isIndexed = false
    self.blendMode = 'add'
    appAddSprite(self, handle)
end

function self:createShortFlare(parentId, x, y)
    local function handle(self)
        if self.energy >= 75 then self.energySpeed = -5 end
    end

    local self = spriteModule.spriteClass('rectangle', 'flare', 'shortFlare', 'flare', false, x, y, 673, 105)
    self.parentId = parentId
    self.movesWithParent = true
    self.isIndexed = false
    self.blendMode = 'add'
    self.rotationSpeed = 10
    self.energySpeed = 10
    self.energy = 1
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle)
end

function self:createFadeInBlack(energySpeed)
    if energySpeed == nil then energySpeed = 5 end

    local self = spriteModule.spriteClass('rectangle', 'black', nil, nil, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self:setRgbBlack()
    self.alpha = 0
    self.energySpeed = energySpeed
    self.energy = 5
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle)
end

function self:createFadeOutBlack()
    local self = spriteModule.spriteClass('rectangle', 'black', nil, nil, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self:setRgbBlack()
    self.energySpeed = -1
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle)
end

function self:createGhost(sprite)
    local self = spriteModule.spriteClass(sprite.displayType, 'ghost', nil, sprite.originalImage, false,
                sprite.x, sprite.y, sprite.width, sprite.height,
                sprite.framesData)
    self.rotation = sprite.rotation
    self.alphaChangesWithEnergy = true
    self.energy = 100
    self.xScale = sprite.xScale
    self.yScale = sprite.yScale
    self:initPhase()
    self.frameName = sprite.frameName
    appAddSprite(self, handle)
    return self
end

function self:createSparks(x, y, amount)
    for i = 1, amount do
        app.spritesHandler:createSpark(x, y)
    end
end

function self:createSpark(x, y)
    local speedMax = 3

    if x ~= nil and y ~= nil then
        local distort = 5
        x, y = misc.distort(x, distort), misc.distort(y, distort)
        local self = spriteModule.spriteClass(sprite.displayType, 'spark', nil, 'spark', false, x, y, 15, 15)
        self.alphaChangesWithEnergy = true
        self.energy = math.random(90, 100)
        self.energySpeed = -4
        self.speedX = math.random(-speedMax, speedMax)
        self.speedY = math.random(-speedMax, speedMax)
        local scale = 1.2
        self:scale(scale, scale)
        self.scaleSpeed = .96
        appAddSprite(self, handle)
    end
end

function self:createDroneHealthBar(drone)
    local function handleBarHealth(self)
        local drone = app.sprites[self.parentId]
        if drone ~= nil then
            local barDamage = app.sprites[drone.data.healthBarId]
            if barDamage ~= nil then
                self:setReferencePoint(display.TopLeftReferencePoint)
                barDamage:setReferencePoint(display.TopLeftReferencePoint)

                local percentage = misc.getPercentRounded(drone.data.energyAtStart, drone.energy)

                self.x = math.floor(drone.x - self.data.maxWidth / 2)
                self.y = drone.y + self.data.offsetY
                self.width = math.floor( (percentage * self.data.maxWidth) / 100 )

                barDamage.x = self.x + self.width
                barDamage.y = self.y
                barDamage.width = self.data.maxWidth - self.width

                local maxAlphaEnergy = 70
                if self.energy >= maxAlphaEnergy then
                    self.energy = maxAlphaEnergy
                    self.energySpeed = 0
                end
                if barDamage.energy >= maxAlphaEnergy then
                    barDamage.energy = maxAlphaEnergy
                    barDamage.energySpeed = 0
                end
            end
        end
    end

    local width, height = 32, 6
    local offsetY = math.floor(drone.height / 2) - 10

    local barHealth = spriteModule.spriteClass('rectangle', 'droneHealthBar', 'health', nil, false, drone.x, drone.y + offsetY, width, height)
    barHealth.parentId = drone.id
    barHealth:setRgb(106, 254, 255)
    barHealth.blendMode = 'add'
    barHealth:toFront()
    barHealth.data.offsetY = offsetY
    barHealth.data.maxWidth = width
    barHealth.energy = 1
    barHealth.energySpeed = 4
    barHealth.alphaChangesWithEnergy = true
    appAddSprite(barHealth, handleBarHealth)

    local barDamage = spriteModule.spriteClass('rectangle', 'droneHealthBar', 'damage', nil, false, drone.x, drone.y + offsetY, 1, height)
    barDamage.parentId = drone.id
    barDamage:setRgb(197, 44, 5)
    barDamage:toFront()
    barDamage.blendMode = 'add'
    barDamage.energy = barHealth.energy
    barDamage.energySpeed = barHealth.energySpeed
    barDamage.alphaChangesWithEnergy = true
    appAddSprite(barDamage, nil)

    drone.data.healthBarId = barDamage.id
end

function self:createObstacles()
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            if other.type == 'bullet' then
                appPlaySound('obstacleBump')
                appHandleGeneralCollideBehavior(self, other)
            end
        end
    end

    local obstacles = app.mapData[app.mapNumber].obstacles
    local width = 51; local height = 252
    if obstacles ~= nil then
        for i = 1, #obstacles do
            local x = obstacles[i][1] + width / 2
            local y = obstacles[i][2] + height / 2
            local rotation = obstacles[i][3]
            local self = spriteModule.spriteClass('rectangle', 'obstacle', nil, 'obstacle', true, x, y, width, height)
            self.bodyType = 'static'
            self.energy = 60
            self.alphaChangesWithEnergy = true
            self.listenToCollision = true
            self.blendMode = 'add'
            self.rotation = rotation
            appAddSprite(self, handle, nil)
        end
    end
end

return self
end
