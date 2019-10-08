module(..., package.seeall)

function spriteClass(displayType, type, subtype, imageName, isAutoPhysical, xOrLinePointsArray, y, widthOrRadius, heightOrNil,
        framesData, polygonShapeOrShapes, isSensor, density, bounce, friction, imagePathContext)
local self = {}
if energy == nil then energy = 100 end
if isAutoPhysical == nil then isAutoPhysical = false end

local x = nil
if misc.getType(xOrLinePointsArray) == 'table' then
    x = xOrLinePointsArray[1]
    y = xOrLinePointsArray[2]
else
    x = xOrLinePointsArray
end
if x == nil then x = 0 end
if y == nil then y = 0 end
local originalImage = imageName
self.originalImage = originalImage

if imageName ~= nil then
    local translatedImage = appGetTranslatedImage(imageName)
    if translatedImage ~= nil then
        if translatedImage.width ~= nil then widthOrRadius = translatedImage.width end
        if translatedImage.height ~= nil then heightOrNil = translatedImage.height end
    end
end

if imageName ~= nil and string.find(imageName, '%.') == nil then imageName = imageName .. '.png' end
if isSensor == nil then isSensor = false end
if density == nil then density = app.defaultDensity end
if bounce == nil then bounce = app.defaultBounce end
if friction == nil then friction = app.defaultFriction end

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
            self = display.newImageRect( appToPath(imageName), thisWidthOrRadius, thisHeightOrNil )
        end
    end

elseif displayType == 'rectangle' then
    self = display.newRect(x, y, widthOrRadius, heightOrNil)

elseif displayType == 'circle' then
    self = display.newCircle(x, y, widthOrRadius)

elseif displayType == 'line' then
    local points = xOrLinePointsArray
    widthOrRadius = 10
    heightOrNil = 10
    if points ~= nil and misc.getType(points) == 'table' and #points >= 4 then
        self = display.newLine(points[1], points[2], points[3], points[4])
        for i = 5, #points - 1, 2 do
            self:append(points[i], points[i + 1])
        end
    else
        appPrint('line points not provided properly')
    end

elseif displayType == 'text' then
    local fontSize = 15 * appGetScaleFactor()
    if widthOrRadius ~= nil and heightOrNil ~= nil then
        self = display.newText('', x, y, widthOrRadius, heightOrNil, app.defaultFont, fontSize)
    else
        self = display.newText( '', x, y, app.defaultFont, fontSize)
    end

elseif displayType == 'group' then
    self = display.newGroup()
    print('Switch to appHandleRemovalsSupportDisplayTypeGroups')

end

local likelyAnImageNotFoundIssue = self == nil
if likelyAnImageNotFoundIssue then return nil end

self.displayType = displayType
if displayType == 'circle' then
    self.radius = widthOrRadius

elseif displayType == 'text' then

elseif displayType == 'line' then

else
    if widthOrRadius ~= nil then self.width = widthOrRadius end
    if heightOrNil ~= nil then self.height = heightOrNil end

end

self.id = appGetId()
self.inited = false
self.type = type
self.subtype = subtype
self.group = nil
self.density = density
self.friction = friction
self.bounce = bounce
self.isAutoPhysical = isAutoPhysical
self.image = ''
self.energy = energy
self.energyMax = misc.getIf(self.energy > 100, self.energy, 100)
self.energyOld = self.energy
self.energySpeed = nil
self.gone = false
self.speedLimit = nil
self.speedLimitX = nil
self.speedLimitY = nil
self.phase = nil
self.extraPhase = nil
self.imageName = imageName
self.spriteSheetFrom = spriteSheetFrom
self.spriteSheetTo = spriteSheetTo
self.onGround = false
self.parentId = nil
self.movesWithParent = false
self.rotatesWithParent = false
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
self.doFollowTarget = true
self.targetFuzziness = nil
self.listenToPreCollision = false
self.listenToCollision = false
self.listenToPostCollision = false
self.listenToTouch = false
self.isDragged = false
self.doRoundPosition = false
self.killedById = nil
self.originalImage = originalImage
self.doSetPhaseWhenFoundTarget = false
self.scaleSpeed = nil
self.isIndexed = true
self.doDieOutsideField = false
self.doesListenToSome = false
self.outsideCheckCounter = 0
self.doUpdateFillColor = false
self.targetPointSpeedWasSetFor = nil
self.doFollowTargetOneOfXY = false

