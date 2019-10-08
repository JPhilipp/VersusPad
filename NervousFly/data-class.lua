module(..., package.seeall)

function dataClass()
local self = {}

self.db = nil

function self:getBool(id, optionalDefaultValue)
    local value = app.data:get(id, optionalDefaultValue)
    return tostring(value) == 'true' or tostring(value) == '1' or value == 1 or value == true
end

function self:setBool(id, value)
    app.data:set( id, misc.getIf(value == true, 1, 0 ) )
end

function self:get(id, optionalDefaultValue)
    local value = nil
    local query = 'SELECT content FROM data WHERE id = ' .. misc.toQueryValue(id)
    for row in self.db:nrows(query) do
        value = row.content
    end
    if value == nil and optionalDefaultValue ~= nil then value = optionalDefaultValue end
    return value
end

function self:set(id, value)
    local query = nil
    if self:get(id) == nil then query = 'INSERT INTO data VALUES (' .. misc.toQueryValue(id) .. ', ' .. misc.toQueryValue(value) .. ')'
    else query = 'UPDATE data SET content = ' .. misc.toQueryValue(value) .. ' WHERE id = ' .. misc.toQueryValue(id)
    end
    self.db:exec(query)
end

function self:open(clearBefore)
    local path = system.pathForFile('storage.db', system.DocumentsDirectory)
    self.db = sqlite3.open(path)
    local function onSystemEvent(event)
        if event.type == 'applicationExit' then app.data.db:close() end
    end

    if clearBefore ~= nil and clearBefore then app.data:clear() end
    self.db:exec( 'CREATE TABLE IF NOT EXISTS data (id STRING, content STRING)' )
end

function self:clear()
    self.db:exec('DROP TABLE data')
end

function self:close()
    self.db:close()
end

function self:print()
    for row in storage.db:nrows('SELECT * FROM data') do
        appPrint( tostring(row.id) .. ' = ' .. tostring(row.content) )
    end
end

return self
end