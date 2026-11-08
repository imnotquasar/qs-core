# 22 · qs-rp — Roleplay Commands

Standard roleplay chat commands (me / do / ooc / b / try / pm) plus a floating
above-head action (ame). Local commands broadcast only to nearby players; proximity
is computed server-side from ped coordinates. Messages render in **qs-corechat**
with a distinct style per type.

- **Location:** `resources/[addons]/qs-rp`.
- **Depends on:** `qs-core`, `qs-corechat`.

---

## Commands

| Command | Scope | Output |
|---|---|---|
| `/me <action>` | local (20 m) | `* Name action` |
| `/do <description>` | local | `* description (( Name ))` |
| `/b <message>` | local (OOC) | `(( Name: message ))` |
| `/ooc <message>` | **global** | `(OOC) Name: message` |
| `/try <action>` | local | `* Name action — and succeeds` / `— and fails` (50/50) |
| `/pm <id> <message>` | private | `(PM from Name): message` to the target + `(PM to Name): message` to you |
| `/ame <action>` | local (20 m) | floating text above your head for 8 s (not in chat) |

`Name` is the character's first + last name (falls back to the FiveM name).
Messages are trimmed and cut to 300 characters; an empty message shows an error
notification. `/pm` refuses your own id and offline ids.

All commands appear in the chat autocomplete (Tab) with parameter hints.

## Config (`config.lua`)

| Key | Default | Meaning |
|---|---|---|
| `Config.Proximity` | `20.0` | Radius (m) for `/me` `/do` `/b` `/try`. |
| `Config.AmeDistance` / `Config.AmeDuration` | `20.0` / `8000` | `/ame` visible radius + lifetime (ms). |
| `Config.MaxLength` | `300` | Max characters per message. |
| `Config.TryOutcomes` | `{ 'success', 'fail' }` | Not used yet: `/try` is always a 50/50 between the `try_success` / `try_fail` locale texts. |

## Events

| Event | Side | Purpose |
|---|---|---|
| `qs-rp:me` / `:do` / `:b` / `:ooc` / `:try` / `:ame` | server | Receive a command (`text`) and broadcast to the right audience. |
| `qs-rp:pm` | server | Private message (`targetId, text`). |
| `qs-rp:client:ame` | client | Draw the floating action above a player's head (`srcId, text`). |

## Notes

- Localised (ar, de, en, es, fr, it, pl, pt, ru, tr; convar `qs:locale`). Text is
  sent to `qs-corechat` via `qs-corechat:client:message` with a `type` field
  (`me`/`do`/`ooc`/`b`/`pm`; `/try` uses `me`) that the chat NUI styles.
