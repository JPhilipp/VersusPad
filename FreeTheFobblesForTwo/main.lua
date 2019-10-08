physics = require('physics')
misc = require('misc')
dataModule = require('data-class')
spritesheetModule = require('sprite')
spriteModule = require('sprite-class')
spritesHandlerModule = require('sprites-handler')
language = require('language-data')
phaseModule = require('phase-class')
menuModule = require('menu-class')
newsModule = require('news-class')
require('app-misc')
require('sqlite3')

appRestarting = false
app = {}

function init()
    misc.initDefaults()
    appClass()

    if app.drawMode ~= nil then physics.setDrawMode(app.drawMode) end
    physics.setGravity(0, app.defaultGravity)
    appClearConsole()
    app.data:open()

    appCreateSprites()
    appCacheImportantSounds()
    app.news:verifyNeededFunctionsAndVariablesExists()
    Runtime:addEventListener('enterFrame', appHandleAll)

    timer.performWithDelay(1000, handleClock)
    app.news:handle()
end

-- **********************

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
    if app.gameRuns then appHandlePhases() end

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

function appEndGame()
    appCreateBackground()
    appRemoveSpritesByType('warningMessage')
    appRemoveSpritesByType('fontImageBackground')
    appRemoveSpritesByType('fontImage')
    appRemoveSpritesByType('menu')
    app.minutesCounter = 0
    app.secondsCounter = 0
end

function appRestartGame()
    appEndGame()
    app.currentPlayer = misc.getIf( app.mode == 'training', 1, math.random(app.playerMax) )
    app.rescuedCountLast = nil

    app.spritesHandler:createClouds()
    appGenerateRandomLevel()

    app.phase:set('gameStarted')
    appResumeGame()
end

function appGenerateRandomLevel()
    app.spritesHandler:createWoodsAndStones()
    app.spritesHandler:createFobbles()
    appPutBackgroundSpritesToBack()
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
    app.spritesHandler:createClouds()
    app.spritesHandler:createBirds()
    app.spritesHandler:createWorm()
    appGenerateRandomLevel()

    app.menu:createButtons()
    appCreateBackground()
    local debugSprite = appGetSpriteByType('debugText')
    if debugSprite then debugSprite:toFront() end

    appIncludeLetterboxBars(false)
end

function appHandlePhases()
    app.phase:handleCounter()
    app.soundPhase:handleCounter()

    if app.mode == 'default' then appHandlePhasesDefault()
    elseif app.mode == 'training' then appHandlePhasesTraining()
    end

    if app.soundPhase.name ~= 'mute' and math.random(1600) <= 1 then
        app.soundPhase:set('mute', 1000, 'default')
        appPlaySound('birds')
    end
end

function appHandlePhasesDefault()
    if app.phase.name == 'gameStarted' then
        if not app.phase:isInited() then
            appRemoveSpritesByType('message')
            appPlaySound('birds')
            app.soundPhase:set('mute', 1000, 'default')
            app.phase:setNext('playerCanMakeTurn', 30)
        end

    elseif app.phase.name == 'playerCanMakeTurn' then
        if not app.phase:isInited() then
            app.currentPlayer = misc.getIf(app.currentPlayer == nil or app.currentPlayer == 2, 1, 2)
            app.spritesHandler:createTurnMessage()
        end

    elseif app.phase.name == 'playerJustMadeturn' then
        if not app.phase:isInited() then
            appRemoveSpritesByType('message')
            app.phase:setNext('waitForFobblesToHalt', 40)
        end

    elseif app.phase.name == 'waitForFobblesToHalt' then
        if not app.phase:isInited() then
            app.phase:setNext('playerCanMakeTurn', 300)
        end

        if appFobblesAreHalting() then
            app.phase:set('playerCanMakeTurn')
        end

    elseif app.phase.name == 'announceWinner' then
        if not app.phase:isInited() then
            appRemoveSpritesByType('message')
            appAnnounceWinner()
            app.phase:setNext('restart', 410)
        end

    elseif app.phase.name == 'restart' then
        if not app.phase:isInited() then
            appRestartGame()
        end

    end
end

