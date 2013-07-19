
; Note!
; This program assumes that longitude east and lattitude north are positive integers
; while longitude west and lattitude south are negative integers.
; 
; Description on longitude & lattitude:
; http://www.worldatlas.com/aatlas/imageg.htm
; 
; Communication with GPS (NMEA 0183):
; http://www.tronico.fi/OH6NT/docs/NMEA0183.pdf
; 

.586
.model flat,stdcall
option casemap:none

include BoatNav.inc
include Distance.asm
include Misc.asm
include GpsComm.asm
include Places.asm
include Options.asm
include TripLog.asm
include DrawMap.asm
include Sonar.asm

.code

LoadWinPos proc
	LOCAL	buffer[256]:BYTE

	invoke GetPrivateProfileString,addr szIniWin,addr szIniWin,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	invoke GetItemInt,addr buffer,10
	mov		winrect.left,eax
	invoke GetItemInt,addr buffer,10
	mov		winrect.top,eax
	invoke GetItemInt,addr buffer,800
	mov		winrect.right,eax
	invoke GetItemInt,addr buffer,600
	mov		winrect.bottom,eax
	invoke GetItemInt,addr buffer,0
	mov		fMaximize,eax
	invoke GetItemInt,addr buffer,0
	mov		sonardata.fShowSat,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.fShowNMEA,eax
	ret

LoadWinPos endp

SaveWinPos proc
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	invoke PutItemInt,addr buffer,winrect.left
	invoke PutItemInt,addr buffer,winrect.top
	invoke PutItemInt,addr buffer,winrect.right
	invoke PutItemInt,addr buffer,winrect.bottom
	invoke PutItemInt,addr buffer,fMaximize
	invoke PutItemInt,addr buffer,sonardata.fShowSat
	invoke PutItemInt,addr buffer,mapdata.fShowNMEA
	invoke WritePrivateProfileString,addr szIniWin,addr szIniWin,addr buffer[1],addr szIniFileName
	ret

SaveWinPos endp

InitMaps proc uses ebx
	LOCAL	buffer[MAX_PATH]:BYTE

	;Get zoom index
	invoke GetPrivateProfileInt,addr szIniMap,addr szIniZoom,1,addr szIniFileName
	mov		mapdata.zoominx,eax
	;Get zoom level
	mov		edx,sizeof ZOOM
	mul		edx
	mov		edx,mapdata.zoom.zoomval[eax]
	mov		mapdata.zoomval,edx
	mov		edx,mapdata.zoom.mapinx[eax]
	mov		mapdata.mapinx,edx
	mov		edx,mapdata.zoom.nx[eax]
	mov		mapdata.nx,edx
	mov		edx,mapdata.zoom.ny[eax]
	mov		mapdata.ny,edx
	invoke strcpy,addr mapdata.options.text[sizeof OPTIONS*3],addr mapdata.zoom.text[eax]
	;Get map pixel positions, left top and right bottom
	invoke GetPrivateProfileString,addr szIniMap,addr szIniPos,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	invoke GetItemInt,addr buffer,0
	mov		mapdata.topx,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.topy,eax
	invoke GetItemInt,addr buffer,256
	mov		mapdata.cursorx,eax
	invoke GetItemInt,addr buffer,256
	mov		mapdata.cursory,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.iLon,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.iLat,eax
	ret

InitMaps endp

InitZoom proc uses ebx esi edi

	mov		esi,offset mapdata.zoom
	xor		ebx,ebx
	.while ebx<MAXZOOM
		invoke wsprintf,addr szbuff,addr szFmtDec,ebx
		invoke GetPrivateProfileString,addr szIniZoom,addr szbuff,addr szNULL,addr szbuff,sizeof szbuff,addr szIniFileName
		.break .if !eax
		invoke GetItemInt,addr szbuff,0
		mov		[esi].ZOOM.zoomval,eax
		invoke GetItemInt,addr szbuff,0
		mov		[esi].ZOOM.mapinx,eax
		invoke GetItemInt,addr szbuff,0
		mov		[esi].ZOOM.scalem,eax
		invoke strcpyn,addr [esi].ZOOM.text,addr szbuff,sizeof ZOOM.text
		invoke CountMapTiles,[esi].ZOOM.mapinx,addr [esi].ZOOM.nx,addr [esi].ZOOM.ny
		invoke GetMapSize,[esi].ZOOM.nx,[esi].ZOOM.ny,addr [esi].ZOOM.xPixels,addr [esi].ZOOM.yPixels,addr [esi].ZOOM.xMeters,addr [esi].ZOOM.yMeters
		.if !ebx
			mov		eax,[esi].ZOOM.xPixels
			mov		mapdata.xPixels,eax
			mov		eax,[esi].ZOOM.yPixels
			mov		mapdata.yPixels,eax
			mov		eax,[esi].ZOOM.xMeters
			mov		mapdata.xMeters,eax
			mov		eax,[esi].ZOOM.yMeters
			mov		mapdata.yMeters,eax
		.endif
		;Convert xPixels to zoomval
		mov		eax,[esi].ZOOM.xPixels
		imul	dd256
		idiv	[esi].ZOOM.zoomval
		mov		[esi].ZOOM.xPixels,eax
		;Convert yPixels to zoomval
		mov		eax,[esi].ZOOM.yPixels
		imul	dd256
		idiv	[esi].ZOOM.zoomval
		mov		[esi].ZOOM.yPixels,eax
		lea		esi,[esi+sizeof ZOOM]
		inc		ebx
	.endw
	mov		mapdata.zoommax,ebx
	ret

InitZoom endp

InitFonts proc uses ebx
	LOCAL	buffer[256]:BYTE
	LOCAL	lf:LOGFONT

	invoke RtlZeroMemory,addr lf,sizeof LOGFONT
	xor		ebx,ebx
	.while ebx<MAXFONT
		invoke BinToDec,ebx,addr buffer
		invoke GetPrivateProfileString,addr szIniFont,addr buffer,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
		.break .if !eax
		invoke GetItemInt,addr buffer,8
		mov		lf.lfHeight,eax
		invoke GetItemInt,addr buffer,0
		.if eax
			mov		eax,700
		.endif
		mov		lf.lfWeight,eax
		invoke GetItemInt,addr buffer,0
		mov		lf.lfItalic,al
		invoke GetItemInt,addr buffer,0
		mov		lf.lfCharSet,al
		invoke strcpyn,addr lf.lfFaceName,addr buffer,LF_FACESIZE
		invoke GetDC,hWnd
		push	eax
		invoke GetDeviceCaps,eax,LOGPIXELSY
		imul	lf.lfHeight
		idiv	dd72
		neg		eax
		mov		lf.lfHeight,eax
		invoke CreateFontIndirect,addr lf
		mov		mapdata.font[ebx*4],eax
		pop		eax
		invoke ReleaseDC,hWnd,eax
		inc		ebx
	.endw
	ret

InitFonts endp

