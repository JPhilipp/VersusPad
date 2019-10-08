module(..., package.seeall)

function getIsoDate(date)
    if date == nil then date = os.date('*t') end
    local isoDate = date.year .. '-' .. misc.padWithZero(date.month) .. '-' .. misc.padWithZero(date.day)
    -- if false and app.isLocalTest then isoDate = '2011-01-01'; appPrint('Changing date to ' .. isoDate) end
    return isoDate
end

function initDefaults(includePhysics)
    if includePhysics == nil then includePhysics = true end
    math.randomseed( os.time() )
    display.setStatusBar(display.HiddenStatusBar)
    if includePhysics then physics.start() end
    system.activate('multitouch')
end

function getIsoDateTime(date)
    if date == nil then date = os.date('*t') end
    local isoDate =
            date.year .. '-' .. misc.padWithZero(date.month) .. '-' .. misc.padWithZero(date.day) .. ' ' ..
            misc.padWithZero(date.hour) .. ':' .. misc.padWithZero(date.min) .. ':' .. misc.padWithZero(date.sec)
    return isoDate
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

function shuffleArray(t)
    local n = #t
    while n > 2 do
        local k = math.random(n)
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end
    return t
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

function split(s, delimiter)
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

function join(array, delimiter)
    -- todo: replace with table.concat
    local s = nil
    if type(array) == 'table' then
        s = ''
        for i = 1, #array do
            s = s .. array[i] .. delimiter
        end
    end
    return s
end

function explode(div,str) -- only used for wordWrap functon, perhaps same as split
    if (div=='') then return false end
    local pos,arr = 0,{}
    -- for each divider found
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
    table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
    return arr
end

function join(thisTable, delimiter)
    local s = ''
    if type(thisTable) == 'table' then
        for i = 1, #thisTable do
            if i >= 2 then s = s .. delimiter end
            s = s .. tostring(thisTable[i])
        end
    end
    return s
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

function toName(v)
    local acceptedLetters = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
            'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
            '0','1','2','3','4','5','6','7','8','9','_','-'}
    if v == nil or type(v) ~= 'string' then v = '' end
    local vNew = ''
    for i = 1, string.len(v) do
        local letter = string.sub(v, i, i)
        if not misc.inArray(acceptedLetters, letter) then
            letter = '-'
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
    if type(v) ~= 'table' then v = {v} end
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
    for i, thisValue in ipairs(array) do
        if thisValue == value then
            is = true
            break
        end
    end
    return is
end

function randomFloat(min, max)
    return math.random(min * 100, max * 100) * .01
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
    local v = nil
    if type(table) == 'table' then
        if #table > 1 then v = table[ math.random(1, #table) ]
        else v = 1
        end
    end
    return v
end

function getRandomString(length)
    local s = math.random(100000, 999000) -- still todo
    return s
end

function toInt(v)
    return math.ceil( tonumber(v) )
end

function getIf(boolean, valueIfTrue, valueIfFalse)
    local value = nil
    if boolean then
        value = valueIfTrue
    else
        value = valueIfFalse
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
    local s = ""
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