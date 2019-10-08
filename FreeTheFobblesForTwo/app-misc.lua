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

function spriteTouchBody(event)
    local sprite = event.target
    if event.phase == 'began' then sprite.action.touched = true
    elseif event.phase == 'ended' then sprite.action.touched = false
    end
    sprite.touchedX = event.x
    sprite.touchedY = event.y

    local cancelEventBubbling = false
    return not cancelEventBubbling
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

function appRemoveSpritesByType(type, optionalSubtype, optionalParentPlayer, optionalGroup)
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type then
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

function spriteTouchBody(event)
    local sprite = event.target
    if event.phase == 'began' then sprite.action.touched = true
    elseif event.phase == 'ended' then sprite.action.touched = false
    end
    sprite.touchedX = event.x
    sprite.touchedY = event.y

    return true
end

function appPlaySound(soundName)
    if app.doPlaySounds and soundName ~= nil then
        local channelName = '-channel' .. math.random(1, app.sameSoundsPlayedSimultaneously)
        appCacheSound(soundName, channelName)
        audio.play(app.cachedSounds[soundName .. channelName])
    end
end

function appStopAllSounds()
    for channelI = 1, 2 do  audio.stop('-channel' .. channelI) end
end

function appCacheImportantSounds()
    if app.doPlaySounds then
        for i, sound in ipairs(app.importantSoundsToCache) do
            for channelI = 1, 2 do appCacheSound(sound, '-channel' .. channelI) end
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

function appPrint(stringOrStringTable, forcePrint)
    if forcePrint == nil then forcePrint = false end
    if app.showDebugInfo or forcePrint then
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
            -- if i == 1 then s = s .. '    [' .. math.random(100, 999) .. ']' end
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

function appGetLanguage()
    local language = system.getPreference('ui', 'language') -- e.g.zh-Hans -> zh
    local abbreviationLength = 2
    if string.len(language) >= abbreviationLength then
        language = string.sub(language, 1, abbreviationLength)
    end
    return language
end

function appToPath(filename)
    local folder = ''

    if app.translatedImages ~= nil and app.translatedImages[app.language] ~= nil and misc.inArray( app.translatedImages[app.language], string.gsub(filename, '.png', '') ) then
        filename = app.language .. '/' .. filename
    end

    if string.find(filename, '.png') ~= nil or string.find(filename, '.jpg') ~= nil then folder = 'image/'
    elseif string.find(filename, '.wav') ~= nil or string.find(filename, '.mp3') ~= nil then folder = 'sound/'
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
        if fontSize == nil then fontSize = 16 end
        if alpha == nil then alpha = .55 end

        local self = spriteModule.spriteClass('text', 'clockText', nil, nil, false, x, y, width, height)
        self.size = fontSize
        self:setRgbWhite()
        self.alpha = alpha
        self:setColorBySelf()
        appAddSprite(self)
    end
end

function appCreateClock(x, y, width, height, fontSize, alpha)
    if app.showDebugInfo then
        if x == nil then x = app.maxXHalf end
        if y == nil then y = 180 end
        if fontSize == nil then fontSize = 20 end
        if alpha == nil then alpha = 1 end

        local self = spriteModule.spriteClass('text', 'debugText', nil, nil, false, x, y, width, height)
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

function appSetDeviceResolution()
    if app.device == 'iPad' then
        app.deviceResolution = {width = 1024, height = 768}
        if appGetIsRetinaPad() then
            app.deviceResolution.width = app.deviceResolution.width * 2
            app.deviceResolution.height = app.deviceResolution.height * 2
        end

    elseif app.isAndroid then
        app.deviceResolution = {width = 1229, height = 768}

    end
end

function appGetScaleFactor()
    local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
    local scaleFactor = math.floor(deviceWidth / display.contentWidth)
    if scaleFactor < 1 then scaleFactor = 1 end
    return scaleFactor
end

function appIncludeLetterboxBars(alwaysInFront)
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
            local width = appGetLetterboxWidth()     
            for n = 1, 2 do
                local x = misc.getIf(n == 1, app.minX - width / 2 - letterboxOffset + 1, app.maxX + width / 2 + letterboxOffset)
                local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, nil, false, x, app.maxYHalf, width, app.maxY)
                self:setRgbByColorTriple(app.letterboxColor[n])
                self.doDieOutsideField = false
                self.data.alwaysInFront = alwaysInFront
                appAddSprite(self, handle, nil)
            end

        else
            local height = appGetLetterboxHeight() 
            for n = 1, 2 do
                local y = misc.getIf(n == 1, app.minY - height / 2 - letterboxOffset + 1, app.maxY + height / 2 + letterboxOffset)
                local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, nil, false, app.maxXHalf, y, app.maxX, height)
                self:setRgbByColorTriple(app.letterboxColor[n])
                self.doDieOutsideField = false
                self.data.alwaysInFront = alwaysInFront
                appAddSprite(self, handle, nil)
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
