# Shortcut reference

All shortcuts assume you're pressing keys on your **MacBook** while focused on a **Windows App / RDP session** with:

- **Windows App → Settings → Keyboard → Send Mac shortcut keys as Windows shortcut keys**: enabled
- `mac-shortcuts.ahk` running inside the Windows session

Legend:
- `Cmd` = ⌘ key (left of spacebar on Mac)
- `Option` = ⌥ key
- `Win App` = handled natively by the Windows App (we don't need to do anything)
- `ahk` = handled by `mac-shortcuts.ahk`

---

## Clipboard & editing basics

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Cmd + C` | Copy | Win App |
| `Cmd + V` | Paste | Win App |
| `Cmd + X` | Cut | Win App |
| `Cmd + A` | Select all | Win App |
| `Cmd + Z` | Undo | Win App |
| `Cmd + Shift + Z` | Redo | Win App |
| `Cmd + S` | Save | Win App |
| `Cmd + F` | Find | Win App |

## Cursor navigation

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Cmd + ←` | `Home` (start of line) | ahk |
| `Cmd + →` | `End` (end of line) | ahk |
| `Cmd + ↑` | `Ctrl+Home` (top of doc) | ahk |
| `Cmd + ↓` | `Ctrl+End` (end of doc) | ahk |
| `Option + ←` | Jump one word left | ahk |
| `Option + →` | Jump one word right | ahk |

## Cursor selection

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Cmd + Shift + ←` | Select to start of line | ahk |
| `Cmd + Shift + →` | Select to end of line | ahk |
| `Cmd + Shift + ↑` | Select to top of doc | ahk |
| `Cmd + Shift + ↓` | Select to end of doc | ahk |
| `Option + Shift + ←` | Select word left | ahk |
| `Option + Shift + →` | Select word right | ahk |

## Deletion

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Backspace` | Delete char left | native |
| `Fn + Backspace` | Forward delete (`Del`) | native |
| `Option + Backspace` | Delete word left | ahk |
| `Cmd + Backspace` | Delete to start of line | ahk |

## Windows & apps

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Cmd + Tab` | Alt+Tab (app switcher) | Win App |
| `Cmd + \`` | Cycle windows (Alt+Esc approximation) | ahk |
| `Cmd + W` | Close tab | Win App |
| `Cmd + T` | New tab | Win App |
| `Cmd + N` | New window | Win App |
| `Cmd + H` | Minimize | ahk |
| `Cmd + M` | Minimize | ahk |

## Screenshots

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Cmd + Shift + 3` | Full-screen capture (`Win+PrintScreen`) | ahk |
| `Cmd + Shift + 4` | Snipping Tool area (`Win+Shift+S`) | ahk |
| `Cmd + Shift + 5` | Snipping Tool panel (same as above) | ahk |

## Tab navigation (browsers, VSCode/Cursor, etc.)

| Mac shortcut | Windows result | Source |
|---|---|---|
| `Cmd + Option + ←` | Previous tab (`Ctrl+Shift+Tab`) | ahk |
| `Cmd + Option + →` | Next tab (`Ctrl+Tab`) | ahk |
| `Cmd + Shift + [` | Previous tab | ahk |
| `Cmd + Shift + ]` | Next tab | ahk |

## Script control

| Shortcut | Action |
|---|---|
| `Ctrl + Alt + P` | Pause/resume the translator (always, regardless of session) |

---

## What is NOT remapped (and why)

- **`Cmd + Space`** → intentionally left alone. Many IDEs use `Ctrl+Space` for autocomplete.
- **`Cmd + Q`** → disabled by default. Many Windows apps use `Ctrl+Q` for legitimate features. Uncomment the line in `mac-shortcuts.ahk` if you want it as `Alt+F4`.
- **`Cmd + ,`** → most Windows apps already accept `Ctrl+,` for preferences, so the Windows App's native translation already works.
- **`Cmd + L`** → browsers already accept `Ctrl+L` for address bar.
- **Mission Control, Exposé, Launchpad** → no direct Windows equivalent. Closest: `Win+Tab` for Task View.
