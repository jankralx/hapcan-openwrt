include $(TOPDIR)/rules.mk

PKG_NAME:=paho-mqtt-c
PKG_VERSION:=1.3.16
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/eclipse-paho/paho.mqtt.c/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=8b960f51edc7e03507637d987882bc486d8f4be6e79431bf99e2763344fd14c5
PKG_BUILD_DIR:=$(BUILD_DIR)/paho.mqtt.c-$(PKG_VERSION)

PKG_MAINTAINER:=Jan Kral <jankralx@gmail.com>
PKG_LICENSE:=EPL-2.0 EDL-1.0
PKG_LICENSE_FILES:=epl-v20 edl-v10

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += \
	-DPAHO_WITH_SSL=OFF \
	-DPAHO_BUILD_SAMPLES=OFF \
	-DPAHO_BUILD_DOCUMENTATION=OFF \
	-DPAHO_ENABLE_TESTING=OFF \
	-DPAHO_ENABLE_CPACK=OFF \
	-DPAHO_HIGH_PERFORMANCE=ON

define Package/libpaho-mqtt-c
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Eclipse Paho MQTT C client library
  URL:=https://eclipse.dev/paho/
endef

define Package/libpaho-mqtt-c/description
  Eclipse Paho MQTT C client library (synchronous and asynchronous API,
  built without TLS).
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/include/MQTT*.h $(1)/usr/include/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libpaho-mqtt3*.so* $(1)/usr/lib/
endef

define Package/libpaho-mqtt-c/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libpaho-mqtt3*.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libpaho-mqtt-c))
