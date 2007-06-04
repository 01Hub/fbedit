
Sub DelTab(ByVal hWin As HWND)
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer
	Dim x As Integer

	tci.mask=TCIF_PARAM
	i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
	If i>=0 Then
		curtab=-1
		prevtab=-1
		SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci))
		lpTABMEM=Cast(TABMEM ptr,tci.lParam)
		CallAddins(ah.hwnd,AIM_FILECLOSE,0,Cast(LPARAM,lpTABMEM->filename),HOOK_FILECLOSE)
		If lpTABMEM->profileinx Then
			WriteProjectFileInfo(lpTABMEM->hedit,lpTABMEM->profileinx,FALSE)
		EndIf
		SendMessage(ah.hpr,PRM_DELPROPERTY,Cast(Integer,lpTABMEM->hedit),0)
		If lpTABMEM->hedit<>ah.hres Then
			x=0
			While x<16
				If fdc(x).hwnd=lpTABMEM->hedit Then
					fdc(x).hwnd=Cast(HWND,-1)
				EndIf
				x=x+1
			Wend
			DestroyWindow(lpTABMEM->hedit)
		Else
			ShowWindow(lpTABMEM->hedit,SW_HIDE)
		EndIf
		ah.hpane(1)=0
		If lpTABMEM->hedit=ah.hpane(0) Then
			ah.hpane(0)=0
		EndIf
		GlobalFree(lpTABMEM)
		SendMessage(ah.htabtool,TCM_DELETEITEM,i,0)
		If SendMessage(ah.htabtool,TCM_GETITEMCOUNT,0,0) Then
			SendMessage(ah.htabtool,TCM_SETCURSEL,i,0)
			If SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)=-1 Then
				SendMessage(ah.htabtool,TCM_SETCURSEL,i-1,0)
			EndIf
			tci.mask=TCIF_PARAM
			SendMessage(ah.htabtool,TCM_GETITEM,SendMessage(ah.htabtool,TCM_GETCURSEL,0,0),Cast(Integer,@tci))
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			SelectTab(ah.hwnd,lpTABMEM->hedit,0)
		Else
			ShowWindow(ah.htabtool,SW_HIDE)
			ShowWindow(ah.hshp,SW_SHOWNA)
			ah.hred=0
			If ah.hfullscreen Then
				DestroyWindow(ah.hfullscreen)
			EndIf
			ad.filename=""
			ah.hpane(0)=0
			ah.hpane(1)=0
			SetWinCaption
		EndIf
		SendMessage(ah.hwnd,WM_SIZE,0,0)
	EndIf
	SendMessage(ah.hpr,PRM_REFRESHLIST,0,0)
	HideList()

End Sub

