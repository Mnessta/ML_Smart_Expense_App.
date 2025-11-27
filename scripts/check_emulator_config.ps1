# Android Emulator Configuration Checker
# This script helps diagnose and fix "System UI isn't responding" issues

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Android Emulator Configuration Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check available RAM
Write-Host "Checking System Resources..." -ForegroundColor Yellow
try {
    $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    Write-Host "  Total RAM: $([math]::Round($totalRAM, 2)) GB" -ForegroundColor White
    
    try {
        $availableRAM = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue / 1024
        Write-Host "  Available RAM: $([math]::Round($availableRAM, 2)) GB" -ForegroundColor White
    } catch {
        Write-Host "  Available RAM: Unable to determine" -ForegroundColor Gray
    }
} catch {
    Write-Host "  WARNING: Could not determine system RAM" -ForegroundColor Red
    $totalRAM = 0
}

if ($totalRAM -gt 0) {
    if ($totalRAM -lt 8) {
        Write-Host "  WARNING: System has less than 8GB RAM" -ForegroundColor Red
        Write-Host "     Recommendation: Close other applications before running emulator" -ForegroundColor Yellow
    } elseif ($totalRAM -lt 16) {
        Write-Host "  OK: System RAM is adequate (8-16GB)" -ForegroundColor Green
    } else {
        Write-Host "  OK: System RAM is excellent (16GB+)" -ForegroundColor Green
    }
}

Write-Host ""

# Check disk space
Write-Host "Checking Disk Space..." -ForegroundColor Yellow
$drive = Get-PSDrive C
$freeSpaceGB = $drive.Free / 1GB
$totalSpaceGB = ($drive.Used + $drive.Free) / 1GB

Write-Host "  C: Drive Free Space: $([math]::Round($freeSpaceGB, 2)) GB" -ForegroundColor White
Write-Host "  C: Drive Total Space: $([math]::Round($totalSpaceGB, 2)) GB" -ForegroundColor White

if ($freeSpaceGB -lt 10) {
    Write-Host "  WARNING: Low disk space (< 10GB free)" -ForegroundColor Red
    Write-Host "     Recommendation: Free up disk space" -ForegroundColor Yellow
} else {
    Write-Host "  OK: Disk space is adequate" -ForegroundColor Green
}

Write-Host ""

# Check Android SDK location
Write-Host "Checking Android SDK..." -ForegroundColor Yellow
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
if (Test-Path $sdkPath) {
    Write-Host "  OK: Android SDK found at: $sdkPath" -ForegroundColor Green
    
    # Check emulator
    $emulatorPath = "$sdkPath\emulator\emulator.exe"
    if (Test-Path $emulatorPath) {
        Write-Host "  OK: Android Emulator found" -ForegroundColor Green
        
        # List available AVDs
        Write-Host ""
        Write-Host "Available Emulators:" -ForegroundColor Yellow
        try {
            $avds = & "$emulatorPath" -list-avds
            foreach ($avd in $avds) {
                Write-Host "  - $avd" -ForegroundColor White
            }
        } catch {
            Write-Host "  Could not list emulators" -ForegroundColor Gray
        }
    } else {
        Write-Host "  WARNING: Android Emulator not found" -ForegroundColor Red
    }
    
    # Check ADB
    $adbPath = "$sdkPath\platform-tools\adb.exe"
    if (Test-Path $adbPath) {
        Write-Host "  OK: ADB found" -ForegroundColor Green
        
        # Check running emulators
        Write-Host ""
        Write-Host "Running Emulators:" -ForegroundColor Yellow
        try {
            $devices = & "$adbPath" devices
            $deviceCount = ($devices | Select-String "emulator").Count
            if ($deviceCount -gt 0) {
                Write-Host "  OK: $deviceCount emulator(s) currently running" -ForegroundColor Green
                $devices | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
            } else {
                Write-Host "  No emulators currently running" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Could not check running devices" -ForegroundColor Gray
        }
    } else {
        Write-Host "  WARNING: ADB not found" -ForegroundColor Red
    }
} else {
    Write-Host "  WARNING: Android SDK not found at default location" -ForegroundColor Red
    Write-Host "     Expected: $sdkPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# RAM recommendations
if ($totalRAM -gt 0) {
    if ($totalRAM -ge 16) {
        Write-Host "Recommended Emulator RAM: 4096 MB (4GB)" -ForegroundColor Green
    } elseif ($totalRAM -ge 8) {
        Write-Host "Recommended Emulator RAM: 2048 MB (2GB)" -ForegroundColor Green
    } else {
        Write-Host "Recommended Emulator RAM: 1536 MB (1.5GB) - Limited by system RAM" -ForegroundColor Yellow
    }
} else {
    Write-Host "Recommended Emulator RAM: 2048 MB (2GB) - Default recommendation" -ForegroundColor Green
}

Write-Host "Recommended VM Heap: 256 MB" -ForegroundColor Green
Write-Host "Recommended Internal Storage: 6-8 GB" -ForegroundColor Green
Write-Host "Recommended Graphics Mode: Software (if issues persist, try Hardware)" -ForegroundColor Green
Write-Host ""

Write-Host "To apply these settings:" -ForegroundColor Yellow
Write-Host "1. Open Android Studio -> Device Manager" -ForegroundColor White
Write-Host "2. Click arrow next to your emulator -> Edit" -ForegroundColor White
Write-Host "3. Click 'Show Advanced Settings'" -ForegroundColor White
Write-Host "4. Apply the recommended values above" -ForegroundColor White
Write-Host "5. Change Graphics to 'Software'" -ForegroundColor White
Write-Host "6. Disable: Device Frame, Camera, Simulated Sensors" -ForegroundColor White
Write-Host ""

Write-Host "Quick Fixes:" -ForegroundColor Yellow
Write-Host "- If emulator is running, try: Wipe Data in Device Manager" -ForegroundColor White
Write-Host "- Close Chrome, VS Code, and other heavy applications" -ForegroundColor White
Write-Host "- Restart the emulator after changing settings" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
