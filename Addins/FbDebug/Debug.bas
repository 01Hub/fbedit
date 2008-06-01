
#Include "debug.bi"

Declare Sub showcontext()
Declare Sub seteip(ad As UInteger)
Declare Sub decoupudt(As String)
Declare Sub decoup2(As String,As Byte)
Declare Function decouparray(As String,As Integer,As Byte) As Integer
Declare Sub findthread(As UInteger)
Declare Sub shcudt(As UShort,As UInteger)
Declare Function shvar(As UShort,As Any Ptr, As UByte) As String
Declare Function decoupscp(As Byte) As Integer

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
	WriteFile(hFile,lpBuff,1024*128,@wr,NULL)
	CloseHandle(hFile)

End Sub

Sub readstab()

	If ReadProcessMemory(dbghand,Cast(Any Ptr,basestab),@recupstab,12,0)=0 Then
		PutString(StrPtr("error reading memory"))
	End If

End Sub

Sub readstabs(ad As UInteger)

	If ReadProcessMemory(dbghand,Cast(Any Ptr,ad+basestabs),@recup,1000,0)=0 Then
		PutString(StrPtr("error reading memory"))
	End If

End Sub

Function decoupnames(strg As String) As String
	Dim As Integer p,d
	Dim As String nm,strg2,nm2

	strg2=Mid(strg,5,999)
	p=Val(strg2)
	If p>9 Then d=3 Else d=2
	nm=Mid(strg2,d,p)
	strg2=Mid(strg2,d+p,999)
	p=Val(strg2)
	If p>9 Then d=3 Else d=2
	nm2=Mid(strg2,d,p)
	Return "NS : "+nm+"."+nm2

End Function

Function decoupproc(strg As String) As String
	Dim As Integer p,d
	Dim As String nm,strg2,nm2

	If Left(strg,3)<>"__Z" Then Return strg
	If strg[3]=Asc("N") Then
		strg2=Mid(strg,5,999)
		p=Val(strg2)
		If p>9 Then d=3 Else d=2
		nm=Mid(strg2,d,p)
		strg2=Mid(strg2,d+p,999)
		p=Val(strg2)
		If p Then
			If p>9 Then d=3 Else d=2
			nm2=Mid(strg2,d,p)
			p=InStr(nm2,"__get__")
			If p Then
				Return "Get property : "+nm+"."+Left(nm2,p-1)
			Else
				p=InStr(nm2,"__set__")
				If p Then
					Return "Set property : "+nm+"."+Left(nm2,p-1)
				Else
					Return "Function : "+nm+"."+nm2
				EndIf
			EndIf
		Else
			Select Case Left(strg2,2)
				Case "cv"
					strg2=Mid(strg2,3,999)
					p=Val(strg2)
					If p>9 Then d=3 Else d=2
					Return "Cast : "+nm+"-->"+Mid(strg2,d,p)
				Case "C1"
					Return "Constructor : "+nm
				Case "D1"
					Return "Destructor : "+nm
				Case Else
					Return "Unknown"+strg2
			End Select
		EndIf
	Else 'operator
		Return "Operator : "+strg
	EndIf
	
End Function

Sub decoup2(gv As String,f As Byte)
	Dim p As Integer=1,c As UShort,e As Integer,gv2 As String

	If InStr(gv,"=")=0 Then
		If f=TYUDT Then
			cudt(cudtnb).typ=Val(Mid(gv,p,999))
		Else
			vrb(vrbnb).typ=Val(Mid(gv,p,999))
		End If
	Else
		If InStr(gv,"=ar1") Then p=decouparray(gv,InStr(gv,"=ar1")+1,f)
		gv2=Mid(gv,p,999)
		For p=0 To Len(gv)-1
			If gv2[p]=Asc("*") Then c+=1
			If gv2[p]=Asc("=") Then e=p+1
		Next 
		If c Then 'pointer
			If InStr(gv2,"=f") Then 'procedure
				If InStr(gv2,"=f7") Then
					p=200+c 'sub
				Else
					p=220+c 'function
				EndIf
			Else
				p=c
				e+=1
			End If
		Else
			p=0
		End If
		If f=TYUDT Then
			cudt(cudtnb).pt=p
			cudt(cudtnb).typ=Val(Mid(gv2,e+1,999))
		Else
			vrb(vrbnb).pt=p
			vrb(vrbnb).typ=Val(Mid(gv2,e+1,999))
		End If
	EndIf 

End Sub

