<#
.SYNOPSIS
    Configures Windows keyboard layout for Mac users accessing via Windows App / RDP.
.DESCRIPTION
    Switches the current user's input method between:
      - US pure            -> best for code, no dead keys
      - US-International   -> dead keys enabled ('+a=a, ~+a=~a, AltGr+,=c-cedilla)
      - ABNT2 (BR)         -> Brazilian keyboard (if your Mac uses ABNT2)

    Removes conflicting layouts to prevent accidental language switching.
    Only affects the current user (no admin required).
.NOTES
    Windows 10/11. After running, disconnect+reconnect the RDP session.
.EXAMPLE
    .\setup-keyboard-layout.ps1
    .\setup-keyboard-layout.ps1 -Layout US
    .\setup-keyboard-layout.ps1 -Layout USIntl -KeepPortuguese
    .\setup-keyboard-layout.ps1 -Layout ABNT2
.LINK
    https://github.com/feliperun/mac-win-app
#>

param(
    [ValidateSet("US", "USIntl", "ABNT2", "Ask")]
    [string]$Layout = "Ask",

    [switch]$KeepPortuguese
)

$ErrorActionPreference = "Stop"

function Write-Step($num, $msg) { Write-Host "`n>> $num. $msg" -ForegroundColor Cyan }
function Write-Ok($msg)         { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Info($msg)       { Write-Host "   --  $msg" -ForegroundColor Gray }
function Write-Warn($msg)       { Write-Host "   !!  $msg" -ForegroundColor Yellow }

$LAYOUTS = @{
    "US"     = @{ Tip = "0409:00000409"; Lang = "en-US"; Label = "US (pure, no dead keys)"  }
    "USIntl" = @{ Tip = "0409:00020409"; Lang = "en-US"; Label = "US-International (dead keys)" }
    "ABNT2"  = @{ Tip = "0416:00000416"; Lang = "pt-BR"; Label = "Portuguese (Brazil ABNT2)" }
}

Write-Step 1 "Current keyboard state"
$current = Get-WinUserLanguageList
foreach ($lang in $current) {
    Write-Info "Language: $($lang.LanguageTag)  ($($lang.LocalizedName))"
    foreach ($tip in $lang.InputMethodTips) {
        Write-Info "   input: $tip"
    }
}

if ($Layout -eq "Ask") {
    Write-Host ""
    Write-Host "Choose layout:" -ForegroundColor Yellow
    Write-Host "  [1] US pure           (quotes/tildes are literal; no native c-cedilla)"
    Write-Host "  [2] US-International  (dead keys: ' + a = a-accent; AltGr+, = c-cedilla)"
    Write-Host "  [3] ABNT2 (Brazilian) (for Mac ABNT2 keyboards)"
    Write-Host ""
    $choice = Read-Host "Option (1/2/3)"
    switch ($choice) {
        "1" { $Layout = "US" }
        "2" { $Layout = "USIntl" }
        "3" { $Layout = "ABNT2" }
        default { throw "Invalid option. Aborting." }
    }
}

$selected = $LAYOUTS[$Layout]
Write-Step 2 "Applying $($selected.Label) ($($selected.Tip))"

$newList = New-WinUserLanguageList -Language $selected.Lang
$newList[0].InputMethodTips.Clear()
$newList[0].InputMethodTips.Add($selected.Tip)

if ($KeepPortuguese -and $selected.Lang -ne "pt-BR") {
    $pt = $current | Where-Object { $_.LanguageTag -like "pt*" } | Select-Object -First 1
    if ($pt) {
        Write-Info "Preserving $($pt.LanguageTag) with the selected keyboard"
        $ptLang = New-WinUserLanguageList -Language $pt.LanguageTag
        $ptLang[0].InputMethodTips.Clear()
        $ptLang[0].InputMethodTips.Add($selected.Tip)
        $newList.Add($ptLang[0])
    }
}

Set-WinUserLanguageList $newList -Force
Write-Ok "Language/keyboard list updated"

Write-Step 3 "Verification"
$after = Get-WinUserLanguageList
foreach ($lang in $after) {
    Write-Info "Language: $($lang.LanguageTag)  ($($lang.LocalizedName))"
    foreach ($tip in $lang.InputMethodTips) {
        $mark = if ($tip -eq $selected.Tip) { "<-- active" } else { "" }
        Write-Info "   input: $tip $mark"
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " Layout configured: $($selected.Label)" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Warn "Disconnect + reconnect the Windows App session to apply."
Write-Host ""
Write-Host "Test with:  @ # [ ] { } \ | ``  ~  '  """ -ForegroundColor Gray
if ($Layout -eq "USIntl") {
    Write-Host "Tip US-Intl: for literal ' or "" press the key then SPACE" -ForegroundColor Gray
    Write-Host "Tip US-Intl: c-cedilla = AltGr + ,    n-tilde = ~ then n" -ForegroundColor Gray
}
