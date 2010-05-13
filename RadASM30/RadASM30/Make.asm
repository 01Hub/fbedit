
MAKEEXE struct
	hThread		DWORD ?
	hRead		DWORD ?
	hWrite		DWORD ?
	pInfo		PROCESS_INFORMATION <?>
	uExit		DWORD ?
	buffer		BYTE MAX_PATH*2 dup(?)
	cmd			BYTE MAX_PATH dup(?)
	cmdline		BYTE MAX_PATH dup(?)
	output		BYTE MAX_PATH dup(?)
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

	invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCR
	.if Param==IDM_MAKE_RUN
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.cmd
		.if makeexe.cmdline
			invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr szSpc
			invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.cmdline
		.endif
	.else
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.buffer
	.endif
	invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCR
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

DeleteMinorFiles proc uses ebx esi edi

	.if da.fDelMinor
		;Get relative pointer to selected build command
		invoke SendMessage,ha.hCboBuild,CB_GETCURSEL,0,0
		mov		edx,sizeof MAKE
		mul		edx
		mov		esi,eax
		lea		edi,da.make.szOutAssemble[esi]
		mov		ebx,offset da.szMainAsm
		invoke iniInStr,edi,addr szDollarA
		.if eax==-1
			invoke strcpy,addr makeexe.output,edi
		.else
			push	esi
			mov		esi,eax
			invoke strcpyn,addr makeexe.output,edi,addr [esi+1]
			invoke strcat,addr makeexe.output,ebx
			invoke RemoveFileExt,addr makeexe.output
			invoke strcat,addr makeexe.output,addr [edi+esi+2]
			pop		esi
		.endif
		call	DeleteIt
		lea		edi,da.make.szOutLink[esi]
		invoke iniInStr,edi,addr szDotDll
		.if eax!=-1
			invoke iniInStr,edi,addr szDollarA
			.if eax==-1
				invoke strcpy,addr makeexe.output,edi
			.else
				push	esi
				mov		esi,eax
				invoke strcpyn,addr makeexe.output,edi,addr [esi+1]
				invoke strcat,addr makeexe.output,ebx
				pop		esi
			.endif
			invoke RemoveFileExt,addr makeexe.output
			invoke strcat,addr makeexe.output,addr szDotExp
			call	DeleteIt
			invoke RemoveFileExt,addr makeexe.output
			invoke strcat,addr makeexe.output,addr szDotLib
			call	DeleteIt
		.endif
		.if da.szMainRC
			lea		edi,da.make.szOutCompileRC[esi]
			mov		ebx,offset da.szMainRC
			invoke iniInStr,edi,addr szDollarR
			.if eax==-1
				invoke strcpy,addr makeexe.output,edi
			.else
				push	esi
				mov		esi,eax
				invoke strcpyn,addr makeexe.output,edi,addr [esi+1]
				invoke strcat,addr makeexe.output,ebx
				invoke RemoveFileExt,addr makeexe.output
				invoke strcat,addr makeexe.output,addr [edi+esi+2]
				pop		esi
			.endif
			call	DeleteIt
		.endif
	.endif
	ret

DeleteIt:
	invoke DeleteFile,addr makeexe.output
	.if eax
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szDeleted
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset makeexe.output
		invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCR
	.endif
	retn

