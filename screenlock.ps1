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

# ============ CREATE THE SYNC SCRIPT ============
$syncScriptPath = "$env:ProgramData\LockScreen.ps1"

$syncScript = @'
function Get-CurrentWallpaper {
    $WallpaperPath = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Wallpaper
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
    $WallpaperRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
    $SoftwarePolicies = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
    $ExplorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-not (Test-Path $LockScreenRegPath)) { New-Item -Path $LockScreenRegPath -Force | Out-Null }
    if (-not (Test-Path $CspPath)) { New-Item -Path $CspPath -Force | Out-Null }
    if (-not (Test-Path $WallpaperRegPath)) { New-Item -Path $WallpaperRegPath -Force | Out-Null }
    if (-not (Test-Path $SoftwarePolicies)) { New-Item -Path $SoftwarePolicies -Force | Out-Null }
    if (-not (Test-Path $ExplorerRegPath)) { New-Item -Path $ExplorerRegPath -Force | Out-Null }
    Set-ItemProperty -Path $LockScreenRegPath -Name "LockScreenImage" -Value $WallpaperPath -Type String -Force
    Set-ItemProperty -Path $LockScreenRegPath -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $CspPath -Name "LockScreenImagePath" -Value $WallpaperPath -Type String -Force
    Set-ItemProperty -Path $CspPath -Name "LockScreenImageStatus" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $WallpaperRegPath -Name "NoChangingWallPaper" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $SoftwarePolicies -Name "NoChangingWallPaper" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $ExplorerRegPath -Name "NoSetDesktopBackground" -Value 1 -Type DWord -Force
}

$currentWallpaper = Get-CurrentWallpaper
Update-LockScreen -WallpaperPath $currentWallpaper
$lastWallpaper = $currentWallpaper

while ($true) {
    Start-Sleep -Seconds 3
    $newWallpaper = Get-CurrentWallpaper
    if ($newWallpaper -ne $lastWallpaper) {
        Update-LockScreen -WallpaperPath $newWallpaper
        $lastWallpaper = $newWallpaper
    }
}
'@

$syncScript | Out-File -FilePath $syncScriptPath -Encoding UTF8 -Force
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "LockScreen" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

# ============ APPLY LOCK ============
Write-Output "Applying lock..."

$WallpaperRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
if (-not (Test-Path $WallpaperRegPath)) { New-Item -Path $WallpaperRegPath -Force | Out-Null }
Set-ItemProperty -Path $WallpaperRegPath -Name "NoChangingWallPaper" -Value 1 -Type DWord -Force
$SoftwarePolicies = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
if (-not (Test-Path $SoftwarePolicies)) { New-Item -Path $SoftwarePolicies -Force | Out-Null }
Set-ItemProperty -Path $SoftwarePolicies -Name "NoChangingWallPaper" -Value 1 -Type DWord -Force
$ExplorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $ExplorerRegPath)) { New-Item -Path $ExplorerRegPath -Force | Out-Null }
Set-ItemProperty -Path $ExplorerRegPath -Name "NoSetDesktopBackground" -Value 1 -Type DWord -Force
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScriptPath`"" -WindowStyle Hidden

Write-Output "========================================"
Write-Output "INSTALLATION COMPLETE!"
Write-Output "========================================"
Write-Output ""