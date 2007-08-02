#Define IDD_DLGLANGUAGE		1200
#Define IDC_LSTLANGUAGE		1003

Dim Shared hLngDlg As HWND

Sub ConvertFrom(ByVal buff As ZString ptr)
	Dim x As Integer

	x=1
	While x
		x=InStr(*buff,"\t")
		If x Then
			*buff=Left(*buff,x-1) & !"\9" & Mid(*buff,x+2)
		EndIf
	Wend	
	x=1
	While x
		x=InStr(*buff,"\r")
		If x Then
			*buff=Left(*buff,x-1) & !"\13" & Mid(*buff,x+2)
		EndIf
	Wend	
	x=1
	While x
		x=InStr(*buff,"\n")
		If x Then
			*buff=Left(*buff,x-1) & !"\10" & Mid(*buff,x+2)
		EndIf
	Wend	

End Sub

Function FindString(ByVal hMem As HGLOBAL,ByVal szApp As String,ByVal szKey As String) As String
	Dim buff As ZString*512
	Dim As Integer x,y,z
	Dim lp As ZString Ptr

	If hMem Then
		buff=!"\13\10[" & szApp & !"]\13\10"
		lp=hMem
		x=InStr(*lp,buff)
		If x Then
			z=InStr(x+1,*lp,!"\13\10[")
			If z=0 Then
				z=65535
			EndIf
			buff=!"\13\10" & szKey & "="
			x=InStr(x,*lp,buff)
			If x<>0 And x<z Then
				x=x+Len(buff)
				y=InStr(x,*lp,!"\13")
				buff=Mid(*lp,x,y-x)
				ConvertFrom(@buff)
			Else
				buff=""
			EndIf
		Else
			buff=""
		EndIf
	Else
		buff=""
	EndIf
	Return buff

End Function

Sub UpdateMenuItems(ByVal hMenu As HMENU,ByVal szApp As String)
	Dim hMnu As HMENU
	Dim nPos As Integer
	Dim mii As MENUITEMINFO
	Dim buff As ZString*256
	Dim szID As ZString*256
	
	hMnu=hMenu
	nPos=0
Nxt:
	mii.cbSize=SizeOf(MENUITEMINFO)
	mii.fMask=MIIM_DATA or MIIM_ID or MIIM_SUBMENU or MIIM_TYPE
	mii.dwTypeData=@buff
	mii.cch=SizeOf(buff)
	If GetMenuItemInfo(hMnu,nPos,TRUE,@mii) Then
		If mii.wID<>0 And buff<>"(Empty)" Then
			szID=Str(mii.wID)
			buff=FindString(hLangMem,szApp,szID)
			If lstrlen(@buff) Then
				mii.fType=MFT_STRING
				SetMenuItemInfo(hMnu,nPos,TRUE,@mii)
			EndIf
			If mii.hSubMenu Then
				UpdateMenuItems(mii.hSubMenu,szApp)
			EndIf
		EndIf
		nPos+=1
		GoTo	Nxt
	EndIf

End Sub

Function DlgTranslateProc(ByVal hWin As HWND,ByVal lParam As LPARAM) As Boolean
	Dim buff As ZString*256
	Dim id As Integer

	If GetParent(hWin)=hLngDlg Then
		id=GetWindowLong(hWin,GWL_ID)
		buff=FindString(hLangMem,Str(lParam),Str(id))
		If buff<>"" Then
			SendMessage(hWin,WM_SETTEXT,0,Cast(LPARAM,@buff))
		EndIf
	EndIf
	Return TRUE

End Function

Sub TranslateDialog(ByVal hWin As HWND,ByVal id As Integer)
	Dim buff As ZString*256

	hLngDlg=hWin
	buff=FindString(hLangMem,Str(id),Str(id))
	If buff<>"" Then
		SendMessage(hWin,WM_SETTEXT,0,Cast(LPARAM,@buff))
	EndIf
	EnumChildWindows(hWin,Cast(Any Ptr,@DlgTranslateProc),id)

End Sub

Sub GetLanguageFile
	Dim buff As ZString*260
	Dim hFile As HANDLE
	Dim nSize As Integer

	buff=ad.AppPath & "\Language\" & Language
	hFile=CreateFile(buff,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0)
	If hFile<>INVALID_HANDLE_VALUE Then
		nSize=GetFileSize(hFile,NULL)
		hLangMem=GlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,nSize+1)
		ReadFile(hFile,hLangMem,nSize,@nSize,0)
		CloseHandle(hFile)
		UpdateMenuItems(ah.hmenu,"10000")
		UpdateMenuItems(ah.hcontextmenu,"20000")
	EndIf

End Sub

Function LanguageDlgProc(ByVal hWin As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As integer
	Dim id As Integer
	Dim buff As ZString*MAX_PATH
	Dim wfd As WIN32_FIND_DATA
	Dim hwfd As HANDLE
	Dim hMem As HGLOBAL
	Dim hFile As HANDLE
	Dim nSize As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_DLGLANGUAGE)
			id=256
			SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_SETTABSTOPS,1,Cast(LPARAM,@id))
			SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_ADDSTRING,0,Cast(LPARAM,StrPtr("(None)")))
			SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_SETCURSEL,0,0)
			buff=ad.AppPath & "\Language\*lng"
			hwfd=FindFirstFile(@buff,@wfd)
			If hwfd<>INVALID_HANDLE_VALUE Then
				while id
					buff=ad.AppPath & "\Language\"
					lstrcat(@buff,@wfd.cFileName)
					hMem=GlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,256*1024)
					hFile=CreateFile(buff,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0)
					If hFile<>INVALID_HANDLE_VALUE Then
						nSize=GetFileSize(hFile,NULL)
						ReadFile(hFile,hMem,nSize,@nSize,0)
						buff=FindString(hMem,"Lang","Lang")
						buff=buff & Chr(9)
						lstrcat(@buff,@wfd.cFileName)
						CloseHandle(hFile)
					EndIf
					GlobalFree(hMem)
					id=SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_ADDSTRING,0,Cast(LPARAM,@buff))
					If lstrcmpi(@Language,@wfd.cFileName)=0 Then
						SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_SETCURSEL,id,0)
					EndIf
					
					id=FindNextFile(hwfd,@wfd)
				Wend
			EndIf
			FindClose(hwfd)
			'
		Case WM_CLOSE
			EndDialog(hWin, 0)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Select Case id
				Case IDOK
					id=SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_GETCURSEL,0,0)
					SendDlgItemMessage(hWin,IDC_LSTLANGUAGE,LB_GETTEXT,id,Cast(LPARAM,@buff))
					Language=Mid(buff,InStr(buff,Chr(9))+1)
					WritePrivateProfileString(StrPtr("Language"),StrPtr("Language"),@Language,@ad.IniFile)
					EndDialog(hWin, 0)
				Case IDCANCEL
					EndDialog(hWin, 0)
			End Select
			'
		Case WM_SIZE
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

