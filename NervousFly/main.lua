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
    appSetGlasses()
    appInitSound()
    app.data:open()
    appLoadData()
    appInitPurchases()
    -- app.news:verifyNeededFunctionsAndVariablesExists()
    appStart(true)

    Runtime:addEventListener('enterFrame', appHandleAll)
    timer.performWithDelay(app.secondInMs, handleClock)
end
 
function appPause()
    if app.runs then
        physics.pause()
        audio.setVolume( 0, {channel = app.musicChannel} )
        app.runs = false
    end
end

function appResume()
    if not app.runs then
        physics.start()
        appRemoveSpritesByGroup('menu')
        appRemoveSpritesByType('price')
        app.runs = true
        appStartBackgroundMusic()
    end
end

function appPrintDeviceInfo()
    appPrint( 'Resolution = ' .. display.contentWidth .. ' x ' .. display.contentHeight .. ' ' ..
            '(Scale = ' .. display.contentScaleX .. ',' .. display.contentScaleY .. ') - ' .. app.device .. ' - ' ..
            'DeviceResolution = ' .. tostring(app.deviceResolution.maxX) .. 'x' .. tostring(app.deviceResolution.maxY) )
end

function appLoadData()
    app.playBackgroundMusic = app.data:getBool('playBackgroundMusic', true)
    app.highestAllTime.score = app.data:get('score', 0)
    app.highestAllTime.iceCubes = app.data:get('iceCubes', 0)
    app.highestAllTime.glass = app.data:get('glass', 1)
    app.highestAllTime.olives = app.data:get('olives', 0)

    -- app.highestAllTime = {score = 10020, iceCubes = 620, glass = 45, olives = 0}
    -- app.highestThisRound = {score = 10020, iceCubes = 620, glass = 45, olives = 0}
end

function appSaveData()
    app.data:set('score', app.highestAllTime.score)
    app.data:set('iceCubes', app.highestAllTime.iceCubes)
    app.data:set('glass', app.highestAllTime.glass)
    app.data:set('olives', app.highestAllTime.olives)
end

function appAmendHighscore()
    if app.highestThisRound.score > app.highestAllTime.score then app.highestAllTime.score = app.highestThisRound.score end
    if app.highestThisRound.iceCubes > app.highestAllTime.iceCubes then app.highestAllTime.iceCubes = app.highestThisRound.iceCubes end
    if app.highestThisRound.glass > app.highestAllTime.glass then app.highestAllTime.glass = app.highestThisRound.glass end
    if app.highestThisRound.olives > app.highestAllTime.olives then app.highestAllTime.olives = app.highestThisRound.olives end
end

function appRestart()
    app.secondsAtWhichToUseSpecial = {}
    app.nextSpecial = nil
    app.secondsCounter = 0
    app.minutesCounter = 0

    local lowCubesDueToPotentialMisunderstanding = 8
    local includeIntro = app.highestThisRound.iceCubes <= lowCubesDueToPotentialMisunderstanding
    app.highestThisRound.score = 0
    app.highestThisRound.iceCubes = 0
    app.highestThisRound.glass = app.highestAllTime.glass
    app.highestThisRound.olives = 0

    app.cubeDropDelay = app.cubeDropDelayInitial
    appRemoveSpritesByGroup(nil)
    appRemoveSpritesByType( {'menuPage', 'menuButton', 'menuText'} )
    app.gameOver = false

    appStart(includeIntro)
end

function appStart(includeIntro)
    if includeIntro == nil then includeIntro = false end
    app.highestThisRound.glass = app.highestAllTime.glass
    appCreateSprites(includeIntro)
    app.phase:set('default')
    app.extraPhase:set('default')
    if not app.musicStarted then appStartBackgroundMusic()
    else if app.playBackgroundMusic then audio.fade( {channel = app.musicChannel, time = 2000, volume = 1} ) end
    end
end

function appStartBackgroundMusic()
    if app.musicStarted then
        if app.playBackgroundMusic then audio.setVolume( 1, {channel = app.musicChannel} ) end
    else
        appPlaySound('theme', app.musicChannel, true, nil, true)
        audio.setVolume( misc.getIf(app.playBackgroundMusic, 1, 0), {channel = app.musicChannel} )
        app.musicStarted = true
    end
end

function appStopBackgroundMusic()
    if app.musicStarted then
        audio.stop(app.musicChannel)
        app.musicStarted = false
    end
end

