physics = require('physics')
misc = require('misc')
dataModule = require('data-class')
spriteModule = require('sprite-class')
spritesHandlerModule = require('sprites-handler')
language = require('language-data')
phaseModule = require('phase-class')
extraModule = require('extra-class')
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
    physics.setGravity(0, 0)
    appClearConsole()
    app.data:open()

    appCreateSprites()
    appCacheAllImportantSounds()
    app.news:verifyNeededFunctionsAndVariablesExists()
    Runtime:addEventListener('enterFrame', appHandleAll)

    timer.performWithDelay(1000, handleClock)
    app.news:handle()
end

function appEndGame()
    app.extra:doEnd()
    app.extra = extraModule.extraClass()
    for i = 1, app.playerMax do
        app.score[i] = 0
        local forceControlReset = app.leftHandedControlManuallySwitchedInRowCount[i] <= 1
        if forceControlReset and app.leftHandedControl[i] then appToggleControlPosition(i) end
    end
    appCreateBackground('background/default.png')
    appRemoveSpritesByType('ball')
    appRemoveSpritesByType('countdown')
    appRemoveSpritesByType('announcement')
    appRemoveSpritesByType('wormPart')
    appRemoveSpritesByType('scorePeg')
    appRemoveSpritesByType('extraPill')
    appRemoveSpritesByType('menu')
    app.minutesCounter = 0
    app.secondsCounter = 0
    app.timeOfLastGoal = nil
end

function appRestartGame()
    appEndGame()
    app.spritesHandler:createCountdown()
    appResumeGame()
end

function appRecreateWormsAndBallIfNeeded()
    if appGetSpriteCountByType('wormPart', 'head') ~= 2 or appGetSpriteCountByType('ball') ~= 1 then
        appRecreateWormsAndBall()
    end
end

function appRecreateWormsAndBall()
    appRemoveSpritesByType('wormPart')
    appRemoveSpritesByType('ball')
    app.spritesHandler:createWormParts()
    app.spritesHandler:createBall()
end

function appPauseGame()
    app.gameRuns = false
    physics.pause()
end

function appResumeGame()
    appRemoveSpritesByGroup('menu')
    app.gameRuns = true
    physics.start()
end

function appCreateSprites()
    appCreateDebugAndClock()

    app.spritesHandler:createWalls()
    app.spritesHandler:createControls()
    app.menu:createButtons()
    app.spritesHandler:createAtmosphere()
    app.spritesHandler:createCountdown()
    appCreateBackground('background/default.png')
    appIncludeLetterboxBars()
end

function appCreateDebugAndClock()
    if app.showClock then
        local spriteClock = spriteModule.spriteClass('text', 'clockText', nil, nil, false, 231, 958)
        spriteClock.size = 17
        spriteClock:setRgbWhite()
        spriteClock.alpha = .85
        spriteClock:setColorBySelf()
        appAddSprite(spriteClock)
    end

    if app.showDebugInfo then
        local spriteDebug = spriteModule.spriteClass( 'text', 'debugText', nil, nil, false, app.maxX / 2, 180)
        spriteDebug.size = 20
        spriteDebug:setRgbWhite()
        spriteDebug:setColorBySelf()
        appAddSprite(spriteDebug)
    end
end

function appGoalScored(goalWhichWasHitParentPlayerI)
    app.timeOfLastGoal = appGetTimeInSeconds()
    local scoringPlayerI = misc.getIf(goalWhichWasHitParentPlayerI == 1, 2, 1)
    app.score[scoringPlayerI] = app.score[scoringPlayerI] + 1
    appUpdateScore()
    appDisableBuzzersUntilBallReset()
    app.spritesHandler:createGoalEffects(goalWhichWasHitParentPlayerI)
    appResetWorms()
    if misc.inArray( {'magicGoal', 'captive'}, app.extra.name ) then app.extra:doEnd() end
    local gameOver = appCheckForGameOver()
    appPlaySound( misc.getIf(gameOver, 'winner.mp3', 'goal.mp3') )
end

function appResetWormTail(parentPlayer, x, y)
    local wormParts = appGetSpritesByType('wormPart', nil, parentPlayer)
    for id, wormPart in pairs(wormParts) do
        if wormPart.subtype ~= 'head' then
            wormPart.followBuffer = {}
            wormPart.x = x
            wormPart.y = y
        end
    end
end

function appDisableBuzzersUntilBallReset()
    local sprites = appGetSpritesByType('wall', 'buzzer')
    for id, sprite in pairs(sprites) do sprite.phase:set('offUntilBallReset') end
end

function appUpdateScore()
    for playerI = 1, app.playerMax do
        for scoreI = 1, app.scoreMax do
            local id = 'scorePeg' .. playerI .. '-' .. scoreI
            if scoreI <= app.score[playerI] and appGetSpriteById(id) == nil then
                app.spritesHandler:createScorePeg(id, playerI, scoreI)
            end
            app.spritesHandler:adjustScorePegPosition(id)
        end
    end
end

function appCheckForGameOver()
    local gameOver = false
    for playerI = 1, app.playerMax do
        if app.score[playerI] == app.scoreMax then
            app.spritesHandler:createAnnouncement(playerI, 'winnerAnnouncement')
            gameOver = true
        end
    end
    return gameOver
