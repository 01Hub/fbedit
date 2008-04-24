
InstallRACodeComplete		PROTO :DWORD,:DWORD
UnInstallRACodeComplete		PROTO
InstallFileBrowser			PROTO :DWORD,:DWORD
UnInstallFileBrowser		PROTO
InstallRAProperty			PROTO :DWORD,:DWORD
UnInstallRAProperty			PROTO
GridInstall					PROTO :DWORD,:DWORD

include windows.inc
include Comctl32.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib comctl32.lib
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

includelib Lib\RACodeComplete.lib
includelib Lib\RAFile.lib
includelib Lib\RAProperty.lib
includelib Lib\RAGrid.lib

;VKim Debug
include masm32.inc
include \RadASM\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM\masm\lib\debug.lib

