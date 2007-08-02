
#Define IDD_DLGDEBUGOPT						5100
#Define IDC_BTNDEBUGOPT						1002
#Define IDC_EDTDEBUGOPT						1001

Function DebugOptDlgProc(ByVal hWin As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As Integer
	Dim As Long id, Event
	Dim ofn As OPENFILENAME

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_DLGDEBUGOPT)
			SetDlgItemText(hWin,IDC_EDTDEBUGOPT,@ad.smakerundebug)
			'
		Case WM_CLOSE
			EndDialog(hWin, 0)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case id
				Case IDOK
					GetDlgItemText(hWin,IDC_EDTDEBUGOPT,@ad.smakerundebug,SizeOf(ad.smakerundebug))
					WritePrivateProfileString(StrPtr("Debug"),StrPtr("Debug"),@ad.smakerundebug,@ad.IniFile)
					EndDialog(hWin, 0)
					'
				Case IDCANCEL
					EndDialog(hWin, 0)
					'
				Case IDC_BTNDEBUGOPT
					RtlZeroMemory(@ofn,SizeOf(ofn))
					ofn.lStructSize=SizeOf(ofn)
					ofn.hwndOwner=hWin
					ofn.hInstance=hInstance
					ofn.lpstrFilter=@EXEFilterString
					ofn.lpstrFile=@buff
					GetDlgItemText(hWin,IDC_EDTDEBUGOPT,@buff,256)
					ofn.nMaxFile=256
					ofn.Flags=OFN_FILEMUSTEXIST Or OFN_HIDEREADONLY Or OFN_PATHMUSTEXIST
					If GetOpenFileName(@ofn) Then
						SetDlgItemText(hWin,IDC_EDTDEBUGOPT,@buff)
					EndIf
					'
			End Select
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