Sub decoupudt(readl As String)
	Dim As UShort p,q
	Dim As String tnm

	p=InStr(readl,":")
	tnm=Left(readl,p-1)
	p+=3
	q=InStr(readl,"=")
	udtidx=Val(Mid(readl,p,q-p))
	udt(udtidx).nm=tnm
	p=q+2
	q=p-1
	While readl[q]<64
		q+=1
	Wend
	q+=1
	udt(udtidx).lg=Val(Mid(readl,p,q-p))
	p=q
	udt(udtidx).lb=cudtnb+1
	While readl[p-1]<>Asc(";")
		cudtnb+=1
		q=InStr(p,readl,":")
		cudt(cudtnb).nm=Mid(readl,p,q-p) 'variable name
		p=q+1
		q=InStr(p,readl,",")
		decoup2(Mid(readl,p,q-p),TYUDT) 'variable type
		p=q+1
		q=InStr(p,readl,",")
		cudt(cudtnb).ofs=Val(Mid(readl,p,q-p))\8  'offset début
		p=q+1
		q=InStr(p,readl,";")
		'Val(Mid(readl,p,q-p))	'lenght in bits, not used
		p=q+1 
	Wend
	udt(udtidx).ub=cudtnb

End Sub

Sub decoup(gv As String)
	Dim p As Integer

	If InStr(gv,"=-") Or Left(gv,8)="string:t" Or Left(gv,7)="pchar:t" Then Exit Sub
	If gv[0]=Asc(":") Then 'return value
		'dbgprint ("type return value x "+Mid(gv,2,999))
		Exit Sub
	End If
	If InStr(gv,";;") Then 'defined type or redim var
		If InStr(gv,":Tt") Then
			ttyp=TYUDT 'UDT
			decoupudt(gv)
		Else
			ttyp=TYRDM 'REDIM
			vrbnb+=1:vrb(vrbnb).nm=Left(gv,InStr(gv,":")-1) 'var ou parametre
			vrb(vrbnb).arr=Cast(Any Ptr,recupstab.ad)
			proc(procnb+1).vr=vrbnb+1 'just to have the next beginning
			decoupscp(gv[InStr(gv,":")])'first caracter after ":"
			'indiquer position de ";;"+1 pour recherche du type
			decoup2(Mid(gv,InStr(gv,";;")+2,999),ttyp)
		EndIf
	Else
		ttyp=TYDIM 'DIM
		vrbnb+=1
		If Left(gv,4)="__ZN" And InStr(gv,":") Then
			vrb(vrbnb).nm=decoupnames(gv) 'namespace
		Else
			vrb(vrbnb).nm=Left(gv,InStr(gv,":")-1) 'var ou parametre
		End If
		proc(procnb+1).vr=vrbnb+1 'just to have the next beginning
		p=decoupscp(gv[InStr(gv,":")])'first caracter after ":"
		decoup2(Mid(gv,InStr(gv,":")+p,999),ttyp)
	EndIf

End Sub

Function decoupscp(gv As Byte) As Integer

	Select Case gv
		Case Asc("S")	  'shared
			vrb(vrbnb).mem=1
			Return 2
		Case Asc("V")	  'static
			vrb(vrbnb).mem=2
			Return 2
		Case Asc("v")	  'byref parameter
			vrb(vrbnb).mem=3
			Return 2
		Case Asc("p")	  'byval parameter
			vrb(vrbnb).mem=4
			Return 2
		Case Else			'local
			vrb(vrbnb).mem=5
			Return 1
	End Select	

End Function

Function decouparray(gv As String,d As Integer,f As Byte) As Integer
	Dim As Integer p=d,q,c

	While gv[p-1]=Asc("a") 
		p+=4 'skip ar1
		q=InStr(p,gv,";")
		If f=TYDIM Then
			arrnb+=1:arr(arrnb).nlu(c).lb=Val(Mid(gv,p,q-p)) 'lbound
		Else
			audtnb+=1
			audt(audtnb).nlu(c).lb=Val(Mid(gv,p,q-p))
			cudt(cudtnb).arr=audtnb
		End If
		p=q+1
		q=InStr(p,gv,";")
		If f=TYDIM Then 
			arr(arrnb).nlu(c).ub=Val(Mid(gv,p,q-p))'ubound
			arr(arrnb).nlu(c).nb=arr(arrnb).nlu(c).ub-arr(arrnb).nlu(c).lb+1 'dim
		Else
			audt(audtnb).nlu(c).ub=Val(Mid(gv,p,q-p))
			audt(audtnb).nlu(c).nb=audt(audtnb).nlu(c).ub-audt(audtnb).nlu(c).lb
		End If
		p=q+1
		c+=1
	Wend
	If f=TYDIM Then
		arr(arrnb).dmn=c 'nb dim
		vrb(vrbnb).arr=@arr(arrnb)
	Else
		audt(audtnb).dm=c
	End If
	Return p

