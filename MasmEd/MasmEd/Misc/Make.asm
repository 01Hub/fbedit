MAKE struct
	hThread		dd ?
	hRead		dd ?
	hWrite		dd ?
	pInfo		PROCESS_INFORMATION <?>
	uExit		dd ?
	buffer		db 512 dup(?)
MAKE ends

.data

defPathBin				db 'C:\masm32\bin',0
defPathInc				db 'C:\masm32\include',0
defPathLib				db 'C:\masm32\lib',0

defCompileRC			db 'rc /v',0
defAssemble				db 'ml /c /coff /Cp',0
defLink					db 'link /SUBSYSTEM:WINDOWS /RELEASE /VERSION:4.0',0
defDbgLink				db 'link /SUBSYSTEM:WINDOWS /DEBUG /VERSION:4.0',0

ExtRC					db '.rc',0
ExtRes					db '.res',0
ExtObj					db '.obj',0
ExtExe					db '.exe',0

rsrcrc					db 'rsrc.rc',0
rsrcres					db 'rsrc.res',0

MakeDone				db 0Dh,'Make done.',0Dh,0
Errors					db 0Dh,'Error(s) occured.',0Dh,0
Terminated				db 0Dh,'Terminated by user.',0
NoRC					db 0Dh,'No .rc file found.',0Dh,0
Exec					db 0Dh,'Executing:',0
NoDel					db 0Dh,'Could not delete:',0Dh,0

CreatePipeError			db 'Error during pipe creation',0
CreateProcessError		db 'Error during process creation',0Dh,0Ah,0

.data?

make					MAKE <>

.code

MakeThreadProc proc uses ebx,Param:DWORD
	LOCAL	sat:SECURITY_ATTRIBUTES
	LOCAL	startupinfo:STARTUPINFO
	LOCAL	bytesRead:DWORD
	LOCAL	buffer[256]:BYTE

	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset szCr
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr make.buffer
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset szCr
	invoke SendMessage,hOut,EM_SCROLLCARET,0,0
	.if Param==IDM_MAKE_RUN
		invoke WinExec,addr make.buffer,SW_SHOWNORMAL
		.if eax>=32
			xor		eax,eax
		.endif
	.else
		mov sat.nLength,sizeof SECURITY_ATTRIBUTES
		mov sat.lpSecurityDescriptor,NULL
		mov sat.bInheritHandle,TRUE
		invoke CreatePipe,addr make.hRead,addr make.hWrite,addr sat,NULL
		.if eax==NULL
			;CreatePipe failed
			invoke LoadCursor,0,IDC_ARROW
			invoke SetCursor,eax
			invoke MessageBox,hWnd,addr CreatePipeError,addr szAppName,MB_ICONERROR+MB_OK
			xor		eax,eax
		.else
			mov startupinfo.cb,sizeof STARTUPINFO
			invoke GetStartupInfo,addr startupinfo
			mov eax,make.hWrite
			mov startupinfo.hStdOutput,eax
			mov startupinfo.hStdError,eax
			mov startupinfo.dwFlags,STARTF_USESHOWWINDOW+STARTF_USESTDHANDLES
			mov startupinfo.wShowWindow,SW_HIDE
			;Create process
			invoke CreateProcess,NULL,addr make.buffer,NULL,NULL,TRUE,NULL,NULL,NULL,addr startupinfo,addr make.pInfo
			.if eax==NULL
				;CreateProcess failed
				invoke CloseHandle,make.hRead
				invoke CloseHandle,make.hWrite
				invoke LoadCursor,0,IDC_ARROW
				invoke SetCursor,eax
				invoke lstrcpy,addr buffer,addr CreateProcessError
				invoke lstrcat,addr buffer,addr make.buffer
				invoke MessageBox,hWnd,addr buffer,addr szAppName,MB_ICONERROR+MB_OK
				xor		eax,eax
			.else
				invoke CloseHandle,make.hWrite
				invoke RtlZeroMemory,addr make.buffer,sizeof make.buffer
				xor		ebx,ebx
				.while TRUE
					invoke ReadFile,make.hRead,addr make.buffer[ebx],1,addr bytesRead,NULL
					.if eax==NULL
						.if ebx
							call	OutputText
						.endif
						.break
					.else
						.if make.buffer[ebx]==0Ah || ebx==511
							call	OutputText
						.else
							inc		ebx
						.endif
					.endif
				.endw
				invoke GetExitCodeProcess,make.pInfo.hProcess,addr make.uExit
				invoke CloseHandle,make.hRead
				invoke CloseHandle,make.pInfo.hProcess
				invoke CloseHandle,make.pInfo.hThread
				mov		eax,TRUE
			.endif
		.endif
	.endif
	invoke ExitThread,eax
	ret

