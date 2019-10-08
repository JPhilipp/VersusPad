module(..., package.seeall)

function spriteClass(displayType, type, subtype, imageName, isAutoPhysical, x, y, widthOrRadius, heightOrNil,
        framesData, polygonShape, parentPlayer, isSensor)
local self = {}
if energy == nil then energy = 100 end
if isAutoPhysical == nil then isAutoPhysical = false end
if x == nil then x = 0 end
if y == nil then y = 0 end
if imageName ~= nil and string.find(imageName, '%.') == nil then imageName = imageName .. '.png' end
if isSensor == nil then isSensor = false end

if app.drawMode == 'debug' then imageName = nil end

if imageName ~= nil then
    local thisWidthOrRadius = widthOrRadius
    local thisHeightOrNil = heightOrNil
    if thisHeightOrNil == nil then
        thisWidthOrRadius = widthOrRadius * 2 - 1
        thisHeightOrNil = thisWidthOrRadius
    end

    if framesData ~= nil then
        for i = 1, #framesData.names do
            if framesData.names[i].count == nil then framesData.names[i].count = 1 end
        end
        local options = {sheetContentWidth = framesData.image.width, sheetContentHeight = framesData.image.height, numFrames = framesData.image.count,
                width = thisWidthOrRadius, height = thisHeightOrNil}
        local imageSheet = graphics.newImageSheet( appToPath(imageName), options )
        self = display.newSprite(imageSheet, framesData.names)

    else
        if imagePathContext ~= nil then
            self = display.newImage(imageName, imagePathContext)
        else
            local imageWhichFillsScreen, newImageName = appGetImageWhichFillsScreen(imageName)
            if imageWhichFillsScreen ~= nil then
                widthOrRadius = imageWhichFillsScreen.width * display.contentScaleX
                heightOrNil = imageWhichFillsScreen.height * display.contentScaleY
                self = display.newImageRect( appToPath(newImageName), widthOrRadius, heightOrNil )
            else
                self = display.newImageRect( appToPath(imageName), thisWidthOrRadius, thisHeightOrNil )
            end
        end
    end

elseif displayType == 'rectangle' then
    self = display.newRect(x, y, widthOrRadius, heightOrNil)

elseif displayType == 'circle' then
    self = display.newCircle(x, y, widthOrRadius)

elseif displayType == 'text' then
    local fontSize = 14 * appGetScaleFactor()
    if widthOrRadius ~= nil and heightOrNil ~= nil then
        self = display.newText('', x, y, widthOrRadius, heightOrNil, app.defaultFont, fontSize)
    else
        self = display.newText( '', x, y, app.defaultFont, fontSize)
    end

end

self.displayType = displayType
if displayType == 'circle' then
    self.radius = widthOrRadius
else
    if widthOrRadius ~= nil then self.width = widthOrRadius end
    if heightOrNil ~= nil then self.height = heightOrNil end
end

self.id = appGetId()
self.inited = false
self.type = type
self.subtype = subtype
self.group = nil
self.isAutoPhysical = isAutoPhysical
self.image = ''
self.energy = energy
self.energyOld = self.energy
self.energySpeed = 0
self.gone = false
self.speedLimit = nil
self.speedLimitX = nil
self.speedLimitY = nil
self.doDieOutsideField = true
self.phase = phaseModule.phaseClass()
self.extraPhase = phaseModule.phaseClass()
self.imageName = imageName
self.spriteSheetFrom = spriteSheetFrom
self.spriteSheetTo = spriteSheetTo
self.onGround = false
self.parentId = nil
self.movesWithParent = false
self.movesWithParentIsRelativeToOrigin = false
self.disappearsWithParent = true
self.parentXOld = nil
self.parentYOld = nil
self.debugMe = false
self.directionX = nil
self.directionY = nil
self.touchedX = nil
self.touchedY = nil
self.rotationImageOffset = 0
self.alphaChangesWithEnergy = false
self.data = {}
self.handle = nil
self.handleWhenGone = nil
self.emphasizeAppearance = false
self.emphasizeDisappearance = false
self.doFollowTarget = true
self.listenToPreCollision = false
self.listenToCollision = false
self.listenToPostCollision = false
self.listenToTouch = false

self.collisionWith = nil
self.collisionForce = nil

-- Common DisplayObject properties:
self.x = x
self.y = y

-- self.rotation = 0

self.alpha = 1
-- self.isVisible
-- self.isHitTestable
-- self.numChildren
-- self.parent (read only)
-- self.stageBounds {minX, maxX, minY, maxY}
-- self.stageHeight
-- self.stageWidth
-- self.xOrigin
-- self.yOrigin
-- self.xReference
-- self.yReference
-- self.xScale
-- self.yScale

