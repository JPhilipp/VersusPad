physics = require('physics')
misc = require('misc')
dataModule = require('data-class')
language = require('language-data')
spriteModule = require('sprite-class')
store = require('store')
spritesHandlerModule = require('sprites-handler')
phaseModule = require('phase-class')
menuModule = require('menu-class')
newsModule = require('news-class')
require('app-misc')
require('app-purchasing')
require('sqlite3')

appRestarting = false
app = {}

function init()
    misc.initDefaults()
    appClass()
    appClearConsole()
    app.data:open()
    appLoadData()

    appCreateSprites()
    appCacheImportantSounds()
    Runtime:addEventListener('enterFrame', appHandleAll)
    timer.performWithDelay(app.secondInMs, handleClock)
    -- app.news:verifyNeededFunctionsAndVariablesExists()

    app.news:handle()
end

function appEndGame()
    appRemoveSpritesByType( {'message', 'menu', 'text', 'part', 'dragPart'} )
    appResetScores()
    app.minutesCounter = 0
    app.secondsCounter = 0
    app.currentRound = nil
end

function appRestartGame()
    appEndGame()
    app.phase:set('build')
    appResumeGame()
end

function appPauseGame()
    appStopAllSounds()
    app.gameRuns = false
    physics.pause()
end

function appResumeGame()
    appStopAllSounds()
    appRemoveSpritesByGroup('menu')
    app.gameRuns = true
    physics.start()
end

function appCreateSprites()
    appCreateDebug()
    appCreateClock()

    app.spritesHandler:createGround()
    app.spritesHandler:createBirds()
    app.spritesHandler:createWagon()
    app.spritesHandler:createClouds()

    app.menu:createButtons()
    appCreateBackground()
    appIncludeLetterboxBars()
end

function setIsHitTestableByType(type, subtype, isHitTestable)
    local sprites = appGetSpritesByType(type, subtype)
    for i = 1, #sprites do sprites[i].isHitTestable = isHitTestable end
end

