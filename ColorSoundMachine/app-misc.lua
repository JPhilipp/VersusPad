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
    app.spritesCount = spritesCount
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
            infos[#infos + 1] = app.framesCounter
            -- infos[#infos + 1] = 'FPS ' .. app.framesCounter
            -- infos[#infos + 1] = 'Spr ' .. app.spritesCount
            -- infos[#infos + 1] = tostring(app.phase.name) .. ' (' .. tostring(app.phase.counter) .. ')'
            -- infos[#infos + 1] = sTime
            -- infos[#infos + 1] =  'd: ' .. app.cubeDropDelay
            -- infos[#infos + 1] = ' | Cherry: ' .. tostring(app.secondsAtWhichToUseSpecial['cherry'])
            -- infos[#infos + 1] = ' | Olive: ' .. tostring(app.secondsAtWhichToUseSpecial['olive'])
            appDebugClock( misc.join(infos, ' | ') )
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
            if desiredId == sprite.id then desiredSprite = sprite; break end
        end
    end
    return desiredSprite
end

function appGetSpriteByTypeAndParentId(desiredType, desiredParentId)
    local desiredSprite = nil
    if desiredType ~= nil and desiredParentId ~= nil then
        for id, sprite in pairs(app.sprites) do
            if desiredType == sprite.type and desiredParentId == sprite.parentId then
                desiredSprite = sprite
                break
            end
        end
    end
    return desiredSprite
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

function appGetSpriteCountByType(type, optionalSubtype, optionalParentPlayer, optionalParentId)
    local count = 0
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.type == type and not sprite.gone then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end
                if ok and optionalParentId ~= nil then ok = sprite.parentId == optionalParentId end
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

function appGetSpriteCountNearby(type, subtype, x, y, maxDistanceToTakeIntoAccount)
    local v = 0
    for id, sprite in pairs(app.sprites) do
        if sprite.type == type and sprite.subtype == subtype and not sprite.gone then
            local distance = misc.getDistance( {x = x, y = y}, {x = sprite.x, y = sprite.y} )
            if math.abs(distance) <= maxDistanceToTakeIntoAccount then v = v + 1 end
        end
    end
    return v
end

function appGetSpritesNearby(type, x, y, maxDistanceToTakeIntoAccount)
    local spritesNearby = {}
    for id, sprite in pairs(app.sprites) do
        if sprite.type == type and not sprite.gone then
            local distance = misc.getDistance( {x = x, y = y}, {x = sprite.x, y = sprite.y} )
            if math.abs(distance) <= maxDistanceToTakeIntoAccount then spritesNearby[#spritesNearby + 1] = sprite end
        end
    end
    return spritesNearby
end

function appGetRectanglesNearby(type, rectangle1, maxDistanceToTakeIntoAccount)
    local spritesNearby = {}
    for id, sprite in pairs(app.sprites) do
        if sprite.type == type and not sprite.gone and not appRectanglesAreFar(rectangle1, sprite, maxDistanceToTakeIntoAccount) then
            spritesNearby[#spritesNearby + 1] = sprite
        end
    end
    return spritesNearby
end

function appRectanglesAreFar(rect1, rect2, distanceNeeded)
    local dBall = math.floor(distanceNeeded)

    local roxA = {}
    roxA.x = rect1.x
    roxA.y = rect1.y
    roxA.dx = math.floor(rect1.width / 2)
    roxA.dy = math.floor(rect1.height / 2)
    roxA.theta = rect1.rotation

    local roxB = {}
    roxB.x = rect2.x
    roxB.y = rect2.y
    roxB.dx = math.floor(rect2.width / 2)
    roxB.dy = math.floor(rect2.height / 2)
    roxB.theta = rect2.rotation

    radiusA = math.sqrt(roxA.dx ^ 2 + roxA.dy ^ 2)
    radiusB = math.sqrt(roxB.dx ^ 2 + roxB.dy ^ 2)
    
    diffABx = roxA.x - roxB.x
    diffABy = roxA.y - roxB.y
    dCtr2Ctr = math.sqrt(diffABx ^ 2 + diffABy ^ 2)
    
    dCircles = dCtr2Ctr - (radiusA + radiusB)
    
    if dCircles > dBall then return true end

    if dCircles > 0 then nonintersectAB = true end

    dBall = dBall ^ 2

    rAth = math.rad(roxA.theta)
    cosA = math.cos(rAth)
    sinA = math.sin(rAth)
    
    tx = roxB.dx - diffABx
    ty = roxB.dy - diffABy
    xBne = cosA * tx + sinA * ty
    yBne = -sinA * tx + cosA * ty
    if dsqr2box(xBne, yBne, roxA.dx, roxA.dy) <= dBall then return false end
    
    tx = -roxB.dx - diffABx
    ty = roxB.dy - diffABy
    xBnw = cosA * tx + sinA * ty
    yBnw = -sinA * tx + cosA * ty
    if dsqr2box(xBnw, yBnw, roxA.dx, roxA.dy) <= dBall then return false end

    tx = -roxB.dx - diffABx
    ty = -roxB.dy - diffABy
    xBsw = cosA * tx + sinA * ty
    yBsw = -sinA * tx + cosA * ty
    if dsqr2box(xBsw, yBsw, roxA.dx, roxA.dy) <= dBall then return false end

    tx = roxB.dx - diffABx
    ty = -roxB.dy - diffABy
    xBse = cosA * tx + sinA * ty
    yBse = -sinA * tx + cosA * ty
    if dsqr2box(xBse, yBse, roxA.dx, roxA.dy) <= dBall then return false end
    
    rBth = math.rad(roxB.theta)
    cosB = math.cos(rBth)
    sinB = math.sin(rBth)
    
    tx = roxA.dx + diffABx
    ty = roxA.dy + diffABy
    xAne = cosB * tx + sinB * ty
    yAne = -sinB * tx + cosB * ty
    if dsqr2box(xAne, yAne, roxB.dx, roxB.dy) <= dBall then return false end
    
    tx = -roxA.dx + diffABx
    ty = roxA.dy + diffABy
    xAnw = cosB * tx + sinB * ty
    yAnw = -sinB * tx + cosB * ty
    if dsqr2box(xAnw, yAnw, roxB.dx, roxB.dy) <= dBall then return false end

    tx = -roxA.dx + diffABx
    ty = -roxA.dy + diffABy
    xAsw = cosB * tx + sinB * ty
    yAsw = -sinB * tx + cosB * ty
    if dsqr2box(xAsw, yAsw, roxB.dx, roxB.dy) <= dBall then return false end

    tx = roxA.dx + diffABx
    ty = -roxA.dy + diffABy
    xAse = cosB * tx + sinB * ty
    yAse = -sinA * tx + cosB * ty
    if dsqr2box(xAse,yAse,roxB.dx,roxB.dy) <= dBall then return false end

    if nonintersectAB then return true end
    if xBne > roxA.dx and xBnw > roxA.dx and xBsw > roxA.dx and xBse > roxA.dx then return true end
    if yBne > roxA.dy and yBnw > roxA.dy and yBsw > roxA.dy and yBse > roxA.dy then return true end
    if xBne < -roxA.dx and xBnw < -roxA.dx and xBsw < -roxA.dx and xBse < -roxA.dx then return true end
    if yBne < -roxA.dy and yBnw < -roxA.dy and yBsw < -roxA.dy and yBse < -roxA.dy then return true end
    if xAne > roxB.dx and xAnw > roxB.dx and xAsw > roxB.dx and xAse > roxB.dx then return true end
    if yAne > roxB.dy and yAnw > roxB.dy and yAsw > roxB.dy and yAse > roxB.dy then return true end
    if xAne < -roxB.dx and xAnw < -roxB.dx and xAsw < -roxB.dx and xAse < -roxB.dx then return true end
    if yAne < -roxB.dy and yAnw < -roxB.dy and yAsw < -roxB.dy and yAse < -roxB.dy then return true end
    
    return false
end

function dsqr2box(tx, ty, dx, dy)
    -- Compute distance squared from point (tx,ty) to an unrotated box centered at origin [-dx,dx] X [-dy,dy]

    tx = math.abs(tx)
    if tx > dx then tx = (tx - dx) ^ 2 else tx = 0 end

    ty = math.abs(ty)
    if ty > dy then ty = (ty - dy) ^ 2 else ty = 0 end

    return tx + ty
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

function appGetSpritesByPhase(phase, optionalType, optionalSubtype)
    local desiredSprites = {}
    if type ~= nil then
        for id, sprite in pairs(app.sprites) do
            if sprite.phase and sprite.phase.name == phase and not sprite.gone then
                local ok = true
                if ok and optionalType ~= nil then ok = sprite.type == optionalType end
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end

                if ok then desiredSprites[#desiredSprites + 1] = sprite end
            end
        end
    end
    return desiredSprites
end

function appGetSpritesByType(typeOrTypesArray, optionalSubtypeOrSubtypesArray, optionalParentPlayer)
    local desiredSprites = {}
    if typeOrTypesArray ~= nil then
        for id, sprite in pairs(app.sprites) do
            if ( sprite.type == typeOrTypesArray or ( type(typeOrTypesArray) == 'table' and misc.inArray(typeOrTypesArray, sprite.type) ) ) and not sprite.gone then
                local ok = true
                if ok and optionalSubtypeOrSubtypesArray ~= nil then ok = sprite.subtype == optionalSubtypeOrSubtypesArray or
                        ( type(optionalSubtypeOrSubtypesArray) == 'table' and misc.inArray(optionalSubtypeOrSubtypesArray, sprite.subtype) ) end
                if ok and optionalParentPlayer ~= nil then ok = sprite.parentPlayer == optionalParentPlayer end

                if ok then desiredSprites[#desiredSprites + 1] = sprite end
            end
        end
    end
    return desiredSprites
end

function appASpriteIsDragged()
    local isIt = false
    for id, sprite in pairs(app.sprites) do
        if sprite.isDragged then
            isIt = true
            break
        end
    end
    return isIt
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
    if app.showDebugInfo then
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

function appMoveSpritesAway(typeOrTypesArray, speedX, speedY, energySpeed)
    if energySpeed == nil then energySpeed = -5 end
    local sprites = appGetSpritesByType(typeOrTypesArray)
    for i = 1, #sprites do
        local sprite = sprites[i]
        sprite.type = 'movingAway'
        sprite.energySpeed = energySpeed
        sprite.speedX = speedX
        sprite.speedY = speedY
        sprite.alphaChangesWithEnergy = true
        sprite.alsoAllowsExtendedNonPhysicalHandling = true
    end
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

    elseif app.isAndroid then
        app.deviceResolution = {width = 1229, height = 768}

    end
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
    local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
    local scaleFactor = math.floor(deviceWidth / display.contentWidth)
    if scaleFactor < 1 then scaleFactor = 1 end
    return scaleFactor
end

function appIncludeLetterboxBars()
    if app.isAndroid then
        local function handle(self) self:toFront() end

        if app.blackbarsOffset == nil then app.blackbarsOffset = 0 end
        if app.backgroundColor == nil then app.backgroundColor = {red = 0, green = 0, blue = 0} end
        appRemoveSpritesByType('letterboxBars')

        if app.maxX > app.maxY then
            local extraMargin = 84
            local width = (app.deviceResolution.width - display.contentWidth) * .5 + extraMargin
    
            for n = 1, 2 do
                local x = misc.getIf(n == 1, app.minX - width / 2 - app.blackbarsOffset + 1, app.maxX + width / 2 + app.blackbarsOffset)
                local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, nil, false, x, app.maxYHalf, width, app.maxY)
                if app.backgroundColor == nil then app.backgroundColor = {red = 0, green = 0, blue = 0} end
                self:setRgbByColorTriple(app.backgroundColor)
                self.doDieOutsideField = false
                appAddSprite(self, handle, nil)
            end

        else
        local extraMargin = 64
            local height = (app.deviceResolution.height - display.contentHeight) * .5 + extraMargin
    
            for n = 1, 2 do
                local y = misc.getIf(n == 1, app.minY - height / 2 - app.blackbarsOffset + 1, app.maxY + height / 2 + app.blackbarsOffset)
                local self = spriteModule.spriteClass('rectangle', 'letterboxBar', nil, nil, false, app.maxXHalf, y, app.maxX, height)
                self:setRgbByColorTriple(app.backgroundColor)
                self.doDieOutsideField = false
                appAddSprite(self, handle, nil)
            end

        end

    end
end
