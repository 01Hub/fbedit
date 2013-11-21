
IDD_DLGGPSSETUP			equ 1400
IDC_CHKRESET			equ 1401
IDC_CHKTRACKSMOOTHING	equ 1401
IDC_BTNRATEDN			equ 1407
IDC_TRBRATE				equ 1406
IDC_BTNRATEUP			equ 1402
IDC_BTNSMOOTHDN			equ 1408
IDC_TRBSMOOTH			equ 1409
IDC_BTNSMOOTHUP			equ 1410

SATHT					equ 220
SATRAD					equ (SATHT-20)/2
SATTXTWT				equ 78
SATSIGNALWT				equ 148

.const

szCOM1					BYTE 'COM1',0
szBaudRate				BYTE '4800',0

szFmtTime				BYTE '%02d%02d%02d %02d:%02d:%02d',0
szColon					BYTE ': ',0

szFix					BYTE 'Fix:',0
szHDOP					BYTE 'HDOP:',0
szVDOP					BYTE 'VDOP:',0
szPDOP					BYTE 'PDOP:',0
szSatelites				BYTE 'Sat:',0
szAltitude				BYTE 'Alt:',0
szLattitude				BYTE 'Lattitude:',0
szLongitude				BYTE 'Longitude:',0
szBearing				BYTE 'Bearing:',0
szSpeed					BYTE 'Speed:',0
szNoFix					BYTE 'No fix',0
szFix2D					BYTE '2D',0
szFix3D					BYTE '3D',0

.data?

hFileLogRead			HANDLE ?
hFileLogWrite			HANDLE ?
npos					DWORD ?
COMPort					BYTE 16 dup(?)
BaudRate				BYTE 16 dup(?)
COMActive				DWORD ?
hCom					HANDLE ?
combuff					BYTE 4096 dup(?)

.code

LoadGPSFromIni proc
	LOCAL	buffer[256]:BYTE

	invoke GetPrivateProfileString,addr szIniGPS,addr szIniGPS,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	invoke GetItemStr,addr buffer,addr szCOM1,addr COMPort,6
	invoke GetItemStr,addr buffer,addr szBaudRate,addr BaudRate,6
	invoke GetItemInt,addr buffer,0
	mov		COMActive,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.TrackSmooth,eax
	invoke GetItemInt,addr buffer,1
	mov		mapdata.TrailRate,eax
	ret

LoadGPSFromIni endp

SaveGPSToIni proc
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	invoke PutItemStr,addr buffer,addr COMPort
	invoke PutItemStr,addr buffer,addr BaudRate
	invoke PutItemInt,addr buffer,COMActive
	invoke PutItemInt,addr buffer,mapdata.TrackSmooth
	invoke PutItemInt,addr buffer,mapdata.TrailRate
	invoke WritePrivateProfileString,addr szIniGPS,addr szIniGPS,addr buffer[1],addr szIniFileName
	ret

SaveGPSToIni endp

GPSOptionProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke ImageList_GetIcon,hIml,12,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNSMOOTHDN,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke SendDlgItemMessage,hWin,IDC_BTNRATEDN,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke ImageList_GetIcon,hIml,4,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNSMOOTHUP,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke SendDlgItemMessage,hWin,IDC_BTNRATEUP,BM_SETIMAGE,IMAGE_ICON,ebx
		push	0
		push	IDC_BTNSMOOTHDN
		push	IDC_BTNSMOOTHUP
		push	IDC_BTNRATEDN
		mov		eax,IDC_BTNRATEUP
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		invoke SendDlgItemMessage,hWin,IDC_TRBSMOOTH,TBM_SETRANGE,FALSE,(99 SHL 16)+0
		invoke SendDlgItemMessage,hWin,IDC_TRBSMOOTH,TBM_SETPOS,TRUE,mapdata.TrackSmooth
		invoke SendDlgItemMessage,hWin,IDC_TRBRATE,TBM_SETRANGE,FALSE,(99 SHL 16)+1
		invoke SendDlgItemMessage,hWin,IDC_TRBRATE,TBM_SETPOS,TRUE,mapdata.TrailRate
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke IsDlgButtonChecked,hWin,IDC_CHKRESET
				mov		mapdata.GPSReset,eax
				invoke SaveGPSToIni
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNSMOOTHDN
				.if mapdata.TrackSmooth
					dec		mapdata.TrackSmooth
					invoke SendDlgItemMessage,hWin,IDC_TRBSMOOTH,TBM_SETPOS,TRUE,mapdata.TrackSmooth
				.endif
			.elseif eax==IDC_BTNSMOOTHUP
				.if mapdata.TrackSmooth<99
					inc		mapdata.TrackSmooth
					invoke SendDlgItemMessage,hWin,IDC_TRBSMOOTH,TBM_SETPOS,TRUE,mapdata.TrackSmooth
				.endif
			.elseif eax==IDC_BTNRATEDN
				.if mapdata.TrailRate>1
					dec		mapdata.TrailRate
					invoke SendDlgItemMessage,hWin,IDC_TRBRATE,TBM_SETPOS,TRUE,mapdata.TrailRate
				.endif
			.elseif eax==IDC_BTNRATEUP
				.if mapdata.TrailRate<99
					inc		mapdata.TrailRate
					invoke SendDlgItemMessage,hWin,IDC_TRBRATE,TBM_SETPOS,TRUE,mapdata.TrailRate
				.endif
			.endif
		.endif
	.elseif eax==WM_HSCROLL
		invoke SendMessage,lParam,TBM_GETPOS,0,0
		mov		ebx,eax
		invoke GetWindowLong,lParam,GWL_ID
		.if eax==IDC_TRBSMOOTH
			mov		mapdata.TrackSmooth,ebx
		.else
			mov		mapdata.TrailRate,ebx
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,lParam
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

GPSOptionProc endp

GetPointOnCircle proc uses edi,radius:DWORD,angle:DWORD,lpPoint:ptr POINT
	LOCAL	r:QWORD

	mov		edi,lpPoint
	fild    DWORD ptr [angle]
	fmul	REAL8 ptr [deg2rad]
	fst		REAL8 ptr [r]
	fcos
	fild    DWORD ptr [radius]
	fmulp	st(1),st(0)
	fistp	DWORD ptr [edi].POINT.x
	fld		REAL8 ptr [r]
	fsin
	fild    DWORD ptr [radius]
	fmulp	st(1),st(0)
	fistp	DWORD ptr [edi].POINT.y
	ret

GetPointOnCircle endp

GPSProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	srect:RECT
	LOCAL	ps:PAINTSTRUCT
	LOCAL	mDC:HDC
	LOCAL	buffer[256]:BYTE
	LOCAL	pt:POINT
	LOCAL	ptcenter:POINT

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hGPS,eax
	.elseif eax==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke GetClientRect,hWin,addr rect
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke SetBkMode,mDC,TRANSPARENT
		invoke CreatePen,PS_SOLID,1,808080h
		invoke SelectObject,mDC,eax
		push	eax
		invoke SelectObject,mDC,sonardata.hBrBack
		push	eax
		invoke SelectObject,mDC,mapdata.font[2*4]
		push	eax
		invoke FillRect,mDC,addr rect,sonardata.hBrBack
		mov		eax,rect.right
		sub		eax,SATSIGNALWT+SATRAD+5
		mov		ptcenter.x,eax
		mov		ptcenter.y,SATHT/2;-5
		mov		ecx,ptcenter.x
		mov		edx,ptcenter.y
		invoke Ellipse,mDC,addr [ecx-SATRAD],addr [edx-SATRAD],addr [ecx+SATRAD],addr [edx+SATRAD]
		mov		ecx,ptcenter.x
		mov		edx,ptcenter.y
		invoke Ellipse,mDC,addr [ecx-SATRAD/2],addr [edx-SATRAD/2],addr [ecx+SATRAD/2],addr [edx+SATRAD/2]
		mov		ecx,ptcenter.x
		mov		edx,ptcenter.y
		invoke MoveToEx,mDC,addr [ecx-SATRAD],edx,NULL
		mov		ecx,ptcenter.x
		mov		edx,ptcenter.y
		invoke LineTo,mDC,addr [ecx+SATRAD],edx
		mov		ecx,ptcenter.x
		mov		edx,ptcenter.y
		invoke MoveToEx,mDC,ecx,addr [edx-SATRAD],NULL
		mov		ecx,ptcenter.x
		mov		edx,ptcenter.y
		invoke LineTo,mDC,ecx,addr [edx+SATRAD]
		mov		eax,ptcenter.x
		mov		edx,ptcenter.y
		sub		eax,8
		sub		edx,8
		invoke ImageList_Draw,hIml,28,mDC,eax,edx,ILD_TRANSPARENT
		invoke GetClientRect,hWin,addr rect
		mov		rect.top,5
		mov		eax,rect.right
		mov		esi,eax
		sub		esi,SATSIGNALWT
		sub		eax,SATTXTWT+5
		mov		rect.left,eax
		xor		ebx,ebx
		xor		edi,edi
		.while ebx<12
			.if mapdata.satelites.SatelliteID[edi]
				;This would be the right way but gives poor graphic representation of the elevation angle.
				;invoke GetPointOnCircle,SATRAD,satelites.Elevation[edi],addr pt
				;mov		ecx,pt.x
				;A linear function of the elevation angle gives better graphic representation
				mov		eax,90
				movsx	edx,mapdata.satelites.Elevation[edi]
				sub		eax,edx
				mov		ecx,SATRAD
				mul		ecx
				mov		ecx,180/2
				div		ecx
				mov		ecx,eax
				movzx	edx,mapdata.satelites.Azimuth[edi]
				; North is 0 deg, sub 90 deg
				sub		edx,90
				invoke GetPointOnCircle,ecx,edx,addr pt
				mov		eax,ptcenter.x
				sub		eax,8
				add		pt.x,eax
				mov		eax,ptcenter.y
				sub		eax,8
				add		pt.y,eax
				movzx	eax,mapdata.satelites.SatelliteID[edi]
				invoke wsprintf,addr buffer,addr szFmtDec2,eax
				invoke strcat,addr buffer,addr szColon
				movzx	eax,mapdata.satelites.SNR[edi]
				invoke wsprintf,addr buffer[4],addr szFmtDec2,eax
				invoke strcat,addr buffer,addr szColon+1
				movsx	eax,mapdata.satelites.Elevation[edi]
				invoke wsprintf,addr buffer[7],addr szFmtDec2,eax
				invoke strcat,addr buffer,addr szColon+1
				movzx	eax,mapdata.satelites.Azimuth[edi]
				invoke wsprintf,addr buffer[10],addr szFmtDec3,eax
				.if mapdata.satelites.SNR[edi]
					.if mapdata.satelites.Fixed[edi]
						push	06000h
						mov		eax,29
					.else
						push	0800000h
						mov		eax,31
					.endif
				.else
					push	080h
					mov		eax,30
				.endif
				invoke ImageList_Draw,hIml,eax,mDC,pt.x,pt.y,ILD_TRANSPARENT
				add		pt.x,1
				add		pt.y,1
				invoke SetTextColor,mDC,0FFFFFFh
				invoke TextOut,mDC,pt.x,pt.y,addr buffer,2
				pop		eax
				invoke SetTextColor,mDC,eax
				invoke TextOut,mDC,rect.left,rect.top,addr buffer,13
				add		rect.top,10
				mov		edx,rect.bottom
				sub		edx,25
				invoke TextOut,mDC,esi,edx,addr buffer,1
				mov		edx,rect.bottom
				sub		edx,15
				invoke TextOut,mDC,esi,edx,addr buffer[1],1
				mov		srect.left,esi
				lea		eax,[esi+10]
				mov		srect.right,eax
				mov		eax,rect.bottom
				sub		eax,27
				mov		srect.bottom,eax
				movzx	edx,mapdata.satelites.SNR[edi]
				;shr		edx,1
				sub		eax,edx
				mov		srect.top,eax
				invoke GetTextColor,mDC
				invoke CreateSolidBrush,eax
				push	eax
				invoke FillRect,mDC,addr srect,eax
				pop		eax
				invoke DeleteObject,eax
				mov		eax,srect.bottom
				sub		eax,50
				mov		srect.top,eax
				invoke GetStockObject,WHITE_BRUSH
				invoke FrameRect,mDC,addr srect,eax
				add		esi,12
			.endif
			lea		edi,[edi+sizeof SATELITE]
			inc		ebx
		.endw
		invoke SetTextColor,mDC,0
		mov		esi,rect.right
		sub		esi,485
		invoke TextOut,mDC,esi,5,addr szFix,4
		invoke TextOut,mDC,esi,15,addr szSatelites,4
		invoke TextOut,mDC,esi,25,addr szHDOP,5
		invoke TextOut,mDC,esi,35,addr szVDOP,5
		invoke TextOut,mDC,esi,45,addr szPDOP,5
		invoke TextOut,mDC,esi,55,addr szAltitude,4
		invoke TextOut,mDC,esi,65,addr szLattitude,10
		invoke TextOut,mDC,esi,75,addr szLongitude,10
		invoke TextOut,mDC,esi,85,addr szBearing,8
		invoke TextOut,mDC,esi,95,addr szSpeed,6
		add		esi,60
		movzx	eax,mapdata.altitude.fixquality
		.if eax==2
			invoke TextOut,mDC,esi,5,addr szFix2D,2
		.elseif eax==3
			invoke TextOut,mDC,esi,5,addr szFix3D,2
		.else
			invoke TextOut,mDC,esi,5,addr szNoFix,6
		.endif
		movzx	eax,mapdata.altitude.nsat
		invoke wsprintf,addr buffer,addr szFmtDec,eax
		invoke strlen,addr buffer
		invoke TextOut,mDC,esi,15,addr buffer,eax
		movzx	eax,mapdata.altitude.hdop
		mov		ebx,25
		call	PrintDOP
		movzx	eax,mapdata.altitude.vdop
		mov		ebx,35
		call	PrintDOP
		movzx	eax,mapdata.altitude.pdop
		mov		ebx,45
		call	PrintDOP
		movsx	eax,mapdata.altitude.alt
		invoke wsprintf,addr buffer,addr szFmtDec,eax
		invoke strlen,addr buffer
		invoke TextOut,mDC,esi,55,addr buffer,eax
		invoke wsprintf,addr buffer,addr szFmtDec10,mapdata.iLat
		invoke strlen,addr buffer
		mov		edx,dword ptr buffer[eax-3]
		mov		ecx,dword ptr buffer[eax-7]
		mov		dword ptr buffer[eax-2],edx
		mov		dword ptr buffer[eax-6],ecx
		mov		buffer[eax-6],'.'
		inc		eax
		.if buffer=='0'
			mov		word ptr buffer,' N'
		.else
			mov		word ptr buffer,' S'
		.endif
		invoke TextOut,mDC,esi,65,addr buffer,eax
		invoke wsprintf,addr buffer,addr szFmtDec10,mapdata.iLon
		invoke strlen,addr buffer
		mov		edx,dword ptr buffer[eax-3]
		mov		ecx,dword ptr buffer[eax-7]
		mov		dword ptr buffer[eax-2],edx
		mov		dword ptr buffer[eax-6],ecx
		mov		buffer[eax-6],'.'
		inc		eax
		.if buffer=='0'
			mov		word ptr buffer,' E'
		.else
			mov		word ptr buffer,' W'
		.endif
		invoke TextOut,mDC,esi,75,addr buffer,eax
		invoke BinToDec,mapdata.iBear,addr buffer
		invoke strlen,addr buffer
		invoke TextOut,mDC,esi,85,addr buffer,eax
		invoke wsprintf,addr buffer,addr szFmtDec2,mapdata.iSpeed
		invoke strlen,addr buffer
		mov		edx,dword ptr buffer[eax-1]
		mov		buffer[eax-1],'.'
		mov		dword ptr buffer [eax],edx
		inc		eax
		invoke TextOut,mDC,esi,95,addr buffer,eax
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		pop		eax
		invoke SelectObject,mDC,eax
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

PrintDOP:
	invoke wsprintf,addr buffer,addr szFmtDec2,eax
	invoke strlen,addr buffer
	mov		edx,dword ptr buffer[eax-1]
	mov		buffer[eax-1],'.'
	mov		dword ptr buffer [eax],edx
	inc		eax
	invoke TextOut,mDC,esi,ebx,addr buffer,eax
	retn

GPSProc endp
