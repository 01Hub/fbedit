
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
include Bluetooth.asm

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
				mov		esi,offset mapdata.bmpcache
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
	LOCAL	pt:POINT

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
		invoke SetTimer,hWin,1000,50,NULL
	.elseif eax==WM_TIMER
		.if mapdata.ShowCtrl==0
			invoke GetCursorPos,addr pt
			invoke ScreenToClient,hWin,addr pt
			invoke GetClientRect,hWin,addr rect
			mov		eax,pt.x
			mov		edx,pt.y
			.if eax<rect.right && edx<rect.bottom
				mov		ecx,rect.right
				mov		edx,ecx
				sub		ecx,40
				sub		edx,95+40
				.if eax>ecx && mapdata.CtrlWt<95
					mov		mapdata.ShowCtrl,1
				.elseif eax<edx && mapdata.CtrlWt
					mov		mapdata.ShowCtrl,2
				.endif
			.elseif mapdata.CtrlWt==95
				mov		mapdata.ShowCtrl,2
			.endif
		.elseif mapdata.ShowCtrl==1
			.if mapdata.CtrlWt<95
				add		mapdata.CtrlWt,15
				.if mapdata.CtrlWt>=95
					mov		mapdata.CtrlWt,95
					mov		mapdata.ShowCtrl,0
				.endif
				invoke SendMessage,hWin,WM_SIZE,0,0
			.endif
		.elseif mapdata.ShowCtrl==2
			.if mapdata.CtrlWt
				sub		mapdata.CtrlWt,15
				.if sdword ptr mapdata.CtrlWt<=0
					mov		mapdata.CtrlWt,0
					mov		mapdata.ShowCtrl,0
				.endif
				invoke SendMessage,hWin,WM_SIZE,0,0
			.endif
		.endif
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
					invoke wsprintf,addr mapdata.options.text[sizeof OPTIONS*5],addr szFmtDist,0
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
						invoke ClearTrail
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
					invoke wsprintf,addr mapdata.options.text[sizeof OPTIONS*5],addr szFmtDist,0
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
						mov		sonardata.dptinx,0
						mov		sonardata.hReplay,ebx
						.if sonarreplay.Version>=200
							invoke ClearTrail
						.endif
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
			.elseif eax==IDM_OPTION_DISTANCE
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,5
			.elseif eax==IDM_OPTION_RANGE
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,10
			.elseif eax==IDM_OPTIO_DEPTH
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,11
			.elseif eax==IDM_OPTION_WATERTEMP
				invoke DialogBoxParam,hInstance,IDD_DLGOPTION,hWin,addr OptionsProc,12
			.elseif eax==IDM_OPTION_SONAR
				invoke CreateDialogParam,hInstance,IDD_DLGSONAR,hSonar,addr SonarOptionProc,0
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
					invoke ShowWindow,hMap,SW_RESTORE
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
				invoke wsprintf,addr mapdata.options.text[sizeof OPTIONS*5],addr szFmtDist,0
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
				invoke wsprintf,addr mapdata.options.text[sizeof OPTIONS*5],addr szFmtDist,0
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
			.elseif eax==IDM_SONAR_FULLSCREEN
				invoke GetParent,hSonar
				.if eax==hWin
					invoke ShowWindow,hSonar,SW_HIDE
					invoke SetParent,hSonar,0
					invoke ShowWindow,hSonar,SW_SHOWMAXIMIZED
				.else
					invoke SetParent,hSonar,hWin
					invoke ShowWindow,hSonar,SW_RESTORE
				.endif
				invoke SetActiveWindow,hSonar
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
		.if hFileLogWrite || !sonardata.fBluetooth
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
		invoke GetParent,hMap
		.if eax==hWin
			invoke GetParent,hSonar
			.if eax==hWin
				invoke GetClientRect,hWin,addr rect
				mov		eax,mapdata.CtrlWt
				sub		rect.right,eax
				invoke MoveWindow,hControls,rect.right,0,95,rect.bottom,TRUE
				mov		ebx,sonardata.wt
				sub		ebx,mapdata.CtrlWt
				sub		rect.right,ebx
				.if sonardata.fShowSat
					sub		rect.bottom,SATHT
					invoke MoveWindow,hSonar,rect.right,0,ebx,rect.bottom,TRUE
					invoke MoveWindow,hGPS,rect.right,rect.bottom,ebx,SATHT,TRUE
					add		rect.bottom,SATHT
				.else
					invoke MoveWindow,hSonar,rect.right,0,ebx,rect.bottom,TRUE
					invoke MoveWindow,hGPS,rect.right,rect.bottom,0,0,TRUE
				.endif
				; Make a sizebar
				sub		rect.right,4
				invoke GetDlgItem,hWin,IDC_LSTNMEA
				mov		ebx,eax
				.if mapdata.fShowNMEA
					sub		rect.bottom,SATHT
					invoke MoveWindow,hMap,0,0,rect.right,rect.bottom,TRUE
					invoke MoveWindow,ebx,0,rect.bottom,rect.right,SATHT,TRUE
				.else
					invoke MoveWindow,hMap,0,0,rect.right,rect.bottom,TRUE
					invoke MoveWindow,ebx,0,rect.bottom,0,0,TRUE
				.endif
			.endif
		.endif
	.elseif eax==WM_MOUSEMOVE
		invoke GetClientRect,hWin,addr rect
		mov		ebx,MAXXECHO+RANGESCALE+SCROLLWT+4
		add		ebx,sonardata.SignalBarWt
		mov		eax,rect.right
		sub		eax,4
		.if ebx>eax
			mov		ebx,eax
		.endif
		invoke GetCapture
		mov		edx,lParam
		movsx	ecx,dx
		shr		edx,16
		movsx	edx,dx
		.if eax==hWin
			mov		eax,rect.right
			sub		eax,ecx
			.if sdword ptr eax<95
				mov		eax,95
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
		invoke KillTimer,hWin,1000
		invoke KillTimer,hSonar,1000
		.if !fExitMAPThread
			mov		fExitMAPThread,TRUE
		.endif
		.if !fExitSTMThread
			mov		fExitSTMThread,TRUE
		.endif
		.if !fExitBluetoothThread
			mov		fExitBluetoothThread,TRUE
		.endif
		invoke RtlZeroMemory,addr msg,sizeof MSG
		invoke GetMessage,addr msg,NULL,0,0
		invoke TranslateAccelerator,hWnd,hAccel,addr msg
		.if !eax
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
		invoke Sleep,500
		; Terminate STM Thread
		.if fExitSTMThread!=2
			invoke WaitForSingleObject,hSTMThread,3000
			.if eax==WAIT_TIMEOUT
				invoke TerminateThread,hSTMThread,0
			.endif
		.endif
		invoke CloseHandle,hSTMThread
		; Terminate Bluetooth Thread
		.if fExitBluetoothThread!=2
			invoke WaitForSingleObject,hBluetoothThread,3000
			.if eax==WAIT_TIMEOUT
				invoke TerminateThread,hBluetoothThread,0
			.endif
		.endif
		invoke CloseHandle,hBluetoothThread
		; Terminate MAP Thread
		.if fExitMAPThread!=2
			invoke WaitForSingleObject,hMAPThread,3000
			.if eax==WAIT_TIMEOUT
				invoke TerminateThread,hMAPThread,0
			.endif
		.endif
		invoke CloseHandle,hMAPThread
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
	mov		wc.lpfnWndProc,offset MapChildProc
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

	mov		wc.lpfnWndProc,offset SonarChildProc
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
	;Create thread that paints the map
	invoke CreateThread,NULL,0,addr MAPThread,0,0,addr tid
	mov		hMAPThread,eax
	;Create thread that updates using data from STM
	invoke CreateThread,NULL,NULL,addr STMThread,0,0,addr tid
	mov		hSTMThread,eax
	;Create thread that comunicates with the STM using Bluetooth
	invoke CreateThread,NULL,NULL,addr BlueToothClient,0,0,addr tid
	mov		hBluetoothThread,eax
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

GetChksum proc lpData:DWORD
	
	call GetCheckSum
	ret

CheckSum:
	xor		eax,eax
	.while byte ptr [edx]!='*'
		xor		al,[edx]
		.if byte ptr [edx]==0Dh
			retn
		.endif
		inc		edx
	.endw
	PrintHex al
;	push	eax
;	shr		eax,4
;	.if eax>=0ah
;		add		eax,'A'-0Ah
;	.else
;		or		eax,30h
;	.endif
;	mov		[edx+1],al
;	pop		eax
;	and		eax,0Fh
;	.if eax>=0ah
;		add		eax,'A'-0Ah
;	.else
;		or		eax,30h
;	.endif
;	mov		[edx+2],al
	retn


GetCheckSum:
	mov		edx,lpData
	.while byte ptr [edx]
		.while byte ptr [edx] && byte ptr [edx]!='$'
			inc		edx
		.endw
		.if byte ptr [edx]
			inc		edx
			call	CheckSum
		.endif
	.endw
	retn

GetChksum endp

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
;invoke GetChksum,offset szGPSReset
	invoke ExitProcess,eax

end start
