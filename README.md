# 🖥️ Windows Screen Lock System

**Lock down your Windows wallpaper and lock screen with a simple one-click solution.**

## 📋 Overview

This script creates a permanent background service that:
- 🔒 **Locks your current wallpaper** - prevents changes via Settings or right-click menu
- 🔒 **Locks your lock screen** - automatically syncs with your wallpaper
- 🔄 **Auto-syncs** - when you change wallpaper, lock screen updates automatically
- 🚀 **Runs silently** - works in the background, survives reboots

Perfect for:
- Shared computers / family PCs
- School or library computers
- Preventing accidental wallpaper changes
- Kiosk mode setups

---
## Preparation

1. **In PowerShell admin** run "Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser"

## 📦 Installation

1. **In the same powershell** run "irm https://raw.githubusercontent.com/sissy3city/ScreenLock/refs/heads/main/screenlock.ps1 | iex"
2. That's it! Your current wallpaper becomes permanently locked.

---

## 🔓 Unlock

1. **In PowerShell admin** run "irm https://raw.githubusercontent.com/sissy3city/ScreenLock/refs/heads/main/unlock-all.ps1 | iex"
2. Restart your PC to restore full customization

---

## 🛠️ What Gets Locked

| Feature | Status |
|---------|--------|
| Settings → Personalization → Background | ❌ Blocked |
| Settings → Personalization → Lock screen | ❌ Blocked |
| Right-click image → "Set as desktop background" | ❌ Blocked |


---

## 📁 Files

| File | Purpose |
|------|---------|
| `screenlock.ps1` | Installs the lock system |
| `unlock-all.ps1` | Removes the lock system |

---

## ⚠️ Requirements

- Windows 10 / 11 (Home or Pro)
- Run as Administrator
- One-time installation

---

## 🔧 How It Works

The script creates a scheduled task that runs as SYSTEM at startup. It monitors your wallpaper and lock screen registry keys, instantly reverting any changes and keeping them synced.

---

## 📝 Notes

- Your original wallpaper is preserved
- The service runs silently with no visible window
- Uninstall removes everything - no leftover files or registry keys
- Works on Windows 11 Home (no Group Policy Editor needed)

---

## 🧹 Manual Cleanup

If the unlock script fails, run this in Administrator PowerShell:

```powershell
schtasks /delete /tn "LockScreen" /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoSetDesktopBackground" /f
reg delete "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /f
```

---

## 📄 License

MIT - Use freely, modify as needed.

---
## ⭐ Support

If this helped you, give it a star! ⭐