function appHandlePhases()
    app.phase:handleCounter()
    app.soundPhase:handleCounter()

    if app.phase.name == 'build' then
        if not app.phase:isInited() then
            app.data.wagonMovementStarted = false
            appRemoveSpritesByType( {'part', 'message', 'text', 'setPartsButton', 'dragPart', 'part'} )
            appPositionSpritesAtOrigin('wagon')
            app.spritesHandler:createBorderWall()
            appSetPhaseByType('wagon', 'default')

            if app.settingsDifferentPartsForEach then
                app.spritesHandler:createDragParts(1)
                app.spritesHandler:createDragParts(2)
            else
                app.spritesHandler:createDragParts()
            end

            appPutBackgroundSpritesToBack()

            app.spritesHandler:createKnights()
            app.spritesHandler:createSunTransition()

            local debugSprite = appGetSpriteByType('debugText')
            if debugSprite ~= nil then debugSprite:toFront() end

            app.spritesHandler:createMessageImage('build', app.maxXHalf, 216, 320, 161)
            app.spritesHandler:createSetPartsButton()
            app.spritesHandler:createSecondsText()

            if app.currentRound == nil then
                app.currentRound = 1
                appResetScores()
                app.spritesHandler:createScoreShields()
            else
                app.currentRound = app.currentRound + 1
            end

            local buildingSeconds = misc.getIf(app.settingsUseMoreBuildingSeconds, 40, 25)
            app.phase:setNext('battle', nil, buildingSeconds)
            appSetToFrontByType('cloud', 'dust')

            app.soundPhase:set( 'mute', 300 + math.random(200), 'default' )

            if app.currentRound == 1 then
                if not app.isLocalTest then appPlaySound('theme-intro') end
            else
                appPlaySound('drums-transition')
                appPlaySound('armor')
            end

            app.data.tickSoundPlayed = {}
            app.roundsPlayedSinceAppStart = app.roundsPlayedSinceAppStart + 1

            if not app.purchasesInited then
                appInitPurchases()
                app.purchasesInited = true
            end
        end

        local secondsLeft = app.phase:getSecondsLeft()
        if secondsLeft == 1 and app.data.tickSoundPlayed['1'] == nil then
            appPlaySound('tick-drum')
            app.data.tickSoundPlayed['1'] = true
        elseif secondsLeft == 0 and app.data.tickSoundPlayed['0'] == nil then
            appPlaySound('tick-drum')
            app.data.tickSoundPlayed['0'] = true
        end

    elseif app.phase.name == 'battle' then
        if not app.phase:isInited() then
            app.data.wagonMovementStarted = false
            
            appRemoveSpritesByType( {'message', 'text', 'borderWall', 'setPartsButton'} )
            app.phase:setNext('announceBattleOrGameWinner', nil, 20)
            app.spritesHandler:createSunTransition()

            appReplaceDragPartsWithPhysicParts()
            appSetToFrontByType('cloud', 'dust')
            app.data.dramaticDrumsPlayed = false
            app.data.tickSoundPlayed = {}
            appPlaySound('tick-drum-with-bell')
            app.data.playerHadEmptyWagonAfterNSeconds  = nil
            app.data.lastTimeCannonBallHit = nil
        end

        local secondsLeft = app.phase:getSecondsLeft()
        if secondsLeft == 2 and app.data.tickSoundPlayed[2] == nil then
            appPlaySound('drums-dramatic')
            app.data.tickSoundPlayed[2] = true
        end

        local secondsPassed = app.phase:getSecondsPassed()
        local spritesAreHalting = appSpritesAreHalting('part')
        app.data.shootingBeganAndCannonBallHitSomethingRecently = true
        if secondsPassed > 10 then
            if app.data.lastTimeCannonBallHit == nil then app.data.shootingBeganAndCannonBallHitSomethingRecently = false
            else app.data.shootingBeganAndCannonBallHitSomethingRecently = secondsPassed - app.data.lastTimeCannonBallHit <= 4
            end
        end

        local magicIsOngoing = appGetSpriteCountByTypeAndSubtypes( 'part',
                {'stormVessel', 'statueOfGenerosity', 'statueOfProsperity', 'rasEye'} ) >= 1 or
                appGetSpriteCountByType('rasBeam') >= 1
        local cannonsCount = appGetSpriteCountByTypeAndSubtypes( 'part', {'cannon', 'twinCannon', 'blackCannon', 'goldenCannon'} )

        local extraSeconds = misc.getIf(app.settingsUseMoreBuildingSeconds, 5, 0)

        if not (magicIsOngoing and secondsPassed <= 14 + extraSeconds) then
            if secondsPassed >= 9 + extraSeconds and spritesAreHalting and cannonsCount == 0 and not magicIsOngoing then
                app.phase:set('announceBattleOrGameWinner')
            elseif secondsPassed >= 10 + extraSeconds and spritesAreHalting and not app.data.shootingBeganAndCannonBallHitSomethingRecently then
                app.phase:set('announceBattleOrGameWinner')
            elseif secondsPassed >= 3 + extraSeconds and appGetSpriteCountByType('part') == 0 then
                app.phase:set('announceBattleOrGameWinner')
            elseif secondsPassed >= 2 + extraSeconds and app.data.playerHadEmptyWagonAfterNSeconds == nil then
                if appGetSpriteCountByType('part', nil, 1) == 0 or appGetSpriteCountByType('part', nil, 2) == 0 then
                    app.data.playerHadEmptyWagonAfterNSeconds = secondsPassed
                end
            elseif secondsPassed >= 5 + extraSeconds and app.data.playerHadEmptyWagonAfterNSeconds ~= nil and secondsPassed - app.data.playerHadEmptyWagonAfterNSeconds >= 2 + extraSeconds then
                app.phase:set('announceBattleOrGameWinner')
            end
        end

    elseif app.phase.name == 'announceBattleOrGameWinner' then
        if not app.phase:isInited() then
            appPlaySound('tick-drum-with-bell')
            appRemoveSpritesByType( {'message', 'text'} )
            app.spritesHandler:createSunTransition()

            local winnerI, x, y = appGetHighestPart()
            if winnerI ~= nil then
                local loserI = misc.getIf(winnerI == 1, 2, 1)
                appSetPhaseByType('knight', 'cheer', winnerI)
                appSetPhaseByType('knight', 'retreat', loserI)

                app.score[winnerI] = app.score[winnerI] + 1
                local width = 460
                local height = 70
                app.spritesHandler:createMessageImage('higher-tower-' .. winnerI, x, y - height / 2, width, height, 5)
                appPlaySound('cheers')

                app.spritesHandler:createScoreShields()

                if app.score[winnerI] >= app.scoreMax then
                    app.currentRound = nil
                    local x = app.minX + 200
                    local y = 200
                    if winnerI == 2 then x = app.maxX - x end
                    app.spritesHandler:createMessageImage('winner', x, y, 185, 45, 0, 10, true)
                    app.currentRound = nil
                    appSetPhaseByType('knight', 'stormCastle', winnerI, math.floor( appGetSpriteCountByType('knight', nil, winnerI) * .5 ) )
                    app.phase:setNext('build', nil, 10)
                else
                    app.phase:setNext('build', nil, 5)
                end
            else
                app.spritesHandler:createMessageImage('draw', app.maxXHalf, 200, 171, 29, 0, 4)
                app.phase:setNext('build', nil, 5)
            end

        end
    end

    if misc.inArray( {'build', 'battle'}, app.phase.name ) and app.soundPhase.name ~= 'mute' and math.random(100) <= 1 then
        app.soundPhase:set( 'mute', 300 + math.random(200), 'default' )
        appPlaySound('armor')
    end
    -- appDebug( app.phase:getInfo() )
end

function appGetHighestPart()
    local higherPlayer = nil
    local x = nil
    local y = nil
    local xByPlayer = {}
    local yByPlayer = {}
    for playerI = 1, app.playerMax do
        xByPlayer[playerI], yByPlayer[playerI] = appGetHighestPartByPlayer(playerI)
    end

    if (yByPlayer[1] ~= nil and yByPlayer[2] == nil) or (yByPlayer[1] ~= nil and yByPlayer[2] ~= nil and (yByPlayer[1] < yByPlayer[2]) ) then
        higherPlayer = 1
    elseif (yByPlayer[2] ~= nil and yByPlayer[1] == nil) or (yByPlayer[2] ~= nil and yByPlayer[1] ~= nil and (yByPlayer[2] < yByPlayer[1]) ) then
        higherPlayer = 2
    end

    if higherPlayer ~= nil then
        x = xByPlayer[higherPlayer]
        y = yByPlayer[higherPlayer]
    end

    return higherPlayer, x, y
