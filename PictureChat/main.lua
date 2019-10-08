misc = require('misc')
dataModule = require('data-class')
store = require('store')
spriteModule = require('sprite-class')
spritesheetModule = require('sprite')
spritesHandlerModule = require('sprites-handler')
language = require('language-data')
phaseModule = require('phase-class')
menuModule = require('menu-class')
newsModule = require('news-class')
require('app-misc')
require('app-data')
require('sqlite3')

app = {}

function init()
    misc.initDefaults(false)
    appClass()
    appClearConsole()
    appDefineTranslatedImages()
    appInitSound()
    appInitPictogramTypes()
    appCreateSprites()
    app.news:verifyNeededFunctionsAndVariablesExists()

    app.data:open()

    appSwitchToPictogramCategory(app.defaultCategory)
    appRefreshSpeechDisplay()
    Runtime:addEventListener('enterFrame', appHandleAll)
    appPlaySound( misc.getIf(app.isAndroid, 'intro.mp3', 'intro.m4a') )

    app.news:handle()
end

function appPause()
    if app.runs then
        appStopAllSounds()
        app.runs = false
    end
end

function appResume()
    if not app.runs then
        appStopAllSounds()
        appRemoveSpritesByGroup('menu')
        app.runs = true
    end
end

function appKeyboardTextEntered(event)
    if event.phase == 'submitted' then
        -- native.showAlert( 'You entered', tostring(app.keyboardText.text), {'OK'} )
        appPlaySound('click')
        appAddPictogramToSpeech(1)
        appSpeechSayIt()
        appSwitchToProgramCategory(app.defaultCategory)
        native.setKeyboardFocus(nil)
    end
end

function appCreateSprites()
    app.spritesHandler:createBackground()
    for i = 1, #app.speakers do app.spritesHandler:createAvatar(i) end
    app.spritesHandler:createTabsLow()
    app.spritesHandler:createButton(appSpeechDeleteIt, 'delete', 981, 478, 86, 55)
    app.spritesHandler:createButton(appSpeechSayIt, 'sayIt', 983, 714, 102, 145)
    app.menu:createButtons()
    app.spritesHandler:createMessageImage('intro', app.maxXHalf, app.maxYHalf - 120, 536, 199, 2, 2, true, true)
    appIncludeLetterboxBars(false, 199)
end

function appSwitchToPictogramCategory(category)
    if category ~= nil then
        app.negationIsOn = false
        app.currentCategory = category
        app.spritesHandler:createTabHi(app.currentCategory)
        appLoadPictogramButtonsOfCategory()
    end
end

function appLoadPictogramButtonsOfCategory(page)
    if page == nil then page = 1 end
    if app.currentCategoryPage ~= page then app.negationIsOn = false end
    app.currentCategoryPage = page

    appRemoveSpritesByType( {'pictogramButton', 'negateButton', 'messageLettersOnly'} )

    if app.currentCategory == 'letters' and not app.lettersEnabled then
        app.spritesHandler:createLettersOnlyMessage()
        appRemoveSpritesByType('moreButton')
    else
        appDoLoadPictogramButtonsOfCategory(page)
    end
end

function appKeepUsingPictures()
    appSwitchToPictogramCategory(app.defaultCategory)
end

function appEnableLetters()
    app.lettersEnabled = true
    appRefreshPictogramButtons()
end

function appShowKeyboard()
    appCreateKeyboardTextIfNeeded()
    native.setKeyboardFocus(app.keyboardText)
end

function appCreateKeyboardTextIfNeeded()
    if app.keyboardText == nil then
        app.keyboardText = native.newTextField(20, 20, 300, 100, appKeyboardTextEntered)
        app.keyboardText.font = native.newFont(native.systemFontBold, 34)
        app.keyboardText:setTextColor(0, 0, 0, 255)
    end
end

