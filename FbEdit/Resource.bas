#define IDD_DLGRESED            1300
#define IDC_RARESED             1301

Dim Shared ressize As WINSIZE=(300,170,0,52,100,100)

Function ResEdProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim rect As RECT
	Dim As Integer nInx,x,y
	Dim pt As Point
	Dim hMnu As HMENU
	Dim hDll As HMODULE
	Dim nBtn As Integer
	Dim tbxwt As Integer
	Dim lpCTLDBLCLICK As CTLDBLCLICK Ptr

	Select Case uMsg
		Case WM_INITDIALOG
			ah.hraresed=GetDlgItem(hWin,IDC_RARESED)
			SendMessage(ah.hraresed,DEM_SETSIZE,0,Cast(LPARAM,@ressize))
			SetDialogOptions(hWin)
			SendMessage(ah.hraresed,DEM_SETPOSSTATUS,Cast(Integer,ah.hsbr),0)
			nInx=1
			x=0
			While nInx<=32
				GetPrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@szNULL,@buff,260,@ad.IniFile)
				If Len(buff) Then
					hDll=Cast(HMODULE,SendMessage(ah.hraresed,DEM_ADDCONTROL,0,Cast(Integer,@buff)))
					If hDll Then
						hCustDll(x)=hDll
						x=x+1
					EndIf
				EndIf
				nInx=nInx+1
			Wend
			'
		Case WM_CLOSE
			DestroyWindow(hWin)
			'
		Case WM_DESTROY
			DestroyWindow(ah.hraresed)
			'
		Case WM_SIZE
			GetClientRect(hWin,@rect)
			MoveWindow(ah.hraresed,0,0,rect.right,rect.bottom,TRUE)
'		Case EM_GETMODIFY
'			Return SendMessage(ah.hraresed,PRO_GETMODIFY,0,0)
'			'
		Case EM_SETMODIFY
			SendMessage(ah.hraresed,PRO_SETMODIFY,wParam,0)
			'
		Case EM_UNDO
			SendMessage(ah.hraresed,DEM_UNDO,0,0)
			'
		Case EM_REDO
			SendMessage(ah.hraresed,DEM_REDO,0,0)
			'
		Case WM_CUT
			SendMessage(ah.hraresed,DEM_CUT,0,0)
			'
		Case WM_COPY
			SendMessage(ah.hraresed,DEM_COPY,0,0)
			'
		Case WM_PASTE
			SendMessage(ah.hraresed,DEM_PASTE,0,0)
			'
		Case WM_CLEAR
			SendMessage(ah.hraresed,DEM_DELETECONTROLS,0,0)
			'
		Case WM_NOTIFY
			lpCTLDBLCLICK=Cast(CTLDBLCLICK Ptr,lParam)
			If (GetKeyState(VK_LBUTTON) And &H80)=0 Then
				fTimer=1
			EndIf
			If lpCTLDBLCLICK->nmhdr.code=NM_DBLCLK Then
				'TextToOutput(*lpCTLDBLCLICK->lpCtlName)
				'TextToOutput(*lpCTLDBLCLICK->lpDlgName)
				CallAddins(hWin,AIM_CTLDBLCLK,0,lParam,HOOK_CTLDBLCLK)
			EndIf
			'
		Case WM_CONTEXTMENU
			If lParam=-1 Then
				GetWindowRect(hWin,@rect)
				pt.x=rect.left+90
				pt.y=rect.top+90
			Else
				pt.x=lParam And &HFFFF
				pt.y=lParam Shr 16
			EndIf
			hMnu=GetSubMenu(ah.hcontextmenu,4)
			TrackPopupMenu(hMnu,TPM_LEFTALIGN Or TPM_RIGHTBUTTON,pt.x,pt.y,0,ah.hwnd,0)
		Case WM_SHOWWINDOW
			If ah.hfullscreen<>0 And fInUse=FALSE Then
				fInUse=TRUE
				If wParam Then
					If GetParent(hWin)<>ah.hfullscreen Then
						SetFullScreen(hWin)
					EndIf
				Else
					If GetParent(hWin)=ah.hfullscreen Then
						SetParent(hWin,ah.hwnd)
					EndIf
				EndIf
				fInUse=FALSE
			EndIf
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
