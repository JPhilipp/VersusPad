module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.helpPageNumber = 1

function self:goToHomepage()
    system.openURL('http://versuspad.com')
end

function self:showTutorialVideo()
    system.openURL('http://www.youtube.com/watch?v=p9uV3e--_A4')
end

function self:showReviewPage()
    local appUrl = ''
    if app.isIOs then
        local countryCode = system.getPreference('locale', 'country')
        local appUrl = 'itms://itunes.apple.com/' .. countryCode .. '/app/' .. misc.toName(app.title) .. '/id' .. app.id
    else
        appUrl = 'https://play.google.com/store/apps/details?id=' .. app.idInStore
    end
    system.openURL(appUrl)
end

function self:createButton(x, y, imageName, functionObject, width, height, optionalData)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            self.data:functionObject(self.data)
        end
    end

    if x == nil then x = app.maxXHalf end
    if y == nil then y = app.maxYHalf end
    if width == nil then width = 274 end
    if height == nil then height = 41 end
    local subtype = imageName
    if imageName ~= nil then imageName = 'menu/button/' .. imageName end
    local self = spriteModule.spriteClass('rectangle', 'menuButton', subtype, imageName, false, x, y, width, height)
    if optionalData ~= nil then self.data = optionalData end
    self.data.functionObject = functionObject
    if imageName == nil then
        self.isVisible = false
        self.isHitTestable = true
        -- self:setRgb( 0, math.random(0, 255), 255, 70 )
    end
    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createPageLoadMachine(newPage)
    local function handleLoadArea(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appDeleteMachinesMarkedForDeletion()
            appClearMachine()
            appLoadMachineData(self.data.machineId)
            app.currentSavedId = self.data.machineId
            appPlaySound('click')
            appStart()
            appResume()
        end
    end

    local function handleDeleteMachine(self, data)
        if not misc.inArray(app.machineIdsToDeleteSoon, data.machineId) then
            app.machineIdsToDeleteSoon[#app.machineIdsToDeleteSoon + 1] = data.machineId
            app.menu:createPageLoadMachine(app.currentLoadMachinePage)
        end
    end

    local function handleUndoDeleteMachine(self, data)
        misc.removeSingleValueFromArray(app.machineIdsToDeleteSoon, data.machineId)
        app.menu:createPageLoadMachine(app.currentLoadMachinePage)
    end

    local function switchToNextPage()
        self:createPageLoadMachine(app.currentLoadMachinePage + 1)
    end

    if newPage == nil then app.currentLoadMachinePage = 1
    else app.currentLoadMachinePage = newPage
    end

    appRemoveSpritesByGroup('menu')
    local backgroundPageId = app.menu:createFreshPageWithBackground(nil, true)

    local machinesPerPage = 4
    local machineCount = app.data:getCount('machines')
    local min = (app.currentLoadMachinePage - 1) * machinesPerPage + 1
    local max = min + machinesPerPage - 1
    local previewOffsetX = misc.getIf(machineCount > machinesPerPage, 0, 22)
    local doIncludeNextButton = false
    local machineI = 0
    local previewWidth = 88; local previewHeight = 117
    local scale = (previewWidth / app.maxX)

    local rows = {}
    local query = 'SELECT id, dataString FROM machines WHERE dateLastSaved <> "" ORDER BY dateLastSaved DESC'
    for row in app.data.db:nrows(query) do rows[#rows + 1] = row end

    if #rows == 0 then
        local emptyMessage = spriteModule.spriteClass('rectangle', 'emptyMessage', nil, 'menu/loadEmpty', false, app.maxXHalf, 197, 245, 38)
        appAddSprite(emptyMessage, nil, moduleGroup)
    else
        for i = 1, #rows do
            if i >= min and i <= max then
                local row = rows[i]
                local markedForDeletion = misc.inArray(app.machineIdsToDeleteSoon, row.id)
    
                machineI = machineI + 1
                local centerPoints = {
                        {x = 81 + previewOffsetX, y = 120}, {x = 200 + previewOffsetX, y = 120},
                        {x = 81 + previewOffsetX, y = 282}, {x = 200 + previewOffsetX, y = 282} }
                local x = centerPoints[machineI].x; local y = centerPoints[machineI].y

                local alpha = misc.getIf(markedForDeletion, .3, 1)
                local previewBack = spriteModule.spriteClass('rectangle', 'previewBack', nil, 'menu/previewBackground', false, x, y - 10, 94, 104)
                previewBack.parentId = backgroundPageId
                previewBack.data.machineId = row.id
                previewBack.alpha = alpha
                appAddSprite(previewBack, handleLoadArea, moduleGroup)
    
                app.menu:createPreviewBlocks( x, y, previewWidth, previewHeight,
                        appGetPlanesDataFromString(row.dataString), backgroundPageId, scale, alpha )
    
                if markedForDeletion then
                    app.menu:createButton( x, y - 15, 'deletedUndo', handleUndoDeleteMachine, 62, 48, {machineId = row.id} )
                else
                    previewBack.listenToTouch = true
                    local deleteButton = app.menu:createButton( x + 35, y - 50, 'delete', handleDeleteMachine, 25, 25, {machineId = row.id} )
                end
    
                local vignette = spriteModule.spriteClass('rectangle', 'vignette', nil, 'menu/previewVignette', false, x, y, 103, 137)
                vignette.parentId = backgroundPageId
                appAddSprite(vignette, nil, moduleGroup)

                if not markedForDeletion then
                    local loadButton = spriteModule.spriteClass('rectangle', 'menuButton', nil, 'menu/button/load', false,
                            x, y + 49, 87, 28)
                    loadButton.parentId = backgroundPageId
                    loadButton.data.machineId = row.id
                    loadButton.listenToTouch = true
                    appAddSprite(loadButton, handleLoadArea, moduleGroup)
                end
    
            elseif i > max then
                doIncludeNextButton = true
            end
        end

        if doIncludeNextButton then app.menu:createButton(280, 200, 'nextPage', switchToNextPage, 29, 295) end
    end
end

function self:createPreviewBlocks(centerX, centerY, previewWidth, previewHeight, planesData, parentId, scale, alpha)
    local blockScaleAdjust = .88
    local previewPlane = 1
    local planeData = planesData[1]
    local boundary = {x1 = centerX - previewWidth * .5, y1 = centerY - previewHeight * .5,
            x2 = centerX + previewWidth * .5, y2 = centerY + previewHeight * .5 - 15}
    local margin = -5

    for i = 1, #planeData do
        local block = planeData[i]
        local x = centerX - previewWidth * .5 + block.x * (scale * blockScaleAdjust) + 5.5
        local y = centerY - previewHeight * .5 + block.y * (scale * blockScaleAdjust) - 5.5
        local isInBoundary = x - margin >= boundary.x1 and x + margin <= boundary.x2 and y - margin >= boundary.y1 and y + margin <= boundary.y2
        if isInBoundary then
            app.spritesHandler:createBlockOrNavigationBlock('block', block.subtype, x, y,
                    block.rotationIndex, nil, block.noteIndex, true, scale, alpha, parentId)
        end
    end
end

function self:createPageMain()
    local function showPageHowToPlay() app.menu:createPageHowToPlay() end
    local function showPageMoreGamesAbout() app.menu:createPageMoreGamesAbout() end
    local function showPageUnlockPremium() app.menu:createPageUnlockPremium() end
    local function showLoadPage() app.menu:createPageLoadMachine() end

    local backgroundPageId = app.menu:createFreshPageWithBackground('main')

    local isPremium = app.products[1].isPurchased
    local y = 131
    local margin = 42
    local premiumMarkerX = 255

    app.menu:createButton(198, 60, nil, appRestart, 198, 41)

    app.menu:createButton( nil, y + margin * 0, nil, misc.getIf(isPremium, showLoadPage, app.menu.createPageUnlockPremium) )
    if not isPremium then app.spritesHandler:createPremiumMarker(premiumMarkerX, y + margin * 0 + 1, backgroundPageId, moduleGroup) end

    app.menu:createButton( nil, y + margin * 1, nil, misc.getIf(isPremium, appSaveMachine, app.menu.createPageUnlockPremium) )
    if not isPremium then app.spritesHandler:createPremiumMarker(premiumMarkerX, y + margin * 1 - 1, backgroundPageId, moduleGroup) end

    app.menu:createButton( nil, y + margin * 2, nil, misc.getIf(isPremium, appSaveMachineAsNew, app.menu.createPageUnlockPremium) )
    if not isPremium then app.spritesHandler:createPremiumMarker(premiumMarkerX, y + margin * 2 - 2, backgroundPageId, moduleGroup) end

    app.menu:createButton(nil, y + margin * 3 + 5, nil, app.menu.showTutorialVideo)
    app.menu:createButton(nil, y + margin * 5 + 5, nil, showPageMoreGamesAbout)

    if app.products[1].isPurchased then
        local ownsPremiumLabel = spriteModule.spriteClass('image', 'menuButton', nil, 'menu/ownsPremiumLabel', false, app.maxXHalf, 305, 266, 29)
        ownsPremiumLabel.parentId = backgroundPageId
        appAddSprite(ownsPremiumLabel, nil, moduleGroup)
    else
        app.menu:createButton(nil, 305, 'upgrade', app.menu.createPageUnlockPremium)
    end
end

function self:createPageMoreGamesAbout()
    local function clearDataForTest()
        app.data:clear()
        app.data:exec('DROP TABLE machines')
        native.showAlert( 'Success', 'OK, all data cleared.', {'OK'} )
    end

    app.menu:createFreshPageWithBackground('moreGamesAbout', true)

    app.menu:createButton(nil, 125, nil, app.menu.goToHomepage, 190, 50)
    app.menu:createButton(193, 229, nil, app.menu.goToHomepage, 133, 28)
    app.menu:createButton(116, 264, nil, app.menu.showReviewPage, 106, 28)
end

function self:createPageUnlockPremium()
    app.menu:createFreshPageWithBackground('unlockPremium', false)

    app.menu:createButton(76, 349, nil, app.menu.closeMenu, 95, 50)
    app.menu:createButton(220, 349, nil, appStartPurchase, 180, 90)
    app.menu:createButton(238, 426, nil, appStartPurchaseRestore, 73, 31)

    store.loadProducts( {app.products[1].id}, appLoadProductsCallback )
    -- app.menu:createPriceText('$0.99')
end

function self:createPriceText(price)
    local parentPage = appGetSpriteById('unlockPremium')
    if parentPage ~= nil then
        appRemoveSpritesByType('price')
        local self = spriteModule.spriteClass('text', 'price', nil, nil, false, 220, 378, 35, 18)
        self.parentId = parentPage.id
        self:setRgb(79, 79, 66)
        self.text = price
        self:setFontSize(24)
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:createBackButton()
    -- app.menu:createButton(74, 25, 'back', app.menu.createPageMain, 116, 27)
end

function self:closeMenu()
    appResume()
end

function self:createFreshPageWithBackground(pageImageName, includeResumeButton)
    if includeResumeButton == nil then includeResumeButton = true end
    appRemoveSpritesByGroup('menu')

    local subtype = pageImageName
    local background = spriteModule.spriteClass('rectangle', 'menuPage', subtype, 'menu/background', false, app.maxXHalf, app.maxYHalf, 308, 433)
    appAddSprite(background, handle, moduleGroup)

    if pageImageName ~= nil then
        local page = spriteModule.spriteClass('rectangle', 'menuPage', nil, 'menu/page/' .. pageImageName, false,
                app.maxXHalf, app.maxYHalf, 320, 480)
        page.id = pageImageName
        appAddSprite(page, handle, moduleGroup)
    end

    if includeResumeButton then app.menu:createButton(nil, 397, 'resume', app.menu.closeMenu) end
    return background.id
end

function self:createButtons()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            if app.runs then
                app.menu:createPageMain()
                appPause()
                app.showClock = true and app.showDebugInfo
                appPlaySound('click')
            end
        end
    end

    appRemoveSpritesByType('menuButton')
    local width = 31; local height = 29
    local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, 'menu/button/menu', false, 307, 14, width, height)
    self.doDieOutsideField = false
    self.listenToTouch = true
    appAddSprite(self, handle, 'menuButton')
end

function self:createSavedIndicator()
    local function handle(self)
        if self.phase.name == 'fadeOut' then
            if not self.phase:isInited() then
                self.energySpeed = -4
                self.phase:set('default')
            end
        end
    end

    local self = spriteModule.spriteClass('rectangle', 'savedIndicator', nil, 'savedIndicator', false, 39, 12, 58, 23)
    self.energy = 10
    self.energySpeed = 15
    self.alphaChangesWithEnergy = true
    self.phase:setNext('fadeOut', 100)
    appAddSprite(self, handle, moduleGroup)
end

return self
end