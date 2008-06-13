#Include Once "windows.bi"
#Include Once "win/commctrl.bi"
#Include Once "win/richedit.bi"

#Include "..\..\..\..\..\Inc\RAEdit.bi"
#Include "..\..\..\..\..\Inc\Addins.bi"
#Include "..\..\..\..\..\Inc\RAProperty.bi"
#Include "FbDebug.bi"
#Include "Debug.bas"

Function MakeProjectFileName(ByVal sFile As String) As String
	Dim As ZString*260 sItem,sPath
	Dim As Integer x,y

	sItem=sFile
	sPath=lpData->ProjectPath
	Do While TRUE
		If Left(sItem,3)="..\" Then
			sItem=Mid(sItem,4)
			x=InStr(sPath,"\")
			y=x
			Do While x
				y=x
				x=InStr(x+1,sPath,"\")
			Loop
			sPath=Left(sPath,y-1)
		Else
			Exit Do
		EndIf
	Loop
	Return sPath & "\" & sItem

End Function

Function IsProjectFile(ByVal lpFile As ZString Ptr) As Integer
	Dim As Integer nInx,nMiss
	Dim sItem As ZString*260

	nInx=1
	nMiss=0
	Do While nInx<256 And nMiss<MAX_MISS
		sItem=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
		If Len(sItem) Then
			nMiss=0
			sItem=MakeProjectFileName(sItem)
			If lstrcmpi(@sItem,lpFile)=0 Then
				Return nInx
			EndIf
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop
	nInx=1001
	nMiss=0
	Do While nInx<1256 And nMiss<MAX_MISS
		sItem=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
		If Len(sItem) Then
			nMiss=0
			sItem=MakeProjectFileName(sItem)
			If lstrcmpi(@sItem,lpFile)=0 Then
				Return nInx
			EndIf
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop
	Return 0

End Function

Sub SaveBreakpoints(ByVal hWin As HWND,ByVal nInx As Integer)
	Dim buff As ZString*4096
	Dim nLn As Integer

	nLn=-1
	While TRUE
		nLn=SendMessage(hWin,REM_NXTBOOKMARK,nLn,5)
		If nLn<>-1 Then
			buff &="," & Str(nLn)
		Else
			WritePrivateProfileString("BreakPoint",Str(nInx),@buff[1],@lpData->ProjectFile)
			Exit While
		EndIf
	Wend
End Sub

Sub LoadBreakpoints(ByVal hWin As HWND,ByVal nInx As Integer)
	Dim buff As ZString*2048
	Dim As Integer nLn,x

	SendMessage(hWin,REM_CLRBOOKMARKS,0,5)
	GetPrivateProfileString("BreakPoint",Str(nInx),@szNULL,@buff,SizeOf(buff),@lpData->ProjectFile)
	While Len(buff)
		x=InStr(buff,",")
		If x Then
			nLn=Val(Left(buff,x-1))
			buff=Mid(buff,x+1)
		Else
			nLn=Val(buff)
			buff=""
		EndIf
		SendMessage(hWin,REM_SETBOOKMARK,nLn,5)
	Wend
End Sub

Function CheckBpLine(ByVal nLine As Integer,ByVal lpszFile As ZString Ptr) As Boolean
	Dim i As Integer

	nLine+=1
	For i=1 To linenb
		If rline(i).nu=nLine And UCase(*lpszFile)=UCase(source(proc(rline(i).pr).sr)) Then
			Return TRUE
		EndIf
	Next
	Return FALSE

End Function

Function CheckBpItems(ByVal lpszItems As ZString Ptr,ByVal lpszFile As ZString Ptr) As Integer
	Dim As Integer x,y,nLn,nAnt

	x=1
	y=1
	While x
		x=InStr(y,*lpszItems,",")
		If x Then
			nLn=Val(Mid(*lpszItems,y,5))
			y=x+1
		Else
			nLn=Val(Mid(*lpszItems,y,5))
		EndIf
		If CheckBpLine(nLn,lpszFile)=FALSE Then
			nAnt+=1
		EndIf
	Wend
	Return nAnt

End Function

Function CheckBreakPoints() As Integer
	Dim As Integer i,nInx,nMiss,nAnt
	Dim As ZString*260 szFile,szItem

	nInx=1
	nMiss=0
	Do While nInx<256 And nMiss<MAX_MISS
		szFile=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@szFile,SizeOf(szFile),@lpData->ProjectFile)
		If Len(szFile) Then
			nMiss=0
			szFile=MakeProjectFileName(szFile)
			GetPrivateProfileString(StrPtr("BreakPoint"),Str(nInx),@szNULL,@szItem,SizeOf(szItem),@lpData->ProjectFile)
			If Len(szItem) Then
				nAnt+=CheckBpItems(@szItem,@szFile)
			EndIf
			i+=1
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop
	nInx=1001
	nMiss=0
	Do While nInx<1256 And nMiss<MAX_MISS
		szFile=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@szFile,SizeOf(szFile),@lpData->ProjectFile)
		If Len(szFile) Then
			nMiss=0
			szFile=MakeProjectFileName(szFile)
			GetPrivateProfileString(StrPtr("BreakPoint"),Str(nInx),@szNULL,@szItem,SizeOf(szItem),@lpData->ProjectFile)
			If Len(szItem) Then
				nAnt+=CheckBpItems(@szItem,@szFile)
			EndIf
			i+=1
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop
	Return nAnt

