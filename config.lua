Config = {}

Config.TaserWeapon = `WEAPON_STUNGUN`
Config.MaxCartridges = 2
Config.TaserCooldown = 5000 -- Cooldown between shots (ms) - ADJUST THIS VALUE PER SERVER NEEDS
Config.StunDuration = 6500 -- How long target stays down (ms) - ADJUST THIS VALUE PER SERVER NEEDS
Config.ReloadTime = 2000 -- Reload time (ms) - ADJUST THIS VALUE PER SERVER NEEDS
Config.ReloadKey = 45 -- R
Config.CartridgeItem = 'taser_cartridge' -- ox_inventory ammo item used for manual reload

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

-- ============================================
-- CUSTOM ANIMATION SYSTEM
-- ============================================

-- Reload Animation Configuration with Enhanced Customization
Config.ReloadAnimation = {
    -- Optional preset key from presets table below
    preset = "stungun_operator",

    -- Fallback custom animation (used when preset is missing)
    dict = "anim@weapons@pistol@machine_str",
    anim = "reload_aim",

    -- TaskPlayAnim controls
    flags = 48,                    -- Animation flags (0-255)
    blendIn = 8.0,                 -- Blend in time (seconds)
    blendOut = -8.0,               -- Blend out time (seconds)
    playbackRate = 0.0,            -- Animation playback rate (0.0 = auto, >0.0 = manual)
    lockX = false,                 -- Lock X position
    lockY = false,                 -- Lock Y position
    lockZ = false,                 -- Lock Z position
    
    -- Enhanced animation options
    enterPlaybackRate = 1.0,       -- Speed when animation starts (0.1-3.0)
    exitPlaybackRate = 1.0,        -- Speed when animation ends (0.1-3.0)
    holdTime = 0,                  -- Additional hold time after animation completes (ms)
    fadeInTime = 0.0,              -- Fade in duration (seconds)
    fadeOutTime = 0.0,             -- Fade out duration (seconds)

    -- Built-in presets (set preset = "name" above)
    presets = {
        stungun_operator = {
            dict = "anim@weapons@pistol@machine_str",
            anim = "reload_aim",
            flags = 51,
            blendIn = 4.0,
            blendOut = -4.0,
            -- Enhanced options for this preset
            enterPlaybackRate = 1.0,
            exitPlaybackRate = 1.0,
            holdTime = 200,
        },
        ap_pistol = {
            dict = "anim@weapons@pistol@machine_str",
            anim = "reload_aim",
            flags = 48,
            blendIn = 8.0,
            blendOut = -8.0,
        },
        pistol = {
            dict = "weapons@pistol@reload",
            anim = "reload_aim",
            flags = 48,
            blendIn = 8.0,
            blendOut = -8.0,
        },
        combat_pistol = {
            dict = "anim@weapons@first_person@aiming@pistol@str",
            anim = "reload",
            flags = 48,
            blendIn = 8.0,
            blendOut = -8.0,
        },
        micro_smg = {
            dict = "anim@weapons@smg@micro_str",
            anim = "reload",
            flags = 48,
            blendIn = 8.0,
            blendOut = -8.0,
        },
        -- Custom taser-specific animations
        taser_tactical = {
            dict = "anim@melee@large_wpn@streamed_core",
            anim = "ground_attack_on_spot",
            flags = 49,
            blendIn = 3.0,
            blendOut = -3.0,
            playbackRate = 0.0,
            enterPlaybackRate = 1.2,
            exitPlaybackRate = 0.8,
            holdTime = 150,
        },
        taser_quick = {
            dict = "anim@weapons@pistol@single_str",
            anim = "reload_aim",
            flags = 48,
            blendIn = 2.0,
            blendOut = -2.0,
            enterPlaybackRate = 1.5,
            exitPlaybackRate = 1.5,
        },
        taser_realistic = {
            dict = "anim@weapons@pistol@machine_str",
            anim = "reload_aim",
            flags = 51,
            blendIn = 6.0,
            blendOut = -6.0,
            playbackRate = 0.0,
            enterPlaybackRate = 0.8,
            exitPlaybackRate = 1.0,
            holdTime = 500,
            fadeInTime = 0.1,
            fadeOutTime = 0.1,
        },
    }
}

