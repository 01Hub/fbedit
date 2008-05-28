#Include Once "windows.bi"
#Include Once "win/commctrl.bi"
#Include Once "win/richedit.bi"

#Include "..\..\..\..\..\Inc\Addins.bi"
#Include "FbDebug.bi"
#Include "Debug.bas"

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
	hooks.hook1=HOOK_COMMAND
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	Return @hooks

End Function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
Function DllFunction Cdecl Alias "DllFunction" (ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As bool Export
	Dim tid As Integer

	Select Case uMsg
		Case AIM_COMMAND
			If wParam=IDM_MAKE_RUNDEBUG Then
				szFileName=lpData->ProjectPath & "\" & lpData->smakeoutput
				lpFunctions->TextToOutput(szFileName)
				hThread=CreateThread(NULL,0,Cast(Any Ptr,@RunFile),Cast(LPVOID,@szFileName),NULL,@tid)
				Return TRUE
			EndIf
			'
		Case AIM_CLOSE
			'
	End Select
	Return FALSE

End Function
