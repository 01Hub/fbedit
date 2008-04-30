
'TabOptions.dlg
#Define IDD_TABOPTIONS						2000
#Define IDC_TABOPT							2001

'TabOpt1.dlg
#Define IDD_TABOPT1							2100
#Define IDC_RBNEXPOPT1						2101
#Define IDC_RBNEXPOPT2						2102
#Define IDC_EDTEXPOPT						2113
#Define IDC_RBNEXPOPT3						2103
#Define IDC_RBNEXPORTOUT					2112
#Define IDC_RBNEXPORTCLIP					2111
#Define IDC_RBNEXPORTFILE					2110
#Define IDC_CHKAUTOEXPORT					2114
#Define IDC_RBNEXPOPT4						2104

'TabOpt2.dlg
#Define IDD_TABOPT2							2200
#Define IDC_BTNCUSTDEL						2205
#Define IDC_BTNCUSTADD						2204
#Define IDC_GRDCUST							2201

'TabOpt3.dlg
#Define IDD_TABOPT3							2300
#Define IDC_EDTY								4005
#Define IDC_EDTX								4008
#Define IDC_CHKSNAPGRID						4002
#Define IDC_CHKSHOWGRID						4003
#Define IDC_UDNY								4004
#Define IDC_UDNX								4007
#Define IDC_CHKSHOWTIP						4001
#Define IDC_STCGRIDCOLOR					4006
#Define IDC_CHKGRIDLINE						4009
#Define IDC_CHKSTYLEHEX						4010
#Define IDC_CHKSIZETOFONT					4011
#Define IDC_CHKSIMPLEPROPERTY				4012
#Define IDC_CHKDEFSTATIC					4013

Dim Shared hTabOpt As HWND
Dim Shared hTabDlg(3) As HWND
Dim Shared SelTab As Integer
Dim Shared grdcol As Integer
Dim Shared hGrdBr As HBRUSH

Function TabOpt1Proc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_TABOPT1)
			CheckRadioButton(hWin,IDC_RBNEXPOPT1,IDC_RBNEXPOPT4,IDC_RBNEXPOPT1+nmeexp.nType)
			CheckRadioButton(hWin,IDC_RBNEXPORTFILE,IDC_RBNEXPORTOUT,IDC_RBNEXPORTFILE+nmeexp.nOutput)
			SendDlgItemMessage(hWin,IDC_EDTEXPOPT,EM_LIMITTEXT,MAX_PATH,0)
			SetDlgItemText(hWin,IDC_EDTEXPOPT,nmeexp.szFileName)
			CheckDlgButton(hWin,IDC_CHKAUTOEXPORT,nmeexp.fAuto)
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

