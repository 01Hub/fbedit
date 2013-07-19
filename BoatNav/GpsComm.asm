
IDD_DLGGPSSETUP			equ 1400
IDC_EDTCOMPORT			equ 1403
IDC_CBOBAUDRATE			equ 1404
IDC_CHKCOMACTIVE		equ 1405
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

szCOM1				BYTE 'COM1',0
szBaudRate			BYTE '4800',0
					BYTE '9600',0
					BYTE '19200',0
					BYTE '38400',0,0
szComFailed			BYTE 'Opening com port failed.',0

;NMEA Messages
szGPRMC				BYTE '$GPRMC',0
szGPGSV				BYTE '$GPGSV',0
szGPGGA				BYTE '$GPGGA',0
szGPGSA				BYTE '$GPGSA',0

szBinToDec			BYTE '%06d',0
szFmtTime			BYTE '%02d%02d%02d %02d:%02d:%02d',0
szColon				BYTE ': ',0

szFix				BYTE 'Fix:',0
szHDOP				BYTE 'HDOP:',0
szVDOP				BYTE 'VDOP:',0
szPDOP				BYTE 'PDOP:',0
szSatelites			BYTE 'Sat:',0
szAltitude			BYTE 'Alt:',0
szLattitude			BYTE 'Lattitude:',0
szLongitude			BYTE 'Longitude:',0
szBearing			BYTE 'Bearing:',0
szSpeed				BYTE 'Speed:',0
szNoFix				BYTE 'No fix',0
szFix2D				BYTE '2D',0
szFix3D				BYTE '3D',0

.data?

hFileLogRead		HANDLE ?
hFileLogWrite		HANDLE ?
npos				DWORD ?
COMPort				BYTE 16 dup(?)
BaudRate			BYTE 16 dup(?)
COMActive			DWORD ?
hCom				HANDLE ?
dcb					DCB <>
to					COMMTIMEOUTS <>
combuff				BYTE 4096 dup(?)
linebuff			BYTE 512 dup(?)
logbuff				BYTE 1024 dup(?)

.code

SendGPSData proc lpData:DWORD
	LOCAL	status:DWORD

	call	GetCheckSum
	.if hCom
		invoke strlen,lpData
		mov		edx,eax
		invoke WriteFile,hCom,lpData,edx,addr status,NULL
	.else
		.while mapdata.GPSInit==1
			invoke DoSleep,100
		.endw
		mov		status,1
		.while (status & 255)
			;Download Start status (first byte)
			invoke STLinkRead,hGPS,STM32_Sonar,addr status,4
			.if !eax || eax==IDABORT || eax==IDIGNORE
				jmp		STLinkErr
			.endif
		.endw
		invoke STLinkWrite,hGPS,STM32_Sonar+16+512,lpData,512
		.if !eax || eax==IDABORT || eax==IDIGNORE
			jmp		STLinkErr
		.endif
	 	mov		sonardata.Start,2
		invoke STLinkWrite,hGPS,STM32_Sonar,addr sonardata.Start,4
		.if !eax || eax==IDABORT || eax==IDIGNORE
			jmp		STLinkErr
		.endif
		.while TRUE
			invoke DoSleep,100
			;Download Start status (first byte)
			invoke STLinkRead,hGPS,STM32_Sonar,addr status,4
			.if !eax || eax==IDABORT || eax==IDIGNORE
				jmp		STLinkErr
			.endif
			.break .if !(status & 255)
		.endw
	.endif
	ret

STLinkErr:
	invoke PostMessage,hWnd,WM_CLOSE,0,0
	xor		eax,eax
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
	push	eax
	shr		eax,4
	.if eax>=0ah
		add		eax,'A'-0Ah
	.else
		or		eax,30h
	.endif
	mov		[edx+1],al
	pop		eax
	and		eax,0Fh
	.if eax>=0ah
		add		eax,'A'-0Ah
	.else
		or		eax,30h
	.endif
	mov		[edx+2],al
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

SendGPSData endp

SendGPSConfig proc
	LOCAL	buffer[512]:BYTE

	invoke RtlZeroMemory,addr buffer,sizeof buffer
	invoke strcpy,addr buffer,addr szGPSInitData
	.if mapdata.GPSReset
		invoke strcat,addr buffer,addr szGPSReset
		mov		mapdata.GPSReset,FALSE
	.endif
	invoke SendGPSData,addr buffer
	mov		mapdata.GPSInit,0
	ret

