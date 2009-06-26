;#########################################################################
; Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;		Include file

include RADebug.inc
include Misc.asm
include Math.asm
include DbgHelp.asm
include Debug.asm
include Immediate.asm
include BreakPoint.asm

.code

;#########################################################################
; Common AddIn Procedures

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
		.if ax==[ebx].ACCEL.cmd || [ebx].ACCEL.cmd==0 || (dl==byte ptr [ebx].ACCEL.key && dh==[ebx].ACCEL.fVirt)
			.if ![ebx].ACCEL.cmd
				; Add new
				inc		nAccel
			.endif
			mov		[ebx].ACCEL.cmd,ax
			mov		byte ptr [ebx].ACCEL.key,dl
			mov		[ebx].ACCEL.fVirt,dh
			.break
		.endif
		add		ebx,sizeof ACCEL
		dec		ecx
	.endw
	retn

UpdateAccelerators endp

CreateDebugMenu proc uses ebx esi edi,hWin:HWND
	LOCAL	mii:MENUITEMINFO

	.if hMnu
		mov		eax,[lpHandles]
		invoke RemoveMenu,[eax].ADDINHANDLES.hMenu,IDAddIn,MF_BYCOMMAND
		invoke DestroyMenu,hMnu
		mov		hMnu,0
	.elseif !IDAddIn
		mov		edi,offset IDAddIn
		xor		ecx,ecx
		.while ecx<9
			push	ecx
			; Allocate a new menu id
			invoke SendMessage,hWin,AIM_GETMENUID,0,0
			pop		ecx
			mov		[edi+ecx*4],eax
			inc		ecx
		.endw
	.endif
	invoke CreatePopupMenu
	mov		hMnu,eax
	;Make menu
	mov		edx,5
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
	mov		eax,[edi]
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
			;Add our menuitem
			invoke AppendMenu,hMnu,MF_STRING,[edi],esi
			add		edi,4
		.endif
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	ret

CreateDebugMenu endp

EditProc proc uses ebx esi,hWin:HWND,wParam:WPARAM,lParam:LPARAM
	LOCAL	ti:TOOLINFO
	LOCAL	buffer[256]:BYTE
	LOCAL	pt:POINT
	LOCAL	hPar:HWND

	mov		ti.cbSize,SizeOf TOOLINFO
	mov		ti.uFlags,TTF_IDISHWND
	mov		eax,hWin
	mov		ti.hWnd,eax
	mov		ti.uId,eax
	mov		ti.lpszText,0
	invoke SendMessage,hTip,TTM_GETTOOLINFO,0,addr ti
	.if dbg.hDbgThread && dbg.fHandled
		.if !eax
			;Add the tooltip
			mov		ti.uFlags,TTF_IDISHWND Or TTF_SUBCLASS
			mov		eax,hWin
			mov		ti.hWnd,eax
			mov		ti.uId,eax
			mov		eax,hInstance
			mov		ti.hInst,eax
			invoke SendMessage,hTip,TTM_ADDTOOL,0,addr ti
		.endif
		mov		eax,lParam
		mov		edx,eax
		shr		edx,16
		movsx	edx,dx
		movsx	eax,ax
		mov		pt.x,eax
		mov		pt.y,edx
		sub		eax,dbg.pt.x
		.if CARRY?
			neg		eax
		.endif
		sub		edx,dbg.pt.y
		.if CARRY?
			neg		edx
		.endif
		.if eax>5 || edx>5
			mov		eax,pt.x
			mov		dbg.pt.x,eax
			mov		eax,pt.y
			mov		dbg.pt.y,eax
			invoke GetParent,hWin
			mov		hPar,eax
			invoke SendMessage,hPar,EM_CHARFROMPOS,0,addr pt
			invoke SendMessage,hPar,REM_ISCHARPOS,eax,0
			.if !eax
				invoke SendMessage,hPar,REM_GETCURSORWORD,sizeof buffer,addr buffer
				.if buffer
					mov		var.IsSZ,0
					invoke GetVarVal,addr buffer,eax,TRUE
					.if eax
						mov		edx,var.ProjectFileID
						.if edx
							invoke GetParent,hPar
							invoke GetWindowLong,eax,16
							mov		edx,var.ProjectFileID
							sub		edx,eax
						.endif
						.if !edx
							; Show tooltip
							mov		ti.lpszText,offset outbuffer
							call	Activate
						.else
							; Hide tooltip
							call	DeActivate
						.endif
					.else
						; Hide tooltip
						call	DeActivate
					.endif
				.else
					; Hide tooltip
					call	DeActivate
				.endif
			.else
				; Hide tooltip
				call	DeActivate
			.endif
		.endif
	.elseif eax
		; Delete the tool
		invoke SendMessage,hTip,TTM_DELTOOL,0,addr ti
	.endif
	ret

