#Include Once "windows.bi"
#Include Once "win/commctrl.bi"
#Include Once "win/richedit.bi"

#Include "..\..\..\..\..\Inc\RAEdit.bi"
#Include "..\..\..\..\..\Inc\Addins.bi"
#Include "FbDebug.bi"
#Include "Debug.bas"

Function MakeProjectFileName(ByVal sFile As String) As String
	Dim sItem As String*260
	Dim sPath As String*260
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
	Dim nInx As Integer
	Dim nMiss As Integer
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

Sub GetBreakPoints()
	Dim i As Integer
	Dim nInx As Integer
	Dim nMiss As Integer
	Dim sItem As ZString*260

	For i=0 To 31
		bp(i).nInx=0
		bp(i).sFile=""
		bp(i).sBP=""
	Next
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

Function EditProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim buff As ZString*256
	Dim nme As ZString*256
	Dim pt As Point
	Dim i As Integer
	Dim adr As Integer
	Dim bval As ZString*32

	Select Case uMsg
		Case WM_KEYDOWN
			If hThread Then
				Return 0
			EndIf
			'
		Case WM_CHAR
			If hThread Then
				Return 0
			EndIf
			'
		Case WM_MOUSEMOVE
			If hThread Then
				If nLnDebug<>-1 Then
					GetCursorPos(@pt)
					If Abs(pt.x-ptcur.x)>3 Or Abs(pt.y-ptcur.y)>3 Then
						ptcur.x=pt.x
						ptcur.y=pt.y
						SendMessage(GetParent(hWin),REM_GETCURSORWORD,SizeOf(buff),Cast(LPARAM,@buff))
						nme=UCase(buff)
						i=1
						adr=0
						While vrb(i).nm<>""
							If nme=vrb(i).nm Then
								Select Case vrb(i).mem
									Case 1
										nme="Shared"
										adr=procsk+vrb(i).adr
										'
									Case 2
										nme="Static"
										adr=procsk+vrb(i).adr
										'
									Case 3
										nme="ByRef"
										'
									Case 4
										nme="ByVal"
										'
									Case 5
										nme="Local"
										adr=procsk+vrb(i).adr
										'
									Case Else
										nme="Unknown"
								End Select
								buff=nme & " " & buff & ":" & udt(vrb(i).typ).nm & "="
								If adr Then
									Select Case vrb(i).typ
										Case 0
											' Proc
										Case 1
											' Integer
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
											buff=buff & Str(Peek(Integer,@bval))
										Case 2
											' Byte
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
											buff=buff & Str(Peek(Byte,@bval))
										Case 3
											' UByte
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,1,0)
											buff=buff & Str(Peek(UByte,@bval))
										Case 4
											' Char
										Case 5
											' Short
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
											buff=buff & Str(Peek(Short,@bval))
										Case 6
											' UShort
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,2,0)
											buff=buff & Str(Peek(UShort,@bval))
										Case 7
											' Void
										Case 8
											' UInteger
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
											buff=buff & Str(Peek(UInteger,@bval))
										Case 9
											' Longint
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
											buff=buff & Str(Peek(LongInt,@bval))
										Case 10
											' ULongint
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
											buff=buff & Str(Peek(ULongInt,@bval))
										Case 11
											' Single
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,4,0)
											buff=buff & Str(Peek(Single,@bval))
										Case 12
											' Double
											ReadProcessMemory(dbghand,Cast(Any Ptr,adr),@bval,8,0)
											buff=buff & Str(Peek(Double,@bval))
										Case 13
											' String
										Case 14
											' ZString
										Case 15
											' PChar
									End Select
								EndIf
								PutString(buff)
								PutString("Adr:" & Str(vrb(i).adr) & " Pt:" & Str(vrb(i).pt))
PutString(proc(procrnb).nm)
PutString(Str(procsk+vrb(i).adr))
PutString("db" & Str(proc(procrnb).db))
PutString("fn" & Str(proc(procrnb).fn))
PutString("sr" & Str(proc(procrnb).sr))
PutString("ad" & Str(proc(procrnb).ad))
PutString("vr" & Str(proc(procrnb).vr))
PutString("rv" & Str(proc(procrnb).rv))


								Exit While
							EndIf
							i+=1
						Wend
					EndIf
				EndIf
				Return 0
			EndIf
			'
	End Select
	Return CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
	
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
	Dim nLn As Integer
	Dim x As Integer

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
	nMnuRunToCursor=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuRunToCursor,StrPtr("Run &To Cursor"))
	nMnuStepInto=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStepInto,StrPtr("Step &Into"))
	nMnuStepOver=SendMessage(lpHandles->hwnd,AIM_GETMENUID,0,0)
	AppendMenu(mii.hSubMenu,MF_STRING,nMnuStepOver,StrPtr("Step &Over"))