InitScroll proc

	mov		eax,mapdata.nx
	inc		eax
	shl		eax,9
	sub		eax,mapdata.mapwt
	shr		eax,4
	invoke SetScrollRange,hMap,SB_HORZ,0,eax,TRUE
	mov		eax,mapdata.topx
	shr		eax,4
	invoke SetScrollPos,hMap,SB_HORZ,eax,TRUE
	mov		eax,mapdata.ny
	inc		eax
	shl		eax,9
	sub		eax,mapdata.mapht
	shr		eax,4
	invoke SetScrollRange,hMap,SB_VERT,0,eax,TRUE
	mov		eax,mapdata.topy
	shr		eax,4
	invoke SetScrollPos,hMap,SB_VERT,eax,TRUE
	ret

InitScroll endp

MapProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	pt:POINT
	LOCAL	x:DWORD
	LOCAL	y:DWORD
	LOCAL	iLon:DWORD
	LOCAL	iLat:DWORD
	LOCAL	fDist:REAL10
	LOCAL	fBear:REAL10

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hMap,eax
		invoke ImageList_Create,16,16,ILC_COLOR24 or ILC_MASK,8+16,0
		mov		hIml,eax
		invoke LoadBitmap,hInstance,100
		mov		ebx,eax
		invoke ImageList_AddMasked,hIml,ebx,0FF00FFh
		invoke DeleteObject,ebx
		invoke GetDC,hWin
		mov		mapdata.hDC,eax
		invoke CreateCompatibleDC,mapdata.hDC
		mov		mapdata.mDC,eax
		invoke GetSystemMetrics,SM_CXSCREEN
		mov		mapdata.cxs,eax
		invoke GetSystemMetrics,SM_CYSCREEN
		mov		mapdata.cys,eax
		invoke CreateCompatibleBitmap,mapdata.hDC,mapdata.cxs,mapdata.cys
		invoke SelectObject,mapdata.mDC,eax
		mov		mapdata.hmBmpOld,eax
		invoke CreateCompatibleDC,mapdata.hDC
		mov		mapdata.mDC2,eax
		invoke CreateCompatibleBitmap,mapdata.hDC,1,1
		invoke SelectObject,mapdata.mDC2,eax
		mov		mapdata.hmBmpOld2,eax
		invoke CreateCompatibleDC,mapdata.hDC
		mov		mapdata.tDC,eax
		invoke SetStretchBltMode,mapdata.mDC,COLORONCOLOR
		invoke SetBkMode,mapdata.mDC2,TRANSPARENT
	.elseif eax==WM_CONTEXTMENU
		mov		eax,lParam
		.if eax!=-1
			movsx	edx,ax
			mov		mousept.x,edx
			mov		pt.x,edx
			shr		eax,16
			movsx	edx,ax
			mov		mousept.y,edx
			mov		pt.y,edx
			.if mapdata.btrip
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.btrip==2
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_TRIP_DONE,eax
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.btrip==3
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_TRIP_EDIT,eax
				.if mapdata.btrip==3 && mapdata.onpoint!=-1
					mov		eax,MF_BYCOMMAND or MF_ENABLED
					.if mapdata.triphead==1
						mov		eax,MF_BYCOMMAND or MF_GRAYED
					.endif
					invoke EnableMenuItem,hContext,IDM_TRIP_DELETE,eax
					invoke GetSubMenu,hContext,2
				.else
					invoke GetSubMenu,hContext,1
				.endif
			.elseif mapdata.bdist
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.bdist==2
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_DIST_DONE,eax
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.bdist==3
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_DIST_EDIT,eax
				.if mapdata.bdist==3 && mapdata.onpoint!=-1
					mov		eax,MF_BYCOMMAND or MF_ENABLED
					.if mapdata.disthead==1
						mov		eax,MF_BYCOMMAND or MF_GRAYED
					.endif
					invoke EnableMenuItem,hContext,IDM_DIST_DELETE,eax
					invoke GetSubMenu,hContext,4
				.else
					invoke GetSubMenu,hContext,3
				.endif
			.else
				invoke ScreenToClient,hWin,addr pt
				invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr iLon,addr iLat
				invoke FindPlace,iLon,iLat
				mov		nPlace,eax
				mov		edx,MF_BYCOMMAND or MF_GRAYED
				.if eax!=-1
					mov		edx,MF_BYCOMMAND or MF_ENABLED
				.endif
				invoke EnableMenuItem,hContext,IDM_EDITPLACE,edx
				invoke GetSubMenu,hContext,0
			.endif
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,mousept.x,mousept.y,0,hWnd,0
			invoke ScreenToClient,hWin,addr mousept
		.endif
	.elseif eax==WM_PAINT
		inc		mapdata.paintnow
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		mov		eax,rect.right
		mov		mapdata.mapwt,eax
		mov		eax,rect.bottom
		mov		mapdata.mapht,eax
		invoke CreateCompatibleBitmap,mapdata.hDC,mapdata.mapwt,mapdata.mapht
		invoke SelectObject,mapdata.mDC2,eax
		invoke DeleteObject,eax
		invoke InitScroll
	.elseif eax==WM_MOUSEMOVE
		mov		edx,lParam
		movsx	eax,dx
		shr		edx,16
		movsx	edx,dx
		mov		pt.x,eax
		mov		pt.y,edx
		push	eax
		push	edx
		invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
		invoke MapPosToGpsPos,x,y,addr iLon,addr iLat
		invoke SetDlgItemInt,hControls,IDC_STCLAT,iLat,TRUE
		mov		eax,iLon
		invoke SetDlgItemInt,hControls,IDC_STCLON,eax,TRUE
		pop		edx
		pop		eax
		.if mapdata.bdist==1 && mapdata.disthead
			.if eax>mapdata.mapwt || edx>mapdata.mapht
				invoke ReleaseCapture
				.if mapdata.disthead
					inc		mapdata.paintnow
				.endif
			.else
				mov		pt.x,eax
				mov		pt.y,edx
				invoke BitBlt,mapdata.hDC,0,0,mapdata.mapwt,mapdata.mapht,mapdata.mDC2,0,0,SRCCOPY
				mov		edi,mapdata.disthead
				dec		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke GpsPosToMapPos,mapdata.dist.iLon[ebx],mapdata.dist.iLat[ebx],addr x,addr y
				invoke MapPosToScrnPos,x,y,addr x,addr y
				mov 	eax,x
				sub		eax,mapdata.topx
				imul	dd256
				idiv	mapdata.zoomval
				mov		x,eax
				mov 	eax,y
				sub		eax,mapdata.topy
				imul	dd256
				idiv	mapdata.zoomval
				mov		y,eax
				invoke MoveToEx,mapdata.hDC,x,y,NULL
				invoke LineTo,mapdata.hDC,pt.x,pt.y
				inc		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx]
				invoke GetCapture
				.if eax!=hWin
					invoke SetCapture,hWin
				.endif
				invoke GetDistance,addr mapdata.dist,mapdata.disthead
			.endif
		.elseif mapdata.bdist==3 && mapdata.disthead
			.if (wParam & MK_LBUTTON) && mapdata.onpoint!=-1
				mov		ebx,mapdata.onpoint
				shl		ebx,4
				mov		ecx,eax
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx]
				.if mapdata.onpoint
					invoke BearingDistanceInt,mapdata.dist.iLon[ebx-sizeof LOG],addr mapdata.dist.iLat[ebx-sizeof LOG],mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx],addr fDist,addr fBear
					fld		fBear
					fistp	mapdata.dist.iBear[ebx-sizeof LOG]
				.endif
				mov		eax,mapdata.disthead
				dec		eax
				invoke GetDistance,addr mapdata.dist,eax
			.else
				invoke FindPoint,eax,edx,addr mapdata.dist,mapdata.disthead
				mov		mapdata.onpoint,eax
			.endif
			inc		mapdata.paintnow
		.elseif mapdata.btrip==1 && mapdata.triphead
			.if eax>mapdata.mapwt || edx>mapdata.mapht
				invoke ReleaseCapture
				.if mapdata.triphead
					inc		mapdata.paintnow
				.endif
			.else
				mov		pt.x,eax
				mov		pt.y,edx
				invoke BitBlt,mapdata.hDC,0,0,mapdata.mapwt,mapdata.mapht,mapdata.mDC2,0,0,SRCCOPY
				mov		edi,mapdata.triphead
				dec		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke GpsPosToMapPos,mapdata.trip.iLon[ebx],mapdata.trip.iLat[ebx],addr x,addr y
				invoke MapPosToScrnPos,x,y,addr x,addr y
				mov 	eax,x
				sub		eax,mapdata.topx
				imul	dd256
				idiv	mapdata.zoomval
				mov		x,eax
				mov 	eax,y
				sub		eax,mapdata.topy
				imul	dd256
				idiv	mapdata.zoomval
				mov		y,eax
				invoke MoveToEx,mapdata.hDC,x,y,NULL
				invoke LineTo,mapdata.hDC,pt.x,pt.y
				inc		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx]
				invoke GetCapture
				.if eax!=hWin
					invoke SetCapture,hWin
				.endif
				invoke GetDistance,addr mapdata.trip,mapdata.triphead
			.endif
		.elseif mapdata.btrip==3 && mapdata.triphead
			.if (wParam & MK_LBUTTON) && mapdata.onpoint!=-1
				mov		ebx,mapdata.onpoint
				shl		ebx,4
				mov		ecx,eax
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx]
				.if mapdata.onpoint
					invoke BearingDistanceInt,mapdata.trip.iLon[ebx-sizeof LOG],addr mapdata.trip.iLat[ebx-sizeof LOG],mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx],addr fDist,addr fBear
					fld		fBear
					fistp	mapdata.trip.iBear[ebx-sizeof LOG]
				.endif
				mov		eax,mapdata.triphead
				dec		eax
				invoke GetDistance,addr mapdata.trip,eax
			.else
				invoke FindPoint,eax,edx,addr mapdata.trip,mapdata.triphead
				mov		mapdata.onpoint,eax
			.endif
			inc		mapdata.paintnow
		.elseif wParam==MK_LBUTTON
			;Drag the map
			mov		eax,lParam
			movsx	eax,ax
			sub		eax,mousept.x
			neg		eax
			imul	mapdata.zoomval
			idiv	dd256
			add		eax,mousemappt.x
			mov		mapdata.topx,eax
			.if SIGN?
				mov		mapdata.topx,0
			.endif
			mov		eax,lParam
			shr		eax,16
			movsx	eax,ax
			sub		eax,mousept.y
			neg		eax
			imul	mapdata.zoomval
			idiv	dd256
			add		eax,mousemappt.y
			mov		mapdata.topy,eax
			.if SIGN?
				mov		mapdata.topy,0
			.endif
			mov		eax,mapdata.topx
			shr		eax,4
			invoke SetScrollPos,hMap,SB_HORZ,eax,TRUE
			mov		eax,mapdata.topy
			shr		eax,4
			invoke SetScrollPos,hMap,SB_VERT,eax,TRUE
			inc		mapdata.paintnow
		.endif
	.elseif eax==WM_LBUTTONDOWN
		mov		eax,mapdata.topx
		mov		mousemappt.x,eax
		mov		eax,mapdata.topy
		mov		mousemappt.y,eax
		mov		edx,lParam
		movsx	eax,dx
		mov		mousept.x,eax
		shr		edx,16
		movsx	edx,dx
		mov		mousept.y,edx
		.if mapdata.bdist==1
			;Add new point
			mov		edi,mapdata.disthead
			.if edi<MAXDIST-1
				mov		ecx,eax
				mov		ebx,edi
				shl		ebx,4
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx]
				inc		mapdata.disthead
				inc		mapdata.paintnow
			.endif
		.elseif mapdata.btrip==1
			;Add new point
			mov		edi,mapdata.triphead
			.if edi<MAXTRIP-1
				mov		ecx,eax
				mov		ebx,edi
				shl		ebx,4
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx]
				inc		mapdata.triphead
				inc		mapdata.paintnow
			.endif
		.elseif (!mapdata.bdist || mapdata.bdist==2) && (!mapdata.btrip || mapdata.btrip==2)
			invoke SetCapture,hWin
			invoke LoadCursor,0,IDC_SIZEALL
			invoke SetCursor,eax
		.endif
	.elseif eax==WM_LBUTTONUP
		.if (!mapdata.bdist || mapdata.bdist==2) && (!mapdata.btrip || mapdata.btrip==2)
			invoke GetCapture
			.if eax==hWin
				invoke ReleaseCapture
				invoke LoadCursor,0,IDC_ARROW
				invoke SetCursor,eax
			.endif
		.endif
		invoke SetFocus,hWnd
	.elseif eax==WM_SETCURSOR
		.if mapdata.bdist==1 || mapdata.btrip==1 || (mapdata.bdist==3 && mapdata.onpoint!=-1) || (mapdata.btrip==3 && mapdata.onpoint!=-1)
			invoke LoadCursor,0,IDC_CROSS
		.else
			invoke LoadCursor,0,IDC_ARROW
		.endif
		invoke SetCursor,eax
	.elseif eax==WM_MOUSEWHEEL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		movsx	eax,ax
		test	edx,MK_CONTROL
		.if ZERO?
			.if sdword ptr eax<0
				invoke GetScrollPos,hWin,SB_VERT
				add		eax,4
				call	VScroll
			.else
				invoke GetScrollPos,hWin,SB_VERT
				sub		eax,4
				call	VScroll
			.endif
		.else
			.if sdword ptr eax<0
				invoke GetScrollPos,hWin,SB_HORZ
				add		eax,4
				call	HScroll
			.else
				invoke GetScrollPos,hWin,SB_HORZ
				sub		eax,4
				call	HScroll
			.endif
		.endif
	.elseif eax==WM_KEYDOWN
		mov		eax,wParam
		.if eax==VK_RIGHT
			invoke GetScrollPos,hWin,SB_HORZ
			add		eax,4
			call	HScroll
		.elseif eax==VK_LEFT
			invoke GetScrollPos,hWin,SB_HORZ
			sub		eax,4
			call	HScroll
		.elseif eax==VK_DOWN
			invoke GetScrollPos,hWin,SB_VERT
			add		eax,4
			call	VScroll
		.elseif eax==VK_UP
			invoke GetScrollPos,hWin,SB_VERT
			sub		eax,4
			call	VScroll
		.endif
	.elseif eax==WM_VSCROLL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		.if edx==SB_THUMBPOSITION
			call	VScroll
		.elseif edx==SB_LINEDOWN
			invoke GetScrollPos,hWin,SB_VERT
			add		eax,4
			call	VScroll
		.elseif edx==SB_LINEUP
			invoke GetScrollPos,hWin,SB_VERT
			sub		eax,4
			.if CARRY?
				xor		eax,eax
			.endif
			call	VScroll
		.elseif edx==SB_PAGEDOWN
			invoke GetScrollPos,hWin,SB_VERT
			mov		edx,mapdata.mapht
			shr		edx,4
			add		eax,edx
			call	VScroll
		.elseif edx==SB_PAGEUP
			invoke GetScrollPos,hWin,SB_VERT
			mov		edx,mapdata.mapht
			shr		edx,4
			sub		eax,edx
			call	VScroll
		.endif
	.elseif eax==WM_HSCROLL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		.if edx==SB_THUMBPOSITION
			call	HScroll
		.elseif edx==SB_LINEDOWN
			invoke GetScrollPos,hWin,SB_HORZ
			add		eax,4
			call	HScroll
		.elseif edx==SB_LINEUP
			invoke GetScrollPos,hWin,SB_HORZ
			sub		eax,4
			call	HScroll
		.elseif edx==SB_PAGEDOWN
			invoke GetScrollPos,hWin,SB_HORZ
			mov		edx,mapdata.mapwt
			shr		edx,4
			add		eax,edx
			call	HScroll
		.elseif edx==SB_PAGEUP
			invoke GetScrollPos,hWin,SB_HORZ
			mov		edx,mapdata.mapwt
			shr		edx,4
			sub		eax,edx
			call	HScroll
		.endif
	.elseif eax==WM_DESTROY
		invoke SelectObject,mapdata.mDC,mapdata.hmBmpOld
		invoke DeleteObject,eax
		invoke DeleteDC,mapdata.mDC
		invoke SelectObject,mapdata.mDC2,mapdata.hmBmpOld2
		invoke DeleteObject,eax
		invoke DeleteDC,mapdata.mDC2
		invoke DeleteDC,mapdata.tDC
		invoke ReleaseDC,hWin,mapdata.hDC
		xor		ebx,ebx
		mov		esi,offset bmpcache
		.while ebx<MAXBMP
			.if [esi].BMP.hBmp
				invoke DeleteObject,[esi].BMP.hBmp
			.endif
			lea		esi,[esi+sizeof BMP]
			inc		ebx
		.endw
		xor		ebx,ebx
		.while ebx<MAXFONT
			.if mapdata.font[ebx*4]
				invoke DeleteObject,mapdata.font[ebx*4]
			.endif
			inc		ebx
		.endw
		invoke ImageList_Destroy,hIml
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