OutputText:
	mov		make.buffer[ebx+1],0
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr make.buffer
	invoke SendMessage,hOut,EM_SCROLLCARET,0,0
	xor		ebx,ebx
	retn

MakeThreadProc endp

FindErrors proc uses ebx
	LOCAL	buffer[512]:BYTE
	LOCAL	nLn:DWORD
	LOCAL	nLnErr:DWORD
	LOCAL	nLastLnErr:DWORD
	LOCAL	nErr:DWORD

	invoke SendMessage,hOut,EM_GETLINECOUNT,0,0
	xor		ebx,ebx
	mov		nErrID,ebx
	mov		nLn,ebx
	mov		nLastLnErr,-1
	.while nLn<eax
		push	eax
		call	TestLine
		pop		eax
		inc		nLn
	.endw
	mov		ErrID[ebx*4],0
	ret

TestLine:
	mov		word ptr buffer,sizeof buffer-1
	invoke SendMessage,hOut,EM_GETLINE,nLn,addr buffer
	mov		byte ptr buffer[eax],0
	invoke iniInStr,addr buffer,addr szError
	.if eax!=-1
		.while eax && byte ptr buffer[eax]!='('
			dec		eax
		.endw
		mov		byte ptr buffer[eax],0
		invoke AsciiToDw,addr buffer[eax+1]
		dec		eax
		.if eax!=nLastLnErr
			mov		nLnErr,eax
			mov		nLastLnErr,eax
			invoke SendMessage,hOut,REM_SETBOOKMARK,nLn,6
			invoke SendMessage,hOut,REM_GETBMID,nLn,0
			mov		nErr,eax
			invoke lstrlen,addr buffer
			.while eax && word ptr buffer[eax+1]!='\:'
				dec		eax
			.endw
			invoke OpenEditFile,addr buffer[eax],0
			invoke GetWindowLong,hREd,GWL_ID
			.if eax==IDC_RAE
				invoke SendMessage,hREd,REM_SETERROR,nLnErr,nErr
				mov		eax,nErr
				mov		ErrID[ebx*4],eax
				inc		ebx
			.endif
		.endif
	.endif
	retn

FindErrors endp

