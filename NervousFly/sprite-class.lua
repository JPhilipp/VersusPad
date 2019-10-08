module(..., package.seeall)

function spriteClass(displayType, type, subtype, imageName, isAutoPhysical, xOrLinePointsArray, y, widthOrRadius, heightOrNil,
        spriteSheetFrom, spriteSheetTo, polygonShapeOrShapes, parentPlayer, isSensor, density, bounce, friction, imagePathContext)
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

if imageName ~= nil then
    local translatedImage = appGetTranslatedImage(imageName)
    if translatedImage ~= nil then
        if translatedImage.width ~= nil then widthOrRadius = translatedImage.width end
        if translatedImage.height ~= nil then heightOrNil = translatedImage.height end
    end
end

if imageName ~= nil and string.find(imageName, '%.') == nil then imageName = imageName .. '.png' end
if isSensor == nil then isSensor = false end
if widthOrRadius == nil then widthOrRadius = 10 end
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

    if spriteSheetFrom ~= nil then
        local spriteSheet = spritesheetModule.newSpriteSheet( appToPath(imageName), thisWidthOrRadius, thisHeightOrNil )
        local spriteSet = spritesheetModule.newSpriteSet(spriteSheet, spriteSheetFrom, spriteSheetTo)
        self = spritesheetModule.newSprite(spriteSet)
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
    local fontSize = 15
    self = display.newText('', x, y, app.defaultFont, fontSize)
elseif displayType == 'group' then
    self = display.newGroup()
end

local likelyAnImageNotFoundIssue = self == nil
if likelyAnImageNotFoundIssue then return nil end

self.displayType = displayType
if displayType == 'circle' then
    self.radius = widthOrRadius
elseif displayType == 'text' then
    -- self.width = nil
    -- self.height = nil
else
    self.width = widthOrRadius
    self.height = heightOrNil
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
self.soundPhase = phaseModule.phaseClass()
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
self.targetFuzziness = nil
self.listenToPreCollision = false
self.listenToCollision = false
self.listenToPostCollision = false
self.listenToTouch = false
self.isDragged = false

self.animationFrames = nil -- to workaround Corona spritesheet scaling issue
self.animationFrameNames = nil
self.animationFrame = nil

self.collisionWith = {}
self.collisionForce = {}

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
self.parentPlayer = parentPlayer
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

self.frameNameNumber = {}
self.frameName = nil
self.frameOld = nil
self.frame = nil
self.frameSpeed = nil
self.rotationSpeed = nil
self.rotationSpeedLimit = nil
self.targetRotation = nil
self.rotationOld = nil
self.followBuffer = {}
self.phasesWithFrameNames = {}
self.extraPhasesWithFrameNames = {}
self.alsoAllowsExtendedNonPhysicalHandling = true

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

function self:setFrameNumbers(array)
    for i, v in ipairs(array) do
        self.frameNameNumber[v] = i
    end
end

function self:getParent()
    return appGetSpriteById(self.parentId)
end

function self:resetSpin()
    self.bodyType = 'static'
    self.bodyType = 'dynamic'
end

function self:magneticTowards(x, y, strength)
    if strength == 0 then strength = 1000 end
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

function self:pushTowardsDirection(angle)
    local x = math.cos(angle * math.pi / 180)
    local y = math.sin(angle * math.pi / 180)
    local speedX = x * (self.speedLimit * 10)
    local speedY = y * (self.speedLimit * 10)
    self:applyForce(speedX, speedY, self.x, self.y)
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

    if self.extraPhase ~= nil and not self.extraPhase.inited and misc.inArray(self.extraPhasesWithFrameNames, self.extraPhase.name) then
        self.frameName = self.extraPhase.name
    end
end

function self:handleGenericBehavior()
    self.collisionWith = {}
    self.collisionForce = {}

    if self.frameName ~= nil and self.frameNameNumber[self.frameName] ~= nil then
        self.currentFrame = self.frameNameNumber[self.frameName]
    end

    self:disappearWithParentIfNeeded()

    if self.alsoAllowsExtendedNonPhysicalHandling then
        self:moveWithParentIfNeeded()
        self:adjustToTargetSpeed()
        self:keepToSpeedLimits()
        self:followTarget()
        self:adjustRotation()
        self:adjustAlpha()
        self:setFillColorBySelf()
    end

    self:followTargetRotation()
    self:adjustFrame()

    if self.phase ~= nil then self.phase:handleCounter() end
    if self.extraPhase ~= nil then self.extraPhase:handleCounter() end
    if self.soundPhase ~= nil then self.soundPhase:handleCounter() end

    self:updatePositionIfNeeded()

    self:adjustEnergy()
    self:dieOutsideField()

    for id, value in pairs(self.action) do
        self.actionOld[id] = self.action[id]
    end
    if self.listenToTouch then
        self.action.touchJustBegan = false
        self.action.touchJustEnded = false
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
        if self.displayType == 'text' or self.displayType == 'line' then self:setColorBySelf()
        elseif self.imageName == nil then self:setFillColorBySelf()
        end
    end
end

function self:followTargetRotation()
    if self.targetRotation ~= nil then
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
    end
end

function self:updatePositionIfNeeded()
    if self.speedX ~= 0 and self.speedX ~= nil then self.x = self.x + self.speedX end
    if self.speedY ~= 0 and self.speedY ~= nil then self.y = self.y + self.speedY end

    local xFloor = math.floor(self.x)
    local yFloor = math.floor(self.y)

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