VScroll:
	.if sdword ptr eax<0
		xor		eax,eax
	.endif
	push	eax
	invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
	pop		eax
	shl		eax,4
	mov		edx,mapdata.ny
	inc		edx
	shl		edx,9
	sub		edx,mapdata.mapht
	.if eax>edx
		mov		eax,edx
	.endif
	mov		mapdata.topy,eax
	inc		mapdata.paintnow
	retn

HScroll:
	.if sdword ptr eax<0
		xor		eax,eax
	.endif
	push	eax
	invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
	pop		eax
	shl		eax,4
	mov		edx,mapdata.nx
	inc		edx
	shl		edx,9
	sub		edx,mapdata.mapwt
	.if eax>edx
		mov		eax,edx
	.endif
	mov		mapdata.topx,eax
	inc		mapdata.paintnow
	retn

MapProc endp

ControlsChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		ebx,hWin
		mov		hControls,ebx
		invoke CheckDlgButton,hWin,IDC_CHKLOCKTOGPS,BST_CHECKED
		mov		mapdata.gpslock,TRUE
		invoke CheckDlgButton,hWin,IDC_CHKSHOWTRAIL,BST_CHECKED
		mov		mapdata.gpstrail,TRUE
		.if sonardata.fShowSat
			invoke CheckDlgButton,hWin,IDC_CHKSHOWSAT,BST_CHECKED
		.endif
		.if mapdata.fShowNMEA
			invoke CheckDlgButton,hWin,IDC_CHKSHOWNMEA,BST_CHECKED
		.endif
		invoke InitPlaces
		mov		eax,BST_UNCHECKED
		.if sonardata.AutoRange
			mov		eax,BST_CHECKED
		.endif
		invoke CheckDlgButton,hWin,IDC_CHKAUTORANGE,eax
		invoke ImageList_GetIcon,hIml,12,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNDEPTHDOWN,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke ImageList_GetIcon,hIml,4,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNDEPTHUP,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke GetDlgItem,hWin,IDC_BTNDEPTHDOWN
		invoke SetWindowLong,eax,GWL_WNDPROC,offset ButtonProc
		mov		lpOldButtonProc,eax
		invoke GetDlgItem,hWin,IDC_BTNDEPTHUP
		invoke SetWindowLong,eax,GWL_WNDPROC,offset ButtonProc
		mov		eax,FALSE
		ret
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED || edx==1
			.if eax==IDC_BTNZOOMIN
				mov		eax,mapdata.zoominx
				.if eax
					dec		eax
					invoke ZoomMap,eax
					invoke DoGoto,mapdata.iLon,mapdata.iLat,mapdata.gpslock,TRUE
				.endif
			.elseif eax==IDC_BTNZOOMOUT
				mov		eax,mapdata.zoominx
				inc		eax
				.if eax<32
					mov		edx,sizeof ZOOM
					mul		edx
					mov		ebx,eax
					.if mapdata.zoom.zoomval[ebx]
						mov		eax,mapdata.zoominx
						inc		eax
						invoke ZoomMap,eax
						invoke DoGoto,mapdata.iLon,mapdata.iLat,mapdata.gpslock,TRUE
					.endif
				.endif
			.elseif eax==IDC_BTNMAP
				xor		ebx,ebx
				mov		esi,offset bmpcache
				.while ebx<MAXBMP
					.if [esi].BMP.hBmp
						invoke DeleteObject,[esi].BMP.hBmp
						mov		[esi].BMP.hBmp,0
						mov		[esi].BMP.inuse,0
					.endif
					lea		esi,[esi+sizeof BMP]
					inc		ebx
				.endw
				.if fSeaMap
					invoke strcpy,addr szFileName,addr szLandFileName
					mov		fSeaMap,FALSE
				.else
					invoke strcpy,addr szFileName,addr szSeaFileName
					mov		fSeaMap,TRUE
				.endif
				inc		mapdata.paintnow
			.elseif eax==IDC_CHKPAUSEGPS
				invoke IsDlgButtonChecked,hWin,IDC_CHKPAUSEGPS
				mov		mapdata.gpslogpause,eax
				mov		edx,MF_BYCOMMAND or MF_UNCHECKED
				.if eax
					mov		edx,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_GPS_PAUSE,edx
			.elseif eax==IDC_CHKLOCKTOGPS
				invoke IsDlgButtonChecked,hWin,IDC_CHKLOCKTOGPS
				mov		mapdata.gpslock,eax
				inc		mapdata.paintnow
			.elseif eax==IDC_CHKSHOWTRAIL
				invoke IsDlgButtonChecked,hWin,IDC_CHKSHOWTRAIL
				mov		mapdata.gpstrail,eax
				inc		mapdata.paintnow
			.elseif eax==IDC_CHKSHOWGRID
				invoke IsDlgButtonChecked,hWin,IDC_CHKSHOWGRID
				mov		mapdata.mapgrid,eax
				inc		mapdata.paintnow
			.elseif eax==IDC_CHKSHOWSAT
				xor		sonardata.fShowSat,TRUE
				invoke SendMessage,hWnd,WM_SIZE,0,0
			.elseif eax==IDC_CHKSHOWNMEA
				xor		mapdata.fShowNMEA,TRUE
				invoke SendMessage,hWnd,WM_SIZE,0,0
			.elseif eax==IDC_CBOPLACES
				invoke SendDlgItemMessage,hWin,IDC_CBOPLACES,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOPLACES,CB_GETITEMDATA,eax,0
				invoke DoGoto,[eax].PLACE.iLon,[eax].PLACE.iLat,TRUE,FALSE
				inc		mapdata.paintnow
			.elseif eax==IDC_CHKAUTORANGE
				xor		sonardata.AutoRange,1
				mov		eax,BST_UNCHECKED
				.if sonardata.AutoRange
					mov		eax,BST_CHECKED
				.endif
				invoke CheckDlgButton,hWin,IDC_CHKAUTORANGE,eax
			.elseif eax==IDC_CHKZOOM
				xor		sonardata.zoom,1
				inc		sonardata.PaintNow
			.elseif eax==IDC_CHKDEPTHCURSOR
				xor		sonardata.cursor,1
				.if sonardata.cursor
					invoke EnableScrollBar,hSonar,SB_VERT,ESB_ENABLE_BOTH
				.else
					invoke EnableScrollBar,hSonar,SB_VERT,ESB_DISABLE_BOTH
				.endif
				inc		sonardata.PaintNow
			.elseif eax==IDC_BTNDEPTHDOWN
				.if sonardata.RangeInx
					mov		sonardata.dptinx,0
					dec		sonardata.RangeInx
					movzx	eax,sonardata.RangeInx
					invoke SetRange,eax
					inc		sonardata.fGainUpload
				.endif
			.elseif eax==IDC_BTNDEPTHUP
				mov		eax,sonardata.MaxRange
				dec		eax
				.if al>sonardata.RangeInx
					mov		sonardata.dptinx,0
					inc		sonardata.RangeInx
					movzx	eax,sonardata.RangeInx
					invoke SetRange,eax
					inc		sonardata.fGainUpload
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret


