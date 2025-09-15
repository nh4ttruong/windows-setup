#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Development Environment Setup Script with WSL Sub-menu
.DESCRIPTION
    A comprehensive script to set up common development tools and utilities on Windows
.AUTHOR
    nh4ttruong
.VERSION
    1.0.0
#>

# Handle execution policy
function Set-ExecutionPolicyIfNeeded {
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope Process
        if ($currentPolicy -eq 'Restricted') {
            Write-Host "Setting execution policy for this session..." -ForegroundColor Yellow
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
            Write-Host "Execution policy updated successfully" -ForegroundColor Green
        }
    } catch {
        Write-Host "Could not update execution policy: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
        exit 1
    }
}

# Set execution policy at the start
Set-ExecutionPolicyIfNeeded

# Script configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Color scheme configuration for WSL
$WSLColorScheme = @{
    name = "coolnight"
    background = "#010C18"
    black = "#0B3B61"
    blue = "#1376F9"
    brightBlack = "#63686D"
    brightBlue = "#388EFF"
    brightCyan = "#FF6AD7"
    brightGreen = "#74FFD8"
    brightPurple = "#AE81FF"
    brightRed = "#FF54B0"
    brightWhite = "#60FBBF"
    brightYellow = "#FCF5AE"
    cursorColor = "#38FF9D"
    cyan = "#FF5ED4"
    foreground = "#ECDEF4"
    green = "#52FFD0"
    purple = "#C792EA"
    red = "#FF3A3A"
    selectionBackground = "#38FF9C"
    white = "#16FDA2"
    yellow = "#FFF383"
}

# Functions
function Write-ColorText {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Clear-Host
    $separator = "=" * 80
    Write-Host $separator -ForegroundColor Cyan
    Write-Host " Windows Development Environment Setup" -ForegroundColor Yellow
    if ($Title) {
        Write-Host " $Title" -ForegroundColor Green
    }
    Write-Host " Script by: nh4ttruong | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host $separator -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-ColorText "[STEP] $Message" -Color Yellow
}

function Write-Success {
    param([string]$Message)
    Write-ColorText "[SUCCESS] $Message" -Color Green
}

function Write-Error {
    param([string]$Message)
    Write-ColorText "[ERROR] $Message" -Color Red
}

function Write-Warning {
    param([string]$Message)
    Write-ColorText "[WARNING] $Message" -Color Yellow
}

function Write-Info {
    param([string]$Message)
    Write-ColorText "[INFO] $Message" -Color Cyan
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-InternetConnection {
    try {
        $response = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
        return $response
    } catch {
        return $false
    }
}

function Show-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

function Install-Winget {
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Step "Installing Windows Package Manager (winget)..."
        try {
            Show-Progress -Activity "Installing Winget" -Status "Downloading installer..." -PercentComplete 25
            
            # Check if App Installer is available
            $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
            if (-not $appInstaller) {
                Write-Step "Installing App Installer..."
                $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                $downloadUrl = ($releases.assets | Where-Object { $_.name -like "*msixbundle" }).browser_download_url
                $tempFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
                
                Show-Progress -Activity "Installing Winget" -Status "Downloading App Installer..." -PercentComplete 50
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile
                
                Show-Progress -Activity "Installing Winget" -Status "Installing package..." -PercentComplete 75
                Add-AppxPackage -Path $tempFile
                Remove-Item $tempFile -Force
            }
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Show-Progress -Activity "Installing Winget" -Status "Completed" -PercentComplete 100
            Write-Progress -Activity "Installing Winget" -Completed
            Write-Success "Winget installed successfully"
            Start-Sleep -Seconds 1
        } catch {
            Write-Progress -Activity "Installing Winget" -Completed
            Write-Error "Failed to install winget: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Success "Winget is already installed"
    }
    return $true
}

# WSL Functions
function Get-WSLStatus {
    try {
        $null = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            return "installed"
        } else {
            return "not_installed"
        }
    } catch {
        return "not_installed"
    }
}

