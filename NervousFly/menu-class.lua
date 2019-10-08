module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.helpPageNumber = 1

function self:showMoreGames()
    system.openURL('http://versuspad.com')
end

function self:showSoundCredits()
    system.openURL('http://versuspad.com/' .. app.name .. '-credits')
end

function self:showReviewPage()
    local countryCode = system.getPreference('locale', 'country') -- e.g. 'us'
    local appUrl = 'itms://itunes.apple.com/' .. countryCode .. '/app/' .. misc.toName(app.title) .. '/id' .. app.id
    system.openURL(appUrl)
end

function self:createButton(x, y, imageName, functionObject, width, height)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            self.data:functionObject()
        end
    end

    if x == nil then x = app.maxXHalf end
    if y == nil then y = app.maxYHalf end
    if width == nil then width = 219 end
    if height == nil then height = 41 end
    local subtype = imageName
    if imageName ~= nil then imageName = 'menu/button/' .. imageName end
    local self = spriteModule.spriteClass('rectangle', 'menuButton', subtype, imageName, false, x, y, width, height)
    self.data.functionObject = functionObject
    if imageName == nil then
        self.isVisible = false
        self.isHitTestable = true
        -- self:setRgb( 0, math.random(0, 255), 255, 70 )
    end
    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createPageMain(glassToView, addCrumblesEffect)
    local function viewPrevious()
        app.currentGlassViewingInMenu = app.currentGlassViewingInMenu - 1
        if app.currentGlassViewingInMenu < 1 then app.currentGlassViewingInMenu = app.highestAllTime.glass end
        app.menu:createPageMain(app.currentGlassViewingInMenu, false)
    end

    local function showPageHowToPlay()
        app.menu:createPageHowToPlay()
    end

    local function showPageHighscores()
        app.menu:createPageHighscores()
    end

    local function showPageMoreGamesAbout()
        app.menu:createPageMoreGamesAbout()
    end

    local function showPageUnlockStorage()
        app.menu:createPageUnlockStorage()
    end

    local function toggleMusic()
        app.playBackgroundMusic = not app.playBackgroundMusic
        app.data:setBool('playBackgroundMusic', app.playBackgroundMusic)
        app.menu:createPageMain(nil, false)
    end

    app.menu:createFreshPageWithBackground()

    if addCrumblesEffect == nil then addCrumblesEffect = true end

    if glassToView == nil then
        app.currentGlassViewingInMenu = app.highestAllTime.glass
        glassToView = app.currentGlassViewingInMenu
    end

    local glassBack = spriteModule.spriteClass('rectangle', 'menuGlassBack', nil, 'menu/glass-back', false, 102, 117, 178, 168)
    appAddSprite(glassBack, nil, moduleGroup)

    local headerText = spriteModule.spriteClass('text', 'menuHeader', nil, nil, false, app.maxXHalf, 19)
    headerText.size = 14
    if glassToView == app.highestAllTime.glass then
        if app.highestAllTime.glass == 1 then headerText.text = 'You own ' .. app.highestAllTime.glass .. ' glass:'
        elseif app.highestAllTime.glass == #app.glasses then headerText.text = 'You own all glasses! Your latest:'
        else headerText.text = 'You own ' .. app.highestAllTime.glass .. ' glasses. Your latest:'
        end
    else
        if app.highestAllTime.glass == #app.glasses then headerText.text = 'You own all glasses!'
        else headerText.text = 'You own ' .. app.highestAllTime.glass .. ' glasses.'
        end
    end
    appAddSprite(headerText, nil, moduleGroup)

    local rightColumnX = 248

    if app.highestAllTime.glass > 1 then app.menu:createButton(rightColumnX, 64, 'viewPrevious', viewPrevious, 97, 43) end

    local glass = app.glasses[glassToView]

    local glassText = spriteModule.spriteClass('text', 'menuGlassText', nil, nil, false, glassBack.x, glassBack.y + 50)
    glassText.text = glass.title
    glassText:setRgbBlack()
    glassText.size = 13
    appAddSprite(glassText, nil, moduleGroup)

    local glassImage = spriteModule.spriteClass('rectangle', 'menuGlassImage', nil, 'glass/' .. glass.filename, false, glassBack.x, glassBack.y - 10,
            app.glassSize.width, app.glassSize.height)
    glassImage:scale(.8, .8)
    appAddSprite(glassImage, nil, moduleGroup)

    if app.products[1].isPurchased then
        local purchasedBadge = spriteModule.spriteClass('rectangle', 'unlockStorage', nil, 'menu/infiniteStorage', false, rightColumnX + 2, 119, 101, 53)
        appAddSprite(purchasedBadge, nil, moduleGroup)
    else
        app.menu:createButton(rightColumnX, 119, 'unlockStorage', showPageUnlockStorage, 97, 43)
    end

    if app.highestAllTime.glass < #app.glasses then
        local nextGlassHeader = spriteModule.spriteClass('rectangle', 'menuNextGlassHeader', nil, 'menu/ice-cubes-needed', false, rightColumnX, 160, 97, 19)
        appAddSprite(nextGlassHeader, nil, moduleGroup)

        local menuNextGlassText = spriteModule.spriteClass('text', 'menuNextGlassText', nil, nil, false, rightColumnX, 184)
        menuNextGlassText.text = appGetCubesNeededForNextGlass()
        menuNextGlassText.size = 17
        appAddSprite(menuNextGlassText, nil, moduleGroup)
    else
        local menuNextGlassText = spriteModule.spriteClass('text', 'menuNextGlassText', nil, nil, false, rightColumnX, 184)
        menuNextGlassText.text = 'Congrats!'
        menuNextGlassText.size = 17
        appAddSprite(menuNextGlassText, nil, moduleGroup)
    end

    local y = 239
    local margin = 48
    app.menu:createButton(nil, 239 + margin * 0, 'howToPlay', showPageHowToPlay)
    app.menu:createButton(nil, 239 + margin * 1, 'highscores', showPageHighscores)
    app.menu:createButton(nil, 239 + margin * 2, 'moreGamesAbout', showPageMoreGamesAbout)
    app.menu:createButton( nil, 239 + margin * 3, misc.getIf(app.playBackgroundMusic, 'turnOffMusic', 'turnOnMusic'), toggleMusic )

    if addCrumblesEffect then app.menu:createWoodCrumbles() end
