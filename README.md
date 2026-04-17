<div align="center">

# mac-win-app

**Make a Windows PC feel like a Mac when you access it via [Windows App](https://apps.apple.com/us/app/windows-app/id1295203466) or RDP.**

One command. Zero config.
`Cmd+←`, `Option+←`, `Cmd+Backspace`, `Cmd+Shift+4` — they all just work.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)](https://learn.microsoft.com/powershell)
[![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-2f3236)](https://autohotkey.com)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)](https://www.microsoft.com/windows)

</div>

---

## The problem

You're a MacBook user. Your day-job PC is a Windows box you only reach over RDP (Windows App, Microsoft Remote Desktop, AWS WorkSpaces, Azure Virtual Desktop, Parallels Client).

Every time you connect:

- `Cmd+Left/Right` doesn't jump to line start/end.
- `Option+Left/Right` doesn't skip words.
- `Cmd+Backspace` doesn't nuke the current line.
- `Cmd+Shift+4` doesn't take a screenshot.
- Your Mac keyboard types `Ç` out of nowhere because Windows picked a Brazilian layout.
- Context switching between both machines rewires your muscle memory daily.

## The fix

`mac-win-app` sets up three things so the remote Windows feels native to a Mac user:

1. **Keyboard layout** that matches your MacBook (US, US-International, or ABNT2 for BR keyboards).
2. **AutoHotkey v2 script** that translates the macOS shortcuts the Windows App doesn't handle on its own (word/line navigation, deletion, screenshots, tab switching).
3. **Conditional activation** — the script only fires inside RDP sessions. If someone logs into the physical machine, the script stays idle. No surprises.

All in your user scope. No admin rights. No registry hacks. Fully reversible.

---

## Quickstart

Inside your remote Windows session, open **PowerShell** and run:

```powershell
iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/install.ps1 | iex
```

The installer will:

- Install **AutoHotkey v2** via `winget` (if missing)
- Prompt for your keyboard layout (US / US-Intl / ABNT2)
- Drop the scripts into `%LOCALAPPDATA%\mac-win-app`
- Start the shortcut translator
- Register it to run at login

Then:

1. Open **Windows App → Settings → Keyboard** and enable **Send Mac shortcut keys as Windows shortcut keys**.
2. Disconnect and reconnect the RDP session so the keyboard layout is picked up.
3. Try `Cmd+Left`, `Option+Shift+Right`, `Cmd+Shift+4`.

### Non-interactive install

```powershell
# One-liner with preset layout
& ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/install.ps1))) -Layout USIntl

# Or clone + run
git clone https://github.com/feliperun/mac-win-app
cd mac-win-app
.\install.ps1 -Layout US
```

---

## What you get

### Shortcut translations

| MacBook gesture | What happens in Windows |
|---|---|
| `Cmd + C / V / X / A / Z / S / F / T / W` | Copy, paste, cut, select-all, undo, save, find, new tab, close *(via Windows App)* |
| `Cmd + ←` / `Cmd + →` | Jump to start / end of line |
| `Cmd + ↑` / `Cmd + ↓` | Top / bottom of document |
| `Cmd + Shift + ←/→/↑/↓` | Extend selection |
| `Option + ←` / `Option + →` | Jump one word |
| `Option + Shift + ←/→` | Select one word |
| `Cmd + Backspace` | Delete to start of line |
| `Option + Backspace` | Delete previous word |
| `Cmd + H` / `Cmd + M` | Minimize window |
| `Cmd + \`` (backtick) | Cycle windows *(approximation of Mac's same-app cycling)* |
| `Cmd + Shift + 3` | Full-screen screenshot |
| `Cmd + Shift + 4` / `Cmd + Shift + 5` | Snipping Tool (area) |
| `Cmd + Option + ←/→` | Previous / next tab |
| `Cmd + Shift + [` / `]` | Previous / next tab *(Chrome/VSCode Mac style)* |
| `Ctrl + Alt + P` | Pause/resume the translator |

See [`docs/shortcuts.md`](docs/shortcuts.md) for the full list, including which ones are handled natively by the Windows App vs added by this project.

### Keyboard layouts

| Preset | Use when | Example |
|---|---|---|
| **US pure** | Mac ANSI keyboard, write code, never type Portuguese | `'` and `"` are literal, no dead keys |
| **US-International** | Mac ANSI + sometimes write in pt/es/fr | `' + a = á`, `~ + a = ã`, `AltGr + , = ç` |
| **ABNT2** | Mac with Brazilian layout | Native `Ç` and Portuguese diacritics |

---

## How it works

```
 ┌────────────────┐       ┌────────────────────┐       ┌──────────────┐
 │  MacBook       │       │  Windows App (RDP) │       │  Windows PC  │
 │  Cmd + ←       │──────▶│  translates Cmd→Ctrl│──────▶│ Ctrl + ←     │
 └────────────────┘       └────────────────────┘       └──────┬───────┘
                                                              │
                                                              ▼
                                                  ┌─────────────────────┐
                                                  │  mac-shortcuts.ahk  │
                                                  │  Ctrl + ← → Home    │
                                                  └─────────────────────┘
```

The Windows App already translates the basic `Cmd → Ctrl` shortcuts when you enable **Send Mac shortcut keys as Windows shortcut keys**. This project picks up from there — it covers **cursor navigation**, **deletion**, **screenshots** and other macOS idioms that the Windows App doesn't translate on its own.

The magic for safety: `#HotIf IsRdpSession()` at the top of the AHK script wraps every hotkey. On every keystroke AutoHotkey checks `%SESSIONNAME%`:

- `RDP-Tcp#0` → you're connected via Windows App → shortcuts active
- `Console` → someone's physically at the keyboard → shortcuts idle

That single guard is what makes the tool safe on shared workstations.

Full details in [`docs/how-it-works.md`](docs/how-it-works.md).

---

## Uninstall

```powershell
iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/uninstall.ps1 | iex
```

That stops the script, removes the autostart entry, and deletes `%LOCALAPPDATA%\mac-win-app`. Add `-RemoveAutoHotkey -RestoreLayout` if you want a full cleanup.

---

## FAQ

<details>
<summary><strong>Does this need admin rights?</strong></summary>

No. Everything runs in the current user scope: keyboard layout via `Set-WinUserLanguageList`, AHK installed in `%LOCALAPPDATA%`, autostart via `shell:startup`.
</details>

<details>
<summary><strong>Will it affect people who log into the PC physically?</strong></summary>

No. The script checks `%SESSIONNAME%` on every keystroke and stays idle for console (local) sessions. Only RDP and ICA (Citrix) sessions see the remapping.
</details>

<details>
<summary><strong>Why not Karabiner-Elements on the Mac instead?</strong></summary>

You can, and for some people that's cleaner. The trade-off:

- **Karabiner (Mac side)**: remaps keys before they even leave the Mac. Lets you do app-specific rules. But it can't remap things that only exist on the Windows side, like "jump to end of line" when the Windows app doesn't interpret `Cmd+Right`.
- **mac-win-app (Windows side)**: lives where the shortcuts actually execute. Works regardless of the client OS. Plus the keyboard-layout setup is Windows-side anyway.

If you want the best experience, you can use both — Karabiner for app-aware Mac-side rules, mac-win-app for the Windows-side heavy lifting.
</details>

<details>
<summary><strong>Why PowerShell + AutoHotkey and not Rust?</strong></summary>

Because it's a focused proof-of-concept and AutoHotkey's keyboard-hook implementation is rock-solid. A Rust rewrite is on the roadmap once the feature set stabilizes. See [Roadmap](#roadmap).
</details>

<details>
<summary><strong>I'm seeing `Ç` when I type apostrophe + c.</strong></summary>

You're on US-International. That's the dead-key behavior. If you'd rather have literal `'` and `"` at the cost of losing native accented characters, reinstall with `-Layout US`:

```powershell
.\install.ps1 -Layout US
```
</details>

<details>
<summary><strong>Does it work with AWS WorkSpaces / Azure Virtual Desktop / Parallels Client?</strong></summary>

The AHK script works anywhere the session sets `SESSIONNAME` to an `RDP-*` or `ICA-*` value (standard for Windows remote sessions). Tested on Windows App (Mac). Community reports welcome — open an issue with your setup.
</details>

<details>
<summary><strong>Can I customize the shortcuts?</strong></summary>

Yes. Edit `%LOCALAPPDATA%\mac-win-app\scripts\mac-shortcuts.ahk`, then reload by killing the tray icon and double-clicking it again. See [`docs/how-it-works.md`](docs/how-it-works.md) for AHK symbol reference.
</details>

<details>
<summary><strong>How do I verify the install worked?</strong></summary>

```powershell
# Keyboard layout
Get-WinUserLanguageList | Format-List LanguageTag, InputMethodTips

# Script running
Get-Process AutoHotkey64

# Autostart registered
Test-Path "$([Environment]::GetFolderPath('Startup'))\mac-win-app.lnk"
```
</details>

---

## Roadmap

- [x] v0.1 — PowerShell + AutoHotkey MVP
- [ ] v0.2 — Config file for custom mappings (TOML)
- [ ] v0.3 — Winget package (`winget install macwinapp`)
- [ ] v1.0 — Rust rewrite, single binary, no external dependencies
- [ ] Future — Parallels Client / AWS WorkSpaces client presets, app-specific rules

## Contributing

Issues and PRs welcome. If you use a remote Windows setup that isn't covered (Citrix, Parallels RAS, Chrome Remote Desktop, etc.), open an issue with:

- Client you use (name + version)
- Value of `$env:SESSIONNAME` inside the session
- Shortcuts you wish worked

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for common issues.

## License

MIT. See [`LICENSE`](LICENSE).

---

<sub>Built by a Mac user who got tired of retraining his muscle memory every morning. If this saves your sanity, consider starring the repo.</sub>