Function TabOpt2Proc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id,Event
	Dim nInx As Integer
	Dim ofn As OPENFILENAME
	Dim hGrd As HWND
	Dim clmn As COLUMN
	Dim row(1) As Integer
	Dim x As Integer
	Dim lpGRIDNOTIFY As GRIDNOTIFY Ptr

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_TABOPT2)
			hGrd=GetDlgItem(hWin,IDC_GRDCUST)
			SendMessage(hGrd,WM_SETFONT,SendMessage(hWin,WM_GETFONT,0,0),FALSE)
			clmn.colwt=300
			clmn.lpszhdrtext=StrPtr("Custom control")
			clmn.halign=GA_ALIGN_LEFT
			clmn.calign=GA_ALIGN_LEFT
			clmn.ctype=TYPE_EDITBUTTON
			clmn.ctextmax=128
			clmn.lpszformat=0
			clmn.himl=0
			clmn.hdrflag=0
			SendMessage(hGrd,GM_ADDCOL,0,Cast(LPARAM,@clmn))
			' Style mask
			clmn.colwt=80
			clmn.lpszhdrtext=StrPtr("Style mask")
			clmn.halign=GA_ALIGN_LEFT
			clmn.calign=GA_ALIGN_LEFT
			clmn.ctype=TYPE_EDITTEXT
			clmn.ctextmax=16
			clmn.lpszformat=0
			clmn.himl=0
			clmn.hdrflag=0
			SendMessage(hGrd,GM_ADDCOL,0,Cast(LPARAM,@clmn))
			nInx=1
			While nInx<=32
				GetPrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@szNULL,@buff,260,@ad.IniFile)
				If Len(buff) Then
					x=InStr(buff,",")
					If x Then
						buff[x-1]=NULL
						row(0)=Cast(Integer,@buff)
						row(1)=Cast(Integer,@buff[x])
					Else
						row(0)=Cast(Integer,@buff)
						row(1)=0
					EndIf
					SendMessage(hGrd,GM_ADDROW,0,Cast(LPARAM,@row(0)))
				EndIf
				nInx=nInx+1
			Wend
			'
		Case WM_COMMAND
			hGrd=GetDlgItem(hWin,IDC_GRDCUST)
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case Event
				Case BN_CLICKED
					Select Case id
						Case IDC_BTNCUSTADD
							nInx=SendMessage(hGrd,GM_ADDROW,0,0)
							SendMessage(hGrd,GM_SETCURSEL,0,nInx)
							SetFocus(hGrd)
							'
						Case IDC_BTNCUSTDEL
							nInx=SendMessage(hGrd,GM_GETCURROW,0,0)
							SendMessage(hGrd,GM_DELROW,nInx,0)
							SendMessage(hGrd,GM_SETCURSEL,0,nInx)
							SetFocus(hGrd)
							'
					End Select
					'
			End Select
			'
		Case WM_NOTIFY
			hGrd=GetDlgItem(hWin,IDC_GRDCUST)
			lpGRIDNOTIFY=Cast(GRIDNOTIFY Ptr,lParam)
			If lpGRIDNOTIFY->nmhdr.hwndFrom=hGrd Then
				If lpGRIDNOTIFY->nmhdr.code=GN_HEADERCLICK Then
					' Sort the grid by column, invert sorting order
					SendMessage(hGrd,GM_COLUMNSORT,lpGRIDNOTIFY->col,SORT_INVERT)
				ElseIf lpGRIDNOTIFY->nmhdr.code=GN_BUTTONCLICK Then
					' Cell button clicked
					ofn.lStructSize=SizeOf(ofn)
					ofn.hwndOwner=hWin
					ofn.hInstance=hInstance
					ofn.lpstrFilter=@DLLFilterString
					ofn.lpstrFile=@buff
					lstrcpy(@buff,Cast(ZString Ptr,lpGRIDNOTIFY->lpdata))
					ofn.nMaxFile=MAX_PATH
					ofn.Flags=OFN_FILEMUSTEXIST Or OFN_HIDEREADONLY Or OFN_PATHMUSTEXIST
					' Show the Open dialog
					If GetOpenFileName(@ofn) Then
						lstrcpy(Cast(ZString Ptr,lpGRIDNOTIFY->lpdata),@buff)
						lpGRIDNOTIFY->fcancel=FALSE
					Else
						lpGRIDNOTIFY->fcancel=TRUE
					EndIf
				EndIf
			EndIf
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

