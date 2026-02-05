-- Enhanced Smart Taser System
-- Features: Fixed cooldowns, professional UI, configurable animations

local taserCartridges = Config.MaxCartridges
local lastTase = 0
local isReloading = false
local cooldownEndTime = 0

-- Format time for display
local function formatTime(ms)
    local seconds = math.ceil(ms / 1000)
    return string.format("%.1fs", ms / 1000)
end

-- Generate cartridge icons string
local function getCartridgeIcons(count, max)
    if not Config.UI.icons.enabled then
        return string.format("%d/%d", count, max)
    end
    
    local icons = ""
    for i = 1, max do
        if i <= count then
            icons = icons .. Config.UI.icons.filled
        else
            icons = icons .. Config.UI.icons.empty
        end
    end
    return icons
end

-- Update UI with enhanced styling and cooldown bar
local function updateUI()
    local ped = PlayerPedId()
    if GetSelectedPedWeapon(ped) ~= Config.TaserWeapon then
        lib.hideTextUI()
        return
    end

    if not IsPlayerFreeAiming(PlayerId()) then
        lib.hideTextUI()
        return
    end

    -- Calculate cooldown status
    local currentTime = GetGameTimer()
    local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)
    local isOnCooldown = cooldownRemaining > 0

    -- Build main UI text
    local mainText = string.format("Taser Charges\n%s", getCartridgeIcons(taserCartridges, Config.MaxCartridges))
    
    -- Add cooldown indicator if active
    if isOnCooldown then
        mainText = mainText .. string.format("\n🔄 Cooldown: %s", formatTime(cooldownRemaining))
    elseif taserCartridges == 0 then
        mainText = mainText .. "\n⚠️ RELOAD REQUIRED"
    end

    -- Show main UI
    lib.showTextUI(mainText, {
        position = Config.UI.position,
        icon = "bolt",
        style = Config.UI.style
    })
end

-- Hide weapon HUD when taser is equipped
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if GetSelectedPedWeapon(ped) == Config.TaserWeapon then
            HideHudComponentThisFrame(2) -- weapon icon
            HideHudComponentThisFrame(7) -- area name
            HideHudComponentThisFrame(9) -- street name
            HideHudComponentThisFrame(20) -- weapon ammo
        end
    end
end)

-- UI update thread - runs every 100ms for smooth animations
CreateThread(function()
    while true do
        Wait(100)
        updateUI()
    end
end)

-- Main control thread
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weapon == Config.TaserWeapon then
            local currentTime = GetGameTimer()
            local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)
            
            -- Disable firing if out of cartridges OR on cooldown
            if taserCartridges <= 0 or cooldownRemaining > 0 then
                DisablePlayerFiring(ped, true)
            end

            -- Check for taser trigger (using IsControlJustPressed instead of Released)
            if IsControlJustPressed(0, 24) then
                if taserCartridges > 0 and cooldownRemaining == 0 then
                    -- Fire taser
                    taserCartridges = taserCartridges - 1
                    lastTase = currentTime
                    cooldownEndTime = currentTime + Config.TaserCooldown
                    
                    -- Play sound effect
                    local coords = GetEntityCoords(ped)
                    PlaySoundFromCoord(-1, "ROCKET_REMOTE_YES", coords, "HUD_MINI_GAME_SOUNDSET", false, 0, false)
                    
                    TriggerServerEvent('smarttaser:logTaser', taserCartridges)

                    -- Check if we hit a player
                    local target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if DoesEntityExist(target) and IsPedAPlayer(target) then
                        TriggerServerEvent("smarttaser:stunPlayer", GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
                        
                        -- Success notification
                        lib.notify({ 
                            title = "⚡ Smart Taser", 
                            description = string.format("Target stunned! %s cartridges remaining", taserCartridges),
                            type = "success", 
                            duration = 3000 
                        })
                    else
                        -- Miss notification
                        lib.notify({ 
                            title = "⚡ Smart Taser", 
                            description = string.format("Shot fired! %s cartridges remaining", taserCartridges),
                            type = "inform", 
                            duration = 2000 
                        })
                    end
                elseif taserCartridges <= 0 then
                    -- Out of cartridges
                    lib.notify({ 
                        title = "⚡ Smart Taser", 
                        description = "⚠️ No cartridges left! Press [R] to reload.", 
                        type = "error", 
                        duration = 5000 
                    })
                elseif cooldownRemaining > 0 then
                    -- Still on cooldown
                    lib.notify({ 
                        title = "⚡ Smart Taser", 
                        description = string.format("🔄 Cooldown active! %s remaining", formatTime(cooldownRemaining)), 
                        type = "warning", 
                        duration = 2000 
                    })
                end
            end

            -- Check for reload key
            if IsControlJustReleased(0, Config.ReloadKey) then
                if isReloading then return end
                
                if taserCartridges >= Config.MaxCartridges then
                    lib.notify({ 
                        title = "⚡ Smart Taser", 
                        description = "🔋 Taser is already fully charged!", 
                        type = "success", 
                        duration = 3000 
                    })
                    return
                end
                
                TriggerServerEvent('smarttaser:checkCartridgeItem')
            end
        end
    end
end)

-- Reload event with configurable animation
RegisterNetEvent('smarttaser:reloadTaser')
AddEventHandler('smarttaser:reloadTaser', function()
    if isReloading then return end
    
    local ped = PlayerPedId()
    isReloading = true
    
    -- Hide UI during reload to prevent conflicts
    lib.hideTextUI()

    -- Request the animation dict from config
    RequestAnimDict(Config.ReloadAnimation.dict)
    local timeout = 1000
    local startTime = GetGameTimer()
    
    while not HasAnimDictLoaded(Config.ReloadAnimation.dict) do
        Wait(0)
        if GetGameTimer() - startTime > timeout then
            print("Failed to load animation dict: " .. Config.ReloadAnimation.dict)
            isReloading = false
            return
        end
    end

    -- Play the configured reload animation
    if HasAnimDictLoaded(Config.ReloadAnimation.dict) then
        TaskPlayAnim(
            ped, 
            Config.ReloadAnimation.dict, 
            Config.ReloadAnimation.anim, 
            8.0, 
            -8.0, 
            Config.ReloadTime, 
            Config.ReloadAnimation.flags, 
            0, 
            false, 
            false, 
            false
        )
    end

    -- Play reload sound
    local coords = GetEntityCoords(ped)
    PlaySoundFromCoord(-1, "MG_RELOAD", coords, "MP_WEAPONS_SOUNDSET", false, 0, false)

    -- Wait for reload duration with simple timer (no progress bar to avoid conflicts)
    Wait(Config.ReloadTime)
    
    -- Clear animation
    ClearPedTasks(ped)
    
    -- Reload complete
    taserCartridges = Config.MaxCartridges
    
    lib.notify({ 
        title = "⚡ Smart Taser", 
        description = "🔋 Taser reloaded and ready!", 
        type = "success", 
        duration = 4000 
    })
    
    isReloading = false
end)

-- Stun effect event
RegisterNetEvent('smarttaser:applyStun')
AddEventHandler('smarttaser:applyStun', function()
    local ped = PlayerPedId()
    
    -- Play taser hit animation/sound
    PlaySoundFromEntity(-1, "ROCKET_REMOTE_YES", ped, "HUD_MINI_GAME_SOUNDSET", false, 0)
    
    -- Apply ragdoll effect
    SetPedToRagdoll(ped, Config.StunDuration, Config.StunDuration, 0, false, false, false)
end)

-- Initialize cartridges on resource start
CreateThread(function()
    Wait(1000)
    taserCartridges = Config.MaxCartridges
end)