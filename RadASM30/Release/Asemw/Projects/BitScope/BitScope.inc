
;-----------------------------------------------------
;*****************************************************
;Equates
;-----------------------------------------------------
T2CON		EQU 0C8h
RCAP2L		EQU 0CAh
RCAP2H		EQU 0CBh
TL2		EQU 0CCh
TH2		EQU 0CDh
ADCCTLRD	EQU 8000h
ADCCTLWR	EQU 8000h		;D0 | ADCCLKSEL
					;D1 |
					;D2 |
					;D3 | RAMPAGE
					;D4 |
					;D5   CLK1PHASE
					;D6   ADC/MCU
					;D7   ADCMR
ADCRD		EQU 8001h
ADCWR		EQU 8001h
USBIO		EQU 8003h
USBRXF		EQU P3.2
USBTXE		EQU P3.4
;-----------------------------------------------------
;Adresses in internal ram
INTBITS		EQU 20h			;Interrupt jump control
ADCCTL		EQU 21h			;Byte written at ADCCTLWR
RAMPAGE0	EQU 00h			;ADC CHA
RAMPAGE1	EQU 08h			;LA CHA
RAMPAGE2	EQU 10h			;ADC CHB
RAMPAGE3	EQU 18h			;LA CHB
CLK1PHASE	EQU 20h			;CLK1PHASE
ADCMCU		EQU 40h			;ADC/MCU L=ADC, H=MCU
ADCMR		EQU 80h			;ADCMR L=RESET

BUFFER		EQU 40h			;16 Bytes
DPLSAVE		EQU 50h			;Holds DPL during PRNTCSTR
DPHSAVE		EQU 51h			;Holds DPH during PRNTCSTR
SSADRLSB	EQU 52h			;Single step adress LSB
SSADRMSB	EQU 53h			;Single step adress MSB