Function TabOpt3Proc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim lpDRAWITEMSTRUCT As DRAWITEMSTRUCT Ptr
	Dim cc As ChooseColor

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_TABOPT3)
			SendDlgItemMessage(hWin,IDC_UDNX,UDM_SETRANGE,0,&H00020014)	' Set range
			SendDlgItemMessage(hWin,IDC_UDNX,UDM_SETPOS,0,grdsize.x)		' Set default value
			SendDlgItemMessage(hWin,IDC_UDNY,UDM_SETRANGE,0,&H00020014)	' Set range
			SendDlgItemMessage(hWin,IDC_UDNY,UDM_SETPOS,0,grdsize.y)		' Set default value
			CheckDlgButton(hWin,IDC_CHKSHOWGRID,grdsize.show)
			CheckDlgButton(hWin,IDC_CHKSNAPGRID,grdsize.snap)
			CheckDlgButton(hWin,IDC_CHKSHOWTIP,grdsize.tips)
			CheckDlgButton(hWin,IDC_CHKGRIDLINE,grdsize.line)
			CheckDlgButton(hWin,IDC_CHKSTYLEHEX,grdsize.stylehex)
			CheckDlgButton(hWin,IDC_CHKSIZETOFONT,grdsize.sizetofont)
			CheckDlgButton(hWin,IDC_CHKSIMPLEPROPERTY,grdsize.simple)
			CheckDlgButton(hWin,IDC_CHKDEFSTATIC,grdsize.defstatic)
			'
		Case WM_DRAWITEM
			lpDRAWITEMSTRUCT=Cast(DRAWITEMSTRUCT Ptr,lParam)
			FillRect(lpDRAWITEMSTRUCT->hDC,@lpDRAWITEMSTRUCT->rcItem,hGrdBr)
		Case WM_COMMAND
			If wParam=IDC_STCGRIDCOLOR Then
				cc.lStructSize=SizeOf(ChooseColor)
				cc.hwndOwner=hWin
				cc.hInstance=Cast(Any Ptr,hInstance)
				cc.lpCustColors=Cast(Any Ptr,@custcol)
				cc.Flags=CC_FULLOPEN Or CC_RGBINIT
				cc.lCustData=0
				cc.lpfnHook=0
				cc.lpTemplateName=0
				cc.rgbResult=grdcol
				If ChooseColor(@cc) Then
					DeleteObject(hGrdBr)
					grdcol=cc.rgbResult
					hGrdBr=CreateSolidBrush(grdcol)
					InvalidateRect(GetDlgItem(hWin,IDC_STCGRIDCOLOR),NULL,TRUE)
				EndIf
			EndIf
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

Sub SetDialogOptions(ByVal hWin As HWND)
	Dim st As Integer

	lstrcpy(@buff,nmeexp.szFileName)
	SendMessage(ah.hraresed,PRO_SETEXPORT,(nmeexp.nOutput Shl 16)+nmeexp.nType,Cast(Integer,@buff))
	SendMessage(ah.hraresed,DEM_SETGRIDSIZE,(grdsize.y Shl 16) +grdsize.x,(grdsize.line Shl 24)+grdsize.color)
	st=GetWindowLong(ah.hraresed,GWL_STYLE)
	st=st And (-1 Xor (DES_GRID Or DES_SNAPTOGRID Or DES_TOOLTIP Or DES_STYLEHEX Or DES_SIZETOFONT Or DES_NODEFINES Or DES_SIMPLEPROPERTY Or DES_DEFIDC_STATIC))
	If grdsize.show Then
		st=st Or DES_GRID
	EndIf
	If grdsize.snap Then
		st=st Or DES_SNAPTOGRID
	EndIf
	If grdsize.tips Then
		st=st Or DES_TOOLTIP
	EndIf
	If grdsize.stylehex Then
		st=st Or DES_STYLEHEX
	EndIf
	If grdsize.sizetofont Then
		st=st Or DES_SIZETOFONT
	EndIf
	If grdsize.nodefines Then
		st=st Or DES_NODEFINES
	EndIf
	If grdsize.simple Then
		st=st Or DES_SIMPLEPROPERTY
	EndIf
	If grdsize.defstatic Then
		st=st Or DES_DEFIDC_STATIC
	EndIf
	SetWindowLong(ah.hraresed,GWL_STYLE,st)

End Sub