Activate:
	invoke SendMessage,hTip,TTM_SETTOOLINFO,0,addr ti
	invoke SendMessage,hTip,TTM_ACTIVATE ,FALSE,0
	invoke SendMessage,hTip,TTM_ACTIVATE ,TRUE,0
	retn

DeActivate:
	invoke SendMessage,hTip,TTM_ACTIVATE ,FALSE,0
	retn

EditProc endp

DoNotDebugProc proc uses esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	buffer1[8]:BYTE
	LOCAL	nInx:DWORD
	LOCAL	hMem:HGLOBAL

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,65536
		mov		hMem,eax
		mov		edi,eax
		mov		nInx,0
		.while TRUE
			invoke wsprintf,addr buffer1,addr szCommaBP[1],nInx
			mov		eax,lpData
			invoke GetPrivateProfileString,addr szNoDebug,addr buffer1,addr szNULL,addr buffer,sizeof buffer,[eax].ADDINDATA.lpProject
			.break .if !eax
			invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_ADDSTRING,0,addr buffer
			invoke strcpy,edi,addr buffer
			invoke strlen,edi
			lea		edi,[edi+eax+1]
			inc		nInx
		.endw
		mov		edx,lpData
		;Get pointer to word list
		mov		esi,[edx].ADDINDATA.lpWordList
		;Skip the words loaded from .api files
		add		esi,[edx].ADDINDATA.rpProjectWordList
		;Loop trough the word list
		.while [esi].PROPERTIES.nSize
			;Check if it is a proc
			.if [esi].PROPERTIES.nType=='p'
				push	esi
				;Point to the proc name
				lea		esi,[esi+sizeof PROPERTIES]
				mov		edi,hMem
				.while byte ptr [edi]
					invoke strcmp,edi,esi
					.break .if !eax
					invoke strlen,edi
					lea		edi,[edi+eax+1]
				.endw
				.if eax
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_ADDSTRING,0,esi
				.endif
				pop		esi
			.endif
			;Move to next word
			mov		eax,[esi].PROPERTIES.nSize
			lea		esi,[esi+eax+sizeof PROPERTIES]
		.endw
		invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_SETCURSEL,0,0
		invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_SETCURSEL,0,0
		.if dbg.hDbgThread
			mov		eax,IDC_BTNDONOTDEBUG
			call	Disable
			mov		eax,IDC_BTNDEBUG
			call	Disable
			mov		eax,IDC_BTNDONOTDEBUGALL
			call	Disable
			mov		eax,IDC_BTNDEBUGALL
			call	Disable
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				mov		eax,lpData
				invoke WritePrivateProfileSection,addr szNoDebug,addr szBPNULL,[eax].ADDINDATA.lpProject
				mov		nInx,0
				.while TRUE
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_GETTEXT,nInx,addr buffer
					.break .if eax==LB_ERR
					invoke wsprintf,addr buffer1,addr szCommaBP[1],nInx
					mov		eax,lpData
					invoke WritePrivateProfileString,addr szNoDebug,addr buffer1,addr buffer,[eax].ADDINDATA.lpProject
					inc		nInx
				.endw
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNDONOTDEBUG
				invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		nInx,eax
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_GETTEXT,nInx,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_DELETESTRING,nInx,0
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_ADDSTRING,0,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_SETCURSEL,eax,0
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_SETCURSEL,nInx,0
					.if eax==LB_ERR && nInx
						dec		nInx
						invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_SETCURSEL,nInx,0
					.endif
				.endif
			.elseif eax==IDC_BTNDEBUG
				invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		nInx,eax
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_GETTEXT,nInx,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_DELETESTRING,nInx,0
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_ADDSTRING,0,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_SETCURSEL,eax,0
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_SETCURSEL,nInx,0
					.if eax==LB_ERR && nInx
						dec		nInx
						invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_SETCURSEL,nInx,0
					.endif
				.endif
			.elseif eax==IDC_BTNDONOTDEBUGALL
				.while TRUE
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_GETTEXT,0,addr buffer
					.break .if eax==LB_ERR
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_DELETESTRING,0,0
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_ADDSTRING,0,addr buffer
				.endw
			.elseif eax==IDC_BTNDEBUGALL
				.while TRUE
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_GETTEXT,0,addr buffer
					.break .if eax==LB_ERR
					invoke SendDlgItemMessage,hWin,IDC_LSTDONOTDEBUG,LB_DELETESTRING,0,0
					invoke SendDlgItemMessage,hWin,IDC_LSTDEBUG,LB_ADDSTRING,0,addr buffer
				.endw
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Disable:
	invoke GetDlgItem,hWin,eax
	invoke EnableWindow,eax,FALSE
	retn

