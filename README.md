

# Naming Convention Checker

Breniak's **Godot Editor plugin** that warns when project files do not follow a defined naming convention.

The plugin automatically scans the project filesystem and prints warnings in the editor output when files do not match the rules defined in `settings.cfg`.

This helps keep projects consistent.

## Built With

-   Godot Engine 4.6+

## Installation

1.  Download a release from the repository.
2.  Extract the archive.
3.  Copy the folder: `addons/naming_convention_checker` into your project: `res://addons/`
4.  Enable the plugin: `Project → Project Settings → Plugins → Naming Convention Checker`

## How It Works

Each time the filesystem changes (file added, renamed, removed, etc.), the plugin scans the project and verifies that filenames follow the rules defined in: `addons/naming_convention_checker/settings.cfg`

If a rule is violated, a warning appears in the output:

`[FILE NAMING] myTexture.png must begin with ["T_", "UI_"] -> res://textures/myTexture.png`

or

`[FILE NAMING] bad file name.png has space in its name -> res://textures/bad file name.png`

## Configuration

All rules are defined in: `addons/naming_convention_checker/settings.cfg`

When enabled, the addon will create it if the file doesn't exist.

The file contains **three sections**.

### Section: Ignores

This section is static, you can't add new keys.

| Setting | Description |
|--|--|
| `ignore_spaces` | If `false`, files containing spaces will trigger a warning |
| `ignored_extensions` | File extensions that will not be checked |
| `ignored_folders` | Folder names that will be skipped entirely |

Example:
```ini
[Ignores]  
  
ignore_spaces=false  
ignored_extensions=["import","uid","cfg","ini"]  
ignored_folders=["addons", "temp", "script"]
```

### Section: Files

Defines naming rules based on **file extensions**.

Each entry is a **dictionary** with two fields:

-   `extensions` → file extensions affected by the rule
-   `prefixes` → valid prefixes for filenames

→ You can add or remove entries as you wish as long as you respect the two field names.

**Example:**
```ini
[Files]  
  
texture={"extensions": ["png","jpg"], "prefixes": ["T_", "UI_"]}  
scene={"extensions": ["tscn"], "prefixes": ["P_", "L_"]}  
audio={"extensions": ["wav","ogg"], "prefixes": ["SFX_", "music_"]}
```

Valid names:
```
T_character.png  
UI_button.png  
P_main_menu.tscn  
SFX_explosion.wav
```

Invalid names:
```
character.png  
button.png  
main_menu.tscn  
explosion.wav
```

### Section: Scripts

This section defines rules for **GDScripts** (`.gd`).

Each rule contains:

-   `class` → Must match the exact `class_name` or native class in godot.
-   `prefixes` → required filename prefixes

→ You can add or remove entries as you wish as long as you respect the two field names.

Example:
```ini
[Scripts]  
  
control={"class":"Control","prefixes":["ui_"]}
actor={"class":"CharacterBody3D","prefixes":["c_"]}
enemy={"class":"Actor","prefixes":["a_"]}
```

**Example:**

Valid:
```
ui_screen_interface.gd
c_walker.gd 
a_orc.gd
```
Invalid:
```
screen_interface.gd  
walker.gd 
orc.gd
```

### Section: Resources

This section defines rules for **Godot resources** (`.tres` and `.res`).

Each rule contains:

-   `class` → Native or custom resource class, it must match the exact `class_name` in godot.
-   `prefixes` → required filename prefixes

→ You can add or remove entries as you wish as long as you respect the two field names.

Example:
```ini
[Resources]  
  
base_material_3d={"class":"BaseMaterial3D","prefixes":["M_"]}  
shader_material={"class":"ShaderMaterial","prefixes":["M_"]}  
particle_material={"class":"ParticleProcessMaterial","prefixes":["PM_"]}  
theme={"class":"Theme","prefixes":["theme_"]}
```

**Example:**

Valid:
```
M_character.tres  
PM_fire_particles.tres  
theme_default.tres
```
Invalid:
```
character_material.tres  
fire_particles.tres  
default_theme.tres
```