SendGPSConfig endp

OpenCom proc

	.if hCom
		invoke CloseHandle,hCom
		mov		hCom,0
	.endif
	.if COMActive
		; Setup
	  Retry:
		invoke CreateFile,addr COMPort,GENERIC_READ or GENERIC_WRITE,NULL,NULL,OPEN_EXISTING,NULL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov		hCom,eax
			mov		dcb.DCBlength,sizeof DCB
			invoke GetCommState,hCom,addr dcb
			invoke DecToBin,addr BaudRate
			mov		dcb.BaudRate,eax
			mov		dcb.ByteSize,8
			mov		dcb.Parity,NOPARITY
			mov		dcb.StopBits,ONESTOPBIT
			invoke SetCommState,hCom,addr dcb
			mov		to.ReadTotalTimeoutConstant,1
			mov		to.WriteTotalTimeoutConstant,10
			invoke SetCommTimeouts,hCom,addr to
			invoke SendGPSConfig
		.else
			invoke MessageBox,hWnd,addr szComFailed,addr COMPort,MB_ICONERROR or MB_ABORTRETRYIGNORE
			.if eax==IDABORT
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.elseif eax==IDRETRY
				jmp		Retry
			.endif
		.endif
	.else
		mov		mapdata.GPSInit,TRUE
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

