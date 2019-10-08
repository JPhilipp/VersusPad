module(..., package.seeall)

function initDefaults(includePhysics)
    if includePhysics == nil then includePhysics = true end
    -- if not app.isLocalTest then ...
    math.randomseed( os.time() )
    display.setStatusBar(display.HiddenStatusBar)
    if includePhysics then physics.start() end
    system.activate('multitouch')
end

function getIsoDate(date)
    if date == nil then date = os.date('*t') end
    local isoDate = date.year .. '-' .. misc.padWithZero(date.month) .. '-' .. misc.padWithZero(date.day)
    -- if false and app.isLocalTest then isoDate = '2011-01-01'; appPrint('Changing date to ' .. isoDate) end
    return isoDate
end

function getIsoDateTime(date)
    if date == nil then date = os.date('*t') end
    local isoDate =
            date.year .. '-' .. misc.padWithZero(date.month) .. '-' .. misc.padWithZero(date.day) .. ' ' ..
            misc.padWithZero(date.hour) .. ':' .. misc.padWithZero(date.min) .. ':' .. misc.padWithZero(date.sec)
    return isoDate
end

function addCommasToNumber(amount)
    local formatted = amount
    while true do  
        formatted, k = string.gsub( formatted, "^(-?%d+)(%d%d%d)", '%1,%2' )
        if (k == 0) then break end
    end
    return formatted
end

