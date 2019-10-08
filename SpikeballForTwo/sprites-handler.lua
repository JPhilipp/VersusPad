module(..., package.seeall)
local moduleGroup = nil

function spritesHandlerClass()
local self = {}

function self:createWormParts(group, useExistingWormsForReference, optionalSpecificPlayer)
    local function handle(self)
        if not self.inited then self.namesWithFrames = {'default', 'poisoned'} end
    
        if self.subtype == 'head' then
            if not self.inited then self:toFront() end

            if self.phase.name == 'default' or self.phase.name == 'justRecoveredFromPoison' then
                local defaultRotationSpeedLimit = nil

                local defaultSpeedLimit = 12
                local isJailed = app.extra.name == 'captive' and app.extra.playerWhoCollected ~= self.parentPlayer
                if isJailed then
                    defaultSpeedLimit = 6
                    self.speedLimit = defaultSpeedLimit
                end

                local resetSpin = false
                resetSpin = misc.getChance(10)

                if self.phase.name == 'default' then
                    if not self.phase:isInited() then
                        self.rotationSpeedLimit = defaultRotationSpeedLimit
                        self.phase.nameNext = 'default'
                        self.phase.counter = 20
                        self.speedLimit = defaultSpeedLimit
                        resetSpin = true
                    end

                elseif self.phase.name == 'justRecoveredFromPoison' then
                    if not self.phase:isInited() then
                        self.rotationSpeedLimit = defaultRotationSpeedLimit
                        self.phase.nameNext = 'default'
                        self.phase.counter = 20
                        self.speedLimit = defaultSpeedLimit
                        resetSpin = true
                    end
        
                end

                if self.collisionWith ~= nil then
                    if self.collisionWith.type == 'wormPart' and
                            (self.collisionWith.subtype == 'spikedBody' or self.collisionWith.subtype == 'spikedTail' or self.collisionWith.data.hasSpikedArmor) then
                        if self.collisionWith.phase.name == 'poisoned' then
                            self.phase:set('underCollisionShock', 30, 'default')
                        elseif self.phase.name ~= 'justRecoveredFromPoison' and not self.data.hasSpikedArmor then
                            self.phase:set('poisoned', app.timeFramesToPoison, 'justRecoveredFromPoison')
                        end

                    elseif self.collisionWith.type == 'wall' then
                        if self.collisionForce >= app.forceConsideredSomething and ( app.controlWasUsed[self.parentPlayer] or misc.getChance(5) ) then
                            app.spritesHandler:createSparks(self.x, self.y)
                        end

                    elseif misc.inArray(app.extra.poisonousSprites, self.collisionWith.type) and self.phase.name ~= 'justRecoveredFromPoison' then
                        if self.collisionWith.type == 'hunter' then
                            self.phase:set('poisoned', app.timeFramesToPoison, 'justRecoveredFromPoison')
                        else
                            self.phase:set('poisoned', app.timeFramesToPoisonShort, 'justRecoveredFromPoison')
                        end

                    end

                    if self.collisionForce >= app.forceConsideredSomething then
                        if self.collisionWith.type == 'ball' then
                            appPlaySound('ball-collision')
                        elseif self.collisionWith.type == 'wall' and app.controlWasUsed[self.parentPlayer] then
                            if self.extraPhase.name == 'default' then
                                appPlaySound('wall-collision')
                                self.extraPhase:set('pauseSound', 75, 'default')
                            end
                        elseif self.collisionWith.type == 'box' then
                            if self.extraPhase.name == 'default' then
                                appPlaySound('bump')
                                self.extraPhase:set('pauseSound', 30, 'default')
                            end
                        end
                    end
                end

                if resetSpin then self:resetSpin() end

                if self.action.boost and self.phase.name == 'default' and app.extra.name ~= 'iceLand' and not isJailed then
                    self.phase:set('boost', 20, 'default')
                end

                local adjustDelayed = app.extra.name == 'iceLand'

                local doAdjustSpeedToRotation = true
                if app.extra.name == 'wobblyWorld' then
                    doAdjustSpeedToRotation = misc.getChance(60)
                end

                if doAdjustSpeedToRotation then self:adjustSpeedToRotation(adjustDelayed) end

                if app.extra.name == 'wobblyWorld' then appPushRandomlySometimes(self, 350) end

                if misc.getChance(3) then app.spritesHandler:createSparks(self.x, self.y, 1, nil, 0, 0) end
        
            elseif self.phase.name == 'boost' then
                if not self.phase:isInited() then
                    self.frameName = 'default'
                    self.speedLimit = 40
                    appPlaySound('boost')
                end

                if self.collisionWith ~= nil then
                    if self.collisionWith.type == 'wall' then
                        if self.collisionForce >= app.forceConsideredSomething then
                            app.spritesHandler:createSparks(self.x, self.y)
                            appPlaySound('wall-collision')
                        end
                        self.phase:set('underCollisionShock', 30, 'default')
                    elseif misc.inArray(app.extra.poisonousSprites, self.collisionWith.type) and self.phase.name ~= 'justRecoveredFromPoison' then
                        self.phase:set('poisoned', app.timeFramesToPoisonShort, 'justRecoveredFromPoison')
                    elseif self.collisionWith.type == 'ball' then
                        appPlaySound('ball-collision')
                    end
                end

                if misc.getChance(50) then
                    local color = misc.getIf( self.parentPlayer == 1, {red = 51, green = 255, blue = 255}, {red = 255, green = 119, blue = 252} )
                    if app.extra.name == 'goldenArmor' then color = {red = 255, green = 223, blue = 44}  end
                    app.spritesHandler:createSparks(self.x, self.y, nil, nil, 0, 0, color)
                end
        
                self:adjustSpeedToRotation()
                self.speedLimit = self.speedLimit - 1
        
            elseif self.phase.name == 'poisoned' then
                if not self.phase:isInited() then
                    self.speedLimit = 1
                    self.rotationSpeedLimit = 0
                    appPlaySound('poisoned')
                end
        
            elseif self.phase.name == 'underCollisionShock' then
                if not self.phase:isInited() then
                end
        
            end
            -- if self.parentPlayer == 1 then appDebug( self.phase:getInfo() ) end
        
        else -- if self.subtype == 'body' or self.subtype == 'spikedBody' or self.subtype == 'spikedTail' then
            if self.targetSprite ~= nil then
                if self.targetSprite.phase ~= nil and self.targetSprite.phase.name ~= self.phase.name then
                    self.phase.name = self.targetSprite.phase.name
                end
    
                self:followTargetSpritePath()
                if misc.getChance(5) then self:resetSpin() end
            end
        end
    end

    local spikedBodyMax = 5
    if app.extra.name == 'longTails' and optionalSpecificPlayer == app.extra.playerWhoCollected then
        spikedBodyMax = 14
    end

    local subtypes = {'head', 'body'}
    for i = 1, spikedBodyMax do table.insert(subtypes, 'spikedBody') end
    table.insert(subtypes, 'spikedTail')

    for playerI = 1, app.playerMax do
        local doCreate = true
        if optionalSpecificPlayer ~= nil then doCreate = optionalSpecificPlayer == playerI end

        if doCreate then
            local lastSprite = nil
    
            for subtypeI, subtype in ipairs(subtypes) do
                local imageName = 'worm-player-' .. playerI .. '/' .. subtype
    
                local width = 35
                local height = 30
                local widthInner = width - 5
                local heightInner = height - 3
                local shape = nil
                local followDelay = nil
    
                if subtype == 'head' then
                    width = 58
                    widthInner = width - 7
                    shape = {5, 6,
                            53, 6,
                            53, 13,
                            37, 27,
                            21, 27,
                            5, 13}
                    heightInner = height - 6

                elseif subtype == 'body' or subtype == 'spikedBody' then
                    shape = {12, 4,
                            24, 4,
                            29, 14,
                            29, 36,
                            6, 36,
                            6, 14}
                    heightInner = height - 6
    
                elseif subtype == 'spikedTail' then
                    shape = {12, 4,
                            23, 4,
                            29, 13,
                            29, 20,
                            18, 28,
                            6, 20,
                            6, 12}
                    heightInner = height - 4

                end

                local x = 230
                local y = 650 + (subtypeI -1) * heightInner
                if playerI == 2 then
                    x = app.maxX - x
                    y = app.maxY - y
                end
    
                local rotation = 0
                if subtype == 'head' and playerI == 2 then rotation = 180 end
    
                if useExistingWormsForReference then
                    if subtype == 'head' then
                        local existingWorm = appGetSpriteByType('wormPart', 'head', playerI)
                        if existingWorm ~= nil then
                            x = existingWorm.x
                            y = existingWorm.y
                            rotation = existingWorm.rotation
                        end
                    else
                        x = -200
                        y = -200
                    end
                end
    
                local frames = {'default', 'poisoned'}
    
                if app.extra.name == 'goldenArmor' then
                    imageName = 'extra/worm/' .. subtype
                    frames = {'default'}
                end

                local framesData = {
                        image = {width = width * #frames, height = height, count = #frames},
                        names = {
                        {name = 'default', start = 1},
                        {name = 'poisoned', start = #frames}
                        }
                        }

                local self = spriteModule.spriteClass('rectangle', 'wormPart', subtype, imageName, true, x, y, width, height,
                        framesData, shape, playerI)
                self.group = group

                self.data.hasSpikedArmor = app.extra.name == 'goldenArmor'

                self.isBullet = true
                self.isSleepingAllowed = false
                self.phasesWithFrameNames  = {'default', 'poisoned'}
                self.emphasizeAppearance = subtype == 'head'
                self.doDieOutsideField = false
                self.alsoAllowsExtendedNonPhysicalHandling = false
                if followDelay ~= nil then self.followDelay = followDelay end

                self.rotation = rotation
                self.rotationImageOffset = 90
                self.isBullet = true
    
                if lastSprite ~= nil then
                    self.targetSprite = lastSprite
                    self.doFollowTarget = false
                end

                if self.subtype == 'head' then
                    self.listenToPostCollision = true
                end
    
                appAddSprite(self, handle, moduleGroup)
    
                lastSprite = self
            end

        end
    end
end

function self:createWalls()
    local safety = 60
    self:createWallAndPotentiallyMirror('default', 295 - safety * 2, 0, 10 + safety * 2, 97, true, true, true) -- top left goal post & mirrored friends
    self:createWallAndPotentiallyMirror('default', 2 - safety, 340, 9 + safety, 341, true, false, false) -- left wall & mirrored friend
    self:createWallAndPotentiallyMirror('net', 300, 0, 169, 65, false, true, false) -- goal sensor & mirrored friend

    -- diagonal walls
    self:createWall('default', 89, 224, 492, 72, -45)
    self:createWall('default', app.maxX - 89, 224, 492, 72, 45)
    self:createWall('default', 102, app.maxY - 212, 492, 72, 225)
    self:createWall('default', app.maxX - 102, app.maxY - 212, 492, 72, 135)

    self:createBuzzerWalls()
    self:createGoalZones()
end

function self:createGoalZones()
    for playerI = 1, app.playerMax do
        local isAutoPhysical = true
        local width = 163
        local height = 98
        local x = app.maxX / 2
        local y = app.maxY - height / 2
        local self = spriteModule.spriteClass('rectangle', 'goalZone', nil, nil, isAutoPhysical, x, y, width, height, nil, nil, playerI)

        self.bodyType = 'static'
        self.isVisible = false
        self.isHitTestable = true

        self.alpha = 0
        self:setRgbWhite()
        self:setFillColorBySelf()

        if playerI == 2 then self.y = app.maxY - self.y end
    
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createBuzzerWalls()
    local width = 222
    local height = 83
    local shape = {30, 38,
        190, 38,
        190, 51,
        30, 51}
    for parentPlayerI = 1, app.playerMax do
        local x = app.maxX / 2 - width / 2
        local y = app.maxY - 119
        if parentPlayerI == 2 then y = app.maxY - y - 86 end
        self:createWall('buzzer', x, y, width, height, nil, 'buzzer', 1, 2, shape, parentPlayerI)
    end
    appDisableBuzzersUntilBallReset()
end

function self:createGoalEffects(goalWhichWasHitParentPlayerI)
    self:createGoalEffectWaves(goalWhichWasHitParentPlayerI)
    self:createGoalEffectText(goalWhichWasHitParentPlayerI)
end

function self:createGoalEffectText(goalWhichWasHitParentPlayerI)
    local height = 62
    local margin = 15
    local self = spriteModule.spriteClass('rectangle', 'goalEffectText', nil,
            'goal-' .. goalWhichWasHitParentPlayerI .. '-hit', false, app.maxX / 2, app.maxY - height / 2 - margin, 131, height)
    if goalWhichWasHitParentPlayerI == 2 then
        self.y = app.maxY - self.y
    end
    self.energy = 425
    self.energySpeed = -5
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createGoalEffectWaves(goalWhichWasHitParentPlayerI)
    local maxWaves = 4
    for waveI = 1, maxWaves do
        local height = 131
        local y = app.maxY - height / 2
        if goalWhichWasHitParentPlayerI == 2 then y = app.maxY - y end

        local self = spriteModule.spriteClass('rectangle', 'goalEffectWave', nil, 'player-scores-back', false, app.maxX / 2, y, 215, height)
        self.energySpeed = -1
        self.alphaChangesWithEnergy = true
        self.speedY = -(.5 + waveI)
        self.doDieOutsideField = false
    
        if goalWhichWasHitParentPlayerI == 2 then
            self.rotation = 180
            self.speedY = self.speedY * -1
        end
    
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createWallAndPotentiallyMirror(subtype, x, y, width, height, alsoMirrorX, alsoMirrorY, alsoMirrorXY)
    self:createWall(subtype, x, y, width, height)
    if alsoMirrorX then self:createWall(subtype, app.maxX - x - width + 2, y, width, height) end
    if alsoMirrorY then self:createWall(subtype, x, app.maxY - y - height + 1, width, height) end
    if alsoMirrorXY then self:createWall(subtype, app.maxX - x - width + 2, app.maxY - y - height + 1, width, height) end
end

function self:createWall(subtype, x, y, width, height, rotation, imageName, spriteSheetFrom, spriteSheetTo, shape, parentPlayer)
    local function handle(self)
        if self.subtype == 'buzzer' then
            if self.phase.name == 'default' or self.phase.name == 'onForLonger' then
                if not self.phase:isInited() then
                    if self.data.oldY ~= nil then self.y = self.data.oldY end

                    self.phase.nameNext = 'off'
                    local timeFrames = 75

                    if self.phase.name == 'onForLonger' then
                        timeFrames = 140
                    elseif app.thereWasLongTimeWithoutGoal then
                        timeFrames = 40
                    else
                        local otherPlayerI = misc.getIf(self.parentPlayer == 1, 2, 1)
                        if app.score[otherPlayerI] ~= nil and app.score[otherPlayerI] >= 2 then
                            timeFrames = timeFrames + app.score[otherPlayerI] * 40
                        end
                    end

                    self.phase.counter = timeFrames
                end

            elseif self.phase.name == 'off' or self.phase.name == 'offForLonger' or self.phase.name == 'offUntilBallReset' then
                if not self.phase:isInited() then
                    local somewhereOutsideScreenWorkaround = -200
                    if self.y ~= somewhereOutsideScreenWorkaround then
                        self.data.oldY = self.y
                        self.y = somewhereOutsideScreenWorkaround
                    end
    
                    if app.thereWasLongTimeWithoutGoal then
                        self.phase.nameNext = 'default'
                        self.phase.counter = 400
                    elseif self.phase.name == 'off' then
                        self.phase.nameNext = 'default'
                        self.phase.counter = 300 -- was 220
                    end
                end
    
            end

        end
    end    

    local framesData = nil
    if imageName ~= nil and not (spriteSheetTo == nil or spriteSheetTo == 1 or spriteSheetTo == 0) then
        framesData = {
                image = {width = width * spriteSheetTo, height = height, count = spriteSheetTo},
                names = {
                {name = 'default', start = 1, count = spriteSheetTo, time = 180, loopDirection = 'forward'}
                }
                }
    end

    local self = spriteModule.spriteClass('rectangle', 'wall', subtype, imageName, true, x, y, width, height,
            framesData, shape, parentPlayer)
    self.alsoAllowsExtendedNonPhysicalHandling = false

    if imageName ~= nil then self.frameName = 'default' end

    if rotation ~= nil then self.rotation = rotation
    else self:setPosFromLeftTop(x, y, width, height)
    end

    self.bodyType = 'static'
    if imageName == nil then
        self.isHitTestable = true
        self.isVisible = false
    end

    self.isSleepingAllowed = false
    self.parentPlayer = parentPlayer
    self.isBullet = true

    if subtype == 'net' then
        self.doDieOutsideField = false
        self.parentPlayer = misc.getIf(y < app.maxY / 2, 2, 1)
    end

    appAddSprite(self, handle, moduleGroup)
end

function self:createBall(max, group)
    if max == nil then max = 1 end

    local function handle(self)
        if self.phase.name == 'default' then

            local showSparks = true
            if app.extra.name == 'magicGoal' then
                local enemyPlayer = misc.getIf(app.extra.playerWhoCollected == 1, 2, 1)
                local goal = appGetSpriteByType('wall', 'net', enemyPlayer)
                if goal ~= nil then self:magneticTowards(goal.x, goal.y) end
            end

            if misc.getChance(10) and showSparks then
                app.spritesHandler:createSparks(self.x, self.y, 1)
            end

            if app.extra.name == 'wobblyWorld' then appPushRandomlySometimes(self, 1) end

            if self.collisionWith ~= nil then
                if self.collisionWith.type == 'wall' and self.collisionWith.subtype == 'net' then
                    if appGetSpriteCountByType('announcement') == 0 then
                        self.phase:set('justHitGoal', 200, 'positionAtStart')
                        appGoalScored(self.collisionWith.parentPlayer)
                    end

                elseif self.collisionWith.type == 'wall' or self.collisionWith.type == 'movingWall' then
                    if self.collisionForce >= app.forceConsideredSomething then
                        appPlaySound('wall-collision')
                    elseif not misc.inArray( {'magnet', 'wobblyWorld', 'magicGoal'}, app.extra.name ) then
                        local pushX = 0
                        local pushY = 0
                        local pushForce = 20
                        if self.collisionWith.rotation == -45 then
                            pushX = pushForce
                            pushY = pushForce
                        elseif self.collisionWith.rotation == 45 then
                            pushX = -pushForce
                            pushY = pushForce
                        elseif self.collisionWith.rotation == 135 then
                            pushX = -pushForce
                            pushY = -pushForce
                        elseif self.collisionWith.rotation == 225 then
                            pushX = pushForce
                            pushY = -pushForce
                        else
                            local margin = 50
                            if self.x < margin then
                                pushX = pushForce
                            elseif self.x > app.maxX - margin then
                                pushX = -pushForce
                            elseif self.y < app.maxY / 2 then
                                pushY = pushForce
                            elseif self.y > app.maxY / 2 then
                                pushY = -pushForce
                            end
                        end
                
                        if pushX ~= 0 or pushY ~= 0 then
                            self.data.pushX = pushX
                            self.data.pushY = pushY
                            self.phase.nameNext = 'pushAwayFromWall'
                            self.phase.counter = 1
                        end
                    end

                elseif self.collisionWith.type == 'wormPart' and app.extra ~= nil and app.extra.name == 'camouflage' then
                    local fakeBalls = appGetSpritesByType('fakeBall')
                    for i, fakeBall in ipairs(fakeBalls) do
                        fakeBall.energy = 115
                        fakeBall.energySpeed = -1
                    end

                end

                if showSparks then app.spritesHandler:createSparks(self.x, self.y) end
            end
    
        elseif self.phase.name == 'positionAtStart' then
            if not self.phase:isInited() then
                if not ( appGetSpriteCountByType('countdown') >= 1 or appGetSpriteCountByType('announcement') >= 1 ) then
                    if self.y ~= math.floor(app.maxY / 2) then -- workaround to allow child to adjust, potentially fix in future
                        self.x = math.random(app.minX + 150, app.maxX - 150)
                        self.y = math.floor(app.maxY / 2)
                    end
                    app.spritesHandler:createEmphasizeAppearanceEffect(self.x, self.y)
                    self:resetSpin()
    
                    local sprites = appGetSpritesByType('wall', 'buzzer')
                    for id, sprite in pairs(sprites) do sprite.phase:set('onForLonger') end
                end
                self.phase:set('default')
            end
    
        elseif self.phase.name == 'justHitGoal' then
            if not self.phase:isInited() then
                local speedX, speedY = self:getLinearVelocity()
                self:setLinearVelocity(speedX * .1, speedY * .1)
                self.phase.nameNext = 'positionAtStart'
                self.phase.counter = 200
            end

            if misc.getChance(90) then app.spritesHandler:createSparks(self.x, self.y, 1) end
    
        elseif self.phase.name == 'pushAwayFromWall' then
            if not self.phase:isInited() then
                self:applyForce(self.data.pushX, self.data.pushY, self.x, self.y)
                self.phase:set('default')
            end

        else
            if not self.phase:isInited() then
                self.phase.nameNext = 'default'
                self.phase.counter = 30
            end

        end

        local sane = self.phase ~= nil
        if sane and self.phase.name ~= 'default' then
            local saneNextName = self.phase.nameNext == 'default' or self.phase.nameNext == 'positionAtStart'
            local saneNextCounter = self.phase.counter ~= nil and self.phase.counter >= 1 and self.phase.counter <= 250
            sane = saneNextName and saneNextCounter
        end
        if not sane then
            -- appPrint( 'resetting insane phase ' .. tostring(self.phase.name) )
            self.phase:set('default')
        end

    end

    for i = 1, max do
        local margin = 70
        local x = math.floor( math.random(app.minX + margin, app.maxX - margin) )
        local y = math.floor(app.maxY / 2) -- must be this too, for current start position workaround
        local self = spriteModule.spriteClass('circle', 'ball', nil, nil, true, x, y, 13)
        self.phase:set('positionAtStart')
        self:setRgb(255, 0, 255, 0)
        self:setFillColorBySelf()
        self.isSleepingAllowed = false
        self.isBullet = true
        self.isHitTestable = true
        self.isVisible = false
        self.emphasizeAppearance = true
        self.emphasizeDisappearance = true
        self.handle = handle
        self.group = group
        self.listenToPostCollision = true
        self.alsoAllowsExtendedNonPhysicalHandling = false
        self.linearDamping = .3 -- was .35
        appAddSprite(self, handle, moduleGroup)

        local glow = spriteModule.spriteClass('rectangle', 'ballGlow', nil, 'ball-and-glow', false, self.x, self.y, 62, 62)
        glow.parentId = self.id
        glow.movesWithParent = true
        glow.disappearsWithParent = true
        glow.group = group
        appAddSprite(glow)
    end
end

function self:createAtmosphere()
    local function handle(self)
        if misc.getChance(1) then
            self.speedX = misc.getIf( misc.getChance(), -4, 4 )
            if misc.getChance() then
                app.spritesHandler:createGlowSparks(self.x, self.y, self.speedX, self.speedY)
            else
                local y = app.maxY / 2 + math.random(-200, 200)
                if misc.getChance() then
                    app.spritesHandler:createGlowSparks(app.minX, y, 4, 0)
                else
                    app.spritesHandler:createGlowSparks(app.maxX, y, -4, 0)
                end
            end
        end
    end

    appRemoveSpritesByType('atmosphere')
    local offset = 250
    local lastSprite = nil
    for i = 1, 3 do -- 4
        local x = app.maxX / 2 + math.random(-offset, offset)
        local y = app.maxY / 2 + math.random(-offset, offset)
        local size = 40 + i * 10
        local self = spriteModule.spriteClass('circle', 'atmosphere', nil, nil, false, x, y, size)
        self.id = 'atmosphericSprite' .. i
        self:setRgb(255, 255, 129, 5)
        self.speedLimit = 4
        self.speedLimitX = self.speedLimit
        self.speedLimitY = self.speedLimit
        self.speedStep = .25
        self.targetX = app.maxX / 2
        self.targetY = app.maxY / 2
        self.doFollowTarget = true
        self.doDieOutsideField = false
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createEmphasizeAppearanceEffect(x, y)
    local function handle(self)
        self:adjustRadius(-1)
    end
    
    local radius = 70
    local self = spriteModule.spriteClass('circle', 'emphasis', nil, nil, false, x, y, radius)
    self.radius = 70
    self.energy = 90
    self.energySpeed = -2
    self.alphaChangesWithEnergy = true
    self:setRgbWhite()
    self:setFillColorBySelf()

    appAddSprite(self, handle, moduleGroup)
end

function self:createEmphasizeDisappearanceEffect(x, y)
    local function handle(self)
        self:adjustRadius(1)
    end
    
    local radius = 15
    local self = spriteModule.spriteClass('circle', 'emphasis', nil, nil, false, x, y, radius)
    self.radius = radius
    self.energy = 90
    self.energySpeed = -3
    self.alphaChangesWithEnergy = true
    self:setRgbWhite()
    self:setFillColorBySelf()

    appAddSprite(self, handle, moduleGroup)
end

function self:createControls()
    local function handle(self)
        if self.controlledSprite == nil or self.controlledSprite.gone then
            self.controlledSprite = appGetSpriteByType('wormPart', 'head', self.parentPlayer)
        end

        if self.touchedX ~= nil and self.touchedY ~= nil then
            app.controlWasUsed[self.parentPlayer] = true
            local distanceX = self.touchedX - self.x
            local distanceY = self.touchedY - self.y
            local maxRadius = self.width / 2
            local thisRadius = math.sqrt(distanceX * distanceX + distanceY * distanceY)
            if thisRadius <= maxRadius and (distanceX ~= 0 or distanceY ~= 0) then
                local rotation = misc.getAngleFromXY(distanceX, distanceY)
                if self.controlledSprite ~= nil then self.controlledSprite.targetRotation = rotation + self.controlledSprite.rotationImageOffset end

                local speed = thisRadius * .22
                local speedMax = 20

                if self.controlledSprite ~= nil and
                        ( app.extra.name == 'speedMania' or
                        (app.extra.name == 'extraSpeed' and self.controlledSprite.parentPlayer == app.extra.playerWhoCollected) ) then
                    speed = speed * 2
                    speedMax = speedMax * 2
                end

                if speed > speedMax then speed = speedMax end
                if self.controlledSprite ~= nil then self.controlledSprite.speedLimit = speed end

                if self.data.controlledArrow ~= nil then self.data.controlledArrow.rotation = rotation end
                if self.data.controlledTapIcon ~= nil then
                    self.data.controlledTapIcon.x = self.touchedX
                    self.data.controlledTapIcon.y = self.touchedY
                    if not self.data.controlledTapIconInited then self.data.controlledTapIcon.alpha = 1 end
                end
            end
        end

    end

    appRemoveSpritesByType('controlArrow')
    appRemoveSpritesByType('control')
    appRemoveSpritesByType('tapIcon')

    for playerI = 1, app.playerMax do
        local size = 317
        local x = 628
        local y = 884

        if playerI == 2 then y = y + 2 end

        local xOffset = 58
        local arrowWidth = 70
        local arrowHeight = 40
        local arrowX = x + xOffset
        local arrowY = y -- + arrowHeight / 2

        if playerI == 2 then
            x = app.maxX - x
            y = app.maxY - y
            arrowX = x + xOffset + 3
            arrowY = y
        end

        local arrow = spriteModule.spriteClass('rectangle', 'controlArrow', nil, 'control-arrow-player-' .. playerI, false, arrowX, arrowY, arrowWidth, arrowHeight)
        arrow.parentPlayer = playerI
        if app.leftHandedControl[playerI] then
            if playerI == 1 then
                arrow.x = app.maxX - arrow.x + 123
            else
                arrow.x = app.maxX - arrow.x + 113
            end
        end
        arrow.xReference = -xOffset
        arrow.rotation = misc.getIf(playerI == 1, -90, 90)
        appAddSprite(arrow)

        local tapIcon = spriteModule.spriteClass('rectangle', 'tapIcon', nil, 'tap-icon', false, x, y, 60, 60)
        tapIcon.alpha = 0
        appAddSprite(tapIcon)

        local self = spriteModule.spriteClass('rectangle', 'control', nil, nil, false, x, y, size, size)
        self.parentPlayer = playerI
        self.isHitTestable = true
        self.isVisible = false
        self:setRgb( 0, math.random(0, 255), 255, 0)
        self:setFillColorBySelf()
        self.data.controlledArrow = arrow
        self.data.controlledTapIcon = tapIcon
        self.data.controlledTapIconInited = false
        self:toBack()
        self.listenToTouch = true

        if app.leftHandedControl[playerI] then
            self.x = app.maxX - self.x -- approximation
        end
        appAddSprite(self, handle, moduleGroup)

        arrow:toBack()
    end
end

function self:createCountdown()
    local function handle(self)
        if self.phase.name == 'default' and not self.phase:isInited() then
            appPlaySound('countdown-beat')
        end

        if self.energy == 10 then
            if self.data.number > 1 then
                self.data.number = self.data.number - 1
                self.text = self.data.number
                self.energy = 90
                appPlaySound('countdown-beat')
            else
                self.gone = true
                appPlaySound('intro.mp3')
                appRecreateWormsAndBall()
            end
        end
    end

    appRemoveSpritesByType('countdown')
    local self = spriteModule.spriteClass('text', 'countdown', nil, nil, false, app.maxX / 2, app.maxY / 2)
    self.size = 150
    self:setRgbWhite()
    self:setColorBySelf()
    self.rotation = 45
    self.energy = 90
    self.energySpeed = -2.5
    self.data.number = 3
    self.rotationSpeed = 5
    self.text = self.data.number
    self.alphaChangesWithEnergy = true
    self.phase:set('default')
    appAddSprite(self, handle, moduleGroup)
end

function self:createAnnouncement(playerI, subtype, optionalText)
    local function handle(self)
        if self.subtype == 'winnerAnnouncement' then
            local color = misc.getIf( self.parentPlayer == 1, {red = 51, green = 255, blue = 255}, {red = 255, green = 119, blue = 252} )
            if misc.getChance(15) then app.spritesHandler:createSparks(self.x, self.y, 1, 22, nil, nil, color) end
            self:toFront()
        end

        self.data.sizeBuffer = self.data.sizeBuffer - .1 -- perhaps no speed improvement...
        if self.size ~= math.floor(self.data.sizeBuffer) then self.size = math.floor(self.data.sizeBuffer) end
    end

    local function handleWhenGone(self)
        if self.subtype == 'winnerAnnouncement' and not (app.extra ~= nil and app.extra.name == 'training') then
            appRestartGame()
        elseif self.subtype == 'trainingAnnouncement' and (app.extra ~= nil and app.extra.name == 'training') then
            app.extra:doEnd()
            app.extra:doStart(self.parentPlayer, 'training')
        end
    end

    if app.extra.name ~= 'training' then app.extra:doEnd() end
    for i = 1, 3 do
        local thisSubtype = misc.getIf(i == 1, subtype, 'clone')
        local self = spriteModule.spriteClass('text', 'announcement', thisSubtype, nil, false, app.maxX / 2, app.maxY / 2)
        self.size = 70
        self.data.sizeBuffer = self.size
        self:setRgbWhite()
        self:setColorBySelf()
        self.rotation = 45
        self.energy = 400
        self.energySpeed = -1
        self.rotationSpeed = 3
        self.parentPlayer = playerI

        if self.subtype == 'clone' then
            self.alpha = 1 - i * .22
            self.rotationSpeed = self.rotationSpeed - ( (i - 1) * .2 )
        else
            self.alphaChangesWithEnergy = true
        end

        if optionalText ~= nil then
            self.text = optionalText
        else
            self.text = 'PLAYER ' .. playerI .. ' WINS'
        end
        appAddSprite(self, handle, moduleGroup, handleWhenGone)
    end
end

function self:createSparks(x, y, maxSparks, sparkRadius, speedX, speedY, color)
    local maxSparksAll = 40
    if color == nil then
        color = {red = 255, green = 255, blue = 255}
    end

    local sparkCount = appGetSpriteCountByType('spark')
    if maxSparks == nil then maxSparks = 5 end
    local maxSparkRadiusIfRandom = 10

    for sparkI = 1, maxSparks, 1 do
        if sparkCount < maxSparksAll then
            sparkCount = sparkCount + 1

            local radius = sparkRadius
            if radius == nil then radius = math.random(2, maxSparkRadiusIfRandom) end

            local fuzzyPosition = 5
            x = x + math.random(-fuzzyPosition, fuzzyPosition)
            y = y + math.random(-fuzzyPosition, fuzzyPosition)
    
            local self = spriteModule.spriteClass('circle', 'spark', nil, nil, false, x, y, radius)

            local speedLimit = 7
            self.speedX = misc.getIf(speedX ~= nil, speedX, math.random(-speedLimit, speedLimit) )
            self.speedY = misc.getIf(speedY ~= nil, speedY, math.random(-speedLimit, speedLimit) )
            self.speedLimit = speedLimit
            self.alphaChangesWithEnergy = true

            self:setRgbByColorTriple(color)
            self:setFillColorBySelf()
            self.energy = 100
            self.energySpeed = -5
    
            appAddSprite(self, handle, moduleGroup)
        end
    end
end

function self:createGlowSparks(x, y, speedX, speedY)
    local self = spriteModule.spriteClass('circle', 'spark', nil, nil, false, x, y, 3)

    local speedLimit = 7
    self.speedX = speedX
    self.speedY = speedY
    self.alphaChangesWithEnergy = true

    self:setRgb(255, 255, 129, 80)
    self:setFillColorBySelf()
    self.energy = 80
    self.energySpeed = -.5

    appAddSprite(self, handle, moduleGroup)
end

function self:createScorePeg(id, playerI, scoreI)
    local x = 29 + (scoreI - 1) * 40
    local y = 959
    if playerI == 2 then
        x = app.maxX - x
        y = app.maxY - y
    end
    local self = spriteModule.spriteClass('rectangle', 'scorePeg', nil, 'score-peg', false, x, y, 22, 22)
    self.id = id
    self.data.originalX = x
    self.data.offsetXForLefthanded = 473
    self.emphasizeAppearance = true
    self.parentPlayer = playerI
    appAddSprite(self)
end

function self:adjustScorePegPosition(id)
    local sprite = appGetSpriteById(id)
    if sprite ~= nil then
        sprite.x = sprite.data.originalX
        if app.leftHandedControl[sprite.parentPlayer] then
            offsetX = misc.getIf(sprite.parentPlayer == 1, sprite.data.offsetXForLefthanded, -sprite.data.offsetXForLefthanded)
            sprite.x = sprite.x + offsetX
        end
    end
end

return self
end