require('physics')
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
url = require("socket.url")
specialRooms = require('special-rooms')
require('app-misc')
require('app-purchasing')
require('sqlite3')

app = {}

function init()
    misc.initDefaults()
    appClass()
    appClearConsole()
    app.data:open()
    appInitDresses()
    appLoadData()
    appDefineImagesWhichFillScreen()
    appInitItems()
    appInitMusicData()
    app.news:verifyNeededFunctionsAndVariablesExists()
    -- if app.isLocalTest then app.sector = 'topTunnel' end -- 'water', 'topTunnel'
    audio.setVolume( misc.getIf(app.doPlayBackgroundMusic, 1, 0), {channel = app.musicChannel} )

    app.phase:set('introQuote')

    Runtime:addEventListener('enterFrame', appHandleAll)
    timer.performWithDelay(app.secondInMs, handleClock)
end
 
function appPause()
    if app.runs then
        physics.pause()
        system.setIdleTimer(true)
        app.runs = false
    end
end

function appResume()
    if not app.runs then
        physics.start()
        if app.doPlayBackgroundMusic then audio.fade( {channel = app.musicChannel, time = 500, volume = 1} ) end
        system.setIdleTimer(false)
        appRemoveSpritesByGroup('menu')
        app.runs = true
    end
end

function appRestart()
    appClearState()
    appStart()
    appResume()
end

function appCreateSprites()
    appCreateClock(maxXHalf, 10, nil, nil, 25, .75)
    appCreateDebug(app.maxXHalf, 20, nil, nil, 16, .85)
    app.menu:createOpenButton()
    app.spritesHandler:createScore()
    appIncludeLetterboxBars()
end

function appClearState()
    app.score = 0
    app.roomNumber = 0
    app.lastBackground = 1
    app.introStoryPage = 1
    app.wasTimeOut = false
    app.restartWhenResumed = false

    app.gameClock.secondsLeftOld = nil
    app.gameClock.secondsLeft = app.gameClock.secondsLeftAtStart

    app.hadBattleCryThisRoom = false
    app.sector = 'default'
    audio.setVolume( misc.getIf(app.doPlayBackgroundMusic, 1, 0), {channel = app.musicChannel} )

    appRemoveSprites()
    app.phase = phaseModule.phaseClass()
    app.phase:set('default')
end

function appStart()
    app.phase:set('default')
end

function appPlayNextMusic()
    local i = 1
    if app.musicOrder[i] == nil then appInitMusic() end -- should be appInitMusicData() I think, seems to be bug in live version!
    if app.musicOrder[i] ~= nil then
        local soundName = table.remove(app.musicOrder, i)
        local doPlayMusicAsStream = false
        appPlaySound('theme/' .. soundName, app.musicChannel, nil, appPlayNextMusic, doPlayMusicAsStream)
    end
end

function appHandlePhases()
    app.phase:handleCounter()
    app.extraPhase:handleCounter()
    -- appDebug( app.extraPhase:getInfo() )

    if app.phase.name == 'introQuote' then
        if not app.phase:isInited() then
            if not app.skipQuoteForTest then
                app.spritesHandler:createCenteredBuddhaQuote()
            end
            app.startedInMicroseconds = system.getTimer()
            local delayToLetQuoteOrientate = 100
            app.phase:setNext('loadSound', delayToLetQuoteOrientate)
        end

    elseif app.phase.name == 'loadSound' then
        if not app.phase:isInited() then
            local minSecondsToDisplayQuote = 3
            appInitSound()
            appInitPurchases()
            local tookSeconds = ( system.getTimer() - app.startedInMicroseconds ) * .001

            if tookSeconds >= minSecondsToDisplayQuote or app.skipQuoteForTest then
                app.phase:set('default')
            else
                local secondsToDelay = math.ceil(minSecondsToDisplayQuote - tookSeconds)
                app.phase:setNext('default', nil, secondsToDelay)
            end
        end

    elseif app.phase.name == 'default' then
        if not app.phase:isInited() then
            app.wasTimeOut = false

            app.runsSinceAppStart = app.runsSinceAppStart + 1
            if app.runsSinceAppStart == 1 then app.news:handle() end

            if app.introStoryPage == 1 then appRemoveSprites() end
            if app.skipIntroForTest then
                app.phase:set('newRoom')
            else
                audio.setVolume( 0, {channel = app.musicChannel} )
                display.setDefault('background', 0, 0, 0)
                app.spritesHandler:showIntroStoryPage(app.introStoryPage)

                local function onSoundComplete()
                    if app.phase.name == 'default' then
                        if app.introStoryPage < app.maxStoryPages then
                            app.introStoryPage = app.introStoryPage + 1
                            app.phase:set('default')
                        else
                            app.phase:set('newRoom')
                        end
                    end
                end

                local soundName = 'introStory/' .. app.introStoryPage
                appPlaySound(soundName, nil, nil, onSoundComplete)

                if app.introStoryPage == 1 then
                    app.spritesHandler:createTextWithShadow( '(TAP TO SKIP)', {x = app.maxXHalf, y = app.maxY - 20}, 27, 600, nil, nil, true )
                end
            end
        end

    elseif app.phase.name == 'newRoom' then
        if not app.phase:isInited() then
            collectgarbage('collect')
            app.extraPhase:set('default')
            app.bombsLeft = app.bombsPerRoom
            app.secondsLeftOld = nil
            if app.isIOs then display.setDefault('background', 172, 81, 32) end

            app.hadBattleCryThisRoom = false
            app.roomNumber = app.roomNumber + 1
            if app.roomNumber == 1 then
                if app.doPlayBackgroundMusic then audio.setVolume( 1, {channel = app.musicChannel} ) end
                appPlayNextMusic()
            end

            if app.sectorNext ~= nil then
                app.sector = app.sectorNext
                app.sectorNext = nil
            end

            if app.sector ~= app.sectorOld then
                if app.sector == 'water' then
                    physics.setGravity(0, 3)
                else
                    physics.setGravity(app.gravityX, app.gravityY)
                end

                app.sectorChangedAtRoomNumber = app.roomNumber
                app.sectorOld = app.sector
            end

            app.hadSlowMotionThisRoom = false
            appRemoveSprites()
            app.spritesHandler:createRoom()
            appCreateSprites()
            app.spritesHandler:createControls()
            -- appCreateStatus()
        end

        if app.extraPhase.name ~= 'slowMotion' then
            app.gameClock.framesCounter = app.gameClock.framesCounter + 1
            if app.gameClock.framesCounter >= app.framesPerSecondGoal then
                app.gameClock.secondsLeft = app.gameClock.secondsLeft - 1
                if app.gameClock.secondsLeft < 0 then app.gameClock.secondsLeft = 0 end
                app.gameClock.framesCounter = 0
            end
        end

        if app.gameClock.secondsLeft <= 10 and app.phase.nameNext ~= 'gameOver' then
            if app.gameClock.secondsLeftOld == nil or app.gameClock.secondsLeft ~= app.gameClock.secondsLeftOld then
                app.spritesHandler:createCountDownMessage(app.gameClock.secondsLeft)
                app.gameClock.secondsLeftOld = app.gameClock.secondsLeft
            end

            if app.gameClock.secondsLeft <= 0 then app.phase:set('timeOut') end
        end

    elseif app.phase.name == 'timeOut' then
        if not app.phase:isInited() then
            app.wasTimeOut = true
            if app.sector == 'default' then
                appRemoveSpritesByType( {'textMessage', 'bomb', 'bombShard', 'control', 'countDownMessage'} )
                appCreateNinjasMakeGirlEscapeSequence()
                app.phase:setNext('gameOver', 110)
            else
                app.phase:set('gameOver')
            end
        end

    elseif app.phase.name == 'gameOver' then
        if not app.phase:isInited() then
            appRemoveSpritesByType( {'textMessage', 'bomb', 'bombShard', 'control', 'countDownMessage'} )
            app.spritesHandler:createGameOverScreen()
            appSaveData()
        end
    end

    if app.extraPhase.name == 'default' then
        if not app.extraPhase:isInited() then
            if app.doPlayBackgroundMusic then audio.setVolume( 1, {channel = app.musicChannel} ) end
            if audio.isChannelPlaying(app.soundChannelHeartbeat) and app.hadSlowMotionThisRoom then
                -- audio.stop()
            end
            app.doHandleSprites = true
            physics.start()
            appRemoveSpritesByType('cloneImage')
        end

    elseif app.extraPhase.name == 'slowMotion' then
        if not app.extraPhase:isInited() then
            if app.doPlayBackgroundMusic then audio.setVolume( .2, {channel = app.musicChannel} ) end
        end
        app.doHandleSprites = app.extraPhase.counter % 5 == 0
        if not app.doHandleSprites then physics.pause()
        elseif app.doHandleSprites then physics.start()
        end

    elseif app.extraPhase.name == 'earthquake' then
        if not app.extraPhase:isInited() then
            appPlaySound('earthquake')
            system.vibrate()
            app.extraPhase:setNext('earthquakeEnds', 55)
            for i = 1, 15 do
                app.spritesHandler:createShard( 'room', math.random(app.minX, app.maxX), math.random(app.minY, app.maxY), nil, nil, true )
            end
        end
        appShakeAllRelevantSprites()

    elseif app.extraPhase.name == 'earthquakeEnds' then
        if not app.extraPhase:isInited() then
            appShakeAllRelevantSprites(0)
        end
        
    end

    app.extraPhase:handleCounter()
