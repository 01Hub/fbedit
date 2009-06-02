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
include BreakPoint.asm

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

EnableMenu proc uses esi edi
	LOCAL	hREd:HWND
	LOCAL	chrg:CHARRANGE
	LOCAL	nLine:DWORD
	LOCAL	nInx:DWORD

	mov		esi,offset IDAddIn+4
	mov		eax,lpData
	.if [eax].ADDINDATA.fProject
		; Toggle &Breakpoint
		invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_GRAYED
		; Run &To Caret
		invoke EnableMenuItem,hMnu,[esi+24],MF_BYCOMMAND or MF_GRAYED
		mov		eax,lpHandles
		.if [eax].ADDINHANDLES.hEdit
			mov		edx,[eax].ADDINHANDLES.hEdit
			mov		hREd,edx
			invoke GetWindowLong,[eax].ADDINHANDLES.hMdiCld,0
			.if eax==ID_EDIT
				.if dbg.hDbgThread
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
					mov		nLine,eax
					mov		eax,lpHandles
					invoke GetWindowLong,[eax].ADDINHANDLES.hMdiCld,16
					invoke GetFileIDFromProjectFileID,eax
					.if eax
						mov		edx,nLine
						inc		edx
						xor		ecx,ecx
						mov		edi,offset dbgline
						.while ecx<inxline
							.if edx==[edi].DEBUGLINE.LineNumber
								.if eax==[edi].DEBUGLINE.FileID
									.break
								.endif
							.endif
							inc		ecx
							add		edi,sizeof DEBUGLINE
						.endw
						.if ecx!=inxline
							; Toggle &Breakpoint
							invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_ENABLED
							; Run &To Caret
							invoke EnableMenuItem,hMnu,[esi+24],MF_BYCOMMAND or MF_ENABLED
						.endif
					.endif
				.else
					; Toggle &Breakpoint
					invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_ENABLED
				.endif
			.endif
		.endif
		; &Clear Breakpoints
		invoke AnyBreakPoints
		.if eax
			invoke EnableMenuItem,hMnu,[esi+4],MF_BYCOMMAND or MF_ENABLED
		.else
			invoke EnableMenuItem,hMnu,[esi+4],MF_BYCOMMAND or MF_GRAYED
		.endif
		; &Run
		invoke EnableMenuItem,hMnu,[esi+8],MF_BYCOMMAND or MF_ENABLED
		; Do not Debug
		invoke EnableMenuItem,hMnu,[esi+28],MF_BYCOMMAND or MF_ENABLED
		.if dbg.hDbgThread
			; &Stop
			invoke EnableMenuItem,hMnu,[esi+12],MF_BYCOMMAND or MF_ENABLED
			; Step &Into
			invoke EnableMenuItem,hMnu,[esi+16],MF_BYCOMMAND or MF_ENABLED
			; Step &Over
			invoke EnableMenuItem,hMnu,[esi+20],MF_BYCOMMAND or MF_ENABLED
		.else
			; &Stop
			invoke EnableMenuItem,hMnu,[esi+12],MF_BYCOMMAND or MF_GRAYED
			; Step &Into
			invoke EnableMenuItem,hMnu,[esi+16],MF_BYCOMMAND or MF_GRAYED
			; Step &Over
			invoke EnableMenuItem,hMnu,[esi+20],MF_BYCOMMAND or MF_GRAYED
			; Run &To Caret
			invoke EnableMenuItem,hMnu,[esi+24],MF_BYCOMMAND or MF_GRAYED
		.endif
	.else
		; No project loaded, disable all
		.while dword ptr [esi]
			invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_GRAYED
			add		esi,4
		.endw
	.endif
	ret

EnableMenu endp

EditProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov		eax,uMsg
	invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
	ret

EditProc endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
InstallDll proc uses ebx hWin:DWORD, fOpt:DWORD

	mov	ebx,hWin
	invoke LoadLibrary,addr DbgHelpDLL
	.if eax
		mov		hDbgHelpDLL,eax
		mov		eax,fOpt
		mov		fOptions,eax
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
		mov		eax,RAM_COMMAND OR RAM_CLOSE OR RAM_MENUREBUILD OR RAM_PROJECTOPENED OR RAM_PROJECTCLOSED OR RAM_EDITOPEN or RAM_EDITSELCHANGE
	.endif
	; ECX and EDX must be null before we return
	xor		ecx,ecx
	xor		edx,edx
	ret 

