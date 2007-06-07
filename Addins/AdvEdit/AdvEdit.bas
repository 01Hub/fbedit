#Include Once "windows.bi"
#Include Once "win/richedit.bi"
#Include Once "win/commctrl.bi"

#Include "..\..\FbEdit\Inc\Addins.bi"
#Include "..\..\FbEdit\Inc\RAEdit.bi"

#Include "AdvEdit.bi"

Sub AddToMenu(ByVal id As Integer,ByVal sMenu As String)

	AppendMenu(hSubMnu,MF_STRING,id,sMenu)

End Sub

Sub UpdateMenu(ByVal id As Integer,ByVal sMenu As String)
	Dim mii As MENUITEMINFO

	mii.cbSize=SizeOf(MENUITEMINFO)
	mii.fMask=MIIM_TYPE
	mii.fType=MFT_STRING
	mii.dwTypeData=@sMenu
	SetMenuItemInfo(lpHandles->hmenu,id,FALSE,@mii)

End Sub

Sub AddAccelerator(ByVal fvirt As Integer,ByVal akey As Integer,ByVal id As Integer)
	Dim nAccel As Integer
	Dim acl(500) As ACCEL
	Dim i As Integer

	nAccel=CopyAcceleratorTable(lpHandles->haccel,NULL,0)
	CopyAcceleratorTable(lpHandles->haccel,@acl(0),nAccel)
	DestroyAcceleratorTable(lpHandles->haccel)
	' Check if id exist
	For i=0 To nAccel-1
		If acl(i).cmd=id Then
			' id exist, update accelerator
			acl(i).fVirt=fvirt
			acl(i).key=akey
			GoTo Ex
		EndIf
	Next i
	' Check if accelerator exist
	For i=0 To nAccel-1
		If acl(i).fVirt=fvirt And acl(i).key=akey Then
			' Accelerator exist, update id
			acl(i).cmd=id
			GoTo Ex
		EndIf
	Next i
	' Add new accelerator
	acl(nAccel).fVirt=fvirt
	acl(nAccel).key=akey
	acl(nAccel).cmd=id
	nAccel=nAccel+1
Ex:
	lpHandles->haccel=CreateAcceleratorTable(@acl(0),nAccel)

End Sub

Sub AddToolbarButton(ByVal id As Integer,ByVal idbmp As Integer)
	Dim tbab As TBADDBITMAP
	Dim tbbtn As TBBUTTON

	tbab.hInst=hInstance
	tbab.nID=idbmp
	tbbtn.iBitmap=SendMessage(lpHandles->htoolbar,TB_ADDBITMAP,1,Cast(LPARAM,@tbab))

	tbbtn.idCommand=id
	tbbtn.fsState=TBSTATE_ENABLED
	tbbtn.fsStyle=TBSTYLE_BUTTON
	SendMessage(lpHandles->htoolbar,TB_BUTTONSTRUCTSIZE,SizeOf(TBBUTTON),0)
	SendMessage(lpHandles->htoolbar,TB_INSERTBUTTON,-1,Cast(LPARAM,@tbbtn))
	lpData->tbwt=lpData->tbwt+24

End Sub

' Returns info on what messages the addin hooks into (in an ADDINHOOKS type).
Function InstallDll Cdecl Alias "InstallDll" (ByVal hWin As HWND,ByVal hInst As HINSTANCE) As ADDINHOOKS ptr Export

	' The dll's instance
	hInstance=hInst
	' Get pointer to ADDINHANDLES
	lpHandles=Cast(ADDINHANDLES ptr,SendMessage(hWin,AIM_GETHANDLES,0,0))
	' Get pointer to ADDINDATA
	lpData=Cast(ADDINDATA ptr,SendMessage(hWin,AIM_GETDATA,0,0))
	' Get pointer to ADDINFUNCTIONS
	lpFunctions=Cast(ADDINFUNCTIONS ptr,SendMessage(hWin,AIM_GETFUNCTIONS,0,0))
	' Add "Advanced" sub menu to "Edit" menu.
	hSubMnu=CreatePopupMenu
	AppendMenu(GetSubMenu(lpHANDLES->hmenu,1),MF_STRING Or MF_POPUP,Cast(Integer,hSubMnu),StrPtr("Advanced Edit"))

	' Add menu items to "Advanced" sub menu
	' Word commands
	IdSelectWord=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdSelectWord,"Select Word	Shift+Ctrl+W")
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT Or FCONTROL,Asc("W"),IdSelectWord)
	IdCopyWord=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdCopyWord,"Copy Word	Shift+Ctrl+C")
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT Or FCONTROL,Asc("C"),IdCopyWord)
	IdCutWord=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdCutWord,"Cut Word	Shift+Ctrl+X")
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT Or FCONTROL,Asc("X"),IdCutWord)
	IdDeleteWord=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdDeleteWord,"Delete Word")
	' Line commands
	IdSelectLine=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdSelectLine,"Select Line	Shift+Ctrl+L")
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FSHIFT Or FCONTROL,Asc("L"),IdSelectLine)
	IdCopyLine=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdCopyLine,"Copy Line	Alt+Ctrl+C")
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FALT Or FCONTROL,Asc("C"),IdCopyLine)
	IdCutLine=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdCutLine,"Cut Line	Alt+Ctrl+X")
	AddAccelerator(FVIRTKEY Or FNOINVERT Or FALT Or FCONTROL,Asc("X"),IdCutLine)
	IdDeleteLine=SendMessage(hWin,AIM_GETMENUID,0,0)
	AddToMenu(IdDeleteLine,"Delete Line")

