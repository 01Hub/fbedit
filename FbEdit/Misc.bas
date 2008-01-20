
Dim Shared lpOldEditProc As Any Ptr
Dim Shared lpOldParEditProc As Any Ptr
Dim Shared lpOldOutputProc As Any Ptr
Dim Shared mdn As Integer
Dim Shared prechrg As CHARRANGE

Function GetOwner() As HWND

	If ah.hfullscreen Then
		Return ah.hfullscreen
	EndIf
	Return ah.hwnd

End Function

Sub AddApiFile(ByVal sFile As String,ByVal nType As Integer)
	Dim sItem As ZString*260
	Dim x As Integer
	Dim sApi As String
	Dim sApiItem As String

	GetPrivateProfileString(StrPtr("Api"),@sFile,@szNULL,@sItem,SizeOf(sItem),@ad.IniFile)
	Do While Len(sItem)
		x=InStr(sItem,",")
		If x Then
			buff=Left(sItem,x-1)
			sItem=Mid(sItem,x+1)
		Else
			buff=sItem
			sItem=""
		EndIf
		If fProject Then
			sApi=ProjectApiFiles
		Else
			sApi=ApiFiles
		EndIf
		While Len(sApi)
			sApiItem=GetTextItem(sApi)
			x=InStr(sApiItem," ")
			If x Then
				sApiItem=Left(sApiItem,x-1)
			EndIf
			If Left(buff,Len(sApiItem))=sApiItem Then
				buff=ad.AppPath & "\Api\" & buff
				SendMessage(ah.hpr,PRM_ADDPROPERTYFILE,nType,Cast(Integer,@buff))
				Exit While
			EndIf
		Wend
	Loop

End Sub

Sub LoadApiFiles

	SendMessage(ah.hpr,PRM_CLEARWORDLIST,0,0)
	AddApiFile("Case",Asc("C")+2*256)
	AddApiFile("Call",Asc("P")+3*256)
	AddApiFile("Const",Asc("A")+2*256)
	AddApiFile("Struct",Asc("S")+2*256)
	AddApiFile("Word",Asc("W")+2*256)
	AddApiFile("Type",Asc("T")+2*256)
	AddApiFile("Desc",Asc("D")+2*256)

End Sub

Sub ShowOutput(ByVal bShow As Boolean)

	If bShow Then
		If (wpos.fview And VIEW_OUTPUT)=0 Then
			SendMessage(ah.hwnd,WM_COMMAND,IDM_VIEW_OUTPUT,0)
		EndIf
	Else
		If wpos.fview And VIEW_OUTPUT Then
			SendMessage(ah.hwnd,WM_COMMAND,IDM_VIEW_OUTPUT,0)
		EndIf
	EndIf

End Sub

Sub TextToOutput(ByVal sText As String)

	SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,@sText))
	SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))

End Sub

Function MyGlobalAlloc(ByVal nType As Integer,ByVal nSize As Integer) As HGLOBAL
	Dim hMem As HGLOBAL

Retry:

	hMem=GlobalAlloc(nType,nSize)
	If hMem=0 Then
		Select Case MessageBox(ah.hwnd,"Memory allocation failed." & CRLF & Str(nSize) & " Bytes.",@szAppName,MB_ABORTRETRYIGNORE Or MB_ICONERROR)
			Case IDRETRY
				GoTo Retry
				'
			Case IDABORT
				End
				'
			Case IDIGNORE
				'
		End Select
	EndIf
	Return hMem

End Function

Sub SetFullScreen(ByVal hWin As HWND)

	If ah.hfullscreen Then
		SetParent(hWin,ah.hfullscreen)
		ShowWindow(hWin,SW_SHOWMAXIMIZED)
		SetWindowPos(hWin,HWND_TOP,0,0,0,0,SWP_NOSIZE)
		SetFocus(hWin)
	EndIf

End Sub