Sub AddTab(hEdt As HWND,ByVal lpFileName As String)
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer
	Dim x As Integer
	Dim hFile As HANDLE

	i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
	buff=lpFileName
	Do While InStr(buff,"\")
		buff=Mid(buff,InStr(buff,"\")+1)
	Loop
	lpTABMEM=MyGlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,SizeOf(TABMEM))
	lpTABMEM->hedit=hEdt
	lpTABMEM->filename=lpFileName
	If fProject Then
		lpTABMEM->profileinx=IsProjectFile(lpFileName)
	Else
		lpTABMEM->profileinx=0
	EndIf
	' Set file time
	hFile=CreateFile(lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL)
	If hFile<>INVALID_HANDLE_VALUE Then
		GetFileTime(hFile,NULL,NULL,@lpTABMEM->ft)
		CloseHandle(hFile)
	EndIf
	tci.mask=TCIF_TEXT Or TCIF_PARAM Or TCIF_IMAGE
	tci.pszText=@buff
	If lpTABMEM->profileinx>1000 Then
		tci.iImage=6
	Else
		tci.iImage=GetFileImg(buff)
	EndIf
	tci.lParam=Cast(LPARAM,lpTABMEM)
	x=SendMessage(ah.htabtool,TCM_INSERTITEM,999,Cast(Integer,@tci))
	ShowWindow(ah.htabtool,SW_SHOWNA)
	If ah.hpane(0)=0 Then
		ShowWindow(ah.hshp,SW_HIDE)
	Else
		ah.hpane(1)=hEdt
	EndIf
	SelectTab(ah.hwnd,hEdt,0)
	fTimer=1

End Sub

Sub UpdateTab()
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer

	i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
	tci.mask=TCIF_PARAM
	SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci))
	lpTABMEM=Cast(TABMEM ptr,tci.lParam)
	buff=ad.filename
	Do While InStr(buff,"\")
		buff=Mid(buff,InStr(buff,"\")+1)
	Loop
	lpTABMEM->filename=ad.filename
	tci.mask=TCIF_TEXT
	tci.pszText=@buff
	SendMessage(ah.htabtool,TCM_SETITEM,i,Cast(Integer,@tci))

End Sub

Sub SelectTab(ByVal hWin As HWND,ByVal hEdit As HWND,ByVal nInx As Integer)
	Dim tci As TCITEM
	Dim hOld As HWND
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer

	tci.mask=TCIF_PARAM
	i=0
	While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			If (lpTABMEM->hedit=hEdit And hEdit<>0) Or (lpTABMEM->profileinx=nInx And nInx<>0) Then
				SendMessage(ah.htabtool,TCM_SETCURSEL,i,0)
				hOld=ah.hred
				ah.hred=lpTABMEM->hedit
				ad.filename=lpTABMEM->filename
				SendMessage(hWin,WM_SIZE,0,0)
				ShowWindow(ah.hred,SW_SHOWNA)
				SetWinCaption
				If hOld<>ah.hpane(0) And ah.hred<>ah.hpane(0) And hOld<>ah.hred Then
					ShowWindow(hOld,SW_HIDE)
				EndIf
				ShowWindow(ah.htt,SW_HIDE)
				HideList()
				If ah.hpane(0)<>0 And ah.hred<>ah.hpane(0) Then
					If ah.hred<>ah.hpane(1) Then
						ShowWindow(ah.hpane(1),SW_HIDE)
					EndIf
					ah.hpane(1)=ah.hred
				EndIf
				SendMessage(ah.hwnd,WM_SIZE,0,0)
				SetFocus(lpTABMEM->hedit)
				Exit While
			EndIf
		Else
			If nInx Then
				OpenProjectFile(nInx)
			EndIf
			Exit While
		EndIf
		i=i+1
	Wend
End Sub

Sub NextTab(ByVal fPrev As Boolean)
	Dim n As Integer
	Dim i As Integer
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr

	n=SendMessage(ah.htabtool,TCM_GETITEMCOUNT,0,0)
	If n>1 Then
		i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
		If fPrev Then
			i=i-1
			If i<0 Then
				i=n-1
			EndIf
		Else
			i=i+1
			If i=n Then
				i=0
			EndIf
		EndIf
		tci.mask=TCIF_PARAM
		SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci))
		lpTABMEM=Cast(TABMEM ptr,tci.lParam)
		SelectTab(ah.hwnd,lpTABMEM->hedit,0)
	EndIf

End Sub

Sub SwitchTab()
	Dim n As Integer
	Dim i As Integer
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr

	n=SendMessage(ah.htabtool,TCM_GETITEMCOUNT,0,0)
	If n>1 Then
		i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
		tci.mask=TCIF_PARAM
		If SendMessage(ah.htabtool,TCM_GETITEM,prevtab,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			SelectTab(ah.hwnd,lpTABMEM->hedit,0)
		EndIf
	EndIf

End Sub

Function CreateEdit(ByVal sFile As String) As HWND
	Dim hCtl As HWND
	Dim hTmp As HWND
	Dim st As Integer
	Dim tpe As Integer

	hCtl=ah.hred
	tpe=FileType(sFile)
	If tpe=2 And (GetKeyState(VK_CONTROL) And &H80)=0 And fNoResMode=FALSE Then
		hTmp=IsResOpen
		If hTmp Then
			SelectTab(ah.hwnd,hTmp,0)
			If WantToSave(ah.hred)=FALSE Then
				ReadTheFile(ah.hred,sFile)
				UpdateTab
				SetWinCaption
			EndIf
			Return 0
		Else
			hTmp=ah.hres
		EndIf
	Else
		st=WS_CHILD Or WS_VISIBLE Or WS_CLIPCHILDREN Or WS_CLIPSIBLINGS Or STYLE_SCROLLTIP Or STYLE_DRAGDROP Or STYLE_AUTOSIZELINENUM' Or STYLE_NOBACKBUFFER
		If tpe=0 Then
			st=st Or STYLE_NOHILITE
		EndIf
		hTmp=CreateWindowEx(WS_EX_CLIENTEDGE,StrPtr("RAEDIT"),NULL,st,0,0,0,0,ah.hwnd,Cast(Any ptr,IDC_RAEDIT),hInstance,0)
		UpdateEditOption(hTmp)
		If tpe=2 Then
			SendMessage(hTmp,REM_SETWORDGROUP,0,1)
		ElseIf tpe=1 Then
			SetWindowLong(hTmp,GWL_ID,IDC_CODEED)
			SetWindowLong(hTmp,GWL_USERDATA,2)
		Else
			SendMessage(hTmp,REM_SETWORDGROUP,0,15)
		EndIf
		SendMessage(hTmp,WM_SETTEXT,0,Cast(Integer,StrPtr("")))
		SendMessage(hTmp,EM_SETMODIFY,FALSE,0)
		lpOldParEditProc=Cast(Any ptr,SetWindowLong(hTmp,GWL_WNDPROC,Cast(Integer,@ParEditProc)))
		lpOldEditProc=Cast(Any ptr,SendMessage(hTmp,REM_SUBCLASS,0,Cast(Integer,@EditProc)))
	EndIf
	If edtopt.linenumbers Then
		CheckDlgButton(hTmp,-2,TRUE)
		SendMessage(hTmp,WM_COMMAND,-2,0)
	EndIf
	Return hTmp

End Function

Sub SetFileInfo(ByVal hWin As HWND,ByVal sFile As String)
	Dim nInx As Integer
	Dim pfi As PFI

	If fProject Then
		nInx=IsProjectFile(sFile)
		ReadProjectFileInfo(nInx,@pfi)
		SetProjectFileInfo(hWin,@pfi)
	EndIf

End Sub

Sub OpenTheFile(ByVal sFile As String)
	Dim sType As String
	Dim sItem As ZString*260
	Dim x As Integer
	Dim nInx As Integer
	Dim hTmp As HWND

	If FileType(sFile)=5 Then
		If fProject Then
			If CloseProject=FALSE Then
				Exit Sub
			EndIf
		EndIf
		ad.filename=sFile
		ad.ProjectFile=ad.filename
		OpenProject
		fTimer=1
		s=String(8192,!"\0")
	ElseIf IsFileOpen(ah.hwnd,sFile,TRUE)=FALSE Then
		If CallAddins(ah.hwnd,AIM_FILEOPEN,0,Cast(LPARAM,@sFile),HOOK_FILEOPEN) Then
			Exit Sub
		EndIf
		If fProject Then
			If IsProjectFile(sFile)=0 Then
				AddMruFile(sFile)
			EndIf
		Else
			AddMruFile(sFile)
		EndIf
		x=InStr(sFile,".")
		If x Then
			sType=Mid(sFile,x) & "."
		Else
			sType=".xyz."
		EndIf
		nInx=1
		Do While TRUE
			GetPrivateProfileString(StrPtr("Open"),Str(nInx),@szNULL,@sItem,SizeOf(sItem),@ad.IniFile)
			If Len(sItem) Then
				If InStr(sItem,sType) Then
					sItem=Mid(sItem,InStr(sItem,",")+1)
					buff="""" & sFile & """"
					ShellExecute(ah.hwnd,NULL,@sItem,@buff,0,SW_SHOWDEFAULT)
					Exit Sub
				EndIf
			Else
				Exit Do
			EndIf
			nInx=nInx+1
		Loop
		' Open the file
		hTmp=CreateEdit(sFile)
		If hTmp Then
			ad.filename=sFile
			AddTab(hTmp,ad.filename)
			ReadTheFile(ah.hred,ad.filename)
			SetFileInfo(ah.hred,ad.filename)
			SetFocus(ah.hred)
		EndIf
	EndIf

End Sub

Sub OpenAFile(ByVal hWin As HWND)
	Dim ofn As OPENFILENAME
	Dim hMem As HGLOBAL
	Dim i As Integer
	Dim pth As ZString*260
	Dim sFile As ZString*260
	Dim s As ZString*260
	Dim hTmp As HWND

	hMem=MyGlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,32*1024)
	ofn.lStructSize=SizeOf(OPENFILENAME)
	ofn.hwndOwner=GetOwner
	ofn.hInstance=hInstance
	ofn.lpstrFile=Cast(ZString ptr,hMem)
	ofn.nMaxFile=32*1024
	ofn.lpstrFilter=StrPtr(ALLFilterString)
	ofn.Flags=OFN_FILEMUSTEXIST Or OFN_HIDEREADONLY Or OFN_PATHMUSTEXIST Or OFN_ALLOWMULTISELECT Or OFN_EXPLORER
	If GetOpenFileName(@ofn) Then
		lstrcpy(@pth,Cast(ZString ptr,hMem))
		i=Len(pth)+1
		lstrcpy(@s,Cast(ZString ptr,hMem+i))
		If Asc(s)=0 Then
			' Open single file
			OpenTheFile(pth)
		Else
			' Open multiple files
			Do While Asc(s)<>0
				sFile=pth & "\" & s
				hTmp=CreateEdit(sFile)
				AddTab(hTmp,sFile)
				ReadTheFile(hTmp,sFile)
				i=i+Len(s)+1
				lstrcpy(@s,Cast(ZString ptr,hMem+i))
			Loop
		EndIf
	EndIf
	GlobalFree(hMem)

End Sub

Function SaveFileAs(ByVal hWin As HWND) As Boolean
	Dim ofn As OPENFILENAME

	ofn.lStructSize=SizeOf(OPENFILENAME)
	If hWin=ah.hwnd Then
		ofn.hwndOwner=GetOwner
	Else
		ofn.hwndOwner=hWin
	EndIf
	ofn.hInstance=hInstance
	buff=ad.filename
	ofn.lpstrFile=StrPtr(buff)
	ofn.nMaxFile=260
	ofn.lpstrDefExt=StrPtr("bas")
	ofn.lpstrFilter=StrPtr(ALLFilterString)
	ofn.Flags=OFN_HIDEREADONLY Or OFN_PATHMUSTEXIST Or OFN_OVERWRITEPROMPT
	If GetSaveFileName(@ofn) Then
		ad.filename=buff
		WriteTheFile(ah.hred,ad.filename)
		UpdateTab
		SetWinCaption
		Return TRUE
	EndIf
	Return FALSE

End Function

Function WantToSave(ByVal hWin As HWND) As Boolean

	If ah.hred Then
		If SendMessage(ah.hred,EM_GETMODIFY,0,0) Then
			Select Case  MessageBox(hWin,"Want to save changes?",@szAppName,MB_YESNOCANCEL + MB_ICONQUESTION)
				Case IDYES
					If Left(ad.filename,10)="(Untitled)" Then
						Return SaveFileAs(hWin) Xor TRUE
					Else
						WriteTheFile(ah.hred,ad.filename)
					EndIf
					'
				Case IDCANCEL
					Return TRUE
					'
			End Select
		EndIf
	EndIf
	Return FALSE

End Function

Sub UnlockAllTabs()
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer
	
	tci.mask=TCIF_PARAM
	i=0
	While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			SendMessage(lpTABMEM->hedit,REM_SETLOCK,FALSE,0)
		Else
			Exit while
		EndIf
		i+=1
	Wend
	
End Sub

Function CloseAllTabs(ByVal hWin As HWND,ByVal fProjectClose As Boolean,ByVal hWinDontClose As HWND) As Boolean
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer
	Dim x As Integer

	tci.mask=TCIF_PARAM
	i=0
	While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			If lpTABMEM->hedit<>hWinDontClose And SendMessage(lpTABMEM->hedit,REM_GETLOCK,0,0)<>1 Then
				ShowWindow(ah.hred,SW_HIDE)
				ah.hred=lpTABMEM->hedit
				ad.filename=lpTABMEM->filename
				SendMessage(hWin,WM_SIZE,0,0)
				ShowWindow(ah.hred,SW_SHOW)
				SendMessage(ah.htabtool,TCM_SETCURSEL,i,0)
				SetWinCaption
				If WantToSave(hWin) Then
					Return TRUE
				EndIf
				CallAddins(ah.hwnd,AIM_FILECLOSE,0,Cast(LPARAM,lpTABMEM->filename),HOOK_FILECLOSE)
				If lpTABMEM->profileinx Then
					WriteProjectFileInfo(lpTABMEM->hedit,lpTABMEM->profileinx,fProjectClose)
				EndIf
				SendMessage(ah.hpr,PRM_DELPROPERTY,Cast(Integer,lpTABMEM->hedit),0)
				If lpTABMEM->hedit<>ah.hres Then
					x=0
					While x<16
						If fdc(x).hwnd=lpTABMEM->hedit Then
							fdc(x).hwnd=Cast(HWND,-1)
						EndIf
						x=x+1
					Wend
					DestroyWindow(lpTABMEM->hedit)
				Else
					ShowWindow(lpTABMEM->hedit,SW_HIDE)
				EndIf
				GlobalFree(lpTABMEM)
				SendMessage(ah.htabtool,TCM_DELETEITEM,i,0)
				i=i-1
			EndIf
		Else
			Exit While
		EndIf
		i=i+1
	Wend
	If hWinDontClose Then
		SelectTab(ah.hwnd,hWinDontClose,0)
	ElseIf SendMessage(ah.htabtool,TCM_GETITEMCOUNT,0,0) Then
		SendMessage(ah.htabtool,TCM_GETITEM,0,Cast(Integer,@tci))
		lpTABMEM=Cast(TABMEM ptr,tci.lParam)
		SelectTab(ah.hwnd,lpTABMEM->hedit,0)
		' don't close project
		Return TRUE
	Else
		ShowWindow(ah.htabtool,SW_HIDE)
		curtab=-1
		prevtab=-1
		ah.hred=0
		ShowWindow(ah.hshp,SW_SHOWNA)
		If ah.hfullscreen Then
			DestroyWindow(ah.hfullscreen)
		EndIf
		ad.filename=""
	EndIf
	SendMessage(ah.hpr,PRM_REFRESHLIST,0,0)
	SetWinCaption
	HideList()
	Return FALSE

End Function

Function OpenAProject(ByVal hWin As HWND) As Boolean
	Dim ofn As OPENFILENAME
	Dim sFile As ZString*260

	ofn.lStructSize=SizeOf(OPENFILENAME)
	ofn.hwndOwner=GetOwner
	ofn.hInstance=hInstance
	ofn.lpstrInitialDir=@ad.DefProjectPath
	sFile=String(260,0)
	ofn.lpstrFile=@sFile
	ofn.nMaxFile=260
	ofn.lpstrFilter=StrPtr(PRJFilterString)
	ofn.lpstrTitle=StrPtr("Open Project")
	ofn.Flags=OFN_FILEMUSTEXIST Or OFN_HIDEREADONLY Or OFN_PATHMUSTEXIST Or OFN_EXPLORER
	If GetOpenFileName(@ofn) Then
		If fProject Then
			If CloseProject=FALSE Then
				Return FALSE
			EndIf
		Else
			If CloseAllTabs(hWin,FALSE,0)=TRUE Then
				Return FALSE
			EndIf
		EndIf
		ad.ProjectFile=sFile
		OpenProject
		Return TRUE
	EndIf
	Return FALSE

End Function

Function SaveAllFiles(ByVal hWin As HWND) As Integer
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer
	Dim nNotSaved As Integer
	Dim hOld As HWND

	SetFocus(ah.hred)
	tci.mask=TCIF_PARAM
	nNotSaved=0
	i=0
	Do While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			If SendMessage(lpTABMEM->hedit,EM_GETMODIFY,0,0) Then
				If Left(lpTABMEM->filename,10)="(Untitled)" Then
					hOld=ah.hred
					ah.hred=lpTABMEM->hedit
					ad.filename=lpTABMEM->filename
					SendMessage(hWin,WM_SIZE,0,0)
					If ah.hred<>hOld Then
						ShowWindow(ah.hred,SW_SHOW)
						ShowWindow(hOld,SW_HIDE)
					EndIf
					SendMessage(ah.htabtool,TCM_SETCURSEL,i,0)
					SetWinCaption
					If SaveFileAs(hWin)=FALSE Then
						nNotSaved+=1
					EndIf
				Else
					WriteTheFile(lpTABMEM->hedit,lpTABMEM->filename)
				EndIf
			EndIf
		Else
			Exit Do
		EndIf
		i=i+1
	Loop
	Return nNotSaved

End Function

Function GetProjectFileID(ByVal hWin As HWND) As Integer
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer

	tci.mask=TCIF_PARAM
	i=0
	Do While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			If lpTABMEM->hedit=hWin Then
				Return lpTABMEM->profileinx
			EndIf
		Else
			Exit Do
		EndIf
		i=i+1
	Loop
	Return 0

End Function

Sub UpdateAllTabs(ByVal nType As Integer)
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim i As Integer
	Dim x As Integer
	Dim p As Integer
	Dim hFile As HANDLE
	Dim ft As FILETIME

	tci.mask=TCIF_PARAM
	i=0
	p=0
	Do While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM ptr,tci.lParam)
			If nType=1 Then
				' Update options
				If lpTABMEM->hedit<>ah.hres Then
					UpdateEditOption(lpTABMEM->hedit)
				EndIf
			ElseIf nType=2 Then
				' Clear errors
				If lpTABMEM->hedit<>ah.hres Then
					SendMessage(lpTABMEM->hedit,REM_CLRBOOKMARKS,0,7)
				EndIf
			ElseIf nType=3 Then
				If lpTABMEM->hedit<>ah.hres Then
					x=GetWindowLong(lpTABMEM->hedit,GWL_USERDATA)
					If x=2 Or (x=1 And lpTABMEM->hedit<>ah.hred) Then
						' Update properties
						p=p+ParseFile(ah.hwnd,lpTABMEM->hedit,lpTABMEM->filename)
					EndIf
				EndIf
			ElseIf nType=4 Then
				x=SendMessage(lpTABMEM->hedit,EM_GETMODIFY,0,0)
				If x<>(lpTABMEM->filestate And 1) Then
					lpTABMEM->filestate=lpTABMEM->filestate And (-1 Xor 1)
					lpTABMEM->filestate=lpTABMEM->filestate Or x
					CallAddins(ah.hwnd,AIM_FILESTATE,i,Cast(Integer,lpTABMEM),HOOK_FILESTATE)
				EndIf
			ElseIf nType=5 Then
				hFile=CreateFile(lpTABMEM->filename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL)
				If hFile<>INVALID_HANDLE_VALUE Then
					GetFileTime(hFile,NULL,NULL,@ft)
					CloseHandle(hFile)
					If ft.dwLowDateTime<>lpTABMEM->ft.dwLowDateTime Then
						' File changed outside editor
						fChangeNotification=-1
						lstrcpy(@buff,lpTABMEM->filename)
						buff=buff & CR & "File changed outside editor!" & CR & "Reopen the file?"
						If MessageBox(ah.hwnd,@buff,@szAppName,MB_YESNO Or MB_ICONEXCLAMATION)=IDYES Then
							' Reload file
							ReadTheFile(lpTABMEM->hedit,lpTABMEM->filename)
							lstrcpy(@buff,lpTABMEM->filename)
							SetFileInfo(lpTABMEM->hedit,buff)
						EndIf
						lpTABMEM->ft.dwLowDateTime=ft.dwLowDateTime
						lpTABMEM->ft.dwHighDateTime=ft.dwHighDateTime
						fChangeNotification=10
					EndIf
				EndIf
			ElseIf nType=6 Then
				' Clear find
				If lpTABMEM->hedit<>ah.hres Then
					SendMessage(lpTABMEM->hedit,REM_CLRBOOKMARKS,0,3)
				EndIf
			EndIf
		Else
			Exit Do
		EndIf
		i=i+1
	Loop
	If nType=3 And p>0 Then
		SendMessage(ah.hpr,WM_SETREDRAW,FALSE,0)
		SendMessage(ah.hpr,PRM_REFRESHLIST,0,0)
		SendMessage(ah.hpr,WM_SETREDRAW,TRUE,0)
	EndIf
	If nType=2 Or nType=6 Then
		fTimer=1
	EndIf

