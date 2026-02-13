local QBCore = exports['qb-core']:GetCoreObject()

local function GetRestrictedChannelConfig(channel)
    if not channel then
        return nil
    end

    local whole = math.floor(channel)
    return Config.RestrictedChannels[whole] or Config.RestrictedChannels[channel]
end

local function HasRequiredJob(Player, restrictedCfg)
    if not restrictedCfg then
        return true
    end

    local playerJob = Player.PlayerData.job
    if not playerJob then
        return false
    end

    if restrictedCfg.job and playerJob.name ~= restrictedCfg.job then
        return false
    end

    if restrictedCfg.minGrade and (not playerJob.grade or (playerJob.grade.level or 0) < restrictedCfg.minGrade) then
        return false
    end

    return true
end

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

QBCore.Functions.CreateCallback('advanced-radio:server:CanJoinChannel', function(source, cb, channel)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Player not found')
        return
    end

    local frequency = tonumber(channel)
    if not frequency then
        cb(false, 'Invalid frequency')
        return
    end

    local minFrequency = tonumber(Config.MinFrequency) or 1.0
    local maxFrequency = tonumber(Config.MaxFrequency) or 999
    if frequency < minFrequency or frequency > maxFrequency then
        cb(false, ('Frequency must be between %.1f and %.1f'):format(minFrequency, maxFrequency))
        return
    end

    local restrictedCfg = GetRestrictedChannelConfig(frequency)
    if not HasRequiredJob(Player, restrictedCfg) then
        cb(false, 'Encrypted Channel: Access Denied')
        return
    end

    cb(true)
end)
