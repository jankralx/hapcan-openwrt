# Development

## Requirements

- Linux with podman (rootless works) and git
- about 15 GB of disk for a build tree, 4 GB RAM or more
- first build: 15–60 minutes depending on CPU cores (toolchain included),
  later builds a few minutes

The build runs in a Debian container (`container/Containerfile`), so the host
needs no OpenWrt build dependencies. The repository is mounted at the same
path inside the container, so paths in logs match the host.

## Make targets

| Target | What |
|---|---|
| `make image` | full build, results in `out/` |
| `make prepare` | only set up `build/openwrt` (worktree, patches, feeds, `.config`) |
| `make packages` | build `hmsg` and `hapcan-base` (and their dependencies) |
| `make menuconfig` | OpenWrt menuconfig in the build tree |
| `make diffconfig` | print the minimal config of the build tree |
| `make shell` | shell in the build container |
| `make deploy` | copy the image to `$(HOST)` and sysupgrade |
| `make deploy-hmsg` | install the freshly built hmsg and paho packages on `$(HOST)` |
| `make test` | bridge test against `$(HOST)` with a HAPCAN USB interface on `$(HAPCAN_TTY)` |
| `make console` | serial console on `$(TTY)` (minicom, 57600) |
| `make flash-stm32` | flash the STM32 CANable firmware over SWD (ST-Link, STM32CubeProgrammer) |
| `make clean` | remove `build/` and `out/` |

`HOST`, `TTY`, `HAPCAN_TTY`, `JOBS` and `SYSUPGRADE_FLAGS` can be set on the
command line or in `local.mk`, which is ignored by git. Keep anything specific
to your setup (addresses, serial port paths) there, not in tracked files:

```make
HOST = hapcan-xxxx.local
TTY = /dev/serial/by-id/usb-FTDI_FT230X_Basic_UART_<serial>-if00-port0
HAPCAN_TTY = /dev/serial/by-id/usb-FTDI_HAPCAN_Interface_<serial>-if00-port0
```

## Test bench

A useful bench is:

- the interface, Ethernet to the PC (e.g. a NetworkManager "shared"
  connection, which provides DHCP),
- the interface serial console (UART0) to the PC through a USB-UART adapter,
- the HAPCAN bus with a few modules and an original HAPCAN USB interface
  connected to the PC, for `make test`,
- optionally an ST-Link on the STM32 SWD header.

`make test` (`tools/hapcan-bridge-test.py`) sends a read-only hardware type
request over TCP and over the USB interface, and checks that each arrives on
the other side:

```
sent via TCP: 10 30 fd fd ff ff 00 00 ff ff ff ff
  tcp: 5 frames ...
  usb: 5 frames ...
TCP->CAN->USB: OK | USB->CAN->TCP: OK
```

## Working on hmsg

hmsg source is the `hmsg/` submodule. `feed/hmsg/Makefile` copies
`hmsg/SW` into the build, and `PKG_FILE_DEPENDS` makes it rebuild when the
source changes.

```sh
$EDITOR hmsg/SW/source/...
make packages deploy-hmsg
ssh root@$HOST logread -f -e hmsg
```

The hmsg sources use CRLF line endings. Keep them when editing.

Commit hmsg changes in the submodule, push them to the hmsg repository, then
commit the new submodule pointer here.

## Working on the board support patch

The patch in `patches/openwrt/` is plain `git format-patch` output. To change it:

```sh
make prepare                       # build/openwrt has the patch applied as a commit
cd build/openwrt
$EDITOR target/linux/ramips/dts/mt7628an_hapcan_interface.dts
git commit -a --amend
git format-patch -1 -o ../../patches/openwrt/ --zero-commit --no-signature
```

Remove the old patch file if the subject (and so the file name) changed.

## Changing the configuration

Add packages or options to `config/hapcan.diffconfig`. `scripts/prepare.sh`
fails if a `=y` line of it does not survive `make defconfig` (usually a
missing dependency). To find the right symbols, use `make menuconfig` and
`make diffconfig`.

## Updating OpenWrt

```sh
git -C openwrt fetch --tags
git -C openwrt checkout v25.12.N
make prepare         # fails if a patch does not apply; fix as above
make image && make deploy && make test
git add openwrt patches && git commit -m "Update OpenWrt to v25.12.N"
```

## Releases

1. Update the version of changed packages (`PKG_VERSION`/`PKG_RELEASE` in `feed/*/Makefile`).
2. Tag the repository (`git tag -a vX.Y.Z`). The build embeds `git describe` as
   the firmware version (`/etc/openwrt_release`, `DISTRIB_REVISION`).
3. `make clean image`, run the test bench, and attach `out/*` to a GitHub release.

## Upstreaming

| What | Where | Status |
|---|---|---|
| `kmod-rtc-bq32k`, `kmod-iio-mcp3422` | openwrt/openwrt | merged, in 25.12 |
| `paho-mqtt-c` package | openwrt/packages | candidate, not yet submitted |
| board support patch | openwrt/openwrt | possible once the hardware is publicly available |
| hmsg build fixes, CAN reconnect | alcp1/HMSG | candidates |

## Known limitations

- hmsg opens `can0` only at start and does not reconnect. The `can0` hotplug
  script restarts hmsg as a workaround. A reconnect inside hmsg would be better.
- Kernel module packages from the official OpenWrt repositories do not match
  this kernel. Build needed modules with the image.
