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

szproc						db	'proc'
szendp						db	'endp'
szstruct					db	'struct'
szstruc						db	'struc'
szunion						db	'union'
szends						db	'ends'
szequ						db	'equ'
szmacro						db	'macro'
szendm						db	'endm'
szlocal						db	'local'
szdword						db	'dword'
szptr						db	'PTR '
szskiplinefirstword			db 	6,'option',
								7,'include',
							   10,'includelib',
								6,'invoke',
								0,0

szskipwordprocparam			db	7,'private',
								6,'public',
								6,'export',
								4,'uses',
								3,'eax',
								3,'ebx',
								3,'ecx',
								3,'edx',
								3,'esi',
								3,'edi',
								3,'ebp',
								3,'esp',
								1,'c',
								7,'stdcall',
								6,'pascal',
								7,'fortran',
								5,'basic',
								7,'syscall',
								0,0

szdatatypes					db	2,'db',
								2,'dw',
								2,'dd',
								2,'dq',
								2,'df',
								2,'dt',
								4,'byte',
								4,'word',
								5,'dword',
								5,'qword',
								5,'real4',
								5,'real8',
								6,'real10',
								5,'tbyte',
								0,0

szdatatypeptr				db	3,'ptr'

szcolon						db	':',0
szcomment					db 'comment',0
szstring					db '"',"'",0,0

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
