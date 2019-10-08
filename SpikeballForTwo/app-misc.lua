function appHandleAll()
    -- local spritesCount = 0
    for id, sprite in pairs(app.sprites) do
        -- if sprite ~= nil then spritesCount = spritesCount + 1 end
        if sprite ~= nil and sprite.energy > 0 and not sprite.gone then
            if app.gameRuns or misc.inArray(app.groupsToHandleEvenWhenGamePaused, sprite.group) then
                sprite:handleGenericBehaviorPre()
                if sprite.handle ~= nil then sprite:handle() end
                sprite:handleGenericBehavior()
            end
        end
    end

    if app.gameRuns then app.extra:handle() end

    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and ( sprite.energy <= 0 or sprite.gone ) then
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

function __genOrderedIndex( t )
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

function appGetIsRetina()
    local isIt = true
    local info = system.getInfo('architectureInfo') -- e.g. 'iPad3,1'
    if info ~= nil and info ~= '' then
        info = info:lower()
        local isPlain = true
        isIt = not ( info:find('ipad1', 1, isPlain) == 1 or info:find('ipad2', 1, isPlain) == 1 )
    end
    return isIt
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
            -- s = s .. 'FPS: ' end
            s = s .. app.framesCounter -- .. ' / ' .. app.framesPerSecondGoal
            s = s ..  ' | ' .. sTime
            appDebugClock(s)
            app.framesCounter = 0
        end
    
        if not app.thereWasLongTimeWithoutGoal then
            local timeWithoutGoal = appGetTimeInSeconds()
            if app.timeOfLastGoal ~= nil then timeWithoutGoal = appGetTimeInSeconds() - app.timeOfLastGoal end
            if timeWithoutGoal > 100 then app.thereWasLongTimeWithoutGoal = true end
        end
    end

    timer.performWithDelay(1000, handleClock)
end

function appGetTimeInSeconds()
    return app.minutesCounter * 60 + app.secondsCounter
end

function spriteTouchBody(event)
    local sprite = event.target
    if event.phase == 'began' then
        sprite.action.touched = true
    elseif event.phase == 'ended' then
        sprite.action.touched = false
    end
    sprite.touchedX = event.x
    sprite.touchedY = event.y
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

function appRemoveSpritesByGroup(group)
    if group ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.group == group then sprite.gone = true end
        end
    end
end

function appRemoveSpritesByType(type, optionalGroup, optionalParentPlayer)
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type then
                local ok = true
                if ok and optionalGroup ~= nil then ok = sprite.group == optionalGroup end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end
    
                if ok then sprite.gone = true end        
            end
        end
    end
end

function appGetSpriteCountByType(type, optionalSubtype)
    local count = 0
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok then count = count + 1 end
            end
        end
    end
    return count
end

function appHasSpriteNearby(type, x, y, maxDistance)
    local has = false
    for id, sprite in pairs(app.sprites) do
        if sprite.type == type and not sprite.gone then
            local distance = misc.getDistance( {x = x, y = y}, {x = sprite.x, y = sprite.y} )
            if math.abs(distance) <= maxDistance then has = true; break end
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

function appPlaySound(soundName)
    if app.doPlaySounds and soundName ~= nil then
        local channelName = '-channel' .. math.random(1, app.sameSoundsPlayedSimultaneously)
        appCacheSound(soundName, channelName)
        audio.play(app.cachedSounds[soundName .. channelName])
    end
end

function appCacheAllImportantSounds()
    if app.doPlaySounds then
        local importantSounds = {'countdown-beat', 'wall-collision', 'ball-collision', 'goal.mp3', 'poisoned', 'intro.mp3', 'start-extra.mp3', 'end-extra.mp3', 'collect-item.mp3', 'winner.mp3'}
        for i, sound in ipairs(importantSounds) do
            for channelI = 1, 2 do
                appCacheSound(sound, '-channel' .. channelI)
            end
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
        if string.find(soundNameFull, '%.') == nil then soundNameFull = soundNameFull .. '.wav' end
        soundNameFull = appToPath(soundNameFull)
        app.cachedSounds[soundName .. channelName] = audio.loadSound(soundNameFull)
    end
end

function appClearConsole()
    if app.showDebugInfo then
        for i = 1, 100 do
            print()
        end
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

function appDebugAndStop(s)
    appAlert(s)
end

function appAlert(s)
    if app.showDebugInfo then
        native.showAlert( 'Alert', tostring(s), {'OK'} )
    end
end

function appDebug(s)
    if app.showDebugInfo then
        local debugSprite = appGetSpriteByType('debugText')
        local sGuid = '    [guid ' .. math.random(10000, 99000) .. ']'
        debugSprite.text = tostring(s) .. sGuid
    end
end

function appDebugClock(s)
    if app.showClock then
        local clockSprite = appGetSpriteByType('clockText')
        clockSprite.text = tostring(s)
    end
end

function appPrint(stringOrStringTable)
    if app.showDebugInfo then
        local indent = ''

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

