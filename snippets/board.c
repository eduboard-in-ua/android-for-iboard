#include <common.h>
#include <gpio.h>
#include <dm.h>
#include <asm/io.h>
#include <asm/arch-rockchip/clock.h>
#include <asm/arch-rockchip/hardware.h>

__weak int rk_board_init(void)
{
    printf("RK3588 OPS U-Boot Board Init Start\n");

    // 1. OPS电源控制GPIO初始化（金手指供电使能脚）
    // GPIO4_D5 电源使能引脚，上电拉高
    gpio_request(157, "OPS_POWER_EN");
    gpio_direction_output(157, 1);
    mdelay(20);

    // 2. 风扇PWM控制脚初始化
    gpio_request(160, "PWM_FAN");
    gpio_direction_output(160, 0);

    // 3. 调试串口打印
    debug("OPS Power Pin Init OK, GPIO157 = HIGH\n");

    // 4. 读取OPS硬件检测引脚（识别OPS金手指在位）
    if(gpio_get_value(158)){
        printf("OPS Module Detected\n");
        env_set("hdmi_default", "hdmi0"); // 默认HDMI0输出
    }else{
        printf("No OPS Slot Detected\n");
    }

    printf("RK3588 OPS Board Init Complete\n");
    return 0;
}

// U-Boot启动前期调试打印DDR、时钟
void board_init_f(ulong dummy)
{
    debug("==== RK3588 SPL Preloader Init ====\n");
    debug("DDR Initialization Begin...\n");
    dram_init();
    debug("DDR Detect Success, DRAM Size: %dGB\n", gd->ram_size / 1024 / 1024 / 1024);
    serial_init();
    debug("UART Debug Console Ready\n");
    spl_hotkey_init(); // 检测Recovery下载按键
}
