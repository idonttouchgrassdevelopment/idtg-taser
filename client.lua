-- Enhanced Smart Taser System with Custom Notification UI
-- Features: Fixed cooldowns, native UI with configurable background, configurable animations
-- NEW: Custom notification system matching taser UI style with improved spacing

local taserCartridges = Config.MaxCartridges
local lastTase = 0
local isReloading = false
local cooldownEndTime = 0
local showUI = false

-- Debug logging for timer verification
local function logTimerDebug(msg)
    -- Uncomment the line below to enable debug logging
    -- print("^2[TASER TIMER DEBUG]^7 " .. msg)
end

-- ============================================
-- UTILITY FUNCTIONS (Must be defined first)
-- ============================================

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

-- Draw rectangle
local function drawRect(x, y, width, height, r, g, b, a)
    DrawRect(x, y, width, height, r, g, b, a)
end

-- ============================================
-- SIMPLIFIED NOTIFICATION SYSTEM (Max 1 visible)
-- ============================================

local activeNotification = nil
local notificationQueue = {}

-- Show notification (simplified to 1 at a time)
local function showNotification(data)
    if not data or not Config.UI.notifications.enabled then return end
    
    local notification = {
        id = GetGameTimer(),
        title = data.title or "⚡ Smart Taser",
        description = data.description or "",
        type = data.type or "default",
        duration = Config.UI.notifications.duration,
        startTime = GetGameTimer(),
    }
    
    if activeNotification == nil then
        activeNotification = notification
    else
        table.insert(notificationQueue, notification)
    end
end

-- Draw single notification (toast-style)
local function drawNotification()
    if not activeNotification then return end
    
    local currentTime = GetGameTimer()
    local elapsed = currentTime - activeNotification.startTime
    local progress = 1 - (elapsed / activeNotification.duration)
    
    if progress <= 0 then
        activeNotification = nil
        if #notificationQueue > 0 then
            activeNotification = table.remove(notificationQueue, 1)
        end
        return
    end
    
    -- Parse colors based on type
    local colors = {success = {r = 76, g = 175, b = 80}, error = {r = 244, g = 67, b = 54}, warning = {r = 255, g = 152, b = 0}, inform = {r = 33, g = 150, b = 243}, default = {r = 0, g = 212, b = 255}}
    local color = colors[activeNotification.type] or colors.default
    local accentR, accentG, accentB = color.r, color.g, color.b
    
    -- Position based on config
    local notifConfig = Config.UI.notifications
    local xPos = 0.92
    local yPos = 0.08
    
    if notifConfig.position == "top-left" then
        xPos = 0.08
        yPos = 0.08
    elseif notifConfig.position == "bottom-left" then
        xPos = 0.08
        yPos = 0.92
    elseif notifConfig.position == "bottom-right" then
        xPos = 0.92
        yPos = 0.92
    end
    
    local width = notifConfig.width
    local height = notifConfig.height
    local themeConfig = Config.UI.theme
    
    -- Parse background color
    local bgR, bgG, bgB, bgA = parseRgba(themeConfig.colors.background)
    
    -- Draw notification background with accent border
    drawRect(xPos, yPos, width, height, bgR, bgG, bgB, bgA)
    drawRect(xPos - (width / 2) + 0.002, yPos, 0.004, height - 0.002, accentR, accentG, accentB, 255)
    
    -- Draw title
    SetTextFont(themeConfig.font)
    SetTextScale(0.36, 0.36)
    SetTextColour(accentR, accentG, accentB, 255)
    SetTextCentre(false)
    SetTextDropshadow(2, 0, 0, 0, 180)
    SetTextEntry("STRING")
    AddTextComponentString(activeNotification.title)
    DrawText(xPos - (width / 2) + 0.012, yPos - (height / 2) + 0.004)
    
    -- Draw description
    SetTextFont(themeConfig.font)
    SetTextScale(0.32, 0.32)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(false)
    SetTextDropshadow(2, 0, 0, 0, 180)
    SetTextEntry("STRING")
    AddTextComponentString(activeNotification.description)
    DrawText(xPos - (width / 2) + 0.012, yPos + (height / 2) - 0.024)
end

-- Notification render thread
CreateThread(function()
    while true do
        Wait(0)
        drawNotification()
    end
end)

-- ============================================
-- TASER UI SYSTEM (Enhanced with Better Spacing)
-- ============================================

