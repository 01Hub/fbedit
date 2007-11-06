#include once "windows.bi"
#Include Once "win/commctrl.bi"

#Include "..\..\..\..\..\Inc\Addins.bi"
#Include "ReallyRad.bi"

#define IDD_DLGREALLYRAD        1000
#define IDC_CBOFIL              1001
#define IDC_CBOTEMPLATE         1002
#define IDC_STCFILE             1003
#define IDC_STCTEMPLATE         1004
#define IDC_STCPROCNAME         1005
#define IDC_EDTPROCNAME         1006

Function ReallyRadProc(ByVal hWin As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As Integer
	Dim As Long id, Event, x
	Dim buff As ZString*MAX_PATH
	Dim wfd As WIN32_FIND_DATA
	Dim hwfd As HANDLE

	Select Case uMsg
		Case WM_INITDIALOG
			id=1
			Do While id<256
				GetPrivateProfileString(StrPtr("File"),Str(id),@szNULL,@buff,SizeOf(buff),@lpData->ProjectFile)
				If Len(buff) Then
					If LCase(Right(buff,4))=".bas" Then
						x=SendDlgItemMessage(hWin,IDC_CBOFIL,CB_ADDSTRING,0,Cast(LPARAM,@buff))
						x=SendDlgItemMessage(hWin,IDC_CBOFIL,CB_SETITEMDATA,x,id)
					EndIf
				EndIf
				id+=1
			Loop
			id=1001
			Do While id<1256
				GetPrivateProfileString(StrPtr("File"),Str(id),@szNULL,@buff,SizeOf(buff),@lpData->ProjectFile)
				If Len(buff) Then
					If LCase(Right(buff,4))=".bas" Then
						buff=buff & Str(id)
						x=SendDlgItemMessage(hWin,IDC_CBOFIL,CB_ADDSTRING,0,Cast(LPARAM,@buff))
						x=SendDlgItemMessage(hWin,IDC_CBOFIL,CB_SETITEMDATA,x,id)
					EndIf
				EndIf
				id+=1
			Loop
			SendDlgItemMessage(hWin,IDC_CBOFIL,CB_SETCURSEL,0,0)
			buff=lpData->AppPath & "\Templates\*.rad"
			hwfd=FindFirstFile(@buff,@wfd)
			If hwfd<>INVALID_HANDLE_VALUE Then
				id=1
				While id
					id=SendDlgItemMessage(hWin,IDC_CBOTEMPLATE,CB_ADDSTRING,0,Cast(LPARAM,@wfd.cFileName))
					id=FindNextFile(hwfd,@wfd)
				Wend
			EndIf
			FindClose(hwfd)
			SendDlgItemMessage(hWin,IDC_CBOTEMPLATE,CB_SETCURSEL,0,0)
			SendDlgItemMessage(hWin,IDC_EDTPROCNAME,WM_SETTEXT,0,Cast(LPARAM,@szDialogProc))
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			If Event=BN_CLICKED Then
				Select Case id
					Case IDCANCEL
						EndDialog(hWin, 0)
						'
					Case IDOK
						EndDialog(hWin, 0)
						'
				End Select
			EndIf
			'
		Case WM_CLOSE
			EndDialog(hWin, 0)
			'
		Case WM_SIZE
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

' Returns info on what messages the addin hooks into (in an ADDINHOOKS type).
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
	hooks.hook1=HOOK_CTLDBLCLK
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	return @hooks

end function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
function DllFunction CDECL alias "DllFunction" (byval hWin as HWND,byval uMsg as UINT,byval wParam as WPARAM,byval lParam as LPARAM) as bool EXPORT

	select case uMsg
		case AIM_CTLDBLCLK
			DialogBoxParam(hInstance,Cast(ZString Ptr,IDD_DLGREALLYRAD),hWin,@ReallyRadProc,lParam)
			'
		case AIM_CLOSE
			'
	end select
	return FALSE

end function