End Sub

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
	hooks.hook1=HOOK_COMMAND Or HOOK_FILEOPENNEW Or HOOK_FILECLOSE Or HOOK_MENUENABLE Or HOOK_ADDINSLOADED
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	Return @hooks

End Function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
Function DllFunction Cdecl Alias "DllFunction" (ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As bool Export
	Dim tid As Integer
	Dim nLn As Integer
	Dim nInx As Integer
	Dim chrg As CHARRANGE
	Dim lp As Any Ptr

	Select Case uMsg
		Case AIM_COMMAND
			If wParam=nMnuRun Then
				If lstrlen(@lpData->ProjectFile) Then
					GetBreakPoints
					nDebugMode=0
					nLnRunTo=-1
					If hThread Then
						If nLnDebug<>-1 Then
							SendMessage(lpHandles->hred,REM_SETHILITELINE,nLnDebug,0)
							nLnDebug=-1
						EndIf
						ResumeThread(pinfo.hThread)
					Else
						If Len(lpData->smakeoutput) Then
							szFileName=lpData->ProjectPath & "\" & lpData->smakeoutput
						Else
							szFileName=lpData->ProjectFile
							szFileName=Left(szFileName,Len(szFileName)-3) & "exe"
						EndIf
						nLnDebug=-1
						nDebugMode=1
						hThread=CreateThread(NULL,0,Cast(Any Ptr,@RunFile),Cast(LPVOID,@szFileName),NULL,@tid)
					EndIf
				EndIf
				Return TRUE
			ElseIf wParam=nMnuRunToCursor Then
				If hThread Then
					nDebugMode=0
					If nLnDebug<>-1 Then
						SendMessage(lpHandles->hred,REM_SETHILITELINE,nLnDebug,0)
						nLnDebug=-1
					EndIf
					If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
						If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
							nInx=IsProjectFile(@lpData->filename)
							If nInx Then
								SendMessage(lpHandles->hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
								nLnRunTo=SendMessage(lpHandles->hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)
							EndIf
						EndIf
					EndIf
					ResumeThread(pinfo.hThread)
				EndIf
				Return TRUE
			ElseIf wParam=nMnuStepInto Then
				If hThread Then
					nDebugMode=1
					nLnRunTo=-1
					If nLnDebug<>-1 Then
						SendMessage(lpHandles->hred,REM_SETHILITELINE,nLnDebug,0)
						nLnDebug=-1
					EndIf
					ResumeThread(pinfo.hThread)
				EndIf
				Return TRUE
			ElseIf wParam=nMnuStepOver Then
				If hThread Then
					nDebugMode=2
					nLnRunTo=-1
					nprocrnb=procrnb
					If nLnDebug<>-1 Then
						SendMessage(lpHandles->hred,REM_SETHILITELINE,nLnDebug,0)
						nLnDebug=-1
					EndIf
					ResumeThread(pinfo.hThread)
				EndIf
				Return TRUE
			ElseIf wParam=nMnuToggle Then
				If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
					If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
						nInx=IsProjectFile(@lpData->filename)
						If nInx Then
							SendMessage(lpHandles->hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
							nLn=SendMessage(lpHandles->hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)
							tid=SendMessage(lpHandles->hred,REM_GETBOOKMARK,nLn,0)
							If tid=0 Then
								SendMessage(lpHandles->hred,REM_SETBOOKMARK,nLn,5)
							ElseIf tid=5 Then
								SendMessage(lpHandles->hred,REM_SETBOOKMARK,nLn,0)
							EndIf
							SaveBreakpoints(lpHandles->hred,nInx)
						EndIf
					EndIf
				EndIf
				Return TRUE
			ElseIf wParam=nMnuClear Then
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
			EndIf
			'
		Case AIM_FILEOPENNEW
			If lstrlen(@lpData->ProjectFile) Then
				If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
					If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
						nInx=IsProjectFile(Cast(ZString Ptr,lParam))
						If nInx Then
							lpOldEditProc=Cast(Any Ptr,SendMessage(lpHandles->hred,REM_SUBCLASS,0,Cast(LPARAM,@EditProc)))
							LoadBreakpoints(lpHandles->hred,nInx)
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
		Case AIM_ADDINSLOADED
			CreateDebugMenu
			'
		Case AIM_MENUENABLE
			nInx=MF_BYCOMMAND Or MF_GRAYED
			If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
				If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
					nInx=MF_BYCOMMAND Or MF_ENABLED
				EndIf
			EndIf
			EnableMenuItem(lpHandles->hmenu,nMnuToggle,nInx)
			EnableMenuItem(lpHandles->hmenu,nMnuClear,nInx)
			'
	End Select
	Return FALSE

End Function