-- Format time for display with configurable precision
local function formatTime(ms)
    if Config.Timers.preventNegative and ms < 0 then
        ms = 0
    end
    
    local precision = Config.Timers.cooldownPrecision or 1
    local seconds = ms / 1000
    local format = "%." .. precision .. "f"
    local timeStr = string.format(format, seconds)
    
    if Config.UI.taser.timerDisplay.showUnitLabel then
        timeStr = timeStr .. "s"
    end
    
    return timeStr
end

-- Get cartridge display string
local function getCartridgeDisplay(count, max)
    return string.format("%d/%d", count, max)
end

-- Draw the taser UI (Ultra-Compact Horizontal Bar)
local function drawTaserUI()
    if not showUI then return end
    
    -- Calculate cooldown status with safety checks
    local currentTime = GetGameTimer()
    local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)
    local isOnCooldown = cooldownRemaining > 0
    
    -- Get configuration
    local taserConfig = Config.UI.taser
    local themeConfig = Config.UI.theme
    local chargeConfig = taserConfig.chargeIndicator
    
    -- Parse colors
    local bgR, bgG, bgB, bgA = parseRgba(themeConfig.colors.background)
    local textR, textG, textB = hexToRgb(themeConfig.colors.text)
    local accentR, accentG, accentB = hexToRgb(themeConfig.colors.accent)
    
    -- Calculate screen position
    local xPos = 0.5
    local yPos = 0.5
    local width = taserConfig.dimensions.width
    local height = taserConfig.dimensions.height
    
    if taserConfig.position == "right-center" then
        xPos = 0.95 - (width / 2)
        yPos = 0.5
    elseif taserConfig.position == "left-center" then
        xPos = 0.08 + (width / 2)
        yPos = 0.5
    elseif taserConfig.position == "top-center" then
        xPos = 0.5
        yPos = 0.08 + (height / 2)
    elseif taserConfig.position == "top-right" then
        xPos = 0.92 - (width / 2)
        yPos = 0.08 + (height / 2)
    elseif taserConfig.position == "top-left" then
        xPos = 0.08 + (width / 2)
        yPos = 0.08 + (height / 2)
    elseif taserConfig.position == "bottom-center" then
        xPos = 0.5
        yPos = 0.92 - (height / 2)
    elseif taserConfig.position == "bottom-right" then
        xPos = 0.92 - (width / 2)
        yPos = 0.92 - (height / 2)
    elseif taserConfig.position == "bottom-left" then
        xPos = 0.08 + (width / 2)
        yPos = 0.92 - (height / 2)
    end
    
    -- Draw background bar
    drawRect(xPos, yPos, width, height, bgR, bgG, bgB, bgA)
    
    -- Draw modern glowing border effect with double border
    drawRect(xPos, yPos - (height / 2) - 0.001, width, 0.0025, accentR, accentG, accentB, 255) -- Top glow
    drawRect(xPos, yPos + (height / 2) + 0.001, width, 0.0025, accentR, accentG, accentB, 255) -- Bottom glow
    drawRect(xPos - (width / 2) - 0.001, yPos, 0.0025, height, accentR, accentG, accentB, 200) -- Left
    drawRect(xPos + (width / 2) + 0.001, yPos, 0.0025, height, accentR, accentG, accentB, 200) -- Right
    
    -- Add inner border for futuristic look
    drawRect(xPos, yPos - (height / 2) + 0.003, width, 0.001, accentR, accentG, accentB, 120) -- Inner top
    drawRect(xPos, yPos + (height / 2) - 0.003, width, 0.001, accentR, accentG, accentB, 120) -- Inner bottom
    
    -- Add enhanced outer glow for futuristic effect
    drawRect(xPos, yPos - (height / 2) - 0.003, width, 0.002, accentR, accentG, accentB, 60) -- Extended top glow
    drawRect(xPos, yPos + (height / 2) + 0.003, width, 0.002, accentR, accentG, accentB, 60) -- Extended bottom glow
    
    -- LEFT SECTION: Icon (Lightning Bolt) - Centered vertically, larger and futuristic
    local leftX = xPos - (width / 2) + 0.012
    if taserConfig.elements.icon then
        SetTextFont(themeConfig.font)
        SetTextScale(0.38, 0.38)  -- Slightly smaller for balance
        SetTextColour(accentR, accentG, accentB, 255)
        SetTextCentre(true)
        SetTextDropshadow(3, 0, 0, 0, 255)  -- Stronger shadow
        SetTextEntry("STRING")
        AddTextComponentString("⚡")
        DrawText(leftX, yPos - 0.016)  -- Centered in UI box
    end
    
    -- CENTER SECTION: Label - Modern futuristic style
    local centerX = xPos - 0.018
    if taserConfig.elements.label then
        SetTextFont(themeConfig.font)
        SetTextScale(0.36, 0.36)  -- Larger text size
        SetTextColour(textR, textG, textB, 255)
        SetTextCentre(true)
        SetTextDropshadow(3, 0, 0, 0, 255)  -- Stronger shadow for depth
        SetTextEntry("STRING")
        AddTextComponentString("Taser Cartridges")
        DrawText(centerX, yPos - 0.012)  -- Raised slightly higher
    end
    
    -- RIGHT SECTION: Charge Indicator Cells
    if taserConfig.elements.chargeIndicator then
        local cellWidth = chargeConfig.cellWidth
        local cellHeight = chargeConfig.cellHeight
        local cellSpacing = chargeConfig.cellSpacing
        local filledR, filledG, filledB = hexToRgb(chargeConfig.filledColor)
        local emptyR, emptyG, emptyB = hexToRgb(chargeConfig.emptyColor)
        local borderR, borderG, borderB, borderA = parseRgba(chargeConfig.borderColor)
        
        -- Calculate starting X position for cells (right side) - better spacing
        local totalCellWidth = (Config.MaxCartridges * cellWidth) + ((Config.MaxCartridges - 1) * cellSpacing)
        local cellStartX = xPos + (width / 2) - 0.012 - totalCellWidth
        
        -- Draw charge cells with futuristic styling
        for i = 1, Config.MaxCartridges do
            local cellX = cellStartX + ((i - 1) * (cellWidth + cellSpacing)) + (cellWidth / 2)
            local cellY = yPos
            
            -- Determine cell appearance based on charge status
            local cellR, cellG, cellB, cellA
            if i <= taserCartridges then
                -- Charged - full opacity with glow
                cellR, cellG, cellB, cellA = filledR, filledG, filledB, 255
            else
                -- Empty - reduced opacity (grayed out)
                cellR, cellG, cellB, cellA = emptyR, emptyG, emptyB, 80
            end
            
            -- Draw outer glow effect for charged cells
            if i <= taserCartridges then
                drawRect(cellX, cellY, cellWidth + 0.003, cellHeight + 0.003, cellR, cellG, cellB, 80)
            end
            
            -- Draw filled cell (core)
            drawRect(cellX, cellY, cellWidth, cellHeight, cellR, cellG, cellB, cellA)
            
            -- Draw cell border with adaptive glow (always visible)
            local borderA = i <= taserCartridges and 255 or 120
            drawRect(cellX, cellY - (cellHeight / 2), cellWidth, 0.002, borderR, borderG, borderB, borderA) -- Top
            drawRect(cellX, cellY + (cellHeight / 2), cellWidth, 0.002, borderR, borderG, borderB, borderA) -- Bottom
            drawRect(cellX - (cellWidth / 2), cellY, 0.002, cellHeight, borderR, borderG, borderB, borderA) -- Left
            drawRect(cellX + (cellWidth / 2), cellY, 0.002, cellHeight, borderR, borderG, borderB, borderA) -- Right
        end
    end
    
    -- COOLDOWN TIMER - Display centered between label and charge cells
    if isOnCooldown and taserConfig.elements.cooldownTimer then
        local timerX = xPos + 0.020
        local timerY = yPos - 0.008
        local timerText = formatTime(cooldownRemaining)
        
        -- Draw timer text only
        SetTextFont(themeConfig.font)
        SetTextScale(0.26, 0.26)  -- Smaller timer text
        SetTextColour(255, 255, 255, 255)  -- White text
        SetTextCentre(true)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEntry("STRING")
        AddTextComponentString(timerText)
        DrawText(timerX, timerY)
    end