end

function appGetHighestPartByPlayer(playerI)
    local x = nil
    local y = nil
    local sprites = appGetSpritesByType('part', nil, playerI)
    for id, self in pairs(sprites) do
        if y == nil or self.contentBounds.yMin < y then
            x = self.x
            y = self.contentBounds.yMin
        end
    end
    return x, y
end

function appReplaceDragPartsWithPhysicParts()
    local dragParts = appGetSpritesByType('dragPart')
    for id, self in pairs(dragParts) do
        if self.data.wasTouched and not app.partSubtypes[self.subtype].disappearsDuringBattle then
            app.spritesHandler:createPart( self.subtype, self.x, self.y, self.width, self.height, self.rotation,
                    self.parentPlayer, misc.cloneTable(self.data.shapeOrShapes), self.data.imageName )
        else
            self.emphasizeDisappearance = true
        end
        self.gone = true
    end
end

function appGetPartWidthHeightShape(subtype)
    local width = app.partSubtypes[subtype].width
    local height = app.partSubtypes[subtype].height
    local shapeOrShapes = nil

    if subtype == 'box' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(width, height, 3)

    elseif subtype == 'stormVessel' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(width, height, 3)

    elseif subtype == 'blackCannon' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(width, height, 3)

    elseif subtype == 'smallBox' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(width, height, 3)

    elseif subtype == 'square' or subtype == 'metalSquare' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(84, 84, 2)

    elseif subtype == 'metalBarrier' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(width, height, 2)

    elseif subtype == 'longPillar' then
        shapeOrShapes = appGetRectangleWithPaddingAbsolute(width, height, 2)

    elseif subtype == 'magpieStone' then
        shapeOrShapes = {25,1,  39,9,  width-1,height - 1,  1,height - 1,  12,9}

    elseif subtype == 'bouncingLinen' then
        shapeOrShapes = {4,2,  111,61,  108,66,  2,66,  2,4}

    elseif subtype == 'hShape' then
        shapeOrShapes = {
                {1,1,  width-1,1,  width-1,13,  1,13},
                {30,1, 45,1, 45,99,  30,99},
                {1,87,  width-1,87,  width-1,height-1, 1,height-1},
                }

    elseif subtype == 'tShape' then
        shapeOrShapes = {
                {1,1,  width-1,1,  width-1,14,  1,14},
                {30,1, 45,1, 45,99,  30,99},
                }

    elseif subtype == 'moonShape' then
        shapeOrShapes = {1,1,  width-1,1, 132 / 2,44 / 2,  117 / 2,59 / 2,  99 / 2,68 / 2,  73 / 2,73 / 2, 35 / 2,63 / 2,  15 / 2,46 / 2,  1,22 / 2}

    elseif subtype == 'lShape' then
        shapeOrShapes = {
                {2,2,  width-2,2,  width-2,15,  2,15},
                {2,2,  15,2,  15,height-2,  2,height-2},
                }

    elseif subtype == 'sShape' then
        shapeOrShapes = {
                {1,1,  81,1,  81,13,  1,13},
                {68,1,  81,1,  81,height-1,  68,height-1},
                {68,69,  width-1,69,  width-1,height-1, 68,height-1},
                }

    elseif subtype == 'battleLion' then
        shapeOrShapes = {30,0,  41,17,  width,84,  width,height,  0,height,  3,60,  17,3}

    elseif subtype == 'rasEye' then
        shapeOrShapes = {26,0,  38,4,  width,height - 1,  0,height - 1,  14,4}

    elseif subtype == 'cross' then
        shapeOrShapes = {
                {70,2,  85,2,  85,height-2,  70,height-2},
                {2,68,  width-2,68,  width-2,83,  2,83}
                }

    elseif subtype == 'pillar' then
        shapeOrShapes = {25,0,  48,0,  48,height,  25,height}

    elseif subtype == 'oddPillar' then
        shapeOrShapes = {
                {97,0,  108,17,  11,78,  0,63},
                {4,62,  242,62,  width,height,  4,height}
                }

    elseif subtype == 'triangle' then
        shapeOrShapes = {1,0,  23,0,  width,119,  width,136,  1,136}

    elseif subtype == 'evenTriangle' then
        shapeOrShapes = {72,0,  147,105, 3,105}

    elseif subtype == 'cannon' or subtype == 'goldenCannon' then
        shapeOrShapes = {61,0,  width,42,  width,height - 1,  0,height - 1,  0,36}

    elseif subtype == 'twinCannon' then
        shapeOrShapes = appGetRectangleWithPaddingsAbsolute(width, height, 6, 1, 9, 2)

    elseif subtype == 'statueOfGenerosity' or subtype == 'statueOfProsperity' then
        shapeOrShapes = {35,0,  43,13,  40,height, 1,height,  3,25}

    elseif subtype == 'spike' then
        local marginY = 13
        shapeOrShapes = {0,1 + marginY,  64,1 + marginY, 214,13 + marginY,  64,26 + marginY,  0,26 + marginY}

    elseif subtype == 'squareSpike' then
        shapeOrShapes = {
                appGetRectangleWithPaddingAbsolute(83, height, 1),
                {79,26,  216,38,  79,51}
                }

    elseif subtype == 'oddBox' then
        shapeOrShapes = {
                {23,20,  91,16,  67,109,  0,106},
                {23,21,  145,0,  149,21,  24,44},
                {3,89,  132,89,  132,110,  3,110}
                }

    elseif subtype == 'smallOddBox' then
        shapeOrShapes = {
                {14,14,  55,12,  41,68,  0,66},
                {14,13,  89,0,  92,12,  15,27},
                {2,56,  81,56,  81,70,  1,70}
                }

    elseif subtype == 'slantedCrate' then
        shapeOrShapes = {71,2,  173,2,  173,19,  108,82,  10,82,  2,70}

    else
        appGetRectangleWithPaddingAbsolute(width - 1, height - 1, 0)

    end

    return width, height, shapeOrShapes