DeleteMinorFiles endp

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
		lea		edi,da.make.szOutCompileRC[esi]
		mov		ebx,offset da.szMainRC
		call	SetOutputFile
		mov		eax,TRUE
		call	MakeIt
	.elseif eax==IDM_MAKE_ASSEMBLE
		invoke strcpy,addr makeexe.buffer,addr da.szAssemble
		invoke strcat,addr makeexe.buffer,addr szSpc
		invoke strcat,addr makeexe.buffer,addr da.make.szAssemble[esi]
		invoke strcat,addr makeexe.buffer,addr szSpc
		invoke strcat,addr makeexe.buffer,offset szQuote
		invoke strcat,addr makeexe.buffer,addr da.szMainAsm
		invoke strcat,addr makeexe.buffer,offset szQuote
		lea		edi,da.make.szOutAssemble[esi]
		mov		ebx,offset da.szMainAsm
		call	SetOutputFile
		mov		eax,TRUE
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
				push	ebx
				mov		ebx,edi
				lea		edi,da.make.szOutAssemble[esi]
				call	SetOutputFile
				mov		eax,TRUE
				call	MakeIt
				pop		ebx
				.break .if fExitCode
			.endif
		.endw
	.elseif eax==IDM_MAKE_LINK
		.if da.make.szLink[esi]
			invoke strcpy,addr makeexe.buffer,addr da.szLink
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,addr da.make.szLink[esi]
			invoke iniInStr,addr makeexe.buffer,addr szDollarD
			.if eax!=-1
				;Add .def file
				.if da.fProject
					xor		ebx,ebx
					.while TRUE
						invoke SendMessage,ha.hProjectBrowser,RPBM_FINDNEXTITEM,ebx,0
						.break .if !eax
						mov		edi,eax
						mov		ebx,[edi].PBITEM.id
						invoke strlen,addr [edi].PBITEM.szitem
						.if eax>4
							mov		eax,dword ptr [edi].PBITEM.szitem[eax-4]
							and		eax,5F5F5FFFh
							.if eax=='FED.'
								invoke strcpy,addr buffer,addr [edi].PBITEM.szitem
								invoke RemovePath,addr buffer,addr da.szProjectPath,addr tmpbuff[512]
								invoke iniInStr,addr makeexe.buffer,addr szDollarD
								mov		edi,eax
								invoke strcpyn,addr tmpbuff,addr makeexe.buffer,addr [edi+1]
								invoke strcat,addr tmpbuff,offset szQuote
								invoke strcat,addr tmpbuff,addr tmpbuff[512]
								invoke strcat,addr tmpbuff,offset szQuote
								invoke strcat,addr tmpbuff,addr makeexe.buffer[edi+2]
								invoke strcpy,addr makeexe.buffer,addr tmpbuff
								.break
							.endif
						.endif
					.endw
				.else
					invoke strcpy,addr buffer,addr da.szMainAsm
					invoke RemoveFileExt,addr buffer
					invoke strcat,addr buffer,addr szDotDef
					invoke iniInStr,addr makeexe.buffer,addr szDollarD
					mov		edi,eax
					invoke strcpyn,addr tmpbuff,addr makeexe.buffer,addr [edi+1]
					invoke strcat,addr tmpbuff,offset szQuote
					invoke strcat,addr tmpbuff,addr buffer
					invoke strcat,addr tmpbuff,offset szQuote
					invoke strcat,addr tmpbuff,addr makeexe.buffer[edi+2]
					invoke strcpy,addr makeexe.buffer,addr tmpbuff
				.endif
			.endif
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,offset szQuote
			lea		edi,da.make.szOutAssemble[esi]
			mov		ebx,offset da.szMainAsm
			call	SetOutputFile
			invoke strcat,addr makeexe.buffer,addr makeexe.output
			invoke strcat,addr makeexe.buffer,offset szQuote
			.if da.fProject
				;Add modules
				xor		ebx,ebx
				.while TRUE
					invoke SendMessage,ha.hProjectBrowser,RPBM_FINDNEXTITEM,ebx,0
					.break .if !eax
					mov		ebx,[eax].PBITEM.id
					.if [eax].PBITEM.flag==FLAG_MODULE
						push	ebx
						mov		edi,eax
						invoke strcat,addr makeexe.buffer,addr szSpc
						invoke strcat,addr makeexe.buffer,offset szQuote
						invoke strlen,addr [edi].PBITEM.szitem
						.while [edi].PBITEM.szitem[eax]!='\' && eax
							dec		eax
						.endw
						.if [edi].PBITEM.szitem[eax]=='\'
							inc		eax
						.endif
						lea		ebx,[edi].PBITEM.szitem[eax]
						lea		edi,da.make.szOutAssemble[esi]
						call	SetOutputFile
						invoke strcat,addr makeexe.buffer,addr makeexe.output
						invoke strcat,addr makeexe.buffer,offset szQuote
						pop		ebx
					.endif
				.endw
			.endif
			.if da.szMainRC
				invoke strcat,addr makeexe.buffer,addr szSpc
				invoke strcat,addr makeexe.buffer,offset szQuote
				lea		edi,da.make.szOutCompileRC[esi]
				mov		ebx,offset da.szMainRC
				call	SetOutputFile
				invoke strcat,addr makeexe.buffer,addr makeexe.output
				invoke strcat,addr makeexe.buffer,offset szQuote
			.endif
			lea		edi,da.make.szOutLink[esi]
			mov		ebx,offset da.szMainAsm
			call	SetOutputFile
			invoke iniInStr,addr makeexe.buffer,addr szDollarO
			.if eax!=-1
				mov		edi,eax
				invoke strcpyn,addr tmpbuff,addr makeexe.buffer,addr [edi+1]
				invoke strcat,addr tmpbuff,offset szQuote
				invoke strcat,addr tmpbuff,addr makeexe.output
				invoke strcat,addr tmpbuff,offset szQuote
				invoke strcat,addr tmpbuff,addr makeexe.buffer[edi+2]
				invoke strcpy,addr makeexe.buffer,addr tmpbuff
			.endif
			mov		eax,TRUE
			call	MakeIt
		.elseif da.make.szLib[esi]
			invoke strcpy,addr makeexe.buffer,addr da.szLib
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,addr da.make.szLib[esi]
			invoke strcat,addr makeexe.buffer,addr szSpc
			invoke strcat,addr makeexe.buffer,offset szQuote
			lea		edi,da.make.szOutAssemble[esi]
			mov		ebx,offset da.szMainAsm
			call	SetOutputFile
			invoke strcat,addr makeexe.buffer,addr makeexe.output
			invoke strcat,addr makeexe.buffer,offset szQuote
			lea		edi,da.make.szOutLib[esi]
			mov		ebx,offset da.szMainAsm
			call	SetOutputFile
			mov		eax,TRUE
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
			lea		edi,da.make.szOutLink[esi]
			mov		ebx,offset da.szMainAsm
			call	SetOutputFile
			invoke strcpy,addr makeexe.cmd,addr makeexe.output
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
					.if fClear==3
						invoke DeleteMinorFiles
					.endif
					invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset MakeDone
				.endif
			.endif
		.endif
		.if dword ptr [ErrID]
			invoke SendMessage,ha.hWnd,WM_COMMAND,IDM_EDIT_NEXTERROR,0
		.else
			invoke SendMessage,ha.hOutput,EM_SCROLLCARET,0,0
			invoke SetFocus,ha.hOutput
		.endif
	.endif
  Ex:
	.if !fExitCode
		.if fHide
			invoke ShowOutput,FALSE
		.endif
		.if ha.hMdi
			invoke SetFocus,ha.hEdt
		.endif
	.endif
	mov		eax,fExitCode
	ret

MakeIt:
	mov		fExitCode,0
	.if eax
		;Delete old file
		invoke GetFileAttributes,addr makeexe.output
		.if eax!=INVALID_HANDLE_VALUE
			invoke DeleteFile,addr makeexe.output
			.if !eax
				mov		fExitCode,-1
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset NoDel
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,addr makeexe.output
				invoke SendMessage,ha.hOutput,EM_REPLACESEL,FALSE,offset szCR
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
	invoke GetFileAttributes,addr makeexe.output
	.if eax==INVALID_HANDLE_VALUE
		mov		fExitCode,eax
	.endif
	retn

SetOutputFile:
	invoke iniInStr,edi,addr szDollarA
	.if eax==-1
		invoke iniInStr,edi,addr szDollarR
	.endif
	.if eax==-1
		invoke strcpy,addr makeexe.output,edi
	.else
		push	esi
		mov		esi,eax
		invoke strcpyn,addr makeexe.output,edi,addr [esi+1]
		invoke strcat,addr makeexe.output,ebx
		invoke RemoveFileExt,addr makeexe.output
		invoke strcat,addr makeexe.output,addr [edi+esi+2]
		pop		esi
	.endif
	retn

OutputMake endp