-- ============================================
-- SAFETY SYSTEM
-- ============================================

Config.Safety = {
    enabled = true,             -- Enable manual taser safety
    defaultOn = true,           -- Safety starts ON when resource/player loads
    toggleKey = 311,            -- K key (FiveM control index)
    keybind = 'k',              -- Keyboard key mapping for rebinding in FiveM settings
    toggleDebounce = 250,       -- Prevent rapid toggling (ms)
}

-- ============================================
-- UI CONFIGURATION
-- ============================================

-- Tip: if you want a fully custom animation, set preset to nil and edit dict/anim/flags above.

-- UI Configuration (Enhanced with Modern Visual Effects)
Config.UI = {
    -- Layout mode: "compact", "minimal", "detailed"
    -- compact: Shows icon, cartridges, status, cooldown timer
    -- minimal: Only icon and cartridges/status (0.06×0.04)
    -- detailed: Legacy detailed view with all info
    layout = "minimal",
    
    -- Main taser UI positioning
    taser = {
        enabled = true,
        position = "right-center", -- Centered on the right side of screen
        hideWhenNotAiming = true,
        
        -- Modern horizontal bar layout with enhanced spacing
        dimensions = {
            width = 0.190,    -- Wider panel for a cleaner segmented layout
            height = 0.050,   -- Slimmer capsule-like height
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
        
        -- Charge indicator cell options with modern styling
        chargeIndicator = {
            cellWidth = 0.012,        -- Compact battery capsule width
            cellHeight = 0.020,       -- Slim battery capsule height
            cellSpacing = 0.007,      -- Balanced spacing between battery cells
            filledColor = "#8dff3d",  -- Lime-green active battery
            emptyColor = "#5a6a7a",   -- Muted slate for empty battery
            borderColor = "rgba(141, 255, 61, 220)",
        }
    },
    
    -- Notification system (enhanced)
    notifications = {
        enabled = true,
        maxVisible = 1,              -- Only 1 notification at a time
        position = "top-right",      -- "top-left", "top-right", "bottom-left", "bottom-right"
        width = 0.14,
        height = 0.045,
        duration = 2800,             -- Slightly longer auto-dismiss time (ms)
        stackDirection = "down",     -- New notifications appear below existing ones
        
        -- Which events show notifications
        showOn = {
            fire = false,            -- Don't show fire messages (less spam)
            cooldown = false,         -- Don't spam cooldown messages
            reload = true,            -- Show reload complete
            hit = true,               -- Show when hitting target
            miss = false,             -- Don't show miss messages
        }
    },
    
    -- Theme and styling (modern and sexy)
    theme = {
        mode = "neon",               -- "dark", "light", "neon"
        font = 4,                    -- Font ID (0-7 available in GTA5)
        
        colors = {
            background = "rgba(10, 14, 24, 240)",    -- Main panel body
            panelInner = "rgba(16, 21, 30, 228)",    -- Inner panel inset
            shadow = "rgba(0, 0, 0, 130)",           -- Panel shadow
            divider = "rgba(94, 106, 124, 140)",     -- Vertical separators
            text = "#ffffff",
            accent = "#30e6ff",                      -- Top strip + reload fill
            title = "rgba(220, 236, 255, 245)",      -- Header text
            subtitle = "rgba(130, 152, 181, 230)",   -- Helper text
            icon = "rgba(214, 243, 255, 255)",       -- Bolt icon color
            iconSubtext = "rgba(138, 160, 190, 210)",-- Bolt subtext color
            statusBackground = "rgba(12, 18, 28, 230)", -- Status capsule background
            timerText = "rgba(188, 212, 242, 230)",  -- Cooldown timer text
            reloadRail = "rgba(22, 30, 44, 215)",    -- Reload rail background
            ready = "#7bf2a9",                       -- Ready status
            reloading = "#ffc652",                   -- Reloading status
            empty = "#ff6470",                       -- Empty status
            cooldown = "#78cdff",                    -- Cooldown status
            success = "#00ff88",
            warning = "#ffaa00",
            error = "#ff4466",
        },
        
        -- Typography
        titleScale = 0.42,
        bodyScale = 0.35,
        
        -- Visual styling
        border = false,              -- Minimal design, no borders
        padding = 0.010,
    }
}