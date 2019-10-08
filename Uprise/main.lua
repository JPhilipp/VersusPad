physics = require('physics')
misc = require('misc')
language = require('language-data')
dataModule = require('data-class')
sprite = require('sprite')
store = require('store')
spriteModule = require('sprite-class')
spritesHandlerModule = require('sprites-handler')
spritesHandlerInterfaceModule = require('sprites-handler-interface')
phaseModule = require('phase-class')
newsModule = require('news-class')
mapData = require('map-data')
require('app-misc')
require('app-purchasing')
require('sqlite3')
-- profiler = require 'Profiler'; profiler.startProfiler( {name = 'profilerResults', time = 10000, delay = 6000} )

app = {}

function appClass()
    app.title = 'Uprise'
    app.name = 'rebellion'
    app.version = '1.0'
    app.id = '880707603'
    app.runs = true
    app.defaultLanguage = 'en'
    app.language = appGetLanguage()

    app.showDebugInfo = false -- false
    app.isLocalTest = false -- false
    app.doPlaySounds = true -- true
    app.didLoadMapOnce = false

    app.device = system.getInfo('model')
    app.isIOs = app.device == 'iPad' or app.device == 'iPhone'
    app.isAndroid = not app.isIOs

    app.showClock = false and app.showDebugInfo
    app.framesCounter = 0
    app.framesPerSecondGoal = 30
    app.maxRotation = 360
    app.maxMeats = 10
    app.secondInMs = 1000
    app.secondsCounter = 0
    app.minutesCounter = 0
    app.playAllSounds = true
    app.difficulty = 1
    app.shownLogoThisSession = false

    app.maxThemes = 1
    app.importantSoundsToCache = {
            'bump', 'cannotDoThis', 'charge', 'click', 'crackle', 'dronePassed', 'explosion', 'multiply',
            'pickUp', 'putDown', 'shoot', 'teleport', 'magnet', 'smallBump/1', 'smallBump/2', 'smallBump/3',
            'newCreationObject'
            }
    app.cachedSounds = {}
    app.debugCounter = 0
    app.recentlyPlayedSounds = {}

    app.creationObjectOrder = {
        {'bumper', 'bumper'},
        {'bumper', 'charger'},
        {'portal', 'portal'},
        {'multiplier'},
        {'bumper', 'charger'},
        {'bumper', 'charger'},
        {'magnet', 'charger'},

        {'bumper', 'charger'},
        {'bumper', 'charger'},
        {'bumper', 'charger'},
        {'bumper'},
        {'multiplier'},
    }

    app.musicOrder = {}
    app.soundChannel = {music = 1}
    app.soundVolumeDefault = {.8}
    app.soundsQueue = {}
    app.didUseRotationRing = false

    app.translatedImages = {}

    app.phase = phaseModule.phaseClass()
    app.extraPhase = phaseModule.phaseClass()

    app.minX = 0; app.maxX = 1212
    app.minY = 0; app.maxY = 768
    app.maxXHalf = math.floor(app.maxX / 2); app.maxYHalf = math.floor(app.maxY / 2)
    app.minimumViewableRectangle = nil
    app.magneticMaxValue = misc.getDistance( {x = 0, y = 0}, {x = app.maxX, y = app.maxY} )

    app.sprites = {}

    appSetFont( {'Bio-discThin', 'bio-discthin', 'biost', 'bio disc', 'bio disc thin', 'biost.tff', 'Bio-disc Thin'}, '' ) --

    app.handleSpritesWhenGone = true

    app.mapPack = 1
    app.mapPackOld = nil
    app.mapPackMax = 3
    app.mapNumber = nil
    app.mapNumberToRepeat = nil
    app.wave = nil
    app.wavesGoal = 15
    app.lifeCountAtStart = 10
    app.lifeCount = app.lifeCountAtStart
    app.difficulty = nil
    app.creationEnergySpeedDefault = .0625
    app.creationEnergySpeed = app.creationEnergySpeedDefault
    app.creationEnergyMax = 100
    app.creationEnergy = app.creationEnergyMax

    app.difficultyMax = 3
    app.creationObjectIndex = 1

    app.rebelObjectSubtypes = {'bumper', 'magnet', 'multiplier', 'charger', 'portal'}
    app.droneSubtypes = {'default', 'slow', 'fast', 'plane'}
    app.wavePhase = phaseModule.phaseClass()

    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    -- app.pathData = pathDataModule.pathDataClass()
    app.spritesIndex = {}

    app.idInStore = 'com.versuspad.' .. app.name
    app.productIdPrefix = app.idInStore .. '.'
    app.products = {
        { id = appPrefixProductId('routes2'), title = 'Barricades Routes Pack', number = 2, price = nil, isPurchased = false },
        { id = appPrefixProductId('routes3'), title = 'Twinfire Routes Pack', number = 3, price = nil, isPurchased = false },
    }

    app.largeImageSuffix = '@2x'
    app.guidChars = nil

    app.doPlayBackgroundMusic = true

    app.defaultDensity = 1; app.defaultBounce = 0.2; app.defaultFriction = 0.3

    app.groupsToHandleEvenWhenPaused = {'news', 'interface'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()
    app.spritesHandlerInterface = spritesHandlerInterfaceModule.spritesHandlerInterfaceClass()

    app.alignmentRectangle = { x1 = app.minX, y1 = app.minY, x2 = app.maxX, y2 = app.maxY }

    if app.isLocalTest then
        -- physics.setDrawMode('debug')
        -- physics.setDrawMode('hybrid')
    end

    app.newsDialog = nil
end

function init()
    appInitDefaults(true, 60, 0)
    app.phase:set('mainGame')
end

function appLoadData()
    app.didLoadMapOnce = app.data:getBool('didLoadMapOnce', false)
    app.mapPack = app.data:get('mapPack', 1)
end

function appSaveData()
    app.data:setBool('didLoadMapOnce', app.didLoadMapOnce)
    app.data:set('mapPack', app.mapPack)
end

function appSetValuesToDefault()
    app.mapNumber = 1
    app.wave = 0
    app.lifeCount = app.lifeCountAtStart
    app.difficulty = 1
    app.creationEnergySpeed = .125
    app.creationEnergy = app.creationEnergyMax - 20
    app.creationObjectIndex = 1
end

function appHandlePhases()
    app.phase:handleCounter()

    if app.phase.name == 'default' then
        if not app.phase:isInited() then
            app.phase:set('mainGame')
        end

    elseif app.phase.name == 'mainGame' then
        if not app.phase:isInited() then
            -- app.mapPack = 1 --
            app.mapData = mapData.getAll(app.mapPack)
            if app.mapNumberToRepeat then
                app.mapNumber = app.mapNumberToRepeat
                app.mapNumberToRepeat = nil
                if app.mapNumber > #app.mapData then app.mapNumber = 1 end
            elseif not app.didLoadMapOnce then
                app.mapNumber = 28
                app.didLoadMapOnce = true
                appSaveData()
            else
                app.mapNumber = math.random(1, #app.mapData)
            end

            -- app.mapNumber = 28 -- #app.mapData --

            appRemoveSprites()
            appCreateDefaultSprites()
            app.spritesHandler:createBackground()
            app.spritesHandler:createBackgroundParticles()
            app.spritesHandler:createObstacles()
            app.spritesHandler:createTowers()
            -- appCreateTestObjects()
            app.spritesHandler:createSkyLights()
            app.spritesHandlerInterface:createPauseButton()
            app.spritesHandlerInterface:createWaveInfo()
            app.spritesHandlerInterface:createLifeInfo()
            app.spritesHandlerInterface:createCreationObjects()
            app.spritesHandlerInterface:createCreationBar()

            appStopAllSounds()
            appPlayNextMusic()
            app.wavePhase:setNext('start', 220)
            app.spritesHandler:createFadeOutBlack()
            if not app.shownLogoThisSession then
                app.spritesHandlerInterface:createLogo()
                app.shownLogoThisSession = true
            end
            -- app.spritesHandler:createDronePathLine(app.mapData[app.mapNumber].dronePath)
            -- app.spritesHandler:createDronePathLine(app.mapData[app.mapNumber].dronePathOther)

            if not app.purchasesInited then
                appInitPurchases()
                app.purchasesInited = true
            end
        end

        handleWaves()

        -- if appGetSpriteCountByType('black') == 0 and appGetSpriteCountByType('announce', 'win') == 0 then ...

    elseif app.phase.name == 'gameOver' then
        if not app.phase:isInited() then
            app.spritesHandler:createFadeInBlack(.5)
            app.spritesHandlerInterface:createAnnounce(nil, nil, 'GAME OVER', 50, false)

            local allTimeBestWaves = app.data:get('allTimeBestWaves_' .. app.mapPack .. '_' .. app.mapNumber, 1)
            if app.wave > allTimeBestWaves then
                app.spritesHandlerInterface:createNewBestAnnounce()
                app.data:set('allTimeBestWaves_' .. app.mapPack .. '_' .. app.mapNumber, app.wave)
            end
            app.spritesHandlerInterface:createRepeatRouteButton()
            appPlaySound('gameOver')

            app.phase:setNext('restart', 350)
        end

    elseif app.phase.name == 'restart' then
        if not app.phase:isInited() then
            appRemoveSpritesByType('drone')
            appRestart()
        end

    end
end

function appCreateTestObjects()
    app.spritesHandler:createRebelObject('bumper', 1055, 285)
    app.spritesHandler:createRebelObject('bumper', 1055, 185)
    app.spritesHandler:createRebelObject('bumper', 105, 613)
    app.spritesHandler:createRebelObject('bumper', 105, 713, 60)
    app.spritesHandler:createRebelObject('magnet', 984, 572)
    app.spritesHandler:createRebelObject('magnet', 662, 709)
    app.spritesHandler:createRebelObject('multiplier', 990, 508, 300)
    app.spritesHandler:createRebelObject('multiplier', 790, 508, 300)
    app.spritesHandler:createRebelObject('portal', 1084, 330)
    app.spritesHandler:createRebelObject('portal', 432, 651)
    app.spritesHandler:createRebelObject('charger', 200, 200)
end

function handleWaves()
    app.wavePhase:handleCounter()

    if app.wavePhase.name == 'start' then
        if not app.wavePhase:isInited() then
            app.wave = app.wave + 1
            app.spritesHandlerInterface:createAnnounce(nil, nil, 'WAVE ' .. app.wave, 50, true)
            local waveData = appGetWaveData()
            local offset = 0
            local marginBetweenGroups = 500
            local marginBetweenGroupMembers = 80

            for subwaveI = 1, #waveData do
                local subwave = waveData[subwaveI]
                local droneSubtype, droneCount = subwave[1], subwave[2]
                local droneData = appGetDroneData(droneSubtype)

                if subwaveI > 1 then
                    offset = offset + marginBetweenGroups * droneData.speedFactor
                end

                for droneI = 1, droneCount do
                    offset = offset + marginBetweenGroupMembers
                    app.spritesHandler:createDrone(droneSubtype, offset, droneI)
                end
            end
        end

        if appGetSpriteCountByType('drone') == 0 and app.wavePhase.nameNext ~= 'start' then
            if app.wave == app.wavesGoal then
                app.spritesHandlerInterface:createYouWonAnnounce()
                app.wavePhase:setNext('start', 290)
            else
                app.wavePhase:setNext('start', 190)
            end
        end
    end
end

function appGetDroneData(subtype)
    local data = {}
    local baseEnergy = 120

    if subtype == 'default' then
        data = {
            baseEnergy = baseEnergy, speedFactor = 1
        }

    elseif subtype == 'strong' then
        data = {
            baseEnergy = math.floor(baseEnergy * 2.5), speedFactor = .5
        }

    elseif subtype == 'fast' then
        data = {
            baseEnergy = baseEnergy, speedFactor = 1.1
        }

    elseif subtype == 'plane' then
        data = {
            baseEnergy = baseEnergy, speedFactor = 1.1
        }

    end

    return data
end

function appGetWaveData()
    local data = {}

    if app.wave == 1 then
        data = {
                {'default', 2},
                {'default', 4},
            }

    elseif app.wave == 2 then
        data = {
                {'default', 3},
                {'strong', 1}
            }

    else

        if math.mod(app.wave, 3) == 0 then
            data = {
                    {'default', 2}
                }

        elseif math.mod(app.wave, 5) == 0 then
            data = {
                    {'default', 8},
                    {'strong', 3},
                }

        elseif math.mod(app.wave, 8) == 0 then
            data = {
                    {'default', 10},
                    {'strong', 4}
                }

        else
            data = {
                    {'default', 4},
                    {'default', 3}
                }

        end

    end

    return data
end

function appCreateDefaultSprites()
    appCreateClock(app.maxXHalf, app.alignmentRectangle.y1 + 10, nil, nil, 25, .6)
    appCreateDebug(app.maxXHalf, app.alignmentRectangle.y1 + 40, nil, nil, 25, .9)
end

function appDefineTranslatedImages()
end

function appHilightNavigation()
    local sprites = appGetSpritesByType( {'navigationRebelObject', 'pauseButton'} )
    for i = 1, #sprites do sprites[i].alpha = sprites[i].data.alphaDefault end
end

function appLolightNavigation()
    local sprites = appGetSpritesByType( {'navigationRebelObject', 'pauseButton'} )
    for i = 1, #sprites do sprites[i].alpha = .25 end
end

function appHandleDamage(drone, bullet)
    local damage = misc.keepInLimits(bullet.energy, nil, 100)
    bullet.energy = bullet.energy - drone.energy * .5
    drone.energy = drone.energy - damage
    app.spritesHandler:createSparks(bullet.x, bullet.y, damage * .25)
    appPlaySound( 'smallBump/' .. math.random(1, 3) )

    local healthBar = appGetSpriteByTypeAndParentId('droneHealthBar', drone.id)
    if healthBar == nil then app.spritesHandler:createDroneHealthBar(drone) end
end

function appGetTargetPortal(selfPortal, bullet)
    local targetPortal = nil
    local portals = appGetSpritesByType('rebelObject', 'portal')

    for i = 1, #portals do
        local portal = portals[i]
        if portal.id ~= selfPortal.id and portal.data.connectionGroup == selfPortal.data.connectionGroup then
            local didTeleport = portal.data.didTeleportBullet[bullet.id] ~= nil and portal.data.didTeleportBullet[bullet.id]
            if not didTeleport then
                targetPortal = portal
            end
            break
        end
    end

    return targetPortal
end

function appHandleGeneralCollideBehavior(rebelObject, bullet)
    if bullet == nil or bullet.group ~= 'interface' then
        local ghost = app.spritesHandler:createGhost(rebelObject)
        ghost.group = 'interface'
        ghost:setFillColor(255, 255, 0, 100)
        ghost.energy = 100
        ghost.energySpeed = -3
        ghost.scaleSpeed = 1.01
        ghost.blendMode = 'add'
        ghost:toFront()
    
        if bullet ~= nil then
            app.spritesHandler:createSparks(bullet.x, bullet.y, 2)
        end
    end
end

function appGetRebelObjectData(subtype)
    local defaultSize = 72
    data = {
            bumper =     { width = 61, height = 61, radius = nil },
            multiplier = { width = 73, height = 73, radius = nil },
            magnet =     { width = defaultSize, height = defaultSize, radius = 125 },
            portal =     { width = defaultSize, height = defaultSize, radius = math.floor(defaultSize * .25) },
            charger =    { width = defaultSize, height = defaultSize, radius = math.floor(defaultSize * .5) },
        }
    return data[subtype]
end

function appHandleRotationRing(self)
    if self.data.isRotateable then
        local ring = appGetSpriteByTypeAndParentId('rotationRing', self.id)
        if ring ~= nil then
            if ring.energySpeed < 0 then
                ring.energy = ring.energyMax
                ring.energySpeed = ring.data.energySpeedDefault
            end
        else
            app.spritesHandler:createRotationRing(self)
            self:toFront()
        end

    else
        appRemoveSpritesByType('rotationRing')

    end
end

function appGetReadyText()
    local s, isExtraWide = '', false

    local differentSubtypes = {}
    local translation = {bumper = 'reflector', multiplier = 'splitter'}

    local creationObjects = appGetSpritesByType('creationObject')
    for i = 1, #creationObjects do
        local object = creationObjects[i]
        local subtype = object.subtype
        if translation[subtype] ~= nil then subtype = translation[subtype] end
        subtype = string.upper(subtype)
        if misc.inArray(differentSubtypes, subtype) or misc.inArray(differentSubtypes, subtype .. 'S') then
            if differentSubtypes[1] == subtype then
                differentSubtypes[1] = differentSubtypes[1] .. 'S'
            end
        else
            table.insert(differentSubtypes, 1, subtype)
        end
    end

    s = misc.join(differentSubtypes, ' + ') .. "\nREADY TO DRAG"
    isExtraWide = #differentSubtypes >= 2

    return s, isExtraWide
end

function appGetOtherPortalGroupCount(connectionGroupToIgnore)
    local groups = {}

    local portals = appGetSpritesByType('rebelObject', 'portal')
    for i = 1, #portals do
        local portal = portals[i]
        if portal.data.connectionGroup ~= connectionGroupToIgnore and not misc.inArray(groups, portal.data.connectionGroup) then
            groups[#groups + 1] = portal.data.connectionGroup
        end
    end

    return #groups
end

function appTrySelectPurchasedRoutesPack(packNumber)
    local isPurchased = packNumber == 1 or appGetProductIsPurchasedPerDB( appPrefixProductId('routes' .. packNumber) )
    if isPurchased then
        app.mapPack = packNumber
        appRemoveSpritesByType('packsMenu', 'lock' .. packNumber)

        for i = 1, app.mapPackMax do
            local packBack = appGetSpriteByType('packsMenu', 'packBack' .. i)
            packBack.isVisible = i == app.mapPack
        end
    end
end

function appTogglePausePlay()
    local types = {'drone', 'bullet', 'tower'}
    app.runs = not app.runs
    appPlaySound('click')
    local button = appGetSpriteByType('pauseButton')

    if not app.runs then
        local back = appGetSpriteByType('background')
        if back then back.alpha = .7 end

        appStopSprites(types)
        local towers = appGetSpritesByType('tower')
        for i = 1, #towers do
            local tower = towers[i]
            tower.phase:set('shoot')
        end
        button.frameName = 'resume'

        audio.setVolume( .1, { channel = app.soundChannel.music } )

        app.spritesHandlerInterface:createAbout()
        app.spritesHandlerInterface:createPacksMenu()
        appRemoveSpritesByType('logo')
        app.mapPackOld = app.mapPack

    else
        local back = appGetSpriteByType('background')
        if back then back.alpha = 1 end

        appStartSprites(types)
        local sprites = appGetSpritesByType( {'trailLine', 'bullet'} )
        for i = 1, #sprites do
            local sprite = sprites[i]
            if sprite.group == 'interface' then
                sprite.gone = true
            end
        end
        button.frameName = 'pause'
        audio.setVolume( app.soundVolumeDefault[app.soundChannel.music], { channel = app.soundChannel.music } )

        appSaveData()
        appRemoveSpritesByType( {'about', 'packsMenu'} )
        if app.mapPackOld ~= app.mapPack then
            appRestart()
        end

    end
end

function appGetCollisionFilter(self)
    local filter = {}
    local categoryDefault =                  '       X'
    local categoryBullet =                   '      X '
    local categoryBulletClone =              '     X  '
    local categoryMultiplier =               '    X   '

    local maskDefault =                      ' XXXXXXX'
    local maskIgnoresBullets =               ' XXXXX X'
    local maskIgnoresAllButBullets =         '     XX '
    local maskIgnoresBulletsAndMultipliers = ' XXX   X'
    local maskIgnoresBulletClones =          ' XXXX XX'

    filter.categoryBits = categoryDefault
    filter.maskBits = maskDefault

    if self.type == 'bullet' and self.subtype == 'clone' then
        filter.categoryBits = categoryBulletClone
        filter.maskBits = maskIgnoresBulletsAndMultipliers

    elseif self.type == 'bullet' then
        filter.categoryBits = categoryBullet
        filter.maskBits = maskIgnoresBullets

    elseif self.type == 'rebelObject' and self.subtype == 'multiplier' then
        filter.categoryBits = categoryMultiplier
        filter.maskBits = maskIgnoresBulletClones

    elseif self.type == 'drone' then
        filter.maskBits = maskIgnoresAllButBullets

    end

    filter.categoryBits = misc.binaryToDecimal(filter.categoryBits, 'X')
    filter.maskBits = misc.binaryToDecimal(filter.maskBits, 'X')
    return filter
end

init()