End Function

Sub GetBreakPoints()
	Dim As Integer nInx,nMiss
	Dim sItem As ZString*260

	For bpnb=0 To SOURCEMAX
		bp(bpnb).nInx=0
		bp(bpnb).sFile=""
		bp(bpnb).sBP=""
	Next
	nMiss=CheckBreakPoints
	If nMiss Then
		MessageBox(lpHandles->hwnd,"There is " & Str(nMiss) & " unhandled breakpoint(s).","Debug",MB_OK Or MB_ICONINFORMATION)
	EndIf
	bpnb=0
	nInx=1
	nMiss=0
	Do While nInx<256 And nMiss<MAX_MISS
		sItem=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
		If Len(sItem) Then
			nMiss=0
			sItem=MakeProjectFileName(sItem)
			bp(bpnb).nInx=nInx
			bp(bpnb).sFile=sItem
			GetPrivateProfileString(StrPtr("BreakPoint"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
			If Len(sItem) Then
				bp(bpnb).sBP="," & sItem & ","
			EndIf
			bpnb+=1
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop
	nInx=1001
	nMiss=0
	Do While nInx<1256 And nMiss<MAX_MISS
		sItem=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
		If Len(sItem) Then
			nMiss=0
			sItem=MakeProjectFileName(sItem)
			bp(bpnb).nInx=nInx
			bp(bpnb).sFile=sItem
			GetPrivateProfileString(StrPtr("BreakPoint"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
			If Len(sItem) Then
				bp(bpnb).sBP="," & sItem & ","
			EndIf
			bpnb+=1
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop

End Sub

Sub CreateToolTip()

	hTip=CreateWindowEx(0,"tooltips_class32",NULL,TTS_NOPREFIX,0,0,0,0,NULL,0,hInstance,0)
	SendMessage(hTip,TTM_ACTIVATE,TRUE,0)
	SendMessage(hTip,TTM_SETDELAYTIME,TTDT_INITIAL,100)
	SendMessage(hTip,TTM_SETDELAYTIME,TTDT_AUTOPOP,5000)
	SendMessage(hTip,TTM_SETMAXTIPWIDTH,0,800)

End sub

Function GetArrayDim(ByVal lpArr As tarr Ptr) As String
	Dim n As Integer
	Dim s As String

	For n=0 To lpArr->dmn-1
		'PutString("siz: " & lpArr->siz & " dmn:" & lpArr->dmn & " nlu(n).nb: " & lpArr->nlu(n).nb & " nlu(n).lb: " & lpArr->nlu(n).lb & " nlu(n).ub: " & lpArr->nlu(n).ub)
		s=s & "," & Str(lpArr->nlu(n).lb) & " To " & Str(lpArr->nlu(n).ub)
	Next
	Return Mid(s,2)

End Function

Function GetUdtDim(ByVal lpArr As taudt Ptr) As String
	Dim n As Integer
	Dim s As String

	For n=0 To lpArr->dm-1
		'PutString("siz: " & lpArr->siz & " dmn:" & lpArr->dmn & " nlu(n).nb: " & lpArr->nlu(n).nb & " nlu(n).lb: " & lpArr->nlu(n).lb & " nlu(n).ub: " & lpArr->nlu(n).ub)
		s=s & "," & Str(lpArr->nlu(n).lb) & " To " & Str(lpArr->nlu(n).ub)
	Next
	Return Mid(s,2)

End Function

Function GetVar(ByVal typ As Integer,ByRef adr As UInteger,ByVal lpszNme As ZString Ptr,ByVal lpszBuff As ZString Ptr,ByVal dp As Integer) As String
	Dim bval As ZString*32, buff As ZString*128
	Dim i As Integer
	Dim lpArr As tarr Ptr

	Select Case typ
		Case 0
			' Proc
		Case 1
			' Integer
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
				buff=Str(Peek(Integer,@bval))
			EndIf
		Case 2
			' Byte
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
				buff=Str(Peek(Byte,@bval))
			EndIf
		Case 3
			' UByte
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
				buff=Str(Peek(UByte,@bval))
			EndIf
		Case 4
			' Char
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,65,0)
				If Len(buff)>64 Then
					buff=Left(buff,64) & "..."
				EndIf
				buff=Chr(34) & buff & Chr(34)
			EndIf
		Case 5
			' Short
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
				buff=Str(Peek(Short,@bval))
			EndIf
		Case 6
			' UShort
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
				buff=Str(Peek(UShort,@bval))
			EndIf
		Case 7
			' Void
			buff=""
		Case 8
			' UInteger
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
				buff=Str(Peek(UInteger,@bval))
			EndIf
		Case 9
			' Longint
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				buff=Str(Peek(LongInt,@bval))
			EndIf
		Case 10
			' ULongint
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				buff=Str(Peek(ULongInt,@bval))
			EndIf
		Case 11
			' Single
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
				buff=Str(Peek(Single,@bval))
			EndIf
		Case 12
			' Double
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				buff=Str(Peek(Double,@bval))
			EndIf
		Case 13
			' String
			If adr Then
				buff=String(66,0)
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
				adr=Peek(Integer,@bval)
				i=Peek(Integer,@bval+4)
				If adr>0 And i>0 Then
					If i>65 Then
						i=65
					EndIf
					ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,i,0)
					If Len(buff)>64 Then
						buff=Left(buff,64) & "..."
					EndIf
				EndIf
				buff=Chr(34) & buff & Chr(34)
			EndIf
		Case 14
			' ZString
			If adr Then
				ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,65,0)
				If Len(buff)>64 Then
					buff=Left(buff,64) & "..."
				EndIf
				buff=Chr(34) & buff & Chr(34)
			EndIf
		Case 15
			' PChar
			buff=""
		Case Else
			i=InStr(*lpszNme,".")
			If i Then
				buff=Left(*lpszNme,i-1)
				*lpszNme=Mid(*lpszNme,i+1)
			Else
				buff=*lpszNme
				*lpszNme=""
			EndIf
			For i=udt(typ).lb To udt(typ).ub
				If cudt(i).nm=buff Then
					If adr Then
						adr+=cudt(i).ofs
					EndIf
					' Array
					If cudt(i).arr Then
						lpArr=Cast(tarr Ptr,cudt(i).arr)
						'PutString("cudt(i).arr: " & cudt(i).arr)
						dp=InStr(dp+1,*lpszBuff,"(")
						*lpszBuff=Left(*lpszBuff,dp) & GetUdtDim(@audt(cudt(i).arr)) & Mid(*lpszBuff,dp+1)
					EndIf
					Return GetVar(cudt(i).Typ,adr,lpszNme,lpszBuff,dp)
					Exit For
				EndIf
			Next
	End Select
	If Len(buff) Then
		Return udt(typ).nm & "=" & buff
	Else
		Return udt(typ).nm
	EndIf

End Function

Function EditProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim ti As TOOLINFO
	Dim As ZString*256 buff,nme1,nme2,nsp
	Dim pt As Point
	Dim As Integer i,j,n,dp,adr,fGlobal,fParam,nCursorLine
	Dim lpTOOLTIPTEXT As TOOLTIPTEXT Ptr
	Dim lpArr As tarr Ptr

	Select Case uMsg
'		Case WM_KEYDOWN
'			If hThread Then
'				Return 0
'			EndIf
'			'
'		Case WM_CHAR
'			If hThread Then
'				Return 0
'			EndIf
'			'
		Case WM_MOUSEMOVE
			If hThread Then
				SetCursor(LoadCursor(0,IDC_ARROW))
				If nLnDebug<>-1 Then
					GetCursorPos(@pt)
					If Abs(pt.x-ptcur.x)>3 Or Abs(pt.y-ptcur.y)>3 Then
						ptcur.x=pt.x
						ptcur.y=pt.y
						SendMessage(GetParent(hWin),REM_SETCURSORWORDTYPE,2,0)
						nCursorLine=SendMessage(GetParent(hWin),REM_GETCURSORWORD,SizeOf(buff),Cast(LPARAM,@buff))
						SendMessage(GetParent(hWin),REM_SETCURSORWORDTYPE,0,0)
						' With block, fixup buff
						If Left(buff,1)="." Then
							i=IsProjectFile(@lpData->filename)
							i=SendMessage(lpHandles->hpr,PRM_ISINWITHBLOCK,i,nCursorLine)
							If i Then
								lstrcpy(@nme1,Cast(ZString Ptr,i))
								buff=nme1 & buff
							EndIf
						EndIf
						' Array, fixup buff
						dp=0
						While InStr(dp+1,buff,"(")
							i=InStr(dp+1,buff,"(")
							dp=i
							j=0
							While TRUE
								If Mid(buff,i,1)="(" Then
									j+=1
								ElseIf Mid(buff,i,1)=")" Then
									j-=1
									If j=0 Then
										buff=Left(buff,dp) & Mid(buff,i)
										Exit while
									EndIf
								EndIf
								i+=1
							Wend
						Wend
						nme1=UCase(buff)
						' Fixup nme1
						While InStr(nme1,"(")
							i=InStr(nme1,"(")
							nme1=Left(nme1,i-1) & Mid(nme1,i+2)
						Wend
						While InStr(nme1,"->")
							i=InStr(nme1,"->")
							nme1=Left(nme1,i-1) & "." & Mid(nme1,i+2)
						Wend
						i=InStr(nme1,".")
						If i Then
							nsp="NS : " & nme1
							nme2=Mid(nme1,i+1)
							nme1=Left(nme1,i-1)
						EndIf
						i=1
						adr=0
						While i<=vrbnb
							If (vrb(i).pn=procsv Or vrb(i).pn<0) And (nme1=vrb(i).nm Or nsp=vrb(i).nm) Then
								'PutString("procsv: " & Str(procsv))
								'PutString("vrb(i).pn: " & Str(vrb(i).pn))
								'PutString("vrb(i).nm: " & vrb(i).nm)
								'PutString("nme: " & nme)
								'PutString("vrb(i).pt: " & vrb(i).pt)
								'PutString("vrb(i).pt: " & vrb(i).adr)
								' Array, insert dimension(s)
								dp=0
								If vrb(i).arr Then
									lpArr=vrb(i).arr
									dp=InStr(buff,"(")
									buff=Left(buff,dp) & GetArrayDim(lpArr) & Mid(buff,dp+1)
								EndIf
								Select Case vrb(i).mem
									Case 1
										nme1="Shared"
										adr=vrb(i).adr
										fGlobal=1
										'
									Case 2
										nme1="Static"
										adr=vrb(i).adr
										fGlobal=1
										'
									Case 3
										nme1="ByRef"
										adr=ebp_this+vrb(i).adr
										fParam=2
										'
									Case 4
										nme1="ByVal"
										adr=ebp_this+vrb(i).adr
										fParam=1
										'
									Case 5
										nme1="Local"
										adr=ebp_this+vrb(i).adr
										'
									Case Else
										nme1="Unknown"
								End Select
								If fGlobal=0 Then
									If fParam Then
										' Parameter
										If proc(procsv).nu=nCursorLine+1 Then
											If fParam=2 Then
												' ByRef
												ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@adr,4,0)
											EndIf
										Else
											adr=0
										EndIf
									Else
										' Check if in scope
										For j=1 To linenb
											If rline(j).nu=nCursorLine+1 And rline(j).sv=procsv Then
												If rline(j).ad<proc(procsv).db Or rline(j).ad>proc(procsv).fn Then
													adr=0
												EndIf
												Exit For
											EndIf
										Next
									EndIf
								EndIf
								If adr Then
									For j=1 To vrb(i).pt
										buff="*" & buff
										ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@adr,4,0)
									Next
									buff=nme1 & " " & buff & " As "
									dp=InStr(buff,"(")
									If dp Then
										adr=0
									EndIf
									buff=buff & GetVar(vrb(i).typ,adr,@nme2,@buff,dp)
									szTipText=buff
									ti.cbSize=SizeOf(TOOLINFO)
									ti.uFlags=TTF_IDISHWND Or TTF_SUBCLASS
									ti.hWnd=hWin
									ti.uId=Cast(Integer,hWin)
									ti.hInst=hInstance
									ti.lpszText=@szTipText
									SendMessage(hTip,TTM_ADDTOOL,0,Cast(LPARAM,@ti))
									SendMessage(hTip,TTM_ACTIVATE,FALSE,0)
									SendMessage(hTip,TTM_ACTIVATE,TRUE,0)
								EndIf
								'PutString(buff)
								'PutString("Adr:" & Str(vrb(i).adr) & " Pt:" & Str(vrb(i).pt))
								'PutString(proc(procsv).nm)
								'PutString("Adr " & Str(procsk+vrb(i).adr))
								'PutString("db " & Str(proc(procsv).db))
								'PutString("fn " & Str(proc(procsv).fn))
								'PutString("sr " & Str(proc(procsv).sr))
								'PutString("ad " & Str(proc(procsv).ad))
								'PutString("vr " & Str(proc(procsv).vr))
								'PutString("rv " & Str(proc(procsv).rv))
								'PutString("procsv " & Str(procsv))
								Return 0
							EndIf
							i+=1
						Wend
					Else
						Return 0
					EndIf
				EndIf
				SendMessage(hTip,TTM_ACTIVATE,FALSE,0)
				Return 0
			EndIf
			'
	End Select
	Return CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
	