ControlsChildProc endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	dwread:DWORD
	LOCAL	msg:MSG

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		fldz
		fstp	mapdata.fSumDist
		invoke GetMenu,hWin
		mov		hMenu,eax
		invoke LoadMenu,hInstance,IDM_CONTEXT
		mov		hContext,eax
		invoke LoadAccelerators,hInstance,IDR_ACCEL
		mov		hAccel,eax
		invoke MoveWindow,hWin,winrect.left,winrect.top,winrect.right,winrect.bottom,FALSE
		invoke CreateDialogParam,hInstance,IDD_DLGCONTROLS,hWin,addr ControlsChildProc,0
	.elseif eax==WM_CONTEXTMENU
		invoke GetDlgItem,hWin,IDC_LSTNMEA
		.if eax==wParam
			mov		eax,lParam
			.if eax!=-1
				movsx	edx,ax
				mov		mousept.x,edx
				shr		eax,16
				movsx	edx,ax
				mov		mousept.y,edx
				invoke GetSubMenu,hContext,6
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,mousept.x,mousept.y,0,hWin,0
			.endif
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
;File
		.if edx==BN_CLICKED || edx==1
			.if eax==IDM_FILE_OPENTRIP
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke OpenTrip,eax
					invoke DoGoto,mapdata.trip.iLon,mapdata.trip.iLat,TRUE,FALSE
					inc		mapdata.paintnow
					mov		mapdata.btrip,2
					mov		mapdata.onpoint,-1
				.endif
			.elseif eax==IDM_FILE_SAVETRIP
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke SaveTrip,eax
				.endif
			.elseif eax==IDM_FILE_OPENDIST
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke OpenDistance,eax
					invoke DoGoto,mapdata.dist.iLon,mapdata.dist.iLat,TRUE,FALSE
					inc		mapdata.paintnow
					mov		mapdata.bdist,2
					mov		mapdata.onpoint,-1
				.endif
			.elseif eax==IDM_FILE_SAVEDIST
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke SaveDistance,eax
				.endif
			.elseif eax==IDM_FILE_OPENTRAIL
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke OpenTrail,eax
					invoke DoGoto,mapdata.trail.iLon,mapdata.trail.iLat,TRUE,FALSE
					inc		mapdata.paintnow
				.endif
			.elseif eax==IDM_FILE_SAVETRAIL
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke SaveTrail,eax
				.endif
			.elseif eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
