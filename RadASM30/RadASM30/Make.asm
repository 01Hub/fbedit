
MAKEEXE struct
	hThread		DWORD ?
	hRead		DWORD ?
	hWrite		DWORD ?
	pInfo		PROCESS_INFORMATION <?>
	uExit		DWORD ?
	buffer		BYTE MAX_PATH*2 dup(?)
	cmd			BYTE MAX_PATH dup(?)
	cmdline		BYTE MAX_PATH dup(?)
MAKEEXE ends

.data

MakeDone				BYTE 0Dh,'Make done.',0Dh,0
Errors					BYTE 0Dh,'Error(s) occured.',0Dh,0
Terminated				BYTE 0Dh,'Terminated by user.',0
NoRC					BYTE 0Dh,'No .rc file found.',0Dh,0
Exec					BYTE 0Dh,'Executing:',0
NoDel					BYTE 0Dh,'Could not delete:',0Dh,0

CreatePipeError			BYTE 'Error during pipe creation',0
CreateProcessError		BYTE 'Error during process creation',0Dh,0Ah,0

.data?

makeexe					MAKEEXE <>
nErrID					DWORD ?
ErrID					DWORD 128 dup(?)

.code

MakeThreadProc proc uses ebx,Param:DWORD
	LOCAL	sat:SECURITY_ATTRIBUTES
	LOCAL	startupinfo:STARTUPINFO
	LOCAL	bytesRead:DWORD
	LOCAL	buffer[256]:BYTE

	invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCr
	.if Param==IDM_MAKE_RUN
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.cmd
		.if makeexe.cmdline
			invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr szSpc
			invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.cmdline
		.endif
	.else
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.buffer
	.endif
	invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCr
	invoke SendMessage,ha.hOutput,EM_SCROLLCARET,0,0
	.if Param==IDM_MAKE_RUN
		invoke ShellExecute,ha.hWnd,NULL,addr makeexe.cmd,addr makeexe.cmdline,NULL,SW_SHOWNORMAL
		.if eax>=32
			xor		eax,eax
		.endif
	.else
		mov sat.nLength,sizeof SECURITY_ATTRIBUTES
		mov sat.lpSecurityDescriptor,NULL
		mov sat.bInheritHandle,TRUE
		invoke CreatePipe,addr makeexe.hRead,addr makeexe.hWrite,addr sat,NULL
		.if eax==NULL
			;CreatePipe failed
			invoke LoadCursor,0,IDC_ARROW
			invoke SetCursor,eax
			invoke MessageBox,ha.hWnd,addr CreatePipeError,addr DisplayName,MB_ICONERROR+MB_OK
			xor		eax,eax
		.else
			mov startupinfo.cb,sizeof STARTUPINFO
			invoke GetStartupInfo,addr startupinfo
			mov eax,makeexe.hWrite
			mov startupinfo.hStdOutput,eax
			mov startupinfo.hStdError,eax
			mov startupinfo.dwFlags,STARTF_USESHOWWINDOW+STARTF_USESTDHANDLES
			mov startupinfo.wShowWindow,SW_HIDE
			;Create process
			invoke CreateProcess,NULL,addr makeexe.buffer,NULL,NULL,TRUE,NULL,NULL,NULL,addr startupinfo,addr makeexe.pInfo
			.if eax==NULL
				;CreateProcess failed
				invoke CloseHandle,makeexe.hRead
				invoke CloseHandle,makeexe.hWrite
				invoke LoadCursor,0,IDC_ARROW
				invoke SetCursor,eax
				invoke strcpy,addr buffer,addr CreateProcessError
				invoke strcat,addr buffer,addr makeexe.buffer
				invoke MessageBox,ha.hWnd,addr buffer,addr DisplayName,MB_ICONERROR+MB_OK
				xor		eax,eax
			.else
				invoke CloseHandle,makeexe.hWrite
				invoke RtlZeroMemory,addr makeexe.buffer,sizeof makeexe.buffer
				xor		ebx,ebx
				.while TRUE
					invoke ReadFile,makeexe.hRead,addr makeexe.buffer[ebx],1,addr bytesRead,NULL
					.if eax==NULL
						.if ebx
							call	OutputText
						.endif
						.break
					.else
						.if makeexe.buffer[ebx]==0Ah || ebx==511
							call	OutputText
						.else
							inc		ebx
						.endif
					.endif
				.endw
				invoke GetExitCodeProcess,makeexe.pInfo.hProcess,addr makeexe.uExit
				invoke CloseHandle,makeexe.hRead
				invoke CloseHandle,makeexe.pInfo.hProcess
				invoke CloseHandle,makeexe.pInfo.hThread
				mov		eax,TRUE
			.endif
		.endif
	.endif
	invoke ExitThread,eax
	ret

