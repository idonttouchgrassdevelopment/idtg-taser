-- Professional Smart Taser System - Clean UI Implementation
-- Features: Modern neon UI, cooldown timer, charge indicator, reload system

-- State variables
local taserCartridges = Config.MaxCartridges
local lastTase = 0
local isReloading = false
local cooldownEndTime = 0
local showUI = false
local reloadStartTime = 0
local reloadProgress = 0
local safetyOn = Config.Safety and Config.Safety.defaultOn or false
local lastSafetyToggle = 0
local nuiVisible = false

-- ============================================
-- UTILITY FUNCTIONS
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

-- Format time for display
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

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================

local activeNotification = nil
local notificationQueue = {}

-- Show notification (DISABLED)
local function showNotification(data)
    return  -- Notifications disabled
end

-- Draw single notification
local function drawNotification()
    if not activeNotification then return end

    local currentTime = GetGameTimer()
    local elapsed = currentTime - activeNotification.startTime
    local progress = 1 - (elapsed / activeNotification.duration)

    -- Check if notification expired
    if progress <= 0 then
        activeNotification = nil
        if #notificationQueue > 0 then
            activeNotification = table.remove(notificationQueue, 1)
        end
        return
    end

    -- Parse colors based on type
    local colors = {
        success = {r = 76, g = 175, b = 80},
        error = {r = 244, g = 67, b = 54},
        warning = {r = 255, g = 152, b = 0},
        inform = {r = 33, g = 150, b = 243},
        default = {r = 0, g = 212, b = 255}
    }
    local color = colors[activeNotification.type] or colors.default
    local accentR, accentG, accentB = color.r, color.g, color.b

    -- Position based on config
    local notifConfig = Config.UI.notifications
    local baseX = 0.92
    local baseY = 0.08

    if notifConfig.position == "top-left" then
        baseX = 0.08
        baseY = 0.08
    elseif notifConfig.position == "bottom-left" then
        baseX = 0.08
        baseY = 0.92
    elseif notifConfig.position == "bottom-right" then
        baseX = 0.92
        baseY = 0.92
    end

    local xPos = baseX
    local yPos = baseY
    local width = notifConfig.width
    local height = notifConfig.height
    local themeConfig = Config.UI.theme

    -- Parse background color
    local bgR, bgG, bgB, bgA = parseRgba(themeConfig.colors.background)

    -- Draw notification background
    drawRect(xPos, yPos, width, height, bgR, bgG, bgB, bgA)

    -- Draw gradient overlay
    drawRect(xPos, yPos, width, height * 0.3, accentR, accentG, accentB, 15)

    -- Draw animated accent border with glow
    drawRect(xPos - (width / 2) + 0.002, yPos, 0.0035, height - 0.001, accentR, accentG, accentB, 255)
    drawRect(xPos - (width / 2) + 0.002, yPos, 0.008, height - 0.001, accentR, accentG, accentB, 60)

    -- Draw corner accents
    local cornerSize = 0.006
    drawRect(xPos - (width / 2) + cornerSize, yPos - (height / 2) + 0.001, cornerSize * 2, 0.0015, accentR, accentG, accentB, 200)
    drawRect(xPos - (width / 2) + 0.001, yPos - (height / 2) + cornerSize, 0.0015, cornerSize * 2, accentR, accentG, accentB, 200)

    -- Draw title
    SetTextFont(themeConfig.font)
    SetTextScale(0.38, 0.38)
    SetTextColour(accentR, accentG, accentB, 255)
    SetTextCentre(false)
    SetTextDropshadow(2, accentR, accentG, accentB, 150)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(activeNotification.title)
    DrawText(xPos - (width / 2) + 0.015, yPos - (height / 2) + 0.005)

    -- Draw description
    SetTextFont(themeConfig.font)
    SetTextScale(0.32, 0.32)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(false)
    SetTextDropshadow(2, 0, 0, 0, 180)
    SetTextEntry("STRING")
    AddTextComponentString(activeNotification.description)
    DrawText(xPos - (width / 2) + 0.015, yPos + (height / 2) - 0.025)

    -- Draw progress bar at bottom
    local progressWidth = width * progress
    local progressY = yPos + (height / 2) - 0.001
    drawRect(xPos - (width / 2) + (progressWidth / 2), progressY, progressWidth, 0.002, accentR, accentG, accentB, 255)
    drawRect(xPos - (width / 2) + (progressWidth / 2), progressY, progressWidth, 0.004, accentR, accentG, accentB, 100)
