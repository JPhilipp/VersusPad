module(..., package.seeall)
require 'sqlite3'
local moduleGroup = 'news'
function newsClass()
local self = {}

self.splitter = '~'
self.waitBeforeTryShowingDays = nil
self.currentlyShownGuid = nil
self.currentlyShownUrl = nil

function self:handle()
    local today = misc.getIsoDate()
    local waitBeforeTryShowingDays = app.data:get('dialog_waitBeforeTryShowingDays')
    local lastTriedToShowDate = app.data:get('dialog_lastTriedToShowDate')
    if not misc.isNumber(waitBeforeTryShowingDays) then waitBeforeTryShowingDays = nil end

    if lastTriedToShowDate == nil or waitBeforeTryShowingDays == nil then
        app.data:set('dialog_lastTriedToShowDate', today)
        app.data:set( 'dialog_waitBeforeTryShowingDays', math.random(2, 4) )
    else
        local differenceInDays = misc.getDifferenceBetweenDatesInDays(lastTriedToShowDate, today)
        if tonumber(differenceInDays) >= tonumber(waitBeforeTryShowingDays) then
            app.data:set('dialog_lastTriedToShowDate', today)
            app.data:set( 'dialog_waitBeforeTryShowingDays', math.random(1, 2) )
            app.news:grabAndHandleLiveNews()
        end
    end
end

function self:grabAndHandleLiveNews()
    local function networkListener(event)
        if not event.isError then
            app.news:handleNewsResponse(event.response)
        end
    end

    local newsUrl = 'http://file.versuspad.com/' .. misc.getIf(app.isAndroid, 'news-android.txt', 'news.txt')
    newsUrl = newsUrl .. '?guid=id' .. misc.getRandomString(32)
    newsUrl = newsUrl .. '&supportsUnicode=true'

    local headers = {}
    headers['Accept-Language'] = app.language
    local params = {}
    params.headers = headers
    network.request(newsUrl, 'GET', networkListener)
end

function self:handleNewsResponse(responseText)
    local responseDataArr = misc.split(responseText, ';')
    local requiredLength = 6
    if #responseDataArr == requiredLength then
        local i = 1
        local guid = responseDataArr[i]; i = i + 1
        local recipientsString = responseDataArr[i]; i = i + 1
        local recipientsExcludedString = responseDataArr[i]; i = i + 1
        local text = responseDataArr[i]; i = i + 1
        local url = responseDataArr[i]; i = i + 1
        local waitBeforeTryShowingDays = app.news:getValueFromRangeString(responseDataArr[i]); i = i + 1

        local recipients = misc.getIf(recipientsString ~= '', misc.split(recipientsString, ','), {} )
        local recipientsExcluded = misc.getIf(recipientsExcludedString ~= '', misc.split(recipientsExcludedString, ','), {} )
        app.data:set('dialog_waitBeforeTryShowingDays', waitBeforeTryShowingDays)

        local isInIncludedNames = misc.inArray(recipients, app.name) or misc.inArray(recipients, app.name .. ' ' .. app.version) or misc.inArray(recipients, '*')
        local isInExcludedNames = misc.inArray(recipientsExcluded, app.name) or misc.inArray(recipientsExcluded, app.name .. ' ' .. app.version)
        local isRecipient = isInIncludedNames and not isInExcludedNames
        if isRecipient and not app.news:newsIsBlacklisted(guid) then
            app.news.waitBeforeTryShowingDays = waitBeforeTryShowingDays
            app.data:set( 'dialog_waitBeforeTryShowingDays', math.random(1, 2) )
            app.news:show(guid, text, url)
        end

    else
        local waitBeforeTryShowingDays = misc.getIf( responseText ~= '', app.news:getValueFromRangeString(responseText),  1 )
        app.data:set('dialog_waitBeforeTryShowingDays', waitBeforeTryShowingDays)
    end
end

function self:newsIsBlacklisted(guid)
    local blacklistString = app.data:get('newsBlacklist')
    local blacklist = {}
    if blacklistString ~= nil then blacklist = misc.split(blacklistString, app.news.splitter) end
    return misc.inArray(blacklist, guid)
end

