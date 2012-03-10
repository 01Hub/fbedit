
IDD_DLGGPSSETUP		equ 1400
IDC_EDTCOMPORT		equ 1403
IDC_CBOBAUDRATE		equ 1404
IDC_CHKCOMACTIVE	equ 1405

.const

szCOM1				BYTE 'COM1',0
szBaudRate			BYTE '4800',0
					BYTE '9600',0
					BYTE '19200',0
					BYTE '38400',0,0
szComFailed			BYTE 'Opening com port failed.',0Dh,'Retry?',0

szGPRMC				BYTE '$GPRMC',0
szGPGSV				BYTE '$GPGSV',0

szBinToDec			BYTE '%06d',0
szFmtTime			BYTE '%02d%02d%02d %02d:%02d:%02d',0
szColon				BYTE ': ',0


.data?

hFileLogRead		HANDLE ?
hFileLogWrite		HANDLE ?
npos				DWORD ?
combuff				BYTE 4096 dup(?)
linebuff			BYTE 512 dup(?)
logbuff				BYTE 1024 dup(?)
COMPort				BYTE 16 dup(?)
BaudRate			BYTE 16 dup(?)
COMActive			DWORD ?
hCom				HANDLE ?
dcb					DCB <>
to					COMMTIMEOUTS <>

.code

OpenCom proc

	.if hCom
		invoke CloseHandle,hCom
		mov		hCom,0
	.endif
	.if COMActive
		; Setup
		invoke CreateFile,addr COMPort,GENERIC_READ or GENERIC_WRITE,NULL,NULL,OPEN_EXISTING,NULL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov		hCom,eax
			mov		dcb.DCBlength,sizeof DCB
			invoke DecToBin,addr BaudRate
			mov		dcb.BaudRate,eax
			mov		dcb.ByteSize,8
			mov		dcb.Parity,0
			mov		dcb.StopBits,1
			invoke SetCommState,hCom,addr dcb
			mov		to.ReadTotalTimeoutConstant,1
			mov		to.WriteTotalTimeoutConstant,10
			invoke SetCommTimeouts,hCom,addr to
		.else
			invoke MessageBox,hWnd,addr szComFailed,addr COMPort,MB_ICONERROR or MB_YESNO
			.if eax==IDNO
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.endif
		.endif
	.endif
	ret

OpenCom endp

GetLine proc uses esi,pos:DWORD

	mov		ecx,pos
	.if combuff[ecx]=='$'
		xor		edx,edx
		.while combuff[ecx] && edx<500
			mov		al,combuff[ecx]
			.if al==0Dh
				mov		linebuff[edx],0
				inc		ecx
				.if combuff[ecx]==0Ah
					inc		ecx
					mov		eax,ecx
					sub		eax,pos
					jmp		Ex
				.endif
				.break
			.endif
			mov		linebuff[edx],al
			inc		ecx
			inc		edx
		.endw
	.endif
	xor		eax,eax
  Ex:
	ret

GetLine endp

DoGPSComm proc uses ebx esi edi,Param:DWORD
	LOCAL	nRead:DWORD
	LOCAL	nWrite:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	bufflog[256]:BYTE
	LOCAL	bufftime[32]:BYTE
	LOCAL	buffdate[32]:BYTE
	LOCAL	nTrail:DWORD
	LOCAL	iLon:DWORD
	LOCAL	iLat:DWORD
	LOCAL	fDist:REAL10
	LOCAL	fBear:REAL10
	LOCAL	iTime:DWORD
	LOCAL	iSumDist:DWORD
	LOCAL	ft:FILETIME
	LOCAL	lft:FILETIME
	LOCAL	lst:SYSTEMTIME
	LOCAL	fValid:DWORD
	LOCAL	nGPSCount:DWORD
	LOCAL	nSatelites:DWORD
	LOCAL	SatPtr:DWORD

	invoke OpenCom
	.while  !fExitGpsThread
		mov		eax,sonardata.nGPSCounter
		.if hFileLogRead
			.if !map.gpslogpause
				invoke ReadFile,hFileLogRead,addr combuff,1024,addr nRead,NULL
				.if !nRead
					invoke CloseHandle,hFileLogRead
					invoke GetDlgItem,hWnd,IDC_CHKPAUSE
					invoke EnableWindow,eax,FALSE
					mov		hFileLogRead,0
					mov		npos,0
					fldz
					fstp	fDist
					mov		nTrail,0
				.else
					.if !nTrail
						fldz
						fstp	map.fSumDist
					.endif
					invoke strlen,addr combuff
					lea		eax,[eax+1]
					add		npos,eax
					invoke SetFilePointer,hFileLogRead,npos,NULL,FILE_BEGIN
					xor		ebx,ebx
					call	GPSExec
					invoke Sleep,100
				.endif
			.endif
			mov		nRead,0
		.elseif eax!=nGPSCount && !sonardata.hReplay
			mov		nGPSCount,eax
			invoke strcpy,addr combuff,addr sonardata.GPSArray
			xor		ebx,ebx
			call	GPSExec
		.elseif hCom
			xor		ebx,ebx
