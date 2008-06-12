
#Include "debug.bi"

Declare Sub showcontext()
Declare Sub seteip(ad As UInteger)
Declare Sub decoupudt(As String)
Declare Sub decoup2(As String,As Byte)
Declare Function decouparray(As String,As Integer,As Byte) As Integer
Declare Sub findthread(As UInteger)
Declare Function decoupscp(As Byte) As Integer

Sub PutString(ByVal lpStr As ZString Ptr)
	Dim chrg As CHARRANGE

	chrg.cpMin=-1
	chrg.cpMax=-1
	SendMessage(lpHandles->hout,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
	SendMessage(lpHandles->hout,EM_REPLACESEL,FALSE,Cast(LPARAM,lpStr))
	SendMessage(lpHandles->hout,EM_REPLACESEL,FALSE,Cast(LPARAM,@szCRLF))

End Sub

'Sub HexDump(ByVal lpBuff As ZString Ptr,ByVal nSize As Integer)
'	Dim sLine As ZString*256
'	Dim i As Integer
'	Dim j As Integer
'	Dim ub As UByte
'	For j=0 To 1023
'		sLine=""
'		For i=0 To 15
'			ub=Peek(lpBuff)
'			sLine=sline & Right("0" & Hex(ub) & " ",3)
'			lpBuff=lpBuff+1
'		Next
'		PutString(sLine)
'	Next
'
'End Sub
'
'Sub SaveDump(ByVal lpBuff As ZString Ptr)
'	Dim hFile As HANDLE
'	Dim wr As Integer
'
'	hFile=CreateFile(@"dump.bin",GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL)
'	WriteFile(hFile,lpBuff,1024*128,@wr,NULL)
'	CloseHandle(hFile)
'
'End Sub
'
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
	Else
		'operator
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
		If InStr(gv,"=ar1") Then
			p=decouparray(gv,InStr(gv,"=ar1")+1,f)
		EndIf
		gv2=Mid(gv,p,999)
		For p=0 To Len(gv)-1
			If gv2[p]=Asc("*") Then
				c+=1
			EndIf
			If gv2[p]=Asc("=") Then
				e=p+1
			EndIf
		Next 
		If c Then
			'pointer
			If InStr(gv2,"=f") Then
				'procedure
				If InStr(gv2,"=f7") Then
					'sub
					p=200+c
				Else
					'function
					p=220+c
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
		'variable name
		cudt(cudtnb).nm=Mid(readl,p,q-p)
		p=q+1
		q=InStr(p,readl,",")
		'variable type
		decoup2(Mid(readl,p,q-p),TYUDT)
		p=q+1
		q=InStr(p,readl,",")
		'offset début
		cudt(cudtnb).ofs=Val(Mid(readl,p,q-p))\8
		p=q+1
		q=InStr(p,readl,";")
		'Val(Mid(readl,p,q-p))	'lenght in bits, not used
		p=q+1 
	Wend
	udt(udtidx).ub=cudtnb

End Sub

Sub decoup(gv As String)
	Dim p As Integer

	If InStr(gv,"=-") Or Left(gv,8)="string:t" Or Left(gv,7)="pchar:t" Then
		Exit Sub
	EndIf
	If gv[0]=Asc(":") Then 'return value
		'dbgprint ("type return value x "+Mid(gv,2,999))
		Exit Sub
	End If
	If InStr(gv,";;") Then
		'defined type or redim var
		If InStr(gv,":Tt") Then
			'UDT
			ttyp=TYUDT
			decoupudt(gv)
		Else
			'REDIM
			ttyp=TYRDM
			'var ou parametre
			vrbnb+=1:vrb(vrbnb).nm=Left(gv,InStr(gv,":")-1)
			vrb(vrbnb).arr=Cast(Any Ptr,recupstab.ad)
			'just to have the next beginning
			proc(procnb+1).vr=vrbnb+1
			'first caracter after ":"
			decoupscp(gv[InStr(gv,":")])
			'indiquer position de ";;"+1 pour recherche du type
			decoup2(Mid(gv,InStr(gv,";;")+2,999),ttyp)
		EndIf
	Else
		'DIM
		ttyp=TYDIM
		vrbnb+=1
		If Left(gv,4)="__ZN" And InStr(gv,":") Then
			'namespace
			vrb(vrbnb).nm=decoupnames(gv)
		Else
			vrb(vrbnb).nm=Left(gv,InStr(gv,":")-1) 'var ou parametre
		End If
		'just to have the next beginning
		proc(procnb+1).vr=vrbnb+1
		'first caracter after ":"
		p=decoupscp(gv[InStr(gv,":")])
		decoup2(Mid(gv,InStr(gv,":")+p,999),ttyp)
	EndIf
	'PutString(vrb(vrbnb).nm)

End Sub

Function decoupscp(gv As Byte) As Integer

	Select Case gv
		Case Asc("S")
			'shared
			vrb(vrbnb).mem=1
			vrb(vrbnb).pn=-procnb
			Return 2
		Case Asc("V")
			'static
			vrb(vrbnb).mem=2
			vrb(vrbnb).pn=-procnb
			Return 2
		Case Asc("v")
			'byref parameter
			vrb(vrbnb).mem=3
			vrb(vrbnb).pn=-procnb
			Return 2
		Case Asc("p")
			'byval parameter
			vrb(vrbnb).mem=4
			vrb(vrbnb).pn=-procnb
			Return 2
		Case Else
			'local
			vrb(vrbnb).mem=5
			vrb(vrbnb).pn=-procnb
			Return 1
	End Select	

End Function

Function decouparray(gv As String,d As Integer,f As Byte) As Integer
	Dim As Integer p=d,q,c

	While gv[p-1]=Asc("a")
		'skip ar1
		p+=4
		q=InStr(p,gv,";")
		If f=TYDIM Then
			arrnb+=1
			'lbound
			arr(arrnb).nlu(c).lb=Val(Mid(gv,p,q-p))
		Else
			audtnb+=1
			audt(audtnb).nlu(c).lb=Val(Mid(gv,p,q-p))
			cudt(cudtnb).arr=audtnb
		End If
		p=q+1
		q=InStr(p,gv,";")
		If f=TYDIM Then 
			'ubound
			arr(arrnb).nlu(c).ub=Val(Mid(gv,p,q-p))
			'dim
			arr(arrnb).nlu(c).nb=arr(arrnb).nlu(c).ub-arr(arrnb).nlu(c).lb+1
		Else
			audt(audtnb).nlu(c).ub=Val(Mid(gv,p,q-p))
			audt(audtnb).nlu(c).nb=audt(audtnb).nlu(c).ub-audt(audtnb).nlu(c).lb
		End If
		p=q+1
		c+=1
	Wend
	If f=TYDIM Then
		'nb dim
		arr(arrnb).dmn=c
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

Sub SetBreakPoints(ByVal nLnRunTo As Integer)
	Dim As Integer i,j,bpinx
	Dim sln As String

	For i=1 To linenb
		If rLine(i).sv=-1 And i<>linesav Then
			For bpinx=0 To bpnb
				If UCase(bp(bpinx).sFile)=UCase(source(proc(rline(i).pr).sr)) Then
					sln="," & Str(rLine(i).nu-1) & ","
					If InStr(bp(bpinx).sBP,sln) Then
						rLine(i).sv=0
						'save 1 byte before writing &CC
						ReadProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@rLine(i).sv,1,0)
						'Breakpoint
						WriteProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@breakvalue,1,0)
					EndIf
				EndIf
			Next
			If rline(i).nu-1=nLnRunTo And rLine(i).sv=-1 Then
				If UCase(lpData->filename)=UCase(source(proc(rline(i).pr).sr)) Then
					rLine(i).sv=0
					'save 1 byte before writing &CC
					ReadProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@rLine(i).sv,1,0)
					'Breakpoint
					WriteProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@breakvalue,1,0)
				EndIf
			EndIf
		EndIf
	Next
	fRun=0

