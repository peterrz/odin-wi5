#!/bin/bash
#
# OpenWrt firmware build script for TP-LINK Archer C7, TL-WR1043ND, TL-WDR4300 and Netgear R6100
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
Usage: ${0##*/} [-hv] <TLWR1043|ARCHERC7|TLWDR4300|nand>
Build OpenWRT firmware with integrated Click and Open vSwitch for the
specified wireless router. 

P.S In order to generate an OpenWRT firmware with Click for Netgear R6100, please use the nand option.

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
    TLWR1043 | ARCHERC7 | TLWDR4300 | nand)
      TARGET_PROFILE=$@
      ;;
    *)
      show_help
      exit 1
  esac
}

clean_up() {
  rm -rf openwrt odin-driver-patches 
}

clone_openwrt() {
  if ! [ -d openwrt ]; then
    git clone git://git.openwrt.org/15.05/openwrt.git openwrt
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

#add the required feeds, i.e. packages you want to make available in menuconfig
install_custom_feeds() {
  cp openwrt/feeds.conf.default openwrt/feeds.conf
  echo "src-link custom `pwd`/custom" >> openwrt/feeds.conf
  cd openwrt
  ./scripts/feeds update -a
  ./scripts/feeds install -a 
}

# select the packages you want to be set to be compiled and installed 

# to add the Support for wireless debugging in ath9k driver (this will call debug.c).
#   Kernel modules / Wireless drivers / kmod-ath / Atheros wireless debugging
#   set the flag CONFIG_PACKAGE_ATH_DEBUG=y in the .conf file
configure_openwrt() {
  if test "$TARGET_PROFILE" == "nand" 
  then			
  make defconfig
  sed -i.orig \
      -e 's/\(CONFIG_TARGET_ar71xx_generic_Default\)=y/# \1 is not set/' \
      -e "s/# \(CONFIG_TARGET_ar71xx_$TARGET_PROFILE\) is not set/\1=y/" \
      -e 's/# \(CONFIG_PACKAGE_click\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvswitch\) is not set/\1=y/' \
      -e 's/# \(CONFIG_DEVEL\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_wireless-tools\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_luci\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_joe\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_nano\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvpn-nossl\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-openvswitch\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-tun\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-usb-storage\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-ext4\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-msdos\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-vfat\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-nls-cp437\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-nls-iso8859-13\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-crypto-crc32c\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-lib-crc32c\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_tcpdump\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_hostapd\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_hostapd-utils\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_ATH_DEBUG\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-ath\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-ath9k-htc\) is not set/\1=y/' \
      -e 's/\(CONFIG_PACKAGE_odhcp6c\)=y/# \1 is not set/' \
      -e 's/\(CONFIG_PACKAGE_odhcpd\)=y/# \1 is not set/' \
    .config
  make defconfig
  else
  make defconfig
  sed -i.orig \
      -e 's/\(CONFIG_TARGET_ar71xx_generic_Default\)=y/# \1 is not set/' \
      -e "s/# \(CONFIG_TARGET_ar71xx_generic_$TARGET_PROFILE\) is not set/\1=y/" \
      -e 's/# \(CONFIG_PACKAGE_click\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvswitch\) is not set/\1=y/' \
      -e 's/# \(CONFIG_DEVEL\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_wireless-tools\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_luci\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_joe\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_nano\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_openvpn-nossl\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-openvswitch\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-tun\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-usb-storage\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-ext4\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-msdos\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-fs-vfat\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-nls-cp437\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-nls-iso8859-13\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-crypto-crc32c\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-lib-crc32c\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_tcpdump\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_hostapd\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_hostapd-utils\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_ATH_DEBUG\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-ath\) is not set/\1=y/' \
      -e 's/# \(CONFIG_PACKAGE_kmod-ath9k-htc\) is not set/\1=y/' \
      -e 's/\(CONFIG_PACKAGE_odhcp6c\)=y/# \1 is not set/' \
      -e 's/\(CONFIG_PACKAGE_odhcpd\)=y/# \1 is not set/' \
    .config
  make defconfig	
  fi
  
 

#Remove the "CONFIG_USE_MIPS16=y" option. Uncheck the MIPS16 option:
#	Advanced config. options/ Target opt./ Build packages with MIPS16 instructions

  sed -i.orig \
      -e 's/# \(CONFIG_TARGET_OPTIONS\) is not set/\1=y/' \
      -e 's/\(CONFIG_USE_MIPS16\)=y/# \1 is not set/' \
    .config
  make defconfig

  sed -i.orig \
      -e 's/# \(CONFIG_PACKAGE_openvswitch-ipsec\) is not set/\1=y/' \
    .config
  make defconfig
}

build() {
  make $VERBOSE
}

parse_arguments "$@"
clean_up
clone_openwrt
patch_ath9k
install_custom_feeds
configure_openwrt
build
