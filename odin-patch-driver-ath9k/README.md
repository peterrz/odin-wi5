Odin patch for ath9k driver
===========================

This is a patch you must apply at the file debug.c of the aht9k driver.

The file is `build_dir/target-mips_34kc_uClibc-0.9.33.2/linux-ar71xx_generic/compat-wireless-2014-05-22/drivers/net/wireless/ath/ath9k/debug.c`

The idea is that you include some new functions there, in order to modify the mask that allows the AP to send the layer-2 ACKs.

Odin makes use of the debugging tools for the drivers: https://wireless.wiki.kernel.org/en/users/drivers/ath9k/debug.

It creates a file called `/sys/kernel/debug/ieee80211/phy0/ath9k/bssid_extra`, where the mask is stored.

The driver will use it in order to decide if a frame is targeted to it, and therefore send a layer-2 ACK.

Please note this: a device in monitor mode does not send layer-2 ACKs. Therefore, you must create an e.g. `mon0` device in addition to the e.g. `wlan0`, but **both interfaces must be up**.


Original version of Lalith Suresh
---------------------------------
It was originally written by Lalith Suresh:
https://github.com/lalithsuresh/odin-driver-patches/tree/00941b6c82d4a5d4f1b1df295c69ec5153b2f5aa

It has a bug: line 46 says
`+	.open = ath9k_debugfs_open,`

But it should say
`+	.open = simple_open,`

Improved versions by fgg89
--------------------------
And it was improved by fgg89: https://github.com/fgg89/odin-utilities

In this repository you will find the ath5k, the ath9k and the ath9k_htc patches.

The ath9k has the same bug than the original of Lalith Suresh.