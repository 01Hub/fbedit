
/*
!!! Primary linker script file generated automatically !!!
This file contains the input and output files names
It also includes the secondary/main linker script that is specified in the Ride options (default or custom)
*/

SEARCH_DIR(".")
SEARCH_DIR("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter")
SEARCH_DIR("C:\Program Files (x86)\Raisonance\Ride\Lib\ARM")
STARTUP(".\startup_stm32f4xx.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\main.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\stm32f4xx_it.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\stm32f4xx_rcc.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\stm32f4xx_gpio.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\stm32f4xx_tim.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\misc.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\system_stm32f4xx.o")
INPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\stm32f4_discovery.o")
EXTERN( __io_putchar )
EXTERN( _write )
GROUP(
"STM32x_io_putchar_thumb.a"
"std_sbrk_thumb.lib"
"smallprintf_thumb.a"
"libc.a"
"libm.a"

)
INCLUDE "C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32F100_64K_8K_FLASH.ld"
OUTPUT("C:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\LCMeter.elf")