end

-- Notification render thread
CreateThread(function()
    while true do
        Wait(0)
        drawNotification()
    end
end)

-- ============================================
-- TASER UI RENDERING
-- ============================================

-- Draw the main taser interface
local function drawTaserUI()
    local currentTime = GetGameTimer()
    local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)
    local isOnCooldown = cooldownRemaining > 0

    if isReloading then
        reloadProgress = math.min(1.0, (currentTime - reloadStartTime) / Config.ReloadTime)
    else
        reloadProgress = 0
    end

    if not showUI then
        if nuiVisible then
            SendNUIMessage({ action = 'setVisible', visible = false })
            nuiVisible = false
        end
        return
    end

    if not nuiVisible then
        SendNUIMessage({ action = 'setVisible', visible = true })
        nuiVisible = true
    end

    local status = 'Ready'
    if isReloading then
        status = 'Reloading'
    elseif safetyOn then
        status = 'Safe'
    elseif taserCartridges <= 0 then
        status = 'Empty'
    elseif isOnCooldown then
        status = 'Charging'
    end

    SendNUIMessage({
        action = 'update',
        cartridges = taserCartridges,
        maxCartridges = Config.MaxCartridges,
        cooldown = cooldownRemaining,
        cooldownText = formatTime(cooldownRemaining),
        showCooldown = isOnCooldown and not isReloading and not safetyOn,
        status = status,
        ready = (not isReloading and not safetyOn and taserCartridges > 0 and not isOnCooldown),
        isReloading = isReloading,
        reloadProgress = reloadProgress,
        safetyOn = safetyOn
    })

    -- Get configuration
    local taserConfig = Config.UI.taser
    local themeConfig = Config.UI.theme
    local chargeConfig = taserConfig.chargeIndicator

    -- Parse colors - Enhanced neon theme for weapon lock style
    local bgR, bgG, bgB, bgA = parseRgba("rgba(8, 12, 20, 245)")
    local accentR, accentG, accentB = hexToRgb("#00d4ff")
    local innerR, innerG, innerB, innerA = parseRgba("rgba(14, 20, 32, 240)")
    local shadowR, shadowG, shadowB, shadowA = parseRgba("rgba(0, 0, 0, 150)")
    local glowR, glowG, glowB, glowA = parseRgba("rgba(0, 212, 255, 30)")
    local titleR, titleG, titleB, titleA = parseRgba("rgba(200, 235, 255, 255)")
    local subtitleR, subtitleG, subtitleB, subtitleA = parseRgba("rgba(140, 175, 200, 220)")
    local iconR, iconG, iconB, iconA = parseRgba("rgba(0, 212, 255, 255)")
    local iconSubR, iconSubG, iconSubB, iconSubA = parseRgba("rgba(100, 150, 180, 200)")
    local statusBgR, statusBgG, statusBgB, statusBgA = parseRgba("rgba(10, 16, 26, 240)")
    local timerR, timerG, timerB, timerA = parseRgba("rgba(180, 220, 255, 255)")
    local reloadRailR, reloadRailG, reloadRailB, reloadRailA = parseRgba("rgba(20, 28, 40, 230)")
    local readyR, readyG, readyB = hexToRgb("#00ff88")
    local reloadingR, reloadingG, reloadingB = hexToRgb("#ffcc00")
    local emptyR, emptyG, emptyB = hexToRgb("#ff4444")
    local cooldownR, cooldownG, cooldownB = hexToRgb("#00d4ff")

    -- Calculate screen position - Right-center as requested
    local xPos = 0.925
    local yPos = 0.5
    local width = taserConfig.dimensions.width
    local height = taserConfig.dimensions.height

    local halfW = width / 2
    local halfH = height / 2

    -- Enhanced glow effect with layered shadows
    drawRect(xPos + 0.003, yPos + 0.003, width + 0.008, height + 0.008, accentR, accentG, accentB, 25)
    drawRect(xPos, yPos + 0.003, width + 0.004, height + 0.004, shadowR, shadowG, shadowB, shadowA)
    drawRect(xPos, yPos, width, height, bgR, bgG, bgB, bgA)
    drawRect(xPos, yPos, width - 0.003, height - 0.006, innerR, innerG, innerB, innerA)

    -- Top accent bar with gradient effect
    drawRect(xPos, yPos - halfH + 0.0015, width - 0.003, 0.0028, accentR, accentG, accentB, 255)
    drawRect(xPos, yPos - halfH + 0.0015, width - 0.003, 0.006, accentR, accentG, accentB, 60)

    -- Zone widths
    local leftZoneWidth = 0.035
    local rightZoneWidth = 0.068
    local centerZoneWidth = width - leftZoneWidth - rightZoneWidth - 0.015

    -- Enhanced dividers with glow
    drawRect(xPos - halfW + leftZoneWidth, yPos, 0.0015, height - 0.012, accentR, accentG, accentB, 120)
    drawRect(xPos - halfW + leftZoneWidth, yPos, 0.003, height - 0.012, accentR, accentG, accentB, 40)
    drawRect(xPos + halfW - rightZoneWidth, yPos, 0.0015, height - 0.012, accentR, accentG, accentB, 120)
    drawRect(xPos + halfW - rightZoneWidth, yPos, 0.003, height - 0.012, accentR, accentG, accentB, 40)

    -- LEFT SECTION: Enhanced icon block with glow
    if taserConfig.elements.icon then
        local boltY = yPos - 0.012

        -- Icon glow effect
        drawRect(xPos - halfW + 0.016, boltY, 0.028, 0.028, accentR, accentG, accentB, 40)

        SetTextFont(themeConfig.font)
        SetTextScale(0.46, 0.46)
        SetTextColour(iconR, iconG, iconB, iconA)
        SetTextCentre(true)
        SetTextDropshadow(2, 0, 0, 0, 180)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString("⚡")
        DrawText(xPos - halfW + 0.016, boltY)

        SetTextFont(themeConfig.font)
        SetTextScale(0.18, 0.18)
        SetTextColour(iconSubR, iconSubG, iconSubB, iconSubA)
        SetTextCentre(true)
        SetTextDropshadow(1, 0, 0, 0, 150)
        SetTextEntry("STRING")
        AddTextComponentString("26")
        DrawText(xPos - halfW + 0.016, boltY + 0.020)
    end

    -- CENTER SECTION: Enhanced status display
    if taserConfig.elements.label then
        local centerTextX = xPos - (centerZoneWidth / 2) + 0.060
        local titleText = "SMART TASER"
        local stateText = "READY"
        local stateR, stateG, stateB = readyR, readyG, readyB
        local helperText = "SYSTEM ACTIVE"

        if isReloading then
            stateText = "RELOADING"
            helperText = "INSERTING CARTRIDGE"
            stateR, stateG, stateB = reloadingR, reloadingG, reloadingB
        elseif safetyOn then
            stateText = "SAFE"
            helperText = "SAFETY ENABLED"
            stateR, stateG, stateB = cooldownR, cooldownG, cooldownB
        elseif taserCartridges <= 0 then
            stateText = "EMPTY"
            helperText = "PRESS R TO RELOAD"
            stateR, stateG, stateB = emptyR, emptyG, emptyB
        elseif isOnCooldown then
            stateText = "CHARGING"
            helperText = "CAPACITOR RECHARGING"
            stateR, stateG, stateB = cooldownR, cooldownG, cooldownB
        end

        -- Title with glow
        SetTextFont(themeConfig.font)
        SetTextScale(0.32, 0.32)
        SetTextColour(titleR, titleG, titleB, titleA)
        SetTextCentre(false)
        SetTextDropshadow(1, 0, 0, 0, 180)
        SetTextEntry("STRING")
        AddTextComponentString(titleText)
        DrawText(centerTextX - 0.040, yPos - 0.015)

        -- Subtitle
        SetTextFont(themeConfig.font)
        SetTextScale(0.21, 0.21)
        SetTextColour(subtitleR, subtitleG, subtitleB, subtitleA)
        SetTextCentre(false)
        SetTextEntry("STRING")
        AddTextComponentString(helperText)
        DrawText(centerTextX - 0.040, yPos + 0.004)

        -- Enhanced status capsule
        drawRect(centerTextX + 0.025, yPos + 0.011, 0.055, 0.016, statusBgR, statusBgG, statusBgB, statusBgA)

        -- Status indicator bar with glow
        drawRect(centerTextX + 0.025, yPos + 0.011, 0.053, 0.003, stateR, stateG, stateB, 255)
        drawRect(centerTextX + 0.025, yPos + 0.011, 0.053, 0.005, stateR, stateG, stateB, 50)

        SetTextFont(themeConfig.font)
        SetTextScale(0.24, 0.24)
        SetTextColour(stateR, stateG, stateB, 255)
        SetTextCentre(true)
        SetTextDropshadow(1, 0, 0, 0, 150)
        SetTextEntry("STRING")
        AddTextComponentString(stateText)
        DrawText(centerTextX + 0.025, yPos + 0.006)

        -- Timer with enhanced styling
        if isOnCooldown and not isReloading and not safetyOn then
            SetTextFont(themeConfig.font)
            SetTextScale(0.22, 0.22)
            SetTextColour(timerR, timerG, timerB, timerA)
            SetTextCentre(true)
            SetTextDropshadow(1, 0, 0, 0, 160)
            SetTextEntry("STRING")
            AddTextComponentString(formatTime(cooldownRemaining))
            DrawText(centerTextX + 0.058, yPos + 0.006)
        end
    end

    -- RIGHT SECTION: Enhanced charge indicator
    if taserConfig.elements.chargeIndicator then
        local cellWidth = chargeConfig.cellWidth
        local cellHeight = chargeConfig.cellHeight
        local cellSpacing = chargeConfig.cellSpacing
        local filledR, filledG, filledB = hexToRgb(chargeConfig.filledColor)
        local emptyR, emptyG, emptyB = hexToRgb(chargeConfig.emptyColor)

        local totalCellWidth = (Config.MaxCartridges * cellWidth) + ((Config.MaxCartridges - 1) * cellSpacing)
        local cellStartX = xPos + halfW - 0.012 - totalCellWidth

        for i = 1, Config.MaxCartridges do
            local cellX = cellStartX + ((i - 1) * (cellWidth + cellSpacing)) + (cellWidth / 2)
            local cellY = yPos
            local active = i <= taserCartridges

            local baseR = active and filledR or emptyR
            local baseG = active and filledG or emptyG
            local baseB = active and filledB or emptyB
            local fillA = active and 245 or 60

            -- Enhanced glow effect for active cells
            if active then
                drawRect(cellX, cellY, cellWidth + 0.005, cellHeight + 0.005, baseR, baseG, baseB, 80)
                drawRect(cellX, cellY, cellWidth + 0.008, cellHeight + 0.008, baseR, baseG, baseB, 30)
            end
            drawRect(cellX, cellY, cellWidth, cellHeight, baseR, baseG, baseB, fillA)

            -- Enhanced highlight strip
            if active then
                drawRect(cellX - 0.0018, cellY - (cellHeight * 0.16), cellWidth * 0.48, cellHeight * 0.20, 255, 255, 255, 100)
            end
        end
    end

    -- Enhanced reload progress rail
    if isReloading then
        local railWidth = width - 0.020
        local railX = xPos
        local railY = yPos + halfH + 0.009
        local fillWidth = railWidth * reloadProgress

        drawRect(railX, railY, railWidth, 0.0042, reloadRailR, reloadRailG, reloadRailB, reloadRailA)
        if fillWidth > 0 then
            drawRect(railX - (railWidth / 2) + (fillWidth / 2), railY, fillWidth, 0.0042, accentR, accentG, accentB, 255)
            drawRect(railX - (railWidth / 2) + (fillWidth / 2), railY, fillWidth, 0.0075, accentR, accentG, accentB, 60)
        end
    end
