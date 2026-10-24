# CLAUDE.md

OpenWrt firmware for the HAPCAN Ethernet Interface (HLK-7628N / MT7628 board
bridging a HAPCAN CAN bus to Ethernet). Read `README.md`, then
`docs/architecture.md` for how things fit and `docs/development.md` for workflows.

## Layout rules

- `openwrt/` is upstream OpenWrt pinned to a release tag. Never modify it.
  Board changes go to `patches/openwrt/*.patch`, made with `git format-patch`
  in `build/openwrt` (see docs/development.md).
- `build/` and `out/` are generated. `build/openwrt` is a git worktree of the
  submodule with the patches applied as commits. `scripts/prepare.sh` resets
  it, so do not keep work there.
- Use-case behaviour (services, defaults, hotplug) belongs in the
  `feed/hapcan-base` package, not in the OpenWrt patch. The patch holds only
  hardware description.
- `hmsg/` is a separate repository (submodule). Its C sources use CRLF line
  endings, so preserve them (e.g. Python `open(..., newline='')`).
- `hardware/` is a separate repository owned by another maintainer. Don't change it from here.

## Commands

```sh
make image                     # full build in podman → out/
make packages                  # only hmsg + hapcan-base
make deploy                    # sysupgrade $(HOST) with out/ image
make deploy-hmsg               # install new hmsg without reflashing
make test                      # TCP <-> CAN <-> HAPCAN USB interface check
make console                   # serial console, 57600 baud
```

The first build takes 15–60 minutes, so run it in the background. Bench
settings (`HOST`, `TTY`, `HAPCAN_TTY`) are in `local.mk`, which is untracked.

## Device facts

- OpenWrt 25.12: package manager is `apk`, not `opkg`. BusyBox `ip` has no
  `-br`, and there is no `timeout` command.
- Network: `lan` static fallback `192.168.168.100/24` plus `lan_dhcp` DHCP client on
  `br-lan`. mDNS `hapcan-xxxx.local` and `_hapcan._tcp`.
- CAN: `/dev/ttyACM0` (STM32 CANable, slcan) → `slcand` → `can0` at 125 kbit/s.
  HAPCAN frames are 29-bit IDs: type(12) | response flag(1) | node(8) | group(8).
- hmsg config `/etc/hmsg/config.json`, TCP port 1001, logs `logread -e hmsg`.
- Serial console: UART0, 57600 8N1, root shell without login.

## Verifying changes

After a change to anything that runs on the device: build, `make deploy`
(`SYSUPGRADE_FLAGS="-v -n"` to test first-boot behaviour), wait for boot, and
run `make test`. For network or mDNS changes, also check
`avahi-browse -rt _hapcan._tcp` from the PC.

## Public repository

This repository is public. Keep personal or site-specific data (IP addresses
of a bench, serial numbers, local paths, emails other than maintainer
addresses already in package Makefiles) out of tracked files. Put it in `local.mk`.
