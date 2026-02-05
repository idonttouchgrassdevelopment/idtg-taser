local hasFramework = false
local GetPlayer = nil

Citizen.CreateThread(function()
    Wait(1000)
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

RegisterServerEvent('smarttaser:logTaser')
AddEventHandler('smarttaser:logTaser', function(cartridgesLeft)
    local src = source
    print(("[SmartTaser] Player %s fired taser. %d cartridges left."):format(src, cartridgesLeft))
end)

RegisterServerEvent('smarttaser:stunPlayer')
AddEventHandler('smarttaser:stunPlayer', function(targetId)
    TriggerClientEvent('smarttaser:applyStun', targetId)
end)

RegisterServerEvent('smarttaser:checkCartridgeItem')
AddEventHandler('smarttaser:checkCartridgeItem', function()
    local src = source
    if not hasFramework or not GetPlayer then
        TriggerClientEvent('smarttaser:reloadTaser', src)
        return
    end

    local Player = GetPlayer(src)
    if not Player then return end

    local removed = false
    if Player.Functions then
        removed = Player.Functions.RemoveItem('taser_cartridge', 1)
    elseif Player.removeInventoryItem then
        local count = Player.getInventoryItem('taser_cartridge').count
        if count > 0 then
            Player.removeInventoryItem('taser_cartridge', 1)
            removed = true
        end
    end

    if removed then
        TriggerClientEvent('smarttaser:reloadTaser', src)
    else
        TriggerClientEvent('chat:addMessage', src, {args = {"Taser", "You have no taser cartridges!"}})
    end
end)