End Sub

Function TabToolProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim lret As Integer
	Dim ht As TCHITTESTINFO
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr

	Select Case uMsg
		Case WM_LBUTTONDBLCLK
			ht.pt.x=LoWord(lParam)
			ht.pt.y=HiWord(lParam)
			lret=SendMessage(hWin,TCM_HITTEST,0,Cast(Integer,@ht))
			If lret<>-1 Then
				tci.mask=TCIF_PARAM
				SendMessage(hWin,TCM_GETITEM,lret,Cast(Integer,@tci))
				lpTABMEM=Cast(TABMEM ptr,tci.lParam)
				SelectTab(ah.hwnd,lpTABMEM->hedit,0)
				SendMessage(lpTABMEM->hedit,REM_SETLOCK,SendMessage(lpTABMEM->hedit,REM_GETLOCK,0,0) Xor 1,0)
				Return 0
			EndIf
			'
		Case WM_RBUTTONDOWN
			ht.pt.x=LoWord(lParam)
			ht.pt.y=HiWord(lParam)
			lret=SendMessage(hWin,TCM_HITTEST,0,Cast(Integer,@ht))
			If lret<>-1 Then
				tci.mask=TCIF_PARAM
				SendMessage(hWin,TCM_GETITEM,lret,Cast(Integer,@tci))
				lpTABMEM=Cast(TABMEM ptr,tci.lParam)
				SelectTab(ah.hwnd,lpTABMEM->hedit,0)
				Return 0
			EndIf
			'
		Case WM_MBUTTONDOWN
			ht.pt.x=LoWord(lParam)
			ht.pt.y=HiWord(lParam)
			lret=SendMessage(hWin,TCM_HITTEST,0,Cast(Integer,@ht))
			If lret<>-1 Then
				tci.mask=TCIF_PARAM
				SendMessage(hWin,TCM_GETITEM,lret,Cast(Integer,@tci))
				lpTABMEM=Cast(TABMEM ptr,tci.lParam)
				SelectTab(ah.hwnd,lpTABMEM->hedit,0)
				Return 0
			EndIf
			'
		Case WM_MBUTTONUP
			SendMessage(ah.hwnd,WM_COMMAND,IDM_FILE_CLOSE,0)
			Return 0
			'
	End Select
	Return CallWindowProc(lpOldTabToolProc,hWin,uMsg,wParam,lParam)

