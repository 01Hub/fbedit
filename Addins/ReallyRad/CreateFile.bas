Dim Shared lpDIALOG As DIALOG Ptr

Function ConvertLine(ByVal sLine As String,ByVal sFunction As String,ByVal sName As String) As String
	Dim x As Integer

	x=InStr(sLine,sFunction)
	If x Then
		Return Left(sLine,x-1) & sName & Mid(sLine,x+Len(sFunction))
	EndIf
	Return sLine

End Function

Function FindFirstCtrl(ByVal nType As Integer) As Integer

	lpDIALOG=lpCTLDBLCLICK->lpDlgMem
	While lpDIALOG->hwnd
		If lpDIALOG->hwnd>0 And lpDIALOG->ntype=nType Then
			Return 1
		EndIf
		lpDIALOG=Cast(DIALOG Ptr,Cast(Integer,lpDIALOG)+SizeOf(DIALOG))
	Wend
	Return 0

End Function

Function FindNextCtrl(ByVal nType As Integer) As Integer

	While lpDIALOG->hwnd
		lpDIALOG=Cast(DIALOG Ptr,Cast(Integer,lpDIALOG)+SizeOf(DIALOG))
		If lpDIALOG->hwnd>0 And lpDIALOG->ntype=nType Then
			Return 1
		EndIf
	Wend
	Return 0

End Function

Function CreateOutputFile(ByVal sTemplate As String) As HGLOBAL
	Dim hMem As HGLOBAL
	Dim f As Integer
	Dim nMode As Integer
	Dim sLine As String
	Dim sTmp As String
	Dim i As Integer
	Dim lpEvent As Integer
	Dim lpBN_CLICKED As Integer
	Dim nButton As Integer
	Dim nType As Integer

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
						lpDIALOG=Cast(DIALOG Ptr,Cast(Integer,lpDIALOG)+SizeOf(DIALOG))
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
				ElseIf sLine=szBEGINEVENT Then
					lpEvent=lstrlen(hMem)
					nMode=4
				Else
					sLine=ConvertLine(sLine,szDIALOGPROC,szProc)
					lstrcat(Cast(ZString Ptr,hMem),sLine)
					lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
				EndIf
				'
			Case 4
				If sLine=szENDEVENT Then
					nMode=3
				ElseIf sLine=szBEGINBN_CLICKED Then
					lpBN_CLICKED=lstrlen(hMem)
					nType=4
					nMode=5
				Else
					lstrcat(Cast(ZString Ptr,hMem),sLine)
					lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
				EndIf
				'
			Case 5
				If sLine=szENDBN_CLICKED Then
					nMode=4
				ElseIf sLine=szBEGINSELECTCASEID Then
					nButton=FindFirstCtrl(nType)
					nMode=98
				Else
					lstrcat(Cast(ZString Ptr,hMem),sLine)
					lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
				EndIf
				'
			Case 98
				If sLine=szENDSELECTCASEID Then
					nMode=5
				ElseIf sLine=szBEGINCASEID Then
					nMode=99
				Else
					lstrcat(Cast(ZString Ptr,hMem),sLine)
					lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
				EndIf
			Case 99
				If sLine=szENDCASEID Then
					nMode=98
				Else
					While nButton
						sTmp=ConvertLine(sLine,szCONTROLNAME,lpDIALOG->idname)
						lstrcat(Cast(ZString Ptr,hMem),sTmp)
						lstrcat(Cast(ZString Ptr,hMem),@szCRLF)
						nButton=FindNextCtrl(nType)
					Wend
				EndIf
		End Select
	Wend
	Close
	Return hMem

End Function