Sub GetFilePath(ByVal sFile As String)
	Dim x As Integer

	x=Len(sFile)
	While x
		If Asc(sFile,x)=Asc("\") Then
			sFile=Left(sFile,x-1)
			Exit While
		EndIf
		x=x-1
	Wend

End Sub

Function GetFileExt(ByVal sFile As String) As String
	Dim x As Integer

	x=Len(sFile)
	While x
		If Asc(sFile,x)=Asc(".") Then
			Exit While
		EndIf
		x=x-1
	Wend
	GetFileExt=Mid(sFile,x)

End Function

Function RemoveFileExt(ByVal sFile As String) As String
	Dim x As Integer

	x=Len(sFile)
	While x
		If Asc(sFile,x)=Asc(".") Then
			Exit While
		EndIf
		x=x-1
	Wend
	RemoveFileExt=Left(sFile,x-1)

End Function

Function GetFileName(ByVal sFile As String,ByVal fExt As Boolean) As String
	Dim x As Integer
	Dim sItem As ZString*260

	sItem=sFile
	If fExt=FALSE Then
		x=Len(sItem)
		While x
			If Asc(sItem,x)=Asc(".") Then
				sItem=Left(sItem,x-1)
				Exit While
			EndIf
			x=x-1
		Wend
	EndIf
	x=Len(sItem)
	While x
		If Asc(sItem,x)=Asc("\") Then
			Exit While
		EndIf
		x=x-1
	Wend
	GetFileName=Mid(sItem,x+1)

End Function

Function OutputProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim pt As Point
	Dim hMnu As HMENU

	Select Case uMsg
		Case WM_CONTEXTMENU
			If lParam=-1 Then
				GetCaretPos(@pt)
				ClientToScreen(hWin,@pt)
				pt.x=pt.x+10
			Else
				pt.x=lParam And &HFFFF
				pt.y=lParam Shr 16
			EndIf
			hMnu=GetSubMenu(ah.hcontextmenu,2)
			TrackPopupMenu(hMnu,TPM_LEFTALIGN Or TPM_RIGHTBUTTON,pt.x,pt.y,0,ah.hwnd,0)
			'
	End Select
	Return CallWindowProc(lpOldOutputProc,hWin,uMsg,wParam,lParam)

End Function

Sub AutoBrace(ByVal hWin As HWND,ByVal nchr As Integer)
	Dim chrg As CHARRANGE

	SendMessage(hWin,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If SendMessage(hWin,REM_ISCHARPOS,chrg.cpMin,0)=0 Then
		SendMessage(hWin,WM_CHAR,nchr,0)
		SendMessage(hWin,EM_EXSETSEL,0,Cast(Integer,@chrg))
		SendMessage(hWin,EM_SCROLLCARET,0,0)
	EndIf

End Sub

Sub CaseConvertWord(ByVal hWin As HWND,ByVal cp As Integer)
	Dim lret As ZString Ptr
	Dim lp As Integer
	Dim chrg As CHARRANGE

	If SendMessage(hWin,REM_ISCHARPOS,cp,0)=0 Then
		SendMessage(hWin,REM_SETCHARTAB,Asc("."),CT_CHAR)
		If SendMessage(hWin,REM_GETWORD,260,Cast(LPARAM,@buff)) Then
			lret=FindExact(@szCaseConvert,@buff,FALSE)
			If lret Then
				lstrcpy(@buff,lret)
				If edtopt.autocase=2 Then
					buff=LCase(buff)
				ElseIf edtopt.autocase=3 Then
					buff=UCase(buff)
				EndIf
				SendMessage(hWin,REM_CASEWORD,cp,Cast(LPARAM,@buff))
			EndIf
		EndIf
		SendMessage(hWin,REM_SETCHARTAB,Asc("."),CT_HICHAR)
	EndIf

End Sub

Sub CaseConvertWordFromList(ByVal hWin As HWND,ByVal cp As Integer,ByVal hMem As HGLOBAL,ByVal nCount As Integer)
	Dim lret As ZString Ptr
	Dim lp As Integer
	Dim chrg As CHARRANGE
	Dim ms As MEMSEARCH

	If SendMessage(hWin,REM_ISCHARPOS,cp,0)=0 Then
		If SendMessage(hWin,REM_GETWORDFROMPOS,cp,Cast(LPARAM,@buff)) Then
			ms.lpMem=hMem
			ms.lpFind=@buff
			lp=SendMessage(ah.hpr,PRM_FINDINSORTEDLIST,nCount,Cast(LPARAM,@ms))
			If lp>0 Then
				lp=Cast(Integer,hMem)+lp*4
				lret=Cast(ZString Ptr,Peek(Integer,lp))
				lstrcpy(@buff,lret)
				If edtopt.autocase=2 Then
					buff=LCase(buff)
				ElseIf edtopt.autocase=3 Then
					buff=UCase(buff)
				EndIf
				SendMessage(hWin,REM_CASEWORD,cp,Cast(LPARAM,@buff))
			EndIf
		EndIf
	EndIf

End Sub

Sub CaseConvert(ByVal hWin As HWND)
	Dim chrg As CHARRANGE
	Dim tmpchrg As CHARRANGE
	Dim lp As Integer
	Dim hCur As HCURSOR
	Dim hMem As HGLOBAL
	Dim nCount As Integer

	hCur=GetCursor
	SetCursor(LoadCursor(0,IDC_WAIT))
	SendMessage(hWin,REM_SETCHARTAB,Asc("."),CT_CHAR)
	hMem=Cast(HGLOBAL,SendMessage(ah.hpr,PRM_GETSORTEDLIST,Cast(WPARAM,@szCaseConvert),Cast(LPARAM,@nCount)))
	SendMessage(hWin,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
	If chrg.cpMin=chrg.cpMax Then
		tmpchrg.cpMin=0
		tmpchrg.cpMax=-1
		While tmpchrg.cpMin<10000000 And tmpchrg.cpMin<>tmpchrg.cpMax
			tmpchrg.cpMax=tmpchrg.cpMin
			CaseConvertWordFromList(hWin,tmpchrg.cpMin,hMem,nCount)
			tmpchrg.cpMin=SendMessage(hWin,EM_FINDWORDBREAK,WB_MOVEWORDRIGHT,tmpchrg.cpMin+1)
		Wend
	Else
		tmpchrg.cpMin=chrg.cpMin
		tmpchrg.cpMax=-1
		While tmpchrg.cpMin<=chrg.cpMax And tmpchrg.cpMin<>tmpchrg.cpMax
			tmpchrg.cpMax=tmpchrg.cpMin
			CaseConvertWordFromList(hWin,tmpchrg.cpMin,hMem,nCount)
			tmpchrg.cpMin=SendMessage(hWin,EM_FINDWORDBREAK,WB_MOVEWORDRIGHT,tmpchrg.cpMin+1)
		Wend
	EndIf
	SendMessage(hWin,REM_SETCHARTAB,Asc("."),CT_HICHAR)
	SendMessage(hWin,REM_REPAINT,0,0)
	GlobalFree(hMem)
	SendMessage(hWin,EM_SETMODIFY,TRUE,0)
	SetCursor(hCur)

End Sub

Function GetIndent(ByVal hWin As HWND,ByVal ln As Integer,ByVal lpszBlockSt As ZString Ptr,ByVal lpErr As Integer Ptr) As String
	Dim lx As Integer
	Dim lz As Integer
	Dim szIndent As ZString*512
	
	Poke Integer,lpErr,1
	lx=ln+1
	lz=0
	While lx<>-1
		lz=lx
		lx=SendMessage(hWin,REM_PRVBOOKMARK,lx,1)
		lz=SendMessage(hWin,REM_PRVBOOKMARK,lz,2)
		If lz>lx Then
			lx=lz
		EndIf
		If lx>=0 Then
			lz=SendMessage(hWin,REM_GETBLOCKEND,lx,0)
			If lz>=ln Then
				If SendMessage(hWin,REM_ISLINE,lx,Cast(LPARAM,lpszBlockSt))>=0 Then
					' Get indent
					szIndent=Chr(255) & Chr(1)
					lx=SendMessage(hWin,EM_GETLINE,lx,Cast(LPARAM,@szIndent))
					szIndent[lx]=NULL
					lz=1
					While lz<lx
						If Asc(szIndent,lz)<>VK_SPACE And Asc(szIndent,lz)<>VK_TAB Then
							szIndent[lz-1]=NULL
							Poke Integer,lpErr,0
							Exit While
						EndIf
						lz=lz+1
					Wend
				EndIf
				Exit While
			ElseIf lz=-1 Then
				Exit While
			EndIf
		EndIf
	Wend
	Return szIndent

End Function

Function SetIndent(ByVal hWin As HWND,ByVal ln As Integer,ByVal lpszIndent As ZString Ptr) As Integer
	Dim szIndent As ZString*512
	Dim lx As Integer
	Dim lz As Integer
	Dim chrg As CHARRANGE

	' Get indent
	szIndent=Chr(255) & Chr(1)
	lx=SendMessage(hWin,EM_GETLINE,ln,Cast(LPARAM,@szIndent))
	szIndent[lx]=NULL
	lz=1
	While lz<=lx
		If Asc(szIndent,lz)<>VK_SPACE And Asc(szIndent,lz)<>VK_TAB Then
			szIndent[lz-1]=NULL
			Exit While
		EndIf
		lz=lz+1
	Wend
	chrg.cpMin=SendMessage(hWin,EM_LINEINDEX,ln,0)
	chrg.cpMax=chrg.cpMin+lz-1
	If lstrcmp(@szIndent,lpszIndent) Then
		SendMessage(hWin,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
		SendMessage(hWin,EM_REPLACESEL,TRUE,Cast(LPARAM,lpszIndent))
	Else
		chrg.cpMin=chrg.cpMax
		SendMessage(hWin,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
		SendMessage(hWin,EM_SCROLLCARET,0,0)
	EndIf
	Return lz

End Function

Function AddIndent(ByVal n As Integer,ByVal lpszIndent As ZString Ptr) As String
	Dim szIndent As ZString*512

	lstrcpy(@szIndent,lpszIndent)
	If edtopt.expand Then
		szIndent=szIndent & Space(n*edtopt.tabsize)
	Else
		szIndent=szIndent & String(n,Chr(VK_TAB))
	EndIf
	Return szIndent

End Function

Sub FormatIndent(ByVal hWin As HWND)
	Dim wp As Integer
	Dim lz As Integer
	Dim ln As Integer
	Dim lm As Integer
	Dim chrg As CHARRANGE
	Dim lnst As Integer
	Dim lntop As Integer
	Dim hCur As HCURSOR

	' Indent / Outdent
	hCur=GetCursor
	SetCursor(LoadCursor(0,IDC_WAIT))
	SendMessage(hWin,WM_SETREDRAW,FALSE,0)
	lntop=SendMessage(hWin,EM_GETFIRSTVISIBLELINE,0,0)
	SendMessage(hWin,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
	lnst=SendMessage(hWin,EM_LINEFROMCHAR,chrg.cpMin,0)
	SendMessage(hWin,REM_LOCKUNDOID,TRUE,0)
	lm=SendMessage(hWin,EM_GETLINECOUNT,0,0)
	ln=0
	buff=""
	While ln<=lm
		wp=0
		While wp<32
			If szIndent(wp)<>szNULL Then
				If SendMessage(hWin,REM_ISLINE,ln,Cast(LPARAM,@szIndent(wp)))>=0 Then
					' Get current indent
					lz=0
					s=buff
					buff=GetIndent(hWin,ln,@szIndent(autofmt(wp).st),@lz)
					If lz=0 Then
						If wp=autofmt(wp).st Then
							buff=s
						EndIf
						' Indent word line
						buff=AddIndent(autofmt(wp).add1,@buff)
						SetIndent(hWin,ln,@buff)
						' Indent caret line
						buff=AddIndent(autofmt(wp).add2,@buff)
						Exit While
					EndIf
				EndIf
			EndIf
			wp=wp+1
		Wend
		If wp=32 Then
			lz=SendMessage(hWin,EM_LINEINDEX,ln,0)
			If SendMessage(hWin,REM_ISCHARPOS,lz,0)<>1 Then
				SetIndent(hWin,ln,@buff)
			EndIf
		EndIf
		SendMessage(hWin,REM_TRIMSPACE,ln,0)
		ln=ln+1
	Wend
	SendMessage(hWin,REM_LOCKUNDOID,FALSE,0)
	chrg.cpMin=0
	chrg.cpMax=0
	SendMessage(hWin,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
	SendMessage(hWin,EM_SCROLLCARET,0,0)
	SendMessage(hWin,EM_LINESCROLL,0,lntop)
	chrg.cpMin=SendMessage(hWin,EM_LINEINDEX,lnst,0)
	chrg.cpMax=chrg.cpMin
	SendMessage(hWin,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
	SendMessage(hWin,EM_SCROLLCARET,0,Cast(LPARAM,@chrg))
	SendMessage(hWin,WM_SETREDRAW,TRUE,0)
	SendMessage(hWin,REM_REPAINT,0,0)
	SendMessage(hWin,EM_SCROLLCARET,0,0)
	SetCursor(hCur)

End Sub

Function ReplaceType(ByVal lpProc As ZString Ptr,ByVal nOwner As Integer,ByVal nLine As Integer) As Boolean
	Dim x As Integer
	Dim y As Integer
	Dim lret As ZString Ptr
	Dim sItem As ZString*256
	Dim sTest As ZString*256

	sItem=buff
	If Asc(sItem)=Asc(".") Then
		lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINWITHBLOCK,nOwner,nLine))
		If lret Then
			lstrcpy(@sTest,lret)
		EndIf
		sItem=sTest & sItem
		buff=sItem
	EndIf
	s=sItem
	sItem=Left(buff,InStr(buff,".")-1)
	If lpProc Then
		lpProc=lpProc+Len(*lpProc)+1
		sTest=sItem
		SendMessage(ah.hpr,PRM_FINDITEMDATATYPE,Cast(Integer,@sTest),Cast(Integer,lpProc))
		If Len(sTest)=0 Then
			lpProc=lpProc+Len(*lpProc)+1
			sTest=sItem
			SendMessage(ah.hpr,PRM_FINDITEMDATATYPE,Cast(Integer,@sTest),Cast(Integer,lpProc))
		EndIf
		If Len(sTest) Then
			If FindExact(StrPtr("s"),@sTest,TRUE) Then
				buff=sTest & Mid(buff,InStr(buff,"."))
				Return TRUE
			EndIf
		EndIf
	EndIf
	lret=FindExact(StrPtr("d"),@sItem,TRUE)
	If lret Then
		lret=lret+Len(*lret)+1
		lstrcpy(@sItem,lret)
		If FindExact(StrPtr("s"),@sItem,TRUE) Then
			buff=sTest & Mid(buff,InStr(buff,"."))
			Return TRUE
		EndIf
	EndIf
	Return FALSE

End Function

Sub TestCaseConvert(ByVal hWin As HWND,ByVal wParam As Integer)
	Dim chrg As CHARRANGE

	If edtopt.autocase<>0 And wParam<>VK_BACK Then
		If Peek(Byte,ad.lpCharTab+wParam)<>1 Then
			If prechrg.cpMin=prechrg.cpMax Then
				SendMessage(hWin,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
				SendMessage(hWin,EM_EXSETSEL,0,Cast(LPARAM,@prechrg))
				CaseConvertWord(hWin,prechrg.cpMin)
				SendMessage(hWin,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
			EndIf
		EndIf
	EndIf

End Sub

Function ShowTooltip(ByVal hWin As HWND,ByVal lptt As TOOLTIP Ptr) As Integer
	Dim tti As TTITEM
	Dim pt As Point
	Dim wp As Integer
	
	If edtopt.codecomplete Then
		fconstlist=UpdateConstList(lptt->lpszApi,lptt->nPos+1)
	EndIf
	If fconstlist Then
		' Move code complete list
		MoveList
		Return TRUE
	Else
		' Show tooltip
		HideList
		If lstrcmp(@szApi,lptt->lpszApi) Then
			lstrcpy(@szApi,lptt->lpszApi)
			nsel=0
			novr=lptt->novr
		EndIf
		tti.nsel=nsel
		tti.lpszApi=lptt->lpszApi
		tti.lpszParam=lptt->ovr(nsel).lpszParam
		tti.lpszRetType=lptt->ovr(nsel).lpszRetType
		tti.nitem=lptt->nPos
		wp=SendMessage(ah.htt,TTM_GETITEMNAME,0,Cast(LPARAM,@tti))
		tti.lpszDesc=FindExact(StrPtr("D"),Cast(ZString Ptr,wp),TRUE)
		If tti.lpszDesc Then
			tti.lpszDesc=tti.lpszDesc+Len(*tti.lpszDesc)+1
		EndIf
		tti.novr=lptt->novr
		GetCaretPos(@pt)
		ClientToScreen(hWin,@pt)
		wp=SendMessage(ah.htt,TTM_SETITEM,0,Cast(LPARAM,@tti))
		pt.x=pt.x-wp
		SendMessage(ah.htt,TTM_SCREENFITS,0,Cast(LPARAM,@pt))
		If edtopt.tooltip Then
			SetWindowPos(ah.htt,HWND_TOP,pt.x,pt.y+20,0,0,SWP_NOSIZE Or SWP_NOACTIVATE Or SWP_SHOWWINDOW)
			InvalidateRect(ah.htt,NULL,TRUE)
			Return TRUE
		EndIf
	EndIf
	Return FALSE

End Function

Function EditProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim pt As Point
	Dim rect As RECT
	Dim lret As Integer
	Dim ln As Integer
	Dim lp As Integer
	Dim wp As Integer
	Dim lx As Integer
	Dim chrg As CHARRANGE
	Dim chrg1 As CHARRANGE
	Dim tti As TTITEM
	Dim tt As TOOLTIP
	Dim hMnu As HMENU
	Dim trng As TEXTRANGE
	Dim hPar As HWND
	Dim p As ZString Ptr
	Dim ft As FINDTEXTEX
	Dim tp As Integer
	Dim lz As Integer
	Dim isinp As ISINPROC

	Select Case uMsg
		Case WM_CHAR
			hPar=GetParent(hWin)
			If SendMessage(hPar,REM_GETWORDGROUP,0,0)=0 Then
				SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@prechrg))
				lret=12345
				If edtopt.autobrace Then
					If wParam=Asc("(") Then
						lret=CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
						AutoBrace(hPar,Asc(")"))
					ElseIf wParam=Asc("{") Then 
						lret=CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
						TestCaseConvert(hPar,wParam)
						AutoBrace(hPar,Asc("}"))
						Return lret
					ElseIf wParam=Asc("[") Then
						lret=CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
						TestCaseConvert(hPar,wParam)
						AutoBrace(hPar,Asc("]"))
						Return lret
					EndIf
				EndIf
				'smart maths
				If wParam=Asc("+") And edtopt.smartmath Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If Asc(buff)=Asc("+") Then
							SendMessage(hPar,EM_REPLACESEL,0,Cast(LPARAM,StrPtr("=")))
							Return 0
						EndIf
					EndIf
				EndIf
				If wParam=Asc("-") And edtopt.smartmath Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If Asc(buff)=Asc("-") Then
							SendMessage(hPar,EM_REPLACESEL,0,Cast(LPARAM,StrPtr("=")))
							Return 0
						EndIf
					EndIf
				EndIf
				If wParam=Asc("*") And edtopt.smartmath Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If Asc(buff)=Asc("*") Then
							SendMessage(hPar,EM_REPLACESEL,0,Cast(LPARAM,StrPtr("=")))
							Return 0
						EndIf
					EndIf
				EndIf
				If wParam=Asc("/") And edtopt.smartmath Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If Asc(buff)=Asc("/") Then
							SendMessage(hPar,EM_REPLACESEL,0,Cast(LPARAM,StrPtr("=")))
							Return 0
						EndIf
					EndIf
				EndIf
				If wParam=Asc("\") And edtopt.smartmath Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If Asc(buff)=Asc("\") Then
							SendMessage(hPar,EM_REPLACESEL,0,Cast(LPARAM,StrPtr("=")))
							Return 0
						EndIf
					EndIf
				EndIf
				If wParam=VK_BACK Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If trng.chrg.cpMin>0 And trng.chrg.cpMin=trng.chrg.cpMax Then
						' Get the deleted character
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						Select Case As Const Asc(buff)
							Case Asc(","),Asc("("),Asc("."),34
								HideList
								ShowWindow(ah.htt,SW_HIDE)
						End Select
					EndIf
				EndIf
				If (wParam=VK_TAB Or wParam=VK_RETURN) And IsWindowVisible(ah.hcc) Then
					' Update edit from code complete list
					SendMessage(hPar,EM_EXGETSEL,0,Cast(Integer,@chrg))
					lret=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
					chrg.cpMin=SendMessage(hPar,EM_LINEINDEX,lret,0)
					buff=Chr(255) & Chr(1)
					p=Cast(ZString Ptr,SendMessage(hPar,EM_GETLINE,lret,Cast(LPARAM,@buff)))
					buff[Cast(Integer,p)]=NULL
					If fincliblist Or fincludelist Then
						SendMessage(ah.hout,REM_SETCHARTAB,Asc("/"),CT_CHAR)
						SendMessage(ah.hpr,PRM_GETWORD,chrg.cpMax-chrg.cpMin,Cast(LPARAM,@buff))
						SendMessage(ah.hout,REM_SETCHARTAB,Asc("/"),CT_CMNTINITCHAR)
					Else
						SendMessage(ah.hpr,PRM_GETWORD,chrg.cpMax-chrg.cpMin,Cast(LPARAM,@buff))
					EndIf
					chrg.cpMin=chrg.cpMax-Len(buff)
					p=Cast(ZString Ptr,SendMessage(ah.hcc,CCM_GETITEM,SendMessage(ah.hcc,CCM_GETCURSEL,0,0),0))
					If p Then
						SendMessage(hPar,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
						lstrcpy(@buff,p)
						lret=InStr(buff,":")
						If lret Then
							buff[lret-1]=NULL
						EndIf
						SendMessage(hPar,EM_REPLACESEL,TRUE,Cast(LPARAM,@buff))
					EndIf
					If fconstlist=FALSE Then
						HideList()
					Else
						ShowWindow(ah.hcc,SW_HIDE)
					EndIf
					Return 0
				ElseIf wParam=Asc(".") And IsWindowVisible(ah.hcc) Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
						trng.chrg.cpMin-=1
						trng.lpstrText=@buff
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If SendMessage(ah.hcc,CCM_GETCOUNT,0,0)<=1 Then
							HideList
						ElseIf Asc(buff)=Asc(".") Then
							Return 0
						EndIf
				ElseIf wParam=Asc("(") Or wParam=Asc(",") Or wParam=VK_BACK Then
					If lret=12345 Then
						lret=CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
					EndIf
					TT:
					ShowWindow(ah.htt,SW_HIDE)
					TestCaseConvert(hPar,wParam)
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
					If SendMessage(hPar,REM_ISCHARPOS,chrg.cpMin,0)=0 Then
						lp=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
						chrg.cpMin=SendMessage(hPar,EM_LINEINDEX,lp,0)
						buff=Chr(255) & Chr(1)
						SendMessage(hPar,EM_GETLINE,lp,Cast(LPARAM,@buff))
						buff[chrg.cpMax-chrg.cpMin]=NULL
						tt.lpszType=StrPtr("Pp")
						tt.lpszLine=@buff
						SendMessage(ah.hout,REM_SETCHARTAB,Asc("."),CT_CHAR)
						If SendMessage(ah.hpr,PRM_GETTOOLTIP,TT_NOMATCHCASE Or TT_PARANTESES,Cast(LPARAM,@tt))<>0 And InStr(buff,"(")<>0 Then
							If ShowTooltip(hWin,@tt)=FALSE Then
								If InStr(buff,".") Then
									buff=Mid(buff,InStr(buff,".")+1)
								EndIf
							EndIf
						Else
							If InStr(buff,".") And InStr(buff,".")<InStr(buff,"(") Then
								lp=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
								isinp.nLine=lp
								If fProject Then
									lx=GetProjectFileID(hPar)
								Else
									lx=Cast(Integer,hPar)
								EndIf
								isinp.nOwner=lx
								isinp.lpszType=StrPtr("pxyzo")
								p=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
								If ReplaceType(p,lx,lp) Then
									If SendMessage(ah.hpr,PRM_GETTOOLTIP,TT_NOMATCHCASE Or TT_PARANTESES,Cast(LPARAM,@tt)) Then
										s=Left(buff,InStr(buff,"(")-1)
										tt.lpszApi=@s
										ShowTooltip(hWin,@tt)
									Else
										' udt.sub( udt->sub(
										SendMessage(ah.hout,REM_SETCHARTAB,Asc("."),CT_HICHAR)
										If SendMessage(ah.hpr,PRM_GETTOOLTIP,TT_NOMATCHCASE Or TT_PARANTESES,Cast(LPARAM,@tt)) Then
											ShowTooltip(hWin,@tt)
										EndIf	
									EndIf
								EndIf
							Else
								SendMessage(ah.hout,REM_SETCHARTAB,Asc("."),CT_HICHAR)
								GoTo	TestUpdate
							EndIf
						EndIf
						SendMessage(ah.hout,REM_SETCHARTAB,Asc("."),CT_HICHAR)
					EndIf
					Return lret
				ElseIf wParam=VK_SPACE And (GetKeyState(VK_CONTROL) And &H80)<>0 Then
					Return 0
				ElseIf wParam=VK_ESCAPE Or wParam=Asc(")") Then
					' Hide list and tooltip
					ShowWindow(ah.htt,SW_HIDE)
					HideList
					If wParam=VK_ESCAPE Then
						Return 0
					EndIf
				ElseIf wParam=VK_TAB Then
					If (GetKeyState(VK_SHIFT) And &H80)<>0 Then
						SendMessage(ah.hwnd,WM_COMMAND,IDM_EDIT_BLOCKOUTDENT,0)
						Return 0
					Else
						SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
						If chrg.cpMin<>chrg.cpMax Then
							SendMessage(ah.hwnd,WM_COMMAND,IDM_EDIT_BLOCKINDENT,0)
							Return 0
						EndIf
					EndIf
				EndIf
				lret=CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
				TestCaseConvert(hPar,wParam)
				If (wParam=Asc(".") Or wParam=Asc(">")) And fconstlist=TRUE Then
					HideList
				EndIf
			TestUpdate:
				If (IsWindowVisible(ah.hcc) Or fconstlist) Then
					If fconstlist=TRUE Then
						SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
						lp=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
						chrg.cpMin=SendMessage(hPar,EM_LINEINDEX,lp,0)
						buff=Chr(255) & Chr(1)
						SendMessage(hPar,EM_GETLINE,lp,Cast(LPARAM,@buff))
						buff[chrg.cpMax-chrg.cpMin]=NULL
						tt.lpszType=StrPtr("Pp")
						tt.lpszLine=@buff
						SendMessage(ah.hpr,PRM_GETTOOLTIP,TT_NOMATCHCASE Or TT_PARANTESES,Cast(LPARAM,@tt))
						' Show tooltip
						tti.lpszApi=tt.lpszApi
						tti.lpszParam=tt.ovr(0).lpszParam
						tti.lpszRetType=tt.ovr(0).lpszRetType
						tti.nitem=tt.nPos
						UpdateConstList(tti.lpszApi,tti.nitem+1)
					Else
						SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
						isinp.nLine=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
						isinp.nOwner=Cast(Integer,hPar)
						If fProject Then
							isinp.nOwner=GetProjectFileID(hPar)
						EndIf
						isinp.lpszType=StrPtr("pxyzo")
						p=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
						If ftypelist Then
							If wParam=VK_SPACE Or wParam=VK_TAB Then
								HideList
							Else
								UpdateTypeList
							EndIf
						ElseIf fstructlist Then
							UpdateStructList(p)
						ElseIf fincludelist Then
							lret=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
							chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,lret,0)
							buff=Chr(255) & Chr(1)
							lret=SendMessage(ah.hred,EM_GETLINE,lret,Cast(LPARAM,@buff))
							buff[lret]=NULL
							lret=InStr(buff,Chr(34))
							buff=Mid(buff,lret+1)
							UpdateIncludeList()
						ElseIf fincliblist Then
							lret=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
							chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,lret,0)
							buff=Chr(255) & Chr(1)
							lret=SendMessage(ah.hred,EM_GETLINE,lret,Cast(LPARAM,@buff))
							buff[lret]=NULL
							lret=InStr(buff,Chr(34))
							buff=Mid(buff,lret+1)
							UpdateInclibList()
						Else
							UpdateList(p)
						EndIf
					EndIf
					' Move code complete list
					MoveList
				ElseIf wParam=Asc(".") And IsWindowVisible(ah.hcc)=FALSE And edtopt.codecomplete<>0 Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						fconstlist=FALSE
						IsStructList
					EndIf
				ElseIf wParam=Asc(">") And IsWindowVisible(ah.hcc)=FALSE And edtopt.codecomplete<>0 Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@trng.chrg))
					If SendMessage(hPar,REM_ISCHARPOS,trng.chrg.cpMin,0)=0 Then
						trng.chrg.cpMin=trng.chrg.cpMin-2
						trng.lpstrText=@s
						SendMessage(hPar,EM_GETTEXTRANGE,0,Cast(LPARAM,@trng))
						If s="->" Then
							fconstlist=FALSE
							IsStructList
						EndIf
					EndIf
				ElseIf (wParam=VK_TAB Or wParam=VK_SPACE) And edtopt.codecomplete<>0 Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
					If SendMessage(hPar,REM_ISCHARPOS,chrg.cpMin,0)=0 Then
						chrg.cpMin=chrg.cpMin-1
						chrg.cpMax=chrg.cpMax-1
						SendMessage(hPar,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
						SendMessage(hPar,REM_GETWORD,256,Cast(LPARAM,@s))
						chrg.cpMin=chrg.cpMin+1
						chrg.cpMax=chrg.cpMax+1
						SendMessage(hPar,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
						s=UCase(s)
						If s="AS" Then
							UpdateTypeList
							' Move code complete list
							MoveList
							ftypelist=TRUE
						EndIf
					EndIf
				ElseIf wParam=34 And edtopt.autoinclude Then
					SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
					ln=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
					s=Chr(255) & Chr(1)
					ln=SendMessage(hPar,EM_GETLINE,ln,Cast(LPARAM,@s))
					s[ln]=NULL
					s=UCase(s)
					lret=InStr(s,Chr(34))
					lret=InStr(lret+1,s,Chr(34))
					If InStr(s,"#INCLUDE")<>0 And lret=0 Then
						'reset last dir
						dirlist=""
						BuildDirList(ad.fbcPath & "\Inc",NULL,6)
						If fProject Then
							BuildDirList(ad.ProjectPath,NULL,7)
						EndIf
						UpdateIncludeList()
					ElseIf InStr(s,"#INCLIB")<>0 And lret=0 Then
						'reset last dir
						dirlist=""
						BuildDirList(ad.fbcPath & "\Lib",NULL,6)
						If fProject Then
							BuildDirList(ad.ProjectPath,NULL,7)
						EndIf
						UpdateInclibList()
					ElseIf IsWindowVisible(ah.hcc) Then
						HideList
					EndIf
				ElseIf wParam=VK_RETURN Then
					' Block Complete
					If edtopt.autoblock Then
						SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
						ln=SendMessage(hPar,EM_LINEFROMCHAR,chrg.cpMin,0)-1
						If SendMessage(hPar,REM_GETBOOKMARK,ln,0)=1 Then
							wp=0
							While wp<32
								If SendMessage(hPar,REM_ISLINE,ln,Cast(LPARAM,@szSt(wp)))>=0 Then
									lx=ln+1
									lz=0
									While lx<>-1
										lx=SendMessage(hPar,REM_PRVBOOKMARK,lx,1)
										If lx<>-1 Then
											lz=SendMessage(hPar,REM_GETBLOCKEND,lx,0)
											tp=0
											If lz=-1 Then
												tp=SendMessage(hPar,REM_ISLINE,lx,Cast(LPARAM,@szSt(wp)))
												Exit While
											ElseIf lz>ln Then
												tp=SendMessage(hPar,REM_ISLINE,lx,Cast(LPARAM,@szSt(wp)))
												If tp=-1 Then
													Exit While
												EndIf
											EndIf
										EndIf
									Wend
									If lz<>-1 Or tp=-1 Then
										SendMessage(hPar,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
										SendMessage(hPar,EM_SCROLLCARET,0,0)
										Exit While
									EndIf
									' Get indent
									buff=Chr(255) & Chr(1)
									lp=SendMessage(hPar,EM_GETLINE,ln,Cast(LPARAM,@buff))
									buff[lp]=NULL
									lz=1
									While lz<lp
										If Asc(buff,lz)<>VK_SPACE And Asc(buff,lz)<>VK_TAB Then
											buff[lz-1]=NULL
											Exit While
										EndIf
										lz=lz+1
									Wend
									' Insert the text
									buff=Chr(VK_RETURN) & buff & szEn(wp)
									If edtopt.autocase=2 Then
										buff=LCase(buff)
									ElseIf edtopt.autocase=3 Then
										buff=UCase(buff)
									EndIf
									SendMessage(hPar,EM_REPLACESEL,TRUE,Cast(LPARAM,@buff))
									SendMessage(hPar,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
									SendMessage(hPar,EM_SCROLLCARET,0,0)
									Exit While
								EndIf
								wp=wp+1
							Wend
						EndIf
					EndIf
					If edtopt.autoformat Then
						' Indent / Outdent
						SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
						ln=SendMessage(hPar,EM_LINEFROMCHAR,chrg.cpMin,0)-1
						wp=0
						While wp<32
							If szIndent(wp)<>szNULL Then
								If SendMessage(hPar,REM_ISLINE,ln,Cast(LPARAM,@szIndent(wp)))>=0 Then
									' Get current indent
									lz=0
									buff=GetIndent(hPar,ln,@szIndent(autofmt(wp).st),@lz)
									If lz=0 Then
										' Indent word line
										buff=AddIndent(autofmt(wp).add1,@buff)
										SetIndent(hPar,ln,@buff)
										' Indent caret line
										buff=AddIndent(autofmt(wp).add2,@buff)
										SetIndent(hPar,ln+1,@buff)
										Exit While
									EndIf
								EndIf
							EndIf
							wp=wp+1
						Wend
					EndIf
				EndIf
				Return lret
			EndIf
		Case WM_KEYDOWN
			If IsWindowVisible(ah.hcc) Then
				lp=(lParam Shr 16) And &H3FF
				wp=wParam
				If (wp=&H28 And (lp=&H150 Or lp=&H50)) Or (wp=&H26 And (lp=&H148 Or lp=&H48)) Or (wp=&H21 And (lp=&H149 Or lp=&H49)) Or (wp=&H22 And (lp=&H151 Or lp=&H51)) Then
					' Down / Up /PgUp / PgDn
					' Relay event to the code complete list
					PostMessage(ah.hcc,uMsg,wParam,lParam)
					Return 0
				EndIf
			ElseIf IsWindowVisible(ah.htt)<>0 And novr>1 Then
				lp=(lParam Shr 16) And &H3FF
				wp=wParam
				If wp=&H28 And (lp=&H150 Or lp=&H50) Then
					' Down
					If nsel<novr-1 Then
						nsel+=1
						hPar=GetParent(hWin)
						GoTo TT
					EndIf
					Return 0
				ElseIf wp=&H26 And (lp=&H148 Or lp=&H48) Then
					' Up
					If nsel Then
						nsel-=1
						hPar=GetParent(hWin)
						GoTo TT
					EndIf
					Return 0
				EndIf
			EndIf
			If wParam=VK_INSERT Then
				fTimer=1
			ElseIf wParam=VK_SPACE And (GetKeyState(VK_CONTROL) And &H80)<>0 Then
				' Show code complete list
				ShowWindow(ah.htt,SW_HIDE)
				HideList
				hPar=GetParent(hWin)
				SendMessage(hPar,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
				isinp.nLine=SendMessage(hPar,EM_EXLINEFROMCHAR,0,chrg.cpMax)
				isinp.nOwner=Cast(Integer,hPar)
				If fProject Then
					isinp.nOwner=GetProjectFileID(hPar)
				EndIf
				isinp.lpszType=StrPtr("pxyzo")
				p=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
				If p<>0 And (GetKeyState(VK_SHIFT) And &H80)<>0 Then
					flocallist=TRUE
				EndIf
				UpdateList(p)
				' Move code complete list
				MoveList
				Return 0
			EndIf
		Case WM_CONTEXTMENU
			If lParam=-1 Then
				GetCaretPos(@pt)
				ClientToScreen(hWin,@pt)
				pt.x=pt.x+10
			Else
				pt.x=lParam And &HFFFF
				pt.y=lParam Shr 16
			EndIf
			hMnu=GetMenu(ah.hwnd)
			hMnu=GetSubMenu(hMnu,1)
			TrackPopupMenu(hMnu,TPM_LEFTALIGN Or TPM_RIGHTBUTTON,pt.x,pt.y,0,ah.hwnd,0)
			Return 0
		Case WM_LBUTTONDOWN
			mdn=GetKeyState(VK_CONTROL) And &H80
		Case WM_LBUTTONUP
			If mdn Then
				buff=OpenInclude
				If Len(buff) Then
					OpenTheFile(buff,FALSE)
				EndIf
			EndIf
		Case WM_KILLFOCUS
			'temp fix split focus bug
			If ah.hpane(0)=0 Then
				Return CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
			EndIf
			ShowWindow(ah.hTT,SW_HIDE)
			hPar=GetParent(Cast(HWND,wParam))
			While hPar
				If hPar=ah.hres Then
					If ah.hred<>ah.hpane(0) Then
						ah.hpane(1)=ah.hred
					EndIf
					SelectTab(ah.hwnd,ah.hres,0)
					Exit While
				EndIf
				hPar=GetParent(hPar)
			Wend
		Case WM_SETFOCUS
			'temp fix split focus bug
			If ah.hpane(0)=0 Then
				Return CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)
			EndIf
			If ah.hred<>GetParent(hWin) Then
				If ah.hred<>ah.hpane(0) Then
					ah.hpane(1)=ah.hred
				EndIf
				SelectTab(ah.hwnd,GetParent(hWin),0)
			EndIf
	End Select
	Return CallWindowProc(lpOldEditProc,hWin,uMsg,wParam,lParam)

End Function

Function ParEditProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer

	Select Case uMsg
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
	Return CallWindowProc(lpOldParEditProc,hWin,uMsg,wParam,lParam)

End Function

Function CCProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer

	Select Case uMsg
		Case WM_CHAR
			If wParam=VK_TAB Or wParam=VK_RETURN Then
				SendMessage(ah.hred,WM_CHAR,VK_TAB,0)
				Return 0
			ElseIf wParam=VK_ESCAPE Then
				ShowWindow(hWin,SW_HIDE)
				ftypelist=FALSE
				fconstlist=FALSE
				fstructlist=FALSE
				flocallist=FALSE
				fincludelist=FALSE
				fincliblist=FALSE
				Return 0
			EndIf
			'
		Case WM_LBUTTONDBLCLK
			SendMessage(ah.hred,WM_CHAR,VK_TAB,0)
			Return 0
			'
		Case WM_ACTIVATE
			SendMessage(ah.hwnd,WM_NCACTIVATE,TRUE,0)
			'
	End Select
	Return CallWindowProc(lpOldCCProc,hWin,uMsg,wParam,lParam)

End Function

Sub UpdateEditOption(hEdt As HWND)
	Dim style As Integer
	
	SendMessage(hEdt,REM_SETCOLOR,0,Cast(Integer,@fbcol.racol))
	SendMessage(hEdt,REM_SETFONT,0,Cast(Integer,@ah.rafnt))
	SendMessage(hEdt,REM_TABWIDTH,edtopt.tabsize,edtopt.expand)
	SendMessage(hEdt,REM_AUTOINDENT,0,edtopt.autoindent)
	style=GetWindowLong(hEdt,GWL_STYLE)
	style=style And (-1 Xor STYLE_HILITECOMMENT)
	If edtopt.hilitecmnt Then
		style=style Or STYLE_HILITECOMMENT
	EndIf
	SetWindowLong(hEdt,GWL_STYLE,style)

End Sub

Function FileType(ByVal sFile As String) As Integer
	Dim sItem As String

	sItem=GetFileExt(sFile) & "."
	If InStr(UCase(sCodeFiles),UCase(sItem)) Then
		Return 1
	ElseIf UCase(Right(sFile,3))=".RC" Then
		Return 2
	ElseIf UCase(Right(sFile,4))=".HLP" Then
		Return 3
	ElseIf UCase(Right(sFile,4))=".CHM" Then
		Return 4
	ElseIf UCase(Right(sFile,4))=".FBP" Then
		Return 5
	EndIf
	Return 0

End Function

Sub HH_Help()

	If hHtmlOcx=0 Then
		hHtmlOcx=LoadLibrary(StrPtr("hhctrl.ocx"))
		pHtmlHelpProc=GetProcAddress(hHtmlOcx,StrPtr("HtmlHelpA"))
	EndIf
	If hHtmlOcx Then
		hhaklink.cbStruct=SizeOf(HH_AKLINK)
		hhaklink.fReserved=FALSE
		hhaklink.pszKeywords=@s
		hhaklink.pszUrl=NULL
		hhaklink.pszMsgText=NULL
		hhaklink.pszMsgTitle=NULL
		hhaklink.pszWindow=NULL
		hhaklink.fIndexOnFail=FALSE
		Asm
			'HtmlHelp(0,@buff,HH_DISPLAY_TOPIC,NULL)
			push	0
			push	HH_DISPLAY_TOPIC
			lea	eax,buff
			push	eax
			push	0
			Call	[pHtmlHelpProc]
			mov	hHHwin,eax
			lea	eax,hhaklink
			push	eax
			push	HH_KEYWORD_LOOKUP
			lea	eax,buff
			push	eax
			push	0
			Call	[pHtmlHelpProc]
		End Asm
	EndIf

End Sub

Sub EnableDisable(ByVal bm As Long,ByVal id As Long)
	Dim hMnu As HMENU

	hMnu=GetMenu(ah.hwnd)
	EnableMenuItem(hMnu,id,IIf(bm,MF_ENABLED,MF_GRAYED))
	SendMessage(ah.htoolbar,TB_ENABLEBUTTON,id,IIf(bm,TRUE,FALSE))
	
End Sub

Sub EnableDisableContext(ByVal bm As Long,ByVal id As Long)
	Dim hMnu As HMENU

	hMnu=GetMenu(ah.hwnd)
	EnableMenuItem(ah.hcontextmenu,id,IIf(bm,MF_ENABLED,MF_GRAYED))
	
End Sub

Sub TrimTrailingSpaces
	Dim chrg As CHARRANGE
	Dim LnSt As Integer
	Dim LnEn As Integer

	SendMessage(ah.hred,WM_SETREDRAW,FALSE,0)
	SendMessage(ah.hred,REM_LOCKUNDOID,TRUE,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	LnSt=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)
	If chrg.cpMax>chrg.cpMin Then
		chrg.cpMax=chrg.cpMax-1
	EndIf
	chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,LnSt,0)
	LnEn=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
	Do While LnSt<=LnEn
		SendMessage(ah.hred,REM_TRIMSPACE,LnSt,FALSE)
		LnSt=LnSt+1
	Loop
	chrg.cpMax=SendMessage(ah.hred,EM_LINEINDEX,LnEn,0)
	chrg.cpMax=chrg.cpMax+SendMessage(ah.hred,EM_LINELENGTH,chrg.cpMax,0)+1
	SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@chrg))
	SendMessage(ah.hred,REM_LOCKUNDOID,FALSE,0)
	SendMessage(ah.hred,WM_SETREDRAW,TRUE,0)
	SendMessage(ah.hred,REM_REPAINT,0,0)
	SetFocus(ah.hred)

End Sub

Sub IndentComment(ByVal char As String,ByVal fUn As Boolean)
	Dim ochrg As CHARRANGE
	Dim chrg As CHARRANGE
	Dim LnSt As Integer
	Dim LnEn As Integer
	Dim LnCnt As Integer
	Dim buffer As String*32
	Dim tmp As Integer

	SendMessage(ah.hred,WM_SETREDRAW,FALSE,0)
	SendMessage(ah.hred,REM_LOCKUNDOID,TRUE,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(LPARAM,@ochrg))
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
	SendMessage(ah.hred,EM_HIDESELECTION,TRUE,0)
	LnSt=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)
	If chrg.cpMax>chrg.cpMin Then
		chrg.cpMax=chrg.cpMax-1
	EndIf
	LnEn=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
	LnCnt=LnEn-LnSt
	If LnCnt Then
		ochrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,LnSt,0)
		ochrg.cpMax=SendMessage(ah.hred,EM_LINEINDEX,LnEn,0)
		ochrg.cpMax=ochrg.cpMax+SendMessage(ah.hred,EM_LINELENGTH,ochrg.cpMax,0)+1
	Else
		If ochrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,LnSt,0) And ochrg.cpMax=SendMessage(ah.hred,EM_LINEINDEX,LnEn+1,0) Then
			LnCnt=1
		EndIf
	EndIf
	Do While LnSt<=LnEn
		If fUn Then
			' Uncomment or Outdent
			chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,LnSt,0)
			chrg.cpMax=chrg.cpMin+1
			SendMessage(ah.hred,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
			SendMessage(ah.hred,EM_GETSELTEXT,0,Cast(LPARAM,@buffer))
			If char=buffer Then
				SendMessage(ah.hred,EM_REPLACESEL,TRUE,Cast(LPARAM,StrPtr("")))
				ochrg.cpMax=ochrg.cpMax-1
				If LnCnt=0 Then
					ochrg.cpMin=ochrg.cpMin-1
				EndIf
			ElseIf char=Chr(9) Then
				tmp=edtopt.tabsize
				While tmp
					chrg.cpMax=chrg.cpMin+tmp
					SendMessage(ah.hred,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
					SendMessage(ah.hred,EM_GETSELTEXT,0,Cast(LPARAM,@buffer))
					If buffer=Space(tmp) Then
						SendMessage(ah.hred,EM_REPLACESEL,TRUE,Cast(LPARAM,StrPtr("")))
						ochrg.cpMax=ochrg.cpMax-tmp
						If LnCnt=0 Then
							ochrg.cpMin=ochrg.cpMin-tmp
						EndIf
						Exit While
					EndIf
					tmp=tmp-1
				Wend
			EndIf
		Else
			' Comment or Indent
			chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,LnSt,0)
			chrg.cpMax=chrg.cpMin
			SendMessage(ah.hred,EM_EXSETSEL,0,Cast(LPARAM,@chrg))
			If char=Chr(9) And edtopt.expand Then
				buffer=Space(edtopt.tabsize)
				SendMessage(ah.hred,EM_REPLACESEL,TRUE,Cast(LPARAM,@buffer))
				ochrg.cpMax=ochrg.cpMax+edtopt.tabsize
				If LnCnt=0 Then
					ochrg.cpMin=ochrg.cpMin+edtopt.tabsize
				EndIf
			Else
				SendMessage(ah.hred,EM_REPLACESEL,TRUE,Cast(LPARAM,@char))
				ochrg.cpMax=ochrg.cpMax+1
				If LnCnt=0 Then
					ochrg.cpMin=ochrg.cpMin+1
				EndIf
			EndIf
		EndIf
		LnSt=LnSt+1
	Loop
	SendMessage(ah.hred,EM_EXSETSEL,0,Cast(LPARAM,@ochrg))
	SendMessage(ah.hred,EM_HIDESELECTION,FALSE,0)
	SendMessage(ah.hred,REM_LOCKUNDOID,FALSE,0)
	SendMessage(ah.hred,WM_SETREDRAW,TRUE,0)
	SendMessage(ah.hred,REM_REPAINT,0,0)
	SetFocus(ah.hred)

End Sub


Sub CheckMenu()

	CheckMenuItem(ah.hmenu,IDM_VIEW_OUTPUT,IIf(wpos.fview And VIEW_OUTPUT,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hmenu,IDM_VIEW_PROJECT,IIf(wpos.fview And VIEW_PROJECT,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hmenu,IDM_VIEW_PROPERTY,IIf(wpos.fview And VIEW_PROPERTY,MF_CHECKED,MF_UNCHECKED))

	CheckMenuItem(ah.hmenu,IDM_VIEW_TOOLBAR,IIf(wpos.fview And VIEW_TOOLBAR,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hmenu,IDM_VIEW_TABSELECT,IIf(wpos.fview And VIEW_TABSELECT,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hmenu,IDM_VIEW_STATUSBAR,IIf(wpos.fview And VIEW_STATUSBAR,MF_CHECKED,MF_UNCHECKED))

	CheckMenuItem(ah.hmenu,IDM_FORMAT_LOCK,IIf(SendMessage(ah.hraresed,DEM_ISLOCKED,0,0),MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hmenu,IDM_FORMAT_GRID,IIf(GetWindowLong(ah.hraresed,GWL_STYLE) And DES_GRID,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hmenu,IDM_FORMAT_SNAP,IIf(GetWindowLong(ah.hraresed,GWL_STYLE) And DES_SNAPTOGRID,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hcontextmenu,IDM_FORMAT_LOCK,IIf(SendMessage(ah.hraresed,DEM_ISLOCKED,0,0),MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hcontextmenu,IDM_FORMAT_GRID,IIf(GetWindowLong(ah.hraresed,GWL_STYLE) And DES_GRID,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(ah.hcontextmenu,IDM_FORMAT_SNAP,IIf(GetWindowLong(ah.hraresed,GWL_STYLE) And DES_SNAPTOGRID,MF_CHECKED,MF_UNCHECKED))

End Sub

Sub EnableMenu()
	Dim bm As Integer
	Dim chrg As CHARRANGE
	Dim id As Integer

	If ah.hred=ah.hres Then

		EnableDisable(FALSE,IDM_FILE_PRINT)

		EnableDisable(FALSE,IDM_EDIT_GOTO)
		EnableDisable(FALSE,IDM_EDIT_FIND)
		EnableDisable(FALSE,IDM_EDIT_FINDNEXT)
		EnableDisable(FALSE,IDM_EDIT_FINDPREVIOUS)
		EnableDisable(FALSE,IDM_EDIT_REPLACE)
		EnableDisable(FALSE,IDM_EDIT_FINDDECLARE)
		EnableDisable(FALSE,IDM_EDIT_RETURN)

		EnableDisable(FALSE,IDM_EDIT_BLOCKINDENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKOUTDENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKCOMMENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKUNCOMMENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKTRIM)
		EnableDisable(FALSE,IDM_EDIT_CONVERTTAB)
		EnableDisable(FALSE,IDM_EDIT_CONVERTSPACE)
		EnableDisable(FALSE,IDM_EDIT_CONVERTUPPER)
		EnableDisable(FALSE,IDM_EDIT_CONVERTLOWER)
		EnableDisable(FALSE,IDM_EDIT_BLOCKMODE)
		EnableDisable(FALSE,IDM_EDIT_BLOCK_INSERT)
		EnableDisable(FALSE,IDM_EDIT_EXPAND)

		bm=SendMessage(ah.hraresed,DEM_CANUNDO,0,0)
		EnableDisable(bm,IDM_EDIT_UNDO)
		bm=SendMessage(ah.hraresed,DEM_CANREDO,0,0)
		EnableDisable(bm,IDM_EDIT_REDO)

		bm=SendMessage(ah.hraresed,DEM_ISSELECTION,0,0)
		EnableDisable(bm,IDM_EDIT_CUT)
		EnableDisable(bm,IDM_EDIT_COPY)
		EnableDisable(bm,IDM_EDIT_DELETE)
		EnableDisableContext(bm,IDM_EDIT_CUT)
		EnableDisableContext(bm,IDM_EDIT_COPY)
		EnableDisableContext(bm,IDM_EDIT_DELETE)
		EnableDisable(FALSE,IDM_EDIT_SELECTALL)

		EnableDisable(bm,IDM_FORMAT_CENTER)
		EnableDisableContext(bm,IDM_FORMAT_CENTER)
		If bm<>2 Then
			bm=0
		EndIf
		EnableDisable(bm,IDM_FORMAT_ALIGN)
		EnableDisable(bm,IDM_FORMAT_SIZE)
		EnableDisable(bm,IDM_FORMAT_RENUM)
		EnableDisableContext(bm,IDM_FORMAT_ALIGN)
		EnableDisableContext(bm,IDM_FORMAT_SIZE)
		EnableDisableContext(bm,IDM_FORMAT_RENUM)

		bm=SendMessage(ah.hraresed,DEM_CANPASTE,0,0)
		EnableDisable(bm,IDM_EDIT_PASTE)
		EnableDisableContext(bm,IDM_EDIT_PASTE)

		EnableDisable(FALSE,IDM_EDIT_BOOKMARKTOGGLE)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKNEXT)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKPREVIOUS)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKDELETE)
		EnableDisable(FALSE,IDM_EDIT_ERRORCLEAR)
		EnableDisable(FALSE,IDM_EDIT_ERRORNEXT)

		EnableDisable(TRUE,IDM_FORMAT_LOCK)
		EnableDisableContext(TRUE,IDM_FORMAT_LOCK)
		bm=SendMessage(ah.hraresed,DEM_ISBACK,0,0) Xor TRUE
		EnableDisable(bm,IDM_FORMAT_BACK)
		EnableDisableContext(bm,IDM_FORMAT_BACK)
		bm=SendMessage(ah.hraresed,DEM_ISFRONT,0,0) Xor TRUE
		EnableDisable(bm,IDM_FORMAT_FRONT)
		EnableDisableContext(bm,IDM_FORMAT_FRONT)
		EnableDisable(TRUE,IDM_FORMAT_GRID)
		EnableDisable(TRUE,IDM_FORMAT_SNAP)
		EnableDisable(TRUE,IDM_FORMAT_TAB)
		EnableDisableContext(TRUE,IDM_FORMAT_GRID)
		EnableDisableContext(TRUE,IDM_FORMAT_SNAP)
		EnableDisableContext(TRUE,IDM_FORMAT_TAB)

		EnableDisable(FALSE,IDM_FORMAT_CASECONVERT)
		EnableDisable(FALSE,IDM_FORMAT_INDENT)

		EnableDisable(TRUE,IDM_VIEW_DIALOG)
		EnableDisable(FALSE,IDM_VIEW_SPLITSCREEN)
		EnableDisable(TRUE,IDM_VIEW_FULLSCREEN)
		EnableDisable(TRUE,IDM_VIEW_DUALPANE)

		EnableDisable(TRUE,IDM_RESOURCE_DIALOG)
		EnableDisable(TRUE,IDM_RESOURCE_MENU)
		EnableDisable(TRUE,IDM_RESOURCE_ACCEL)
		EnableDisable(TRUE,IDM_RESOURCE_STRINGTABLE)
		EnableDisable(TRUE,IDM_RESOURCE_VERSION)
		EnableDisable(TRUE,IDM_RESOURCE_XPMANIFEST)
		EnableDisable(TRUE,IDM_RESOURCE_RCDATA)
		EnableDisable(TRUE,IDM_RESOURCE_LANGUAGE)
		EnableDisable(TRUE,IDM_RESOURCE_INCLUDE)
		EnableDisable(TRUE,IDM_RESOURCE_RES)
		EnableDisable(TRUE,IDM_RESOURCE_NAMES)
		EnableDisable(TRUE,IDM_RESOURCE_EXPORT)
		EnableDisable(TRUE,IDM_RESOURCE_REMOVE)
		EnableDisable(TRUE,IDM_RESOURCE_UNDO)

		EnableDisable(FALSE,IDM_MAKE_QUICKRUN)
		EnableDisableContext(FALSE,IDM_PROPERTY_JUMP)
		EnableDisableContext(FALSE,IDM_PROPERTY_COPY)
	ElseIf ah.hred=0 Then
		EnableDisable(FALSE,IDM_FILE_PRINT)
		EnableDisable(FALSE,IDM_EDIT_GOTO)
		EnableDisable(FALSE,IDM_EDIT_FIND)
		EnableDisable(FALSE,IDM_EDIT_FINDNEXT)
		EnableDisable(FALSE,IDM_EDIT_FINDPREVIOUS)
		EnableDisable(FALSE,IDM_EDIT_REPLACE)
		EnableDisable(FALSE,IDM_EDIT_FINDDECLARE)
		EnableDisable(FALSE,IDM_EDIT_RETURN)
		EnableDisable(FALSE,IDM_EDIT_BLOCKINDENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKOUTDENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKCOMMENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKUNCOMMENT)
		EnableDisable(FALSE,IDM_EDIT_BLOCKTRIM)
		EnableDisable(FALSE,IDM_EDIT_CONVERTTAB)
		EnableDisable(FALSE,IDM_EDIT_CONVERTSPACE)
		EnableDisable(FALSE,IDM_EDIT_CONVERTUPPER)
		EnableDisable(FALSE,IDM_EDIT_CONVERTLOWER)
		EnableDisable(FALSE,IDM_EDIT_BLOCKMODE)
		EnableDisable(FALSE,IDM_EDIT_BLOCK_INSERT)
		EnableDisable(FALSE,IDM_EDIT_UNDO)
		EnableDisable(FALSE,IDM_EDIT_REDO)
		EnableDisable(FALSE,IDM_EDIT_CUT)
		EnableDisable(FALSE,IDM_EDIT_COPY)
		EnableDisable(FALSE,IDM_EDIT_DELETE)
		EnableDisable(FALSE,IDM_EDIT_PASTE)
		EnableDisable(FALSE,IDM_EDIT_SELECTALL)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKTOGGLE)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKNEXT)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKPREVIOUS)
		EnableDisable(FALSE,IDM_EDIT_BOOKMARKDELETE)
		EnableDisable(FALSE,IDM_EDIT_ERRORCLEAR)
		EnableDisable(FALSE,IDM_EDIT_ERRORNEXT)
		EnableDisable(FALSE,IDM_EDIT_EXPAND)
		EnableDisable(FALSE,IDM_FORMAT_LOCK)
		EnableDisable(FALSE,IDM_FORMAT_BACK)
		EnableDisable(FALSE,IDM_FORMAT_FRONT)
		EnableDisable(FALSE,IDM_FORMAT_GRID)
		EnableDisable(FALSE,IDM_FORMAT_SNAP)
		EnableDisable(FALSE,IDM_FORMAT_ALIGN)
		EnableDisable(FALSE,IDM_FORMAT_SIZE)
		EnableDisable(FALSE,IDM_FORMAT_CENTER)
		EnableDisable(FALSE,IDM_FORMAT_TAB)
		EnableDisable(FALSE,IDM_FORMAT_RENUM)
		EnableDisable(FALSE,IDM_FORMAT_CASECONVERT)
		EnableDisable(FALSE,IDM_FORMAT_INDENT)
		EnableDisable(FALSE,IDM_VIEW_DIALOG)
		EnableDisable(FALSE,IDM_VIEW_SPLITSCREEN)
		EnableDisable(FALSE,IDM_VIEW_FULLSCREEN)
		EnableDisable(FALSE,IDM_VIEW_DUALPANE)
		EnableDisable(FALSE,IDM_RESOURCE_DIALOG)
		EnableDisable(FALSE,IDM_RESOURCE_MENU)
		EnableDisable(FALSE,IDM_RESOURCE_ACCEL)
		EnableDisable(FALSE,IDM_RESOURCE_STRINGTABLE)
		EnableDisable(FALSE,IDM_RESOURCE_VERSION)
		EnableDisable(FALSE,IDM_RESOURCE_XPMANIFEST)
		EnableDisable(FALSE,IDM_RESOURCE_RCDATA)
		EnableDisable(FALSE,IDM_RESOURCE_LANGUAGE)
		EnableDisable(FALSE,IDM_RESOURCE_INCLUDE)
		EnableDisable(FALSE,IDM_RESOURCE_RES)
		EnableDisable(FALSE,IDM_RESOURCE_NAMES)
		EnableDisable(FALSE,IDM_RESOURCE_EXPORT)
		EnableDisable(FALSE,IDM_RESOURCE_REMOVE)
		EnableDisable(FALSE,IDM_RESOURCE_UNDO)

		EnableDisable(FALSE,IDM_MAKE_QUICKRUN)

		EnableDisableContext(FALSE,IDM_PROPERTY_JUMP)
		EnableDisableContext(FALSE,IDM_PROPERTY_COPY)
	Else
		id=GetWindowLong(ah.hred,GWL_ID)
		EnableDisable(TRUE,IDM_FILE_PRINT)
		EnableDisable(TRUE,IDM_EDIT_GOTO)
		EnableDisable(TRUE,IDM_EDIT_FIND)
		EnableDisable(TRUE,IDM_EDIT_FINDNEXT)
		EnableDisable(TRUE,IDM_EDIT_FINDPREVIOUS)
		EnableDisable(TRUE,IDM_EDIT_REPLACE)
		If fdc(fdcpos).hwnd Then
			EnableDisable(TRUE,IDM_EDIT_RETURN)
		Else
			EnableDisable(FALSE,IDM_EDIT_RETURN)
		EndIf
		bm=0
		If id=IDC_CODEED Then
			bm=1
		EndIf
		EnableDisable(bm,IDM_EDIT_FINDDECLARE)
		EnableDisable(bm,IDM_EDIT_BLOCKINDENT)
		EnableDisable(bm,IDM_EDIT_BLOCKOUTDENT)
		EnableDisable(bm,IDM_EDIT_BLOCKCOMMENT)
		EnableDisable(bm,IDM_EDIT_BLOCKUNCOMMENT)
		EnableDisable(bm,IDM_EDIT_BLOCKMODE)
		EnableDisable(bm,IDM_EDIT_EXPAND)
		EnableDisable(bm,IDM_FORMAT_CASECONVERT)
		EnableDisable(bm,IDM_FORMAT_INDENT)
		EnableDisable(bm,IDM_MAKE_QUICKRUN)
		bm=SendMessage(ah.hred,EM_CANUNDO,0,0)
		EnableDisable(bm,IDM_EDIT_UNDO)
		bm=SendMessage(ah.hred,EM_CANREDO,0,0)
		EnableDisable(bm,IDM_EDIT_REDO)
		SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
		bm=chrg.cpMax-chrg.cpMin
		EnableDisable(bm,IDM_EDIT_CUT)
		EnableDisable(bm,IDM_EDIT_COPY)
		EnableDisable(bm,IDM_EDIT_DELETE)
		If id<>IDC_CODEED Then
			bm=0
		EndIf
		EnableDisable(bm,IDM_EDIT_BLOCKTRIM)
		EnableDisable(bm,IDM_EDIT_CONVERTTAB)
		EnableDisable(bm,IDM_EDIT_CONVERTSPACE)
		EnableDisable(bm,IDM_EDIT_CONVERTUPPER)
		EnableDisable(bm,IDM_EDIT_CONVERTLOWER)
		bm=SendMessage(ah.hred,EM_CANPASTE,CF_TEXT,0)
		EnableDisable(bm,IDM_EDIT_PASTE)
		EnableDisable(TRUE,IDM_EDIT_SELECTALL)
		EnableDisable(TRUE,IDM_EDIT_BOOKMARKTOGGLE)
		If id=IDC_CODEED Then
			bm=SendMessage(ah.hred,REM_GETMODE,0,0) And MODE_BLOCK
			EnableDisable(bm,IDM_EDIT_BLOCK_INSERT)
			bm=SendMessage(ah.hred,REM_NXTBOOKMARK,nLastLine,3)+1
			EnableDisable(bm,IDM_EDIT_BOOKMARKNEXT)
			bm=SendMessage(ah.hred,REM_PRVBOOKMARK,nLastLine,3)+1
			EnableDisable(bm,IDM_EDIT_BOOKMARKPREVIOUS)
			bm=SendMessage(ah.hred,REM_NXTBOOKMARK,-1,3)+1
			EnableDisable(bm,IDM_EDIT_BOOKMARKDELETE)
	
			bm=SendMessage(ah.hred,REM_NXTBOOKMARK,-1,7)+1
			EnableDisable(bm,IDM_EDIT_ERRORCLEAR)
			EnableDisable(bm,IDM_EDIT_ERRORNEXT)
		Else
			EnableDisable(FALSE,IDM_EDIT_BLOCK_INSERT)
			bm=SendMessage(ah.hred,HEM_ANYBOOKMARKS,0,0)
			EnableDisable(bm,IDM_EDIT_BOOKMARKNEXT)
			EnableDisable(bm,IDM_EDIT_BOOKMARKPREVIOUS)
			EnableDisable(bm,IDM_EDIT_BOOKMARKDELETE)

			EnableDisable(FALSE,IDM_EDIT_ERRORCLEAR)
			EnableDisable(FALSE,IDM_EDIT_ERRORNEXT)
		EndIf

		EnableDisable(FALSE,IDM_FORMAT_LOCK)
		EnableDisable(FALSE,IDM_FORMAT_BACK)
		EnableDisable(FALSE,IDM_FORMAT_FRONT)
		EnableDisable(FALSE,IDM_FORMAT_GRID)
		EnableDisable(FALSE,IDM_FORMAT_SNAP)
		EnableDisable(FALSE,IDM_FORMAT_ALIGN)
		EnableDisable(FALSE,IDM_FORMAT_SIZE)
		EnableDisable(FALSE,IDM_FORMAT_CENTER)
		EnableDisable(FALSE,IDM_FORMAT_TAB)
		EnableDisable(FALSE,IDM_FORMAT_RENUM)

		EnableDisable(FALSE,IDM_VIEW_DIALOG)
		EnableDisable(TRUE,IDM_VIEW_SPLITSCREEN)
		EnableDisable(TRUE,IDM_VIEW_FULLSCREEN)
		EnableDisable(TRUE,IDM_VIEW_DUALPANE)
		EnableDisable(FALSE,IDM_RESOURCE_DIALOG)
		EnableDisable(FALSE,IDM_RESOURCE_MENU)
		EnableDisable(FALSE,IDM_RESOURCE_ACCEL)
		EnableDisable(FALSE,IDM_RESOURCE_STRINGTABLE)
		EnableDisable(FALSE,IDM_RESOURCE_VERSION)
		EnableDisable(FALSE,IDM_RESOURCE_XPMANIFEST)
		EnableDisable(FALSE,IDM_RESOURCE_RCDATA)
		EnableDisable(FALSE,IDM_RESOURCE_LANGUAGE)
		EnableDisable(FALSE,IDM_RESOURCE_INCLUDE)
		EnableDisable(FALSE,IDM_RESOURCE_RES)
		EnableDisable(FALSE,IDM_RESOURCE_NAMES)
		EnableDisable(FALSE,IDM_RESOURCE_EXPORT)
		EnableDisable(FALSE,IDM_RESOURCE_REMOVE)
		EnableDisable(FALSE,IDM_RESOURCE_UNDO)

		If SendMessage(ah.hpr,PRM_GETCURSEL,0,0)=LB_ERR Then
			EnableDisableContext(FALSE,IDM_PROPERTY_JUMP)
			EnableDisableContext(FALSE,IDM_PROPERTY_COPY)
		Else
			EnableDisableContext(TRUE,IDM_PROPERTY_JUMP)
			EnableDisableContext(TRUE,IDM_PROPERTY_COPY)
		EndIf
	EndIf
	If fProject Then
		EnableDisable(TRUE,IDM_FILE_CLOSEPROJECT)
		EnableDisable(TRUE,IDM_PROJECT_ADDNEWFILE)
		EnableDisable(TRUE,IDM_PROJECT_ADDNEWMODULE)
		EnableDisable(TRUE,IDM_PROJECT_ADDEXISTINGFILE)
		EnableDisable(TRUE,IDM_PROJECT_ADDEXISTINGMODULE)
		EnableDisable(TRUE,IDM_PROJECT_SETMAIN)
		EnableDisable(TRUE,IDM_PROJECT_TOGGLE)
		EnableDisable(TRUE,IDM_PROJECT_REMOVE)
		EnableDisable(TRUE,IDM_PROJECT_RENAME)
		EnableDisable(TRUE,IDM_PROJECT_OPTIONS)
		EnableDisable(TRUE,IDM_PROJECT_CREATETEMPLATE)
		EnableDisableContext(TRUE,IDM_FILE_CLOSEPROJECT)
		EnableDisableContext(TRUE,IDM_PROJECT_ADDNEWFILE)
		EnableDisableContext(TRUE,IDM_PROJECT_ADDNEWMODULE)
		EnableDisableContext(TRUE,IDM_PROJECT_ADDEXISTINGFILE)
		EnableDisableContext(TRUE,IDM_PROJECT_ADDEXISTINGMODULE)
		EnableDisableContext(TRUE,IDM_PROJECT_SETMAIN)
		EnableDisableContext(TRUE,IDM_PROJECT_TOGGLE)
		EnableDisableContext(TRUE,IDM_PROJECT_REMOVE)
		EnableDisableContext(TRUE,IDM_PROJECT_RENAME)
		EnableDisableContext(TRUE,IDM_PROJECT_OPTIONS)
	Else
		EnableDisable(FALSE,IDM_FILE_CLOSEPROJECT)
		EnableDisable(FALSE,IDM_PROJECT_ADDNEWFILE)
		EnableDisable(FALSE,IDM_PROJECT_ADDNEWMODULE)
		EnableDisable(FALSE,IDM_PROJECT_ADDEXISTINGFILE)
		EnableDisable(FALSE,IDM_PROJECT_ADDEXISTINGMODULE)
		EnableDisable(FALSE,IDM_PROJECT_SETMAIN)
		EnableDisable(FALSE,IDM_PROJECT_TOGGLE)
		EnableDisable(FALSE,IDM_PROJECT_REMOVE)
		EnableDisable(FALSE,IDM_PROJECT_RENAME)
		EnableDisable(FALSE,IDM_PROJECT_OPTIONS)
		EnableDisable(FALSE,IDM_PROJECT_CREATETEMPLATE)
		EnableDisableContext(FALSE,IDM_FILE_CLOSEPROJECT)
		EnableDisableContext(FALSE,IDM_PROJECT_ADDNEWFILE)
		EnableDisableContext(FALSE,IDM_PROJECT_ADDNEWMODULE)
		EnableDisableContext(FALSE,IDM_PROJECT_ADDEXISTINGFILE)
		EnableDisableContext(FALSE,IDM_PROJECT_ADDEXISTINGMODULE)
		EnableDisableContext(FALSE,IDM_PROJECT_SETMAIN)
		EnableDisableContext(FALSE,IDM_PROJECT_TOGGLE)
		EnableDisableContext(FALSE,IDM_PROJECT_REMOVE)
		EnableDisableContext(FALSE,IDM_PROJECT_RENAME)
		EnableDisableContext(FALSE,IDM_PROJECT_OPTIONS)
	EndIf

End Sub

Sub SetWinCaption()

	If ah.hred Then
		If fProject Then
			SetWindowText(ah.hwnd,"FreeBASIC editor - " & ProjectDescription & " - ["& ad.filename & "]")
		Else
			SetWindowText(ah.hwnd,"FreeBASIC editor - " & ad.filename)
		EndIf
	Else
		If fProject Then
			SetWindowText(ah.hwnd,"FreeBASIC editor - " & ProjectDescription)
		Else
			SetWindowText(ah.hwnd,"FreeBASIC editor")
		EndIf
	EndIf

End Sub

Function IsResOpen() As HWND
	Dim tci As TCITEM
	Dim lpTABMEM As TABMEM Ptr
	Dim i As Integer

	tci.mask=TCIF_PARAM
	i=0
	Do While TRUE
		If SendMessage(ah.htabtool,TCM_GETITEM,i,Cast(Integer,@tci)) Then
			lpTABMEM=Cast(TABMEM Ptr,tci.lParam)
			If GetWindowLong(lpTABMEM->hedit,GWL_ID)=IDC_RESED Then
				Return lpTABMEM->hedit
			EndIf
		Else
			Exit Do
		EndIf
		i=i+1
	Loop
	Return 0

End Function

Sub UpdateFileProperty
	Dim nInx As Integer

	If fProject Then
		nInx=IsProjectFile(ad.filename)
		SendMessage(ah.hpr,PRM_SELOWNER,nInx,0)
	Else
		SendMessage(ah.hpr,PRM_SELOWNER,Cast(Integer,ah.hred),0)
	EndIf

End Sub

Sub ShowProjectTab()

	If SendMessage(ah.htab,TCM_GETCURSEL,0,0)=0 Then
		' File browser
		ShowWindow(ah.hfib,SW_SHOWNA)
		ShowWindow(ah.hprj,SW_HIDE)
	Else
		' Project browser
		ShowWindow(ah.hprj,SW_SHOWNA)
		ShowWindow(ah.hfib,SW_HIDE)
	EndIf

End Sub

Sub OpenMruProjects
	Dim sFile As ZString*260
	Dim As Integer i,j,x
	Dim hMnu As HMENU

	hMnu=GetSubMenu(GetMenu(ah.hwnd),0)
	For i=1 To 4
		DeleteMenu(hMnu,14000+i,MF_BYCOMMAND)
	Next i
	j=1
	For i=1 To 4
		If GetPrivateProfileString(StrPtr("MruProject"),Str(i),@szNULL,@sFile,SizeOf(sFile),@ad.IniFile) Then
			x=InStr(sFile,",")
			If x Then
				If GetFileAttributes(Mid(sFile,x+1))<>-1 Then
					AppendMenu(hMnu,MF_STRING,14000+j,"&" & Str(j) & " " & Left(sFile,x-1))
					MruProject(j-1)=sFile
					j=j+1
				EndIf
			EndIf
		EndIf
	Next i
	CallAddins(ah.hwnd,AIM_MENUREFRESH,0,0,HOOK_MENUREFRESH)

End Sub

Sub AddMruProject
	Dim sItem As ZString*260
	Dim i As Integer
	Dim x As Integer
	Dim hMnu As HMENU

	hMnu=GetSubMenu(GetMenu(ah.hwnd),0)
	For i=0 To 3
		x=InStr(MruProject(i),",")
		sItem=Mid(MruProject(i),x+1)
		If lstrcmpi(@sItem,@ad.ProjectFile)=0 Then
			For x=i To 2
				MruProject(x)=MruProject(x+1)
			Next x
			MruProject(3)=""
		EndIf
	Next i
	For i=3 To 1 Step -1
		MruProject(i)=MruProject(i-1)
	Next i
	MruProject(0)=ProjectDescription & "," & ad.ProjectFile
	For i=1 To 4
		DeleteMenu(hMnu,14000+i,MF_BYCOMMAND)
		WritePrivateProfileString(StrPtr("MruProject"),Str(i),@MruProject(i-1),@ad.IniFile)
		x=InStr(MruProject(i-1),",")
		If x Then
			AppendMenu(hMnu,MF_STRING,14000+i,"&" & Str(i) & " " & Left(MruProject(i-1),x-1))
		EndIf
	Next i
	CallAddins(ah.hwnd,AIM_MENUREFRESH,0,0,HOOK_MENUREFRESH)

End Sub

Sub OpenMruFiles
	Dim sFile As ZString*260
	Dim As Integer i,j,x
	Dim mii As MENUITEMINFO

	mii.cbSize=SizeOf(MENUITEMINFO)
	mii.fMask=MIIM_SUBMENU
	GetMenuItemInfo(ah.hmenu,IDM_FILE_RECENTFILE,FALSE,@mii)
	For i=1 To 9
		DeleteMenu(mii.hSubMenu,15000+i,MF_BYCOMMAND)
	Next i
	j=1
	For i=1 To 9
		If GetPrivateProfileString(StrPtr("MruFile"),Str(i),@szNULL,@sFile,SizeOf(sFile),@ad.IniFile) Then
			x=InStr(sFile,",")
			If x Then
				If GetFileAttributes(Mid(sFile,x+1))<>-1 Then
					AppendMenu(mii.hSubMenu,MF_STRING,15000+j,"&" & Str(j) & " " & Left(sFile,x-1))
					MruFile(j-1)=sFile
					j=j+1
				EndIf
			EndIf
		EndIf
	Next i
	CallAddins(ah.hwnd,AIM_MENUREFRESH,0,0,HOOK_MENUREFRESH)

End Sub

Sub AddMruFile(ByVal sFile As String)
	Dim sItem As ZString*260
	Dim i As Integer
	Dim x As Integer
	Dim mii As MENUITEMINFO

	mii.cbSize=SizeOf(MENUITEMINFO)
	mii.fMask=MIIM_SUBMENU
	GetMenuItemInfo(ah.hmenu,IDM_FILE_RECENTFILE,FALSE,@mii)
	For i=0 To 8
		x=InStr(MruFile(i),",")
		sItem=Mid(MruFile(i),x+1)
		If lstrcmpi(@sItem,sFile)=0 Then
			For x=i To 7
				MruFile(x)=MruFile(x+1)
			Next x
			MruFile(8)=""
		EndIf
	Next i
	For i=8 To 1 Step -1
		MruFile(i)=MruFile(i-1)
	Next i
	MruFile(0)=GetFileName(sFile,TRUE) & "," & sFile
	For i=1 To 9
		DeleteMenu(mii.hSubMenu,15000+i,MF_BYCOMMAND)
		WritePrivateProfileString(StrPtr("MruFile"),Str(i),@MruFile(i-1),@ad.IniFile)
		x=InStr(MruFile(i-1),",")
		If x Then
			AppendMenu(mii.hSubMenu,MF_STRING,15000+i,"&" & Str(i) & " " & Left(MruFile(i-1),x-1))
		EndIf
	Next i
	CallAddins(ah.hwnd,AIM_MENUREFRESH,0,0,HOOK_MENUREFRESH)

End Sub

Sub NotImplemented()

	MessageBox(ah.hwnd,"Not implemented",@szAppName,MB_OK)

End Sub

Function OpenInclude() As String
	Dim chrg As CHARRANGE
	Dim x As Integer
	Dim sItem As ZString*260
	Dim p As ZString Ptr

	If ah.hred<>0 And ah.hred<>ah.hres Then
		SendMessage(ah.hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
		If SendMessage(ah.hred,REM_ISCHARPOS,chrg.cpMin,0)=3 Then
			x=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
			chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,x,0)
			buff=Chr(255) & Chr(1)
			x=SendMessage(ah.hred,EM_GETLINE,x,Cast(LPARAM,@buff))
			buff[x]=NULL
			x=chrg.cpMax-chrg.cpMin+1
			While x
				If Asc(buff,x-1)=34 Then
					Exit While
				EndIf
				x=x-1
			Wend
			buff=Mid(buff,x)
			x=InStr(buff,"""")
			buff=Left(buff,x-1)
			If fProject Then
				sItem=ad.ProjectPath & "\"
			Else
				sItem=ad.filename
				GetFilePath(sItem)
				sItem=sItem & "\"
			EndIf
			If GetFileAttributes(sItem & buff)<>-1 Then
				buff=sItem & buff
				GetFullPathName(@buff,260,@buff,@p)
				Return buff
			Else
				If Len(ad.fbcPath) Then
					buff=ad.fbcPath & "\inc\" & buff
				Else
					buff=ad.AppPath & "\inc\" & buff
				EndIf
				If GetFileAttributes(buff)<>-1 Then
					GetFullPathName(@buff,260,@buff,@p)
					Return buff
				EndIf
			EndIf
		EndIf
	EndIf
	Return ""

End Function

Function GetTextItem(ByRef sText As String) As String
	Dim x As Integer
	Dim sItem As String

	x=InStr(sText,",")
	If x Then
		sItem=Left(sText,x-1)
		sText=Mid(sText,x+1)
	Else
		sItem=sText
		sText=""
	EndIf
	Return sItem

End Function

Function ConvToTwips(ByVal lSize As Integer) As Integer

	If ppage.inch Then
		'Inches
		Return (lSize*1440)\1000
	EndIf
	'millimeters
	Return (lSize*567)\1000

End Function

Sub PrintDoc
	Dim doci As DOCINFO
	Dim pX As Integer
	Dim pY As Integer
	Dim pML As Integer
	Dim pMT As Integer
	Dim pMR As Integer
	Dim pMB As Integer
	Dim chrg As CHARRANGE
	Dim rect As RECT
	Dim buffer As ZString*32
	Dim nLine As Integer
	Dim nPageno As Integer
	Dim nMLine As Integer
	Dim fmr As FORMATRANGE
	Dim hOldFont As HFONT

	pX=ConvToTwips(psd.ptPaperSize.x)
	pML=ConvToTwips(psd.rtMargin.left)
	pMR=ConvToTwips(psd.rtMargin.right)
	pY=ConvToTwips(psd.ptPaperSize.y)
	pMT=ConvToTwips(psd.rtMargin.top)
	pMB=ConvToTwips(psd.rtMargin.bottom)
	fmr.rcPage.left=0
	fmr.rc.left=pML
	fmr.rcPage.right=pX
	fmr.rc.right=pX-pMR
	fmr.rcPage.top=0
	fmr.rc.top=pMT
	fmr.rcPage.bottom=pY
	fmr.rc.bottom=pY-pMB
	fmr.hdc=GetDC(ah.hred)
	hOldFont=SelectObject(fmr.hdc,ah.rafnt.hFont)
	fmr.hdcTarget=pd.hDC
	doci.cbSize=SizeOf(doci)
	doci.lpszDocName=StrPtr("FbEdit")
	If pd.Flags And PD_PRINTTOFILE Then
		buffer="FILE:"
		doci.lpszOutput=@buffer
	Else
		doci.lpszOutput=NULL
	EndIf
	doci.lpszDatatype=NULL
	doci.fwType=NULL
	StartDoc(pd.hDC,@doci)
	If pd.Flags And PD_SELECTION Then
		SendMessage(ah.hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
		nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMin)
		nPageno=nLine\ppage.pagelen
		nMLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
		pd.nToPage=9999
		fmr.chrg.cpMin=chrg.cpMin
		fmr.chrg.cpMax=chrg.cpMax
	Else
		nPageno=pd.nFromPage-1
		nLine=nPageno*ppage.pagelen
		nMLine=SendMessage(ah.hred,EM_GETLINECOUNT,0,0)
		fmr.chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,nLine,0)
		fmr.chrg.cpMax=-1
	EndIf
	While nLine<nMline And nPageno<pd.nToPage
		nPageno+=1
		StartPage(pd.hDC)
		fmr.chrg.cpMin=SendMessage(ah.hred,EM_FORMATRANGE,TRUE,Cast(LPARAM,@fmr))
		If EndPage(pd.hDC)<=0 Then
			Exit While
		EndIf
		nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,fmr.chrg.cpMin)
	Wend
	EndDoc(pd.hDC)
	SelectObject(fmr.hdc,hOldFont)
	DeleteDC(pd.hDC)
	ReleaseDC(ah.hred,fmr.hdc)

End Sub
