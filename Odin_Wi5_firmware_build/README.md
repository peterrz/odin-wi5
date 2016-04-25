Problems of this script
-----------------------

It works in certain computers, but it does not work in others.

When compiling Click Modular Router, you obtain the next error:

`   BUILDCXX ../../lib/error.cc`
`../../lib/error.cc: In static member function 'static String ErrorHandler::vxformat(int, const char*, __va_list_tag*)':`
`../../lib/error.cc:724: error: cannot convert '__va_list_tag**' to '__va_list_tag (*)[1]' in argument passing`

`make[6]: *** [error.bo] Error 1`

`make[6]: Leaving directory '/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt/build_dir/target-mips_34kc_uClibc-0.9.33.2/click-20150424/tools/lib'`

`make[5]: *** [lib] Error 2`

`make[5]: Leaving directory '/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt/build_dir/target-mips_34kc_uClibc-0.9.33.2/click-20150424/tools'`

`make[4]: *** [tools] Error 2`

`make[4]: Leaving directory '/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt/build_dir/target-mips_34kc_uClibc-0.9.33.2/click-20150424'`

`make[3]: *** [/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt/build_dir/target-mips_34kc_uClibc-0.9.33.2/click-20150424/.configured_] Error 2`

`make[3]: Leaving directory '/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/custom/click'`

`make[2]: *** [package/feeds/custom/click/compile] Error 2`

`make[2]: Leaving directory '/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt'`

`make[1]: *** [/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt/staging_dir/target-mips_34kc_uClibc-0.9.33.2/stamp/.package_compile] Error 2`

`make[1]: Leaving directory '/home/proyecto/odin-wi5/Odin_Wi5_firmware_build/openwrt'`

`make: *** [world] Error 2`

It seems the value of `HAVE_ADDRESSABLE_VA_LIST`variable is not correctly set in certain computers/kernels.
