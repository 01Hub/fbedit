
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
ADCCTLWR	EQU 8000h
ADCRD		EQU 8001h
ADCWR		EQU 8001h
USBIO		EQU 8003h
USBRXF		EQU P3.2
USBTXE		EQU P3.4
;-----------------------------------------------------
;Adresses in internal ram
INTBITS		EQU 20h			;Interrupt jump control
BUFFER		EQU 40h			;16 Bytes
DPLSAVE		EQU 50h			;Holds DPL during PRNTCSTR
DPHSAVE		EQU 51h			;Holds DPH during PRNTCSTR
SSADRLSB	EQU 52h			;Single step adress LSB
SSADRMSB	EQU 53h			;Single step adress MSB
