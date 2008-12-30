Dim Shared As String dirlist

Sub SetupProperty()
	SendMessage(ah.hpr,PRM_SETCHARTAB,0,Cast(LPARAM,ad.lpCharTab))
	SendMessage(ah.hpr,PRM_SETGENDEF,0,Cast(Integer,@defgen))
	' Lines to skip
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,Cast(Integer,StrPtr("declare")))
	' Words to skip
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_FIRSTWORD,Cast(Integer,StrPtr("private")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_FIRSTWORD,Cast(Integer,StrPtr("public")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_SECONDWORD,Cast(Integer,StrPtr("shared")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_DATATYPEINIT,Cast(Integer,StrPtr("as")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("byval")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("byref")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("alias")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("cdecl")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("stdcall")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTITEMFIRSTWORD,Cast(Integer,StrPtr("as")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTITEMSECONDWORD,Cast(Integer,StrPtr("as")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTTHIRDWORD,Cast(Integer,StrPtr("as")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTITEMINIT,Cast(Integer,StrPtr("declare")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTITEMINIT,Cast(Integer,StrPtr("static")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_PTR,Cast(Integer,StrPtr("ptr")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTLINEFIRSTWORD,Cast(Integer,StrPtr("private")))
	SendMessage(ah.hpr,PRM_ADDIGNORE,IGNORE_STRUCTLINEFIRSTWORD,Cast(Integer,StrPtr("public")))
	' Property types
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("p")+256,Cast(Integer,StrPtr(szCode)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("c"),Cast(Integer,StrPtr(szConst)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("d")+512,Cast(Integer,StrPtr(szData)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("s"),Cast(Integer,StrPtr(szStruct)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("e"),Cast(Integer,StrPtr(szEnum)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("n"),Cast(Integer,StrPtr(szNamespace)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("m"),Cast(Integer,StrPtr(szMacro)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("x")+256,Cast(Integer,StrPtr(szConstructor)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("y")+256,Cast(Integer,StrPtr(szDestructor)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("z")+256,Cast(Integer,StrPtr(szProperty)))
	SendMessage(ah.hpr,PRM_ADDPROPERTYTYPE,Asc("o")+256,Cast(Integer,StrPtr(szOperator)))
	' Parse defs
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypesub))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendsub))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypefun))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendfun))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypedata))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypecommon))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypestatic))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypevar))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeconst))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeconst2))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypestruct))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendstruct))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeunion))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendunion))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeenum))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendenum))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypenamespace))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendnamespace))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypewithblock))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendwithblock))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypemacro))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendmacro))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeconstructor))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendconstructor))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypedestructor))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeenddestructor))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeproperty))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendproperty))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeoperator))
	SendMessage(ah.hpr,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendoperator))
	' Set cbo selection
	SendMessage(ah.hpr,PRM_SELECTPROPERTY,Asc("p")+256,0)
	' Set button 'Open files'
	SendMessage(ah.hpr,PRM_SETSELBUTTON,2,0)
End Sub

Sub HideList()

	ShowWindow(ah.hcc,SW_HIDE)
	ftypelist=FALSE
	fconstlist=FALSE
	fstructlist=FALSE
	fmessagelist=FALSE
	flocallist=FALSE
	fincludelist=FALSE
	fincliblist=FALSE
	fenumlist=FALSE

End Sub

Sub MoveList()
	Dim pt As Point
	Dim rect As RECT
	Dim rect1 As RECT

	GetCaretPos(@pt)
	GetWindowRect(ah.hcc,@rect1)
	SendMessage(ah.hred,EM_GETRECT,0,Cast(Integer,@rect))
	ClientToScreen(ah.hred,Cast(Point Ptr,@rect))
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

Function FindExact(ByVal lpTypes As ZString Ptr,ByVal lpFind As ZString Ptr,ByVal fMatchCase As Boolean) As ZString Ptr
	Dim lret As ZString Ptr

	lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(Integer,lpTypes),Cast(Integer,lpFind)))
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
		lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_FINDNEXT,Cast(Integer,lpTypes),Cast(Integer,lpFind)))
	Wend
	Return 0

End Function

Sub GetItems(ByVal ntype As Integer)
	Dim x As Integer
	Dim sItem As ZString*256
	Dim lps As ZString Ptr

	lps=@s
	x=1
	Do While x
		x=InStr(s,",")
		If x Then
			lstrcpyn(ccpos,@s,x)
			s=*(lps+x)
