
#Define IDD_FINDDLG							2500
#Define IDC_FINDTEXT							2001
#Define IDC_BTN_REPLACE						2010
#Define IDC_REPLACETEXT						2002
#Define IDC_REPLACESTATIC					2009
#Define IDC_BTN_REPLACEALL					2008
#Define IDC_CHK_WHOLEWORD					2007
#Define IDC_CHK_MATCHCASE					2003
#Define IDC_CHK_PROJECTFILES				2012
#Define IDC_CHK_SKIPCOMMENTS				2013
#Define IDC_RBN_ALL							2004
#Define IDC_RBN_DOWN							2005
#Define IDC_RBN_UP							2006

Dim Shared findbuff As ZString*260
Dim Shared replacebuff As ZString*260
Dim Shared fDir As Long=0
Dim Shared fPos As Long
Dim Shared fPro As Long
Dim Shared fProFileNo As Long
Dim Shared fr As Long=FR_DOWN
Dim Shared fres As Long
Dim Shared ft As FINDTEXTEX
Dim Shared nReplaceCount As Integer
Dim Shared fSkipCommentLine As Long

Function Find(hWin As HWND,frType As Long) As Long
	Dim chrg As CHARRANGE
	Dim sFile As ZString*260
	Dim hMem As HGLOBAL
	Dim ms As MEMSEARCH
	Dim tmp As Integer
	Dim nLine As Integer
	Dim lLine As Integer

TryAgain:
	If fPro=1 Then
		fres=0
		While fres=0
			sFile=GetProjectFileName(fProFileNo)
			If Len(sFile) Then
				If FileType(sFile)=1 Then
					hMem=GetFileMem(sFile)
					ms.lpMem=hMem
					ms.lpFind=@findbuff
					ms.lpCharTab=ad.lpCharTab
					' Memory search down is faster
					ms.fr=fr Or FR_DOWN
					fres=SendMessage(ah.hpr,PRM_MEMSEARCH,0,Cast(Integer,@ms))
					GlobalFree(hMem)
					If fres Then
						tmp=fProFileNo
						OpenProjectFile(fProFileNo)
						SetFocus(ah.hfind)
						fProFileNo=tmp
						If fDir=2 Then
							chrg.cpMin=-1
							chrg.cpMax=-1
						Else
							chrg.cpMin=0
							chrg.cpMax=0
						EndIf
						SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@chrg))
						fPos=0
						fPro=2
						fres=-1
						Exit While
					EndIf
				EndIf
			EndIf
			fProFileNo=fProFileNo+1
			If fProFileNo>1256 Then
				' Project Files searched
				If nReplaceCount Then
					buff="Project Files searched" & CR & Str(nReplaceCount) & " Replacements done."
					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
					nReplaceCount=0
				Else
					MessageBox(hWin,StrPtr("Project Files searched"),@szAppName,MB_OK Or MB_ICONINFORMATION)
				EndIf
				fres=-1
				fProFileNo=1
				Return fres
			ElseIf fProFileNo>256 And fProFileNo<1001 Then
				fProFileNo=1001
			EndIf
		Wend
	EndIf
	' Get current selection
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	' Setup find
	ft.chrg.cpMin=chrg.cpMin
	If frType And FR_DOWN Then
		If fres<>-1 Then
			ft.chrg.cpMin=chrg.cpMin+Len(findbuff)
		EndIf
	Else
		ft.chrg.cpMax=0
	EndIf
	ft.lpstrText=@findbuff
TryFind:
	' Do the find
	fres=SendMessage(ah.hred,EM_FINDTEXTEX,frType,Cast(Integer,@ft))
	If ft.chrg.cpMin>(ft.chrg.cpMax And &H7FFFFFFF) And fDir=0 Then
		fres=-1
	EndIf
	If fres<>-1 Then
		If fSkipCommentLine Then
			tmp=SendMessage(ah.hred,REM_ISCHARPOS,ft.chrgText.cpMin,0)
			If tmp=1 Or tmp=2 Then
				If fDir=2 Then
					ft.chrg.cpMin-=1
				Else
					ft.chrg.cpMin+=1
				EndIf
				GoTo TryFind
			EndIf
		EndIf
		' Mark the foud text
		SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@ft.chrgText))
		SendMessage(ah.hred,REM_VCENTER,0,0)
		SendMessage(ah.hred,EM_SCROLLCARET,0,0)
	Else
		If fDir=0 And fPos<>0 Then 
			ft.chrg.cpMin=0
			ft.chrg.cpMax=fPos
			fPos=0
			GoTo TryFind
		Else
			If fPro Then
				' Next project file
				fPro=1
				fProFileNo=fProFileNo+1
				GoTo TryAgain
			Else
				' Region searched
				If nReplaceCount then
					buff="Region searched" & CR & Str(nReplaceCount) & " Replacements done."
					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
					nReplaceCount=0
				Else
					MessageBox(hWin,StrPtr("Region searched"),@szAppName,MB_OK Or MB_ICONINFORMATION)
				EndIf
				ft.chrg.cpMax=ft.chrg.cpMin
				SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@ft.chrg))
				fPos=ft.chrg.cpMin
				fres=-1
				ft.chrg.cpMax=-1 
				fProFileNo=1
			EndIf
		EndIf
	EndIf
	Return fres

End Function

