# 03 · qs-corechat — Chat

A chat replacement (`resources/[core]/qs-corechat`, formerly `qs-chat`) with its own
NUI and the core theme. It is compatible with the common parts of the standard
FiveM chat API (`chat:addMessage`, `chat:addSuggestion`) so other resources keep
working unchanged.

- **Dependencies:** `qs-core`.
- **Version:** 0.1.0.
- **UI:** React (`web/build`).
- **Key:** `T` opens the chat (`RegisterKeyMapping 'chatopen'`, rebindable).
- **server.cfg:** `set resources_useSystemChat false` — the default `chat` resource
  stays off because qs-corechat replaces it.

---

## 1. How it works

1. The player presses `T` → the NUI opens and the suggestion list is sent (not
   while the pause menu is open or the chat is hidden).
2. On send:
   - If the text starts with `/`, it runs as a **command** (`ExecuteCommand`).
   - Otherwise it goes to the server (`qs-corechat:server:send`).
3. The server takes the **character name** (charinfo from qs-core; falls back to
   `GetPlayerName`), trims the text to **256 characters**, and re-broadcasts it to
   **everyone** with `qs-corechat:client:message` (no proximity; the server
   `chatMessage` event is not fired).
4. The NUI takes the theme with `GetColors()` and the language from the convar
   `qs:locale`; it repaints on `qs:client:colorsChanged`.
5. The chat hides itself while the pause menu is open.

No exports. It integrates via **events**.

---

## 2. Events

### Listened on the client (standard FiveM API — compatibility)

| Event | Args | Effect |
|---|---|---|
| `chat:addMessage` | `msg` | Shows a message. Accepts `{ args = { author, text } }`, `{ args = { text } }`, `{ text = ... }` or a plain string. `color`, `template`, `multiline` and extra `args` are ignored. |
| `chat:addSuggestion` | `name, help, params` | Adds a command suggestion. |
| `chat:addSuggestions` | `list` | Adds several suggestions. |
| `chat:removeSuggestion` | `name` | Removes a suggestion. |

Not handled: `chat:clear`, `chat:addTemplate`, `chat:addMode`, and suggestions are
not generated automatically from registered commands — add them yourself.

```lua
-- Add a suggestion from your resource (client)
TriggerEvent('chat:addSuggestion', '/me', 'Text emote', {
    { name = 'text', help = 'what you do' },
})

-- Show a system message
TriggerEvent('chat:addMessage', { args = { 'System', 'Welcome to the server' } })
```

### Internal

| Event | Direction | Description |
|---|---|---|
| `qs-corechat:server:send` | client → server | Sends a chat message (plain text). |
| `qs-corechat:client:message` | server → client | Delivers `{ author, text, type? }` to the NUI. `type` (`me`, `do`, `ooc`, `b`, `pm`, `system`, `player`) picks the style; qs-rp uses it. |
| `qs:chat:display` | local event | `TriggerEvent('qs:chat:display', false)` hides the chat (and closes it if open); `true` shows it. |
| `qs:client:colorsChanged` | local | Repaints the theme. |

---

## 3. Commands / keymapping

| Command | Key | Effect |
|---|---|---|
| `/chatopen` | `T` | Opens the chat box. |

---

## 4. Customization

- **Language:** `locales/*.lua` (ar, de, en, es, fr, it, pl, pt, ru, tr) and
  `lang.lua`. Active language via the convar `qs:locale` (use `setr` so clients can
  read it).
- **Theme:** inherited from the core; no configuration needed.

---

## 5. Example: hide the chat during a cinematic

```lua
TriggerEvent('qs:chat:display', false)   -- hide
-- ... your cinematic ...
TriggerEvent('qs:chat:display', true)    -- show again
```
