include $(TOPDIR)/rules.mk

PKG_NAME:=click
PKG_VERSION:=20150424
PKG_RELEASE:=1
PKG_REV:=a05e2bc2340a90891bab157718552ea0fd1b8c6a

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://github.com/kohler/click.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

WI5_AGENT_NAME:=wi5-agent
WI5_AGENT_VERSION:=20170421
WI5_AGENT_REV:=55e398adbd00fdd241623f71457d4085b3f2177e
WI5_AGENT_SOURCE:=$(WI5_AGENT_NAME)-$(WI5_AGENT_VERSION).tar.gz
WI5_AGENT_PROTO:=git
WI5_AGENT_URL:=https://github.com/Wi5/odin-wi5-agent.git
WI5_AGENT_SUBDIR:=$(WI5_AGENT_NAME)-$(WI5_AGENT_VERSION)

AGENT_CLICK_GENERATOR:=agent-click-file-gen.py

include $(INCLUDE_DIR)/package.mk

define Package/click
	SECTION:=net
	CATEGORY:=Network
	DEPENDS:=+kmod-tun +libpcap +libstdcpp +librt
	TITLE:=Click Modular Router
	URL:=http://read.cs.ucla.edu/click
endef

define Package/click/Description
	The Click Modular Router userspace package with Odin agent integration
endef

define Download/wi5-agent
	FILE:=$(WI5_AGENT_SOURCE)
	URL:=$(WI5_AGENT_URL)
	PROTO:=$(WI5_AGENT_PROTO)
	VERSION:=$(WI5_AGENT_REV)
	SUBDIR:=$(WI5_AGENT_SUBDIR)
endef

define Build/Prepare
	$(Build/Prepare/Default)
	$(TAR) -C $(PKG_BUILD_DIR) -xzf $(DL_DIR)/$(WI5_AGENT_SOURCE)
	$(CP) $(PKG_BUILD_DIR)/$(WI5_AGENT_NAME)-$(WI5_AGENT_VERSION)/src/odinagent{.cc,.hh} $(PKG_BUILD_DIR)/elements/local
	python $(PKG_BUILD_DIR)/$(WI5_AGENT_NAME)-$(WI5_AGENT_VERSION)/$(AGENT_CLICK_GENERATOR) \
		4 50 14:CC:20:AC:72:91 192.168.1.129 2819 /sys/kernel/debug/ieee80211/phy0/ath9k/bssid_extra odin-wi5-airties 192.168.1.7 0 11 12 25 0 \
		> $(PKG_BUILD_DIR)/userlevel/agent.click
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); \
		rm -rf config.{cache,status} ; \
		./configure \
			--prefix=/usr \
			--enable-local \
			--enable-userlevel \
			--enable-wifi \
			--disable-linuxmodule \
	)
	$(MAKE) -C $(PKG_BUILD_DIR) tools share/click/elementmap.xml
	(cd $(PKG_BUILD_DIR)/userlevel; \
		../tools/click-mkmindriver/click-mkmindriver -a -u -V \
			-f agent.click -C ../share/click -p $(PKG_NAME) \
			-E Discard -E Print -E ARPPrint; \
	)
	$(CP) ./files/click_1.patch $(PKG_BUILD_DIR)
	(cd $(PKG_BUILD_DIR); \
		patch < click_1.patch; \
    	)
	$(CP) ./files/click_2.patch $(PKG_BUILD_DIR)/include/click
	(cd $(PKG_BUILD_DIR)/include/click/; \
		ls; \
		patch < click_2.patch; \
	)
	$(CP) ./files/click_3.patch $(PKG_BUILD_DIR)/lib
	(cd $(PKG_BUILD_DIR)/lib; \
		patch < click_3.patch; \
	)
	$(MAKE) -C $(PKG_BUILD_DIR) clean-tools
	(cd $(PKG_BUILD_DIR); \
		rm -rf config.{cache,status} ; \
		STAGING_DIR=$(TOOLCHAIN_DIR) \
		./configure \
			--prefix=/usr \
			--host=$(GNU_TARGET_NAME) \
			--build=$(GNU_HOST_NAME) \
			--enable-local \
			--enable-userlevel \
			--enable-wifi \
			--disable-linuxmodule \
	)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)
	$(MAKE) -C $(PKG_BUILD_DIR) MINDRIVER=$(PKG_NAME)
endef

define Package/click/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/share/click
	$(CP) $(PKG_BUILD_DIR)/userlevel/click $(1)/usr/bin/click
	$(CP) $(PKG_BUILD_DIR)/userlevel/$(PKG_NAME)click $(1)/usr/bin/minclick
	$(CP) $(PKG_BUILD_DIR)/tools/click-align/click-align $(1)/usr/bin/click-align
	$(CP) $(PKG_BUILD_DIR)/share/click/elementmap.xml $(1)/usr/share/click/elementmap.xml
	$(CP) $(PKG_BUILD_DIR)/userlevel/agent.click $(1)/usr/share/click/agent.click
	$(INSTALL_BIN) ./files/start_odin_new.sh $(1)/usr/share/click/start_odin_new.sh
endef

$(eval $(call Download,wi5-agent))
$(eval $(call BuildPackage,click))
