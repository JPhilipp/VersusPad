module(..., package.seeall)
local moduleGroup = 'menu'

function menuClass()
local self = {}
self.helpPageNumber = 1

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
    local self = spriteModule.spriteClass('rectangle', 'dialog', 'dialogHelp', 'help', false, app.maxXHalf, app.maxYHalf, app.maxX, app.maxY)
    self.doDieOutsideField = false
    appAddSprite(self, handle, moduleGroup)

    if app.language == 'de' then
        app.menu:createDialogButton(55, 430, app.menu.showMoreGames, 510, 100)
        app.menu:createDialogButton(55, 602, app.menu.showReviewPage, 414, 49)
        app.menu:createDialogButton(55, 651, app.menu.showEmailDialog, 414, 56)
    else
        app.menu:createDialogButton(55, 445, app.menu.showMoreGames, 510, 100)
        app.menu:createDialogButton(55, 624, app.menu.showReviewPage, 414, 39)
        app.menu:createDialogButton(55, 665, app.menu.showEmailDialog, 414, 46)
    end
    app.menu:createCloseButton()
end

function self:createCloseButton()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            appRemoveSpritesByGroup('menu')
            appResume()
        end
    end

    local width = 134; local height = 100
    local self = spriteModule.spriteClass('rectangle', 'dialogButton', 'close', nil, false, app.maxX - width / 2, width / 2, width, height)
    self.doDieOutsideField = false
    self.isHitTestable = true
    self.isVisible = false
    -- self:setRgb( 0, math.random(0, 255), 255, 70 )
    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createDialogButton(left, top, functionObject, width, height, optionalSubtype)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            self.data:functionObject()
        end
    end

    local self = spriteModule.spriteClass('rectangle', 'dialogButton', optionalSubtype, nil, false, left + width / 2, top + height / 2, width, height)
    self.data.functionObject = functionObject
    self.isVisible = false
    self.isHitTestable = true
    -- self:setRgb( 0, math.random(0, 255), 255, 70 )

    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
end

function self:createButtons()
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click')
            if appGetSpriteByType('dialog') == nil then
                app.menu:createDialogHelp()
                appPause()
            else
                appRemoveSpritesByGroup('menu')
                appResume()
            end
        end
    end

    appRemoveSpritesByType('menuButton')
    local width = 105; local height = 50
    local self = spriteModule.spriteClass('rectangle', 'menuButton', nil, nil, false, app.maxX - width / 2, height / 2, width, height)
    self.doDieOutsideField = false
    self.isVisible = false
    self.isHitTestable = true
    -- self:setRgb( 0, math.random(0, 255), 255, 70 )

    self.listenToTouch = true
    appAddSprite(self, handle, 'menuButton')
end

return self
end