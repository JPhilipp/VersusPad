module(..., package.seeall)
local moduleGroup = 'interface'

function spritesHandlerInterfaceClass()
local self = {}

function self:createPauseButton()
    local function handle(self)
        if self.action.touchJustEnded then appTogglePausePlay()
        else self:toFront()
        end
    end

    local width, height = 80, 80
    local x = app.alignmentRectangle.x1 + width / 2
    local y = app.alignmentRectangle.y2 - height / 2

    local framesData = {
            image = {width = width * 2, height = height, count = 2},
            names = { {name = 'pause', start = 1}, {name = 'resume', start = 2} }
    }
    local self = spriteModule.spriteClass('rectangle', 'pauseButton', nil, moduleGroup .. '/pauseButton', false, x, y, width, height,
            framesData)
    self.alpha = .6
    self.blendMode = 'add'
    self.listenToTouch = true
    self.frameName = 'pause'
    appAddSprite(self, handle, moduleGroup)
end

function self:createWaveInfo()
    local function handle(self)
        if self.data.oldWave == nil or app.wave ~= self.data.oldWave then
            self.data.oldWave = app.wave
            local text = app.mapData[app.mapNumber].title:upper() .. '  |  WAVE ' .. misc.getIf(app.wave < 1, 1, app.wave) .. ' / ' .. app.wavesGoal
            if app.wave > app.wavesGoal then
                text = text .. ' | YOU WON!'
            end
            self.text = text
            self:topLeftAlign()
        end
        self:toFront()
    end

    local x = app.alignmentRectangle.x1 -- app.minX + 125
    local y = app.alignmentRectangle.y1 -- app.minY + 20
    local width = 850; local height = 50

    local self = spriteModule.spriteClass('text', 'waveInfo', 'text', nil, false, x, y, width, height)
    self.text = app.mapData[app.mapNumber].title:upper()
    self.size = 32
    self.alpha = .6
    self.data.oldWave = nil
    self:topLeftAlign()
    appAddSprite(self, handle, moduleGroup)

    local subtitle = spriteModule.spriteClass('text', 'waveInfo', 'subtitle', nil, false, x, y + 32, width, height)
    local allTimeBestWaves = app.data:get('allTimeBestWaves_' .. app.mapPack .. '_' .. app.mapNumber, 1)
    subtitle.text = 'ALL TIME BEST: ' .. tostring(allTimeBestWaves) .. ' WAVE' .. misc.getIf(allTimeBestWaves > 1, 'S', '')
    subtitle.size = 25
    subtitle.alpha = .6
    subtitle.data.oldWave = nil
    subtitle:topLeftAlign()
    appAddSprite(subtitle, nil, moduleGroup)
end

function self:createLifeInfo()
    local function handle(self)
        if app.lifeCount < 0 then app.lifeCount = 0 end

        if self.data.oldLifeCount == nil or app.lifeCount ~= self.data.oldLifeCount then
            self.text = app.lifeCount
            self.data.oldLifeCount = app.lifeCount

            if app.lifeCount < app.lifeCountAtStart then
                local icon = appGetSpriteByType('lifeInfo', 'icon')
                if icon ~= nil then
                    local ghost = app.spritesHandler:createGhost(icon)
                    ghost:setFillColor(255, 0, 0, 100)
                    ghost.group = 'interface'
                    ghost:setRgbRed(100)
                    ghost.energy = 90
                    ghost.energySpeed = -1.5
                    ghost.scaleSpeed = 1.01
                    ghost:toFront()
                    appPlaySound('dronePassed')
                    system.vibrate()
                end
            end

            if app.lifeCount <= 0 and app.phase.name == 'mainGame' then
                app.phase:set('gameOver')
            end
        end
    end

    local x = app.alignmentRectangle.x2
    local y = app.alignmentRectangle.y1

    local width, height = 75, 50
    local icon = spriteModule.spriteClass('rectangle', 'lifeInfo', 'icon', moduleGroup .. '/life', false, x - width / 2, y + height / 2, width, height)
    icon.alpha = .42
    icon.blendMode = 'add'
    appAddSprite(icon, nil, moduleGroup)

    local self = spriteModule.spriteClass('text', 'lifeInfo', 'text', nil, false, x - width / 2, y + height / 2 + 2, nil, nil)
    self.size = 35
    self:setRgbBlack()
    self.data.oldLifeCount = nil
    appAddSprite(self, handle, moduleGroup)
