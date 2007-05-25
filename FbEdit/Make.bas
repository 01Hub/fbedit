
Sub GetMakeOption()
	Dim nInx As Integer
	Dim sText As ZString*260

	SendMessage(ah.hcbobuild,CB_RESETCONTENT,0,0)
	If fProject Then
		' Get make option from ini
		nInx=1
		While GetPrivateProfileString(StrPtr("Make"),Str(nInx),@szNULL,@buff,SizeOf(ad.smake),@ad.ProjectFile)
			If Len(buff) Then
				buff=Left(buff,InStr(buff,",")-1)
				SendMessage(ah.hcbobuild,CB_ADDSTRING,0,Cast(Integer,@buff))
			EndIf
			nInx=nInx+1
		Wend
		nInx=GetPrivateProfileInt(StrPtr("Make"),StrPtr("Current"),1,@ad.ProjectFile)
		SendMessage(ah.hcbobuild,CB_SETCURSEL,nInx-1,0)
		GetPrivateProfileString(StrPtr("Make"),Str(nInx),@szNULL,@ad.smake,SizeOf(ad.smake),@ad.ProjectFile)
		If Len(ad.smake) Then
			nInx=InStr(ad.smake,",")
			sText=Left(ad.smake,nInx-1)
			SendMessage(ah.hsbr,SB_SETTEXT,2,Cast(Integer,@sText))
			ad.smake=Mid(ad.smake,nInx+1)
		EndIf
		GetPrivateProfileString(StrPtr("Make"),StrPtr("Module"),StrPtr("Module Build,fbc -c"),@ad.smakemodule,SizeOf(ad.smakemodule),@ad.ProjectFile)
		If Len(ad.smakemodule) Then
			nInx=InStr(ad.smakemodule,",")
			ad.smakemodule=Mid(ad.smakemodule,nInx+1)
		EndIf
		fRecompile=GetPrivateProfileInt(StrPtr("Make"),StrPtr("Recompile"),0,@ad.ProjectFile)
		GetPrivateProfileString(StrPtr("Make"),StrPtr("Output"),@szNULL,@ad.smakeoutput,SizeOf(ad.smakeoutput),@ad.ProjectFile)
		GetPrivateProfileString(StrPtr("Make"),StrPtr("Run"),@szNULL,@ad.smakerun,SizeOf(ad.smakerun),@ad.ProjectFile)
	Else
		' Get make option from ini
		nInx=1
		While GetPrivateProfileString(StrPtr("Make"),Str(nInx),@szNULL,@buff,SizeOf(ad.smake),@ad.IniFile)
			If Len(buff) Then
				buff=Left(buff,InStr(buff,",")-1)
				SendMessage(ah.hcbobuild,CB_ADDSTRING,0,Cast(Integer,@buff))
			EndIf
			nInx=nInx+1
		Wend
		nInx=GetPrivateProfileInt(StrPtr("Make"),StrPtr("Current"),1,@ad.IniFile)
		SendMessage(ah.hcbobuild,CB_SETCURSEL,nInx-1,0)
		GetPrivateProfileString(StrPtr("Make"),Str(nInx),@szNULL,@ad.smake,SizeOf(ad.smake),@ad.IniFile)
		If Len(ad.smake) Then
			nInx=InStr(ad.smake,",")
			sText=Left(ad.smake,nInx-1)
			SendMessage(ah.hsbr,SB_SETTEXT,2,Cast(Integer,@sText))
			ad.smake=Mid(ad.smake,nInx+1)
		EndIf
		GetPrivateProfileString(StrPtr("Make"),StrPtr("Module"),StrPtr("Module Build,fbc -c"),@ad.smakemodule,SizeOf(ad.smakemodule),@ad.IniFile)
		If Len(ad.smakemodule) Then
			nInx=InStr(ad.smakemodule,",")
			ad.smakemodule=Mid(ad.smakemodule,nInx+1)
		EndIf
		fRecompile=0
		ad.smakeoutput=""
		ad.smakerun=""
	EndIf
	If Len(ad.fbcPath) Then
		ad.smake=ad.fbcPath & "\" & ad.smake
		ad.smakemodule=ad.fbcPath & "\" & ad.smakemodule
	EndIf

End Sub