GetMore:
			.if hCom
		 		invoke ReadFile,hCom,addr combuff[ebx],256,addr nRead,NULL
		 		mov		eax,nRead
		 		.if eax
			 		add		ebx,eax
			 		mov		combuff[ebx],0
			 		invoke Sleep,10
			 		jmp		GetMore
		 		.endif
		 		.if combuff
;	PrintStringByAddr offset combuff
		 			xor		ebx,ebx
					call	GPSExec
					mov		combuff,0
		 		.endif
			.endif
		.endif
		invoke Sleep,100
	.endw
	.if hFileLogRead
		invoke CloseHandle,hFileLogRead
		mov		hFileLogRead,0
	.endif
	.if hFileLogWrite
		invoke CloseHandle,hFileLogWrite
		mov		hFileLogWrite,0
	.endif
;PrintText "GPS Exit"
	ret

GPSExec:
	.if combuff[ebx]
		invoke GetLine,ebx
		.if eax
			add		ebx,eax
			push	ebx
			.if hFileLogWrite
				invoke strcpy,addr bufflog,addr linebuff
				invoke strcat,addr bufflog,addr szCRLF
			.endif
			invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
			invoke strcmp,addr buffer,addr szGPRMC
			.if !eax
				call	PositionSpeedDirection
				.if hFileLogWrite
					invoke strcat,addr logbuff,addr bufflog
				.endif
			.else
				invoke strcmp,addr buffer,addr szGPGSV
				.if !eax
					.if !sonardata.fGSV
						mov		sonardata.fGSV,TRUE
						invoke SendMessage,hWnd,WM_SIZE,0,0
					.endif
					invoke GetItemInt,addr linebuff,0			;Number of Messages
					invoke GetItemInt,addr linebuff,0			;Messages number
					push	eax
					invoke GetItemInt,addr linebuff,0			;Satellites in View
					pop		edx
					.if edx==1
						mov		nSatelites,eax
						mov		SatPtr,0
					.endif
					xor		ebx,ebx
					mov		edi,SatPtr
					.while nSatelites && ebx<4
						invoke GetItemInt,addr linebuff,0			;Satellite ID
						mov		satelites.SatelliteID[edi],eax
						invoke GetItemInt,addr linebuff,0			;Elevation
						mov		satelites.Elevation[edi],eax
						invoke GetItemInt,addr linebuff,0			;Azimuth
						mov		satelites.Azimuth[edi],eax
						invoke GetItemInt,addr linebuff,0			;SNR
						mov		satelites.SNR[edi],eax
						lea		edi,[edi+sizeof SATELITE]
						inc		ebx
						dec		nSatelites
					.endw
					mov		SatPtr,edi
					.if !nSatelites
						invoke InvalidateRect,hGPS,NULL,TRUE
					.endif
				.endif
			.endif
			.if hFileLogWrite && !map.gpslogpause
				invoke strlen,addr logbuff
				lea		edx,[eax+1]
				invoke WriteFile,hFileLogWrite,addr logbuff,edx,addr nWrite,NULL
			.endif
			.if !hFileLogRead
				mov		npos,0
			.endif
			mov		logbuff,0
			mov		combuff,0
			.if (!map.bdist || map.bdist==2) && (!map.btrip || map.btrip==2)
				invoke DoGoto,map.iLon,map.iLat,map.gpslock,TRUE
				invoke SetDlgItemInt,hWnd,IDC_EDTEAST,map.iLon,TRUE
				invoke SetDlgItemInt,hWnd,IDC_EDTNORTH,map.iLat,TRUE
				inc		map.paintnow
			.endif
			pop		ebx
			jmp		GPSExec
		.endif
	.endif
	retn

