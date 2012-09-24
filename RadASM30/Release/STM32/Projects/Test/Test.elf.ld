
/*!!! Primary linker script file generated automatically !!!This file contains the input and output files namesIt also includes the secondary/main linker script that is specified in the Ride options (default or custom)*/
SEARCH_DIR(".")
/*SEARCH_DIR("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STN32F4_GTVTerminal")*/
SEARCH_DIR("C:\Program Files\Raisonance\Ride\Lib\ARM")
STARTUP(".\startup_stm32f4xx.o")
INPUT(".\main.o")
INPUT(".\video.o")
INPUT(".\keyboard.o")
INPUT(".\mouse.o")
INPUT(".\usart.o")
INPUT(".\keystate.o")
INPUT(".\window.o")
INPUT(".\desktop.o")
INPUT(".\pong.o")
INPUT(".\terminal.o")
INPUT(".\logicanalyser.o")
INPUT(".\AlieGame.o")
INPUT(".\scope.o")
INPUT(".\misc.o")
INPUT(".\stm32f4_discovery.o")
INPUT(".\stm32f4xx_dma.o")
INPUT(".\stm32f4xx_exti.o")
INPUT(".\stm32f4xx_gpio.o")
INPUT(".\stm32f4xx_it.o")
INPUT(".\stm32f4xx_rcc.o")
INPUT(".\stm32f4xx_spi.o")
INPUT(".\stm32f4xx_syscfg.o")
INPUT(".\stm32f4xx_tim.o")
INPUT(".\stm32f4xx_usart.o")
INPUT(".\system_stm32f4xx.o")
/*EXTERN( __io_putchar )*/
/*EXTERN( _write )*/
/*GROUP("STM32x_io_putchar_thumb.a""std_sbrk_thumb.lib""smallprintf_thumb.a""libc.a""libm.a")*/
/*GROUP("libc.a""libm.a")*/
INCLUDE "STM32F100_64K_8K_FLASH.ld"
/*OUTPUT("C:\FbEdit\Projects\Applications\FbEdit\STM32F4Discovery\STN32F4_GTVTerminal\GTVTerminal.elf")*/
