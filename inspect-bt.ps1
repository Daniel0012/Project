$ErrorActionPreference = 'Continue'

"=== BT radio device + driver ==="
$radio = Get-PnpDevice -Class Bluetooth -PresentOnly | Where-Object { $_.InstanceId -like 'USB\VID_0BDA&PID_4853*' } | Select-Object -First 1
if (-not $radio) { $radio = Get-PnpDevice -Class Bluetooth -PresentOnly | Where-Object { $_.Service -eq 'BTHUSB' } | Select-Object -First 1 }
if ($radio) {
  "FriendlyName: $($radio.FriendlyName)"
  "InstanceId:   $($radio.InstanceId)"
  "Status:       $($radio.Status)"
  Get-PnpDeviceProperty -InstanceId $radio.InstanceId | Sort-Object KeyName | Format-Table KeyName, Data -AutoSize | Out-String -Width 300
} else { "No BT radio found" }

"=== All Bluetooth-class devices (present) ==="
Get-PnpDevice -Class Bluetooth -PresentOnly | Sort-Object FriendlyName | Format-Table Status, FriendlyName, InstanceId -AutoSize | Out-String -Width 260

"=== MEDIA class devices (audio controllers/codecs) ==="
Get-PnpDevice -Class MEDIA | Sort-Object Status -Descending | Format-Table Status, FriendlyName, InstanceId -AutoSize | Out-String -Width 260

"=== Devices named Smart Sound / SST / LE Audio (any state) ==="
Get-PnpDevice | Where-Object { $_.FriendlyName -match 'Smart Sound|SST|LE Audio|LC3' } | ForEach-Object {
  ""
  "FriendlyName: $($_.FriendlyName)"
  "Status: $($_.Status)   Class: $($_.Class)"
  "InstanceId: $($_.InstanceId)"
  Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName DEVPKEY_Device_DriverInfPath, DEVPKEY_Device_DriverVersion, DEVPKEY_Device_DriverDate, DEVPKEY_Device_DriverProvider, DEVPKEY_Device_HardwareIds, DEVPKEY_Device_ProblemCode 2>$null | Format-Table KeyName, Data -AutoSize | Out-String -Width 300
}

"=== WinRT BluetoothAdapter capability dump ==="
try {
  $null = [Windows.Devices.Bluetooth.BluetoothAdapter,Windows.Devices.Bluetooth,ContentType=WindowsRuntime]
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
  $asTask = $asTaskGeneric.MakeGenericMethod([Windows.Devices.Bluetooth.BluetoothAdapter])
  $netTask = $asTask.Invoke($null, @([Windows.Devices.Bluetooth.BluetoothAdapter]::GetDefaultAsync()))
  $null = $netTask.Wait(10000)
  $adapter = $netTask.Result
  if ($adapter) { $adapter | Format-List * } else { "GetDefaultAsync returned null" }
} catch { "WinRT query failed: $_" }

"=== Realtek/Bluetooth entries in BT class key (driver-level settings) ==="
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}'
Get-ChildItem $classKey -ErrorAction SilentlyContinue | ForEach-Object {
  $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
  if ($props.MatchingDeviceId -like '*VID_0BDA*' -or $props.ProviderName -match 'Realtek') {
    ""
    "--- $($_.PSChildName): $($props.DriverDesc) ---"
    $props | Format-List * | Out-String -Width 300
  }
}
