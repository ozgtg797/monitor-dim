# MonitorDim

A tiny free menu bar app that controls the real brightness of your external monitor on Apple Silicon Macs.

It talks to the monitor over DDC/CI, the same channel the monitor's own buttons use, so the backlight actually goes down. No overlay, no washed-out colors.

## Install

1. Download `MonitorDim.dmg` from [Releases](../../releases) and drag MonitorDim to Applications.
2. Open it. macOS will say it can't verify the app, because it isn't signed with a paid Apple Developer ID.
3. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to MonitorDim. You only do this once.

A sun icon appears in the menu bar. Click it and drag the slider. Turn on **Launch at Login** in the same menu if you want it to start with your Mac.

## Requirements

- Mac with Apple Silicon (M1 or newer)
- macOS 14 or newer
- A monitor with DDC/CI turned on (most monitors have it on by default; check the monitor's own settings menu if the slider does nothing)

Some docks, adapters and DisplayLink connections don't pass DDC through. If it doesn't work, try a direct USB-C or HDMI cable.

Tested on Mac mini M4 (macOS 26) and MacBook Pro M4 Pro (macOS 27) with an LG HDR 4K.

## Build from source

Needs Xcode Command Line Tools (`xcode-select --install`).

```sh
./build.sh      # build/MonitorDim.app
./make-dmg.sh   # build/MonitorDim.dmg
```

`build/ddc-test` is a small command line tool: run it to read the brightness, or `build/ddc-test 40` to set it.

## How it works

On Apple Silicon, macOS exposes each external display as an `IOAVService`. MonitorDim writes standard DDC/CI "set VCP feature" packets for brightness (VCP code `0x10`) to it over I²C. These are private Apple APIs, which is why the app can't be on the Mac App Store.

The approach comes from the open source projects [m1ddc](https://github.com/waydabber/m1ddc) and [MonitorControl](https://github.com/MonitorControl/MonitorControl).

## License

MIT
