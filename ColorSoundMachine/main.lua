physics = require('physics')
misc = require('misc')
language = require('language-data')
dataModule = require('data-class')
spritesheetModule = require('sprite')
store = require('store')
spriteModule = require('sprite-class')
spritesHandlerModule = require('sprites-handler')
phaseModule = require('phase-class')
menuModule = require('menu-class')
newsModule = require('news-class')
require('app-misc')
require('app-purchasing')
require('sqlite3')

app = {}

function init()
    misc.initDefaults()
    appClass()
    appClearConsole()
    appDefineTranslatedImages()
    appDefineImagesWhichFillScreen()
    appDefineCachedSounds()
    appInitSound()
    app.data:open()
    appCreateDbTablesIfNeeded()
    appInitPurchases()
    -- app.news:verifyNeededFunctionsAndVariablesExists()
    appStart()
    if not app.data:getBool('playedIntroBefore') then
        media.playVideo('video/intro.m4v', false)
        app.data:setBool('playedIntroBefore', true)
    end

    Runtime:addEventListener('enterFrame', appHandleAll)
    timer.performWithDelay(app.secondInMs, handleClock)
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
        appDeleteMachinesMarkedForDeletion()
        system.setIdleTimer(false)
        physics.start()
        appRemoveSpritesByGroup('menu')
        app.runs = true
    end
end

function appRestart()
    appClearMachine()
    appStart()
    appResume()
end

function appClearMachine()
    appRemoveSprites()
    app.dropBallCounter = 1
    app.currentSavedId = nil
    app.currentNavigationPage = 1
    app.currentPlane = 1
    app.planesMax = #app.notes['planes']
    app.planesData = {}
    app.planePhase = phaseModule.phaseClass()
    app.planePhase:set('default')
    app.phase = phaseModule.phaseClass()
    app.phase:set('default')
    for i = 1, app.planesMax do app.planesData[i] = {} end
end

function appStart(isPlaneChange)
    if isPlaneChange == nil then isPlaneChange = false end
    system.setIdleTimer(false)

    if isPlaneChange then
        app.planePhase:set('default')
        appRemoveSpritesByType( {'block', 'ball', 'waveEffect'} )
    else
        timer.performWithDelay(4000, app.news.handle)
        appRemoveSprites()
    end

    appCreateSprites(nil, not isPlaneChange)
    if isPlaneChange then
        app.dropBallCounter = 4
        app.phase:set('dropBalls')
    else
        app.phase:set('default', app.smallPhaseUnitFrames, 'dropBalls')
    end
end

function appCreatePageUnlockPremium()
    appPause()
    app.menu:createPageUnlockPremium()
end

function appLoadMachineData(id)
    local value = nil
    local query = 'SELECT dataString FROM machines WHERE id = ' .. misc.toQueryValue(id)
    for row in app.data.db:nrows(query) do
        app.planesData = appGetPlanesDataFromString(row.dataString)
        break
    end
end

