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

UpdateAccelerators proc uses ebx esi edi
	LOCAL	nAccel:DWORD
	LOCAL	hMem:DWORD
	LOCAL	hAccel:DWORD

	mov		eax,lpHandles
	mov		eax,[eax].ADDINHANDLES.hAccel
	mov		hAccel,eax
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8192
	mov		hMem,eax
	invoke CopyAcceleratorTable,hAccel,NULL,0
	mov		nAccel,eax
	invoke CopyAcceleratorTable,hAccel,hMem,nAccel
	invoke DestroyAcceleratorTable,hAccel
	;Toggle &Breakpoint
	mov		eax,IDAddIn[4]
	mov		dl,'T'
	mov		dh,FCONTROL
	call	UpdateAccel
	;&Clear Breakpoints
	mov		eax,IDAddIn[8]
	mov		dl,'T'
	mov		dh,FCONTROL or FSHIFT
	call	UpdateAccel
	;&Run
	mov		eax,IDAddIn[12]
	mov		dl,76h
	mov		dh,FSHIFT
	call	UpdateAccel
	;&Stop
	mov		eax,IDAddIn[16]
	mov		dl,76h
	mov		dh,FALT
	call	UpdateAccel
	;Step &Into
	mov		eax,IDAddIn[20]
	mov		dl,76h
	mov		dh,0
	call	UpdateAccel
	;Step &Over
	mov		eax,IDAddIn[24]
	mov		dl,76h
	mov		dh,FCONTROL
	call	UpdateAccel
	;Run &To Caret
	mov		eax,IDAddIn[28]
	mov		dl,76h
	mov		dh,FCONTROL or FSHIFT
	call	UpdateAccel
	invoke CreateAcceleratorTable,hMem,nAccel
	mov		edx,lpHandles
	mov		[edx].ADDINHANDLES.hAccel,eax
	invoke GlobalFree,hMem
	ret

UpdateAccel:
	or		dh,FNOINVERT or FVIRTKEY
	mov		ebx,hMem
	mov		ecx,nAccel
	inc		ecx
	.while ecx
		.if ax==[ebx].tagACCEL.cmd || [ebx].tagACCEL.cmd==0 || (dl==byte ptr [ebx].tagACCEL.key && dh==[ebx].tagACCEL.fVirt)
			.if ![ebx].tagACCEL.cmd
				; Add new
				inc		nAccel
			.endif
			mov		[ebx].tagACCEL.cmd,ax
			mov		byte ptr [ebx].tagACCEL.key,dl
			mov		[ebx].tagACCEL.fVirt,dh
			.break
		.endif
		add		ebx,sizeof tagACCEL
		dec		ecx
	.endw
	retn

UpdateAccelerators endp

CreateDebugMenu proc uses ebx esi edi,hWin:HWND
	LOCAL	mii:MENUITEMINFO

	.if !hMnu
		invoke CreatePopupMenu
		mov		hMnu,eax
		;Edit menu
		mov		edx,4
		;Adjust topmost popup if maximized.
		mov		eax,[lpData]
		.if [eax].ADDINDATA.fMaximized
			inc		edx
		.endif
		;Get handle of edit popup
		mov		eax,[lpHandles]
		invoke GetSubMenu,[eax].ADDINHANDLES.hMenu,edx		;Edit menu
		push	eax
		;Add our menuitem
		invoke AppendMenu,eax,MF_POPUP or MF_STRING,hMnu,addr DebugMenu
		mov		edi,offset IDAddIn
		; Allocate a new menu id
		invoke SendMessage,hWin,AIM_GETMENUID,0,0
		mov		[edi],eax
		add		edi,4
		mov		mii.cbSize,sizeof MENUITEMINFO
		mov		mii.fMask,MIIM_ID
		mov		mii.wID,eax
		pop		eax
		push	eax
		invoke GetMenuItemCount,eax
		lea		ecx,[eax-1]
		pop		edx
		invoke SetMenuItemInfo,edx,ecx,TRUE,addr mii
		mov		esi,offset MenuItems
		.while byte ptr [esi]
			.if byte ptr [esi]=='-'
				invoke AppendMenu,hMnu,MF_SEPARATOR,0,0
			.else
				; Allocate a new menu id
				invoke SendMessage,hWin,AIM_GETMENUID,0,0
				mov		[edi],eax
				;Add our menuitem
				invoke AppendMenu,hMnu,MF_STRING,[edi],esi
				add		edi,4
			.endif
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
	.endif
	ret

