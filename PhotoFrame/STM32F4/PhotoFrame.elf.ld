
/*
!!! Primary linker script file generated automatically !!!
This file contains the input and output files names
It also includes the secondary/main linker script that is specified in the Ride options (default or custom)
*/

SEARCH_DIR(".")
SEARCH_DIR("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4")
SEARCH_DIR("C:\Program Files\Raisonance\Ride\Lib\ARM")
STARTUP("startup_stm32f10x_md.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\main.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\misc.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\stm32f4xx_gpio.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\stm32f4xx_it.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\stm32f4xx_rcc.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\system_stm32f4xx.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\stm32f4xx_exti.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\stm32f4xx_syscfg.o")
EXTERN( __io_putchar )
EXTERN( _write )
GROUP(
"STM32x_io_putchar_thumb.a"
"std_sbrk_thumb.lib"
"smallprintf_thumb.a"
"libc.a"
"libm.a"

)
INCLUDE "C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\STM32F100_64K_8K_FLASH.ld"
OUTPUT("C:\FbEdit\Projects\Applications\FbEdit\PhotoFrame\STM32F4\PhotoFrame.elf")