DoNotDebugProc endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
InstallDll proc uses ebx,hWin:DWORD,fOpt:DWORD

	mov		ebx,hWin
	mov		eax,fOpt
	mov		fOptions,eax
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0
	mov		lpHandles,eax
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	mov		eax,[eax].ADDINDATA.nRadASMVer
	.if eax>=2217
		mov		nRadASMVer,eax
		; Get handle to outputwindow #1, #2 and #3
		mov		eax,lpHandles
		mov		edx,[eax].ADDINHANDLES.hOut1
		mov		hOut1,edx
		mov		edx,[eax].ADDINHANDLES.hOut2
		mov		hOut2,edx
		mov		edx,[eax].ADDINHANDLES.hOut3
		mov		hOut3,edx
		invoke SendMessage,hOut3,REM_SUBCLASS,0,addr ImmediateProc
		mov		lpOldOutProc3,eax
		; Create tooltip
		invoke CreateWindowEx,0,addr sztooltips_class32,NULL,TTS_NOPREFIX,0,0,0,0,NULL,0,hInstance,0
		mov		hTip,eax
		invoke SendMessage,hTip,TTM_ACTIVATE,TRUE,0
		invoke SendMessage,hTip,TTM_SETDELAYTIME,TTDT_INITIAL,100
		invoke SendMessage,hTip,TTM_SETDELAYTIME,TTDT_AUTOPOP,10000
		invoke SendMessage,hTip,TTM_SETMAXTIPWIDTH,0,800
		invoke CreateDebugMenu,hWin
		invoke UpdateAccelerators
		; Messages to hook into
		mov		eax,RAM_COMMAND OR RAM_CLOSE OR RAM_MENUREBUILD OR RAM_PROJECTOPENED OR RAM_PROJECTCLOSED OR RAM_EDITOPEN or RAM_EDITSELCHANGE or RAM_EDITSAVED
		mov		ecx,RAM_EDITMOUSEMOVE
	.else
		xor		eax,eax
		xor		ecx,ecx
	.endif
	xor		edx,edx
	ret 

InstallDll Endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
GetOptions proc

	mov		eax,offset AddinOpt
	ret

GetOptions endp

