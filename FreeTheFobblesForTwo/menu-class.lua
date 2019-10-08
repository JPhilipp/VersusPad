module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.helpPageNumber = 1

function self:createDarkOverlay()
    if appGetSpriteByType('darkOverlay') == nil then
        local self = spriteModule.spriteClass('rectangle', 'darkOverlay', nil, nil, false, app.maxX / 2, app.maxY / 2, app.maxX, app.maxY + appGetLetterboxHeight() * 2)
        self:setRgbBlack()
        self:setFillColorBySelf()
        self.alpha = .32
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:toggleTraining()
    appEndGame()
    app.mode = misc.getIf(app.mode == 'default', 'training', 'default')
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
    if app.isIOs then
        local countryCode = system.getPreference('locale', 'country')
        local appUrl = 'itms://itunes.apple.com/' .. countryCode .. '/app/' .. misc.toName(app.title) .. '/id' .. app.id
    else
        appUrl = 'https://play.google.com/store/apps/details?id=' .. app.idInStore
    end
    system.openURL(appUrl)
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
    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogHelp', imageName, false, app.maxX / 2, app.maxY / 2 + 54, 683, 855)
    if app.menu.parentPlayer == 2 then self:mirrorXY() end
    self.energy = 10
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    self.data.targetY = self.y
    self.y = self.y + misc.getIf(app.menu.parentPlayer == 1, 8, -8)
    self.data.pageNumber = pageNumber
    appAddSprite(self, handle, moduleGroup)

    if pageNumber == 1 then

        if app.language == 'zh' then
            app.menu:createDialogButton(app.maxXHalf, 498, app.menu.createDialogHelp)
            app.menu:createDialogButton(564, 624, app.menu.showEmailDialog, 190, 28)
            app.menu:createDialogButton(452, 650, app.menu.showMoreGames, 120, 30)
            app.menu:createDialogButton(400, 676, app.menu.showReviewPage, 216, 28)
        else
            app.menu:createDialogButton(app.maxXHalf, 514, app.menu.createDialogHelp)
            app.menu:createDialogButton(564, 647, app.menu.showEmailDialog, 210, 32)
            app.menu:createDialogButton(270, 665, app.menu.showMoreGames, 140, 34)
            app.menu:createDialogButton(501, 684, app.menu.showReviewPage, 295, 32)
        end

        appPlaySound('theme')
    elseif pageNumber == 2 then
        app.menu:createDialogButton(566, 837, app.menu.createDialogHelp, 270)
    end
    app.menu:createDialogButton(app.maxX / 2, 927, appResumeGame)
end

function self:createDialogSmall()
    local function handle(self)
        if self.y > self.data.targetY then self.y = self.y - 1
        elseif self.y < self.data.targetY then self.y = self.y + 1
        end
    end

    app.menu:createDarkOverlay()

    local dialogX = app.maxXHalf
    local dialogY = 792
    local width = 473
    local height = 413

    local filename = misc.getIf(app.mode == 'training', 'menu/selection-during-training', 'menu/selection')
    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogSmall', filename, false, dialogX, dialogY, width, height)
    self.data.targetY = self.y
    self.y = self.y + misc.getIf(app.menu.parentPlayer == 1, 8, -8)
    self.energy = 10
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)

    local baseY = dialogY - 123
    local spacerY = 55
    local i = 0
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.createDialogHelp); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, appRestartGame); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.toggleTraining); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.showMoreGames); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i + 43, appResumeGame); i = i + 1
end

function self:createDialogButton(x, y, functionObject, optionalWidth, optionalHeight)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click.mp3')
            self.data:functionObject()
        end
    end

    local width = misc.getIf(optionalWidth == nil, 344, optionalWidth)
    local height = misc.getIf(optionalHeight == nil, 51, optionalHeight)

    local self = spriteModule.spriteClass('rectangle', 'dialogButton', subtype, nil, true, x, y, width, height)
    self.data.functionObject = functionObject
    self.isHitTestable = true
    self.isVisible = false
    -- self:setRgb( 0, math.random(0, 255), 255, 70)

    self.listenToTouch = true
    self:toFront()
    appAddSprite(self, handle, moduleGroup)
end

function self:createButtons()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            if appGetSpriteByType('dialog') == nil then
                app.menu:createDialogSmall()
                appPauseGame()
            else
                appResumeGame()
                appRemoveSpritesByGroup('menu')
            end
            appPlaySound('click')
        end
    end

    appRemoveSpritesByType('menuButton')
    local width = 135
    local height = 49
    local x = 555
    local y = app.maxY - height + height / 2

    local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, nil, false, x, y, width, height)
    self.listenToTouch = true
    self.isHitTestable = true
    self.isVisible = false
    appAddSprite(self, handle, 'menuButton')
end

return self
end