# iBoard Android

U-Boot bootloader snippets and Android boot parameters for the iBoard RK3588 OPS project. The code covers board initialization, hardware descriptions, and early processor startup.

## Contents

| File | Purpose |
| --- | --- |
| `snippets/board.c` | OPS power initialization, GPIO control, and DDR and UART diagnostic messages. |
| `snippets/rk3588-android-ops.dtsi` | Device Tree fragment for power, fan, Ethernet, HDMI, UART, and SATA. |
| `snippets/boot-env.h` | U-Boot environment variables and Android boot parameters. |
| `snippets/startup.S` | Assembly fragment for initial stack setup and transition to board initialization. |
| `scripts/check.sh` | Repeatable local checks for whitespace, branding, environment formatting, and startup assembly syntax. |

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

## Reference implementations

These references help identify the integration points. Their board settings must be matched to the actual iBoard BSP and schematic before use.

| Reference | Relevant pattern |
| --- | --- |
| [Rockchip U-Boot, `next-dev`](https://github.com/rockchip-linux/u-boot/tree/next-dev) | Vendor Android boot command, board hooks, and Rockchip platform initialization. |
| [Rockchip kernel, `develop-5.10`](https://github.com/rockchip-linux/kernel/tree/develop-5.10) | RK3588 Device Trees and the vendor driver consuming `rockchip,temp-trips`. |
| [Radxa Android build guide](https://docs.radxa.com/en/rock5/rock5t/other-os/android/low-level-dev/build-system) | A manifest coordinates U-Boot, kernel, Android device configuration, and AOSP revisions for a specific board. |

Two checks against these vendor trees need resolution before integration:

- The [Rockchip Android command](https://github.com/rockchip-linux/u-boot/blob/next-dev/cmd/boot_android.c#L18-L54) requires an interface and device argument. The [standard vendor environment](https://github.com/rockchip-linux/u-boot/blob/next-dev/include/configs/rockchip-common.h) supplies them through `${devtype}` and `${devnum}`. The current `bootcmd=boot_android; reset` is incomplete for that implementation. Select the arguments and fallback flow from the target BSP.
- The [Rockchip PWM fan driver](https://github.com/rockchip-linux/kernel/blob/develop-5.10/drivers/hwmon/pwm-fan.c) sets the maximum state to the number of cooling levels minus one and rejects larger states. Our five-level table references state `5`, which is outside `0..4` for that driver. The [Toybrick RK3588 example](https://github.com/rockchip-linux/kernel/blob/develop-5.10/arch/arm64/boot/dts/rockchip/rk3588-toybrick-x0.dtsi) uses the same property with six levels. Confirm the target driver and intended fan curve before changing either table.

Fan thermal policy is implemented by the kernel driver. Keep kernel thermal configuration in the matching kernel Device Tree and integrate only bootloader-supported nodes into U-Boot. The C board hooks, startup assembly, and environment fragments belong to the selected U-Boot tree.

## Static validation

Run from the repository root:

```sh
./scripts/check.sh
```

The script also works when invoked by its full path from another directory. It requires Git and Clang with the AArch64 assembler backend; the temporary C probe runs on the host. Standard POSIX shell utilities are used, and all temporary files are removed on completion or interruption.

The command checks committed changes from the import commit plus staged and unstaged whitespace, iBoard messages and Device Tree model, the environment header's C syntax and NUL-separated `key=value` format, and both SPL and non-SPL assembly paths. External environment macros and stack constants are supplied as test placeholders.

Exit status `0` means these static checks passed. The final integration notice remains relevant: the checks do not validate Android command semantics against a real BSP, GPIO assignments, kernel Device Tree bindings, board initialization, or boot behavior. The command does not download dependencies, build a firmware image, or access hardware.