InstallDll Endp

GetOptions proc

	mov		eax,offset AddinOpt
	ret

GetOptions endp

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
			invoke ToggleBreakpoint
			invoke SaveBreakPoints
			.if dbg.hDbgThread
				invoke LoadAllBreakPoints
				invoke MapBreakPoints
			.endif
		.elseif edx==IDAddIn[8]
			;&Clear Breakpoints
			invoke ClearBreakpoints
			.if dbg.hDbgThread
				invoke MapBreakPoints
			.endif
		.elseif edx==IDAddIn[12]
			;&Run
			.if dbg.hDbgThread
				invoke ClearBreakPointsAll
				invoke SetBreakPoints
				invoke ResumeThread,dbg.threadcontext
			.else
				mov		eax,lpData
				.if [eax].ADDINDATA.fProject
					invoke LoadAllBreakPoints
					invoke PutString,addr szDebug
					mov		edx,lpData
					invoke GetPrivateProfileString,addr szMakeFiles,addr szMakeFilesObjKey,addr szNULL,addr szObjName,sizeof szObjName,[edx].ADDINDATA.lpProject
					mov		edx,lpData
					invoke lstrcpy,addr szFileName,[edx].ADDINDATA.lpProjectPath
					invoke lstrcat,addr szFileName,addr szObjName
					invoke lstrcpy,addr szObjName,addr szFileName
					mov		edx,lpData
					invoke GetPrivateProfileString,addr szMakeFiles,addr szMakeFilesExeKey,addr szNULL,addr szExeName,sizeof szExeName,[edx].ADDINDATA.lpProject
					mov		edx,lpData
					invoke lstrcpy,addr szFileName,[edx].ADDINDATA.lpProjectPath
					invoke lstrcat,addr szFileName,addr szExeName
					invoke lstrcpy,addr szExeName,addr szFileName
					invoke PutString,addr szExeName
					invoke CreateThread,NULL,0,addr Debug,addr szExeName,NULL,addr tid
					mov		dbg.hDbgThread,eax
					invoke EnableMenu
					invoke LockFiles,TRUE
				.endif
			.endif
		.elseif edx==IDAddIn[16]
			;&Stop
			.if dbg.hDbgThread
				invoke TerminateProcess,dbg.pinfo.hProcess,0
			.endif
		.elseif edx==IDAddIn[20]
			;Step &Into
			.if dbg.hDbgThread
				invoke SetBreakPointsAll
				invoke ResumeThread,dbg.threadcontext
			.endif
		.elseif edx==IDAddIn[24]
			;Step &Over
			.if dbg.hDbgThread
			.endif
		.elseif edx==IDAddIn[28]
			;Run &To Caret
			.if dbg.hDbgThread
			.endif
		.elseif edx==IDAddIn[32]
			;Do not Debug
		.endif
	.elseif eax==AIM_EDITOPEN
		invoke EnableMenu
		invoke LoadBreakPoints
		.if lParam==ID_EDIT
			invoke SetWindowLong,wParam,GWL_WNDPROC,offset EditProc
			mov		lpOldEditProc,eax
		.endif
		.if dbg.hDbgThread
			invoke LockFiles,TRUE
		.endif
		;
	.elseif eax==AIM_EDITSELCHANGE
		.if dbg.hDbgThread
			invoke EnableMenu
		.endif
		;
	.elseif eax==AIM_CLOSE
		invoke FreeLibrary,hDbgHelpDLL
		;
	.elseif eax==AIM_MENUREBUILD
		;
	.elseif eax==AIM_PROJECTCLOSED
		invoke EnableMenu
		;
	.elseif eax==AIM_PROJECTOPENED
		invoke UpdateAccelerators
		invoke EnableMenu
		;
	.endif
	mov eax,FALSE
	ret

DllProc Endp

;#########################################################################

End DllEntry