end

function appCreateNinjasMakeGirlEscapeSequence()
    local ninjaDirection = -1
    local girl = appGetSpriteByType('girl')
    if girl ~= nil then
        ninjaDirection = misc.getIf(girl.x < app.maxXHalf, -1, 1)
        app.spritesHandler:createGirlEscapesFromNinjas(girl, ninjaDirection)
        girl.gone = true
    end
    app.spritesHandler:createNinjas(ninjaDirection)
end

function appShakeAllRelevantSprites(offsetMax)
    if offsetMax == nil then offsetMax = 4 end
    if misc.getChance(75) then
        local unaffectedSpriteTypes = {'menuButton', 'girl', 'shard', 'bomb', 'bombShard', 'spikeball', 'control', 'girlDust', 'fire', 'smoke'}
        local offsetX = math.random(-offsetMax, offsetMax)
        local offsetY = math.random(-offsetMax, offsetMax)
        for id, sprite in pairs(app.sprites) do
            if not misc.inArray(unaffectedSpriteTypes, sprite.type) and sprite.displayType ~= 'text' then
                sprite.x = sprite.originX + offsetX
                sprite.y = sprite.originY + offsetY
            end
        end
    end
end

function appLoadData()
    app.highestAllTimeScore = app.data:get('highestAllTimeScore', 0)
    app.diamondsOwned = app.data:get('diamondsOwned', 0)

    for i = 1, #app.dress do
        app.dress[i].isOwned = app.data:getBool('dress' .. i .. 'Owned', app.dress[i].isOwned)
    end
    app.currentDress = app.data:get('currentDress', 1)

    app.doPlayBackgroundMusic = app.data:getBool('doPlayBackgroundMusic', true)
end

function appSaveData()
    if app.score > app.highestAllTimeScore then app.highestAllTimeScore = app.score end
    app.data:set('highestAllTimeScore', app.highestAllTimeScore)
    app.data:set('diamondsOwned', app.diamondsOwned)

    for i = 1, #app.dress do
        app.data:setBool('dress' .. i .. 'Owned', app.dress[i].isOwned)
    end
    app.data:set('currentDress', app.currentDress)

    app.data:setBool('doPlayBackgroundMusic', app.doPlayBackgroundMusic)
end

function appToggleBackgroundMusic()
    app.doPlayBackgroundMusic = not app.doPlayBackgroundMusic
    audio.setVolume( misc.getIf(app.doPlayBackgroundMusic, 1, 0), {channel = app.musicChannel} )
    appSaveData()

    app.menu:createPageMain()
end

function appGetRandomRoomMap()
    local map = {}; local roofHeight = nil; local groundHeight = nil
    local backgroundImage = nil; local backgroundIsAnimated = nil

    local specialSectorRoomsInRow = misc.getIf(app.sector == 'water', 2, 3)
    local includeSectorArrow = app.sector ~= 'default' and app.sectorChangedAtRoomNumber ~= nil and
            app.roomNumber - app.sectorChangedAtRoomNumber >= specialSectorRoomsInRow
    local isFirstSinceSectorChange = app.roomNumber == app.sectorChangedAtRoomNumber
    local isSecondSinceSectorChange = app.roomNumber - 1 == app.sectorChangedAtRoomNumber

    if app.lastGirlPosition.x == nil or app.lastGirlPosition.y == nil then
        app.lastGirlPosition.x = app.maxX
        app.lastGirlPosition.y = 335
    end

    local girlMapX = misc.getIf(app.lastGirlPosition.x > app.maxXHalf, 1, app.mapMaxX)
    if app.sector ~= 'default' then girlMapX = 1 end

    if app.sector == 'water' then
        map, roofHeight, groundHeight, backgroundIsAnimated = appGetRandomRoomMapSectorWater(includeSectorArrow, isFirstSinceSectorChange)

    elseif app.sector == 'topTunnel' then
        map, roofHeight, groundHeight, backgroundIsAnimated = appGetRandomRoomMapSectorTopTunnel(includeSectorArrow, isFirstSinceSectorChange)

    else
        roofHeight = 10; groundHeight = 14
        backgroundIsAnimated = false
        local bitOfTimePassedSinceLastSpecialRoom = app.specialRoomShownAtRoomNumber == nil or
                app.roomNumber - app.specialRoomShownAtRoomNumber >= 2
        local isTest = false
        if isTest or ( app.roomNumber >= 6 and misc.getChance(25) and bitOfTimePassedSinceLastSpecialRoom ) then
            app.specialRoomShownAtRoomNumber = app.roomNumber
            map = specialRooms.getMap(girlMapX ~= 1)
            if girlMapX ~= 1 then map = appMirrorMap(map) end
        elseif app.roomNumber == 1 then
            map = appGetMapIntroRoom(girlMapX)
        else
            map = appGetRandomRoomMapSectorDefault(isFirstSinceSectorChange, isSecondSinceSectorChange, girlMapX)
        end

    end

    local i = 1
    if app.lastBackground ~= nil then i = misc.getIf(app.lastBackground == 1, 2, 1) end
    backgroundImage = 'background/' .. app.sector .. '/' .. i
    app.lastBackground = i

    if app.sector == 'default' then map = appAddWindowToRoomIfNoCrashablesPresent(map) end

    return map, roofHeight, groundHeight, backgroundImage, backgroundIsAnimated