function appGetPlanesDataFromString(dataString)
    local planesData = {}
    local planesDataStrings = misc.split(dataString, '|')
    local numberOfPlanes = misc.getLowest(#planesDataStrings, app.planesMax)
    for planeI = 1, numberOfPlanes do
        planesData[planeI] = {}
        local blocks = misc.split(planesDataStrings[planeI], ';')
        for blockI = 1, #blocks do
            if blocks[blockI] ~= '' then
                local block = misc.split(blocks[blockI], ',')
                planesData[planeI][blockI] = { subtype = tostring(block[1]), x = tonumber(block[2]), y = tonumber(block[3]),
                        rotationIndex = tonumber(block[4]), noteIndex = tonumber(block[5]) }
            end
        end
    end
    return planesData
end

function appSaveMachine()
    appResume()
    timer.performWithDelay(100, appDoSaveMachine)
end

function appDoSaveMachine()
    if app.currentSavedId == nil then
        app.data:exec( 'INSERT INTO machines (dateCreated, dateLastSaved) ' ..
                'VALUES (' .. misc.toQuery( misc.getIsoDateTime() ) .. ', "")' )
        app.currentSavedId = app.data:getLastId()
    end

    if app.currentSavedId ~= nil then
        app.planesData[app.currentPlane] = appGetPlaneDataFromCurrentBlocks()
        local dataString = appGetPlanesDataString()

        if dataString == '' then
            app.db:exec( 'DELETE FROM machines WHERE id = ' .. misc.toQuery(app.currentSavedId) )
            app.currentSavedId = nil
        else
            local query = 'UPDATE machines SET ' ..
                    'dataString = ' .. misc.toQuery(dataString) .. ', dateLastSaved = ' .. misc.toQuery( misc.getIsoDateTime() ) .. ' ' ..
                    'WHERE id = ' .. misc.toQuery(app.currentSavedId)
            app.data:exec(query)
            app.menu:createSavedIndicator()
        end
    end
end

function appDeleteMachinesMarkedForDeletion()
    for i = 1, #app.machineIdsToDeleteSoon do
        local id = app.machineIdsToDeleteSoon[i]
        app.data:exec( 'DELETE FROM machines WHERE id = ' .. misc.toQuery(id) )
        if id == app.currentSavedId then app.currentSavedId = nil end
    end
    app.machineIdsToDeleteSoon = {}
end

function appGetPlanesDataString()
    local planesDataString = {}
    for i = 1, app.planesMax do
        local blockStrings = {}
        if app.planesData[i] ~= nil then
            for blockI = 1, #app.planesData[i] do
                local block = app.planesData[i][blockI]
                if block ~= nil and block.subtype ~= nil and block.subtype ~= '' then
                    blockStrings[blockI] = misc.clearNil(block.subtype) .. ',' ..
                            misc.clearNil(block.x) .. ',' .. misc.clearNil(block.y) .. ',' ..
                            misc.clearNil(block.rotationIndex) .. ',' .. misc.clearNil(block.noteIndex)
                end
            end
        end
        planesDataString[i] = misc.join(blockStrings, ';')
    end
    return misc.join(planesDataString, '|')
end

function appSaveMachineAsNew()
    app.currentSavedId = nil
    appSaveMachine()
end

function appCreateDbTablesIfNeeded()
    app.data:exec( 'CREATE TABLE IF NOT EXISTS machines ' ..
            '(id INTEGER PRIMARY KEY AUTOINCREMENT, dataString STRING, dateCreated STRING, dateLastSaved STRING)' )
    -- dataString = 'itemData1,itemData1,itemData1;itemData2,itemData2,itemData2|...'
end

function appCreateSprites(includeIntro, includeNavigation)
    app.spritesHandler:createBackground()
    appCreateSpritesFromPlaneData()

    if includeNavigation then
        app.spritesHandler:createNavigation()
        app.menu:createButtons()
        appCreateClock(app.maxX - 13, 39, nil, nil, 11, .45)
        appCreateDebug(app.maxXHalf, 65, nil, nil, 16, .9)
    end

    appIncludeLetterboxBars()
end

function appHandlePhases()
    app.phase:handleCounter()
    app.planePhase:handleCounter()

    if app.phase.name == 'dropBalls' then
        if not app.phase:isInited() then
            local dropBallCounterMax = 16

            local includeVeryFastOnes = true
            local includeFastOnes = misc.inArray( {2, 4, 6, 8, 10, 12, 14, 16}, app.dropBallCounter )
            local includeNormalOnes = misc.inArray( {4, 8, 12, 16}, app.dropBallCounter )
            local includeSlowOnes = misc.inArray( {8, 16}, app.dropBallCounter )
            local includeVerySlowOnes = misc.inArray( {16}, app.dropBallCounter )

            local sprites = appGetSpritesByType('block')
            for i = 1, #sprites do
                local sprite = sprites[i]
                if sprite.data.isDropper then
                    local doDrop = true
                    if sprite.subtype == 'waitDropper' then
                        doDrop = appGetSpriteCountByType('ball', nil, nil, sprite.id) == 0
                    elseif sprite.subtype == 'bumpDropper' then
                        doDrop = false
                    end

                    if doDrop then
                        local nearbySpeederCount = appGetSpriteCountNearby('block', 'speederBlock', sprite.x, sprite.y, app.blockDistanceConsideredNear)
                        local nearbySlowerCount = appGetSpriteCountNearby('block', 'slowerBlock', sprite.x, sprite.y, app.blockDistanceConsideredNear)

                        local isVeryFast = nearbySpeederCount >= 2
                        local isFast = nearbySpeederCount == 1
                        local isNormal = nearbySpeederCount == 0 and nearbySlowerCount == 0
                        local isSlow = not isFast and not isVeryFast and nearbySlowerCount == 1
                        local isVerySlow = not isFast and not isVeryFast and nearbySlowerCount >= 2

                        doDrop = (includeVeryFastOnes and isVeryFast) or (includeFastOnes and isFast) or (includeNormalOnes and isNormal) or
                                (includeSlowOnes and isSlow) or (includeVerySlowOnes and isVerySlow)
                    end

                    if doDrop then
                        app.spritesHandler:createBall( appGetBallSubtypeByBlock(sprite.subtype), sprite.x, sprite.y + sprite.height / 2, sprite.id )
                    end
                end
            end

            if includeNormalOnes then
                local movers = appGetSpritesByType('block', 'horizontalMover')
                for i = 1, #movers do
                    local mover = movers[i]
                    if not mover.isDragged then
                        mover.alsoAllowsExtendedNonPhysicalHandling = true
                        if mover.speedX == 0 then
                            mover.speedX = 1
                        else
                            mover.speedX = mover.speedX * -1
                            if mover.speedX > 0 and mover.data.placedX ~= nil then
                                mover.x = mover.data.placedX
                            end
                        end
                    end
                end
            end

            app.dropBallCounter = app.dropBallCounter + 1
            if app.dropBallCounter > dropBallCounterMax then app.dropBallCounter = 1 end

            app.phase:set('default', app.smallPhaseUnitFrames, 'dropBalls')
        end

    end

    if app.planePhase.name == 'default' then
        if not app.planePhase:isInited() then
            app.planePhase:setNext('readyForChange', 10)
        end
    end
end

function appGetNumberOfPlacedItems()
    local v = 0
    local sprites = appGetSpritesByType('block')
    for i = 1, #sprites do
        local sprite = sprites[i]
        if not sprite.gone and (sprite.data ~= nil and sprite.data.dropped) then
            v = v + 1
        end
    end
    return v
end

function appGetBallSubtypeByBlock(blockSubtype)
    local ballSubtype = 'default'
    local ballSubtypes = {changeDropper = 'changer', changeReverseDropper = 'changerReverse',
            dropperPlus = 'plus', dropperMinus = 'minus', waitDropper = 'wait', planeBallDropper = 'plane'}
    if ballSubtypes[blockSubtype] then ballSubtype = ballSubtypes[blockSubtype] end
    return ballSubtype
end

function appDefineCachedSounds()
    for pitch = app.basePitch - 1, app.basePitch + 1 do
        for note = 1, app.notesMax do
            app.importantSoundsToCache[#app.importantSoundsToCache + 1] = app.baseInstrument .. '/' .. pitch .. '-' .. note
            if pitch == app.basePitch then
                app.importantSoundsToCache[#app.importantSoundsToCache + 1] =
                        app.planeInstrument[app.currentPlane].name .. '/' .. app.planeInstrument[app.currentPlane].pitch .. '-' .. note
            end
        end
        app.importantSoundsToCache[#app.importantSoundsToCache + 1] = 'drum/' .. pitch
    end
    app.importantSoundsToCache[#app.importantSoundsToCache + 1] = 'drum/plane'
end

function appChangePlane(newPlane)
    local didChangePlane = false
    if newPlane ~= app.currentPlane and (app.planePhase ~= nil and app.planePhase.name == 'readyForChange') then
        appSetFlipBlocksToTarget()
        appSetMoversToPlacedPosition()
        app.planesData[app.currentPlane] = appGetPlaneDataFromCurrentBlocks()
        app.currentPlane = newPlane
        didChangePlane = true
        appStart(true)
    end
    return didChangePlane
end

function appSetFlipBlocksToTarget()
    local sprites = appGetSpritesByType('block', 'flipBlock')
    for i = 1, #sprites do
        local sprite = sprites[i]
        if sprite.phase ~= nil then
            if sprite.phase.nameNext == 'flip' then sprite.targetRotation = sprite.rotation * -1 end
            sprite.rotation = sprite.targetRotation
            sprite.data.rotationIndex = misc.getArrayIndexByValue(sprite.data.rotations, sprite.rotation)
            sprite.phase:set('default')
        end
    end
end

function appSetMoversToPlacedPosition()
    local sprites = appGetSpritesByType('block')
    for i = 1, #sprites do
        local sprite = sprites[i]
        if sprite.data.placedX ~= nil and sprite.data.placedY ~= nil then
            if sprite.x ~= sprite.data.placedX then sprite.x = sprite.data.placedX end
            if sprite.y ~= sprite.data.placedY then sprite.y = sprite.data.placedY end
        end
    end
end

function appGetPlaneDataFromCurrentBlocks()
    local data = {}
    local blocks = appGetSpritesByType('block')
    for i = 1, #blocks do
        local block = blocks[i]
        local blockX = block.x
        local blockY = block.y
        if block.data.placedX ~= nil and block.data.placedY ~= nil then
            blockX = block.data.placedX; blockY = block.data.placedY
        end
        data[#data + 1] = { subtype = block.subtype, x = math.floor(blockX), y = math.floor(blockY),
                rotationIndex = block.data.rotationIndex, noteIndex = block.data.noteIndex}
    end
    return data
end

function appCreateSpritesFromPlaneData()
    local data = app.planesData[app.currentPlane]
    if data == nil or #data == 0 then
        if app.currentPlane == 1 then
            app.spritesHandler:createBlockOrNavigationBlock('block', 'changeDropper', app.maxXHalf, 17)
        else
            app.spritesHandler:createBlockOrNavigationBlock('block', 'dropper', app.maxXHalf, 17)
            app.spritesHandler:createBlockOrNavigationBlock('block', 'planeTunnel', app.maxXHalf, 380)
        end
    else
        for i = 1, #data do
            local block = data[i]
            app.spritesHandler:createBlockOrNavigationBlock('block', block.subtype, block.x, block.y, block.rotationIndex, nil, block.noteIndex)
        end
    end
end

function appCreateSampleBlocks()
    app.spritesHandler:createBlockOrNavigationBlock('block', 'dropperPlus', app.maxXHalf + 86, 20, 1)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'dropperPlus', app.maxXHalf + 36, 20, 1)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'normalBlock', app.maxXHalf, 140, 2)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'lockedBlock', app.maxXHalf + 60, 220, 7)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'bouncerBlock', app.maxXHalf, 280, 2)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'dropperMinus', app.maxXHalf - 90, 50, 1)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'dropperMinus', app.maxXHalf + 130, 50, 1)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'normalBlock', app.maxXHalf - 90, 280, 6)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'normalBlock', app.maxXHalf - 60, 380, 7)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'normalBlock', app.maxXHalf + 90, 280, 4)
    app.spritesHandler:createBlockOrNavigationBlock('block', 'normalBlock', app.maxXHalf + 150, 280, 6)