function appDoLoadPictogramButtonsOfCategory(page)
    local selectablePictogramI = 1

    local marginX = 14
    local marginY = 2
    local minX = 15
    local minY = 452
    local maxX = 622
    local maxY = 665 -- 685
    local x = minX
    local y = minY
    local width = app.pictogramWidth
    local height = app.pictogramHeight
    local scale = nil
    local needsMoreButton = {left = false, right = false}

    local indexes = appGetPictogramIndexesOfCategory(app.currentCategory)
    if misc.inArray(app.categoriesWithSmallerPictograms, app.currentCategory) then
        scale = app.pictogramSmallerScale
        width = width * scale
        height = height * scale
    else
        app.spritesHandler:createButton(appToggleNegate, 'negate', 48, 729, 68, 47)
    end

    local thisPage = 1
    local i = 0
    local row = 1

    for i = 1, #indexes do
        if x + width > maxX then
            y = y + height + marginY
            x = minX
            if y > maxY then
                y = minY
                if page == thisPage and i <= #indexes then needsMoreButton.right = true end
                thisPage = thisPage + 1
            end
        end

        if page == thisPage then
            app.spritesHandler:createPictogram(indexes[i], app.negationIsOn, x + width / 2, y + height / 2, 'pictogramButton', scale)
        end

        x = x + width + marginX
        selectablePictogramI = selectablePictogramI + 1
    end

    needsMoreButton.left = page > 1

    local directions = {'left', 'right'}
    for i = 1, #directions do
        local direction = directions[i]
        if needsMoreButton[direction] then
            local button = appGetSpriteByType('moreButton', direction)
            if button == nil then app.spritesHandler:createCategoryMoreButton(direction)
            else button:toFront()
            end
        else
            appRemoveSpritesByType('moreButton', direction)
        end
    end
end

