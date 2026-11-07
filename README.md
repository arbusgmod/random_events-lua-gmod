# Random Events — Garry's Mod addon

Random chaos for you and your friends. Start an event, pick a weapon, survive.
Works in singleplayer and multiplayer. The mod is a single Lua file. An optional game mode runs the events automatically.

## What is in this repository

The mod and the game mode are in the same repository, in two separate folders:

```
Random Events Addon/
  random_events/                 -> put this folder into  garrysmod/addons/
Random Events Game Mod/
  randomevents/                  -> put this folder into  garrysmod/gamemodes/
```

Open the folder you need (for example **Random Events Game Mod**), take the folder inside it and drop it into the right place in `garrysmod`.

- **Random Events Addon**: the mod itself (events, cutscenes, menus, roles). Needed always.
- **Random Events Game Mod**: the game mode. It needs the mod. Without the mod, players see a black screen with a message.

**Important:** do not rename the folders *inside* these two folders. The game mode folder must stay `randomevents` (small letters, no spaces), because it has to match `randomevents.txt`. Only the outer folders (`Random Events Addon`, `Random Events Game Mod`) are just for sorting on GitHub.

## Features

- **8 random events**, each with an epic cutscene and its own music
- **Multiplayer**: every player picks a weapon before the round starts (Half-Life 2 + Custom tab)
- **Custom interface** in a dark gray-green theme, all animated:
  Escape menu ("Random Event Mode"), TAB scoreboard, weapon selector with a spinning 3D model,
  health / armor / ammo HUD, kill feed, Options menu
- **Host-only event panel** (bindable to any key)
- **Roles and admin tools**: VIP, Moderator, Admin, Superadmin (shown over the head), kick / ban / freeze / bring and more, from the TAB menu or the server console
- **TAB menu**: click a player to change their voice volume, mute them, copy SteamID, open their Steam profile
- **14 entities in the Q-menu** (Entities tab)
- **Watermelon prank**: a giant watermelon may roll in from behind... and flatten you
  (custom death scene; can be turned off in the settings)
- Everything is **cleaned up automatically** after an event ends

## Events

| # | Event | What happens |
|---|-------|--------------|
| 1 | Watermelon Event | Watermelons keep spawning |
| 2 | Zombie Event | Kill all the zombies |
| 3 | Kill Everyone | Survive the jumpscares |
| 4 | Prop Rain | Props fall all over the map |
| 5 | Headcrab Swarm | Kill all the headcrabs |
| 6 | Low Gravity | Everything floats. Survive! |
| 7 | Combine Invasion | Defeat the Combine soldiers |
| 8 | Barrel Chaos | Explosive barrels everywhere |

## Commands

| Command | What it does |
|---------|--------------|
| `random_event` | Start a random event |
| `random_event 1..8` | Start a specific event by number |
| `/randomevent` (chat) | Same as above, also `/randomevent 2` |
| `random_event_stop` or `/stopevent` | Stop the current event |
| `theadminpanel` | Open the admin panel (host only) |
| `theadminpanel_bind o` | Bind the admin panel to a key (here: O) |
| `/fix` or `re_fix` | Restore the normal controls and camera if something got stuck |
| `re_intro` | Replay the intro |

## Game mode (optional)

The mod can also run as a game mode called **Random Events**: free time with a countdown, then a random event, then the results, again and again.
Players who survive an event get a win. The game mode needs this mod; without it, players see a black screen with a message.

Take the `randomevents` folder from **Random Events Game Mod**, put it into `garrysmod/gamemodes/`, then pick **Random Events** in the game mode list
(on a server: `+gamemode randomevents`). Settings: `re_gm_wait`, `re_gm_auto`, `re_gm_minplayers`, `re_gm_timeout`. Admins can use `re_gm_next`.
After every event the whole map is reset. In the game mode only players with a role (VIP, Moderator, Admin, Superadmin) can use the spawn menu (Q).
More settings: `re_gm_cleanmap`, `re_gm_restrict_menu`. The logo and the icon are `logo.png` (height 128 px) and `icon24.png` (24 x 24 px) in the `randomevents` folder, next to `randomevents.txt`.

## Roles and admin tools

Roles: **VIP < Moderator < Admin < Superadmin**. The role is shown over the player's head and in the TAB menu.
The host of a listen server is always Superadmin. On a dedicated server give roles from the server console:

```
re_setrole <player|steamid> <vip|moderator|admin|superadmin|none>
re_roles
re_adminhelp
```

| Role | Can do |
|------|--------|
| VIP | Role tag (cosmetic) |
| Moderator | `re_kick`, `re_freeze`, `re_bring`, `re_goto`, `re_respawn` |
| Admin | + `re_heal`, `re_god`, `re_slay`, `re_ban`, `re_unban`, `re_banlist`, start / stop events |
| Superadmin | + `re_setrole` |

Hold **TAB**, then click a player: voice volume, mute, SteamID, and (with a role) the admin actions.
Roles are saved in `garrysmod/data/random_events_roles.txt`, bans in `random_events_bans.txt`.

## Settings

At the top of `random_events.lua`:

| Setting | Meaning |
|---------|---------|
| `PRANK_ENABLED` | Turn the watermelon prank on or off |
| `PRANK_DEADLY` | `true` = the giant watermelon kills, `false` = it only knocks you back |
| `PRANK_COOLDOWN` | Seconds before the same player can be pranked again |
| `PRANK_POP_DELAY` | Seconds the body flies before it bursts into pieces |

## Q-menu entities

Mystery Box, Bouncy Watermelon, Watermelon Bomb, Medkit, Ammo Crate, Armor Battery,
Jump Pad, Gravity Bubble, Zombie Spawner, Giant Watermelon, Landmine, Speed Orb,
Disco Ball, Watermelon Launcher.

## Screenshots

_Add your screenshots / GIFs here._

## Notes

- Uses only built-in Half-Life 2 content; no extra downloads needed.
- Tested by the author in Garry's Mod; found a bug? Open an issue and attach the red
  Lua error from the console (`~`).

## License

MIT (or whichever you choose — add a `LICENSE` file).
