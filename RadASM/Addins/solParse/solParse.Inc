include windows.inc
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

;Debug
include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

include ..\RadAsm.inc

PROPERTIES	struct
	nSize	dd ?
	Owner	dd ?
	nType	db ?
PROPERTIES ends

.const

szskipline					db 	10,7,'section'
							db	10,7,'include'
							db	10,6,'invoke'
							db	0,0,0

szword1						db	10,4,'proc'
							db	11,5,'struc'
							db	11,6,'struct'
							db	11,5,'union'
							db	12,5,'macro'
							db	0,0,0

szinproc					db	10,3,'arg'
							db	11,5,'local'
							db	12,4,'endp'
							db	0,0,0


szword2						db	10,3,'equ'
							db	0,0,0

szdatatypes					db	10,2,'DB'
							db	10,2,'DW'
							db	10,2,'DD'
							db	10,2,'DQ'
							db	10,2,'DF'
							db	10,2,'DT'
							db	11,4,'BYTE'
							db	11,5,'SBYTE'
							db	11,4,'WORD'
							db	11,5,'SWORD'
							db	11,5,'FWORD'
							db	11,5,'DWORD'
							db	11,6,'SDWORD'
							db	11,5,'QWORD'
							db	11,5,'REAL4'
							db	11,5,'REAL8'
							db	11,6,'REAL10'
							db	11,5,'TBYTE'
							db	0,0,0

szdword						db	'DWORD',0
szptr						db	'PTR ',0
szproc						db	'proc',0
szlocal						db	'local',0
szendp						db	'endp',0
szstruct					db	'struct',0
szstruc						db	'struc',0
szunion						db	'union',0
szends						db	'ends',0
szequ						db	'equ',0
szmacro						db	'macro',0
szendm						db	'endm',0


szskipwordprocparam			db	7,'private'
							db	6,'public'
							db	6,'export'
							db	4,'uses'
							db	3,'eax'
							db	3,'ebx'
							db	3,'ecx'
							db	3,'edx'
							db	3,'esi'
							db	3,'edi'
							db	3,'ebp'
							db	3,'esp'
							db	1,'c'
							db	7,'stdcall'
							db	6,'pascal'
							db	7,'fortran'
							db	5,'basic'
							db	7,'syscall'
							db	0,0

szdataconv					db	'DB',0,'BYTE',0
							db	'DW',0,'WORD',0
							db	'DD',0,'DWORD',0
							db	'DQ',0,'QWORD',0
							db	'DT',0,'TBYTE',0
							db	'DF',0,'FWORD',0
							db	'DD',0,'REAL4',0
							db	'DQ',0,'REAL8',0
							db	'DT',0,'REAL10',0
							db	'DB',0,'SBYTE',0
							db	'DW',0,'SWORD',0
							db	'DD',0,'SDWORD',0
							db	0,0

szcomment					db '/*',0
szstring					db '"',"'",0,0
szadd						db '+',0
szcolon						db ':',0

.data?

buffer						db	16384 dup(?)
buffer1						db	16384 dup(?)
buffer2						db	16384 dup(?)
lpHandles					dd	?
lpProcs						dd	?
lpData						dd	?
lpFunSt						dd	?
lpFunEn						dd	?
lpFunPos					dd	?
