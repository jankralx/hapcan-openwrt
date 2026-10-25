# hapcan-openwrt

OpenWrt firmware for the **HAPCAN Ethernet Interface**, a board that connects a
[HAPCAN](https://hapcan.com) home automation bus (CAN) to Ethernet.

The board carries a Hi-Link HLK-7628N module (MediaTek MT7628, 128 MB RAM,
32 MB flash) running OpenWrt, an STM32 running CANable (slcan) firmware as the
CAN controller, an RTC and an ADC. On the network side it offers:

- the **HAPCAN Ethernet interface protocol on TCP port 1001**, so HAPCAN
  Programmer and other tools can talk to the bus as with the original
  HAPCAN Ethernet module,
- an optional **MQTT gateway** (relays, buttons, RGB, temperature modules, raw frames)
  for Home Assistant, openHAB and others,
- discovery over **mDNS**: `hapcan-xxxx.local` and the `_hapcan._tcp` service.

Both are provided by [hmsg](https://github.com/jankralx/HMSG-openwrt).

## Quick start

Build (needs podman, git and about 15 GB of disk):

```sh
git clone --recurse-submodules https://github.com/jankralx/hapcan-openwrt.git
cd hapcan-openwrt
make image
```

The sysupgrade image and packages land in `out/`. Flash an interface that
already runs OpenWrt:

```sh
make deploy HOST=hapcan-xxxx.local
```

Then connect HAPCAN Programmer to `hapcan-xxxx.local`, port 1001.

## Documentation

| Document | For |
|---|---|
| [docs/device.md](docs/device.md) | using the interface: network access, hmsg configuration, RTC, ADC, recovery |
| [docs/architecture.md](docs/architecture.md) | how hardware, OpenWrt and hmsg fit together, and why the repository looks like this |
| [docs/development.md](docs/development.md) | building, flashing, the test bench, updating OpenWrt, upstreaming |
| [CLAUDE.md](CLAUDE.md) | orientation for AI coding agents working in this repository |

## Repository layout

| Path | What |
|---|---|
| `openwrt/` | submodule: upstream [OpenWrt](https://github.com/openwrt/openwrt) pinned to a release tag, never modified |
| `patches/openwrt/` | board support on top of upstream OpenWrt |
| `feed/` | OpenWrt package feed: `hapcan-base`, `hmsg`, `paho-mqtt-c` |
| `hmsg/` | submodule: [hmsg](https://github.com/jankralx/HMSG-openwrt) gateway source |
| `hardware/` | submodule: [board hardware and STM32 firmware](https://github.com/fatalwir/HAPCAN-Ethernet_interface) |
| `config/hapcan.diffconfig` | OpenWrt build configuration |
| `container/` | build environment |
| `scripts/` | build helpers |
| `tools/` | test tools |

## Related projects

- [HAPCAN-Ethernet_interface](https://github.com/fatalwir/HAPCAN-Ethernet_interface): board design (KiCad) and STM32 firmware
- [HMSG](https://github.com/jankralx/HMSG-openwrt): HAPCAN / MQTT / socket server gateway, forked from [alcp1/HMSG](https://github.com/alcp1/HMSG)
- HAPCAN Programmer: desktop tool to configure HAPCAN modules, connects to TCP port 1001

## License

This repository is licensed under the [GNU General Public License v2.0](LICENSE),
the same as OpenWrt. The submodules have their own licenses: `hmsg/` and
`hardware/` are GPL-3.0, `openwrt/` is GPL-2.0. Packages built from `feed/`
declare their license in `PKG_LICENSE`.
