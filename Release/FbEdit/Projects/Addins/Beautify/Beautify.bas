#include once "windows.bi"
#include once "win/commctrl.bi"

#include "..\..\FbEdit\Inc\Addins.bi"

#include "Beautify.bi"

' Update toolbar imagelists
sub Toolbar
	Dim nOld As Integer
	Dim nNew As Integer
	Dim hOldIml As HIMAGELIST
	dim hDC as HDC
	dim mDC as HDC
	dim hBmp as HBITMAP
	dim hOldBmp as HBITMAP
	dim hBr as HBRUSH
	dim rect as RECT
	dim i as integer
	dim x as integer
	dim y as integer
	dim c as integer

	' Destroy old imagelist
	hOldIml=Cast(HIMAGELIST,SendMessage(lpHANDLES->htoolbar,TB_GETIMAGELIST,0,0))
	nOld=ImageList_GetImageCount(hOldIml)
	SendMessage(lpHANDLES->htoolbar,TB_SETIMAGELIST,0,NULL)
	' Create a new imagelist
	hIml=ImageList_LoadImage(hInstance,Cast(zstring ptr,IDB_TOOLBAR),16,29,&HC0C0C0,IMAGE_BITMAP,LR_CREATEDIBSECTION)
	nNew=ImageList_GetImageCount(hIml)
	hDC=GetDC(NULL)
	mDC=CreateCompatibleDC(hDC)
	hBr=CreateSolidBrush(&HC0C0C0)
	hBmp=CreateCompatibleBitmap(hDC,16,16)
	rect.left=0
	rect.top=0
	rect.right=16
	rect.bottom=16
	While nNew<nOld
		hOldBmp=SelectObject(mDC,hBmp)
		FillRect(mDC,@rect,hBR)
		ImageList_Draw(hOldIml,nNew,mDC,0,0,ILD_TRANSPARENT)
		SelectObject(mDC,hOldBmp)
		ImageList_AddMasked(hIml,hBmp,&HC0C0C0)
		nNew=nNew+1
	Wend
	DeleteObject(hBmp)
	ImageList_Destroy(hOldIml)
	' Create a grayed bitmap
	rect.left=0
	rect.top=0
	rect.right=nOld*16
	rect.bottom=16
	hBmp=CreateCompatibleBitmap(hDC,rect.right,rect.bottom)
	ReleaseDC(NULL,hDC)
	hOldBmp=SelectObject(mDC,hBmp)
	FillRect(mDC,@rect,hBr)
	DeleteObject(hBr)
	i=0
	while i<nOld
		ImageList_Draw(hIml,i,mDC,rect.left,0,ILD_TRANSPARENT)
		rect.left=rect.left+16
		i=i+1
	wend
	y=0
	while y<16
		x=0
		while x<rect.right
			c=GetPixel(mDC,x,y)
			if c<>&HC0C0C0 then
				asm
					mov		eax,[c]
					bswap		eax
					shr		eax,8
					'movzx		ecx,al			' red
					xor		ecx,ecx
					mov		cl,al
					imul		ecx,ecx,66
					'movzx		edx,ah			' green
					xor		edx,edx
					mov		dl,ah
					imul		edx,edx,129
					add		edx,ecx
					shr		eax,16			' blue
					imul		eax,eax,25
					add		eax,edx
					add		eax,128
					shr		eax,8
					add		eax,16
					imul		eax,eax,&H010101
					and		eax,&HFCFCFC
					shr		eax,2
					or			eax,&H808080
					mov		[c],eax
				end asm
				SetPixel(mDC,x,y,c)
			endif
			x=x+1
		wend
		y=y+1
	wend
	SelectObject(mDC,hOldBmp)
	DeleteDC(mDC)
	' Create a grayed imagelist
	hGrayIml=ImageList_Create(16,16,ILC_MASK or ILC_COLOR24,nOld,0)
	ImageList_AddMasked(hGrayIml,hBmp,&HC0C0C0)
	DeleteObject(hBmp)
	' Set the new imagelists to the toolbar
	SendMessage(lpHANDLES->htoolbar,TB_SETIMAGELIST,0,Cast(LPARAM,hIml))
	SendMessage(lpHANDLES->htoolbar,TB_SETDISABLEDIMAGELIST,0,Cast(LPARAM,hGrayIml))
	hBmp=LoadBitmap(hInstance,Cast(zstring ptr,IDB_MENUCHECK))
	nCheck=ImageList_AddMasked(hIml,hBmp,&HC0C0C0)
	DeleteObject(hBmp)