Function FindDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id,Event,lret
	Dim hCtl As HWND
	Dim chrg As CHARRANGE
	Dim rect As RECT

	Select Case uMsg
		Case WM_INITDIALOG
			findvisible=hWin
			If lParam Then
				PostMessage(hWin,WM_COMMAND,(BN_CLICKED Shl 16) Or IDC_BTN_REPLACE,0)
			EndIf
			' Put text in edit boxes
			SendDlgItemMessage(hWin,IDC_FINDTEXT,EM_LIMITTEXT,255,0)
			SendDlgItemMessage(hWin,IDC_FINDTEXT,WM_SETTEXT,0,Cast(Integer,@findbuff))
			SendDlgItemMessage(hWin,IDC_REPLACETEXT,EM_LIMITTEXT,255,0)
			SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_SETTEXT,0,Cast(Integer,@replacebuff))
			' Set check boxes
			If fr And FR_MATCHCASE Then
				CheckDlgButton(hWin,IDC_CHK_MATCHCASE,BST_CHECKED)
			EndIf
			If fr And FR_WHOLEWORD Then
				CheckDlgButton(hWin,IDC_CHK_WHOLEWORD,BST_CHECKED)
			EndIf
			' Set find direction
			If fDir=0 Then
				id=IDC_RBN_ALL
			ElseIf fDir=1 Then
				id=IDC_RBN_DOWN
			Else
				id=IDC_RBN_UP
			EndIf
			CheckDlgButton(hWin,id,BST_CHECKED)
			SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
			If fProject Then
				If fPro Then
					CheckDlgButton(hWin,IDC_CHK_PROJECTFILES,BST_CHECKED)
				EndIf
			Else
				fPro=0
				EnableWindow(GetDlgItem(hWin,IDC_CHK_PROJECTFILES),FALSE)
			EndIf
			If fSkipCommentLine Then
				CheckDlgButton(hWin,IDC_CHK_SKIPCOMMENTS,BST_CHECKED)
			EndIf
			fPos=ft.chrg.cpMin
			ft.chrg.cpMax=-1
			fProFileNo=1
			SetWindowPos(hWin,0,wpos.ptfind.x,wpos.ptfind.y,0,0,SWP_NOSIZE)
			nReplaceCount=0
			'
		Case WM_ACTIVATE
			If wParam<>WA_INACTIVE Then
				ah.hfind=hWin
			EndIf
			fres=-1
			SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
			fPos=ft.chrg.cpMin
			ft.chrg.cpMax=-1
			fProFileNo=1
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			If Event=BN_CLICKED Then
				Select Case id
					Case IDOK
						Find(hWin,fr)
						'
					Case IDCANCEL
						SendMessage(hWin,WM_CLOSE,0,0)
						'
					Case IDC_BTN_REPLACE
						hCtl=GetDlgItem(hWin,IDC_BTN_REPLACEALL)
						If IsWindowEnabled(hCtl)=FALSE Then
							' Enable Replace all button
							EnableWindow(hCtl,TRUE)
							' Set caption to Replace...
							SetWindowText(hWin,StrPtr("Replace..."))
							' Show replace
							hCtl=GetDlgItem(hWin,IDC_REPLACESTATIC)
							ShowWindow(hCtl,SW_SHOWNA)
							hCtl=GetDlgItem(hWin,IDC_REPLACETEXT)
							ShowWindow(hCtl,SW_SHOWNA)
						Else
							If fres<>-1 Then
								nReplaceCount=nReplaceCount+1
								SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
								SendMessage(ah.hred,EM_REPLACESEL,TRUE,Cast(Integer,@replacebuff))
								If fr And FR_DOWN Then
									chrg.cpMin=chrg.cpMin+lstrlen(@replacebuff)-lstrlen(@findbuff)
									chrg.cpMax=chrg.cpMin
								EndIf
								SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@chrg))
							EndIf
							Find(hWin,fr)
						EndIf
						'
					Case IDC_BTN_REPLACEALL
						If fres=-1 Then
							Find(hWin,fr)
						EndIf
						Do While fres<>-1
							SendMessage(hWin,WM_COMMAND,(BN_CLICKED Shl 16) Or IDC_BTN_REPLACE,0)
						Loop
						'
					Case IDC_CHK_MATCHCASE
						fr=fr Xor FR_MATCHCASE
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
					Case IDC_CHK_WHOLEWORD
						fr=fr Xor FR_WHOLEWORD
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
					Case IDC_CHK_PROJECTFILES
						fPro=fPro Xor 1
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
					Case IDC_CHK_SKIPCOMMENTS
						fSkipCommentLine=fSkipCommentLine Xor 1
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
					Case IDC_RBN_ALL
						fDir=0
						fr=fr Or FR_DOWN
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
					Case IDC_RBN_DOWN
						fDir=1
						fr=fr Or FR_DOWN
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
					Case IDC_RBN_UP
						fDir=2
						fr=fr And (-1 Xor FR_DOWN)
						fres=-1
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
						fPos=ft.chrg.cpMin
						ft.chrg.cpMax=-1
						fProFileNo=1
						'
				End Select
				'
			ElseIf Event=EN_CHANGE Then
				' Update text buffers
				If id=IDC_FINDTEXT Then
					SendDlgItemMessage(hWin,id,WM_GETTEXT,255,Cast(Integer,@findbuff))
					fres=-1
					SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
					fPos=ft.chrg.cpMin
					ft.chrg.cpMax=-1
					fProFileNo=1
				ElseIf id=IDC_REPLACETEXT Then
					SendDlgItemMessage(hWin,id,WM_GETTEXT,255,Cast(Integer,@replacebuff))
					fres=-1
					SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@ft.chrg))
					fPos=ft.chrg.cpMin
					ft.chrg.cpMax=-1
					fProFileNo=1
				EndIf
			EndIf
			'
		Case WM_CLOSE
			DestroyWindow(hWin)
			SetFocus(ah.hred)
			'
		Case WM_DESTROY
			GetWindowRect(hWin,@rect)
			wpos.ptfind.x=rect.left
			wpos.ptfind.y=rect.top
			ah.hfind=0
			findvisible=0
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
