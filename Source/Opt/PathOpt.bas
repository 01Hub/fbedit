
'PathOpt.dlg
#Define IDD_DLGPATHOPTION					5400
#Define IDC_EDTOPTCOMPILERPATH			1003
#Define IDC_EDTOPTPROJECTPATH				1005
#Define IDC_BTNOPTPROJECTPATH				1007
#Define IDC_BTNOPTCOMPILERPATH			1008

Function PathOptDlgProc(ByVal hWin As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			GetPrivateProfileString(StrPtr("Project"),StrPtr("Path"),@szNULL,@buff,260,@ad.IniFile)
			SetDlgItemText(hWin,IDC_EDTOPTPROJECTPATH,@buff)
			GetPrivateProfileString(StrPtr("Make"),StrPtr("fbcPath"),@szNULL,@buff,260,@ad.IniFile)
			SetDlgItemText(hWin,IDC_EDTOPTCOMPILERPATH,@buff)
			'
		Case WM_CLOSE
			EndDialog(hWin, 0)
			'
		Case WM_COMMAND
			Select Case LoWord(wParam)
				Case IDOK
					GetDlgItemText(hWin,IDC_EDTOPTPROJECTPATH,@ad.DefProjectPath,260)
					WritePrivateProfileString(StrPtr("Project"),StrPtr("Path"),@ad.DefProjectPath,@ad.IniFile)
					If Left(ad.DefProjectPath,1)="\" Then
						ad.DefProjectPath=Left(ad.AppPath,2) & ad.DefProjectPath
					EndIf
					GetDlgItemText(hWin,IDC_EDTOPTCOMPILERPATH,@ad.fbcPath,260)
					WritePrivateProfileString(StrPtr("Make"),StrPtr("fbcPath"),@ad.fbcPath,@ad.IniFile)
					If Left(ad.fbcPath,1)="\" Then
						ad.fbcPath=Left(ad.AppPath,2) & ad.fbcPath
					EndIf
					GetMakeOption
					EndDialog(hWin, 0)
					'
				Case IDCANCEL
					EndDialog(hWin, 0)
					'
				Case IDC_BTNOPTPROJECTPATH
					BrowseFolder(hWin,IDC_EDTOPTPROJECTPATH)
					'
				Case IDC_BTNOPTCOMPILERPATH
					BrowseFolder(hWin,IDC_EDTOPTCOMPILERPATH)
					'
			End Select
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