end sub

' FbEdit main window callback
function WndProc(byval hWin as HWND,byval uMsg as UINT,byval wParam as WPARAM,byval lParam as LPARAM) as integer
	dim lpMEASUREITEMSTRUCT as MEASUREITEMSTRUCT ptr
	dim lpDRAWITEMSTRUCT as DRAWITEMSTRUCT ptr
	dim lpMNUITEM as MNUITEM ptr
	dim mDC as HDC
	dim rect as RECT
	dim rect1 as RECT
	dim hBmp as HBITMAP
	dim hOldBmp as HBITMAP
	dim hOldFont as HFONT
	dim hBr as HBRUSH
	dim hBr1 as HBRUSH
	dim hPen as HPEN
	dim hOldPen as HPEN

	select case uMsg
		case WM_MEASUREITEM
			lpMEASUREITEMSTRUCT=Cast( MEASUREITEMSTRUCT ptr,lParam)
			if lpMEASUREITEMSTRUCT->CtlType=ODT_MENU and hMem<>0 then
				lpMNUITEM=Cast(MNUITEM ptr,lpMEASUREITEMSTRUCT->itemData)
				lpMEASUREITEMSTRUCT->itemWidth=lpMNUITEM->wdt
				lpMEASUREITEMSTRUCT->itemHeight=lpMNUITEM->hgt
				return TRUE
			endif
			'
		case WM_DRAWITEM
			lpDRAWITEMSTRUCT=Cast(DRAWITEMSTRUCT ptr,lParam)
			if lpDRAWITEMSTRUCT->CtlType=ODT_MENU and hMem<>0 then
				mDC=CreateCompatibleDC(lpDRAWITEMSTRUCT->hdc)
				rect.left=0
				rect.top=0
				rect.right=lpDRAWITEMSTRUCT->rcItem.right-lpDRAWITEMSTRUCT->rcItem.left
				rect.bottom=lpDRAWITEMSTRUCT->rcItem.bottom-lpDRAWITEMSTRUCT->rcItem.top
				hBmp=CreateCompatibleBitmap(lpDRAWITEMSTRUCT->hdc,rect.right,rect.bottom)
				hOldBmp=SelectObject(mDC,hBmp)
				hOldFont=SelectObject(mDC,hMnuFont)
				lpMNUITEM=Cast(MNUITEM ptr,lpDRAWITEMSTRUCT->itemData)
				if lpMNUITEM->ntype=2 then
					hPen=CreatePen(PS_SOLID,1,&HF5BE9F)
					hOldPen=SelectObject(mDC,hPen)
					FillRect(mDC,@rect,hMenuBrush)
					MoveToEx(mDC,rect.left+20,rect.top+5,NULL)
					LineTo(mDC,rect.right,rect.top+5)
					SelectObject(mDC,hOldPen)
					DeleteObject(hPen)
				else
					SetBkMode(mDC,TRANSPARENT)
					SetTextColor(mDC,GetSysColor(COLOR_MENUTEXT))
					if (lpDRAWITEMSTRUCT->itemState and ODS_GRAYED)=0 then
						if lpDRAWITEMSTRUCT->itemState and ODS_SELECTED then
							hBr=CreateSolidBrush(&HF5BE9F)
							FillRect(mDC,@rect,hBr)
							if lpMNUITEM->ntype=1 then
								' Menu bar
								hPen=CreatePen(PS_SOLID,1,&H800000)
								hOldPen=SelectObject(mDC,hPen)
								MoveToEx(mDC,rect.left,rect.bottom-1,NULL)
								LineTo(mDC,rect.left,rect.top)
								LineTo(mDC,rect.right-1,rect.top)
								LineTo(mDC,rect.right-1,rect.bottom)
								SelectObject(mDC,hOldPen)
								DeleteObject(hPen)
							else
								hBr1=CreateSolidBrush(&H800000)
								FrameRect(mDC,@rect,hBr1)
								DeleteObject(hBr1)
							endif
							DeleteObject(hBr)
						else
							if lpMNUITEM->ntype=1 then
								' Menu bar
								FillRect(mDC,@rect,GetSysColorBrush(COLOR_MENU))
							else
								FillRect(mDC,@rect,hMenuBrush)
								if lpDRAWITEMSTRUCT->itemState and ODS_CHECKED then
									rect1.left=0
									rect1.right=18
									rect1.top=(rect.bottom-18)/2
									rect1.bottom=rect1.top+18
									DrawEdge(mDC,@rect1,BDR_SUNKENINNER,BF_RECT)
								endif
							endif
						endif
					else
						FillRect(mDC,@rect,hMenuBrush)
					endif
					if lpDRAWITEMSTRUCT->itemState and ODS_GRAYED then
						SetTextColor(mDC,GetSysColor(COLOR_GRAYTEXT))
						if lpMNUITEM->img then
							ImageList_Draw(hGrayIml,lpMNUITEM->img-1,mDC,rect.left+1,rect.top+1,ILD_NORMAL)
						elseif lpDRAWITEMSTRUCT->itemState and ODS_CHECKED then
							ImageList_Draw(hIml,nCheck,mDC,rect.left+1,rect.top+1,ILD_NORMAL)
						endif
					else
						if lpMNUITEM->img then
							ImageList_Draw(hIml,lpMNUITEM->img-1,mDC,rect.left+1,rect.top+1,ILD_NORMAL)
						elseif lpDRAWITEMSTRUCT->itemState and ODS_CHECKED then
							ImageList_Draw(hIml,nCheck,mDC,rect.left+1,rect.top+1,ILD_NORMAL)
						endif
					endif
					if lpMNUITEM->ntype=1 then
						rect.left=rect.left+8
					else
						rect.left=rect.left+21
					endif
					rect.right=rect.right-4
					DrawText(mDC,@lpMNUITEM->txt,lstrlen(@lpMNUITEM->txt),@rect,DT_SINGLELINE or DT_VCENTER)
					DrawText(mDC,@lpMNUITEM->acl,lstrlen(@lpMNUITEM->acl),@rect,DT_SINGLELINE or DT_RIGHT or DT_VCENTER)
				endif
				BitBlt(lpDRAWITEMSTRUCT->hdc,lpDRAWITEMSTRUCT->rcItem.left,lpDRAWITEMSTRUCT->rcItem.top,lpDRAWITEMSTRUCT->rcItem.right-lpDRAWITEMSTRUCT->rcItem.left,lpDRAWITEMSTRUCT->rcItem.bottom-lpDRAWITEMSTRUCT->rcItem.top,mDC,0,0,SRCCOPY)
				SelectObject(mDC,hOldFont)
				SelectObject(mDC,hOldBmp)
				DeleteObject(hBmp)
				DeleteDC(mDC)
				return TRUE
			endif
			'
	end select
	return CallWindowProc(lpOldWndProc,hWin,uMsg,wParam,lParam)

