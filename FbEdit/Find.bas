
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

Dim Shared fres As Integer

Sub InitFindDir
	
	Select Case f.fdir
		Case 0
			' All
			f.ft.chrg.cpMin=f.chrginit.cpMin
			f.ft.chrg.cpMax=f.chrgrange.cpMax
			f.fr=f.fr Or FR_DOWN
		Case 1
			' Down
			f.ft.chrg.cpMin=f.chrginit.cpMin
			f.ft.chrg.cpMax=f.chrgrange.cpMax
			f.fr=f.fr Or FR_DOWN
		Case 2
			' Up
			f.ft.chrg.cpMin=f.chrginit.cpMin
			f.ft.chrg.cpMax=0
			f.fr=f.fr And (-1 Xor FR_DOWN)
	End Select

End Sub

Sub InitFind
	Dim nLn As Integer
	Dim isinp As ISINPROC
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM Ptr
	Dim p As ZString Ptr
	Dim i As Integer
	Dim sItem As String

	f.listoffiles=""
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(LPARAM,@f.chrginit))
	Select Case f.fsearch
		Case 0
			' Current Procedure
			isinp.nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,f.chrginit.cpMin)
			isinp.lpszType=StrPtr("p")
			If fProject Then
				tci.mask=TCIF_PARAM
				SendMessage(ah.htabtool,TCM_GETITEM,SendMessage(ah.htabtool,TCM_GETCURSEL,0,0),Cast(LPARAM,@tci))
				lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
				isinp.nOwner=lpTABMEM->profileinx
			Else
				isinp.nOwner=Cast(Integer,ah.hred)
			EndIf
			p=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
			If p Then
				p=FindExact(StrPtr("p"),p,TRUE)
				nLn=SendMessage(ah.hpr,PRM_FINDGETLINE,0,0)
				f.chrgrange.cpMin=SendMessage(ah.hred,EM_LINEINDEX,nLn,0)
				nLn=SendMessage(ah.hpr,PRM_FINDGETENDLINE,0,0)
				f.chrgrange.cpMax=SendMessage(ah.hred,EM_LINEINDEX,nLn,0)
				f.fnoproc=FALSE
			Else
				f.chrgrange.cpMin=0
				f.chrgrange.cpMax=SendMessage(ah.hred,WM_GETTEXTLENGTH,0,0)
				f.fnoproc=TRUE
			EndIf
		Case 1
			' Current Module
			f.chrgrange.cpMin=0
			f.chrgrange.cpMax=SendMessage(ah.hred,WM_GETTEXTLENGTH,0,0)
		Case 2
			' All Open Files
			'f.ntabinit=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
			'f.ntab=f.ntabinit
			f.chrgrange.cpMin=0
			f.chrgrange.cpMax=SendMessage(ah.hred,WM_GETTEXTLENGTH,0,0)
			f.listoffiles=","
			' Add open files
			i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
			If i Then
				While TRUE
					tci.mask=TCIF_PARAM
					If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
						lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
						If FileType(lpTABMEM->filename)=1 Then
							f.listoffiles &= Str(i) & ","
						EndIf
					Else
						Exit While
					EndIf
					i+=1
				Wend
			EndIf
			i=0
			While TRUE
				tci.mask=TCIF_PARAM
				If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
					lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
					If FileType(lpTABMEM->filename)=1 Then
						If InStr(f.listoffiles,"," & Str(i) & ",")=0 Then
							f.listoffiles &= Str(i) & ","
						EndIf
					EndIf
				Else
					Exit While
				EndIf
				i+=1
			Wend
			f.fpro=1
			f.listoffiles=Mid(f.listoffiles,2)
