;#########################################################################
;		Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;		Include file

include RADebug.inc
include Misc.asm
include DbgHelp.asm
include Debug.asm

.code

;#########################################################################
;		Common AddIn Procedures

DllEntry proc hInst:HINSTANCE, reason:DWORD, reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

AddMenu proc

	.if IDAddIn
		mov		edx,4		;Tools menu
		;Adjust topmost popup if maximized.
		mov		eax,lpData
		mov		eax,[eax].ADDINDATA.fMaximized
		.if eax
			inc		edx
		.endif
		;Get handle of menu
		mov		eax,lpHandles
		mov		eax,[eax].ADDINHANDLES.hMenu
		;Get handle of Project popup
		invoke GetSubMenu,eax,edx
		;Add our menuitem
		invoke AppendMenu,eax,MF_STRING,IDAddIn,addr szDebug
	.endif
	ret

AddMenu endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
InstallDll proc uses ebx hWin:DWORD, fOpt:DWORD

	mov	ebx,hWin
	invoke LoadLibrary,addr DbgHelpDLL
	.if eax
		mov		hDbgHelpDLL,eax
		;Get pointer to handles struct
		invoke SendMessage,ebx,AIM_GETHANDLES,0,0;	
		mov	lpHandles,eax
		;Get pointer to proc struct
		invoke SendMessage,ebx,AIM_GETPROCS,0,0
		mov	lpProc,eax
		;Get pointer to data struct
		invoke SendMessage,ebx,AIM_GETDATA,0,0	
		mov	lpData,eax
		mov		eax,lpHandles
		mov		eax,[eax].ADDINHANDLES.hOut1
		mov		hOut,eax
		; Allocate a new menu id
		invoke SendMessage,ebx,AIM_GETMENUID,0,0
		mov IDAddIn,eax
		invoke AddMenu
		; Messages to hook into
		mov	eax, RAM_COMMAND OR RAM_CLOSE OR RAM_MENUREBUILD OR RAM_PROJECTOPENED OR RAM_PROJECTCLOSE
	.endif
	; ECX and EDX must be null before we return
	xor ecx, ecx
	xor edx, edx
	ret 

InstallDll Endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
; This proc handles messages sent from RadASM to our dll
; Return TRUE to prevent RadASM and other DLL's from
DllProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL	tid:DWORD

	mov	eax, uMsg
	.if eax == AIM_COMMAND
		mov eax,wParam
		movzx edx,ax
		shr eax, 16
		.if edx==IDAddIn
			; Your addin has been selected
			.if !hDbgThread
				invoke PutString,addr szDebug
				invoke CreateThread,NULL,0,addr Debug,addr szFileName,NULL,addr tid
				mov		hDbgThread,eax
			.endif
		.elseif hDbgThread
			.if edx==IDM_WINDOW_TILEHOR				; F7
				; Step into
				invoke ResumeThread,threadcontext
				mov		eax,TRUE
			.elseif edx==IDM_WINDOW_TILEVER			; Ctrl+F7
				; Step over
				mov		eax,TRUE
			.elseif edx==IDM_WINDOW_CASCADE			; Shift+F7
				; Run
				mov		eax,TRUE
			.elseif edx==IDM_WINDOW_ARRANGEICONS	; Ctrl+Shift+F7
				mov		eax,TRUE
				; Run to Cursor
			.else
				xor		eax,eax
			.endif
			ret
		.endif
	.elseif eax==AIM_CLOSE
		invoke FreeLibrary,hDbgHelpDLL
		;
	.elseif eax==AIM_MENUREBUILD
		;
	.elseif eax==AIM_PROJECTCLOSE
		;
	.elseif eax==AIM_PROJECTOPENED
		;
	.endif
	mov eax,FALSE
	ret

DllProc Endp

;#########################################################################

End DllEntry
