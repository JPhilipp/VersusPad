module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.parentPlayer = nil

function self:createDarkOverlay()
    if appGetSpriteByType('darkOverlay') == nil then
        local self = spriteModule.spriteClass('rectangle', 'darkOverlay', nil, nil, false, app.maxX / 2, app.maxY / 2, app.maxX, app.maxY)
        self:setRgbBlack()
        self:setFillColorBySelf()
        self.alpha = .4
        appAddSprite(self, handle, moduleGroup)
    end
end

function self:startTraining()
    appEndGame()
    appResumeGame()
    app.extra:doStart(app.menu.parentPlayer, 'training')
end

function self:moveControlPosition()
    if app.leftHandedControl[app.menu.parentPlayer] then
        app.leftHandedControlManuallySwitchedInRowCount[app.menu.parentPlayer] = 0
    else
        app.leftHandedControlManuallySwitchedInRowCount[app.menu.parentPlayer] = app.leftHandedControlManuallySwitchedInRowCount[app.menu.parentPlayer] + 1
    end
    appToggleControlPosition(app.menu.parentPlayer)
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

    appRemoveSpritesByType('dialog')
    appRemoveSpritesByType('dialogButton')

    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogHelp', 'menu/large', false, app.maxX / 2, app.maxY / 2 + 54, 745, 861)
    if app.menu.parentPlayer == 2 then self:mirrorXY() end
    self.energy = 10
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    self.data.targetY = self.y
    self.y = self.y + misc.getIf(app.menu.parentPlayer == 1, 8, -8)
    appAddSprite(self, handle, moduleGroup)

    app.menu:createDialogButton(app.maxX / 2, 375, app.menu.showVideo)
    app.menu:createDialogButton(530, 651 - 21, app.menu.showEmailDialog, 250, 38)
    app.menu:createDialogButton(233, 675 - 21, app.menu.showMoreGames, 140, 38)
    app.menu:createDialogButton(437, 699 - 21, app.menu.showReviewPage, 278, 38)
    app.menu:createDialogButton(app.maxX / 2, 927, appResumeGame)
end

function self:showVideo()
    media.playVideo('video/help.m4v', true)
end

function self:createDialogSmall()
    local function handle(self)
        if self.y > self.data.targetY then self.y = self.y - 1
        elseif self.y < self.data.targetY then self.y = self.y + 1
        end
    end

    local isTraining = app.extra ~= nil and app.extra.name == 'training'

    app.menu:createDarkOverlay()

    local dialogX = 258
    local dialogY = 784
    local width = 426
    local height = 423
    if app.leftHandedControl[app.menu.parentPlayer] then dialogX = app.maxX - width / 2 + 17 end

    local filename = misc.getIf(isTraining, 'menu/small-during-training', 'menu/small')
    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogSmall', filename, false, dialogX, dialogY, width, height)
    if app.menu.parentPlayer == 2 then self:mirrorXY() end
    self.data.targetY = self.y
    self.y = self.y + misc.getIf(app.menu.parentPlayer == 1, 8, -8)
    self.energy = 10
    self.energySpeed = 10
    self.alphaChangesWithEnergy = true
    appAddSprite(self, handle, moduleGroup)

    local baseY = dialogY - 137
    local spacerY = 52
    local i = 0
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.createDialogHelp); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, appRestartGame); i = i + 1

    if isTraining then app.menu:createDialogButton(dialogX, baseY + spacerY * i, appRestartGame); i = i + 1
    else app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.startTraining); i = i + 1
    end

    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.moveControlPosition); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i, app.menu.showMoreGames); i = i + 1
    app.menu:createDialogButton(dialogX, baseY + spacerY * i + 27, appResumeGame); i = i + 1
end

function self:createDialogButton(x, y, functionObject, optionalWidth, optionalHeight)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click.mp3')
            self.data:functionObject()
        end
    end

    local width = misc.getIf(optionalWidth == nil, 356, optionalWidth)
    local height = misc.getIf(optionalHeight == nil, 48, optionalHeight)

    local self = spriteModule.spriteClass('rectangle', 'dialogButton', subtype, nil, true, x, y, width, height)
    self.data.functionObject = functionObject
    self.isHitTestable = true
    self.isVisible = false
    -- self:setRgb( 0, math.random(0, 255), 255, 70); self:setFillColorBySelf()
    self.listenToTouch = true
    self:toFront()
    if app.menu.parentPlayer == 2 then self:mirrorXY() end
    appAddSprite(self, handle, moduleGroup)
end

function self:createButtons()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            local menuTriggersExtraSelection = false
            if menuTriggersExtraSelection then

                if appGetSpriteByType('extraButtonsDialog') == nil then
                    app.extra:doEnd()
                    app.extra.spritesHandler:createExtraSelectionDialog()
                    appPauseGame()
                else
                    appResumeGame()
                    appRemoveSpritesByGroup('menu')
                end

            else                
                if appGetSpriteByType('dialog') == nil then
                    app.menu.parentPlayer = self.parentPlayer
                    app.menu:createDialogSmall()
                    appPauseGame()
                else
                    appResumeGame()
                    appRemoveSpritesByGroup('menu')
                end

            end
            appPlaySound('click.mp3')
        end
    end

    appRemoveSpritesByType('menuButton')
    for playerI = 1, app.playerMax do
        local width = 110
        local height = 60
        local x = 250
        local y = app.maxY - height + height / 2

        if app.leftHandedControl[playerI] then x = app.maxX - width / 2 end

        if playerI == 2 then
            x = app.maxX - x
            y = app.maxY - y
        end

        local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, nil, false, x, y, width, height)
        self.parentPlayer = playerI
        self.listenToTouch = true
        self.isVisible = false
        self.isHitTestable = true
        appAddSprite(self, handle, 'menuButton')
    end
end

return self
end