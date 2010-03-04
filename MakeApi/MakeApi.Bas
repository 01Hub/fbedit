/'
	This program creates api files from .bi and/or .bas files
'/

#Include Once "windows.bi"
#Include Once "win/commctrl.bi"
#Include Once "win/commdlg.bi"
#Include Once "win/shlwapi.bi"

#Include "MakeApi.bi"

Sub TabReplace(ByRef szin As ZString)

	Asm
		push	esi
		xor	ecx,ecx
		mov	eax,VK_TAB
		mov	edx,VK_SPACE
		mov	esi,[szin]
		jmp	L3
	L1:
		cmp	al,[esi+ecx]
		jne	L2
		mov	[esi+ecx],dl
	L2:
		inc	ecx
	L3:
		cmp	ah,[esi+ecx]
		jne	L1
		pop	esi
	End Asm

End Sub

Sub DblSpaceRemove(ByRef szin As ZString)

	Asm
		push	esi
		push	edi
		mov	edx,VK_SPACE
		mov	esi,[szin]
		lea	edi,[esi+1]
	LL1:
		inc	esi
		mov	al,[esi]
		cmp	al,VK_SPACE
		je	LL3
	LL2:
		mov	[edi],al
		inc	edi
		or		al,al
		jne	LL1
		jmp	LL4
	LL3:
		cmp	al,[edi-1]
		jne	LL2
		jmp	LL1
	LL4:
		pop	edi
		pop	esi
	End Asm

End Sub

Sub Convert(byval sInputFile as string,byval sOutputFile as string)
	Dim sLine As String
	Dim sApi As String
	Dim i As Integer
	Dim iPos As Integer

	Open sInputFile For Input As #1
	Open sOutputFile For Output As #2
	Do While Not EOF(1)
		Line Input #1, sLine
		szWord=Trim(sLine)
		TabReplace(szWord)
		DblSpaceRemove(szWord)
		sLine=Trim(szWord)
		If LCase(Left(sLine, 8)) = "declare " Then
			sLine=Mid(sLine,9)
		EndIf
		If LCase(Left(sLine, 9)) = "function " Or LCase(Left(sLine, 4)) = "sub " Then
			iPos = InStr(sLine, """")
			If iPos Then
				i = InStr(iPos + 1, sLine, """")
				If i Then
		 			sLine = Left(sLine, iPos - 1) & Mid(sLine, i + 1)
				EndIf
			EndIf
			iPos = InStr(LCase(sLine), " alias ")
			If iPos Then
				sLine = Left(sLine, iPos - 1) & Mid(sLine, iPos + 7)
			EndIf
			iPos = InStr(LCase(sLine), " cdecl")
			If iPos Then
				sLine = Left(sLine, iPos - 1) & Mid(sLine, iPos + 6)
			EndIf
			If LCase(Left(sLine, 9)) = "function " Then
				Print #2, sLine
				Print #2, "end function"
			ElseIf LCase(Left(sLine, 4)) = "sub " Then
				Print #2, sLine
			Print #2, "end sub"
			End If
		ElseIf LCase(Left(sLine, 8)) = "#define " Then
			If InStr(sLine,"__") = 0 Then
				Print #2, sLine
			End If
		ElseIf LCase(Left(sLine, 5)) = "type " Then
			if InStr(LCase(sLine)," as ") = 0 Then
				Print #2, sLine
				Do
		 			Line Input #1, sLine
		 			Print #2, sLine
				Loop Until InStr(LCase(sLine),"end type")
			End If
		ElseIf LCase(Left(sLine, 5)) = "enum " Then
			Print #2, sLine
			Do
				Line Input #1, sLine
				Print #2, sLine
			Loop Until InStr(LCase(sLine),"end enum")
		End If
	Loop
	Close #1
	Close #2

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

Sub SetupProperty()
	' Property types
	SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("p")+256,Cast(Integer,StrPtr(szCode)))
	SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("c"),Cast(Integer,StrPtr(szConst)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("d")+512,Cast(Integer,StrPtr(szData)))
	SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("s"),Cast(Integer,StrPtr(szStruct)))
	SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("e"),Cast(Integer,StrPtr(szEnum)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("n"),Cast(Integer,StrPtr(szNamespace)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("m"),Cast(Integer,StrPtr(szMacro)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("x")+256,Cast(Integer,StrPtr(szConstructor)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("y")+256,Cast(Integer,StrPtr(szDestructor)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("z")+256,Cast(Integer,StrPtr(szProperty)))
	'SendMessage(hPrp,PRM_ADDPROPERTYTYPE,Asc("o")+256,Cast(Integer,StrPtr(szOperator)))
	SendMessage(hPrp,PRM_SETCHARTAB,0,Cast(LPARAM,lpCharTab))
	SendMessage(hPrp,PRM_SETGENDEF,0,Cast(Integer,@defgen))
	' Lines to skip
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,Cast(Integer,StrPtr("declare")))
	' Words to skip
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_FIRSTWORD,Cast(Integer,StrPtr("private")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_FIRSTWORD,Cast(Integer,StrPtr("public")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_SECONDWORD,Cast(Integer,StrPtr("shared")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_DATATYPEINIT,Cast(Integer,StrPtr("as")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("byval")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("byref")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("alias")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("cdecl")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_PROCPARAM,Cast(Integer,StrPtr("stdcall")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTITEMFIRSTWORD,Cast(Integer,StrPtr("as")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTITEMSECONDWORD,Cast(Integer,StrPtr("as")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTTHIRDWORD,Cast(Integer,StrPtr("as")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTITEMINIT,Cast(Integer,StrPtr("declare")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTITEMINIT,Cast(Integer,StrPtr("static")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_PTR,Cast(Integer,StrPtr("ptr")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_DATATYPE,Cast(Integer,StrPtr("const")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTLINEFIRSTWORD,Cast(Integer,StrPtr("private")))
	SendMessage(hPrp,PRM_ADDIGNORE,IGNORE_STRUCTLINEFIRSTWORD,Cast(Integer,StrPtr("public")))
	' Parse defs
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypesub))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendsub))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypefun))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendfun))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypedata))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypecommon))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypestatic))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypevar))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeconst))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeconst2))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypestruct))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendstruct))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeunion))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendunion))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeenum))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendenum))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypenamespace))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendnamespace))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypewithblock))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendwithblock))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypemacro))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendmacro))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeconstructor))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendconstructor))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypedestructor))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeenddestructor))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeproperty))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendproperty))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeoperator))
	SendMessage(hPrp,PRM_ADDDEFTYPE,0,Cast(Integer,@deftypeendoperator))
	' Set cbo selection
	SendMessage(hPrp,PRM_SELECTPROPERTY,Asc("p")+256,0)
	' Set button 'Open files'
	SendMessage(hPrp,PRM_SETSELBUTTON,2,0)