OutputMake proc uses ebx,nCommand:DWORD,lpFileName:DWORD,fClear:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	buffer2[256]:BYTE
	LOCAL	fExitCode:DWORD
	LOCAL	ThreadID:DWORD
	LOCAL	msg:MSG

	invoke OutputSelect,0
	test	wpos.fView,4
	.if ZERO?
		or		wpos.fView,4
		invoke ShowWindow,hOut,SW_SHOWNA
		invoke SendMessage,hWnd,WM_SIZE,0,0
	.endif
	movzx	eax,MainFile
	.if !eax
		invoke SendMessage,hOut,WM_SETTEXT,0,addr szNoMain
		ret
	.endif
	invoke SetCurDir,lpFileName,FALSE
	mov		fExitCode,0
	invoke LoadCursor,0,IDC_WAIT
	invoke SetCursor,eax
	invoke SetFocus,hOut
	mov		make.buffer,0
	.if fClear==1 || fClear==2
		invoke SendMessage,hOut,WM_SETTEXT,0,addr make.buffer
		invoke SendMessage,hOut,EM_SCROLLCARET,0,0
	.endif
	mov		eax,nCommand
	.if eax==IDM_MAKE_COMPILE
		invoke lstrcpy,addr make.buffer,offset CompileRC
		invoke lstrcat,addr make.buffer,addr szSpc
		;Try FileName.rc
		invoke lstrcpy,addr buffer2,lpFileName
		invoke RemoveFileExt,addr buffer2
		invoke lstrcat,addr buffer2,offset ExtRC
		invoke GetFileAttributes,addr buffer2
		.if eax==-1
			;FileName.rc not found, try rsrc.rc
			mov		lpFileName,offset rsrcrc
			invoke RemoveFileName,addr buffer2
			invoke lstrcat,addr buffer2,lpFileName
			invoke GetFileAttributes,addr buffer2
			.if eax==-1
				;FileName.rc nor rsrc.rc found, give message and exit
				invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset NoRC
				invoke SendMessage,hOut,EM_SCROLLCARET,0,0
				jmp		Ex
			.endif
		.endif
		invoke lstrcat,addr make.buffer,offset szQuote
		invoke lstrcat,addr make.buffer,addr buffer2
		invoke lstrcat,addr make.buffer,offset szQuote
		mov		eax,offset ExtRes
	.elseif eax==IDM_MAKE_ASSEMBLE
		invoke lstrcpy,addr make.buffer,offset Assemble
		invoke lstrcat,addr make.buffer,addr szSpc
		invoke lstrcat,addr make.buffer,offset szQuote
		invoke lstrcat,addr make.buffer,lpFileName
		invoke lstrcat,addr make.buffer,offset szQuote
		mov		eax,offset ExtObj
	.elseif eax==IDM_MAKE_LINK
		invoke SendMessage,hCbo,CB_GETCURSEL,0,0
		.if eax
			invoke lstrcpy,addr make.buffer,offset DbgLink
		.else
			invoke lstrcpy,addr make.buffer,offset Link
		.endif
		invoke lstrcat,addr make.buffer,addr szSpc
		invoke lstrcpy,addr buffer2,lpFileName
		invoke RemoveFileExt,addr buffer2
		invoke lstrcat,addr buffer2,offset ExtObj
		invoke lstrcat,addr make.buffer,offset szQuote
		invoke lstrcat,addr make.buffer,addr buffer2
		invoke lstrcat,addr make.buffer,offset szQuote
		invoke RemoveFileExt,addr buffer2
		invoke lstrcat,addr buffer2,offset ExtRes
		invoke GetFileAttributes,addr buffer2
		.if eax==-1
			;FileName.res not found, try if rsrc.res exist
			invoke RemoveFileName,addr buffer2
			invoke lstrcat,addr buffer2,offset rsrcres
			invoke GetFileAttributes,addr buffer2
			.if eax!=-1
				;rsrc.res found
				invoke lstrcat,addr make.buffer,offset szSpc
				invoke lstrcat,addr make.buffer,offset szQuote
				invoke lstrcat,addr make.buffer,addr buffer2
				invoke lstrcat,addr make.buffer,offset szQuote
			.endif
		.else
			;FileName.res found
			invoke lstrcat,addr make.buffer,offset szSpc
			invoke lstrcat,addr make.buffer,offset szQuote
			invoke lstrcat,addr make.buffer,addr buffer2
			invoke lstrcat,addr make.buffer,offset szQuote
		.endif
		mov		eax,offset ExtExe
	.elseif eax==IDM_MAKE_RUN
		invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset Exec
		invoke lstrcpy,addr make.buffer,lpFileName
		invoke RemoveFileExt,addr make.buffer
		invoke lstrcat,addr make.buffer,offset ExtExe
		xor		eax,eax
	.else
		jmp		Ex
	.endif
	.if eax
		;Delete old file
		push	eax
		invoke lstrcpy,addr buffer2,lpFileName
		invoke RemoveFileExt,addr buffer2
		pop		eax
		invoke lstrcat,addr buffer2,eax
		invoke GetFileAttributes,addr buffer2
		.if eax!=INVALID_HANDLE_VALUE
			invoke DeleteFile,addr buffer2
			.if !eax
				mov		fExitCode,-1
				invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset NoDel
				invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr buffer2
				invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset szCr
				invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset Errors
				jmp		Ex
			.endif
		.endif
	.endif
	invoke CreateThread,NULL,NULL,addr MakeThreadProc,nCommand,NORMAL_PRIORITY_CLASS,addr ThreadID
	mov		make.hThread,eax
	.while TRUE
		invoke LoadCursor,0,IDC_WAIT
		invoke SetCursor,eax
		invoke GetMessage,addr msg,NULL,0,0
		mov		eax,msg.message
		.if eax!=WM_CHAR
			.if msg.wParam==VK_ESCAPE
				invoke TerminateProcess,make.pInfo.hProcess,1234
			.endif
		.elseif eax!=WM_KEYDOWN && eax!=WM_CLOSE && (eax<WM_MOUSEFIRST || eax>WM_MOUSELAST)
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
		invoke GetExitCodeThread,make.hThread,addr ThreadID
		.break .if ThreadID!=STILL_ACTIVE
	.endw
	invoke CloseHandle,make.hThread
	.if ThreadID
		.if make.uExit==1234
			invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset Terminated
			invoke FindErrors
		.else
			mov		fExitCode,-1
			;Check if file exists
			invoke GetFileAttributes,addr buffer2
			.if eax==-1
				mov		fExitCode,eax
				invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset Errors
				invoke FindErrors
			.else
				.if fClear==1 || fClear==3
					invoke SendMessage,hOut,EM_REPLACESEL,FALSE,offset MakeDone
				.endif
				mov		fExitCode,0
			.endif
		.endif
		.if dword ptr [ErrID]
			invoke SendMessage,hWnd,WM_COMMAND,IDM_EDIT_NEXTERROR,0
		.else
			invoke SendMessage,hOut,EM_SCROLLCARET,0,0
			invoke SetFocus,hOut
		.endif
	.endif
  Ex:
	invoke LoadCursor,0,IDC_ARROW
	invoke SetCursor,eax
	mov		eax,fExitCode
	ret

OutputMake endp

