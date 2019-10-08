module(..., package.seeall)

function getMap(willBeMirrored)
    local map = appInitMap()

    local ticketsMax = 15
    local ticket = math.random(1, ticketsMax)
    local illegalTicketsForMirroredMaps = {16, 10}

    if willBeMirrored then
        while misc.inArray(illegalTicketsForMirroredMaps, ticket) do
            ticket = math.random(1, ticketsMax)
        end
    end

    if ticket == 1 then map = specialRooms.getBridgeOfDeath(map)
    elseif ticket == 2 then map = specialRooms.getBridgeOfDeathOneWay(map)
    elseif ticket == 3 then map = specialRooms.getBridgeOfDeathHardJump(map)
    elseif ticket == 4 then map = specialRooms.getConfrontedByASpikeball(map)
    elseif ticket == 5 then map = specialRooms.getFollowedByASpikeball(map)
    elseif ticket == 6 then map = specialRooms.getTowerOfDanger(map)
    elseif ticket == 7 then map = specialRooms.getUnstableDeathValley(map)
    elseif ticket == 8 then map = specialRooms.getFallingSpikeball(map)
    elseif ticket == 9 then map = specialRooms.getDangerJumpTower(map)
    elseif ticket == 10 then map = specialRooms.getUpAndDown(map)
    elseif ticket == 11 then map = specialRooms.getBlocksValley(map)
    elseif ticket == 12 then map = specialRooms.getWrongRouteKills(map)
    elseif ticket == 13 then map = specialRooms.getGreenOpensDoors(map)
    elseif ticket == 14 then map = specialRooms.getWrongButtonKills(map)
    elseif ticket == 15 then map = specialRooms.getLastMinuteSpikeballDecision(map)
    end

    return map
end

function getBridgeOfDeath(map)
    map[1][2].hasGirl = true

    for x = app.mapMinX, app.mapMaxX do
        map[x][app.mapMinY].item = 'bladeTop'
        map[x][app.mapMaxY].item = 'bladeBottom'
    end

    map[app.mapMinX][2].hasFloor = true
    map[app.mapMaxX][2].hasFloor = true

    return map
end

function getBridgeOfDeathOneWay(map)
    map[1][2].hasGirl = true

    for x = app.mapMinX, app.mapMaxX do
        map[x][app.mapMinY].item = 'bladeTop'
        map[x][app.mapMaxY].item = 'bladeBottom'
    end

    for y = app.mapMinY, app.mapMaxY do
        map[app.mapMaxX][y].hasWallRight = true
    end

    map[1][2].hasFloor = true
    map[2][2].hasFloor = true

    return map
end

function getBridgeOfDeathHardJump(map)
    map[1][2].hasGirl = true

    for x = 1, app.mapMaxX - 1 do map[x][app.mapMinY].item = 'bladeTop' end
    for x = 1, app.mapMaxX do map[x][app.mapMaxY].item = 'bladeBottom' end

    map[1][1].hasWallLeft = true
    map[1][3].hasWallLeft = true
    map[app.mapMaxX][2].hasWallRight = true
    map[app.mapMaxX][3].hasWallRight = true
    map[app.mapMaxX][1].hasFloor = true

    map[1][1].hasFloor = true
    map[1][2].hasFloor = true
    map[2][2].hasFloor = true

    map[1][2].item = 'fallBlade'
    map[1][2].hasGirl = true

    return map
end

function getConfrontedByASpikeball(map)
    map[1][1].hasGirl = true
    map[1][1].hasFloor = true

    map[3][1].hasFloor = true
    map[4][1].hasFloor = true

    map[2][2].hasFloor = true
    map[3][2].hasFloor = true
    map[4][2].hasFloor = true

    map[4][1].hasWallRight = true
    map[4][2].hasWallRight = true
    map[4][3].hasWallRight = true

    map[1][2].hasWallLeft = true
    map[1][3].hasWallLeft = true

    map[4][1].item = 'spikeball'

    for x = 1, app.mapMaxX do
        for y = 2, app.mapMaxY do
            if map[x][y - 1].hasFloor then map[x][y].item = 'bladeTop' end
        end
    end

    map[3][1].item = 'bladeTop'

    return map
end

function getFollowedByASpikeball(map)
    map[1][1].hasGirl = true

    for x = 1, app.mapMaxX do
        for y = 1, app.mapMaxY do
            map[x][y].hasFloor = true
        end
    end

    map[4][1].item = {'spikeball-fast', 'guard'}

    map[1][2].hasWallRight = true

    map[4][2].hasWallRight = true
    map[4][3].hasWallRight = true

    map[3][3].item = 'fallBlade'

    map[3][1].hasFloor = false
    map[4][2].hasFloor = false
    map[1][2].hasFloor = false

    map[1][3].item = 'bladeBottom'

    return map
end

function getTowerOfDanger(map)
    map[1][3].hasGirl = true

    map[2][1].item = 'bladeTop'
    map[3][1].item = 'bladeTop'

    map[2][3].item = 'highTableWithVasesAndBladeBlocks'

    return map
