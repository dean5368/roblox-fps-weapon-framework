# roblox-fps-weapon-framework
# Roblox FPS Weapon Framework

A modular Roblox FPS / FFA weapon framework built in Luau.

This system includes server-authoritative shooting, RemoteEvent validation, ammo and reload handling, ADS, recoil, crosshair behavior, hitmarkers, tracers, impact effects, attachments/upgrades, shotgun support, grenade launcher support, and configurable weapon settings.

## Demo

Video demo: [PUT VIDEO LINK HERE]

## Features

- Server-authoritative firing
- RemoteEvent validation
- Ammo and reload system
- Fire-rate anti-spam checks
- Shot origin and aim validation
- Hit detection and damage handling
- Headshot/bodyshot support
- Tracer, impact, blood, and crack effects
- Hitmarker feedback
- ADS and FOV behavior
- Camera recoil and recoil recovery
- Dynamic crosshair
- Sprint/crouch weapon behavior
- Reload cancellation
- Shotgun reload and pump timing
- Suppressor, extended mag, sight, grip, laser, and scope support
- Grenade launcher / explosive weapon support
- Reusable weapon settings modules

## Main Code Examples

### Server Weapon Logic

`src/tools/G17/Server.server.lua`

Handles validated firing, ammo, cooldowns, reloads, hit detection, damage, shotgun/projectile logic, and server-side weapon state.

### Client Weapon Logic

`src/tools/G17/Local.client.lua`

Handles input, ADS, recoil, crosshair UI, FOV, scope behavior, local visual prediction, reload UI, and equip/unequip cleanup.

### Reusable Client Modules

`src/clientModules/`

Contains modular controllers for recoil, upgrades, reloads, crosshair, scope, laser, hitmarkers, and shot effects.

### Weapon Settings

`src/tools/G17/Settings.lua`  
`src/tools/AK12/Settings.lua`

These files configure weapon damage, ammo, fire rate, recoil, spread, reload time, sounds, attachments, and other weapon-specific behavior.

## Security Design

The client does not control damage or ammo.

The client requests a shot, but the server validates:

- Player and equipped tool
- Ammo count
- Reload state
- Fire-rate cooldown
- Shot origin
- Aim point
- Muzzle position

Only after validation does the server consume ammo and process hit detection.

## Notes

This repository contains selected source code from the weapon framework for portfolio review. Some Roblox assets, animations, models, sounds, and UI instances are not included in this repository.
