
include		windows.inc
include		kernel32.inc
include		user32.inc
include		Comctl32.inc

includelib	kernel32.lib
includelib	user32.lib
includelib	Comctl32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

.const

IDD_MAIN				equ 101
IDC_EDT1        		equ 102
STM32F4_CLOCK			equ 200000000
ADCSingle_SampleClocks	DWORD 3,15,28,56,84,112,144,480

;#########################################################################

.data?

hInstance				DWORD ?
SampleRates				DWORD 256 dup(?)
SampleRateClk			DWORD 256 dup(?)

;#########################################################################
