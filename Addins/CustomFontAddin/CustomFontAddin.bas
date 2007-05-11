#include once "windows.bi"
#include once "win/commctrl.bi"

#include "..\..\FbEdit\Inc\Addins.bi"

dim SHARED hInstance as HINSTANCE
dim SHARED hooks as ADDINHOOKS
dim SHARED lpHandles as ADDINHANDLES ptr
dim SHARED lpFunctions as ADDINFUNCTIONS ptr
dim SHARED lpData as ADDINDATA ptr

function InstallDll CDECL alias "InstallDll" (byval hWin as HWND,byval hInst as HINSTANCE) as ADDINHOOKS ptr EXPORT

	' The dll's instance
	hInstance=hInst
	' Get pointer to ADDINHANDLES
	lpHandles=Cast(ADDINHANDLES ptr,SendMessage(hWin,AIM_GETHANDLES,0,0))
	' Get pointer to ADDINDATA
	lpData=Cast(ADDINDATA ptr,SendMessage(hWin,AIM_GETDATA,0,0))
	' Get pointer to ADDINFUNCTIONS
	lpFunctions=Cast(ADDINFUNCTIONS ptr,SendMessage(hWin,AIM_GETFUNCTIONS,0,0))
	' Messages this addin will hook into
	hooks.hook1=HOOK_ADDINSLOADED Or HOOK_CLOSE
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	return @hooks

end Function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
function DllFunction CDECL alias "DllFunction" (byval hWin as HWND,byval uMsg as UINT,byval wParam as WPARAM,byval lParam as LPARAM) as bool Export
	Dim fontname As ZString * 32
	fontname = "cft.ttf"
'	fontname = "dina.fon"
	Select case uMsg
		Case AIM_ADDINSLOADED
			AddFontResource(Cast(Zstring ptr,@fontname))
		Case AIM_CLOSE
			RemoveFontResource(Cast(Zstring ptr,@fontname))
	End Select
	
	Return FALSE
end Function