function appAddJoint(joint)
    app.joints[#app.joints + 1] = joint
end

function appToPath(filename)
    local folder = ''
    if string.find(filename, '.png') ~= nil or string.find(filename, '.jpg') ~= nil then
        folder = 'image/'
    elseif string.find(filename, '.wav') ~= nil or string.find(filename, '.mp3') ~= nil then
        folder = 'sound/'
    end

    local absolutePath = folder .. filename
    -- if not app.isLocalTest then absolutePath = system.pathForFile(absolutePath) end

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

function appAddSprite(sprite, optionalHandleFunction, optionalGroup, optionalHandleWhenGone)
    sprite:adjustAlpha(100)
    sprite.handle = optionalHandleFunction
    if sprite.group == nil then sprite.group = optionalGroup end
    sprite.handleWhenGone = optionalHandleWhenGone
    app.sprites[sprite.id] = sprite
end

function appGetDensityValue(self)
    local v = 100
    -- if self.type == 'wheel' then v = 500 end
    return v
end

function appGetBounceValue(self)
    local v = .5
    -- if self.type == 'wheel' then v = .75 end
    return v
end

function appGetLanguage(supportedLanguages)
    if supportedLanguages == nil then supportedLanguages = {'en'} end
    local neededLength = string.len(supportedLanguages[1])
    local language = nil

    local systemLanguages = { system.getPreference('ui', 'language'), system.getPreference('locale', 'language') }
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

function appGetDeviceResolution(isPortrait)
    if isPortrait == nil then isPortrait = true end
    local deviceResolution = { width = nil, height = nil }
    if app.device == 'iPad' then
        deviceResolution = {width = 768, height = 1024}
        if not isPortrait then deviceResolution = {width = deviceResolution.height, height = deviceResolution.width} end
        if appGetIsRetinaPad() then
            deviceResolution.width = deviceResolution.width * 2
            deviceResolution.height = deviceResolution.height * 2
        end

    elseif app.isAndroid then
        deviceResolution = {width = 768, height = 1229} -- i.e. 800x1280
        if not isPortrait then deviceResolution = {width = deviceResolution.height, height = deviceResolution.width} end
    end
    return deviceResolution
end

function appGetScaleFactor()
    local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
    local scaleFactor = math.floor(deviceWidth / display.contentWidth)
    if scaleFactor < 1 then scaleFactor = 1 end
    return scaleFactor
end

function appIncludeLetterboxBars(alwaysInFront, useImagesOfThisSize)
    if app.isAndroid then

        local function handle(self)
            if self.data.alwaysInFront then self:toFront()
            else self:toBack()
            end
        end

        if alwaysInFront == nil then alwaysInFront = true end
        if letterboxOffset == nil then letterboxOffset = 0 end
        local black = {red = 0, green = 0, blue = 0}
        if app.letterboxColor == nil then app.letterboxColor = {black, black} end
        if app.letterboxColor[2] == nil then app.letterboxColor[2] = app.letterboxColor[1] end
        appRemoveSpritesByType('letterboxBars')

        if app.maxX > app.maxY then
            for n = 1, 2 do
                local width = nil; local image = nil
                if useImagesOfThisSize == nil then width = appGetLetterboxWidth()
                else width = useImagesOfThisSize; image = 'letterbox-' .. n
                end

                local x = misc.getIf(n == 1, app.minX - width / 2 - letterboxOffset + 1, app.maxX + width / 2 + letterboxOffset)
                local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, image, false, x, app.maxYHalf, width, app.maxY)
                if image == nil then self:setRgbByColorTriple(app.letterboxColor[n]); self:setFillColorBySelf() end
                self.doDieOutsideField = false
                self.data.alwaysInFront = alwaysInFront
                appAddSprite(self, handle)
            end

        else
            for n = 1, 2 do
                local height = nil; local image = nil
                if useImagesOfThisSize == nil then height = appGetLetterboxHeight()
                else height = useImagesOfThisSize; image = 'letterbox-' .. n
                end

                local y = misc.getIf(n == 1, app.minY - height / 2 - letterboxOffset + 1, app.maxY + height / 2 + letterboxOffset)
                local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, image, false, app.maxXHalf, y, app.maxX, height)
                if image == nil then self:setRgbByColorTriple(app.letterboxColor[n]); self:setFillColorBySelf() end
                self.doDieOutsideField = false
                self.data.alwaysInFront = alwaysInFront
                appAddSprite(self, handle)
            end

        end

    end
end

function appGetLetterboxWidth()
    local extraMargin = 84
    return (app.deviceResolution.width - display.contentWidth) * .5 + extraMargin
end

function appGetLetterboxHeight()
    local extraMargin = 64
    return math.abs(app.deviceResolution.height - display.contentHeight) * .5 + extraMargin
end

function appToPackageName(s)
    local abc = {'a','b','c','d','e','f', 'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
    return misc.toName(s, abc)
end
