# Troubleshooting

## Shortcuts aren't working at all

Run a quick diagnostic inside the RDP session:

```powershell
# Is the AHK script running?
Get-Process AutoHotkey64

# Is Windows App's translation on?
# -> Windows App (on Mac) -> Settings -> Keyboard -> Send Mac shortcut keys as Windows shortcut keys

# Are we actually in an RDP session?
$env:SESSIONNAME
# Should print something like RDP-Tcp#0. If it prints Console, you're not on RDP.
```

If `SESSIONNAME` prints something non-standard for your remote client, open an issue with the value and we'll add detection for it.

## Some shortcuts work, others don't

`Cmd+C/V/X/A/Z/S/F/T/W` are handled by the **Windows App**, not this script. If only those specific ones are broken:

- Confirm **Send Mac shortcut keys as Windows shortcut keys** is on.
- Make sure **Keyboard mode** (in the connection's advanced settings) is set to **Mac**, not **Windows**.

If instead `Cmd+Left`, `Cmd+Backspace`, `Cmd+Shift+4` don't work, the AHK side isn't firing:

```powershell
# Restart it
Get-Process AutoHotkey64 | Where-Object {
    (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine -like "*mac-shortcuts.ahk*"
} | Stop-Process -Force

Start-Process "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" `
    -ArgumentList "`"$env:LOCALAPPDATA\mac-win-app\scripts\mac-shortcuts.ahk`""
```

## `Ç` appears when typing apostrophe + c

You're on **US-International** and hitting a dead-key combo. Either:

- **Switch to US pure** (recommended for code-heavy work):
  ```powershell
  & "$env:LOCALAPPDATA\mac-win-app\scripts\setup-keyboard-layout.ps1" -Layout US
  ```
- **Learn the escape**: press the quote/tilde key followed by `Space` to get a literal `'`, `"`, `~`, `^`, `` ` ``. For `Ç` specifically, use `AltGr + ,`.

## Accented characters don't work at all

You're on **US pure**. That layout has no dead keys by design. Switch to US-International:

```powershell
& "$env:LOCALAPPDATA\mac-win-app\scripts\setup-keyboard-layout.ps1" -Layout USIntl
```

Then disconnect + reconnect the RDP session.

## Keyboard layout change didn't take effect

Some apps cache the layout at startup. The safe fix:

1. Disconnect the RDP session completely (not just minimize).
2. Reconnect.

If it still doesn't stick, sign out of the Windows user fully (`logoff`) and sign back in.

## `winget` is missing

`winget` ships with "App Installer" from the Microsoft Store. On older Windows 10 it may not be present. Install it:

- Open **Microsoft Store** → search "App Installer" → install.
- Or grab the MSIX bundle from https://aka.ms/getwinget

Then rerun `install.ps1`.

## Pre-existing AutoHotkey v1

AHK v1 and v2 can coexist, but the installer only looks for v2. If `v1` is also installed, no conflict — our script uses `#Requires AutoHotkey v2.0` and will only run under v2.

## The autostart shortcut disappeared

Windows occasionally reshuffles the Startup folder during updates. Recreate it:

```powershell
$startup  = [Environment]::GetFolderPath('Startup')
$ahk      = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$script   = "$env:LOCALAPPDATA\mac-win-app\scripts\mac-shortcuts.ahk"
$link     = Join-Path $startup "mac-win-app.lnk"

$sh = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut($link)
$lnk.TargetPath = $ahk
$lnk.Arguments  = "`"$script`""
$lnk.Save()
```

## I pressed Cmd+Q and closed the RDP session

That's the Windows App doing it, not this script. To prevent: inside the Windows App session settings, turn off **Send Mac shortcut keys** temporarily, or use `Cmd+Ctrl+F` to enter full screen first (which captures system keys inside the session).

## Something's weird and I just want to undo everything

```powershell
iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/uninstall.ps1 | iex
```

Add `-RemoveAutoHotkey -RestoreLayout` for a clean-room reset.

## I have a bug report

Please open an issue at https://github.com/feliperun/mac-win-app/issues with:

- Windows version (`winver`)
- RDP client and its version
- Output of `$env:SESSIONNAME`
- Output of `Get-WinUserLanguageList | Format-List`
- Which shortcut misbehaves and what it does instead
