#define CONFIG_EXTRA_ENV_SETTINGS \
    BOOTENV_SHARED_MTD \
    ENV_MEM_LAYOUT_SETTINGS \
    "fdtfile=" "rk3588-android-ops.dtb" "\0" \
    "partitions=" PARTS_RKIMG "\0" \
    "bootargs=earlyprintk console=ttyFIQ0 loglevel=7 rootwait rw androidboot.hardware=rk3588ops\0" \
    "bootcmd=boot_android; reset\0" \
    "autostart=yes\0" \
    "bootdelay=0\0"  /* Zero boot delay for automatic startup on OPS all-in-one systems. */