-- Common Body properties:
-- self.isAwake
-- self.isBodyActive
-- self.isBullet
-- self.isFixedRotation = true
-- self.angularVelocity
-- self.linearDamping
-- self.angularDamping
-- self.bodyType
self.isSleepingAllowed = true

-- Common methods for Vector Objects:
-- self:setFillColor(r, g, b [, a])
-- self.setStrokeColor(r, g, b [, a])

-- Common DisplayObject methods:
-- self:rotate(deltaAngle)
-- self:scale(sX, sY)
-- self:setReferencePoint(referencePoint)
-- self:translate(x, y)

-- Common Body methods:
-- self:setLinearVelocity(xPixelsPerSecond, yPixelsPerSecond)
-- self:getLinearVelocity
-- self:applyForce(xForce, yForce, xWhereToApply, yWhereToApply)
-- self:applyLinearImpulse(xForce, yForce, xWhereToApply, yWhereToApply)
-- self:applyTorque(rotationalForce)
-- self:applyAngularImpulse(angularImpulse)
-- self:resetMassData()

self.xOld = x
self.yOld = y
self.xFloat = x
self.yFloat = y
self.speedX = 0
self.speedY = 0
self.targetSpeedX = nil
self.targetSpeedY = nil
self.speedStep = .5
self.targetSprite = nil
self.targetX = nil
self.targetY = nil
self.red = nil
self.green = nil
self.blue = nil
self.parentPlayer = parentPlayer
self.controlledSprite = nil
self.action = {}
self.actionOld = {}
self.collisionFilter = nil
self.followDelay = 6
if polygonShape ~= nil then polygonShape = misc.getAbsolutePolygon(polygonShape, widthOrRadius, heightOrNil) end

self.frameName = nil
self.frameNameOld = nil
self.rotationSpeed = nil
self.rotationSpeedLimit = nil
self.targetRotation = nil
self.rotationOld = nil
self.followBuffer = {}
self.phasesWithFrameNames = {}
self.alsoAllowsExtendedNonPhysicalHandling = true

if self.isAutoPhysical then
    if self.displayType == 'circle' then
        if isSensor then
            physics.addBody( self, { isSensor = isSensor, radius = self.radius, filter = appGetCollisionFilter(self) } )
        else
            physics.addBody( self, { isSensor = isSensor, density = 1, friction = 50, bounce = appGetBounceValue(self), radius = self.radius, filter = appGetCollisionFilter(self) } )
        end
    else
        physics.addBody( self, { isSensor = isSensor, density = appGetDensityValue(self), friction = .6, bounce = appGetBounceValue(self), shape = polygonShape, filter = appGetCollisionFilter(self) } )
    end
end

function spritePreCollision(self, event)
end
self.preCollision = spritePreCollision

function spriteCollision(self, event)
    self.collisionWith = event.other
    self.collisionForce = event.force
end
self.collision = spriteCollision

function spritePostCollision(self, event)
    self.collisionWith = event.other
    self.collisionForce = event.force
end
self.postCollision = spritePostCollision

function self:resetSpin()
    self.bodyType = 'static'
    self.bodyType = 'dynamic'
end

function self:magneticTowards(x, y)
    local strength = 1000
    local distance = misc.getDistance( {x = x, y = y}, self )
    local power = app.magneticMaxValue / distance / strength	
    local pushX = (x - self.x) * power
    local pushY = (y - self.y) * power
    self:applyForce(pushX, pushY, self.x, self.y)
end

function self:followTargetSpritePath()
    table.insert( self.followBuffer, 1, { x = self.targetSprite.x, y = self.targetSprite.y, rotation = self.targetSprite.rotation } )

    local length = #self.followBuffer
    if length >= self.followDelay then
        if length > self.followDelay then table.remove(self.followBuffer, length) end

        local bufferItem = self.followBuffer[self.followDelay]
        self.x = bufferItem.x
        self.y = bufferItem.y
        self.rotation = bufferItem.rotation
    end
end