function filterArrayBySearch(array, query)
    local filteredArray = nil
    if array ~= nil and type(array) == 'table' then
        filteredArray = {}
        for i = 1, #array do
            if string.find(array[i], query) ~= nil then
                filteredArray[#filteredArray + 1] = array[i]
            end
        end
    end
    return filteredArray
end

function reverseArray(array)
    local reversedArray = nil
    if array ~= nil and type(array) == 'table' then
        reversedArray = {}
        local max = #array
        for i = 1, max do
            reversedArray[i] = array[max - (i - 1)]
        end
    end
    return reversedArray
end

function tableValuesAreSame(table1, table2)
    local areSame = true
    if #table1 ~= #table2 then
        areSame = false
    else
        for i = 1, #table1 do
            if table1[i] ~= table2[i] then
                areSame = false
                break
            end
        end
    end
    return areSame
end

function getArrayIndexByValue(array, v)
    local index = nil
    for i = 1, #array do
        if array[i] == v then
            index = i
            break
        end
    end
    return index
end

function removeSingleValueFromArray(array, value)
    for i = 1, #array do
        if array[i] == value then
            table.remove(array, i)
            break
        end
    end
    return array
end

function getArrayIndexById(array, id)
    local index = nil
    for i = 1, #array do
        if array[i].id ~= nil and array[i].id == id then
            index = i
            break
        end
    end
    return index
end

function getFileExtension(path, includeDot)
    -- only includeDot == true supported for now
    if includeDot == nil then includeDot = false end
    return string.match(path, '%....')
end

function removeFileExtension(path)
    return string.gsub(path, '%....', '') -- quick hack assumes 3-digit extensions
end

function stringStartsWith(s, startsWith)
    return string.sub( s, 1, string.len(startsWith) ) == startsWith
end

function roundToDigits(n, digits)
    if digits == nil then digits = 2 end
    local shift = 10 ^ digits
    return math.floor(n * shift + 0.5) / shift
end

function getType(v)
    -- useful for when variable 'type' is defined
    return type(v)
end

function getSubArrayCount(array)
    -- untested so far
    local subCount = 0
    for i = 1, #array do
        subCount = subCount + #array[i]
    end
    return subCount
end

function cloneTable(t)
    -- does table.copy() now work?

    if type(t) ~= 'table' then return t end
    local mt = getmetatable(t)
    local res = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then v = misc.cloneTable(v) end
        res[k] = v
    end
    setmetatable(res, mt)
    return res
end

function getRelativeRectangleFromAbsolute(rectAbs)
    local rectRel = {} 
    rectRel.width = rectAbs.x2 - rectAbs.x1
    rectRel.height = rectAbs.y2 - rectAbs.y1
    rectRel.x = rectAbs.x1 + rectRel.width / 2
    rectRel.y = rectAbs.y1 + rectRel.height / 2
    return rectRel
end

function pointIsInRectangle(point, rectangle)
    return point.x >= rectangle.x1 and point.x <= rectangle.x2 and point.y >= rectangle.y1 and point.y <= rectangle.y2
end

function getRectangleCenter(rect)
    local width = rect.x2 - rect.x1
    local height = rect.y2 - rect.y1
    local x = rect.x1 + width / 2
    local y = rect.y1 + height / 2
    return { x = math.floor(x), y = math.floor(y) }
end

function getRectangleCenterBottom(rect)
    local width = rect.x2 - rect.x1
    local x = rect.x1 + width / 2
    return { x = math.floor(x), y = rect.y2 }
end

function getRectangleCenterTop(rect)
    local width = rect.x2 - rect.x1
    local x = rect.x1 + width / 2
    return { x = math.floor(x), y = rect.y1 }
end

function growRectangle(rect, margin)
    return {x1 = rect.x1 - margin, y1 = rect.y1 - margin, x2 = rect.x2 + margin, y2 = rect.y2 + margin}
end

function getRandomPointInRectangle(rect)
    return { x = math.random(rect.x1, rect.x2), y = math.random(rect.y1, rect.y2) }
end

function clearNil(v)
    if v == nil then v = '' end
    return v
end

function getDirection(v)
    local direction = 0
    if v < 0 then direction = -1
    elseif v > 0 then direction = 1
    end
    return direction
end
    
function shuffleArray(array)
    local arrayCount = #array
    for i = arrayCount, 2, -1 do
        local j = math.random(1, i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

function mirrorPolygonHorizontally(polygon, width)
    local newPolygon = {}
    for i = #polygon - 1, 1, -2 do
        newPolygon[#newPolygon + 1] = width - polygon[i]
        newPolygon[#newPolygon + 1] = polygon[i + 1]
    end
    return newPolygon
end

function binaryToDecimal(binaryString, optionalBitChar)
    if optionalBitChar == nil then optionalBitChar = '1' end
    local num = 0
    local ex = string.len(binaryString) - 1
    local l = ex + 1
    for i = 1, l do
        b = string.sub(binaryString, i, i)
        if b == optionalBitChar then num = num + 2 ^ ex end
        ex = ex - 1
    end
    return tonumber( string.format('%u', num) )
end

function getDirectionOfRotation(rotation)
    return math.cos(rotation * math.pi / 180), math.sin(rotation * math.pi / 180)
end

function distortValue(value, amountToDistort)
    if amountToDistort == nil then amountToDistort = 10 end
    value = math.random(value - amountToDistort, value + amountToDistort)
    return value
end

function distort(value, amountToDistort)
    return misc.distortValue(value, amountToDistort)
end

function distortPoint(point, amountToDistort)
    return { x = misc.distortValue(point.x, amountToDistort), y = misc.distortValue(point.y, amountToDistort) }
end

function isNumber(v)
    local isIt = false
    if type(v) == 'number' then
        isIt = true
    elseif type(v) == 'string' then
        if v == '' then
            isIt = false
        else
            local foundNonNumber = false
            local numbers = {'0','1','2','3','4','5','6','7','8','9'}
            local max = string.len(v)
            for i = 1, max do
                local char = string.sub(v, i, i)
                if not misc.inArray(numbers, char) then foundNonNumber = true end
            end
            isIt = not foundNonNumber
        end
    end
    return isIt
end

function toStringBlankForNil(s)
    local v = ''
    if s ~= nil then v = tostring(s) end
    return v
end

function isNan(n)
    return tostring(n) == tostring(0/0)
end

function getFileText(relativePath, pathContext)
    if pathContext == nil then pathContext = system.DocumentsDirectory end
    local path = system.pathForFile(relativePath, pathContext)
    local s = nil
    local file = io.open(path, 'r')
    if file then
        s = file:read("*a")
        io.close(file)
    end
    return s
end

function setFileText(relativePath, s, pathContext)
    if pathContext == nil then pathContext = system.DocumentsDirectory end
    local path = system.pathForFile(relativePath, pathContext)
    appPrint('Saved to ' .. path)
    local file = io.open(path, 'w') -- was w+
    file:write( tostring(s) )
    io.close(file)
end

function getPercentRounded(all, part)
    return math.floor( misc.getPercent(all, part) )
end

function getPercent(all, part)
    local v = 0
    if all >= part then
        v = (part / all) * 100
    end
    return v
end

function trim(s)
    return( string.gsub(s, "^%s*(.-)%s*$", "%1") )
end

function getDifferenceBetweenDatesInDays(isoDate1, isoDate2)
    local date1 = misc.isoDateToDate(isoDate1)
    local date2 = misc.isoDateToDate(isoDate2)
    local oneDayInS = 60 * 60 * 24
    local differenceInS = math.abs( os.difftime( os.time(date1), os.time(date2) ) )
    return misc.getIf( differenceInS > 0, math.ceil(differenceInS / oneDayInS), 0 )
end

function join(thisTable, delimiter)
    if delimiter == nil then delimiter = ';' end
    return table.concat(thisTable, delimiter)
end

function split(s, delimiter)
    if delimiter == nil then delimiter = ';' end
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(s, delimiter, from)
    while delim_from do
        table.insert( result, string.sub(s, from , delim_from-1) )
        from = delim_to + 1
        delim_from, delim_to = string.find(s, delimiter, from)
    end
    table.insert( result, string.sub(s, from) )
    return result
end

function splitAsNumbers(s, delimiter)
    local thisTable = misc.split(s, delimiter)
    for i = 1, #thisTable do thisTable[i] = tonumber(thisTable[i]) end
    return thisTable
end

function isoDateToDate(isoDate)
    local date = misc.split(isoDate, '-')
    return { year = tonumber(date[1]), month = tonumber(date[2]), day = tonumber(date[3]) }
end

function toQuery(v)
    return toQueryValue(v)
end

function toQueryValue(v)
    -- todo: properly escape
    if v == nil then
        v = '""'
    elseif misc.isNumber(v) and v == math.floor( tonumber(v) ) then
    else
        v = '"' .. tostring(v)  .. '"'
    end
    return v
end

function toName(v, acceptedLetters, forceLowerCase)
    if v == nil or type(v) ~= 'string' then v = '' end
    if acceptedLetters == nil then
        acceptedLetters = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
                'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
                '0','1','2','3','4','5','6','7','8','9','_', '-'}
    end
    if forceLowerCase == nil then forceLowerCase = false end
    if forceLowerCase then v = v:lower() end

    local vNew = ''
    for i = 1, string.len(v) do
        local letter = string.sub(v, i, i)
        if not misc.inArray(acceptedLetters, letter) then
            if misc.inArray(acceptedLetters, '-') then letter = '-'
            else letter = ''
            end
        end
        vNew = vNew .. letter
    end
    return vNew
end

function getAbsolutePolygon(shape, width, height)
    local widthHalf = math.floor(width / 2)
    local heightHalf = math.floor(height / 2)
    local shapeClone = {}
    for i = 1, #shape, 2 do
        shapeClone[i] = shape[i] - widthHalf
        shapeClone[i + 1] = shape[i + 1] - heightHalf
    end
    return shapeClone
end

function getMin(a, b)
    return misc.getIf(a < b, a, b)
end

function getMax(a, b)
    return misc.getIf(a > b, a, b)
end

function trimNumber(number, max)
    if number > max then number = tostring(max) .. '+' end
    return number
end

function getAngleFromXY(x, y)
    return math.atan2(y, x) / math.pi * 180
end

function getDistance(point1, point2)
    local xfactor = point2.x - point1.x
    local yfactor = point2.y - point1.y
    return math.sqrt( (xfactor*xfactor) + (yfactor*yfactor) )
end

function toTable(v)
    if v ~= nil and type(v) ~= 'table' then v = {v} end
    return v
end

function getWrappedTextArray(str, letterMax, indent, indent1)
    str = misc.explode("\n", str)
 
    -- apply line breaks using the wrapping function
    local i = 1
    local strFinal = ""
    while i <= #str do
            strW = misc.wrap(str[i], letterMax, indent, indent1)
            strFinal = strFinal .. "\n" .. strW
            i = i + 1
    end
    str = strFinal
    
    -- search for each line that ends with a line break and add to an array
    local pos, arr = 0, {}
    for st,sp in function() return string.find(str,"\n",pos,true) end do
            table.insert(arr,string.sub(str,pos,st-1)) 
            pos = sp + 1 
    end
    table.insert(arr,string.sub(str,pos)) 

    local realArr = {}
    if #arr >= 2 then
        for n = 2, #arr do realArr[n - 1] = arr[n] end
    end

    return realArr
end

function wrap(str, letterMax, indent, indent1)
    indent = indent or ""
    indent1 = indent1 or indent
    letterMax = letterMax or 72
    local here = 1-#indent1
    return indent1..str:gsub("(%s+)()(%S+)()",
            function(sp, st, word, fi)
                if fi-here > letterMax then
                      here = st - #indent
                      return "\n" .. indent .. word
                end
            end)
end

function angleBetween(srcObj, dstObj)
    local xDist = dstObj.x - srcObj.x
    local yDist = dstObj.y - srcObj.y
    local angleBetween = math.deg( math.atan(yDist / xDist) )
    if (srcObj.x < dstObj.x) then
        angleBetween = angleBetween + 90
    else
        angleBetween = angleBetween - 90
    end
    angleBetween = angleBetween + 90
    return angleBetween
end

function addArrayToArray(originalArray, additionalArray)
    for i = 1, #additionalArray do
        originalArray[#originalArray + 1] = additionalArray[i]
    end
    return originalArray
end

function inArray(array, value)
    local is = false
    for i = 1, #array do
        if array[i] == value then
            is = true
            break
        end
    end
    return is
end

function randomFloat(min, max)
    return math.random(min * 100, max * 100) * .01
end

function randomNonZero(min, max)
    local r = nil
    while r == nil or r == 0 do
        r = math.random(min, max)
    end
    return r
end

function keepInLimits(v, min, max)
    if min ~= nil and v < min then v = min
    elseif max ~= nil and v > max then v = max
    end
    return v
end

function keepInLimitsCircular(v, min, max)
    if v > max then v = min + math.abs(max - v)
    elseif v < min then v = max - v
    end
    return v
end

function keepInLimitsCircularFixed(v, min, max)
    if v > max then v = min
    elseif v < min then v = max
    end
    return v
end

function padWithZero(s)
    s = tostring(s)
    if string.len(s) < 2 then s = '0' .. s end
    return s
end

function getChance(chanceInPercent)
    if chanceInPercent == nil then chanceInPercent = 50 end
    return chanceInPercent >= 100 or math.random(0, 100) <= chanceInPercent
end

function getIfChance(chanceInPercent, valueIfTrue, valueIfFalse)
    return misc.getIf( misc.getChance(chanceInPercent), valueIfTrue, valueIfFalse )
end

function getRandomEntry(table)
    local v = nil; local index = nil
    if type(table) == 'table' then
        index = math.random(1, #table)
        v = table[index]
    end
    return v
end

function getRandomEntryAndIndex(table)
    local v = nil; local index = nil
    if type(table) == 'table' then
        index = math.random(1, #table)
        v = table[index]
    end
    return v, index
end

function toInt(v)
    return math.ceil( tonumber(v) )
end

function getIf(boolean, valueIfTrue, valueIfFalse)
    local value = nil
    if boolean then value = valueIfTrue
    else value = valueIfFalse
    end
    return value
end

function toBoolean(v)
    return v~= nil and v == true
end

function tableShallowCopy(x)
   local y = { }
   for k, v in pairs(x) do y[k]=v end
   return y
end

function verboseBoolean(bool)
    return misc.getIf(bool, 'true', 'false')
end

function getLowest(a, b)
    local v = nil
    if a < b then v = a
    else v = b
    end
    return v
end

function getHighest(a, b)
    -- also see: table.maxn()
    local v = nil
    if a > b then v = a
    else v = b
    end
    return v
end

function tableToString(data, indent) 
    local s = ''

    local indentLength = 4
    if indent == nil then indent = 0 end
    local separator = ' = '

    if type(data) == "string" or type(data) == "number" then
        s = s .. (" "):rep(indent) .. data .. "\n"
    elseif type(data) == "boolean" then
        s = s .. misc.verboseBoolean(data)
    elseif type(data) == "table" then
        local i, v
        for i, v in pairs(data) do
            if type(v) == "table" then
                s = s .. (" "):rep(indent) .. i .. separator .. "\n"
                s = s .. misc.tableToString(v, indent + indentLength)
            else
                s = s .. (" "):rep(indent) .. i .. separator .. misc.tableToString(v, 0)
            end
        end
    end

    return s 
end

function getOffsetPointByRotation(centerPoint, rotation, offsetLength, rotationOffset)
    local rotation = math.ceil(rotation % 360)
    rotation = 360 - rotation + rotationOffset
    local angle  = math.rad(rotation)
    local pointWithOffset = {
            x = centerPoint.x + math.sin(angle) * offsetLength,
            y = centerPoint.y + math.cos(angle) * offsetLength
            }
    return pointWithOffset
end

function normalizeRotationAngle(angleInDegrees)
    angleInDegrees = angleInDegrees % 360
    if angleInDegrees < 0 then
        angleInDegrees = angleInDegrees + 360
    end
    return angleInDegrees
end

function upperCaseFirst(s)
    return s:sub(1,1):upper()..s:sub(2)
end

function getRandomNonZero(min, max)
    local r = nil
    while r == nil or r == 0 do r = math.random(min, max) end
    return r
end

function getRandomExcept(min, max, except, optionalFirst)
    local r = nil
    r = math.random(min, max)
    if except == nil and optionalFirst ~= nil then r = optionalFirst end
    if except ~= nil then
        while r == except do r = math.random(min, max) end
    end
    return r
end

function getNeededSpeedByTargetPoint(baseSpeed, startPoint, targetPoint)
    local otherVec = misc.vec_sub(targetPoint, startPoint)
    local distance = misc.vec_mag(otherVec)
    otherVec = misc.vec_add( otherVec, misc.vec_mul( {x = 0, y = 0}, distance / baseSpeed ) )
    local speed = misc.vec_mul( misc.vec_normal(otherVec), baseSpeed )
    return speed.x, speed.y
end

function vec_mag(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

function vec_sub(a, b)
    return {x = a.x - b.x, y = a.y - b.y}
end

function vec_add(a, b)
    return {x = a.x + b.x, y = a.y + b.y}
end

function vec_mul(a, c)
    return {x = a.x * c, y = a.y * c}
end

function vec_div(a, c)
    return misc.vec_mul(a, 1.0 / c)
end

function vec_normal(a)
    return misc.vec_div( a, vec_mag(a) )
end

function sign(v)
    local sgn = 0
    if v < 0 then sgn = -1
    elseif v > 0 then sgn = 1
    end
    return sgn
end

function getRandomString(length)
    local s = math.random(100000, 999000)
    return s
end

function round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end
