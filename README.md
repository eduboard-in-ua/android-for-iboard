# iBoard Android

U-Boot bootloader snippets and Android boot parameters for the iBoard RK3588 OPS project. The code covers board initialization, hardware descriptions, and early processor startup.

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

## iBoard branding

The project name, board initialization messages, and Device Tree `model` identify iBoard. Hardware identifiers such as `compatible`, the DTB filename, and `androidboot.hardware` remain unchanged so that textual branding does not change platform matching.

## Items to resolve during integration

| Area | Required integration work |
| --- | --- |
| GPIO mapping | Confirm GPIOs `157`, `158`, and `160` against the board schematic and BSP. RK3588 has five 32-pin SoC GPIO banks; `160` needs an explicit board mapping rather than an assumed SoC pin assignment. |
| GPIO handling | The snippets do not request or configure input GPIO `158`, or check GPIO and environment operation results. Define input direction, error handling, and initialization order in the target U-Boot board hooks. |
| Fan and thermal control | Reconcile the fan GPIO with `pwm9` and its pin configuration. There are five `cooling-levels` entries, while the final `rockchip,temp-trips` row ends in `5`; confirm the vendor driver's property semantics and state mapping. |
| Device Tree | Supply the referenced controller, regulator, and pinctrl labels from the target tree. Confirm vendor-specific properties, including `rockchip,temp-trips` and `rockchip,hdmi20`, against the selected BSP bindings. |
| Boot configuration | Provide the environment macros and the `rk3588-android-ops.dtb` artifact. Confirm the Android boot command, partition layout, and `rk3588ops` hardware identifier against the target image. |
| Early startup | Merge `rk_board_init` into the BSP's existing board hooks rather than adding another weak definition. Integrate `board_init_f` and the assembly with the target startup flow; stack definitions, global data setup, DDR routines, and recovery-key handling must come from that tree. |

The fan property must be checked against the BSP in use. The [mainline Linux PWM fan binding](https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/hwmon/pwm-fan.yaml) uses thermal-zone cooling maps; it does not define `rockchip,temp-trips`. The [Rockchip RK3588 pinctrl driver](https://github.com/rockchip-linux/u-boot/blob/next-dev/drivers/pinctrl/rockchip/pinctrl-rk3588.c) describes the SoC GPIO banks.

## Static validation

The environment header passes a C syntax check with the external environment macros supplied as test placeholders. The startup assembly passes AArch64 syntax checks for both SPL and non-SPL paths with test stack constants. These checks cover the fragments' syntax; board initialization, Device Tree integration, and boot behavior require the actual BSP and hardware.
