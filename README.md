# RGXQoL

Quality-of-life enhancements for WoW Forever and Classic Era, derived from Leatrix Plus and rebuilt on RGX-Framework.

## Features

- A single options panel (`/qol`) collecting quality-of-life toggles.
- Flight-point data for Alliance and Horde routes.
- Sound muting helpers.
- Client guards for the WoW Forever (classic beta) API surface.

## Compatibility

- WoW Forever (classic beta, interface `16001`)
- Classic Era (interface `11509`)

### RGX Guides Quest-Automation Coexistence

When [RGX Guides](https://gitlab.dicematrix.cloud/rgxmods/warcraft/RGXGuides) is loaded with staged quest automation active, QoL's automate-quests handler defers to Guides for NPC/quest interactions within an active guide step. Detection uses `C_AddOns.IsAddOnLoaded("RGXGuides")` and the guide-state flag `RGXGuides.QuestAutoAccept()` exposed per the realmgx-guides#4 contract. At each automation decision point (quest accept, quest turn-in, quest select), if Guides is loaded and its flag reports an active guide step covering the current NPC/quest, QoL returns early instead of proceeding.

When RGX Guides is absent or disabled, QoL automation behavior is unchanged. Precedence rule: Guides-specific automation takes priority over QoL generic automation for covered interactions; QoL handles only quests not owned by an active Guides step. This prevents double-accept of the same quest.

## Requirements

- [RGX-Framework](https://github.com/RGXMods/RGX-Framework) must be installed and enabled.

## Installation

1. Install RGX-Framework.
2. Copy this repository into your `Interface/AddOns` directory as `RGXQoL`.
3. Restart the game client.

## Commands

| Command | Action |
| --- | --- |
| `/qol` | Open the options panel |
| `/rl` | Reload the UI |

## License And Attribution

Derived from Leatrix Plus by Leatrix; see `Changelog.txt` for the Leatrix Plus attribution.

## Links

- Development (GitLab): `rgxmods/warcraft/RGXQoL`
- Distribution mirror (GitHub): [RGXMods/RGXQoL](https://github.com/RGXMods/RGXQoL)