function self:adjustSpeedToRotation(adjustDelayed)
    if adjustDelayed == nil then adjustDelayed = false end
    -- before: if self.rotation ~= self.rotationOld and self.speedLimit ~= nil then ...
    local rotationValue = self.rotation - self.rotationImageOffset
    local x = math.cos(rotationValue * math.pi / 180)
    local y = math.sin(rotationValue * math.pi / 180)
    local speedX = x * (self.speedLimit * 10)
    local speedY = y * (self.speedLimit * 10)

    if adjustDelayed then
        local speedStep = 3
        local targetSpeedX = speedX
        local targetSpeedY = speedY
        if self.data.speedX == nil then self.data.speedX = targetSpeedX end
        if self.data.speedY == nil then self.data.speedY = targetSpeedY end

        if self.data.speedX < targetSpeedX then
            self.data.speedX = self.data.speedX + speedStep
            if self.data.speedX > targetSpeedX then self.data.speedX = targetSpeedX end
        elseif self.data.speedX > targetSpeedX then
            self.data.speedX = self.data.speedX - speedStep
            if self.data.speedX < targetSpeedX then self.data.speedX = targetSpeedX end
        end

        if self.data.speedY < targetSpeedY then
            self.data.speedY = self.data.speedY + speedStep
            if self.data.speedY > targetSpeedY then self.data.speedY = targetSpeedY end
        elseif self.data.speedY > targetSpeedY then
            self.data.speedY = self.data.speedY - speedStep
            if self.data.speedY < targetSpeedY then self.data.speedY = targetSpeedY end
        end

        self:setLinearVelocity(self.data.speedX, self.data.speedY)
    else
        self.data.speedX = speedX
        self.data.speedY = speedY
        self:setLinearVelocity(speedX, speedY)
    end

    self.rotationOld = self.rotation
end

function self:directTowardsTargetSprite()
    if self.targetSprite ~= nil then
        local angleDegrees = misc.angleBetween(self, self.targetSprite)
        self.rotation = angleDegrees - 90
    end
end

function self:stop()
    self.speedX = nil
    self.speedY = nil
    self.target = nil
    self.targetX = nil
    self.targetY = nil
    self.targetSpeedX = nil
    self.targetSpeedY = nil
    self.rotationSpeed = nil

    if self.isAutoPhysical then
        self:setLinearVelocity(0, 0)
    end
end

function self:getAlphaFromPercent(percent)
    local alpha = 0
    local alphaMax = 1

    if percent ~= nil and math.floor(percent) >= 0 then
        alpha = math.floor(percent) * (alphaMax / 100)
        if alpha > alphaMax then alpha = alphaMax end
    end
    return alpha
end

function self:mirrorXY(includingRotation)
    if includingRotation == nil then includingRotation = true end
    self.x = app.maxX - self.x
    self.y = app.maxY - self.y
    if includingRotation then self.rotation = self.rotation + 180 end
end

function self:setAlphaToEnergy()
    if self.energy ~= self.energyOld then
        self.alpha = self:getAlphaFromPercent(self.energy)
    end
end

function self:handleGenericBehaviorPre()
    if self.phase ~= nil and not self.phase.inited then
        if misc.inArray(self.phasesWithFrameNames, self.phase.name) then self.frameName = self.phase.name end

        if not self.inited then
            if self.listenToPreCollision then self:addEventListener('preCollision', self) end
            if self.listenToPostCollision then self:addEventListener('postCollision', self) end
            if self.listenToCollision then self:addEventListener('collision', self) end
            if self.listenToTouch then self:addEventListener('touch', spriteTouchBody) end
        end
    end
end

function self:handleGenericBehavior()
    self.collisionWith = nil
    self.collisionForce = nil

    if self.frameName ~= nil and self.frameName ~= self.frameNameOld then
        self:setSequence(self.frameName)
        self:play()
        self.frameNameOld = self.frameName
    end

    self:disappearWithParentIfNeeded()

    if self.alsoAllowsExtendedNonPhysicalHandling then
        self:moveWithParentIfNeeded()
        self:adjustToTargetSpeed()
        self:keepToSpeedLimits()
        self:followTarget()
        self:adjustRotation()
        self:adjustAlpha()
    end

    self:followTargetRotation()

    if self.phase ~= nil then self.phase:handleCounter() end
    if self.extraPhase ~= nil then self.extraPhase:handleCounter() end

    self:updatePositionIfNeeded()

    self:adjustEnergy()
    self:dieOutsideField()

    for id, value in pairs(self.action) do
        self.actionOld[id] = self.action[id]
    end

    if not self.inited then
        self.inited = true
        if self.emphasizeAppearance then app.spritesHandler:createEmphasizeAppearanceEffect(self.x, self.y) end
    end
end

function self:adjustEnergy()
    self.energyOld = self.energy
    if self.energySpeed ~= 0 then
        self.energy = self.energy + self.energySpeed

        local energyNormalMax = 100
        if self.energySpeed > 0 and self.energy >= energyNormalMax then
            self.energy = energyNormalMax
            self.energySpeed = 0
        end
    end
  
    if self.energy <= 0 then
        self.energy = 0
        self.gone = true
    end