end

function appGetAiBuildingBoundary()
    local wagon = appGetSpriteByType('wagon', nil, app.enemyPlayer)
    if wagon ~= nil then
        local marginX = 40
        local marginY = 120
        local height = 420
        local boundary = {
                x1 = wagon.x - wagon.width / 2 + marginX, x2 = wagon.x + wagon.width / 2 - marginX,
                y1 = wagon.y - wagon.height / 2 - height, y2 = wagon.y - wagon.height / 2 - marginY
                }
        return boundary
    end
end

function appAdjustPathIfNeeded(filename)
    if type(filename) == 'string' and app.mode == 'training' and misc.inArray( app.imagesWhichChangeDuringTraining, misc.removeFileExtension(filename) ) then
        filename = misc.removeFileExtension(filename) .. '-during-training' .. misc.getFileExtension(filename)
    end
    return filename
end

function appGetCollisionFilter(self)
    local filter = {}

    local categoryDefault =           '       X'
    local categoryDragPart =          '      X '
    local categoryGround =            '     X  '
    local categoryCannonBallPlayer1 = '   X    '
    local categoryCannonBallPlayer2 = '  X     '
    local categoryBorderWall =        ' X      '

    local maskDefault =               ' XXXXXXX' -- collides with everything
    local maskDragPart =              ' X      ' -- collides with nothing but borderWall
    local maskPart =                  ' XXXX  X' -- collides with everything but dragParts or ground
    local maskCannonPlayer1 =         ' XX X  X' -- collides with everything but dragParts or ground or cannonBallPlayer1
    local maskCannonPlayer2 =         ' X XX  X' -- collides with everything but dragParts or ground or cannonBallPlayer2

    filter.categoryBits = categoryDefault
    filter.maskBits = maskDefault

    if self.type == 'dragPart' then
        filter.categoryBits = categoryDragPart
        filter.maskBits = maskDragPart
    elseif self.type == 'part' and app.partSubtypes[self.subtype].isCannon then
        filter.maskBits = misc.getIf(self.parentPlayer == 1, maskCannonPlayer1, maskCannonPlayer2)
    elseif self.type == 'part' then
        filter.maskBits = maskPart
    elseif self.type == 'ground' then
        filter.categoryBits = categoryGround
    elseif self.type == 'borderWall' then
        filter.categoryBits = categoryBorderWall
    elseif self.type == 'cannonBall' then
        filter.categoryBits = misc.getIf(self.parentPlayer == 1, categoryCannonBallPlayer1, categoryCannonBallPlayer2)
    end

    filter.categoryBits = misc.binaryToDecimal(filter.categoryBits, 'X')
    filter.maskBits = misc.binaryToDecimal(filter.maskBits, 'X')
    return filter
end

function appLoadData()
    app.settingsUseMorePartsPerWagon = app.data:getBool('settingsUseMorePartsPerWagon', false)
    app.settingsUseMoreBuildingSeconds = app.data:getBool('settingsUseMoreBuildingSeconds', false)
    app.settingsDifferentPartsForEach = app.data:getBool('settingsDifferentPartsForEach', false)
    app.gold = app.data:get('gold', 70)

    for i = 1, #app.products do
        app.products[i].isPurchased = app.data:getBool('purchased_' .. app.products[i].id, false)
    end

    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        part.owned = app.data:getBool('partOwned_' .. key, part.ownedByDefault)
        part.selected = app.data:getBool('partSelected_' .. key, part.selectedByDefault)
    end
end

function appSaveData()
    app.data:setBool('settingsUseMorePartsPerWagon', app.settingsUseMorePartsPerWagon)
    app.data:setBool('settingsUseMoreBuildingSeconds', app.settingsUseMoreBuildingSeconds)
    app.data:setBool('settingsDifferentPartsForEach', app.settingsDifferentPartsForEach)
    app.data:set('gold', app.gold)

    for i = 1, #app.products do
        app.data:setBool('purchased_' .. app.products[i].id, app.products[i].isPurchased)
    end

    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        if part.ownedByDefault then part.owned = true end
        app.data:setBool('partOwned_' .. key, part.owned)
        app.data:setBool('partSelected_' .. key, part.selected)
    end
end

function appRestorePurchases()
    appStartPurchaseRestore()
    app.menu:createDialogSetParts()
end

function appGetRandomPartSubtype()
    local subtypes = appGetSelectedPartSubtypes()
    if #subtypes == 0 then
        subtypes = {'smallBox'}
        app.partSubtypes.smallBox.selected = true
    end
    return misc.getRandomEntry(subtypes)
