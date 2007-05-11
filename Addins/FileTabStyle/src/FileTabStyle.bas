
/' File Tab Styler, by krcko

	Addin for FBEdit
	
	Adds some options to file tab control.

'/


#include once "windows.bi"
#include once "win/commctrl.bi"

#include "..\..\..\..\Inc\Addins.bi"

Type TABMEM
	hedit			As HWND
	filename		As ZString * 260
	profileinx		As Integer
	filestate		As Integer
End Type

#define IDB_TABICONS 100

#define TAB_STYLE_BASE     TCS_FOCUSNEVER Or WS_CHILD Or WS_CLIPCHILDREN Or WS_CLIPSIBLINGS Or WS_TABSTOP Or WS_VISIBLE Or TCS_FORCEICONLEFT Or TCS_FORCELABELLEFT

'' tab styles
#define TAB_STYLE_DEFAULT  TCS_TABS
#define TAB_STYLE_BUTTONS  TCS_BUTTONS Or TCS_BOTTOM
#define TAB_STYLE_FLAT     TAB_STYLE_BUTTONS Or TCS_FLATBUTTONS Or TCS_HOTTRACK 

#define TAB_STYLE_ID_DEFAULT   0
#define TAB_STYLE_ID_BUTTONS   1
#define TAB_STYLE_ID_FLAT      2


Dim Shared lpHandles	As ADDINHANDLES Pointer
Dim Shared lpFunctions 	As ADDINFUNCTIONS Pointer

Dim Shared CurTabStyle 	As Byte
Dim Shared FixedWidth   As Byte
Dim Shared ModIndicator	As Byte

Dim Shared mnuTabStyle	As HMENU
Dim Shared mnuModType	As HMENU
Dim Shared mnuDefault	As Integer
Dim Shared mnuButtons	As Integer
Dim Shared mnuFlat		As Integer
Dim Shared mnuFixed		As Integer
Dim Shared mnuModPic	As Integer
Dim Shared mnuModTxt	As Integer
Dim Shared mnuModOff	As Integer


Sub SetTabStyle
	
	Dim As Integer TabStyle = TAB_STYLE_DEFAULT
	
	If CurTabStyle = TAB_STYLE_ID_BUTTONS Then
		
		TabStyle = TAB_STYLE_BUTTONS
		
	ElseIf CurTabStyle = TAB_STYLE_ID_FLAT Then
		
		TabStyle = TAB_STYLE_FLAT
	
	End If
	
	If FixedWidth Then
		
		TabStyle Or= TCS_FIXEDWIDTH
		
	End If
	
	SetWindowLong lpHandles->htabtool, GWL_STYLE, TAB_STYLE_BASE Or TabStyle
	
End Sub

#macro Check(_menu_, _item_, _condition_)
mmi.fState = Iif(_condition_, MFS_CHECKED, MFS_UNCHECKED)
SetMenuItemInfo _menu_, _item_, FALSE, VarPtr(mmi)
#endmacro

Sub UpdateMenu
	
	Dim mmi As MENUITEMINFO
	
	mmi.cbSize = SizeOf(MMI)
	mmi.fMask = MIIM_STATE
	
	Check(mnuTabStyle, mnuDefault, CurTabStyle = TAB_STYLE_ID_DEFAULT)
	
	Check(mnuTabStyle, mnuButtons, CurTabStyle = TAB_STYLE_ID_BUTTONS)
	
	Check(mnuTabStyle, mnuFlat, CurTabStyle = TAB_STYLE_ID_FLAT)
	
	Check(mnuTabStyle, mnuFixed, FixedWidth)
	
	Check(mnuModType, mnuModPic, ModIndicator And TCIF_IMAGE)
	
	Check(mnuModType, mnuModTxt, ModIndicator And TCIF_TEXT)
	
	Check(mnuModType, mnuModOff, ModIndicator = 0)		

End Sub