end

function self:createPageHowToPlay()
    app.menu:createFreshPageWithBackground('howToPlay')
    app.menu:createBackButton()

    app.menu:createButton(255, 29, nil, app.menu.showMoreGames, 143, 48)

    app.menu:createWoodCrumbles()
end

function self:createPageHighscores()
    app.menu:createFreshPageWithBackground('highscores')
    app.menu:createBackButton()

    local y = 96
    local margin = 60
    local i = 0
    app.menu:createHighscoreScoreText(y + margin * i, app.highestAllTime.score); i = i + 1
    app.menu:createHighscoreScoreText(y + margin * i, app.highestAllTime.iceCubes); i = i + 1
    app.menu:createHighscoreScoreText(y + margin * i, app.highestAllTime.glass); i = i + 1
    app.menu:createHighscoreScoreText(y + margin * i, app.highestAllTime.olives)

    app.menu:createWoodCrumbles()
end

function self:createHighscoreScoreText(y, value)
    local self = spriteModule.spriteClass('text', 'menuText', nil, nil, false, 298, y)
    self.text = value
    self.size = 22

    self:setReferencePoint(display.CenterRightReferencePoint)
    self.x = self.originX

    self:setRgbWhite()
    appAddSprite(self, nil, moduleGroup)
end

function self:createPageMoreGamesAbout()
    local function clearDataForTest()
        app.data:clear()
        native.showAlert( 'Success', 'OK, all data cleared.', {'OK'} )
    end

    app.menu:createFreshPageWithBackground('moreGamesAbout')
    app.menu:createBackButton()

    app.menu:createButton(app.maxXHalf, 170, 'versuspad', app.menu.showMoreGames)

    app.menu:createButton(199, 308, nil, app.menu.showSoundCredits, 209, 54)
    app.menu:createButton(app.maxXHalf, 371, nil, app.menu.showReviewPage, 310, 60)
    --- app.menu:createButton(app.maxX - 50, 30, nil, clearDataForTest, 99, 60) --- remove later

    app.menu:createWoodCrumbles()