OutputText:
	mov		makeexe.buffer[ebx+1],0
	invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.buffer
	invoke SendMessage,ha.hOutput,EM_SCROLLCARET,0,0
	xor		ebx,ebx
	retn

MakeThreadProc endp

FindErrors proc uses ebx
	LOCAL	buffer[512]:BYTE
	LOCAL	nLn:DWORD
	LOCAL	nLnErr:DWORD
	LOCAL	nLastLnErr:DWORD
	LOCAL	nErr:DWORD

	invoke SendMessage,ha.hOutput,EM_GETLINECOUNT,0,0
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
	invoke SendMessage,ha.hOutput,EM_GETLINE,nLn,addr buffer
	mov		byte ptr buffer[eax],0
	invoke iniInStr,addr buffer,addr szError
	.if eax!=-1
		.while eax && byte ptr buffer[eax]!='('
			dec		eax
		.endw
		mov		byte ptr buffer[eax],0
		invoke DecToBin,addr buffer[eax+1]
		dec		eax
		.if eax!=nLastLnErr
			mov		nLnErr,eax
			mov		nLastLnErr,eax
			invoke strlen,addr buffer
			.while eax && word ptr buffer[eax+1]!='\:'
				dec		eax
			.endw
			invoke strcpy,addr buffer,addr buffer[eax]
			invoke GetCurrentDirectory,MAX_PATH,addr tmpbuff
			invoke strcat,addr tmpbuff,addr szBS
			invoke strcat,addr tmpbuff,addr buffer
			invoke strcpy,addr buffer,addr tmpbuff
;			invoke GetFullPathName,addr tmpbuff,sizeof buffer,addr buffer,NULL
			invoke GetFileAttributes,addr buffer
			.if eax!=INVALID_HANDLE_VALUE && !(eax & FILE_ATTRIBUTE_DIRECTORY)
				invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
				.if eax==-1
					invoke OpenTheFile,addr buffer,0
				.endif
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE
						invoke SendMessage,ha.hOutput,REM_SETBOOKMARK,nLn,6
						invoke SendMessage,ha.hOutput,REM_GETBMID,nLn,0
						mov		nErr,eax
						invoke SendMessage,ha.hEdt,REM_SETERROR,nLnErr,nErr
						mov		eax,nErr
						mov		ErrID[ebx*4],eax
						inc		ebx
					.endif
				.endif
			.endif
		.endif
	.endif
	retn

FindErrors endp