;Log
			.elseif eax==IDM_LOG_START
				.if !hFileLogWrite
					invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
					.if eax
						invoke strcpy,addr buffer,eax
						invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
						.if eax!=INVALID_HANDLE_VALUE
							mov		combuff,0
							mov		npos,0
							mov		hFileLogWrite,eax
						.endif
					.endif
				.endif
			.elseif eax==IDM_LOG_END
				.if hFileLogWrite
					invoke CloseHandle,hFileLogWrite
					mov		hFileLogWrite,0
				.elseif hFileLogRead
					invoke CloseHandle,hFileLogRead
					mov		hFileLogRead,0
					mov		hFileLogWrite,0
					mov		mapdata.ntrail,0
					mov		mapdata.trailhead,0
					mov		mapdata.trailtail,0
					fldz
					fstp	mapdata.fSumDist
					invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
				.endif
			.elseif eax==IDM_LOG_REPLAY
				.if !hFileLogRead
					invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
					.if eax
						invoke strcpy,addr buffer,eax
						invoke CreateFile,addr buffer,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
						.if eax
							mov		combuff,0
							mov		npos,0
							mov		mapdata.ntrail,0
							mov		mapdata.trailhead,0
							mov		mapdata.trailtail,0
							fldz
							fstp	mapdata.fSumDist
							mov		hFileLogRead,eax
						.endif
					.endif
				.endif
			.elseif eax==IDM_LOG_CLEARTRAIL
				mov		eax,mapdata.trailtail
				.if eax!=mapdata.trailhead
					invoke MessageBox,hWin,addr szAskSaveTrail,addr szAppName,MB_YESNOCANCEL or MB_ICONQUESTION
					.if eax!=IDCANCEL
						.if eax==IDYES
							invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,IDM_FILE_SAVETRAIL
							.if eax
								invoke SaveTrail,eax
							.endif
						.endif
						mov		mapdata.ntrail,0
						mov		mapdata.trailhead,0
						mov		mapdata.trailtail,0
						inc		mapdata.paintnow
						fldz
						fstp	mapdata.fSumDist
						invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
					.endif
				.endif
			.elseif eax==IDM_LOG_STARTSONAR
				.if !sonardata.hLog
					invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
					.if eax
						invoke strcpy,addr buffer,eax
						invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
						.if eax!=INVALID_HANDLE_VALUE
							mov		sonardata.hLog,eax
						.endif
					.endif
				.endif
			.elseif eax==IDM_LOG_ENDSONAR
				.if sonardata.hLog
					invoke CloseHandle,sonardata.hLog
					mov		sonardata.hLog,0
				.elseif sonardata.hReplay
					invoke CloseHandle,sonardata.hReplay
					mov		sonardata.hReplay,0
					mov		npos,0
					mov		mapdata.ntrail,0
					mov		mapdata.trailhead,0
					mov		mapdata.trailtail,0
					fldz
					fstp	mapdata.fSumDist
					invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
					invoke SetScrollPos,hSonar,SB_HORZ,0,TRUE
					mov		sonardata.dptinx,0
					invoke EnableScrollBar,hSonar,SB_HORZ,ESB_DISABLE_BOTH
				.endif
			.elseif eax==IDM_LOG_REPLAYSONAR
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,eax
				.if eax
					invoke strcpy,addr buffer,eax
					.if sonardata.hReplay
						invoke CloseHandle,sonardata.hReplay
						mov		sonardata.hReplay,0
					.endif
					invoke CreateFile,addr buffer,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
					.if eax!=INVALID_HANDLE_VALUE
						mov		ebx,eax
						invoke ResetDepth
						invoke ReadFile,ebx,addr sonarreplay,1,addr dwread,NULL
						invoke SetFilePointer,ebx,0,NULL,FILE_BEGIN
						invoke EnableScrollBar,hSonar,SB_HORZ,ESB_ENABLE_BOTH
						invoke GetFileSize,ebx,NULL
						shr		eax,9
						invoke SetScrollRange,hSonar,SB_HORZ,0,eax,TRUE
						invoke SonarClear
						.if sonarreplay.Version>=200
							mov		npos,0
							mov		mapdata.ntrail,0
							mov		mapdata.trailhead,0
							mov		mapdata.trailtail,0
							fldz
							fstp	mapdata.fSumDist
							invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
						.endif
						mov		sonardata.dptinx,0
						mov		sonardata.hReplay,ebx
					.endif
				.endif
