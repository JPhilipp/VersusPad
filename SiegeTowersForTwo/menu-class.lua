module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.partsPageNumber = 1

function self:createDarkOverlay()
    if appGetSpriteByType('darkOverlay') == nil then
        local self = spriteModule.spriteClass('rectangle', 'darkOverlay', nil, nil, false, app.maxX / 2, app.maxY / 2, app.maxX, app.maxY)
        self:setRgb(7, 27, 79)
        self.alpha = .46
        self:setFillColorBySelf()
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:toggleTraining()
    -- app.data:clear()

    app.mode = misc.getIf(app.mode == 'default', 'training', 'default')
    local imageName = 'background'
    if app.mode == 'training' then imageName = imageName .. '-during-training' end
    appCreateBackground(imageName)
    appRestartGame()
end

function self:showMoreGames()
    system.openURL('http://versuspad.com')
end

function self:showEmailDialog()
    local semiEscapedTitle = string.gsub(app.title, ' ', '%%20')
    system.openURL( 'mailto:philipp.lenssen@gmail.com?subject=' .. semiEscapedTitle .. '%20v' .. app.version
            .. misc.getIf(app.device ~= 'iPad', '%20on Android', '') )
end

function self:showReviewPage()
    local appUrl = ''
    if app.device == 'iPad' then
        local countryCode = system.getPreference('locale', 'country') -- e.g. 'us'
        local appUrl = 'itms://itunes.apple.com/' .. countryCode .. '/app/siege-towers/id' .. app.id
    else
        appUrl = 'https://play.google.com/store/apps/details?id=' .. app.idInStore
    end
    system.openURL(appUrl)
end

function self:showVideo()
    if app.device == 'iPad' then media.playVideo( appToPath('help.m4v'), true )
    else system.openURL('http://www.youtube.com/watch?v=7d-lloPAxio')
    end
end

function self:createDialogHelp()
    local function handle(self)
        if self.y > self.data.targetY then self.y = self.y - 1
        elseif self.y < self.data.targetY then self.y = self.y + 1
        end
    end

    local pageNumber = 1
    local dialog = appGetSpriteByType('dialog', 'dialogHelp')
    if dialog ~= nil then pageNumber = dialog.data.pageNumber + 1 end

    appRemoveSpritesByType('dialog')
    appRemoveSpritesByType('dialogButton')

    local imageName = 'menu/help-' .. pageNumber

    local width = 660
    local height = 703
    local dialogX = app.maxXHalf
    local dialogY = app.maxY - math.floor(height / 2) - 40

    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogHelp', imageName, false, dialogX, dialogY, width, height)
    if app.menu.parentPlayer == 2 then self:mirrorXY() end
    self.energy = 10
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    self.data.targetY = self.y
    self.y = self.y + misc.getIf(app.menu.parentPlayer == 1, 8, -8)
    self.data.pageNumber = pageNumber
    appAddSprite(self, handle, moduleGroup)

    if pageNumber == 1 then
        app.menu:createDialogButton(340, 315, app.menu.showVideo, 250)
        app.menu:createDialogButton(650, 315, app.menu.createDialogHelp, 320)

        if app.language == 'zh' then
            app.menu:createDialogButton(315, 455, app.menu.showEmailDialog, 195, 40)
            app.menu:createDialogButton(275, 496, app.menu.showMoreGames, 115, 40)
            app.menu:createDialogButton(715, 492, app.menu.showReviewPage, 100, 40)
        else
            app.menu:createDialogButton(495, 434 + 45, app.menu.showEmailDialog, 170, 40)
            app.menu:createDialogButton(710, 434 + 45, app.menu.showMoreGames, 130, 40)
            app.menu:createDialogButton(290, 470 + 45, app.menu.showReviewPage, 130, 40)
        end

        appPlaySound('theme')
    end
    app.menu:createDialogButton(app.maxXHalf, 671, appResumeGame)
end

function self:createDialogSmall()
    local function handle(self)
        if self.y > self.data.targetY then self.y = self.y - 1
        elseif self.y < self.data.targetY then self.y = self.y + 1
        end
    end

    app.menu:createDarkOverlay()

    local width = 341
    local height = 363
    local dialogX = app.maxXHalf
    local dialogY = app.maxY - math.floor(height / 2) - 40

    local filename = misc.getIf(app.mode == 'training', 'menu/selection-during-training', 'menu/selection')
    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogSmall', filename, false, dialogX, dialogY, width, height)
    self.data.targetY = self.y
    self.y = self.y + misc.getIf(app.menu.parentPlayer == 1, 8, -8)
    self.energy = 10
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)

    local baseY = dialogY - 123
    local spacerY = 57
    local i = 0
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.createDialogHelp); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, appRestartGame); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.toggleTraining); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.showMoreGames); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i + 27, appResumeGame); i = i + 1
end