GPSThread proc uses ebx esi edi,Param:DWORD
	LOCAL	nRead:DWORD
	LOCAL	nWrite:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	bufflog[256]:BYTE
	LOCAL	bufftime[32]:BYTE
	LOCAL	buffdate[32]:BYTE
	LOCAL	iLon:DWORD
	LOCAL	iLat:DWORD
	LOCAL	fDist:REAL10
	LOCAL	fBear:REAL10
	LOCAL	iTime:DWORD
	LOCAL	iSumDist:DWORD
	LOCAL	utcst:SYSTEMTIME
	LOCAL	localst:SYSTEMTIME
	LOCAL	fValid:DWORD
	LOCAL	GPSTail:DWORD
	LOCAL	nSatelites:DWORD
	LOCAL	SatPtr:DWORD
	LOCAL	tmp:DWORD

	mov		GPSTail,0
	invoke DoSleep,2000
	invoke OpenCom
	.while  !fExitGPSThread
		.if !mapdata.gpslogpause
			.if hFileLogRead
				.if !mapdata.gpslogpause
					invoke ReadFile,hFileLogRead,addr combuff,1024,addr nRead,NULL
					.if !nRead
						invoke CloseHandle,hFileLogRead
						mov		hFileLogRead,0
						mov		npos,0
						fldz
						fstp	fDist
						fldz
						fstp	mapdata.fSumDist
						mov		mapdata.ntrail,0
						mov		mapdata.trailhead,0
						mov		mapdata.trailtail,0
						invoke SetDlgItemText,hControls,IDC_STCDIST,addr szNULL
					.else
						.if !mapdata.ntrail
							fldz
							fstp	mapdata.fSumDist
						.endif
						invoke strlen,addr combuff
						lea		eax,[eax+1]
						add		npos,eax
						invoke SetFilePointer,hFileLogRead,npos,NULL,FILE_BEGIN
						xor		ebx,ebx
						call	GPSExec
						invoke DoSleep,100
					.endif
				.endif
				mov		nRead,0
			.elseif hCom && !sonardata.hReplay
				xor		ebx,ebx
			  COMGetMore:
				.if hCom
			 		invoke ReadFile,hCom,addr combuff[ebx],256,addr nRead,NULL
			 		mov		eax,nRead
			 		.if eax
				 		add		ebx,eax
				 		and		ebx,(sizeof combuff/2)-1
				 		mov		combuff[ebx],0
				 		invoke Sleep,10
				 		jmp		COMGetMore
			 		.endif
			 		.if combuff
			 			xor		ebx,ebx
						call	GPSExec
						mov		combuff,0
			 		.endif
				.endif
			.elseif mapdata.fSTLink && mapdata.fSTLink!=IDIGNORE && !sonardata.hReplay
				.if mapdata.GPSInit
					xor		edi,edi
					.while edi<3
						invoke STLinkRead,hGPS,STM32_Sonar+16+sizeof SONAR.EchoArray+sizeof SONAR.GainArray+sizeof SONAR.GainInit,addr buffer,256
						xor		ebx,ebx
						mov		eax,-1
						.while ebx<250 && buffer[ebx]!=0
							invoke strcmpn,addr buffer[ebx],addr szGPRMC,6
							.break .if !eax
							inc		ebx
						.endw
						.break .if !eax
						invoke DoSleep,1000
						inc		edi
					.endw
					.if !eax
						invoke RtlZeroMemory,addr buffer,sizeof buffer
						invoke strcpy,addr buffer,offset szSetBaud
						invoke SendGPSData,addr buffer
						invoke DoSleep,100
					.endif
					mov		tmp,1
					.while (tmp & 255)
						;Download Start status (first byte)
						invoke STLinkRead,hGPS,STM32_Sonar,addr tmp,4
						.if !eax || eax==IDABORT || eax==IDIGNORE
							jmp		STLinkErr
						.endif
					.endw
				 	mov		sonardata.Start,3
					invoke STLinkWrite,hGPS,STM32_Sonar,addr sonardata.Start,4
					invoke DoSleep,100
					invoke SendGPSConfig
				.endif
				xor		ebx,ebx
			  STMGetMore:
				;Download ADCAirTemp and GPSHead
				invoke STLinkRead,hGPS,STM32_Sonar+12,addr tmp,4
				.if !eax || eax==IDABORT || eax==IDIGNORE
					jmp		STLinkErr
				.endif
				mov		edi,tmp
				shr		edi,16
				.if edi!=GPSTail
					mov		edx,GPSTail
					and		edx,sizeof SONAR.GPSArray-4
					.if edi>GPSTail
						mov		eax,edi
						shr		eax,2
						inc		eax
						shl		eax,2
						sub		eax,edx
						invoke STLinkRead,hGPS,addr [STM32_Sonar+16+sizeof SONAR.EchoArray+sizeof SONAR.GainArray+sizeof SONAR.GainInit+edx],addr sonardata.GPSArray[edx],eax
					.else
						;Buffer rollover
						mov		eax,512
						sub		eax,edx
						invoke STLinkRead,hGPS,addr [STM32_Sonar+16+sizeof SONAR.EchoArray+sizeof SONAR.GainArray+sizeof SONAR.GainInit+edx],addr sonardata.GPSArray[edx],eax
						mov		eax,edi
						shr		eax,2
						inc		eax
						shl		eax,2
						invoke STLinkRead,hGPS,STM32_Sonar+16+sizeof SONAR.EchoArray+sizeof SONAR.GainArray+sizeof SONAR.GainInit,addr sonardata.GPSArray,eax
					.endif
					.if !eax || eax==IDABORT || eax==IDIGNORE
						jmp		STLinkErr
					.endif
					mov		esi,GPSTail
					mov		GPSTail,edi
					.while esi!=edi
						mov		al,sonardata.GPSArray[esi]
						mov		combuff[ebx],al
						inc		esi
						and		esi,sizeof SONAR.GPSArray-1
						inc		ebx
					.endw
					mov		combuff[ebx],0
					invoke DoSleep,150
					jmp		STMGetMore
				.endif
				xor		ebx,ebx
				call	GPSExec
			.elseif !sonardata.hReplay
				invoke strcpy,addr combuff,addr szGPSDemoData
				xor		ebx,ebx
				call	GPSExec
				invoke DoSleep,900
			.endif
		.endif
		invoke DoSleep,100
	.endw
	.if hFileLogRead
		invoke CloseHandle,hFileLogRead
		mov		hFileLogRead,0
	.endif
	.if hFileLogWrite
		invoke CloseHandle,hFileLogWrite
		mov		hFileLogWrite,0
	.endif
	mov		fExitGPSThread,2
	xor		eax,eax
	ret

STLinkErr:
	invoke PostMessage,hWnd,WM_CLOSE,0,0
	xor		eax,eax
	ret

