# iBoard Android

U-Boot bootloader snippets for an iBoard board based on the Rockchip RK3588, with Android boot parameters. The code covers OPS board initialization, hardware descriptions, and early processor startup.

## Contents

| File | Purpose |
| --- | --- |
| `snippets/board.c` | OPS power initialization, GPIO control, and DDR and UART diagnostic messages. |
| `snippets/rk3588-android-ops.dtsi` | Device Tree fragment for power, fan, Ethernet, HDMI, UART, and SATA. |
| `snippets/boot-env.h` | U-Boot environment variables and Android boot parameters. |
| `snippets/startup.S` | Assembly fragment for initial stack setup and transition to board initialization. |

## Integration

Integrate these snippets into a compatible RK3588 U-Boot source tree or SDK/BSP. That tree must provide the required functions, macros, base Device Tree, and configuration for the specific board. Check the GPIO assignments and hardware descriptions against the board schematic before integration.

This repository contains individual bootloader snippets. It does not include a complete Android source tree, build tools, or a ready-to-flash firmware image. Build and hardware testing have not been performed.