function self:createDialogButton(x, y, functionObject, optionalWidth, optionalHeight, usesTopLeftCoordinates)
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'ended' then
            appPlaySound('click.mp3')
            self.data:functionObject()
        end
    end

    if usesTopLeftCoordinates then
        x = x + optionalWidth / 2
        y = y + optionalHeight / 2
    end
    local width = misc.getIf(optionalWidth == nil, 280, optionalWidth)
    local height = misc.getIf(optionalHeight == nil, 51, optionalHeight)

    local self = spriteModule.spriteClass('rectangle', 'dialogButton', subtype, nil, true, x, y, width, height)
    self.bodyType = 'static'
    self.data.functionObject = functionObject
    self.isHitTestable = true
    self.isVisible = false
    self:addEventListener('touch', handleTouch)

    -- self.isVisible = true; self:setRgb( 0, math.random(0, 255), 255, 70); self.alpha = .5 ---

    self:toFront()
    appAddSprite(self, handle, moduleGroup)
end

function self:createDialogSetParts()
    local function handleGoldText(self)
        local text = 'YOUR GOLD: ' .. app.gold
        if text ~= self.text then
            self.text = text
        end
    end

    appRemoveSpritesByGroup('menu')
    app.menu:createDarkOverlay()

    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogParts', 'menu/parts-dialog', false, app.maxXHalf, app.maxYHalf, 1024, 768)
    appAddSprite(self, handle, moduleGroup)

    for i = 1, app.partsPerPage do
        local index = (app.partsDialogPageNumber - 1) * app.partsPerPage + i
        if index > #app.partSubtypesOrder then break end

        app.menu:createPart(app.partSubtypesOrder[index])
    end

    local goldTextWidth = 300
    local goldText = spriteModule.spriteClass('text', 'goldText', 'goldText', nil, false, 54 + goldTextWidth / 2, 62, goldTextWidth, 50)
    goldText:setFontSize(23)
    goldText:setRgb(67, 79, 100)
    appAddSprite(goldText, handleGoldText, moduleGroup)

    app.menu:createDialogButton(980, 38, app.menu.saveAndRestartGameIfChanged, 45, 45)

    local bottomButtonWidth = 128
    local bottomButtonHeight = 28
    local bottomButtonY = 712
    app.menu:createDialogButton(772, bottomButtonY, app.menu.resetSelections, bottomButtonWidth, bottomButtonHeight)
    app.menu:createDialogButton(911, bottomButtonY, appRestorePurchases, bottomButtonWidth, bottomButtonHeight)

    local checkDifferentPartsForEach = spriteModule.spriteClass('rectangle', 'dialog', 'checkDifferentPartsForEach', 'menu/checkmark-small', false,
            570 - 357, 708, 12, 13)
    checkDifferentPartsForEach.isVisible = app.settingsDifferentPartsForEach
    appAddSprite(checkDifferentPartsForEach, nil, moduleGroup)

    local checkUseMorePartsPerWagon = spriteModule.spriteClass('rectangle', 'dialog', 'checkUseMorePartsPerWagon', 'menu/checkmark-small', false,
            735 - 357, 708, 12, 13)
    checkUseMorePartsPerWagon.isVisible = app.settingsUseMorePartsPerWagon
    appAddSprite(checkUseMorePartsPerWagon, nil, moduleGroup)

    local checkUseMoreBuildingSeconds = spriteModule.spriteClass('rectangle', 'dialog', 'checkUseMoreBuildingSeconds', 'menu/checkmark-small', false,
            889 - 357, 708, 12, 13)
    checkUseMoreBuildingSeconds.isVisible = app.settingsUseMoreBuildingSeconds
    appAddSprite(checkUseMoreBuildingSeconds, nil, moduleGroup)

    app.menu:createDialogButton(555 - 357, 693, app.menu.toggleSettingsDifferentPartsForEach, 139, 37, true)
    app.menu:createDialogButton(720 - 357, 693, app.menu.toggleSettingsUseMorePartsPerWagon, 115, 37, true)
    app.menu:createDialogButton(875 - 357, 693, app.menu.toggleSettingsUseMoreBuildingSeconds, 107, 37, true)

    app.menu:createDialogButton(49, 516, app.menu.setPartsPageBack, 49, 45, true)
    app.menu:createDialogButton(878, 516, app.menu.setPartsPageForward, 100, 45, true)

    app.menu:createDialogButton(62, 652, app.menu.showAboutPurchasing, 50, 50)

    app.menu:createBuyGoldTexts()
