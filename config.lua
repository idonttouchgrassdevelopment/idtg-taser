Config = {}

Config.TaserWeapon = `WEAPON_STUNGUN`
Config.MaxCartridges = 2
Config.TaserCooldown = 5000 -- Cooldown between shots (ms)
Config.StunDuration = 6500 -- How long target stays down (ms)
Config.ReloadTime = 2000 -- Reload time (ms)
Config.ReloadKey = 45 -- R

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

-- UI Configuration
Config.UI = {
    -- Main UI positioning (options: "center", "right-center", "left-center", "top-center", "top-right", "top-left", "bottom-center", "bottom-right", "bottom-left")
    position = "right-center",
    
    -- Style configuration - uses native colors (RGBA values)
    style = {
        -- Background color (hex or rgba format)
        -- Examples: "#1a1a2e" or "rgba(26, 26, 46, 230)" or "rgba(0, 0, 0, 200)"
        backgroundColor = "rgba(20, 20, 35, 240)",
        
        -- Text/accent color (hex format)
        -- Examples: "#00d4ff" (cyan), "#ff6b6b" (red), "#4caf50" (green), "#ffd700" (gold)
        color = "#00d4ff",
        
        -- Border color (hex or rgba format)
        border = "rgba(0, 212, 255, 180)"
    },
    
    -- Cooldown bar configuration
    cooldownBar = {
        enabled = true,
        -- Background color of the progress bar track
        backgroundColor = "rgba(0, 0, 0, 150)",
        -- Foreground color when cooldown is active
        foregroundColor = "#ff6b6b",
        -- Color when ready to fire (green)
        readyColor = "#4caf50"
    },
    
    -- Cartridge icons configuration
    icons = {
        enabled = true,
        filled = "🔋",  -- Emoji for full cartridges
        empty = "⬛"   -- Emoji for empty cartridges
    }
}