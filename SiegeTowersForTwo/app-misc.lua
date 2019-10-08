function appHandleAll()
    local spritesCount = 0
    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil then spritesCount = spritesCount + 1 end
        if sprite ~= nil and sprite.energy > 0 and not sprite.gone then
            if app.gameRuns or misc.inArray(app.groupsToHandleEvenWhenGamePaused, sprite.group) then
                sprite:handleGenericBehaviorPre()
                if sprite.handle ~= nil then sprite:handle() end
                sprite:handleGenericBehavior()
            end
        end
    end
    if app.gameRuns and app.phase ~= nil then appHandlePhases() end

    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and (sprite.energy <= 0 or sprite.gone) then
            if app.gameRuns or misc.inArray(app.groupsToHandleEvenWhenGamePaused, sprite.group) then
                if sprite.handleWhenGone ~= nil then sprite:handleWhenGone() end
                if sprite.emphasizeDisappearance then app.spritesHandler:createEmphasizeDisappearanceEffect(sprite.x, sprite.y) end
                app.sprites[id]:removeSelf()
                app.sprites[id] = nil
            end
        end
    end

    app.framesCounter = app.framesCounter + 1
end

function handleClock()
    if app.gameRuns then
        app.secondsCounter = app.secondsCounter + 1
        if app.secondsCounter == 60 then
            app.secondsCounter = 0
            app.minutesCounter = app.minutesCounter + 1
        end
    
        if app.showClock then
            local sTime = misc.padWithZero(app.minutesCounter) .. ':' .. misc.padWithZero(app.secondsCounter)
            if app.framesCounter > app.framesPerSecondGoal then app.framesCounter = app.framesPerSecondGoal end
            local s = ''
            s = s .. 'FPS ' .. app.framesCounter
            s = s .. ' | ' .. tostring(app.phase.name) .. ' (' .. tostring(app.phase.counter) .. ')'
            s = s ..  ' | ' .. sTime
            appDebugClock(s)
            app.framesCounter = 0
        end

    end
    timer.performWithDelay(1000, handleClock)
end

function appGetTimeInSeconds()
    return app.minutesCounter * 60 + app.secondsCounter
end

function appSetText(subtype, text)
    local sprite = appGetSpriteByType('text', subtype)
    if sprite ~= nil then sprite.text = text end
end

function appResetScores()
    for i = 1, app.playerMax do app.score[i] = 0 end
end

function appGetSpriteById(desiredId)
    local desiredSprite = nil
    if desiredId ~= nil then
        for id, sprite in pairs(app.sprites) do
            if desiredId == sprite.id then
                desiredSprite = sprite
                break
            end
        end
    end
    return desiredSprite
end

function appSpritesAreHalting(type, consideredFast)
    local foundFastlyMovingOne = false
    if consideredFast == nil then consideredFast = 2.5 end
    local fastestSpeed = 0
    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and sprite.energy > 0 and not sprite.gone and sprite.type == type then
            local speedX, speedY = sprite:getLinearVelocity()
            if speedX > fastestSpeed then fastestSpeed = speedX end
            if speedY > fastestSpeed then fastestSpeed = speedY end
            if math.abs(speedX) >= consideredFast and math.abs(speedY) >= consideredFast then -- todo: should be vector speed sum...
                foundFastlyMovingOne = true
                break
            end
        end
    end
    -- appDebug('fastestSpeed = ' .. fastestSpeed)
    return not foundFastlyMovingOne
end

function spriteTouchBody(event)
    local sprite = event.target
    if event.phase == 'began' then sprite.action.touched = true
    elseif event.phase == 'ended' then sprite.action.touched = false
    end
    sprite.touchedX = event.x
    sprite.touchedY = event.y

    local continueEventBubbling = true
    return continueEventBubbling
end

function appSetPhaseByType(type, phaseName, optionalParentPlayer, maxCountToChange)
    local countChanged = 0
    if type ~= nil and phaseName ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = true
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end
                if ok then
                    countChanged = countChanged + 1
                    sprite.phase:set(phaseName)

                    if maxCountToChange ~= nil and countChanged > maxCountToChange then break end
                end
            end
        end
    end
