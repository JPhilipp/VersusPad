module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.helpPageNumber = 1

function self:goToHomepage()
    system.openURL('http://versuspad.com')
end

function self:showReviewPage()
    local appUrl = ''
    if app.isIOs then
        local countryCode = system.getPreference('locale', 'country') -- e.g. 'us'
        local appUrl = 'itms://itunes.apple.com/' .. countryCode .. '/app/' .. misc.toName(app.title) .. '/id' .. app.id
    else
        appUrl = 'https://play.google.com/store/apps/details?id=' .. app.idInStore
    end
    system.openURL(appUrl)
end

function self:createPageMain()
    local function clearDataForTest() app.data:clear(); native.showAlert( 'Success', 'OK, all data cleared.', {'OK'} ) end
    local function showUpgradeScreen() app.spritesHandler:createUpgradeScreen(true) end

    appRemoveSpritesByType('menuPage')

    local background = spriteModule.spriteClass('rectangle', 'menuPage', subtype, 'menu/page/main', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    local backId = background.id
    appAddSprite(background, handle, moduleGroup)

    app.menu:createButton(backId, 120, 102, nil, app.menu.createPageHelp)

    local musicButtonImage = 'turn' .. misc.getIf(app.doPlayBackgroundMusic, 'Off', 'On') .. 'Music'
    app.menu:createButton(backId, 349, 107, musicButtonImage, appToggleBackgroundMusic, 197, 67)

    app.menu:createButton(backId, 120, 182, nil, app.menu.createPageChangeClothes)
    app.menu:createButton(backId, 360, 182, nil, app.menu.createPageAbout)

    app.menu:createButtonResume(backId)

    appSaveData()
    local highscore = spriteModule.spriteClass('text', 'highscoreText', nil, nil, false, 130, 280)
    highscore.parentId = backId
    highscore:setFontSize(38)
    highscore:setRgbByColorTriple(app.menuTextColor)
    highscore.text = '$' .. app.highestAllTimeScore
    appAddSprite(highscore, handle, moduleGroup)

    -- app.menu:createButton(backId, 5, 5, nil, clearDataForTest, 100, 100) -- remove later
end

function self:createPageChangeClothes()
    appRemoveSpritesByType( {'menuPage', 'buttonPart'} )

    local background = spriteModule.spriteClass('rectangle', 'menuPage', nil, 'menu/page/changeClothes', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    local backId = background.id
    appAddSprite(background, handle, moduleGroup)

    local buttonWidth = 240; local buttonHeight = 63
    local i = 0
    for gridY = 1, 3 do
        for gridX = 1, 2 do
            i = i + 1
    
            if i <= #app.dress then
                local left = buttonWidth * (gridX - 1)
                local top = 66 + buttonHeight * (gridY - 1)
                app.menu:createChangeClothesButton(backId, i, app.dress[i], left, top, buttonWidth, buttonHeight)
            else
                break
            end
        end
    end

    app.menu:createBuyDiamondsPackButton(backId)

    local text = spriteModule.spriteClass('text', 'menuPage', 'headline', nil, false, 430, 29, 300, height)
    text.parentId = backId
    text:setFontSize(30)
    text:setRgbByColorTriple(app.menuTextColor)
    text.text = 'YOU OWN ' .. misc.addCommasToNumber(app.diamondsOwned) .. ' x'
    text:topRightAlign()
    appAddSprite(text, nil, moduleGroup)

    app.menu:createButton(backId, 53, 29, nil, app.menu.createPageMain, 112, 55)
end

function self:createChangeClothesButton(parentId, i, dress, left, top, width, height)
    local function handleTouch(event)
        local self = event.target

        if event.phase == 'began' then

            local function buttonListenerCongrats(event)
                if event.action == 'clicked' then
                    app.menu:createPageChangeClothes()
                end
            end

            local function buttonListenerBuy(event)
                if event.action == 'clicked' then
                    local eventIndexYes = 2
                    if event.index == eventIndexYes then
                        appStartPurchase()
                    end
                end

            end

            appPlaySound('click')
            dress = app.dress[self.data.index]

            if dress.isOwned then
                app.currentDress = self.data.index
                app.menu:createPageChangeClothes()

            else
                if dress.priceInDiamonds <= app.diamondsOwned then
                    app.diamondsOwned = app.diamondsOwned - dress.priceInDiamonds
                    dress.isOwned = true
                    app.currentDress = self.data.index

                    appSaveData()
                    native.showAlert( '', 'Congratulations, you got the suit for ' .. dress.priceInDiamonds .. ' diamonds!',
                            {'OK'}, buttonListenerCongrats )
                else
                    local priceInfo = ''
                    local priceText = appGetSpriteByType('buttonPart', 'price')
                    if priceText ~= nil and priceText.text ~= '' then priceInfo = ' for ' .. priceText.text end

                    native.showAlert( '', "You don't have enough diamonds. " ..
                            'Buy ' .. misc.addCommasToNumber(app.diamondsInPack) .. ' diamonds' .. priceInfo .. '?',
                            {'No', 'Yes'}, buttonListenerBuy )

                    appPrint("You don't have enough diamonds. " ..
                            'Buy ' .. misc.addCommasToNumber(app.diamondsInPack) .. ' diamonds' .. priceInfo .. '?')

                end

            end

        end
    end

    local y = top + height / 2

    if i == app.currentDress then
        local current = spriteModule.spriteClass('rectangle', 'buttonPart', nil, 'menu/button-hi', false, left + width / 2, y, width, height)
        current.parentId = backId
        appAddSprite(current, nil, moduleGroup)
    end

    local image = 'girl/' .. dress.name .. '/run-1-right'
    local girl = spriteModule.spriteClass('rectangle', 'buttonPart', nil, image, false, left + 28, y, app.girlWidth, app.girlHeight)
    girl.parentId = backId
    appAddSprite(girl, nil, moduleGroup)

    local name = spriteModule.spriteClass('text', 'buttonPart', nil, nil, false, left + 120, y + 1, 113, height)
    name.parentId = backId
    name:setFontSize(30)
    name:setRgbByColorTriple(app.buttonTextColor)
    name.text = string.gsub(dress.title, ' ', "\n")
    appAddSprite(name, nil, moduleGroup)

    if dress.isOwned then
        local checkmark = spriteModule.spriteClass('rectangle', 'buttonPart', nil, 'menu/owned-checkmark', false, left + width - 38, y, 40, 40)
        checkmark.parentId = backId
        appAddSprite(checkmark, nil, moduleGroup)
    else
        local price = spriteModule.spriteClass('text', 'buttonPart', nil, nil, false, left + width - 38, y - 16)
        price.parentId = backId
        price:setFontSize(28)
        price:setRgbByColorTriple(app.buttonTextColor)
        price.text = dress.priceInDiamonds
        appAddSprite(price, nil, moduleGroup)

        local diamond = spriteModule.spriteClass('rectangle', 'buttonPart', nil, 'menu/diamond', false, price.x, y + 10, 30, 30)
        diamond.parentId = backId
        appAddSprite(diamond, nil, moduleGroup)
    end

    local overlay = spriteModule.spriteClass('rectangle', 'buttonPart', nil, nil, false, left + width / 2, y, width, height)
    overlay.data.index = i
    overlay.isVisible = false
    overlay.isHitTestable = true
    if app.showButtonSizes then
        overlay.isVisible = true
        overlay:setRgb( 0, math.random(0, 255), 255, 70 )
    end
    overlay:addEventListener('touch', handleTouch)
    appAddSprite(overlay, handle, moduleGroup)
end

function self:createBuyDiamondsPackButton(parentId)
    local function handleTouch(event)
        local self = event.target

        if event.phase == 'began' then
            appPlaySound('click')
            appStartPurchase()
        end
    end

    local left = 0; local top = 256; local width = app.maxX; local height = 64
    local x = left + width / 2; local y = top + height / 2

    local icon = spriteModule.spriteClass('rectangle', 'buttonPart', nil, 'menu/diamondsPack', false, left + 31, y - 1, 50, 43)
    icon.parentId = backId
    appAddSprite(icon, nil, moduleGroup)

    local text = spriteModule.spriteClass('text', 'buttonPart', nil, nil, false, left + 63, y - 20, 300, height)
    text.parentId = backId
    text:setFontSize(30)
    text:setRgbByColorTriple(app.buttonTextColor)
    text.text = 'BUY ' .. misc.addCommasToNumber(app.diamondsInPack) .. ' DIAMONDS!'
    text:topLeftAlign()
    appAddSprite(text, nil, moduleGroup)

    local price = spriteModule.spriteClass('text', 'buttonPart', 'price', nil, false, left + width - 40, y - 8, 95, 25)
    price.parentId = backId
    price:setFontSize(30)
    price.text = misc.getIf(app.diamondsPackPriceCached ~= nil, app.diamondsPackPriceCached, '') -- e.g. $2.99
    price:setRgbByColorTriple(app.buttonTextColor)
    appAddSprite(price, nil, moduleGroup)

    store.loadProducts( {app.products[1].id}, appLoadProductsCallback )

    local overlay = spriteModule.spriteClass('rectangle', 'buttonPart', nil, nil, false, left + width / 2, y, width, height)
    overlay.isVisible = false
    overlay.isHitTestable = true
    if app.showButtonSizes then
        overlay.isVisible = true
        overlay:setRgb( 0, math.random(0, 255), 255, 70 )
    end
    overlay:addEventListener('touch', handleTouch)
    appAddSprite(overlay, handle, moduleGroup)
end

function self:createPageHelp()
    local background = spriteModule.spriteClass('rectangle', 'menuPage', nil, 'menu/page/help', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    local backId = background.id
    appAddSprite(background, handle, moduleGroup)

    local text = spriteModule.spriteClass('text', 'buttonPart', 'text', nil, false, app.maxXHalf, app.maxYHalf - 10, app.maxX - 30, app.maxY - 80)
    text.parentId = backId
    text:setFontSize(27)
    text.text = "Your goal as Karate Girl is to destroy as much $$$ value in the crook's mansion as possible! " ..
            "Tap left to throw a bomb (one per room), press right to jump (multiple taps jump higher). " ..
            "Collect diamonds to buy new clothes. Run, Karate Girl, Run!"
    text:setRgbByColorTriple(app.menuTextColor)
    appAddSprite(text, nil, moduleGroup)

    app.menu:createButton(backId, 110, 274, nil, app.menu.goToHomepage)
    app.menu:createButtonResume(backId)
end

function self:createPageAbout()
    local function showSoundCredits() system.openURL('http://versuspad.com/karategirl-credits') end

    local background = spriteModule.spriteClass('rectangle', 'menuPage', nil, 'menu/page/about', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    local backId = background.id
    appAddSprite(background, handle, moduleGroup)

    app.menu:createButton(backId, 320, 111, nil, showSoundCredits, 180, 40)
    app.menu:createButton(backId, app.maxXHalf, 173, nil, app.menu.goToHomepage, app.maxX)
    app.menu:createButton(backId, 126, 285, nil, app.menu.showReviewPage, 235, 53)

    app.menu:createButtonResume(backId)
end

function self:createButtonResume(backId)
    local function resume()
        if app.restartWhenResumed then
            app.restartWhenResumed = false
            appRestart()
        else
            app.menu:closeMenu()
        end
    end 

    app.menu:createButton(backId, 349, 275, 'resume', resume, 196, 57)
end

function self:createButton(parentId, x, y, imageName, functionObject, width, height, optionalData)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            self.data:functionObject(self.data)
        end
    end

    if x == nil then x = app.maxXHalf end
    if y == nil then y = app.maxYHalf end
    if width == nil then width = 230 end
    if height == nil then height = 75 end
    local subtype = imageName
    if imageName ~= nil then imageName = 'menu/button/' .. imageName end

    local self = spriteModule.spriteClass('rectangle', 'menuButton', subtype, imageName, false, x, y, width, height)
    self.parentId = parentId
    if optionalData ~= nil then self.data = optionalData end
    self.data.functionObject = functionObject
    if imageName == nil then
        self.isVisible = false
        self.isHitTestable = true

        if app.showButtonSizes then
            self.isVisible = true
            self:setRgb( 0, math.random(0, 255), 255, 70 )
        end
    end
    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

function self:closeMenu()
    if app.doPlayBackgroundMusic then audio.fade( {channel = app.musicChannel, time = 1000, volume = 1} ) end
    appResume()
end

function self:createOpenButton()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            if app.runs then
                appRemoveSpritesByTypeNow(app.temporaryTypes)
                app.menu:createPageMain()
                app.showClock = true and app.showDebugInfo
                appPause()
                audio.fade( {channel = app.musicChannel, time = 500, volume = 0} )
                audio.stop(app.soundChannelFootsteps)
                audio.stop(app.soundChannelHeartbeat)
                appPlaySound('click')
            else
                appResume()
            end
        end
    end

    appRemoveSpritesByType('menuButton')
    local width = 83; local height = 76
    local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, 'menu/button', false, app.maxX - width / 2, height / 2, width, height)
    self.listenToTouch = true
    appAddSprite(self, handle, 'menuButton')
end

return self
end