end function

' Check if menu item exists in array
function FindMnuPos(byval pMem as MNUITEM ptr,byval hMnu as HMENU,byval wid as integer) as MNUITEM ptr
	dim i as integer

	while TRUE
		if (pMem->wid=wid and pMem->hmnu=hMnu) or pMem->hmnu=0 then
			exit while
		endif
		i=Cast(integer,pMem)
		i=i+SizeOf(MNUITEM)
		pMem=Cast(MNUITEM ptr,i)
	wend
	return pMem

end function

' Make menu items ownerdrawn
sub GetMenuItems(byval hMnu as HMENU,byval nPos as integer)
	dim mii as MENUITEMINFO
	dim buffer as zstring*260
	dim i as integer
	dim hDC as HDC
	dim mDC as HDC
	dim rect as RECT
	dim hOldFont as HFONT
	dim pMem as MNUITEM ptr

	hDC=GetDC(NULL)
	mDC=CreateCompatibleDC(hDC)
	ReleaseDC(NULL,hDC)
	hOldFont=SelectObject(mDC,hMnuFont)
NextMnu:
	mii.cbSize=sizeof(MENUITEMINFO)
	mii.fMask=MIIM_DATA or MIIM_ID or MIIM_SUBMENU or MIIM_TYPE
	mii.dwTypeData=@buffer
	mii.cch=sizeof(buffer)
	if GetMenuItemInfo(hMnu,nPos,TRUE,@mii) then
		if (mii.fType and MFT_OWNERDRAW)=0 then
			pMem=FindMnuPos(hMem,hMnu,mii.wID)
			pMem->hmnu=hMnu
			pMem->wid=mii.wID
			mii.fType=mii.fType or MFT_OWNERDRAW
			mii.dwItemData=Cast(integer,pMem)
			if (mii.fType and MFT_SEPARATOR)=0 then
				i=instr(buffer,Chr(VK_TAB))
				if i then
					lstrcpyn(@pMem->txt,@buffer,i)
					pMem->acl=mid(buffer,i+1)
				else
					lstrcpy(@pMem->txt,@buffer)
				endif
				DrawText(mDC,@pMem->txt,lstrlen(@pMem->txt),@rect,DT_CALCRECT or DT_SINGLELINE)
				pMem->wdt=rect.right
				if lstrlen(@pMem->acl) then
					DrawText(mDC,@pMem->acl,lstrlen(@pMem->acl),@rect,DT_CALCRECT or DT_SINGLELINE)
					pMem->wdt=pMem->wdt+8+rect.right
				endif
				if hMnu=hMenu then
					' Menu bar
					pMem->ntype=1
					pMem->wdt=pMem->wdt+4
				else
					' Menu item
					pMem->ntype=3
					pMem->wdt=pMem->wdt+22
					if SendMessage(lpHANDLES->htoolbar,TB_COMMANDTOINDEX,mii.wID,0)>=0 then
						pMem->img=SendMessage(lpHANDLES->htoolbar,TB_GETBITMAP,mii.wID,0)+1
					endif
				endif
				pMem->hgt=MnuFontHt
			else
				' Separator
				pMem->ntype=2
				pMem->hgt=10
			endif
			if pMem->ntype<>1 then
				SetMenuItemInfo(hMnu,nPos,TRUE,@mii)
			endif
		endif
		if mii.hSubMenu then
			GetMenuItems(mii.hSubMenu,0)
		endif
		nPos=nPos+1
		goto	NextMnu
	endif
	SelectObject(mDC,hOldFont)
	DeleteDC(mDC)