Type MAKE
	hThread	As HANDLE
	hrd		As HANDLE
	hwr		As HANDLE
	pInfo		As PROCESS_INFORMATION
	uExit		As Integer
End Type

Function MakeThreadProc(ByVal Param As ZString ptr) As Integer
	Dim makeinf As MAKE
	Dim sat As SECURITY_ATTRIBUTES
	Dim startupinfo As STARTUPINFO
	Dim lret As Integer
	Dim i As Integer

	sat.nLength=SizeOf(SECURITY_ATTRIBUTES)
	sat.lpSecurityDescriptor=NULL
	sat.bInheritHandle=TRUE
	makeinf.uExit=10
	If CreatePipe(@makeinf.hrd,@makeinf.hwr,@sat,NULL)=NULL Then
		' CreatePipe failed
		MessageBox(NULL,StrPtr("CreatePipe failed"),@szAppName,MB_OK Or MB_ICONERROR)
	Else
		startupinfo.cb=SizeOf(STARTUPINFO)
		GetStartupInfo(@startupinfo)
		startupinfo.hStdOutput=makeinf.hwr
		startupinfo.hStdError=makeinf.hwr
		' Create process
		startupinfo.dwFlags=STARTF_USESHOWWINDOW
		startupinfo.wShowWindow=SW_SHOWNORMAL
		If CreateProcess(NULL,Param,NULL,NULL,FALSE,NULL,NULL,NULL,@startupinfo,@makeinf.pInfo)=0 Then
			' CreateProcess failed
			CloseHandle(makeinf.hrd)
			CloseHandle(makeinf.hwr)
			MessageBox(NULL,StrPtr("CreateProcess failed"),@szAppName,MB_OK Or MB_ICONERROR)
		Else
			WaitForSingleObject(makeinf.pInfo.hProcess,INFINITE)
			GetExitCodeProcess(makeinf.pInfo.hProcess,@makeinf.uExit)
			CloseHandle(makeinf.hwr)
			CloseHandle(makeinf.hrd)
			CloseHandle(makeinf.pInfo.hThread)
			CloseHandle(makeinf.pInfo.hProcess)
		EndIf
	EndIf
	Do While i<1000
		lret=DeleteFile(StrPtr("FbTemp.exe"))
		If lret Then
			Exit Do
		EndIf
		i+=1
	Loop
	If lret=0 Then
		lret=GetLastError
		MessageBox(ah.hwnd,"Deleting FbTemp.exe failed! Error: " & Str(lret),"Quick run",MB_OK Or MB_ICONERROR)
	EndIf
	Return makeinf.uExit

End Function

Function MakeRun(ByVal sFile As String,ByVal fDebug As Boolean) As Integer
	Dim fval As ZString ptr

	GetFullPathName(@sFile,260,@buff,@fval)
	buff=RemoveFileExt(buff) & ".exe"
	If fDebug Then
		buff=ad.smakerundebug & " " & """" & buff & """"
	EndIf
	If Len(ad.smakerun) Then
		buff=buff & " " & ad.smakerun
	EndIf
	MakeRun=WinExec(@buff,SW_SHOWNORMAL)

End Function

