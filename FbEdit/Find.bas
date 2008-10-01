
#Define IDD_FINDDLG							2500
#Define IDC_FINDTEXT							2001
#Define IDC_REPLACETEXT						2002
#Define IDC_CHK_MATCHCASE					2003
#Define IDC_CHK_WHOLEWORD					2007
#Define IDC_BTN_REPLACEALL					2008
#Define IDC_REPLACESTATIC					2009
#Define IDC_BTN_REPLACE						2010
#Define IDC_CHK_SKIPCOMMENTS				2013
#Define IDC_CHK_LOGFIND						2014
#Define IDC_BTN_FINDALL						2015
' Direction
#Define IDC_RBN_ALL							2004
#Define IDC_RBN_DOWN							2005
#Define IDC_RBN_UP							2006
' Search
#Define IDC_RBN_PROCEDURE					2502
#Define IDC_RBN_MODULE						2503
#Define IDC_RBN_FILES						2504
#Define IDC_RBN_PROJECTFILES				2012

'Dim Shared findbuff As ZString*260
'Dim Shared replacebuff As ZString*260
'Dim Shared fDir As Long=0
Dim Shared fPos As Long
Dim Shared fPro As Long
Dim Shared fProFileNo As Long
'Dim Shared fr As Long=FR_DOWN
Dim Shared fres As Long
'Dim Shared ft As FINDTEXTEX
Dim Shared nReplaceCount As Integer
Dim Shared fSkipCommentLine As Long
Dim Shared fLogFind As Long
Dim Shared fLogFindClear As Long
Dim Shared fOnlyOneTime As Long

Sub ResetFind
	fres=-1
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@f.ft.chrg))
	fPos=f.ft.chrg.cpMin
	f.ft.chrg.cpMax=-1
	fProFileNo=1
	fOnlyOneTime=0
	If fLogFindClear Then
		SendMessage(ah.hwnd,IDM_OUTPUT_CLEAR,0,0)
	EndIf
	SetDlgItemText(findvisible,IDOK,GetInternalString(IS_FIND))

End Sub

Sub ShowStat(ByVal fOneFile As Long)
	Dim As Integer i,bm,nFiles,nFounds,nRepeats,nErrors,nWarnings

	i=SendMessage(ah.hout,EM_GETLINECOUNT,0,0)
	While i>-1
		bm=SendMessage(ah.hout,REM_GETBOOKMARK,i,0)
		Select Case As Const bm
			Case 3
				nFounds+=1
			Case 4
				nRepeats+=1
			Case 5
				nFiles+=1
			Case 6
				nWarnings+=1
			Case 7
				nErrors+=1
		End Select
		i-=1
	Wend
	If fOneFile Then
		wsprintf(@buff,GetInternalString(IS_REGION_SEARCHED_INFO),10,10,10,nFounds,10,nRepeats,10,10,10,nErrors,10,nWarnings)
	Else
		wsprintf(@buff,GetInternalString(IS_PROJECT_FILES_SEARCHED_INFO),10,10,10,nFiles,10,nFounds,10,nRepeats,10,10,10,nErrors,10,nWarnings)
	EndIf
	MessageBox(ah.hwnd,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)

End Sub