function appCreateSprites(includeIntro)
    appRemoveSpritesByGroup(nil)
    if includeIntro == nil then includeIntro = false end
    app.spritesHandler:createBackground()
    -- app.spritesHandler:createGlowEffect()
    app.spritesHandler:createGround()
    app.spritesHandler:createWalls()
    app.spritesHandler:createTouchArea()
    if includeIntro then
        app.spritesHandler:createMessageImage('intro', app.maxXHalf, app.maxYHalf, app.maxX, app.maxY, .5, .5, nil, nil, nil, false)
    end
    app.spritesHandler:createScore()
    app.spritesHandler:createFly()
    app.menu:createButtons()
    appCreateClock(78, 35, nil, nil, 14, .7)
    appCreateDebug(app.maxXHalf, 65, nil, nil, 16, .9)
end

function appHandlePhases()
    app.phase:handleCounter()
    app.extraPhase:handleCounter()

    if app.phase.name == 'default' then
        if not app.phase:isInited() then
            appStartBackgroundMusic()
            app.phase:setNext('dropStartCubes', 180)
        end

    elseif app.phase.name == 'dropStartCubes' then
        if not app.phase:isInited() then
            if not app.gameOver then appDropStartCubes() end
            app.news:handle()
            app.phase:set('wait')
        end

    elseif app.phase.name == 'wait' then
        if not app.phase:isInited() then
            app.phase:setNext( 'dropCube', math.floor(app.cubeDropDelay) )
        end

    elseif app.phase.name == 'dropCube' then
        if not app.phase:isInited() then
            if not app.gameOver then

                if #app.nextCubeSubtypes >= 1 then
                    app.spritesHandler:createCube(nil, nil, app.nextCubeSubtypes[1])
                    table.remove(app.nextCubeSubtypes, 1)

                elseif app.nextSpecial == 'cherry' then
                    app.spritesHandler:createCherry()

                elseif app.nextSpecial == 'olive' then
                    app.spritesHandler:createOlive()

                elseif app.nextSpecial == 'multipleCubesHorizontal' then
                    local subtypes = appGetRandomDistinctCubeSubtypes(3)
                    for i = -1, 1 do
                        app.spritesHandler:createCube( app.maxXHalf + (i * 80), nil, subtypes[1] )
                        table.remove(subtypes, 1)
                    end

                elseif app.nextSpecial == 'multipleCubesVertical' then
                    local subtypes = appGetRandomDistinctCubeSubtypes(3)
                    local x = misc.getIfChance(nil, 80, app.maxX - 80)
                    for i = 1, 3 do
                        app.spritesHandler:createCube( x, -(i * 55), subtypes[i] )
                    end

                else
                    local randomSubtype = nil
                    while randomSubtype == nil or randomSubtype == app.lastCubeSubtype do
                        randomSubtype = math.random(1, app.maxCubeTypes)
                    end
                    app.spritesHandler:createCube(nil, nil, randomSubtype)

                end

                app.nextSpecial = nil
                app.phase:set('wait')

            end
        end

    elseif app.phase.name == 'showGameOver' then
        if not app.phase:isInited() then
            audio.fade( {channel = app.musicChannel, time = 1000, volume = 0} )
            appPlaySound('game-over')
            local scoreSprite = appGetSpriteByType('score')
            if scoreSprite then scoreSprite:toFront() end
            app.spritesHandler:createMessageImage('game-over', app.gameOverCauserX, 107, 210, 161, .5, .5, true, true, nil, true)

            --- app.highestThisRound.iceCubes = 300 --- for tests

            if app.highestThisRound.glass < #app.glasses then
                local cubesNeededForNextGlass = appGetCubesNeededForNextGlass()
                if app.highestThisRound.iceCubes > cubesNeededForNextGlass then
                    app.phase:setNext('showGlasWon', 100)
                else
                    app.phase:setNext('showScore', 150)
                end
            end
        end

    elseif app.phase.name == 'showGlasWon' then
        if not app.phase:isInited() then
            local message = appGetSpriteByType('message')
            if message ~= nil then message.energySpeed = -5 end

            local cubesNeededForNextGlass = appGetCubesNeededForNextGlass()
            local nextGlass = app.highestThisRound.glass + 1
            app.spritesHandler:createGlassMessage(nextGlass, cubesNeededForNextGlass)
            if nextGlass > app.glassesFreeStorageCanHold and not app.products[1].isPurchased then
                app.spritesHandler:createPurchaseMessage()
            else
                app.highestThisRound.glass = nextGlass
                app.phase:setNext('showScore', 330)
            end
        end

    elseif app.phase.name == 'showScore' then
        if not app.phase:isInited() then
            app.menu:showEndOfGameScore()
            appAmendHighscore()
            appSaveData()
        end

    end

    if not app.playBackgroundMusic and not app.gameOver and math.random(1, 1000) == 1 then appPlaySound('hum') end