self.collisionWith = {}
self.collisionForce = {}
self.collisionWithPreState = {}

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
self.oldRed = nil
self.oldGreen = nil
self.oldBlue = nil
self.controlledSprite = nil
self.action = {}
self.actionOld = {}
self.collisionFilter = nil
self.followDelay = 6
self.originX = self.x
self.originY = self.y
if polygonShapeOrShapes ~= nil then
    polygonShapeOrShapes = misc.cloneTable(polygonShapeOrShapes)
    if misc.getType(polygonShapeOrShapes[1]) == 'table' then
        for shapeI = 1, #polygonShapeOrShapes do
            polygonShapeOrShapes[shapeI] = misc.getAbsolutePolygon(polygonShapeOrShapes[shapeI], widthOrRadius, heightOrNil)
        end
    else
        polygonShapeOrShapes = misc.getAbsolutePolygon(polygonShapeOrShapes, widthOrRadius, heightOrNil)
    end
end

self.frameName = nil
self.frameNameOld = nil
self.framesData = framesData
-- self.frame = nil
self.phasesWithFrameNames = nil
self.extraPhasesWithFrameNames = nil

self.rotationSpeed = nil
self.rotationSpeedLimit = nil
self.targetRotation = nil
self.rotationOld = nil
self.alsoAllowsExtendedNonPhysicalHandling = true
self.isSensor = isSensor

if self.isAutoPhysical then
    if self.displayType == 'circle' then
        if isSensor then physics.addBody( self, { isSensor = isSensor, radius = self.radius, filter = appGetCollisionFilter(self) } )
        else physics.addBody( self, { isSensor = isSensor, density = density, friction = friction, bounce = bounce, radius = self.radius, filter = appGetCollisionFilter(self) } )
        end
    else
        if polygonShapeOrShapes ~= nil and misc.getType(polygonShapeOrShapes[1]) == 'table' then
            if #polygonShapeOrShapes == 2 then
                physics.addBody( self, 
                        { isSensor = isSensor, density = density, friction = friction, bounce = bounce, shape = polygonShapeOrShapes[1], filter = appGetCollisionFilter(self) },
                        { isSensor = isSensor, density = density, friction = friction, bounce = bounce, shape = polygonShapeOrShapes[2], filter = appGetCollisionFilter(self) }
                        )
            elseif #polygonShapeOrShapes == 3 then
                physics.addBody( self, 
                        { isSensor = isSensor, density = density, friction = friction, bounce = bounce, shape = polygonShapeOrShapes[1], filter = appGetCollisionFilter(self) },
                        { isSensor = isSensor, density = density, friction = friction, bounce = bounce, shape = polygonShapeOrShapes[2], filter = appGetCollisionFilter(self) },
                        { isSensor = isSensor, density = density, friction = friction, bounce = bounce, shape = polygonShapeOrShapes[3], filter = appGetCollisionFilter(self) }
                        )
            else
                appPrint('Over 3 shapes not supported yet')
            end
        else
            physics.addBody( self, { isSensor = isSensor, density = density, friction = friction, bounce = bounce, shape = polygonShapeOrShapes, filter = appGetCollisionFilter(self) } )

        end
    end
end