end

function appSetToFrontByType(type, optionalSubtype)
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok then sprite:toFront() end
            end
        end
    end
end

function appRemoveSpriteById(desiredId)
    for id, sprite in pairs(app.sprites) do
        if sprite.id == desiredId then sprite.gone = true end
    end
end

function appRemoveSpritesByGroup(group)
    if group ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.group == group then sprite.gone = true end
        end
    end
end

function appRemoveSprites()
    for id, sprite in pairs(app.sprites) do sprite.gone = true end
end

function appPositionSpritesAtOrigin(type)
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type then
                if sprite.originX ~= nil then sprite.x = sprite.originX end
                if sprite.originY ~= nil then sprite.y = sprite.originY end
            end
        end
    end
end

function appRemoveSpritesByType(typeOrTypes, optionalSubtype, optionalParentPlayer, optionalGroup)
    if typeOrTypes ~= nil then
        typeOrTypes = misc.toTable(typeOrTypes)
        for id, sprite in pairs(app.sprites) do
            if misc.inArray(typeOrTypes, sprite.type) then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end
                if ok and optionalGroup ~= nil then ok = sprite.group == optionalGroup end

                if ok then sprite.gone = true end        
            end
        end
    end
end

function appGetSpriteCountByType(type, optionalSubtype, optionalParentPlayer)
    local count = 0
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end
                if ok then count = count + 1 end
            end
        end
    end
    return count
end

function appGetSpriteCountByTypeAndSubtypes(type, subtypes, optionalParentPlayer)
    local count = 0
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = misc.inArray(subtypes, sprite.subtype)
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end
                if ok then count = count + 1 end
            end
        end
    end
    return count
end

function appHasSpriteNearby(type, subtype, parentPlayer, x, y, maxDistanceToTakeIntoAccount)
    local has = false
    for id, sprite in pairs(app.sprites) do
        if sprite.type == type and sprite.subtype == subtype and not sprite.gone then
            if sprite.parentPlayer == parentPlayer or parentPlayer == nil then
                local distance = misc.getDistance( {x = x, y = y}, {x = sprite.x, y = sprite.y} )
                if math.abs(distance) <= maxDistanceToTakeIntoAccount then
                    has = true
                    break
                end
            end
        end
    end
    return has
end

function appGetSpriteByType(type, optionalSubtype, optionalParentPlayer)
    local desiredSprite = nil
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end

                if ok then
                    desiredSprite = sprite
                    break
                end
            end
        end
    end
    return desiredSprite
end