TextToOutput(f.listoffiles)
		Case 3
			' All Project Files
			f.listoffiles=","
			' Add open project files
			i=SendMessage(ah.htabtool,TCM_GETCURSEL,0,0)
			If i Then
				While TRUE
					tci.mask=TCIF_PARAM
					If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
						lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
						If lpTABMEM->profileinx Then
							If FileType(lpTABMEM->filename)=1 Then
								f.listoffiles &= Str(lpTABMEM->profileinx) & ","
							EndIf
						EndIf
					Else
						Exit While
					EndIf
					i+=1
				Wend
			EndIf
			i=0
			While TRUE
				tci.mask=TCIF_PARAM
				If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(LPARAM,@tci)) Then
					lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
					If lpTABMEM->profileinx Then
						If FileType(lpTABMEM->filename)=1 Then
							If InStr(f.listoffiles,"," & Str(lpTABMEM->profileinx) & ",")=0 Then
								f.listoffiles &= Str(lpTABMEM->profileinx) & ","
							EndIf
						EndIf
					EndIf
				Else
					Exit While
				EndIf
				i+=1
			Wend
			' Add not open project files
			f.ffileno=0
			While f.ffileno<1256
				f.ffileno+=1
				sItem=GetProjectFileName(f.ffileno)
				If Len(sItem) Then
					If FileType(sItem)=1 Then
						If InStr(f.listoffiles,"," & Str(f.ffileno) & ",")=0 Then
							f.listoffiles &= Str(f.ffileno) & ","
						EndIf
					EndIf
				EndIf
				If f.ffileno>256 And f.ffileno<1001 Then
					f.ffileno=1000
				EndIf
			Wend
			f.listoffiles=Mid(f.listoffiles,2)
			f.ffileno=1
			f.fpro=1
	End Select
	InitFindDir
	f.ft.lpstrText=@f.findbuff

End Sub

Sub ResetFind

	If f.fpro=0 Then
		fres=-1
		'f.ffileno=1
		f.fonlyonetime=0
		f.nreplacecount=0
		If f.flogfindclear Then
			SendMessage(ah.hwnd,IDM_OUTPUT_CLEAR,0,0)
		EndIf
		SetDlgItemText(findvisible,IDOK,GetInternalString(IS_FIND))
		InitFind
	EndIf

End Sub

Sub ShowStat(ByVal fOneFile As Integer)
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

Function FindInFile(hWin As HWND,frType As Integer) As Integer
	Dim res As Integer

	res=SendMessage(hWin,EM_FINDTEXTEX,frType,Cast(LPARAM,@f.ft))
	If res<>-1 Then
		If f.fdir=2 Then
			f.ft.chrg.cpMin=f.ft.chrgText.cpMin-1
		Else
			f.ft.chrg.cpMin=f.ft.chrgText.cpMax
		EndIf
	Else
		If f.fdir=0 Then
			If f.chrginit.cpMin<>0 And f.ft.chrg.cpMax>f.chrginit.cpMin Then
				f.ft.chrg.cpMin=f.chrgrange.cpMin
				f.ft.chrg.cpMax=f.chrginit.cpMin-1
				res=FindInFile(hWin,frType)
			EndIf
		EndIf
	EndIf
	Return res

End Function

Function Find(hWin As HWND,frType As Integer) As Integer
	Dim isinp As ISINPROC
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM Ptr
	Dim p As ZString Ptr
	Dim sFile As ZString*260
	Dim hMem As HGLOBAL
	Dim ms As MEMSEARCH
	Dim hREd As HWND
	Dim i As Integer

	Select Case f.fsearch
		Case 0
			' Current Procedure
			If f.fnoproc Then
				While TRUE
					fres=FindInFile(ah.hred,frType)
					If fres<>-1 Then
						isinp.nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,f.ft.chrgText.cpMin)
						isinp.lpszType=StrPtr("p")
						If fProject Then
							tci.mask=TCIF_PARAM
							SendMessage(ah.htabtool,TCM_GETITEM,SendMessage(ah.htabtool,TCM_GETCURSEL,0,0),Cast(LPARAM,@tci))
							lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
							isinp.nOwner=lpTABMEM->profileinx
						Else
							isinp.nOwner=Cast(Integer,ah.hred)
						EndIf
						p=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
						If p=0 Then
							Exit While
						EndIf
					Else
						Exit While
					EndIf
				Wend
			Else
				fres=FindInFile(ah.hred,frType)
			EndIf
		Case 1
			' Current Module
			fres=FindInFile(ah.hred,frType)
		Case 2
			' All Open Files
