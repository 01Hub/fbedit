.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Debug.inc
include Misc.asm
include DebugPdb.asm

.code


;########################################################################

Dump proc uses ebx esi edi,lpData:DWORD
	LOCAL	dbgbuffer[256]:BYTE
	LOCAL	buffer[256]:BYTE

	mov		ebx,lpData
	invoke ReadProcessMemory,dbghand,ebx,addr dbgbuffer,256,0
	.if eax
		lea		esi,dbgbuffer
		xor		edx,edx
		.while edx<16
			push	edx
			invoke DumpLine,ebx,esi,16
			add		esi,16
			add		ebx,16
			pop		edx
			inc		edx
		.endw
		mov		dword ptr buffer,0A0Dh
		invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr buffer
		xor		eax,eax
		inc		eax
	.else
		.while TRUE
			invoke ReadProcessMemory,dbghand,ebx,addr dbgbuffer,1,0
PrintHex eax
			.break .if !eax
			invoke DumpLine,ebx,addr dbgbuffer,16
			add		ebx,16
		.endw
		xor		eax,eax
	.endif
	ret

Dump endp

PutString proc lpszStr:DWORD

	invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,lpszStr
	invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szCRLF
	ret

PutString endp

Debug proc lpFileName:DWORD
	LOCAL	sinfo:STARTUPINFO
	LOCAL	de:DEBUG_EVENT
	LOCAL	fContinue:DWORD
	LOCAL	buffer[256]:BYTE

	invoke RtlZeroMemory,addr sinfo,sizeof STARTUPINFO
	mov		sinfo.cb,SizeOf STARTUPINFO
	mov		sinfo.dwFlags,STARTF_USESHOWWINDOW
	mov		sinfo.wShowWindow,SW_NORMAL
	;Create process
	invoke CreateProcess,NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,addr sinfo,addr pinfo
	.if eax
		invoke WaitForSingleObject,pinfo.hProcess,10
		invoke OpenProcess,PROCESS_ALL_ACCESS,TRUE,pinfo.dwProcessId
		mov		dbghand,eax
		.while eax
			invoke Dump,dbgdump
			.if eax
				add		dbgdump,256
			.endif
		.endw
ret
		.while TRUE
			invoke WaitForDebugEvent,addr de,INFINITE
			mov		fContinue,DBG_CONTINUE
			mov		eax,de.dwDebugEventCode
			.if eax==EXCEPTION_DEBUG_EVENT
;					Select Case de.Exception.ExceptionRecord.ExceptionCode
;						Case EXCEPTION_BREAKPOINT
;							If fExit=0 Then
;								findthread(de.dwThreadId)
;								If debugthreadcontext=0 Then
;									If rline(FindLine(Cast(UInteger,de.Exception.ExceptionRecord.ExceptionAddress))).nu Then
;										debugthreadcontext=threadcontext
;									EndIf
;								EndIf
;								If threadcontext=debugthreadcontext Then
;									gestbrk(Cast(UInteger,de.Exception.ExceptionRecord.ExceptionAddress),fRun)
;								Else
;									gestbrk(Cast(UInteger,de.Exception.ExceptionRecord.ExceptionAddress),99)
;								EndIf
;							Else
;								' Stop
;								fContinue=DBG_EXCEPTION_NOT_HANDLED
;							EndIf
;						Case EXCEPTION_ACCESS_VIOLATION
;							sException="EXCEPTION_ACCESS_VIOLATION"
;							fContinue=DBG_EXCEPTION_NOT_HANDLED
;						Case EXCEPTION_FLT_DIVIDE_BY_ZERO
;							sException="EXCEPTION_FLT_DIVIDE_BY_ZERO"
;							fContinue=DBG_EXCEPTION_NOT_HANDLED
;						Case EXCEPTION_INT_DIVIDE_BY_ZERO
;							sException="EXCEPTION_INT_DIVIDE_BY_ZERO"
;							fContinue=DBG_EXCEPTION_NOT_HANDLED
;						Case EXCEPTION_DATATYPE_MISALIGNMENT
;							sException="EXCEPTION_DATATYPE_MISALIGNMENT"
;							fContinue=DBG_EXCEPTION_NOT_HANDLED
;						Case EXCEPTION_SINGLE_STEP
;							sException="EXCEPTION_SINGLE_STEP"
;							fContinue=DBG_EXCEPTION_NOT_HANDLED
;						Case DBG_CONTROL_C
;							sException="DBG_CONTROL_C"
;							fContinue=DBG_EXCEPTION_NOT_HANDLED
;					End Select
;					If fContinue=DBG_EXCEPTION_NOT_HANDLED Then
;						If de.Exception.dwFirstChance Then
;							If fexit=0 Then
;								PutString(sException)
;								findthread(de.dwThreadId)
;								gestbrk(Cast(UInteger,de.Exception.ExceptionRecord.ExceptionAddress),0)
;							EndIf
;						EndIf
;					EndIf
			.elseif eax==CREATE_PROCESS_DEBUG_EVENT
;					'PutString("CREATE_PROCESS_DEBUG_EVENT")
;					With de.CreateProcessInfo
;						threadnb+=1
;						thread(threadnb).thread=.hThread
;						thread(threadnb).threadid=de.dwThreadId
;						thread(threadnb).threadres=0
;						threadcontext=.hThread
;						hDebugFile=.hFile
;						If mainthread=0 Then
;							mainthread=threadcontext
;						EndIf
;					End With
			.elseif eax==CREATE_THREAD_DEBUG_EVENT
