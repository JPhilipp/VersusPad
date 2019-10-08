module(..., package.seeall)

function getStringsData()
    local v = {}

    v['newsDialogHeader'] = {
            en = 'News',
            de = 'Nachricht',
            zh = '新闻'}
    v['newsDialogShow'] = {
            en = 'Show Me!',
            de = "Zeig's mir!",
            zh = '我要看！'}
    v['newsDialogRemind'] = {
            en = 'Remind me',
            de = 'Erinner mich',
            zh = '稍候提醒'}
    v['newsDialogNo'] = {
            en = 'No thanks',
            de = 'Nein danke',
            zh = '不，谢谢'}

    ----------------------------

    v['allTimeHi'] = {
            en = 'All-Time Hi:',
            de = 'ALLZEIT-HI:',
            zh = '此次分数：'}

    return v
end

function get(id, replacementArray)
    local v = ''
    local strings = language.getStringsData()

    if strings[id]  ~= nil then
        if strings[id][app.language] ~= nil then v = strings[id][app.language]
        elseif strings[id][app.defaultLanguage] ~= nil then v = strings[id][app.defaultLanguage]
        end
    end

    if type(replacementArray) == 'table' then
        for searchFor, replaceWith in pairs(replacementArray) do
            v = string.gsub( v, '%[' .. tostring(searchFor) .. '%]', tostring(replaceWith) )
        end
    end

    return v
end

function getByArray(languageNameValueArray)
    local v = ''
    if languageNameValueArray[app.language] ~= nil then v = languageNameValueArray[app.language]
    elseif languageNameValueArray[app.defaultLanguage] ~= nil then v = languageNameValueArray[app.defaultLanguage]
    end
    return v
end