end

function appHandleTimedEvents()
    local time = misc.padWithZero(app.minutesCounter) .. ':' .. misc.padWithZero(app.secondsCounter)
    local secondsAll = appGetTimeInSeconds()

    if misc.inArray( {'00:30', '00:50', '01:10', '01:40', '02:10', '02:30', '03:20', '05:00'}, time ) then
        app.cubeDropDelay = app.cubeDropDelay - 10
    end
    
    if app.secondsAtWhichToUseSpecial['cherry'] == nil then
        app.secondsAtWhichToUseSpecial['cherry'] = math.random(30, 50)
        app.secondsAtWhichToUseSpecial['multipleCubesHorizontal'] = math.random(30, 50)
        app.secondsAtWhichToUseSpecial['multipleCubesVertical'] = math.random(51, 70)
        app.secondsAtWhichToUseSpecial['olive'] = math.random(60, 80)
    end

    local special = 'olive'
    if secondsAll == app.secondsAtWhichToUseSpecial[special] then
        app.nextSpecial = special
        app.secondsAtWhichToUseSpecial[special] = app.secondsAtWhichToUseSpecial[special] + math.random(10, 20)
    end

    local special = 'cherry'
    if secondsAll == app.secondsAtWhichToUseSpecial[special] then
        if appGetSpriteCountByType(special) == 0 then
            app.nextSpecial = special
            app.secondsAtWhichToUseSpecial[special] = app.secondsAtWhichToUseSpecial[special] + math.random(30, 45)
        end
    end

    local special = 'multipleCubesHorizontal'
    if secondsAll == app.secondsAtWhichToUseSpecial[special] then
        app.nextSpecial = special
        app.secondsAtWhichToUseSpecial[special] = app.secondsAtWhichToUseSpecial[special] + math.random(10, 20)
    end

    local special = 'multipleCubesVertical'
    if secondsAll == app.secondsAtWhichToUseSpecial[special] then
        app.nextSpecial = special
        app.secondsAtWhichToUseSpecial[special] = app.secondsAtWhichToUseSpecial[special] + math.random(10, 20)
    end
end

function appDropStartCubes()
    local subtypes = appGetRandomDistinctCubeSubtypes(6)
    local n = 0
    for column = 1, 2 do
        for i = 1, 3 do
            n = n + 1
            local x = misc.getIf(column == 1, app.maxXHalf - 60, app.maxXHalf + 60)
            app.spritesHandler:createCube( x, -(i * 55), subtypes[n] )
        end
    end
    app.nextCubeSubtypes = {misc.getRandomEntry(subtypes)}
end