end

function appDefineTranslatedImages()
end

function appDefineImagesWhichFillScreen()
    local padSize = misc.getIf( appGetIsRetinaPad(), {width = 768 * 2, height = 1024 * 2}, {width = 768, height = 1024} )
    for planeI = 1, app.planesMax do
        app.imagesWhichFillScreen[planeI] = {imageName = 'plane-background/' .. planeI, width = padSize.width, height = padSize.height}
    end
end

function appRemoveOldestSlowly(spriteType)
    for id, sprite in pairs(app.sprites) do
        if sprite.type == spriteType and (sprite.energySpeed == nil or sprite.energySpeed >= 0) and not sprite.gone then
            sprite.energySpeed = -1
            sprite.alphaChangesWithEnergy = true

            if spriteType == 'ball' then
                local back = appGetSpriteByTypeAndParentId('ballBack', sprite.id)
                if back ~= nil then
                    back.energySpeed = sprite.energySpeed
                    back.alphaChangesWithEnergy = sprite.alphaChangesWithEnergy
                end
                break
            end
        end
    end
end

function appMoveNearBlocksInDirection(field)
    local directionX, directionY = appGetBaseDirection(field)
    local fieldRectangle = {x = field.x, y = field.y, width = 27, height = 27, rotation = 45}
    local sprites = appGetRectanglesNearby('block', fieldRectangle, 12)
    for i = 1, #sprites do
        local sprite = sprites[i]
        if not sprite.isSensor and sprite.subtype ~= 'horizontalMover' and sprite.phase.name == 'default' then -- not sprite.isSensor and 
            sprite.speedX = directionX
            sprite.speedY = directionY
            sprite.alsoAllowsExtendedNonPhysicalHandling = true
            sprite.phase:set('movingAway', app.smallPhaseUnitFrames * 4, 'movingBack')
        end
    end
