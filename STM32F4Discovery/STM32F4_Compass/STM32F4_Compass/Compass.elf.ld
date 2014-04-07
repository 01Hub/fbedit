
/*
!!! Primary linker script file generated automatically !!!
This file contains the input and output files names
It also includes the secondary/main linker script that is specified in the Ride options (default or custom)
*/

SEARCH_DIR(".")
SEARCH_DIR("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass")
SEARCH_DIR("D:\Ride\Ride\Lib\ARM")
STARTUP("startup_stm32f10x_md.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\main.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4xx_it.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\system_stm32f4xx.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4xx_rcc.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4_discovery.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4xx_gpio.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4xx_i2c.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4_discovery_lis302dl.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\stm32f4xx_spi.o")
EXTERN( __io_putchar )
EXTERN( _write )
GROUP(
"STM32x_io_putchar_thumb.a"
"std_sbrk_thumb.lib"
"smallprintf_thumb.a"
"libc.a"
"libm.a"

)
INCLUDE "D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\STM32F100_64K_8K_FLASH.ld"
OUTPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_Compass\STM32F4_Compass\Compass.elf")
