
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

;VKim Debug
include masm32.inc
include \RadASM\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM\masm\lib\debug.lib

.const

szStatic			db 'Static',0

.data?

hInstance			dd ?
hFont				dd ?
hWnd				HWND ?
fRightCaption		dd ?