function Get-WSLDistributions {
    try {
        $distributions = wsl --list --verbose 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $distributions
        } else {
            return @()
        }
    } catch {
        return @()
    }
}

function Install-WSL2 {
    Write-Header "Installing WSL2"
    Write-Info "Windows Subsystem for Linux allows you to run Linux environment directly on Windows"
    Write-Host ""
    
    try {
        Show-Progress -Activity "Installing WSL2" -Status "Checking current status..." -PercentComplete 10
        Write-Step "Checking WSL status..."
        
        $wslStatus = Get-WSLStatus
        if ($wslStatus -eq "installed") {
            Write-Success "WSL is already installed"
        } else {
            Show-Progress -Activity "Installing WSL2" -Status "Installing WSL components..." -PercentComplete 50
            Write-Step "Installing WSL2..."
            wsl --install --no-distribution | Out-Null
            
            Show-Progress -Activity "Installing WSL2" -Status "Setting WSL2 as default..." -PercentComplete 80
            Write-Step "Setting WSL2 as default version..."
            wsl --set-default-version 2 | Out-Null
        }
        
        Show-Progress -Activity "Installing WSL2" -Status "Completed" -PercentComplete 100
        Write-Progress -Activity "Installing WSL2" -Completed
        Write-Success "WSL2 setup completed"
        Write-Warning "A restart may be required for WSL2 to work properly"
        
    } catch {
        Write-Progress -Activity "Installing WSL2" -Completed
        Write-Error "Failed to install WSL2: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Install-Ubuntu {
    Write-Header "Installing Ubuntu for WSL2"
    Write-Info "Ubuntu is a popular Linux distribution perfect for development"
    Write-Host ""
    
    # Check if WSL is installed first
    if ((Get-WSLStatus) -eq "not_installed") {
        Write-Warning "WSL2 is not installed. Please install WSL2 first."
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-ColorText "Available Ubuntu versions:" -Color Cyan
    Write-Host ""
    Write-Host "   1. Ubuntu 22.04 LTS (Jammy Jellyfish) - Recommended for stability"
    Write-Host "   2. Ubuntu 24.04 LTS (Noble Numbat) - Latest features"
    Write-Host "   3. Both versions - Install both for maximum flexibility"
    Write-Host ""
    
    do {
        $choice = Read-Host "Select Ubuntu version (1-3)"
    } while ($choice -notmatch '^[1-3]$')
    
    try {
        switch ($choice) {
            "1" {
                Show-Progress -Activity "Installing Ubuntu" -Status "Installing Ubuntu 22.04 LTS..." -PercentComplete 50
                Write-Step "Installing Ubuntu 22.04 LTS..."
                wsl --install -d Ubuntu-22.04 | Out-Null
                wsl --set-default Ubuntu-22.04 | Out-Null
                Write-Success "Ubuntu 22.04 LTS set as default"
            }
            "2" {
                Show-Progress -Activity "Installing Ubuntu" -Status "Installing Ubuntu 24.04 LTS..." -PercentComplete 50
                Write-Step "Installing Ubuntu 24.04 LTS..."
                wsl --install -d Ubuntu-24.04 | Out-Null
                wsl --set-default Ubuntu-24.04 | Out-Null
                Write-Success "Ubuntu 24.04 LTS set as default"
            }
            "3" {
                Show-Progress -Activity "Installing Ubuntu" -Status "Installing Ubuntu 22.04 LTS..." -PercentComplete 33
                Write-Step "Installing Ubuntu 22.04 LTS..."
                wsl --install -d Ubuntu-22.04 | Out-Null
                
                Show-Progress -Activity "Installing Ubuntu" -Status "Installing Ubuntu 24.04 LTS..." -PercentComplete 66
                Write-Step "Installing Ubuntu 24.04 LTS..."
                wsl --install -d Ubuntu-24.04 | Out-Null
                wsl --set-default Ubuntu-24.04 | Out-Null
                Write-Success "Ubuntu 24.04 LTS set as default"
            }
        }
        
        Show-Progress -Activity "Installing Ubuntu" -Status "Completed" -PercentComplete 100
        Write-Progress -Activity "Installing Ubuntu" -Completed
        Write-Success "Ubuntu installation initiated successfully"
        Write-Info "Ubuntu setup will continue in a new window"
        Write-Warning "Follow the prompts to create a username and password"
        
    } catch {
        Write-Progress -Activity "Installing Ubuntu" -Completed
        Write-Error "Failed to install Ubuntu: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Setup-WSLColorScheme {
    Write-Header "Setting up WSL Color Scheme"
    Write-Info "Configuring 'Cool Night' color scheme for a beautiful terminal experience"
    Write-Host ""
    
    try {
        $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        
        Show-Progress -Activity "Configuring Color Scheme" -Status "Checking Windows Terminal..." -PercentComplete 20
        
        if (Test-Path $settingsPath) {
            Show-Progress -Activity "Configuring Color Scheme" -Status "Backing up settings..." -PercentComplete 40
            Write-Step "Backing up current Windows Terminal settings..."
            Copy-Item $settingsPath "$settingsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            
            Show-Progress -Activity "Configuring Color Scheme" -Status "Applying color scheme..." -PercentComplete 70
            Write-Step "Configuring 'Cool Night' color scheme..."
            
            $settings = Get-Content $settingsPath | ConvertFrom-Json
            
            # Add color scheme if it doesn't exist
            if (-not ($settings.schemes | Where-Object { $_.name -eq $WSLColorScheme.name })) {
                if (-not $settings.schemes) {
                    $settings | Add-Member -NotePropertyName "schemes" -NotePropertyValue @()
                }
                $settings.schemes += $WSLColorScheme
            }
            
            # Set as default for WSL profiles
            foreach ($profile in $settings.profiles.list) {
                if ($profile.source -like "*WSL*" -or $profile.commandline -like "*wsl*" -or $profile.name -like "*Ubuntu*") {
                    $profile | Add-Member -NotePropertyName "colorScheme" -NotePropertyValue $WSLColorScheme.name -Force
                }
            }
            
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
            
            Show-Progress -Activity "Configuring Color Scheme" -Status "Completed" -PercentComplete 100
            Write-Progress -Activity "Configuring Color Scheme" -Completed
            Write-Success "'Cool Night' color scheme configured successfully"
        } else {
            Write-Warning "Windows Terminal not found. Installing Windows Terminal..."
            Show-Progress -Activity "Configuring Color Scheme" -Status "Installing Windows Terminal..." -PercentComplete 50
            winget install --id Microsoft.WindowsTerminal --silent --accept-package-agreements --accept-source-agreements | Out-Null
            
            Show-Progress -Activity "Configuring Color Scheme" -Status "Completed" -PercentComplete 100
            Write-Progress -Activity "Configuring Color Scheme" -Completed
            Write-Success "Windows Terminal installed. Color scheme will be applied after first launch."
        }
    } catch {
        Write-Progress -Activity "Configuring Color Scheme" -Completed
        Write-Error "Failed to configure WSL color scheme: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-WSLInfo {
    Write-Header "WSL System Information"
    
    try {
        Write-ColorText "WSL Status and Information:" -Color Cyan
        Write-Host ""
        
        # WSL Installation Status
        $wslStatus = Get-WSLStatus
        $statusText = if ($wslStatus -eq "installed") { "Installed" } else { "Not Installed" }
        Write-Host "   WSL Status: $statusText"
        
        if ($wslStatus -eq "installed") {
            # Show WSL version
            try {
                $null = wsl --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   WSL Version: Available"
                }
            } catch {
                Write-Host "   WSL Version: Classic WSL"
            }
            
            # Show installed distributions
            Write-Host ""
            Write-ColorText "Installed Linux Distributions:" -Color Cyan
            
            $distributions = Get-WSLDistributions
            if ($distributions.Count -gt 1) {
                foreach ($line in $distributions[1..($distributions.Count-1)]) {
                    if ($line.Trim() -ne "") {
                        $parts = $line -split '\s+', 3
                        if ($parts.Count -ge 3) {
                            $name = $parts[0] -replace '\*', ''
                            $running = if ($parts[1] -eq "Running") { "Running" } else { "Stopped" }
                            $version = $parts[2]
                            $default = if ($line.StartsWith("*")) { "(Default)" } else { "" }
                            Write-Host "   $name - $running - WSL $version $default"
                        }
                    }
                }
            } else {
                Write-Host "   No distributions installed"
            }
        }
        
        Write-Host ""
        
        # Windows Terminal Status
        $terminalPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        $terminalStatus = if (Test-Path $terminalPath) { "Installed" } else { "Not Installed" }
        Write-Host "   Windows Terminal: $terminalStatus"
        
        # Color scheme status
        if (Test-Path $terminalPath) {
            try {
                $settings = Get-Content $terminalPath | ConvertFrom-Json
                $colorSchemeExists = $settings.schemes | Where-Object { $_.name -eq $WSLColorScheme.name }
                $colorSchemeStatus = if ($colorSchemeExists) { "Configured" } else { "Not Configured" }
                Write-Host "   Cool Night Theme: $colorSchemeStatus"
            } catch {
                Write-Host "   Cool Night Theme: Unable to check"
            }
        }
        
        Write-Host ""
        
    } catch {
        Write-Error "Failed to retrieve WSL information: $($_.Exception.Message)"
    }
    
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Install-AllWSL {
    Write-Header "Complete WSL Setup"
    Write-Info "This will set up a complete WSL development environment"
    Write-Host ""
    
    Write-Warning "This process will:"
    Write-Host "   • Install WSL2 if not already installed"
    Write-Host "   • Install Windows Terminal"
    Write-Host "   • Configure Cool Night color scheme"
    Write-Host "   • Install Ubuntu (your choice of version)"
    Write-Host "   • May require a system restart"
    Write-Host ""
    
    $confirm = Read-Host "Continue with complete WSL setup? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        $startTime = Get-Date
        
        Write-Step "Starting complete WSL setup..."
        Write-Host ""
        
        # Install WSL2 first
        Write-Info "Step 1/3: Installing WSL2..."
        Install-WSL2
        
        # Setup color scheme
        Write-Info "Step 2/3: Configuring color scheme..."
        Setup-WSLColorScheme
        
        # Install Ubuntu
        Write-Info "Step 3/3: Installing Ubuntu..."
        Install-Ubuntu
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Header "WSL Setup Complete!"
        Write-Success "Complete WSL environment has been configured!"
        Write-Host ""
        Write-ColorText "Setup time: $($duration.Minutes) minutes and $($duration.Seconds) seconds" -Color Green
        Write-Host ""
        Write-Info "What was configured:"
        Write-Host "   • WSL2 installed and configured"
        Write-Host "   • Windows Terminal with Cool Night theme"
        Write-Host "   • Ubuntu Linux distribution"
        Write-Host ""
        Write-Info "Next steps:"
        Write-Host "   • Open Windows Terminal"
        Write-Host "   • Select Ubuntu from the dropdown"
        Write-Host "   • Complete Ubuntu user setup"
        Write-Host "   • Enjoy your new Linux environment!"
        Write-Host ""
        
        if ((Get-WSLStatus) -eq "not_installed") {
            Write-Warning "A restart is required for WSL2 to work properly"
            $restart = Read-Host "Restart now? (y/N)"
            if ($restart -eq 'y' -or $restart -eq 'Y') {
                Write-Step "Restarting computer in 5 seconds..."
                Start-Sleep -Seconds 5
                Restart-Computer -Force
            }
        }
    } else {
        Write-ColorText "WSL setup cancelled" -Color Yellow
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-WSLMenu {
    do {
        Write-Header "WSL (Windows Subsystem for Linux) Setup"
        
        # Show current WSL status
        $wslStatus = Get-WSLStatus
        $statusText = if ($wslStatus -eq "installed") { "Installed" } else { "Not Installed" }
        Write-ColorText "Current WSL Status: $statusText" -Color $(if ($wslStatus -eq "installed") { "Green" } else { "Red" })
        
        # Show installed distributions count
        if ($wslStatus -eq "installed") {
            $distributions = Get-WSLDistributions
            $distroCount = if ($distributions.Count -gt 1) { $distributions.Count - 1 } else { 0 }
            Write-ColorText "Installed distributions: $distroCount" -Color Cyan
        }
        
        Write-Host ""
        Write-ColorText "WSL Setup Options:" -Color Cyan
        Write-Host ""
        Write-Host "   1. Install WSL2"
        Write-Host "   2. Install Ubuntu for WSL2"
        Write-Host "   3. Setup Cool Night Color Scheme"
        Write-Host "   4. View WSL System Information"
        Write-Host ""
        Write-Host "   9. Complete WSL Setup (All-in-one)"
        Write-Host "   0. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select WSL option (0-4, 9)"
        
        switch ($choice) {
            "1" { Install-WSL2 }
            "2" { Install-Ubuntu }
            "3" { Setup-WSLColorScheme }
            "4" { Show-WSLInfo }
            "9" { Install-AllWSL }
            "0" { return }
            default { 
                Write-Warning "Invalid option. Please select 0-4 or 9."
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# Other application installation functions
function Install-VSCode {
    Write-Header "Installing Visual Studio Code"
    Write-Info "Visual Studio Code is a free, lightweight, and powerful code editor"
    Write-Host ""
    
    try {
        Show-Progress -Activity "Installing VS Code" -Status "Starting installation..." -PercentComplete 10
        Write-Step "Downloading and installing VS Code..."
        
        Show-Progress -Activity "Installing VS Code" -Status "Installing via winget..." -PercentComplete 50
        winget install --id Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements | Out-Null
        
        Show-Progress -Activity "Installing VS Code" -Status "Configuring PATH..." -PercentComplete 90
        # Add to PATH if not already there
        $vscodePath = "${env:ProgramFiles}\Microsoft VS Code\bin"
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$vscodePath*") {
            $newPath = "$currentPath;$vscodePath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            Write-Success "VS Code added to PATH"
        }
        
        Show-Progress -Activity "Installing VS Code" -Status "Completed" -PercentComplete 100
        Write-Progress -Activity "Installing VS Code" -Completed
        Write-Success "VS Code installed successfully"
        Write-Info "You can now run 'code' from command line to open VS Code"
        
    } catch {
        Write-Progress -Activity "Installing VS Code" -Completed
        Write-Error "Failed to install VS Code: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Install-Unikey {
    Write-Header "Installing Unikey"
    Write-Info "Unikey is a Vietnamese input method for typing Vietnamese text"
    Write-Host ""
    
    try {
        Show-Progress -Activity "Installing Unikey" -Status "Accessing download page..." -PercentComplete 25
        Write-Step "Checking latest Unikey version..."
        
        # Try to get the latest Unikey download URL
        $unikeyPage = Invoke-WebRequest -Uri "https://www.unikey.org/download.html" -UseBasicParsing
        $downloadLink = ($unikeyPage.Links | Where-Object { $_.href -like "*setup*" -or $_.href -like "*install*" }).href | Select-Object -First 1
        
        if ($downloadLink) {
            if ($downloadLink -notmatch "^https?://") {
                $downloadLink = "https://www.unikey.org" + $downloadLink
            }
            
            $tempFile = "$env:TEMP\unikey-setup.exe"
            
            Show-Progress -Activity "Installing Unikey" -Status "Downloading installer..." -PercentComplete 50
            Write-Step "Downloading Unikey installer..."
            Invoke-WebRequest -Uri $downloadLink -OutFile $tempFile -UseBasicParsing
            
            Show-Progress -Activity "Installing Unikey" -Status "Running installer..." -PercentComplete 75
            Write-Step "Running Unikey installer..."
            Write-Warning "Please follow the installation wizard that will appear"
            Start-Process -FilePath $tempFile -Wait
            
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            Show-Progress -Activity "Installing Unikey" -Status "Completed" -PercentComplete 100
            Write-Progress -Activity "Installing Unikey" -Completed
            Write-Success "Unikey installation completed"
        } else {
            throw "Could not find download link"
        }
    } catch {
        Write-Progress -Activity "Installing Unikey" -Completed
        Write-Error "Failed to install Unikey automatically: $($_.Exception.Message)"
        Write-Warning "Opening Unikey download page in browser..."
        Start-Process "https://www.unikey.org/download.html"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Enable-Telnet {
    Write-Header "Enabling Telnet Client"
    Write-Info "Telnet client allows you to connect to remote servers using the Telnet protocol"
    Write-Host ""
    
    try {
        Show-Progress -Activity "Enabling Telnet" -Status "Checking current status..." -PercentComplete 30
        Write-Step "Checking if Telnet Client is already enabled..."
        
        $telnetFeature = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient
        
        if ($telnetFeature.State -eq "Enabled") {
            Write-Success "Telnet Client is already enabled"
        } else {
            Show-Progress -Activity "Enabling Telnet" -Status "Enabling feature..." -PercentComplete 70
            Write-Step "Enabling Telnet Client feature..."
            Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart | Out-Null
            
            Show-Progress -Activity "Enabling Telnet" -Status "Completed" -PercentComplete 100
            Write-Success "Telnet Client enabled successfully"
        }
        
        Write-Progress -Activity "Enabling Telnet" -Completed
        Write-Info "You can now use 'telnet' command from command line"
        
    } catch {
        Write-Progress -Activity "Enabling Telnet" -Completed
        Write-Error "Failed to enable Telnet Client: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Activate-Windows {
    Write-Header "Windows Activation"
    Write-Info "Microsoft Activation Scripts (MAS) - Community tool for Windows activation"
    Write-Host ""
    
    Write-Warning "Important Information:"
    Write-Host "   • This uses Microsoft Activation Scripts from massgrave.dev"
    Write-Host "   • This is a community-maintained activation tool"
    Write-Host "   • Please ensure you understand the implications"
    Write-Host "   • Use at your own discretion"
    Write-Host ""
    
    Write-ColorText "More info: https://massgrave.dev/" -Color Blue
    Write-Host ""
    
    $confirm = Read-Host "Do you want to proceed with Windows activation? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            Show-Progress -Activity "Windows Activation" -Status "Downloading MAS script..." -PercentComplete 50
            Write-Step "Downloading and running MAS activation script..."
            irm https://massgrave.dev/get | iex
            
            Show-Progress -Activity "Windows Activation" -Status "Completed" -PercentComplete 100
            Write-Progress -Activity "Windows Activation" -Completed
            Write-Success "Activation script executed successfully"
        } catch {
            Write-Progress -Activity "Windows Activation" -Completed
            Write-Error "Failed to run activation script: $($_.Exception.Message)"
            Write-Warning "You can manually visit: https://massgrave.dev/"
        }
    } else {
        Write-ColorText "Windows activation skipped" -Color Yellow
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Install-PowerToys {
    Write-Header "Installing PowerToys"
    Write-Info "Microsoft PowerToys - A set of utilities for power users to tune and streamline Windows"
    Write-Host ""
    
    try {
        Show-Progress -Activity "Installing PowerToys" -Status "Installing via winget..." -PercentComplete 50
        Write-Step "Installing Microsoft PowerToys..."
        winget install --id Microsoft.PowerToys --silent --accept-package-agreements --accept-source-agreements | Out-Null
        
        Show-Progress -Activity "Installing PowerToys" -Status "Completed" -PercentComplete 100
        Write-Progress -Activity "Installing PowerToys" -Completed
        Write-Success "PowerToys installed successfully"
        
        Write-Host ""
        Write-Info "PowerToys includes these awesome utilities:"
        Write-Host "   • FancyZones - Advanced window manager"
        Write-Host "   • PowerRename - Bulk file rename utility"
        Write-Host "   • File Locksmith - Unlock files in use"
        Write-Host "   • ColorPicker - Pick colors from anywhere"
        Write-Host "   • PowerToys Run - Quick launcher (Alt+Space)"
        Write-Host "   • Screen Ruler - Measure pixels on screen"
        Write-Host "   • PowerToys Peek - Quick file preview"
        Write-Host "   • Keyboard Manager - Remap keys"
        Write-Host "   • Mouse utilities - Enhanced mouse features"
        Write-Host "   And many more!"
        Write-Host ""
        Write-Info "Tip: Press Alt+Space to open PowerToys Run after installation"
        
    } catch {
        Write-Progress -Activity "Installing PowerToys" -Completed
        Write-Error "Failed to install PowerToys: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SystemInfo {
    Write-Header "System Information"
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem
        $processor = Get-CimInstance -ClassName Win32_Processor
        
        Write-ColorText "System Details:" -Color Cyan
        Write-Host ""
        Write-Host "   OS: $($os.Caption) $($os.Version)"
        Write-Host "   Architecture: $($os.OSArchitecture)"
        Write-Host "   Computer: $($computer.Manufacturer) $($computer.Model)"
        Write-Host "   Processor: $($processor.Name)"
        Write-Host "   Total RAM: $([math]::Round($computer.TotalPhysicalMemory / 1GB, 2)) GB"
        Write-Host "   User: $env:USERNAME"
        Write-Host "   PowerShell: $($PSVersionTable.PSVersion)"
        Write-Host "   Internet: $(if (Test-InternetConnection) { 'Connected' } else { 'Disconnected' })"
        Write-Host ""
        
        # Show Windows features status
        Write-ColorText "Windows Features Status:" -Color Cyan
        Write-Host ""
        
        $features = @(
            @{Name="TelnetClient"; Display="Telnet Client"},
            @{Name="Microsoft-Windows-Subsystem-Linux"; Display="WSL"},
            @{Name="VirtualMachinePlatform"; Display="Virtual Machine Platform"}
        )
        
        foreach ($feature in $features) {
            try {
                $status = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue
                $statusText = if ($status.State -eq "Enabled") { "Enabled" } else { "Disabled" }
                Write-Host "   $($feature.Display): $statusText"
            } catch {
                Write-Host "   $($feature.Display): Unknown"
            }
        }
        
        Write-Host ""
        
    } catch {
        Write-Error "Failed to retrieve system information: $($_.Exception.Message)"
    }
    
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Menu {
    Write-Header "Main Menu"
    
    # Check internet connection
    $internetStatus = if (Test-InternetConnection) { "Connected" } else { "Disconnected" }
    Write-ColorText "Internet Status: $internetStatus" -Color $(if (Test-InternetConnection) { "Green" } else { "Red" })
    
    if (-not (Test-InternetConnection)) {
        Write-Warning "Some features may not work without internet connection"
    }
    
    Write-Host ""
    Write-ColorText "Available Setup Options:" -Color Cyan
    Write-Host ""
    Write-Host "   1. Install Visual Studio Code"
    Write-Host "   2. Install Unikey (Vietnamese Input)"
    Write-Host "   3. WSL Setup Menu"
    Write-Host "   4. Enable Telnet Client"
    Write-Host "   5. Activate Windows (MAS)"
    Write-Host "   6. Install PowerToys"
    Write-Host ""
    Write-Host "   9. Install All (Recommended)"
    Write-Host "   s. Show System Information"
    Write-Host "   0. Exit"
    Write-Host ""
}

function Install-All {
    Write-Header "Complete System Setup"
    Write-Info "This will install all components for a complete development environment"
    Write-Host ""
    
    Write-Warning "This process will:"
    Write-Host "   • Install multiple applications"
    Write-Host "   • Set up complete WSL environment"
    Write-Host "   • Take several minutes to complete"
    Write-Host "   • May require a system restart"
    Write-Host "   • Require user interaction for some installers"
    Write-Host ""
    
    $confirm = Read-Host "Continue with complete installation? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        $startTime = Get-Date
        
        Write-Step "Starting complete system setup..."
        Write-Host ""
        
        # Install all components
        Install-VSCode
        Install-Unikey
        Install-AllWSL
        Enable-Telnet
        Install-PowerToys
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Header "Installation Complete!"
        Write-Success "All components have been installed successfully!"
        Write-Host ""
        Write-ColorText "Installation time: $($duration.Minutes) minutes and $($duration.Seconds) seconds" -Color Green
        Write-Host ""
        Write-Info "What was installed:"
        Write-Host "   • Visual Studio Code"
        Write-Host "   • Unikey (Vietnamese Input)"
        Write-Host "   • Complete WSL2 environment with Ubuntu"
        Write-Host "   • Windows Terminal with Cool Night theme"
        Write-Host "   • Telnet Client"
        Write-Host "   • PowerToys"
        Write-Host ""
        Write-Warning "Please restart your computer to ensure all features work properly"
        Write-Host ""
        
        $restart = Read-Host "Restart now? (y/N)"
        if ($restart -eq 'y' -or $restart -eq 'Y') {
            Write-Step "Restarting computer in 5 seconds..."
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        }
    } else {
        Write-ColorText "Complete installation cancelled" -Color Yellow
    }
}

function Main {
    # Initial setup
    Write-Host ""
    Write-Host "Windows Development Environment Setup Script" -ForegroundColor Green
    Write-Host "Created by: nh4ttruong | Version 1.3.2" -ForegroundColor Gray
    Write-Host "GitHub: https://github.com/nh4ttruong" -ForegroundColor Blue
    Write-Host ""
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator!"
        Write-Host ""
        Write-ColorText "To run as Administrator:" -Color Yellow
        Write-Host "   1. Right-click on PowerShell"
        Write-Host "   2. Select 'Run as Administrator'"
        Write-Host "   3. Run the script again"
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    # Check internet connection
    if (-not (Test-InternetConnection)) {
        Write-Warning "No internet connection detected!"
        Write-Host "Some features require internet access. Please check your connection."
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    }
    
    # Install winget if not available
    if (-not (Install-Winget)) {
        Write-Warning "Failed to install winget. Some features may not work."
        Write-Host "Press any key to continue anyway..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    do {
        Show-Menu
        $choice = Read-Host "Select an option (0-6, 9, s)"
        
        switch ($choice.ToLower()) {
            "1" { Install-VSCode }
            "2" { Install-Unikey }
            "3" { Show-WSLMenu }
            "4" { Enable-Telnet }
            "5" { Activate-Windows }
            "6" { Install-PowerToys }
            "9" { Install-All }
            "s" { Show-SystemInfo }
            "0" { 
                Write-Header "Thank You!"
                Write-ColorText "Thank you for using Windows Setup Script!" -Color Green
                Write-ColorText "Created by nh4ttruong" -Color Gray
                Write-ColorText "Website: https://nh4ttruong.me" -Color Blue
                Write-ColorText "GitHub: https://github.com/nh4ttruong" -Color Blue
                Write-Host ""
                Write-Host "Happy coding!" -ForegroundColor Yellow
                Write-Host ""
                exit 0
            }
            default { 
                Write-Warning "Invalid option. Please select 0-6, 9, or 's'."
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# Run the main function
Main