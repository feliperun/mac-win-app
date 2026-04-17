# How it works

## Architecture

```
 ┌────────────────┐       ┌────────────────────────┐       ┌──────────────┐
 │  MacBook       │       │  Windows App (RDP)     │       │  Windows PC  │
 │                │       │                        │       │              │
 │  Cmd + ←       │──────▶│  Send Mac shortcut     │──────▶│  Ctrl + ←    │
 │                │       │  keys as Windows...    │       │              │
 └────────────────┘       └────────────────────────┘       └──────┬───────┘
                                                                  │
                                                                  ▼
                                                   ┌──────────────────────────┐
                                                   │  mac-shortcuts.ahk       │
                                                   │                          │
                                                   │  #HotIf IsRdpSession()   │
                                                   │  ^Left:: Send "{Home}"   │
                                                   └──────────────────────────┘
```

## The three layers

### 1. Keyboard layout (Windows side)

`Set-WinUserLanguageList` (PowerShell) replaces the user's input method list. Each entry has a TIP code:

| Layout | TIP | Notes |
|---|---|---|
| US (pure) | `0409:00000409` | ANSI, no dead keys |
| US-International | `0409:00020409` | Dead keys via `'`, `"`, `~`, `^`, `` ` `` |
| ABNT2 (BR) | `0416:00000416` | Brazilian Portuguese keyboard |

Why we remove other layouts: Windows allows quick switching between installed keyboards via `Win+Space`, and accidental switches are a classic source of "why did my `/` become `:`" frustration. Keeping a single TIP eliminates it.

### 2. Windows App's built-in translation (RDP side)

When you tick **Send Mac shortcut keys as Windows shortcut keys**, the client hijacks the modifier key press at the Mac level and rewrites it on the wire:

- `Cmd` → `Ctrl`
- `Option` → `Alt`
- Some special cases (`Cmd+Tab` stays local to the Mac, `Cmd+Q` closes the RDP session if you don't have a session shortcut for it, etc.)

This means that inside the Windows VM, a physical `Cmd+C` on the Mac arrives as a `Ctrl+C`. Most native Windows shortcuts Just Work after this.

What the Windows App does NOT translate:
- Navigation shortcuts that have no Mac equivalent in chord form (`Cmd+Left` → `Home`)
- Deletion idioms (`Cmd+Backspace`)
- Screenshot tooling
- Tab cycling with `Cmd+Shift+[` / `]`

Those are what `mac-shortcuts.ahk` covers.

### 3. AutoHotkey translator

AHK v2 hooks into the low-level Windows keyboard API (`WH_KEYBOARD_LL`). Each defined hotkey is a pattern that matches a sequence of virtual keycodes + modifiers.

Our symbols:

| AHK symbol | Key |
|---|---|
| `^` | `Ctrl` (arrives here when Mac `Cmd` is pressed) |
| `!` | `Alt` (arrives here when Mac `Option` is pressed) |
| `+` | `Shift` |
| `#` | `Win` |

Example: `^Left:: Send "{Home}"` means "when Ctrl+Left is pressed, send Home instead."

## The RDP-only guard

The feature that keeps the tool safe on shared machines is this block:

```autohotkey
IsRdpSession() {
    sessionName := EnvGet("SESSIONNAME")
    return InStr(sessionName, "RDP") > 0 || InStr(sessionName, "ICA") > 0
}

#HotIf IsRdpSession()
; ...all hotkeys...
#HotIf
```

`SESSIONNAME` is a Windows environment variable that holds:

| Value | Meaning |
|---|---|
| `Console` | Local interactive session (physical keyboard/monitor) |
| `RDP-Tcp#<N>` | Remote Desktop session |
| `ICA-tcp#<N>` | Citrix session |

`#HotIf` is an AutoHotkey directive that enables/disables hotkey registrations based on a boolean expression, reevaluated on each keystroke. The effect:

- Physical login: `SESSIONNAME=Console` → `IsRdpSession()` returns false → hotkeys not intercepted.
- RDP login: `SESSIONNAME=RDP-Tcp#0` → `IsRdpSession()` returns true → hotkeys active.
- Disconnect/reconnect: no restart needed. State is detected per-event.

## The installer (high level)

```
install.ps1
 ├── 1. Ensure AutoHotkey v2 present
 │       - Check known install paths
 │       - If missing: winget install --scope user
 ├── 2. Download scripts from GitHub raw
 │       - %LOCALAPPDATA%\mac-win-app\scripts\
 ├── 3. Apply keyboard layout
 │       - Invokes setup-keyboard-layout.ps1 (Set-WinUserLanguageList)
 ├── 4. Start AHK process
 │       - Kill any previous instance pointing to our script
 │       - Start new one detached
 └── 5. Register autostart
         - Create .lnk in shell:startup → WScript.Shell
```

No registry keys, no services, no scheduled tasks. Everything lives in the user profile.

## Why not Karabiner on the Mac?

Karabiner-Elements is excellent for per-app rules and complex modifications on macOS, but it can't intercept behavior that only exists after the keystroke crosses into the Windows session. For cursor navigation and line-level edits, the Windows side is the right place to intervene.

A healthy combination: Karabiner for Mac-side app awareness (e.g. "in Windows App, swap left-command and left-control") + `mac-win-app` for Windows-side shortcut translation and keyboard layout.

## Why AHK and not Rust (yet)?

- AHK has 20+ years of battle-tested keyboard-hook code.
- A single `.ahk` file is trivially editable by anyone who knows a bit of scripting.
- The community shares `.ahk` snippets widely — customization is a Google search away.
- The total working set is <50 lines of actual hotkey logic.

A Rust rewrite (single `.exe`, no dependencies, TOML config, `winget install mac-win-app`) is on the roadmap for after the feature set stabilizes based on real user feedback.
