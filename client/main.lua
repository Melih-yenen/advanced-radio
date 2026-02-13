local QBCore = exports['qb-core']:GetCoreObject()
local isRadioOpen = false
local currentChannel = nil
local currentVolume = tonumber(Config.DefaultVolume) or 50
local radioProp = nil

local function DebugLog(msg)
    if Config.Debug then
        print(('[advanced-radio] %s'):format(msg))
    end
end

local function Notify(msg, notifyType)
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(msg, notifyType or 'primary')
        return
    end

    TriggerEvent('chat:addMessage', { args = { '[Radio]', msg } })
end

local function LoadAnimDic(dict)
    if HasAnimDictLoaded(dict) then
        return
    end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

local function AttachRadio()
    local ped = PlayerPedId()
    local model = GetHashKey(Config.Prop)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(0)
    end

    local bone = GetPedBoneIndex(ped, 28422)
    radioProp = CreateObject(model, 1.0, 1.0, 1.0, true, true, false)
    AttachEntityToEntity(radioProp, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 2, true)
    SetModelAsNoLongerNeeded(model)
end

local function RemoveRadio()
    if radioProp and DoesEntityExist(radioProp) then
        DeleteEntity(radioProp)
    end
    radioProp = nil
end

local function LeaveCurrentRadio()
    exports['pma-voice']:removePlayerFromRadio()
    currentChannel = nil
    DebugLog('Left radio')
end

local function RoundFrequency(num)
    local decimals = math.max(0, tonumber(Config.FrequencyDecimals) or 1)
    local mult = 10 ^ decimals
    return math.floor((num * mult) + 0.5) / mult
end

local function ValidateFrequency(num)
    local value = tonumber(num)
    if not value then
        return nil, 'Invalid frequency'
    end

    local minFrequency = tonumber(Config.MinFrequency) or 1.0
    local maxFrequency = tonumber(Config.MaxFrequency) or 999
    local rounded = RoundFrequency(value)

    if rounded < minFrequency or rounded > maxFrequency then
        return nil, ('Frequency must be between %.1f and %.1f'):format(minFrequency, maxFrequency)
    end

    return rounded
end

local function ToggleRadio(state)
    isRadioOpen = state
    SetNuiFocus(state, state)

    if state then
        SendNUIMessage({
            type = 'open',
            maxFrequency = tonumber(Config.MaxFrequency) or 999,
            minFrequency = tonumber(Config.MinFrequency) or 1.0,
            defaultVolume = currentVolume,
            presets = Config.Presets or {},
            currentChannel = currentChannel
        })

        if Config.EnableAnimation then
            local ped = PlayerPedId()
            LoadAnimDic('cellphone@')
            TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_read_base', 8.0, -8.0, -1, 50, 0.0, false, false, false)
            AttachRadio()
        end
    else
        SendNUIMessage({ type = 'close' })

        if Config.EnableAnimation then
            local ped = PlayerPedId()
            StopAnimTask(ped, 'cellphone@', 'cellphone_text_read_base', 1.0)
            RemoveRadio()
        end
    end
end

RegisterCommand(Config.Command, function()
    if isRadioOpen then
        ToggleRadio(false)
        return
    end

    if Config.RadioItem then
        QBCore.Functions.TriggerCallback('advanced-radio:server:HasRadio', function(hasItem)
            if hasItem then
                ToggleRadio(true)
            else
                Notify("You don't have a radio!", 'error')
            end
        end)
        return
    end

    ToggleRadio(true)
end)

CreateThread(function()
    while true do
        Wait(3000)
        if isRadioOpen and Config.RadioItem then
            QBCore.Functions.TriggerCallback('advanced-radio:server:HasRadio', function(hasItem)
                if hasItem then
                    return
                end

                ToggleRadio(false)
                LeaveCurrentRadio()
                Notify('You lost your radio!', 'error')
            end)
        end
    end
end)

RegisterKeyMapping(Config.Command, 'Open Radio', 'keyboard', Config.OpenKey)

RegisterNUICallback('close', function(_, cb)
    ToggleRadio(false)
    cb({ ok = true })
end)

RegisterNUICallback('joinRadio', function(data, cb)
    local frequency, err = ValidateFrequency(data.channel)
    if not frequency then
        cb({ ok = false, error = err })
        return
    end

    QBCore.Functions.TriggerCallback('advanced-radio:server:CanJoinChannel', function(canJoin, reason)
        if not canJoin then
            Notify(reason or 'Access denied', 'error')
            cb({ ok = false, error = reason or 'Access denied' })
            return
        end

        exports['pma-voice']:setRadioChannel(frequency)
        currentChannel = frequency
        DebugLog(('Joined radio %.1f'):format(frequency))
        cb({ ok = true, channel = frequency })
    end, frequency)
end)

RegisterNUICallback('leaveRadio', function(_, cb)
    LeaveCurrentRadio()
    cb({ ok = true })
end)

RegisterNUICallback('setVolume', function(data, cb)
    local volume = tonumber(data.volume)
    if not volume then
        cb({ ok = false, error = 'Invalid volume' })
        return
    end

    volume = math.max(0, math.min(100, math.floor(volume)))
    currentVolume = volume
    exports['pma-voice']:setRadioVolume(volume)
    DebugLog(('Volume set to %s'):format(volume))
    cb({ ok = true, volume = volume })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if isRadioOpen then
        SetNuiFocus(false, false)
    end
    RemoveRadio()
    LeaveCurrentRadio()
end)