GPSExec:
	.if combuff[ebx]
		invoke GetLine,ebx
		.if eax
			add		ebx,eax
			push	ebx
			;Update NMEA logg
			invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_GETCOUNT,0,0
			mov		ebx,eax
			.if eax>MAXNMEA
				invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_DELETESTRING,0,0
				dec		ebx
			.endif
			invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_ADDSTRING,0,offset linebuff
			invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_SETTOPINDEX,ebx,0
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
					invoke GetItemInt,addr linebuff,0			;Number of Messages
					invoke GetItemInt,addr linebuff,0			;Message number
					push	eax
					invoke GetItemInt,addr linebuff,0			;Satellites in View
					pop		edx
					.if edx==1
						mov		nSatelites,eax
						mov		SatPtr,0
						mov		ebx,12
						sub		ebx,nSatelites
						mov		edi,sizeof SATELITE*11
						.while ebx
							mov		satelites.SatelliteID[edi],0
							lea		edi,[edi-sizeof SATELITE]
							dec		ebx
						.endw
					.endif
					xor		ebx,ebx
					mov		edi,SatPtr
					.while nSatelites && ebx<4
						invoke GetItemInt,addr linebuff,0			;Satellite ID
						mov		satelites.SatelliteID[edi],al
						invoke GetItemInt,addr linebuff,0			;Elevation
						mov		satelites.Elevation[edi],al
						invoke GetItemInt,addr linebuff,0			;Azimuth
						mov		satelites.Azimuth[edi],ax
						invoke GetItemInt,addr linebuff,0			;SNR
						mov		satelites.SNR[edi],al
						lea		edi,[edi+sizeof SATELITE]
						inc		ebx
						dec		nSatelites
					.endw
					mov		SatPtr,edi
					.if !nSatelites
						invoke InvalidateRect,hGPS,NULL,TRUE
					.endif
				.else
					invoke strcmp,addr buffer,addr szGPGGA
					.if !eax
						;UTC time
						invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
						;Lat
						invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
						invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
						;Lon
						invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
						invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
						;Fix quality
						invoke GetItemInt,addr linebuff,0
						;Number of satelites
						invoke GetItemInt,addr linebuff,0
						mov		altitude.nsat,al
						;HDOP
						invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
						;Altitude
						invoke GetItemInt,addr linebuff,0
						mov		altitude.alt,ax
						invoke InvalidateRect,hGPS,NULL,TRUE
					.else
						invoke strcmp,addr buffer,addr szGPGSA
						.if !eax
							;Mode M or A
							invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
							;Mode 1=No fix,2=2D or 3=3D
							invoke GetItemInt,addr linebuff,0
							mov		altitude.fixquality,al
							xor		ebx,ebx
							xor		edi,edi
							.while ebx<12
								mov		satelites.Fixed[edi],FALSE
								lea		edi,[edi+sizeof SATELITE]
								inc		ebx
							.endw
							xor		ebx,ebx
							.while ebx<12
								invoke GetItemInt,addr linebuff,0
								.if eax
									push	ebx
									xor		ebx,ebx
									xor		edi,edi
									.while ebx<12
										.if al==satelites.SatelliteID[edi]
											mov		satelites.Fixed[edi],TRUE
										  .break
										.endif
										lea		edi,[edi+sizeof SATELITE]
										inc		ebx
									.endw
									pop		ebx
								.endif
								inc		ebx
							.endw
							;HDOP
							invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
							lea		esi,buffer
							mov		edi,esi
							mov		edx,esi
							.while byte ptr [esi]
								mov		al,[esi]
								.if al!='.'
									mov		[edi],al
									inc		edi
								.else
									lea		edx,[edi+1]
								.endif
								inc		esi
							.endw
							mov		byte ptr [edx],0
							invoke DecToBin,addr buffer
							mov		altitude.hdop,ax
							;VDOP
							invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
							lea		esi,buffer
							mov		edi,esi
							mov		edx,esi
							.while byte ptr [esi]
								mov		al,[esi]
								.if al!='.'
									mov		[edi],al
									inc		edi
								.else
									lea		edx,[edi+1]
								.endif
								inc		esi
							.endw
							mov		byte ptr [edx],0
							invoke DecToBin,addr buffer
							mov		altitude.vdop,ax
							;PDOP
							invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
							lea		esi,buffer
							mov		edi,esi
							mov		edx,esi
							.while byte ptr [esi]
								mov		al,[esi]
								.if al!='.'
									mov		[edi],al
									inc		edi
								.else
									lea		edx,[edi+1]
								.endif
								inc		esi
							.endw
							mov		byte ptr [edx],0
							invoke DecToBin,addr buffer
							mov		altitude.pdop,ax
							invoke InvalidateRect,hGPS,NULL,TRUE
						.endif
					.endif
				.endif
			.endif
			.if hFileLogWrite && !mapdata.gpslogpause
				invoke strlen,addr logbuff
				lea		edx,[eax+1]
				invoke WriteFile,hFileLogWrite,addr logbuff,edx,addr nWrite,NULL
			.endif
			.if !hFileLogRead
				mov		npos,0
			.endif
			mov		logbuff,0
			mov		combuff,0
			.if (!mapdata.bdist || mapdata.bdist==2) && (!mapdata.btrip || mapdata.btrip==2)
				invoke DoGoto,mapdata.iLon,mapdata.iLat,mapdata.gpslock,TRUE
				invoke SetDlgItemInt,hControls,IDC_STCLON,mapdata.iLon,TRUE
				invoke SetDlgItemInt,hControls,IDC_STCLAT,mapdata.iLat,TRUE
				inc		mapdata.paintnow
				invoke InvalidateRect,hGPS,NULL,TRUE
			.endif
			pop		ebx
			jmp		GPSExec
		.endif
	.endif
	retn

