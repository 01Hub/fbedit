
Function DumpEnumProc(ByVal hWin As HWND,ByVal lParam As LPARAM) As Boolean
	Dim buff As ZString*256
	Dim nInx As Integer
	Dim szID As ZString*256

	If GetParent(hWin)=lParam Then
		buff=""
		SendMessage(hWin,WM_GETTEXT,SizeOf(buff),Cast(LPARAM,@buff))
		if buff<>"" And buff<>"0" And buff<>"..." Then
			nInx=GetWindowLong(hWin,GWL_ID)
			If nInx<>-1 Then
				ConvertTo(@buff)
				szID=Str(nInx)
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@szID))
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr("=")))
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@buff))
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr(!"\13\10")))
			EndIf
		EndIf
	EndIf
	Return TRUE

End Function

Function DumpDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim buff As ZString*256
	Dim szID As ZString*256

	Select Case uMsg
		Case WM_INITDIALOG
'			szID=Str(lParam)
'			SendMessage(hWin,WM_GETTEXT,SizeOf(buff),Cast(LPARAM,@buff))
'			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr("[")))
'			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@szID))
'			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr("] ")))
'			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@buff))
'			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr(!"\13\10")))
			szID=Str(lParam)
			SendMessage(hWin,WM_GETTEXT,SizeOf(buff),Cast(LPARAM,@buff))
			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr("[")))
			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@szID))
			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr(!"]\13\10")))
			If buff<>"" Then
				ConvertTo(@buff)
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@szID))
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr("=")))
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@buff))
				SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,StrPtr(!"\13\10")))
			EndIf
			EnumChildWindows(hWin,Cast(ENUMWINDOWSPROC,@DumpEnumProc),Cast(LPARAM,hWin))
			SendMessage(hEdt,EM_REPLACESEL,FALSE,Cast(LPARAM,@szDivider))
			SendMessage(hWin,WM_CLOSE,NULL,NULL)
		Case WM_CLOSE
			EndDialog(hWin,NULL)
		Case Else
			Return FALSE
	End Select
	Return TRUE

End Function

Function ChildDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim buff As ZString*256
	Dim szID As ZString*256
	Dim st As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			ShowWindow(hWin,TRUE)
		Case WM_LBUTTONDOWN
			EndDialog(GetParent(hWin),NULL)
		Case Else
			Return FALSE
	End Select
	Return TRUE

End Function

Function TestContainerDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			CreateDialogParam(hInstance,Cast(ZString Ptr,lParam),hWin,@ChildDlgProc,0)
		Case WM_CLOSE
			EndDialog(hWin,NULL)
		Case WM_LBUTTONDOWN
			EndDialog(hWin,NULL)
		Case Else
			Return FALSE
	End Select
	Return TRUE

End Function

Function TestDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim buff As ZString*256
	Dim szID As ZString*256
	Dim st As Integer
	Dim id As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			st=GetWindowLong(hWin,GWL_STYLE)
			If st And WS_CHILD Then
				DialogBoxParam(hInstance,Cast(ZString Ptr,IDD_DLGTEST),hWnd,@TestContainerDlgProc,lParam)
				EndDialog(hWin,NULL)
			EndIf
			Return FALSE
		Case WM_CLOSE
			EndDialog(hWin,NULL)
		Case WM_LBUTTONDOWN
			EndDialog(hWin,NULL)
		Case Else
			Return FALSE
	End Select
	Return TRUE

End Function
