/*******************************************************************************
* File Name          : readme.txt
* Author             : KetilO
* Version            : V1.0.0
* Date               : 05/13/2011
* Description        : Description of the sonar project.
*******************************************************************************/

Description
===========
A short ping at 200 KHz is transmitted at intervals depending on depth range (200 to 400 ms).
From the time it takes for the echo to return we can calculate the depth.
The ADC measures the strenght of the echo at intervalls depending on range
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
1. Timer to generate the 200 KHz two phase ping signal.
   The number of pulses is variable (1 to 127).
2. Timer to generate an interrupt for every 5,4 us. The interval is constant but the
   number of samples / pixel depends on range.


Time needed for the different ranges:Time needed for the different ranges:
===========================================================================================================
Range		Time for echo to return		Pixel time					      cm / Pixel							        Samples / Pixel
===========================================================================================================
  2 m		1380 *   2 =   2760 us		  2760 / 512 =   5,4 us		  5,4 / 1380 * 100 =  0,39 cm		  2 / 2 =   1
  4 m		1380 *   4 =   5520 us		  5520 / 512 =  10,8 us		 10,8 / 1380 * 100 =  0,78 cm		  4 / 2 =   2
  6 m		1380 *   6 =   8280 us		  8280 / 512 =  16,1 us		 16,1 / 1380 * 100 =  1.17 cm		  6 / 2 =   3
 10 m		1380 *  10 =  13800 us		 13800 / 512 =  27,0 us		 27,0 / 1380 * 100 =  1.96 cm		 10 / 2 =   5
 20 m		1380 *  20 =  27600 us		 27600 / 512 =  53,9 us		 53,9 / 1380 * 100 =  3,91 cm		 20 / 2 =  10
30 m		1380 *  30 =  41400 us		 41400 / 512 =  80,0 us		 80,0 / 1380 * 100 =  5,80 cm		 30 / 2 =  15
 50 m		1380 *  50 =  69000 us		 69000 / 512 = 134,8 us		134,8 / 1380 * 100 =  9,77 cm		 50 / 2 =  25
 70 m		1380 *  70 =  96600 us		 96600 / 512 = 188,7 us		188,7 / 1380 * 100 = 13,67 cm		 70 / 2 =  35
100 m		1380 * 100 = 138000 us		138000 / 512 = 269,5 us		269,5 / 1380 * 100 = 19,53 cm		100 / 2 =  50
150 m		1380 * 150 = 207000 us		207000 / 512 = 404,3 us		404,3 / 1380 * 100 = 29,30 cm		150 / 2 =  75
200 m		1380 * 200 = 276000 us		276000 / 512 = 539,1 us		539,1 / 1380 * 100 = 39,07 cm		200 / 2 = 100
===========================================================================================================


Hardware environment
====================
Runs on STM32 Discovery.

Additional hardware
===================
o Transmitter capable of delivering at least 150 watts RMS to the swinger.
  For the swinger I am using, 1000 Vpp is needed.
o Echo receiver with gain control, tuned at 200 KHz.

Port pins used
==============
PA2		ADC Echo in
PA3		ADC Battery in
PA4		DAC channel1 Gain control out
PA5		ADC Water temprature in
PA6		ADC Air temprature in

PA8		Ping phase 0 out
PA9		Ping phase 1 out


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