PositionSpeedDirection:
	mov		eax,mapdata.iLon
	mov		iLon,eax
	mov		eax,mapdata.iLat
	mov		iLat,eax
	;Time
	invoke GetItemStr,addr linebuff,addr szNULL,addr bufftime,32
	;Status
	invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
	.if buffer=='A'
		or		mapdata.fcursor,2
		mov		fValid,TRUE
	.else
		and		mapdata.fcursor,1
		mov		fValid,FALSE
	.endif
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
		mov		mapdata.iLat,eax
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
		mov		mapdata.iLon,eax
		;Speed
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke strlen,addr buffer
		.while buffer[eax]!='.' && eax
			dec		eax
		.endw
		mov		buffer[eax+2],0
		mov		ecx,dword ptr buffer[eax+1]
		mov		dword ptr buffer[eax],ecx
		invoke DecToBin,addr buffer
		mov		mapdata.iSpeed,eax
		invoke wsprintf,addr buffer,addr szFmtDec2,mapdata.iSpeed
		invoke strlen,addr buffer
		movzx	ecx,word ptr buffer[eax-1]
		shl		ecx,8
		mov		cl,'.'
		mov		dword ptr buffer[eax-1],ecx
		invoke strcpy,addr mapdata.options.text,addr buffer
		;Bearing
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		invoke DecToBin,addr buffer
		mov		mapdata.iBear,eax
		invoke SetGPSCursor
	.else
		;Lattitude
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		;N/S
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		;Longitude
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		;E/W
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		;Speed
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
		;Bearing
		invoke GetItemStr,addr linebuff,addr szNULL,addr buffer,32
	.endif
	mov		iTime,0
	;Date
	invoke GetItemStr,addr linebuff,addr szNULL,addr buffdate,32
	;YYYY YYYM MMMD DDDD
	;0010 0100 0000 0000 0000 0000 0001 1111
	;Get year
	invoke DecToBin,addr buffdate[4]
	mov		edx,eax
	add		edx,2000
	mov		utcst.wYear,dx
	mov		buffdate[4],0
	shl		eax,9
	or		iTime,eax
	;Get month
	invoke DecToBin,addr buffdate[2]
	mov		utcst.wMonth,ax
	mov		buffdate[2],0
	shl		eax,5
	or		iTime,eax
	;Get day
	invoke DecToBin,addr buffdate
	mov		utcst.wDayOfWeek,0
	mov		utcst.wDay,ax
	or		iTime,eax
	shl		iTime,16
	;HHHH HMMM MMS SSSS
	;Get seconds
	invoke DecToBin,addr bufftime[4]
	mov		utcst.wMilliseconds,0
	mov		utcst.wSecond,ax
	mov		bufftime[4],0
	shr		eax,1
	or		iTime,eax
	;Get minutes
	invoke DecToBin,addr bufftime[2]
	mov		utcst.wMinute,ax
	mov		bufftime[2],0
	shl		eax,5
	or		iTime,eax
	;Get hours
	invoke DecToBin,addr bufftime
	mov		utcst.wHour,ax
	shl		eax,11
	or		iTime,eax
	mov		eax,iTime
	mov		mapdata.iTime,eax
	invoke SystemTimeToTzSpecificLocalTime,NULL,addr utcst,addr localst
	mov		ebx,esp
	movzx	eax,localst.wSecond
	push	eax
	movzx	eax,localst.wMinute
	push	eax
	movzx	eax,localst.wHour
	push	eax
	movzx	eax,localst.wYear
	sub		eax,2000
	push	eax
	movzx	eax,localst.wMonth
	push	eax
	movzx	eax,localst.wDay
	push	eax
	push	offset szFmtTime
	lea		eax,mapdata.options.text[sizeof OPTIONS*4]
	push	eax
	call	wsprintf
	mov		esp,ebx
	.if fValid
		invoke AddTrailPoint,mapdata.iLon,mapdata.iLat,mapdata.iBear,mapdata.iTime,mapdata.iSpeed
		.if mapdata.ntrail
			mov		eax,mapdata.iLon
			mov		edx,mapdata.iLat
			.if eax!=iLon || edx!=iLat
				invoke BearingDistanceInt,iLon,iLat,mapdata.iLon,mapdata.iLat,addr fDist,addr fBear
				fld		fDist
				fld		mapdata.fSumDist
				faddp	st(1),st(0)
				fst		st(1)
				lea		eax,mapdata.fSumDist
				fstp	REAL10 PTR [eax]
				lea		eax,iSumDist
				fistp	dword ptr [eax]
				invoke SetDlgItemInt,hControls,IDC_STCDIST,iSumDist,FALSE
				invoke SetDlgItemInt,hControls,IDC_STCBEARING,mapdata.iBear,FALSE
			.endif
		.endif
		inc		mapdata.ntrail
	.endif
	retn

