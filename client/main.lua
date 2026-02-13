local QBCore = exports['qb-core']:GetCoreObject() -- Assuming QBCore, but will make it standalone compatible where possible
local isRadioOpen = false

local radioProp = nil

local function LoadAnimDic(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
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
    radioProp = CreateObject(model, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(radioProp, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
end

local function RemoveRadio()
    if radioProp ~= nil then
        DeleteEntity(radioProp)
        radioProp = nil
    end
end

-- Function to toggle radio UI
local function ToggleRadio(state)
    isRadioOpen = state
    SetNuiFocus(state, state)
    if state then
        SendNUIMessage({
            type = "open"
        })
        -- Add animation here
        if Config.EnableAnimation then
            local ped = PlayerPedId()
            LoadAnimDic('cellphone@')
            TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_read_base', 8.0, -8.0, -1, 50, 0, false, false, false)
            AttachRadio()
        end
    else
        SendNUIMessage({
            type = "close"
        })
        -- Remove animation
        if Config.EnableAnimation then
            local ped = PlayerPedId()
            StopAnimTask(ped, 'cellphone@', 'cellphone_text_read_base', 1.0)
            RemoveRadio()
        end
    end
end

RegisterCommand(Config.Command, function()
    if not isRadioOpen then
        if Config.RadioItem then
            QBCore.Functions.TriggerCallback('advanced-radio:server:HasRadio', function(hasItem)
                if hasItem then
                    ToggleRadio(true)
                else
                    QBCore.Functions.Notify("You don't have a radio!", "error")
                end
            end)
        else
            ToggleRadio(true)
        end
    else
        ToggleRadio(false)
    end
end)

-- Loop to check if player still has radio while open
CreateThread(function()
    while true do
        Wait(1000)
        if isRadioOpen and Config.RadioItem then
            local PlayerData = QBCore.Functions.GetPlayerData()
            local hasItem = false
            if PlayerData.items then
                for _, item in pairs(PlayerData.items) do
                    if item and item.name == Config.RadioItem then
                        hasItem = true
                        break
                    end
                end
            end
            
            if not hasItem then
                ToggleRadio(false)
                QBCore.Functions.Notify("You lost your radio!", "error")
            end
        end
    end
end)

RegisterKeyMapping(Config.Command, 'Open Radio', 'keyboard', Config.OpenKey)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    ToggleRadio(false)
    cb('ok')
end)

RegisterNUICallback('joinRadio', function(data, cb)
    local frequency = tonumber(data.channel)
    if not frequency then return end
    
    if Config.RestrictedChannels[frequency] then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData.job.name ~= Config.RestrictedChannels[frequency].job then
            if Config.Debug then print("Restricted channel. Job required: " .. Config.RestrictedChannels[frequency].job) end
            TriggerEvent('QBCore:Notify', "Encrypted Channel: Access Denied", "error")
            return
        end
    end

    exports['pma-voice']:setRadioChannel(frequency)
    if Config.Debug then print("Joined Radio: " .. frequency) end
    -- TriggerEvent('QBCore:Notify', "Joined channel: " .. frequency, "success")
    cb('ok')
end)

RegisterNUICallback('leaveRadio', function(data, cb)
    exports['pma-voice']:removePlayerFromRadio()
    if Config.Debug then print("Left Radio") end
    -- TriggerEvent('QBCore:Notify', "Disconnected", "error")
    cb('ok')
end)

RegisterNUICallback('setVolume', function(data, cb)
    local volume = tonumber(data.volume)
    if volume then
        exports['pma-voice']:setRadioVolume(volume)
        if Config.Debug then print("Volume set to: " .. volume) end
    end
    cb('ok')
end)