End Sub

Sub SetBreakAll()
	Dim i As Integer

	For i=1 To linenb
		If rLine(i).sv=-1 Then
			rLine(i).sv=0
			'save 1 byte before writing &CC
			ReadProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@rLine(i).sv,1,0)
			'Breakpoint
			WriteProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@breakvalue,1,0)
		EndIf
	Next

End Sub

Sub ClearBreakAll(ByVal nNotProc As Integer)
	Dim i As Integer

	For i=1 To linenb
		If rLine(i).sv<>-1 And rline(i).pr<>nNotProc Then
			'restore 1 byte
			WriteProcessMemory(dbghand,Cast(Any Ptr,rline(i).ad),@rLine(i).sv,1,0)
			rLine(i).sv=-1
		EndIf
	Next

End Sub

Sub gestbrk(ad As UInteger)
	Dim As UInteger i,bpinx
	Dim chrg As CHARRANGE

	i=linesav+1
	proccurad=ad
	If rline(i).ad<>ad Then
		For i=1 To linenb
			If rline(i).ad=ad Then
				Exit For
			EndIf
		Next
		If i>linenb Then
			'Print "Starting press space"
			Exit Sub
		EndIf
	End If
	If linesav<>0 Then
		rLine(linesav).sv=0
		'save 1 byte before writing &CC
		ReadProcessMemory(dbghand,Cast(Any Ptr,rline(linesav).ad),@rLine(linesav).sv,1,0)
		'restore CC previous line
		WriteProcessMemory(dbghand,Cast(Any Ptr,rLine(linesav).ad),@breakvalue,1,0)
	EndIf
	linesav=i
	SetBreakAll
	If rline(i).sv<>-1 Then
		'restore old value for execution
		WriteProcessMemory(dbghand,Cast(Any Ptr,rLine(i).ad),@rLine(i).sv,1,0)
		rline(i).sv=-1
	EndIf
	'showcontext
	seteip(ad)
	'showcontext
	If procrsk>procsk Then
		'new proc ATTENTION ADD A POSSIBILITY TO INCREASE THIS ARRAY
		procrnb+=1
		procrsk=procsk
		ebp_this=procsk
		procr(procrnb).sk=procrsk
		procsv=rline(i).pr
		procr(procrnb).sk=procrsk
		procr(procrnb).idx=procsv
		'add manage LIST
		'PutString("NEW proc "+proc(procsv).nm)
	ElseIf procrsk<procsk Then
		'previous proc
		procrsk=procsk
		ebp_this=procsk
		procsv=rline(i).pr
		procrnb-=1
		'planned to suppress LIST
		'PutString("RETURN proc "+proc(procsv).nm)
	EndIf
	'INTEGRATION FOLLOWING LINES ABOVE ???
	'dbgprint (Str(won)+" Current line "+Str(rLine(i).nu)+" : "+Left(sourceline(proc(procsv).sr,rLine(i).nu),55))
	If fRun Then
		ClearBreakAll(0)
		SetBreakPoints(0)
	Else
		For bpinx=0 To bpnb
			'PutString(source(proc(procsv).sr))
			'PutString(bp(bpinx).sFile)
			If UCase(bp(bpinx).sFile)=UCase(source(proc(procsv).sr)) Then
				szFileName=bp(bpinx).sFile
				'PutString(szFileName)
				PostMessage(lpHandles->hwnd,AIM_OPENFILE,0,Cast(LPARAM,@szFileName))
				WaitForSingleObject(pinfo.hProcess,100)
				nLnDebug=rLine(i).nu-1
				hLnDebug=lpHandles->hred
				chrg.cpMin=SendMessage(hLnDebug,EM_LINEINDEX,nLnDebug,0)
				chrg.cpMax=chrg.cpMin
				SendMessage(hLnDebug,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
				SendMessage(hLnDebug,EM_SCROLLCARET,0,0)
				SendMessage(hLnDebug,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
				SendMessage(hLnDebug,REM_SETHILITELINE,nLnDebug,2)
				SuspendThread(pinfo.hThread)
				Exit For
			EndIf
		Next
	EndIf

End Sub

Sub findthread(tid As UInteger)
	Dim i As Byte

	'if msg from thread then flag off
	For i=0 To threadnb
		If tid=threadid(i) Then
			threadcontext=thread(i)
			threadres(i)=0
			Exit Sub
		EndIf
	Next

End Sub

Sub ClearVars()
	Dim As Integer i,j

	secnb=0
	pe=0
	basestab=0
	basestabs=0
	recup=String(1000,0)
	procnb=0
	procfg=0
	procsv=0
	procad=0
	procin=0
	procsk=0
	proccurad=0
	proc(1).vr=1
	procrnb=0
	procrsk=4294967295'current proc stack
	sourceix=0
	sourcenb=0
	ttyp=0
	udtidx=0
	cudtnb=0
	audtnb=0
	vrbnb=0
	linenb=0
	linesav=0
	arrnb=0
	threadcontext=0
	threadnb=0
	nLnDebug=-1
	hLnDebug=0

	For i=0 To PROCMAX
		proc(i).nm=""
		proc(i).db=0
		proc(i).fn=0
		proc(i).sr=0
		proc(i).ad=0
		proc(i).vr=0
		proc(i).rv=0
		proc(i).nu=0
	Next
	For i=0 To PROCRMAX
		procr(i).sk=0
		procr(i).idx=0
	Next
	For i=16 To TYPEMAX
		udt(i).nm=""
		udt(i).lb=0
		udt(i).ub=0
		udt(i).lg=0
	Next
	For i=0 To CTYPEMAX
		cudt(i).nm=""
		cudt(i).Typ=0
		cudt(i).ofs=0
		cudt(i).arr=0
		cudt(i).pt=0
	Next
	For i=0 To ATYPEMAX
		audt(i).dm=0
		For j=0 To 5
			audt(i).nlu(j).nb=0
			audt(i).nlu(j).lb=0
			audt(i).nlu(j).ub=0
		Next
	Next
	For i=0 To SOURCEMAX
		source(i)=""
	Next
	For i=0 To VARMAX
		vrb(i).nm=""
		vrb(i).typ=0
		vrb(i).adr=0
		vrb(i).mem=0
		vrb(i).arr=0
		vrb(i).pt=0
		vrb(i).pn=0
	Next
	For i=0 To ARRMAX
		arr(i).dat=0
		arr(i).pot=0
		arr(i).siz=0
		arr(i).dmn=0
		For j=0 To 5
			arr(i).nlu(j).nb=0
			arr(i).nlu(j).lb=0
			arr(i).nlu(j).ub=0
		Next
	Next
	For i=0 To LINEMAX
		rline(i).ad=0
		rline(i).nu=0
		rline(i).sv=0
		rline(i).pr=0
	Next
	For i=0 To THREADMAX
		thread(i)=0
		threadid(i)=0
		threadres(i)=0
	Next

End Sub

Function RunFile StdCall (ByVal lpFileName As ZString Ptr) As Integer
	Dim sinfo As STARTUPINFO
	Dim As Integer lret,fContinue
	Dim de As DEBUG_EVENT
	Dim buffer As ZString*256
	Dim As UShort i,j
	Dim sException As String

	ClearVars
	sinfo.cb=SizeOf(STARTUPINFO)
	'GetStartupInfo(@sinfo)
	sinfo.dwFlags=STARTF_USESHOWWINDOW
	sinfo.wShowWindow=SW_NORMAL
	' Create process
	lret=CreateProcess(NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,@sinfo,@pinfo)
	If lret Then
		WaitForSingleObject(pinfo.hProcess,10)
		dbghand=OpenProcess(PROCESS_ALL_ACCESS,TRUE,pinfo.dwProcessId)
		'beginning of section area
		pe=&h400086
		ReadProcessMemory(dbghand,Cast(Any Ptr,pe),@secnb,2,0)
		pe=&h400178
		For i=1 To secnb
			'Init var
			secnm=String(8,0)
			'read 8 bytes max name size
			ReadProcessMemory(dbghand,Cast(Any Ptr,pe),@secnm,8,0)
			If secnm=".stab" Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,pe+12),@basestab,4,0)
			ElseIf secnm=".stabstr" Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,pe+12),@basestabs,4,0)
			EndIf
			pe+=40
		Next
		If basestab Then
			basestab+=&h400000+12
			basestabs+=&h400000
			While TRUE
				readstab()
				If recupstab.code=0 Then
					Exit While
				EndIf
				If recupstab.stabs Then
					readstabs(recupstab.stabs)
					Select Case recupstab.code
						Case 36
							'proc
							procfg=1
							procad=recupstab.ad:procnb+=1
							proc(procnb).sr=sourceix
							proc(procnb).ad=recupstab.ad
							proc(procnb).nm=decoupproc(Left(recup,InStr(recup,":")-1))
							'return value
							proc(procnb).rv=Val(Mid(recup,InStr(recup,":F")+2,5))
							proc(procnb).nu=recupstab.nline
						Case 38
							'init var
							decoup(recup)
							vrb(vrbnb).adr=recupstab.ad
						Case 40
							'uninit var
							decoup(recup)
							vrb(vrbnb).adr=recupstab.ad			  
						Case 100
							'PutString("Main Source: " & Str(recup))
							source(0)+=recup:sourceix=0
							i=1
							While i
								i=InStr(i,source(0),"/")
								If i Then
									source(0)[i-1]=Asc("\")
								EndIf
							Wend
						Case 128
							'local
							decoup(recup)
							If recupstab.ad Then
								'stack offset
								vrb(vrbnb).adr=recupstab.ad
							EndIf
						Case 130
							'include RAS
							'PutString("include RAS " & recup)
						Case 132
							'include
							'PutString("Include: " & Str(recup))
							sourcenb+=1
							source(sourcenb)=recup
							sourceix=sourcenb' ????? Utilité :sourcead(sourcenb)=recupstab.ad
							i=1
							While i
								i=InStr(i,source(sourcenb),"/")
								If i Then
									source(sourcenb)[i-1]=Asc("\")
								EndIf
							Wend
						Case 160
							'parameter
							 decoup(recup)
							 vrb(vrbnb).adr=recupstab.ad
						Case 42
							'main RAS
							'PutString("main RAS " & recup)
						Case Else
							PutString("UNKNOWN ")';recupstab.code;recupstab.stabs;recupstab.nline,recupstab.ad;" ";recup
					End Select
				Else
					Select Case recupstab.code
						Case 68
							If recupstab.ad Then 'avoid to stop on sub or function line
								'print "line : ";recupstab.nline;" offset adr :";recupstab.ad;" -> ";procad+recupstab.ad
								'PutString("Line: " & Str(recupstab.nline))
								linenb+=1
								rline(linenb).ad=recupstab.ad+procad
								rLine(linenb).nu=recupstab.nline
								rLine(linenb).pr=procnb
								rLine(linenb).sv=-1
							End If
						Case 192
							If procfg Then
								''print "Begin.block proc";recupstab.ad+procad
								procfg=0
								proc(procnb).db=recupstab.ad+procad
							Else
								''print "Begin. of block"					
							End If
							'PutString("Begin. of block" & rLine(linenb).nu)
						Case 224
							''print "End of block";recupstab.ad+procad
							procsv=recupstab.ad+procad
							'PutString("End of block" & rLine(linenb).nu)
						Case 36
							''print "End of proc";procsv
							proc(procnb).fn=procsv
						Case 162
							'' print "End include"
							sourceix=0
						Case 100
							Exit While 'end of file
						Case Else
							PutString("UNKNOWN " & recupstab.code & "," & recupstab.stabs & "," & recupstab.nline & "," & recupstab.ad)
					End Select
				End If
				basestab+=12
			Wend
			' To handle variables with the same name but of different type
			For i=1 To vrbnb
				For j=i+1 To vrbnb
					If vrb(i).nm=vrb(j).nm Then
						vrb(i).pn=Abs(vrb(i).pn)
						vrb(j).pn=Abs(vrb(j).pn)
					EndIf
				Next
			Next
			PutString("Main Source: " & source(0))
			GetBreakPoints
			SetBreakPoints(0)
		Else
			PutString("No debug info found. Compile with the -g option.")
		EndIf
'		For i=1 To vrbnb
'			PutString(vrb(i).nm)
'		Next
'		For i=1 To udtidx
'			PutString("i: " & i & " " & udt(i).nm & " lb: " & udt(i).lb & " ub: " & udt(i).ub & " lg: " & udt(i).lg)
'		Next
'		For i=1 To cudtnb
'			PutString("i: " & i & " " & cudt(i).nm & " Typ: " & cudt(i).Typ & " ofs: " & cudt(i).ofs & " arr: " & cudt(i).arr & " pt: " & cudt(i).pt)
'		Next
'		For i=1 To audtnb
'			PutString("i: " & i & " dm: " & audt(i).dm & " nlu.nb: " & audt(i).nlu(0).nb)
'		Next
		While TRUE
			lret=WaitForDebugEvent(@de,INFINITE)
			fContinue=DBG_CONTINUE
			Select Case de.dwDebugEventCode
				Case EXCEPTION_DEBUG_EVENT
'					If de.Exception.ExceptionRecord.ExceptionAddress<&H70000000 Then
						Select Case de.Exception.ExceptionRecord.ExceptionCode
							Case EXCEPTION_BREAKPOINT
								If fExit=0 Then
									findthread(de.dwThreadId)
									'PRINT "adr : ";de.Exception.ExceptionRecord.ExceptionAddress 'value of instruction pointer when exception occurred	
									gestbrk(Cast(UInteger,de.Exception.ExceptionRecord.ExceptionAddress))
								Else
									'WriteProcessMemory(dbghand,de.Exception.ExceptionRecord.ExceptionAddress,@breakvalue,1,0)
									fContinue=DBG_EXCEPTION_NOT_HANDLED
								EndIf
							Case EXCEPTION_ACCESS_VIOLATION
								sException="EXCEPTION_ACCESS_VIOLATION"
								fContinue=DBG_EXCEPTION_NOT_HANDLED
							Case EXCEPTION_FLT_DIVIDE_BY_ZERO
								sException="EXCEPTION_FLT_DIVIDE_BY_ZERO"
								fContinue=DBG_EXCEPTION_NOT_HANDLED
							Case EXCEPTION_INT_DIVIDE_BY_ZERO
								sException="EXCEPTION_INT_DIVIDE_BY_ZERO"
								fContinue=DBG_EXCEPTION_NOT_HANDLED
							Case EXCEPTION_DATATYPE_MISALIGNMENT
								sException="EXCEPTION_DATATYPE_MISALIGNMENT"
								fContinue=DBG_EXCEPTION_NOT_HANDLED
							Case EXCEPTION_SINGLE_STEP
								sException="EXCEPTION_SINGLE_STEP"
								fContinue=DBG_EXCEPTION_NOT_HANDLED
							Case DBG_CONTROL_C
								sException="DBG_CONTROL_C"
								fContinue=DBG_EXCEPTION_NOT_HANDLED
						End Select
						If fContinue=DBG_EXCEPTION_NOT_HANDLED Then
							If de.Exception.dwFirstChance Then
								If fexit=0 Then
									PutString(sException)
									findthread(de.dwThreadId)
									gestbrk(Cast(UInteger,de.Exception.ExceptionRecord.ExceptionAddress))
								EndIf
							EndIf
						EndIf
'					EndIf
				Case CREATE_THREAD_DEBUG_EVENT
					'PutString(StrPtr("CREATE_THREAD_DEBUG_EVENT"))
					With de.CreateThread
						'Print "hthread ";.hthread
						threadnb+=1
						thread(threadnb)=Cast(UInteger,.hThread)
						threadid(threadnb)=de.dwThreadId
						threadres(threadnb)=99
						
						threadcontext=Cast(UInteger,.hThread)
						'Print "nb of thread";threadnb+1
						For i As Integer=0 To threadnb
							'Print i,thread(i),threadres(i)
						Next
						'Print "start adress";.lpStartAddress
					End With
				Case CREATE_PROCESS_DEBUG_EVENT
					'PutString("CREATE_PROCESS_DEBUG_EVENT")
					With de.CreateProcessInfo
						threadnb+=1
						thread(threadnb)=Cast(UInteger,.hThread)
						threadid(threadnb)=de.dwThreadId
						threadres(threadnb)=0
						threadcontext=Cast(UInteger,.hThread)
						hDebugFile=.hFile
					End With
				Case EXIT_THREAD_DEBUG_EVENT
					PutString(StrPtr("EXIT_THREAD_DEBUG_EVENT"))
				Case EXIT_PROCESS_DEBUG_EVENT
					PutString(StrPtr("EXIT_PROCESS_DEBUG_EVENT"))
					lret=ContinueDebugEvent(de.dwProcessId,de.dwThreadId,DBG_CONTINUE)
					If fExit Then
						PutString("Terminated by user.")
					EndIf
					Exit While
				Case LOAD_DLL_DEBUG_EVENT
					GetModuleFileName(de.LoadDll.lpBaseOfDll,@buffer,256)
					PutString("LOAD_DLL_DEBUG_EVENT " & buffer)
				Case UNLOAD_DLL_DEBUG_EVENT
					PutString(StrPtr("UNLOAD_DLL_DEBUG_EVENT"))
				Case OUTPUT_DEBUG_STRING_EVENT
					'PutString(StrPtr("OUTPUT_DEBUG_STRING_EVENT"))
					lret=ReadProcessMemory(dbghand,de.DebugString.lpDebugStringData,@buffer,255,0)
					PutString(@buffer)
				Case RIP_EVENT
					PutString(StrPtr("RIP_EVENT"))
			End Select
			ContinueDebugEvent(de.dwProcessId,de.dwThreadId,fContinue)
		Wend
		lret=CloseHandle(dbghand)
		lret=CloseHandle(pinfo.hThread)
		lret=CloseHandle(pinfo.hProcess)
		lret=CloseHandle(hDebugFile)
		lret=CloseHandle(hThread)
		hThread=0
		lpData->fDebug=FALSE
		LockFiles(FALSE)
		ClearVars
		EnableDebugMenu
	EndIf
	Return 0

End Function
