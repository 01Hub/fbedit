
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
	Dim nMode As Integer
	Dim sLine As String
	Dim sTmp As String
	Dim lpDIALOG As DIALOG Ptr
	Dim i As Integer

	hMem=GlobalAlloc(GMEM_FIXED Or GMEM_ZEROINIT,128*1024)
	f=FreeFile
	Open sTemplate For Input As #f
	' Skip description
	Line Input #f,sLine
	While Not Eof(f)
		Line Input #f,sLine
		Select Case nMode
			Case 0
				If sLine=szBEGINDEF Then
					lpDIALOG=lpCTLDBLCLICK->lpDlgMem
					nMode=1
				ElseIf sLine=szBEGINCREATE Then
					nMode=2
				ElseIf sLine=szBEGINPROC Then
					nMode=3
				EndIf
			Case 1
				If sLine=szENDDEF Then
					nMode=0
				Else
					While lpDIALOG->hwnd
						If lpDIALOG->hwnd>0 Then
							If Len(lpDIALOG->idname) Then
								sTmp=ConvertLine(sLine,szCONTROLNAME,lpDIALOG->idname)
								sTmp=ConvertLine(sTmp,szCONTROLID,Str(lpDIALOG->id))
								lstrcat(Cast(ZString Ptr,hMem),sTmp)
								lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
							EndIf
						EndIf
						i=Cast(Integer,lpDIALOG)
						i=i+SizeOf(DIALOG)
						lpDIALOG=Cast(DIALOG Ptr,i)
					Wend
				EndIf
				'
			Case 2
				If sLine=szENDCREATE Then
					nMode=0
				Else
					sLine=ConvertLine(sLine,szDIALOGNAME,szName)
					sLine=ConvertLine(sLine,szDIALOGPROC,szProc)
					lstrcat(Cast(ZString Ptr,hMem),sLine)
					lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
				EndIf
				'
			Case 3
				If sLine=szENDPROC Then
					nMode=0
				Else
					sLine=ConvertLine(sLine,szDIALOGPROC,szProc)
					lstrcat(Cast(ZString Ptr,hMem),sLine)
					lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
				EndIf
				'
		End Select
	Wend
	Close
	Return hMem

End Function