End Sub

Sub MakeApiFile(ByVal hWin As HWND,ByRef szPrefix As ZString,ByVal nType As Integer)
	Dim szFileName As ZString*260
	Dim i As Integer
	Dim lp As ZString Ptr
	Dim hFile As HANDLE
	Dim dwWrite As Integer

	szFileName=AppPath & "\" & szPrefix
	Select Case nType
		Case 0
			szFileName &="Call.api"
		Case 1
			szFileName &="Word.api"
		Case 2
			szFileName &="Struct.api"
		Case 3
			szFileName &="Enum.api"
	End Select
	hFile=CreateFile(@szFileName,GENERIC_WRITE Or GENERIC_READ,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL)
	If hFile<>INVALID_HANDLE_VALUE Then
		While TRUE
			If SendMessage(lpRAPROPERTY->hlst,LB_GETTEXT,i,Cast(LPARAM,@szWord))<>LB_ERR Then
				lp=Cast(ZString Ptr,SendMessage(lpRAPROPERTY->hlst,LB_GETITEMDATA,i,0))+SizeOf(PROPERTIES)
				szLine=*lp
				lp+=lstrlen(lp)+1
				If Len(*lp) Then
					szLine &="," & *lp
				EndIf
				Select Case nType
					Case 0
						lp+=lstrlen(lp)+1
						If Len(*lp) Then
							szLine &="|" & *lp
						EndIf
						'
					Case 1
						'
					Case 2
						'
					Case 3
						'
				End Select
				szLine &=szCRLF
				If szLine<>szLastLine Then
					WriteFile(hFile,@szLine,Len(szLine),@dwWrite,NULL)
					szLastLine=szLine
				EndIf
			Else
				Exit While
			EndIf
			i+=1
		Wend
		CloseHandle(hFile)
		MessageBox(hWin,"Successfylly created" & szCRLF & szFileName,szAppName,MB_OK Or MB_ICONINFORMATION)
	EndIf

End Sub

Sub ParseFiles(ByVal hWin As HWND)
	Dim As Integer i,dwRead
	Dim sInp as zstring*260
	Dim hMem As HGLOBAL
	Dim hFile As HANDLE
	
	SendMessage(hPrp,PRM_DELPROPERTY,0,0)
	i=0
	While TRUE
		If SendDlgItemMessage(hWin,IDC_LSTBI,LB_GETTEXT,i,Cast(LPARAM,@sInp))<>LB_ERR Then
			Convert(sInp,AppPath & "\" & "Temp.txt")
			sInp=AppPath & "\" & "Temp.txt"
			hFile=CreateFile(@sInp,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL)
			If hFile<>INVALID_HANDLE_VALUE Then
				hMem=GlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,1024*1024)
				ReadFile(hFile,hMem,GetFileSize(hFile,0),@dwRead,NULL)
				SendMessage(hPrp,PRM_PARSEFILE,i+1,Cast(LPARAM,hMem))
				GlobalFree(hMem)
				CloseHandle(hFile)
			EndIf
		Else
			Exit While
		EndIf
		i+=1
	Wend
	SendMessage(hPrp,PRM_REFRESHLIST,0,0)

