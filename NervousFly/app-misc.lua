function appHandleAll()
    local spritesCount = 0
    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil then spritesCount = spritesCount + 1 end
        if sprite ~= nil and sprite.energy > 0 and not sprite.gone then
            if app.runs or misc.inArray(app.groupsToHandleEvenWhenPaused, sprite.group) then
                sprite:handleGenericBehaviorPre()
                if sprite.handle ~= nil then sprite:handle() end
                sprite:handleGenericBehavior()
            end
        end
    end
    if app.runs and app.phase ~= nil then appHandlePhases() end

    appHandleRemovals()

    if app.recentlyPlayedSounds ~= nil and #app.recentlyPlayedSounds > 0 and misc.getChance(30) then
        table.remove(app.recentlyPlayedSounds, 1)
    end

    app.framesCounter = app.framesCounter + 1
end

function appHandleRemovals()
    local indexNonGroup = 1
    local indexGroup = 2
    for iDisplayType = indexNonGroup, indexGroup do

        for id, sprite in pairs(app.sprites) do
            if sprite ~= nil and ( sprite.energy <= 0 or sprite.gone ) then
                local displayTypeOk = (sprite.displayType ~= 'group' and iDisplayType == indexNonGroup) or
                        (sprite.displayType == 'group' and iDisplayType == indexGroup)
                if displayTypeOk then
                    if app.runs or misc.inArray(app.groupsToHandleEvenWhenPaused, sprite.group) then
                        if sprite.handleWhenGone ~= nil then sprite:handleWhenGone() end
                        if sprite.emphasizeDisappearance then app.spritesHandler:createEmphasizeDisappearanceEffect(sprite.x, sprite.y) end
                        if app.sprites[id].removeSelf then app.sprites[id]:removeSelf() end
                        app.sprites[id] = nil
                    end
                end
            end
        end

    end
end

function appGetImageWhichFillsScreen(imageName)
    local desiredImage = nil
    local newImageName = nil
    if imageName ~= nil then
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

function appSetFont(fontNames)
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
    if app.defaultFont == nil then app.defaultFont = native.systemFontBold end
end

function appMiscShowFonts()
    if app.fontsPage == nil then app.fontsPage = 0 end
    app.fontsPage = app.fontsPage + 1

    appRemoveSpritesByType( {'background', 'fly', 'cube', 'message', 'fontName'} )
    app.gameOver = true

    local fontNames = native.getFontNames()
    fontNames = misc.filterArrayBySearch(fontNames, 'Marker')

    local perPage = 25
    local min = (app.fontsPage - 1) * perPage
    y = 0
    for i = 1, #fontNames do
        if i >= min and i <= min + perPage then
            y = y + 1
            local self = spriteModule.spriteClass('text', 'fontName', nil, nil, false, app.maxXHalf, 38 + y * 14)
            self.text = '"' .. fontNames[i] .. '"'
            self.size = 12
            appAddSprite(self)
        end
    end
end

function appOpenDatabase(databaseName)
    if databaseName == nil then databaseName = 'userData' end
    local path = system.pathForFile( misc.toName(databaseName) .. '.db', system.DocumentsDirectory )
    app.db = sqlite3.open(path)
end

function appDbGetLastId()
    local v = nil
    for row in app.db:nrows( 'SELECT last_insert_rowid() as lastId' ) do
        v = row.lastId
        break
    end
    return v
end

function appPrintTable(tableName)
    local separator = ' | '
    local didPrintHeader = false
    appPrint('__________ table ' .. tostring(tableName) .. ' __________', false, false, false)
    for row in app.db:nrows( 'SELECT * FROM ' .. misc.toQuery(tableName) ) do
        if not didPrintHeader then
            local sHeader = ''
            for k, v in orderedPairs(row) do
                if sHeader ~= '' then sHeader = sHeader .. separator end
                sHeader = sHeader .. tostring(k)
            end
            appPrint(sHeader, false, false, false)
            didPrintHeader = true
        end

        local s = ''
        for k, v in orderedPairs(row) do
            if s ~= '' then s = s .. separator end
            s = s .. tostring(v)
        end
        appPrint(s, false, false, false)
    end
end

