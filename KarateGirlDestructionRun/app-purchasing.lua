function appInitPurchases()
    if #app.products >= 1 then

        local foundUnpurchasedProducts = false
        for i = 1, #app.products do
            if appGetProductIsPurchasedPerDB(app.products[i].id) then
                app.products[i].isPurchased = true
            else
                foundUnpurchasedProducts = true
            end
        end

        if foundUnpurchasedProducts then
            if store.availableStores.apple then store.init(appStoreCallback)
            else store.init('google', appStoreCallback)
            end
        end
    end
end

function appStartPurchase()
    if store.canMakePurchases then
        store.purchase( {app.products[1].id} )
        appSetIsBusy(true)
    else
        appShowPurchasingDisabledDialog()
        if app.runs then app.phase:set('startBattle')
        else app.menu:createPageMain()
        end
    end
end

function appRemoveSpritesAfterPurchaseStarted()
    appRemoveSprites()
end

function appStartPurchaseRestore()
    if store.availableStores.apple then
        if store.canMakePurchases then
            appSetIsBusy(true)
            store.restore()
        else
            appShowPurchasingDisabledDialog()
            if app.runs then app.phase:set('startBattle')
            else app.menu:createPageMain()
            end
        end

    else
        appStartPurchase()

    end
end

function appSetIsBusy(isBusy)
    -- native.setActivityIndicator(doShow) -- currently disabled due to issues
end

function appShowPurchasingDisabledDialog()
    native.showAlert( 'Purchasing disabled',
            'Purchasing has been disabled in your device settings. Please enable and restart ' .. app.title .. ' to purchase.', { 'OK' } )
end

function appGetProductIsPurchasedPerDB(productId)
    return app.data:getBool('purchased_' .. productId, false)
end

function appSavePurchaseInDB(productId)
    if productId ~= nil and not appGetProductIsPurchasedPerDB(productId) then
        app.data:setBool('purchased_' .. productId, true)
    end
end

function appStoreCallback(event)
    local transaction = misc.getIf(event ~= nil, event.transaction, nil)
    local state = misc.getIf(transaction ~= nil, transaction.state, nil)

    if state == 'purchased' or state == 'restored' then
        if app.products[1].id == transaction.productIdentifier or app.products[1].id == transaction.originalIdentifier or app.products[1].id == transaction.originalTransactionIdentifier then
            app.products[1].isPurchased = true
            --- appSavePurchaseInDB(app.products[1].id)
            app.diamondsOwned = app.diamondsOwned + app.diamondsInPack
            appSaveData()
            native.showAlert( '', 'Congratulations, you now own ' .. misc.addCommasToNumber(app.diamondsOwned) .. ' diamonds!', {'OK'} )
            app.menu.createPageChangeClothes()
        else
            native.showAlert( 'Transaction issue',
                    'Could not match ' .. tostring(app.products[1].id) .. ' with identifier ' .. tostring(transaction.productIdentifier), {'OK'} )
        end

    elseif state == 'cancelled' then
        native.showAlert( 'Transaction cancelled', 'You cancelled the transaction.', {'OK'} )

    elseif state == 'failed' then
        local errorMessage = transaction.errorString
        if errorMessage == 'unknown' or errorMessage == nil or errorMessage == '' then errorMessage = transaction.errorType end
        if errorMessage == 'unknown' or errorMessage == nil or errorMessage == '' then errorMessage = 'An unknown error occurred.' end
        native.showAlert( 'Transaction failed', tostring(errorMessage), {'OK'} )

    else
        native.showAlert( 'Transaction issue', 'Unknown transaction state', {'OK'} )
    end

    app.menu:createPageMain()

    appSetIsBusy(false)
    if transaction ~= nil then store.finishTransaction(transaction) end
end

function appLoadProductsCallback(event)
    if event ~= nil and event.products ~= nil then
        local price = nil
        for i = 1, #event.products do
            if event.products[i].productIdentifier == app.products[1].id then
                price = event.products[i].localizedPrice
                if price == nil or price == '' then price = event.products[i].price end
                break
            end
        end

        local priceText = appGetSpriteByType('buttonPart', 'price')
        if price ~= nil and priceText ~= nil then
            priceText.text = price
            app.diamondsPackPriceCached = price
        end
    end
end

function appPrefixProductId(productId)
    if productId ~= nil and productId ~= '' then
        productId = app.productIdPrefix .. appRemovePrefixFromProductId(productId)
    end
    return productId
end

function appRemovePrefixFromProductId(productId)
    if productId ~= nil then
        local pattern = string.gsub(app.productIdPrefix, '%.', '%%.')
        productId = string.gsub(productId, pattern, '')
    end
    return productId
end
