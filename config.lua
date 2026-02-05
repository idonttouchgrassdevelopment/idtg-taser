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
    -- Main UI positioning
    position = "right-center",
    
    -- Style configuration
    style = {
        backgroundColor = "#1a1a2e",
        color = "#00d4ff",
        fontSize = "16px",
        padding = "10px 16px",
        borderRadius = "12px",
        fontFamily = "Segoe UI, Roboto, Helvetica, Arial, sans-serif",
        boxShadow = "0 4px 12px rgba(0, 212, 255, 0.3)",
        border = "2px solid rgba(0, 212, 255, 0.5)"
    },
    
    -- Cooldown bar configuration
    cooldownBar = {
        enabled = true,
        height = "4px",
        backgroundColor = "rgba(0, 0, 0, 0.5)",
        foregroundColor = "#ff6b6b",
        borderRadius = "2px"
    },
    
    -- Cartridge icons configuration
    icons = {
        enabled = true,
        filled = "🔋",
        empty = "⬛"
    }
}