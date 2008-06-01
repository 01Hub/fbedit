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
	nMnuToggle=SendMessage(hWin,AIM_GETMENUID,0,0)
	AppendMenu(GetSubMenu(lpHandles->hmenu,1),MF_STRING,nMnuToggle,StrPtr("Toggle breakpoint"))
	nMnuClear=SendMessage(hWin,AIM_GETMENUID,0,0)
	AppendMenu(GetSubMenu(lpHandles->hmenu,1),MF_STRING,nMnuClear,StrPtr("Clear breakpoints"))
	' Messages this addin will hook into
	hooks.hook1=HOOK_COMMAND Or HOOK_FILEOPEN Or HOOK_FILECLOSE Or HOOK_MENUENABLE
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	Return @hooks

End Function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
Function DllFunction Cdecl Alias "DllFunction" (ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As bool Export
	Dim tid As Integer
	Dim nInx As Integer
	Dim chrg As CHARRANGE

	Select Case uMsg
		Case AIM_COMMAND
			If wParam=IDM_MAKE_RUNDEBUG Then
				If lstrlen(@lpData->ProjectFile) Then
					If Len(lpData->smakeoutput) Then
						szFileName=lpData->ProjectPath & "\" & lpData->smakeoutput
					Else
						szFileName=lpData->ProjectFile
						szFileName=Left(szFileName,Len(szFileName)-3) & "exe"
					EndIf
					lpFunctions->TextToOutput(szFileName)
					hThread=CreateThread(NULL,0,Cast(Any Ptr,@RunFile),Cast(LPVOID,@szFileName),NULL,@tid)
					Return TRUE
				EndIf
			ElseIf wParam=IDM_MAKE_RUN Then
				If hThread Then
					PutString(StrPtr("IDM_MAKE_RUN"))
					ResumeThread(pinfo.hThread)
					Return TRUE
				EndIf
			ElseIf wParam=nMnuToggle Then
				If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
					If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
						SendMessage(lpHandles->hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
						nInx=SendMessage(lpHandles->hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)
						tid=SendMessage(lpHandles->hred,REM_GETBOOKMARK,nInx,0)
						If tid=0 Then
							SendMessage(lpHandles->hred,REM_SETBOOKMARK,nInx,6)
						ElseIf tid=6 Then
							SendMessage(lpHandles->hred,REM_SETBOOKMARK,nInx,0)
						EndIf
					EndIf
				EndIf
				Return TRUE
			ElseIf wParam=nMnuClear Then
				If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
					If GetWindowLong(lpHandles->hred,GWL_ID)<>IDC_HEXED Then
					EndIf
				EndIf
				Return TRUE
			EndIf
			'
		Case AIM_FILEOPEN
			If lstrlen(@lpData->ProjectFile) Then
				'PutString(Cast(ZString Ptr,lParam))
				nInx=IsProjectFile(Cast(ZString Ptr,lParam))
				If nInx Then
					'PutString("Open: " & Str(nInx))
				EndIf
			EndIf
			'
		Case AIM_FILECLOSE
			If lstrlen(@lpData->ProjectFile) Then
				'PutString(Cast(ZString Ptr,lParam))
				nInx=IsProjectFile(Cast(ZString Ptr,lParam))
				If nInx Then
					'PutString("Close: " & Str(nInx))
				EndIf
			EndIf
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
