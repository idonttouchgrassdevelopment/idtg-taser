-- Enhanced Smart Taser System
-- Features: Fixed cooldowns, native UI with configurable background, configurable animations

local taserCartridges = Config.MaxCartridges
local lastTase = 0
local isReloading = false
local cooldownEndTime = 0
local showUI = false

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

-- Parse hex color to RGB
local function hexToRgb(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
    end
    return 255, 255, 255
end

-- Parse rgba color
local function parseRgba(color)
    local r, g, b, a = 255, 255, 255, 255
    
    if color:sub(1, 1) == "#" then
        r, g, b = hexToRgb(color)
    elseif color:match("rgba?%(") then
        r, g, b, a = color:match("rgba?%((%d+),%s*(%d+),%s*(%d+)%.?(%d*)%)")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        if a then
            a = tonumber(a)
            if a <= 1 then a = a * 255 end
        else
            a = 255
        end
    end
    
    return r, g, b, a
end

-- Draw rectangle with rounded corners (simulated)
local function drawRect(x, y, width, height, r, g, b, a)
    DrawRect(x, y, width, height, r, g, b, a)
end

-- Draw text using native FiveM functions with enhanced styling
local function drawText(text, x, y, scale, r, g, b, a, font, shadow, outline)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(true)
    
    if shadow then
        SetTextDropshadow(2, 0, 0, 0, 200)
    else
        SetTextDropshadow(0, 0, 0, 0, 0)
    end
    
    if outline then
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextOutline()
    end
    
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Draw the taser UI with enhanced visuals and background
local function drawTaserUI()
    if not showUI then return end
    
    -- Calculate cooldown status
    local currentTime = GetGameTimer()
    local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)
    local isOnCooldown = cooldownRemaining > 0
    
    -- Calculate screen position based on Config.UI.position
    local xPos = 0.5
    local yPos = 0.5
    local width = 0.15
    local height = 0.12
    local xOffset = 0.0
    
    if Config.UI.position == "right-center" then
        xPos = 0.92 - (width / 2)
        yOffset = 0.5
    elseif Config.UI.position == "left-center" then
        xPos = 0.08 + (width / 2)
        yOffset = 0.5
    elseif Config.UI.position == "top-center" then
        xPos = 0.5
        yOffset = 0.08 + (height / 2)
    elseif Config.UI.position == "top-right" then
        xPos = 0.92 - (width / 2)
        yOffset = 0.08 + (height / 2)
    elseif Config.UI.position == "top-left" then
        xPos = 0.08 + (width / 2)
        yOffset = 0.08 + (height / 2)
    elseif Config.UI.position == "bottom-center" then
        xPos = 0.5
        yOffset = 0.92 - (height / 2)
    elseif Config.UI.position == "bottom-right" then
        xPos = 0.92 - (width / 2)
        yOffset = 0.92 - (height / 2)
    elseif Config.UI.position == "bottom-left" then
        xPos = 0.08 + (width / 2)
        yOffset = 0.92 - (height / 2)
    else
        xPos = 0.5
        yOffset = 0.5
    end
    
    -- Parse style colors from config
    local bgR, bgG, bgB, bgA = parseRgba(Config.UI.style.backgroundColor)
    local borderR, borderG, borderB, borderA = parseRgba(Config.UI.style.border)
    local textR, textG, textB = hexToRgb(Config.UI.style.color)
    
    -- Draw background
    drawRect(xPos, yPos, width, height, bgR, bgG, bgB, bgA)
    
    -- Draw border (simulated with outline)
    drawRect(xPos, yPos - (height / 2) + 0.002, width, 0.003, borderR, borderG, borderB, borderA) -- Top
    drawRect(xPos, yPos + (height / 2) - 0.002, width, 0.003, borderR, borderG, borderB, borderA) -- Bottom
    drawRect(xPos - (width / 2) + 0.002, yPos, 0.003, height, borderR, borderG, borderB, borderA) -- Left
    drawRect(xPos + (width / 2) - 0.002, yPos, 0.003, height, borderR, borderG, borderB, borderA) -- Right
    
    -- Draw title
    local titleY = yPos - (height / 2) + 0.025
    drawText("⚡ SMART TASER", xPos, titleY, 0.45, textR, textG, textB, 255, 4, true, true)
    
    -- Draw separator line
    local separatorY = yPos - (height / 2) + 0.045
    drawRect(xPos, separatorY, width - 0.02, 0.002, textR, textG, textB, 100)
    
    -- Draw charges
    local chargeY = yPos - (height / 2) + 0.065
    local chargeText = "Charges: " .. getCartridgeIcons(taserCartridges, Config.MaxCartridges)
    drawText(chargeText, xPos, chargeY, 0.4, 255, 255, 255, 255, 4, true, true)
    
    -- Draw cooldown bar if enabled
    if Config.UI.cooldownBar.enabled then
        local barY = yPos - (height / 2) + 0.085
        local barWidth = width - 0.04
        local barX = xPos
        local barHeight = 0.008
        
        -- Draw background bar
        local barBgR, barBgG, barBgB, barBgA = parseRgba(Config.UI.cooldownBar.backgroundColor)
        drawRect(barX, barY, barWidth, barHeight, barBgR, barBgG, barBgB, barBgA)
        
        -- Draw cooldown progress
        if isOnCooldown then
            local progress = 1 - (cooldownRemaining / Config.TaserCooldown)
            local barFgR, barFgG, barFgB = hexToRgb(Config.UI.cooldownBar.foregroundColor)
            drawRect(barX - (barWidth / 2) + (barWidth * progress / 2), barY, barWidth * progress, barHeight, barFgR, barFgG, barFgB, 255)
        elseif taserCartridges > 0 then
            -- Show full bar when ready
            local barFgR, barFgG, barFgB = 76, 175, 80 -- Green
            drawRect(barX, barY, barWidth, barHeight, barFgR, barFgG, barFgB, 255)
        end
    end
    
    -- Draw status text at bottom
    local statusY = yPos + (height / 2) - 0.02
    if isOnCooldown then
        drawText("🤒 Cooldown: " .. formatTime(cooldownRemaining), xPos, statusY, 0.35, 255, 152, 0, 255, 4, true, true)
    elseif taserCartridges == 0 then
        drawText("⚠️ RELOAD REQUIRED", xPos, statusY, 0.35, 244, 67, 54, 255, 4, true, true)
    else
        drawText("✓ READY", xPos, statusY, 0.35, 76, 175, 80, 255, 4, true, true)
    end
end

-- Update UI state
local function updateUI()
    local ped = PlayerPedId()
    if GetSelectedPedWeapon(ped) ~= Config.TaserWeapon then
        showUI = false
        return
    end

    if not IsPlayerFreeAiming(PlayerId()) then
        showUI = false
        return
    end
    
    showUI = true
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

-- UI drawing thread - runs every frame
CreateThread(function()
    while true do
        Wait(0)
        drawTaserUI()
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
                        description = string.format("🤒 Cooldown active! %s remaining", formatTime(cooldownRemaining)), 
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
    
    -- Hide UI during reload
    showUI = false

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