end sub

' Create a bitmap for the menu back brush
function MakeBitMap(byval barwidth as integer,byval barcolor as integer,byval bodycolor as integer) as HBITMAP
	dim hBmp as HBITMAP
	dim hOldBmp as HBITMAP
	dim hDC as HDC
	dim mDC as HDC
	dim hDeskTop as HWND
	dim as integer x,y,bc

	hDeskTop=GetDesktopWindow
	hDC=GetDC(hDeskTop)
	mDC=CreateCompatibleDC(hDC)
	hBmp=CreateCompatibleBitmap(hDC,600,8)
	ReleaseDC(hDeskTop,hDC)
	hOldBmp=SelectObject(mDC,hBmp)
	y=0
	while y<8
		x=0
		bc=barcolor
		while x<barwidth
			SetPixel(mDC,x,y,bc)
			bc=bc-&h040404
			x=x+1
		wend
		while x<600
			SetPixel(mDC,x,y,bodycolor)
			x=x+1
		wend
		y=y+1
	wend
	SelectObject(mDC,hOldBmp)
	DeleteDC(mDC)
	return hBmp

end function

' Let the menu look cool
sub CoolMenu(byval hMenu as HMENU,byval barcolor as integer,byval bodycolor as integer)
	dim MInfo as MENUINFO
	dim i as integer
	dim hMnu as HMENU
	dim hBmp as HBITMAP
	dim hBr as HBRUSH

	hBmp=MakeBitMap(22,BarColor,BodyColor)
	hBr=CreatePatternBrush(hBmp)
	DeleteObject(hBmp)
	MInfo.hbrBack=hBr
	MInfo.cbSize=SizeOf(MENUINFO)
	MInfo.fmask=MIM_BACKGROUND or MIM_APPLYTOSUBMENUS
	i=0
  Nxt:
	hMnu=GetSubMenu(hMenu,i)
	if hMnu then
		SetMenuInfo(hMnu,@MInfo)
		i=i+1
		goto Nxt
	endif

