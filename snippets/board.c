#include <common.h>
#include <gpio.h>
#include <dm.h>
#include <asm/io.h>
#include <asm/arch-rockchip/clock.h>
#include <asm/arch-rockchip/hardware.h>

__weak int rk_board_init(void)
{
    printf("iBoard RK3588 OPS U-Boot Board Init Start\n");

    // 1. Initialize the OPS power-control GPIO (edge-connector power enable).
    // Drive the GPIO4_D5 power-enable pin high at startup.
    gpio_request(157, "OPS_POWER_EN");
    gpio_direction_output(157, 1);
    mdelay(20);

    // 2. Initialize the fan PWM control pin.
    gpio_request(160, "PWM_FAN");
    gpio_direction_output(160, 0);

    // 3. Print serial-console diagnostics.
    debug("OPS Power Pin Init OK, GPIO157 = HIGH\n");

    // 4. Read the detection pin to check whether the OPS module is present.
    if(gpio_get_value(158)){
        printf("OPS Module Detected\n");
        env_set("hdmi_default", "hdmi0"); // Default to HDMI0 output.
    }else{
        printf("No OPS Slot Detected\n");
    }

    printf("iBoard RK3588 OPS Board Init Complete\n");
    return 0;
}

// Print DDR and clock diagnostics during early U-Boot startup.
void board_init_f(ulong dummy)
{
    debug("==== RK3588 SPL Preloader Init ====\n");
    debug("DDR Initialization Begin...\n");
    dram_init();
    debug("DDR Detect Success, DRAM Size: %dGB\n", gd->ram_size / 1024 / 1024 / 1024);
    serial_init();
    debug("UART Debug Console Ready\n");
    spl_hotkey_init(); // Check the recovery/download button.
}
