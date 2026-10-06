# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Not a software project. This is a working directory for troubleshooting Bluetooth LE Audio / audio codecs on this specific PC (goal: best possible Galaxy Buds3 Pro audio). There is no build, lint, or test tooling — the "codebase" is one diagnostic script plus the live system itself. Full investigation history and current experiment state live in the Claude project memory (`buds3-le-audio-investigation.md`); read that before re-diagnosing anything.

## Critical context: machine identity is spoofed

GalaxyBookEnabler makes this PC impersonate a Samsung Galaxy Book (for Quick Share/Multi Control). Identity sources disagree on purpose:

- `HKLM\HARDWARE\DESCRIPTION\System\BIOS` — **spoofed** ("SAMSUNG ... Galaxy Book5 Pro 960XHA"), re-applied at boot by scheduled tasks. Do not trust it; do not "fix" it.
- `Get-CimInstance Win32_ComputerSystem` / `Win32_BaseBoard` — **truthful**: Lenovo LOQ 15IRH8 (82XV), i7-13620H, Windows 11 25H2.

Key hardware: Realtek RTL8852BE Bluetooth (`USB\VID_0BDA&PID_4853\00E04C000001`), Realtek ALC257 audio on Intel SST (`PCI\VEN_8086&DEV_51CA`). Many Samsung services run by design (the spoof's app ecosystem) — they are not malware and not the audio problem.

## Commands

Full Bluetooth/audio stack dump (radio properties, WinRT adapter capabilities, SST device tree, Realtek driver settings):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\inspect-bt.ps1
```

The script must run under Windows PowerShell 5.1 (`powershell.exe`, as shown) — the WinRT `Windows.Devices.Bluetooth` projection it uses does not load in PowerShell 7. Most other work needs an elevated shell (HKLM writes, `pnputil`).

Frequent one-liners:

```powershell
# Did Realtek's LE Audio virtual device appear? (success indicator for the inband experiment)
Get-PnpDevice | Where-Object InstanceId -like 'RTK_BT*'

# Restart the BT radio (drops/reconnects all BT devices for ~5 s)
pnputil /restart-device "USB\VID_0BDA&PID_4853\00E04C000001"

# A2DP codec flag: 1 = AAC (quality), 0 = SBC (user's deliberate game mode — lower encode latency).
# Use .\toggle-bt-codec.ps1 (elevated) to flip modes; don't "fix" a 0 without asking.
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\BthA2dp\Parameters' | Select BluetoothAacEnable
```

## How LE Audio gating works on this machine (the big picture)

Windows shows "Use LE Audio when available" only when a vendor (IHV) ACX audio driver publishes `GUID_BLUETOOTH_LEAUDIO_SUPPORT_INTERFACE`. No inbox/host LC3 path exists for generic adapters, and no Windows registry value or BIOS option can force the toggle (`IsLeAudioSupported`-style keys are Android concepts). The stack here, bottom to top:

1. **Radio**: RTL8852BE, driver `oem225.inf` (Realtek/Lenovo filter `RtkBtFilter2` + `RtkBtManServ`).
2. **Vendor inband gate**: `HKLM\SYSTEM\CurrentControlSet\Services\RtkBtFilter2\Parameters\EnableLeAudioInband` — when honored, the filter enumerates virtual device `RTK_BT\{5DBB7054-7951-4B40-B907-52F1E482C57F}`.
3. **VSAP audio half**: "Realtek Bluetooth LE Audio Driver" (MEDIA class, v2.0.11.x via Windows Update/MS Update Catalog) binds to that RTK_BT device → toggle appears.

Known limits (verified June 2026, sources in memory file): Realtek only enables this for 8852BE-VT/8852CE/8922AE — **the plain 8852BE in this machine ignores the flag (experiment run 2026-06-09: flag + reboot produced no RTK_BT device; flag reverted). Native LE Audio on this radio is a dead end — don't re-run the experiment.** Windows LC3 media is capped at 48 kHz/16-bit — 24-bit/96 kHz is impossible over LE Audio on any PC; Samsung Seamless Codec works only between Samsung phone/tablet and Buds, never on Windows. The Intel "Smart Sound for Bluetooth LE Audio" path (`DEV_AE33`) requires firmware NHLT tables this Lenovo lacks — never reinstall that driver (a previously force-staged copy, `oem202.inf`, was removed).

If LE Audio on this radio proves impossible: best quality fallback is AAC (keep `BluetoothAacEnable=1`), best latency is a USB LC3 dongle, and the verified native-toggle path is swapping the M.2 card to MediaTek MT7925 or Realtek 8922AE.