'			s=Mid(s,x+1)
		Else
			lstrcpy(ccpos,@s)
		EndIf
		If Len(*ccpos) Then
			lstrcpyn(@sItem,ccpos,Len(buff)+1)
			If lstrcmpi(@sItem,@buff)=0 Then
				If InStr(UCase(*ccpos),":SUB") Or InStr(UCase(*ccpos),":FUNCTION") Then
					SendMessage(ah.hcc,CCM_ADDITEM,1,Cast(Integer,ccpos))
				ElseIf InStr(UCase(*ccpos),":CONSTRUCTOR")=0 And InStr(UCase(*ccpos),":DESTRUCTOR")=0 Then
					SendMessage(ah.hcc,CCM_ADDITEM,ntype,Cast(Integer,ccpos))
				EndIf
				ccpos=ccpos+Len(*ccpos)+1
			EndIf
		EndIf
	Loop 

End Sub

Sub UpdateList(ByVal lpProc As ZString Ptr)
	Dim lret As Integer
	Dim chrg As CHARRANGE
	Dim ntype As Integer

	ccpos=@ccstring
	SendMessage(ah.hcc,CCM_CLEAR,0,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If chrg.cpMin=chrg.cpMax Then
'		SendMessage(ah.hcc,WM_SETREDRAW,FALSE,0)
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
						lstrcpy(ccpos,Cast(ZString Ptr,lret))
						lstrcat(ccpos,@szColon)
						lret=lret+Len(*Cast(ZString Ptr,lret))+1
						lstrcat(ccpos,Cast(ZString Ptr,lret))
						lret=Cast(Integer,ccpos)
						ccpos=ccpos+Len(*ccpos)+1
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
			lpProc=lpProc+Len(*lpProc)+1
			lstrcpy(@s,lpProc)
			If Asc(s)<>NULL Then
				GetItems(8)
			EndIf
			lpProc=lpProc+Len(*lpProc)+1
			' Skip return type
			lpProc=lpProc+Len(*lpProc)+1
			lstrcpy(@s,lpProc)
			If Asc(s)<>NULL Then
				GetItems(9)
			EndIf
		EndIf
		SendMessage(ah.hcc,CCM_SORT,0,TRUE)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
'		SendMessage(ah.hcc,WM_SETREDRAW,TRUE,0)
'		UpdateWindow(ah.hcc)
	EndIf

End Sub

Sub UpdateStructList(ByVal lpProc As ZString Ptr)
	Dim lret As ZString Ptr
	Dim chrg As CHARRANGE
	Dim ntype As Integer
	Dim As Integer x,y
	Dim sLine As ZString*1024
	Dim sItem As ZString*1024
	Dim p As ZString Ptr
	Dim nline As Integer
	Dim nowner As Integer

	SendMessage(ah.hcc,CCM_CLEAR,0,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If chrg.cpMin=chrg.cpMax Then
		nline=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
		chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,nline,0)
		x=chrg.cpMax-chrg.cpMin
		buff=String(1024,0)
		buff=Chr(x And 255) & Chr(x\256)
		lret=Cast(ZString Ptr,SendMessage(ah.hred,EM_GETLINE,nline,Cast(Integer,@buff)))
		buff[Cast(Integer,lret)]=NULL
		lstrcpy(@sLine,@buff)
		nowner=Cast(Integer,ah.hred)
		If fProject Then
			nowner=IsProjectFile(ad.filename)
		EndIf
		SendMessage(ah.hpr,PRM_GETSTRUCTSTART,Len(sLine),Cast(LPARAM,@sLine))
		If Asc(sLine)=Asc(".") Then
			lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINWITHBLOCK,nowner,nline))
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
					'x=Len(sLine)+1
					x=InStr(sLine,".")
				EndIf
				sLine=sLine & "  "
				Mid(sLine,x,2)=szNULL & szNULL
				GoTo TestNext1
			EndIf
			' Skip proc name
			lpProc=lpProc+Len(*lpProc)+1
			' Get parameters list
			lstrcpy(@sItem,p)
			SendMessage(ah.hpr,PRM_FINDITEMDATATYPE,Cast(WPARAM,@sItem),Cast(LPARAM,lpProc))
			If Len(sItem)=0 Then
				' Skip parameters list
				lpProc=lpProc+Len(*lpProc)+1
				' Skip return type
				lpProc=lpProc+Len(*lpProc)+1
				' Get local data list
			TestNext:
				lstrcpy(@sItem,p)
				SendMessage(ah.hpr,PRM_FINDITEMDATATYPE,Cast(WPARAM,@sItem),Cast(LPARAM,lpProc))
			EndIf
			If Len(sItem) Then
				lret=FindExact(StrPtr("Ss"),@sItem,FALSE)
				If lret Then
					lret=lret+Len(*lret)+1
					p=p+Len(*p)+1
					If Len(*p) Then
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
				lret=lret+Len(*lret)+1
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
					lret=lret+Len(*lret)+1
					p=p+Len(*p)+1
					If Len(*p) Then
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
					lret=lret+Len(*lret)+1
					p=p+Len(*p)+1
					If Len(*p) Then
						lpProc=lret
						GoTo TestNext
					EndIf
					ccpos=@ccstring
					lstrcpy(@s,lret)
					If Asc(s)<>NULL Then
						GetItems(15)
					EndIf
				Else
					' Namespace
					lret=FindExact(StrPtr("n"),p,TRUE)
					If lret Then
						sItem=*p & "." & buff
						lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(WPARAM,StrPtr("psdc")),Cast(LPARAM,@sItem)))
						While lret
							x=InStr(*lret,".")
							lret=lret+x
							ntype=SendMessage(ah.hpr,PRM_FINDGETTYPE,0,0)
							Select Case As Const ntype
								Case Asc("p")
									ntype=1
								Case Asc("c")
									ntype=3
								Case Asc("s")
									ntype=5
								Case Asc("d")
									ntype=14
								Case Else
									ntype=0
							End Select
							SendMessage(ah.hcc,CCM_ADDITEM,ntype,Cast(Integer,lret))
							lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_FINDNEXT,Cast(WPARAM,StrPtr("psdc")),Cast(LPARAM,@sItem)))
						Wend
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
'		SendMessage(ah.hcc,WM_SETREDRAW,FALSE,0)
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
'		SendMessage(ah.hcc,WM_SETREDRAW,TRUE,0)
'		UpdateWindow(ah.hcc)
		If SendMessage(ah.hcc,CCM_GETCOUNT,0,0) Then
			ftypelist=TRUE
		EndIf
	EndIf

