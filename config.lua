Config = {}

Config.TaserWeapon = `WEAPON_STUNGUN`
Config.MaxCartridges = 2
Config.TaserCooldown = 5000 -- Cooldown between shots (ms) - ADJUST THIS VALUE PER SERVER NEEDS
Config.StunDuration = 6500 -- How long target stays down (ms) - ADJUST THIS VALUE PER SERVER NEEDS
Config.ReloadTime = 2000 -- Reload time (ms) - ADJUST THIS VALUE PER SERVER NEEDS
Config.ReloadKey = 45 -- R

-- Timer Configuration
Config.Timers = {
    -- Precision: decimal places shown in cooldown timer (1-2 recommended)
    -- 1 = "3.2s", 2 = "3.24s"
    cooldownPrecision = 1,
    
    -- Update frequency: how often the UI updates (in ms)
    -- Lower = smoother but more CPU, Higher = less smooth but less CPU
    -- Recommended: 0 (every frame) for accurate timing
    updateInterval = 0,
    
    -- Ensure timer never goes negative (safety check)
    preventNegative = true,
}

-- Reload Animation Configuration
Config.ReloadAnimation = {
    dict = "anim@weapons@pistol@machine_str",
    anim = "reload_aim",
    flags = 48
}

-- Alternative animation presets you can use:
-- AP Pistol: dict = "anim@weapons@pistol@machine_str", anim = "reload_aim"
-- Pistol: dict = "weapons@pistol@reload", anim = "reload_aim"
-- Combat Pistol: dict = "anim@weapons@first_person@aiming@pistol@str", anim = "reload"
-- Micro SMG: dict = "anim@weapons@smg@micro_str", anim = "reload"

-- UI Configuration (Ultra-Compact Redesign)
Config.UI = {
    -- Layout mode: "compact", "minimal", "detailed"
    -- compact: Shows icon, cartridges, status, cooldown timer
    -- minimal: Only icon and cartridges/status (0.06×0.04)
    -- detailed: Legacy detailed view with all info
    layout = "compact",
    
    -- Main taser UI positioning
    taser = {
        enabled = true,
        position = "right-center", -- Positioned on right side, vertically centered
        hideWhenNotAiming = true,
        
        -- Ultra-compact horizontal bar layout with modern spacing
        dimensions = {
            width = 0.15,    -- Better spacing width
            height = 0.050,  -- Increased modern height
        },
        
        -- What elements to display (toggleable)
        elements = {
            icon = true,              -- ⚡ symbol
            label = true,             -- "SMART TASER" text
            cartridges = false,       -- Show numeric count (disabled in bar mode)
            status = false,           -- Don't show READY/COOLDOWN (too verbose)
            cooldownTimer = true,     -- Show timer (displays cooldown remaining)
            chargeIndicator = true,   -- Show charge cells (like battery)
            cooldownBar = false,      -- Show progress bar (disabled in compact mode)
        },
        
        -- Timer display options
        timerDisplay = {
            showUnitLabel = true,     -- Show "s" suffix (3.2s vs 3.2)
            alwaysShow = false,       -- Show timer even when ready (shows 0.0s)
            hideWhenReady = true,     -- Hide timer when cooldown is done
        },
        
        -- Charge indicator cell options
        chargeIndicator = {
            cellWidth = 0.015,        -- Width of each charge cell
            cellHeight = 0.024,       -- Height of each charge cell
            cellSpacing = 0.005,      -- Space between cells
            filledColor = "#01ff00",  -- Bright neon green
            emptyColor = "#ff3366",   -- Neon red when empty
            borderColor = "rgba(0, 255, 0, 200)",
        }
    },
    
    -- Notification system (simplified)
    notifications = {
        enabled = true,
        maxVisible = 1,              -- Only 1 notification at a time
        position = "top-right",      -- "top-left", "top-right", "bottom-left", "bottom-right"
        width = 0.12,
        height = 0.04,
        duration = 2500,             -- Auto-dismiss time (ms)
        stackDirection = "down",     -- New notifications appear below existing ones
        
        -- Which events show notifications
        showOn = {
            fire = true,             -- Show when firing
            cooldown = false,         -- Don't spam cooldown messages
            reload = true,            -- Show reload complete
            hit = true,               -- Show when hitting target
            miss = false,             -- Don't show miss messages
        }
    },
    
    -- Theme and styling
    theme = {
        mode = "neon",               -- "dark", "light", "neon"
        font = 4,                    -- Font ID (0-7 available in GTA5)
        
        colors = {
            background = "rgba(12, 12, 22, 250)",    -- Darker modern background
            text = "#ffffff",
            accent = "#00ffff",       -- Bright cyan neon
            success = "#01ff00",      -- Bright neon green
            warning = "#ff9800",      -- Orange
            error = "#ff3366",        -- Neon red/pink
        },
        
        -- Typography
        titleScale = 0.40,
        bodyScale = 0.33,
        
        -- Visual styling
        border = false,              -- Minimal design, no borders
        padding = 0.008,
    }
}