End Function

Sub seteip(ad As UInteger)
	Dim vcontext As CONTEXT

	vcontext.contextflags=CONTEXT_CONTROL
	GetThreadContext(Cast(HANDLE,threadcontext),@vcontext)
	procsk=vcontext.ebp
	vcontext.Eip=ad
	SetThreadContext(Cast(HANDLE,threadcontext),@vcontext)

End Sub

Sub gestbrk(ad As UInteger)
	Dim i As UInteger

	i=linesav+1
	proccurad=ad
	If rline(i).ad<>ad Then
		For i=1 To linenb
			If rline(i).ad=ad Then Exit For
		Next
		If i>linenb Then Print "Starting press space":Exit Sub
	End If
	If linesav<>0 Then WriteProcessMemory(dbghand,Cast(Any Ptr,rLine(linesav).ad),@breakvalue,1,0) 'restore CC previous line
	linesav=i
	WriteProcessMemory(dbghand,Cast(Any Ptr,rLine(i).ad),@rLine(i).sv,1,0) 'restore old value for execution
	'showcontext
	seteip(ad)
	'showcontext
	If procrsk>procsk Then
		procrnb+=1'new proc ATTENTION ADD A POSSIBILITY TO INCREASE THIS ARRAY
		procrsk=procsk
		procr(procrnb).sk=procrsk
		procsv=rline(i).pr
		procr(procrnb).sk=procrsk
		procr(procrnb).idx=procsv
		'add manage LIST
		PutString("NEW proc "+proc(procsv).nm)
	ElseIf procrsk<procsk Then
		procrsk=procsk'previous proc
		procsv=rline(i).pr
		procrnb-=1
		'planned to suppress LIST
		PutString("RETURN proc"+proc(procsv).nm)
	EndIf
	'INTEGRATION FOLLOWING LINES ABOVE ???
	'dbgprint (Str(won)+" Current line "+Str(rLine(i).nu)+" : "+Left(sourceline(proc(procsv).sr,rLine(i).nu),55))
End Sub

Sub findthread(tid As UInteger)
	Dim i As Byte

	For i=0 To threadnb 'if msg from thread then flag off
		If tid=threadid(i) Then threadcontext=thread(i):threadres(i)=0 :Exit Sub
	Next

End Sub