Function Find(hWin As HWND,frType As Long) As Long
	Dim chrg As CHARRANGE
	Dim sFile As ZString*260
	Dim hMem As HGLOBAL
	Dim ms As MEMSEARCH
	Dim As Integer x,tmp,nLine,nLinesOut

	chrg.cpMin=-1
	chrg.cpMax=-1
	SendMessage(ah.hout,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
	nLinesOut=SendMessage(ah.hout,EM_GETLINECOUNT,0,0)

TryAgain:
	If fPro=1 Then
		fres=0
		While fres=0
			sFile=GetProjectFileName(fProFileNo)
			If Len(sFile) Then
				If FileType(sFile)=1 Then
					hMem=GetFileMem(sFile)
					If hMem Then
						ms.lpMem=hMem
						ms.lpFind=@f.findbuff
						ms.lpCharTab=ad.lpCharTab
						' Memory search down is faster
						ms.fr=f.fr Or FR_DOWN
						fres=SendMessage(ah.hpr,PRM_MEMSEARCH,0,Cast(Integer,@ms))
						GlobalFree(hMem)
						If fres Then
							f.ft.chrg.cpMin-=1
							f.ft.chrg.cpMax=f.ft.chrg.cpMin
							SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
							tmp=fProFileNo
							OpenProjectFile(fProFileNo)
							SetFocus(ah.hfind)
							fProFileNo=tmp
							If f.fdir=2 Then
								chrg.cpMin=-1
								chrg.cpMax=-1
								f.ft.chrg.cpMin=-1
								f.ft.chrg.cpMax=0
							Else
								chrg.cpMin=0
								chrg.cpMax=0
								f.ft.chrg.cpMin=0
								f.ft.chrg.cpMax=-1
							EndIf
							SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@chrg))
							fOnlyOneTime=0
							fPos=0
							fPro=2
							fres=-1
							Exit While
						EndIf
					Else
						MessageBox(ah.hfind,GetInternalString(IS_COULD_NOT_FIND) & CRLF & sFile,@szAppName,MB_OK Or MB_ICONERROR)
					EndIf
				EndIf
			EndIf
			fProFileNo=fProFileNo+1
			If fProFileNo>1256 Then
				' Project Files searched
				If nReplaceCount Then
					buff=GetInternalString(IS_PROJECT_FILES_SEARCHED) & CR & Str(nReplaceCount) & " " & GetInternalString(IS_REPLACEMENTS_DONE)
					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
					nReplaceCount=0
				Else
					If fLogFind Then
						ShowStat(FALSE)
					Else
						MessageBox(hWin,GetInternalString(IS_PROJECT_FILES_SEARCHED),@szAppName,MB_OK Or MB_ICONINFORMATION)
					EndIf
				EndIf
				f.ft.chrg.cpMax=f.ft.chrg.cpMin
				SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
				fres=-1
				fProFileNo=1
				ResetFind
				Return fres
			ElseIf fProFileNo>256 And fProFileNo<1001 Then
				fProFileNo=1001
			EndIf
		Wend
	EndIf
	' Get current selection
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	' Setup find
	If (frType And FR_DOWN)=0 Then
		f.ft.chrg.cpMax=0
	EndIf
	f.ft.lpstrText=@f.findbuff
TryFind:
	' Do the find
	fres=SendMessage(ah.hred,EM_FINDTEXTEX,frType,Cast(Integer,@f.ft))
	If f.ft.chrgText.cpMin>=(f.ft.chrg.cpMax And &h7FFFFFFF) And f.fdir=0 Then
		fres=-1
	EndIf
	If fres<>-1 Then
		If fSkipCommentLine Then
			tmp=SendMessage(ah.hred,REM_ISCHARPOS,f.ft.chrgText.cpMin,0)
			If tmp=1 Or tmp=2 Then
				If f.fdir=2 Then
					f.ft.chrg.cpMin-=1
				Else
					f.ft.chrg.cpMin+=1
				EndIf
				GoTo TryFind
			EndIf
		EndIf
		If fLogFind Then
			If fOnlyOneTime=0 Then
				SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@ad.filename))
				SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@CR))
				SendMessage(ah.hout,REM_SETBOOKMARK,nLinesOut,5)
				SendMessage(ah.hout,REM_SETBMID,nLinesOut,0)
				fOnlyOneTime=1
				nLinesOut+=1
			EndIf
			buff=Chr(255) & Chr(1)
			nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,fres)
			chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,nLine,0)
			chrg.cpMax=SendMessage(ah.hred,EM_GETLINE,nLine,Cast(LPARAM,@buff))
			buff[chrg.cpMax]=NULL
			lstrcpy(@s," (")
			lstrcat(@s,Str(nLine+1))
			lstrcat(@s,") ")
			lstrcat(@s,@buff)
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@s))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@CR))
			x=SendMessage(ah.hred,REM_GETBOOKMARK,nLine,0)
			If x<>3 Then
				SendMessage(ah.hout,REM_SETBOOKMARK,nLinesOut,3)
				SendMessage(ah.hred,REM_SETBOOKMARK,nLine,3)
				x=SendMessage(ah.hout,REM_GETBMID,nLinesOut,0)
				SendMessage(ah.hred,REM_SETBMID,nLine,x)
			Else
				SendMessage(ah.hout,REM_SETBOOKMARK,nLinesOut,4)
				SendMessage(ah.hout,REM_SETBMID,nLinesOut,0)
			EndIf
			nLinesOut+=1
		EndIf
		' Mark the foud text
		SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrgText))
		SendMessage(ah.hred,REM_VCENTER,0,0)
		SendMessage(ah.hred,EM_SCROLLCARET,0,0)
	Else
		If f.fdir=0 And fPos<>0 Then 
			f.ft.chrg.cpMin=0
			f.ft.chrg.cpMax=fPos
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
				If nReplaceCount Then
					buff=GetInternalString(IS_REGION_SEARCHED) & CR & Str(nReplaceCount) & " " & GetInternalString(IS_REPLACEMENTS_DONE)
					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
					nReplaceCount=0
				Else
					If fLogFind Then
						ShowStat(TRUE)
					Else
						MessageBox(hWin,GetInternalString(IS_REGION_SEARCHED),@szAppName,MB_OK Or MB_ICONINFORMATION)
					EndIf
				EndIf
				f.ft.chrg.cpMax=f.ft.chrg.cpMin
				SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
				fPos=f.ft.chrg.cpMin
				fres=-1
				f.ft.chrg.cpMax=-1 
				fProFileNo=1
			EndIf
		EndIf
	EndIf
	Return fres