function self:adjustFrame()
    if self.frameSpeed ~= nil then
        if self.frame == nil or math.floor(self.frame) < 1 or math.floor(self.frame) > self.spriteSheetTo then self.frame = 1 end
        
        if math.floor(self.frame) ~= self.frameOld then
            self.currentFrame = math.floor(self.frame)
            self.frameOld = math.floor(self.frame)
        end

        self.frame = self.frame + self.frameSpeed
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
        if self.targetFuzziness ~= nil then
            if self.x >= self.targetX - self.targetFuzziness and self.x <= self.targetX + self.targetFuzziness then
                self.x = self.targetX
                self.speedX = 0
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
            end
        end
    end
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

function self:setRgb(red, green, blue, optionalAlphaInPercent)
    self.red = misc.keepInLimits(red, 0, 255)
    self.green = misc.keepInLimits(green, 0, 255)
    self.blue = misc.keepInLimits(blue, 0, 255)
    if optionalAlphaInPercent ~= nil then
        self.alpha = self:getAlphaFromPercent( misc.keepInLimits(optionalAlphaInPercent, 0, 100) )
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
    local colorChanged = (self.red ~= nil and self.green ~= nil and self.blue ~= nil) and
            (self.oldRed ~= self.red or self.oldGreen ~= self.green or self.oldBlue ~= self.blue)
    if colorChanged then
        self.oldRed = self.red
        self.oldGreen = self.green
        self.oldBlue = self.blue
        if self.displayType == 'text' then self:setTextColor(self.red, self.green, self.blue, self.alpha * 255)
        elseif self.displayType == 'line' then self:setColor(self.red, self.green, self.blue, self.alpha * 255)
        else self:setFillColor(self.red, self.green, self.blue, self.alpha * 255)
        end
    end
end

function self:setColorBySelf()
    if self.displayType == 'text' then
        self:setTextColor(self.red, self.green, self.blue, self.alpha * 255)
    elseif self.displayType == 'line' then
        self:setColor(self.red, self.green, self.blue, self.alpha * 255)
    end
end

function self:dieOutsideField()
    if self.doDieOutsideField and misc.getChance(5) then
        if self:isOutside() then self.gone = true end
    end
end

function self:isOutside()
    return (self.x + self.width < app.minX) or
            (self.x - self.width > app.maxX) or
            (self.y + self.height < app.minY) or
            (self.y - self.height > app.maxY)
end

function self:adjustToTargetSpeed()
    if self.targetSpeedX ~= nil then
        if self.speedX < self.targetSpeedX then
            self.speedX = self.speedX + self.speedStep
            if self.speedX > self.targetSpeedX then self.speedX = self.targetSpeedX end
        elseif self.speedX > self.targetSpeedX then
            self.speedX = self.speedX - self.speedStep
            if self.speedX < self.targetSpeedX then self.speedX = self.targetSpeedX end
        end
    end
    if self.targetSpeedY ~= nil then
        if self.speedY < self.targetSpeedY then
            self.speedY = self.speedY + self.speedStep
            if self.speedY > self.targetSpeedY then self.speedY = self.targetSpeedY end
        elseif self.speedY > self.targetSpeedY then
            self.speedY = self.speedY - self.speedStep
            if self.speedY < self.targetSpeedY then self.speedY = self.targetSpeedY end
        end
    end
end

function self:makeSound(soundName, doForcePlay)
    if self.soundPhase ~= nil then
        if doForcePlay == nil then doForcePlay = false end

        local doPlaySound = true

        if not doForcePlay then
            if self.soundPhase.name ~= 'default' then
                if self.soundPhase.name == soundName then doPlaySound = false
                elseif self.soundPhase.name ~= soundName then doPlaySound = true -- self.soundPhase.counter <= 1
                end
            end
        end

        if doPlaySound then
            appPlaySound(soundName)
            self.soundPhase:set(soundName, 20, 'default')
        end
    
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
    return self:bounceOffBoundary( {x1 = app.minX - margin, y1 = app.minY - margin, x2 = app.maxX + margin, y2 = app.maxY + margin} )
end

function self:updateAnimationFrame()
    for i = 1, #self.animationFrameNames do
        local frameName = self.animationFrameNames[i]
        local frame = self.animationFrames[frameName]
        if frame ~= nil then
            if self.animationFrame == frameName then
                frame.isVisible = true
                frame.rotation = self.rotation
                frame:toFront()

            else
                frame.isVisible = false
            end
        end
    end
end

function self:adjustRadius(radiusSpeed)
    self.radius = self.radius + radiusSpeed
    if self.radius <= 1 then self.radius = 1 end
    self.width = self.radius * 2
    self.height = self.radius * 2
end

function self:pushIntoAppBorders(margin)
    if margin == nil then margin = 10 end
    if self.x - self.width / 2 < app.minX + margin then self.x = app.minX + margin + self.width / 2
    elseif self.x + self.width / 2 > app.maxX - margin then self.x = app.maxX - margin - self.width / 2
    end

    if self.y - self.height / 2 < app.minY + margin then self.y = app.minY + margin + self.height / 2
    elseif self.y + self.height / 2 > app.maxY - margin then self.y = app.maxY - margin - self.height / 2
    end
end

function self:alertId()
    native.showAlert('Sprite', self.id)
end

function self:printId()
    print('sprite.id = ' .. self.id)
end

return self
end