GPSThread endp

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
				invoke GetDlgItemText,hWin,IDC_EDTCOMPORT,addr COMPort,6
				invoke SendDlgItemMessage,hWin,IDC_CBOBAUDRATE,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOBAUDRATE,CB_GETLBTEXT,eax,addr BaudRate
				invoke IsDlgButtonChecked,hWin,IDC_CHKCOMACTIVE
				mov		COMActive,eax
				invoke IsDlgButtonChecked,hWin,IDC_CHKRESET
				mov		mapdata.GPSReset,eax
				invoke SaveGPSToIni
				invoke OpenCom
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
			.if satelites.SatelliteID[edi]
				;This would be the right way but gives poor graphic representation of the elevation angle.
				;invoke GetPointOnCircle,SATRAD,satelites.Elevation[edi],addr pt
				;mov		ecx,pt.x
				;A linear function of the elevation angle gives better graphic representation
				mov		eax,90
				movsx	edx,satelites.Elevation[edi]
				sub		eax,edx
				mov		ecx,SATRAD
				mul		ecx
				mov		ecx,180/2
				div		ecx
				mov		ecx,eax
				movzx	edx,satelites.Azimuth[edi]
				; North is 0 deg, sub 90 deg
				sub		edx,90
				invoke GetPointOnCircle,ecx,edx,addr pt
				mov		eax,ptcenter.x
				sub		eax,8
				add		pt.x,eax
				mov		eax,ptcenter.y
				sub		eax,8
				add		pt.y,eax
				movzx	eax,satelites.SatelliteID[edi]
				invoke wsprintf,addr buffer,addr szFmtDec2,eax
				invoke strcat,addr buffer,addr szColon
				movzx	eax,satelites.SNR[edi]
				invoke wsprintf,addr buffer[4],addr szFmtDec2,eax
				invoke strcat,addr buffer,addr szColon+1
				movsx	eax,satelites.Elevation[edi]
				invoke wsprintf,addr buffer[7],addr szFmtDec2,eax
				invoke strcat,addr buffer,addr szColon+1
				movzx	eax,satelites.Azimuth[edi]
				invoke wsprintf,addr buffer[10],addr szFmtDec3,eax
				.if satelites.SNR[edi]
					.if satelites.Fixed[edi]
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
				movzx	edx,satelites.SNR[edi]
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
		movzx	eax,altitude.fixquality
		.if eax==2
			invoke TextOut,mDC,esi,5,addr szFix2D,2
		.elseif eax==3
			invoke TextOut,mDC,esi,5,addr szFix3D,2
		.else
			invoke TextOut,mDC,esi,5,addr szNoFix,6
		.endif
		movzx	eax,altitude.nsat
		invoke wsprintf,addr buffer,addr szFmtDec,eax
		invoke strlen,addr buffer
		invoke TextOut,mDC,esi,15,addr buffer,eax
		movzx	eax,altitude.hdop
		mov		ebx,25
		call	PrintDOP
		movzx	eax,altitude.vdop
		mov		ebx,35
		call	PrintDOP
		movzx	eax,altitude.pdop
		mov		ebx,45
		call	PrintDOP
		movsx	eax,altitude.alt
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