end

function self:adjustAlpha(chanceToUpdateAlpha)
    if chanceToUpdateAlpha == nil then chanceToUpdateAlpha = 100 end
    if self.alphaChangesWithEnergy and self.energy <= 100 and math.floor(self.energy) ~= math.floor(self.energyOld) and misc.getChance(chanceToUpdateAlpha) then
        self:setAlphaToEnergy()
        if self.displayType == 'text' then
            self:setColorBySelf()
        elseif self.imageName == nil then
            self:setFillColorBySelf()
        end
    end
end

function self:followTargetRotation()
    if self.targetRotation ~= nil then
        if self.rotationSpeedLimit ~= nil and self.rotationSpeedLimit > 0 then
            local difference = (self.targetRotation - self.rotation) % 360
    
            if difference > 180 then
                difference = difference - 360
            elseif difference < -180 then
                difference = difference + 360
            end
    
            if difference > 0 then
                self.rotation = self.rotation + misc.getMin(difference, self.rotationSpeedLimit)
            else
                self.rotation = self.rotation + misc.getMax(difference, -self.rotationSpeedLimit)
            end

        else
            if self.rotation ~= self.targetRotation then self.rotation = self.targetRotation end
        end    
    end
end

function self:updatePositionIfNeeded()
    if self.speedX ~= 0 and self.speedX ~= nil then self.xFloat = self.xFloat + self.speedX end
    if self.speedY ~= 0 and self.speedY ~= nil then self.yFloat = self.yFloat + self.speedY end

    local xFloor = math.floor(self.xFloat)
    local yFloor = math.floor(self.yFloat)

    if xFloor ~= self.xOld then
        self.x = xFloor
        self.xOld = xFloor
    end
    if yFloor ~= self.yOld  then
        self.y = yFloor
        self.yOld = yFloor
    end
end

function self:moveWithParentIfNeeded()
    if self.movesWithParent and self.parentId ~= nil then
        local parentSprite = appGetSpriteById(self.parentId)
        if parentSprite ~= nil then
            if self.movesWithParentIsRelativeToOrigin then
                local parentX = math.floor(parentSprite.x)
                local parentY = math.floor(parentSprite.y)
    
                if self.parentXOld == nil or self.parentYOld == nil then
                    self.parentXOld = parentX
                    self.parentYOld = parentY
                elseif parentX ~= self.parentXOld or parentY ~= self.parentYOld then
                    local offX = self.parentXOld - parentX
                    local offY = self.parentYOld - parentY
                    self.x = self.x + offX * -1
                    self.y = self.y + offY * -1
                    self.parentXOld = parentX
                    self.parentYOld = parentY
                end
            else
                self.x = parentSprite.x
                self.y = parentSprite.y
            end

        end
    end
end

function self:disappearWithParentIfNeeded()
    if self.disappearsWithParent and self.parentId ~= nil then
        local parentSprite = appGetSpriteById(self.parentId)
        if parentSprite == nil or parentSprite.gone then self.gone = true end
    end
end

function self:adjustRotation()
    if self.rotationSpeed ~= nil and self.rotationSpeed ~= 0 then
        self.rotation = self.rotation + self.rotationSpeed
        if self.rotation > app.maxRotation then
            self.rotation = 0
        elseif self.rotation < 0 then
            self.rotation = app.maxRotation
        end
    end
end

function self:keepToSpeedLimits()
    if self.speedLimitX ~= nil and self.speedX ~= nil and self.speedX ~= 0 then
        if self.speedX < -self.speedLimitX then self.speedX = -self.speedLimitX
        elseif self.speedX > self.speedLimitX then self.speedX = self.speedLimitX
        end
    end

    if self.speedLimitY ~= nil and self.speedY ~= nil and self.speedY ~= 0 then
        if self.speedY < -self.speedLimitY then self.speedY = -self.speedLimitY
        elseif self.speedY > self.speedLimitY then self.speedY = self.speedLimitY
        end
    end
end

function self:followTarget()
    if self.doFollowTarget then
        if self.targetSprite ~= nil and self.targetSprite.x ~= nil and self.targetSprite.y ~= nil then
            self.targetX = self.targetSprite.x
            self.targetY = self.targetSprite.y
        end
    end

    if self.targetX ~= nil then
        if self.x < self.targetX then self.speedX = self.speedX + self.speedStep
        elseif self.x > self.targetX then self.speedX = self.speedX - self.speedStep
        end
    end

    if self.targetY ~= nil then
        if self.y < self.targetY then self.speedY = self.speedY + self.speedStep                 
        elseif self.y > self.targetY then self.speedY = self.speedY - self.speedStep
        end
    end
