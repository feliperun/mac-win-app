<#
.SYNOPSIS
    Uninstalls mac-win-app. Keeps AutoHotkey installed unless -RemoveAutoHotkey is passed.
.DESCRIPTION
    Stops the running AHK script, removes the autostart shortcut, deletes the install
    directory, and (optionally) restores the keyboard layout to US pure.

    Run via one-liner:

        iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/uninstall.ps1 | iex
.PARAMETER InstallDir
    Install location. Defaults to "$env:LOCALAPPDATA\mac-win-app".
.PARAMETER RemoveAutoHotkey
    Also uninstall AutoHotkey v2 via winget.
.PARAMETER RestoreLayout
    Reset keyboard layout to US pure before uninstalling.
.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/feliperun/mac-win-app/main/uninstall.ps1 | iex
.EXAMPLE
    .\uninstall.ps1 -RemoveAutoHotkey -RestoreLayout
.LINK
    https://github.com/feliperun/mac-win-app
#>

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\mac-win-app",
    [switch]$RemoveAutoHotkey,
    [switch]$RestoreLayout
)

$ErrorActionPreference = "Continue"

function Write-Step($num, $msg) { Write-Host "`n>> $num. $msg" -ForegroundColor Cyan }
function Write-Ok($msg)         { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Info($msg)       { Write-Host "   --  $msg" -ForegroundColor Gray }

Write-Host ""
Write-Host "  mac-win-app uninstaller" -ForegroundColor Magenta
Write-Host ""

Write-Step 1 "Stopping mac-shortcuts.ahk"
Get-Process AutoHotkey64 -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        if ($cmdLine -like "*mac-shortcuts.ahk*") {
            Stop-Process -Id $_.Id -Force
            Write-Ok "Stopped PID $($_.Id)"
        }
    } catch {}
}

Write-Step 2 "Removing autostart shortcut"
$startup  = [Environment]::GetFolderPath('Startup')
$linkPath = Join-Path $startup "mac-win-app.lnk"
$legacy   = Join-Path $startup "mac-shortcuts.lnk"
foreach ($p in @($linkPath, $legacy)) {
    if (Test-Path $p) {
        Remove-Item $p -Force
        Write-Ok "Removed $p"
    }
}

Write-Step 3 "Removing install directory"
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
    Write-Ok "Removed $InstallDir"
} else {
    Write-Info "Not present: $InstallDir"
}

if ($RestoreLayout) {
    Write-Step 4 "Restoring keyboard layout (US pure)"
    try {
        $newList = New-WinUserLanguageList -Language "en-US"
        $newList[0].InputMethodTips.Clear()
        $newList[0].InputMethodTips.Add("0409:00000409")
        Set-WinUserLanguageList $newList -Force
        Write-Ok "Layout set to US pure"
    } catch {
        Write-Host "   !! Failed to restore layout: $_" -ForegroundColor Yellow
    }
}

if ($RemoveAutoHotkey) {
    Write-Step 5 "Uninstalling AutoHotkey v2"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall --id AutoHotkey.AutoHotkey --silent | Out-Null
        Write-Ok "AutoHotkey removed"
    } else {
        Write-Info "winget not available; uninstall AutoHotkey manually"
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  mac-win-app uninstalled" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