function spritePreCollision(self, event)
    local other = event.other
    local speedX, speedY = other:getLinearVelocity()
    self.collisionWithPreState[#self.collisionWithPreState + 1] = {
            x = other.x, y = other.y, speedX = speedX, speedY = speedY, rotation = other.rotation
        }
    self.collisionWith[#self.collisionWith + 1] = other
end
self.preCollision = spritePreCollision

function spriteCollision(self, event)
    if event.phase == 'began' then self.collisionWith[#self.collisionWith + 1] = event.other end
end
self.collision = spriteCollision

function spritePostCollision(self, event)
    self.collisionWith[#self.collisionWith + 1] = event.other
    self.collisionForce[#self.collisionForce + 1] = event.force
end
self.postCollision = spritePostCollision

function self:getParent()
    return app.sprites[self.parentId]
end

function self:getKiller()
    return app.sprites[self.killedById]
end

function self:resetSpin()
    self.bodyType = 'static'
    self.bodyType = 'dynamic'
end

function self:magneticTowards(x, y, invertStrength)
    if invertStrength == nil then invertStrength = 1000 end
    local distance = misc.getDistance( {x = x, y = y}, self )
    local power = app.magneticMaxValue / distance / invertStrength
    power = misc.round(power, 4)
    local pushX = (x - self.x) * power
    local pushY = (y - self.y) * power
    pushX, pushY = misc.round(pushX, 0), misc.round(pushY, 0)
    self:applyForce(pushX, pushY, self.x, self.y)
end

function self:pushTowardsDirection(angle, useImpulse)
    local x = math.cos(angle * math.pi / 180)
    local y = math.sin(angle * math.pi / 180)
    local speedX = x * (self.speedLimit * 10)
    local speedY = y * (self.speedLimit * 10)
    if useImpulse then
        self:applyLinearImpulse(speedX, speedY, self.x, self.y)
    else
        self:applyForce(speedX, speedY, self.x, self.y)
    end
end

function self:adjustSpeedToRotation()
    local rotationValue = self.rotation + self.rotationImageOffset
    local x = math.cos(rotationValue * math.pi / 180)
    local y = math.sin(rotationValue * math.pi / 180)
    local speedX = x * (self.speedLimit * 10)
    local speedY = y * (self.speedLimit * 10)
    self:setLinearVelocity(speedX, speedY)
    self.rotationOld = self.rotation
    return speedX, speedY
end

function self:directTowardsTargetSprite()
    if self.targetSprite ~= nil then
        local angleDegrees = misc.angleBetween(self, self.targetSprite)
        self.rotation = angleDegrees - 90
    end
end

function self:getPosition()
    return {x = self.x, y = self.y}
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

function self:mirrorXY(includingRotation)
    if includingRotation == nil then includingRotation = true end
    self.x = app.maxX - self.x
    self.y = app.maxY - self.y
    if includingRotation then self.rotation = self.rotation + 180 end
end

function self:handleGenericBehaviorPre()
    if self.phasesWithFrameNames ~= nil and self.phase ~= nil and not self.phase.inited and
            misc.inArray(self.phasesWithFrameNames, self.phase.name) then
        self.frameName = self.phase.name
    end

    if not self.inited then
        if self.listenToPreCollision then
            self:addEventListener('preCollision', self)
            self.doesListenToSome = true
        end
        if self.listenToPostCollision then
            self:addEventListener('postCollision', self)
            self.doesListenToSome = true
        end
        if self.listenToCollision then
            self:addEventListener('collision', self)
            self.doesListenToSome = true
        end
        if self.listenToTouch then
            self:addEventListener('touch', spriteTouchBody)
            self.doesListenToSome = true
        end
    end

    if self.extraPhasesWithFrameNames ~= nil and self.extraPhase ~= nil and not self.extraPhase.inited and
            misc.inArray(self.extraPhasesWithFrameNames, self.extraPhase.name) then
        self.frameName = self.extraPhase.name
    end
end

function self:handleGenericBehavior()
    if self.doesListenToSome then
        self.collisionWith = {}
        self.collisionForce = {}
        self.collisionWithPreState = {}
    end

    if self.frameName ~= nil and self.frameName ~= self.frameNameOld then
        self:setSequence(self.frameName)
        self:play()
        self.frameNameOld = self.frameName
    end

    if self.alsoAllowsExtendedNonPhysicalHandling then
        if self.parentId ~= nil and self.disappearsWithParent then self:disappearWithParent() end
        if self.movesWithParent then self:moveWithParent() end
        if self.rotatesWithParent then self:rotateWithParent() end
        if self.targetSpeedX ~= nil then self:adjustToTargetSpeedX() end
        if self.targetSpeedY ~= nil then self:adjustToTargetSpeedY() end
        if self.speedLimitX ~= nil and self.speedX ~= 0 then
            self.speedX = misc.keepInLimits(self.speedX, -self.speedLimitX, self.speedLimitX)
        end
        if self.speedLimitY ~= nil and self.speedY ~= nil then
            self.speedY = misc.keepInLimits(self.speedY, -self.speedLimitY, self.speedLimitY)
        end

        if self.doFollowTarget then
            if self.targetSprite ~= nil and self.targetSprite.x ~= nil and self.targetSprite.y ~= nil then
                self.targetX = self.targetSprite.x
                self.targetY = self.targetSprite.y
            end
        end

        if self.doFollowTargetOneOfXY then
            if self.targetX ~= nil or self.targetY ~= nil then self:followTargetOneOfXY() end
        else
            if self.targetX ~= nil and self.targetY ~= nil then self:followTarget() end
        end

        if self.rotationSpeed ~= nil then self:adjustRotation() end
        if self.doUpdateFillColor then self:setFillColorBySelf() end
        if self.targetRotation ~= nil then self:followTargetRotation() end
        if self.scaleSpeed ~= nil then self:scale(self.scaleSpeed, self.scaleSpeed) end
    end

    if self.phase ~= nil then self.phase:handleCounter() end
    if self.extraPhase ~= nil then self.extraPhase:handleCounter() end

    if self.alsoAllowsExtendedNonPhysicalHandling then
        self:updatePositionIfNeeded()
    end

    if self.alphaChangesWithEnergy then self:adjustAlpha() end
    self:adjustEnergy()
    if self.energy <= 0 then
        self.energy = 0
        self.gone = true
    end

    if self.doDieOutsideField then self:dieOutsideField() end

    if self.doesListenToSome then
        for id, value in pairs(self.action) do
            self.actionOld[id] = self.action[id]
        end
        if self.listenToTouch then
            self.action.touchJustBegan = false
            self.action.touchJustEnded = false
        end
    end

    self.inited = true
end

function self:adjustEnergy()
    self.energyOld = self.energy
    if self.energySpeed ~= nil and self.energySpeed ~= 0 then
        self.energy = self.energy + self.energySpeed

        if self.energySpeed > 0 and self.energy >= self.energyMax then
            self.energy = self.energyMax
            self.energySpeed = 0
        end
    end
end

function self:adjustAlpha()
    if self.energy <= 100 and math.floor(self.energy) ~= math.floor(self.energyOld) then
        self.alpha = misc.keepInLimits(self.energy * .01, 0, 1)

        if self.displayType == 'text' or self.displayType == 'line' then self:setColorBySelf()
        elseif self.imageName == nil then self:setFillColorBySelf()
        end
    end
end

function self:updatePositionIfNeeded()
    if self.speedX ~= 0 and self.speedX ~= nil then self.x = self.x + self.speedX end
    if self.speedY ~= 0 and self.speedY ~= nil then self.y = self.y + self.speedY end

    xFloor = self.x
    yFloor = self.y
    if self.doRoundPosition then
        xFloor = math.floor(xFloor)
        yFloor = math.floor(yFloor)
    end

    if xFloor ~= self.xOld then
        self.x = xFloor
        self.xOld = xFloor
    end
    if yFloor ~= self.yOld  then
        self.y = yFloor
        self.yOld = yFloor
    end
end

function self:moveWithParent()
    if self.parentId ~= nil then
        local parentSprite = app.sprites[self.parentId]
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

function self:rotateWithParent()
    local parentSprite = app.sprites[self.parentId]
    if parentSprite ~= nil and parentSprite.rotation ~= nil then
        self.rotation = parentSprite.rotation
    end
end

function self:disappearWithParent()
    local parentSprite = app.sprites[self.parentId]
    if parentSprite == nil or parentSprite.gone then self.gone = true end
end

function self:adjustRotation()
    if self.rotationSpeed ~= 0 then
        self.rotation = self.rotation + self.rotationSpeed
    end
end

function self:followTarget()
    if self.targetX ~= nil and self.targetY ~= nil then

        local targetPoint = {x = self.targetX, y = self.targetY}
        if self.targetPointSpeedWasSetFor == nil or
                (self.targetPointSpeedWasSetFor.x ~= targetPoint.x and self.targetPointSpeedWasSetFor.y ~= targetPoint.y) then

            local speedLimit = 1
            if self.speedLimitX ~= nil and (self.speedLimitY == nil or self.speedLimitX > self.speedLimitY) then
                speedLimit = self.speedLimitX
            elseif self.speedLimitY ~= nil then
                speedLimit = self.speedLimitY
            end
    
            self.speedX, self.speedY = misc.getNeededSpeedByTargetPoint( speedLimit, {x = self.x, y = self.y}, targetPoint )
            -- self.targetSpeedX, self.targetSpeedY = misc.getNeededSpeedByTargetPoint( speedLimit, {x = self.x, y = self.y}, targetPoint )

            self.targetPointSpeedWasSetFor = targetPoint
        end

        local fuzzy = 0
        if self.targetFuzziness ~= nil then fuzzy = self.targetFuzziness end
        local foundTarget = self.x >= self.targetX - fuzzy and self.x <= self.targetX + fuzzy and
                self.y >= self.targetY - fuzzy and self.y <= self.targetY + fuzzy

        if foundTarget and self.doSetPhaseWhenFoundTarget then
            self.phase:set('foundTarget')
            self.targetX = nil
            self.targetY = nil
            self.targetPointSpeedWasSetFor = nil
        end

    end
end

function self:followTargetOneOfXY()
    local didFindX = false; local didFindY = false

    if self.targetX ~= nil then
        if self.x < self.targetX then self.speedX = self.speedX + self.speedStep
        elseif self.x > self.targetX then self.speedX = self.speedX - self.speedStep
        end

        if self.targetFuzziness ~= nil then
            if self.x >= self.targetX - self.targetFuzziness and self.x <= self.targetX + self.targetFuzziness then
                self.x = self.targetX
                self.speedX = 0
                self.x = math.floor(self.x); self.targetX = math.floor(self.targetX)
                didFindX = true
            end
        end
    end

    if self.targetY ~= nil then
        if self.y < self.targetY then self.speedY = self.speedY + self.speedStep
        elseif self.y > self.targetY then self.speedY = self.speedY - self.speedStep
        end

        if self.targetFuzziness ~= nil then
            if self.y >= self.targetY - self.targetFuzziness and self.y <= self.targetY + self.targetFuzziness then
                self.y = self.targetY
                self.speedY = 0
                didFindY = true
            end
        end
    end

    if self.doSetPhaseWhenFoundTarget and didFindX and didFindY then self.phase:set('foundTarget') end
end

function self:followTargetRotation()
    if self.rotationSpeedLimit ~= nil and self.rotationSpeedLimit > 0 then
        local difference = (self.targetRotation - self.rotation) % 360

        if difference > 180 then difference = difference - 360
        elseif difference < -180 then difference = difference + 360
        end

        if difference > 0 then self.rotation = self.rotation + misc.getMin(difference, self.rotationSpeedLimit)
        else self.rotation = self.rotation + misc.getMax(difference, -self.rotationSpeedLimit)
        end
    else
        if self.rotation ~= self.targetRotation then self.rotation = self.targetRotation end
    end    

    if self.rotation >= app.maxRotation then self.rotation = self.rotation % app.maxRotation end
end

function self:setRgbWhite()
    self:setRgb(255, 255, 255)
end

function self:setRgbBlack()
    self:setRgb(0, 0, 0)
end

function self:setRgbRed()
    self:setRgb(255, 0, 0)
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

function self:centerText()
    self:setReferencePoint(display.CenterReferencePoint)
    self.x = self.originX
    self.y = self.originY
end

function self:setRgb(red, green, blue, optionalAlphaInPercent)
    self.red = misc.keepInLimits(red, 0, 255)
    self.green = misc.keepInLimits(green, 0, 255)
    self.blue = misc.keepInLimits(blue, 0, 255)
    if optionalAlphaInPercent ~= nil then
        self.alpha = misc.keepInLimits(self.energy * .01, 0, 1)
    end
    self:setFillColorBySelf()
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
    local colorChanged = (self.red ~= nil and self.green ~= nil and self.blue ~= nil) and
            (self.oldRed ~= self.red or self.oldGreen ~= self.green or self.oldBlue ~= self.blue)
    if colorChanged then
        self.oldRed = self.red
        self.oldGreen = self.green
        self.oldBlue = self.blue
        if self.displayType == 'text' then self:setFillColor(self.red, self.green, self.blue, self.alpha * 255)
        elseif self.displayType == 'line' then self:setColor(self.red, self.green, self.blue, self.alpha * 255)
        else self:setFillColor(self.red, self.green, self.blue, self.alpha * 255)
        end
    end
end

function self:setColorBySelf()
    if self.displayType == 'text' then
        self:setFillColor(self.red, self.green, self.blue, self.alpha * 255)
    elseif self.displayType == 'line' then
        self:setColor(self.red, self.green, self.blue, self.alpha * 255)
    end
end

function self:dieOutsideField()
    self.outsideCheckCounter = self.outsideCheckCounter + 1
    if self.outsideCheckCounter == 30 then
        self.outsideCheckCounter = 0
        if self:isOutside() then self.gone = true end
    end
end

function self:isOutside()
    return self.x + self.width < app.minX or
            self.x - self.width > app.maxX or
            self.y + self.height < app.minY or
            self.y - self.height > app.maxY
end

function self:adjustToTargetSpeedX()
    if self.speedX < self.targetSpeedX then
        self.speedX = self.speedX + self.speedStep
        if self.speedX > self.targetSpeedX then self.speedX = self.targetSpeedX end
    elseif self.speedX > self.targetSpeedX then
        self.speedX = self.speedX - self.speedStep
        if self.speedX < self.targetSpeedX then self.speedX = self.targetSpeedX end
    end
end

function self:adjustToTargetSpeedY()
    if self.speedY < self.targetSpeedY then
        self.speedY = self.speedY + self.speedStep
        if self.speedY > self.targetSpeedY then self.speedY = self.targetSpeedY end
    elseif self.speedY > self.targetSpeedY then
        self.speedY = self.speedY - self.speedStep
        if self.speedY < self.targetSpeedY then self.speedY = self.targetSpeedY end
    end
end

function self:bounceOffBoundary(rect)
    local didBounce = false
    if rect.x1 ~= nil and self.x - self.width / 2 <= rect.x1 and self.speedX ~= nil and self.speedX < 0 then
        self.x = rect.x1 - self.width / 2
        self.speedX = self.speedX * -1
        didBounce = true
    elseif rect.x2 ~= nil and self.x + self.width / 2 >= rect.x2 and self.speedX ~= nil and self.speedX > 0 then
        self.x = rect.x2 + self.width / 2
        self.speedX = self.speedX * -1
        didBounce = true
    end

    if rect.y1 ~= nil and self.y - self.height / 2 <= rect.y1 and self.speedY ~= nil and self.speedY < 0 then
        self.y = rect.y1 - self.height / 2
        self.speedY = self.speedY * -1
        didBounce = true
    elseif rect.y2 ~= nil and self.y + self.height / 2 >= rect.y2 and self.speedY ~= nil and self.speedY > 0 then
        self.y = rect.y2 + self.height / 2
        self.speedY = self.speedY * -1
        didBounce = true
    end
    return didBounce
end

function self:bounceOffAppBoundary(margin)
    if margin == nil then margin = 0 end
    return self:bounceOffBoundary( {x1 = app.minX - margin, y1 = app.minY - margin, x2 = app.maxX + margin, y2 = app.maxY + margin} )
end

function self:reappearOppositeIfOffAppBoundary(doRandomize)
    if doRandomize == nil then doRandomize = false end

    if self.speedX < 0 and self.x + self.width / 2 < app.minX then
        self.x = app.maxX + self.width / 2
        if doRandomize then self.y = math.random(app.minY, app.maxY) end
    elseif self.speedX > 0 and self.x - self.width / 2 > app.maxX then
        self.x = app.minX - self.width / 2
        if doRandomize then self.y = math.random(app.minY, app.maxY) end
    end
    if self.speedY < 0 and self.y + self.height / 2 < app.minY then
        self.y = app.maxY + self.height / 2
        if doRandomize then self.x = math.random(app.minX, app.maxX) end
    elseif self.speedY > 0 and self.y - self.height / 2 > app.maxY then
        self.y = app.minY - self.height / 2
        if doRandomize then self.x = math.random(app.minX, app.maxX) end
    end
end

function self:adjustRadius(radiusSpeed)
    self.radius = self.radius + radiusSpeed
    if self.radius <= 1 then self.radius = 1 end
    self.width = self.radius * 2
    self.height = self.radius * 2
end

function self:pushIntoAppBorders(margin)
    self:pushIntoRectangleBorders( {x1 = app.minX, y1 = app.minY, x2 = app.maxX, y2 = app.maxY}, 1 )
end

function self:pushIntoRectangle(rect, margin)
    if margin == nil then margin = 0 end
    if self.x - self.width / 2 < rect.x2 + margin then self.x = rect.x1 + margin + self.width / 2
    elseif self.x + self.width / 2 > rect.x2 - margin then self.x = rect.x2 - margin - self.width / 2
    end

    if self.y - self.height / 2 < rect.y1 + margin then self.y = rect.y1 + margin + self.height / 2
    elseif self.y + self.height / 2 > rect.y2 - margin then self.y = rect.y2 - margin - self.height / 2
    end
end

function self:topLeftAlign()
    self:setReferencePoint(display.TopLeftReferencePoint)
    self.x = self.originX
    self.y = self.originY
end

function self:topRightAlign()
    self:setReferencePoint(display.TopRightReferencePoint)
    self.x = self.originX
    self.y = self.originY
end

function self:kill(otherSprite)
    if otherSprite ~= nil then
        otherSprite.killedById = self.id
        otherSprite.gone = true
    end
end

function self:fadeIn(energySpeed)
    if energySpeed == nil then energySpeed = 1 end
    self.energy = 1
    self.energySpeed = energySpeed
    self.alphaChangesWithEnergy = true
end

function self:setTarget(point)
    self.targetX = point.x
    self.targetY = point.y
end

function self:setPoint(point)
    self.x = point.x
    self.y = point.y
end

function self:getPoint()
    return {x = self.x, y = self.y}
end

function self:getRectangle()
    return {x1 = self.x - self.width / 2, y1 = self.y - self.height / 2, x2 = self.x + self.width / 2, y2 = self.y + self.height / 2}
end

function self:getTopLeft()
    return {x = self.x - self.width / 2, y = self.y - self.height / 2}
end

function self:setFontSize(fontSize)
    self.size = fontSize * appGetScaleFactor()
end

function self:initPhase(phaseName)
    self.phase = phaseModule.phaseClass()
    if phaseName ~= nil then self.phase:set(phaseName) end
end

return self
end