;Option
			.elseif eax==IDM_OPTION_SPEED
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,0
			.elseif eax==IDM_OPTION_BATTERY
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,1
			.elseif eax==IDM_OPTION_AIRTEMP
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,2
			.elseif eax==IDM_OPTION_SCALE
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,3
			.elseif eax==IDM_OPTION_TIME
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,4
			.elseif eax==IDM_OPTION_RANGE
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,10
			.elseif eax==IDM_OPTIO_DEPTH
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,11
			.elseif eax==IDM_OPTION_WATERTEMP
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,12
			.elseif eax==IDM_OPTION_SONAR
				invoke CreateDialogParam,hInstance,IDD_DLGSONAR,hWin,addr SonarOptionProc,0
			.elseif eax==IDM_OPTION_GAIN
				invoke DialogBoxParam,hInstance,IDD_DLGSONARGAIN,hWin,addr SonarGainOptionProc,0
			.elseif eax==IDM_OPTION_SONARCOLOR
				invoke DialogBoxParam,hInstance,IDD_DLGSONARCOLOR,hWin,addr SonarColorOptionProc,0
			.elseif eax==IDM_OPTION_GPS
				invoke DialogBoxParam,hInstance,IDD_DLGGPSSETUP,hWin,addr GPSOptionProc,0
