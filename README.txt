This script adds a modular smart taser system with visual UI, reloading, cartridge control.

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
Replace your stungun item with this code

['WEAPON_STUNGUN'] = {
			label = 'Tazer',
			weight = 227,
			durability = 0.1,
			ammoname = 'taser_cartridge'
		},
---

## ⚙️ Config Options

In `config.lua`, you can set:
- `Config.StunDuration` → Adjust how long players are stunned.
- `Config.MaxCartridges` → Max taser shots before needing reload.

---

## 📌 Notes

- Requires `ox_lib` and `ox_inventory`
- Taser UI appears only when aiming
- Animations and sounds included (you can swap them if you want)