function self:addToNewsBlacklist(guid)
    local blacklistString = app.data:get('newsBlacklist')
    local blacklist = {}
    if blacklistString ~= nil then blacklist = misc.split(blacklistString, app.news.splitter) end
    if not misc.inArray(blacklist, guid) then
        blacklist[#blacklist + 1] = misc.toName(guid)
    end
    app.data:set( 'newsBlacklist', misc.join(blacklist, app.news.splitter) )
end

function self:show(guid, text, url)
    local function buttonListener(event)
        if event.action == 'clicked' then
            local indexes = {app.news.approveAndGoTo, app.news.cancel, app.news.remind}
            if indexes[event.index] ~= nil then indexes[event.index]() end
        end
    end

    if app.runs then appPause() end
    app.news.currentlyShownGuid = guid
    app.news.currentlyShownUrl = url

    native.showAlert( language.get('newsDialogHeader'), text,
            { language.get('newsDialogShow'), language.get('newsDialogNo'), language.get('newsDialogRemind') }, buttonListener )
end

function self:getValueFromRangeString(rangeString)
    local v = 1
    if not (rangeString == '' or rangeString == nil) then
        local fromToArr = misc.split(rangeString, '-')
        if #fromToArr == 2 then
            v = math.random( misc.toInt(fromToArr[1]), misc.toInt(fromToArr[2]) )
        else
            v = misc.toInt(rangeString)
        end
    end
    return v
end

function self:remind()
    app.data:set('dialog_waitBeforeTryShowingDays', 1)

    appRemoveSpritesByGroup(moduleGroup)
    appResume()
end

function self:cancel()
    app.data:set('dialog_waitBeforeTryShowingDays', app.news.waitBeforeTryShowingDays)
    app.news:addToNewsBlacklist(app.news.currentlyShownGuid)

    appRemoveSpritesByGroup(moduleGroup)
    appResume()
end

function self:approveAndGoTo()
    app.data:set('dialog_waitBeforeTryShowingDays', app.news.waitBeforeTryShowingDays)
    appRemoveSpritesByGroup(moduleGroup)
    app.news:addToNewsBlacklist(app.news.currentlyShownGuid)
    local delayToAllowWritingMS = 500
    timer.performWithDelay(delayToAllowWritingMS, app.news.doGoToNews)
    timer.performWithDelay(3000, appResume)
end

function self:doGoToNews()
    system.openURL(app.news.currentlyShownUrl)
end

function self:createDialogButton(x, y, functionObject, width, height)
    local function handle(self)
        if self.actionOld.touched ~= self.action.touched and self.action.touched then
            appPlaySound('click.mp3')
            self.data:functionObject()
        end
    end

    local self = spriteModule.spriteClass('rectangle', 'newsDialogButton', subtype, nil, false, x, y, width, height)
    self.data.functionObject = functionObject
    self.isHitTestable = true
    self.isVisible = false

    if true and app.isLocalTest then
        self.isVisible = true
        self:setRgb( 0, math.random(0, 255), 255, 70)
    end

    self.listenToTouch = true
    appAddSprite(self, handle, moduleGroup)
    self:toFront()
end

function self:verifyNeededFunctionsAndVariablesExists()
    local preceder = 'News-Class could not find needed '

    if app.isLocalTest == nil then appPrint(preceder .. 'app.isLocalTest', true) end
    if app.data == nil then appPrint(preceder .. 'app.data', true) end
    if app.language == nil then appPrint(preceder .. 'app.language', true) end
    if app.name == nil then appPrint(preceder .. 'app.name', true) end
    if app.version == nil then appPrint(preceder .. 'app.version', true) end
    if app.runs == nil then appPrint(preceder .. 'app.runs', true) end
    if appPause == nil then appPrint(preceder .. 'appPause', true) end
    if app.maxX == nil then appPrint(preceder .. 'app.maxX', true) end
    if app.maxY == nil then appPrint(preceder .. 'app.maxY', true) end
    if appAddSprite == nil then appPrint(preceder .. 'appAddSprite', true) end
    if appRemoveSpritesByGroup == nil then appPrint(preceder .. 'appRemoveSpritesByGroup', true) end
    if appResume == nil then appPrint(preceder .. 'appResume', true) end
    if appPlaySound == nil then appPrint(preceder .. 'appPlaySound', true) end

    if misc.getIf == nil then appPrint(preceder .. 'misc.getIf', true) end
    if misc.getIsoDate == nil then appPrint(preceder .. 'misc.getIsoDate', true) end
    if misc.isNumber == nil then appPrint(preceder .. 'misc.isNumber', true) end
    if misc.getDifferenceBetweenDatesInDays == nil then appPrint(preceder .. 'misc.getDifferenceBetweenDatesInDays', true) end
    if misc.getRandomString == nil then appPrint(preceder .. 'misc.getRandomString', true) end
    if misc.split == nil then appPrint(preceder .. 'misc.split', true) end
    if misc.inArray == nil then appPrint(preceder .. 'misc.inArray', true) end
    if misc.toName == nil then appPrint(preceder .. 'misc.toName', true) end
    if misc.join == nil then appPrint(preceder .. 'misc.join', true) end
    if misc.getWrappedTextArray == nil then appPrint(preceder .. 'misc.getWrappedTextArray', true) end
    if misc.toInt == nil then appPrint(preceder .. 'misc.toInt', true) end
end

return self
end