TheNextTab:
			If f.fpro=1 Then
				While Len(f.listoffiles)
					i=InStr(f.listoffiles,",")
					f.ffileno=Val(Left(f.listoffiles,i-1))
					f.listoffiles=Mid(f.listoffiles,i+1)
					tci.mask=TCIF_PARAM
					SendMessage(ah.htabtool,TCM_GETITEM,f.ffileno,Cast(LPARAM,@tci))
					lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
					SendMessage(lpTABMEM->hedit,EM_EXGETSEL,0,Cast(LPARAM,@f.chrginit))
					f.chrgrange.cpMin=0
					f.chrgrange.cpMax=SendMessage(lpTABMEM->hedit,WM_GETTEXTLENGTH,0,0)
					InitFindDir
					fres=FindInFile(lpTABMEM->hedit,frType)
					If fres<>-1 Then
						f.fpro=2
						SelectTab(ah.hwnd,lpTABMEM->hedit,0)
						GoTo TheNextTab
					Else
						f.fpro=1
						GoTo TheNextTab
					EndIf
				Wend
				fres=-1
			Else
				fres=FindInFile(ah.hred,frType)
				If fres=-1 Then
					f.fpro=1
					GoTo TheNextTab
				EndIf
			EndIf
		Case 3
			' All Project Files
TheNextFile:
			If f.fpro=1 Then
				While Len(f.listoffiles)
					i=InStr(f.listoffiles,",")
					f.ffileno=Val(Left(f.listoffiles,i-1))
					f.listoffiles=Mid(f.listoffiles,i+1)
					sFile=GetProjectFileName(f.ffileno)
					hMem=GetFileMem(sFile)
					ms.lpMem=hMem
					ms.lpFind=@f.findbuff
					ms.lpCharTab=ad.lpCharTab
					' Memory search down is faster
					ms.fr=f.fr Or FR_DOWN
					fres=SendMessage(ah.hpr,PRM_MEMSEARCH,0,Cast(Integer,@ms))
					GlobalFree(hMem)
					If fres Then
						OpenProjectFile(f.ffileno)
						SetFocus(ah.hfind)
						SendMessage(ah.hred,EM_EXGETSEL,0,Cast(LPARAM,@f.chrginit))
						f.chrgrange.cpMin=0
						f.chrgrange.cpMax=SendMessage(ah.hred,WM_GETTEXTLENGTH,0,0)
						InitFindDir
						f.fpro=2
						GoTo TheNextFile
					EndIf
				Wend
				fres=-1
			Else
				fres=FindInFile(ah.hred,frType)
				If fres=-1 Then
					f.fpro=1
					GoTo TheNextFile
				EndIf
			EndIf
	End Select
	If fres<>-1 Then
		SendMessage(ah.hred,EM_EXSETSEL,0,Cast(LPARAM,@f.ft.chrgText))
		SendMessage(ah.hred,REM_VCENTER,0,0)
		SendMessage(ah.hred,EM_SCROLLCARET,0,0)
	Else
		Select Case f.fsearch
			Case 0,1,2
				MessageBox(hWin,GetInternalString(IS_REGION_SEARCHED),@szAppName,MB_OK Or MB_ICONINFORMATION)
			Case 3
				' Project Files searched
				If f.nreplacecount Then
					buff=GetInternalString(IS_PROJECT_FILES_SEARCHED) & CR & Str(f.nreplacecount) & " " & GetInternalString(IS_REPLACEMENTS_DONE)
					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
				Else
					If f.flogfind Then
						ShowStat(FALSE)
					Else
						MessageBox(hWin,GetInternalString(IS_PROJECT_FILES_SEARCHED),@szAppName,MB_OK Or MB_ICONINFORMATION)
					EndIf
				EndIf
				f.ft.chrg.cpMax=f.ft.chrg.cpMin
				SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
		End Select
		f.fpro=0
		ResetFind
	EndIf
	Return fres