End Sub

Function UpdateConstList(ByVal lpszApi As ZString Ptr,npos As Integer) As Boolean
	Dim lret As ZString Ptr
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
				lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_FINDFIRST,Cast(WPARAM,StrPtr("SsTe")),Cast(LPARAM,@buff)))
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
					lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_FINDNEXT,0,0))
				Loop
				SendMessage(ah.hcc,CCM_SORT,0,0)
			EndIf
			SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
			Return TRUE
		EndIf
	EndIf
	Return FALSE

End Function

Function UpdateEnumList(ByVal lpszEnum As ZString Ptr) As Boolean
	Dim lret As ZString Ptr
	Dim chrg As CHARRANGE
	Dim ln As Integer
	Dim ccal As CC_ADDLIST

	SendMessage(ah.hcc,CCM_CLEAR,0,0)
	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	If chrg.cpMin=chrg.cpMax Then
		lret=lpszEnum+Len(*lpszEnum)+1
		ln=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
		chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,ln,0)
		buff=Chr(255) & Chr(1)
		ln=SendMessage(ah.hred,EM_GETLINE,ln,Cast(Integer,@buff))
		buff[ln]=NULL
		SendMessage(ah.hpr,PRM_GETWORD,chrg.cpMax-chrg.cpMin,Cast(Integer,@buff))
		lstrcpy(@s,lret)
		ccal.lpszList=@s
		ccal.lpszFilter=@buff
		ccal.nType=14
		SendMessage(ah.hcc,CCM_ADDLIST,0,Cast(Integer,@ccal))
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		Return TRUE
	EndIf
	Return FALSE

End Function

Sub IsStructList()
	Dim x As Integer
	Dim lret As ZString Ptr
	Dim chrg As CHARRANGE
	Dim isinp As ISINPROC

	SendMessage(ah.hred,EM_EXGETSEL,0,Cast(Integer,@chrg))
	isinp.nLine=SendMessage(ah.hred,EM_EXLINEFROMCHAR,0,chrg.cpMax)
	isinp.nOwner=Cast(Integer,ah.hred)
	If fProject Then
		isinp.nOwner=GetProjectFileID(ah.hred)
	EndIf
	isinp.lpszType=StrPtr("pxyzo")
	lret=Cast(ZString Ptr,SendMessage(ah.hpr,PRM_ISINPROC,0,Cast(LPARAM,@isinp)))
	UpdateStructList(lret)
	If fstructlist Then
		MoveList
	EndIf

End Sub