end

-- ============================================
-- UI THREADS
-- ============================================

-- Update UI visibility state
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
            HideHudComponentThisFrame(2)  -- weapon icon
            HideHudComponentThisFrame(7)  -- area name
            HideHudComponentThisFrame(9)  -- street name
            HideHudComponentThisFrame(20) -- weapon ammo
        end
    end
end)

-- UI state update thread
CreateThread(function()
    local updateInterval = Config.Timers.updateInterval or 0
    while true do
        Wait(updateInterval)
        updateUI()
    end
end)

-- UI rendering thread
CreateThread(function()
    while true do
        Wait(0)
        drawTaserUI()
    end
end)

-- ============================================
-- MAIN CONTROL THREAD
-- ============================================

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        local notifConfig = Config.UI.notifications

        if weapon == Config.TaserWeapon then
            local currentTime = GetGameTimer()
            local cooldownRemaining = math.max(0, cooldownEndTime - currentTime)

            if Config.Safety and Config.Safety.enabled and IsControlJustReleased(0, Config.Safety.toggleKey) then
                if currentTime - lastSafetyToggle >= (Config.Safety.toggleDebounce or 250) then
                    safetyOn = not safetyOn
                    lastSafetyToggle = currentTime
                end
            end

            -- Disable firing if out of cartridges, on cooldown, reloading, or safety enabled
            if taserCartridges <= 0 or cooldownRemaining > 0 or isReloading or safetyOn then
                DisablePlayerFiring(ped, true)
            end

            -- Taser fire control
            if IsControlJustPressed(0, 24) then
                if safetyOn then
                    showNotification({
                        title = "⚡ Safety",
                        description = "Safety is ON (press [K])",
                        type = "warning",
                    })
                elseif taserCartridges > 0 and cooldownRemaining == 0 then
                    -- Fire taser
                    taserCartridges = taserCartridges - 1
                    lastTase = currentTime
                    cooldownEndTime = currentTime + Config.TaserCooldown

                    -- Play sound effect
                    local coords = GetEntityCoords(ped)
                    PlaySoundFromCoord(-1, "ROCKET_REMOTE_YES", coords, "HUD_MINI_GAME_SOUNDSET", false, 0, false)

                    TriggerServerEvent('smarttaser:logTaser', taserCartridges)

                    -- Check if we hit a player
                    local hit, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if hit and DoesEntityExist(target) and IsPedAPlayer(target) then
                        TriggerServerEvent("smarttaser:stunPlayer", GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))

                        if notifConfig.showOn.hit then
                            showNotification({
                                title = "⚡ Hit!",
                                description = string.format("Target stunned! %s left", taserCartridges),
                                type = "success",
                            })
                        end
                    else
                        if notifConfig.showOn.miss then
                            showNotification({
                                title = "⚡ Fired!",
                                description = string.format("%s cart remaining", taserCartridges),
                                type = "inform",
                            })
                        end
                    end
                elseif taserCartridges <= 0 then
                    showNotification({
                        title = "⚡ No Ammo",
                        description = "Press [R] to reload",
                        type = "error",
                    })
                elseif cooldownRemaining > 0 then
                    if notifConfig.showOn.cooldown then
                        showNotification({
                            title = "⚡ Cooldown",
                            description = formatTime(cooldownRemaining),
                            type = "warning",
                        })
                    end
                end
            end

            -- Reload control
            if IsControlJustReleased(0, Config.ReloadKey) then
                if not isReloading then
                    TriggerServerEvent('smarttaser:checkCartridgeItem')
                end
            end
        end
    end
