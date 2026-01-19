local QBCore = exports['qb-core']:GetCoreObject()

-- Store player markers in memory for quick access
local playerMarkers = {}

-- Load markers for a player from database
RegisterNetEvent('core_gps:server:loadMarkers', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Load from database
    local result = MySQL.query.await('SELECT * FROM core_gps WHERE citizenid = ? ORDER BY id ASC', {citizenid})
    
    if result then
        local markers = {}
        for _, row in ipairs(result) do
            table.insert(markers, {
                id = row.id,
                label = row.label,
                coords = json.decode(row.coords),
                street = row.street,
                timestamp = row.timestamp
            })
        end
        playerMarkers[citizenid] = markers
    else
        playerMarkers[citizenid] = {}
    end
    
    TriggerClientEvent('core_gps:client:updateMarkers', src, playerMarkers[citizenid])
end)

-- Add a new marker
RegisterNetEvent('core_gps:server:addMarker', function(markerData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not playerMarkers[citizenid] then
        playerMarkers[citizenid] = {}
    end
    
    -- Check max markers limit
    if #playerMarkers[citizenid] >= Config.MaxMarkers then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of markers (' .. Config.MaxMarkers .. ')', 'error')
        return
    end
    
    -- Insert into database
    local insertId = MySQL.insert.await('INSERT INTO core_gps (citizenid, label, coords, street, timestamp) VALUES (?, ?, ?, ?, ?)', {
        citizenid,
        markerData.label,
        json.encode(markerData.coords),
        markerData.street,
        markerData.timestamp
    })
    
    if insertId then
        markerData.id = insertId
        table.insert(playerMarkers[citizenid], markerData)
        TriggerClientEvent('core_gps:client:updateMarkers', src, playerMarkers[citizenid])
        TriggerClientEvent('QBCore:Notify', src, 'Location marked!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to save marker', 'error')
    end
end)

-- Remove a marker
RegisterNetEvent('core_gps:server:removeMarker', function(index)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if playerMarkers[citizenid] and playerMarkers[citizenid][index] then
        local markerId = playerMarkers[citizenid][index].id
        
        -- Delete from database
        MySQL.query.await('DELETE FROM core_gps WHERE id = ? AND citizenid = ?', {markerId, citizenid})
        
        -- Remove from memory
        table.remove(playerMarkers[citizenid], index)
        TriggerClientEvent('core_gps:client:updateMarkers', src, playerMarkers[citizenid])
        TriggerClientEvent('QBCore:Notify', src, 'Marker removed!', 'success')
    end
end)

-- Share marker with another player
RegisterNetEvent('core_gps:server:shareMarker', function(targetId, markerIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local TargetPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))
    
    if not Player then return end
    
    if not TargetPlayer then
        TriggerClientEvent('core_gps:client:shareResult', src, false, 'Player not found or offline')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if playerMarkers[citizenid] and playerMarkers[citizenid][markerIndex] then
        local markerData = playerMarkers[citizenid][markerIndex]
        local senderName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        TriggerClientEvent('core_gps:client:receiveSharedMarker', TargetPlayer.PlayerData.source, markerData, senderName)
        TriggerClientEvent('core_gps:client:shareResult', src, true, 'Location shared successfully!')
    else
        TriggerClientEvent('core_gps:client:shareResult', src, false, 'Marker not found')
    end
end)