/'	' Change accelerator for an existing command
	#define IDM_EDIT_REDO						10023
	' Update the accelerator
	AddAccelerator(FVIRTKEY or FNOINVERT or FSHIFT or FCONTROL,Asc("Z"),IDM_EDIT_REDO)
	' Update the menu
	UpdateMenu(IDM_EDIT_REDO,"&Redo	Shift+Ctrl+Z")
'/

	' Add quick run button to toolbar
	AddToolbarButton(IDM_MAKE_QUICKRUN,100)

	' Messages this addin will hook into
	hooks.hook1=HOOK_COMMAND Or HOOK_GETTOOLTIP
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	Return @hooks

End Function

Sub SelectWord
	Dim chrg As CHARRANGE

	SendMessage(lpHandles->hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
	chrg.cpMin=SendMessage(lpHandles->hred,EM_FINDWORDBREAK,WB_MOVEWORDLEFT,chrg.cpMin)
	chrg.cpMax=SendMessage(lpHandles->hred,EM_FINDWORDBREAK,WB_MOVEWORDRIGHT,chrg.cpMin)
	SendMessage(lpHandles->hred,EM_EXSETSEL,0,Cast(LPARAM,@chrg))

End Sub

Sub CopyWord

	SelectWord
	SendMessage(lpHandles->hred,WM_COPY,0,0)

End Sub

Sub CutWord

	SelectWord
	SendMessage(lpHandles->hred,WM_CUT,0,0)

End Sub

Sub DeleteWord

	SelectWord
	SendMessage(lpHandles->hred,WM_CLEAR,0,0)

End Sub

Sub SelectLine
	Dim chrg As CHARRANGE
	Dim nLn As Integer

	SendMessage(lpHandles->hred,EM_EXGETSEL,0,Cast(LPARAM,@chrg))
	nLn=SendMessage(lpHandles->hred,EM_LINEFROMCHAR,chrg.cpMin,0)
	chrg.cpMin=SendMessage(lpHandles->hred,EM_LINEINDEX,nLn,0)
	chrg.cpMax=chrg.cpMin+SendMessage(lpHandles->hred,EM_LINELENGTH,chrg.cpMin,0)+1
	SendMessage(lpHandles->hred,EM_EXSETSEL,0,Cast(LPARAM,@chrg))

End Sub

Sub CopyLine

	SelectLine
	SendMessage(lpHandles->hred,WM_COPY,0,0)

End Sub

Sub CutLine

	SelectLine
	SendMessage(lpHandles->hred,WM_CUT,0,0)

End Sub

Sub DeleteLine

	SelectLine
	SendMessage(lpHandles->hred,WM_CLEAR,0,0)

End Sub

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
Function DllFunction Cdecl Alias "DllFunction" (ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer Export

	Select Case uMsg
		Case AIM_COMMAND
			If lpHandles->hred<>0 And lpHandles->hred<>lpHandles->hres Then
				Select Case LoWord(wParam)
					Case IdSelectWord
						SelectWord
						'
					Case IdCopyWord
						CopyWord
						'
					Case IdCutWord
						CutWord
						'
					Case IdDeleteWord
						DeleteWord
						'
					Case IdSelectLine
						SelectLine
						'
					Case IdCopyLine
						CopyLine
						'
					Case IdCutLine
						CutLine
						'
					Case IdDeleteLine
						DeleteLine
						'
				End Select
			EndIf
			'
		Case AIM_GETTOOLTIP
			If wParam=IDM_MAKE_QUICKRUN Then
				Return Cast(Integer,@szQuickRun)
			EndIf
			'
	End Select
	Return FALSE

End Function