function appGetDbCount(tableName)
    local v = 0
    local query = 'SELECT count(*) AS thisCount FROM ' .. misc.toName(tableName)
    for row in app.db:nrows(query) do
        v = row.thisCount
        break
    end
    return v
end

function handleClock()
    if app.runs then
        app.secondsCounter = app.secondsCounter + 1
        if app.secondsCounter == 60 then
            app.secondsCounter = 0
            app.minutesCounter = app.minutesCounter + 1
        end

        if app.showClock then
            local sTime = misc.padWithZero(app.minutesCounter) .. ':' .. misc.padWithZero(app.secondsCounter)
            if app.framesCounter > app.framesPerSecondGoal then app.framesCounter = app.framesPerSecondGoal end
            local infos = {}
            infos[#infos + 1] = 'FPS ' .. app.framesCounter
            -- infos[#infos + 1] = tostring(app.phase.name) .. ' (' .. tostring(app.phase.counter) .. ')'
            infos[#infos + 1] = sTime
            -- infos[#infos + 1] =  'd: ' .. app.cubeDropDelay
            -- infos[#infos + 1] = ' | Cherry: ' .. tostring(app.secondsAtWhichToUseSpecial['cherry'])
            -- infos[#infos + 1] = ' | Olive: ' .. tostring(app.secondsAtWhichToUseSpecial['olive'])
            -- appDebugClock( misc.join(infos, ' | ') )
            app.framesCounter = 0
        end

        if appHandleTimedEvents then appHandleTimedEvents() end

    end
    timer.performWithDelay(1000, handleClock)
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
    if event.phase == 'began' then
        sprite.action.touched = true
        sprite.action.touchJustBegan = true
        sprite.action.touchJustEnded = false
        display.getCurrentStage():setFocus(sprite)
    elseif event.phase == 'ended' then
        sprite.action.touched = false
        sprite.action.touchJustBegan = false
        sprite.action.touchJustEnded = true
        display.getCurrentStage():setFocus(nil)
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
    for id, sprite in pairs(app.sprites) do
        if sprite.group == group then sprite.gone = true end
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

function appGetSpriteByType(type, optionalSubtype, optionalParentPlayer, evenWhenGone)
    local desiredSprite = nil
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and (not sprite.gone or evenWhenGone) then
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
            if ( sprite.type == typeOrTypesArray or ( type(typeOrTypesArray) == 'table' and misc.inArray(typeOrTypesArray, sprite.type) ) ) and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end

                if ok then desiredSprites[#desiredSprites + 1] = sprite end
            end
        end
    end
    return desiredSprites
end

function appGetSpriteByType(typeOrTypesArray, optionalSubtype)
    local desiredSprite = nil
    if typeOrTypesArray ~= nil then
        for id, sprite in pairs(app.sprites) do
            if ( sprite.type == typeOrTypesArray or ( type(typeOrTypesArray) == 'table' and misc.inArray(typeOrTypesArray, sprite.type) ) ) and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and desiredSprite == nil then
                    desiredSprite = sprite
                    break
                end
            end
        end
    end
    return desiredSprite
end

function appPutBackgroundSpritesToBack()
    local sprites = appGetSpritesByType(app.backgroundSpriteTypes)
    for id, sprite in pairs(sprites) do sprite:toBack() end

    local background = appGetSpriteByType('background')
    if background ~= nil then background:toBack() end
end

function getTimeInSeconds()
    -- hmm, twice?
    return appGetTimeInSeconds()
end

function appGetTimeInSeconds()
    local v = nil
    if app.minutesCounter ~= nil and app.secondsCounter ~= nil then
        v = app.minutesCounter * 60 + app.secondsCounter
    end
    return v
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

function appPlaySound(soundName, optionalChannel, optionalDoLoop, optionalOnCompleteFunction, optionalPlayAsStream)
    if app.doPlaySounds and soundName ~= nil then
        if not misc.inArray(app.recentlyPlayedSounds, soundName) then
            app.recentlyPlayedSounds[#app.recentlyPlayedSounds + 1] = soundName

            if string.find(soundName, '%.') == nil then soundName = soundName .. '.mp3' end
            soundName = appToPath(soundName)
            local params = {}
            if optionalChannel ~= nil then params.channel = optionalChannel end
            if optionalDoLoop ~= nil and optionalDoLoop then params.loops = -1 end
            if optionalOnCompleteFunction ~= nil then params.onComplete = optionalOnCompleteFunction end
            if optionalPlayAsStream == nil then optionalPlayAsStream = false end
    
            local soundHandle = nil
            if app.cachedSounds[soundName] ~= nil then soundHandle = app.cachedSounds[soundName]
            elseif optionalPlayAsStream then soundHandle = audio.loadStream(soundName)
            else soundHandle = audio.loadSound(soundName)
            end
    
            audio.play(soundHandle, params)
        end
    end
end

function appInitSound()
    if app.doPlaySounds then
        audio.reserveChannels(app.musicChannel)
        appCacheImportantSounds()
    end
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

function appCacheSound(soundName)
    if app.doPlaySounds then
        if string.find(soundName, '%.') == nil then soundName = soundName .. '.mp3' end
        soundName = appToPath(soundName)
        app.cachedSounds[soundName] = audio.loadSound(soundName)
    end
end

function appStopAllSounds()
    audio.stop()
end

function appPutBackgroundToBack()
    local background = appGetSpriteByType('background')
    if background ~= nil then background:toBack() end
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

function appDebugAndStop(s)
    appAlert(s)
end

function appAlert(s)
    if app.showDebugInfo then
        native.showAlert( 'Alert', tostring(s), {'OK'} )
    end
end

function appDebug(s, showGuid)
    if app.showDebugInfo then
        if showGuid == nil then showGuid = true end

        local debugSprite = appGetSpriteByType('debugText')
        if debugSprite ~= nil then
            local sGuid = misc.getIf(showGuid, '    [guid ' .. math.random(10000, 99000) .. ']', '')
            debugSprite.text = tostring(s) .. sGuid
            debugSprite:toFront()
        end
    end
end

function appDebugClock(s)
    if app.showClock then
        local clockSprite = appGetSpriteByType('clockText')
        if clockSprite ~= nil then
            clockSprite.text = tostring(s)
            clockSprite:toFront()
        end
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

function appPrint(stringOrStringTable, forcePrint, doIndent, showGuid)
    if forcePrint == nil then forcePrint = false end
    if doIndent == nil then doIndent = false end -- true
    if showGuid == nil then showGuid = true end

    if app.showDebugInfo or forcePrint then
        local indent = ''
        if doIndent then
            indent = '                                                             '
            if app.maxX > app.maxY then indent = indent .. '                      ' end
        end

        local stringTable = {}
        if type(stringOrStringTable) == 'table' then
            stringTable = stringOrStringTable
        else
            stringTable = {}
            stringTable[1] = stringOrStringTable
        end

        for i = 1, #stringTable do
            local s = indent .. tostring(stringTable[i])
            if i == 1 and showGuid then s = s .. '    [' .. math.random(100, 999) .. ']' end
            print(s)
        end
    end
end

function appGetId(idLength)
    local s = ''
    if idLength == nil then idLength = 16 end

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

    if appAdjustPathIfNeeded ~= nil then filename = appAdjustPathIfNeeded(filename) end

    if appGetTranslatedImage(filename) ~= nil then
        filename = app.language .. '/' .. filename
    end

    if string.find(filename, '.png') ~= nil or string.find(filename, '.jpg') ~= nil then folder = 'image/'
    elseif string.find(filename, '.wav') ~= nil or string.find(filename, '.mp3') ~= nil or string.find(filename, '.m4a') ~= nil then folder = 'sound/'
    end
    local absolutePath = folder .. filename
    return absolutePath
end

function appGetTranslatedImage(filename)
    local translatedImage = nil
    if filename ~= nil and app.translatedImages ~= nil and app.translatedImages[app.language] ~= nil then
        for i = 1, #app.translatedImages[app.language] do
            local thisFilename = app.translatedImages[app.language][i].filename
            if string.gsub(thisFilename, '.png', '') == string.gsub(filename, '.png', '') then
                translatedImage = app.translatedImages[app.language][i]
                break
            end
        end
    end
    return translatedImage
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

function appShowAvailableFonts(optionalSearch)
    local fonts = native.getFontNames()
    for i, font in ipairs(fonts) do
        local ok = true
        if optionalSearch ~= nil then ok = string.find(font, optionalSearch) ~= nil end
        if ok then appPrint(font, nil, false, false) end
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