;					PutString("CREATE_THREAD_DEBUG_EVENT Thread=" & de.CreateThread.hThread)
;					With de.CreateThread
;						For i=0 To threadnb
;							If thread(i).thread=0 Then
;								Exit For
;							EndIf
;						Next
;						If i>threadnb Then
;							threadnb=i
;						EndIf
;						thread(i).thread=.hThread
;						thread(i).threadret=threadcontext
;						thread(i).threadid=de.dwThreadId
;						thread(i).threadres=99
;						threadcontext=.hThread
;					End With
			.elseif eax==EXIT_THREAD_DEBUG_EVENT
;					For i=0 To threadnb
;						If thread(i).threadid=de.dwThreadId Then
;							If debugthreadcontext=thread(i).thread Then
;								ClearBreakAll(0)
;								SetBreakPoints(-1)
;								debugthreadcontext=0
;							EndIf
;							PutString("EXIT_THREAD_DEBUG_EVENT ExitCode=" & de.ExitThread.dwExitCode & " Exitthread=" & thread(i).thread & " Returnthread=" & thread(i).threadret)
;							thread(i).thread=0
;							threadcontext=thread(i).threadret
;							If nLnDebug=-1 And threadcontext<>0 Then
;								lret=ResumeThread(threadcontext)
;							EndIf
;							Exit For
;						EndIf
;					Next
			.elseif eax==EXIT_PROCESS_DEBUG_EVENT
				invoke PutString,addr szEXIT_PROCESS_DEBUG_EVENT
				invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,DBG_CONTINUE
;					If fExit Then
;						PutString("Terminated by user.")
;					EndIf
				.break
			.elseif eax==LOAD_DLL_DEBUG_EVENT
					mov		buffer,0
					;invoke GetModuleFileName,de.LoadDll.lpBaseOfDll,addr buffer,256
					invoke PutString,addr szLOAD_DLL_DEBUG_EVENT
					;invoke PutString,addr buffer
			.elseif eax==UNLOAD_DLL_DEBUG_EVENT
;					buffer=""
;					GetModuleFileName(de.UnloadDll.lpBaseOfDll,@buffer,256)
				invoke PutString,addr szUNLOAD_DLL_DEBUG_EVENT
			.elseif eax==OUTPUT_DEBUG_STRING_EVENT
;					nln=de.DebugString.nDebugStringLength
;					If nln>255 Then
;						nln=255
;					EndIf
;					lret=ReadProcessMemory(dbghand,de.DebugString.lpDebugStringData,@buffer,nln,0)
;					PutString(@buffer)
			.elseif eax==RIP_EVENT
;					PutString("RIP_EVENT")
			.endif
			invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,fContinue
		.endw

	.endif
	ret

Debug endp

CldDlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hCldDlg,eax
		invoke SetCurrentStream
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWnd,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNBROWSE
				;Zero out the ofn struct
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				;Setup the ofn struct
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrFilter,offset szPDBFilterString
				mov		buffer[0],0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.lpstrDefExt,NULL
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				;Show the Open dialog
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke SetDlgItemText,hWin,IDC_EDTFILE,addr buffer
					invoke CloseStreams
					invoke OpenPdbFile,addr buffer
					invoke SetCurrentStream
					invoke DumpStream,offset stream,0
				.endif
			.elseif eax==IDC_BTNPREVIOUS
				.if nCurrentStream
					dec		nCurrentStream
					invoke SetCurrentStream
					mov		eax,nCurrentStream
					mov		edx,offset stream
					lea		edx,[edx+eax*sizeof STREAM]
					invoke DumpStream,edx,eax
				.endif
			.elseif eax==IDC_BTNNEXT
				mov		eax,nCurrentStream
				inc		eax
				.if eax<nStreams
					inc		nCurrentStream
					invoke SetCurrentStream
					mov		eax,nCurrentStream
					mov		edx,offset stream
					lea		edx,[edx+eax*sizeof STREAM]
					invoke DumpStream,edx,eax
				.endif
			.elseif eax==IDC_BTNSAVE
				.if nStreams
					invoke SaveStream,nCurrentStream
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

CldDlgProc endp

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	cldrect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke GetDlgItem,hWin,IDC_REDDEBUG
		mov		hEdt,eax
		invoke CreateFontIndirect,addr Courier_New_10
		mov		hFont,eax
		invoke SendMessage,hEdt,WM_SETFONT,hFont,FALSE
		invoke SendMessage,hEdt,EM_EXLIMITTEXT,0,1024*1024
		invoke CreateDialogParam,hInstance,IDD_DLGCHILD,hWin,addr CldDlgProc,0
	.elseif eax==WM_SIZE
		; Move and size the rich edit control
		invoke GetClientRect,hWin,addr rect
		mov		eax,rect.bottom
		sub		eax,70
		invoke MoveWindow,hEdt,0,0,rect.right,eax,TRUE
		; Move the cild dialog
		invoke GetClientRect,hCldDlg,addr cldrect
		mov		eax,rect.bottom
		sub		eax,65
		mov		edx,rect.right
		sub		edx,cldrect.right
		invoke MoveWindow,hCldDlg,edx,eax,cldrect.right,cldrect.bottom,TRUE
	.elseif eax==WM_CLOSE
		invoke CloseStreams
		invoke DeleteObject,hFont
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke LoadLibrary,addr RichEditDLL
	mov		hRichEdDLL,eax
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke FreeLibrary,hRichEdDLL
	invoke ExitProcess,0

end start
