'Export.dlg
#Define IDD_DLGEXPORT				5600
#Define IDC_CHKFUN					1001
#Define IDC_CHKCON					1002
#Define IDC_CHKVAR					1003
#Define IDC_CHKUDT					1004
#Define IDC_CHKENU					1005
#Define IDC_CHKNME					1006
#Define IDC_CHKMAC					1007
#Define IDC_CHKCNS					1008
#Define IDC_CHKDES					1009
#Define IDC_CHKPRO					1010
#Define IDC_CHKOPR					1011

Sub ExportFunctions()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("p")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		lret=lret+Len(lret[0])+1
		If Len(lret[0]) Then
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
			lret=lret+lstrlen(lret)+1
			If lstrlen(lret) Then
				SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr("|")))
				SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
			EndIf
		EndIf
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportConstants()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("c")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportData()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("d")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
		lret=lret+Len(lret[0])+1
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportUDTs()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("s")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
		lret=lret+Len(lret[0])+1
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportEnums()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("e")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
		lret=lret+Len(lret[0])+1
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportNamespaces()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("n")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportMacros()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("m")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
		lret=lret+Len(lret[0])+1
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportConstructors()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("x")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		lret=lret+Len(lret[0])+1
		If Len(lret[0]) Then
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		EndIf
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportDestructors()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("y")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		lret=lret+Len(lret[0])+1
		If Len(lret[0]) Then
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		EndIf
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportProperties()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("z")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		lret=lret+Len(lret[0])+1
		If Len(lret[0]) Then
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		EndIf
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Sub ExportOperators()
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("o")),Cast(Integer,StrPtr(""))))
	Do While lret
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		lret=lret+Len(lret[0])+1
		If Len(lret[0]) Then
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(",")))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,lret))
		EndIf
		SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
	Loop

End Sub

Function ExportDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			'
		Case WM_CLOSE
			EndDialog(hWin, 0)
			'
		Case WM_COMMAND
			Select Case LoWord(wParam)
				Case IDOK
					ShowOutput(TRUE)
					SendMessage(ah.hout,WM_SETTEXT,0,Cast(Integer,StrPtr("")))
					nLinesOut=0
					UpdateAllTabs(6)
					If IsDlgButtonChecked(hWin,IDC_CHKFUN) Then
						ExportFunctions
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKCON) Then
						ExportConstants
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKVAR) Then
						ExportData
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKUDT) Then
						ExportUDTs
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKENU) Then
						ExportEnums
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKNME) Then
						ExportNamespaces
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKMAC) Then
						ExportMacros
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKCNS) Then
						ExportConstructors
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKDES) Then
						ExportDestructors
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKPRO) Then
						ExportProperties
					EndIf
					If IsDlgButtonChecked(hWin,IDC_CHKOPR) Then
						ExportOperators
					EndIf
					'
				Case IDCANCEL
					EndDialog(hWin, 0)
					'
			End Select
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
