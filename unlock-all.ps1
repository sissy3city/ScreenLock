# ============================================
# UNLOCK SCREEN LOCK SYSTEM
# ============================================

# Run as Administrator check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output "ERROR: Run as Administrator!"
    pause
    exit
}

Write-Output "========================================"
Write-Output "UNLOCKING SCREEN LOCK SYSTEM..."
Write-Output "========================================"


Stop-ScheduledTask -TaskName "AutoLockScreen" -ErrorAction SilentlyContinue | Out-Null
Unregister-ScheduledTask -TaskName "AutoLockScreen" -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
Get-Process -Name "powershell" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine
        if ($cmdLine -like "*AutoLockScreen*") {
            Stop-Process -Id $_.Id -Force
        }
    } catch {}
}

$ExplorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Remove-ItemProperty -Path $ExplorerRegPath -Name "NoSetDesktopBackground" -ErrorAction SilentlyContinue
$WallpaperRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
Remove-ItemProperty -Path $WallpaperRegPath -Name "NoChangingWallPaper" -ErrorAction SilentlyContinue
$SoftwarePolicies = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
Remove-ItemProperty -Path $SoftwarePolicies -Name "NoChangingWallPaper" -ErrorAction SilentlyContinue
$LockScreenRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
Remove-ItemProperty -Path $LockScreenRegPath -Name "NoChangingLockScreen" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $LockScreenRegPath -Name "LockScreenImage" -ErrorAction SilentlyContinue
$CspPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
Remove-ItemProperty -Path $CspPath -Name "LockScreenImagePath" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $CspPath -Name "LockScreenImageStatus" -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\AutoLockScreen.ps1" -Force -ErrorAction SilentlyContinue
Write-Output "Refreshing policies..."
gpupdate /force /target:user > $null 2>&1

# Restart Explorer to apply changes
Write-Output "Restarting Explorer..."
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process "explorer.exe"

Write-Output "========================================"
Write-Output "UNLOCK COMPLETE!" 
Write-Output "========================================"
Write-Output ""
Write-Output "Restart your PC to ensure everything is cleared"
Write-Output ""