; This proc handles messages sent from RadASM to our dll
DllProc proc uses ebx,hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL	tid:DWORD
	LOCAL	buffer[512]:BYTE

	mov		eax,uMsg
	.if eax==AIM_COMMAND
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
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
			invoke SaveBreakPoints
			.if dbg.hDbgThread
				invoke LoadAllBreakPoints
				invoke MapBreakPoints
			.endif
		.elseif edx==IDAddIn[12]
			;&Run
			.if dbg.hDbgThread
				;.if dbg.fHandled
					mov		dbg.fHandled,FALSE
					invoke ResetSelectLine
					mov		dbg.func,FUNC_RUN
					invoke ClearBreakPointsAll
					invoke SetBreakPoints
					mov		ebx,dbg.lpthread
					.if [ebx].DEBUGTHREAD.suspended
						invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
						mov		[ebx].DEBUGTHREAD.suspended,FALSE
						invoke ResumeThread,[ebx].DEBUGTHREAD.htread
					.endif
				;.endif
			.else
				mov		ebx,lpData
				.if [ebx].ADDINDATA.fProject
					invoke UnsavedFiles
					.if eax
						invoke wsprintf,addr buffer,addr szUnsavedFiles,eax
						mov		edx,lpHandles
						invoke MessageBox,[edx].ADDINHANDLES.hWnd,addr buffer,addr szDebug,MB_OK or MB_ICONERROR
					.else
						invoke GetPrivateProfileString,addr szMakeFiles,addr szMakeFilesObjKey,addr szNULL,addr szObjName,sizeof szObjName,[ebx].ADDINDATA.lpProject
						invoke strcpy,addr szTempName,[ebx].ADDINDATA.lpProjectPath
						invoke strcat,addr szTempName,addr szObjName
						invoke strcpy,addr szObjName,addr szTempName
						invoke GetPrivateProfileString,addr szMakeFiles,addr szMakeFilesExeKey,addr szNULL,addr szExeName,sizeof szExeName,[ebx].ADDINDATA.lpProject
						invoke strcpy,addr szTempName,[ebx].ADDINDATA.lpProjectPath
						invoke strcat,addr szTempName,addr szExeName
						invoke strcpy,addr szExeName,addr szTempName
						invoke NewerFiles
						.if sdword ptr eax>0
							invoke wsprintf,addr buffer,addr szNewerFiles,eax
							mov		edx,lpHandles
							invoke MessageBox,[edx].ADDINHANDLES.hWnd,addr buffer,addr szDebug,MB_OK or MB_ICONERROR
						.elseif sdword ptr eax<0
							invoke wsprintf,addr buffer,addr szExeNotFound,addr szExeName
							mov		edx,lpHandles
							invoke MessageBox,[edx].ADDINHANDLES.hWnd,addr buffer,addr szDebug,MB_OK or MB_ICONERROR
						.else
							invoke RtlZeroMemory,addr dbg,sizeof dbg
							.if fOptions & 4
								; Pin output window
								push	0
								push	15						;TLM_GET_STRUCT
								mov		eax,lpHandles
								push	[eax].ADDINHANDLES.hOut
								mov		eax,lpProc
								call	[eax].ADDINPROCS.lpToolMessage
								mov		edx,[eax+8]				;.Visible
								.if !edx
									; Show
									mov		eax,lpHandles
									mov		eax,[eax].ADDINHANDLES.hWnd
									invoke SendMessage,eax,WM_COMMAND,IDM_VIEW_OUTPUTWINDOW,eax
								.else
									; Hide
									mov		eax,lpHandles
									mov		eax,[eax].ADDINHANDLES.hWnd
									invoke SendMessage,eax,WM_COMMAND,IDM_VIEW_OUTPUTWINDOW,eax
									; Show
									mov		eax,lpHandles
									mov		eax,[eax].ADDINHANDLES.hWnd
									invoke SendMessage,eax,WM_COMMAND,IDM_VIEW_OUTPUTWINDOW,eax
								.endif
							.endif
							; Clear output #3
							push	3
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpOutputSelect
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpClearOut
							; Clear output #2
							push	2
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpOutputSelect
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpClearOut
							; Clear output #1
							push	1
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpOutputSelect
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpClearOut
							mov		dbg.func,FUNC_RUN
							; Show debug info window
							push	1
							mov		eax,lpProc
							call	[eax].ADDINPROCS.lpOutputSelect
							invoke CreateThread,NULL,0,addr Debug,addr szExeName,NULL,addr tid
							mov		dbg.hDbgThread,eax
						.endif
					.endif
				.endif
			.endif
		.elseif edx==IDAddIn[16]
			;&Stop
			.if dbg.hDbgThread
				invoke ResetSelectLine
				mov		dbg.func,FUNC_STOP
				invoke TerminateProcess,dbg.pinfo.hProcess,0
			.endif
		.elseif edx==IDAddIn[20]
			;Step &Into
			.if dbg.hDbgThread
				.if dbg.fHandled
					mov		dbg.fHandled,FALSE
					invoke ResetSelectLine
				  StepInto:
					mov		dbg.func,FUNC_STEPINTO
					invoke SetBreakPointsAll
					mov		ebx,dbg.lpthread
					.if ![ebx].DEBUGTHREAD.suspended
						mov		[ebx].DEBUGTHREAD.suspended,TRUE
						invoke SuspendThread,[ebx].DEBUGTHREAD.htread
					.endif
					invoke SwitchThread
					mov		ebx,eax
					mov		dbg.lpthread,ebx
					.if [ebx].DEBUGTHREAD.suspended
						invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
						mov		[ebx].DEBUGTHREAD.suspended,FALSE
						invoke ResumeThread,[ebx].DEBUGTHREAD.htread
					.endif
				.endif
			.endif
		.elseif edx==IDAddIn[24]
			;Step &Over
			.if dbg.hDbgThread
				.if dbg.fHandled
					mov		dbg.fHandled,FALSE
					invoke ResetSelectLine
					invoke IsLineCall
					.if !eax
						jmp		StepInto
					.endif
					mov		ebx,dbg.lpthread
					mov		ebx,[ebx].DEBUGTHREAD.lpline
					mov		ax,[ebx].DEBUGLINE.FileID
					lea		ebx,[ebx+sizeof DEBUGLINE]
					.if ax==[ebx].DEBUGLINE.FileID
						;Step &Over
						mov		dbg.func,FUNC_STEPOVER
						invoke ClearBreakPointsAll
						invoke SetBreakpointAtCurrentLine,[ebx].DEBUGLINE.LineNumber
						mov		ebx,dbg.lpthread
						.if [ebx].DEBUGTHREAD.suspended
							mov		[ebx].DEBUGTHREAD.suspended,FALSE
							invoke ResumeThread,[ebx].DEBUGTHREAD.htread
						.endif
					.else
						jmp		StepInto
					.endif
				.endif
			.endif
		.elseif edx==IDAddIn[28]
			;Run &To Caret
			.if dbg.hDbgThread
				.if dbg.fHandled
					mov		dbg.fHandled,FALSE
					invoke ResetSelectLine
					mov		dbg.func,FUNC_RUNTOCARET
					invoke ClearBreakPointsAll
					invoke SetBreakpointAtCurrentLine,0
					mov		ebx,dbg.lpthread
					.if [ebx].DEBUGTHREAD.suspended
						mov		[ebx].DEBUGTHREAD.suspended,FALSE
						invoke ResumeThread,[ebx].DEBUGTHREAD.htread
					.endif
				.endif
			.endif
		.elseif edx==IDAddIn[32]
			;Do not Debug
			mov		eax,lpHandles
			invoke DialogBoxParam,hInstance,IDD_DLGDONOTDEBUG,[eax].ADDINHANDLES.hWnd,addr DoNotDebugProc,0
		.endif
		;
	.elseif eax==AIM_EDITOPEN
		invoke EnableMenu
		.if lParam==ID_EDIT
			invoke LoadBreakPoints
		.endif
		.if dbg.hDbgThread
			invoke LockFiles,TRUE
		.endif
		;
	.elseif eax==AIM_EDITSELCHANGE
		invoke EnableMenu
		;
	.elseif eax==AIM_EDITSAVED
		invoke SaveBreakPoints
		;
	.elseif eax==AIM_CLOSE
		.if lpOldOutProc3
			;UnHook Output3 WndProc
			invoke SendMessage,hOut3,REM_SUBCLASS,0,lpOldOutProc3
			mov		lpOldOutProc3,0
		.endif
		.if hMnu
			mov		eax,[lpHandles]
			invoke RemoveMenu,[eax].ADDINHANDLES.hMenu,IDAddIn,MF_BYCOMMAND
			invoke DestroyMenu,hMnu
			mov		hMnu,0
		.endif
		;
	.elseif eax==AIM_MENUREBUILD
		mov		eax,lpHandles
		invoke CreateDebugMenu,[eax].ADDINHANDLES.hWnd
		invoke UpdateAccelerators
		;
	.elseif eax==AIM_PROJECTCLOSED
		invoke EnableMenu
		;
	.elseif eax==AIM_PROJECTOPENED
		invoke UpdateAccelerators
		invoke EnableMenu
		invoke LoadWatch
		;
	.elseif eax==AIM_UNHOOK
		mov		eax,hWin
		.if eax==hOut3
			mov		eax,wParam
			.if eax==lpOldOutProc3
				;Remove the hook from the chain
				mov		eax,lParam
				mov		lpOldOutProc3,eax
				mov		eax,TRUE
				jmp		Ex
			.endif
		.endif
		;
	.elseif eax==AIM_EDITMOUSEMOVE
		invoke EditProc,hWin,wParam,lParam
	.endif
	mov eax,FALSE
  Ex:
	ret

DllProc Endp

;#########################################################################

End DllEntry