end

function appBlowAwayBalls(x, y)
    local inverseStrength = 20
    local sprites = appGetSpritesByType('ball')
    for i = 1, #sprites do
        local sprite = sprites[i]
        local distance = misc.getDistance( {x = x, y = y}, sprite )
        if distance <= 40 then
            local power = app.magneticMaxValue / distance / inverseStrength
            local pushX = - ( (x - sprite.x) * power )
            local pushY = - ( (y - sprite.y) * power )
            sprite:applyForce(pushX, pushY, sprite.x, sprite.y)
        end
    end
end

function appGetBaseDirection(sprite)
    local directionX = 0
    local directionY = 0
    if sprite.rotation == 0 then directionY = -1
    elseif sprite.rotation == 90 then directionX = 1
    elseif sprite.rotation == 180 then directionY = 1
    elseif sprite.rotation == 270 then directionX = -1
    end
    return directionX, directionY
end

function appGetCollisionFilter(self)
    local filter = {}
    local categoryDefault =           '       X'
    local maskDefault =               ' XXXXXXX' -- collides with everything

    filter.categoryBits = categoryDefault
    filter.maskBits = maskDefault

    filter.categoryBits = misc.binaryToDecimal(filter.categoryBits, 'X')
    filter.maskBits = misc.binaryToDecimal(filter.maskBits, 'X')
    return filter
