module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createBackground()
    local self = spriteModule.spriteClass('rectangle', 'background', nil, 'background', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self:toBack()
    appAddSprite(self, handle, moduleGroup)
end

function self:createAvatar(index)
    local function handle(self)
        if self.action.touchJustBegan then
            appPlaySound('click')

            local speaker = app.speakers[self.data.index]
            if speaker.gender == 'male' and not speaker.isRobot then speaker.gender = 'female'; speaker.isRobot = false
            elseif speaker.gender == 'female' and not speaker.isRobot then speaker.gender = 'female'; speaker.isRobot = true
            elseif speaker.gender == 'female' and speaker.isRobot then speaker.gender = 'male'; speaker.isRobot = true
            elseif speaker.gender == 'male' and speaker.isRobot then speaker.gender = 'male'; speaker.isRobot = false
            end

            local otherSpeaker = misc.getIf(self.data.index == 1, 2, 1)
            if not speaker.isRobot and not (app.speakers[app.currentSpeaker].isRobot) then
                local message = appGetSpriteByType('message', 'robot-speaking')
                if message ~= nil then message.energySpeed = -5 end
            end

            app.spritesHandler:createAvatar(self.data.index)
            self.gone = true
        end

        if self.subtype == 'robot' and app.currentSpeaker == self.data.index then

            if self.phase.name == 'default' then
                if self.data.pictogramsToSpeak == nil or #self.data.pictogramsToSpeak == 0 then
                    self.data.pictogramsToSpeak = appGetRobotPictogramsToSpeak(self.data.index)
                    self.phase:setNext('speakPictogram', 75)
                    local width = 1010; local height = 353
                    if appGetSpriteCountByType('message', 'robot-speaking') == 0 then
                        app.spritesHandler:createMessageImage('robot-speaking',
                                app.maxXHalf, app.maxY - height / 2, width, height, nil, nil, true, false)
                    end
                end

            elseif self.phase.name == 'waitABitThenSpeakPictogram' then
                if not self.phase:isInited() then
                    if self.data.pictogramsToSpeak ~= nil then
                        self.phase:setNext( 'speakPictogram', 25 + math.random(-5, 5) )
                    end
                end

            elseif self.phase.name == 'speakPictogram' then
                if not self.phase:isInited() then
                    if self.data.pictogramsToSpeak ~= nil and #self.data.pictogramsToSpeak >= 1 then
                        local pictogram = self.data.pictogramsToSpeak[1]
                        appAddPictogramToSpeech(pictogram.pictogramIndex, pictogram.isNegated)
                        appPlaySound('click')
                        table.remove(self.data.pictogramsToSpeak, 1)
                        if #self.data.pictogramsToSpeak == 0 then
                            self.phase:setNext('sayIt', 25)
                        else
                            self.phase:set('waitABitThenSpeakPictogram')
                        end
                    end
                end

            elseif self.phase.name == 'sayIt' then
                if not self.phase:isInited() then
                    appSpeechSayIt()
                    self.data.pictogramsToSpeak = nil
                    local otherSpeaker = misc.getIf(self.data.index == 1, 2, 1)
                    self.phase:set('default')
                    if not app.speakers[otherSpeaker].isRobot then
                        local message = appGetSpriteByType('message', 'robot-speaking')
                        if message ~= nil then message.energySpeed = -5 end
                    end
                end

            end
        end
    end

    local speaker = app.speakers[index]
    local image = 'avatar/' .. index .. '-' .. speaker.gender .. '-' .. misc.getIf(speaker.isRobot, 'robot', 'human')

    local width; local height
    if speaker.gender == 'male' and not speaker.isRobot then width = 141; height = 244
    elseif speaker.gender == 'female' and not speaker.isRobot then width = 146; height = 264
    elseif speaker.gender == 'male' and speaker.isRobot then width = 186; height = 242
    elseif speaker.gender == 'female' and speaker.isRobot then width = 177; height = 256
    end

    local x = 88
    if index == 2 then x = app.maxX - x end

    local subtype = misc.getIf(speaker.isRobot, 'robot', 'human')
    local self = spriteModule.spriteClass('rectangle', 'avatar', subtype, image, false, x, 264, width, height)
    self.data.index = index
    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createCategoryMoreButton(direction)
    local function handle(self)
        if self.action.touchJustBegan then
            if not app.speakers[app.currentSpeaker].isRobot then
                appPlaySound('click')
                appLoadPictogramButtonsOfCategory( misc.getIf(self.subtype == 'left', app.currentCategoryPage - 1, app.currentCategoryPage + 1) )
            end            
        end
    end

    local x = misc.getIf(direction == 'left', 470, 564)
    local y = 727
    local self = spriteModule.spriteClass('rectangle', 'moreButton', direction, 'button/more-' .. direction, false, x, y, 81, 50)
    self.listenToTouch = true
    self:toFront()
    appAddSprite(self, handle, moduleGroup)
end

function self:createTabsLow()
    local function handle(self)
        if self.action.touchJustBegan then
            if not app.speakers[app.currentSpeaker].isRobot then
                appPlaySound('click')
                appSwitchToPictogramCategory(self.subtype)
            end
        end
    end

    local tabY = 424
    for i = 1, #app.tabsX do
        local category = app.pictogramCategories[i]

        local self = spriteModule.spriteClass('rectangle', 'tab', category, nil, false, app.tabsX[i], tabY, 80, 66)
        self.listenToTouch = true
        self.isVisible = false
        -- self:setRgb( 0, math.random(0, 255), 255, 70 )
        self.isHitTestable = true
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createTabHi(category)
    appRemoveSpritesByType('tabHi')

    local i = 0
    for id, thisCategory in pairs(app.pictogramCategories) do
        i = i + 1
        if thisCategory == category then break end
    end

    if i ~= 0 then
        local tabY = 421
        local self = spriteModule.spriteClass('rectangle', 'tabHi', nil, 'tab-hi/' .. category, false, app.tabsX[i], tabY, 114, 66)
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createButton(functionObject, typePrefix, x, y, width, height, optionalParentId)
    local function handle(self)
        if self.action.touchJustBegan then
            if not app.speakers[app.currentSpeaker].isRobot then
                appPlaySound('click')
                self.data.functionObject()
            end
        end
    end

    local self = spriteModule.spriteClass('rectangle', typePrefix .. 'Button', nil, 'button/' .. typePrefix, false, x, y, width, height)
    self.data.functionObject = functionObject
    self.listenToTouch = true
    if optionalParentId ~= nil then self.parentId = optionalParentId end
    appAddSprite(self, handle, moduleGroup)
end

function self:createSpeechBubble(speaker, speechBubbleNumber, spansRowsNumber)
    if speaker ~= nil and speechBubbleNumber ~= nil then
        local verticalPositionNames = {'top', 'middle', 'bottom'}
        local verticalPositionName = verticalPositionNames[speechBubbleNumber]
        local image = 'speech-bubble/' .. verticalPositionName .. '-' .. misc.getIf(speaker == 1, 'left', 'right')
        if spansRowsNumber ~= nil then image = image .. '-spans' .. spansRowsNumber end
        local self = spriteModule.spriteClass('rectangle', 'speechBubble', 'speaker' .. speaker, image, false, app.maxXHalf, 384 / 2, app.maxX, 384)
        self.doDieOutsideField = false
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createLettersOnlyMessage()
    local self = spriteModule.spriteClass('rectangle', 'messageLettersOnly', nil, 'letters-only-message', false, 290, 530, 529, 73)
    local parentId = self.id
    appAddSprite(self, handle, moduleGroup)

    app.spritesHandler:createButton(appKeepUsingPictures, 'keepUsingPictures', 151, 599, 248, 53, parentId)
    app.spritesHandler:createButton(appEnableLetters, 'enableLetters', 424, 598, 265, 56, parentId)
end

function self:createPictogram(index, isNegated, x, y, thisType, optionalScale)
    local function handle(self)
        if self.type == 'pictogramWriting' and self.subtype == 'textCursor' then
            if self.phase.name == 'blinkVisible' then
                if not self.phase:isInited() then self.isVisible = true; self.phase:setNext('blinkInvisible', self.data.blinkSpeed) end
            elseif self.phase.name == 'blinkInvisible' then
                if not self.phase:isInited() then self.isVisible = false; self.phase:setNext('blinkVisible', self.data.blinkSpeed) end
            end

        elseif self.action.touchJustBegan then
            if not app.speakers[app.currentSpeaker].isRobot then
                appPlaySound('click')
                appAddPictogramToSpeech(self.data.index)
            end
        end
    end

    local pictogramType = app.pictogramTypes[index]
    local alternate = ''
    if thisType == 'pictogramWriting' and pictogramType.hasAlternateForWriting then alternate = alternate .. '-alternate-for-writing' end
    local imagePath = 'pictogram/' .. pictogramType.category .. '/' .. pictogramType.name .. alternate .. '.png'
    local self = spriteModule.spriteClass('rectangle', thisType, nil, imagePath, false, x, y, app.pictogramWidth, app.pictogramHeight)
    self.data.index = index
    self.listenToTouch = true

    if index == app.textCursorIndex then
        self.subtype = 'textCursor'
        self.data.blinkSpeed = 25
        self.phase:set('blinkInvisible', self.data.blinkSpeed)
        self.isVisible = false
    end

    if optionalScale ~= nil and optionalScale ~= 1 then self:scale(optionalScale, optionalScale) end

    appAddSprite(self, handle, moduleGroup)

    if isNegated then
        local negator = spriteModule.spriteClass('rectangle', thisType, nil, 'pictogram/special/negation', false, x, y, app.pictogramWidth, app.pictogramHeight)
        if optionalScale ~= nil and optionalScale ~= 1 then negator:scale(optionalScale, optionalScale) end
        appAddSprite(negator, handle, moduleGroup)
    end
end

function self:createMessageImage(imageName, x, y, width, height, shakeSpeedX, shakeSpeedY, doFadeIn, doFadeOut, framesBeforeFadeOut)
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
    
        local self = spriteModule.spriteClass('rectangle', 'message', subtype, 'message-' .. imageName, false, x, y, width, height)
        self:pushIntoAppBorders()
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
        self:toFront()
        appAddSprite(self, handle, moduleGroup)
    end
end

return self
end