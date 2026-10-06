# Flips the Buds3 Pro link between SBC (game mode, lower latency) and AAC (quality mode).
# Run elevated. Buds drop and reconnect within ~5-10 s.
$key = 'HKLM:\SYSTEM\CurrentControlSet\Services\BthA2dp\Parameters'
$cur = (Get-ItemProperty $key).BluetoothAacEnable
$new = if ($cur -eq 0) { 1 } else { 0 }
Set-ItemProperty $key -Name BluetoothAacEnable -Value $new
pnputil /restart-device "USB\VID_0BDA&PID_4853\00E04C000001" | Out-Null
Write-Host ("Switched to: " + ($(if ($new -eq 1) { 'AAC (quality mode)' } else { 'SBC (game mode, lower latency)' })))
