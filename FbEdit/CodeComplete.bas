
Sub HideList()

	ShowWindow(ah.hcc,SW_HIDE)
	ftypelist=FALSE
	fconstlist=FALSE
	fstructlist=FALSE
	flocallist=FALSE
	fincludelist=FALSE
	fincliblist=FALSE

End Sub

Sub MoveList()
	Dim pt As Point
	Dim rect As RECT
	Dim rect1 As RECT

	GetCaretPos(@pt)
	GetWindowRect(ah.hcc,@rect1)
	SendMessage(ah.hred,EM_GETRECT,0,Cast(Integer,@rect))
	ClientToScreen(ah.hred,Cast(Point ptr,@rect))
	rect.top=rect.top+pt.y+18
	If rect.top+rect1.bottom-rect1.top+8>GetSystemMetrics(SM_CYMAXIMIZED) Then
		rect.top=rect.top-rect1.bottom+rect1.top-22
	EndIf
	If edtopt.autowidth Then
		rect.right=SendMessage(ah.hcc,CCM_GETMAXWIDTH,0,0)+8
		If rect.right<100 Then
			rect.right=100
		EndIf
	Else
		rect.right=rect1.right-rect1.left
	EndIf
	rect.bottom=wpos.ptcclist.y
	SetWindowPos(ah.hcc,HWND_TOP,rect.left+pt.x+5,rect.top,rect.right,rect.bottom,SWP_NOACTIVATE Or SWP_SHOWWINDOW)
	ShowWindow(ah.htt,SW_HIDE)

End Sub

Function FindExact(ByVal lpTypes As ZString ptr,ByVal lpFind As ZString ptr,ByVal fMatchCase As Boolean) As ZString ptr
	Dim lret As ZString ptr

	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,lpTypes),Cast(Integer,lpFind)))
	While lret
		If fMatchCase Then
			If lstrcmp(lret,lpFind)=0 Then
				Return lret
			EndIf
		Else
			If lstrcmpi(lret,lpFind)=0 Then
				Return lret
			EndIf
		EndIf
		lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,Cast(Integer,lpTypes),Cast(Integer,lpFind)))
	Wend
	Return 0

End Function

Sub GetItems(ByVal ntype As Integer)
	Dim x As Integer
	Dim sItem As ZString*256

	x=1
	Do While x
		x=InStr(s,",")
		If x Then
			lstrcpyn(ccpos,@s,x)
			s=Mid(s,x+1)
		Else
			lstrcpy(ccpos,@s)
		EndIf
		If Len(ccpos[0]) Then
			lstrcpyn(@sItem,ccpos,Len(buff)+1)
			If lstrcmpi(@sItem,@buff)=0 Then
				SendMessage(ah.hcc,CCM_ADDITEM,ntype,Cast(Integer,ccpos))
				ccpos=ccpos+Len(ccpos[0])+1
			EndIf
		EndIf
	Loop

End Sub

Sub UpdateList(ByVal lpProc As ZString ptr)
	Dim lret As Integer
	Dim chrg As CHARRANGE
	Dim ntype As Integer

	ccpos=@ccstring
	SendMessage(ah.hcc,CCM_CLEAR,0,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If chrg.cpMin=chrg.cpMax Then
		lret=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
		chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,lret,0)
		buff=Chr(255) & Chr(1)
		lret=SendMessage(ah.hred,EM_GETLINE,lret,Cast(Integer,@buff))
		buff[lret]=NULL
		SendMessage(ah.hpr,PRM_GETWORD,chrg.cpMax-chrg.cpMin,Cast(Integer,@buff))
		If flocallist=FALSE Then
			lret=SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("PpWcSsdTne")),Cast(Integer,@buff))
			Do While lret
				ntype=SendMessage(ah.hpr,PRM_FINDGETTYPE,0,0)
				Select Case As Const ntype
					Case Asc("P")
						ntype=0
					Case Asc("p")
						ntype=1
					Case Asc("C")
						ntype=2
					Case Asc("W")
						ntype=2
					Case Asc("c")
						ntype=3
					Case Asc("S")
						ntype=4
					Case Asc("s")
						ntype=5
					Case Asc("d")
						lstrcpy(ccpos,Cast(ZString ptr,lret))
						lstrcat(ccpos,@szColon)
						lret=lret+lstrlen(Cast(ZString ptr,lret))+1
						lstrcat(ccpos,Cast(ZString ptr,lret))
						lret=Cast(Integer,ccpos)
						ccpos=ccpos+Len(ccpos[0])+1
						ntype=14
					Case Asc("T")
						ntype=10
					Case Asc("e")
						ntype=14
					Case Else
						ntype=0
				End Select
				SendMessage(ah.hcc,CCM_ADDITEM,ntype,lret)
				lret=SendMessage(ah.hpr,PRM_FINDNEXT,0,0)
			Loop
		EndIf
		If lpProc Then
			'ccpos=@ccstring
			lpProc=lpProc+Len(lpProc[0])+1
			lstrcpy(@s,lpProc)
			If Asc(s)<>NULL Then
				GetItems(8)
			EndIf
			lpProc=lpProc+Len(lpProc[0])+1
			' Skip return type
			lpProc=lpProc+lstrlen(lpProc)+1
			lstrcpy(@s,lpProc)
			If Asc(s)<>NULL Then
				GetItems(9)
			EndIf
		EndIf
		SendMessage(ah.hcc,CCM_SORT,0,0)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
	EndIf

