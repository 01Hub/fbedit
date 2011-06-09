/*******************************************************************************
* File Name          : readme.txt
* Author             : KetilO
* Version            : V1.0.0
* Date               : 05/13/2011
* Description        : Description of the sonar project.
*******************************************************************************/

Description
===========
A short ping at 200 KHz is transmitted at intervals depending on depth range (200 to 500 ms).
From the time it takes for the echo to return we can calculate the depth.
The adc measures the strenght of the echo at intervalls depending on range
and stores it in a 512 byte array.

Speed of sound in water
=======================
Temp (C)    Speed (m/s)
  0             1403
  5             1427
 10             1447
 20             1481
 30             1507
 40             1526

1450 m/s is probably a good estimate.
Time for sound to travel 100 cm: 1000000 / 1450 = 689,66 ~ 690 us
Since it is the echo we are measuring: 690 * 2 = 1380 us

Two timers are needed:
1. Timer in PWM mode to generate the 200 KHz two phase ping signal.
   The number of pulses is variable (1 to 256).
2. Timer to generate an interrupt for every pixel. The interval depends
   on range.

Time needed for the different ranges:
========================================================================
Range		Time for echo to return		Pixel time                  Pixel skip
========================================================================
  4 m		1380 *   4 =   5520 us		  5520 / 512 =  10,8 us
  6 m		1380 *   6 =   8280 us		  8280 / 512 =  16,1 us
 10 m		1380 *  10 =  13800 us		 13800 / 512 =  27,0 us
 20 m		1380 *  20 =  27600 us		 27600 / 512 =  53,9 us
 30 m		1380 *  30 =  41400 us		 41400 / 512 =  80,0 us
 50 m		1380 *  50 =  69000 us		 69000 / 512 = 134,8 us
 70 m		1380 *  70 =  96600 us		 96600 / 512 = 188,7 us
100 m		1380 * 100 = 138000 us		138000 / 512 = 269,5 us
150 m		1380 * 150 = 207000 us		207000 / 512 = 404,3 us
200 m		1380 * 200 = 276000 us		276000 / 512 = 539,1 us
250 m		1380 * 250 = 345000 us		345000 / 512 = 673,8 us
300 m		1380 * 300 = 414000 us		414000 / 512 = 808,6 us
350 m		1380 * 350 = 483000 us		483000 / 512 = 943,4 us

Hardware environment
====================
Runs on STM32 Discovery.

Additional hardware
===================
Output amplifier capable of delivering at least 800 watts peak to the swinger.
For the swinger I am using 800 Vpp is needed to generate 800 watts peak.
Input amplifier and filter tuned at 200 KHz.
Gain control.
Amplifier measuring amplitude.


Directory contents
==================
stm32f10x_conf.h  Library Configuration file
stm32f10x_it.c    Interrupt handlers
stm32f10x_it.h    Interrupt handlers header file
main.c            Main program
 

How to use it
=============
In order to make the program work, you must do the following:
- Create a project and setup all your toolchain's start-up files
- Compile the directory content files and required Library files:
  + stm32f10x_adc.c
  + stm32f10x_dac.c
  + stm32f10x_lib.c
  + stm32f10x_tim.c
  + stm32f10x_gpio.c
  + stm32f10x_rcc.c
  + stm32f10x_nvic.c
  + stm32ff10x_flash.c

- Link all compiled files and load your image into target memory
- Run the example