end

function self:setRgbWhite()
    self:setRgb(255, 255, 255)
end

function self:setRgbBlack()
    self:setRgb(0, 0, 0)
end

function self:setRgbRandom()
    self:setRgb( math.random(0, 255), math.random(0, 255), math.random(0, 255) )
end

function self:pushRgbIntoLimits()
    self.red = misc.keepInLimits(self.red, 0, 255)
    self.green = misc.keepInLimits(self.green, 0, 255)
    self.blue = misc.keepInLimits(self.blue, 0, 255)
end

function self:setRgbByColorTriple(color)
    self:setRgb(color.red, color.green, color.blue)
end

function self:setRgb(red, green, blue, optionalAlphaInPercent)
    self.red = red
    self.green = green
    self.blue = blue
    if optionalAlphaInPercent ~= nil then
        self.alpha = self:getAlphaFromPercent(optionalAlphaInPercent)
    end
end

function self:setPosFromLeftTop(x, y, width, height)
    if width == nil then width = self.width end
    if height == nil then height = self.height end

    self.x = math.floor(x + width / 2)
    self.y = math.floor(y + height / 2)
    self.width = width
    self.height = height
end

function self:setFillColorBySelf()
    if self.displayType ~= 'text' then
        self:setFillColor(self.red, self.green, self.blue, self.alpha * 255)
    end
end

function self:setColorBySelf()
    if self.displayType == 'text' then
        self:setTextColor(self.red, self.green, self.blue, self.alpha * 255)
    end
end

function self:dieOutsideField()
    if self.doDieOutsideField and misc.getChance(1) then
        if self.xFloat + self.width < app.minX then
            self.gone = true
        elseif self.xFloat - self.width > app.maxX then
            self.gone = true
        elseif self.yFloat + self.height < app.minY then
            self.gone = true
        elseif self.yFloat - self.height > app.maxY then
            self.gone = true
        end
    end
end

function self:adjustToTargetSpeed()
    if self.targetSpeedX ~= nil then
        if self.speedX < self.targetSpeedX then
            self.speedX = self.speedX + self.speedStep
            if self.speedX > self.targetSpeedX then
                self.speedX = self.targetSpeedX
            end
        elseif self.speedX > self.targetSpeedX then
            self.speedX = self.speedX - self.speedStep
            if self.speedX < self.targetSpeedX then
                self.speedX = self.targetSpeedX
            end
        end
    end
    if self.targetSpeedY ~= nil then
        if self.speedY < self.targetSpeedY then
            self.speedY = self.speedY + self.speedStep
            if self.speedY > self.targetSpeedY then
                self.speedY = self.targetSpeedY
            end
        elseif self.speedY > self.targetSpeedY then
            self.speedY = self.speedY - self.speedStep
            if self.speedY < self.targetSpeedY then
                self.speedY = self.targetSpeedY
            end
        end
    end
end

function self:bounceOffBoundary(rect)
    if rect.x1 ~= nil and self.x - self.width / 2 <= rect.x1 and self.speedX ~= nil and self.speedX < 0 then
        self.x = rect.x1 - self.width / 2
        self.speedX = self.speedX * -1
    elseif rect.x2 ~= nil and self.x + self.width / 2 >= rect.x2 and self.speedX ~= nil and self.speedX > 0 then
        self.x = rect.x2 + self.width / 2
        self.speedX = self.speedX * -1
    end

    if rect.y1 ~= nil and self.y - self.height / 2 <= rect.y1 and self.speedY ~= nil and self.speedY < 0 then
        self.y = rect.y1 - self.height / 2
        self.speedY = self.speedY * -1
    elseif rect.y2 ~= nil and self.y + self.height / 2 >= rect.y2 and self.speedY ~= nil and self.speedY > 0 then
        self.y = rect.y2 + self.height / 2
        self.speedY = self.speedY * -1
    end
end

function self:adjustRadius(radiusSpeed)
    self.radius = self.radius + radiusSpeed
    if self.radius <= 1 then self.radius = 1 end
    self.width = self.radius * 2
    self.height = self.radius * 2
end

function self:alertId()
    native.showAlert('Sprite', self.id)
end

function self:printId()
    print('sprite.id = ' .. self.id)
end

function self:setFontSize(fontSize)
    self.size = fontSize * appGetScaleFactor()
end

return self
end