End Function

'Function Find(hWin As HWND,frType As Integer) As Long
'	Dim chrg As CHARRANGE
'	Dim sFile As ZString*260
'	Dim hMem As HGLOBAL
'	Dim ms As MEMSEARCH
'	Dim As Integer x,tmp,nLine,nLinesOut
'
'	chrg.cpMin=-1
'	chrg.cpMax=-1
'	SendMessage(ah.hout,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
'	nLinesOut=SendMessage(ah.hout,EM_GETLINECOUNT,0,0)
'
'TryAgain:
'	If f.fpro=1 Then
'		fres=0
'		While fres=0
'			sFile=GetProjectFileName(f.fprofileno)
'			If Len(sFile) Then
'				If FileType(sFile)=1 Then
'					hMem=GetFileMem(sFile)
'					If hMem Then
'						ms.lpMem=hMem
'						ms.lpFind=@f.findbuff
'						ms.lpCharTab=ad.lpCharTab
'						' Memory search down is faster
'						ms.fr=f.fr Or FR_DOWN
'						fres=SendMessage(ah.hpr,PRM_MEMSEARCH,0,Cast(Integer,@ms))
'						GlobalFree(hMem)
'						If fres Then
'							f.ft.chrg.cpMin-=1
'							f.ft.chrg.cpMax=f.ft.chrg.cpMin
'							SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
'							tmp=f.fprofileno
'							OpenProjectFile(f.fprofileno)
'							SetFocus(ah.hfind)
'							f.fprofileno=tmp
'							If f.fdir=2 Then
'								chrg.cpMin=-1
'								chrg.cpMax=-1
'								f.ft.chrg.cpMin=-1
'								f.ft.chrg.cpMax=0
'							Else
'								chrg.cpMin=0
'								chrg.cpMax=0
'								f.ft.chrg.cpMin=0
'								f.ft.chrg.cpMax=-1
'							EndIf
'							SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@chrg))
'							f.fonlyonetime=0
'							fPos=0
'							f.fpro=2
'							fres=-1
'							Exit While
'						EndIf
'					Else
'						MessageBox(ah.hfind,GetInternalString(IS_COULD_NOT_FIND) & CRLF & sFile,@szAppName,MB_OK Or MB_ICONERROR)
'					EndIf
'				EndIf
'			EndIf
'			f.fprofileno=f.fprofileno+1
'			If f.fprofileno>1256 Then
'				' Project Files searched
'				If f.nreplacecount Then
'					buff=GetInternalString(IS_PROJECT_FILES_SEARCHED) & CR & Str(f.nreplacecount) & " " & GetInternalString(IS_REPLACEMENTS_DONE)
'					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
'					f.nreplacecount=0
'				Else
'					If f.flogfind Then
'						ShowStat(FALSE)
'					Else
'						MessageBox(hWin,GetInternalString(IS_PROJECT_FILES_SEARCHED),@szAppName,MB_OK Or MB_ICONINFORMATION)
'					EndIf
'				EndIf
'				f.ft.chrg.cpMax=f.ft.chrg.cpMin
'				SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
'				fres=-1
'				f.fprofileno=1
'				ResetFind
'				Return fres
'			ElseIf f.fprofileno>256 And f.fprofileno<1001 Then
'				f.fprofileno=1001
'			EndIf
'		Wend
'	EndIf
'	' Get current selection
'	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
'	' Setup find
'	If (frType And FR_DOWN)=0 Then
'		f.ft.chrg.cpMax=0
'	EndIf
'	f.ft.lpstrText=@f.findbuff
'TryFind:
'	' Do the find
'	fres=SendMessage(ah.hred,EM_FINDTEXTEX,frType,Cast(Integer,@f.ft))
'	If f.ft.chrgText.cpMin>=(f.ft.chrg.cpMax And &h7FFFFFFF) And f.fdir=0 Then
'		fres=-1
'	EndIf
'	If fres<>-1 Then
'		If f.fskipcommentline Then
'			tmp=SendMessage(ah.hred,REM_ISCHARPOS,f.ft.chrgText.cpMin,0)
'			If tmp=1 Or tmp=2 Then
'				If f.fdir=2 Then
'					f.ft.chrg.cpMin-=1
'				Else
'					f.ft.chrg.cpMin+=1
'				EndIf
'				GoTo TryFind
'			EndIf
'		EndIf
'		If f.flogfind Then
'			If f.fonlyonetime=0 Then
'				SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@ad.filename))
'				SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@CR))
'				SendMessage(ah.hout,REM_SETBOOKMARK,nLinesOut,5)
'				SendMessage(ah.hout,REM_SETBMID,nLinesOut,0)
'				f.fonlyonetime=1
'				nLinesOut+=1
'			EndIf
'			buff=Chr(255) & Chr(1)
'			nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,fres)
'			chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,nLine,0)
'			chrg.cpMax=SendMessage(ah.hred,EM_GETLINE,nLine,Cast(LPARAM,@buff))
'			buff[chrg.cpMax]=NULL
'			lstrcpy(@s," (")
'			lstrcat(@s,Str(nLine+1))
'			lstrcat(@s,") ")
'			lstrcat(@s,@buff)
'			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@s))
'			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(LPARAM,@CR))
'			x=SendMessage(ah.hred,REM_GETBOOKMARK,nLine,0)
'			If x<>3 Then
'				SendMessage(ah.hout,REM_SETBOOKMARK,nLinesOut,3)
'				SendMessage(ah.hred,REM_SETBOOKMARK,nLine,3)
'				x=SendMessage(ah.hout,REM_GETBMID,nLinesOut,0)
'				SendMessage(ah.hred,REM_SETBMID,nLine,x)
'			Else
'				SendMessage(ah.hout,REM_SETBOOKMARK,nLinesOut,4)
'				SendMessage(ah.hout,REM_SETBMID,nLinesOut,0)
'			EndIf
'			nLinesOut+=1
'		EndIf
'		' Mark the foud text
'		SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrgText))
'		SendMessage(ah.hred,REM_VCENTER,0,0)
'		SendMessage(ah.hred,EM_SCROLLCARET,0,0)
'	Else
'		If f.fdir=0 And fPos<>0 Then 
'			f.ft.chrg.cpMin=0
'			f.ft.chrg.cpMax=fPos
'			fPos=0
'			GoTo TryFind
'		Else
'			If f.fpro Then
'				' Next project file
'				f.fpro=1
'				f.fprofileno=f.fprofileno+1
'				GoTo TryAgain
'			Else
'				' Region searched
'				If f.nreplacecount Then
'					buff=GetInternalString(IS_REGION_SEARCHED) & CR & Str(f.nreplacecount) & " " & GetInternalString(IS_REPLACEMENTS_DONE)
'					MessageBox(hWin,@buff,@szAppName,MB_OK Or MB_ICONINFORMATION)
'					f.nreplacecount=0
'				Else
'					If f.flogfind Then
'						ShowStat(TRUE)
'					Else
'						MessageBox(hWin,GetInternalString(IS_REGION_SEARCHED),@szAppName,MB_OK Or MB_ICONINFORMATION)
'					EndIf
'				EndIf
'				f.ft.chrg.cpMax=f.ft.chrg.cpMin
'				SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@f.ft.chrg))
'				fPos=f.ft.chrg.cpMin
'				fres=-1
'				f.ft.chrg.cpMax=-1 
'				f.fprofileno=1
'			EndIf
'		EndIf
'	EndIf
'	Return fres
'
'End Function
'
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
	Dim As Integer id,Event,lret
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
			CheckDlgButton(hWin,IDC_CHK_SKIPCOMMENTS,IIf(f.fskipcommentline,BST_CHECKED,BST_UNCHECKED))
			CheckDlgButton(hWin,IDC_CHK_LOGFIND,IIf(f.flogfind,BST_CHECKED,BST_UNCHECKED))
			EnableWindow(GetDlgItem(hWin,IDC_BTN_FINDALL),f.flogfind)
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
			f.fpro=0
			ResetFind
			'
		Case WM_ACTIVATE
			If wParam<>WA_INACTIVE Then
				ah.hfind=hWin
			EndIf
			'CheckDlgButton(hWin,IDC_RBN_PROJECTFILES,IIf(f.fpro,BST_CHECKED,BST_UNCHECKED))
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
						If f.fdir=2 Then
							buff=GetInternalString(IS_PREVIOUS)
						Else
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
								f.nreplacecount+=1
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
								'If fPos=0 And f.ft.chrg.cpMax<>-1 Then
								'	f.ft.chrg.cpMax=f.ft.chrg.cpMax+(Len(f.replacebuff)-Len(f.findbuff))
								'EndIf
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
						f.fpro=0
						ResetFind
						'
					Case IDC_CHK_WHOLEWORD
						f.fr=f.fr Xor FR_WHOLEWORD
						f.fpro=0
						ResetFind
						'
					Case IDC_CHK_SKIPCOMMENTS
						f.fskipcommentline=f.fskipcommentline Xor 1
						f.fpro=0
						ResetFind
						'
					Case IDC_CHK_LOGFIND
						f.flogfind=f.flogfind Xor 1
						EnableWindow(GetDlgItem(hWin,IDC_BTN_FINDALL),f.flogfind)
						f.fpro=0
						ResetFind
						'
					Case IDC_RBN_ALL
						f.fdir=0
						f.fpro=0
						ResetFind
						'
					Case IDC_RBN_DOWN
						f.fdir=1
						f.fpro=0
						ResetFind
						'
					Case IDC_RBN_UP
						f.fdir=2
						f.fpro=0
						ResetFind
						'
					Case IDC_RBN_PROCEDURE
						f.fsearch=0
						ResetFind
					Case IDC_RBN_MODULE
						f.fsearch=1
						f.fpro=0
						ResetFind
					Case IDC_RBN_FILES
						f.fsearch=2
						f.fpro=0
						ResetFind
					Case IDC_RBN_PROJECTFILES
						f.fsearch=3
						f.fpro=0
						ResetFind
						'
				End Select
				'
			ElseIf Event=CBN_EDITCHANGE Then
				SendDlgItemMessage(hWin,id,WM_GETTEXT,255,Cast(LPARAM,@f.findbuff))
				SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_GETTEXT,255,Cast(LPARAM,@f.replacebuff))
				f.fpro=0
				ResetFind
				'
			ElseIf Event=CBN_SELCHANGE Then
				id=SendDlgItemMessage(hWin,id,CB_GETCURSEL,0,0)
				SendDlgItemMessage(hWin,IDC_FINDTEXT,CB_SETCURSEL,id,0)
				SendDlgItemMessage(hWin,IDC_FINDTEXT,WM_GETTEXT,255,Cast(LPARAM,@f.findbuff))
				SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_GETTEXT,255,Cast(LPARAM,@f.replacebuff))
				f.fpro=0
				ResetFind
				'
			ElseIf Event=EN_CHANGE Then
				' Update text buffers
				SendDlgItemMessage(hWin,IDC_FINDTEXT,WM_GETTEXT,255,Cast(LPARAM,@f.findbuff))
				SendDlgItemMessage(hWin,IDC_REPLACETEXT,WM_GETTEXT,255,Cast(LPARAM,@f.replacebuff))
				f.fpro=0
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
