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
            if store.availableStores.apple then
                store.init(appStoreCallback)
                appInitPrices()
            else
                store.init('google', appStoreCallback)
            end
        end
    end
end

function appInitPrices()
    local ids = {}
    for i = 1, #app.products do ids[#ids + 1] = app.products[i].id end
    store.loadProducts(ids, appLoadProductsCallback)
end

function appStartPurchase(id)
    if store.canMakePurchases then
        store.purchase( {id} )
        appSetIsBusy(true)
    else
        appShowPurchasingDisabledDialog()
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
        end

    else
        appStartPurchase()
    end
end

function appSetIsBusy(isBusy)
    -- native.setActivityIndicator(doShow) -- currently disabled due to issues
end

function appShowPurchasingDisabledDialog()
    appAlert('Purchasing has been disabled in your device settings. Please enable and restart ' .. app.title .. ' to purchase.')
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
        local somethingFound = false
        for i = 1, #app.products do
            local product = app.products[i]
            local id = product.id
            if id == transaction.productIdentifier or id == transaction.originalIdentifier or id == transaction.originalTransactionIdentifier then
                if not appGetProductIsPurchasedPerDB(id) then
                    product.isPurchased = true
                    appSavePurchaseInDB(id)
                    appTrySelectPurchasedRoutesPack(product.number)

                    if state == 'purchased' then
                        appAlert( 'Congratulations, you now own a new routes pack!' )
                    elseif state == 'restored' then
                        appAlert( 'Successfully restored your route packs!' )
                    end
                    appPlaySound('success')
                end
                somethingFound = true
            end
        end

        if not somethingFound then
            if state == 'restored' then
                appAlert('No past route packs found to restore.')
            else
                appAlert( 'Could not match any product with identifier ' .. tostring(transaction.productIdentifier) )
            end
        end

    elseif state == 'cancelled' then
        appAlert('You cancelled the transaction.')

    elseif state == 'failed' then
        local errorMessage = transaction.errorString
        if errorMessage == 'unknown' or errorMessage == nil or errorMessage == '' then errorMessage = transaction.errorType end
        if errorMessage == 'unknown' or errorMessage == nil or errorMessage == '' then errorMessage = 'An unknown error occurred.' end
        appAlert( tostring(errorMessage) )

    else
        appAlert('Unknown transaction state')
    end

    appSetIsBusy(false)
    if transaction ~= nil then store.finishTransaction(transaction) end
end

function appLoadProductsCallback(event)
    if event ~= nil and event.products ~= nil then
        for i = 1, #event.products do
            local productI = appGetProductIndexById(event.products[i].productIdentifier)
            if productI then
                if event.products[i].productIdentifier == app.products[productI].id then
                    local price = event.products[i].localizedPrice
                    if price == nil or price == '' then price = event.products[i].price end
                    app.products[productI].price = price
                end
            end
        end
    end
end

function appGetProductIndexById(id)
    local productIndex = nil
    for i = 1, #app.products do
        if id == app.products[i].id then
            productIndex = i
            break
        end
    end
    return productIndex
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

function appAlert(s)
    native.showAlert( '', s, {'OK'} )
    display.getCurrentStage():setFocus(nil)
end
