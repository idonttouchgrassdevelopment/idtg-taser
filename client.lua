-- Enhanced Smart Taser System with Custom Notification UI
-- Features: Fixed cooldowns, native UI with configurable background, configurable animations
-- NEW: Custom notification system matching taser UI style with improved spacing

local taserCartridges = Config.MaxCartridges
local lastTase = 0
local isReloading = false
local cooldownEndTime = 0
local showUI = false
local reloadStartTime = 0
local reloadProgress = 0

-- Animation state for UI elements
local animationStates = {
    pulseIntensity = 0,
    pulseDirection = 1,
    glowIntensity = 0,
    slideIn = 0,
}

-- Debug logging for timer verification
local function logTimerDebug(msg)
    -- Uncomment the line below to enable debug logging
    -- print("^2[TASER TIMER DEBUG]^7 " .. msg)
end

-- ============================================
-- ANIMATION & VISUAL EFFECT FUNCTIONS
-- ============================================

-- Update animation states
local function updateAnimations()
    -- Pulsing effect for charge indicators
    animationStates.pulseIntensity = animationStates.pulseIntensity + (0.03 * animationStates.pulseDirection)
    if animationStates.pulseIntensity >= 1 then
        animationStates.pulseIntensity = 1
        animationStates.pulseDirection = -1
    elseif animationStates.pulseIntensity <= 0 then
        animationStates.pulseIntensity = 0
        animationStates.pulseDirection = 1
    end
    
    -- Glow intensity based on reload
    if isReloading then
        local reloadElapsed = GetGameTimer() - reloadStartTime
        reloadProgress = math.min(1, reloadElapsed / Config.ReloadTime)
        animationStates.glowIntensity = 0.5 + (math.sin(reloadElapsed * 0.01) * 0.3)
    else
        reloadProgress = 0
        animationStates.glowIntensity = 0.3 + (math.sin(GetGameTimer() * 0.003) * 0.1)
    end
    
    -- Slide in animation
    if showUI and animationStates.slideIn < 1 then
        animationStates.slideIn = math.min(1, animationStates.slideIn + 0.08)
    elseif not showUI and animationStates.slideIn > 0 then
        animationStates.slideIn = math.max(0, animationStates.slideIn - 0.12)
    end
end

-- Ease out cubic for smooth animations
local function easeOutCubic(t)
    t = math.max(0, math.min(1, t))
    return 1 - math.pow(1 - t, 3)
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

-- Draw single notification (enhanced with animations)
local function drawNotification()
    if not activeNotification then return end
    
    local currentTime = GetGameTimer()
    local elapsed = currentTime - activeNotification.startTime
    local progress = 1 - (elapsed / activeNotification.duration)
    
    -- Slide in/out animation
    local slideProgress = 1
    if elapsed < 300 then
        slideProgress = easeOutCubic(elapsed / 300)
    elseif elapsed > activeNotification.duration - 300 then
        slideProgress = easeOutCubic((activeNotification.duration - elapsed) / 300)
    end
    
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
    
    -- Position based on config with slide animation
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
    
    -- Apply slide animation
    local xOffset = (baseX > 0.5 and 1 or -1) * 0.15 * (1 - slideProgress)
    local xPos = baseX + xOffset
    local yPos = baseY
    
    local width = notifConfig.width
    local height = notifConfig.height
    local themeConfig = Config.UI.theme
    
    -- Parse background color with fade animation
    local bgR, bgG, bgB, bgA = parseRgba(themeConfig.colors.background)
    bgA = math.floor(bgA * slideProgress)
    
    -- Draw notification background with gradient effect
    drawRect(xPos, yPos, width, height, bgR, bgG, bgB, bgA)
    
    -- Draw gradient overlay
    drawRect(xPos, yPos, width, height * 0.3, accentR, accentG, accentB, math.floor(15 * slideProgress))
    
    -- Draw animated accent border with glow
    drawRect(xPos - (width / 2) + 0.002, yPos, 0.0035, height - 0.001, accentR, accentG, accentB, math.floor(255 * slideProgress))
    drawRect(xPos - (width / 2) + 0.002, yPos, 0.008, height - 0.001, accentR, accentG, accentB, math.floor(60 * slideProgress))
    
    -- Draw corner accents
    local cornerSize = 0.006
    drawRect(xPos - (width / 2) + cornerSize, yPos - (height / 2) + 0.001, cornerSize * 2, 0.0015, accentR, accentG, accentB, math.floor(200 * slideProgress))
    drawRect(xPos - (width / 2) + 0.001, yPos - (height / 2) + cornerSize, 0.0015, cornerSize * 2, accentR, accentG, accentB, math.floor(200 * slideProgress))
    
    -- Draw title with enhanced styling
    SetTextFont(themeConfig.font)
    SetTextScale(0.38, 0.38)
    SetTextColour(accentR, accentG, accentB, math.floor(255 * slideProgress))
    SetTextCentre(false)
    SetTextDropshadow(2, accentR, accentG, accentB, 150)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(activeNotification.title)
    DrawText(xPos - (width / 2) + 0.015, yPos - (height / 2) + 0.005)
    
    -- Draw description
    SetTextFont(themeConfig.font)
    SetTextScale(0.32, 0.32)
    SetTextColour(255, 255, 255, math.floor(255 * slideProgress))
    SetTextCentre(false)
    SetTextDropshadow(2, 0, 0, 0, 180)
    SetTextEntry("STRING")
    AddTextComponentString(activeNotification.description)
    DrawText(xPos - (width / 2) + 0.015, yPos + (height / 2) - 0.025)
    
    -- Draw progress bar at bottom
    local progressWidth = width * progress
    local progressY = yPos + (height / 2) - 0.001
    drawRect(xPos - (width / 2) + (progressWidth / 2), progressY, progressWidth, 0.002, accentR, accentG, accentB, math.floor(255 * slideProgress))
    drawRect(xPos - (width / 2) + (progressWidth / 2), progressY, progressWidth, 0.004, accentR, accentG, accentB, math.floor(100 * slideProgress))
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