end sub


' Returns info on what messages the addin hooks into (in an ADDINHOOKS type).
function InstallDll CDECL alias "InstallDll" (byval hWin as HWND,byval hInst as HINSTANCE) as ADDINHOOKS ptr EXPORT

	' The dll's instance
	hInstance=hInst
	' Get pointer to ADDINHANDLES
	lpHandles=Cast(ADDINHANDLES ptr,SendMessage(hWin,AIM_GETHANDLES,0,0))
	' Get pointer to ADDINDATA
	lpData=Cast(ADDINDATA ptr,SendMessage(hWin,AIM_GETDATA,0,0))
	' Get pointer to ADDINFUNCTIONS
	lpFunctions=Cast(ADDINFUNCTIONS ptr,SendMessage(hWin,AIM_GETFUNCTIONS,0,0))
	' Messages this addin will hook into
	hooks.hook1=HOOK_CLOSE or HOOK_ADDINSLOADED or HOOK_MENUREFRESH
	hooks.hook2=0
	hooks.hook3=0
	hooks.hook4=0
	return @hooks

end function

' FbEdit calls this function for every addin message that this addin is hooked into.
' Returning TRUE will prevent FbEdit and other addins from processing the message.
function DllFunction CDECL alias "DllFunction" (byval hWin as HWND,byval uMsg as UINT,byval wParam as WPARAM,byval lParam as LPARAM) as bool EXPORT
	dim hBmp as HBITMAP
	dim ncm as NONCLIENTMETRICS

	select case uMsg
		case AIM_CLOSE
			' FbEdit is closing
			DeleteObject(hMnuFont)
			DeleteObject(hMenuBrush)
			GlobalFree(hMem)
			hMem=0
			'
		case AIM_ADDINSLOADED
			' Beautify toolbar
			Toolbar
			' Beautify menu arrows
			ImageList_Destroy(lpHANDLES->hmnuiml)
			lpHANDLES->hmnuiml=ImageList_Create(16,16,ILC_COLOR24 or ILC_MASK,4,0)
			hBmp=LoadBitmap(hInstance,Cast(zstring ptr,IDB_MNUARROW))
			ImageList_AddMasked(lpHANDLES->hmnuiml,hBmp,&HC0C0C0)
			DeleteObject(hBmp)
			' Get menu font
			ncm.cbSize=sizeof(NONCLIENTMETRICS)
			SystemParametersInfo(SPI_GETNONCLIENTMETRICS,sizeof(NONCLIENTMETRICS),@ncm,0)
			hMnuFont=CreateFontIndirect(@ncm.lfMenuFont)
			MnuFontHt=Abs(ncm.lfMenuFont.lfHeight)+6
			if MnuFontHt<18 then
				MnuFontHt=18
			endif
			'Create back brush for menu items
			hBmp=MakeBitMap(19,&HFFCEBE,&HFFFFFF)
			hMenuBrush=CreatePatternBrush(hBmp)
			DeleteObject(hBmp)
			' Let the menus look cool
			CoolMenu(lpHANDLES->hmenu,&HFFCEBE,&HFFFFFF)
			CoolMenu(lpHANDLES->hcontextmenu,&HFFCEBE,&HFFFFFF)
			' Subclass FbEdit main window
			lpOldWndProc=Cast(any ptr,SetWindowLong(lpHANDLES->hwnd,GWL_WNDPROC,Cast(integer,@WndProc)))
			' Allocate memory for menu items
			hMem=GlobalAlloc(GMEM_FIXED or GMEM_ZEROINIT,1024*64)
			' Make menu items ownerdrawn
			hMenu=lpHANDLES->hmenu
			GetMenuItems(hMenu,0)
			hMenu=lpHANDLES->hcontextmenu
			GetMenuItems(hMenu,0)
			'
		case AIM_MENUREFRESH
			' Make menu items ownerdrawn (only new or updated menu items)
			hMenu=lpHANDLES->hmenu
			GetMenuItems(hMenu,0)
			hMenu=lpHANDLES->hcontextmenu
			GetMenuItems(hMenu,0)
			'
	end select
	return FALSE

end function