Function TabOptionsProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id, Event
	Dim ts As TCITEM
	Dim nInx As Integer
	Dim lpNMHDR As NMHDR Ptr

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_TABOPTIONS)
			grdcol=grdsize.color
			hGrdBr=CreateSolidBrush(grdcol)
			' Create the tabs
			hTabOpt=GetDlgItem(hWin,IDC_TABOPT)
			ts.mask=TCIF_TEXT
			ts.iImage=-1
			ts.lParam=0
			ts.pszText=StrPtr("Exports")
			SendMessage(hTabOpt,TCM_INSERTITEM,0,Cast(Integer,@ts))
			ts.pszText=StrPtr("Custom controls")
			SendMessage(hTabOpt,TCM_INSERTITEM,1,Cast(Integer,@ts))
			ts.pszText=StrPtr("Behaviour")
			SendMessage(hTabOpt,TCM_INSERTITEM,2,Cast(Integer,@ts))
			' Create the tab dialogs
			hTabDlg(0)=CreateDialogParam(hInstance,Cast(ZString Ptr,IDD_TABOPT1),hTabOpt,@TabOpt1Proc,0)
			hTabDlg(1)=CreateDialogParam(hInstance,Cast(ZString Ptr,IDD_TABOPT2),hTabOpt,@TabOpt2Proc,0)
			hTabDlg(2)=CreateDialogParam(hInstance,Cast(ZString Ptr,IDD_TABOPT3),hTabOpt,@TabOpt3Proc,0)
			SelTab=0
			'
		Case WM_NOTIFY
			lpNMHDR=Cast(NMHDR Ptr,lParam)
			If lpNMHDR->code=TCN_SELCHANGE Then
				' Tab selection
				id=SendMessage(hTabOpt,TCM_GETCURSEL,0,0)
				If id<>SelTab Then
					ShowWindow(hTabDlg(SelTab),SW_HIDE)
					ShowWindow(hTabDlg(id),SW_SHOWDEFAULT)
					SelTab=id
				EndIf
			EndIf
		Case WM_CLOSE
			DeleteObject(hGrdBr)
			EndDialog(hWin,0)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case id
				Case IDOK
					Select Case TRUE
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT1)
							nmeexp.nType=0
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT2)
							nmeexp.nType=1
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT3)
							nmeexp.nType=2
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT4)
							nmeexp.nType=3
					End Select
					Select Case TRUE
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPORTFILE)
							nmeexp.nOutput=0
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPORTCLIP)
							nmeexp.nOutput=1
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPORTOUT)
							nmeexp.nOutput=2
					End Select
					GetDlgItemText(hTabDlg(0),IDC_EDTEXPOPT,@buff,260)
					lstrcpyn(nmeexp.szFileName,buff,32)
					nmeexp.fAuto=IsDlgButtonChecked(hTabDlg(0),IDC_CHKAUTOEXPORT)
					SaveToIni(StrPtr("Resource"),StrPtr("Export"),"4440",@nmeexp,FALSE)
					grdsize.x=GetDlgItemInt(hTabDlg(2),IDC_EDTX,NULL,FALSE)
					grdsize.y=GetDlgItemInt(hTabDlg(2),IDC_EDTY,NULL,FALSE)
					grdsize.show=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSHOWGRID)
					grdsize.snap=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSNAPGRID)
					grdsize.tips=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSHOWTIP)
					grdsize.line=IsDlgButtonChecked(hTabDlg(2),IDC_CHKGRIDLINE)
					grdsize.stylehex=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSTYLEHEX)
					grdsize.sizetofont=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSIZETOFONT)
					grdsize.simple=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSIMPLEPROPERTY)
					grdsize.defstatic=IsDlgButtonChecked(hTabDlg(2),IDC_CHKDEFSTATIC)
					grdsize.color=grdcol
					SaveToIni(StrPtr("Resource"),StrPtr("Grid"),"444444444444",@grdsize,FALSE)
					SetDialogOptions(ah.hres)
					buff=String(32,0)
					WritePrivateProfileSection(StrPtr("CustCtrl"),@buff,@ad.IniFile)
					nInx=0
					While SendDlgItemMessage(hTabDlg(1),IDC_GRDCUST,GM_GETROWCOUNT,0,0)>nInx
						SendDlgItemMessage(hTabDlg(1),IDC_GRDCUST,GM_GETCELLDATA,nInx Shl 16,Cast(LPARAM,@buff))
						buff &=","
						SendDlgItemMessage(hTabDlg(1),IDC_GRDCUST,GM_GETCELLDATA,(nInx Shl 16)+1,Cast(LPARAM,@buff[Len(buff)]))
						nInx=nInx+1
						WritePrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@buff,@ad.IniFile)
					Wend
					SendMessage(hWin,WM_CLOSE,0,0)
					'
				Case IDCANCEL
					SendMessage(hWin,WM_CLOSE,0,0)
					'
			End Select
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