end

function self:createPageUnlockStorage()
    app.menu:createFreshPageWithBackground('unlockStorage')
    app.menu:createBackButton()

    app.menu:createButton(app.maxXHalf, 191, 'buy', appStartPurchase)
    app.menu:createButton(app.maxXHalf, 317, 'restore', appStartPurchaseRestore)

    appStopBackgroundMusic()
    store.loadProducts( {app.products[1].id}, appLoadProductsCallback )

    app.menu:createWoodCrumbles()
end

function self:createBackButton()
    app.menu:createButton(74, 25, 'back', app.menu.createPageMain, 116, 27)
end

function self:closeMenu()
    app.menu:createWoodCrumbles(true)
    appResume()
end

function self:showEndOfGameScore()
    local function removePageAndRestart()
        app.menu:createWoodCrumbles()
        appRestart()
    end

    appRemoveSpritesByGroup(nil)
    appRemoveSpritesByType( {'menuButton', 'purchaseText', 'price'} )
    app.menu:createFreshPageWithBackground('endOfGameScore', false)

    local y = 98
    local margin = 58
    local fadeInDelay = 30
    local fadeInDelayMargin = 25
    local i = 0
    if app.menu.data == nil then app.menu.data = {} end
    app.menu.data.clappingSoundAssigned = false
    app.menu:createScoreText(y + margin * i, app.highestThisRound.score, app.highestAllTime.score, fadeInDelay + fadeInDelayMargin * i); i = i + 1
    app.menu:createScoreText(y + margin * i, app.highestThisRound.iceCubes, app.highestAllTime.iceCubes, fadeInDelay + fadeInDelayMargin * i); i = i + 1
    app.menu:createScoreText(y + margin * i, app.highestThisRound.glass, app.highestAllTime.glass, fadeInDelay + fadeInDelayMargin * i); i = i + 1
    app.menu:createScoreText(y + margin * i, app.highestThisRound.olives, app.highestAllTime.olives, fadeInDelay + fadeInDelayMargin * i)

    app.menu:createButton(nil, 443, 'playAgain', removePageAndRestart)
    appPrint('created playAgain button')
    app.menu:createWoodCrumbles()
end

