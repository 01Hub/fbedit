#Include Once "windows.bi"
#Include Once "win/commctrl.bi"
#Include Once "win/richedit.bi"

#Include "..\..\..\..\..\Inc\RAEdit.bi"
#Include "..\..\..\..\..\Inc\Addins.bi"
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
	Dim As Integer i,nInx,nMiss
	Dim sItem As ZString*260

	For i=0 To SOURCEMAX
		bp(i).nInx=0
		bp(i).sFile=""
		bp(i).sBP=""
	Next
	nMiss=CheckBreakPoints
	If nMiss Then
		MessageBox(lpHandles->hwnd,"There is " & Str(nMiss) & " unhandled breakpoint(s).","Debug",MB_OK Or MB_ICONINFORMATION)
	EndIf
	i=0
	nInx=1
	nMiss=0
	Do While nInx<256 And nMiss<MAX_MISS
		sItem=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
		If Len(sItem) Then
			nMiss=0
			sItem=MakeProjectFileName(sItem)
			bp(i).nInx=nInx
			bp(i).sFile=sItem
			GetPrivateProfileString(StrPtr("BreakPoint"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
			If Len(sItem) Then
				bp(i).sBP="," & sItem & ","
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
		sItem=szNULL
		GetPrivateProfileString(StrPtr("File"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
		If Len(sItem) Then
			nMiss=0
			sItem=MakeProjectFileName(sItem)
			bp(i).nInx=nInx
			bp(i).sFile=sItem
			GetPrivateProfileString(StrPtr("BreakPoint"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@lpData->ProjectFile)
			If Len(sItem) Then
				bp(i).sBP="," & sItem & ","
			EndIf
			i+=1
		Else
			nMiss=nMiss+1
		EndIf
		nInx=nInx+1
	Loop

End Sub

Sub CreateToolTip()

	hTip=CreateWindowEx(0,"tooltips_class32",NULL,TTS_NOPREFIX,0,0,0,0,NULL,0,hInstance,0)
	SendMessage(hTip,TTM_ACTIVATE,TRUE,0)
	SendMessage(hTip,TTM_SETDELAYTIME,TTDT_AUTOMATIC,500)
	SendMessage(hTip,TTM_SETMAXTIPWIDTH,0,800)

End sub

Function GetVar(ByVal typ As Integer,ByRef adr As UInteger,ByVal nme2 As ZString Ptr) As String
	Dim bval As ZString*32, buff As ZString*128
	Dim i As Integer

	Select Case typ
		Case 0
			' Proc
		Case 1
			' Integer
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
			Return Str(Peek(Integer,@bval))
		Case 2
			' Byte
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
			Return Str(Peek(Byte,@bval))
		Case 3
			' UByte
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
			Return Str(Peek(UByte,@bval))
		Case 4
			' Char
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,65,0)
			If Len(buff)>64 Then
				buff=Left(buff,64) & "..."
			EndIf
			Return Chr(34) & buff & Chr(34)
		Case 5
			' Short
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
			Return Str(Peek(Short,@bval))
		Case 6
			' UShort
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
			Return Str(Peek(UShort,@bval))
		Case 7
			' Void
			Return ""
		Case 8
			' UInteger
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
			Return Str(Peek(UInteger,@bval))
		Case 9
			' Longint
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
			Return Str(Peek(LongInt,@bval))
		Case 10
			' ULongint
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
			Return Str(Peek(ULongInt,@bval))
		Case 11
			' Single
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
			Return Str(Peek(Single,@bval))
		Case 12
			' Double
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
			Return Str(Peek(Double,@bval))
		Case 13
			' String
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
			Return Chr(34) & buff & Chr(34)
		Case 14
			' ZString
			ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@buff,65,0)
			If Len(buff)>64 Then
				buff=Left(buff,64) & "..."
			EndIf
			Return Chr(34) & buff & Chr(34)
		Case 15
			' PChar
		Case Else
'PutString(nme2 & "vrb(i).typ: " & vrb(i).typ & " udt(vrb(i).typ).lb: " & udt(vrb(i).typ).lb & " udt(vrb(i).typ).ub: " & udt(vrb(i).typ).ub)
			For i=udt(typ).lb To udt(typ).ub
				If cudt(i).nm=*nme2 Then
'					Return Str(cudt(i).ofs)
					adr+=cudt(i).ofs
					Return GetVar(cudt(i).Typ,adr,nme2)
					Exit For
				EndIf
			Next
	End Select
	Return ""

End Function

Function EditProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim ti As TOOLINFO
	Dim As ZString*256 buff,nme1,nme2
	Dim pt As Point
	Dim As Integer i,j,adr,fGlobal,fParam,nCursorLine
	Dim lpTOOLTIPTEXT As TOOLTIPTEXT Ptr

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
				If nLnDebug<>-1 Then
					GetCursorPos(@pt)
					If Abs(pt.x-ptcur.x)>3 Or Abs(pt.y-ptcur.y)>3 Then
						ptcur.x=pt.x
						ptcur.y=pt.y
						SendMessage(GetParent(hWin),REM_SETCURSORWORDTYPE,2,0)
						nCursorLine=SendMessage(GetParent(hWin),REM_GETCURSORWORD,SizeOf(buff),Cast(LPARAM,@buff))
						SendMessage(GetParent(hWin),REM_SETCURSORWORDTYPE,0,0)
'PutString(buff)
						nme1=UCase(buff)
						i=InStr(nme1,".")
						If i Then
							nme2=Mid(nme1,i+1)
							nme1=Left(nme1,i-1)
						Else
							i=InStr(nme1,"->")
							If i Then
								nme2=Mid(nme1,i+2)
								nme1=Left(nme1,i-1)
							EndIf
						EndIf
						i=1
						adr=0
						While i<=vrbnb
							If nme1=vrb(i).nm And (vrb(i).pn=procsv Or vrb(i).pn<0) Then
'PutString("procsv: " & Str(procsv))
'PutString("vrb(i).pn: " & Str(vrb(i).pn))
'PutString("vrb(i).nm: " & vrb(i).nm)
'PutString("nme: " & nme)
'PutString("vrb(i).pt: " & vrb(i).pt)
'PutString("vrb(i).pt: " & vrb(i).adr)
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
											If rline(j).nu=nCursorLine+1 Then
												Exit For
											EndIf
										Next
										If j<=linenb Then
											'PutString(Str(rline(j).ad) & ",db " & Str(proc(procsv).db) & ",fn " & Str(proc(procsv).fn) & ",ad " & Str(proc(procsv).ad) & ",vr " & Str(proc(procsv).vr))
											If rline(j).ad<proc(procsv).db Or rline(j).ad>proc(procsv).fn Then
												adr=0
											EndIf
										Else
										EndIf
										'PutString(Str(rline(j).ad) & ",db " & Str(proc(procsv).db) & ",fn " & Str(proc(procsv).fn))
									EndIf
								EndIf
								If adr Then
									For j=1 To vrb(i).pt
										buff="*" & buff
'PutString(Str(adr))
										ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@adr,4,0)
									Next
'PutString(Str(adr))
									buff=nme1 & " " & buff & " As " & udt(vrb(i).typ).nm & "="
									buff=buff & GetVar(vrb(i).typ,adr,@nme2)
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

Sub CreateDebugMenu()
	Dim mii As MENUITEMINFO

	mii.cbSize=SizeOf(MENUITEMINFO)
	mii.fMask=MIIM_TYPE Or MIIM_SUBMENU
	mii.fType=MFT_STRING
	mii.dwTypeData=StrPtr("&Debug")
	mii.hSubMenu=CreatePopupMenu()
	InsertMenuItem(lpHandles->hmenu,3,TRUE,@mii)
	nMnuToggle=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuToggle,StrPtr("Toggle &Breakpoint"))
	nMnuClear=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuClear,StrPtr("&Clear Breakpoints"))
	nMnuRun=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuRun,StrPtr("&Run"))
	nMnuStop=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStop,StrPtr("&Stop"))
	nMnuRunToCaret=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuRunToCaret,StrPtr("Run &To Caret	Shift+F5"))
	nMnuStepInto=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStepInto,StrPtr("Step &Into	F5"))
	nMnuStepOver=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStepOver,StrPtr("Step &Over	Ctrl+F5"))

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
			st=MF_BYCOMMAND Or MF_ENABLED
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

	' The dll's instance
	hInstance=hInst
	' Get pointer to ADDINHANDLES
	lpHandles=Cast(ADDINHANDLES Ptr,SendMessage(hWin,AIM_GETHANDLES,0,0))
	' Get pointer to ADDINDATA
	lpData=Cast(ADDINDATA Ptr,SendMessage(hWin,AIM_GETDATA,0,0))
	' Get pointer to ADDINFUNCTIONS
	lpFunctions=Cast(ADDINFUNCTIONS Ptr,SendMessage(hWin,AIM_GETFUNCTIONS,0,0))
	' Messages this addin will hook into
	hooks.hook1=HOOK_COMMAND Or HOOK_FILEOPENNEW Or HOOK_FILECLOSE Or HOOK_MENUENABLE Or HOOK_ADDINSLOADED Or HOOK_FILESTATE
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
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
				Case nMnuRun
					If lstrlen(@lpData->ProjectFile) Then
						nDebugMode=0
						nLnRunTo=-1
						If hThread Then
							ClearDebugLine
							ResumeThread(pinfo.hThread)
						Else
							If Len(lpData->smakeoutput) Then
								szFileName=lpData->ProjectPath & "\" & lpData->smakeoutput
							Else
								szFileName=lpData->ProjectFile
								szFileName=Left(szFileName,Len(szFileName)-3) & "exe"
							EndIf
							szTipText=CheckFileTime(@szFileName)
							If szTipText="" Then
								nLnDebug=-1
								nDebugMode=1
								LockFiles(TRUE)
								lpFunctions->ShowOutput(TRUE)
								PutString("Debugging: " & szFileName)
								lpData->fDebug=TRUE
								hThread=CreateThread(NULL,0,Cast(Any Ptr,@RunFile),Cast(LPVOID,@szFileName),NULL,@tid)
							Else
								MessageBox(lpHandles->hwnd,szTipText,"Debug",MB_OK Or MB_ICONERROR)
							EndIf
						EndIf
					EndIf
					Return TRUE
					'
				Case nMnuStop
					If hThread Then
						TerminateThread(hThread,0)
						CloseHandle(dbghand)
						CloseHandle(pinfo.hThread)
						CloseHandle(pinfo.hProcess)
						CloseHandle(hDebugFile)
						CloseHandle(hThread)
						hThread=0
						ClearDebugLine
						LockFiles(FALSE)
						lpData->fDebug=FALSE
						EnableDebugMenu
					EndIf
					Return TRUE
					'
				Case nMnuRunToCaret
					If hThread Then
						nDebugMode=0
						ClearDebugLine
						If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
							If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
								nInx=IsProjectFile(@lpData->filename)
								If nInx Then
									nLnRunTo=GetLineNumber
								EndIf
							EndIf
						EndIf
						ResumeThread(pinfo.hThread)
					EndIf
					Return TRUE
					'
				Case nMnuStepInto
					If hThread Then
						nDebugMode=1
						nLnRunTo=-1
						ClearDebugLine
						ResumeThread(pinfo.hThread)
					EndIf
					Return TRUE
					'
				Case nMnuStepOver
					If hThread Then
						nDebugMode=2
						nLnRunTo=-1
						nprocrnb=procrnb
						ClearDebugLine
						ResumeThread(pinfo.hThread)
					EndIf
					Return TRUE
					'
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
				Case IDM_MAKE_COMPILE
					If hThread Then
						' Step Into
						nDebugMode=1
						nLnRunTo=-1
						ClearDebugLine
						ResumeThread(pinfo.hThread)
						Return TRUE
					EndIf
					'
				Case IDM_MAKE_RUN
					If hThread Then
						' Tun To Cursor
						nDebugMode=0
						ClearDebugLine
						If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
							If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
								nInx=IsProjectFile(@lpData->filename)
								If nInx Then
									nLnRunTo=GetLineNumber
								EndIf
							EndIf
						EndIf
						ResumeThread(pinfo.hThread)
						Return TRUE
					EndIf
					'
				Case IDM_MAKE_GO
					If hThread Then
						' Step Over
						nDebugMode=2
						nLnRunTo=-1
						nprocrnb=procrnb
						ClearDebugLine
						ResumeThread(pinfo.hThread)
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
			CreateToolTip
			CreateDebugMenu
			lpFunctions->CallAddins(lpHandles->hwnd,AIM_MENUREFRESH,0,0,HOOK_MENUREFRESH)
			'
		Case AIM_MENUENABLE
			EnableDebugMenu
			'
	End Select
	Return FALSE

End Function
