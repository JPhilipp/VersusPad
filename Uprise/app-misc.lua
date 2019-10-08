function appInitDefaults(includePhysics, physicsScale, gravity)
    misc.initDefaults(includePhysics)
    appClass()

    physics.setScale(physicsScale)
    physics.setGravity(0, gravity)

    appClearConsole()
    appDefineTranslatedImages()
    appInitSounds()
    app.data:open()

    appLoadData()
    appInitPurchases()
    appSetAlignmentRectangle()
    appSetMinimumViewableRectangle()
    -- app.news:verifyNeededFunctionsAndVariablesExists()
    appSetValuesToDefault()
    appStart()

    Runtime:addEventListener('enterFrame', appHandleAll)
    timer.performWithDelay(app.secondInMs, handleClock)

    app.news:handle()
end

function appPause()
    if app.runs then
        system.setIdleTimer(true)
        physics.pause()
        app.runs = false
    end
end

function appResume()
    if not app.runs then
        system.setIdleTimer(false)
        physics.start()
        appRemoveSpritesByGroup('menu')
        app.runs = true
    end
end

function appRestart()
    appSetValuesToDefault()
    app.phase.name = 'none'
    appStart()
    appResume()
end

function appStart()
    system.setIdleTimer(false)
    appRemoveSprites()
    appHandleRemovalsForcedSimple()
    appCreateDefaultSprites()
    app.phase:set('default')
end

function appHandleAll()
    local spritesCount = 0
    for id, sprite in pairs(app.sprites) do
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

    if app.recentlyPlayedSounds ~= nil and #app.recentlyPlayedSounds > 0 and misc.getChance(15) then
        table.remove(app.recentlyPlayedSounds, 1)
    end

    if app.showDebugInfo then app.framesCounter = app.framesCounter + 1 end
end

function appHandleRemovals()
    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and (sprite.energy <= 0 or sprite.gone) then

            if app.runs or misc.inArray(app.groupsToHandleEvenWhenPaused, sprite.group) then
                if sprite.handleWhenGone ~= nil and app.handleSpritesWhenGone then
                    sprite:handleWhenGone()
                end

                if sprite.isIndexed then
                    app.spritesIndex[sprite.type][sprite.id] = nil
                end

                if app.sprites[id].removeSelf then app.sprites[id]:removeSelf() end
                app.sprites[id] = nil

            end

        end
    end
end

function appHandleRemovalsForcedSimple()
    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and (sprite.energy <= 0 or sprite.gone) then
            if sprite.isIndexed then app.spritesIndex[sprite.type][sprite.id] = nil end
            if app.sprites[id].removeSelf then app.sprites[id]:removeSelf() end
            app.sprites[id] = nil
        end
    end
end

function appAddSprite(sprite, optionalHandleFunction, optionalGroup, optionalHandleWhenGone)
    if sprite.isAutoPhysical then sprite.isHitTestable = true end

    sprite.handle = optionalHandleFunction
    if sprite.group == nil then sprite.group = optionalGroup end
    sprite.handleWhenGone = optionalHandleWhenGone
    app.sprites[sprite.id] = sprite

    if sprite.isIndexed then
        if app.spritesIndex[sprite.type] == nil then app.spritesIndex[sprite.type] = {} end
        app.spritesIndex[sprite.type][sprite.id] = true
    end

    if sprite.handle ~= nil then sprite:handle() end
end