Function GetTabInfo(index As Integer, ByRef image As Integer, remAsterisk As Byte = 1) As String
	
	Dim item	As TC_ITEM
	Dim buffer	As String = String(100, 0)
	
	item.mask = TCIF_TEXT Or TCIF_IMAGE
	item.pszText = StrPtr(buffer)
	item.cchTextMax = 100
	
	SendMessage lpHandles->htabtool, TCM_GETITEM, index, VarPtr(item)
	
  	buffer = Left(buffer, InStr(buffer, !"\0") - 1)
	
	If (Right(buffer, 2) = " *") And remAsterisk Then buffer = Left(buffer, Len(buffer) - 2)

	image = item.iImage
	
	Return buffer

End Function

Sub ClearIndicators
	
	Dim TabCount	As Integer
	Dim TabText		As String
	Dim TabImage	As Integer
	Dim TabItem		As TC_ITEM
	
	ModIndicator = 0
	
	TabCount = SendMessage(lpHandles->htabtool, TCM_GETITEMCOUNT, 0, 0)
	
	For TabIndex As Integer = 0 To TabCount - 1
		
		TabText = GetTabInfo(TabIndex, TabImage, 0)
		
		TabItem.mask = 0
		
		If Right(TabText, 2) = " *" Then
			
			TabText = Left(TabText, Len(TabText) - 2)
			
			TabItem.mask = TCIF_TEXT
			
			TabItem.pszText = StrPtr(TabText)
			
		End If
		
		If TabImage > 6 Then
			
			TabItem.mask Or= TCIF_IMAGE
			
			TabItem.iImage = TabImage - 7
		
		End If
		
		SendMessage lpHandles->htabtool, TCM_SETITEM, TabIndex, VarPtr(TabItem)
		
	Next
	

End Sub

Sub UpdateTab(ByRef theTab As TABMEM, index As Integer)
	
	Dim changed	As Byte
	Dim item 	As TC_ITEM
	Dim text 	As ZString * 260
	Dim image	As Integer
	
	changed = theTab.filestate And 1
	
	If ModIndicator Then
	
		item.mask = ModIndicator
		
		text = GetTabInfo(index, image)
		
		If item.mask And TCIF_TEXT Then 
			
			If changed Then text += " *"
			
			item.pszText = StrPtr(text)
		
		End If
		
		If item.mask And TCIF_IMAGE Then
			
			If changed Then 
				image += 7
			Else
				image -= 7
			End If
			
			item.iImage = image
		
		End If
		
		SendMessage lpHandles->htabtool, TCM_SETITEM, index, VarPtr(item)
	
	End If

End Sub