CreateDebugMenu endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
InstallDll proc uses ebx hWin:DWORD, fOpt:DWORD

	mov	ebx,hWin
	invoke LoadLibrary,addr DbgHelpDLL
	.if eax
		mov		hDbgHelpDLL,eax
		;Get pointer to handles struct
		invoke SendMessage,ebx,AIM_GETHANDLES,0,0;	
		mov		lpHandles,eax
		;Get pointer to proc struct
		invoke SendMessage,ebx,AIM_GETPROCS,0,0
		mov		lpProc,eax
		;Get pointer to data struct
		invoke SendMessage,ebx,AIM_GETDATA,0,0	
		mov		lpData,eax
		mov		eax,lpHandles
		mov		eax,[eax].ADDINHANDLES.hOut1
		mov		hOut,eax
		invoke CreateDebugMenu,ebx
		invoke UpdateAccelerators
		; Messages to hook into
		mov		eax,RAM_COMMAND OR RAM_CLOSE OR RAM_MENUREBUILD OR RAM_PROJECTOPENED OR RAM_PROJECTCLOSE
	.endif
	; ECX and EDX must be null before we return
	xor		ecx,ecx
	xor		edx,edx
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
		.if edx==IDAddIn[4]
			; Toggle &Breakpoint
			invoke SendMessage,hWin,WM_COMMAND,IDM_EDIT_TOGGLEBP,0
			.if hDbgThread
				invoke MapBreakPoints
			.endif
		.elseif edx==IDAddIn[8]
			;&Clear Breakpoints
			invoke SendMessage,hWin,WM_COMMAND,IDM_EDIT_CLEARBP,0
			.if hDbgThread
				invoke MapBreakPoints
			.endif
		.elseif edx==IDAddIn[12]
			;&Run
			.if hDbgThread
				invoke ClearBreakPointsAll
				invoke SetBreakPoints
				invoke ResumeThread,threadcontext
			.else
				mov		eax,lpData
				.if [eax].ADDINDATA.fProject
					invoke PutString,addr szDebug
					mov		edx,lpData
					invoke GetPrivateProfileString,addr szMakeFiles,addr szMakeFilesKey,addr szNULL,addr szSourceName,sizeof szSourceName,[edx].ADDINDATA.lpProject
					mov		edx,lpData
					invoke lstrcpy,addr szFileName,[edx].ADDINDATA.lpProjectPath
					invoke lstrcat,addr szFileName,addr szSourceName
					invoke PutString,addr szFileName
					invoke CreateThread,NULL,0,addr Debug,addr szFileName,NULL,addr tid
					mov		hDbgThread,eax
				.endif
			.endif
		.elseif edx==IDAddIn[16]
			;&Stop
			.if hDbgThread
				invoke TerminateProcess,pinfo.hProcess,0
			.endif
		.elseif edx==IDAddIn[20]
			;Step &Into
			.if hDbgThread
				invoke SetBreakPointsAll
				invoke ResumeThread,threadcontext
			.endif
		.elseif edx==IDAddIn[24]
			;Step &Over
			.if hDbgThread
			.endif
		.elseif edx==IDAddIn[28]
			;Run &To Caret
			.if hDbgThread
			.endif
		.elseif edx==IDAddIn[32]
			;Do not Debug
		.endif
	.elseif eax==AIM_CLOSE
		invoke FreeLibrary,hDbgHelpDLL
		;
	.elseif eax==AIM_MENUREBUILD
		;
	.elseif eax==AIM_PROJECTCLOSE
		;
	.elseif eax==AIM_PROJECTOPENED
		invoke UpdateAccelerators
		;
	.endif
	mov eax,FALSE
	ret

DllProc Endp

;#########################################################################

End DllEntry