End Function

Function CheckLine(ByVal nLine As Integer,ByVal lpszFile As ZString Ptr) As Boolean
	Dim i As Integer

	If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
		If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
			If hThread Then
				nLine+=1
				For i=1 To linenb
					If rline(i).nu=nLine And UCase(*lpszFile)=UCase(source(proc(rline(i).pr).sr)) Then
						Return TRUE
					EndIf
				Next
				Return FALSE
			EndIf
			Return TRUE
		EndIf
	EndIf
	Return FALSE

End Function

Sub AddAccelerator(ByVal fvirt As Integer,ByVal akey As Integer,ByVal id As Integer)
	Dim nAccel As Integer
	Dim acl(500) As ACCEL
	Dim i As Integer

	nAccel=CopyAcceleratorTable(lpHandles->haccel,NULL,0)
	CopyAcceleratorTable(lpHandles->haccel,@acl(0),nAccel)
	DestroyAcceleratorTable(lpHandles->haccel)
	' Check if id exist
	For i=0 To nAccel-1
		If acl(i).cmd=id Then
			' id exist, update accelerator
			acl(i).fVirt=fvirt
			acl(i).key=akey
			GoTo Ex
		EndIf
	Next i
	' Check if accelerator exist
	For i=0 To nAccel-1
		If acl(i).fVirt=fvirt And acl(i).key=akey Then
			' Accelerator exist, update id
			acl(i).cmd=id
			GoTo Ex
		EndIf
	Next i
	' Add new accelerator
	acl(nAccel).fVirt=fvirt
	acl(nAccel).key=akey
	acl(nAccel).cmd=id
	nAccel=nAccel+1
