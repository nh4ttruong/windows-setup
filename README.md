# Windows Setup Script

> Automate your Windows development environment setup with a simple menu-driven PowerShell script.

## 🚀 Quick Start

Run this one-liner in PowerShell (as Administrator):

```powershell
irm https://raw.githubusercontent.com/nh4ttruong/windows-setup/main/windows-setup.ps1 | iex
```

## 📦 What It Installs

- **Visual Studio Code** - Code editor
- **Unikey** - Vietnamese input method
- **WSL2 + Ubuntu** - Linux environment on Windows
- **Windows Terminal** - Modern terminal with custom theme
- **PowerToys** - Microsoft utilities
- **Telnet Client** - Windows feature

## 📋 Menu Options

```powershell
1. Install Visual Studio Code
2. Install Unikey
3. WSL Setup Menu
4. Enable Telnet Client
5. Activate Windows (MAS)
6. Install PowerToys
9. Install All (Recommended)
```

## ⚡ Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges
- Internet connection

## 🛡️ WSL Features

The WSL submenu includes:
- Install WSL2
- Install Ubuntu (22.04 or 24.04 LTS)
- Setup terminal color theme
- View WSL system info

## 🔧 Manual Download

If the one-liner doesn't work:

```powershell
# Download
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nh4ttruong/windows-setup/main/windows-setup.ps1" -OutFile "windows-setup.ps1"

# Run
PowerShell -ExecutionPolicy Bypass -File "windows-setup.ps1"
```

## ⚠️ Notes

- Script must run as Administrator
- Some installations may require user interaction
- System restart may be needed for WSL
- Windows activation uses community MAS tool

## 🐛 Issues?

Open an [issue](https://github.com/nh4ttruong/windows-setup/issues) if something doesn't work.

---

**Made by [nh4ttruong](https://github.com/nh4ttruong)** • ⭐ Star if helpful!