-- Draw the taser UI (Enhanced with Modern Visual Effects)
local function drawTaserUI()
    -- Update animations first
    updateAnimations()
    
    if not showUI or animationStates.slideIn <= 0 then return end
    
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
    
    -- Apply slide animation
    local easedSlide = easeOutCubic(animationStates.slideIn)
    
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
    
    -- Apply slide animation to position
    local animatedX = xPos + (xPos > 0.5 and (1 - easedSlide) * 0.1 or -(1 - easedSlide) * 0.1)
    local animatedOpacity = math.floor(255 * easedSlide)
    
    -- Draw gradient background (simulated with layered rectangles)
    drawRect(animatedX, animatedY or yPos, width, height, bgR, bgG, bgB, math.floor(bgA * easedSlide))
    
    -- Add subtle gradient overlay (darker at bottom)
    drawRect(animatedX, animatedY or yPos, width, height * 0.4, 0, 0, 0, math.floor(30 * easedSlide))
    
    -- Draw animated glowing border with pulsing effect
    local pulseAlpha = math.floor(150 + (animationStates.pulseIntensity * 105))
    local glowWidth = 0.0025 + (animationStates.glowIntensity * 0.001)
    
    -- Top border with glow
    drawRect(animatedX, animatedY or yPos - (height / 2) - glowWidth, width, glowWidth * 2, accentR, accentG, accentB, math.floor(255 * easedSlide))
    drawRect(animatedX, animatedY or yPos - (height / 2) - glowWidth - 0.002, width, 0.0015, accentR, accentG, accentB, math.floor(pulseAlpha * easedSlide))
    
    -- Bottom border with glow
    drawRect(animatedX, animatedY or yPos + (height / 2) + glowWidth, width, glowWidth * 2, accentR, accentG, accentB, math.floor(255 * easedSlide))
    drawRect(animatedX, animatedY or yPos + (height / 2) + glowWidth + 0.002, width, 0.0015, accentR, accentG, accentB, math.floor(pulseAlpha * easedSlide))
    
    -- Left border
    drawRect(animatedX - (width / 2) - glowWidth, animatedY or yPos, glowWidth * 2, height, accentR, accentG, accentB, math.floor(200 * easedSlide))
    drawRect(animatedX - (width / 2) - glowWidth - 0.002, animatedY or yPos, 0.0015, height, accentR, accentG, accentB, math.floor(pulseAlpha * 0.8 * easedSlide))
    
    -- Right border
    drawRect(animatedX + (width / 2) + glowWidth, animatedY or yPos, glowWidth * 2, height, accentR, accentG, accentB, math.floor(200 * easedSlide))
    drawRect(animatedX + (width / 2) + glowWidth + 0.002, animatedY or yPos, 0.0015, height, accentR, accentG, accentB, math.floor(pulseAlpha * 0.8 * easedSlide))
    
    -- Corner accents for futuristic look
    local cornerSize = 0.008
    local cornerAlpha = math.floor(180 * easedSlide)
    
    -- Top-left corner
    drawRect(animatedX - (width / 2) + cornerSize, animatedY or yPos - (height / 2) + 0.001, cornerSize * 2, 0.002, accentR, accentG, accentB, cornerAlpha)
    drawRect(animatedX - (width / 2) + 0.001, animatedY or yPos - (height / 2) + cornerSize, 0.002, cornerSize * 2, accentR, accentG, accentB, cornerAlpha)
    
    -- Top-right corner
    drawRect(animatedX + (width / 2) - cornerSize, animatedY or yPos - (height / 2) + 0.001, cornerSize * 2, 0.002, accentR, accentG, accentB, cornerAlpha)
    drawRect(animatedX + (width / 2) - 0.001, animatedY or yPos - (height / 2) + cornerSize, 0.002, cornerSize * 2, accentR, accentG, accentB, cornerAlpha)
    
    -- Bottom-left corner
    drawRect(animatedX - (width / 2) + cornerSize, animatedY or yPos + (height / 2) - 0.001, cornerSize * 2, 0.002, accentR, accentG, accentB, cornerAlpha)
    drawRect(animatedX - (width / 2) + 0.001, animatedY or yPos + (height / 2) - cornerSize, 0.002, cornerSize * 2, accentR, accentG, accentB, cornerAlpha)
    
    -- Bottom-right corner
    drawRect(animatedX + (width / 2) - cornerSize, animatedY or yPos + (height / 2) - 0.001, cornerSize * 2, 0.002, accentR, accentG, accentB, cornerAlpha)
    drawRect(animatedX + (width / 2) - 0.001, animatedY or yPos + (height / 2) - cornerSize, 0.002, cornerSize * 2, accentR, accentG, accentB, cornerAlpha)
    
    -- LEFT SECTION: Icon (Lightning Bolt) with pulse animation
    local leftX = animatedX - (width / 2) + 0.015
    if taserConfig.elements.icon then
        local iconScale = 0.42 + (animationStates.pulseIntensity * 0.04)
        local iconAlpha = math.floor(230 + (animationStates.pulseIntensity * 25))
        SetTextFont(themeConfig.font)
        SetTextScale(iconScale, iconScale)
        SetTextColour(accentR, accentG, accentB, iconAlpha)
        SetTextCentre(true)
        SetTextDropshadow(3, accentR, accentG, accentB, 180)
        SetTextEdge(1, accentR, accentG, accentB, 150)
        SetTextEntry("STRING")
        AddTextComponentString("⚡")
        DrawText(leftX, yPos - 0.014)
    end
    
    -- CENTER SECTION: Label with modern styling
    local centerX = animatedX - 0.015
    if taserConfig.elements.label then
        SetTextFont(themeConfig.font)
        SetTextScale(0.38, 0.38)
        SetTextColour(textR, textG, textB, animatedOpacity)
        SetTextCentre(true)
        SetTextDropshadow(2, 0, 0, 0, 200)
        SetTextOutline()
        SetTextEntry("STRING")
        
        local labelText = isReloading and "RELOADING..." or "TASER"
        if isOnCooldown and not isReloading then
            labelText = "COOLDOWN"
        end
        
        AddTextComponentString(labelText)
        DrawText(centerX, yPos - 0.012)
    end
    
    -- RIGHT SECTION: Enhanced Charge Indicator with Animations
    if taserConfig.elements.chargeIndicator then
        local cellWidth = chargeConfig.cellWidth
        local cellHeight = chargeConfig.cellHeight
        local cellSpacing = chargeConfig.cellSpacing
        local filledR, filledG, filledB = hexToRgb(chargeConfig.filledColor)
        local emptyR, emptyG, emptyB = hexToRgb(chargeConfig.emptyColor)
        local borderR, borderG, borderB, borderA = parseRgba(chargeConfig.borderColor)
        
        -- Calculate starting X position for cells
        local totalCellWidth = (Config.MaxCartridges * cellWidth) + ((Config.MaxCartridges - 1) * cellSpacing)
        local cellStartX = animatedX + (width / 2) - 0.012 - totalCellWidth
        
        -- Draw charge cells with enhanced animations
        for i = 1, Config.MaxCartridges do
            local cellX = cellStartX + ((i - 1) * (cellWidth + cellSpacing)) + (cellWidth / 2)
            local cellY = yPos
            
            -- Determine cell appearance based on charge status
            local cellR, cellG, cellB, cellA
            local glowR, glowG, glowB, glowA
            
            if i <= taserCartridges then
                -- Charged - with pulse animation
                cellR, cellG, cellB, cellA = filledR, filledG, filledB, animatedOpacity
                glowR, glowG, glowB, glowA = filledR, filledG, filledB, math.floor((80 + animationStates.pulseIntensity * 40) * easedSlide)
            else
                -- Empty - reduced opacity
                cellR, cellG, cellB, cellA = emptyR, emptyG, emptyB, math.floor(80 * easedSlide)
                glowR, glowG, glowB, glowA = emptyR, emptyG, emptyB, 0
            end
            
            -- Draw animated glow for charged cells
            if i <= taserCartridges then
                local glowSize = 0.002 + (animationStates.pulseIntensity * 0.002)
                drawRect(cellX, cellY, cellWidth + glowSize * 2, cellHeight + glowSize * 2, glowR, glowG, glowB, glowA)
            end
            
            -- Draw cell with rounded corners (simulated)
            drawRect(cellX, cellY, cellWidth, cellHeight, cellR, cellG, cellB, cellA)
            
            -- Draw glowing border
            local borderAlpha = i <= taserCartridges and math.floor((220 + animationStates.pulseIntensity * 35) * easedSlide) or math.floor(100 * easedSlide)
            drawRect(cellX, cellY - (cellHeight / 2), cellWidth, 0.0025, borderR, borderG, borderB, borderAlpha)
            drawRect(cellX, cellY + (cellHeight / 2), cellWidth, 0.0025, borderR, borderG, borderB, borderAlpha)
            drawRect(cellX - (cellWidth / 2), cellY, 0.0025, cellHeight, borderR, borderG, borderB, borderAlpha)
            drawRect(cellX + (cellWidth / 2), cellY, 0.0025, cellHeight, borderR, borderG, borderB, borderAlpha)
            
            -- Inner glow for charged cells
            if i <= taserCartridges then
                drawRect(cellX, cellY, cellWidth * 0.6, cellHeight * 0.4, 255, 255, 255, math.floor(60 * animationStates.pulseIntensity * easedSlide))
            end
        end
    end
    
    -- RELOAD PROGRESS BAR (When reloading)
    if isReloading then
        local barWidth = width - 0.02
        local barHeight = 0.004
        local barX = animatedX
        local barY = yPos + (height / 2) - 0.012
        
        -- Progress bar background
        drawRect(barX, barY, barWidth, barHeight, 30, 30, 40, math.floor(200 * easedSlide))
        
        -- Progress bar fill
        local fillWidth = barWidth * reloadProgress
        local progressR, progressG, progressB = hexToRgb(themeConfig.colors.accent)
        drawRect(barX - (barWidth / 2) + (fillWidth / 2), barY, fillWidth, barHeight, progressR, progressG, progressB, math.floor(255 * easedSlide))
        
        -- Progress bar glow
        drawRect(barX - (barWidth / 2) + (fillWidth / 2), barY, fillWidth, barHeight + 0.002, progressR, progressG, progressB, math.floor(100 * easedSlide))
    end
    
    -- COOLDOWN TIMER with enhanced styling
    if isOnCooldown and taserConfig.elements.cooldownTimer and not isReloading then
        local timerX = animatedX + 0.020
        local timerY = yPos - 0.006
        local timerText = formatTime(cooldownRemaining)
        
        -- Draw timer background
        local timerBgWidth = 0.035
        local timerBgHeight = 0.018
        drawRect(timerX, timerY, timerBgWidth, timerBgHeight, 0, 0, 0, math.floor(180 * easedSlide))
        
        -- Draw timer border
        drawRect(timerX, timerY - (timerBgHeight / 2), timerBgWidth, 0.0015, accentR, accentG, accentB, math.floor(200 * easedSlide))
        drawRect(timerX, timerY + (timerBgHeight / 2), timerBgWidth, 0.0015, accentR, accentG, accentB, math.floor(200 * easedSlide))
        drawRect(timerX - (timerBgWidth / 2), timerY, 0.0015, timerBgHeight, accentR, accentG, accentB, math.floor(200 * easedSlide))
        drawRect(timerX + (timerBgWidth / 2), timerY, 0.0015, timerBgHeight, accentR, accentG, accentB, math.floor(200 * easedSlide))
        
        -- Draw timer text
        SetTextFont(themeConfig.font)
        SetTextScale(0.30, 0.30)
        SetTextColour(255, 255, 255, animatedOpacity)
        SetTextCentre(true)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEntry("STRING")
        AddTextComponentString(timerText)
        DrawText(timerX, timerY - 0.003)
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
    reloadStartTime = GetGameTimer()
    
    -- Keep UI visible during reload for progress bar
    showUI = true

    -- Request the animation dict from config
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
    
    -- Notify server that reload is complete
    TriggerServerEvent('smarttaser:reloadComplete')
    
    -- Show reload complete notification
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