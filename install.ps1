<#
.SYNOPSIS
    mac-win-app installer: makes a Windows PC feel like a Mac over RDP / Windows App.
.DESCRIPTION
    Installs AutoHotkey v2, configures your keyboard layout (US / US-Intl / ABNT2),
    drops the shortcut script in %LOCALAPPDATA%, and wires up autostart.

    Intended to be invoked via one-liner:

        iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/install.ps1 | iex

    No admin rights required. Current user scope only.
.PARAMETER Layout
    Keyboard layout to apply: US (default), USIntl or ABNT2. Use Ask to prompt.
.PARAMETER InstallDir
    Where the scripts will live. Defaults to "$env:LOCALAPPDATA\mac-win-app".
.PARAMETER SkipAutostart
    Do not create the Startup shortcut. Useful for one-off runs.
.PARAMETER SkipKeyboard
    Do not touch the keyboard layout.
.PARAMETER Ref
    Git ref (branch/tag/commit) to fetch. Defaults to "main".
.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/install.ps1 | iex
.EXAMPLE
    & ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/install.ps1))) -Layout USIntl
.EXAMPLE
    .\install.ps1 -Layout ABNT2 -SkipAutostart
.LINK
    https://github.com/feliperun/mac-win-app
#>

param(
    [ValidateSet("US", "USIntl", "ABNT2", "Ask", "Skip")]
    [string]$Layout = "Ask",

    [string]$InstallDir = "$env:LOCALAPPDATA\mac-win-app",

    [switch]$SkipAutostart,

    [switch]$SkipKeyboard,

    [string]$Ref = "main"
)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$REPO     = "feliperun/mac-win-app"
$RAW_BASE = "https://raw.githubusercontent.com/$REPO/$Ref"
$SCRIPTS  = @("scripts/mac-shortcuts.ahk", "scripts/setup-keyboard-layout.ps1")

function Write-Step($num, $msg) { Write-Host "`n>> $num. $msg" -ForegroundColor Cyan }
function Write-Ok($msg)         { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Info($msg)       { Write-Host "   --  $msg" -ForegroundColor Gray }
function Write-Warn($msg)       { Write-Host "   !!  $msg" -ForegroundColor Yellow }

function Get-AhkExePath {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey32.exe",
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey32.exe"
    )
    foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
    return $null
}

Write-Host ""
Write-Host "  mac-win-app installer" -ForegroundColor Magenta
Write-Host "  makes a Windows PC feel like a Mac over RDP" -ForegroundColor DarkGray
Write-Host "  https://github.com/$REPO" -ForegroundColor DarkGray
Write-Host ""

# -----------------------------------------------------------------------------
# 1. Install AutoHotkey v2
# -----------------------------------------------------------------------------
Write-Step 1 "AutoHotkey v2"
$ahk = Get-AhkExePath
if ($ahk) {
    Write-Ok "Already installed: $ahk"
} else {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found. Install App Installer from the Microsoft Store and retry."
    }
    Write-Info "Installing via winget..."
    winget install --id AutoHotkey.AutoHotkey `
        --accept-source-agreements `
        --accept-package-agreements `
        --silent `
        --scope user | Out-Null
    $ahk = Get-AhkExePath
    if (-not $ahk) { throw "AutoHotkey install finished but executable not found." }
    Write-Ok "Installed: $ahk"
}

# -----------------------------------------------------------------------------
# 2. Download scripts
# -----------------------------------------------------------------------------
Write-Step 2 "Downloading scripts to $InstallDir"
New-Item -ItemType Directory -Force -Path "$InstallDir\scripts" | Out-Null
foreach ($rel in $SCRIPTS) {
    $url  = "$RAW_BASE/$rel"
    $dest = Join-Path $InstallDir $rel
    Write-Info "GET $url"
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Ok  "-> $dest"
}

# -----------------------------------------------------------------------------
# 3. Keyboard layout
# -----------------------------------------------------------------------------
if ($SkipKeyboard -or $Layout -eq "Skip") {
    Write-Step 3 "Keyboard layout: skipped"
} else {
    Write-Step 3 "Keyboard layout"
    $kbScript = Join-Path $InstallDir "scripts\setup-keyboard-layout.ps1"
    & $kbScript -Layout $Layout
}

# -----------------------------------------------------------------------------
# 4. Start the AHK script now
# -----------------------------------------------------------------------------
Write-Step 4 "Starting mac-shortcuts.ahk"
$ahkScript = Join-Path $InstallDir "scripts\mac-shortcuts.ahk"

Get-Process AutoHotkey64 -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        if ($cmdLine -like "*mac-shortcuts.ahk*") {
            Write-Info "Stopping previous instance (PID $($_.Id))"
            Stop-Process -Id $_.Id -Force
        }
    } catch {}
}

Start-Process -FilePath $ahk -ArgumentList "`"$ahkScript`"" | Out-Null
Start-Sleep -Milliseconds 800
Write-Ok "Running"

# -----------------------------------------------------------------------------
# 5. Autostart
# -----------------------------------------------------------------------------
if ($SkipAutostart) {
    Write-Step 5 "Autostart: skipped"
} else {
    Write-Step 5 "Autostart"
    $startup  = [Environment]::GetFolderPath('Startup')
    $linkPath = Join-Path $startup "mac-win-app.lnk"
    $legacy   = Join-Path $startup "mac-shortcuts.lnk"

    if (Test-Path $legacy) {
        Remove-Item $legacy -Force
        Write-Info "Removed legacy autostart: $legacy"
    }

    $sh  = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($linkPath)
    $lnk.TargetPath       = $ahk
    $lnk.Arguments        = "`"$ahkScript`""
    $lnk.WorkingDirectory = Split-Path $ahkScript
    $lnk.IconLocation     = "$ahk,0"
    $lnk.Description      = "mac-win-app - macOS shortcuts for RDP sessions"
    $lnk.Save()
    Write-Ok "Created: $linkPath"
}

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  mac-win-app is ready" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Session detected: $env:SESSIONNAME" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Windows App -> Settings -> Keyboard"
Write-Host "     Enable 'Send Mac shortcut keys as Windows shortcut keys'"
Write-Host "  2. Disconnect + reconnect the RDP session (keyboard layout kicks in)"
Write-Host "  3. Try Cmd+Left, Option+Left, Cmd+Shift+4 inside the session"
Write-Host ""
Write-Host "Uninstall anytime:" -ForegroundColor DarkGray
Write-Host "  iwr -useb https://raw.githubusercontent.com/$REPO/$Ref/uninstall.ps1 | iex"
Write-Host ""