;Context
			.elseif eax==IDM_EDITPLACE
				invoke DialogBoxParam,hInstance,IDD_DLGADDPLACE,hWin,addr AddPlaceProc,nPlace
				inc		mapdata.paintnow
			.elseif eax==IDM_ADDPLACE
				invoke DialogBoxParam,hInstance,IDD_DLGADDPLACE,hWin,addr AddPlaceProc,-1
			.elseif eax==IDM_TRIPPLANNING
				mov		mapdata.btrip,1
				mov		mapdata.onpoint,-1
			.elseif eax==IDM_DISTANCE
				mov		mapdata.bdist,1
				mov		mapdata.onpoint,-1
			.elseif eax==IDM_FULLSCREEN
				invoke GetParent,hMap
				.if eax==hWin
					invoke ShowWindow,hMap,SW_HIDE
					invoke SetParent,hMap,0
					invoke ShowWindow,hMap,SW_SHOWMAXIMIZED
				.else
					invoke SetParent,hMap,hWin
					invoke ShowWindow,hWin,SW_RESTORE
				.endif
				invoke SetActiveWindow,hMap
			.elseif eax==IDM_TRIP_DONE
				.if mapdata.btrip==1 || mapdata.btrip==3
					mov		mapdata.btrip,2
					.if mapdata.triphead
						mov		eax,mapdata.triphead
						dec		eax
						invoke GetDistance,addr mapdata.trip,eax
					.endif
					inc		mapdata.paintnow
				.else
					mov		mapdata.btrip,1
				.endif
			.elseif eax==IDM_TRIP_SAVE
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,IDM_FILE_SAVETRIP
				.if eax
					invoke SaveTrip,eax
				.endif
			.elseif eax==IDM_TRIP_EDIT
				.if mapdata.triphead
					.if mapdata.btrip==3
						mov		mapdata.btrip,1
					.else
						mov		mapdata.btrip,3
					.endif
					inc		mapdata.paintnow
				.endif
			.elseif eax==IDM_TRIP_CLEAR
				mov		mapdata.btrip,0
				mov		mapdata.triphead,0
				inc		mapdata.paintnow
				invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
			.elseif eax==IDM_TRIP_INSERT
				invoke InsertPoint,mapdata.onpoint,addr mapdata.trip,addr mapdata.triphead
			.elseif eax==IDM_TRIP_DELETE
				invoke DeletePoint,mapdata.onpoint,addr mapdata.trip,addr mapdata.triphead
			.elseif eax==IDM_DIST_DONE
				.if mapdata.bdist==1 || mapdata.bdist==3
					mov		mapdata.bdist,2
					.if mapdata.disthead
						mov		eax,mapdata.disthead
						dec		eax
						invoke GetDistance,addr mapdata.dist,eax
					.endif
					inc		mapdata.paintnow
				.else
					mov		mapdata.bdist,1
				.endif
			.elseif eax==IDM_DIST_SAVE
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,IDM_FILE_SAVEDIST
				.if eax
					invoke SaveDistance,eax
				.endif
			.elseif eax==IDM_DIST_EDIT
				.if mapdata.disthead
					.if mapdata.bdist==3
						mov		mapdata.bdist,1
					.else
						mov		mapdata.bdist,3
					.endif
					inc		mapdata.paintnow
				.endif
			.elseif eax==IDM_DIST_CLEAR
				mov		mapdata.bdist,0
				mov		mapdata.disthead,0
				inc		mapdata.paintnow
				invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
			.elseif eax==IDM_DIST_INSERT
				invoke InsertPoint,mapdata.onpoint,addr mapdata.dist,addr mapdata.disthead
			.elseif eax==IDM_DIST_DELETE
				invoke DeletePoint,mapdata.onpoint,addr mapdata.dist,addr mapdata.disthead
			.elseif eax==IDM_SONARCLEAR
				invoke SonarClear
			.elseif eax==IDM_SONARPAUSE
				invoke IsDlgButtonChecked,hControls,IDC_CHKPAUSE
				.if eax
					mov		eax,BST_UNCHECKED
				.else
					mov		eax,BST_CHECKED
				.endif
				invoke CheckDlgButton,hControls,IDC_CHKPAUSE,eax
			.elseif eax==IDM_GPS_HIDE
				invoke CheckDlgButton,hWin,IDC_CHKSHOWNMEA,BST_UNCHECKED
				mov		mapdata.fShowNMEA,FALSE
				invoke SendMessage,hWin,WM_SIZE,0,0
			.elseif eax==IDM_GPS_PAUSE
				invoke IsDlgButtonChecked,hWin,IDC_CHKPAUSEGPS
				.if eax
					invoke CheckDlgButton,hWin,IDC_CHKPAUSEGPS,BST_UNCHECKED
					mov		mapdata.gpslogpause,FALSE
				.else
					invoke CheckDlgButton,hWin,IDC_CHKPAUSEGPS,BST_CHECKED
					mov		mapdata.gpslogpause,TRUE
				.endif
				mov		edx,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.gpslogpause
					mov		edx,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_GPS_PAUSE,edx
			.elseif eax==IDM_GPS_SAVE
				invoke DialogBoxParam,hInstance,IDD_DLGTRIPLOG,hWin,addr TripLogProc,IDM_GPS_SAVE
				.if eax
					invoke SaveNMEALog,eax
				.endif
			.elseif eax==IDM_GPS_CLEAR
				invoke SendDlgItemMessage,hWin,IDC_LSTNMEA,LB_RESETCONTENT,0,0
			.endif
		.endif
	.elseif eax==WM_INITMENUPOPUP
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if !mapdata.triphead
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_FILE_SAVETRIP,edx
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if !mapdata.disthead
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_FILE_SAVEDIST,edx
		mov		eax,mapdata.trailtail
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if eax==mapdata.trailhead
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_FILE_SAVETRAIL,edx
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if hFileLogWrite || !sonardata.fSTLink || sonardata.fSTLink==IDIGNORE
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_START,edx
		mov		edx,MF_BYCOMMAND or MF_GRAYED
		.if hFileLogRead || hFileLogWrite
			mov		edx,MF_BYCOMMAND or MF_ENABLED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_END,edx
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if hFileLogRead
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_REPLAY,edx
		mov		eax,mapdata.trailtail
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if eax==mapdata.trailhead
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_CLEARTRAIL,edx
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if sonardata.hLog
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_STARTSONAR,edx
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if sonardata.hReplay
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_REPLAYSONAR,edx
		mov		edx,MF_BYCOMMAND or MF_ENABLED
		.if !sonardata.hLog && !sonardata.hReplay
			mov		edx,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMenu,IDM_LOG_ENDSONAR,edx
	.elseif eax==WM_KEYDOWN || eax==WM_MOUSEWHEEL
		invoke SendMessage,hMap,uMsg,wParam,lParam
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		;sub		rect.right,95
		invoke GetParent,hMap
		.if eax==hWin
			mov		ebx,sonardata.wt
			sub		rect.right,ebx
			push	rect.bottom
			.if sonardata.fShowSat
				sub		rect.bottom,SATHT
				invoke MoveWindow,hSonar,rect.right,0,ebx,rect.bottom,TRUE
				invoke MoveWindow,hGPS,rect.right,rect.bottom,ebx,SATHT,TRUE
			.else
				invoke MoveWindow,hSonar,rect.right,0,ebx,rect.bottom,TRUE
				invoke MoveWindow,hGPS,rect.right,rect.bottom,0,0,TRUE
			.endif
			pop		rect.bottom
			sub		rect.right,4
			sub		rect.right,95
			invoke GetDlgItem,hWin,IDC_LSTNMEA
			.if mapdata.fShowNMEA
				sub		rect.bottom,SATHT
				invoke MoveWindow,eax,95,rect.bottom,rect.right,SATHT,TRUE
			.else
				invoke MoveWindow,eax,95,rect.bottom,0,0,TRUE
			.endif
			invoke MoveWindow,hMap,95,0,rect.right,rect.bottom,TRUE
			add		rect.right,ebx
			add		rect.right,4+95
		.endif
	.elseif eax==WM_MOUSEMOVE
		invoke GetClientRect,hWin,addr rect
		invoke GetCapture
		mov		edx,lParam
		movsx	ecx,dx
		shr		edx,16
		movsx	edx,dx
		mov		ebx,MAXXECHO+RANGESCALE+SCROLLWT+4
		add		ebx,sonardata.SignalBarWt
		.if eax==hWin
			mov		eax,rect.right
			;sub		eax,95
			sub		eax,ecx
			.if sdword ptr eax<50
				mov		eax,50
			.elseif sdword ptr eax>ebx
				mov		eax,ebx
			.endif
			.if eax!=sonardata.wt
				mov		sonardata.wt,eax
				invoke SendMessage,hWin,WM_SIZE,0,0
			.endif
		.else
			mov		eax,rect.right
			sub		eax,ecx
			.if eax>50
				invoke SetCursor,hSplittV
			.endif
		.endif
	.elseif eax==WM_LBUTTONDOWN
		invoke GetClientRect,hWin,addr rect
		mov		edx,lParam
		movsx	ecx,dx
		shr		edx,16
		movsx	edx,dx
		mov		eax,rect.right
		sub		eax,ecx
		.if eax>50
			invoke SetCursor,hSplittV
			invoke SetCapture,hWin
		.endif
	.elseif eax==WM_LBUTTONUP
		invoke GetCapture
		.if eax==hWin
			invoke ReleaseCapture
		.endif
	.elseif eax==WM_CLOSE
		invoke IsIconic,hWin
		.if !eax
			invoke IsZoomed,hWin
			mov		fMaximize,eax
			.if !eax
				invoke GetWindowRect,hWin,addr winrect
				mov		eax,winrect.left
				sub		winrect.right,eax
				mov		eax,winrect.top
				sub		winrect.bottom,eax
			.endif
		.endif
		invoke SaveWinPos
		.if hCom
			invoke CloseHandle,hCom
			mov		hCom,0
		.endif
		invoke SaveStatus
		invoke ShowWindow,hWin,SW_HIDE
		invoke KillTimer,hSonar,1000
		invoke KillTimer,hSonar,1001
		mov		fExitMAPThread,TRUE
		mov		fExitGPSThread,TRUE
		mov		fExitSTMThread,TRUE
		invoke RtlZeroMemory,addr msg,sizeof MSG
		invoke GetMessage,addr msg,NULL,0,0
		invoke TranslateAccelerator,hWnd,hAccel,addr msg
		.if !eax
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
		; Terminate GPS Thread
		invoke WaitForSingleObject,hGPSThread,3000
		.if eax==WAIT_TIMEOUT
			invoke TerminateThread,hGPSThread,0
		.endif
		invoke CloseHandle,hGPSThread
		; Terminate STM Thread
		invoke WaitForSingleObject,hSTMThread,3000
		.if eax==WAIT_TIMEOUT
			invoke TerminateThread,hSTMThread,0
		.endif
		invoke CloseHandle,hSTMThread
		; Terminate MAP Thread
		invoke WaitForSingleObject,hMAPThread,3000
		.if eax==WAIT_TIMEOUT
			invoke TerminateThread,hMAPThread,0
		.endif
		invoke CloseHandle,hMAPThread
		.if sonardata.fSTLink && sonardata.fSTLink!=IDIGNORE
			invoke STLinkDisconnect,hWnd
			invoke STLinkDisconnect,hSonar
		.endif
		invoke GlobalFree,mapdata.hMemLon
		invoke GlobalFree,mapdata.hMemLat
		invoke DestroyWindow,hWin
	.elseif eax==WM_POWERBROADCAST
		.if wParam==PBT_APMSUSPEND
