This script adds a modular smart taser system with a clean UI, reloading, cartridge control, and a safety system.

---

## 📂 Setup

### 1. Install the Script
Put the folder in your `resources/` and ensure it's started:

```
ensure idonttouchgrass-taser
```

### 2. ox_inventory Setup

In your `ox_inventory` item definitions (e.g., `shared/weapons.lua`), add:

```lua
['taser_cartridge'] = {
    label = 'Taser Cartridge',
    weight = 50,
},
```

Replace your stungun item with this:

```lua
['WEAPON_STUNGUN'] = {
    label = 'Tazer',
    weight = 227,
    durability = 0.1,
    ammoname = 'taser_cartridge'
},
```

---

## ⚙️ Config Options

In `config.lua`, you can set:
- `Config.UI.layout` → set to `"minimal"` for version one clean UI.
- `Config.StunDuration` → adjust how long players are stunned.
- `Config.MaxCartridges` → max taser shots before needing reload.
- `Config.Safety.enabled` → enable or disable the safety system.
- `Config.Safety.defaultOn` → have safety on by default when players load in.
- `Config.Safety.toggleKey` → key to toggle safety (default `K`).

---

## 🔒 Safety System

- Safety blocks firing while enabled.
- Toggle safety with **K** (default).
- UI shows `SAFE` state when safety is on.

---

## 📌 Notes

- Requires `ox_lib` and `ox_inventory`.
- Taser UI appears only when aiming (if enabled in config).
- Animations and sounds included (you can swap them if you want).