PositionSpeedDirection:
	;Time
	invoke GetItemStr,addr linebuff,addr szNULL,addr bufftime,32
	;Status
	invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
	.if buffer=='A'
		mov		map.fcursor,TRUE
		mov		fValid,TRUE
	.else
		inc		map.fcursor
		and		map.fcursor,1
		mov		fValid,FALSE
	.endif
	mov		eax,map.iLon
	mov		iLon,eax
	mov		eax,map.iLat
	mov		iLat,eax
	.if fValid
		;Lattitude
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		lea		esi,buffer
		mov		edi,esi
		.while byte ptr [esi]
			mov		al,[esi]
			.if al!='.'
				mov		[edi],al
				inc		edi
			.endif
			inc		esi
		.endw
		mov		byte ptr [edi],0
		invoke DecToBin,addr buffer[2]
		;convert minutes to decimal
		mov		ecx,100
		mul		ecx
		mov		ecx,60
		xor		edx,edx
		div		ecx
		mov		edx,eax
		invoke wsprintf,addr buffer[2],addr szBinToDec,edx
		invoke DecToBin,addr buffer
		push	eax
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		pop		eax
		.if buffer=='S'
			neg		eax
		.endif
		mov		map.iLat,eax
		;Longitude
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		lea		esi,buffer
		mov		edi,esi
		.while byte ptr [esi]
			mov		al,[esi]
			.if al!='.'
				mov		[edi],al
				inc		edi
			.endif
			inc		esi
		.endw
		mov		byte ptr [edi],0
		invoke DecToBin,addr buffer[3]
		;convert minutes to decimal
		mov		ecx,100
		mul		ecx
		mov		ecx,60
		xor		edx,edx
		div		ecx
		mov		edx,eax
		invoke wsprintf,addr buffer[3],addr szBinToDec,edx
		invoke DecToBin,addr buffer
		push	eax
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		pop		eax
		.if combuff=='W'
			neg		eax
		.endif
		mov		map.iLon,eax
		;Speed
		invoke GetItemStr,addr linebuff,addr szNULL,addr map.options.text,sizeof OPTIONS.text
		invoke strcpy,addr buffer,addr map.options.text
		invoke strlen,addr buffer
		.while buffer[eax]!='.' && eax
			dec		eax
		.endw
		mov		buffer[eax+2],0
		mov		ecx,dword ptr buffer[eax+1]
		mov		dword ptr buffer[eax],ecx
		invoke DecToBin,addr buffer
		mov		map.iSpeed,eax
		;Get the bearing
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke DecToBin,addr buffer
		mov		map.iBear,eax
		invoke SetGPSCursor
	.else
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
	.endif
	mov		iTime,0
	;Date
	invoke GetItemStr,addr linebuff,addr szNULL,addr buffdate,32
	;YYYY YYYM MMMD DDDD
	;0010 0100 0000 0000 0000 0000 0001 1111
	;Get year
	invoke DecToBin,addr buffdate[4]
	mov		buffdate[4],0
	shl		eax,9
	or		iTime,eax
	;Get month
	invoke DecToBin,addr buffdate[2]
	mov		buffdate[2],0
	shl		eax,5
	or		iTime,eax
	;Get day
	invoke DecToBin,addr buffdate
	or		iTime,eax
	shl		iTime,16
	;HHHH HMMM MMS SSSS
	;Get seconds
	invoke DecToBin,addr bufftime[4]
	mov		bufftime[4],0
	shr		eax,1
	or		iTime,eax
	;Get minutes
	invoke DecToBin,addr bufftime[2]
	mov		bufftime[2],0
	shl		eax,5
	or		iTime,eax
	;Get hours
	invoke DecToBin,addr bufftime
	shl		eax,11
	or		iTime,eax
	mov		eax,iTime
	mov		map.iTime,eax
	mov		ecx,eax
	movzx	edx,ax
	shr		ecx,16
	invoke DosDateTimeToFileTime,ecx,edx,addr ft
	invoke FileTimeToLocalFileTime,addr ft,addr lft
	invoke FileTimeToSystemTime,addr lft,addr lst
	mov		ebx,esp
	movzx	eax,lst.wSecond
	push	eax
	movzx	eax,lst.wMinute
	push	eax
	movzx	eax,lst.wHour
	push	eax
	movzx	eax,lst.wYear
	sub		eax,1980
	push	eax
	movzx	eax,lst.wMonth
	push	eax
	movzx	eax,lst.wDay
	push	eax
	push	offset szFmtTime
	lea		eax,map.options.text[sizeof OPTIONS*4]
	push	eax
	call	wsprintf
	mov		esp,ebx
	.if fValid
		invoke AddTrailPoint,map.iLon,map.iLat,map.iBear,map.iTime
		.if nTrail
			mov		eax,map.iLon
			mov		edx,map.iLat
			.if eax!=iLon || edx!=iLat
				invoke BearingDistanceInt,iLon,iLat,map.iLon,map.iLat,addr fDist,addr fBear
				fld		fDist
				fld		map.fSumDist
				faddp	st(1),st(0)
				fst		st(1)
				lea		eax,map.fSumDist
				fstp	REAL10 PTR [eax]
				lea		eax,iSumDist
				fistp	dword ptr [eax]
				invoke SetDlgItemInt,hWnd,IDC_EDTDIST,iSumDist,FALSE
				invoke SetDlgItemInt,hWnd,IDC_EDTBEAR,map.iBear,FALSE
			.endif
		.endif
		inc		nTrail
	.endif
	retn