function appHandlePhasesTraining()
    if app.phase.name == 'gameStarted' then
        if not app.phase:isInited() then
            appRemoveSpritesByType('message')
            appPlaySound('birds')
            app.soundPhase:set('mute', 1000, 'default')
            app.phase:set('playerCanMakeTurn')
            app.rescuedCountLast = nil
        end

    elseif app.phase.name == 'playerCanMakeTurn' then
        if not app.phase:isInited() then
            app.spritesHandler:createTurnMessage()
        end

        local rescuedCount = appGetSpriteCountByType('fobble', nil, app.currentPlayer)
            local rescuedEnemiesCount = app.fobblesPerPlayer - appGetSpriteCountByType('fobble', nil, app.enemyPlayer)
        if app.rescuedCountLast ~= rescuedCount then
            app.rescuedCountLast = rescuedCount
            local rescuedPercent = misc.getPercentRounded(app.fobblesPerPlayer, app.fobblesPerPlayer - rescuedCount)
            app.spritesHandler:createFontImageForFreedMessage(app.maxXHalf, 956, rescuedPercent .. '%')

            if rescuedPercent >= app.singlePlayerRequiredRescuePercent then app.phase:set('announceWinner') end
        end
        if rescuedEnemiesCount > 0 then app.phase:set('announceWinner') end

    elseif app.phase.name == 'playerJustMadeturn' then
        if not app.phase:isInited() then
            app.phase:set('playerCanMakeTurn')
        end

    elseif app.phase.name == 'announceWinner' then
        if not app.phase:isInited() then
            local rescuedEnemiesCount = app.fobblesPerPlayer - appGetSpriteCountByType('fobble', nil, app.enemyPlayer)
            appPrint('rescuedEnemiesCount = ' .. rescuedEnemiesCount)
            appRemoveSpritesByType('message')
            app.winner = misc.getIf(rescuedEnemiesCount == 0, app.currentPlayer, app.enemyPlayer)
            appAnnounceWinner()
            app.phase:setNext('restart', 410)
        end

    elseif app.phase.name == 'restart' then
        if not app.phase:isInited() then
            appRestartGame()
        end

    end
end

function appAnnounceWinner()
    app.spritesHandler:createWinMessage(app.winner)
    app.spritesHandler:createCelebratingFobbles(app.winner)
end

function appFobblesAreHalting()
    local foundFastlyMovingOne = false
    local consideredFast = 2.5 -- was 1.5
    local fastestSpeed = 0
    for id, sprite in pairs(app.sprites) do
        if sprite ~= nil and sprite.energy > 0 and not sprite.gone and sprite.type == 'fobble' then
            if sprite.phase.name ~= 'free' then
                local speedX, speedY = sprite:getLinearVelocity()
                if speedX > fastestSpeed then fastestSpeed = speedX end
                if speedY > fastestSpeed then fastestSpeed = speedY end
                if math.abs(speedX) >= consideredFast and math.abs(speedY) >= consideredFast then -- todo: should be vector speed sum...
                    foundFastlyMovingOne = true
                    break
                end
            end
        end
    end
    -- appDebug('fastestSpeed = ' .. fastestSpeed)
    return not foundFastlyMovingOne
end

function appHandlePlayerTurns()
    if app.currentPlayer ~= app.currentPlayerOld and app.phase.name == 'default' then
        app.currentPlayerOld = app.currentPlayer
        app.spritesHandler:createTurnMessage()
    end
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
            s = s ..  ' | L: ' .. app.language
            appDebugClock(s)
            app.framesCounter = 0
        end

        appHasWinnerSanityCheck()
    end
    timer.performWithDelay(1000, handleClock)
end

function appHasWinnerSanityCheck()
    if app.phase.name ~= 'announceWinner' then
        local fobblesPlayer1 = appGetSpriteCountByType('fobble', nil, 1)
        local fobblesPlayer2 = appGetSpriteCountByType('fobble', nil, 2)
        if fobblesPlayer1 == 0 or fobblesPlayer2 == 0 then
            if fobblesPlayer1 == 0 and fobblesPlayer2 == 0 then app.winner = math.random(1, 2)
            elseif fobblesPlayer1 == 0 then app.winner = 1
            elseif fobblesPlayer2 == 0 then app.winner = 2
            end
            app.phase:set('announceWinner')        
        end
    end
end

function appGetTimeInSeconds()
    return app.minutesCounter * 60 + app.secondsCounter
end

function appGetCollisionFilter(self)
    local filter = {}

    local categoryDefault =      '       X'
    local categoryFobble1 =      '      X '
    local categoryFobble2 =      '     X  '
    local categoryStone1 =       '    X   '
    local categoryStone2 =       '   X    '

    local maskDefault =          '  XXXXXX' -- collides with everything
    local maskFobble1 =          '  XX XXX' -- collides with everything but categoryStone1
    local maskFobble2 =          '  X XXXX' -- collides with everything but categoryStone2

    filter.categoryBits = categoryDefault
    filter.maskBits = maskDefault

    if self.type == 'fobble' and self.parentPlayer == 1 then
        filter.categoryBits = categoryFobble1
        filter.maskBits = maskFobble1
    elseif self.type == 'fobble' and self.parentPlayer == 2 then
        filter.categoryBits = categoryFobble2
        filter.maskBits = maskFobble2
    elseif self.type == 'stone' and self.parentPlayer == 1 then
        filter.categoryBits = categoryStone1
    elseif self.type == 'stone' and self.parentPlayer == 2 then
        filter.categoryBits = categoryStone2
    end

    filter.categoryBits = misc.binaryToDecimal(filter.categoryBits, 'X')
    filter.maskBits = misc.binaryToDecimal(filter.maskBits, 'X')
    return filter
end

