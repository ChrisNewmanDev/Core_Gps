local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local savedMarkers = {}
local blips = {}
local markersVisible = true
local isUIOpen = false

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('core_gps:server:loadMarkers')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    savedMarkers = {}
    ClearAllBlips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = QBCore.Functions.GetPlayerData()
        TriggerServerEvent('core_gps:server:loadMarkers')
        Wait(1000)
        if markersVisible then
            local hasItem = QBCore.Functions.HasItem(Config.ItemName)
            if hasItem and #savedMarkers > 0 then
                RefreshBlips()
            end
        end
    end
end)

-- Use GPS Marker Item
RegisterNetEvent('core_gps:client:useItem', function()
    OpenGPSUI()
end)

-- Open GPS UI
function OpenGPSUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        markers = savedMarkers,
        markersVisible = markersVisible
    })
end

-- Close GPS UI
RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Mark Current Location
RegisterNUICallback('markLocation', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    
    local markerData = {
        label = data.label or 'Marked Location',
        coords = {x = coords.x, y = coords.y, z = coords.z},
        street = streetName,
        timestamp = os.time()
    }
    
    TriggerServerEvent('core_gps:server:addMarker', markerData)
    cb('ok')
end)

-- Remove Marker
RegisterNUICallback('removeMarker', function(data, cb)
    TriggerServerEvent('core_gps:server:removeMarker', data.index)
    cb('ok')
end)

-- Share Marker
RegisterNUICallback('shareMarker', function(data, cb)
    TriggerServerEvent('core_gps:server:shareMarker', data.playerId, data.index)
    cb('ok')
end)

-- Toggle Markers
RegisterNUICallback('toggleMarkers', function(data, cb)
    markersVisible = data.visible
    
    if markersVisible then
        RefreshBlips()
    else
        ClearAllBlips()
    end
    
    cb('ok')
end)

-- Set Waypoint from NUI
RegisterNUICallback('setWaypoint', function(data, cb)
    local marker = savedMarkers[data.index]
    if marker then
        SetNewWaypoint(marker.coords.x, marker.coords.y)
        QBCore.Functions.Notify('Waypoint set!', 'success')
    end
    cb('ok')
end)

-- Update markers from server
RegisterNetEvent('core_gps:client:updateMarkers', function(markers)
    savedMarkers = markers
    
    if isUIOpen then
        SendNUIMessage({
            action = 'updateMarkers',
            markers = savedMarkers
        })
    end
    
    if markersVisible then
        RefreshBlips()
    end
end)

-- Receive shared marker
RegisterNetEvent('core_gps:client:receiveSharedMarker', function(markerData, senderName)
    QBCore.Functions.Notify('You received a location from ' .. senderName, 'success')
    TriggerServerEvent('core_gps:server:addMarker', markerData)
end)

-- Notification for share result
RegisterNetEvent('core_gps:client:shareResult', function(success, message)
    if success then
        QBCore.Functions.Notify(message, 'success')
    else
        QBCore.Functions.Notify(message, 'error')
    end
end)

-- Create blips on map
function RefreshBlips()
    ClearAllBlips()
    
    if not markersVisible then return end
    
    -- Check if player has the GPS item
    local hasItem = QBCore.Functions.HasItem(Config.ItemName)
    if not hasItem then return end
    
    for i, marker in ipairs(savedMarkers) do
        local blip = AddBlipForCoord(marker.coords.x, marker.coords.y, marker.coords.z)
        SetBlipSprite(blip, Config.BlipSettings.sprite)
        SetBlipColour(blip, Config.BlipSettings.color)
        SetBlipScale(blip, Config.BlipSettings.scale)
        SetBlipDisplay(blip, Config.BlipSettings.display)
        SetBlipAsShortRange(blip, Config.BlipSettings.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(marker.label)
        EndTextCommandSetBlipName(blip)
        
        table.insert(blips, blip)
    end
end

-- Clear all blips
function ClearAllBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

-- Handle inventory updates to check for item possession
local function CheckItemAndUpdateBlips()
    if not markersVisible then return end
    
    local hasItem = QBCore.Functions.HasItem(Config.ItemName)
    local hasBlips = #blips > 0
    
    if hasItem and not hasBlips and #savedMarkers > 0 then
        RefreshBlips()
    elseif not hasItem and hasBlips then
        ClearAllBlips()
    end
end

-- Listen for inventory updates
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
    CheckItemAndUpdateBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    Wait(1000) -- Small delay to ensure data is loaded
    CheckItemAndUpdateBlips()
end)

-- Also listen to inventory item updates (when items are added/removed)
AddEventHandler('QBCore:Client:OnJobUpdate', function()
    CheckItemAndUpdateBlips()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearAllBlips()
        if isUIOpen then
            SetNuiFocus(false, false)
        end
    end
end)
