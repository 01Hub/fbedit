Sub PutString(ByVal lpStr As ZString Ptr)
	Dim chrg As CHARRANGE

	chrg.cpMin=-1
	chrg.cpMax=-1
	SendMessage(lpHandles->hout,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
	SendMessage(lpHandles->hout,EM_REPLACESEL,FALSE,Cast(LPARAM,lpStr))
	SendMessage(lpHandles->hout,EM_REPLACESEL,FALSE,Cast(LPARAM,@szCRLF))

End Sub

Sub HexDump(ByVal lpBuff As ZString Ptr,ByVal nSize As Integer)
	Dim sLine As ZString*256
	Dim i As Integer
	Dim j As Integer
	Dim ub As UByte
	For j=0 To 1023
		sLine=""
		For i=0 To 15
			ub=Peek(lpBuff)
			sLine=sline & Right("0" & Hex(ub) & " ",3)
			lpBuff=lpBuff+1
		Next
		PutString(sLine)
	Next

End Sub

Sub SaveDump(ByVal lpBuff As ZString Ptr)
	Dim hFile As HANDLE
	Dim wr As Integer

	hFile=CreateFile(@"dump.bin",GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL)
	WriteFile(hFile,lpBuff,65536,@wr,NULL)
	CloseHandle(hFile)

End Sub

Function RunFile StdCall (ByVal lpFileName As ZString Ptr) As Integer
	Dim sinfo As STARTUPINFO
	Dim pinfo As PROCESS_INFORMATION
	Dim lret As Integer
	Dim de As DEBUG_EVENT
	Dim lpCREATE_PROCESS_DEBUG_INFO As CREATE_PROCESS_DEBUG_INFO Ptr
	Dim lpLOAD_DLL_DEBUG_INFO As LOAD_DLL_DEBUG_INFO Ptr
	Dim lpEXCEPTION_DEBUG_INFO As EXCEPTION_DEBUG_INFO Ptr
	Dim lpOUTPUT_DEBUG_STRING_INFO As OUTPUT_DEBUG_STRING_INFO Ptr
	Dim buffer As ZString*1024*64
	Dim ba As Integer
	Dim rd As Integer
	Dim hOP As HANDLE
	Dim hFile As HANDLE

	sinfo.cb=SizeOf(STARTUPINFO)
	GetStartupInfo(@sinfo)
	sinfo.dwFlags=STARTF_USESHOWWINDOW+STARTF_USESTDHANDLES
	sinfo.wShowWindow=SW_SHOW
	' Create process
	lret=CreateProcess(NULL,lpFileName,NULL,NULL,FALSE,DEBUG_PROCESS,NULL,NULL,@sinfo,@pinfo)
	hOP=OpenProcess(PROCESS_ALL_ACCESS,TRUE,pinfo.dwProcessId)
	While TRUE
		lret=WaitForDebugEvent(@de,INFINITE)
		Select Case de.dwDebugEventCode
			Case EXCEPTION_DEBUG_EVENT
				PutString(StrPtr("EXCEPTION_DEBUG_EVENT"))
				lret=Cast(Integer,@de)
				lpEXCEPTION_DEBUG_INFO=Cast(EXCEPTION_DEBUG_INFO Ptr,lret+12)
				PutString(Str(lpEXCEPTION_DEBUG_INFO->ExceptionRecord.ExceptionCode))
				PutString(Hex(lpEXCEPTION_DEBUG_INFO->ExceptionRecord.ExceptionAddress))
				PutString(Str(lpEXCEPTION_DEBUG_INFO->dwFirstChance))
				'lret=@lpEXCEPTION_DEBUG_INFO->ExceptionRecord
				'PutString(Hex(lret))
				'lret=@lpEXCEPTION_DEBUG_INFO->dwFirstChance
				'PutString(Hex(lret))
			Case CREATE_THREAD_DEBUG_EVENT
				PutString(StrPtr("CREATE_THREAD_DEBUG_EVENT"))
			Case CREATE_PROCESS_DEBUG_EVENT
				PutString(StrPtr("CREATE_PROCESS_DEBUG_EVENT"))
				lret=Cast(Integer,@de)
				lpCREATE_PROCESS_DEBUG_INFO=Cast(CREATE_PROCESS_DEBUG_INFO Ptr,lret+12)
				hFile=lpCREATE_PROCESS_DEBUG_INFO->hFile
				PutString("hFile:" & Str(lpCREATE_PROCESS_DEBUG_INFO->hFile))
				PutString("hProcess:" & Str(lpCREATE_PROCESS_DEBUG_INFO->hProcess))
				PutString("hOP:" & Str(hOP))
	
				PutString("hThread:" & Str(lpCREATE_PROCESS_DEBUG_INFO->hThread))
				PutString("lpBaseOfImage:" & Hex(lpCREATE_PROCESS_DEBUG_INFO->lpBaseOfImage))
				PutString("dwDebugInfoFileOffset:" & Hex(lpCREATE_PROCESS_DEBUG_INFO->dwDebugInfoFileOffset))
				PutString("nDebugInfoSize:" & Str(lpCREATE_PROCESS_DEBUG_INFO->nDebugInfoSize))
				PutString("lpThreadLocalBase:" & Hex(lpCREATE_PROCESS_DEBUG_INFO->lpThreadLocalBase))
				PutString("lpStartAddress:" & Hex(lpCREATE_PROCESS_DEBUG_INFO->lpStartAddress))
				PutString("lpImageName:" & Hex(lpCREATE_PROCESS_DEBUG_INFO->lpImageName))
				PutString("fUnicode:" & Str(lpCREATE_PROCESS_DEBUG_INFO->fUnicode))
				'ba=lpCREATE_PROCESS_DEBUG_INFO->lpBaseOfImage+lpCREATE_PROCESS_DEBUG_INFO->dwDebugInfoFileOffset
				'ba=lpCREATE_PROCESS_DEBUG_INFO->lpStartAddress
				'lret=ReadProcessMemory(h,ba,@buffer,lpCREATE_PROCESS_DEBUG_INFO->nDebugInfoSize,@rd)
				ba=Cast(Integer,lpCREATE_PROCESS_DEBUG_INFO->lpBaseOfImage)
				lret=ReadProcessMemory(hOP,ba,@buffer,65536,@rd)
				'ReadFile(lpCREATE_PROCESS_DEBUG_INFO->hFile,@buffer,32768,@rd,NULL)
				SaveDump(@buffer)
				'HexDump(@buffer,lpCREATE_PROCESS_DEBUG_INFO->nDebugInfoSize)
				'PutString("lret:" & Str(lret))
				'PutString("Error:" & Str(GetLastError()))
				PutString("Bytes read:" & Str(rd))
			Case EXIT_THREAD_DEBUG_EVENT
				PutString(StrPtr("EXIT_THREAD_DEBUG_EVENT"))
			Case EXIT_PROCESS_DEBUG_EVENT
				PutString(StrPtr("EXIT_PROCESS_DEBUG_EVENT"))
				lret=ContinueDebugEvent(de.dwProcessId,de.dwThreadId,DBG_CONTINUE)
				PutString("ContinueDebugEvent: " & Str(lret))
				Exit While
			Case LOAD_DLL_DEBUG_EVENT
				PutString(StrPtr("LOAD_DLL_DEBUG_EVENT"))
				lret=Cast(Integer,@de)
				lpLOAD_DLL_DEBUG_INFO=Cast(LOAD_DLL_DEBUG_INFO Ptr,lret+12)
				GetModuleFileName(lpCREATE_PROCESS_DEBUG_INFO->hProcess,@buffer,256)
				PutString(@buffer)
			Case UNLOAD_DLL_DEBUG_EVENT
				PutString(StrPtr("UNLOAD_DLL_DEBUG_EVENT"))
			Case OUTPUT_DEBUG_STRING_EVENT
				PutString(StrPtr("OUTPUT_DEBUG_STRING_EVENT"))
				lret=Cast(Integer,@de)
				lpOUTPUT_DEBUG_STRING_INFO=Cast(OUTPUT_DEBUG_STRING_INFO Ptr,lret+12)
				PutString(Hex(lpOUTPUT_DEBUG_STRING_INFO->lpDebugStringData))
				lret=ReadProcessMemory(hOP,lpOUTPUT_DEBUG_STRING_INFO->lpDebugStringData,@buffer,256,@rd)
				PutString(@buffer)
			Case RIP_EVENT
				PutString(StrPtr("RIP_EVENT"))
		End Select
		ContinueDebugEvent(de.dwProcessId,de.dwThreadId,DBG_CONTINUE)
	Wend
	lret=CloseHandle(hOP)
	PutString("h: " & Str(lret))
	TerminateProcess(pinfo.hProcess,0)
	lret=CloseHandle(pinfo.hThread)
	PutString("pinfo.hThread:" & Str(lret))
	lret=CloseHandle(pinfo.hProcess)
	PutString("pinfo.hProcess " & Str(lret))
	lret=CloseHandle(hFile)
	PutString("hFile: " & Str(lret))
	lret=CloseHandle(hThread)
	PutString("hThread: " & Str(lret))
	Return 0

End Function