End Sub

Sub UpdateStructList(ByVal lpProc As ZString ptr)
	Dim lret As ZString ptr
	Dim chrg As CHARRANGE
	Dim ntype As Integer
	Dim As Integer x,y
	Dim sLine As ZString*512
	Dim sItem As ZString*512
	Dim p As ZString ptr
	Dim nline As Integer
	Dim nowner As Integer

	SendMessage(ah.hcc,CCM_CLEAR,0,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If chrg.cpMin=chrg.cpMax Then
		nline=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
		chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,nline,0)
		x=chrg.cpMax-chrg.cpMin
		buff=STring(1024,0)
		buff=Chr(x and 255) & Chr(x\256)
		lret=Cast(ZString ptr,SendMessage(ah.hred,EM_GETLINE,nline,Cast(Integer,@buff)))
		buff[Cast(Integer,lret)]=NULL
		lstrcpy(@sLine,@buff)
		nowner=Cast(Integer,ah.hred)
		If fProject Then
			nowner=IsProjectFile(ad.filename)
		EndIf
		SendMessage(ah.hpr,PRM_GETSTRUCTSTART,Len(sLine),Cast(LPARAM,@sLine))
		If Asc(sLine)=Asc(".") Then
			lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_ISINWITHBLOCK,nowner,nline))
			If lret Then
				lstrcpy(@s,lret)
				sLine=s & Mid(sLine,InStr(sLine,"."))
			EndIf
		EndIf
		While InStr(buff,"->")
			buff=Mid(buff,InStr(buff,"->")+2)
		Wend
		While InStr(buff,".")
			buff=Mid(buff,InStr(buff,".")+1)
		Wend
		x=Len(sLine)
		SendMessage(ah.hpr,PRM_GETSTRUCTWORD,x,Cast(LPARAM,@sLine))
		p=@sLine
		If lpProc Then
			If lstrcmpi(StrPtr("this"),@sLine)=0 Then
				lstrcpy(@sLine,lpProc)
				x=InStr(sLine,".")
				x=InStr(x+1,sLine,".")
				If x=0 Then
					x=Len(sLine)+1
				EndIf
				sLine=sLine & "  "
				Mid(sLine,x,2)=szNULL & szNULL
				GoTo TestNext1
			EndIf
			' Skip proc name
			lpProc=lpProc+Len(lpProc[0])+1
			' Get parameters list
			lstrcpy(@sItem,p)
			SendMessage(ah.hpr,PRM_FINDITEMDATATYPE,Cast(WPARAM,@sItem),Cast(LPARAM,lpProc))
			If Len(sItem)=0 Then
				' Skip parameters list
				lpProc=lpProc+Len(lpProc[0])+1
				' Skip return type
				lpProc=lpProc+Len(lpProc[0])+1
				' Get local data list
			TestNext:
				lstrcpy(@sItem,p)
				SendMessage(ah.hpr,PRM_FINDITEMDATATYPE,Cast(WPARAM,@sItem),Cast(LPARAM,lpProc))
			EndIf
			If Len(sItem) Then
				lret=FindExact(StrPtr("Ss"),@sItem,FALSE)
				If lret Then
					lret=lret+Len(lret[0])+1
					p=p+Len(p[0])+1
					If Len(p[0]) Then
						lpProc=lret
						GoTo TestNext
					EndIf
					ccpos=@ccstring
					lstrcpy(@s,lret)
					If Asc(s)<>NULL Then
						GetItems(15)
					EndIf
				EndIf
			Else
				lpProc=0
			EndIf
		EndIf
		If lpProc=0 Then
			lret=FindExact(StrPtr("d"),p,FALSE)
			If lret Then
				lret=lret+Len(lret[0])+1
				'Remove namespace from type
