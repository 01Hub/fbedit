
Function ResProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim lpRESMEM As RESMEM ptr
	Dim rect As RECT
	Dim As Integer nInx,x,y
	Dim pt As Point
	Dim hMnu As HMENU
	Dim hDll As HMODULE
	Dim nBtn As Integer
	Dim tbxwt As Integer

	Select Case uMsg
		Case WM_CREATE
			lpRESMEM=MyGlobalAlloc(GMEM_FIXED,SizeOf(RESMEM))
			SetWindowLong(hWin,0,Cast(Integer,lpRESMEM))
			lpRESMEM->hResEd=CreateWindowEx(WS_EX_CLIENTEDGE,StrPtr("DLGEDITCLASS"),0,WS_CHILD Or WS_VISIBLE Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN Or WS_VSCROLL Or WS_HSCROLL,0,0,0,0,hWin,Cast(HMENU,IDC_RESEDIT),hInstance,0)
			SendMessage(lpRESMEM->hResEd,WM_SETFONT,Cast(Integer,hDlgFnt),0)
			lpRESMEM->hProject=CreateWindowEx(WS_EX_CLIENTEDGE,StrPtr("PROJECTCLASS"),0,WS_CHILD Or WS_VISIBLE Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN,0,0,0,0,hWin,Cast(HMENU,IDC_RESPROJECT),hInstance,0)
			SendMessage(lpRESMEM->hProject,WM_SETFONT,Cast(Integer,hDlgFnt),0)
			lpRESMEM->hProperty=CreateWindowEx(0,StrPtr("PROPERTYCLASS"),0,WS_CHILD Or WS_VISIBLE Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN,0,0,0,0,hWin,Cast(HMENU,IDC_RESPROPERTY),hInstance,0)
			SendMessage(lpRESMEM->hProperty,WM_SETFONT,Cast(Integer,hDlgFnt),0)
			lpRESMEM->hToolBox=CreateWindowEx(0,StrPtr("TOOLBOXCLASS"),0,WS_CHILD Or WS_VISIBLE Or WS_CLIPSIBLINGS Or WS_CLIPCHILDREN,0,0,0,0,hWin,Cast(HMENU,IDC_RESTOOLBOX),hInstance,0)
			SendMessage(lpRESMEM->hToolBox,WM_SETFONT,Cast(Integer,hDlgFnt),0)
			SetDialogOptions(hWin)
			SendMessage(lpRESMEM->hResEd,DEM_SETPOSSTATUS,Cast(Integer,ah.hsbr),0)
			nInx=1
			x=0
			While nInx<=32
				GetPrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@szNULL,@buff,260,@ad.IniFile)
				If Len(buff) Then
					hDll=Cast(HMODULE,SendMessage(lpRESMEM->hResEd,DEM_ADDCONTROL,0,Cast(Integer,@buff)))
					If hDll Then
						hCustDll(x)=hDll
						x=x+1
					EndIf
				EndIf
				nInx=nInx+1
			Wend
			'
		Case WM_DESTROY
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			GlobalFree(lpRESMEM)
			'
		Case WM_SIZE
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			GetClientRect(hWin,@rect)
			nBtn=SendMessage(lpRESMEM->hResEd,DEM_GETBUTTONCOUNT,0,0)
			tbxwt=53
			If (nBtn+1)/2*26>rect.bottom Then
				tbxwt=53+26
			EndIf
			MoveWindow(lpRESMEM->hToolBox,0,0,tbxwt,rect.bottom,TRUE)
			MoveWindow(lpRESMEM->hResEd,tbxwt,0,rect.right-180-tbxwt,rect.bottom,TRUE)
			MoveWindow(lpRESMEM->hProject,rect.right-180,0,180,rect.bottom/2,TRUE)
			MoveWindow(lpRESMEM->hProperty,rect.right-180,rect.bottom/2,180,rect.bottom/2,TRUE)
			'
		Case EM_GETMODIFY
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hProject,PRO_GETMODIFY,0,0)
			'
		Case EM_SETMODIFY
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hProject,PRO_SETMODIFY,wParam,0)
			'
		Case EM_UNDO
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hResEd,DEM_UNDO,0,0)
			'
		Case WM_CUT
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hResEd,DEM_CUT,0,0)
			'
		Case WM_COPY
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hResEd,DEM_COPY,0,0)
			'
		Case WM_PASTE
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hResEd,DEM_PASTE,0,0)
			'
		Case WM_CLEAR
			lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
			Return SendMessage(lpRESMEM->hResEd,DEM_DELETECONTROLS,0,0)
			'
		Case WM_NOTIFY
			If (GetKeyState(VK_LBUTTON) And &H80)=0 Then
				fTimer=1
			EndIf
			Return 0
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
			Return 0
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
	End Select
	Return DefWindowProc(hWin,uMsg,wParam,lParam)

End Function