function self:createScoreText(y, value, highestAllTimeValue, showDelay)
    local function handleText(self)
        if self.phase.name == 'show' or self.phase.name == 'showAndCrumble' or self.phase.name == 'showAndApplaud' then
            if not self.phase:isInited() then
                self.isVisible = true

                if self.phase.name == 'showAndCrumble' then
                    appPlaySound('wood-bump')
                    local fuzzy = 3
                    local max = math.random(1, 3)
                    for i = 1, max do
                        app.menu:createWoodCrumble( self.x + math.random(-fuzzy, fuzzy), self.y + math.random(-fuzzy, fuzzy) )
                    end
                elseif self.phase.name == 'showAndApplaud' then
                    appPlaySound('clapping')
                end
            end
        end

        if self.energy >= 100 then self.energySpeed = 0 end
    end

    if value == nil then value = 0 end

    local scoreText = spriteModule.spriteClass('text', 'menuText', nil, nil, false, 210, y)
    scoreText.text = value
    scoreText.size = 18
    scoreText:setReferencePoint(display.CenterRightReferencePoint)
    scoreText.x = scoreText.originX
    scoreText:setRgbWhite()
    scoreText.isVisible = false
    scoreText.phase:setNext('showAndCrumble', showDelay)
    appAddSprite(scoreText, handleText, moduleGroup)

    local x = 265
    if value > highestAllTimeValue then
        local cup = spriteModule.spriteClass('rectangle', 'menuText', nil, 'menu/new-hi', false, x, y, 55, 37)
        cup.isVisible = false
        if not app.menu.data.clappingSoundAssigned then
            cup.phase:setNext('showAndApplaud', showDelay)
            app.menu.data.clappingSoundAssigned = true
        else
            cup.phase:setNext('show', showDelay)
        end
        appAddSprite(cup, handleText, moduleGroup)
    else
        local highscoreHeader = spriteModule.spriteClass('text', 'menuText', nil, nil, false, x, y - 8)
        highscoreHeader.text = language.get('allTimeHi')
        highscoreHeader.size = language.getByArray( { en = 11, de = 10 } )
        highscoreHeader:setRgb(192, 172, 149)
        highscoreHeader.isVisible = false
        highscoreHeader.phase:setNext('show', showDelay)
        appAddSprite(highscoreHeader, handleText, moduleGroup)

        local highscore = spriteModule.spriteClass('text', 'menuText', nil, nil, false, x, y + 8)
        highscore.text = highestAllTimeValue
        highscore.size = 14
        highscore:setRgb(highscoreHeader.red, highscoreHeader.green, highscoreHeader.blue)
        highscore.isVisible = false
        highscore.phase:setNext('show', showDelay)
        appAddSprite(highscore, handleText, moduleGroup)
    end
end

function self:createFreshPageWithBackground(pageImageName, includeResumeGameButton)
    if includeResumeGameButton == nil then includeResumeGameButton = true end
    appRemoveSpritesByType('price')
    appRemoveSpritesByGroup('menu')

    local subtype = pageImageName
    local background = spriteModule.spriteClass('rectangle', 'menuPage', subtype, 'menu/background', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    appAddSprite(background, handle, moduleGroup)

    if pageImageName ~= nil then
        local page = spriteModule.spriteClass('rectangle', 'menuPage', nil, 'menu/page/' .. pageImageName, false,
                app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
        appAddSprite(page, handle, moduleGroup)
    end

    if includeResumeGameButton then app.menu:createButton(nil, 443, 'resumeGame', app.menu.closeMenu) end
end

function self:createWoodCrumbles(persistentWhenMenuCloses)
    if persistentWhenMenuCloses == nil then persistentWhenMenuCloses = false end

    appPlaySound('wood-bump')
    for i = 1, 15 do
        self:createWoodCrumble( math.random(0, app.maxX), math.random(0, app.maxY) )
    end
end

function self:createWoodCrumble(x, y)
    local speedLimit = 7
    local self = spriteModule.spriteClass('rectangle', 'woodCrumble', nil, 'menu/wood-crumble', false, x, y, 13, 30)
    self.targetSpeedY = 9
    self.rotationSpeed = math.random(-10, 10)
    self.speedX = math.random(-speedLimit, speedLimit)
    self.speedY = math.random(-speedLimit, speedLimit / 2) + 3
    self.energy = 140
    self.energySpeed = -3
    self.alphaChangesWithEnergy = true
    appAddSprite( self, handle, misc.getIf(persistentWhenMenuCloses, nil, moduleGroup) )
end

function self:createButtons()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            if app.runs then
                app.menu:createPageMain()
                -- app.showClock = false
                -- appRemoveSpritesByType('clockText')
                appPause()
                appPlaySound('click')
            end
        end
    end

    appRemoveSpritesByType('menuButton')
    local width = 105; local height = 64
    local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, 'menu/button/showMenu', false, app.maxX - width / 2, height / 2, width, height)
    self.doDieOutsideField = false
    self.listenToTouch = true
    appAddSprite(self, handle, 'menuButton')
end

return self
end