Ex:
	lpHandles->haccel=CreateAcceleratorTable(@acl(0),nAccel)

End Sub

Sub CreateDebugMenu()
	Dim mii As MENUITEMINFO

	mii.cbSize=SizeOf(MENUITEMINFO)
	mii.fMask=MIIM_TYPE Or MIIM_SUBMENU
	mii.fType=MFT_STRING
	mii.dwTypeData=StrPtr("&Debug")
	mii.hSubMenu=CreatePopupMenu()
	InsertMenuItem(lpHandles->hmenu,3,TRUE,@mii)
	
	nMnuToggle=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuToggle,StrPtr("Toggle &Breakpoint	Ctrl+T"))
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FCONTROL,Asc("T"),nMnuToggle)

	nMnuClear=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuClear,StrPtr("&Clear Breakpoints	Shift+Ctrl+T"))
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT Or FCONTROL,Asc("T"),nMnuClear)

	AppendMenu(mii.hSubMenu,MF_SEPARATOR,0,0)

	nMnuRun=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuRun,StrPtr("&Run	Shift+F7"))
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT,VK_F7,nMnuRun)

	nMnuStop=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStop,StrPtr("&Stop	Alt+F7"))
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FALT,VK_F7,nMnuStop)

	AppendMenu(mii.hSubMenu,MF_SEPARATOR,0,0)

	nMnuStepInto=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStepInto,StrPtr("Step &Into	F7"))
	AddAccelerator(FVIRTKEY Or FNOINVERT,VK_F7,nMnuStepInto)

	nMnuStepOver=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStepOver,StrPtr("Step &Over	Ctrl+F7"))
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FCONTROL,VK_F7,nMnuStepOver)

	nMnuRunToCaret=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuRunToCaret,StrPtr("Run &To Caret	Shift+Ctrl+F7"))
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT Or FCONTROL,VK_F7,nMnuRunToCaret)