end

function self:showAboutPurchasing()
    local text = "Gold package purchases can be made once and will be restorable for a life time, so if you switch devices you don't need to purchase again! " ..
            "I'm an indie developer and want to thank you for the support, which helps me create more things for you!"
    appAlert(text)
end

function self:setPartsPageBack()
    app.partsDialogPageNumber = app.partsDialogPageNumber - 1
    if app.partsDialogPageNumber < 1 then app.partsDialogPageNumber = app.partsDialogPageNumberMax end
    app.menu:createDialogSetParts()
end

function self:setPartsPageForward()
    app.partsDialogPageNumber = app.partsDialogPageNumber + 1
    if app.partsDialogPageNumber > app.partsDialogPageNumberMax then app.partsDialogPageNumber = 1 end
    app.menu:createDialogSetParts()
end

function self:prepareCreateDialogSetParts()
    appPlaySound('click')
    setIsHitTestableByType('dragPart', nil, false)
    setIsHitTestableByType('setPartsButton', nil, false)
    appPauseGame()
    app.settingsBeforeSetPartsDialog = {
            partSubtypes = misc.cloneTable(app.partSubtypes),
            settingsUseMorePartsPerWagon = app.settingsUseMorePartsPerWagon,
            settingsUseMoreBuildingSeconds = app.settingsUseMoreBuildingSeconds,
            settingsDifferentPartsForEach = app.settingsDifferentPartsForEach
            }
    app.menu:createDialogSetParts()
end

function self:saveAndRestartGameIfChanged()
    appSaveData()
    local foundChangedSetting = false
    for key, value in pairs(app.partSubtypes) do
        if app.partSubtypes[key].selected ~= app.settingsBeforeSetPartsDialog.partSubtypes[key].selected then
            foundChangedSetting = true
            break
        end
    end
    if app.settingsUseMorePartsPerWagon ~= app.settingsBeforeSetPartsDialog.settingsUseMorePartsPerWagon then foundChangedSetting = true end
    if app.settingsUseMoreBuildingSeconds ~= app.settingsBeforeSetPartsDialog.settingsUseMoreBuildingSeconds then foundChangedSetting = true end
    if app.settingsDifferentPartsForEach ~= app.settingsBeforeSetPartsDialog.settingsDifferentPartsForEach then foundChangedSetting = true end

    if foundChangedSetting then appRestartGame()
    else appResumeGame()
    end
end

function self:createBuyGoldTexts()
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'ended' then
            appPlaySound('click')
            local id = self.data.productId
            if appGetProductIsPurchasedPerDB(id) then
                appAlert('You already purchased this.')
            else
                local doTest = false
                if doTest and app.isLocalTest then
                    local testPurchase = { transaction = { state = 'purchased', productIdentifier = id } }
                    appStoreCallback(testPurchase)
                else
                    appStartPurchase(id)
                end
            end
        end
    end

    for i = 1, #app.products do
        app.menu:createBuyGoldText(1, i, app.products[i].title)
        app.menu:createBuyGoldText(2, i, '...')
    end

    local width = 190
    local height = 78
    local lefts = {148, 358, 571, 786}
    for i = 1, #lefts do
        local x = lefts[i] + width / 2
        local button = spriteModule.spriteClass('rectangle', 'dialog', 'purchaseGoldButton', nil, false, x, 594 + height / 2, width, height)
        button.data.productId = appPrefixProductId('goldpack' .. i)
        button.isHitTestable = true
        button.isVisible = false
        button:addEventListener('touch', handleTouch)
        appAddSprite(button, handle, moduleGroup)
    end
end

