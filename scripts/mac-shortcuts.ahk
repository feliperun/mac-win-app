#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
;  mac-shortcuts.ahk
;  Brings macOS keyboard shortcuts to Windows when accessed via RDP / Windows
;  App from a MacBook.
;
;  Requires "Send Mac shortcut keys as Windows shortcut keys" enabled in the
;  Windows App. That makes Cmd (left of the spacebar on Mac) arrive here as
;  Ctrl. What the Windows App does NOT translate (line/word navigation, line
;  delete, screenshots, tab cycling) is handled by this script.
;
;  CONDITIONAL ACTIVATION:
;    Shortcuts ONLY fire when the current session is RDP (Windows App).
;    On console sessions (physical keyboard) the script stays idle and does
;    not interfere with normal PC usage.
;
;  How to use:
;    1. Install AutoHotkey v2:  winget install AutoHotkey.AutoHotkey
;    2. Double-click this .ahk to start
;    3. To launch on startup, drop a shortcut in shell:startup
;
;  AHK symbols:
;    ^ = Ctrl (what arrives when you press Cmd on Mac)
;    ! = Alt  (what arrives when you press Option on Mac)
;    + = Shift
;    # = Win
;
;  Repo: https://github.com/feliperun/mac-win-app
; =============================================================================

; -----------------------------------------------------------------------------
;  Detect whether the current session is RDP (Windows App) or console (local)
; -----------------------------------------------------------------------------
IsRdpSession() {
    sessionName := EnvGet("SESSIONNAME")
    return InStr(sessionName, "RDP") > 0 || InStr(sessionName, "ICA") > 0
}

; #HotIf: all hotkeys below ONLY fire in RDP sessions.
; On console sessions the script stays alive but intercepts nothing.
#HotIf IsRdpSession()

; --------------------------------------------------------------
;  CURSOR NAVIGATION (Cmd+arrows, Option+arrows) macOS style
; --------------------------------------------------------------

; Cmd + Left/Right  ->  Home / End   (start / end of line)
^Left::  Send "{Home}"
^Right:: Send "{End}"

; Cmd + Shift + Left/Right  ->  select to start / end of line
^+Left::  Send "+{Home}"
^+Right:: Send "+{End}"

; Cmd + Up/Down  ->  top / bottom of document
^Up::   Send "^{Home}"
^Down:: Send "^{End}"

; Cmd + Shift + Up/Down  ->  select to top / bottom of document
^+Up::   Send "+^{Home}"
^+Down:: Send "+^{End}"

; Option + Left/Right  ->  jump word
!Left::  Send "^{Left}"
!Right:: Send "^{Right}"

; Option + Shift + Left/Right  ->  select word
!+Left::  Send "^+{Left}"
!+Right:: Send "^+{Right}"

; --------------------------------------------------------------
;  DELETION macOS style
; --------------------------------------------------------------

; Cmd + Backspace  ->  delete to start of line
^Backspace:: Send "+{Home}{Del}"

; Option + Backspace  ->  delete word to the left
!Backspace:: Send "^{Backspace}"

; Fn + Delete on Mac is already forward Delete natively; no mapping needed.

; --------------------------------------------------------------
;  WINDOWS / APPLICATIONS
; --------------------------------------------------------------

; Cmd + H  ->  minimize active window (Mac: hide)
^h:: Send "#{Down}"

; Cmd + M  ->  minimize active window
^m:: Send "#{Down}"

; Cmd + `  (backtick)  ->  switch between windows of same app
; No exact Windows equivalent; Alt+Esc is the closest.
^SC029:: Send "!{Esc}"    ; SC029 = ` key on US layout

; Cmd + Q  ->  close window (Alt+F4 equivalent)
; Commented: many Windows apps (Chrome/Edge) use Ctrl+Q legitimately.
; Uncomment if you never rely on Ctrl+Q for anything else:
; ^q:: Send "!{F4}"

; --------------------------------------------------------------
;  SCREENSHOTS macOS style
; --------------------------------------------------------------

; Cmd + Shift + 3  ->  full screen print (Windows: Win+PrintScreen)
^+3:: Send "#{PrintScreen}"

; Cmd + Shift + 4  ->  selected area print (Windows: Win+Shift+S)
^+4:: Send "#+s"

; Cmd + Shift + 5  ->  screenshot panel on Mac; here we reuse Snipping Tool
^+5:: Send "#+s"

; --------------------------------------------------------------
;  TAB NAVIGATION (browser / IDE)
; --------------------------------------------------------------

; Cmd + Option + Left/Right  ->  previous / next tab
^!Left::  Send "^+{Tab}"
^!Right:: Send "^{Tab}"

; Cmd + Shift + [ / ]  ->  previous / next tab (Chrome/VSCode Mac style)
^+[:: Send "^+{Tab}"
^+]:: Send "^{Tab}"

; --------------------------------------------------------------
;  TRAY ICON / SCRIPT CONTROL
; --------------------------------------------------------------

#HotIf   ; end of conditional block (hotkeys below always apply)

TraySetIcon "shell32.dll", 44
A_IconTip := IsRdpSession()
    ? "mac-win-app - ACTIVE (RDP session)"
    : "mac-win-app - idle (console session)"

; Pause/resume with Ctrl+Alt+P (useful if any shortcut is disruptive)
^!p:: {
    Suspend -1
    if A_IsSuspended
        TrayTip "mac-win-app", "Paused (Ctrl+Alt+P to resume)", 1
    else
        TrayTip "mac-win-app", "Active", 1
}
