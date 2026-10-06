$ErrorActionPreference = 'Continue'

"=== Default audio endpoints (WinRT) ==="
try {
  $null = [Windows.Media.Devices.MediaDevice,Windows.Media.Devices,ContentType=WindowsRuntime]
  $defId = [Windows.Media.Devices.MediaDevice]::GetDefaultAudioRenderId([Windows.Media.Devices.AudioDeviceRole]::Default)
  $comId = [Windows.Media.Devices.MediaDevice]::GetDefaultAudioRenderId([Windows.Media.Devices.AudioDeviceRole]::Communications)
  "Default render: $defId"
  "Default comms : $comId"
} catch { "WinRT default-endpoint query failed: $_" }

"`n=== Active render endpoints + attached effects (APOs) ==="
$renderKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
Get-ChildItem $renderKey | ForEach-Object {
  $state = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DeviceState
  if ($state -ne 1) { return }   # active endpoints only
  $guid  = $_.PSChildName
  $props = Get-ItemProperty "$($_.PSPath)\Properties" -ErrorAction SilentlyContinue
  $name  = $props.'{a45c254e-df1c-4efd-8020-67d146a850e0},14'
  $iface = $props.'{026e516e-b814-414b-83cd-856d6fef4822},2'
  $isDef = if ($defId -and $defId -like "*$guid*") { '  <== DEFAULT' } elseif ($comId -and $comId -like "*$guid*") { '  <== DEFAULT-COMMS' } else { '' }
  ""
  "[$guid] $iface / $name$isDef"
  $fx = Get-ItemProperty "$($_.PSPath)\FxProperties" -ErrorAction SilentlyContinue
  if ($fx) {
    $sysfxOff = $fx.'{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5'
    "  Enhancements disabled flag: $sysfxOff"
    $fx.PSObject.Properties | Where-Object { $_.Name -match '^\{d04e05a6|^\{d3993a3f|^\{c18e2f7e|^\{1c7b1faf|^\{ec1cc9ce' } | ForEach-Object {
      "  APO: $($_.Name) = $($_.Value)"
    }
  } else { "  (no FxProperties key - no third-party APO chain)" }
}