Sub BuildDirList(ByVal lpDir As ZString Ptr,ByVal lpSub As ZString Ptr,ByVal nType As Integer)
	Dim wfd As WIN32_FIND_DATA
	Dim hwfd As HANDLE
	Dim buffer As ZString*260
	Dim subdir As ZString*260
	Dim l As Integer
	Dim ls As Integer

	lstrcpy(@buffer,lpDir)
	lstrcpy(@subdir,lpSub)
	lstrcat(@buffer,"\*")
	hwfd=FindFirstFile(@buffer,@wfd)
	If hwfd<>INVALID_HANDLE_VALUE Then
		While TRUE
			If wfd.dwFileAttributes And FILE_ATTRIBUTE_DIRECTORY Then
				lstrcpy(@s,@wfd.cFileName)
				If Asc(s)<>Asc(".") Then
					buffer[Len(buffer)-1]=0
					l=Len(buffer)
					lstrcat(@buffer,@wfd.cFileName)
					ls=Len(subdir)
					lstrcat(@subdir,@wfd.cFileName)
					lstrcat(@subdir,"/")
					BuildDirList(@buffer,@subdir,nType)
					buffer[l]=0
					lstrcat(@buffer,"*")
					subdir[ls]=0
				EndIf
			Else
				If lpSub Then
					lstrcpy(@s,lpSub)
				Else
					s=""
				EndIf
				lstrcat(@s,@wfd.cFileName)
				dirlist+=Str(nType)+","+LCase(s)+"#"
			EndIf
			If FindNextFile(hwfd,@wfd)=FALSE Then
				Exit While
			EndIf
		Wend
		FindClose(hwfd)
	EndIf

End Sub

Function ExtractDirFile(ByVal lpsrc As ZString Ptr, ByVal lpdst As ZString Ptr) As Integer
	Dim As UByte Ptr ps,pd
	
	ps=lpsrc
	pd=lpdst
	
	While *ps
		If *ps=Asc("#") Then Exit While
		*pd=*ps
		ps+=1
		pd+=1
	Wend
	*pd=0
	Return valInt(*lpdst)
	
End Function

Sub UpdateIncludeList()
	Dim As Integer sFind,nType
	Dim As ZString*260 buffer,txt
	Dim As ZString Ptr p
	
	ccpos=@ccstring
	p=StrPtr(dirlist)
	txt=","+LCase(buff)
	SendMessage(ah.hcc,CCM_CLEAR,0,0)
'	SendMessage(ah.hcc,WM_SETREDRAW,FALSE,0)
	sFind=InStr(dirlist,txt)
	While sFind
		nType=ExtractDirFile(p+sFind-2,@buffer)
		If Right(buffer,3)=".bi" Then
			lstrcpy(ccpos,@buffer+2)
			SendMessage(ah.hcc,CCM_ADDITEM,nType,Cast(LPARAM,ccpos))
			ccpos=ccpos+Len(*ccpos)+1
		EndIf
		sFind=InStr(sFind+1,dirlist,txt)
		fincludelist=TRUE
	Wend
'	SendMessage(ah.hcc,WM_SETREDRAW,TRUE,0)
'	UpdateWindow(ah.hcc)
	If fincludelist Then
		SendMessage(ah.hcc,CCM_SORT,0,0)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		MoveList
	EndIf
	
End Sub

Sub UpdateInclibList()
	Dim As Integer sFind,nType
	Dim As ZString*260 buffer,txt
	Dim As ZString Ptr p
	
	ccpos=@ccstring
	p=StrPtr(dirlist)
	txt=","+LCase(buff)
	SendMessage(ah.hcc,CCM_CLEAR,0,0)
'	SendMessage(ah.hcc,WM_SETREDRAW,FALSE,0)
	sFind=InStr(dirlist,txt)
	While sFind
		nType=ExtractDirFile(p+sFind-2,@buffer)
		If Right(buffer,2)=".a" Then
			lstrcpy(ccpos,@buffer+2)
			SendMessage(ah.hcc,CCM_ADDITEM,nType,Cast(LPARAM,ccpos))
			ccpos=ccpos+Len(*ccpos)+1
		EndIf
		sFind=InStr(sFind+1,dirlist,txt)
		fincliblist=TRUE
	Wend
'	SendMessage(ah.hcc,WM_SETREDRAW,TRUE,0)
'	UpdateWindow(ah.hcc)
	If fincliblist Then
		SendMessage(ah.hcc,CCM_SORT,0,0)
		SendMessage(ah.hcc,CCM_SETCURSEL,0,0)
		MoveList
	EndIf

End Sub