End Sub

Function DlgProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id,Event,i,x
	Dim sInp as ZString*260
	Dim sPth as ZString*260
	Dim s as ZString*260
	Dim ofn as OPENFILENAME

	Select Case uMsg
		Case WM_INITDIALOG
			GetModuleFileName(NULL,@AppPath,260)
			GetFilePath(AppPath)
			hPrp=GetDlgItem(hWin,IDC_PRPCODE)
			lpRAPROPERTY=Cast(RAPROPERTY Ptr,GetWindowLong(hPrp,0))
			ShowWindow(lpRAPROPERTY->htbr,SW_HIDE)
			SetupProperty
			'
		Case WM_CLOSE
			EndDialog(hWin, 0)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case id
				Case IDOK
					GetDlgItemText(hWin,IDC_EDTPREFIX,@sInp,260)
					If Len(sInp) Then
						If SendMessage(lpRAPROPERTY->hlst,LB_GETCOUNT,0,0)>0 Then
							id=SendMessage(lpRAPROPERTY->hcbo,CB_GETCURSEL,0,0)
							MakeApiFile(hWin,sInp,id)
						Else
							MessageBox(hWin,"No Properties.",szAppName,MB_OK Or MB_ICONERROR)
						EndIf
					Else
						MessageBox(hWin,"No File Prefix given.",szAppName,MB_OK Or MB_ICONERROR)
					EndIf
					'
				Case IDCANCEL
					EndDialog(hWin, 0)
					'
				Case IDC_BTNADD
					ofn.lStructSize=sizeof(OPENFILENAME)
					ofn.hwndOwner=hWin
					ofn.hInstance=GetModuleHandle(NULL)
					sInp=string(260,0)
					ofn.lpstrFile=@sInp
					ofn.nMaxFile=260
					ofn.lpstrFilter=@ALLFilterString
					ofn.lpstrTitle=StrPtr("Input File")
					ofn.Flags=OFN_PATHMUSTEXIST or OFN_HIDEREADONLY or OFN_FILEMUSTEXIST or OFN_EXPLORER Or OFN_ALLOWMULTISELECT
					If GetOpenFileName(@ofn) Then
						lstrcpy(@sPth,@sInp)
						i=Len(sPth)+1
						x=Cast(Integer,@sInp)
						lstrcpy(@s,Cast(ZString Ptr,x+i))
						If Asc(s)=0 Then
							' Add single file
							SendDlgItemMessage(hWin,IDC_LSTBI,LB_ADDSTRING,0,Cast(LPARAM,@sInp))
						Else
							' Open multiple files
							Do While Asc(s)<>0
								sInp=sPth & "\" & s
								SendDlgItemMessage(hWin,IDC_LSTBI,LB_ADDSTRING,0,Cast(LPARAM,@sInp))
								i=i+Len(s)+1
								lstrcpy(@s,Cast(ZString Ptr,x+i))
							Loop
						EndIf
						ParseFiles(hWin)
					EndIf
				Case IDC_BTNDEL
					id=SendDlgItemMessage(hWin,IDC_LSTBI,LB_GETCURSEL,0,0)
					If id<>LB_ERR Then
						SendDlgItemMessage(hWin,IDC_LSTBI,LB_DELETESTRING,id,0)
						ParseFiles(hWin)
					EndIf
			End Select
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

'''
''' Program start
'''
	''
	'' Create the Dialog
	''
	szWord="FbEdit.dll"
	CommandLine=GetCommandLine
	CommandLine=PathGetArgs(CommandLine)
	If Len(*CommandLine) Then
		szWord=*CommandLine & "\" & szWord
	EndIf
	hFbEditDll=LoadLibrary(szWord)
	If hFbEditDll Then
		CharTab=Cast(Any Ptr,GetProcAddress(hFbEditDll,StrPtr("GetCharTabPtr")))
		lpCharTab=CharTab()

		SetCharTab=Cast(Any Ptr,GetProcAddress(hFbEditDll,StrPtr("SetCharTabVal")))
		' Turn off default comment char
		SetCharTab(Asc(";"),CT_OPER)
		' Define @ as a operand
		SetCharTab(Asc("@"),CT_OPER)
		' Define # as a character
		SetCharTab(Asc("#"),CT_CHAR)
		' Set comment char
		SetCharTab(Asc("'"),CT_CMNTCHAR)
		' Set comment block init char
		SetCharTab(Asc("/"),CT_CMNTINITCHAR)

		hInstance=GetModuleHandle(NULL)
		DialogBoxParam(hInstance, Cast(ZString Ptr,IDD_DLGAPI), NULL, @DlgProc, NULL)
		FreeLibrary(hFbEditDll)
	Else
		MessageBox(NULL,"Could not find " & szWord,@szAppName,MB_OK Or MB_ICONERROR)
	EndIf
	''
	'' Program has ended
	''
	ExitProcess(0)
'''
''' Program end
'''