OutputMake proc uses ebx esi edi,nCommand:DWORD,fClear:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer2[MAX_PATH]:BYTE
	LOCAL	fExitCode:DWORD
	LOCAL	ThreadID:DWORD
	LOCAL	msg:MSG
	LOCAL	fHide:DWORD

	invoke RtlZeroMemory,addr makeexe,sizeof MAKEEXE
	;Get relative pointer to selected build command
	invoke SendMessage,ha.hCboBuild,CB_GETCURSEL,0,0
	mov		edx,sizeof MAKE
	mul		edx
	mov		esi,eax
	invoke SetOutputTab,0
	invoke ShowOutput,TRUE
	mov		fHide,eax
	.if da.fProject
		invoke SetCurrentDirectory,addr da.szProjectPath
	.else
		invoke strcpy,addr buffer,addr da.szMainAsm
		invoke RemoveFileName,addr buffer
		invoke SetCurrentDirectory,addr buffer
	.endif
	mov		fExitCode,0
	mov		ThreadID,0
	invoke SetFocus,ha.hOutput
	.if fClear==1 || fClear==2
		invoke SendMessage,ha.hOutput,WM_SETTEXT,0,addr makeexe.buffer
		invoke SendMessage,ha.hOutput,EM_SCROLLCARET,0,0
	.endif
	mov		eax,nCommand
	.if eax==IDM_MAKE_COMPILE
		invoke strcpy,addr makeexe.buffer,addr da.szCompileRC
		invoke strcat,addr makeexe.buffer,addr szSpc
		.if !da.make.szCompileRC[esi]
			invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset NoRC
			invoke SendMessage,ha.hOutput,EM_SCROLLCARET,0,0
			jmp		Ex
		.endif
		invoke strcat,addr makeexe.buffer,addr da.make.szCompileRC[esi]
		invoke strcat,addr makeexe.buffer,addr szSpc
		invoke strcat,addr makeexe.buffer,offset szQuote
		invoke strcat,addr makeexe.buffer,addr da.szMainRC
		invoke strcat,addr makeexe.buffer,offset szQuote
		mov		edi,offset da.szMainRC
		lea		eax,da.make.szOutCompileRC[esi]
		call	MakeIt
	.elseif eax==IDM_MAKE_ASSEMBLE
		invoke strcpy,addr makeexe.buffer,addr da.szAssemble
		invoke strcat,addr makeexe.buffer,addr szSpc
		invoke strcat,addr makeexe.buffer,addr da.make.szAssemble[esi]
		invoke strcat,addr makeexe.buffer,addr szSpc
		invoke strcat,addr makeexe.buffer,offset szQuote
		invoke strcat,addr makeexe.buffer,addr da.szMainAsm
		invoke strcat,addr makeexe.buffer,offset szQuote
		mov		edi,offset da.szMainAsm
		lea		eax,da.make.szOutAssemble[esi]
		call	MakeIt
	.elseif eax==IDM_MAKE_MODULES
		xor		ebx,ebx
		.while TRUE
			invoke SendMessage,ha.hProjectBrowser,RPBM_FINDNEXTITEM,ebx,0
			.break .if !eax
			mov		ebx,[eax].PBITEM.id
			.if [eax].PBITEM.flag==FLAG_MODULE
				mov		edi,eax
				invoke strcpy,addr makeexe.buffer,addr da.szAssemble
				invoke strcat,addr makeexe.buffer,addr szSpc
				invoke strcat,addr makeexe.buffer,addr da.make.szAssemble[esi]
				invoke strcat,addr makeexe.buffer,addr szSpc
				invoke strcat,addr makeexe.buffer,offset szQuote
				invoke RemovePath,addr [edi].PBITEM.szitem,addr da.szProjectPath,addr buffer2
				invoke strcat,addr makeexe.buffer,addr buffer2
				invoke strcat,addr makeexe.buffer,offset szQuote
				lea		edi,buffer2
				invoke strlen,edi
				.while byte ptr [edi+eax]!='\' && eax
					dec		eax
				.endw
				.if byte ptr [edi+eax]=='\'
					lea		edi,[edi+eax+1]
				.endif
				lea		eax,da.make.szOutAssemble[esi]
				call	MakeIt
				.break .if fExitCode
			.endif
		.endw
	.elseif eax==IDM_MAKE_LINK
		.if da.make.szLink[esi]
			invoke strcpy,addr makeexe.buffer,addr da.szLink
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,addr da.make.szLink[esi]
			.if da.szMainAsm
				invoke strcat,addr makeexe.buffer,addr szSpc
				invoke strcat,addr makeexe.buffer,offset szQuote
				invoke strcpy,addr buffer,addr da.szMainAsm
				invoke RemoveFileExt,addr buffer
				invoke strcat,addr buffer,addr da.make.szOutAssemble[esi]
				invoke strcat,addr makeexe.buffer,addr buffer
				invoke strcat,addr makeexe.buffer,offset szQuote
			.endif
			.if da.fProject
				;Add modules
				xor		ebx,ebx
				.while TRUE
					invoke SendMessage,ha.hProjectBrowser,RPBM_FINDNEXTITEM,ebx,0
					.break .if !eax
					mov		ebx,[eax].PBITEM.id
					.if [eax].PBITEM.flag==FLAG_MODULE
						mov		edi,eax
						invoke strcat,addr makeexe.buffer,addr szSpc
						invoke strcat,addr makeexe.buffer,offset szQuote
						invoke RemovePath,addr [edi].PBITEM.szitem,addr da.szProjectPath,addr buffer2
						invoke RemoveFileExt,addr buffer2
						invoke strlen,addr buffer2
						.while buffer2[eax]!='\' && eax
							dec		eax
						.endw
						lea		edi,buffer2
						.if buffer2[eax]=='\'
							lea		edi,buffer2[eax+1]
						.endif
						invoke strcat,edi,addr da.make.szOutAssemble[esi]
						invoke strcat,addr makeexe.buffer,edi
						invoke strcat,addr makeexe.buffer,offset szQuote
					.endif
				.endw
			.endif
			.if da.szMainRC
				invoke strcat,addr makeexe.buffer,addr szSpc
				invoke strcat,addr makeexe.buffer,offset szQuote
				invoke strcpy,addr buffer,addr da.szMainRC
				invoke RemoveFileExt,addr buffer
				invoke strcat,addr buffer,addr da.make.szOutCompileRC[esi]
				invoke strcat,addr makeexe.buffer,addr buffer
				invoke strcat,addr makeexe.buffer,offset szQuote
			.endif
			mov		edi,offset da.szMainAsm
			lea		eax,da.make.szOutLink[esi]
			call	MakeIt
		.elseif da.make.szLib[esi]
			invoke strcpy,addr makeexe.buffer,addr da.szLib
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,addr da.make.szLib[esi]
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,offset szQuote
			invoke strcat,addr makeexe.buffer,addr da.szMainAsm
			invoke strcat,addr makeexe.buffer,offset szQuote
			mov		edi,offset da.szMainAsm
			lea		eax,da.make.szOutLib[esi]
			call	MakeIt
		.endif
	.elseif eax==IDM_MAKE_RUN
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset Exec
		.if da.fCmdExe
			invoke strcpy,addr makeexe.cmd,addr da.szCmdExe
			invoke strcat,addr makeexe.cmd,addr szSpc
			xor		eax,eax
			.while makeexe.cmd[eax]!=' '
				inc		eax
			.endw
			mov		makeexe.cmd[eax],0
			invoke strcat,addr makeexe.cmdline,addr makeexe.cmd[eax+1]
			invoke strcat,addr makeexe.cmdline,addr szQuote
			invoke strcat,addr makeexe.cmdline,addr da.szMainAsm
			invoke RemoveFileExt,addr makeexe.cmdline
			invoke strcat,addr makeexe.cmdline,addr da.make.szOutLink[esi]
			.if da.szCommandLine
				invoke strcat,addr makeexe.cmdline,addr szSpc
				invoke strcat,addr makeexe.cmdline,addr da.szCommandLine
			.endif
			invoke strcat,addr makeexe.cmdline,addr szQuote
		.else
			invoke strcpy,addr makeexe.cmd,addr da.szMainAsm
			invoke RemoveFileExt,addr makeexe.cmd
			invoke strcat,addr makeexe.cmd,addr da.make.szOutLink[esi]
			.if da.szCommandLine
				invoke strcpy,addr makeexe.cmdline,addr da.szCommandLine
			.endif
		.endif
		xor		eax,eax
		call	MakeIt
	.else
		jmp		Ex
	.endif
	invoke LoadCursor,0,IDC_ARROW
	invoke SetCursor,eax
	.if ThreadID
		.if makeexe.uExit==1234
			invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset Terminated
			invoke FindErrors
		.else
			.if fExitCode
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset Errors
				invoke FindErrors
			.else
				.if fClear==1 || fClear==3
					invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset MakeDone
				.endif
			.endif
		.endif
		.if dword ptr [ErrID]