end

function getUnstableDeathValley(map)
    map[1][2].hasGirl = true
    for x = 1, app.mapMaxX do
        map[x][1].hasFloor = true

        map[x][3].item = {'bladeBottom', 'tableHighLong'}
        map[x][2].item = {'bladeTop'}
    end

    return map
end

function getFallingSpikeball(map)
    map[1][3].hasGirl = true

    map[4][1].item = {'spikeball'}
    map[1][1].item = {'spikeball-slow'}

    return map
end

function getDangerJumpTower(map)
    map[1][3].hasGirl = true

    map[4][3].item = 'stackedBladeBlocksWithVase'

    return map
end

function getUpAndDown(map)
    map[1][3].hasGirl = true
    map[1][3].item = 'fallBlade'

    map[1][2].hasFloor = true
    map[4][2].hasFloor = true

    map[1][2].hasWallLeft = true

    map[1][1].hasFloor = true
    map[2][1].hasFloor = true
    map[3][1].hasFloor = true
    map[4][1].hasFloor = true
    map[4][2].hasWallRight = true

    map[4][3].hasWallRight = true

    map[4][3].item = {'spikeball', 'doorButtonOpen'}

    return map
end

function getBlocksValley(map)
    map[1][1].hasGirl = true

    map[1][3].item = 'bladeBottom'
    map[2][3].hasBlock = true
    map[3][3].item = 'bladeBottom'
    map[4][3].hasBlock = true

    map[2][1].hasFloor = true
    map[3][1].hasFloor = true
    map[4][1].hasFloor = true

    map[2][2].item = 'bladeTop'
    map[4][2].item = 'bladeTop'

    map[3][1].item = 'fallBlade'
    map[4][1].hasWallRight = true

    return map
end

function getWrongRouteKills(map)
    map[1][1].hasGirl = true

    map[1][1].hasFloor = true
    map[4][1].hasFloor = true

    map[1][2].hasFloor = true
    map[4][2].hasFloor = true

    map[1][1].item = 'fallBlade'

    map[1][3].item = 'guard'

    map[4][1].item = 'guard'

    map[1][2].item = 'guard'

    map[4][2].item = 'guard'

    map[4][3].item = 'guard'

    local escapeY = math.random(1, app.mapMaxY)
    map[4][escapeY].item = nil

    return map
end

function getGreenOpensDoors(map)
    map[1][1].hasGirl = true
    map[1][1].item = 'fallDoor'

    for x = 1, app.mapMaxX, app.mapMaxX - 1 do
        for y = 1, app.mapMaxY do
            map[x][y].hasFloor = true

            if map[x][y].hasGirl then map[x][y].item = {'fallDoorLeft', 'doorButtonClose'}
            elseif x == 1 then map[x][y].item = {'fallDoorLeft', 'doorButtonClose'}
            elseif x == app.mapMaxX then map[x][y].item = {'fallDoorRight', 'doorButtonClose'}
            end
        end
    end

    local didPutButtonOpen = false
    while not didPutButtonOpen do
        local x = misc.getIfChance(nil, 1, app.mapMaxX)
        local y = math.random(1, app.mapMaxY)
        if not map[x][y].hasGirl then
            if x == 1 then map[x][y].item = {'fallDoorLeft', 'doorButtonOpen'}
            elseif x == app.mapMaxX then map[x][y].item = {'fallDoorRight', 'doorButtonOpen'}
            end
            didPutButtonOpen = true
        end
    end

    return map
end

function getWrongButtonKills(map)
    map[1][2].hasGirl = true
    map[1][1].hasFloor = true
    map[1][2].hasFloor = true
    map[1][2].item = {'fallBladeLeft', 'doorButtonClose'}

    map[1][1].hasWallLeft = true
    map[1][3].hasWallLeft = true

    map[4][1].hasFloor = true
    map[4][2].hasFloor = true
    map[4][3].hasFloor = true

    local openY = math.random(1, app.mapMaxY)
    for y = 1, app.mapMaxY do
        map[4][y].item = { 'fallBladeRight', misc.getIf(openY == y, 'doorButtonOpen', 'doorButtonClose') }
    end

    return map
end

function getLastMinuteSpikeballDecision(map)
    for x = 1, app.mapMaxX do map[x][1].hasFloor = true end
    map[3][2].hasFloor = true
    map[4][2].hasFloor = true

    map[1][2].hasGirl = true
    map[1][2].hasFloor = true

    map[1][2].item = 'fallBlade'
    map[1][3].item = 'fallBlade'

    map[3][2].item = 'bladeTop'
    map[3][3].item = 'bladeTop'

    local spikeballs = misc.shuffleArray( {'spikeball-slow', 'spikeball-fast'} )
    map[app.mapMaxX][2].item = {spikeballs[1], 'bladeTop'}
    map[app.mapMaxX][3].item = {spikeballs[2], 'bladeTop'}

    return map
end