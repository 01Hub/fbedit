
/*
!!! Primary linker script file generated automatically !!!
This file contains the input and output files names
It also includes the secondary/main linker script that is specified in the Ride options (default or custom)
*/

SEARCH_DIR(".")
SEARCH_DIR("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM")
SEARCH_DIR("C:\Program Files\Raisonance\Ride\Lib\ARM")
STARTUP("startup_stm32f10x_md.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\main.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\stm32f4xx_it.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\system_stm32f4xx.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\stm32f4xx_rcc.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\stm32f4_discovery.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\stm32f4xx_gpio.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\stm32f4xx_dma.o")
INPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\stm32f4xx_adc.o")
EXTERN( __io_putchar )
EXTERN( _write )
GROUP(
"STM32x_io_putchar_thumb.a"
"std_sbrk_thumb.lib"
"smallprintf_thumb.a"
"libc.a"
"libm.a"

)
INCLUDE "C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\STM32F100_64K_8K_FLASH.ld"
OUTPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STM32F4_DVM\DVM\DVM.elf")
