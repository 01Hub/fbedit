
	include windows.inc
	include kernel32.inc
	include user32.inc

	includelib kernel32.lib
	includelib user32.lib

	include \RadASM\masm\inc\debug.inc
	includelib \RadASM\masm\lib\debug.lib

.data?

hInstance			dd ?	;Dll's module handle

