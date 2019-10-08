module(..., package.seeall)
extraSpritesHandlerModule = require('extra-sprites-handler')

function extraClass()
local self = {}
self.name = nil
self.timeLastStartedOrEnded = nil
self.playerWhoCollected = nil
self.spritesHandler = extraSpritesHandlerModule.extraSpritesHandlerClass()
self.playerScore = {0, 0}

self.names = {'boxes', 'camouflage', 'captive', 'confusion', 'collectMania', 'covered', 'extraSpeed',
        'goldenArmor', 'hunter', 'iceLand', 'invisibility', 'longTails', 'magicGoal', 'magnet', 'movingWalls', 'maze',
        'multiball', 'rooms', 'rowCollect', 'shooters', 'speedMania', 'spikeValley', 'bigWheel', 'wobblyWorld'}
self.names[#self.names + 1] = 'rooms' -- add chances it will appear
self.titles = {goldenArmor = 'ARMOR', boxes = 'BOXES', camouflage = 'CAMOUFLAGE', captive = 'CAPTIVE',
        confusion = 'CONFUSION', collectMania = 'COLLECTORA', covered = 'COVERED',
        extraSpeed = 'SPEED', hunter = 'HUNTER', iceLand = 'ICELAND', invisibility = 'INVISIBILITY',
        longTails = 'LONGTAIL', magicGoal = 'MAGIC GOAL', magnet = 'MAGNET', movingWalls = 'WALLS', bigWheel = 'WHEEL', maze = 'MAZE', multiball = 'MULTIBALL',
        rooms = 'ROOMS', rowCollect = 'ROW COLLECT', shooters = 'SHOOTERS', speedMania = 'SPEEDMANIA', spikeValley = 'SPIKES', wobblyWorld = 'WOBBLE',
        training = 'TRAINING'}
self.iconShowsOnlyFor = {captive = 'other', extraSpeed = 'self', goldenArmor = 'self', longTails = 'self', hunter = 'other', magicGoal = 'self',
        training = 'self'}
self.backgrounds = {'confusion', 'iceLand', 'maze', 'wobblyWorld', 'rooms'}
self.poisonousSprites = {'hunter', 'spike', 'fakeBall'}
self.tookScreenshot = false
self.extraCounterOld = nil

function self:handle()
    local secondsWhichExtraRuns = 35
    local secondsToWaitBetweenExtraPills = 20 -- 20
    local timeNowInSeconds = appGetTimeInSeconds()

    if self.timeLastStartedOrEndedSeconds == nil then self.timeLastStartedOrEndedSeconds = timeNowInSeconds end
    local secondsDifferenceSinceLastStartedOrEnded = timeNowInSeconds - self.timeLastStartedOrEndedSeconds

    if self.name == 'training' then
        secondsWhichExtraRuns = nil
        if self.extraCounterOld ~= secondsDifferenceSinceLastStartedOrEnded then
            self.extraCounterOld = secondsDifferenceSinceLastStartedOrEnded
            if appGetSpriteCountByType('diamond') >= 1 then
                local label = appGetSpriteById('extraCounter' .. self.playerWhoCollected)
                if label ~= nil then
                    local max = 999
                    if secondsDifferenceSinceLastStartedOrEnded == 100 then label.size = 22
                    elseif secondsDifferenceSinceLastStartedOrEnded == max then label.size = 20
                    end
                    label.text = misc.trimNumber(secondsDifferenceSinceLastStartedOrEnded, max)
                end
            end
        end
    elseif self.name == 'rooms' then
        secondsWhichExtraRuns = 60
    end

    if self.name == nil then
        if secondsDifferenceSinceLastStartedOrEnded >= secondsToWaitBetweenExtraPills and appGetSpriteByType('extraPill') == nil then
            local ok = true
            if app.timeOfLastGoal ~= nil then
                local timeWithoutGoal = appGetTimeInSeconds() - app.timeOfLastGoal
                ok = timeWithoutGoal >= 8
            end
            if ok and ( appGetSpriteCountByType('countdown') >= 1 or appGetSpriteCountByType('announcement') >= 1 ) then
                ok = false
            end
            if ok then self.spritesHandler:createExtraPill() end
        end
    else
        if secondsWhichExtraRuns ~= nil and secondsDifferenceSinceLastStartedOrEnded >= secondsWhichExtraRuns then
            self:doEnd()
        end
    end
end

function self:doStart(playerWhoCollected, optionalName)
    if self.name == nil then
        self.playerWhoCollected = playerWhoCollected
        if optionalName == nil then
            self.name = self.names[ math.random(1, #self.names) ]
        else
            self.name = optionalName
        end
        -- self.name = self.names[15] -- for tests

        if misc.inArray(self.backgrounds, self.name) then
            appRemoveSpritesByType('background')
            appCreateBackground('extra/background/' .. self.name)
        end
        self.spritesHandler:createIcon(self.name, self.titles, self.iconShowsOnlyFor)

        if self.name == 'boxes' then
            self.spritesHandler:createBoxes()

        elseif self.name == 'covered' then
            self.spritesHandler:createCover()

        elseif self.name == 'bigWheel' then
            local yOffset = 150
            local xOffset = 90
            appRemoveSpritesByType('ball')
            self.spritesHandler:createBigWheel(xOffset)
            self.spritesHandler:createDiamond(180, app.maxY / 2, false)

            appResetWorms()
            local worms = appGetSpritesByType('wormPart', 'head')
            for i, worm in ipairs(worms) do
                worm.x = app.maxX / 2 - xOffset
                worm.y = app.maxY / 2 + (i - 1) * yOffset - yOffset / 2
            end

        elseif self.name == 'longTails' then
            appRemoveSpritesByType('wormPart', nil, self.playerWhoCollected)
            app.spritesHandler:createWormParts('extra', true, self.playerWhoCollected)

        elseif self.name == 'hunter' then
            self.spritesHandler:createHunter()

        elseif self.name == 'spikeValley' then
            self.spritesHandler:createSpikes()

        elseif self.name == 'camouflage' then
            appResetWorms()
            local worms = appGetSpritesByType('wormPart', 'head')
            for i, worm in ipairs(worms) do
                worm.x = 80
                if i == 2 then worm.x = app.maxX - worm.x end
                worm.y = app.maxY / 2
            end
            self.spritesHandler:createFakeBalls()

        elseif self.name == 'multiball' then
            app.spritesHandler:createBall(2, 'extra')

        elseif self.name == 'magnet' then
            self.spritesHandler:createMagnet()

        elseif self.name == 'movingWalls' then
            self.spritesHandler:createMovingWalls()

        elseif self.name == 'invisibility' then
            local sprites = appGetSpritesByType('wormPart')
            for id, sprite in pairs(sprites) do sprite.alpha = .23 end

        elseif self.name == 'goldenArmor' then
            appRemoveSpritesByType('wormPart', nil, self.playerWhoCollected)
            app.spritesHandler:createWormParts('extra', true, self.playerWhoCollected)

        elseif self.name == 'confusion' then
            local ballGlow = appGetSpriteByType('ballGlow')
            if ballGlow ~= nil then ballGlow.alpha = .65 end
            self.spritesHandler:createConfusion()

        elseif self.name == 'collectMania' then
            appRemoveSpritesByType('ball')
            self.playerScore = {0, 0}
            local margin = 80
            local maxPerQuarter = 3
            for xGrid = -maxPerQuarter, maxPerQuarter do
                for yGrid = -maxPerQuarter, maxPerQuarter do
                    local x = app.maxX / 2 + xGrid * margin
                    local y = app.maxY / 2 + yGrid * margin
                    self.spritesHandler:createDiamond(x, y)
                end
            end
            self.spritesHandler:createExtraCounters()

        elseif self.name == 'maze' then
            appRemoveSpritesByType('ball')
            local sprites = appGetSpritesByType('wormPart', 'head')
            for id, sprite in pairs(sprites) do  app.extra.spritesHandler:putWormInStartingPosition(sprite) end

            local margin = 5
            local rectangles = {
                    {179, 197 + margin, 589, 216 - margin},
                    {179 + margin, 217, 202 - margin, 442},
                    {292 + margin, 217, 315 - margin, 717},
                    {316, 702 + margin, 368, 723 - margin},
                    {179 + margin, 582, 202 - margin, 805}
            }
            for rectangleI = 1, #rectangles do
                for mirror = 1, 2 do
                    local x1 = rectangles[rectangleI][1] + 3
                    local y1 = rectangles[rectangleI][2]
                    local x2 = rectangles[rectangleI][3] + 3
                    local y2 = rectangles[rectangleI][4]
                    if mirror == 2 then
                        x1 = app.maxX - x1 + 5
                        y1 = app.maxY - y1
                        x2 = app.maxX - x2 + 5
                        y2 = app.maxY - y2
                    end
                    self.spritesHandler:createMazeWall(x1, y1, x2, y2)
                end
            end

            self.spritesHandler:createDiamond(app.maxX / 2, app.maxY / 2)

        elseif self.name == 'rooms' then
            appRemoveSpritesByType('ball')
            self.spritesHandler:createExtraCounters()
            local sprites = appGetSpritesByType('wormPart', 'head')
            for id, sprite in pairs(sprites) do  app.extra.spritesHandler:putWormInStartingPosition(sprite) end
            local rectangles = {
                    {21, 346, 'horizontal', nil},
                    {9, 352, 'vertical', nil},
                    {21, 503, 'horizontal', nil},
                    {9, 499, 'vertical', nil},
                    {21, 660, 'horizontal', nil},
                    {285, 343, 'vertical', nil},
                    {285, 509, 'vertical', nil}
            }
            for rectangleI = 1, #rectangles do
                for mirrorX = 1, 2 do
                    local x = rectangles[rectangleI][1]
                    local y = rectangles[rectangleI][2]
                    local horizontalOrVertical = rectangles[rectangleI][3]

                    local width = 168
                    local height = 26
                    if horizontalOrVertical == 'vertical' then
                        local temp = width
                        width = height
                        height = temp
                    end
                    if mirrorX == 2 then x = app.maxX - x - width + 9 end
                    self.spritesHandler:createFieldWall(x, y, 'long', horizontalOrVertical)
                end
            end
            self.spritesHandler:createFieldWall( 180, 419, 'long', 'vertical', nil, true, {y1 = 344, y2 = 674} )
            self.spritesHandler:createFieldWall( app.maxX - 179 - 9, 419, 'long', 'vertical', nil, true, {y1 = 346, y2 = 674} )

            local margin = 40
            self.spritesHandler:createFieldWall( 300, 346, 'long', 'horizontal', nil, true, {x1 = 182 - margin, x2 = 592 + margin} )
            self.spritesHandler:createFieldWall( 300, 660, 'long', 'horizontal', nil, true, {x1 = 182 - margin, x2 = 592 + margin} )

            self.spritesHandler:createDiamond(91, 430)
            self.spritesHandler:createDiamond(91, app.maxY - 430)
            self.spritesHandler:createDiamond(app.maxX / 2, app.maxY / 2)
            self.spritesHandler:createDiamond(app.maxX - 91, 430)
            self.spritesHandler:createDiamond(app.maxX - 91, app.maxY - 430)

        elseif self.name == 'shooters' then
            self.spritesHandler:createCannons()

        elseif self.name == 'rowCollect' then
            appRemoveSpritesByType('ball')
            local collectiblesMax = 4
            for playerI = 1, app.playerMax do
                for number = 1, collectiblesMax do
                    self.spritesHandler:createRowCollectible(playerI, number)
                end
            end

        elseif self.name == 'captive' then
            self.spritesHandler:createJail()
            local jailedSprite = appGetSpriteByType( 'wormPart', 'head', misc.getIf(self.playerWhoCollected == 1, 2, 1) )
            if jailedSprite ~= nil then
                jailedSprite.x = app.maxX / 2
                jailedSprite.y = app.maxY / 2
            end

            local x1 = app.maxX * .25
            local x2 = app.maxX * .75
            local ballX = x1
            local freeSpriteX = x2
            if misc.getChance() then
                ballX = x2
                freeSpriteX = 1
            end
            
            local ball = appGetSpriteByType('ball')
            if ball ~= nil then
                ball.x = ballX
                ball.y = app.maxY / 2
            end

            local freeSprite = appGetSpriteByType('wormPart', 'head', self.playerWhoCollected)
            if freeSprite ~= nil then
                freeSprite.x = freeSpriteX
                freeSprite.y = app.maxY / 2
            end

        elseif self.name == 'training' then
            appRemoveSpritesByType('background')
            appCreateBackground('extra/background/' .. self.name .. '-player-' .. self.playerWhoCollected)

            appRemoveSpritesByType('countdown')
            appRemoveSpritesByType('announcement')
            appRemoveSpritesByType('ball')
            appRemoveSpritesByType('atmosphere')
            appRemoveSpritesByType('wormPart')
            self.spritesHandler:createExtraCounters(true)
            appDisableBuzzersUntilBallReset()
            self.spritesHandler:createTrainingWalls()
            self.spritesHandler:createTrainingDiamonds()
            app.spritesHandler:createWormParts()
            appRemoveSpritesByType( 'wormPart', nil, misc.getIf(self.playerWhoCollected == 1, 2, 1) )

            local sprite = appGetSpriteByType('wormPart', 'head', self.playerWhoCollected)
            app.extra.spritesHandler:putWormInStartingPosition(sprite)

        end
        self.timeLastStartedOrEndedSeconds = appGetTimeInSeconds()
        appPlaySound('start-extra.mp3')
    end
end

function self:doEnd()
    appRemoveSpritesByType('extraPill')
    if self.name ~= nil then
        appRemoveSpritesByGroup('extra')

        local oldName = self.name
        self.name = nil
        local timeNowInSeconds = appGetTimeInSeconds()
        self.timeLastStartedOrEndedSeconds = timeNowInSeconds

        if misc.inArray(self.backgrounds, oldName) then appCreateBackground('background/default.png') end
    
        if oldName == 'iceLand' then
            for playerI = 1, app.playerMax do
                local sprite = appGetSpriteByType('wormPart', 'head', playerI)
                if sprite ~= nil then
                    sprite.data.speedX = nil
                    sprite.data.speedY = nil
                end
            end
        elseif oldName == 'longTails' then
            app.spritesHandler:createWormParts(nil, true, self.playerWhoCollected)
        elseif oldName == 'invisibility' then
            local sprites = appGetSpritesByType('wormPart')
            for id, sprite in pairs(sprites) do sprite.alpha = 1 end
        elseif oldName == 'goldenArmor' then
            app.spritesHandler:createWormParts(nil, true, self.playerWhoCollected)
        elseif misc.inArray( {'collectMania', 'rooms', 'maze', 'bigWheel' }, oldName ) then
            app.spritesHandler:createBall(1)
            local winner = nil
            if self.playerScore[1] > self.playerScore[2] then winner = 1
            elseif self.playerScore[1] < self.playerScore[2] then winner = 2
            else winner = math.random(1, app.playerMax)
            end
            appGoalScored( misc.getIf(winner == 1, 2, 1) )
            self.playerScore = {0, 0}
        elseif oldName == 'confusion' then
            local ballGlow = appGetSpriteByType('ballGlow')
            if ballGlow ~= nil then ballGlow.alpha = 1 end
        elseif oldName == 'rowCollect' then
            app.spritesHandler:createBall(1)
        elseif oldName == 'captive' then
            appResetWorms()
        elseif oldName == 'training' then
            appRemoveSpritesByType('extraCounter')
            appRemoveSpritesByType('announcement')
            appCreateBackground('background/default.png')
            app.spritesHandler:createAtmosphere()
        end
    
        self.playerWhoCollected = nil
        appPlaySound('end-extra.mp3')

        appRecreateWormsAndBallIfNeeded()
    end
end

function self:getInfo()
end

return self
end