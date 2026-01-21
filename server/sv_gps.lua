local QBCore = exports['qb-core']:GetCoreObject()

local playerMarkers = {}
local CURRENT_VERSION = '1.0.0'
local RESOURCE_NAME = 'core_gps'

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
    TriggerClientEvent('core_gps:client:useItem', source)
end)

RegisterNetEvent('core_gps:server:loadMarkers', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    local result = exports['oxmysql']:executeSync('SELECT * FROM core_gps WHERE citizenid = ? ORDER BY id ASC', {citizenid})
    
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

RegisterNetEvent('core_gps:server:addMarker', function(markerData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not playerMarkers[citizenid] then
        playerMarkers[citizenid] = {}
    end
    
    if #playerMarkers[citizenid] >= Config.MaxMarkers then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of markers (' .. Config.MaxMarkers .. ')', 'error')
        return
    end
    
    local insertId = exports['oxmysql']:insertSync('INSERT INTO core_gps (citizenid, label, coords, street, timestamp) VALUES (?, ?, ?, ?, ?)', {
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

RegisterNetEvent('core_gps:server:removeMarker', function(index)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if playerMarkers[citizenid] and playerMarkers[citizenid][index] then
        local markerId = playerMarkers[citizenid][index].id
        
        exports['oxmysql']:executeSync('DELETE FROM core_gps WHERE id = ? AND citizenid = ?', {markerId, citizenid})
        
        table.remove(playerMarkers[citizenid], index)
        TriggerClientEvent('core_gps:client:updateMarkers', src, playerMarkers[citizenid])
        TriggerClientEvent('QBCore:Notify', src, 'Marker removed!', 'success')
    end
end)

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

local CURRENT_VERSION = '1.0.0'
local RESOURCE_NAME = 'core_gps'
local VERSION_CHECK_URL = 'https://raw.githubusercontent.com/ChrisNewmanDev/core_gps/main/version.json'

local function ParseVersion(version)
    local major, minor, patch = version:match('(%d+)%.(%d+)%.(%d+)')
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end

local function CompareVersions(current, latest)
    local currentVer = ParseVersion(current)
    local latestVer = ParseVersion(latest)
    
    if latestVer.major > currentVer.major then return 'outdated'
    elseif latestVer.major < currentVer.major then return 'ahead' end
    
    if latestVer.minor > currentVer.minor then return 'outdated'
    elseif latestVer.minor < currentVer.minor then return 'ahead' end
    
    if latestVer.patch > currentVer.patch then return 'outdated'
    elseif latestVer.patch < currentVer.patch then return 'ahead' end
    
    return 'current'
end

local function CheckVersion()
    PerformHttpRequest(VERSION_CHECK_URL, function(statusCode, response, headers)
        if statusCode ~= 200 then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to check for updates (HTTP ' .. statusCode .. ')^7')
            print('^3[' .. RESOURCE_NAME .. '] ^3Please verify the version.json URL is correct^7')
            return
        end
        
        local success, versionData = pcall(function() return json.decode(response) end)
        
        if not success or not versionData or not versionData.version then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to parse version data^7')
            return
        end
        
        local latestVersion = versionData.version
        local versionStatus = CompareVersions(CURRENT_VERSION, latestVersion)
        
        print('^3========================================^7')
        print('^5[' .. RESOURCE_NAME .. '] Version Checker^7')
        print('^3========================================^7')
        print('^2Current Version: ^7' .. CURRENT_VERSION)
        print('^2Latest Version:  ^7' .. latestVersion)
        print('')
        
        if versionStatus == 'current' then
            print('^2✓ You are running the latest version!^7')
        elseif versionStatus == 'ahead' then
            print('^3⚠ You are running a NEWER version than released!^7')
            print('^3This may be a development version.^7')
        elseif versionStatus == 'outdated' then
            print('^1⚠ UPDATE AVAILABLE!^7')
            print('')
            
            if versionData.changelog and versionData.changelog[latestVersion] then
                local changelog = versionData.changelog[latestVersion]
                
                if changelog.date then
                    print('^6Release Date: ^7' .. changelog.date)
                    print('')
                end
                
                if changelog.changes and #changelog.changes > 0 then
                    print('^5Changes:^7')
                    for _, change in ipairs(changelog.changes) do
                        print('  ^2✓^7 ' .. change)
                    end
                    print('')
                end
                
                if changelog.files_to_update and #changelog.files_to_update > 0 then
                    print('^1Files that need to be updated:^7')
                    for _, file in ipairs(changelog.files_to_update) do
                        print('  ^3➤^7 ' .. file)
                    end
                    print('')
                end
            end
            
            print('^2Download: ^7https://github.com/ChrisNewmanDev/core_gps/releases/latest')
        end
        
        print('^3========================================^7')
    end, 'GET')
end

CreateThread(function()
    Wait(2000)
    CheckVersion()
end)
