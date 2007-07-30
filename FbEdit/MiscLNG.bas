
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

Function FindString(ByVal szApp As String,ByVal szKey As String) As String
	Dim hMem As HGLOBAL
	Dim buff As ZString*512
	Dim As Integer x,y
	Dim lp As ZString Ptr

	hMem=GlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,256*1024)
	SendMessage(hEdt,WM_GETTEXT,256*1024,Cast(LPARAM,hMem))
	buff="[" & szApp & "]"
	lp=hMem
	x=InStr(*lp,buff)
	If x Then
		buff=szKey & "="
		x=InStr(x,*lp,buff)
		If x Then
			x=x+Len(buff)
			y=InStr(x,*lp,!"\13")
			buff=Mid(*lp,x,y-x)
		Else
			buff=""
		EndIf
	Else
		buff=""
	EndIf
	GlobalFree(hMem)
	Return buff

End Function

