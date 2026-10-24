# HAPCAN Ethernet Interface firmware
#
#   make image          build the sysupgrade image into out/
#   make packages       build only the hapcan feed packages (hmsg, ...)
#   make deploy         flash out/ image to $(HOST) with sysupgrade
#   make deploy-hmsg    install freshly built hmsg on $(HOST) without reflashing
#   make test           TCP <-> CAN <-> HAPCAN USB interface ($(HAPCAN_TTY)) test
#
# Local settings (HOST, TTY, ...) can go to local.mk, which is not tracked.

-include local.mk

HOST ?= 192.168.168.100
TTY ?= /dev/ttyUSB0
HAPCAN_TTY ?= /dev/ttyUSB1
JOBS ?= $(shell nproc)
SYSUPGRADE_FLAGS ?= -v

REPO := $(CURDIR)
BUILD := build/openwrt
TARGET_BIN := $(BUILD)/bin/targets/ramips/mt76x8
FEED_BIN := $(BUILD)/bin/packages/mipsel_24kc/hapcan
OUT := out

CONTAINER := hapcan-openwrt-build
TTYFLAG := $(shell [ -t 0 ] && echo -t)
RUN := podman run --rm -i $(TTYFLAG) --userns=keep-id --security-opt label=disable \
	-v $(REPO):$(REPO) -w $(REPO) $(CONTAINER)

SSH := ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$(HOST)
SCP := scp -O -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

.PHONY: all container prepare image packages menuconfig diffconfig shell \
	deploy deploy-hmsg test console flash-stm32 clean

all: image

container: build/.container
build/.container: container/Containerfile
	podman build -t $(CONTAINER) container
	@mkdir -p build && touch $@

prepare: build/.container
	$(RUN) scripts/prepare.sh

image: prepare
	$(RUN) make -C $(BUILD) -j$(JOBS) download world
	rm -rf $(OUT) && mkdir -p $(OUT)
	cp $(TARGET_BIN)/*-hapcan_interface-squashfs-sysupgrade.bin \
		$(TARGET_BIN)/*.manifest $(OUT)/
	cp $(FEED_BIN)/*.apk $(OUT)/
	cd $(OUT) && sha256sum * > sha256sums
	@ls -l $(OUT)

packages: prepare
	$(RUN) make -C $(BUILD) -j$(JOBS) package/hmsg/compile package/hapcan-base/compile

menuconfig: prepare
	$(RUN) make -C $(BUILD) menuconfig

# Print the minimal config of the current build tree, to update config/hapcan.diffconfig
diffconfig:
	@$(RUN) sh -c 'cd $(BUILD) && ./scripts/diffconfig.sh'

shell: build/.container
	$(RUN) bash

deploy:
	$(SCP) $(OUT)/*-sysupgrade.bin root@$(HOST):/tmp/sysupgrade.bin
	$(SSH) sysupgrade $(SYSUPGRADE_FLAGS) /tmp/sysupgrade.bin || true
	@echo "flashing, the device reboots (about 2 minutes)"

deploy-hmsg:
	$(SCP) $(FEED_BIN)/hmsg-*.apk $(FEED_BIN)/libpaho-mqtt-c-*.apk root@$(HOST):/tmp/
	$(SSH) 'apk add --allow-untrusted /tmp/hmsg-*.apk /tmp/libpaho-mqtt-c-*.apk && rm /tmp/*.apk && /etc/init.d/hmsg restart'

test:
	tools/hapcan-bridge-test.py $(HOST) $(HAPCAN_TTY)

console:
	minicom -D $(TTY) -b 57600

flash-stm32:
	hardware/firmware/flash.sh

clean:
	rm -rf build $(OUT)
	git -C openwrt worktree prune