;			invoke SendMessage,ha.hWnd,WM_COMMAND,IDM_EDIT_NEXTERROR,0
		.else
			invoke SendMessage,ha.hOutput,EM_SCROLLCARET,0,0
			invoke SetFocus,ha.hOutput
		.endif
	.endif
  Ex:
	.if !fExitCode && fHide
		invoke ShowOutput,FALSE
	.endif
	mov		eax,fExitCode
	ret

MakeIt:
	mov		fExitCode,0
	.if eax
		;Delete old file
		push	eax
		invoke strcpy,addr buffer,edi
		invoke RemoveFileExt,addr buffer
		pop		eax
		invoke strcat,addr buffer,eax
		invoke GetFileAttributes,addr buffer
		.if eax!=INVALID_HANDLE_VALUE
			invoke DeleteFile,addr buffer
			.if !eax
				mov		fExitCode,-1
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset NoDel
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr buffer
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCr
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset Errors
				jmp		Ex
			.endif
		.endif
	.endif
	invoke CreateThread,NULL,NULL,addr MakeThreadProc,nCommand,NORMAL_PRIORITY_CLASS,addr ThreadID
	mov		makeexe.hThread,eax
	.while TRUE
		invoke GetExitCodeThread,makeexe.hThread,addr ThreadID
		.break .if ThreadID!=STILL_ACTIVE
		invoke GetMessage,addr msg,NULL,0,0
		mov		eax,msg.message
		.if eax!=WM_CHAR
			.if msg.wParam==VK_ESCAPE
				invoke TerminateProcess,makeexe.pInfo.hProcess,1234
			.endif
		.elseif eax!=WM_KEYDOWN && eax!=WM_CLOSE && (eax<WM_MOUSEFIRST || eax>WM_MOUSELAST)
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
		invoke LoadCursor,0,IDC_WAIT
		invoke SetCursor,eax
	.endw
	invoke CloseHandle,makeexe.hThread
	;Check if output file exists
	invoke GetFileAttributes,addr buffer
	.if eax==INVALID_HANDLE_VALUE
		mov		fExitCode,eax
	.endif
	retn

OutputMake endp