end

-- Update UI state
local function updateUI()
    local ped = PlayerPedId()
    if GetSelectedPedWeapon(ped) ~= Config.TaserWeapon then
        showUI = false
        return
    end

    if Config.UI.taser.hideWhenNotAiming then
        if not IsPlayerFreeAiming(PlayerId()) then
            showUI = false
            return
        end
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

-- UI update thread - runs at configured interval for smooth rendering
CreateThread(function()
    local updateInterval = Config.Timers.updateInterval or 0
    while true do
        Wait(updateInterval)
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

-- ============================================
-- MAIN CONTROL THREAD (Updated with New Config)
-- ============================================

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        local notifConfig = Config.UI.notifications

        if weapon == Config.TaserWeapon then
            local currentTime = GetGameTimer()
            -- Ensure cooldown never goes negative
            local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)
            
            -- Disable firing if out of cartridges OR on cooldown
            if taserCartridges <= 0 or cooldownRemaining > 0 then
                DisablePlayerFiring(ped, true)
            end

            -- Check for taser trigger
            if IsControlJustPressed(0, 24) then
                if taserCartridges > 0 and cooldownRemaining == 0 then
                    -- Fire taser
                    taserCartridges = taserCartridges - 1
                    lastTase = currentTime
                    -- Set cooldown end time PRECISELY
                    cooldownEndTime = currentTime + Config.TaserCooldown
                    
                    logTimerDebug(string.format("FIRED | Current: %d | Cooldown End: %d | Duration: %dms", currentTime, cooldownEndTime, Config.TaserCooldown))
                    
                    -- Play sound effect
                    local coords = GetEntityCoords(ped)
                    PlaySoundFromCoord(-1, "ROCKET_REMOTE_YES", coords, "HUD_MINI_GAME_SOUNDSET", false, 0, false)
                    
                    TriggerServerEvent('smarttaser:logTaser', taserCartridges)

                    -- Check if we hit a player
                    local target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if DoesEntityExist(target) and IsPedAPlayer(target) then
                        TriggerServerEvent("smarttaser:stunPlayer", GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
                        
                        -- Show hit notification if enabled
                        if notifConfig.showOn.hit then
                            showNotification({ 
                                title = "⚡ Hit!", 
                                description = string.format("Target stunned! %s left", taserCartridges),
                                type = "success", 
                            })
                        end
                    else
                        -- Miss/no target
                        if notifConfig.showOn.miss then
                            showNotification({ 
                                title = "⚡ Fired!", 
                                description = string.format("%s cart remaining", taserCartridges),
                                type = "inform", 
                            })
                        end
                    end
                elseif taserCartridges <= 0 then
                    -- Out of cartridges
                    showNotification({ 
                        title = "⚡ No Ammo", 
                        description = "Press [R] to reload", 
                        type = "error", 
                    })
                elseif cooldownRemaining > 0 then
                    -- Still on cooldown - only show if enabled
                    if notifConfig.showOn.cooldown then
                        showNotification({ 
                            title = "⚡ Cooldown", 
                            description = formatTime(cooldownRemaining), 
                            type = "warning", 
                        })
                    end
                end
            end

            -- Check for reload key
            if IsControlJustReleased(0, Config.ReloadKey) then
                if isReloading then return end
                
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

    -- Wait for reload duration
    Wait(Config.ReloadTime)
    
    -- Clear animation
    ClearPedTasks(ped)
    
    -- Reload complete
    taserCartridges = Config.MaxCartridges
    
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

-- ============================================
-- DEBUG COMMANDS
-- ============================================

-- Test command: /testtaser to fire and verify timing
RegisterCommand('testtaser', function()
    TriggerEvent('chat:addMessage', {args = {"TASER", "Testing cooldown timer..."}})
    
    local testStart = GetGameTimer()
    cooldownEndTime = testStart + Config.TaserCooldown
    
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Cooldown set for %dms", Config.TaserCooldown)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Start: %d, End: %d", testStart, cooldownEndTime)}})
    
    -- Wait and display timer progress
    local checkThread = CreateThread(function()
        for i = 1, math.ceil(Config.TaserCooldown / 1000) do
            Wait(1000)
            local now = GetGameTimer()
            local remaining = math.max(0, cooldownEndTime - now)
            TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Remaining: %s", formatTime(remaining))}})
            if remaining <= 0 then break end
        end
        TriggerEvent('chat:addMessage', {args = {"TASER", "✓ Cooldown complete!"}})
    end)
end)

-- Test command: /taserconfig to show current config
RegisterCommand('taserconfig', function()
    TriggerEvent('chat:addMessage', {args = {"TASER", "=== CONFIG ==="}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Cooldown: %dms", Config.TaserCooldown)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Timer Precision: %d decimals", Config.Timers.cooldownPrecision)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Max Cartridges: %d", Config.MaxCartridges)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Stun Duration: %dms", Config.StunDuration)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Layout: %s", Config.UI.layout)}})
end)