End Sub

Function GetLineNumber() As Integer
	Dim chrg As CHARRANGE

	SendMessage(lpHandles->hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
	Return SendMessage(lpHandles->hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)

End Function

Sub ClearDebugLine()

	If nLnDebug<>-1 And hLnDebug<>0 Then
		SendMessage(hLnDebug,REM_SETHILITELINE,nLnDebug,0)
		nLnDebug=-1
		hLnDebug=0
	EndIf

End Sub

Sub EnableDebugMenu()
	Dim st As Integer

	st=MF_BYCOMMAND Or MF_GRAYED
	If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
		If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
			If IsProjectFile(@lpData->filename) Then
				st=MF_BYCOMMAND Or MF_ENABLED
			EndIf
		EndIf
	EndIf
	EnableMenuItem(lpHandles->hmenu,nMnuToggle,st)
	EnableMenuItem(lpHandles->hmenu,nMnuClear,st)
	st=MF_BYCOMMAND Or MF_GRAYED
	If lstrlen(@lpData->ProjectFile) Then
		st=MF_BYCOMMAND Or MF_ENABLED
	EndIf
	EnableMenuItem(lpHandles->hmenu,nMnuRun,st)
	' Run To Caret
	st=MF_BYCOMMAND Or MF_GRAYED
	If hThread Then
		If CheckLine(GetLineNumber,@lpData->filename) Then
			st=MF_BYCOMMAND Or MF_ENABLED
		EndIf
	EndIf
	EnableMenuItem(lpHandles->hmenu,nMnuRunToCaret,st)
	' Step Into, Step Over
	st=MF_BYCOMMAND Or MF_GRAYED
	If hThread Then
		st=MF_BYCOMMAND Or MF_ENABLED
	EndIf
	EnableMenuItem(lpHandles->hmenu,nMnuStop,st)
	EnableMenuItem(lpHandles->hmenu,nMnuStepInto,st)
	EnableMenuItem(lpHandles->hmenu,nMnuStepOver,st)

End Sub

Sub LockFiles(ByVal bLock As Boolean)
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM Ptr
	Dim i As Integer

	tci.mask=TCIF_PARAM
	i=0
	While TRUE
		If SendMessage(lpHandles->htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
			lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
			If lpTABMEM->profileinx Then
				SendMessage(lpTABMEM->hedit,REM_READONLY,0,bLock)
			EndIf
		Else
			Exit While
		EndIf
		i+=1
	Wend

End Sub

Function CheckFileTime(ByVal lpszExe As ZString Ptr) As String
	Dim As Integer i,nInx,nMiss
	Dim hFile As HANDLE
	Dim As FILETIME ftexe,ftfile
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM Ptr
	Dim szItem As ZString*260

	' Get exe filetime
	hFile=CreateFile(lpszExe,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0)
	If hFile<>INVALID_HANDLE_VALUE Then
		GetFileTime(hFile,NULL,NULL,@ftexe)
		CloseHandle(hFile)
		' Check for unsaved files
		tci.mask=TCIF_PARAM
		i=0
		While TRUE
			If SendMessage(lpHandles->htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
				lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
				If lpTABMEM->profileinx Then
					If SendMessage(lpTABMEM->hedit,EM_GETMODIFY,0,0) Then
						Return "File(s) not saved"
					EndIf
				EndIf
			Else
				Exit While
			EndIf
			i+=1
		Wend
		nInx=1
		nMiss=0
		Do While nInx<256 And nMiss<MAX_MISS
			szItem=szNULL
			GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@szItem,SizeOf(szItem),@lpData->ProjectFile)
			If Len(szItem) Then
				nMiss=0
				szItem=MakeProjectFileName(szItem)
				hFile=CreateFile(szItem,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0)
				If hFile<>INVALID_HANDLE_VALUE Then
					GetFileTime(hFile,NULL,NULL,@ftfile)
					CloseHandle(hFile)
					If (ftexe.dwHighDateTime=ftfile.dwHighDateTime And  ftexe.dwLowDateTime<ftfile.dwLowDateTime) Or ftexe.dwHighDateTime<ftfile.dwHighDateTime Then
						Return "A source file is newer than the exe." & Chr(13) & Chr(10) & "Recompile the project."
					EndIf
				EndIf
			Else
				nMiss=nMiss+1
			EndIf
			nInx=nInx+1
		Loop
		nInx=1001
		nMiss=0
		Do While nInx<1256 And nMiss<MAX_MISS
			szItem=szNULL
			GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@szItem,SizeOf(szItem),@lpData->ProjectFile)
			If Len(szItem) Then
				nMiss=0
				szItem=MakeProjectFileName(szItem)
				hFile=CreateFile(szItem,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0)
				If hFile<>INVALID_HANDLE_VALUE Then
					GetFileTime(hFile,NULL,NULL,@ftfile)
					CloseHandle(hFile)
					If (ftexe.dwHighDateTime=ftfile.dwHighDateTime And  ftexe.dwLowDateTime<ftfile.dwLowDateTime) Or ftexe.dwHighDateTime<ftfile.dwHighDateTime Then
						Return "A source file is newer than the exe." & Chr(13) & Chr(10) & "Recompile the project."
					EndIf
				EndIf
			Else
				nMiss=nMiss+1
			EndIf
			nInx=nInx+1
		Loop
	Else
		Return *lpszExe & " not found."
	EndIf
	Return ""

End Function

' Returns info on what messages the addin hooks into (in an ADDINHOOKS type).
Function InstallDll Cdecl Alias "InstallDll" (ByVal hWin As HWND,ByVal hInst As HINSTANCE) As ADDINHOOKS Ptr Export

	hooks.hook1=0
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	' The dll's instance
	hInstance=hInst
	' Get pointer to ADDINHANDLES
	lpHandles=Cast(ADDINHANDLES Ptr,SendMessage(hWin,AIM_GETHANDLES,0,0))
	' Get pointer to ADDINDATA
	lpData=Cast(ADDINDATA Ptr,SendMessage(hWin,AIM_GETDATA,0,0))
	' Get pointer to ADDINFUNCTIONS
	lpFunctions=Cast(ADDINFUNCTIONS Ptr,SendMessage(hWin,AIM_GETFUNCTIONS,0,0))
	If lpData->version>=1062 Then
		' Messages this addin will hook into
		hooks.hook1=HOOK_COMMAND Or HOOK_FILEOPENNEW Or HOOK_FILECLOSE Or HOOK_MENUENABLE Or HOOK_ADDINSLOADED Or HOOK_FILESTATE Or HOOK_QUERYCLOSE
	EndIf
	Return @hooks

End Function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
Function DllFunction Cdecl Alias "DllFunction" (ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As bool Export
	Dim As Integer tid,nLn,nInx
	Dim lp As Any Ptr
	Dim lpTABMEM As TABMEM Ptr

	Select Case uMsg
		Case AIM_COMMAND
			nInx=LoWord(wParam)
			Select Case nInx
				Case nMnuToggle
					If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
						If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
							nInx=IsProjectFile(@lpData->filename)
							If nInx Then
								nLn=GetLineNumber
								tid=SendMessage(lpHandles->hred,REM_GETBOOKMARK,nLn,0)
								If tid=0 Then
									If CheckLine(nLn,@lpData->filename) Then
										SendMessage(lpHandles->hred,REM_SETBOOKMARK,nLn,5)
									EndIf
								ElseIf tid=5 Then
									SendMessage(lpHandles->hred,REM_SETBOOKMARK,nLn,0)
								EndIf
								SaveBreakpoints(lpHandles->hred,nInx)
							EndIf
						EndIf
					EndIf
					Return TRUE
					'
				Case nMnuClear
					If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
						If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
							nInx=IsProjectFile(@lpData->filename)
							If nInx Then
								SendMessage(lpHandles->hred,REM_CLRBOOKMARKS,0,5)
								SaveBreakpoints(lpHandles->hred,nInx)
							EndIf
						EndIf
					EndIf
					Return TRUE
					'
				Case nMnuRun
					If lstrlen(@lpData->ProjectFile) Then
						nLnRunTo=-1
						If hThread Then
							ClearDebugLine
							fRun=1
							ResumeThread(pinfo.hThread)
						Else
							fExit=0
							If Len(lpData->smakeoutput) Then
								szFileName=lpData->ProjectPath & "\" & lpData->smakeoutput
							Else
								szFileName=lpData->ProjectFile
								szFileName=Left(szFileName,Len(szFileName)-3) & "exe"
							EndIf
							szTipText=CheckFileTime(@szFileName)
							If szTipText="" Then
								nLnDebug=-1
								LockFiles(TRUE)
								lpFunctions->ShowOutput(TRUE)
								PutString("Debugging: " & szFileName)
								lpData->fDebug=TRUE
								hThread=CreateThread(NULL,0,Cast(Any Ptr,@RunFile),Cast(LPVOID,@szFileName),NULL,@tid)
								EnableDebugMenu
							Else
								MessageBox(lpHandles->hwnd,szTipText,"Debug",MB_OK Or MB_ICONERROR)
							EndIf
						EndIf
					EndIf
					Return TRUE
					'
				Case nMnuStop
					If hThread Then
						fExit=1
						WriteProcessMemory(dbghand,Cast(Any Ptr,rLine(linesav).ad),@breakvalue,1,0)
						ResumeThread(pinfo.hThread)
						ClearDebugLine
					EndIf
					Return TRUE
					'
				Case nMnuStepInto
					If hThread Then
						nLnRunTo=-1
						ClearDebugLine
						ResumeThread(pinfo.hThread)
					EndIf
					Return TRUE
					'
				Case nMnuStepOver
					If hThread Then
						nLnRunTo=-1
						nprocrnb=procrnb
						ClearDebugLine
						ClearBreakAll(procsv)
						SetBreakPoints(0)
						ResumeThread(pinfo.hThread)
					EndIf
					Return TRUE
					'
				Case nMnuRunToCaret
					If hThread Then
						ClearDebugLine
						If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
							If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
								nInx=IsProjectFile(@lpData->filename)
								If nInx Then
									nLnRunTo=GetLineNumber
									ClearBreakAll(0)
									SetBreakPoints(nLnRunTo)
								EndIf
							EndIf
						EndIf
						ResumeThread(pinfo.hThread)
					EndIf
					Return TRUE
					'
				Case IDM_MAKE_COMPILE,IDM_MAKE_RUN,IDM_MAKE_GO,IDM_MAKE_QUICKRUN,IDM_FILE_NEWPROJECT,IDM_FILE_OPENPROJECT,IDM_FILE_CLOSEPROJECT
					If hThread Then
						Return TRUE
					EndIf
					'
			End Select
			'
		Case AIM_FILEOPENNEW
			If lstrlen(@lpData->ProjectFile) Then
				If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
					If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
						nInx=IsProjectFile(Cast(ZString Ptr,lParam))
						If nInx Then
							lpOldEditProc=Cast(Any Ptr,SendMessage(lpHandles->hred,REM_SUBCLASS,0,Cast(LPARAM,@EditProc)))
							LoadBreakpoints(lpHandles->hred,nInx)
							If hThread Then
								SendMessage(lpHandles->hred,REM_READONLY,0,TRUE)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
			'
		Case AIM_FILECLOSE
			If lstrlen(@lpData->ProjectFile) Then
				If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
					If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
						nInx=IsProjectFile(Cast(ZString Ptr,lParam))
						If nInx Then
							SaveBreakpoints(lpHandles->hred,nInx)
						EndIf
					EndIf
				EndIf
			EndIf
			'
		Case AIM_FILESTATE
			If lstrlen(@lpData->ProjectFile) Then
				lpTABMEM=Cast(TABMEM Ptr,lParam)
				If lpTABMEM->hedit<>lpHandles->hres Then
					If GetWindowLong(lpTABMEM->hedit,GWL_ID)<>IDC_HEXED Then
						If lpTABMEM->profileinx Then
							SaveBreakpoints(lpTABMEM->hedit,lpTABMEM->profileinx)
						EndIf
					EndIf
				EndIf
			EndIf
			'
		Case AIM_ADDINSLOADED
			If fDone=0 Then
				fDone=1
				CreateToolTip
				CreateDebugMenu
				lpFunctions->CallAddins(lpHandles->hwnd,AIM_MENUREFRESH,0,0,HOOK_MENUREFRESH)
			EndIf
			'
		Case AIM_MENUENABLE
			EnableDebugMenu
			'
		Case AIM_QUERYCLOSE
			If hThread Then
				MessageBox(hWin,"Still debugging.","Debug",MB_OK Or MB_ICONERROR)
				Return TRUE
			EndIf
			'
	End Select
	Return FALSE

End Function