function appGetSpritesByType(typeOrTypesArray, optionalSubtype, optionalParentPlayer)
    local desiredSprites = {}
    if typeOrTypesArray ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == typeOrTypesArray or ( type(typeOrTypesArray) == 'table' and misc.inArray(typeOrTypesArray, sprite.type) ) and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end

                if ok then desiredSprites[#desiredSprites + 1] = sprite end
            end
        end
    end
    return desiredSprites
end

function appPutBackgroundSpritesToBack()
    local sprites = appGetSpritesByType(app.backgroundSpriteTypes)
    for id, sprite in pairs(sprites) do sprite:toBack() end

    local background = appGetSpriteByType('background')
    if background ~= nil then background:toBack() end
end

function getTimeInSeconds()
    return app.minutesCounter * 60 + app.secondsCounter
end

function appDragBody(self, event)
    local phase = event.phase
    local stage = display.getCurrentStage()

    if phase == 'began' then
        self.bodyType = 'dynamic'
        stage:setFocus(self, event.id)
        self.data.isFocus = true
        self.tempJoint = physics.newJoint('touch', self, event.x, event.y)
   
    elseif self.data.isFocus then

        if phase == 'moved' then
            self.tempJoint:setTarget(event.x, event.y)
        elseif phase == 'ended' or phase == 'cancelled' then
            stage:setFocus(self, nil)
            self.tempJoint:removeSelf()
            self.data.isFocus = false
            self.bodyType = 'static'
        end

    end
end

function appPlaySound(soundName)
    if app.doPlaySounds and soundName ~= nil then
        local channelName = '-channel' .. math.random(1, app.sameSoundsPlayedSimultaneously)
        appCacheSound(soundName, channelName)
        audio.play(app.cachedSounds[soundName .. channelName])
    end
end

function appStopAllSounds()
    for channelI = 1, 2 do audio.stop(channelI) end
end

function appCacheImportantSounds()
    if app.doPlaySounds then
        for i, soundName in ipairs(app.importantSoundsToCache) do
            if string.find(soundName, '%.') == nil then soundName = soundName .. '.mp3' end
            soundName = appToPath(soundName)
            app.cachedSounds[soundName] = audio.loadSound(soundName)
        end
    end
end

function appPutBackgroundToBack()
    local background = appGetSpriteByType('background')
    if background ~= nil then background:toBack() end
end

function appCacheSound(soundName, channelName)
    if app.cachedSounds[soundName .. channelName] == nil then
        local soundNameFull = soundName
        if string.find(soundNameFull, '%.') == nil then soundNameFull = soundNameFull .. '.mp3' end
        soundNameFull = appToPath(soundNameFull)
        app.cachedSounds[soundName .. channelName] = audio.loadSound(soundNameFull)
    end
end

function appClearConsole()
    if app.showDebugInfo then
        for i = 1, 100 do print() end
    end
end

function appGetRectangleWithPadding(width, height, padding)
    return {
            math.floor(padding - width / 2), math.floor(padding - height / 2),
            math.floor(width - padding - width / 2), math.floor(padding - height / 2),
            math.floor(width - padding - width / 2), math.floor(height - padding - height / 2),
            math.floor(padding - width / 2), math.floor(height - padding - height / 2)
            }
end

function appGetRectangleWithPaddingAbsolute(width, height, padding)
    return {
            padding, padding,
            width - padding, padding,
            width - padding, height - padding,
            padding, height - padding
            }
end

function appGetRectangleWithPaddingsAbsolute(width, height, paddingLeft, paddingTop, paddingRight, paddingBottom)
    return {
            paddingLeft, paddingTop,
            width - paddingRight, paddingTop,
            width - paddingRight, height - paddingBottom,
            paddingLeft, height - paddingBottom
            }
end

function appDebugAndStop(s)
    appAlert(s)
end


function appAlert(s, showInAnyCase)
    if showInAnyCase == nil then showInAnyCase = false end
    if app.showDebugInfo or showInAnyCase then
        native.showAlert( '', tostring(s), {'OK'} )
    end
end

function appDebug(s, showGuid)
    if app.showDebugInfo then
        if showGuid == nil then showGuid = true end

        local debugSprite = appGetSpriteByType('debugText')
        local sGuid = misc.getIf(showGuid, '    [guid ' .. math.random(10000, 99000) .. ']', '')
        debugSprite.text = tostring(s) .. sGuid
    end
end

function appDebugClock(s)
    if app.showClock then
        local clockSprite = appGetSpriteByType('clockText')
        clockSprite.text = tostring(s)
    end
end

function appPrint(stringOrStringTable, forcePrint)
    if forcePrint == nil then forcePrint = false end

    if app.showDebugInfo or forcePrint then
        local indent = '                                                                  '
        if app.maxX > app.maxY then indent = indent .. '                      ' end

        local stringTable = {}
        if type(stringOrStringTable) == 'table' then
            stringTable = stringOrStringTable
        else
            stringTable = {}
            stringTable[1] = stringOrStringTable
        end

        for i = 1, #stringTable do
            local s = indent .. tostring(stringTable[i])
            if i == 1 then s = s .. '    [' .. math.random(100, 999) .. ']' end
            print(s)
        end
    end
end

function appGetId()
    local s = ''
    local idLength = 16
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    local charsLength = 62 -- i.e. string.len(chars)

    for i = 1, idLength, 1 do
        local r = math.random(1, charsLength)
        s = s .. string.sub(chars, r, r)
    end
    s = 'i' .. s
    return tostring(s)
end

function appCreateBackground(filename)
    if filename == nil then filename = 'background' end
    appRemoveSpritesByType('background')
    if string.find(filename, '%.') == nil then filename = filename .. '.png' end
    local self = spriteModule.spriteClass('rectangle', 'background', nil, filename, false, app.maxX / 2, app.maxY / 2, app.maxX, app.maxY)
    self.alsoAllowsExtendedNonPhysicalHandling = false
    self:toBack()
    appAddSprite(self)

    if app.showDebugInfo then
        local debugSprite = appGetSpriteByType('debugText')
        if debugSprite then debugSprite:toFront() end
    end
end

function appAddSprite(sprite, optionalHandleFunction, optionalGroup, optionalHandleWhenGone)
    sprite:adjustAlpha(100)
    sprite.handle = optionalHandleFunction
    if sprite.group == nil then sprite.group = optionalGroup end
    sprite.handleWhenGone = optionalHandleWhenGone
    app.sprites[sprite.id] = sprite
end

function appAddJoint(joint)
    app.joints[#app.joints + 1] = joint
end

function appAlertLanguageInfo()
    appAlert(
            tostring( system.getPreference('ui', 'language') ) .. ', ' ..
            tostring( system.getPreference('locale', 'country') ) .. ', ' ..
            tostring( system.getPreference('locale', 'identifier') ) .. ', ' ..
            tostring( system.getPreference('locale', 'language') )
            )
    -- on Android Xoom: English, US, en_US, en
    --                  francais, CA, fr_CA, fr
    -- on iPad:         en-us etc., I think, but need to check again
end

function appGetLanguage(supportedLanguages)
    if supportedLanguages == nil then supportedLanguages = {'en'} end
    local neededLength = string.len(supportedLanguages[1])
    local language = nil

    local systemLanguages = { system.getPreference('ui', 'language'), system.getPreference('locale', 'language') }
    -- systemLanguages = {'English', 'en'} -- for tests, behaves as on Android Xoom
    for i = 1, #systemLanguages do
        local thisLanguage = systemLanguages[i]
        if string.len(thisLanguage) > neededLength then thisLanguage = string.sub(thisLanguage, 1, neededLength) end

        if misc.inArray(supportedLanguages, thisLanguage) then
            language = thisLanguage
            break
        end
    end

    if language == nil then language = supportedLanguages[1] end
    return language
end

function appToPath(filename)
    local folder = ''
    local useSpecialMediaPathOnAndroid = false

    if appAdjustPathIfNeeded ~= nil then filename = appAdjustPathIfNeeded(filename) end

    local originalFileName = filename

    if app.translatedImages ~= nil and app.translatedImages[app.language] ~= nil and misc.inArray( app.translatedImages[app.language], string.gsub(filename, '.png', '') ) then
        filename = app.language .. '/' .. filename
    end

    if app.device ~= 'iPad' and app.osIndependentImages ~= nil and misc.inArray( app.osIndependentImages, string.gsub(originalFileName, '.png', '') ) then
        filename = 'os-independent/' .. filename
    end

    if string.find(filename, '.png') ~= nil or string.find(filename, '.jpg') ~= nil then folder = 'image/'
    elseif (app.device == 'iPad' or not useSpecialMediaPathOnAndroid) and ( string.find(filename, '.wav') ~= nil or string.find(filename, '.mp3') ~= nil ) then folder = 'sound/'
    elseif (app.device == 'iPad' or not useSpecialMediaPathOnAndroid) and string.find(filename, '.m4v') ~= nil then folder = 'video/'
    end

    if app.device ~= 'iPad' and useSpecialMediaPathOnAndroid and ( string.find(filename, '.wav') ~= nil or string.find(filename, '.mp3') ~= nil or string.find(filename, '.m4v') ) then
        filename = string.gsub(filename, '%-', '')
    end

    local absolutePath = folder .. filename

    return absolutePath
end

function appSpriteIsInsideOtherSprite(sprite, spriteOther)
    return sprite.x >= spriteOther.x - spriteOther.width / 2 and sprite.x <= spriteOther.x + spriteOther.width / 2
            and sprite.y >= spriteOther.y - spriteOther.height / 2 and sprite.y <= spriteOther.y + spriteOther.height / 2
end

function appPushRandomlySometimes(self, forceMax)
    if forceMax == nil then forceMax = 3 end
    if misc.getChance(10) then
        self:applyLinearImpulse( math.random(-forceMax, forceMax), math.random(-forceMax, forceMax), self.x, self.y )
    end
end

function appCreateDebug(x, y, width, height, fontSize, alpha)
    if app.showClock then
        if x == nil then x = app.maxXHalf end
        if y == nil then y = app.maxY - 60 end
        if width == nil then width = 120 end
        if height == nil then height = 50 end
        if fontSize == nil then fontSize = 16 end
        if alpha == nil then alpha = .55 end

        local self = spriteModule.spriteClass('text', 'debugText', nil, nil, false, x, y, width, height)
        self.size = fontSize
        self:setRgbWhite()
        self.alpha = alpha
        self:setColorBySelf()
        self:toFront()
        appAddSprite(self)
    end
end

function appCreateClock(x, y, width, height, fontSize, alpha)
    if app.showDebugInfo then
        if x == nil then x = app.maxXHalf end
        if y == nil then y = 180 end
        if width == nil then width = app.maxX end
        if height == nil then height = 50 end
        if fontSize == nil then fontSize = 20 end
        if alpha == nil then alpha = 1 end

        local self = spriteModule.spriteClass('text', 'clockText', nil, nil, false, x, y, width, height)
        self.size = fontSize
        self:setRgbWhite()
        self.alpha = alpha
        self:setColorBySelf()
        self:toFront()
        appAddSprite(self)
    end
end

function __genOrderedIndex(t)
    local orderedIndex = {}
    for key in pairs(t) do table.insert(orderedIndex, key) end
    table.sort(orderedIndex)
    return orderedIndex
end

function orderedNext(t, state)
    if state == nil then
        t.__orderedIndex = __genOrderedIndex(t)
        key = t.__orderedIndex[1]
        return key, t[key]
    end

    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then return key, t[key] end
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    return orderedNext, t, nil
end

function appGetImageWhichFillsScreen(imageName)
    local desiredImage = nil
    local newImageName = nil
    if imageName ~= nil and app.imagesWhichFillScreen ~= nil then
        imageName = string.gsub(imageName, '%.png', '')
        imageName = string.gsub(imageName, '%.jpg', '')
        for i = 1, #app.imagesWhichFillScreen do
            local thisImage = app.imagesWhichFillScreen[i]
            if thisImage.imageName == imageName and
                    thisImage.width == app.deviceResolution.width and thisImage.height == app.deviceResolution.height then
                newImageName = thisImage.imageName .. '@' .. thisImage.width .. 'x' .. thisImage.height
                if string.find(newImageName, '%.') == nil then newImageName = newImageName .. '.png' end
                desiredImage = thisImage
                break
            end
        end
    end
    return desiredImage, newImageName
end

function appSpritesHandleByType(type, subtype)
    local sprites = appGetSpritesByType(type, subtype)
    for i = 1, #sprites do
        local sprite = sprites[i]
        if sprite.handle ~= nil then sprite:handle() end
    end
end

function appPrintDeviceInfo()
    appPrint( 'Resolution = ' .. display.contentWidth .. ' x ' .. display.contentHeight .. ' ' ..
            '(Scale = ' .. display.contentScaleX .. ',' .. display.contentScaleY .. ') - ' .. app.device .. ' - ' ..
            'DeviceResolution = ' .. tostring(app.deviceResolution.width) .. 'x' .. tostring(app.deviceResolution.height) )
end

function appSetDeviceResolution()
    if app.device == 'iPad' then
        app.deviceResolution = {width = 1024, height = 768}
        if appGetIsRetinaPad() then
            app.deviceResolution.width = app.deviceResolution.width * 2
            app.deviceResolution.height = app.deviceResolution.height * 2
        end

    else -- begin Android guess work
        app.deviceResolution = {width = 1229, height = 768}

    end
    -- appAlert(app.deviceResolution.width .. 'x' .. app.deviceResolution.height)
end

function appGetIsRetinaPad()
    local isIt = false
    local info = system.getInfo('architectureInfo') -- e.g. 'iPad3,1'
    if info ~= nil and info ~= '' then
        info = info:lower()
        local isPlain = true
        isIt = not ( info:find('ipad1', 1, isPlain) == 1 or info:find('ipad2', 1, isPlain) == 1 )
    end
    return isIt
end

function appGetScaleFactor()
    --[[
    local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
    local scaleFactor = math.floor(deviceWidth / display.contentWidth)
    if scaleFactor < 1 then scaleFactor = 1 end
    return scaleFactor
    --]]
    return 1
end

function appIncludeLetterboxBars()
    if app.device ~= 'iPad' then

        local function handle(self)
            self:toFront()
        end

        appRemoveSpritesByType('letterboxBars')
        local extraMargin = 70
        local width = (app.deviceResolution.width - display.contentWidth) * .5 + extraMargin

        for n = 1, 2 do
            local x = misc.getIf(n == 1, app.minX - width / 2, app.maxX + width / 2)
            local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, nil, false, x, app.maxYHalf, width, app.maxY)
            self:setRgbBlack()
            self.doDieOutsideField = false
            appAddSprite(self, handle, nil)
        end
    end
end

function appSetFont(fontNames, fontNameAndroid)
    if app.isAndroid and fontNameAndroid ~= nil then
        app.defaultFont = fontNameAndroid
    else
        fontNames = misc.toTable(fontNames)
        app.defaultFont = nil
    
        if fontNames ~= nil then
            local availableFontNames = native.getFontNames()
            for i = 1, #fontNames do
                if misc.inArray(availableFontNames, fontNames[i]) then
                    app.defaultFont = fontNames[i]
                    break
                end
            end
        end
    end

    if app.defaultFont == nil then app.defaultFont = native.systemFontBold end
end

function appMiscShowFonts()
    local function handle(self)
        appPrint(1)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPrint(2)
            appMiscShowFonts()
        end
    end

    if app.fontsPage == nil then app.fontsPage = 0 end
    app.fontsPage = app.fontsPage + 1

    appRemoveSprites()
    appHandleAll()
    app.gameOver = true

    local fontNames = native.getFontNames()
    fontNames = appFilterArrayBySearch(fontNames, 'Lil')

    local perPage = 15
    local min = (app.fontsPage - 1) * perPage
    local max = min + perPage
    y = 0
    for i = 1, #fontNames do
        if i >= min and i <= max + 1 then
            y = y + 1
            local self = spriteModule.spriteClass('text', 'fontName', nil, nil, false, app.maxXHalf, 5 + y * 14)
            self:setFontSize(15)
            if i < max + 1 then
                self.text = '"' .. fontNames[i] .. '"'
            else
                self.text = '-- NEXT -->'
                self.listenToTouch = true
            end
            self:setRgbBlack()
            appAddSprite(self, handle, 'menu')
        end
    end
end

function appFilterArrayBySearch(array, query)
    local filteredArray = nil
    if array ~= nil and type(array) == 'table' then
        filteredArray = {}
        for i = 1, #array do
            if string.find(array[i], query) ~= nil then
                filteredArray[#filteredArray + 1] = array[i]
            end
        end
    end
    return filteredArray
end

function appGetSpriteByParentId(desiredParentId)
    local desiredSprite = nil
    if desiredParentId ~= nil then
        for id, sprite in pairs(app.sprites) do
            if desiredParentId == sprite.parentId then desiredSprite = sprite; break end
        end
    end
    return desiredSprite
end

function appGetChild(parentId)
    local desiredSprite = nil
    if parentId ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.parentId == parentId then
                desiredSprite = sprite
                break
            end
        end
    end
    return desiredSprite
end
