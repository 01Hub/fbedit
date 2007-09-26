#define IDD_HEXFINDDLG          6300
#Define IDC_HEXFINDTEXT         1002
#define IDC_HEXREPLACESTATIC    1003
#define IDC_HEXREPLACETEXT      1004
#define IDC_HEXRBN_HEX          1006
#define IDC_HEXRBN_ASCII        1007
#define IDC_HEXRBN_DOWN         1009
#define IDC_HEXRBN_UP           1010
#define IDC_HEXBTN_REPLACE      1011
#define IDC_HEXBTN_REPLACEALL   1012

Function HexFindDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Integer id,Event

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_HEXFINDDLG)
			findvisible=hWin
			'
		Case WM_ACTIVATE
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			If Event=BN_CLICKED Then
				Select Case id
					Case IDOK
						'
					Case IDCANCEL
						SendMessage(hWin,WM_CLOSE,0,0)
						'
					Case IDC_BTN_REPLACE
						'
					Case IDC_BTN_REPLACEALL
						'
				End Select
				'
			ElseIf Event=EN_CHANGE Then
				' Update text buffers
			EndIf
			'
		Case WM_CLOSE
			DestroyWindow(hWin)
			SetFocus(ah.hred)
			'
		Case WM_DESTROY
			ah.hfind=0
			findvisible=0
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