Function RunFile StdCall (ByVal lpFileName As ZString Ptr) As Integer
	Dim sinfo As STARTUPINFO
	Dim lret As Integer
	Dim de As DEBUG_EVENT
	Dim lpCREATE_PROCESS_DEBUG_INFO As CREATE_PROCESS_DEBUG_INFO Ptr
	Dim lpLOAD_DLL_DEBUG_INFO As LOAD_DLL_DEBUG_INFO Ptr
	Dim lpEXCEPTION_DEBUG_INFO As EXCEPTION_DEBUG_INFO Ptr
	Dim lpOUTPUT_DEBUG_STRING_INFO As OUTPUT_DEBUG_STRING_INFO Ptr
	Dim buffer As ZString*1024*128
	Dim ba As Integer
	Dim rd As Integer
	Dim hFile As HANDLE

	sinfo.cb=SizeOf(STARTUPINFO)
	'GetStartupInfo(@sinfo)
	sinfo.dwFlags=STARTF_USESHOWWINDOW
	sinfo.wShowWindow=SW_NORMAL
	' Create process
	lret=CreateProcess(NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,@sinfo,@pinfo)
	If lret Then
		WaitForSingleObject pinfo.hProcess, 10
		dbghand=OpenProcess(PROCESS_ALL_ACCESS,TRUE,pinfo.dwProcessId)
		'beginning of section area
		pe=&h400086
		ReadProcessMemory(dbghand,Cast(Any Ptr,pe),@secnb,2,0)
		pe=&h400178
		For i As UShort =1 To secnb
			secnm=String(8,0) 'Init var
			'read 8 bytes max name size
			ReadProcessMemory(dbghand,Cast(Any Ptr,pe),@secnm,8,0)
			PutString(StrPtr(secnm))
			If secnm=".stab" Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,pe+12),@basestab,4,0)
			ElseIf secnm=".stabstr" Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,pe+12),@basestabs,4,0)
			EndIf
			pe+=40
		Next
		basestab+=&h400000+12
		basestabs+=&h400000
		While TRUE
			readstab()
			If recupstab.code=0 Then Exit While
			If recupstab.stabs Then
				readstabs(recupstab.stabs)
				Select Case recupstab.code
					Case 36 'proc
						procfg=1:procad=recupstab.ad:procnb+=1:proc(procnb).sr=sourceix
						proc(procnb).ad=recupstab.ad
						proc(procnb).nm=decoupproc(Left(recup,InStr(recup,":")-1))
						  proc(procnb).rv=Val(Mid(recup,InStr(recup,":F")+2,5)) 'return value
					Case 38 'init var
						decoup(recup):vrb(vrbnb).adr=recupstab.ad
					Case 40 'uninit var
						decoup(recup):vrb(vrbnb).adr=recupstab.ad			  
					Case 100
						Print "Main Source : ";recup
						source(0)+=recup:sourceix=0
					Case 128 'local
						decoup(recup):If recupstab.ad Then vrb(vrbnb).adr=recupstab.ad 'stack offset
					Case 130 'include RAS
					Case 132 'include
						Print "Include : ";recup
						sourcenb+=1:source(sourcenb)=recup:sourceix=sourcenb' ????? Utilité :sourcead(sourcenb)=recupstab.ad
					Case 160 'parameter
						 decoup(recup):vrb(vrbnb).adr=recupstab.ad
					Case 42 'main RAS
					Case Else
						Print "UNKNOWN ";recupstab.code;recupstab.stabs;recupstab.nline,recupstab.ad;" ";recup
				End Select
			Else
				Select Case recupstab.code
					Case 68
						If recupstab.ad Then 'avoid to stop on sub or function line
							'print "line : ";recupstab.nline;" offset adr :";recupstab.ad;" -> ";procad+recupstab.ad
							PutString("Line: " & Str(recupstab.nline))
							linenb+=1:rline(linenb).ad=recupstab.ad+procad:rLine(linenb).nu=recupstab.nline:rLine(linenb).pr=procnb
							ReadProcessMemory(dbghand,Cast(Any Ptr,recupstab.ad+procad),@rLine(linenb).sv,1,0) 'sav 1 byte before writing &CC
							'Breakpoint
							If recupstab.nline=6 Or recupstab.nline=8 Then
								WriteProcessMemory(dbghand,Cast(Any Ptr,recupstab.ad+procad),@breakvalue,1,0)
							EndIf 
						End If
						'print linesv(linenb)
						'ReadProcessMemory(dbghand,recupstab.ad+procad,@linesv(linenb),1,0)
						'print linesv(linenb):sleep
					Case 192
						If procfg Then
							''print "Begin.block proc";recupstab.ad+procad
							procfg=0:proc(procnb).db=recupstab.ad+procad
						Else
							''print "Begin. of block"					
						End If
					Case 224
						''print "End of block";recupstab.ad+procad
						procsv=recupstab.ad+procad
					Case 36
							''print "End of proc";procsv
							proc(procnb).fn=procsv
					Case 162
						'' print "End include"
						sourceix=0
					Case 100
						Exit While 'end of file
					Case Else
						Print "UNKNOWN ";recupstab.code;recupstab.stabs;recupstab.nline,recupstab.ad
				End Select
			End If
			basestab+=12
		Wend
		While TRUE
			lret=WaitForDebugEvent(@de,INFINITE)
			Select Case de.dwDebugEventCode
				Case EXCEPTION_DEBUG_EVENT
					lret=Cast(Integer,@de)
					lpEXCEPTION_DEBUG_INFO=Cast(EXCEPTION_DEBUG_INFO Ptr,lret+12)
					If lpEXCEPTION_DEBUG_INFO->ExceptionRecord.ExceptionAddress<&H70000000 Then
						PutString(StrPtr("EXCEPTION_DEBUG_EVENT"))
						PutString(Str(lpEXCEPTION_DEBUG_INFO->ExceptionRecord.ExceptionCode))
						PutString(Hex(lpEXCEPTION_DEBUG_INFO->ExceptionRecord.ExceptionAddress))
						PutString(Str(lpEXCEPTION_DEBUG_INFO->dwFirstChance))
						Select Case lpEXCEPTION_DEBUG_INFO->ExceptionRecord.ExceptionCode
							Case EXCEPTION_ACCESS_VIOLATION
							Case EXCEPTION_BREAKPOINT
								With de.Exception.ExceptionRecord
									findthread(de.dwThreadId)               
									'PRINT "adr : ";.ExceptionAddress 'value of instruction pointer when exception occurred	
									gestbrk(Cast(UInteger,.ExceptionAddress))
								End With
							Case EXCEPTION_DATATYPE_MISALIGNMENT
							Case EXCEPTION_SINGLE_STEP
							Case DBG_CONTROL_C
						End Select
						'ct.ContextFlags=CONTEXT_FULL
						'GetThreadContext(pinfo.hThread,@ct)
						'PutString("eip:" & Hex(ct.Eip))
						'PutString("CS:" & Hex(ct.SegCs))
						'PutString("DS:" & Hex(ct.SegDs))
						'PutString("ES:" & Hex(ct.SegEs))
						'PutString("esp:" & Hex(ct.Esp))
						'PutString("SS:" & Hex(ct.SegSs))
						'lret=@lpEXCEPTION_DEBUG_INFO->ExceptionRecord
						'PutString(Hex(lret))
						'lret=@lpEXCEPTION_DEBUG_INFO->dwFirstChance
						'PutString(Hex(lret))
						'ba=&H400000
						'lret=ReadProcessMemory(hOP,ba,@buffer,1024*96,@rd)
						'SaveDump(@buffer)
						SuspendThread(pinfo.hThread)
					EndIf
				Case CREATE_THREAD_DEBUG_EVENT
					PutString(StrPtr("CREATE_THREAD_DEBUG_EVENT"))
					With de.Createthread
						'Print "hthread ";.hthread
						threadnb+=1
						thread(threadnb)=Cast(UInteger,.hthread)
						threadid(threadnb)=de.dwThreadId
						threadres(threadnb)=99
						threadcontext=Cast(UInteger,.hthread)
						'Print "nb of thread";threadnb+1
						For i As Integer=0 To threadnb
							'Print i,thread(i),threadres(i)
						Next
						'Print "start adress";.lpStartAddress
					End With
				Case CREATE_PROCESS_DEBUG_EVENT
					PutString(StrPtr("CREATE_PROCESS_DEBUG_EVENT"))
					With de.CreateProcessInfo
						threadnb+=1
						thread(threadnb)=Cast(UInteger,.hthread)
						threadid(threadnb)=de.dwThreadId
						threadres(threadnb)=0
						threadcontext=Cast(UInteger,.hthread)
					End With
					lret=Cast(Integer,@de)
					lpCREATE_PROCESS_DEBUG_INFO=Cast(CREATE_PROCESS_DEBUG_INFO Ptr,lret+12)
					hFile=lpCREATE_PROCESS_DEBUG_INFO->hFile
					PutString("hFile:" & Str(lpCREATE_PROCESS_DEBUG_INFO->hFile))
					PutString("hProcess:" & Str(lpCREATE_PROCESS_DEBUG_INFO->hProcess))
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
					'ba=Cast(Integer,lpCREATE_PROCESS_DEBUG_INFO->lpBaseOfImage)
					'lret=ReadProcessMemory(hOP,ba,@buffer,65536,@rd)
					''ReadFile(lpCREATE_PROCESS_DEBUG_INFO->hFile,@buffer,32768,@rd,NULL)
					'SaveDump(@buffer)
					''HexDump(@buffer,lpCREATE_PROCESS_DEBUG_INFO->nDebugInfoSize)
					''PutString("lret:" & Str(lret))
					''PutString("Error:" & Str(GetLastError()))
					'PutString("Bytes read:" & Str(rd))
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
					lret=ReadProcessMemory(dbghand,lpOUTPUT_DEBUG_STRING_INFO->lpDebugStringData,@buffer,256,@rd)
					PutString(@buffer)
				Case RIP_EVENT
					PutString(StrPtr("RIP_EVENT"))
			End Select
			ContinueDebugEvent(de.dwProcessId,de.dwThreadId,DBG_CONTINUE)
		Wend
		lret=CloseHandle(dbghand)
		PutString("dbghand: " & Str(lret))
		TerminateProcess(pinfo.hProcess,0)
		lret=CloseHandle(pinfo.hThread)
		PutString("pinfo.hThread:" & Str(lret))
		lret=CloseHandle(pinfo.hProcess)
		PutString("pinfo.hProcess " & Str(lret))
		lret=CloseHandle(hFile)
		PutString("hFile: " & Str(lret))
		lret=CloseHandle(hThread)
		PutString("hThread: " & Str(lret))
		hThread=0
	EndIf
	Return 0

End Function

