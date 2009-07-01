
include windows.inc
include kernel32.inc
include user32.inc
include dbghelp.inc

includelib kernel32.lib
includelib user32.lib

include \RadASM\masm\inc\debug.inc
includelib \RadASM\masm\lib\debug.lib

.data?

hInstance			HMODULE ?	;Dll's module handle
hProcessDbg			HANDLE ?
hMemFile			HGLOBAL ?