end)

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Reload event
RegisterNetEvent('smarttaser:reloadTaser')
AddEventHandler('smarttaser:reloadTaser', function()
    if isReloading then return end

    local ped = PlayerPedId()
    isReloading = true
    reloadStartTime = GetGameTimer()
    showUI = true

    -- Load animation dictionary
    RequestAnimDict(Config.ReloadAnimation.dict)
    local timeout = 1000
    local startTime = GetGameTimer()

    while not HasAnimDictLoaded(Config.ReloadAnimation.dict) do
        Wait(0)
        if GetGameTimer() - startTime > timeout then
            print("Failed to load animation dict: " .. Config.ReloadAnimation.dict)
            isReloading = false
            TriggerServerEvent('smarttaser:reloadComplete')
            return
        end
    end

    -- Play reload animation
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

    -- Wait for reload to complete
    Wait(Config.ReloadTime)
    ClearPedTasks(ped)

    -- Reload complete
    taserCartridges = Config.MaxCartridges
    isReloading = false

    TriggerServerEvent('smarttaser:reloadComplete')

    if Config.UI.notifications.showOn.reload then
        showNotification({
            title = "⚡ Reloaded",
            description = string.format("Ready to fire! %d cartridges", taserCartridges),
            type = "success",
        })
    end
end)