function appCreatePermanentStickyPictogramButtons()
    local minY = 460
    local x = app.stickyAreaMinX
    local y = 457
    local marginY = 2
    local width = app.pictogramWidth * app.pictogramSmallerScale
    local height = app.pictogramHeight * app.pictogramSmallerScale

    appRemoveSpritesByType('pictogramButtonPermanentSticky')
    local categoryOrder = {'letters'}
    for categoryOrderI = 1, #categoryOrder + 1 do
        for i = 1, #app.pictogramTypes do
            local pictogramType = app.pictogramTypes[i]
            if pictogramType.isPermanentSticky then
                local pictogramType = app.pictogramTypes[i]
                local isThisCategory = pictogramType.category == categoryOrder[categoryOrderI]
                if isThisCategory or (categoryOrderI == #categoryOrder + 1 and not misc.inArray(categoryOrder, pictogramType.category) ) then
                    app.spritesHandler:createPictogram(i, app.negationIsOn, x + width / 2, y + width / 2, 'pictogramButtonPermanentSticky', app.pictogramSmallerScale)

                    x = x + width
                    if x + width > app.stickyAreaMaxX then
                        x = app.stickyAreaMinX
                        y = y + height + marginY
                    end
                end
            end
        end
    end
end

function appRefreshTemporaryStickyPictogramButtons()
    local stickyPictograms = {}
    local x = app.stickyAreaMinX
    local y = 695
    local marginY = 2
    local width = app.pictogramWidth * app.pictogramSmallerScale
    local height = app.pictogramHeight * app.pictogramSmallerScale

    local stickyPictograms = getPopularPictogramIndexes(6)

    -- if not misc.tableValuesAreSame(app.currentStickyPictograms, stickyPictograms) then
        appRemoveSpritesByType('pictogramButtonTemporarySticky')
        for i = 1, #stickyPictograms do
            local pictogramIndex = stickyPictograms[i]
            local pictogramType = app.pictogramTypes[pictogramIndex]
            if not pictogramType.isPermanentSticky then
                app.spritesHandler:createPictogram(stickyPictograms[i], app.negationIsOn, x + width / 2, y + width / 2, 'pictogramButtonTemporarySticky', app.pictogramSmallerScale)
    
                x = x + width
                if x + width > app.stickyAreaMaxX then
                    x = app.stickyAreaMinX
                    y = y + height + marginY
                end
            end
        end
    -- end

    app.currentStickyPictograms = stickyPictograms
    appPutMessagesToFront()
end

function appRefreshPermanentStickyPictogramButtons()
    appCreatePermanentStickyPictogramButtons()
    appPutMessagesToFront()
end

function appPutMessagesToFront()
    local sprites = appGetSpritesByType('message')
    for i = 1, #sprites do
        sprites[i]:toFront()
    end
end

function getPopularPictogramIndexes(max)
    local indexes = {}
    local typesPopularity = {}

    for pictogramIndex = 1, #app.pictogramTypes do
        typesPopularity[pictogramIndex] = 0
    end

    local highestPopularity = nil
    for i = 1, #app.speech do
        local n = app.speech[i].pictogramIndex
        local pictogramType = app.pictogramTypes[n]
        if not pictogramType.isPermanentSticky and pictogramType.category ~= 'letters' then
            typesPopularity[n] = typesPopularity[n] + i
            if highestPopularity == nil or typesPopularity[n] > highestPopularity then
                highestPopularity = typesPopularity[n]
            end
        end
    end

    if highestPopularity ~= nil and highestPopularity ~= 0 then
        for popularity = highestPopularity, 1, -1 do
            for n = 1, #typesPopularity do
                if typesPopularity[n] == popularity then
                    indexes[#indexes + 1] = n
                end
            end
        end
    end

    while #indexes > max do table.remove(indexes) end

    return indexes
end

function appToggleNegate()
    app.negationIsOn = not app.negationIsOn
    appRefreshPictogramButtons()
    appRefreshPermanentStickyPictogramButtons()
    appRefreshTemporaryStickyPictogramButtons()
end

function appGetPictogramIndexesOfCategory(category)
    local indexes = {}
    for i = 1, #app.pictogramTypes do
        if app.pictogramTypes[i].category == category then indexes[#indexes + 1] = i end
    end
    return indexes
end

function appAddPictogramType(name, category, params)
    local shortcuts = {
            personal = 'personal-pronouns-relations-and-body-parts',
            shapes = 'shapes-and-symbols',
            emoticons = 'emoticons-and-gestures',
            location = 'location-transport-travel-animal-and-nature'
            }
    if shortcuts[category] ~= nil then category = shortcuts[category] end

    if not appGetPictogramExists(name, category) then
        local i = #app.pictogramTypes + 1
        app.pictogramTypes[i] = {name = name, category = category, width = width, height = height}
        if params ~= nil then
            app.pictogramTypes[i].isPermanentSticky = misc.getIf(params.isPermanentSticky == nil, false, params.isPermanentSticky)
            app.pictogramTypes[i].hasAlternateForWriting = misc.getIf(params.hasAlternateForWriting == nil, false, params.hasAlternateForWriting)
            app.pictogramTypes[i].isSentenceEnd = misc.getIf(params.isSentenceEnd == nil, false, params.isSentenceEnd)
            app.pictogramTypes[i].isEmoticon = misc.getIf(params.isEmoticon == nil, false, params.isEmoticon)
            app.pictogramTypes[i].isPersonalPronoun = misc.getIf(params.isPersonalPronoun == nil, false, params.isPersonalPronoun)
            app.pictogramTypes[i].isConnector = misc.getIf(params.isConnector == nil, false, params.isConnector)
        end
    else
        appPrint('Skipped adding ' .. name .. ', ' .. category .. ' pictogramType as it already exists')
    end
end

function appGetPictogramExists(name, category)
    local exists = false
    for i = 1, #app.pictogramTypes do
        exists = app.pictogramTypes[i].name == name and app.pictogramTypes[i].category == category
        if exists then break end
    end
    return exists
end

function appSpeechSayIt()
    app.currentSpeaker = misc.getIf(app.currentSpeaker == 1, 2, 1)
    app.negationIsOn = false
    appRefreshSpeechDisplay()
    appRefreshPictogramButtons()
end

function appAddPictogramToSpeech(index, optionalDoNegate)
    appClearOldLogIfNeeded()
    local negate = app.negationIsOn or (optionalDoNegate ~= nil and optionalDoNegate)
    app.speech[#app.speech + 1] = {pictogramIndex = index, speaker = app.currentSpeaker, isNegated = negate }
    appRefreshSpeechDisplay()
    if app.negationIsOn then
        app.negationIsOn = false
        appRefreshPictogramButtons()
        appRefreshPermanentStickyPictogramButtons()
        appRefreshTemporaryStickyPictogramButtons()
    end
end

function appClearOldLogIfNeeded()
    local maxLogCount = 50
    if #app.speech > maxLogCount then
        for i = 1, maxLogCount / 2 do
            table.remove(app.speech, 1)
        end
    end
end

function appRefreshPictogramButtons()
    appLoadPictogramButtonsOfCategory(app.currentCategoryPage)
    appPutMessagesToFront()
end

function appSpeechDeleteIt()
    if app.speech[#app.speech] and app.speech[#app.speech].speaker == app.currentSpeaker then
        table.remove(app.speech)
        appRefreshSpeechDisplay()
        appRefreshPictogramButtons()
    end
end

function appRefreshSpeechDisplay()
    appRemoveSpritesByType( {'pictogramWriting', 'speechBubble'} )

    local speechClone = misc.cloneTable(app.speech)
    speechClone[#speechClone + 1] = {pictogramIndex = app.textCursorIndex, speaker = app.currentSpeaker, isNegated = false}
    local maxRows = 3
    local parts = appGetSpeechAsSpeakerParts(speechClone, maxRows)
    local rowSpeaker = {}
    for i = 1, maxRows do rowSpeaker[i] = nil end

    for partI = 1, #parts do
        local part = parts[partI]
        local n = part[1]
        rowSpeaker[partI] = speechClone[n].speaker
    end

    if (rowSpeaker[1] ~= nil and rowSpeaker[1] == rowSpeaker[2]) and (rowSpeaker[2] ~= nil and rowSpeaker[2] == rowSpeaker[3]) then
        app.spritesHandler:createSpeechBubble(rowSpeaker[1], 1, 3)
    elseif (rowSpeaker[1] ~= nil and rowSpeaker[1] == rowSpeaker[2]) and rowSpeaker[2] ~= rowSpeaker[3] then
        app.spritesHandler:createSpeechBubble(rowSpeaker[1], 1, 2)
        app.spritesHandler:createSpeechBubble(rowSpeaker[3], 3)
    elseif rowSpeaker[1] ~= rowSpeaker[2] and (rowSpeaker[2] ~= nil and rowSpeaker[2] == rowSpeaker[3]) then
        app.spritesHandler:createSpeechBubble(rowSpeaker[1], 1)
        app.spritesHandler:createSpeechBubble(rowSpeaker[2], 2, 2)
    else
        for i = 1, #rowSpeaker do
            app.spritesHandler:createSpeechBubble(rowSpeaker[i], i)
        end
    end

    for partI = 1, #parts do
        local part = parts[partI]
        local ys = {64, 192, 317}
        local y = ys[partI]

        local widthSum = 0
        local indexTrue = 1
        local indexFalse = 2
        for widthCalculationRun = indexTrue, indexFalse do
            local x = nil
            if widthCalculationRun == indexFalse then
                x = app.maxXHalf - (widthSum / 2)
            end
            for pictogramIndexesI = 1, #part do
                local speech = speechClone[ part[pictogramIndexesI] ]
    
                local category = app.pictogramTypes[speech.pictogramIndex].category
                local width = app.pictogramWidth
                local scale = nil
                if misc.inArray(app.categoriesWithSmallerPictograms, category) then
                    scale = app.pictogramSmallerScale
                    width = width * scale
                end
    
                if widthCalculationRun == indexFalse then
                    app.spritesHandler:createPictogram(speech.pictogramIndex, speech.isNegated, x + width / 2, y, 'pictogramWriting', scale)
                    x = x + width
                end

                if widthCalculationRun == indexTrue then
                    widthSum = widthSum + width
                end
            end
        end
    end

    appRefreshPermanentStickyPictogramButtons()
    appRefreshTemporaryStickyPictogramButtons()
end

function appGetSpeechAsSpeakerParts(speech, restrictToNewestN)
    local parts = {}
    local activeSpeaker = nil
    local speechBubbleInnerWidth = 490

    local widthSum = 0
    for i = 1, #speech do
        if activeSpeaker == nil or activeSpeaker ~= speech[i].speaker then
            activeSpeaker = speech[i].speaker
            parts[#parts + 1] = {}
            widthSum = 0
        else
            local width = app.pictogramWidth
            local category = app.pictogramTypes[ speech[i].pictogramIndex ].category
            if misc.inArray(app.categoriesWithSmallerPictograms, category) then
                width = width * app.pictogramSmallerScale
            end
    
            widthSum = widthSum + width
            if widthSum > speechBubbleInnerWidth then
                parts[#parts + 1] = {}
                widthSum = 0
            end

        end

        local part = parts[#parts]
        part[#part + 1] = i
    end

    if restrictToNewestN ~= nil then
        while #parts > restrictToNewestN do table.remove(parts, 1) end
    end
    return parts
end

function appGetRobotPictogramsToSpeak(speaker)
    -- xxx
    local robotSpeech = {}
    if speaker == app.currentSpeaker then
        local speechByOther = getLastSpeechByOther()
        local maxWords = math.random(4, 6)
        local copyWordFromOtherPosition = nil
        if misc.getChance(70) and #speechByOther >= 1 then
            copyWordFromOtherPosition = math.random(1, maxWords)
        end
        local lastWordIsEmoticon = misc.getChance(50)
        local firstWordIsPersonalPronoun = misc.getChance(40)

        for i = 1, maxWords do
            local pictogramIndex = nil; local isNegated = false

            if i == copyWordFromOtherPosition then
                local r = math.random(1, #speechByOther)
                local candidatePictogramIndex = speechByOther[r].pictogramIndex
                local pictogram = app.pictogramTypes[candidatePictogramIndex]
                if pictogram.category ~= 'letters' then
                    pictogramIndex = candidatePictogramIndex
                    if misc.getChance(70) then isNegated = speechByOther[r].isNegated end
                end
            elseif i == 1 and firstWordIsPersonalPronoun then
                pictogramIndex = appGetRandomPictogramIndexByProperty('isPersonalPronoun')
            elseif ( (lastWordIsEmoticon and i == maxWords - 1) or (not lastWordIsEmoticon and i == maxWords) ) and maxWords >= 3 and misc.getChance(80) then
                pictogramIndex = appGetRandomPictogramIndexByProperty('isSentenceEnd')
            elseif lastWordIsEmoticon and i == maxWords then
                pictogramIndex = appGetRandomPictogramIndexByProperty('isEmoticon')
            elseif i > 1 and i < maxWords - 1 and misc.getChance(10) then
                pictogramIndex = appGetRandomPictogramIndexByProperty('isConnector')
            end

            if pictogramIndex == nil then
                pictogramIndex = appGetRandomPictogramIndex( nil, {'letters'} )
                if not isNegated then isNegated = misc.getChance(10) end
            end

            robotSpeech[i] = {pictogramIndex = pictogramIndex, isNegated = isNegated}
        end
    end
    return robotSpeech
end

function appGetRandomPictogramIndexByProperty(propertyName)
    local indexCandidates = {}
    for i = 1, #app.pictogramTypes do
        if app.pictogramTypes[i][propertyName] then indexCandidates[#indexCandidates + 1] = i end
    end
    return misc.getRandomEntry(indexCandidates)
end

function appGetRandomPictogramIndex(optionalCategoryWhitelist, optionalCategoryBlacklist)
    local index = nil
    local triesCounter = 0; local maxTries = 10000
    while index == nil do
        index = math.random(1, #app.pictogramTypes)
        local category = app.pictogramTypes[index].category
        
        if optionalCategoryWhitelist ~= nil and not misc.inArray(optionalCategoryWhitelist, category) then index = nil end
        if optionalCategoryBlacklist ~= nil and misc.inArray(optionalCategoryBlacklist, category) then index = nil end

        triesCounter = triesCounter + 1
        if triesCounter >= maxTries then index = 1 end
    end
    return index
end

function getLastSpeechByOther()
    local speechByOther = {}
    if #app.speech >= 1 then
        local otherSpeaker = misc.getIf(app.currentSpeaker == 1, 2, 1)
        local firstI = nil; local lastI = nil
        for i = #app.speech, 1, -1 do
            local speechPart = app.speech[i]
            if lastI == nil and speechPart.speaker == otherSpeaker then
                lastI = i
            elseif lastI ~= nil and firstI == nil and speechPart.speaker ~= otherSpeaker then
                firstI = i + 1
                break
            end
        end
    
        if firstI == nil then firstI = 1 end
        if lastI ~= nil then
            for i = firstI, lastI do
                speechByOther[#speechByOther + 1] = {pictogramIndex = app.speech[i].pictogramIndex, isNegated = app.speech[i].isNegated}
            end
        end    
    end

    return speechByOther
end

function appDefineTranslatedImages()
    app.translatedImages['zh'] = {
            {filename = 'news-dialog'},
            {filename = 'help'},
            {filename = 'letters-only-message'},
            {filename = 'message-intro'},
            {filename = 'message-robot-speaking'},
            {filename = 'button/delete'},
            {filename = 'button/enableLetters'},
            {filename = 'button/keepUsingPictures'},
            {filename = 'button/more-left'},
            {filename = 'button/more-right'},
            {filename = 'button/sayIt'}
            }
    app.translatedImages['de'] = {
            {filename = 'help'},
            {filename = 'letters-only-message'},
            {filename = 'message-intro'},
            {filename = 'message-robot-speaking'},
            {filename = 'button/delete'},
            {filename = 'button/enableLetters'},
            {filename = 'button/keepUsingPictures'},
            {filename = 'button/more-left'},
            {filename = 'button/more-right'},
            {filename = 'button/sayIt'}
            }
end

function appClass()
    app.title = 'Picture Chat'
    app.name = 'picturechat'
    app.version = '1.2'
    app.id = '444435683'
    app.runs = true
    app.language = appGetLanguage()

    app.showDebugInfo = false -- false
    app.isLocalTest = false -- false
    app.doPlaySounds = true -- true

    app.device = system.getInfo('model')
    app.isIOs = app.device == 'iPad' or app.device == 'iPhone'
    app.isAndroid = not app.isIOs
    app.deviceResolution = {width = nil, height = nil}
    appSetDeviceResolution()
    app.letterboxColor = { {red = 255, green = 255, blue = 255} }

    app.idInStore = 'com.versuspad.' .. appToPackageName(app.name)
    app.productIdPrefix = app.idInStore .. '.'
    -- app.products = { { id = appPrefixProductId('premium'), isPurchased = false } }

    app.showClock = false and app.showDebugInfo
    app.maxRotation = 360
    app.secondInMs = 1000

    app.importantSoundsToCache = {'click'}
    app.cachedSounds = {}
    app.musicChannel = 1
    app.debugCounter = 0

    app.translatedImages = {}

    app.minX = 0
    app.maxX = 1024
    app.minY = 0
    app.maxY = 768
    app.maxXHalf = math.floor(app.maxX / 2)
    app.maxYHalf = math.floor(app.maxY / 2)
    app.tabsX = {54, 149, 241, 327, 408, 490, 577, 665}

    app.sprites = {}
    app.defaultFont = native.systemFontBold
    app.pictogramWidth = 84
    app.pictogramHeight = app.pictogramWidth

    app.placeTypes = {}
    app.pictogramTypes = {}
    app.pictogramCategories = {'personal-pronouns-relations-and-body-parts', 'verbs', 'adjectives', 'emoticons-and-gestures',
            'things', 'location-transport-travel-animal-and-nature', 'shapes-and-symbols', 'letters'}
    app.categoriesWithSmallerPictograms = {'letters'}
    app.defaultCategory = 'personal-pronouns-relations-and-body-parts'
    app.currentCategory = nil
    app.lettersEnabled = false

    app.speech = {} -- {pictogramIndex = , speaker = , isNegated = ...}
    app.currentSpeaker = 1
    app.negationIsOn = false
    app.textCursorIndex = nil
    app.pictogramSmallerScale = .53
    app.stickyAreaMinX = 643
    app.stickyAreaMaxX = 918
    app.currentStickyPictograms = {}
    app.speakers = {}
    app.speakers[#app.speakers + 1] = {gender = 'male', isRobot = false}
    app.speakers[#app.speakers + 1] = {gender = 'female', isRobot = false} -- isRobot = false
    app.currentCategoryPage = nil

    app.menu = menuModule.menuClass()
    app.news = newsModule.newsClass()
    app.data = dataModule.dataClass()
    app.db = nil
    app.keyboardText = nil

    app.groupsToHandleEvenWhenPaused = {'menu', 'menuButton', 'news'}
    app.spritesHandler = spritesHandlerModule.spritesHandlerClass()

    app.newsDialog = nil
end

init()