End Function

#Define IDD_DLGSAVESELECTION		5000
#Define IDC_LSTFILES					1001
#Define IDC_BTNSELECT				1002
#Define IDC_BTNDESELECT				1003

Function SaveAllProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Integer i,n,id,Event
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM ptr
	Dim sItem As ZString*260
	Dim hOld As HWND
	Dim rect As RECT

	Select Case uMsg
		Case WM_INITDIALOG
			tci.mask=TCIF_PARAM
			i=0
			n=0
			Do While TRUE
				If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
					lpTABMEM=Cast(TABMEM ptr,tci.lParam)
					If SendMessage(lpTABMEM->hedit,EM_GETMODIFY,0,0) Then
						lstrcpy(@buff,lpTABMEM->filename)
						sItem=GetFileName(buff,TRUE)
						id=SendDlgItemMessage(hWin,IDC_LSTFILES,LB_ADDSTRING,0,Cast(LPARAM,@sItem))
						SendDlgItemMessage(hWin,IDC_LSTFILES,LB_SETITEMDATA,id,i)
						SendDlgItemMessage(hWin,IDC_LSTFILES,LB_SETSEL,TRUE,id)
						n=n+1
					EndIf
				Else
					Exit Do
				EndIf
				i=i+1
			Loop
			If n=0 Then
				EndDialog(hWin,0)
			EndIf
			SetWindowPos(hWin,0,wpos.ptsavelist.x,wpos.ptsavelist.y,0,0,SWP_NOREPOSITION Or SWP_NOSIZE)
			'
		Case WM_CLOSE
			If lParam=2 Then
				lParam=0
			Else
				lParam=1
			EndIf
			GetWindowRect(hWin,@rect)
			wpos.ptsavelist.x=rect.left
			wpos.ptsavelist.y=rect.top
			EndDialog(hWin,lParam)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case id
				Case IDOK
					i=0
					tci.mask=TCIF_PARAM
					While TRUE
						id=SendDlgItemMessage(hWin,IDC_LSTFILES,LB_GETSEL,i,0)
						If id=LB_ERR Then
							Exit While
						ElseIf id=TRUE Then
							id=SendDlgItemMessage(hWin,IDC_LSTFILES,LB_GETITEMDATA,i,0)
							SendMessage(ah.htabtool,TCM_GETITEM,id,Cast(Integer,@tci))
							lpTABMEM=Cast(TABMEM ptr,tci.lParam)
							If Left(lpTABMEM->filename,10)="(Untitled)" Then
								hOld=ah.hred
								ah.hred=lpTABMEM->hedit
								ad.filename=lpTABMEM->filename
								SendMessage(ah.hwnd,WM_SIZE,0,0)
								If ah.hred<>hOld Then
									ShowWindow(ah.hred,SW_SHOW)
									ShowWindow(hOld,SW_HIDE)
								EndIf
								SendMessage(ah.htabtool,TCM_SETCURSEL,id,0)
								SetWinCaption
								If SaveFileAs(hWin)=FALSE Then
									EndDialog(hWin,1)
									Return TRUE
								EndIf
							Else
								WriteTheFile(lpTABMEM->hedit,lpTABMEM->filename)
							EndIf
						EndIf
						i=i+1
					Wend
					SendMessage(hWin,WM_CLOSE,0,2)
					'
				Case IDCANCEL
					SendMessage(hWin,WM_CLOSE,0,1)
					'
				Case IDC_BTNSELECT
					i=0
					While TRUE
						If SendDlgItemMessage(hWin,IDC_LSTFILES,LB_SETSEL,TRUE,i)=LB_ERR Then
							Exit While
						EndIf
						i=i+1
					Wend
					'
				Case IDC_BTNDESELECT
					i=0
					While TRUE
						If SendDlgItemMessage(hWin,IDC_LSTFILES,LB_SETSEL,FALSE,i)=LB_ERR Then
							Exit While
						EndIf
						i=i+1
					Wend
					'
			End Select
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

