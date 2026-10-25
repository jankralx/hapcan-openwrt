# Architecture

## Hardware

```
             HAPCAN bus (CAN, 125 kbit/s)
                       │
              ┌────────┴────────┐
              │ CAN transceiver │
              └────────┬────────┘
                       │
              ┌────────┴────────┐  USB (CDC ACM, slcan)
              │ STM32F072       ├──────────────┐
              │ CANable firmware│              │
              └─────────────────┘   ┌──────────┴───────────┐
                                    │ HLK-7628N (MT7628)   │── Ethernet
   BQ32000 RTC  (I2C 0x68) ─────────┤ OpenWrt              │
   MCP3422 ADC  (I2C 0x6e) ─────────┤ 128 MB RAM, 32 MB    │── UART0 console
                                    └──────────────────────┘     (57600 8N1)
```

Board design and STM32 firmware: the `hardware/` submodule
([HAPCAN-Ethernet_interface](https://github.com/fatalwir/HAPCAN-Ethernet_interface)).

## Software on the device

| Component | Package | Role |
|---|---|---|
| `slcand` service | `hapcan-base`, `canutils-slcand` | attaches `/dev/ttyACM0` as `can0` (125 kbit/s), restarts when the CANable reappears |
| `can0` hotplug | `hapcan-base` | brings `can0` up |
| hmsg | `hmsg` | `can0` ⇄ TCP server (port 1001, HAPCAN Ethernet protocol) ⇄ MQTT |
| umdns | `umdns` | announces `hapcan-xxxx.local` and `_hapcan._tcp` |
| NTP → RTC hotplug | `hapcan-base` | writes NTP time to the BQ32000 |
| uci-defaults | `hapcan-base` | unique hostname, DHCP client next to the static fallback |
| kernel drivers | device packages | `slcan`, `can-raw`, `cdc-acm`, `rtc-bq32k`, `mcp3422`, `i2c-mt7628` |

Boot sequence for the CAN path:

1. USB enumerates the CANable as `/dev/ttyACM0`. The tty hotplug script (or the
   `slcand` init script at boot) starts `slcand`.
2. `slcand` creates `can0`. The net hotplug script brings it up.
3. hmsg retries opening `can0` every second until it succeeds, and does the
   same after a read or write error (e.g. when the CANable is unplugged).
   It does not need a restart when `can0` comes and goes.

The DHCP and DNS servers (`dnsmasq`, `odhcpd`) are left out of the image,
because the interface is a client on someone else's network. Wi-Fi drivers
stay in the image, but Wi-Fi is disabled by default.

## Build

```
openwrt/ (submodule, upstream tag) ──git worktree──▶ build/openwrt/
patches/openwrt/*.patch ─────────────git am────────▶      │
feed/ ───────────────────────────────src-link──────▶      │ feeds/hapcan
hmsg/ (submodule) ◀── feed/hmsg/Makefile copies the source │
config/hapcan.diffconfig ──────────── .config ────▶       │
                                                          ▼
                                       make world (in Docker/podman container)
                                                          ▼
                                       out/*-sysupgrade.bin, *.apk
```

`scripts/prepare.sh` does all the arrows above. It is idempotent and re-applies
the patches only when the patches or the pinned OpenWrt commit change.

## Design decisions

**Upstream OpenWrt as a pinned submodule plus patches, not a fork.** The
board needs about 40 lines in OpenWrt (device tree, image definition, two
`board.d` entries). A fork would carry the whole OpenWrt history and make
release updates a merge job. With patches, an update is: move the submodule
to the new tag, check that the patches still apply.

**Board behaviour lives in a package (`hapcan-base`), not in OpenWrt's target
directories.** The patch then contains only hardware description, which is
what upstream OpenWrt would accept. Everything specific to the HAPCAN use
case (services, defaults) is a normal package that can be updated with `apk`.

**hmsg as a submodule, built from the local checkout.** The release image
contains exactly the commit the submodule points to. During development,
changes in `hmsg/` are built without committing and installed with
`make deploy-hmsg`.

**Hardware as a submodule.** Each firmware release records which board
revision and STM32 firmware it was made for, and `make flash-stm32` can flash
the STM32 from the same checkout. It is marked `shallow` because the build
does not need it.

**OpenWrt 25.12.** The BQ32000 and MCP3422 kernel module packages are in
upstream OpenWrt from 25.12 on. Earlier releases needed them as extra patches.

**Static fallback plus DHCP plus mDNS.** DHCP and mDNS make the interface
usable on a normal network without configuration. The static
`192.168.168.100` allows a direct cable to a PC, which can take `.1` of that
subnet. The subnet is unusual so that it rarely collides with home networks.

## History

This repository replaces an earlier setup spread over several repositories,
which are no longer maintained:

- `fatalwir/openwrt` (branches `hapcan`, `k01_hapcan_podman`): OpenWrt 24.10 fork with the board
  support, the kernel module packages and a podman environment,
- `jankralx/openwrt-hapcan-packages`: feed with the hmsg package,
- `jankralx/openwrt-extra-packages`: feed with paho-mqtt-c.
