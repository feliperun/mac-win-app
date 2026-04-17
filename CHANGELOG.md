# Changelog

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-04-17

### Added
- `install.ps1` one-liner installer that downloads scripts, installs AutoHotkey v2 via winget, applies a keyboard layout and sets up autostart.
- `uninstall.ps1` that reverses everything created by `install.ps1`.
- `scripts/setup-keyboard-layout.ps1` supporting US pure, US-International and ABNT2 Brazilian layouts.
- `scripts/mac-shortcuts.ahk` with macOS-style shortcuts for cursor navigation, deletion, screenshots and tab switching.
- RDP-only conditional activation (`#HotIf IsRdpSession()`) so the script stays idle on console sessions.
- Documentation: full shortcut reference, how-it-works architecture overview, troubleshooting guide.

[Unreleased]: https://github.com/feliperun/mac-win-app/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/feliperun/mac-win-app/releases/tag/v0.1.0
