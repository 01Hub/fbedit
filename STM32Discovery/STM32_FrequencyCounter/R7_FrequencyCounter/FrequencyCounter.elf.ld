
/*
!!! Primary linker script file generated automatically !!!
This file contains the input and output files names
It also includes the secondary/main linker script that is specified in the Ride options (default or custom)
*/

SEARCH_DIR(".")
SEARCH_DIR("C:\STM32F4\MyProjects\R7_FrequencyCounter")
SEARCH_DIR("C:\Program Files\Raisonance\Ride\Lib\ARM")
STARTUP("C:\STM32F4\MyProjects\R7_FrequencyCounter\startup_stm32f4xx.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\main.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\stm32f4xx_it.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\stm32f4xx_rcc.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\stm32f4xx_gpio.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\stm32f4xx_tim.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\misc.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\system_stm32f4xx.o")
INPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\stm32f4_discovery.o")
EXTERN( __io_putchar )
EXTERN( _write )
GROUP(
"STM32x_io_putchar_thumb.a"
"std_sbrk_thumb.lib"
"smallprintf_thumb.a"
"libc.a"
"libm.a"

)
INCLUDE "C:\STM32F4\MyProjects\R7_FrequencyCounter\STM32F100_64K_8K_FLASH.ld"
OUTPUT("C:\STM32F4\MyProjects\R7_FrequencyCounter\FrequencyCounter.elf")