Function MakeProc(ByVal Param As Integer) As Integer
	Dim sat As SECURITY_ATTRIBUTES
	Dim startupinfo As STARTUPINFO
	Dim pinfo As PROCESS_INFORMATION
	Dim hrd As HANDLE
	Dim hwr As HANDLE
	Dim bytesRead As Integer
	Dim lret As Integer
	Dim buffer As ZString*4096
	Dim rd As ZString*32

	sat.nLength=SizeOf(SECURITY_ATTRIBUTES)
	sat.lpSecurityDescriptor=NULL
	sat.bInheritHandle=TRUE
	lret=CreatePipe(@hrd,@hwr,@sat,NULL)
	If lret=0 Then
		' CreatePipe failed
		SetCursor(LoadCursor(0,IDC_ARROW))
		MessageBox(ah.hwnd,StrPtr("CreatePipeError"),@szAppName,MB_ICONERROR+MB_OK)
	Else
		startupinfo.cb=SizeOf(STARTUPINFO)
		GetStartupInfo(@startupinfo)
		startupinfo.hStdOutput=hwr
		startupinfo.hStdError=hwr
		startupinfo.dwFlags=STARTF_USESHOWWINDOW+STARTF_USESTDHANDLES
		startupinfo.wShowWindow=SW_HIDE
		' Create process
		lret=CreateProcess(NULL,@buff,NULL,NULL,TRUE,NULL,NULL,NULL,@startupinfo,@pinfo)
		If lret=0 Then
			' CreateProcess failed
			CloseHandle(hrd)
			CloseHandle(hwr)
			SetCursor(LoadCursor(0,IDC_ARROW))
			MessageBox(ah.hwnd,@buff,@szAppName,MB_ICONERROR+MB_OK)
		Else
			CloseHandle(hwr)
			SetFocus(ah.hout)
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,@buff))
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,StrPtr(CR)))
			SendMessage(ah.hout,REM_REPAINT,0,TRUE)
			buffer=""
			While TRUE
				lret=ReadFile(hrd,@rd,1,@bytesRead,NULL)
				If lret=0 Then
					Exit While
				ElseIf Asc(rd)=10 Then
					SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,@buffer))
					buffer=""
				Else
					buffer=buffer & rd
				EndIf
			Wend
			CloseHandle(pinfo.hProcess)
			CloseHandle(pinfo.hThread)
			CloseHandle(hrd)
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,@buffer))
			Return 0
		EndIf
	EndIf
	Return -1
	
End Function

Function GetErrLine(ByVal buff As String,ByVal fQuickRun As Boolean) As Integer
	Dim As Integer x,y
	Dim sItem As ZString*260
	Dim buffer As ZString*4096

	buffer=buff
	x=2
	While x
		x=InStr(x,buffer,"(")
		y=InStr(x,buffer,")")
		If y-x>1 And y-x<7 Then
			y=Val(Mid(buffer,x+1))-1
			If fQuickRun Then
				buffer=ad.filename
			Else
				buffer[x-1]=NULL
				If fProject Then
					If Asc(buffer,2)<>Asc(":") Then
						buffer=ad.ProjectPath & "\" & buffer
					EndIf
				Else
					If Asc(buffer,2)<>Asc(":") Then
						GetCurrentDirectory(260,@sItem)
						buffer=sItem & "\" & buffer
					EndIf
				EndIf
			EndIf
			For x=1 To Len(buffer)
				If Asc(buffer,x)=Asc("/") Then
					buffer=Left(buffer,x-1) & "\" & Mid(buffer,x+1)
				EndIf
			Next x
			If fQuickRun=FALSE Then
				GetFullPathName(@buffer,SizeOf(buffer),@buffer,Cast(LPTSTR ptr,@x))
				OpenTheFile(buffer)
			EndIf
			Return y
		ElseIf x Then
			x=x+1
		EndIf
	Wend
	Return -1

End Function

