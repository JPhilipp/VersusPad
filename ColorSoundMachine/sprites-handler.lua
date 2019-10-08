module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createBlockOrNavigationBlock(spriteType, subtype, x, y, rotationIndex, doFadeIn, noteIndex, isForPreview, scale, alpha, parentId)
    local function handle(self)
        for i, other in pairs(self.collisionWith) do
            app.spritesHandler:handleBlockCollision(self, other, self.collisionForce[i])
        end

        if self.type == 'block' then
            local changeLessFrames = {'neutral', 'drum', 'thinBlock', 'longThinBlock', 'moverField', 'swirl'}

            if self.isDragged and self.data.isTouchedCounter ~= nil then
                self.speedX = 0

                self.data.isTouchedCounter = self.data.isTouchedCounter + 1
                if self.data.isTouchedCounter >= 30 and self.data.isTouchedCounter % 20 == 0 and not misc.inArray(changeLessFrames, self.data.frameImage) then
                    self.data.noteIndex = self.data.noteIndex + 1
                    self.data.noteIndex = misc.keepInLimitsCircularFixed(self.data.noteIndex, 1, #self.data.notes)

                    if self.subtype == 'planeTunnel' and self.data.noteIndex == app.currentPlane then self.data.noteIndex = self.data.noteIndex + 1 end
                    self.data.noteIndex = misc.keepInLimitsCircularFixed(self.data.noteIndex, 1, #self.data.notes)

                    if self.subtype ~= 'planeTunnel' then
                        appPlaySound(app.baseInstrument .. '/' .. app.basePitch .. '-' .. self.data.notes[self.data.noteIndex])
                    end

                    app.spritesHandler:createWaveEffect(self.x, self.y, true)
                    app.spritesHandler:createDragHelper(self)
                end
            end

            if not misc.inArray(changeLessFrames, self.data.frameImage) then
                self.data.frameImage = self.data.notes[self.data.noteIndex]
            end

            if self.data.frameImage ~= self.data.frameImageOld then
                local oldFrame = appGetSpriteByTypeAndParentId('blockFrame', self.id)
                app.spritesHandler:createBlockFrame(self)
                if oldFrame ~= nil then
                    oldFrame:toFront()
                    oldFrame.energySpeed = -10
                    oldFrame.type = 'blockFrameOld'
                end
                local icon = appGetSpriteByTypeAndParentId('blockIcon', self.id)
                if icon then icon:toFront() end
            end
        end

        if self.phase.name == 'flip' then
            if not self.phase:isInited() then
                if misc.getArrayIndexByValue(self.data.rotations, self.rotation) ~= nil then
                    self.targetRotation = self.rotation * -1
                    self.data.rotationIndex = misc.getArrayIndexByValue(self.data.rotations, self.targetRotation)
                end
                self.phase:set('default')
            end

        elseif self.subtype == 'swirl' and self.type == 'block' then
            appBlowAwayBalls(self.x, self.y)

        elseif self.phase.name == 'movingBack' then
            if not self.phase:isInited() then
                self.speedX = self.speedX * -1
                self.speedY = self.speedY * -1
            end

            if self.data.placedX ~= nil and self.data.placedY ~= nil then
                if (self.speedX < 0 and self.x <= self.data.placedX) or (self.speedX > 0 and self.x >= self.data.placedX) or 
                        (self.speedY < 0 and self.y <= self.data.placedY) or (self.speedY > 0 and self.y >= self.data.placedY) then
                    self.speedX = 0
                    self.speedY = 0
                    self.x = self.data.placedX
                    self.y = self.data.placedY
                    self.phase:set('default')
                end
            end
        end

    end

    local function handleTouch(event)
        return app.spritesHandler:handleBlockTouch(event)
    end

    if rotationIndex == nil then rotationIndex = 1 end
    if doFadeIn == nil then doFadeIn = false end
    if noteIndex == nil then noteIndex = 1 end
    if isForPreview == nil then isForPreview = false end
    local moduleGroup = misc.getIf(isForPreview, 'menu', nil)

    local fadeInSpeed = 1
    local density = 8
    local bounce = nil
    local friction = 2
    local displayType = 'rectangle'
    local width = app.blockWidth
    local height = width
    local shape = nil
    if subtype == 'flipBlock' then width = 38; height = 13 * 3; shape = {0,13, width,13, width,13 * 2, 0,13 * 2}
    elseif subtype == 'thinBlock' then width = 68; height = 13 * 3; shape = {0,13, width,13, width,13 * 2, 0,13 * 2}
    elseif subtype == 'planeTunnel' then width = 37 / 2; height = nil; displayType = 'circle'
    elseif subtype == 'moverField' then width = 36; height = width
    elseif subtype == 'swirl' then width = 35 / 2; height = nil; displayType = 'circle'
    end

    local isSensor = misc.inArray( {'planeTunnel', 'moverField', 'swirl'}, subtype )
    local isPhysical = not isForPreview
    local self = spriteModule.spriteClass(displayType, spriteType, subtype, nil, isPhysical, x, y, width, height,
            nil, nil, shape, nil, isSensor, density, bounce, friction)
    self.parentId = parentId
    if isSensor then self.listenToCollision = true
    else self.listenToPostCollision = true
    end
    self.bodyType = 'kinematic'
    self.isVisible = false
    self.isHitTestable = true
    self.data.isTouchedCounter = nil
    self.data.dropped = false
    self.doDieOutsideField = false
    self.rotationSpeedLimit = 4
    self.data.placedX = nil
    self.data.placedY = nil
    if self.type == 'block' then
        self.data.placedX = self.x
        self.data.placedY = self.y
    end

    self.data.notesType = nil
    self.data.isDropper = misc.inArray(
            {'dropper', 'changeDropper', 'changeReverseDropper', 'dropperPlus', 'dropperMinus', 'planeBallDropper', 'bumpDropper', 'waitDropper'}, self.subtype )

    local doesChangeColor = not ( self.data.isDropper or
            misc.inArray( {'thinBlock', 'flipBlock', 'speederBlock', 'slowerBlock', 'moverField', 'swirl'}, self.subtype) )
    if self.subtype == 'allBlock' then  self.data.notesType = 'all'
    elseif self.subtype == 'otherBlock' then self.data.notesType = 'majorPentanonicSelection'
    elseif self.subtype == 'planeTunnel' then self.data.notesType = 'planes'
    elseif not doesChangeColor then self.data.notesType = nil
    elseif self.subtype == 'dryBlock' then self.data.notesType = 'drum'
    else self.data.notesType = 'minorPentanonic'
    end

    self.data.notes = misc.getIf(self.data.notesType ~= nil, app.notes[self.data.notesType])
    self.data.noteIndex = noteIndex
    self.alsoAllowsExtendedNonPhysicalHandling = false

    self.data.rotationIndex = rotationIndex
    self.data.rotations = {app.rotationWeakest, app.rotationWeak, app.rotationStrong, app.rotationWeak,
            app.rotationWeakest, -app.rotationWeak, -app.rotationStrong, -app.rotationWeak}
    if self.subtype == 'flipBlock' then
        self.data.rotations = {app.rotationStrong, -app.rotationStrong}
        if self.type == 'navigationBlock' then self.data.rotationIndex = 1 end
    elseif self.subtype == 'moverField' then
        local rotationStep = 90
        self.rotationSpeedLimit = 12
        self.data.rotations = {}
        for i = 1, app.maxRotation / rotationStep do self.data.rotations[i] = rotationStep * (i - 1) end
    elseif self.subtype == 'thinBlock' then
        self.data.rotations = {
                app.rotationWeakest, app.rotationWeak, app.rotationStrong, app.rotationExtraStrong, app.rotationStrong, app.rotationWeak,
                app.rotationWeakest, -app.rotationWeak, -app.rotationStrong, -app.rotationExtraStrong, -app.rotationStrong, -app.rotationWeak}
        if self.type == 'navigationBlock' then self.data.rotationIndex = 3 end
    elseif (self.data.isDropper and self.subtype ~= 'bumpDropper') or
            misc.inArray( {'speederBlock', 'slowerBlock', 'planeTunnel', 'swirl'}, self.subtype ) then
        self.data.rotations = nil
    end
    if self.data.rotations ~= nil then self.rotation = self.data.rotations[self.data.rotationIndex] end

    if self.data.isDropper or misc.inArray( {'speederBlock', 'slowerBlock'}, self.subtype ) then self.data.frameImage = 'neutral'
    elseif self.subtype == 'dryBlock' then self.data.frameImage = 'drum'
    elseif self.subtype == 'flipBlock' then self.data.frameImage = 'thinBlock'
    elseif self.subtype == 'thinBlock' then self.data.frameImage = 'longThinBlock'
    elseif self.subtype == 'moverField' then self.data.frameImage = 'moverField'
    elseif self.subtype == 'swirl' then self.data.frameImage = 'swirl'
    elseif self.subtype == 'planeTunnel' then self.data.frameImage = 'planeTunnel-' .. noteIndex
    else self.data.frameImage = self.data.notes[self.data.noteIndex]
    end

    if alpha ~= nil then app.spritesHandler:createBlockFrame(self, scale, nil, nil, alpha, moduleGroup)
    else app.spritesHandler:createBlockFrame(self, scale, doFadeIn, fadeInSpeed)
    end

    self:addEventListener('touch', handleTouch)

    if spriteType == 'navigationBlock' then self.data.picked = false end

    if self.type == 'block' and subtype == 'swirl' then app.spritesHandler:startSwirlRotation(self) end

    appAddSprite(self, handle, moduleGroup)

    local iconLessBlocks = {'normalBlock', 'dryBlock', 'thinBlock', 'planeTunnel', 'moverField', 'flipBlock', 'swirl'}
    if not misc.inArray(iconLessBlocks, subtype) then
        local icon = spriteModule.spriteClass('rectangle', 'blockIcon', subtype, 'block-icon/' .. subtype, false, self.x, self.y, 34, 34)
        icon.parentId = self.id
        icon.movesWithParent = true
        icon.rotatesWithParent = true
        icon.isVisible = true
        icon.doDieOutsideField = false
        if doFadeIn then
            icon.energy = 10
            icon.energySpeed = fadeInSpeed
            icon.alphaChangesWithEnergy = true
        end
        if scale ~= nil then icon:scale(scale, scale) end
        appAddSprite(icon, nil, moduleGroup)
    end

    return self.id
end

function self:handleBlockCollision(self, other, collisionForce)
    local minCollisionForceToCount = 4
    if self.type == 'block' and ( self.isSensor or (collisionForce and collisionForce >= minCollisionForceToCount) ) then
        local noteIndexBefore = self.data.noteIndex

        if other.type == 'ball' and other.parentId ~= self.id then
            local pitch = app.basePitch
            if self.subtype ~= 'lockedBlock' then
                if other.subtype == 'minus' then pitch = pitch - 1
                elseif other.subtype == 'plus' then pitch = pitch + 1
                end
            end

            if self.data.notes ~= nil and self.subtype ~= 'planeTunnel' then
                local instrument = app.baseInstrument
                if other.subtype == 'plane' then
                    instrument = app.planeInstrument[app.currentPlane].name
                    pitch = app.planeInstrument[app.currentPlane].pitch
                end
                appPlaySound(instrument .. '/' .. pitch .. '-' .. self.data.notes[self.data.noteIndex])
                app.spritesHandler:createWaveEffect(other.x, other.y)
            elseif self.subtype == 'dryBlock' then
                if other.subtype == 'plane' then appPlaySound('drum/plane')
                else appPlaySound('drum/' .. pitch)
                end
                app.spritesHandler:createWaveEffect(other.x, other.y)
            end

            if self.subtype == 'bouncerBlock' then
                if self.y > other.y then
                    local force = 14
                    local nearbySpeederCount = appGetSpriteCountNearby('block', 'speederBlock', self.x, self.y, app.blockDistanceConsideredNear)
                    if nearbySpeederCount >= 2 then force = 28
                    elseif nearbySpeederCount == 1 then force = 22
                    end
                    other:applyLinearImpulse(nil, -force, other.x, other.y)
                end
            end

            if self.data.notes ~= nil and self.subtype ~= 'lockedBlock' then
                local changeDirection = 0
                if other.subtype == 'changer' then changeDirection = 1
                elseif other.subtype == 'changerReverse' then changeDirection = -1
                end
                if changeDirection ~= 0 then
                    self.data.noteIndex = self.data.noteIndex + changeDirection
                    self.data.noteIndex = misc.keepInLimitsCircularFixed(self.data.noteIndex, 1, #self.data.notes)

                    if self.subtype == 'planeTunnel' and self.data.noteIndex == app.currentPlane then
                        self.data.noteIndex = self.data.noteIndex + changeDirection
                        self.data.noteIndex = misc.keepInLimitsCircularFixed(self.data.noteIndex, 1, #self.data.notes)
                    end
                end
            end

            if self.subtype == 'flipBlock' then
                self.phase:setNext('flip', 15)
            elseif self.subtype == 'bumpDropper' then
                app.spritesHandler:createBall( appGetBallSubtypeByBlock(self.subtype), self.x, self.y + self.height / 2, self.id )
            elseif self.subtype == 'moverField' then
                if self.phase.name == 'default' then
                    if not self.phase:isInited() then
                        if self.rotation == self.targetRotation or self.targetRotation == nil then
                            appMoveNearBlocksInDirection(self)
                            self.phase:set('waitBeforeMovingAgain', 40, 'default')
                        end
                    end
                end
            elseif self.subtype == 'planeTunnel' then
                self.data.placedX = self.x
                self.data.placedY = self.y
                if appChangePlane(noteIndexBefore) then
                    other.gone = true
                end
            end
        end

    end
end

function self:handleBlockTouch(event)
    if app.runs and (self.energySpeed == nil or self.energySpeed >= 0) then
        local self = event.target
        if event.phase == 'began' then

            if not appASpriteIsDragged() then

                if misc.inArray(app.premiumBlocks, self.subtype) and not app.products[1].isPurchased then
                    appCreatePageUnlockPremium()
                else
                    self.data.isTouchedCounter = 0
        
                    self.data.dragOffsetX = self.x - event.x
                    self.data.dragOffsetY = self.y - event.y
                    self.data.dragStartX = self.x
                    self.data.dragStartY = self.y
                    self.speedX = 0
                    self.speedY = 0
                    self.phase:set('default')
        
                    local stage = display.getCurrentStage()
                    stage:setFocus(self, event.id)
                    self.isDragged = true
                    if not self.data.picked then self.data.picked = true end
        
                    if self.type == 'navigationBlock' then
                        if self.subtype == 'thinBlock' then
                            local childFrame = appGetSpriteByTypeAndParentId('blockFrame', self.id)
                            if childFrame ~= nil then childFrame.xScale =1; childFrame.yScale = 1 end
                            self.data.rotationIndex = 1
                            self.targetRotation = self.data.rotations[self.data.rotationIndex]
        
                        elseif self.subtype == 'planeTunnel' and app.currentPlane == 1 then
                            self.data.noteIndex = 2
                        end
        
                        appPlaySound('pick-up')
                        self.type = 'block'
                        app.spritesHandler:createBlockOrNavigationBlock('navigationBlock', self.subtype, self.x, self.y, nil, true)
                        if appGetSpriteCountByType('block') > app.maxBlocksToPlace then self.energySpeed = -5 end            
                    end
        
                    app.spritesHandler:createDragHelper(self)
                end
            end
    
        elseif event.phase == 'ended' or event.phase == 'cancelled' then
    
            if self.isDragged then
                local wasShortTap = self.data.isTouchedCounter == nil or self.data.isTouchedCounter < 10
                self.data.isTouchedCounter = 0
                if wasShortTap and self.data.rotations ~= nil and #self.data.rotations > 1 then
                    local draggedDistance = nil
                    if self.data.dragStartX ~= nil and self.data.dragStartY ~= nil then
                        draggedDistance = misc.getDistance( {x = self.data.dragStartX, y = self.data.dragStartY}, {x = self.x, y = self.y} )
                        self.data.dragStartX = nil
                        self.data.dragStartY = nil
                    end

                    if draggedDistance == nil or draggedDistance <= 10 then
                        self.data.rotationIndex = self.data.rotationIndex + 1
                        if self.data.rotationIndex > #self.data.rotations then self.data.rotationIndex = 1 end
                        self.targetRotation = self.data.rotations[self.data.rotationIndex]
                        self:makeSound('rotate', true)

                        if self.subtype == 'flipBlock' then self.phase:set('default') end
                    end
                end
    
                local stage = display.getCurrentStage()
                stage:setFocus(self, nil)
                self.isDragged = false
                self.data.dragOffsetX = nil
                self.data.dragOffsetY = nil
    
                if self.y > app.yConsideredBottomArea then
                    app.blockDidntLeaveBottomAreaInRow = app.blockDidntLeaveBottomAreaInRow + 1
                    if app.blockDidntLeaveBottomAreaInRow >= 4 then app.spritesHandler:createIntroVideoButton() end
                    self.gone = true
                elseif appGetNumberOfPlacedItems() > app.maxBlocksToPlace then
                    appPlaySound('cannot-do-this')
                    self.gone = true
                else        
                    self.data.placedX = self.x
                    self.data.placedY = self.y
                    app.blockDidntLeaveBottomAreaInRow = 0
                    local videoButton = appGetSpriteByType('introVideoButton')
                    if videoButton ~= nil and videoButton.phase.name == 'default' then videoButton.phase:set('fadeOut') end
                end
    
                if self.y + 20 >= app.yConsideredBottomArea then
                    self.y = app.yConsideredBottomArea - 20 - 1
                end
    
                if self.subtype == 'horizontalMover' then
                    self.speedX = 0
                    self.alsoAllowsExtendedNonPhysicalHandling = true
                elseif self.subtype == 'swirl' then
                    app.spritesHandler:startSwirlRotation(self)
                end
    
                self.data.dropped = true
                local dragHelper = appGetSpriteByTypeAndParentId('dragHelper', self.id)
                if dragHelper ~= nil then
                    dragHelper.energy = 100
                    dragHelper.energySpeed = -4
                end
            end
    
        else
            if not self.data.didLeaveBottomArea then
                self.data.didLeaveBottomArea = self.data.dragOffsetY ~= nil and event.y + self.data.dragOffsetY <= app.yConsideredBottomArea
            end
    
        end
    
        if self.isDragged and event.x ~= nil and event.y ~= nil and self.data.dragOffsetX ~= nil and self.data.dragOffsetY ~= nil then
            self.x = event.x + self.data.dragOffsetX
            self.y = event.y + self.data.dragOffsetY
        end
    
        local continueEventPropagation = false
        return continueEventPropagation
    end
end

function self:startSwirlRotation(sprite)
    sprite.rotationSpeed = 2
    sprite.alsoAllowsExtendedNonPhysicalHandling = true
    local existingSwirl = appGetSpriteByType('block', 'swirl')
    if existingSwirl ~= nil then sprite.rotation = existingSwirl.rotation end
end

function self:createIntroVideoButton()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            media.playVideo('video/intro.m4v', true)
            self.phase:set('fadeOut')
        end

        if self.phase.name == 'fadeOut' then
            if not self.phase:isInited() then
                self.energySpeed = -2
                self.phase:set('default')
            end
        end
    end

    if appGetSpriteCountByType('introVideoButton') == 0 then
        local self = spriteModule.spriteClass('rectangle', 'introVideoButton', nil, 'introVideoButton', false, 259, 395, 65, 26)
        self.energy = 10
        self.energySpeed = 5
        self.alphaChangesWithEnergy = true
        self.phase:setNext('fadeOut', 500)
        self.listenToTouch = true
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createPremiumMarker(x, y, parentId, optionalModuleGroup)
    if optionalModuleGroup == nil then optionalModuleGroup = moduleGroup end
    local self = spriteModule.spriteClass('rectangle', 'premiumMarker', nil, 'premiumMarker', false, x, y, 31, 22)
    self.parentId = parentId
    appAddSprite(self, handle, optionalModuleGroup)
end

function self:createBlockFrame(parentSprite, scale, doFadeIn, fadeInSpeed, alpha, optionalModuleGroup)
    if doFadeIn == nil then doFadeIn = false end
    if fadeInSpeed == nil then fadeInSpeed = 1 end

    local self = spriteModule.spriteClass('rectangle', 'blockFrame', frameName, 'block/' .. parentSprite.data.frameImage, false,
            parentSprite.x, parentSprite.y, parentSprite.width, parentSprite.height)
    self.parentId = parentSprite.id
    self.movesWithParent = true
    if doFadeIn then
        self.energy = 10
        self.energySpeed = fadeInSpeed
    elseif alpha ~= nil then
        self.alpha = alpha
    end

    if parentSprite.type == 'navigationBlock' and parentSprite.subtype == 'thinBlock' then
        local thisScale = .7
        self:scale(thisScale, thisScale)
    end

    if scale ~= nil then self:scale(scale, scale) end

    self.alphaChangesWithEnergy = true
    self.doDieOutsideField = false
    self.rotatesWithParent = true
    self.rotation = parentSprite.rotation
    appAddSprite(self, handle, optionalModuleGroup)
    parentSprite.data.frameImageOld = parentSprite.data.frameImage
end

function self:createBall(subtype, x, y, parentId)
    local function handle(self)
        if self.y >= app.yConsideredBottomArea - 5 then self.gone = true end
    end

    local thisCount = appGetSpriteCountByType('ball')
    if thisCount < app.maxBallsToDrop then
        local density = 8; local bounce = .2; local friction = 0.01

        local radius = 17 / 2
        local image = 'ball-icon/' .. subtype
        if subtype == 'plane' then image = image .. '-' .. app.currentPlane end
        local self = spriteModule.spriteClass('circle', 'ball', subtype, image, true, x, y, radius, nil,
                nil, nil, nil, nil, nil, density, bounce, friction)

        self.parentId = parentId
        self.isBullet = true -- mit isBullet = true auf dem iPhone 4 circa 19 FPS
        appAddSprite(self, handle, moduleGroup)

        local ballBack = spriteModule.spriteClass('circle', 'ballBack', nil, 'ball', false, x, y, radius)
        ballBack.parentId = self.id
        ballBack.movesWithParent = true
        ballBack.doDieOutsideField = false
        appAddSprite(ballBack, nil, moduleGroup)

        self:toFront()
    end

    if thisCount >= app.maxBallsToDrop - 10 then appRemoveOldestSlowly('ball') end
end

function self:createBackground()
    appRemoveSpritesByType('background')
    local image = 'plane-background/' .. app.currentPlane
    local self = spriteModule.spriteClass('rectangle', 'background', nil, image, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self:toBack()
    appAddSprite(self, handle, moduleGroup)
end

function self:createWaveEffect(x, y, isStrong)
    local function handle(self)
        self:adjustRadius(1)
    end

    if appGetSpriteCountByType('waveEffect') <= 10 then
        local radius = 8
        if isStrong then radius = 25 end
        local self = spriteModule.spriteClass('circle', 'waveEffect', nil, nil, false, x, y, radius)
        self.radius = radius
        self.energy = 90
        self.energySpeed = -6
        self.alphaChangesWithEnergy = true
        self:setRgbWhite()
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createDragHelper(parentSprite)
    appRemoveSpritesByType('dragHelper')

    local image = 'dragHelper/'
    if parentSprite.data.noteIndex ~= nil and parentSprite.data.notes ~= nil then
        if parentSprite.subtype == 'planeTunnel' then
            image = image .. app.notes['planesInNotes'][parentSprite.data.noteIndex]
        else
            image = image .. parentSprite.data.notes[parentSprite.data.noteIndex]
        end
    else
        image = image .. 'default'
    end

    local self = spriteModule.spriteClass('rectangle', 'dragHelper', nil, image, false, parentSprite.x, parentSprite.y, 148, 148)
    self.parentId = parentSprite.id
    self.movesWithParent = true
    self.energy = 30
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    self.doDieOutsideField = false
    self.rotatesWithParent = true
    self.rotation = parentSprite.rotation
    appAddSprite(self, handle, moduleGroup)
end

function self:createNavigation()
    appRemoveSpritesByType( {'navigationBlock', 'navigationBlockDescription'} )

    local minBlock = (app.currentNavigationPage - 1) * app.blocksPerNavigationPage + 1
    local maxBlock = misc.getMin(#app.blockSubtypes, minBlock + app.blocksPerNavigationPage - 1)
    local xMin = 27
    local xMargin = 15
    local y = 443
    local blockI = 0
    local x = xMin
    for i = minBlock, maxBlock do
        blockI = blockI + 1
        local subtype = app.blockSubtypes[i]
        local blockId = app.spritesHandler:createBlockOrNavigationBlock('navigationBlock', subtype, x, y, nil, nil)

        local descriptionWidth = 43
        local descriptionHeight = 15
        appPrint( 'appGetScaleFactor = ' .. appGetScaleFactor() )
        local image = 'block-description/' .. subtype
        if app.device == 'iPhone' or app.isAndroid then
            image = image .. '-short'
            descriptionWidth = 45
            descriptionHeight = 16
        end

        local description = spriteModule.spriteClass('rectangle', 'navigationBlockDescription', nil, image, false, x, y + 27, 43, 15)
        appAddSprite(description, handle, moduleGroup)

        if misc.inArray(app.premiumBlocks, subtype) and not app.products[1].isPurchased then
            app.spritesHandler:createPremiumMarker(x, y, blockId)
        end

        x = x + app.blockWidth + xMargin
    end

    if appGetSpriteCountByType('nextButton') == 0 then app.spritesHandler:createNextButton() end

    if appGetSpriteCountByType('navigationDescription') == 0 and app.device == 'iPad' then
        local navigationDescription = spriteModule.spriteClass('rectangle', 'navigationDescription', nil, 'navigationDescription', false, app.maxXHalf, y - 23, 278, 4)
        appAddSprite(navigationDescription, handle, moduleGroup)
    end
end

function self:createNextButton()
    local function handle(self)
        if self.action.touchJustBegan then
            appPlaySound('click')
            app.currentNavigationPage = app.currentNavigationPage + 1
            local maxNavigationPages = 4 -- math.ceil( (#app.blockSubtypes + 1) / app.blocksPerNavigationPage ) + 1
            if app.currentNavigationPage > maxNavigationPages then app.currentNavigationPage = 1 end
            app.spritesHandler:createNavigation()
        end
    end

    local y = app.maxY - ( (app.maxY - app.yConsideredBottomArea) / 2 )
    local self = spriteModule.spriteClass('rectangle', 'nextButton', nil, 'nextButton', false, 317, 447, 44, 63)
    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

return self
end