'				lstrcpy(@sItem,lret)
'				lret=lret+InStr(sItem,".")
				lstrcpy(@sItem,lret)
				If InStr(sItem," ") Then
					sItem[InStr(sItem," ")-1]=NULL
					lret=@sItem
				EndIf
				lret=FindExact(StrPtr("Ss"),lret,FALSE)
				If lret Then
					lret=lret+Len(lret[0])+1
					p=p+Len(p[0])+1
					If Len(p[0]) Then
						lpProc=lret
						GoTo TestNext
					EndIf
					ccpos=@ccstring
					lstrcpy(@s,lret)
					If Asc(s)<>NULL Then
						GetItems(15)
					EndIf
				EndIf
			Else
			TestNext1:
				lret=FindExact(StrPtr("s"),p,TRUE)
				If lret Then
					lret=lret+Len(lret[0])+1
					p=p+Len(p[0])+1
					If Len(p[0]) Then
						lpProc=lret
						GoTo TestNext
					EndIf
					ccpos=@ccstring
					lstrcpy(@s,lret)
					If Asc(s)<>NULL Then
						GetItems(15)
					EndIf
				EndIf
			EndIf
		EndIf
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		If SendMessage(ah.hcc,CCM_GETCOUNT,0,0) Then
			fstructlist=TRUE
		EndIf
	EndIf

End Sub

Sub UpdateTypeList()
	Dim lret As Integer
	Dim chrg As CHARRANGE
	Dim ntype As Integer

	SendMessage(ah.hcc,CCM_CLEAR,0,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If chrg.cpMin=chrg.cpMax Then
		lret=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
		chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,lret,0)
		buff=Chr(255) & Chr(1)
		lret=SendMessage(ah.hred,EM_GETLINE,lret,Cast(Integer,@buff))
		buff[lret]=NULL
		SendMessage(ah.hpr,PRM_GETWORD,chrg.cpMax-chrg.cpMin,Cast(Integer,@buff))
		lret=SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,StrPtr("SsTe")),Cast(Integer,@buff))
		Do While lret
			ntype=SendMessage(ah.hpr,PRM_FINDGETTYPE,0,0)
			Select Case As Const ntype
				Case Asc("S")
					ntype=4
				Case Asc("s")
					ntype=5
				Case Asc("T")
					ntype=10
				Case Asc("e")
					ntype=14
			End Select
			SendMessage(ah.hcc,CCM_ADDITEM,ntype,lret)
			lret=SendMessage(ah.hpr,PRM_FINDNEXT,0,0)
		Loop
		SendMessage(ah.hcc,CCM_SORT,0,0)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		If SendMessage(ah.hcc,CCM_GETCOUNT,0,0) Then
			ftypelist=TRUE
		EndIf
	EndIf

End Sub

Function UpdateConstList(ByVal lpszApi As ZString ptr,npos As Integer) As Boolean
	Dim lret As ZString ptr
	Dim chrg As CHARRANGE
	Dim ln As Integer
	Dim ccal As CC_ADDLIST
	Dim ntype As Integer

	buff=Str(npos)
	lstrcat(@buff,lpszApi)
	lret=FindExact(StrPtr("A"),@buff,TRUE)
	If lret Then
		SendMessage(ah.hcc,CCM_CLEAR,0,0)
		SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
		If chrg.cpMin=chrg.cpMax Then
			lret=lret+Len(buff)+1
			ln=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
			chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,ln,0)
			buff=Chr(255) & Chr(1)
			ln=SendMessage(ah.hred,EM_GETLINE,ln,Cast(Integer,@buff))
			buff[ln]=NULL
			SendMessage(ah.hpr,PRM_GETWORD,chrg.cpMax-chrg.cpMin,Cast(Integer,@buff))
			lstrcpy(@s,lret)
			ccal.lpszList=@s
			ccal.lpszFilter=@buff
			ccal.nType=2
			If Len(s) Then
				SendMessage(ah.hcc,CCM_ADDLIST,0,Cast(Integer,@ccal))
			Else
				lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(WPARAM,StrPtr("SsTe")),Cast(LPARAM,@buff)))
				Do While lret
					ntype=SendMessage(ah.hpr,PRM_FINDGETTYPE,0,0)
					Select Case As Const ntype
						Case Asc("S")
							ntype=4
						Case Asc("s")
							ntype=5
						Case Asc("T")
							ntype=10
						Case Asc("e")
							ntype=14
					End Select
					SendMessage(ah.hcc,CCM_ADDITEM,ntype,Cast(LPARAM,lret))
					lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
				Loop
				SendMessage(ah.hcc,CCM_SORT,0,0)
			EndIf
			SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
			Return TRUE
		EndIf
	EndIf
	Return FALSE

End Function