end

function self:createCreationBar()
    local function handle(self)
        if app.creationEnergy < app.creationEnergyMax then
            if app.runs and app.phase.name == 'mainGame' then
                app.creationEnergy = app.creationEnergy + app.creationEnergySpeed
            end

            if app.creationEnergy >= app.creationEnergyMax then
                app.creationEnergy = app.creationEnergyMax
            end

            if app.creationEnergy == app.creationEnergyMax and app.creationEnergySpeed > 0 then
                app.creationEnergySpeed = 0

                appPlaySound('newCreationObject')
                local creationObjectBacks = appGetSpritesByType('creationObjectBack')
                local textX, textY = nil, nil
                for i = 1, #creationObjectBacks do
                    local back = creationObjectBacks[i]
                    back.frameName = 'active'
                    back.blendMode = 'add'
                    if textX == nil or back.x - back.width / 2 < textX then
                        textX = back.x - back.width / 2
                        textY = back.y
                    end
                end

                local creationObjects = appGetSpritesByType('creationObject')
                for i = 1, #creationObjects do
                    creationObjects[i].data.isReady = true
                end

                if textX ~= nil then
                    local text, isExtraWide = appGetReadyText()
                    local width = misc.getIf(isExtraWide, 350, 270)
                    local readyText = spriteModule.spriteClass('text', 'creationObjectsReadyText', nil, nil, false, textX - 25, textY + 20, width, 48)
                    readyText:setRgbWhite()
                    readyText.size = 30
                    readyText.energy = 1
                    readyText.energySpeed = 5
                    readyText.alpha = .01
                    readyText.targetX = textX - 55
                    readyText.speedX = -1
                    readyText.speedLimitX = 1
                    readyText.doFollowTargetOneOfXY = true
                    readyText.alphaChangesWithEnergy = true
                    readyText.text = text
                    readyText.blendMode = 'add'
                    appAddSprite(readyText, nil, moduleGroup)
                end

                local function ghostHandler(self)
                    self.width = self.width + 2
                    self.height = self.height + 2
                end

                local ghost = app.spritesHandler:createGhost(self)
                ghost.y = ghost.y - ghost.height / 2
                ghost:setRgbWhite()
                ghost.energy = 100
                ghost.energySpeed = -4
                ghost.handle = ghostHandler
                ghost.blendMode = 'add'
                ghost:toFront()

            end
        end

        if self.data.oldCreationEnergy == nil or app.creationEnergy ~= self.data.oldCreationEnergy then
            if app.creationEnergy <= 0 then
                self.isVisible = false
            else
                self.isVisible = true
                self:setReferencePoint(display.BottomCenterReferencePoint)
                local percentage = misc.getPercentRounded(app.creationEnergyMax, app.creationEnergy)
    
                self.y = self.data.bottom + 1
                self.height = math.floor( (percentage * self.data.maxHeight) / 100 ) + 1
            end

            self.data.oldCreationEnergy = app.creationEnergy
        end
    end

    local function handleLine(self)
        if app.runs then
            local bar = app.sprites[self.data.barId]
            if bar ~= nil then
                if app.creationEnergy < app.creationEnergyMax then
                    if self.y > bar.data.top then self.y = self.y - 2
                    else self.y = bar.data.bottom
                    end
                end
                self.isVisible = self.y > bar.y - bar.height and app.creationEnergy < app.creationEnergyMax and app.creationEnergy > 5
                self:toFront()
    
            else
                self.gone = true
            end
        end
    end

    local x = app.alignmentRectangle.x2
    local y = app.alignmentRectangle.y2

    local width, height = 24, 98
    local image = moduleGroup .. '/creationBar'
    local barBack = spriteModule.spriteClass('rectangle', 'creationBar', 'background', image, false, x - width / 2, y - height / 2, width, height)
    barBack.blendMode = 'add'
    appAddSprite(barBack, nil, moduleGroup)

    width, height = 10, 82
    local self = spriteModule.spriteClass('rectangle', 'creationBar', 'foreground', nil, false, barBack.x, barBack.y, width, height)
    self.data.top = self.y - self.height / 2
    self.data.bottom = self.y + self.height / 2
    self.data.maxHeight = self.height
    self.height = 1
    self:setRgbWhite()
    self.alpha = .8
    self.blendMode = 'add'
    self.data.oldCreationEnergy = nil
    appAddSprite(self, handle, moduleGroup)

    width, height = 10, 5
    image = moduleGroup .. '/creationBarLine'
    local line = spriteModule.spriteClass('rectangle', 'creationBar', 'line', image, false, self.x, self.data.bottom - height / 2, width, height)
    line.data.barId = self.id
    line.alpha = .6
    appAddSprite(line, handleLine, moduleGroup)    