function self:createBuyGoldText(row, productIndex, text)
    local function handle(self)
        local product = app.products[self.data.productIndex]
        local text = nil
        if product.isPurchased then
            text = 'Purchased.'
        elseif product.price ~= nil and product.price ~= '' then
            text = product.goldAmount .. ' GOLD for ' .. product.price
        else
            text = product.goldAmount .. ' GOLD'
        end

        if text ~= self.text then
            self.text = text
        end
    end

    local frontSprite = nil

    for xOff = -2, 2 do
        for yOff = -2, 2 do
            local x = 230 + (productIndex - 1) * 220 + xOff
            local y = 640 + (row - 1) * 20 + yOff
            local self = spriteModule.spriteClass('text', 'dialogGoldText', nil, nil, false, x, y)
            self:setFontSize(23)
            self.text = text
            self.data.productIndex = productIndex

            self.alpha = .6
            self:setRgb(31, 45, 63)
            if math.abs(xOff) == 2 or math.abs(xOff) == 2 then
                self.alpha = .15
            elseif xOff == 0 and yOff == 0 then
                self:setRgb(255, 253, 106)
                self.alpha = 1
                frontSprite = self
            end

            if row == 1 then appAddSprite(self, nil, moduleGroup)
            else appAddSprite(self, handle, moduleGroup)
            end
        end
    end
    frontSprite:toFront()
end

function self:toggleSettingsDifferentPartsForEach()
    app.settingsDifferentPartsForEach = not app.settingsDifferentPartsForEach
    local checkmark = appGetSpriteByType('dialog', 'checkDifferentPartsForEach')
    checkmark.isVisible = app.settingsDifferentPartsForEach
end

function self:toggleSettingsUseMorePartsPerWagon()
    app.settingsUseMorePartsPerWagon = not app.settingsUseMorePartsPerWagon
    local checkmark = appGetSpriteByType('dialog', 'checkUseMorePartsPerWagon')
    checkmark.isVisible = app.settingsUseMorePartsPerWagon
end

function self:toggleSettingsUseMoreBuildingSeconds()
    app.settingsUseMoreBuildingSeconds = not app.settingsUseMoreBuildingSeconds
    local checkmark = appGetSpriteByType('dialog', 'checkUseMoreBuildingSeconds')
    checkmark.isVisible = app.settingsUseMoreBuildingSeconds
end

function self:updatePart(key)
    local part = app.partSubtypes[key]

    local partButton = appGetSpriteByType('dialog', 'partButton' .. key)
    partButton.isVisible = part.owned

    local partButtonNonOwned = appGetSpriteByType('dialog', 'partButtonNonOwned' .. key)
    if partButtonNonOwned and partButtonNonOwned.energySpeed == 0 and part.owned then
        partButtonNonOwned.energySpeed = -2
        app.menu:createPartSun(partButton.x, partButton.y)
    end

    local costBack = appGetSpriteByType('dialog', 'partCostBack' .. key)
    costBack.isVisible = not part.owned

    local costText = appGetSpriteByType('dialog', 'partCostText' .. key)
    costText.isVisible = not part.owned

    local selected = appGetSpriteByType('dialog', 'partSelected' .. key)
    selected.isVisible = part.selected
end

