
#include "Windows.h"

.CONST

szTest			DB "Test",0

.CODE

ModuleProc FRAME hwnd
	invoke MessageBox,[hwnd],OFFSET szTest,OFFSET szTest,MB_OK
	RET
ModuleProc ENDF