' Returns info on what messages the addin hooks into (in an ADDINHOOKS type).
Function InstallDll CDecl Alias "InstallDll" (ByVal hWin As HWND, ByVal hInst As HINSTANCE) As ADDINHOOKS Pointer Export
	
	Dim hooks 	As ADDINHOOKS
	Dim mnuView	As HMENU
	Dim hBmp	As HBITMAP

	' Get pointer to ADDINHANDLES
	lpHandles = Cast(ADDINHANDLES Pointer, SendMessage(hWin, AIM_GETHANDLES, 0, 0))
	
	' Get pointer to ADDINFUNCTIONS
	lpFunctions = Cast(ADDINFUNCTIONS Pointer, SendMessage(hWin, AIM_GETFUNCTIONS, 0, 0))
	
	' add images to image list
	hBmp = LoadBitmap(hInst, Cast(ZString Pointer, IDB_TABICONS)) 
	ImageList_AddMasked lpHandles->himl, hBmp, &HFF00FF
	DeleteObject hBmp
	
	' get from ini and restore last used style
	lpFunctions->LoadFromIni("FileTabStyler", "Style", "1", VarPtr(CurTabStyle), FALSE)
	lpFunctions->LoadFromIni("FileTabStyler", "Fixed", "1", VarPtr(FixedWidth), FALSE)
	lpFunctions->LoadFromIni("FileTabStyler", "ModStyle", "1", VarPtr(ModIndicator), FALSE)
	SetTabStyle
	
	' create new menus
	mnuTabStyle = CreateMenu
	mnuModType = CreateMenu
	' get View menu
	mnuView = GetSubMenu(lpHandles->hmenu, 3)
	' add menu item to View menu
	AppendMenu mnuView, MF_STRING Or MF_POPUP, mnuTabStyle, StrPtr("File tab style")
	' get menu ids
	mnuDefault = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	mnuButtons = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	mnuFlat = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	mnuFixed = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	mnuModPic = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	mnuModTxt = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	mnuModOff = SendMessage(hWin, AIM_GETMENUID, 0, 0)
	' add menu items
	AppendMenu mnuTabStyle, MF_STRING, mnuDefault, StrPtr("Default")
	AppendMenu mnuTabStyle, MF_STRING, mnuButtons, StrPtr("Buttons")
	AppendMenu mnuTabStyle, MF_STRING, mnuFlat, StrPtr("Flat")
	AppendMenu mnuTabStyle, MF_SEPARATOR, 0, 0
	AppendMenu mnuTabStyle, MF_STRING Or MF_POPUP, mnuModType, StrPtr("Modified state indicator")
	AppendMenu mnuTabStyle, MF_STRING, mnuFixed, StrPtr("Fixed width")
	AppendMenu mnuModType, MF_STRING, mnuModPic, StrPtr("Hillite icon")
	AppendMenu mnuModType, MF_STRING, mnuModTxt, StrPtr("Asterisk character")
	AppendMenu mnuModType, MF_STRING, mnuModOff, StrPtr("No indicator")
	
	UpdateMenu
	

	' Messages this addin will hook into
	hooks.hook1 = HOOK_COMMAND Or HOOK_FILESTATE Or HOOK_CLOSE
	hooks.hook2 = 0
	hooks.hook3 = 0
	hooks.hook4 = 0
	
	Return VarPtr(hooks)

End Function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
Function DllFunction CDecl Alias "DllFunction" (ByVal hWin As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As bool Export
	
	If uMsg = AIM_COMMAND Then		
		
		Select Case LoWord(wParam)
			
			Case mnuDefault : CurTabStyle = TAB_STYLE_ID_DEFAULT
			
			Case mnuButtons : CurTabStyle = TAB_STYLE_ID_BUTTONS
			
			Case mnuFlat    : CurTabStyle = TAB_STYLE_ID_FLAT
			
			Case mnuFixed   : FixedWidth = Not FixedWidth
			
			Case mnuModPic
				If ModIndicator And TCIF_IMAGE Then
					ModIndicator And= Not TCIF_IMAGE
				Else
					ModIndicator Or= TCIF_IMAGE
				End If
			
			Case mnuModTxt
				If ModIndicator And TCIF_TEXT Then
					ModIndicator And= Not TCIF_TEXT
				Else
					ModIndicator Or= TCIF_TEXT
				End If			
			
			Case mnuModOff  : ClearIndicators
			
			Case Else : Return False
		
		End Select
		
		SetTabStyle
		
		UpdateMenu
		
		Return True
	
	ElseIf uMsg = AIM_FILESTATE Then
		
		UpdateTab *Cast(TABMEM Pointer, lParam), wParam
	
	ElseIf uMsg = AIM_CLOSE Then
		
		lpFunctions->SaveToIni("FileTabStyler", "Style", "1", VarPtr(CurTabStyle), FALSE)
		lpFunctions->SaveToIni("FileTabStyler", "Fixed", "1", VarPtr(FixedWidth), FALSE)
		lpFunctions->SaveToIni("FileTabStyler", "ModStyle", "1", VarPtr(ModIndicator), FALSE)
		
		DestroyMenu mnuTabStyle
		DestroyMenu mnuModType	
		
	End If

	Return FALSE

End Function
