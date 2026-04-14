# ============================================
# INSTALL SCREEN LOCK
# ============================================

# Run as Administrator check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output "ERROR: This script must be run as Administrator!"
    pause
    exit
}

Write-Output "========================================"
Write-Output "Installing Screen Lock System..."
Write-Output "========================================"

$syncScriptPath = "$env:ProgramData\LockScreenSync.ps1"

$syncScript = @'
# Self-elevate to admin if needed
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Get-CurrentWallpaper {
    # Get wallpaper for the currently logged-in user
    $sid = (Get-WmiObject Win32_UserAccount | Where-Object { $_.Name -eq $env:USERNAME }).SID
    $regPath = "Registry::HKEY_USERS\$sid\Control Panel\Desktop"
    
    $WallpaperPath = Get-ItemProperty -Path $regPath -Name "Wallpaper" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Wallpaper
    if (-not $WallpaperPath -or -not (Test-Path $WallpaperPath)) {
        $TranscodedPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Themes\TranscodedWallpaper"
        if (Test-Path $TranscodedPath) { $WallpaperPath = $TranscodedPath }
    }
    return $WallpaperPath
}

function Update-LockScreen {
    param([string]$WallpaperPath)

    $LockScreenRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    $CspPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

    if (-not (Test-Path $LockScreenRegPath)) { New-Item -Path $LockScreenRegPath -Force | Out-Null }
    if (-not (Test-Path $CspPath)) { New-Item -Path $CspPath -Force | Out-Null }

    Set-ItemProperty -Path $LockScreenRegPath -Name "LockScreenImage" -Value $WallpaperPath -Type String -Force
    Set-ItemProperty -Path $LockScreenRegPath -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $CspPath -Name "LockScreenImagePath" -Value $WallpaperPath -Type String -Force
    Set-ItemProperty -Path $CspPath -Name "LockScreenImageStatus" -Value 1 -Type DWord -Force
}

# Initial update
$currentWallpaper = Get-CurrentWallpaper
Update-LockScreen -WallpaperPath $currentWallpaper
$lastWallpaper = $currentWallpaper

# Monitor loop
while ($true) {
    Start-Sleep -Seconds 3
    $newWallpaper = Get-CurrentWallpaper
    if ($newWallpaper -and ($newWallpaper -ne $lastWallpaper)) {
        Update-LockScreen -WallpaperPath $newWallpaper
        $lastWallpaper = $newWallpaper
    }
}
'@

$syncScript | Out-File -FilePath $syncScriptPath -Encoding UTF8 -Force

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartInterval (New-TimeSpan -Minutes 5) -RestartCount 999
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

# Remove old task if exists
Unregister-ScheduledTask -TaskName "LockScreenSync" -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask -TaskName "LockScreenSync" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

$WallpaperRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
if (-not (Test-Path $WallpaperRegPath)) { New-Item -Path $WallpaperRegPath -Force | Out-Null }
Set-ItemProperty -Path $WallpaperRegPath -Name "NoChangingWallPaper" -Value 1 -Type DWord -Force

$SoftwarePolicies = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
if (-not (Test-Path $SoftwarePolicies)) { New-Item -Path $SoftwarePolicies -Force | Out-Null }
Set-ItemProperty -Path $SoftwarePolicies -Name "NoChangingWallPaper" -Value 1 -Type DWord -Force

$ExplorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $ExplorerRegPath)) { New-Item -Path $ExplorerRegPath -Force | Out-Null }
Set-ItemProperty -Path $ExplorerRegPath -Name "NoSetDesktopBackground" -Value 1 -Type DWord -Force

# Start the sync script immediately
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScriptPath`"" -WindowStyle Hidden

Write-Output "========================================"
Write-Output "INSTALLATION COMPLETE!"
Write-Output "========================================"
Write-Output ""