function appGetRandomDistinctCubeSubtypes(max)
    local subtypes = {}
    for i = 1, app.maxCubeTypes do subtypes[#subtypes + 1] = i end
    subtypes = misc.shuffleArray(subtypes)
    while #subtypes > max do table.remove(subtypes, 1) end
    return subtypes
end

function appSetGlasses()
    app.glasses[#app.glasses + 1] = { filename = '01-basic-glass', title = 'Basic Glass' }
    app.glasses[#app.glasses + 1] = { filename = '02-moon-glass', title = 'Moon Glass' }
    app.glasses[#app.glasses + 1] = { filename = '03-indestructible-mug', title = 'Indestructible Mug' }
    app.glasses[#app.glasses + 1] = { filename = '04-square-glass', title = 'Square Glass' }
    app.glasses[#app.glasses + 1] = { filename = '05-eye-glass', title = 'Eye Glass' }
    app.glasses[#app.glasses + 1] = { filename = '06-nose-glass', title = 'Nose Glass' }
    app.glasses[#app.glasses + 1] = { filename = '07-boots-mug', title = 'Boots Mug' }
    app.glasses[#app.glasses + 1] = { filename = '08-house-mug', title = 'House Mug' }
    app.glasses[#app.glasses + 1] = { filename = '09-spiked-glass', title = 'Spiked Glass' }
    app.glasses[#app.glasses + 1] = { filename = '10-face-mug', title = 'Face Mug' }
    app.glasses[#app.glasses + 1] = { filename = '11-bubble-glas', title = 'Bubble Glas' }
    app.glasses[#app.glasses + 1] = { filename = '12-mystery-mug', title = 'Mystery Mug' }
    app.glasses[#app.glasses + 1] = { filename = '13-tower-glass', title = 'Tower Glass' }
    app.glasses[#app.glasses + 1] = { filename = '14-fire-mug', title = 'Fire Mug' }
    app.glasses[#app.glasses + 1] = { filename = '15-sun-glass', title = 'Sun Glass' }
    app.glasses[#app.glasses + 1] = { filename = '16-magic-button-mug', title = 'Magic Button Mug' }
    app.glasses[#app.glasses + 1] = { filename = '17-diamond-glass', title = 'Diamond Glass' }
    app.glasses[#app.glasses + 1] = { filename = '18-hand-mug', title = 'Hand Mug' }
    app.glasses[#app.glasses + 1] = { filename = '19-foot-mug', title = 'Foot Mug' }
    app.glasses[#app.glasses + 1] = { filename = '20-alien-mug', title = 'Alien Mug' }
    app.glasses[#app.glasses + 1] = { filename = '21-hero-mug', title = 'Hero Mug' }
    app.glasses[#app.glasses + 1] = { filename = '22-magic-potion-glass', title = 'Magic Potion Glass' }
    app.glasses[#app.glasses + 1] = { filename = '23-caveman-mug', title = 'Caveman Mug' }
    app.glasses[#app.glasses + 1] = { filename = '24-knife-glass', title = 'Knife Glass' }
    app.glasses[#app.glasses + 1] = { filename = '25-endless-rope-mug', title = 'Endless Rope Mug' }
    app.glasses[#app.glasses + 1] = { filename = '26-pyramid-glass', title = 'Pyramid Glass' }
    app.glasses[#app.glasses + 1] = { filename = '27-eternal-ruby-glass', title = 'Eternal Ruby Glass' }
    app.glasses[#app.glasses + 1] = { filename = '28-flying-glass', title = 'Flying Glass' }
    app.glasses[#app.glasses + 1] = { filename = '29-glass-of-balance', title = 'Glass of Balance' }
    app.glasses[#app.glasses + 1] = { filename = '30-serpent-glass', title = 'Serpent Glass' }
    app.glasses[#app.glasses + 1] = { filename = '31-wheeled-glass', title = 'Wheeled Glass' }
    app.glasses[#app.glasses + 1] = { filename = '32-brick-glass', title = 'Brick Glass' }
    app.glasses[#app.glasses + 1] = { filename = '33-magic-molten-glass', title = 'Magic Molten Glass' }
    app.glasses[#app.glasses + 1] = { filename = '34-living-tentacle-mug', title = 'Living Tentacle Mug' }
    app.glasses[#app.glasses + 1] = { filename = '35-mug-of-worlds', title = 'Mug of Worlds' }
    app.glasses[#app.glasses + 1] = { filename = '36-double-faced-mug', title = 'Double Faced Mug' }
    app.glasses[#app.glasses + 1] = { filename = '37-stuck-sceptre-mug', title = 'Stuck Sceptre Mug' }
    app.glasses[#app.glasses + 1] = { filename = '38-living-tree-mug', title = 'Living Tree Mug' }
    app.glasses[#app.glasses + 1] = { filename = '39-mug-with-legs', title = 'Mug With Legs' }
    app.glasses[#app.glasses + 1] = { filename = '40-expandable-glass', title = 'Expandable Glass' }
    app.glasses[#app.glasses + 1] = { filename = '41-armored-glass', title = 'Armored Glass' }
    app.glasses[#app.glasses + 1] = { filename = '42-infinity-mug', title = 'Infinity Mug' }
    app.glasses[#app.glasses + 1] = { filename = '43-guiding-star-glass', title = 'Guiding Star Glass' }
    app.glasses[#app.glasses + 1] = { filename = '44-unliftable-mug', title = 'Unliftable Mug' }
    app.glasses[#app.glasses + 1] = { filename = '45-staircase-mug', title = 'Staircase Mug' }
    app.glasses[#app.glasses + 1] = { filename = '46-friendship-glass', title = 'Friendship Glass' }
    app.glasses[#app.glasses + 1] = { filename = '47-slide-glass', title = 'Slide Glass' }
    app.glasses[#app.glasses + 1] = { filename = '48-glass-of-success', title = 'Glass of Success' }
    app.glasses[#app.glasses + 1] = { filename = '49-infinite-power-mug', title = 'Infinite Power Mug' }
    app.glasses[#app.glasses + 1] = { filename = '50-relaxed-fly-glass', title = 'Relaxed Fly Glass' }
end

function appDefineTranslatedImages()
    app.translatedImages['zh'] = {
            {filename = 'news-dialog'},
            {filename = 'intro'},
            {filename = 'game-over'},
            {filename = 'menu/page/endOfGameScore'},
            {filename = 'menu/new-hi'},
            {filename = 'menu/button/playAgain'},
            {filename = 'menu/button/resumeGame'},
            {filename = 'purchaseText'},
            {filename = 'menu/button/purchaseNo'},
            {filename = 'menu/button/purchaseYes'}
            }
    app.translatedImages['de'] = {
            {filename = 'intro'},
            {filename = 'game-over'},
            {filename = 'menu/page/endOfGameScore'},
            {filename = 'menu/new-hi'},
            {filename = 'menu/button/playAgain'},
            {filename = 'menu/button/resumeGame'},
            {filename = 'purchaseText'},
            {filename = 'menu/button/purchaseNo'},
            {filename = 'menu/button/purchaseYes'}
            }
end

function appDefineImagesWhichFillScreen()
    local padSize = {width = 768, height = 1024}
    app.imagesWhichFillScreen = {
            {imageName = 'background', width = padSize.width, height = padSize.height},
            {imageName = 'menu/background', width = padSize.width, height = padSize.height},
            }
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

function appGetCubesNeededForNextGlass()
    local cubesNeededInitially = 60
    local cubesNeededAdditionPerGlass = 10
    local cubesNeeded = nil
    if app.highestAllTime.glass < #app.glasses then
        cubesNeeded = cubesNeededInitially + (app.highestAllTime.glass - 1) * cubesNeededAdditionPerGlass
    end
    return cubesNeeded
end

function appClass()
    app.title = 'Nervous Fly'
    app.name = 'nervousfly'
    app.version = '1.0'
    app.id = '449706857'
    app.runs = true
    app.defaultLanguage = 'en'
    app.language = appGetLanguage()

    app.showDebugInfo = false --- false
    app.isLocalTest = false --- false
    app.doPlaySounds = true --- true
    -- if true and app.isLocalTest then app.language = 'de' end

    app.device = system.getInfo('model')
    -- if app.isLocalTest then app.device = 'iPad' end

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
    app.glasses = {}
    app.userLevel = 1

    app.translatedImages = {}

    app.phase = phaseModule.phaseClass()
    app.phase:set('default')

    app.extraPhase = phaseModule.phaseClass()
    app.extraPhase:set('default')

    app.minX = 0
    app.maxX = 320
    app.minY = 0
    app.maxY = 480
    app.maxXHalf = math.floor(app.maxX / 2)
    app.maxYHalf = math.floor(app.maxY / 2)

    app.sprites = {}

    appSetFont( {'CreativeBlockBBBold', 'CreativeBlock BB Bold', 'CreativeBlock BB',
            'MarkerFelt-Thin', 'Marker Felt Thin Plain', 'ChalkboardSE-Bold'} )

    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    app.playerSprite = nil

    app.productIdPrefix = 'com.versuspad.' .. app.name .. '.'
    app.products = { { id = appPrefixProductId('infiniteStorage'), isPurchased = false } }

    app.maxCubeTypes = 7
    app.lastCubeSubtype = nil
    app.cubeDropDelayInitial = 100 --- 100 real, 15 for tests
    app.cubeDropDelay = app.cubeDropDelayInitial
    app.gameOver = false
    app.nextCubeSubtypes = {}
    app.nextSpecial = nil
    app.secondsAtWhichToUseSpecial = {}
    app.playBackgroundMusic = true
    app.currentGlassViewingInMenu = nil
    app.glassesFreeStorageCanHold = 2 --- todo later: set to 2
    app.glassSize = {width = 180, height = 111}
    app.musicStarted = false

    app.largeImageSuffix = '@2x'
    app.deviceResolution = {width = nil, height = nil}
    if app.device == 'iPad' then app.deviceResolution = {width = 768, height = 1024} end
    app.imagesWhichFillScreen = {}

    app.gameOverCauserX = nil

    app.highestAllTime = {score = 0, iceCubes = 0, glass = 1, olives = 0}
    app.highestThisRound = {score = 0, iceCubes = 0, glass = app.highestAllTime.glass, olives = 0}

    app.defaultDensity = 1
    app.defaultBounce = 0.2
    app.defaultFriction = 0.3

    app.groupsToHandleEvenWhenPaused = {'menu', 'menuButton', 'news'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()

    app.newsDialog = nil
end

init()