end

function appAddWindowToRoomIfNoCrashablesPresent(map)
    local containsCrashables = appRoomHasType( map, {'table', 'vase', 'window', 'randomItem'} )
    if not containsCrashables then
        local maxWindowsToAdd = math.random(1, 3)
        for i = 1, maxWindowsToAdd do
            local windowAdded = false
            local tries = 0
            while not windowAdded and tries <= 1000 do
                local x = math.random(1, app.mapMaxX); local y = math.random(1, app.mapMaxY)
                if not map[x][y].hasBlock then
                    map[x][y].backgroundItem = 'window'
                    windowAdded = true
                end
            end
        end
    end
    return map
end

function appRoomHasType(map, typeOrTypes)
    local hasType = false
    typeOrTypes = misc.toTable(typeOrTypes)
    for x = 1, app.mapMaxX do
        for y = 1, app.mapMaxY do
            local part = map[x][y]
            if misc.inArray(typeOrTypes, part.item) or misc.inArray(typeOrTypes, part.backgroundItem) then
                hasType = true
                break
            end
        end
    end
    return hasType
end

function appGetRandomRoomMapSectorDefault(isFirstSinceSectorChange, isSecondSinceSectorChange, girlMapX)
    local map = appInitMap()
    local backgroundIsAnimated = false

    local girlMapY = nil
    if app.lastGirlPosition.y - app.girlHeight / 2 <= map[1][2].y then girlMapY = 1
    elseif app.lastGirlPosition.y - app.girlHeight / 2 <= map[1][3].y then girlMapY = 2
    else girlMapY = 3
    end

    local timeNearingEnd = app.gameClock.secondsLeft <= 20

    map[girlMapX][girlMapY].hasGirl = true
    map[girlMapX][girlMapY].hasFloor = true

    for gridPlaceY = 1, app.mapMaxY do
        for gridPlaceX = 1, app.mapMaxX do
            local part = map[gridPlaceX][gridPlaceY]
            if not part.hasFloor then part.hasFloor = misc.getChance(40) end
        end
    end
    map = appMapEnsureOnePassageInFloor(map, girlMapX, girlMapY)

    local isTest = false
    local isEasierRoom = app.roomNumber == 2 and misc.getChance(90)
    local roomHasDiamond = false

    for y = 1, app.mapMaxY do
        for x = 1, app.mapMaxX do
            local part = map[x][y]
            local hasFloorAbove = y == 1 or map[x][y - 1].hasFloor

            if not part.hasGirl then
                if y >= 2 and part.hasFloor and not hasFloorAbove and misc.getChance(35) then
                    part.hasBlock = true
                end
    
                if misc.getChance(80) then
                    if x == 1 then part.hasWallLeft = true
                    elseif x == app.mapMaxX then part.hasWallRight = true
                    end
                end

                local addMiddleWall = misc.getChance(9) and x ~= 1 and x ~= app.mapMaxX
                if addMiddleWall then
                    if misc.getChance() then part.hasWallLeft = true
                    else part.hasWallRight = true
                    end
                end

                if part.hasFloor then

                    if misc.getChance(40) then
                        if y >= 2 and not map[x][y - 1].hasFloor then
                            if misc.getChance(65) then part.item = 'tableWithVases'
                            elseif misc.getChance(60) then part.item = 'highTableWithVases'
                            else part.item = 'table'
                            end
                        elseif misc.getChance(30) then
                            part.item = 'vases'
                        end

                    else

                        local isEdge = (x == 1 or x == app.mapMaxX) and (y == 1 or y == app.mapMaxY)
                        if isEdge and ( (app.roomNumber >= 7 or isTest) and misc.getChance(12) ) and not part.hasBlock and
                                not (isFirstSinceSectorChange or isSecondSinceSectorChange) then
                            part.item = 'sectorArrow' .. misc.getIf(y == 1, 'Up', 'Down')

                        elseif not isEasierRoom then
                            local hasGirlDirectlyLeftOrRight =
                                    (x == app.mapMinX + 1 and map[app.mapMinX][y]) or
                                    (x == app.mapMaxX - 1 and map[app.mapMaxX][y])
                            if misc.getChance(30) and not hasGirlDirectlyLeftOrRight then
                                part.item = 'guard'
                            elseif not part.hasBlock then
                                if not roomHasDiamond and app.roomNumber >= 4 and misc.getChance(10) then
                                    part.item = 'diamond'
                                    roomHasDiamond = true

                                elseif isEdge and misc.getChance(30) then
                                    part.item = 'cannonTowards' .. misc.getIf(x == 1, 'Right', 'Left')

                                elseif timeNearingEnd and misc.getChance(25) then
                                    part.item = 'clock'

                                elseif misc.getChance(70) then
                                    local items = {'bladeBottom', 'bladeBottom', 'spikeball', 'spikeball', 'spikeball'}
                                    if hasFloorAbove then
                                        for itemI = 1, 2 do items[#items + 1] = 'bladeTop' end
                                    end
                                    part.item = misc.getRandomEntry(items)

                                elseif misc.getChance(90) then
                                    part.item = 'randomItem'

                                end
                            end
                        end

                    end

                end
            end

            if part.hasFloor and (not part.hasBlock and part.item == nil) and misc.getChance(40) then
                part.backgroundItem = 'window'
            end
        end
    end

    if app.roomNumber == 2 then
        local helpX = 2; local helpY = 3
        map[helpX][helpY].item = misc.toTable(map[helpX][helpY].item)
        map[helpX][helpY].item[ #map[helpX][helpY].item + 1 ] = 'destroyHelp'
    end

    map = appMapRemoveDirectNeighborBlocks(map)
    map = appMapRemoveDirectNeighbors( map, {'guard'} )
    map = appRemoveMiddleWallWallNeighbors(map)
    if isEasierRoom then map = appEnsureNotTooManyCrashables(map) end
    return map
end

function appEnsureNotTooManyCrashables(map)
    local crashables = {'table', 'tableWithVases', 'highTableWithVases', 'window'}
    local maxTableOrVases = 3
    local tries = 0
    while appGetMapItemCount(map, crashables) > maxTableOrVases and tries <= 1000 do
        tries = tries + 1
        local x = math.random(1, #map); local y = math.random(1, #map[1])

        if misc.inArray(crashables, map[x][y].backgroundItem) then
            map[x][y].backgroundItem = nil
        else
            local items = misc.toTable(map[x][y].item)
            for i = 1, #items do
                if misc.inArray(crashables, items[i]) then
                    map[x][y].item = nil
                    break
                end
            end
        end

    end
    return map
end

function appGetMapItemCount(map, itemNames)
    local itemCount = 0
    for x = 1, #map do
        for y = 1, #map[x] do
            local partItems = misc.toTable(map[x][y].item)
            for i = 1, #partItems do
                if misc.inArray(itemNames, partItems[i]) then
                    itemCount = itemCount + 1
                end
            end
            if misc.inArray(itemNames, map[x][y].backgroundItem) then
                itemCount = itemCount + 1
            end
        end
    end
    return itemCount
end


function appEnsureMapHasTableOrVases(map)
    if not appGetMapHasItem( map, {'table', 'tableWithVases', 'highTableWithVases'} ) then
        local placedItem = false
        local tries = 0; local triesMax = 1000
        while tries <= triesMax and not placedItem do
            local part = map[ math.random(1, #map) ][ math.random(1, #map[1]) ]
            tries = tries + 1
            if part.item == nil and not part.hasGirl and part.hasFloor then
                part.item = 'tableWithVases'
                placedItem = true
            end
        end
    end
    return map
end

function appGetMapHasItem(map, itemNames)
    local hasItem = false
    for x = 1, #map do
        for y = 1, #map[x] do
            local partItems = misc.toTable(map[x][y])
            for i = 1, #partItems do
                if misc.inArray(itemNames, partItems[i]) then
                    hasItem = true
                    break
                end
            end
        end
    end
    return hasItem
end

function appGetTestMap()
    local map = appInitMap()
    local backgroundIsAnimated = false
    local girlMapX = 2

    local girlMapY = nil
    if app.lastGirlPosition.y - app.girlHeight / 2 <= map[1][2].y then girlMapY = 1
    elseif app.lastGirlPosition.y - app.girlHeight / 2 <= map[1][3].y then girlMapY = 2
    else girlMapY = 3
    end

    map[girlMapX][girlMapY].hasGirl = true
    map[girlMapX][girlMapY].hasFloor = true

    map[1][1].hasFloor = true
    map[1][2].hasFloor = true
    map[2][2].hasFloor = true
    map[4][2].hasFloor = true
    map[4][2].hasWallLeft = true

    map[1][1].item = 'doorButtonOpen'

    map[1][3].hasWallLeft = true
    map[4][3].hasWallRight = true

    map = appRemoveMiddleWallWallNeighbors(map)
    return map
end

function appMapEnsureRoomHasReachableOpenButtonIfNoExit(map)
    local hasExit = appMapHasExit(map)
    if not hasExit then
        local placedButton = false
        while not placedButton do
            local x = math.random(app.mapMinX, app.mapMaxX)
            local y = math.random(app.mapMinY, app.mapMaxY)
            if map[x][y].hasFloor and not map[x][y].hasGirl and not map[x][y].hasBlock then
                map[x][y].item = 'doorButtonOpen'
                placedButton = true
            end
        end
    end
    map = appMapEnsureNoMiddleWallsBlockOpenButton(map)
    return map
end

function appMapEnsureNoMiddleWallsBlockOpenButton(map)
    local simplifiedPathMap = appGetSimplifiedPathMap(map)
    local sourceX = 1; local sourceY = 5
    local targetX = 1; local targetY = 1
    local shortestPath = getShortestPath(simplifiedPathMap, sourceX, sourceY, targetX, targetY)

    return map
end

function appGetSimplifiedPathMap(map)
    local pathMap = {}
    for x = 1, 7 do
        pathMap[x] = {}
        for y = 1, 5 do
            pathMap[x][y] = app.enumGridWalkable
        end
    end

    for y = 1, 3 do
        local pathMapY = nil
        if y == 1 then pathMapY = 1
        elseif y == 2 then pathMapY = 3
        elseif y == 3 then pathMapY = 5
        end
        if map[1][y].hasWallRight or map[2][y].hasWallLeft then pathMap[2][pathMapY] = app.enumGridUnwalkable end
        if map[2][y].hasWallRight or map[3][y].hasWallLeft then pathMap[4][pathMapY] = app.enumGridUnwalkable end
        if map[3][y].hasWallRight or map[4][y].hasWallLeft then pathMap[6][pathMapY] = app.enumGridUnwalkable end

        if y == 1 or y == 2 then
            if map[1][y].hasFloor then pathMap[1][pathMapY + 1] = app.enumGridUnwalkable end
            if map[2][y].hasFloor then pathMap[3][pathMapY + 1] = app.enumGridUnwalkable end
            if map[3][y].hasFloor then pathMap[5][pathMapY + 1] = app.enumGridUnwalkable end
            if map[4][y].hasFloor then pathMap[7][pathMapY + 1] = app.enumGridUnwalkable end

            if map[1][y].hasFloor and map[2][y].hasFloor then pathMap[2][pathMapY + 1] = app.enumGridUnwalkable end
            if map[2][y].hasFloor and map[3][y].hasFloor then pathMap[4][pathMapY + 1] = app.enumGridUnwalkable end
            if map[3][y].hasFloor and map[4][y].hasFloor then pathMap[5][pathMapY + 1] = app.enumGridUnwalkable end
        end
    end

    return pathMap
end

function appMapHasExit(map)
    local hasExit = false
    for y = 1, #map[1] do
        for x = 1, #map, #map - 1 do
            if not hasExit then
                local items = misc.toTable(map[x][y].item)
                local hasFallThingLeft = misc.inArray(items, 'fallBladeLeft') or misc.inArray(items, 'fallDoorLeft')
                local hasFallThingRight = misc.inArray(items, 'fallBladeRight') or misc.inArray(items, 'fallDoorRight')
                hasExit = ( x == 1 and not (map[x][y].hasWallLeft or hasFallThingLeft or misc.inArray(items, 'guard') ) ) or
                        ( x == #map and not (map[x][y].hasWallRight or hasFallThingRight or misc.inArray(items, 'guard') ) )
                if hasExit then break end
            end
        end
        if hasExit then break end
    end
    return hasExit
end

function appGetMapIntroRoom()
    local map = appInitMap()
    local backgroundIsAnimated = false

    local girlMapX = 2
    local girlMapY = 1
    map[girlMapX][girlMapY].hasGirl = true
    map[1][girlMapY].backgroundItem = 'breakingWindow'

    map[2][1].item = 'bladeTop'
    map[3][1].item = 'bladeTop'

    map[2][girlMapY].backgroundItem = 'window'
    map[3][girlMapY].backgroundItem = 'window'
    map[4][girlMapY].backgroundItem = 'window'

    map[1][1].hasWallLeft = true
    map[1][2].hasWallLeft = true
    map[1][3].hasWallLeft = true

    map[4][3].item = 'smallWallRight'
    map[2][3].item = 'introHelp'

    map = appRemoveMiddleWallWallNeighbors(map)
    return map
end

function appGetRandomRoomMapSectorTopTunnel(includeSectorArrow, isFirstSinceSectorChange)
    local map = {}
    local roofHeight = 113; local groundHeight = 115
    local gridStartX = 0; local gridStartY = groundHeight
    local gridWidth = 120; local gridHeight = 103
    local backgroundIsAnimated = false

    local maxY = 1
    map = appInitMap(app.mapMaxX, maxY, gridStartX, gridStartY, gridWidth, gridHeight)
    if includeSectorArrow == nil then includeSectorArrow = false end

    map[1][1].hasGirl = true

    local ticket = math.random(1, 13)
    local allFallBladesTicket = 8
    local diamondsTicket = 12
    if includeSectorArrow then ticket = diamondsTicket end

    if ticket == 1 then
        map[1][maxY].item = 'bladeTop'
        map[3][maxY].item = 'bladeTop'
        map[app.mapMaxX][maxY].item = 'spikeball'

    elseif ticket == 2 or ticket == 3 then
        map[4][maxY].item = 'spikeball'

    elseif ticket == 4 then
        map[2][maxY].item = 'spikeball'
        map[4][maxY].item = 'spikeball'

    elseif ticket == 5 then
        map[1][maxY].item = 'bladeTop'
        map[3][maxY].item = 'spikeball-slow'
        map[4][maxY].item = 'bladeBottom'

    elseif ticket == 6 then
        map[1][maxY].item = 'bladeTop'
        map[3][maxY].item = 'spikeball'
        map[4][maxY].item = 'spikeball-slow'

    elseif ticket == 7 then
        map[2][maxY].item = 'bladeBottom'
        map[3][maxY].item = 'bladeTop'
        map[4][maxY].item = 'bladeBottom'

    elseif ticket == allFallBladesTicket then
        for gridPlaceX = 1, app.mapMaxX do
            map[gridPlaceX][maxY].item = 'fallBlade'
        end

    elseif ticket == 9 then
        map[2][maxY].item = 'fallBlade'
        map[4][maxY].item = 'spikeball-slow'

    elseif ticket == 10 then
        map[1][maxY].item = 'fallBlade'
        map[3][maxY].item = 'spikeball'

    elseif ticket == 11 then
        map[1][maxY].item = 'fallBlade'
        map[2][maxY].item = 'fallBlade'
        map[3][maxY].item = 'bladeBottom'
        map[4][maxY].item = 'fallBlade'

    elseif ticket >= diamondsTicket then
        for gridPlaceX = 2, app.mapMaxX do
            map[gridPlaceX][maxY].item = 'diamonds'
        end
    end

    if includeSectorArrow then
        map[app.mapMaxX][maxY].item = 'sectorArrowDownFromTopTunnel'
    end

    if isFirstSinceSectorChange then
        for clockX = app.mapMaxX - 2, app.mapMaxX do
            local clockY = maxY
            map[clockX][clockY].item = misc.toTable(map[clockX][clockY].item)
            table.insert(map[clockX][clockY].item, 'clock')
        end
    end

    return map, roofHeight, groundHeight, backgroundIsAnimated
end

function appGetRandomRoomMapSectorWater(includeSectorArrow, isFirstSinceSectorChange)
    local map = {}
    local roofHeight = 10; local groundHeight = 14
    local gridStartX = 0; local gridStartY = groundHeight
    local gridWidth = 120; local gridHeight = 103
    local backgroundIsAnimated = true

    map = appInitMap(app.mapMaxX, app.mapMaxY, gridStartX, gridStartY, gridWidth, gridHeight)

    map[1][2].hasGirl = true

    if includeSectorArrow then
        for gridX = 3, #map do
            map[gridX][1].item = 'diamonds'
        end

    else
        for gridX = 2, #map do
            for gridY = 1, #map[gridX] do
                if misc.getChance(25) then map[gridX][gridY].item = 'diamonds' end
            end
        end

        if not isFirstSinceSectorChange then
            map[ math.random(app.mapMaxX - 1, app.mapMaxX) ][ math.random(1, app.mapMaxY) ].item = 'fish'
            if misc.getChance(70) then
                map[ math.random(app.mapMaxX - 1, app.mapMaxX) ][ math.random(1, app.mapMaxY) ].item = 'fish'
            end
        end
    
        if misc.getChance(75) or isFirstSinceSectorChange then
            if misc.getChance(50) or isFirstSinceSectorChange then
                map[app.mapMaxX][1].item = 'fish-slow'
                map[app.mapMaxX][app.mapMaxY].item = 'fish-slow'
            else
                map[app.mapMaxX][math.random(1, app.mapMaxY)].item = 'fish-slow'
            end
        end

    end

    if includeSectorArrow then
        map[app.mapMaxX][app.mapMaxY].item = 'sectorArrowUpFromWater'
    end

    if isFirstSinceSectorChange then
        for clockX = app.mapMaxX - 2, app.mapMaxX do
            local clockY = 2
            map[clockX][clockY].item = misc.toTable(map[clockX][clockY].item)
            table.insert(map[clockX][clockY].item, 'clock')
        end
    end

    return map, roofHeight, groundHeight, backgroundIsAnimated
end

function appInitMap(mapMaxX, mapMaxY, gridStartX, gridStartY, gridWidth, gridHeight)
    if mapMaxX == nil then mapMaxX = app.mapMaxX end
    if mapMaxY == nil then mapMaxY = app.mapMaxY end
    if gridStartX == nil then gridStartX = 0 end
    if gridStartY == nil then gridStartY = 11 end
    if gridWidth == nil then gridWidth = 120 end
    if gridHeight == nil then gridHeight = 103 end

    local map = {}
    for gridPlaceX = 1, mapMaxX do
        map[gridPlaceX] = {}
        for gridPlaceY = 1, mapMaxY do
            local x = gridStartX + (gridPlaceX - 1) * gridWidth
            local y = gridStartY + (gridPlaceY - 1) * gridHeight
            map[gridPlaceX][gridPlaceY] = {x = x, y = y, width = gridWidth, height = gridHeight,
                    hasFloor = gridPlaceY == mapMaxY and mapMaxY >= 2, floorLength = 0, hasBlock = false,
                    item = nil, backgroundItem = nil, hasGirl = false, isGround = gridPlaceY == mapMaxY,
                    hasWallLeft = false, hasWallRight = false, wallLengthLeft = 1, wallLengthRight = 1}
        end
    end
    return map
end

function appMapEnsureOnePassageInFloor(map, mustHaveFloorX, mustHaveFloorY)
    for gridPlaceY = 1, #map[1] - 1 do
        local foundPassage = false
        for gridPlaceX = 1, #map do
            local part = map[gridPlaceX][gridPlaceY]
            if not part.hasFloor then
                foundPassage = true
                break
            end
        end

        if not foundPassage then
            local builtPassage = false
            while not builtPassage do
                local thisX = math.random(1, #map); local thisY = gridPlaceY
                if not (thisX == mustHaveFloorX and thisY == mustHaveFloorY) then
                    map[thisX][thisY].hasFloor = false
                    builtPassage = true
                end
            end
        end
    end

    return map
end

function appMapRemoveDirectNeighborBlocks(map)
    local xMin = 2; local xMax = #map - 1; local xStep = 1
    if misc.getChance() then
        xMin, xMax = xMax, xMin
        xStep = xStep * -1
    end

    for n = 1, 2 do
        for gridPlaceY = 1, #map[1] do
            for gridPlaceX = 2, #map - 1 do
                local part = map[gridPlaceX][gridPlaceY]
                if part.hasBlock then
                    local partToLeft = map[gridPlaceX - 1][gridPlaceY]
                    local partToRight = map[gridPlaceX + 1][gridPlaceY]
                    if partToLeft.hasBlock then
                        if misc.getChance() then part.hasBlock = false
                        else partToLeft.hasBlock = false
                        end
                    elseif partToRight.hasBlock then
                        if misc.getChance() then part.hasBlock = false
                        else partToRight.hasBlock = false
                        end
                    end
                end
            end
        end
    end
    return map
end

function appMapRemoveDirectNeighbors(map, types)
    for n = 1, 2 do
        for i = 1, #types do
            local thisType = types[i]
            for gridPlaceY = 1, #map[1] do
                for gridPlaceX = 2, #map - 1 do
                    local part = map[gridPlaceX][gridPlaceY]
                    if part.item == thisType then
                        local partToLeft = map[gridPlaceX - 1][gridPlaceY]
                        local partToRight = map[gridPlaceX + 1][gridPlaceY]
                        if partToLeft.item == thisType or partToRight.item == thisType then
                            part.item = nil
                        end
                    end
                end
            end
        end
    end
    return map
end

function appMirrorMap(map)
    for gridX = 1, #map do
        for gridY = 1, #map[gridX] do
            local part = map[gridX][gridY]
            if (part.hasWallLeft and not part.hasWallRight) or (part.hasWallRight and not part.hasWallLeft) then
                part.hasWallLeft, part.hasWallRight = part.hasWallRight, part.hasWallLeft
            end
        end
    end

    local mapClone = misc.cloneTable(map)
    for gridY = 1, #map[1] do
        for gridX = 1, #map do
            local mirrorX = #map - gridX + 1
            -- why can't I copy all with map[gridX][gridY] = mapClone[mirrorX][gridY] ?

            local part = map[gridX][gridY]
            part.item = mapClone[mirrorX][gridY].item

            if type(part.item) == 'table' then
                for n = 1, #part.item do
                    if part.item[n] == 'fallDoorLeft' then part.item[n] = 'fallDoorRight'
                    elseif part.item[n] == 'fallDoorRight' then part.item[n] = 'fallDoorLeft'
                    end

                    if part.item[n] == 'fallBladeLeft' then part.item[n] = 'fallBladeRight'
                    elseif part.item[n] == 'fallBladeRight' then part.item[n] = 'fallBladeLeft'
                    end
                end
            end

            part.hasFloor = mapClone[mirrorX][gridY].hasFloor
            part.hasBlock = mapClone[mirrorX][gridY].hasBlock
            part.hasWallLeft = mapClone[mirrorX][gridY].hasWallLeft
            part.hasWallRight = mapClone[mirrorX][gridY].hasWallRight
            part.hasGirl = mapClone[mirrorX][gridY].hasGirl
            part.backgroundItem = mapClone[mirrorX][gridY].backgroundItem
        end
    end

    return map
end

function appAddDestructionToScore(spriteDestroyed)
    if app.phase.name == 'newRoom' then
        local addition = 0; local moreAddition = ''
        if spriteDestroyed.type == 'window' then addition = 5
        elseif spriteDestroyed.type == 'table' then addition = 5
        elseif spriteDestroyed.type == 'vase' and spriteDestroyed.subtype == 'silver' then addition = 10
        elseif spriteDestroyed.type == 'vase' and spriteDestroyed.subtype == 'gold' then addition = 20
        elseif spriteDestroyed.type == 'item' then addition = 30
        elseif spriteDestroyed.type == 'diamond' then addition = 50; moreAddition = ' +1D'
        end
        app.score = app.score + addition
        local text = '+$' .. addition .. moreAddition
        app.spritesHandler:createScoredText( {x = spriteDestroyed.x, y = spriteDestroyed.y}, text, nil, false )
    end
end

function appGirlIsHit()
    local girl = appGetSpriteByType('girl')
    if girl ~= nil then
        audio.stop(app.soundChannelFootsteps)
        appPlaySound('girlIsHit')
        app.spritesHandler:createShards(girl, nil, true)
        app.spritesHandler:createGirlGhost(girl)
        girl.gone = true
        app.phase:setNext('gameOver', 60)
    end
end

function appInitItems()
    app.items = {
            {name = 'bathtub', width = 80, height = 60},
            {name = 'tv', width = 57, height = 50},
            {name = 'painting', width = 53, height = 74},
            {name = 'console', width = 67, height = 54},
            {name = 'temple', width = 82, height = 70},
            {name = 'bigVase', width = 69, height = 57},
            }
end

function appInitMusicData()
    app.musicOrder[#app.musicOrder + 1] = '1'
    local lastVariationI = nil
    for i = 1, 1000 do
        local variationI = nil
        while variationI == nil or variationI == lastVariationI do variationI = math.random(1, app.maxThemes) end
        local repeatsMax = misc.getIf(variationI == 1, 1, 2)
        for repeats = 1, repeatsMax do
            app.musicOrder[#app.musicOrder + 1] = variationI
        end
        if misc.getChance(18) then app.musicOrder[#app.musicOrder + 1] = 'filler' end
        lastVariationI = variationI
    end
end

function appStartSlowMotionIfMeetsRequirements()
    if not app.hadSlowMotionThisRoom and app.roomNumber >= 3 and app.extraPhase.name == 'default' then
        app.extraPhase:set('slowMotion', 150, 'default')
        appPlaySound('heartbeat', app.soundChannelHeartbeat)
        appPlaySound('battleCryAndWhoosh')
        local addition = 50
        app.spritesHandler:createTextWithShadow( 'SLOW MOTION BONUS $' .. addition .. '!', {x = app.maxXHalf, y = app.maxYHalf}, 35 )
        app.score = app.score + addition
        app.hadSlowMotionThisRoom = true
        app.hadBattleCryThisRoom = true
    end
end

function appShowMessageIfRoomFullyCleared()
    if app.phase.name == 'newRoom' and (app.phase.nameNext == nil or app.phase.nameNext == 'newRoom') and app.sector == 'default' then
        local vasesAndTableCount = appGetSpriteCountByType( {'vase', 'table'} )
        local wholeItemCount = appGetSpriteCountByType('item', 'whole')
        local windowCount = appGetSpriteCountByType('window', 'whole')
        if vasesAndTableCount + wholeItemCount + windowCount == 0 then
            appRemoveSpritesByType('textMessage')
            local bonusSeconds = 5
            app.spritesHandler:createTextWithShadow( '100% DESTROYED! T+' .. bonusSeconds,
                    {x = app.maxXHalf, y = app.maxYHalf}, 35, nil, nil, 'allDestroyed' )
            app.gameClock.secondsLeft = app.gameClock.secondsLeft + bonusSeconds
            if app.extraPhase.name == 'default' then app.extraPhase:set('earthquake') end
        end
    end
end

function appCheckIfRoomNeedsToBeLeft()
    if app.phase.name == 'newRoom' and (app.phase.nameNext == nil or app.phase.nameNext == 'newRoom') then
        local hasGirl = appGetSpriteCountByType('girl') > 0
        local bombsOnFire = appGetSpritesByPhase('onFire', 'bomb')
        local hasBombsOnFire = #bombsOnFire > 0
        local hasBombShards = appGetHealthySpriteCountByType('bombShard') > 0
        local hasDestroyedMessage = appGetHealthySpriteCountByType('textMessage', 'allDestroyed') > 0
        if not hasGirl and not hasBombsOnFire and not hasBombShards and (not hasDestroyedMessage or app.roomNumber == 1) then
            app.phase:set('newRoom')
        end
    end
end

function appRemoveMiddleWallWallNeighbors(map)
    for y = 1, #map[1] do
        for x = 2, #map - 1 do
            local part = map[x][y]
            local partLeft = map[x - 1][y]
            local partRight = map[x + 1][y]
            if part.hasWallLeft and partLeft.hasWallRight then
                if misc.getChance() then part.hasWallLeft = false else partLeft.hasWallRight = false end
            elseif part.hasWallRight and partRight.hasWallLeft then
                if misc.getChance() then part.hasWallRight = false else partRight.hasWallLeft = false end
            end
        end
    end
    return map
end

function appUniteAdjacentFloorsAndWalls(map)
    map = appUniteAdjacentFloors(map)
    map = appUniteVerticallyAdjacentWalls(map)
    return map
end

function appUniteAdjacentFloors(map)
    for x = 1, #map do
        for y = 1, #map[1] do
            local floorLength = 0
            for xOff = 0, #map - 1 do
                if x + xOff <= #map then
                    local part = map[x + xOff][y]
                    if part.hasFloor then
                        floorLength = floorLength + 1
                        if xOff >= 1 then part.hasFloor = false end
                    else
                        break
                    end
                end
            end
            map[x][y].floorLength = floorLength
        end
    end
    return map
end

function appUniteVerticallyAdjacentWalls(map)
    local uniteSideLeft = 1; local uniteSideRight = 2
    local min = uniteSideLeft; local max = uniteSideRight; local step = 1
    if misc.getChance() then min, max = max, min; step = -1 end
    
    for sideI = min, max, step do

        for x = 1, #map do
            for y = 1, #map[1] do

                if sideI == uniteSideLeft then
    
                    local wallLength = 0
    
                    for yOff = 0, #map[1] - 1 do
                        if y + yOff <= #map[1] then
                            local part = map[x][y + yOff]
                            local partLeft = nil
                            if x >= 2 then partLeft = map[x - 1][y + yOff] end

                            if part.hasWallLeft then
                                wallLength = wallLength + 1
                                if wallLength >= 2 then part.hasWallLeft = false end
                            elseif (partLeft ~= nil and partLeft.hasWallRight) then
                                wallLength = wallLength + 1
                                -- partLeft.hasWallRight = false
                            else
                                break
                            end
                        end
                    end

                    map[x][y].wallLengthLeft = wallLength

                else -- if sideI == uniteSideRight then

                    local wallLength = 0
    
                    for yOff = 0, #map[1] - 1 do
                        if y + yOff <= #map[1] then
                            local part = map[x][y + yOff]
                            local partRight = nil
                            if x < #map then partRight = map[x + 1][y + yOff] end

                            if part.hasWallRight then
                                wallLength = wallLength + 1
                                if wallLength >= 2 then part.hasWallRight = false end
                            elseif (partRight ~= nil and partRight.hasWallLeft) then
                                wallLength = wallLength + 1
                            else
                                break
                            end
                        end
                    end
    
                    map[x][y].wallLengthRight = wallLength

                end

            end
        end

    end

    return map
end

function appGetRandomBuddhaQuote()
    local quotes = {
            "A jug fills drop by drop.",
            "Better than a thousand hollow words, is one word that brings peace.",
            "Chaos is inherent in all compounded things. Strive on with diligence.",
            "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.",
            "Hatred does not cease by hatred, but only by love; this is the eternal rule.",
            "I never see what has been done; I only see what remains to be done.",
            "It is a man's own mind, not his enemy or foe, that lures him to evil ways.",
            "It is better to conquer yourself than to win a thousand battles.",
            "It is better to travel well than to arrive.",
            "Just as treasures are uncovered from the earth, so virtue appears from good deeds.",
            "The foot feels the foot when it feels the ground.",
            "The mind is everything. What you think you become.",
            "The only real failure in life is not to be true to the best one knows.",
            "The tongue is like a sharp knife. It kills without drawing blood.",
            "The way is not in the sky. The way is in the heart.",
            "Never fear what will become of you.",
            "There are only two mistakes one can make along the road to truth; not going all the way, and not starting.",
            "There has to be evil so that good can prove its purity above it.",
            "Doubt is a thorn that irritates and hurts; it is a sword that kills.",
            "Those who are free of resentful thoughts surely find peace.",
            "Three things cannot be long hidden: the sun, the moon, and the truth.",
            "To live a pure unselfish life, one must count nothing as one's own in the midst of abundance.",
            "Virtue is persecuted more by the wicked than it is loved by the good.",
            "We are shaped by our thoughts; we become what we think.",
            "When the mind is pure, joy follows like a shadow that never leaves.",
            "We are what we think. All that we are arises with our thoughts.",
            "With our thoughts, we make the world.",
            "You yourself, as much as anybody in the entire universe deserve your love and affection.",
            "You will not be punished for your anger, you will be punished by your anger.",
            "Thousands of candles can be lit from a single candle, and the life of the candle will not be shortened.",
            "Peace comes from within.",
            "To understand everything is to forgive everything.",
            "A dog is not considered a good dog because he is a good barker.",
            "You cannot travel the path until you have become the path itself.",
            "When you realize how perfect everything is you will tilt your head back and laugh at the sky.",
            "Believe nothing, no matter where you read it, unless it agrees with your own reason.",
            "Have compassion for all beings, rich and poor alike; each has their suffering.",
            "The whole secret of existence is to have no fear.",
            "Your work is to discover your work and then with all your heart to give yourself to it.",
            "To conquer oneself is a greater task than conquering others.",
            "Nothing ever exists entirely alone; everything is in relation to everything else.",
            "All wrong-doing arises because of mind.",
            "Ambition is like love, impatient both of delays and rivals.",
            "He is able who thinks he is able."
            }
    return misc.getRandomEntry(quotes)
end

function appDefineImagesWhichFillScreen()
    local padSize = misc.getIf( appGetIsRetinaPad(), {width = 1024 * 2, height = 768 * 2}, {width = 1024, height = 768} )
    for i = 1, app.maxStoryPages do
        app.imagesWhichFillScreen[#app.imagesWhichFillScreen + 1] =
                {imageName = 'introStory/' .. i, width = padSize.width, height = padSize.height}
    end
end

function appGetGirlDressName(sprite)
    -- app.currentDress = 3 -- for testing
    local v = app.dress[app.currentDress].name
    if sprite.data.wearsSwimsuit then
        v = misc.getIf(app.dress[app.currentDress].hasSpecialSwimsuit, v .. 'Swimsuit', 'swimsuit')
    end
    return v
end

function appInitDresses()
    app.dress = {
        {name = 'karate', title = 'Karate Dress', priceInDiamonds = 0,  hasSpecialSwimsuit = false, isOwned = true},
        {name = 'streetWear', title = 'Street Wear', priceInDiamonds = 100,  hasSpecialSwimsuit = false, isOwned = false},
        {name = 'redNinja', title = 'Red Ninja', priceInDiamonds = 300,  hasSpecialSwimsuit = false, isOwned = false},
        {name = 'blackNinja', title = 'Black Ninja', priceInDiamonds = 500,  hasSpecialSwimsuit = false, isOwned = false},
        {name = 'monk', title = "Monk's Robe", priceInDiamonds = 800,  hasSpecialSwimsuit = true, isOwned = false},
        {name = 'golden', title = 'Golden Armor', priceInDiamonds = 2000,  hasSpecialSwimsuit = false, isOwned = false}
    }
end

function appGetCollisionFilter(self)
    local filter = {}

    local categoryDefault =        '       X'
    local categoryDynamic =        '      X '
    local categoryGirl =           '     X  '

    local maskCollideWithAll =     ' XXXXXXX'
    local maskIgnoresDynamic =     ' XXXXX X'
    local maskOnlyHitsGirl =       '     X  '
    local maskIgnoresGirl =        ' XXXX XX'

    filter.categoryBits = categoryDefault
    filter.maskBits = maskCollideWithAll

    if self.type == 'spikeball' then
        filter.maskBits = maskIgnoresDynamic

    elseif self.type == 'bomb' or self.type == 'bombShard' then
        filter.maskBits = maskIgnoresGirl

    elseif self.type == 'girl' then
        filter.categoryBits = categoryGirl

    elseif self.type == 'cannonBall' then
        filter.maskBits = maskOnlyHitsGirl

    elseif misc.inArray( {'spikeball', 'table', 'guard', 'vase', 'blade', 'bomb'}, self.type ) then
        filter.categoryBits = categoryDynamic

    end

    filter.categoryBits = misc.binaryToDecimal(filter.categoryBits, 'X')
    filter.maskBits = misc.binaryToDecimal(filter.maskBits, 'X')
    return filter
end

function appClass()
    app.title = 'Karate Girl Destruction Run'
    app.name = 'karategirl'
    app.version = '1.2'
    app.id = '486428645'
    app.runs = true
    app.defaultLanguage = 'en'
    app.language = appGetLanguage()

    app.isLocalTest = false -- false
    app.showDebugInfo = true and app.isLocalTest
    app.doPlaySounds = true

    app.skipIntroForTest = false and app.isLocalTest
    app.skipQuoteForTest = false and app.isLocalTest
    app.showButtonSizes = false and app.isLocalTest

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

    app.maxStoryPages = 8
    app.maxThemes = 6
    app.importantSoundsToCache = {}
    app.importantSoundsToCache = {
            'battleCryAndWhoosh', 'colliding', 'collidingSoft', 'explosion', 'footsteps',
            'glassBreaking-1', 'glassBreaking-2', 'glassBreaking-3', 'whoosh',
            'windowBreaking-1', 'windowBreaking-2', 'woodBreaking-1', 'woodBreaking-2', 'theme/filler',
            }

    if not app.isLocalTest then
        for i = 1, app.maxThemes do
            app.importantSoundsToCache[#app.importantSoundsToCache + 1] = 'theme/' .. i
        end
        for i = 1, app.maxStoryPages do
            app.importantSoundsToCache[#app.importantSoundsToCache + 1] = 'introStory/' .. i
        end
    end

    app.cachedSounds = {}
    app.musicChannel = 1
    app.debugCounter = 0
    app.recentlyPlayedSounds = {}
    app.doPlayBackgroundMusic = true

    app.translatedImages = {}

    app.phase = phaseModule.phaseClass()
    app.phase:set('default')

    app.extraPhase = phaseModule.phaseClass()
    app.extraPhase:set('default')

    app.planePhase = phaseModule.phaseClass()
    app.planePhase:set('default')

    app.minX = 0
    app.maxX = 480
    app.minY = 0
    app.maxY = 320
    app.maxXHalf = math.floor(app.maxX / 2)
    app.maxYHalf = math.floor(app.maxY / 2)

    app.sprites = {}
    appSetFont( {'AcknowledgeTTBRK', 'Acknowledge TT BRK', 'Acknowledge TT'}, 'acknowtt' )

    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    
    app.idInStore = 'com.versuspad.' .. app.name
    app.productIdPrefix = app.idInStore .. '.'
    local productId = misc.getIf(app.isAndroid, 'diamondspack', 'diamondsPack')
    app.products = { { id = appPrefixProductId(productId), isPurchased = false } }

    app.largeImageSuffix = '@2x'
    app.deviceResolution = {width = nil, height = nil}
    appSetDeviceResolution()
    app.imagesWhichFillScreen = {}

    app.enemySettings = {}

    app.score = 0
    app.highestAllTimeScore = 0
    app.actualPlaneRotation = 0 -- .4
    app.lastGirlPosition = {x = nil, y = nil}
    app.lastBackground = nil
    app.doHandleSprites = true
    app.spriteTypesToHandleDuringSlowMotion = {'control', 'cloneImage', 'frameImage'}
    app.hadSlowMotionThisRoom = false
    app.gravityXPhysicsWorkaround = .9 -- 1.1
    app.gravityX = app.gravityXPhysicsWorkaround
    app.gravityY = 9.8

    app.roomNumber = 0
    app.sector = 'default'
    app.sectorOld = nil
    app.sectorChangedAtRoomNumber = nil
    app.specialRoomShownAtRoomNumber = nil
    app.sectorNext = nil
    app.introStoryPage = 1
    app.hadBattleCryThisRoom = false

    app.gridSize = 26
    app.brickHeight = 16
    app.vaseHeight = 24
    app.bladeBlockHeight = 30
    app.floorHeight = 13
    app.wallWidth = 16
    app.blockHeight = 42
    app.blockOffsetY = 5
    app.girlWidth = 36
    app.girlHeight = app.girlWidth
    app.tableLegWidth = 14
    app.tableLegHeight= 30
    app.tablePlateWidth = 50
    app.tablePlateHeight = 14
    app.fallThingWidth = 20
    app.mapMinX = 1
    app.mapMinY = 1
    app.mapMaxX = 4
    app.mapMaxY = 3
    app.items = {}
    app.gameClock = { secondsLeft = 0, secondsLeftAtStart = 75, secondsLeftOld = nil, framesCounter = 0 }
    app.gameClock.secondsLeft = app.gameClock.secondsLeftAtStart
    app.musicOrder = {}
    app.secondsLeftOld = nil
    app.bombsPerRoom = 1
    app.bombsLeft = app.bombsPerRoom
    app.underwaterAlpha = .75
    app.showScoredText = true
    app.diamondsOwned = 0
    app.wasTimeOut = false
    app.diamondsInPack = 10000
    app.restartWhenResumed = false
    app.temporaryTypes = {'girlGhost', 'gameOverOverlay', 'scoredText', 'bombShard', 'shard'}
    app.startedInMicroseconds = nil
    app.runsSinceAppStart = 0
    app.diamondsPackPriceCached = nil

    app.menuTextColor = {red = 234, green = 173, blue = 140}
    app.buttonTextColor = {red = 207, green = 254, blue = 251}

    app.dress = {}
    app.currentDress = 1

    app.enumGridUnwalkable = 0
    app.enumGridWalkable = 1

    app.soundChannelFootsteps = 3
    app.soundChannelHeartbeat = 4

    app.spritesCount = 0
    app.defaultDensity = 1; app.defaultBounce = 0.2; app.defaultFriction = 0.3
    app.groupsToHandleEvenWhenPaused = {'menu', 'menuButton'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()
    app.newsDialog = nil
end

init()