Function Make(ByVal sMakeOpt As String,ByVal sFile As String,ByVal fModule As Boolean,ByVal fNoClear As Boolean,ByVal fQuickRun As Boolean) As Integer
	Dim fExitCode As Integer
	Dim lret As Integer
	Dim buffer As ZString*4096
	Dim sItem As ZString*260
	Dim nLine As Integer
	Dim cPos As Integer
	Dim nErr As Integer
	Dim As Integer x,y
	Dim chrg As CHARRANGE
	Dim msg As MSG

	CallAddins(ah.hwnd,AIM_MAKEBEGIN,Cast(WPARAM,@sFile),Cast(LPARAM,@sMakeOpt),HOOK_MAKEBEGIN)
	nErr=0
	If fNoClear=FALSE Then
		SendMessage(ah.hwnd,IDM_OUTPUT_CLEAR,0,0)
	EndIf
	ShowOutput(TRUE)
	If fProject Then
		SetCurrentDirectory(@ad.ProjectPath)
		If fModule Then
			buff=sMakeOpt & " " & """" & sFile & """"
		Else
			sItem=sFile
			If fQuickRun Then
				sItem=GetFileName(ad.filename,FALSE)
			Else
				x=InStr(sItem,".")
				y=x
				While x
					y=x
					x=InStr(x+1,sItem,".")
				Wend
				If y Then
					sItem[y-1]=NULL
				EndIf
			EndIf
			If fProject Then
				sItem=GetProjectResource
			Else
				sItem=sItem & ".rc"
			EndIf
			If (fProject<>0 And fAddMainFiles<>0) Or fProject=0 Then
				If GetFileAttributes(@sItem)<>-1 Then
					buff=sMakeOpt & " " & """" & sFile & """" & " " & """" & sItem & """"
				Else
					buff=sMakeOpt & " " & """" & sFile & """"
				EndIf
			Else
				buff=sMakeOpt
			EndIf
			' Add module oject files
			lret=1001
			Do While lret<1256
				sItem=String(260,szNULL)
				GetPrivateProfileString(StrPtr("File"),Str(lret),@szNULL,@sItem,SizeOf(sItem),@ad.ProjectFile)
				If Len(sItem) Then
					x=InStr(sItem,".")
					y=x
					While x
						y=x
						x=InStr(x+1,sItem,".")
					Wend
					If y Then
						sItem[y-1]=NULL
					EndIf
					If fRecompile=2 Then
						buff=buff & " " & """" & sItem & ".bas" & """"
					Else
						buff=buff & " " & """" & sItem & ".o" & """"
					EndIf
				EndIf
				lret=lret+1
			Loop
			If Len(ad.smakeoutput)<>0 And fQuickRun=FALSE Then
				buff=buff & " -x """ & ad.smakeoutput & """"
			EndIf
		EndIf
	Else
		buff=sFile
		GetFilePath(buff)
		SetCurrentDirectory(@buff)
		If fModule Then
			buff=sMakeOpt & " " & """" & GetFileName(sFile,TRUE)
			buff=buff & """"
		Else
			If fQuickRun Then
				sItem=GetFileName(ad.filename,FALSE)
			Else
				sItem=GetFileName(sFile,FALSE)
			EndIf
			sItem=sItem & ".rc"
			If GetFileAttributes(@sItem)<>-1 Then
				buff=sMakeOpt & " " & """" & GetFileName(sFile,TRUE)
				buff=buff & """" & " " & """" & sItem
				buff=buff & """"
			Else
				buff=sMakeOpt & " " & """" & GetFileName(sFile,TRUE)
				buff=buff & """"
			EndIf
		EndIf
	EndIf
'	lret=CreateThread(NULL,NULL,@MakeProc,0,NORMAL_PRIORITY_CLASS,@x)
'Nxt:
'	GetExitCodeThread(lret,@x)
'	If x=STILL_ACTIVE Then
'		GetMessage(@msg,NULL,0,0)
'		If msg.message=WM_CHAR Then
'			If msg.wParam=VK_ESCAPE Then
'				TerminateProcess(lret,1234)
'			EndIf
'		EndIf
'		TranslateMessage(@msg)
'		DispatchMessage(@msg)
'		GoTo	Nxt
'	EndIf
	x=MakeProc(0)
	If x<>-1 Then
		nLine=1
		lret=-1
		While TRUE
			cPos=SendMessage(ah.hout,EM_LINEINDEX,nLine,0)
			If lret=cPos Then
				Exit While
			EndIf
			lret=cPos
			x=SendMessage(ah.hout,EM_LINELENGTH,cPos,0)
			buffer=Chr(x And 255) & Chr(x\256)
			x=SendMessage(ah.hout,EM_GETLINE,nLine,Cast(Integer,@buffer))
			buffer[x]=NULL
			If InStr(buffer," : error ") Or InStr(buffer,") error ") Or InStr(buffer,") warning ") Then
				If InStr(buffer,") warning ") Then
					SendMessage(ah.hout,REM_SETBOOKMARK,nLine,6)
				Else
					SendMessage(ah.hout,REM_SETBOOKMARK,nLine,7)
					nErr=nErr+1
					y=GetErrLine(buffer,fQuickRun)
					If y>=0 Then
						If ah.hred<>ah.hres Then
							chrg.cpMin=SendMessage(ah.hred,EM_LINEINDEX,y,0)
							chrg.cpMax=chrg.cpMin
							SendMessage(ah.hred,REM_SETBOOKMARK,y,7)
							SendMessage(ah.hred,EM_EXSETSEL,0,Cast(Integer,@chrg))
							SendMessage(ah.hred,EM_SCROLLCARET,0,0)
							x=SendMessage(ah.hout,REM_GETBMID,nLine,0)
							SendMessage(ah.hred,REM_SETBMID,y,x)
						EndIf
						SetFocus(ah.hred)
					EndIf
				EndIf
			ElseIf InStr(buffer,"No such file: ") Then
				SendMessage(ah.hout,REM_SETBOOKMARK,nLine,7)
				SendMessage(ah.hout,REM_SETBMID,nLine,0)
				nErr=nErr+1
			ElseIf InStr(buffer,"undefined reference to") Then
				SendMessage(ah.hout,REM_SETBOOKMARK,nLine,7)
				SendMessage(ah.hout,REM_SETBMID,nLine,0)
				nErr=nErr+1
			ElseIf InStr(buffer,"cannot open output file") Then
				SendMessage(ah.hout,REM_SETBOOKMARK,nLine,7)
				SendMessage(ah.hout,REM_SETBMID,nLine,0)
				nErr=nErr+1
			EndIf
			nLine=nLine+1
		Wend
		If nErr Then
			sItem=CR & "Build error(s)" & CR
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,@sItem))
			MessageBeep(MB_ICONERROR)
		Else
			sItem=CR & "Make done" & CR
			SendMessage(ah.hout,EM_REPLACESEL,0,Cast(Integer,@sItem))
			If ah.hred Then
				SetFocus(ah.hred)
			Else
				SetFocus(ah.hwnd)
			EndIf
		EndIf
	EndIf
	CallAddins(ah.hwnd,AIM_MAKEDONE,Cast(WPARAM,@sFile),Cast(LPARAM,@sMakeOpt),HOOK_MAKEDONE)
	Return nErr

End Function

Function CompileModules(ByVal sMake As String) As Integer
	Dim bm As Integer
	Dim id As Integer
	Dim sFile As String

	If edtopt.autosave Then
		bm=SaveAllFiles(ah.hwnd)
	Else
		bm=DialogBoxParam(hInstance,Cast(ZString ptr,IDD_DLGSAVESELECTION),ah.hwnd,@SaveAllProc,NULL)
	EndIf
	If bm=0 Then
		bm=wpos.fview And VIEW_OUTPUT
		' Clear errors
		UpdateAllTabs(2)
		fBuildErr=0
		If fProject Then
			SendMessage(ah.hwnd,IDM_OUTPUT_CLEAR,0,0)
			id=1001
			Do While id<1256
				sFile=GetProjectFile(id)
				If sFile<>"" Then
					fBuildErr=Make(sMake,sFile,TRUE,TRUE,FALSE)
					If fBuildErr Then
						Exit Do
					EndIf
				EndIf
				id=id+1
			Loop
		Else
			sFile=ad.filename
			fBuildErr=Make(sMake,sFile,TRUE,FALSE,FALSE)
		EndIf
		If fBuildErr=0 And bm=0 Then
			nHideOut=15
		Else
			nHideOut=0
		EndIf
	EndIf
	UpdateAllTabs(4)
	Return fBuildErr

End Function

Function Compile(ByVal sMake As String) As Integer
	Dim bm As Integer
	Dim sFile As String

	If edtopt.autosave Then
		bm=SaveAllFiles(ah.hwnd)
	Else
		bm=DialogBoxParam(hInstance,Cast(ZString ptr,IDD_DLGSAVESELECTION),ah.hwnd,@SaveAllProc,NULL)
	EndIf
	If bm=0 Then
		bm=wpos.fview And VIEW_OUTPUT
		' Clear errors
		UpdateAllTabs(2)
		If fProject Then
			If fRecompile=1 Then
				If CompileModules(ad.smakemodule)=0 Then
					nHideOut=0
					sFile=GetProjectFile(1)
					fBuildErr=Make(sMake,sFile,FALSE,TRUE,FALSE)
				EndIf
			Else
				sFile=GetProjectFile(1)
				fBuildErr=Make(sMake,sFile,FALSE,FALSE,FALSE)
			EndIf
		Else
			sFile=ad.filename
			fBuildErr=Make(sMake,sFile,FALSE,FALSE,FALSE)
		EndIf
		If fBuildErr=0 And bm=0 Then
			nHideOut=15
		Else
			nHideOut=0
		EndIf
	Else
		Return 1
	EndIf
	UpdateAllTabs(4)
	Return fBuildErr

End Function