end

function appCreateBackground(filename)
    appRemoveSpritesByType('background')
    if filename == nil then filename = app.backgroundBaseName end
    app.backgroundBaseName = filename
    if string.find(filename, '%.') == nil then filename = filename .. '.jpg' end
    filename = string.gsub(filename, '%.', appGetBackgroundAddition() .. '.')
    local self = spriteModule.spriteClass('rectangle', 'background', nil, filename, false, app.maxX / 2, app.maxY / 2, app.maxX, app.maxY)
    self.alsoAllowsExtendedNonPhysicalHandling = false
    self:toBack()
    appAddSprite(self)
end

function appResetWorms()
    local worms = appGetSpritesByType('wormPart', 'head')
    for i, worm in ipairs(worms) do
        worm.phase:set('default')
    end 
end

function appGetCollisionFilter(self)
    local filter = {}

    --[[
    Collision-Relevant Categories:
    00000001 (1)    categoryDefault
    00000010 (2)    categoryWorm1
    00000100 (4)    categoryWorm2
    00001000 (8)    categoryWall
    00010000 (16)   categoryGoalZoneByWorm
    01000000 (64)   categoryExtraConstruct

    Collision Masks:
    01001111  (79)  maskDefault (collides with everything)
    01011101  (93)  maskWorm1 (collides with default and worm2 and categoryGoalZone)
    01011011  (91)  maskWorm2 (collides with default and worm1 and categoryGoalZone)
    00000111   (7)  maskWall (collides with everything but other walls)
    00111111  (63)  maskExtraConstruct (collides with worms and ball but not extraConstruct)
    --]]

    filter.categoryBits = 1
    filter.maskBits = 79

    if self.type == 'wormPart' and self.parentPlayer == 1 then
        filter.categoryBits = 2
        filter.maskBits = 93
    elseif self.type == 'wormPart' and self.parentPlayer == 2 then
        filter.categoryBits = 4
        filter.maskBits = 91
    elseif self.type == 'wall' then
        filter.categoryBits = 8
        filter.maskBits = 7
    elseif self.type == 'goalZone' then
        filter.categoryBits = 16
    elseif self.type == 'wheel' then
        filter.categoryBits = 64
        filter.maskBits = 63
    end

    return filter
end

function appToggleControlPosition(playerI)
    if app.showClock then
        app.showClock = false
        appRemoveSpritesByType('clockText')
    end

    app.leftHandedControl[playerI] = not app.leftHandedControl[playerI]
    local sprites = appGetSpritesByType( {'extraIcon', 'iconText', 'extraCounter'}, nil, playerI )
    for i, sprite in ipairs(sprites) do
        sprite.x = app.maxX - sprite.x
    end
    app.spritesHandler:createControls()
    app.menu:createButtons()
    appCreateBackground()
    appUpdateScore()
    appResumeGame()
end

function appGetBackgroundAddition()
    -- returns e.g. '-1-0-0-1' (from left to right, top to bottom)
    local s = ''
    s = s .. misc.getIf(app.leftHandedControl[2], '-0-1', '-1-0')
    s = s .. misc.getIf(app.leftHandedControl[1], '-1-0', '-0-1')
    return s
end

function appClass()
    app.title = 'Spikeball For Two'
    app.name = 'spikeball'
    app.version = '1.2'
    app.id = '417704142'
    app.gameRuns = true
    app.language = appGetLanguage()

    app.showDebugInfo = false -- false
    app.isLocalTest = false
    app.doPlaySounds = true

    app.device = system.getInfo('model')
    app.isIOs = app.device == 'iPad' or app.device == 'iPhone'
    app.isAndroid = not app.isIOs
    app.deviceResolution = appGetDeviceResolution()

    app.idInStore = misc.getIf( app.isAndroid,
            'com.versuspad.' .. appToPackageName(app.name), misc.toName(app.name) .. '.versuspad.com' )
    app.productIdPrefix = app.idInStore .. '.'
    -- app.products = { { id = appPrefixProductId('premium'), isPurchased = false, isNewlyPurchased = false } }

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
    app.timeOfLastGoal = nil
    app.thereWasLongTimeWithoutGoal = false
    app.timeFramesToPoison = 280
    app.timeFramesToPoisonShort = 140
    app.backgroundBaseName = nil
    app.playerMax = 2
    app.joints = {}
    app.scoreMax = 4

    app.minX = 0; app.maxX = 768; app.minY = 0; app.maxY = 1024
    app.maxXHalf = app.maxX / 2; app.maxYHalf = app.maxY / 2

    app.sprites = {}
    app.score = {}
    app.controlWasUsed = {}
    app.leftHandedControl = {}
    app.leftHandedControlManuallySwitchedInRowCount = {}
    for i = 1, app.playerMax do
        app.score[i] = 0
        app.controlWasUsed[i] = false
        app.leftHandedControl[i] = false
        app.leftHandedControlManuallySwitchedInRowCount[i] = 0
    end

    app.extra = extraModule.extraClass()
    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    app.groupsToHandleEvenWhenGamePaused = {'menu', 'menuButton', 'news'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()
    app.magneticMaxValue = misc.getDistance( {x = 0, y = 0}, {x = app.maxX, y = app.maxY} )

    app.newsDialog = nil
end

init()