;			;Standby
;			invoke KillTimer,hSonar,1000
;			invoke KillTimer,hSonar,1001
;			mov		fExitGPSThread,TRUE
;			mov		fExitSTMThread,TRUE
;			; Terminate GPS Thread
;			invoke WaitForSingleObject,hGPSThread,3000
;			.if eax==WAIT_TIMEOUT
;				invoke TerminateThread,hGPSThread,0
;			.endif
;			invoke CloseHandle,hGPSThread
;			mov		hGPSThread,0
;			; Terminate STM Thread
;			invoke WaitForSingleObject,hSTMThread,3000
;			.if eax==WAIT_TIMEOUT
;				invoke TerminateThread,hSTMThread,0
;			.endif
;			invoke CloseHandle,hSTMThread
;			mov		hSTMThread,0
;			.if sonardata.fSTLink && sonardata.fSTLink!=IDIGNORE
;				mov		sonardata.fSTLink,0
;				invoke STLinkDisconnect,hWnd
;				invoke STLinkDisconnect,hSonar
;			.endif
;			mov		fExitGPSThread,FALSE
;			mov		fExitSTMThread,FALSE
			mov		eax,TRUE
			ret
		.elseif wParam==PBT_APMRESUMEAUTOMATIC
;			;Wakeup
;			invoke SetTimer,hSonar,1000,800,NULL
;			invoke SetTimer,hSonar,1001,500,NULL
;			invoke Sleep,1000
;			;Create thread that comunicates with the GPS
;			invoke CreateThread,NULL,0,addr GPSThread,0,0,addr tid
;			mov		hGPSThread,eax
;			;Create thread that comunicates with the STM
;			invoke CreateThread,NULL,NULL,addr STMThread,0,0,addr tid
;			mov		hSTMThread,eax
			mov		eax,TRUE
			ret
		.endif
	.elseif eax==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	invoke RtlZeroMemory,addr wc,sizeof WNDCLASSEX
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset szMainClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset MapProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,0
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szMapClassName
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc

	mov		wc.lpfnWndProc,offset SonarProc
	mov		wc.lpszClassName,offset szSonarClassName
	invoke RegisterClassEx,addr wc

	mov		wc.lpfnWndProc,offset GPSProc
	mov		wc.lpszClassName,offset szGPSClassName
	invoke RegisterClassEx,addr wc

	invoke LoadWinPos
	invoke LoadMapPoints
	invoke InitZoom
	invoke InitOptions
	invoke InitFonts
	invoke InitMaps
	invoke LoadSonarFromIni
	invoke LoadGPSFromIni
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	mov		eax,SW_SHOWNORMAL
	.if fMaximize
		mov		eax,SW_SHOWMAXIMIZED
	.endif
	invoke ShowWindow,hWnd,eax
	invoke UpdateWindow,hWnd
	;Create thread that comunicates with the GPS
	invoke CreateThread,NULL,0,addr GPSThread,0,0,addr tid
	mov		hGPSThread,eax
	;Create thread that paints the map
	invoke CreateThread,NULL,0,addr MAPThread,0,0,addr tid
	mov		hMAPThread,eax
	;Create thread that comunicates with the STM
	invoke CreateThread,NULL,NULL,addr STMThread,0,0,addr tid
	mov		hSTMThread,eax
	invoke RtlZeroMemory,addr msg,sizeof MSG
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateAccelerator,hWnd,hAccel,addr msg
		.if !eax
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

start:
	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	mov		CommandLine,eax
	invoke InitCommonControls
	invoke GetModuleFileName,hInstance,addr szIniFileName,sizeof szIniFileName
	.while szIniFileName[eax]!='\' && eax
		dec		eax
	.endw
	push	eax
	invoke strcpyn,addr szAppPath,addr szIniFileName,addr [eax+1]
	pop		eax
	invoke strcpy,addr szIniFileName[eax+1],addr szIniFile
	invoke strcpy,addr szFileName,addr szLandFileName
	; Initialize GDI+ Librery
    mov     gdiplSTI.GdiplusVersion,1
    mov		gdiplSTI.DebugEventCallback,NULL
    mov		gdiplSTI.SuppressBackgroundThread,FALSE
    mov		gdiplSTI.SuppressExternalCodecs,FALSE
	invoke GdiplusStartup,offset token,offset gdiplSTI,NULL
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke GdiplusShutdown,token
	invoke ExitProcess,eax

end start