function appGetSpritesByType(typeOrTypes, optionalSubtype)
    local foundSprites = {}

    typeOrTypes = misc.toTable(typeOrTypes)
    for i = 1, #typeOrTypes do
        local thisType = typeOrTypes[i]
        if app.spritesIndex[thisType] then

            for id, value in pairs(app.spritesIndex[thisType]) do
                if optionalSubtype == nil or app.sprites[id].subtype == optionalSubtype then
                    foundSprites[#foundSprites + 1] = app.sprites[id]
                end
            end

        end
    end

    return foundSprites
end

function appGetSpritesByGroup(group)
    local foundSprites = {}

    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and sprite.energy > 0 and not sprite.gone then
            if sprite.group == group then
                foundSprites[#foundSprites + 1] = sprite
            end
        end
    end

    return foundSprites
end

function appGetSpriteByType(thisType, optionalSubtype)
    local foundSprite = nil

    if app.spritesIndex[thisType] then
        for id, value in pairs(app.spritesIndex[thisType]) do
            if optionalSubtype == nil or app.sprites[id].subtype == optionalSubtype then
                foundSprite = app.sprites[id]
                break
            end
        end
    end

    return foundSprite
end

function appMiscShowFonts()
    local function handle(self)
        if self.action.touchJustEnded then
            appMiscShowFonts()
        end
    end

    if app.fontsPage == nil then app.fontsPage = 0 end
    app.fontsPage = app.fontsPage + 1

    appRemoveSprites()

    local fontNames = native.getFontNames()
    -- fontNames = misc.filterArrayBySearch(fontNames, 'th')

    local perPage = 25
    local min = (app.fontsPage - 1) * perPage
    local max = min + perPage
    y = 0

    local oldFont = app.defaultFont
    app.defaultFont = native.systemFontBold

    for i = 1, #fontNames do
        if i >= min and i <= max + 1 then
            y = y + 1
            local self = spriteModule.spriteClass('text', 'fontName', nil, nil, false, app.maxXHalf, 5 + y * 14)
            if i < max + 1 then
                self.text = '"' .. fontNames[i] .. '"'
                self:setFontSize(12)
            else
                self.text = '-- NEXT -->'
                self:setFontSize(13)
                self.listenToTouch = true
            end
            appAddSprite(self, handle)
        end
    end

    app.defaultFont = oldFont
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
            infos[#infos + 1] = 'FPS ' .. app.framesCounter
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

function appGetSpriteByTypeAndParentId(desiredType, desiredParentId, optionalSubtype)
    local foundSprite = nil
    if desiredType ~= nil and desiredParentId ~= nil then

        local sprites = appGetSpritesByType(desiredType, optionalSubtype)
        for i = 1, #sprites do
            if sprites[i].parentId == desiredParentId then
                foundSprite = sprites[i]
                break
            end
        end

    end
    return foundSprite
end

function appGetSpriteByParentId(desiredParentId)
    local desiredSprite = nil
    if desiredParentId ~= nil then
        for id, sprite in pairs(app.sprites) do
            if desiredParentId == sprite.parentId then
                desiredSprite = sprite
                break
            end
        end
    end
    return desiredSprite
end

function appGetChild(type, parentId, optionalSubType)
    local foundSprite = nil

    local sprites = appGetSpritesByType(type)
    for i = 1, #sprites do
        if sprites[i].parentId == parentId then
            if optionalSubType == nil or optionalSubType == sprites[i].subtype then
                foundSprite = sprites[i]
                break
            end
        end
    end

    return foundSprite
end

function appGetChildren(type, parentId, optionalSubType)
    local foundSprites = {}

    local sprites = appGetSpritesByType(type)
    for i = 1, #sprites do
        if sprites[i].parentId == parentId then
            if optionalSubType == nil or optionalSubType == sprites[i].subtype then
                foundSprites[#foundSprites + 1] = sprites[i]
            end
        end
    end

    return foundSprites
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

function appSetToFrontByType(typeOrTypes, optionalSubtype)
    typeOrTypes = misc.toTable(typeOrTypes)
    for typeI = 1, #typeOrTypes do
        local sprites = appGetSpritesByType(typeOrTypes[typeI], optionalSubtype)
        for i = 1, #sprites do sprites[i]:toFront() end
    end
end

function appSetToBackByType(typeOrTypes, optionalSubtype)
    typeOrTypes = misc.toTable(typeOrTypes)
    for typeI = 1, #typeOrTypes do
        local sprites = appGetSpritesByType(typeOrTypes[typeI], optionalSubtype)
        for i = 1, #sprites do sprites[i]:toBack() end
    end
end

function appBackgroundToBack()
    local sprite = appGetSpriteByType('background')
    if sprite ~= nil then sprite:toBack() end
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

function appRemoveSpritesExcept(exceptType)
    for id, sprite in pairs(app.sprites) do
        if sprite.type ~= exceptType then sprite.gone = true end
    end
end

function appRemoveSpritesIgnoreHandleWhenGone(exceptType)
    local oldValue = app.handleSpritesWhenGone
    app.handleSpritesWhenGone = false
    if exceptType ~= nil then appRemoveSpritesExcept(exceptType)
    else appRemoveSprites()
    end
    appHandleRemovals()
    app.handleSpritesWhenGone = oldValue
end

function appRemoveSpritesByTypeIgnoreHandleWhenGone(type)
    local oldValue = app.handleSpritesWhenGone
    app.handleSpritesWhenGone = false
    appRemoveSpritesByType(type)
    appHandleRemovals()
    app.handleSpritesWhenGone = oldValue
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

function appRemoveSpritesByTypeNow(typeOrTypes, optionalSubtype, optionalParentPlayer, optionalGroup)
    appRemoveSpritesByType(typeOrTypes, optionalSubtype, optionalParentPlayer, optionalGroup)
    appHandleRemovals()
end

function appRemoveSpritesNow()
    appRemoveSprites()
    appHandleRemovals()
end

function appRemoveSpritesByType(typeOrTypes, optionalSubtype, parentId, optionalGroup)
    if typeOrTypes ~= nil then
        typeOrTypes = misc.toTable(typeOrTypes)
        for id, sprite in pairs(app.sprites) do
            if misc.inArray(typeOrTypes, sprite.type) then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok and parentId ~= nil then ok = sprite.parentId == parentId end
                if ok and optionalGroup ~= nil then ok = sprite.group == optionalGroup end

                if ok then sprite.gone = true end        
            end
        end
    end
end

function appGetSpriteCountByType(typeOrTypes, optionalSubtype, optionalParentId)
    local count = 0

    local sprites = appGetSpritesByType(typeOrTypes, optionalSubtype)
    if optionalParentId ~= nil then
        for i = 1, #sprites do
            if sprites[i].parentId == optionalParentId then count = count + 1 end
        end
    else
        count = #sprites
    end

    return count
end

function appGetPhysicalSpriteCount()
    local count = 0
    for id, sprite in pairs(app.sprites) do
        if sprite.isAutoPhysical and not sprite.gone then count = count + 1 end
    end
    return count
end

function appGetHealthySpriteCountByType(typeOrTypes, optionalSubtype)
    local count = 0
    if typeOrTypes ~= nil then
        typeOrTypes = misc.toTable(typeOrTypes)
        for id, sprite in pairs(app.sprites) do
            local isHealthy = sprite.energySpeed >= 0 or sprite.energy >= 100
            if misc.inArray(typeOrTypes, sprite.type) and not sprite.gone and isHealthy then
                local ok = true
                if ok and optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end
                if ok then count = count + 1 end
            end
        end
    end
    return count
end

function appHasSpriteNearby(type, subtype, x, y, maxDistanceToTakeIntoAccount)
    local has = false
    for id, sprite in pairs(app.sprites) do
        if sprite.type == type and sprite.subtype == subtype and not sprite.gone then
            local distance = misc.getDistance( {x = x, y = y}, {x = sprite.x, y = sprite.y} )
            if math.abs(distance) <= maxDistanceToTakeIntoAccount then
                has = true
                break
            end
        end
    end
    return has
end

function appGetSpritesNearby(type, x, y, maxDistance, optionalSubtype, optionalMinDistance)
    local spritesNearby = {}
    local sprites = appGetSpritesByType(type)
    for i = 1, #sprites do
        local sprite = sprites[i]
        local ok = true
        if optionalSubtype ~= nil then ok = sprite.subtype == optionalSubtype end

        if ok then
            local distance = misc.getDistance( {x = x, y = y}, {x = sprite.x, y = sprite.y} )
            distance = math.abs(distance)
            if distance <= maxDistance and (optionalMinDistance == nil or distance >= optionalMinDistance) then
                spritesNearby[#spritesNearby + 1] = sprite
            end
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

function appPutBackgroundSpritesToBack(backgroundSpriteTypes)
    if app.backgroundSpriteTypes ~= nil then backgroundSpriteTypes = app.backgroundSpriteTypes end
    if backgroundSpriteTypes ~= nil then
        local sprites = appGetSpritesByType()
        for id, sprite in pairs(sprites) do sprite:toBack() end
    
        local background = appGetSpriteByType('background')
        if background ~= nil then background:toBack() end
    end
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

function appPlaySound(soundName, optionalChannel, optionalDoLoop, optionalOnCompleteFunction, optionalPlayAsStream, playEvenWhenRecentlyPlayed)
    if playEvenWhenRecentlyPlayed == nil then playEvenWhenRecentlyPlayed = false end

    if app.doPlaySounds and soundName ~= nil then
        if playEvenWhenRecentlyPlayed or not misc.inArray(app.recentlyPlayedSounds, soundName) then
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

function appAlert(s, showInAnyCase)
    if showInAnyCase == nil then showInAnyCase = false end
    if app.showDebugInfo or showInAnyCase then
        native.showAlert( '', tostring(s), {'OK'} )
    end
end

function appDebug(s, showGuid)
    if app.showDebugInfo then
        if showGuid == nil then showGuid = false end

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
        appRemoveSpritesByType('debugText')
        if x == nil then x = app.maxXHalf end
        if y == nil then y = app.maxY - 60 end
        if fontSize == nil then fontSize = 16 end
        if alpha == nil then alpha = .55 end

        local oldDefaultFont = app.defaultFont
        app.defaultFont = native.systemFontBold

        local self = spriteModule.spriteClass('text', 'debugText', nil, nil, false, x, y, width, height)
        self:setFontSize(fontSize)
        self:setRgbWhite()
        self.alpha = alpha
        self:setColorBySelf()
        self:toFront()
        appAddSprite(self, handle)

        app.defaultFont = oldDefaultFont
    end
end

function appCreateClock(x, y, width, height, fontSize, alpha)
    if app.showDebugInfo then
        appRemoveSpritesByType('clockText')
        if x == nil then x = app.maxXHalf end
        if y == nil then y = 180 end
        if fontSize == nil then fontSize = 20 end
        if alpha == nil then alpha = 1 end

        local oldDefaultFont = app.defaultFont
        app.defaultFont = native.systemFontBold

        local self = spriteModule.spriteClass('text', 'clockText', nil, nil, false, x, y, width, height)
        self:setFontSize(fontSize)
        self:setRgbWhite()
        self.alpha = alpha
        self:setColorBySelf()
        self:toFront()
        appAddSprite(self)

        app.defaultFont = oldDefaultFont
    end
end

function appPrint(stringOrStringTable, forcePrint, doIndent, showGuid)
    if forcePrint == nil then forcePrint = false end
    if doIndent == nil then doIndent = false end -- true
    if showGuid == nil then showGuid = false end -- true

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

function appGetId()
    local id = appGetGuid()
    while app.sprites[id] ~= nil do id = appGetGuid(64) end
    return id
end

function appGetGuid(guidLength)
    if guidLength == nil then guidLength = 16 end
    local s = 'i'
    if app.guidChars == nil then
        app.guidChars = {'0','1','2','3','4','5','6','7','8','9',
                'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
                'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
    end

    local guidCharsLength = #app.guidChars

    for i = 1, guidLength do
        s = s .. app.guidChars[ math.random(1, guidCharsLength) ]
    end

    return s
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

function appAdjustSpriteFrame(sprite)
    if sprite ~= nil and not sprite.gone and sprite.data.frameImage ~= nil and sprite.data.frameImage ~= sprite.data.frameImageOld then
        local width = sprite.width; local height = sprite.height
        local self = spriteModule.spriteClass('rectangle', 'frame', nil, image, false, sprite.x, sprite.y, sprite.width, sprite.height)
        self.parentId = self.id7
        self.movesWithParent = true
        appAddSprite(self, frame, moduleGroup)
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

function appWobbleSprite(self)
    if self.data.rotationSpeedMax == nil then self.data.rotationSpeedMax = math.random(1, 3) * .1 end
    if self.data.rotationLimit == nil then self.data.rotationLimit = 3 end
    if self.data.rotationSpeed == nil then self.data.rotationSpeed = self.data.rotationSpeedMax end

    if self.rotation > self.data.rotationLimit then
        self.rotation = self.data.rotationLimit
        self.data.rotationSpeed = -self.data.rotationSpeedMax
    elseif self.rotation < -self.data.rotationLimit then
        self.rotation = -self.data.rotationLimit
        self.data.rotationSpeed = self.data.rotationSpeedMax
    end
    self.rotation = self.rotation + self.data.rotationSpeed
end

function appHandleBlink(self, length, speed)
    if length == nil then length = 20 end
    if speed == nil then speed = 2.5 end
    if not self.alphaChangesWithEnergy then self.alphaChangesWithEnergy = true end

    if self.extraPhase.name == 'blinkOut' then
        if not self.extraPhase:isInited() then
            self.extraPhase:setNext('blinkIn', length)
            self.energySpeed = -speed
        end
    elseif self.extraPhase.name == 'blinkIn' then
        if not self.extraPhase:isInited() then
            self.extraPhase:setNext('blinkOut', length)
            self.energySpeed = speed
        end
    end
end

function appGetRectangle()
    return {x1 = app.minX, y1 = app.minY, x2 = app.maxX, y2 = app.maxY}
end

function appPrintDeviceInfo()
    appPrint( 'Resolution = ' .. display.contentWidth .. ' x ' .. display.contentHeight .. ' ' ..
            '(Scale = ' .. display.contentScaleX .. ',' .. display.contentScaleY .. ') - ' .. app.device .. ' - ' ..
            'DeviceResolution = ' .. tostring(app.deviceResolution.width) .. 'x' .. tostring(app.deviceResolution.height) )
end

function appShowReviewPage()
    local appUrl = ''
    if app.isIOs then
        local countryCode = system.getPreference('locale', 'country') -- e.g. 'us'
        local overlong = 6
        if countryCode == nil or string.len(countryCode) >= overlong then countryCode = 'us' end
        local appUrl = 'itms://itunes.apple.com/' .. tostring(countryCode) .. '/app/' .. misc.toName(app.title, nil, true) .. '/id' .. tostring(app.id)
    else
        appUrl = 'https://play.google.com/store/apps/details?id=' .. app.idInStore
    end
    system.openURL(appUrl)
end

function appHandleAskForReview(doForceToShow)
    local function buttonListener(event)
        if event.action == 'clicked' then
            local indexes = {'yes', 'no', 'remind'}
            local answer = indexes[event.index]

            if answer == 'yes' then
                app.doAskForReview = false
                appShowReviewPage()

            elseif answer == 'no' then
                app.doAskForReview = false
                app.askForReviewAtRound = app.askForReviewAtRound + 1000

            elseif answer == 'remind' then
                app.askForReviewAtRound = app.askForReviewAtRound + 30
                if app.askForReviewAtRound >= 100 then
                    app.askForReviewAtRound = app.askForReviewAtRound + 100
                end

                if app.askForReviewAtRound >= 500 then app.doAskForReview = false end
            end

            app.data:set('askForReviewAtRound', app.askForReviewAtRound)
            app.data:setBool('doAskForReview', app.doAskForReview)

            -- appPrint( 'app.askForReviewAtRound = ' .. tostring(app.askForReviewAtRound) )
            -- appPrint( 'app.doAskForReview = ' .. tostring(app.doAskForReview) )
        end
    end

    if doForceToShow == nil then doForceToShow = false end
    if (app.doAskForReview and app.askForReviewAtRound == app.roundsPlayedAllTime - 1) or doForceToShow then
        native.showAlert( '', 'Thanks for playing! Do you want to review the game?',
                { 'OK', language.get('newsDialogNo'), language.get('newsDialogRemind') }, buttonListener )
    end
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

function appToPackageName(s)
    local abc = {'a','b','c','d','e','f', 'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
    return misc.toName(s, abc)
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

function appSetPhysicalRotation(sprite, rotation)
    sprite:setReferencePoint(display.TopLeftReferencePoint)
    sprite.rotation = rotation
    local rectContentX, rectContentY = sprite:localToContent(0, 0)
    sprite.rotation = 0
    sprite:setReferencePoint(display.CenterReferencePoint)
    sprite.x = math.floor(rectContentX + sprite.width / 2)
    sprite.y = math.floor(rectContentY + sprite.height / 2)
    sprite.rotation = rotation
    return sprite
end

function appInitSounds(playMusicAtStart)
    if playMusicAtStart == nil then playMusicAtStart = false end
    if app.doPlaySounds then
        for id, channel in pairs(app.soundChannel) do audio.reserveChannels(channel) end
        appCacheImportantSounds()
        appHandleSoundsVolume()
        appInitMusic()
        if playMusicAtStart then appPlayNextMusic() end
    end
end

function appHandleSoundsVolume()
    app.soundVolumeDefault[app.soundChannel.music] = misc.getIf(app.doPlayBackgroundMusic, app.soundVolumeDefault[app.soundChannel.music], 0)

    if app.playAllSounds then
        for id, channel in pairs(app.soundChannel) do
            audio.setVolume( app.soundVolumeDefault[channel], {channel = channel} )
        end
    end
end

function appPlayNextMusic()
    local i = 1
    if app.musicOrder[i] == nil then appInitMusic() end
    if app.musicOrder[i] ~= nil then
        local soundName = table.remove(app.musicOrder, i)
        local doPlayMusicAsStream = false
        appPlaySound('theme/' .. soundName, app.soundChannel.music, nil, appPlayNextMusic, doPlayMusicAsStream, true)
    end
end

function appInitMusic()
    if app.maxThemes ~= nil and app.maxThemes >= 1 then
        app.musicOrder = {}
        app.musicOrder[#app.musicOrder + 1] = '1'
        local lastVariationI = nil
        for i = 1, 1000 do
            if app.maxThemes > 1 then
                local variationI = nil
                while variationI == nil or variationI == lastVariationI do variationI = math.random(1, app.maxThemes) end
                local repeatsMax = misc.getIf(variationI == 1, 1, 2)
                for repeats = 1, repeatsMax do
                    app.musicOrder[#app.musicOrder + 1] = variationI
                end
                lastVariationI = variationI
            else
                app.musicOrder[#app.musicOrder + 1] = '1'
            end
        end
    end
end

function appSetMusicVolumeToDefault()
    if app.playAllSounds then
        local channel = app.soundChannel.music
        audio.setVolume( app.soundVolumeDefault[channel], {channel = channel} )
    end
end

function appSetAlignmentRectangle(marginX, marginY)
    app.alignmentRectangle = appGetActualScreenRectangle(18, 18)
end

function appGetActualScreenRectangle(marginX, marginY)
    if marginX == nil then marginX = 0 end
    if marginY == nil then marginY = 0 end

    local actualWidth, actualHeight = display.pixelHeight, display.pixelWidth
    local scale = display.contentScaleX
    return {
            x1 = math.floor( app.maxXHalf - (actualWidth * scale) * .5 + marginX ),
            y1 = math.floor( app.maxYHalf - (actualHeight * scale) * .5 + marginY ),
            x2 = math.floor( app.maxXHalf + (actualWidth * scale) * .5 - marginX ),
            y2 = math.floor( app.maxYHalf + (actualHeight * scale) * .5 - marginY ) }
end

function appPushIntoRectangle(rectangle, x, y, width, height)
    local widthHalf, heightHalf = width / 2, height / 2

    if x - widthHalf < rectangle.x1 then x = rectangle.x1 + widthHalf
    elseif x + widthHalf > rectangle.x2 then x = rectangle.x2 - widthHalf
    end

    if y - heightHalf < rectangle.y1 then y = rectangle.y1 + heightHalf
    elseif y + heightHalf > rectangle.y2 then y = rectangle.y2 - heightHalf
    end

    return x, y
end

function appSetMinimumViewableRectangle(marginX, marginY)
    if marginX == nil then marginX = 98 end
    if marginY == nil then marginY = 129 end
    app.minimumViewableRectangle = { x1 = app.minX + marginX, y1 = app.minY + marginY,
            x2 = app.maxX - marginX, y2 = app.maxY - marginY }
end

function appGetScaleFactor()
    local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
    local scaleFactor = math.floor(deviceWidth / display.contentWidth)
    if scaleFactor < 1 then scaleFactor = 1 end
    return scaleFactor
end

function appHandleRemovalsSupportDisplayTypeGroups()
    local indexNonGroup = 1
    local indexGroup = 2
    for iDisplayType = indexNonGroup, indexGroup do

        for id, sprite in pairs(app.sprites) do
            if sprite ~= nil and (sprite.energy <= 0 or sprite.gone) then
                local displayTypeOk = (sprite.displayType ~= 'group' and iDisplayType == indexNonGroup) or
                        (sprite.displayType == 'group' and iDisplayType == indexGroup)
                if displayTypeOk then
                    if app.runs or misc.inArray(app.groupsToHandleEvenWhenPaused, sprite.group) then
                        if sprite.handleWhenGone ~= nil and app.runs and app.handleSpritesWhenGone then sprite:handleWhenGone() end
                        if sprite.gone then

                            if sprite.isIndexed then
                                app.spritesIndex[sprite.type][sprite.id] = nil
                            end

                            if app.sprites[id].removeSelf then app.sprites[id]:removeSelf() end
                            app.sprites[id] = nil

                        end
                    end
                end
            end
        end

    end
end

function appGetNearestSprite(point, type, subtype, selfToExclude)
    local nearestDistance = nil
    local sprites = appGetSpritesByType(type, subtype)
    local nearestSprite = nil

    for i = 1, #sprites do
        local sprite = sprites[i]
        if selfToExclude == nil or sprite.id ~= selfToExclude.id then
            local distance = misc.getDistance( point, sprite:getPoint() )
            if nearestDistance== nil or distance < nearestDistance then
                nearestDistance = distance
                nearestSprite = sprite
            end
        end
    end

    return nearestSprite
end

function appStopSprites(types)
    local sprites = appGetSpritesByType(types)
    for i = 1, #sprites do
        local sprite = sprites[i]

        sprite.data.beforeStop = {}

        if sprite.getLinearVelocity then
            local velocityX, velocityY = sprite:getLinearVelocity()
            sprite.data.beforeStop.velocityX = velocityX
            sprite.data.beforeStop.velocityY = velocityY
            sprite.data.beforeStop.bodyType = sprite.bodyType
            if sprite.bodyType ~= nil then sprite.bodyType = 'static' end
        end

        if sprite.phase ~= nil then
            sprite.data.beforeStop.phase = {
                    name = sprite.phase.name,
                    counter = sprite.phase.counter,
                    nameNext = sprite.phase.nameNext,
                    inited = sprite.phase.inited
                    }
        end

        if sprite.getLinearVelocity then sprite:setLinearVelocity(0, 0) end

    end
end

function appStartSprites(types)
    local sprites = appGetSpritesByType(types)
    for i = 1, #sprites do
        local sprite = sprites[i]
        local beforeStop = sprite.data.beforeStop
        if beforeStop ~= nil then
            if sprite.bodyType ~= nil then sprite.bodyType = beforeStop.bodyType end
            if sprite.getLinearVelocity then
                sprite:setLinearVelocity(beforeStop.velocityX, beforeStop.velocityY)
            end

            if beforeStop.phase ~= nil then
                sprite.phase.name = beforeStop.phase.name
                sprite.phase.counter = beforeStop.phase.counter
                sprite.phase.nameNext = beforeStop.phase.nameNext
                sprite.phase.inited = beforeStop.phase.inited
            end

            sprite.data.beforeStop = nil
        end
    end
end
