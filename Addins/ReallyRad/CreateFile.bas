
Function ConvertLine(ByVal sLine As String,ByVal sFunction As String,ByVal sName As String) As String
	Dim x As Integer

	x=InStr(sLine,sFunction)
	If x Then
		Return Left(sLine,x-1) & sName & Mid(sLine,x+Len(sFunction))
	EndIf
	Return sLine

End Function

Function CreateOutputFile(ByVal sTemplate As String) As HGLOBAL
	Dim hMem As HGLOBAL
	Dim f As Integer
	Dim sLine As String

	f=FreeFile
	Open sTemplate For Input As #f
	While Not Eof(f)
		Line Input #f,sLine
		sLine=ConvertLine(sLine,szDIALOGNAME,szName)
		sLine=ConvertLine(sLine,szDIALOGPROC,szProc)
lpFunctions->TextToOutput(sLine)
	Wend
	Close
	hMem=GlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,128*1024)
	Return hMem

End Function
