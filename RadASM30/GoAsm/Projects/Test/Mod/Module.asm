
#include "C:\GoASM\IncludeA\Windows.inc"
#include "C:\GoASM\IncludeA\user32.inc"
#include "C:\GoASM\IncludeA\kernel32.inc"

.CODE

ModuleProc FRAME hwnd
	invoke MessageBeep,0FFFFFFFFh
	RET
ModuleProc ENDF