DoGPSComm endp

LoadGPSFromIni proc
	LOCAL	buffer[256]:BYTE

	invoke GetPrivateProfileString,addr szIniGPS,addr szIniGPS,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	invoke GetItemStr,addr buffer,addr szCOM1,addr COMPort,5
	invoke GetItemStr,addr buffer,addr szBaudRate,addr BaudRate,5
	invoke GetItemInt,addr buffer,0
	mov		COMActive,eax
	ret

LoadGPSFromIni endp

SaveGPSToIni proc
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	invoke PutItemStr,addr buffer,addr COMPort
	invoke PutItemStr,addr buffer,addr BaudRate
	invoke PutItemInt,addr buffer,COMActive
	invoke WritePrivateProfileString,addr szIniGPS,addr szIniGPS,addr buffer[1],addr szIniFileName
	ret

SaveGPSToIni endp

GPSOptionProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SetDlgItemText,hWin,IDC_EDTCOMPORT,addr COMPort
		mov		esi,offset szBaudRate
		xor		edi,edi
		xor		ebx,ebx
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOBAUDRATE,CB_ADDSTRING,0,esi
			invoke strcmp,esi,addr BaudRate
			.if !eax
				mov		ebx,edi
			.endif
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			inc		edi
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBOBAUDRATE,CB_SETCURSEL,ebx,0
		.if COMActive
			invoke CheckDlgButton,hWin,IDC_CHKCOMACTIVE,BST_CHECKED
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke GetDlgItemText,hWin,IDC_EDTCOMPORT,addr COMPort,5
				invoke SendDlgItemMessage,hWin,IDC_CBOBAUDRATE,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOBAUDRATE,CB_GETLBTEXT,eax,addr BaudRate
				invoke IsDlgButtonChecked,hWin,IDC_CHKCOMACTIVE
				mov		COMActive,eax
				invoke SaveGPSToIni
				invoke OpenCom
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_CHKCOMACTIVE
			.endif
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

GPSProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	ps:PAINTSTRUCT
	LOCAL	buffer[256]:BYTE

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hGPS,eax
	.elseif eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		sub		rect.right,110
		mov		eax,rect.right
		shr		eax,1
		sub		eax,170
		mov		rect.left,eax
		add		eax,340
		mov		rect.right,eax
		invoke BeginPaint,hWin,addr ps
		invoke SetBkMode,ps.hdc,TRANSPARENT
		invoke CreatePen,PS_SOLID,1,0FFh
		invoke SelectObject,ps.hdc,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke SelectObject,ps.hdc,eax
		push	eax
		invoke Ellipse,ps.hdc,rect.left,10,rect.right,350
;		invoke ImageList_Draw,hIml,31,ps.hdc,150,150,ILD_TRANSPARENT
;		invoke ImageList_Draw,hIml,29,ps.hdc,120,200,ILD_TRANSPARENT
		mov		eax,rect.right
		sub		eax,rect.left
		shr		eax,1
		add		eax,rect.left
		sub		eax,8
		invoke ImageList_Draw,hIml,28,ps.hdc,eax,360/2-8,ILD_TRANSPARENT
		invoke GetClientRect,hWin,addr rect
		mov		rect.top,5
		mov		eax,rect.right
		sub		eax,105
		mov		rect.left,eax
		xor		ebx,ebx
		xor		edi,edi
		.while ebx<12
			.if satelites.SNR[edi]
				invoke SetTextColor,ps.hdc,0FF00h
			.else
				invoke SetTextColor,ps.hdc,0FFh
			.endif
			invoke wsprintf,addr buffer,addr szFmtDec2,satelites.SatelliteID[edi]
			invoke strcat,addr buffer,addr szColon
			invoke wsprintf,addr buffer[4],addr szFmtDec2,satelites.SNR[edi]
			invoke strcat,addr buffer,addr szColon
			invoke wsprintf,addr buffer[8],addr szFmtDec2,satelites.Elevation[edi]
			invoke strcat,addr buffer,addr szColon
			invoke wsprintf,addr buffer[12],addr szFmtDec3,satelites.Azimuth[edi]
			invoke strlen,addr buffer
			invoke TextOut,ps.hdc,rect.left,rect.top,addr buffer,eax
			add		rect.top,20
			lea		edi,[edi+sizeof SATELITE]
			inc		ebx
		.endw
		pop		eax
		invoke SelectObject,ps.hdc,eax
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke DeleteObject,eax
		invoke EndPaint,hWin,addr ps
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

SetSatText:
	retn

GPSProc endp