Sub IsStructList()
	Dim x As Integer
	Dim lret As ZString ptr
	Dim chrg As CHARRANGE
	Dim isinp As ISINPROC

	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	isinp.nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
	isinp.nOwner=Cast(Integer,ah.hred)
	If fProject Then
		isinp.nOwner=GetProjectFileID(ah.hred)
	EndIf
	isinp.lpszType=StrPtr("pxyzo")
	lret=Cast(ZString ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
	UpdateStructList(lret)
	If fstructlist Then
		MoveList
	EndIf

End Sub

Sub UpdateIncludeList(ByVal lpDir As ZString ptr,ByVal lpSub As ZString ptr,ByVal nType As Integer)
	Dim wfd As WIN32_FIND_DATA
	Dim hwfd As HANDLE
	Dim buffer As ZString*260
	Dim subdir As ZString*260
	Dim sItem As ZString*260
	Dim l As Integer
	Dim ls As Integer

	lstrcpy(@buffer,lpDir)
	lstrcpy(@subdir,lpSub)
	buffer=buffer & "\*.*"
	hwfd=FindFirstFile(@buffer,@wfd)
	If hwfd<>INVALID_HANDLE_VALUE Then
		While TRUE
			If wfd.dwFileAttributes And FILE_ATTRIBUTE_DIRECTORY Then
				lstrcpy(@s,@wfd.cFileName)
				If Asc(s)<>Asc(".") Then
					buffer=Left(buffer,Len(buffer)-3)
					l=Len(buffer)
					lstrcat(@buffer,@wfd.cFileName)
					ls=Len(subdir)
					lstrcat(@subdir,@wfd.cFileName)
					subdir=subdir & "/"
					UpdateIncludeList(buffer,@subdir,nType)
					buffer=Left(buffer,l) & "*.*"
					subdir=Left(subdir,ls)
				EndIf
			Else
				If lpSub Then
					lstrcpy(@s,lpSub)
				Else
					s=""
				EndIf
				lstrcat(@s,@wfd.cFileName)
				If UCase(Right(s,3))=".BI" Then
					lstrcpyn(@sItem,@s,Len(buff)+1)
					If lstrcmpi(@sItem,@buff)=0 Or Len(sItem)=0 Then
						lstrcpy(ccpos,@s)
						SendMessage(ah.hcc,CCM_ADDITEM,nType,Cast(LPARAM,ccpos))
						ccpos=ccpos+Len(ccpos[0])+1
					EndIf
				EndIf
				fincludelist=TRUE
			EndIf
			If FindNextFile(hwfd,@wfd)=FALSE Then
				Exit While
			EndIf
		Wend
		FindClose(hwfd)
	EndIf
	If fincludelist Then
		SendMessage(ah.hcc,CCM_SORT,0,0)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		MoveList
	EndIf

End Sub

Sub UpdateInclibList(ByVal lpDir As ZString ptr,ByVal lpSub As ZString ptr,ByVal nType As Integer)
	Dim wfd As WIN32_FIND_DATA
	Dim hwfd As HANDLE
	Dim buffer As ZString*260
	Dim subdir As ZString*260
	Dim sItem As ZString*260
	Dim l As Integer
	Dim ls As Integer

	lstrcpy(@buffer,lpDir)
	lstrcpy(@subdir,lpSub)
	buffer=buffer & "\*.*"
	hwfd=FindFirstFile(@buffer,@wfd)
	If hwfd<>INVALID_HANDLE_VALUE Then
		While TRUE
			If wfd.dwFileAttributes And FILE_ATTRIBUTE_DIRECTORY Then
				lstrcpy(@s,@wfd.cFileName)
				If Asc(s)<>Asc(".") Then
					buffer=Left(buffer,Len(buffer)-3)
					l=Len(buffer)
					lstrcat(@buffer,@wfd.cFileName)
					ls=Len(subdir)
					lstrcat(@subdir,@wfd.cFileName)
					subdir=subdir & "/"
					UpdateInclibList(buffer,@subdir,nType)
					buffer=Left(buffer,l) & "*.*"
					subdir=Left(subdir,ls)
				EndIf
			Else
				If lpSub Then
					lstrcpy(@s,lpSub)
				Else
					s=""
				EndIf
				lstrcat(@s,@wfd.cFileName)
				If UCase(Right(s,2))=".A" Then
					lstrcpyn(@sItem,@s,Len(buff)+1)
					If lstrcmpi(@sItem,@buff)=0 Or Len(sItem)=0 Then
						lstrcpy(ccpos,@s)
						SendMessage(ah.hcc,CCM_ADDITEM,nType,Cast(LPARAM,ccpos))
						ccpos=ccpos+Len(ccpos[0])+1
					EndIf
				EndIf
				fincliblist=TRUE
			EndIf
			If FindNextFile(hwfd,@wfd)=FALSE Then
				Exit While
			EndIf
		Wend
		FindClose(hwfd)
	EndIf
	If fincliblist Then
		SendMessage(ah.hcc,CCM_SORT,0,0)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		MoveList
	EndIf

End Sub
