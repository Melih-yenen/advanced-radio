local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('advanced-radio:server:HasRadio', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    if not Config.RadioItem then return cb(true) end
    
    local item = Player.Functions.GetItemByName(Config.RadioItem)
    if item then
        cb(true)
    else
        cb(false)
    end
end)
