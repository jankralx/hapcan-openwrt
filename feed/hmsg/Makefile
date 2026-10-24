include $(TOPDIR)/rules.mk

PKG_NAME:=hmsg
PKG_VERSION:=1.13.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Jan Kral <jankralx@gmail.com>
PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE

# Source comes from the hmsg submodule of this repository
HMSG_DIR:=$(CURDIR)/../../hmsg
PKG_FILE_DEPENDS:=$(HMSG_DIR)/SW

include $(INCLUDE_DIR)/package.mk

define Package/hmsg
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=HAPCAN / MQTT / Socket Server Gateway
  URL:=https://github.com/jankralx/HMSG-openwrt
  DEPENDS:=+libpaho-mqtt-c +libjson-c +kmod-can-raw +jsonfilter
endef

define Package/hmsg/description
  Bridges the HAPCAN bus on can0 to TCP clients (HAPCAN Ethernet
  interface protocol, e.g. HAPCAN Programmer) and to MQTT.
endef

define Package/hmsg/conffiles
/etc/hmsg/config.json
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) $(HMSG_DIR)/SW/Makefile $(HMSG_DIR)/SW/source $(HMSG_DIR)/LICENSE $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CPPFLAGS="$(TARGET_CPPFLAGS) -DJSON_CONFIG_FILE_PATH='\"/etc/hmsg/config.json\"'" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/hmsg/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/hmsg
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hmsg $(1)/usr/bin/
	$(INSTALL_BIN) ./files/hmsg.init $(1)/etc/init.d/hmsg
	$(INSTALL_CONF) ./files/config.json $(1)/etc/hmsg/config.json
endef

$(eval $(call BuildPackage,hmsg))