function appRemoveTooCloseStonesOfSameParent()
    local securityBuffer = 32
    local ballDiameter = app.fobbleRadius * 2 + securityBuffer
    appRemoveSpritesByType('testRectangle')

    for playerI = 1, app.playerMax do
        local stones1 = appGetSpritesByType('stone', nil, playerI)
        for id1, stone1 in pairs(stones1) do
            local stones2 = appGetSpritesByType('stone', nil, playerI)
            for id2, stone2 in pairs(stones2) do

                if stone1.id ~= stone2.id and not (stone1.gone or stone2.gone) then
                    if not appRectanglesAreDistantEnough(stone1, stone2, ballDiameter) then
                        stone2.gone = true
                        -- app.spritesHandler:createTestRectangle(stone2)
                    end
                end

            end
        end
    end
end

function appShowStoneCount()
    -- Vor potenziellem Fix: Stone-Anzahl pendelt sich bei 9 ein (variiert aber stark, hmmm)

    local thisCount = appGetSpriteCountByType('stone')

    if app.stoneCount == nil then app.stoneCount = thisCount
    else app.stoneCount = (app.stoneCount + thisCount) / 2
    end

    appPrint( 'Stone count = ' .. math.floor(app.stoneCount) .. ' [this: ' .. thisCount .. ']' )

    timer.performWithDelay(5000, appRestartGame)
end

function appRectanglesAreDistantEnough(rect1, rect2, distanceNeeded)
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

    dBall = dBall ^ 2  -- use diameter dBall squared henceforth

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
    -- Compute distance squared from point (tx,ty) to an
    -- unrotated box centered at origin [-dx,dx] X [-dy,dy]

    tx = math.abs(tx)
    if tx > dx then tx = (tx - dx) ^ 2 else tx = 0 end

    ty = math.abs(ty)
    if ty > dy then ty = (ty - dy) ^ 2 else ty = 0 end

    return tx + ty
end

function appClass()
    app.title = 'Free the Fobbles'
    app.name = 'free-fobbles'
    app.version = '1.2'
    app.id = '422251217'
    app.gameRuns = true
    app.language = appGetLanguage()

    app.showDebugInfo = false -- false
    app.isLocalTest = false -- false
    app.doPlaySounds = true -- true

    app.device = system.getInfo('model')
    app.isIOs = app.device == 'iPad' or app.device == 'iPhone'
    app.isAndroid = not app.isIOs
    app.deviceResolution = {width = nil, height = nil}
    appSetDeviceResolution()

    app.letterboxColor = { {red = 70, green = 143, blue = 212}, {red = 149, green = 172, blue = 21} }
    app.fobblesPerPlayer = 14
    app.framesPerSecondGoal = 30
    app.showClock = true and app.showDebugInfo
    app.maxRotation = 360
    app.framesCounter = 0
    app.secondsCounter = 0
    app.minutesCounter = 0
    app.cachedSounds = {}
    app.sameSoundsPlayedSimultaneously = 2
    app.debugCounter = 0
    app.forceConsideredSomething = 3
    app.playerMax = 2
    app.joints = {}
    app.importantSoundsToCache = {
            'birds', 'wood-explodes', 'fobble-bump', 'fobble-bump-soft', 'fobble-falling', 'fobble-freed', 'win'}
    app.winner = nil
    app.mode = 'default' -- 'default', 'training'
    app.backgroundSpriteTypes = {'cloud', 'bird'}
    app.singlePlayerRequiredRescuePercent = 70
    app.rescuedCountLast = nil
    app.currentPlayer = 2
    app.enemyPlayer = 2
    app.fobbleRadius = 20

    app.idInStore = 'com.versuspad.' .. appToPackageName(app.name)
    appPrint(app.idInStore, true)
    app.productIdPrefix = app.idInStore .. '.'
    -- app.products = { { id = appPrefixProductId('premium'), isPurchased = false } }

    app.translatedImages = {}
    app.translatedImages['zh'] = {'background', 'freed',
            'player-1-turn', 'player-1-turn-during-training', 'player-1-wins', 'player-2-turn', 'player-2-wins', 'player-2-wins-during-training',
            'warning-stonesCannotBeRemoved', 'warning-waitUntilHalting', 'menu/selection', 'menu/selection-during-training', 'menu/help-1'}

    app.defaultGravity = 9.8
    app.defaultDensity = 1
    app.defaultBounce = .4
    app.defaultFriction = 0.1 -- 0.0 to 1.0

    app.minX = 0
    app.maxX = 768
    app.minY = 0
    app.maxY = 1024
    app.maxXHalf = app.maxX / 2
    app.maxYHalf = app.maxY / 2

    app.sprites = {}
    app.score = {}
    for i = 1, app.playerMax do
        app.score[i] = 0
    end

    app.phase = phaseModule.phaseClass()
    app.phase:set('gameStarted')
    app.soundPhase = phaseModule.phaseClass()

    app.stoneCount = nil

    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    app.groupsToHandleEvenWhenGamePaused = {'menu', 'menuButton', 'news'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()
    app.magneticMaxValue = misc.getDistance( {x = 0, y = 0}, {x = app.maxX, y = app.maxY} )

    app.newsDialog = nil
end

-- **********************


init()
