#!/bin/bash
#
# OpenWrt firmware build script for TP-LINK Archer C7, TL-WR1043ND, and TL-WDR4300
#
# Added features for the Horizon 2020 Wi-5 project:
#
#   - Click router with Odin Agent
#   - Open vSwitch
#
# Copyright (c) 2015 AirTies Wireless Networks

# before running this script, you need to check whether these packages are installed in your compiling machine:
# ncurses-dev (the grey and blue menuconfig menus)
# gawk
# svnk (only in Debian 6)
# subversion (only in Debian 7)
# subversion-tools
# build-essential


set -e

VERBOSE=""

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] <TLWR1043|ARCHERC7|TLWDR4300>
Build OpenWRT firmware with integrated Click and Open vSwitch for the
specified wireless router.

  -h    display this help and exit
  -v    verbose mode
EOF
}

parse_arguments() {
  while getopts ":hv" opt; do
    case "$opt" in
      v)
        VERBOSE="V=s"
        ;;
      h)
        show_help
        exit 0
        ;;
      '?')
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
  done
  shift "$((OPTIND-1))"
  case "$@" in
    TLWR1043 | ARCHERC7 | TLWDR4300)
      TARGET_PROFILE=$@
      ;;
    *)
      show_help
      exit 1
  esac
}

clean_up() {
  rm -rf openwrt openvswitch custom/openvswitch odin-driver-patches libatomic-patch
}

clone_openwrt() {
  if ! [ -d openwrt ]; then
    git clone git://git.openwrt.org/14.07/openwrt.git openwrt
  fi
}


patch_ath9k() {
  if ! [ -d odin-driver-patches ]; then
    git clone git://github.com/lalithsuresh/odin-driver-patches.git
  fi
  sed -e '1,2d' \
      -e 's/compat-wireless-2011-12-01.orig/a/' \
      -e 's/compat-wireless-2011-12-01/b/' \
      -e 's/ath9k_debugfs_open/simple_open/' \
    odin-driver-patches/ath9k/ath9k-bssid-mask.patch \
    > openwrt/package/kernel/mac80211/patches/580-ath9k-bssid-mask.patch
}

#libatomic patch is required by openvswitch
# You have to do this, otherwise openvswitch will not compile (because of some missing dependencies with libatomic).
# Note: You must apply a patch to /home/proyecto/openwrt/trunk/package/libs/toolchain/Makefile 
# (in principle, it should have been http://patchwork.openwrt.org/patch/5019/, but this URL did not work
# so we applied this other patch instead: https://gist.github.com/pichuang/7372af6d5d3bd1db5a88
patch_libatomic() {
  if ! [ -d libatomic-patch ]; then
    git clone https://gist.github.com/7372af6d5d3bd1db5a88.git libatomic-patch
  fi
  patch -b openwrt/package/libs/toolchain/Makefile < libatomic-patch/openwrt-add-libatomic.patch
}

clone_openvswitch() {
  if ! [ -d openvswitch ]; then
    git clone git://github.com/ttsubo/openvswitch.git
  fi
}

patch_openvswitch() {
  cp -r openvswitch/openvswitch custom/openvswitch
  sed -i.orig \
      -e'/DEPENDS:=+kmod-stp +kmod-ipv6 +kmod-gre +kmod-lib-crc32c/s/$/ +kmod-crypto-crc32c +kmod-tun/' \
    custom/openvswitch/Makefile
}

#add the required feeds, i.e. packages you want to make available in menuconfig
install_custom_feeds() {
  cp openwrt/feeds.conf.default openwrt/feeds.conf
  echo "src-link custom `pwd`/custom" >> openwrt/feeds.conf
  cd openwrt
  ./scripts/feeds update -a
  ./scripts/feeds install luci
  ./scripts/feeds install nano
  ./scripts/feeds install joe	
  ./scripts/feeds update custom
  ./scripts/feeds install -p custom click
  ./scripts/feeds install -p custom openvswitch-common
}

# select the packages you want to be set to be compiled and installed 

# to add the Support for wireless debugging in ath9k driver (this will call debug.c).
#   Kernel modules / Wireless drivers / kmod-ath / Atheros wireless debugging
#   set the flag CONFIG_PACKAGE_ATH_DEBUG=y in the .conf file
configure_openwrt() {
  make defconfig
  sed -i.orig \
      -e 's/\(CONFIG_TARGET_ar71xx_generic_Default\)=y/# \1 is not set/' \
      -e "s/# \(CONFIG_TARGET_ar71xx_generic_$TARGET_PROFILE\) is not set/\1=y/" \
      -e 's/# \(CONFIG_PACKAGE_click\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvswitch-common\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvswitch-ipsec\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvswitch-switch\) is not set/\1=y/' \
      -e 's/# \(CONFIG_DEVEL\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_wireless-tools\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_libuci-lua\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_libiwinfo-lua\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_libubus-lua\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_luci-base\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_luci-lib-nixio\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_luci-theme-bootstrap\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_luci-mod-admin-full\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_uhttpd\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_uhttpd-mod-ubus\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_rpcd\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_lua\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_joe\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_nano\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvpn-nossl\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-usb-storage\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-ext4\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-msdos\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-vfat\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-nls-cp437\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-nls-iso8859-13\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_tcpdump\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_hostapd\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_hostapd-utils\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_ATH_DEBUG\) is not set/\1=y/' \
    .config
  make defconfig

#Remove the "CONFIG_USE_MIPS16=y" option. Uncheck the MIPS16 option:
#	Advanced config. options/ Target opt./ Build packages with MIPS16 instructions

  sed -i.orig \
      -e 's/# \(CONFIG_TARGET_OPTIONS\) is not set/\1=y/' \
      -e 's/\(CONFIG_USE_MIPS16\)=y/# \1 is not set/' \
    .config
  make defconfig
}

configure_kernel() {
  echo "CONFIG_NET_SCH_HTB=y" >> target/linux/ar71xx/config-3.10
}

build() {
  make $VERBOSE
}

parse_arguments "$@"
clean_up
clone_openwrt
patch_ath9k

# Apply libatomic patch (required by openvswitch)  
# You have to do this, otherwise openvswitch will not compile (because of some missing dependencies with libatomic).
#Note: You must apply a patch to /home/proyecto/openwrt/trunk/package/libs/toolchain/Makefile 
patch_libatomic


clone_openvswitch
patch_openvswitch
install_custom_feeds
configure_openwrt
configure_kernel
build