function self:createPartSun(x, y)
    local size = 250
    local self = spriteModule.spriteClass('rectangle', 'sunTransition', 'small', 'sun-small', false, x, y, size, size)
    self.rotationSpeed = 3
    self.energySpeed = -2
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createPart(key)
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'ended' then
            appPlaySound('click')

            local part = app.partSubtypes[self.data.subtypeKey]
            if not part.owned then
                if part.price <= app.gold then
                    app.gold = app.gold - part.price
                    part.owned = true
                    part.selected = true

                    app.data:set('gold', app.gold)
                    app.data:setBool('partOwned_' .. self.data.subtypeKey, part.owned)
                    app.data:setBool('partSelected_' .. self.data.subtypeKey, part.selected)

                    if appGetSpriteCountByType('sunTransition', 'small') == 0 then
                        appPlaySound('got-new-part')
                    end
                else
                    appAlert('Please buy more Gold to get this item.')
                end
            else
                part.selected = not part.selected
            end

            app.menu:updatePart(self.data.subtypeKey)
        end
    end

    local partsPerRow = 6
    local partRow = 1
    local partI = 1
    local partWidth = 135
    local partHeight = 135
    local partMarginRight = 21
    local partMarginBottom = 18
    local partPadding = 3

    local x = 0
    local y = 0
    local part = app.partSubtypes[key]

    for i = 1, #app.partSubtypesOrder do
        local thisKey = app.partSubtypesOrder[i]

        x = 55 + (partI - 1) * (partWidth + partMarginRight) + partWidth / 2
        y = 65 + (partRow - 1) * (partHeight + partMarginBottom) + partHeight / 2

        if thisKey == key then break end

        partI = partI + 1
        if partI > partsPerRow then
            partI = 1
            if i > (app.partsDialogPageNumber - 1) * app.partsPerPage then
                partRow = partRow + 1
            end
        end
    end

    local button = spriteModule.spriteClass('rectangle', 'dialog', 'partButton' .. key, 'menu/part-background', false, x, y, partWidth, partHeight)
    button.data.subtypeKey = key
    button.isHitTestable = true
    button:addEventListener('touch', handleTouch)
    appAddSprite(button, handle, moduleGroup)

    if not part.owned then
        local buttonNonOwned = spriteModule.spriteClass('rectangle', 'dialog',
                'partButtonNonOwned' .. key, 'menu/part-background-non-owned', false, x, y, partWidth, partHeight)
        buttonNonOwned.energy = 100
        buttonNonOwned.alphaChangesWithEnergy = true
        appAddSprite(buttonNonOwned, nil, moduleGroup)
    end

    if part.title then
        local textWidth = partWidth - partPadding * 2 - 6
        local textX = x + partPadding - 3
        local textY = y + 28
        local text = spriteModule.spriteClass('text', 'dialog', 'partText', nil, false, textX, textY, textWidth, 58)
        text:setFontSize(20)

        if app.language == 'de' and part.title_de and part.description_de then
            text.text = part.title_de:upper() .. ': ' .. part.description_de
        else
            text.text = part.title:upper() .. ': ' .. part.description
        end

        text:setRgb(10, 21, 48)
        appAddSprite(text, nil, moduleGroup)
    end

    local selected = spriteModule.spriteClass('rectangle', 'dialog', 'partSelected' .. key, 'menu/part-selected', false, x + 40, y - 38, 33, 35)
    appAddSprite(selected, nil, moduleGroup)

    local costBack = spriteModule.spriteClass('rectangle', 'dialog', 'partCostBack' .. key, 'menu/get-for', false, x + 32, y - 32, 71, 71)
    appAddSprite(costBack, nil, moduleGroup)

    local costText = spriteModule.spriteClass('text', 'dialog', 'partCostText' .. key, nil, false, x + 46, y - 26, 80, 30)
    costText:setFontSize(17)
    if part.price then costText.text = part.price .. ' GOLD' end
    costText:setRgb(227, 117, 45)
    costText.rotation = 45
    appAddSprite(costText, nil, moduleGroup)

    local maxWidth = 66
    local maxHeight = 44
    local imageX = x - maxWidth / 2 + 12
    local imageY = y - maxHeight / 2 - 5
    local factor = .6
    local isSmall = part.width <= 100 and part.height <= 100
    local imageWidth = part.width * part.sampleSizeFactor
    local imageHeight = part.height * part.sampleSizeFactor
    local image = spriteModule.spriteClass('rectangle', 'dialog', 'partImage' .. key, 'part-1/' .. key, false, imageX, imageY, imageWidth, imageHeight)
    if part.sampleRotation then image.rotation = part.sampleRotation end
    appAddSprite(image, nil, moduleGroup)

    app.menu:updatePart(key)
end

function self:resetSelections()
    appResetSettings()
    app.menu:createDialogSetParts()
end

function self:createButtons()
    local function handleTouch(event)
        local self = event.target
        if event.phase == 'ended' then
            if appGetSpriteCountByType('dialog', 'dialogParts') == 0 then

                local menuTriggersPhaseSkip = false and app.isLocalTest
                if menuTriggersPhaseSkip then
                    app.phase:set(app.phase.nameNext)
                else
                    if appGetSpriteByType('dialog') == nil then
                        app.menu:createDialogSmall()
                        appPauseGame()
                    else
                        appResumeGame()
                    end
                end
    
                appPlaySound('click')
            end
        end
    end

    appRemoveSpritesByType('menuButton')
    local width = 120
    local height = 39
    local x = 630
    if app.language == 'zh' then x = 608 end
    local y = app.maxY - height + height / 2

    local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, nil, false, x, y, width, height)
    self.bodyType = 'static'
    self.isHitTestable = true
    self.isVisible = false
    self:addEventListener('touch', handleTouch)    
    -- self:setRgb( 0, math.random(0, 255), 255, 70)

    appAddSprite(self, handle, 'menuButton')
end

return self
end