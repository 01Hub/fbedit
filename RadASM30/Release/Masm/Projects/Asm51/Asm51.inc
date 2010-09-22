include windows.inc
include kernel32.inc
;include user32.inc
include shlwapi.inc

includelib kernel32.lib
;includelib user32.lib
includelib shlwapi.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

.const

szTestFile	db 'C:\RadASM30\Asm8051\Projects\Verify\Verify.a51',0

szTitle		db '8051 Assembler',0Dh,0Ah,0Ah,0
szError		db ': error ',0

.data?

hInstance		dd ?
CommandLine		dd ?
hOut			dd ?
InpFile			db MAX_PATH dup(?)
hAsmMem			dd ?
hCmdMem			dd ?
hDefMem			dd ?
hAskMem			dd ?
hLinMem			dd ?
dwTemp			dd ?

TEXT_LINE		db 256 dup(?)
				db ?
PASS0_LINE		db 256 dup(?)
PASS1_LINE		db 256 dup(?)
LINE_NUMBER		dd ?
LINE_NO			dd ?


PRG_ADR			DD	?
SWAP_PRG_ADR	DD	?
ORG_ADR			DD	?
NO_OF_BYTES		DD	?

DEF_LBL_ADR		DD	?
ASK_LBL_ADR		DD	?
LST_LIN_ADR		DD	?

OP_CODE			DB	4 dup(?)
NO_OF_OPS		DB	?
CODE			DB	?
REL_MODE		DB	?