end

function appClass()
    app.title = 'Color Sound Machine'
    app.name = 'colorsoundmachine'
    app.version = '1.2'
    app.id = '454783374'
    app.runs = true
    app.defaultLanguage = 'en'
    app.language = appGetLanguage()

    app.showDebugInfo = false -- false
    app.isLocalTest = false -- false
    app.doPlaySounds = true -- true

    app.device = system.getInfo('model')
    app.isIOs = app.device == 'iPad' or app.device == 'iPhone'
    app.isAndroid = not app.isIOs

    app.showClock = false and app.showDebugInfo
    app.framesCounter = 0
    app.framesPerSecondGoal = 30
    app.maxRotation = 360
    app.secondInMs = 1000
    app.secondsCounter = 0
    app.minutesCounter = 0

    app.importantSoundsToCache = {}

    app.cachedSounds = {}
    app.musicChannel = 1
    app.debugCounter = 0
    app.recentlyPlayedSounds = {}

    app.translatedImages = {}

    app.phase = phaseModule.phaseClass()
    app.phase:set('default')

    app.planePhase = phaseModule.phaseClass()
    app.planePhase:set('default')

    app.minX = 0
    app.maxX = 320
    app.minY = 0
    app.maxY = 480
    app.maxXHalf = math.floor(app.maxX / 2)
    app.maxYHalf = math.floor(app.maxY / 2)

    app.sprites = {}

    appSetFont( {'Trebuchet MS', 'Helvetica'}, 'trebuc' )

    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()

    app.idInStore = 'com.versuspad.' .. app.name
    -- com.versuspad.colorsoundmachine.premium
    app.productIdPrefix = app.idInStore .. '.'
    app.products = { { id = appPrefixProductId('premium'), isPurchased = false } }
    -- app.products = { { id = 'android.test.purchased', isPurchased = false } }

    app.gameOver = false

    app.rotationWeakest = .0001
    app.rotationWeak = 10
    app.rotationStrong = 30
    app.rotationExtraStrong = 65

    app.largeImageSuffix = '@2x'
    app.deviceResolution = {width = nil, height = nil}
    appSetDeviceResolution()
    app.imagesWhichFillScreen = {}

    app.blocksPerNavigationPage = 6

    app.blockSubtypes = {
        'normalBlock', 'bouncerBlock', 'lockedBlock', 'horizontalMover', 'dryBlock', 'dropper',
        'changeDropper', 'changeReverseDropper', 'dropperPlus', 'dropperMinus', 'speederBlock', 'slowerBlock',
        'planeBallDropper', 'bumpDropper', 'waitDropper', 'otherBlock', 'thinBlock', 'flipBlock',
        'moverField', 'allBlock', 'swirl', 'planeTunnel'
    }
    app.premiumBlocks = {'swirl', 'allBlock', 'planeTunnel'}

    app.blockWidth = 34
    app.dropBallCounter = 1
    app.currentNavigationPage = 1
    app.yConsideredBottomArea = 414
    app.maxBlocksToPlace = 80
    app.maxBallsToDrop = 50
    app.blockDidntLeaveBottomAreaInRow = 0
    app.machineIdsToDeleteSoon = {}

    app.spritesCount = 0

    app.notesMax = 12
    app.basePitch = 3
    app.planesMax = 5
    app.smallPhaseUnitFrames = 25
    app.blockDistanceConsideredNear = 50

    app.notes = {}
    app.notes['minorPentanonic'] = {1, 4, 6, 8, 11}
    app.notes['majorPentanonicSelection'] = {3, 5, 10}
    app.notes['all'] = {}
    app.notes['planes'] = {}
    app.notes['planesInNotes'] = {'default', 2, 4, 8, 7}
    for i = 1, app.notesMax do app.notes['all'][i] = i end
    for i = 1, app.planesMax do app.notes['planes'][i] = 'planeTunnel-' .. i end

    app.currentPlane = 1
    app.planesData = {}   
    app.currentSavedId = nil
    app.currentLoadMachinePage = nil

    app.baseInstrument = 'neon-koto'
    app.planeInstrument = {
            {name = 'soft-analog', pitch = app.basePitch},
            {name = 'fuel-cells', pitch = app.basePitch + 1},
            {name = 'warming-waves', pitch = app.basePitch},
            {name = 'stratosphere', pitch = app.basePitch + 1},
            {name = 'playful-melody', pitch = app.basePitch}
            }
    app.framesMoverBlocksMoveInOneDirection = 120
    app.magneticMaxValue = misc.getDistance( {x = 0, y = 0}, {x = app.maxX, y = app.maxY} )

    app.defaultDensity = 1
    app.defaultBounce = 0.2
    app.defaultFriction = 0.3

    app.groupsToHandleEvenWhenPaused = {'menu', 'menuButton', 'news'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()

    app.newsDialog = nil
end

init()