-- Stun effect event
RegisterNetEvent('smarttaser:applyStun')
AddEventHandler('smarttaser:applyStun', function()
    local ped = PlayerPedId()

    -- Play taser hit sound
    PlaySoundFromEntity(-1, "ROCKET_REMOTE_YES", ped, "HUD_MINI_GAME_SOUNDSET", false, 0)

    -- Apply ragdoll effect
    SetPedToRagdoll(ped, Config.StunDuration, Config.StunDuration, 0, false, false, false)
end)

-- Initialize cartridges on resource start
CreateThread(function()
    Wait(1000)
    taserCartridges = Config.MaxCartridges
    safetyOn = Config.Safety and Config.Safety.defaultOn or false
end)

-- ============================================
-- DEBUG COMMANDS
-- ============================================

-- Test cooldown timer
RegisterCommand('testtaser', function()
    TriggerEvent('chat:addMessage', {args = {"TASER", "Testing cooldown timer..."}})

    local testStart = GetGameTimer()
    cooldownEndTime = testStart + Config.TaserCooldown

    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Cooldown set for %dms", Config.TaserCooldown)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Start: %d, End: %d", testStart, cooldownEndTime)}})

    -- Monitor timer progress
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

-- Show current config
RegisterCommand('taserconfig', function()
    TriggerEvent('chat:addMessage', {args = {"TASER", "=== CONFIG ==="}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Cooldown: %dms", Config.TaserCooldown)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Timer Precision: %d decimals", Config.Timers.cooldownPrecision)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Max Cartridges: %d", Config.MaxCartridges)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Stun Duration: %dms", Config.StunDuration)}})
    TriggerEvent('chat:addMessage', {args = {"TASER", string.format("Layout: %s", Config.UI.layout)}})
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SendNUIMessage({ action = 'setVisible', visible = false })
    end
end)
