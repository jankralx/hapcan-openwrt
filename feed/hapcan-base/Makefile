include $(TOPDIR)/rules.mk

PKG_NAME:=hapcan-base
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Jan Kral <jankralx@gmail.com>
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/hapcan-base
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=HAPCAN Ethernet Interface system setup
  DEPENDS:=+hmsg +canutils +canutils-slcand +umdns
endef

define Package/hapcan-base/description
  Default settings and services of the HAPCAN Ethernet Interface:
  unique hostname and DHCP client, slcan link to the on-board CANable,
  bringing can0 up and keeping the RTC in sync with NTP.
endef

define Build/Compile
endef

define Package/hapcan-base/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/tty $(1)/etc/hotplug.d/net $(1)/etc/hotplug.d/ntp
	$(INSTALL_DATA) ./files/etc/uci-defaults/60-hapcan $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/etc/init.d/slcand $(1)/etc/init.d/
	$(INSTALL_DATA) ./files/etc/hotplug.d/tty/30-slcand $(1)/etc/hotplug.d/tty/
	$(INSTALL_DATA) ./files/etc/hotplug.d/net/30-can-up $(1)/etc/hotplug.d/net/
	$(INSTALL_DATA) ./files/etc/hotplug.d/ntp/30-rtc $(1)/etc/hotplug.d/ntp/
endef

$(eval $(call BuildPackage,hapcan-base))