End Function

Sub LoadFindHistory()
	Dim As Integer i
	Dim As ZString*260 sItem
	
	For i=1 To 9
		If GetPrivateProfileString(StrPtr("Find"),Str(i),@szNULL,@sItem,SizeOf(sItem),@ad.IniFile) Then
			FindHistory(i-1)=sItem
		Else
			Exit For
		EndIf
	Next
	
End Sub

Sub SaveFindHistory()
	Dim As Integer i
	
	For i=1 To 9
		WritePrivateProfileString(StrPtr("Find"),Str(i),@FindHistory(i-1),@ad.IniFile)
	Next
	
End Sub

Sub UpdateFindHistory(ByVal hWin As HWND)
	
	If Len(f.findbuff) And SendMessage(hWin,CB_FINDSTRINGEXACT,-1,Cast(LPARAM,@f.findbuff))=CB_ERR Then
		SendMessage(hWin,CB_INSERTSTRING,0,Cast(LPARAM,@f.findbuff))
	EndIf

End Sub

Function FindDlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id,Event,lret
	Dim hCtl As HWND
	Dim chrg As CHARRANGE
	Dim rect As RECT

	Select Case uMsg
		Case WM_INITDIALOG
			TranslateDialog(hWin,IDD_FINDDLG)
			findvisible=hWin
			If lParam Then
				PostMessage(hWin,WM_COMMAND,(BN_CLICKED Shl 16) Or IDC_BTN_REPLACE,0)
			EndIf
			' Fill ComboBox
			hCtl=GetDlgItem(hWin,IDC_FINDTEXT)
			For id=0 To 8
				If Len(FindHistory(id)) Then
					SendMessage(hCtl,CB_ADDSTRING,0,Cast(LPARAM,@FindHistory(id)))
				EndIf
			Next
			' Put text in edit boxes
			SendDlgItemMessage(hWin,IDC_FINDTEXT,EM_LIMITTEXT,255,0)
			SendDlgItemMessage(hWin,IDC_FINDTEXT,WM_SETTEXT,0,Cast(Integer,@f.findbuff))
			SendDlgItemMessage(hWin,IDC_REPLACETEXT,EM_LIMITTEXT,255,0)
			SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_SETTEXT,0,Cast(Integer,@f.replacebuff))
			' Set check boxes
			CheckDlgButton(hWin,IDC_CHK_MATCHCASE,IIf(f.fr And FR_MATCHCASE,BST_CHECKED,BST_UNCHECKED))
			CheckDlgButton(hWin,IDC_CHK_WHOLEWORD,IIf(f.fr And FR_WHOLEWORD,BST_CHECKED,BST_UNCHECKED))
			' Set find direction
			Select Case f.fdir
				Case 0
					id=IDC_RBN_ALL
				Case 1
					id=IDC_RBN_DOWN
				Case 2
					id=IDC_RBN_UP
			End Select
			CheckDlgButton(hWin,id,BST_CHECKED)
			SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@f.ft.chrg))
			If fProject=0 Then
				fPro=0
			EndIf
			CheckDlgButton(hWin,IDC_CHK_SKIPCOMMENTS,IIf(fSkipCommentLine,BST_CHECKED,BST_UNCHECKED))
			CheckDlgButton(hWin,IDC_CHK_LOGFIND,IIf(fLogFind,BST_CHECKED,BST_UNCHECKED))
			EnableWindow(GetDlgItem(hWin,IDC_BTN_FINDALL),fLogFind)
			fPos=f.ft.chrg.cpMin
			f.ft.chrg.cpMax=-1
			fProFileNo=1
			EnableWindow(GetDlgItem(hWin,IDC_RBN_PROJECTFILES),fProject)
			Select Case f.fsearch
				Case 0
					id=IDC_RBN_PROCEDURE
				Case 1
					id=IDC_RBN_MODULE
				Case 2
					id=IDC_RBN_FILES
				Case 3
					id=IDC_RBN_PROJECTFILES
			End Select
			CheckDlgButton(hWin,id,BST_CHECKED)
			SetWindowPos(hWin,0,wpos.ptfind.x,wpos.ptfind.y,0,0,SWP_NOSIZE)
			nReplaceCount=0
			'
		Case WM_ACTIVATE
			If wParam<>WA_INACTIVE Then
				ah.hfind=hWin
			EndIf
			If fProject=0 Then
				fPro=0
			EndIf
			CheckDlgButton(hWin,IDC_RBN_PROJECTFILES,IIf(fPro,BST_CHECKED,BST_UNCHECKED))
			EnableWindow(GetDlgItem(hWin,IDC_RBN_PROJECTFILES),fProject)
			ResetFind
			If ah.hred Then
				id=GetWindowLong(ah.hred,GWL_ID)
			EndIf
			If id=IDC_HEXED Or id=0 Then
				EnableWindow(GetDlgItem(hWin,IDOK),FALSE)
				EnableWindow(GetDlgItem(hWin,IDC_BTN_REPLACE),FALSE)
			Else
				EnableWindow(GetDlgItem(hWin,IDOK),TRUE)
				EnableWindow(GetDlgItem(hWin,IDC_BTN_REPLACE),TRUE)
			EndIf
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			If Event=BN_CLICKED Then
				Select Case id
					Case IDOK
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
						If f.fdir=2 Then
							If fres<>-1 Then
								f.ft.chrg.cpMin=chrg.cpMin-1
							EndIf
							buff=GetInternalString(IS_PREVIOUS)
						Else
							If fres<>-1 Then
								f.ft.chrg.cpMin=chrg.cpMin+chrg.cpMax-chrg.cpMin
							EndIf
							buff=GetInternalString(IS_NEXT)
						EndIf
						SendMessage(GetDlgItem(hWin,IDOK),WM_SETTEXT,0,Cast(LPARAM,@buff))
						UpdateFindHistory(GetDlgItem(hWin,IDC_FINDTEXT))
						Find(hWin,f.fr)
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
							SetWindowText(hWin,GetInternalString(IS_REPLACE))
							' Show replace
							hCtl=GetDlgItem(hWin,IDC_REPLACESTATIC)
							ShowWindow(hCtl,SW_SHOWNA)
							hCtl=GetDlgItem(hWin,IDC_REPLACETEXT)
							ShowWindow(hCtl,SW_SHOWNA)
						Else
							If fres<>-1 Then
								nReplaceCount=nReplaceCount+1
								SendMessage(ah.hred,EM_REPLACESEL,TRUE,Cast(Integer,@f.replacebuff))
								SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
								If f.fdir=2 Then
									If fres<>-1 Then
										f.ft.chrg.cpMin=chrg.cpMin-1
									EndIf
								Else
									If fres<>-1 Then
										f.ft.chrg.cpMin=chrg.cpMin+chrg.cpMax-chrg.cpMin
									EndIf
								EndIf
								'update real end
								If fPos=0 And f.ft.chrg.cpMax<>-1 Then
									f.ft.chrg.cpMax=f.ft.chrg.cpMax+(Len(f.replacebuff)-Len(f.findbuff))
								EndIf
							EndIf
							Find(hWin,f.fr)
						EndIf
						'
					Case IDC_BTN_FINDALL
						UpdateFindHistory(GetDlgItem(hWin,IDC_FINDTEXT))
						If fres=-1 Then
							Find(hWin,f.fr)
						EndIf
						Do While fres<>-1
							SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
							If f.fdir=2 Then
								If fres<>-1 Then
									f.ft.chrg.cpMin=chrg.cpMin-1
								EndIf
							Else
								If fres<>-1 Then
									f.ft.chrg.cpMin=chrg.cpMin+chrg.cpMax-chrg.cpMin
								EndIf
							EndIf
							Find(hWin,f.fr)
						Loop
						'
					Case IDC_BTN_REPLACEALL
						If fres=-1 Then
							Find(hWin,f.fr)
						EndIf
						Do While fres<>-1
							SendMessage(hWin,WM_COMMAND,(BN_CLICKED Shl 16) Or IDC_BTN_REPLACE,0)
						Loop
						'
					Case IDC_CHK_MATCHCASE
						f.fr=f.fr Xor FR_MATCHCASE
						ResetFind
						'
					Case IDC_CHK_WHOLEWORD
						f.fr=f.fr Xor FR_WHOLEWORD
						ResetFind
						'
					Case IDC_CHK_SKIPCOMMENTS
						fSkipCommentLine=fSkipCommentLine Xor 1
						ResetFind
						'
					Case IDC_CHK_LOGFIND
						fLogFind=fLogFind Xor 1
						EnableWindow(GetDlgItem(hWin,IDC_BTN_FINDALL),fLogFind)
						ResetFind
						'
					Case IDC_RBN_ALL
						f.fdir=0
						f.fr=f.fr Or FR_DOWN
						ResetFind
						'
					Case IDC_RBN_DOWN
						f.fdir=1
						f.fr=f.fr Or FR_DOWN
						ResetFind
						'
					Case IDC_RBN_UP
						f.fdir=2
						f.fr=f.fr And (-1 Xor FR_DOWN)
						ResetFind
						'
					Case IDC_RBN_PROCEDURE
						f.fsearch=0
					Case IDC_RBN_MODULE
						f.fsearch=1
					Case IDC_RBN_FILES
						f.fsearch=2
					Case IDC_RBN_PROJECTFILES
						f.fsearch=3
						If fPro Then
							fPro=0
						Else
							fPro=1
						EndIf
						ResetFind
						'
				End Select
				'
			ElseIf Event=CBN_EDITCHANGE Then
				SendDlgItemMessage(hWin,id,WM_GETTEXT,255,Cast(LPARAM,@f.findbuff))
				SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_GETTEXT,255,Cast(LPARAM,@f.replacebuff))
				ResetFind
				'
			ElseIf Event=CBN_SELCHANGE Then
				id=SendDlgItemMessage(hWin,id,CB_GETCURSEL,0,0)
				SendDlgItemMessage(hWin,IDC_FINDTEXT,CB_SETCURSEL,id,0)
				SendDlgItemMessage(hWin,IDC_FINDTEXT,WM_GETTEXT,255,Cast(LPARAM,@f.findbuff))
				SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_GETTEXT,255,Cast(LPARAM,@f.replacebuff))
				ResetFind
				'
			ElseIf Event=EN_CHANGE Then
				' Update text buffers
				SendDlgItemMessage(hWin,IDC_FINDTEXT,WM_GETTEXT,255,Cast(LPARAM,@f.findbuff))
				SendDlgItemMessage(hWin,id,WM_GETTEXT,255,Cast(LPARAM,@f.replacebuff))
				ResetFind
			EndIf
			'
		Case WM_CLOSE
			DestroyWindow(hWin)
			SetFocus(ah.hred)
			'
		Case WM_DESTROY
			hCtl=GetDlgItem(hWin,IDC_FINDTEXT)
			For id=0 To 8
				SendMessage(hCtl,CB_GETLBTEXT,id,Cast(LPARAM,@FindHistory(id)))
			Next
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