end

function appGetSelectedPartSubtypes()
    local subtypes = {}
    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        if part.selected then
            subtypes[#subtypes + 1] = key
        end
    end
    return subtypes
end

function appGetPartSubtypesWithHigherChance()
    local subtypes = {}
    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        if part.selected and part.higherChance then
            subtypes[#subtypes + 1] = key
        end
    end
    return subtypes
end

function appGetPartSubtypesToEmphasizeSometimes()
    local subtypes = {}
    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        if part.selected and part.emphasizeSometimes then
            subtypes[#subtypes + 1] = key
        end
    end
    return subtypes
end

function appReplaceUnusedParts(amuletSubtype, parentPlayer)
    local parts = appGetSpritesByType('dragPart', nil, parentPlayer)
    local sequenceSubtypes = app.spritesHandler:getDragPartsSequenceSubtypes(true, amuletSubtype)
    local sequenceI = 1
    for id, self in pairs(parts) do
        if (amuletSubtype == 'amuletOfFullFate' or not self.data.wasTouched) and self.subtype ~= amuletSubtype then
            if sequenceI <= #sequenceSubtypes then
                local subtype = sequenceSubtypes[sequenceI]
                if subtype ~= amuletSubtype then
                    local width, height, shapeOrShapesBase = appGetPartWidthHeightShape(subtype)
                    local rotation = math.random( 0, math.floor(app.maxRotation / app.rotationStep - 1) ) * app.rotationStep
                    local direction = baseDirection
                    local direction = 1
                    if parentPlayer == 2 then direction = misc.getIf(direction == 1, 2, 1) end
                    app.spritesHandler:createDragPart(subtype, self.x, self.y, direction, false, width, height, shapeOrShapesBase, rotation, parentPlayer,
                            self.data.wasTouched)
                end
                self.gone = true
                sequenceI = sequenceI + 1
            else
                break
            end
        end
        appPlaySound('fate-spell')
    end
end

function appResetSettings()
    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        local partDefault = app.partSubtypesDefault[key]
        part.selected = partDefault.selected
    end

    app.settingsUseMorePartsPerWagon = false
    app.settingsUseMoreBuildingSeconds = false
    app.settingsDifferentPartsForEach = false

    app.partsDialogPageNumber = 1

    appSaveData()
end

function appGetAddedGoldCosts()
    local priceSum = 0
    for key, value in pairs(app.partSubtypes) do
        local part = app.partSubtypes[key]
        if part.price then priceSum = priceSum + part.price end
    end
    return priceSum
end

function appClass()
    app.title = 'Siege Towers'
    app.name = 'siege-towers'
    app.version = '1.5'
    app.id = '423691021'
    app.gameRuns = true
    app.language = appGetLanguage( {'en', 'de', 'zh'} )
    -- app.language = 'de'

    app.showDebugInfo = false -- false
    app.isLocalTest = false -- false
    app.doPlaySounds = true -- true
    app.device = system.getInfo('model')

    app.framesPerSecondGoal = 30
    app.showClock = false and app.showDebugInfo
    app.maxRotation = 360
    app.secondInMs = 1000
    app.framesCounter = 0
    app.secondsCounter = 0
    app.minutesCounter = 0
    app.cachedSounds = {}
    app.sameSoundsPlayedSimultaneously = 2
    app.debugCounter = 0
    app.forceConsideredSomething = 3
    app.playerMax = 2
    app.enemyPlayer = 2
    app.joints = {}
    app.recentlyPlayedSounds = {}
    app.importantSoundsToCache = {'cheers', 'wheels', 'cannon-shot-1', 'cannon-shot-2', 'drums-dramatic', 'drums-transition',
        'armor', 'rotate', 'wood-bump-1', 'wood-bump-2', 'wood-bump-soft', 'explode', 'theme-intro', 'tick-drum', 'tick-drum-with-bell'
        }
    app.winner = nil
    app.mode = 'default'
    app.backgroundSpriteTypes = {}

    app.deviceResolution = {}
    appSetDeviceResolution()

    app.defaultGravity = 9.8
    app.defaultDensity = 1
    app.defaultBounce = .4
    app.defaultFriction = .6
    app.defaultPhysicsScale = 60

    app.translatedImages = {}
    app.translatedImages['zh'] = {'background', 'background-during-training', 'message-build', 'message-build-during-training',
            'message-draw', 'message-higher-tower-1', 'message-higher-tower-2', 'message-higher-tower-2-during-training',
            'message-winner', 'news-dialog', 'menu/help-1', 'menu/help-2', 'menu/selection', 'menu/selection-during-training'
            }

    app.osIndependentImages = {'menu/help-1'}

    app.imagesWhichChangeDuringTraining = {'background', 'knight-2', 'message-build', 'message-higher-tower-2',
            'scoreShield/full-2', 'menu/selection'}

    app.minX = 0
    app.maxX = 1024
    app.minY = 0
    app.maxY = 768
    app.maxXHalf = math.floor(app.maxX / 2)
    app.maxYHalf = math.floor(app.maxY / 2)
    app.idInStore = misc.getIf(app.device == 'iPad', app.name .. '.versuspad.com', 'com.versuspad.siegetowers')

    app.physicalGroundY = app.maxY - 93
    app.visualGroundY = app.physicalGroundY - 25
    app.horizonY = 610
    app.partSubtypesOrder = {'smallBox', 'box', 'smallOddBox', 'oddBox', 'triangle', 'pillar', 'oddPillar', 'cannon', 'spike',
            'square', 'metalSquare', 'longPillar', 'evenTriangle', 'cross', 'twinCannon', 'goldenCannon', 'blackCannon',
            'stormVessel',
            'tShape', 'hShape', 'lShape', 'sShape', 'wheel', 'moonShape', 'slantedCrate', 'squareSpike', 'magpieStone',
            'statueOfGenerosity', 'statueOfProsperity', 'battleLion','bouncingLinen', 'metalBarrier',
            'amuletOfFate', 'amuletOfFullFate', 'rasEye'}

    app.partSubtypes = {
        smallBox = {owned = true, selected = true, width = 102, height = 74, selectedByDefault = true, emphasizeSometimes = true, sampleSizeFactor = .4,
                title = 'Wide Box', description = 'A small wide box for all needs!', ownedByDefault = true,
                title_de = 'Breit-Box', description_de = 'Eine kleine, gut einsetzbare Kiste!'},
        box = {owned = true, selected = true, width = 171, height = 115, selectedByDefault = true, sampleSizeFactor = .35,
                title = 'Big Wide Box', description = 'A basic versatile crate!', ownedByDefault = true,
                title_de = 'Grosse Breit-Box', description_de = 'Eine vielseitige Kiste!'},
        smallOddBox = {owned = true, selected = true, width = 93, height = 70, selectedByDefault = true, sampleSizeFactor = .35,
                title = 'Open Box', description = 'An uneven crate!', ownedByDefault = true,
                title_de = 'Kleine Offene Box', description_de = 'Eine kleine schiefe Kiste!'},
        oddBox = {owned = true, selected = true, width = 150, height = 112, selectedByDefault = true, sampleSizeFactor = .4,
                title = 'Big Open Box', description = 'A big uneven crate!', ownedByDefault = true,
                title_de = 'Offene Box', description_de = 'Eine schiefe Kiste!'},
        triangle = {owned = true, selected = true, width = 96, height = 138, selectedByDefault = true, sampleSizeFactor = .37,
                title = 'Stretched Triangle', description = 'A tricky triangular piece!', ownedByDefault = true,
                title_de = 'Gestrecktes Dreieck', description_de = 'Eine knifflige Konstruktion!'},
        pillar = {owned = true, selected = true, width = 74, height = 122, emphasizeSometimes = true, selectedByDefault = true, sampleSizeFactor = .3,
                title = 'Pillar', description = 'A versatile basic pillar!', ownedByDefault = true,
                title_de = 'Brett', description_de = 'Ein vielseitiges Basis-Brett!'},
        oddPillar = {owned = true, selected = true, width = 243, height = 82, selectedByDefault = true, sampleSizeFactor = .29,
                title = 'Hook Pillar', description = 'Construct with care!', ownedByDefault = true,
                title_de = 'Haken-Brett', description_de = 'Verbau es mit Vorsicht!'},
        cannon = {owned = true, selected = true, width = 85, height = 67, higherChance = true, selectedByDefault = true, sampleSizeFactor = .58,
                hasHigherDensity = true, isCannon = true,
                title = 'Cannon', description = 'Fires cannon balls!', ownedByDefault = true,
                title_de = 'Kanone', description_de = 'Feuert Kanonenkugeln!'},
        spike = {owned = true, selected = true, width = 215, height = 53, selectedByDefault = true, sampleSizeFactor = .3,
                hasHigherDensity = true, isMostlyIron = true,
                title = 'Spike', description = 'A heavy metallic pole!', ownedByDefault = true,
                title_de = 'Spitze', description_de = 'Eine schwere Metallspitze!'},

        square = {owned = false, selected = false, width = 85, height = 83, selectedByDefault = false, sampleSizeFactor = .5,
                title = 'Square', description = 'A highly useful perfect square!', price = 20,
                title_de = 'Kasten', description_de = 'Ein vielseitig einsetzbares Quadrat!'},
        metalSquare = {owned = false, selected = false, width = 85, height = 83, selectedByDefault = false, sampleSizeFactor = .5,
                hasHigherDensity = true, isMostlyIron = true,
                title = 'Metal Square', description = 'A crate with heavy metal!', price = 20,
                title_de = 'Metallkasten', description_de = 'Ein Kasten aus schwerem Metall!'},
        longPillar = {owned = false, selected = false, width = 21, height = 195, selectedByDefault = false, sampleSizeFactor = .28,
                title = 'Long Pillar', description = 'Much longer than the basic pillar!', price = 20,
                title_de = 'Lang-Brett', description_de = 'Doppelt so hoch wie das normale Brett!'},
        evenTriangle = {owned = false, selected = false, width = 147, height = 115, selectedByDefault = false, sampleSizeFactor = .42,
                title = 'Triangle', description = 'A triangle with even sides!', price = 20,
                title_de = 'Dreieck', description_de = 'Eine Dreiecksform mit gleichen Seiten!'},

        cross = {owned = false, selected = false, width = 155, height = 155, selectedByDefault = false, sampleSizeFactor = .39, sampleRotation = 45,
                title = 'Cross', description = 'An X-shaped wood construction!', price = 20,
                title_de = 'Kreuz', description_de = 'Bretter in X-Form!'},

        twinCannon = {owned = false, selected = false, width = 105, height = 75, selectedByDefault = false, sampleSizeFactor = .58,
                hasHigherDensity = true, isCannon = true,
                title = 'Twin Cannon', description = 'Fires horizontally + twice as fast!', price = 80,
                title_de = 'Zwillingskanone', description_de = 'Feuert horizontal + doppelt so schnell!'},
        goldenCannon = {owned = false, selected = false, width = 85, height = 67, selectedByDefault = false, sampleSizeFactor = .58,
                hasHigherDensity = true, isCannon = true,
                title = 'Golden Cannon', description = 'Fires stronger cannon balls!', price = 80,
                title_de = 'Goldkanone', description_de = 'Diese Kugeln haben noch mehr Kraft!'},
        blackCannon = {owned = false, selected = false, width = 94, height = 64, selectedByDefault = false, sampleSizeFactor = .58,
                hasHigherDensity = true, isCannon = true,
                title = 'Black Cannon', description = 'A single shot destroys all in its path!', price = 80,
                title_de = 'Schwarze Kanone', description_de = 'Eine Kugel zerbricht alles!'},

        tShape = {owned = false, selected = false, width = 78, height = 102, selectedByDefault = false, sampleSizeFactor = .39,
                title = 'Single Ender', description = 'A T-shaped crate!', price = 60,
                title_de = 'Ein-Ender', description_de = 'Eine Kiste in T-Form!'},
        hShape = {owned = false, selected = false, width = 78, height = 102, selectedByDefault = false, sampleSizeFactor = .39,
                title = 'Twin Ender', description = 'A versatile building piece!', price = 60,
                title_de = 'Doppel-Ender', description_de = 'Ein Flexibler Baustein!'},
        lShape = {owned = false, selected = false, width = 86, height = 86, selectedByDefault = false, sampleSizeFactor = .39,
                title = 'Edge', description = 'An L-shaped block for advanced constructions!', price = 60,
                title_de = 'Ecke', description_de = 'Vielseitig einsetzbare L-Form!'},
        sShape = {owned = false, selected = false, width = 149, height = 83, selectedByDefault = false, sampleSizeFactor = .45,
                title = 'Zig Zag', description = 'Powerful in the hands of a master!', price = 60,
                title_de = 'Zick-Zack', description_de = 'Kraftvoll in der Hand des Meisters!'},
        squareSpike = {owned = false, selected = false, width = 220, height = 83, selectedByDefault = false, sampleSizeFactor = .3,
                hasHigherDensity = true, isMostlyIron = true,
                title = 'Square Spike', description = 'Useful for increasing height or attacking!', price = 100,
                title_de = 'Kastenspitze', description_de = 'Baue hoch oder attackiere!'},
        wheel = {owned = false, selected = false, width = 75, height = 75, selectedByDefault = false, sampleSizeFactor = .5,
                title = 'Wheel', description = 'A smoothly rolling wheel!', price = 100, rotationLocked = true,
                title_de = 'Rad', description_de = 'Ein reibungslos rollendes Rad!'},
        moonShape = {owned = false, selected = false, width = 74, height = 37, selectedByDefault = false, sampleSizeFactor = .6,
                title = 'Moon Shape', description = 'A semi-circle!', price = 50, flipLocked = true,
                title_de = 'Mond-Gebilde', description_de = 'Ein Halbkreis!'},
        slantedCrate = {owned = false, selected = false, width = 177, height = 87, selectedByDefault = false, sampleSizeFactor = .4,
                title = 'Slanted Crate', description = 'For advanced constructions!', price = 50,
                title_de = 'Gekippte Kiste', description_de = 'Gut in erweiterten Konstruktionen!'},

        stormVessel = {owned = false, selected = false, width = 41, height = 60, selectedByDefault = false, sampleSizeFactor = .6,
                explodesSparkFree = true,
                title = 'Storm Vessel', description = 'Magic shakes enemy blocks!', price = 250, rotationLocked = true,
                title_de = 'Sturm-Elixier', description_de = 'Verursache einen magischen Sturm!'},
        magpieStone = {owned = false, selected = false, width = 51, height = 72, selectedByDefault = false, sampleSizeFactor = .6,
                hasHigherDensity = true, alwaysFacesForward = true, explodesSparkFree = true,
                title = 'Magpie Stone', description = 'Steals a random enemy block!', price = 250,
                title_de = 'Elster-Stein', description_de = 'Stiehl eine Kiste vom Gegner!'},
        statueOfGenerosity = {owned = false, selected = false, width = 45, height = 103, selectedByDefault = false, sampleSizeFactor = .5,
                hasHigherDensity = true, alwaysFacesForward = true, explodesSparkFree = true,
                title = 'Statue of Generosity', description = 'Rain silver on enemies!', price = 250,
                title_de = 'Freigiebigkeits-Statue', description_de = 'Regne Silber auf Gegner!'},
        statueOfProsperity = {owned = false, selected = false, width = 45, height = 103, selectedByDefault = false, sampleSizeFactor = .5,
                hasHigherDensity = true, alwaysFacesForward = true, explodesSparkFree = true,
                title = 'Statue of Prosperity', description = 'Gold rocks fall on you!', price = 250,
                title_de = 'Wohlstands-Statue', description_de = 'Es regnet Gold-Steine auf dich!'},
        battleLion = {owned = false, selected = false, width = 58, height = 100, selectedByDefault = false, sampleSizeFactor = .52,
                hasHigherDensity = true, alwaysFacesForward = true, explodesSparkFree = true,
                title = 'Battle Lion', description = 'More attacks for all your cannons!', price = 250,
                title_de = 'Kampfes-Statue', description_de = 'Mehr Angriffe deiner Kanonen!'},
        amuletOfFate = {owned = false, selected = false, width = 68, height = 63, selectedByDefault = false, sampleSizeFactor = .55,
                hasHigherDensity = true, rotationLocked = true, disappearsDuringBattle = true,
                title = 'Amulet of Guided Fate', description = 'Replace unused blocks!', price = 350,
                title_de = 'Schicksals-Amulett', description_de = 'Ersetze unbenutzte Teile!'},
        amuletOfFullFate = {owned = false, selected = false, width = 68, height = 63, selectedByDefault = false, sampleSizeFactor = .55,
                hasHigherDensity = true, rotationLocked = true, disappearsDuringBattle = true,
                title = 'Amulet of Pure Fate', description = 'Replace all blocks!', price = 350,
                title_de = 'Pures-Schicksal-Amulett', description_de = 'Ersetzt alle Teile!'},

        bouncingLinen = {owned = false, selected = false, width = 113, height = 68, selectedByDefault = false, sampleSizeFactor = .55,
                hasHigherDensity = true,
                title = 'Bouncing Linen', description = 'Bounces off rocks and more!', price = 200,
                title_de = 'Abpraller', description_de = 'Steine und mehr prallen ab!'},
        metalBarrier = {owned = false, selected = false, width = 36, height = 133, selectedByDefault = false, sampleSizeFactor = .38,
                hasHigherDensity = true, isMostlyIron = true,
                title = 'Iron Wall', description = 'Even defends against black cannons!', price = 200,
                title_de = 'Eisenwand', description_de = 'Hilft auch gegen schwarze Kanonen!'},

        rasEye = {owned = false, selected = false, width = 53, height = 98, selectedByDefault = false, sampleSizeFactor = .5,
                hasHigherDensity = true, alwaysFacesForward = true, explodesSparkFree = true,
                title = 'Eye of Ra', description = 'Sunbeams burn enemy pieces!', price = 400,
                title_de = 'Auge des Ra', description_de = 'Die Sonne verbrennt gegnerische Teile!'},
        }
    app.partSubtypesDefault = misc.cloneTable(app.partSubtypes)

    app.gold = 40
    app.sprites = {}
    app.score = {}
    app.scoreMax = 3
    appSetFont( {'LilyUPC', 'upcll', 'upcll.ttf', 'lilyupc'}, 'upcll' )

    -- e.g. com.versuspad.siegetowers.goldpack1
    app.productIdPrefix = 'com.versuspad.siegetowers.'
    app.products = {
        { id = appPrefixProductId('goldpack1'), title = 'Gold',                goldAmount = 150, dialogColumn = 1, price = nil, isPurchased = false },
        { id = appPrefixProductId('goldpack2'), title = 'Lots of Gold',        goldAmount = 750, dialogColumn = 2, price = nil, isPurchased = false },
        { id = appPrefixProductId('goldpack3'), title = 'Gold Chest',          goldAmount = 1800, dialogColumn = 3, price = nil, isPurchased = false },
        { id = appPrefixProductId('goldpack4'), title = 'Enormous Gold Chest', goldAmount = 5000, dialogColumn = 4, price = nil, isPurchased = false },
    }

    app.phase = phaseModule.phaseClass()
    app.phase:set('build')
    app.soundPhase = phaseModule.phaseClass()

    app.currentRound = nil
    app.roundsPlayedSinceAppStart = 0
    app.battleWinsNeededForGameWin = 3
    app.rotationStep = 45

    app.isVeryOldAndPossiblySlowIPad = system.getInfo('architectureInfo') == 'iPad1,1'

    app.partsDialogPageNumber = 1
    app.partsPerPage = 18
    app.partsDialogPageNumberMax = math.ceil(#app.partSubtypesOrder / app.partsPerPage)
    app.settingsBeforeSetPartsDialog = nil

    app.settingsUseMorePartsPerWagon = false
    app.settingsUseMoreBuildingSeconds = false
    app.settingsDifferentPartsForEach = false

    app.didLoadPrices = false
    app.purchasesInited = false

    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    app.groupsToHandleEvenWhenGamePaused = {'menu', 'menuButton', 'news'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()
    app.magneticMaxValue = misc.getDistance( {x = 0, y = 0}, {x = app.maxX, y = app.maxY} )

    app.newsDialog = nil

    -- app.drawMode = 'hybrid'
    if app.drawMode ~= nil then physics.setDrawMode(app.drawMode) end
    if app.defaultGravity ~= nil then physics.setGravity(0, app.defaultGravity) end
    if app.defaultPhysicsScale ~= nil then physics.setScale(app.defaultPhysicsScale) end
end

init()