end

function self:createCreationObjects()
    if app.creationObjectIndex <= #app.creationObjectOrder then
        local subtypes = app.creationObjectOrder[app.creationObjectIndex]
        local width, height, margin = 98, 98, 12
        for i = 1, #subtypes do
            local x = app.alignmentRectangle.x2 - width / 2 - ( (i - 1) * (width + margin) ) - 40
            local y = app.alignmentRectangle.y2 - height / 2
            app.spritesHandlerInterface:createCreationObject(subtypes[#subtypes - i + 1], x, y, width, height)
        end
    
        app.creationObjectIndex = app.creationObjectIndex + 1
    end
end

function self:createCreationObject(subtype, x, y, width, height)
    local function handleTouch(event)
        local function handleBackPositionChange(self)

            local function getLeftMostBack(idToExclude)
                local leftMostBack = nil
                local backs = appGetSpritesByType('creationObjectBack')
                for i = 1, #backs do
                    if backs[i].id ~= idToExclude and (leftMostBack == nil or backs[i].x < leftMostBack.x) then
                        leftMostBack = backs[i]
                    end
                end
                return leftMostBack
            end

            local selfBack = app.sprites[self.data.backId]
            if selfBack ~= nil then
                selfBack.energySpeed = -4
                selfBack.speedY = 3

                local leftMostBack = getLeftMostBack(selfBack.id)
                if leftMostBack ~= nil then
                    if leftMostBack.x < selfBack.x then
                        leftMostBack.targetX = selfBack.x
                    end
                end

            end

        end

        local self = event.target

        if self.data.isReady then

            if event.phase == 'began' then
                if not appASpriteIsDragged() then
                    display.getCurrentStage():setFocus(self)
                    self.isDragged = true

                    self.parentId = nil
                    self.movesWithParent = false
                    self.disappearsWithParent = false

                    self.x = event.x
                    self.rotation = 0
                    self.y = event.y + self.data.draggingOffsetY
                    appPlaySound('pickUp')

                    handleBackPositionChange(self)

                    if appGetSpriteCountByType('creationObject') == 1 then
                        app.creationEnergy = 0
                        if app.creationObjectIndex > #app.creationObjectOrder then
                            local barParts = appGetSpritesByType('creationBar')
                            for i = 1, #barParts do
                                barParts[i].alphaChangesWithEnergy = true
                                barParts[i].energySpeed = -2
                            end
                        end
                    end

                    local readyText = appGetSpriteByType('creationObjectsReadyText')
                    if readyText ~= nil then
                        readyText.targetX = nil
                        readyText.speedY = 3
                        readyText.speedLimitY = math.abs(readyText.speedY)
                        readyText.energySpeed = -4
                    end

                end
    
            elseif event.phase == 'moved' then
                if self.isDragged then
                    self.x = event.x
                    self.y = event.y + self.data.draggingOffsetY
                end
    
            elseif event.phase == 'ended' or event.phase == 'cancelled' then
                if self.isDragged then
                    self.isDragged = false
                    appPlaySound('putDown')
                    display.getCurrentStage():setFocus(nil)

                    local rebelObject = app.spritesHandler:createRebelObject(self.subtype, self.x, self.y)
                    appHandleRotationRing(rebelObject)

                    if app.creationEnergy == 0 then
                        app.spritesHandlerInterface:createCreationObjects()
                        app.creationEnergySpeed = app.creationEnergySpeedDefault
                        local rebelObjectCount = appGetSpriteCountByType('rebelObject')
                        if rebelObjectCount <= 3 then
                            app.creationEnergySpeed = app.creationEnergySpeed * 2
                        elseif rebelObjectCount >= 13 then
                            app.creationEnergySpeed = app.creationEnergySpeed * .225
                        end
                    end

                    self.gone = true
                end
    
            end

        elseif appGetSpriteCountByType('waitText') == 0 then
            appPlaySound('cannotDoThis')
            local barBack = appGetSpriteByType('creationBar', 'background')
            if barBack ~= nil then
                local ghost = app.spritesHandler:createGhost(barBack)
                ghost:setFillColor(255, 0, 0, 100)
                ghost.group = 'interface'
                ghost:setRgbRed(100)
                ghost.energy = 150
                ghost.energySpeed = -2
                barBack:toBack()
                appBackgroundToBack()

                local waitText = spriteModule.spriteClass('text', 'waitText', nil, nil, nil,
                        app.alignmentRectangle.x2 - 250, app.alignmentRectangle.y2 - 120, 250, 60)
                waitText.size = 26
                waitText:topLeftAlign()
                waitText.text = "UNDER CONSTRUCTION"
                waitText.energy = 160
                waitText.energySpeed = -1
                waitText.speedY = -.25
                waitText.blendMode = 'add'
                waitText.alphaChangesWithEnergy = true
                waitText:setRgbByColorTriple( {red = 255, green = 31, blue = 31} )
                appAddSprite(waitText, nil, group)
            end
            appSetToFrontByType('creationBar', 'foreground')

        end

    end

    local function handleBack(self)
        if self.phase.name == 'wait' then
            if app.creationEnergy >= 20 and self.data.laterTargetY ~= nil then
                self.targetY = self.data.laterTargetY
                self.speedY = -4
                if app.creationObjectIndex >= 3 then
                    self.speedY = -2
                end
                self.speedLimitY = math.abs(self.speedY)
                self.targetFuzziness = 5
                self.data.laterTargetY = nil
            end
        end
    end

    local data = appGetRebelObjectData(subtype)

    local framesData = {
            image = {width = width * 2, height = height, count = 2},
            names = { {name = 'inactive', start = 1}, {name = 'active', start = 2} }
    }
    local back = spriteModule.spriteClass(displayType, 'creationObjectBack', subtype, moduleGroup .. '/creationObjectBack', false, x, y, width, height,
            framesData)
    back.frameName = 'inactive'
    back.alphaChangesWithEnergy = true
    back.y = app.maxY + 50 + height / 2 + 1
    back.data.laterTargetY = y
    back.doFollowTargetOneOfXY = true
    back.energy = 1
    back.energySpeed = 2
    back:initPhase('wait')
    appAddSprite(back, handleBack, moduleGroup)

    local image = 'rebelObject/gray/' .. subtype
    local self = spriteModule.spriteClass('rectangle', 'creationObject', subtype, image, false, x, y, data.width, data.height)
    self.parentId = back.id
    self.alphaChangesWithEnergy = true
    self.movesWithParent = true
    self.disappearsWithParent = true
    self.energyMax = 80
    self.rotation = 350
    self.blendMode = 'add'
    self.data.isReady = false
    self.data.draggingOffsetY = -70
    self:addEventListener('touch', handleTouch)
    self.data.backId = back.id
    self.energy = 1
    self.energySpeed = 1.8
    appAddSprite(self, nil, moduleGroup)
end

function self:createAnnounce(x, y, text, size, isGood)
    if x == nil then x = app.maxXHalf end
    if y == nil then y = app.maxYHalf end

    local self = spriteModule.spriteClass('text', 'announce', nil, nil, nil, x, y, nil, nil)
    self.size = size
    self.text = text
    self.energy = 180
    self.energySpeed = -1
    self.alphaChangesWithEnergy = true
    self:setRgbByColorTriple( misc.getIf(isGood, {red = 255, green = 255, blue = 156}, {red = 255, green = 31, blue = 31}) )
    self.scaleSpeed = 1.01
    self:toFront()
    appAddSprite(self, handle, moduleGroup)
end

function self:createNewBestAnnounce()
    local self = spriteModule.spriteClass('text', 'announce', nil, nil, nil, app.maxXHalf, app.maxYHalf + 100, nil, nil)
    self.size = 40
    self.text = 'NEW BEST: ' .. tostring(app.wave) .. ' WAVES!'
    self.energy = 300
    self.speedY = -.35
    self.energySpeed = -1
    self.alphaChangesWithEnergy = true
    self.scaleSpeed = 1.002
    self:setRgbByColorTriple( {red = 255, green = 255, blue = 156} )
    appAddSprite(self, handle, moduleGroup)
end

function self:createYouWonAnnounce()
    local function handle(self)
        if self.phase.name == 'rotate' then
            if not self.phase:isInited() then
                self.rotationSpeed = 1
            end
        end
    end

    local self = spriteModule.spriteClass('text', 'announce', 'win', nil, nil, app.maxXHalf, app.maxYHalf + 100, nil, nil)
    self.size = 55
    self.text = 'YOU WON!'
    self.energy = 400
    self.speedY = -.35
    self.energySpeed = -1
    self.alphaChangesWithEnergy = true
    self.scaleSpeed = 1.002
    self:setRgbByColorTriple( {red = 156, green = 255, blue = 156} )
    self:initPhase()
    self.phase:setNext('rotate', 200)
    appAddSprite(self, handle, moduleGroup)

    local overlay = spriteModule.spriteClass('rectangle', 'whiteOverlay', nil, nil, false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    overlay:setRgbWhite()
    overlay.energySpeed = -3
    overlay.energy = 100
    overlay.alphaChangesWithEnergy = true
    appAddSprite(overlay, nil, moduleGroup)

    appPlaySound('win')
end

function self:createLogo()
    local self = spriteModule.spriteClass('rectangle', 'logo', nil, 'logo', nil, app.maxXHalf + 10, app.maxYHalf - 56, 571, 205)
    self.energy = 130
    self.energySpeed = -1
    self.scaleSpeed = .999
    self.alphaChangesWithEnergy = true
    self.blendMode = 'add'
    appAddSprite(self, handle, moduleGroup)
end

function self:createAbout()
    local function handleTouch(event)
        if event.phase == 'began' then
            system.openURL('http://versuspad.com')
        end
    end

    local width = 731; local height = 156
    local x = app.alignmentRectangle.x1 + 60; local y = app.alignmentRectangle.y2 - height + 14
    local self = spriteModule.spriteClass('rectangle', 'about', nil, 'about', nil, x, y, width, height)
    self:topLeftAlign()
    appAddSprite(self, handle, group)

    local button = spriteModule.spriteClass('rectangle', 'about', nil, nil, nil, x + 352, y + 97, 241, 52)
    button:topLeftAlign()
    button:addEventListener('touch', handleTouch)
    button.isVisible = false
    button.isHitTestable = true
    appAddSprite(button, nil, moduleGroup)
end

function self:createPacksMenu()
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'began' then
            appPlaySound('click')

            -- appStoreCallback( {transaction = { state = 'purchased', productIdentifier = appPrefixProductId('routes3') } } )

            local alreadySelected = app.mapPack == self.data.number
            if alreadySelected then
                appTogglePausePlay()

            else
                local isPurchased = self.data.number == 1 or appGetProductIsPurchasedPerDB( appPrefixProductId('routes' .. self.data.number) )
                if isPurchased then
                    appTrySelectPurchasedRoutesPack(self.data.number)
                else
                    appStartPurchase( appPrefixProductId('routes' .. self.data.number) )
                end

            end
        end
    end

    local function handleTouchRestore(event)
        local self = event.target
        if event.phase == 'began' then
            appPlaySound('click')
            appStartPurchaseRestore()
        end
    end

    local function handlePackImage(self)
        if self.data.number == app.mapPack then
            if self.energySpeed == 0 or self.energySpeed == nil then self.energySpeed = -1 end

            if self.energy < 80 and self.energySpeed < 0 then
                self.energySpeed = 1
            elseif self.energy > 98 and self.energySpeed > 0 then
                self.energySpeed = -1
            end
        else
            self.energySpeed = 0
            self.energy = 100
        end
    end

    local stripe = spriteModule.spriteClass('rectangle', 'packsMenu', 'stripe', nil, nil, app.maxXHalf, app.maxYHalf, app.maxX, 236)
    stripe.blendMode = 'add'
    stripe.alpha = .4
    appAddSprite(stripe, nil, group)

    local foundUnpurchasedOnes = false

    local x = 160; local y = 284
    local width = 282; local height = 204
    for i = 1, app.mapPackMax do
        local margin = 8
        local packBack = spriteModule.spriteClass('rectangle', 'packsMenu', 'packBack' .. i, nil, nil,
                x - margin, y - margin, width + margin * 2, height + margin * 2)
        packBack:topLeftAlign()
        packBack.isVisible = i == app.mapPack
        appAddSprite(packBack, nil, moduleGroup)

        local packImage = spriteModule.spriteClass('rectangle', 'packsMenu', 'packImage' .. i, 'packImage/' .. i, nil,
                x, y, width, height)
        packImage:topLeftAlign()
        packImage.data.number = i
        packImage:addEventListener('touch', handleTouch)
        packImage.alphaChangesWithEnergy = true
        appAddSprite(packImage, handlePackImage, moduleGroup)

        local isPurchased = false
        if i == 1 then isPurchased = true
        else isPurchased = appGetProductIsPurchasedPerDB( appPrefixProductId('routes' .. i) )
        end

        if not isPurchased then
            local lock = spriteModule.spriteClass('rectangle', 'packsMenu', 'lock' .. i, 'unlock', nil,
                    x + width - 130, y + 8, 119, 36)
            lock:topLeftAlign()
            lock.data.number = i
            lock.blendMode = 'add'
            lock.alpha = .4
            appAddSprite(lock, nil, moduleGroup)

            foundUnpurchasedOnes = true
        end

        x = x + width + 31
    end

    if foundUnpurchasedOnes then
        local restoreButton = spriteModule.spriteClass('text', 'packsMenu', 'restoreButton', nil, nil,
                app.alignmentRectangle.x2 + height / 2 - 20, y - 5, height, height)
        restoreButton.rotation = -90
        restoreButton.text = 'RESTORE'
        restoreButton.size = 24
        restoreButton:addEventListener('touch', handleTouchRestore)
        appAddSprite(restoreButton, nil, moduleGroup)
    end

end

function self:createRepeatRouteButton()
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'began' and not self.data.wasClicked then
            appPlaySound('click')
            app.mapNumberToRepeat = app.mapNumber
            self.energySpeed = -1
            self.speedY = 1.5
            self.energy = 120
            self.data.wasClicked = true
            self:setFillColor(0, 255, 0, 100)
        end
    end

    local width = 305; local height = 42
    local self = spriteModule.spriteClass('rectangle', 'repeatRouteButton', nil, 'repeatRoute', nil,
            app.maxXHalf, app.alignmentRectangle.y2 - height / 2, width, height)
    self.energySpeed = -4
    self.energy = 800
    self:addEventListener('touch', handleTouch)
    self.alphaChangesWithEnergy = true
    self.data.wasClicked = false
    appAddSprite(self, nil, group)
end

return self
end
