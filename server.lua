local hasFramework = false
local GetPlayer = nil
local hasOxInventory = false

-- Track reload states to prevent exploitation
local playerReloadStates = {}
local reloadCooldowns = {}
local CONFIG = {
    RELOAD_SERVER_COOLDOWN = 2500, -- Minimum time between reload requests (anti-spam)
    RELOAD_TIMEOUT = 5000, -- Maximum time a reload can take before auto-reset
}

Citizen.CreateThread(function()
    Wait(1000)
    hasOxInventory = GetResourceState('ox_inventory') == 'started'

    if GetResourceState('qb-core') == 'started' then
        hasFramework = true
        local QBCore = exports['qb-core']:GetCoreObject()
        GetPlayer = function(src)
            return QBCore.Functions.GetPlayer(src)
        end
    elseif GetResourceState('es_extended') == 'started' then
        hasFramework = true
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        GetPlayer = function(src)
            return ESX.GetPlayerFromId(src)
        end
    end
end)

-- Clean up stale reload states periodically
Citizen.CreateThread(function()
    while true do
        Wait(10000)
        local currentTime = GetGameTimer()
        for src, state in pairs(playerReloadStates) do
            if state and (currentTime - state.startTime > CONFIG.RELOAD_TIMEOUT) then
                playerReloadStates[src] = nil
                reloadCooldowns[src] = nil
                print(("[SmartTaser] Auto-reset reload state for player %s (timeout)"):format(src))
            end
        end
    end
end)

RegisterServerEvent('smarttaser:logTaser')
AddEventHandler('smarttaser:logTaser', function(cartridgesLeft)
    local src = source
    print(("[SmartTaser] Player %s fired taser. %d cartridges left."):format(src, cartridgesLeft))
end)

RegisterServerEvent('smarttaser:stunPlayer')
AddEventHandler('smarttaser:stunPlayer', function(targetId)
    TriggerClientEvent('smarttaser:applyStun', targetId)
end)

-- Client notifies server when reload is complete
RegisterServerEvent('smarttaser:reloadComplete')
AddEventHandler('smarttaser:reloadComplete', function()
    local src = source
    if playerReloadStates[src] then
        playerReloadStates[src] = nil
        print(("[SmartTaser] Player %s reload complete"):format(src))
    end
end)


local function consumeCartridge(src)
    local itemName = Config.CartridgeItem or 'taser_cartridge'

    if hasOxInventory then
        local count = exports.ox_inventory:Search(src, 'count', itemName) or 0
        if count < 1 then
            return false
        end

        return exports.ox_inventory:RemoveItem(src, itemName, 1)
    end

    if hasFramework and GetPlayer then
        local Player = GetPlayer(src)
        if not Player then
            return false
        end

        if Player.Functions then
            return Player.Functions.RemoveItem(itemName, 1)
        end

        if Player.removeInventoryItem and Player.getInventoryItem then
            local item = Player.getInventoryItem(itemName)
            local count = item and item.count or 0
            if count > 0 then
                Player.removeInventoryItem(itemName, 1)
                return true
            end
        end
    end

    -- No supported inventory framework running. Allow reload to avoid hard-locking the taser.
    return true
end

RegisterServerEvent('smarttaser:checkCartridgeItem')
AddEventHandler('smarttaser:checkCartridgeItem', function(currentCartridges)
    local src = source
    local currentTime = GetGameTimer()
    local ammoCount = tonumber(currentCartridges) or 0
    
    -- Validate source
    if not src or src <= 0 then
        print("[SmartTaser] Invalid source in checkCartridgeItem")
        return
    end

    -- Prevent wasting reloads when taser is already full
    if ammoCount >= Config.MaxCartridges then
        TriggerClientEvent('chat:addMessage', src, {args = {"Taser", "Taser is already fully loaded!"}})
        return
    end
    
    -- Anti-spam: Check if player is already reloading
    if playerReloadStates[src] and playerReloadStates[src].isReloading then
        print(("[SmartTaser] Player %s attempted reload while already reloading"):format(src))
        return
    end
    
    -- Anti-spam: Check cooldown between reload requests
    if reloadCooldowns[src] and (currentTime - reloadCooldowns[src] < CONFIG.RELOAD_SERVER_COOLDOWN) then
        print(("[SmartTaser] Player %s spamming reload requests"):format(src))
        TriggerClientEvent('chat:addMessage', src, {args = {"Taser", "Please wait before reloading again!"}})
        return
    end
    
    -- Set reload state and cooldown
    playerReloadStates[src] = {
        isReloading = true,
        startTime = currentTime
    }
    reloadCooldowns[src] = currentTime
    
    -- Check for cartridge item (native ox_inventory first, then framework fallbacks)
    local hasCartridge = consumeCartridge(src)

    if not hasCartridge then
        playerReloadStates[src] = nil
        TriggerClientEvent('chat:addMessage', src, {args = {"Taser", "You have no taser cartridges!"}})
        return
    end
    
    -- All checks passed, trigger client reload
    if hasCartridge then
        TriggerClientEvent('smarttaser:reloadTaser', src)
        
        -- Schedule reload state reset after expected reload time
        SetTimeout(Config.ReloadTime + 500, function()
            if playerReloadStates[src] then
                playerReloadStates[src] = nil
            end
        end)
    end
end)
