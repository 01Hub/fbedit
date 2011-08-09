
IDD_DLGSONAR            equ 1500
IDC_TRBSONARGAIN        equ 1504
IDC_CHKSONARGAIN        equ 1503
IDC_TRBSONARPING        equ 1510
IDC_CHKSONARPING        equ 1509
IDC_TRBSONARRANGE       equ 1507
IDC_CHKSONARRANGE       equ 1506
IDC_TRBSONARCHART       equ 1512
IDC_CHKSOPNARCHART		equ 1523
IDC_CHKSONARDETECT      equ 1515
IDC_TRBSONARNOISE       equ 1501
IDC_CHKSONARNOISE		equ 1521
IDC_CHKSONARALARM       equ 1514
IDC_TRBPINGTIMER        equ 1526
IDC_BTNGD               equ 1502
IDC_BTNGU               equ 1505
IDC_BTNPU               equ 1508
IDC_BTNPD               equ 1511
IDC_BTNRU               equ 1513
IDC_BTNRD               equ 1516
IDC_BTNCU               equ 1517
IDC_BTNCD               equ 1518
IDC_BTNNU               equ 1519
IDC_BTNND               equ 1520
IDC_BTNPTU              equ 1525
IDC_BTNPTD              equ 1527

.code

GetRangePtr proc uses edx,RangeInx:DWORD

	mov		eax,RangeInx
	mov		edx,sizeof RANGE
	mul		edx
	ret

GetRangePtr endp

SetRange proc uses ebx,RangeInx:DWORD

	mov		eax,RangeInx
	mov		sonardata.RangeInx,al
	invoke GetRangePtr,eax
	mov		ebx,eax
	mov		eax,sonarrange.nsample[ebx]
	mov		sonardata.nSample,al
	mov		eax,sonarrange.range[ebx]
	mov		sonardata.RangeVal,eax
	invoke wsprintf,addr sonardata.options.text,addr szFmtDec,eax
	ret

SetRange endp

SonarOptionProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		.if sonardata.AutoRange
			invoke CheckDlgButton,hWin,IDC_CHKSONARRANGE,BST_CHECKED
		.endif
		mov		eax,sonardata.MaxRange
		dec		eax
		shl		eax,16
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARRANGE,TBM_SETRANGE,FALSE,eax
		movzx	eax,sonardata.RangeInx
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARRANGE,TBM_SETPOS,TRUE,eax
		.if sonardata.AutoGain
			invoke CheckDlgButton,hWin,IDC_CHKSONARGAIN,BST_CHECKED
		.endif
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARGAIN,TBM_SETRANGE,FALSE,(255 SHL 16)+0
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARGAIN,TBM_SETPOS,TRUE,sonardata.GainInit
		.if sonardata.AutoPing
			invoke CheckDlgButton,hWin,IDC_CHKSONARPING,BST_CHECKED
		.endif
		.if sonardata.NoiseReject
			invoke CheckDlgButton,hWin,IDC_CHKSONARNOISE,BST_CHECKED
		.endif
		.if sonardata.ChartSync
			invoke CheckDlgButton,hWin,IDC_CHKSOPNARCHART,BST_CHECKED
		.endif
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARPING,TBM_SETRANGE,FALSE,(127 SHL 16)+1
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARPING,TBM_SETPOS,TRUE,sonardata.PingInit
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARNOISE,TBM_SETRANGE,FALSE,(255 SHL 16)+1
		movzx	eax,sonardata.Noise
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARNOISE,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETRANGE,FALSE,(100 SHL 16)+1
		mov		eax,sonardata.ChartSpeed
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETPOS,TRUE,eax
		.if sonardata.FishDetect
			invoke CheckDlgButton,hWin,IDC_CHKSONARDETECT,BST_CHECKED
		.endif
		.if sonardata.FishAlarm
			invoke CheckDlgButton,hWin,IDC_CHKSONARALARM,BST_CHECKED
		.endif
		invoke SendDlgItemMessage,hWin,IDC_TRBPINGTIMER,TBM_SETRANGE,FALSE,(144 SHL 16)+134
		movzx	eax,sonardata.PingTimer
		invoke SendDlgItemMessage,hWin,IDC_TRBPINGTIMER,TBM_SETPOS,TRUE,eax
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SendMessage,hWin,WM_CLOSE,NULL,FALSE
			.elseif eax==IDC_CHKSONARGAIN
				xor		sonardata.AutoGain,1
			.elseif eax==IDC_CHKSONARPING
				xor		sonardata.AutoPing,1
			.elseif eax==IDC_CHKSONARRANGE
				xor		sonardata.AutoRange,1
			.elseif eax==IDC_CHKSONARNOISE
				xor		sonardata.NoiseReject,1
			.elseif eax==IDC_CHKSOPNARCHART
				xor		sonardata.ChartSync,1
			.elseif eax==IDC_CHKSONARDETECT
				xor		sonardata.FishDetect,1
			.elseif eax==IDC_CHKSONARALARM
				xor		sonardata.FishAlarm,1
			.elseif eax==IDC_BTNGD
				.if sonardata.GainInit
					dec		sonardata.GainInit
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARGAIN,TBM_SETPOS,TRUE,sonardata.GainInit
				.endif
			.elseif eax==IDC_BTNGU
				.if sonardata.GainInit<255
					inc		sonardata.GainInit
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARGAIN,TBM_SETPOS,TRUE,sonardata.GainInit
				.endif
			.elseif eax==IDC_BTNPD
				.if sonardata.PingInit>1
					dec		sonardata.PingInit
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARPING,TBM_SETPOS,TRUE,sonardata.PingInit
				.endif
			.elseif eax==IDC_BTNPU
				.if sonardata.PingInit<127
					inc		sonardata.PingInit
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARPING,TBM_SETPOS,TRUE,sonardata.PingInit
				.endif
			.elseif eax==IDC_BTNRD
				.if sonardata.RangeInx
					dec		sonardata.RangeInx
					movzx	eax,sonardata.RangeInx
					invoke SetRange,eax
					movzx	eax,sonardata.RangeInx
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARRANGE,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNRU
				mov		eax,sonardata.MaxRange
				dec		eax
				.if al>sonardata.RangeInx
					inc		sonardata.RangeInx
					movzx	eax,sonardata.RangeInx
					invoke SetRange,eax
					movzx	eax,sonardata.RangeInx
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARRANGE,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNCD
				.if sonardata.ChartSpeed
					dec		sonardata.ChartSpeed
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETPOS,TRUE,sonardata.ChartSpeed
				.endif
			.elseif eax==IDC_BTNCU
				.if sonardata.ChartSpeed<100
					inc		sonardata.ChartSpeed
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETPOS,TRUE,sonardata.ChartSpeed
				.endif
			.elseif eax==IDC_BTNND
				.if sonardata.Noise
					dec		sonardata.Noise
					movzx	eax,sonardata.Noise
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARNOISE,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNNU
				.if sonardata.Noise<255
					inc		sonardata.Noise
					movzx	eax,sonardata.Noise
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARNOISE,TBM_SETPOS,TRUE,eax
				.endif
			.endif
		.endif
	.elseif eax==WM_HSCROLL
		invoke SendMessage,lParam,TBM_GETPOS,0,0
		mov		ebx,eax
		invoke GetDlgCtrlID,lParam
		.if eax==IDC_TRBSONARGAIN
			mov		sonardata.GainInit,ebx
		.elseif eax==IDC_TRBSONARRANGE
			mov		sonardata.RangeInx,bl
			invoke SetRange,ebx
		.elseif eax==IDC_TRBSONARNOISE
			mov		sonardata.Noise,bl
		.elseif eax==IDC_TRBSONARPING
			mov		sonardata.PingInit,ebx
		.elseif eax==IDC_TRBSONARCHART
			mov		sonardata.ChartSpeed,ebx
		.elseif eax==IDC_TRBPINGTIMER
			mov		sonardata.PingTimer,bl
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,lParam
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

SonarOptionProc endp

Random proc uses ecx edx,range:DWORD

	mov		eax,rseed
	mov		ecx,23
	mul		ecx
	add		eax,7
	and		eax,0FFFFFFFFh
	ror		eax,1
	xor		eax,rseed
	mov		rseed,eax
	mov		ecx,range
	xor		edx,edx
	div		ecx
	mov		eax,edx
	ret

Random endp

;Description
;===========
;A short ping at 200KHz is transmitted at intervalls depending on range.
;From the time it takes for the echo to return we can calculate the depth.
;The adc measures the strenght of the echo at intervalls depending on range
;and stores it in a 512 byte array.
;
;Speed of sound in water
;=======================
;Temp (C)    Speed (m/s)
;  0             1403
;  5             1427
; 10             1447
; 20             1481
; 30             1507
; 40             1526
;
;1450m/s is probably a good estimate.
;
;The timer is clocked at 48MHz so it increments every 0,0208333 us.
;For each tick the sound travels 1450 * 0,0208333 = 30,208285 um or 30,208285e-6 meters.

;Timer value calculation
;=======================
;Example 2m range and 48MHz clock
;Timer period Tp=1/48MHz
;Each pixel is Px=2m/512.
;Time for each pixel is t=Px/1450/2
;Timer ticks Tt=t/Tp

;Formula T=((Range/512)/(1450/2))*48000000

;RangeToTimer proc RangeInx:DWORD
;	LOCAL	tmp:DWORD
;
;	mov		eax,RangeInx
;	lea		eax,[eax+eax*2]
;	mov		eax,sonarrange.range[eax*4]
;	mov		tmp,eax
;	fild	tmp
;	mov		tmp,MAXYECHO
;	fild	tmp
;	fdivp	st(1),st
;	mov		tmp,1450/2			;Divide by 2 since it is the echo
;	fild	tmp
;	fdivp	st(1),st
;	mov		tmp,48000000
;	fild	tmp
;	fmulp	st(1),st
;	fistp	tmp
;	mov		eax,tmp
;	dec		eax
;	ret
;
;RangeToTimer endp

UpdateBitmapTile proc uses ebx esi edi,x:DWORD,wt:DWORD,NewRange:DWORD
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC
	LOCAL	rect:RECT

	invoke GetDC,hSonar
	mov		hDC,eax
	invoke CreateCompatibleDC,hDC
	mov		mDC,eax
	invoke CreateCompatibleBitmap,hDC,wt,MAXYECHO
	invoke SelectObject,mDC,eax
	push	eax
	invoke ReleaseDC,hSonar,hDC
	mov		rect.left,0
	mov		rect.top,0
	mov		eax,wt
	mov		rect.right,eax
	mov		rect.bottom,MAXYECHO
	invoke FillRect,mDC,addr rect,sonardata.hBrBack
	xor		esi,esi
	.while esi<wt
		xor		edi,edi
		.while edi<MAXYECHO
			mov		eax,MAXYECHO
			mov		edx,esi
			add		edx,x
			mul		edx
			movzx	eax,sonardata.sonar[eax+edi]
			.if eax
				xor		eax,0FFh
				mov		ah,al
				shl		eax,8
				mov		al,ah
				invoke SetPixel,mDC,esi,edi,eax
			.endif
			inc		edi
		.endw
		inc		esi
	.endw
	mov		eax,x
	mov		edx,MAXYECHO
	mul		edx
	movzx	eax,sonardata.sonar[eax]
	invoke GetRangePtr,eax
	mov		ecx,sonarrange.range[eax]
	mov		eax,MAXYECHO
	mul		ecx
	mov		ecx,NewRange
	div		ecx
	invoke StretchBlt,sonardata.mDC,x,0,wt,eax,mDC,0,0,wt,MAXYECHO,SRCCOPY
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	invoke DeleteDC,mDC
	ret

UpdateBitmapTile endp

UpdateBitmap proc uses ebx esi,NewRange:DWORD
	LOCAL	rect:RECT

	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,MAXXECHO
	mov		rect.bottom,MAXYECHO
	invoke FillRect,sonardata.mDC,addr rect,sonardata.hBrBack
	xor		esi,esi
	.while esi<MAXXECHO
		mov		eax,MAXYECHO
		mul		esi
		movzx	ebx,sonardata.sonar[eax]
		mov		ecx,esi
		.while ecx<MAXXECHO
			inc		ecx
			mov		eax,MAXYECHO
			mul		ecx
			movzx	eax,sonardata.sonar[eax]
			.break .if eax!=ebx
		.endw
		push	ecx
		sub		ecx,esi
		invoke UpdateBitmapTile,esi,ecx,NewRange
		pop		esi
	.endw
	ret

UpdateBitmap endp

STM32Thread proc uses ebx esi edi,lParam:DWORD
	LOCAL	status:DWORD
	LOCAL	STM32Echo[MAXYECHO*2]:BYTE
	LOCAL	fish[MAXFISH]:BYTE
	LOCAL	dwread:DWORD
	LOCAL	dwwrite:DWORD
	LOCAL	buffer[16]:BYTE
	LOCAL	pixcnt:DWORD
	LOCAL	pixdir:DWORD
	LOCAL	pixmov:DWORD
	LOCAL	pixdpt:DWORD
	LOCAL	rngchanged:DWORD

	mov		pixcnt,0
	mov		pixdir,0
	mov		pixmov,0
	mov		pixdpt,250
	mov		rngchanged,3
	invoke RtlZeroMemory,addr STM32Echo,sizeof STM32Echo
	invoke RtlZeroMemory,addr fish,sizeof fish
  Again:
	.if sonardata.hReply
		;Copy old echo
		invoke RtlMoveMemory,addr STM32Echo[MAXYECHO],addr STM32Echo,MAXYECHO
		;Read echo from file
		invoke ReadFile,sonardata.hReply,addr STM32Echo,MAXYECHO,addr dwread,NULL
		.if dwread!=MAXYECHO
			invoke CloseHandle,sonardata.hReply
			mov		sonardata.hReply,0
			jmp		Again
		.endif
		movzx	eax,sonardata.STM32Echo
		invoke SetRange,eax
	.elseif fSTLink && fSTLink!=IDIGNORE
		;Download Start status (first byte)
		invoke STLinkRead,hWnd,STM32_Sonar,addr status,4
		.if !eax
			jmp		STLinkErr
		.endif
		.if !(status & 255)
			;Download ADCBattery, ADCWaterTemp and ADCAirTemp
			invoke STLinkRead,hWnd,STM32_Sonar+8,addr sonardata.dmy1,8
			.if !eax
				jmp		STLinkErr
			.endif
			;Copy old echo
			invoke RtlMoveMemory,addr STM32Echo[MAXYECHO],addr STM32Echo,MAXYECHO
			;Download sonar echo array
			invoke STLinkRead,hWnd,STM32_Sonar+16,addr STM32Echo,MAXYECHO
			.if !eax
				jmp		STLinkErr
			.endif
		 	;Upload Start, PingPulses, Noise, Gain, GainInc, RangeInx, nSample and Timer to init the next reading
			movzx	ebx,STM32Echo
			invoke GetRangePtr,ebx
			mov		ebx,eax
			.if sonardata.AutoGain
				mov		eax,sonardata.GainInit
				add		eax,sonarrange.gainadd[ebx]
				.if eax>255
					mov		eax,255
				.endif
				mov		sonardata.Gain,al
				mov		eax,sonarrange.gaininc[ebx]
				mov		sonardata.GainInc,al
			.else
				mov		eax,sonardata.GainInit
				mov		sonardata.Gain,al
				mov		sonardata.GainInc,0
			.endif
			mov		eax,sonardata.PingInit
			.if sonardata.AutoPing
				add		eax,sonarrange.pingadd[ebx]
				.if eax>127
					mov		eax,127
				.endif
			.endif
			shl		eax,1
			mov		sonardata.Ping,al
		 	mov		sonardata.Start,0
			invoke STLinkWrite,hWnd,STM32_Sonar,addr sonardata.Start,12
			.if !eax
				jmp		STLinkErr
			.endif
			;Start the next phase
		 	mov		sonardata.Start,1
			invoke STLinkWrite,hWnd,STM32_Sonar,addr sonardata.Start,12
			.if !eax
				jmp		STLinkErr
			.endif
		.else
			;Data not ready yet
			invoke Sleep,10
			jmp		Again
		.endif
	.elseif fSTLink==IDIGNORE
		;Copy old echo
		invoke RtlMoveMemory,addr STM32Echo[MAXYECHO],addr STM32Echo,MAXYECHO
		;Clear echo
		xor		eax,eax
		lea		edi,STM32Echo
		mov		ecx,MAXYECHO/4
		rep		stosd
		;Set range index
		movzx	eax,sonardata.RangeInx
		mov		STM32Echo,al
		;Show ping
		invoke GetRangePtr,eax
		mov		ecx,sonarrange.nsample[eax]
		mov		eax,100
		xor		edx,edx
		div		ecx
		.if !eax
			inc		eax
		.endif
		push	eax
		mov		edx,eax
		.while edx
			invoke Random,64
			add		eax,150
			mov		STM32Echo[edx],al
			dec		edx
		.endw
		.if !(pixcnt & 63)
			;Random direction
			invoke Random,8
			mov		pixdir,eax
		.endif
		.if !(pixcnt & 31)
			;Random move
			invoke Random,4
			mov		pixmov,eax
		.endif
		mov		ebx,pixdpt
		mov		eax,pixdir
		.if eax<=1 && ebx>100
			;Up
			sub		ebx,pixmov
		.elseif eax>=3 && ebx<15000
			;Down
			add		ebx,pixmov
		.endif
		mov		pixdpt,ebx
		inc		pixcnt
		mov		eax,ebx
		mov		ecx,1024
		mul		ecx
		push	eax
		;Get current range index
		movzx	eax,STM32Echo
		invoke GetRangePtr,eax
		mov		ecx,sonarrange.range[eax]
		pop		eax
		xor		edx,edx
		div		ecx
		mov		ecx,100
		xor		edx,edx
		div		ecx
		mov		ebx,eax
		pop		edx
		shl		edx,1
		xor		ecx,ecx
		.while ecx<edx
			;Random echo
			invoke Random,100
			.if ebx<MAXYECHO
				add		eax,100
				mov		STM32Echo[ebx],al
			.endif
			inc		ebx
			inc		ecx
		.endw
		invoke Random,ebx
		.if eax>100 && eax<MAXYECHO
			mov		edx,eax
			invoke Random,255
			.if eax>124 && eax<130
				;Random fish
				mov		STM32Echo[edx],al
			.endif
		.endif
		mov		sonardata.ADCBattery,0810h
		mov		sonardata.ADCWaterTemp,0980h
	.endif
	.if sonardata.hLog
		;Write to log file
		invoke WriteFile,sonardata.hLog,addr STM32Echo,MAXYECHO,addr dwwrite,NULL
	.endif
	mov		ecx,MAXFISH-1
	.while ecx
		mov		al,fish[ecx-1]
		mov		fish[ecx],al
		dec		ecx
	.endw
	mov		fish,0
	;Get range index
	mov		al,STM32Echo
	mov		sonardata.STM32Echo,al
	.if al!=STM32Echo[MAXYECHO]
		invoke RtlMoveMemory,addr STM32Echo[MAXYECHO],addr STM32Echo,MAXYECHO
	.endif
	;Remove noise
	call	RemoveNoise
	.if rngchanged
		dec		rngchanged
	.else
		call	FindDepth
		call	FindFish
		call	TestRangeChange
	.endif
	;Get current range index
	movzx	ebx,STM32Echo
	invoke GetRangePtr,ebx
	mov		ebx,eax
	mov		eax,sonarrange.interval[ebx]
	.if sonardata.hReply
		mov		ecx,REPLYSPEED
		xor		edx,edx
		div		ecx
	.endif
	invoke Sleep,eax
	jmp		Again

STLinkErr:
	invoke SendMessage,hWnd,WM_CLOSE,0,0
	xor		eax,eax
	ret

RemoveNoise:
	mov		ebx,1
	.if sonardata.NoiseReject
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			mov		ah,STM32Echo[ebx+MAXYECHO]
			.if al<sonardata.Noise || ah<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.else
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			.if al<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.endif
	retn

FindDepth:
	mov		sonardata.dptinx,0
	and		sonardata.ShowDepth,1
	;Skip blank
	mov		ebx,1
	xor		eax,eax
	.while ebx<MAXYECHO-2
		mov		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*1]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3]
		shl		eax,8
		mov		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*1+1]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2+1]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3+1]
		shl		eax,8
		mov		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*1+2]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2+2]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3+2]
		.break .if eax
		inc		ebx
	.endw
	;Skip ping and surface clutter
	xor		eax,eax
	.while ebx<MAXYECHO-2
		mov		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*1]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3]
		shl		eax,8
		mov		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*1+1]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2+1]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3+1]
		shl		eax,8
		mov		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*1+2]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2+2]
		or		al,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3+2]
		.break .if !eax
		inc		ebx
	.endw
	mov		sonardata.minyecho,ebx
	xor		esi,esi
	xor		edi,edi
	.while ebx<MAXYECHO
		xor		ecx,ecx
		xor		edx,edx
		.while TRUE
			lea		eax,[ebx+ecx]
			.break .if eax>=MAXYECHO
			push	edx
			movzx	edx,sonardata.sonar[ebx+ecx+MAXXECHO*MAXYECHO-MAXYECHO*1]
			movzx	eax,sonardata.sonar[ebx+ecx+MAXXECHO*MAXYECHO-MAXYECHO*2]
			add		edx,eax
			movzx	eax,sonardata.sonar[ebx+ecx+MAXXECHO*MAXYECHO-MAXYECHO*3]
			add		edx,eax
			mov		eax,edx
			pop		edx
			.break .if !eax
			add		edx,eax
			inc		ecx
		.endw
		.if edx>esi
			mov		esi,edx
			mov		edi,ebx
		.endif
		inc		ebx
	.endw
	.if edi>1
		mov		sonardata.nodptinx,0
		mov		ebx,edi
		mov		sonardata.dptinx,ebx
		call	CalculateDepth
		call	SetDepth
		or		sonardata.ShowDepth,2
	.endif
	retn

CalculateDepth:
	push	ecx
	push	edx
	movzx	eax,sonardata.STM32Echo
	invoke GetRangePtr,eax
	mov		eax,sonarrange.range[eax]
	mov		ecx,10
	mul		ecx
	mul		ebx
	mov		ecx,MAXYECHO
	div		ecx
	pop		edx
	pop		ecx
	retn

SetDepth:
	invoke wsprintf,addr buffer,addr szFmtDepth,eax
	invoke strlen,addr buffer
	.if eax>2
		mov		byte ptr buffer[eax-1],0
	.else
		movzx	ecx,word ptr buffer[eax-1]
		shl		ecx,8
		mov		cl,'.'
		mov		dword ptr buffer[eax-1],ecx
	.endif
	invoke strcpy,addr sonardata.options.text[1*sizeof OPTIONS],addr buffer
	retn

FindFish:
	.if sonardata.FishDetect || sonardata.FishAlarm
		mov		ebx,sonardata.minyecho
		add		ebx,5
		mov		edi,sonardata.dptinx
		.if !edi
			mov		edi,MAXYECHO
		.elseif edi>4
			sub		edi,4
		.endif
		.while ebx<edi
			movzx	eax,sonardata.STM32Echo[ebx]
			.if eax
				call	CalculateDepth
				mov		fish,al
				push	ebx
				sub		ebx,MAXFISH/2
				.if CARRY?
					xor		ebx,ebx
				.endif
				call	CalculateDepth
				mov		ecx,eax
				pop		ebx
				push	ebx
				add		ebx,MAXFISH/2
				call	CalculateDepth
				mov		edx,eax
				pop		ebx
				mov		esi,MAXFISH-1
				.while esi
					movzx	eax,fish[esi]
					.break .if eax>ecx && eax<edx
					dec		esi
				.endw
				.if !esi
					movzx	eax,sonardata.STM32Echo[ebx]
					.if sonardata.FishDetect
						.if eax>128
							;Large fish
							mov		eax,255
						.else
							;Small fish
							mov		eax,254
						.endif
						mov		sonardata.STM32Echo[ebx],al
					.endif
					.if sonardata.FishAlarm && !fFishSound
						mov		fFishSound,3
						invoke PlaySound,addr szFishSound,hInstance,SND_ASYNC
					.endif
					.break
				.else
					mov		fish,0
				.endif
			.endif
			inc		ebx
		.endw
	.endif
	retn

TestRangeChange:
	.if sonardata.AutoRange && !sonardata.hReply
		movzx	eax,STM32Echo
		mov		edx,sonardata.MaxRange
		dec		edx
		mov		ebx,sonardata.dptinx
		.if !ebx
			;Bottom not found
			inc		sonardata.nodptinx
			.if sonardata.nodptinx>=4
				mov		sonardata.nodptinx,0
				.if eax<edx
					;Range increment
					inc		eax
					invoke SetRange,eax
					mov		rngchanged,3
				.endif
			.endif
		.else
			;Check if range should be changed
			.if eax && ebx<MAXYECHO/3
				;Range decrement
				dec		eax
				invoke SetRange,eax
				mov		rngchanged,3
			.elseif eax<edx && ebx>(MAXYECHO-MAXYECHO/5)
				;Range increment
				inc		eax
				invoke SetRange,eax
				mov		rngchanged,3
			.endif
		.endif
	.endif
	retn

STM32Thread endp

SonarThreadProc proc uses ebx esi edi,lParam:DWORD
	LOCAL	rect:RECT
	LOCAL	buffer[256]:BYTE
	LOCAL	tmp:DWORD

	.if sonardata.hReply
		call	Update
		;Update range
		movzx	eax,sonardata.STM32Echo
		mov		sonardata.RangeInx,al
	.elseif fSTLink
		call	Update
	.endif
	mov		fThread,FALSE
	xor		eax,eax
	ret

SetBattery:
	.if eax!=sonardata.Battery
		mov		sonardata.Battery,eax
		mov		ecx,100
		mul		ecx
		mov		ecx,1640
		div		ecx
		invoke wsprintf,addr buffer,addr szFmtVolts,eax
		invoke strlen,addr buffer
		movzx	ecx,word ptr buffer[eax-1]
		shl		ecx,8
		mov		cl,'.'
		mov		dword ptr buffer[eax-1],ecx
		invoke strcat,addr buffer,addr szVolts
		invoke strcpy,addr map.options.text[sizeof OPTIONS],addr buffer
		invoke InvalidateRect,hMap,NULL,TRUE
	.endif
	retn

SetWTemp:
	.if eax!=sonardata.WTemp
		mov		sonardata.WTemp,eax
		sub		eax,0BC8h
		neg		eax
		mov		tmp,eax
		fild	tmp
		fld		watertempconv
		fdivp	st(1),st
		fistp	tmp
		invoke wsprintf,addr buffer,addr szFmtDec,tmp
		invoke strlen,addr buffer
		movzx	ecx,word ptr buffer[eax-1]
		shl		ecx,8
		mov		cl,'.'
		mov		dword ptr buffer[eax-1],ecx
		invoke strcat,addr buffer,addr szCelcius
		invoke strcpy,addr sonardata.options.text[sizeof OPTIONS*2],addr buffer
	.endif
	retn

ScrollEchoArray:
	mov		esi,offset sonardata.sonar+MAXYECHO
	mov		edi,offset sonardata.sonar
	mov		ecx,(MAXXECHO*MAXYECHO-MAXYECHO)/4
	rep movsd
	retn

Update:
	movzx	eax,sonardata.ADCBattery
	call	SetBattery
	;Water temprature
	movzx	eax,sonardata.ADCWaterTemp
	call	SetWTemp
	invoke IsDlgButtonChecked,hWnd,IDC_CHKCHART
	.if !eax
		;Check if range is still the same
		movzx	eax,sonardata.STM32Echo
		.if al!=sonardata.sonar[(MAXXECHO*MAXYECHO)-MAXYECHO]
			invoke GetRangePtr,eax
			mov		eax,sonarrange.range[eax]
			invoke UpdateBitmap,eax
			mov		eax,sonardata.ChartSpeed
		.endif
		call	ScrollEchoArray
		invoke RtlMoveMemory,offset sonardata.sonar[(MAXXECHO*MAXYECHO)-MAXYECHO],offset sonardata.STM32Echo,MAXYECHO
		mov		rect.left,0
		mov		rect.top,0
		mov		rect.right,MAXXECHO
		mov		rect.bottom,MAXYECHO
		invoke ScrollDC,sonardata.mDC,-1,0,addr rect,addr rect,NULL,NULL
		mov		rect.left,MAXXECHO-1
		mov		rect.top,0
		mov		rect.right,MAXXECHO
		mov		rect.bottom,MAXYECHO
		invoke FillRect,sonardata.mDC,addr rect,sonardata.hBrBack
		;Draw echo
		mov		ebx,1
		.while ebx<MAXYECHO
			movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
			.if eax
				xor		eax,0FFh
				mov		ah,al
				shl		eax,8
				mov		al,ah
				invoke SetPixel,sonardata.mDC,MAXXECHO-1,ebx,eax
			.endif
			inc		ebx
		.endw
		;Remove fish
		mov		ebx,1
		.while ebx<MAXYECHO
			.if sonardata.STM32Echo[ebx]>253
				mov		sonardata.STM32Echo[ebx],1
			.endif
			inc		ebx
		.endw
		;Draw echo strenght
		mov		rect.left,0
		mov		rect.top,0
		mov		rect.right,SIGNALBAR
		mov		rect.bottom,MAXYECHO
		invoke FillRect,sonardata.mDCS,addr rect,sonardata.hBrBack
		mov		ebx,1
		.while ebx<MAXYECHO
			movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
			mov		ecx,SIGNALBAR
			mul		ecx
			shr		eax,8
			.if eax
				push	eax
				invoke MoveToEx,sonardata.mDCS,0,ebx,NULL
				pop		eax
				invoke LineTo,sonardata.mDCS,eax,ebx
			.endif
			inc		ebx
		.endw
	.endif
	invoke InvalidateRect,hSonar,NULL,TRUE
	invoke UpdateWindow,hSonar
	retn

SonarThreadProc endp

ShowRangeDepthTempScaleFish proc uses ebx esi edi,hDC:HDC
	LOCAL	rcsonar:RECT
	LOCAL	rect:RECT
	LOCAL	x:DWORD
	LOCAL	buffer[32]:BYTE

	invoke GetClientRect,hSonar,addr rcsonar
	.if sonardata.FishDetect
		call	ShowFish
	.endif
	invoke SetBkMode,hDC,TRANSPARENT
	xor		ebx,ebx
	mov		esi,offset sonardata.options
	.while ebx<MAXSONAROPTION
		.if [esi].OPTIONS.show
			.if ebx==1
				.if (sonardata.ShowDepth & 1) || (sonardata.ShowDepth>1)
					call ShowOption
				.endif
			.else
				call ShowOption
			.endif
		.endif
		lea		esi,[esi+sizeof OPTIONS]
		inc		ebx
	.endw
	call	ShowScale
	ret

ShowFish:
	movzx	ebx,sonardata.sonar[(MAXXECHO*MAXYECHO)-MAXYECHO]
	invoke GetRangePtr,ebx
	mov		ebx,sonarrange.range[eax]
	mov		esi,MAXXECHO+RANGESCALE+SIGNALBAR
	sub		esi,rcsonar.right
	.while esi<MAXXECHO
		xor		edi,edi
		.while edi<MAXYECHO
			mov		eax,MAXYECHO
			mul		esi
			movzx	eax,sonardata.sonar[eax+edi]
			.if eax==254 || eax==255
				push	eax
				mov		eax,MAXYECHO
				mul		esi
				movzx	eax,sonardata.sonar[eax]
				invoke GetRangePtr,eax
				mov		ecx,sonarrange.range[eax]
				mov		eax,edi
				mul		ecx
				xor		edx,edx
				div		ebx
				mov		ecx,rcsonar.bottom
				mul		ecx
				mov		ecx,MAXYECHO
				xor		edx,edx
				div		ecx
				mov		ecx,eax
				mov		edx,rcsonar.right
				sub		edx,RANGESCALE+SIGNALBAR
				sub		edx,MAXXECHO
				pop		eax
				xchg	eax,ecx
				.if ecx==255
					;Large fish
					mov		ecx,18
				.else
					;Small fish
					mov		ecx,17
				.endif
				invoke ImageList_Draw,hIml,ecx,hDC,addr [esi+edx-8],addr [eax],ILD_TRANSPARENT
			.endif
			inc		edi
		.endw
		inc		esi
	.endw
	retn

ShowOption:
	mov		ecx,[esi].OPTIONS.pt.x
	mov		edx,[esi].OPTIONS.pt.y
	mov		rect.left,ecx
	mov		rect.top,edx
	mov		eax,rcsonar.right
	sub		eax,ecx
	mov		rect.right,eax
	mov		eax,rcsonar.bottom
	sub		eax,edx
	mov		rect.bottom,eax
	mov		eax,[esi].OPTIONS.font
	add		eax,7
	mov		ecx,map.font[eax*4]
	mov		edx,[esi].OPTIONS.position
	.if !edx
		;Left, Top
		mov		eax,DT_LEFT or DT_SINGLELINE
	.elseif edx==1
		;Center, Top
		mov		eax,DT_LEFT or DT_SINGLELINE
	.elseif edx==2
		;Rioght, Top
		mov		eax,DT_RIGHT or DT_SINGLELINE
	.elseif edx==3
		;Left, Bottom
		mov		eax,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
	.elseif edx==4
		;Center, Bottom
		mov		eax,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
	.elseif edx==5
		;Right, Bottom
		mov		eax,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
	.endif
	invoke TextDraw,hDC,ecx,addr rect,addr [esi].OPTIONS.text,eax
	retn

DrawScaleBar:
	mov		ebx,rect.right
	sub		ebx,rect.left
	shr		ebx,1
	add		ebx,rect.left
	invoke MoveToEx,hDC,ebx,rect.top,NULL
	invoke LineTo,hDC,ebx,rect.bottom
	invoke MoveToEx,hDC,rect.left,rect.top,NULL
	invoke LineTo,hDC,rect.right,rect.top
	mov		ebx,rect.bottom
	sub		ebx,rect.top
	shr		ebx,1
	add		ebx,rect.top
	invoke MoveToEx,hDC,rect.left,ebx,NULL
	invoke LineTo,hDC,rect.right,ebx
	invoke MoveToEx,hDC,rect.left,rect.bottom,NULL
	invoke LineTo,hDC,rect.right,rect.bottom
	retn

DrawScaleText:
	push	rect.top
	add		rect.top,2
	invoke DrawText,hDC,addr buffer,1,addr rect,DT_CENTER or DT_TOP or DT_SINGLELINE
	mov		eax,rect.bottom
	sub		eax,rect.top
	shr		eax,1
	sub		eax,20
	add		rect.top,eax
	invoke DrawText,hDC,addr buffer[8],-1,addr rect,DT_CENTER or DT_TOP or DT_SINGLELINE
	mov		eax,rect.bottom
	sub		eax,16
	mov		rect.top,eax
	invoke DrawText,hDC,addr buffer[16],-1,addr rect,DT_CENTER or DT_TOP or DT_SINGLELINE
	pop		rect.top
	retn

ShowScale:
	invoke CopyRect,addr rect,addr rcsonar
	mov		eax,rect.right
	sub		eax,SIGNALBAR
	mov		rect.right,eax
	sub		eax,RANGESCALE
	mov		rect.left,eax
	mov		rect.top,6
	sub		rect.bottom,5
	invoke CreatePen,PS_SOLID,5,0FFFFFFh
	invoke SelectObject,hDC,eax
	push	eax
	call	DrawScaleBar
	pop		eax
	invoke SelectObject,hDC,eax
	invoke DeleteObject,eax
	invoke GetStockObject,BLACK_PEN
	invoke SelectObject,hDC,eax
	push	eax
	call	DrawScaleBar
	sub		rect.left,20
	add		rect.right,20
	mov		word ptr buffer,'0'
	mov		edi,sonardata.RangeVal
	invoke wsprintf,addr buffer[16],addr szFmtDec,edi
	shr		edi,1
	invoke wsprintf,addr buffer[8],addr szFmtDec,edi
	invoke SetTextColor,hDC,0FFFFFFh
	sub		rect.left,2
	sub		rect.top,2
	call	DrawScaleText
	add		rect.left,4
	call	DrawScaleText
	add		rect.top,4
	call	DrawScaleText
	sub		rect.left,4
	call	DrawScaleText
	invoke SetTextColor,hDC,0
	add		rect.left,2
	sub		rect.top,2
	call	DrawScaleText
	pop		eax
	invoke SelectObject,hDC,eax
	retn

ShowRangeDepthTempScaleFish endp

SaveSonarToIni proc
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	;Width,AutoRange,AutoGain,AutoPing,FishDetect,FishAlarm,RangeInx,Noise,PingInit,GainInit,ChartSpeed,NoiseReject,ChartSync,PingTimer
	invoke PutItemInt,addr buffer,sonardata.wt
	invoke PutItemInt,addr buffer,sonardata.AutoRange
	invoke PutItemInt,addr buffer,sonardata.AutoGain
	invoke PutItemInt,addr buffer,sonardata.AutoPing
	invoke PutItemInt,addr buffer,sonardata.FishDetect
	invoke PutItemInt,addr buffer,sonardata.FishAlarm
	invoke PutItemInt,addr buffer,sonardata.RangeInx
	invoke PutItemInt,addr buffer,sonardata.Noise
	invoke PutItemInt,addr buffer,sonardata.PingInit
	invoke PutItemInt,addr buffer,sonardata.GainInit
	invoke PutItemInt,addr buffer,sonardata.ChartSpeed
	invoke PutItemInt,addr buffer,sonardata.NoiseReject
	invoke PutItemInt,addr buffer,sonardata.ChartSync
	movzx	eax,sonardata.PingTimer
	invoke PutItemInt,addr buffer,eax
	invoke WritePrivateProfileString,addr szIniSonar,addr szIniSonar,addr buffer[1],addr szIniFileName
	ret

SaveSonarToIni endp

LoadSonarFromIni proc uses ebx
	LOCAL	buffer[256]:BYTE
	
	invoke RtlZeroMemory,addr buffer,sizeof buffer
	invoke GetPrivateProfileString,addr szIniSonar,addr szIniSonar,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	;Width,AutoRange,AutoGain,AutoPing,FishDetect,FishAlarm,RangeInx,Noise,PingInit,GainInit,ChartSpeed,NoiseReject,ChartSync,PingTimer
	invoke GetItemInt,addr buffer,250
	mov		sonardata.wt,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.AutoRange,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.AutoGain,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.AutoPing,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.FishDetect,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.FishAlarm,eax
	invoke GetItemInt,addr buffer,0
	mov		sonardata.RangeInx,al
	invoke GetItemInt,addr buffer,31
	mov		sonardata.Noise,al
	invoke GetItemInt,addr buffer,7
	mov		sonardata.PingInit,eax
	invoke GetItemInt,addr buffer,63
	mov		sonardata.GainInit,eax
	invoke GetItemInt,addr buffer,100
	mov		sonardata.ChartSpeed,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.NoiseReject,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.ChartSync,eax
	invoke GetItemInt,addr buffer,139
	mov		sonardata.PingTimer,al
	;Get the range definitions
	xor		ebx,ebx
	xor		edi,edi
	.while ebx<32
		invoke wsprintf,addr buffer,addr szFmtDec,ebx
		invoke GetPrivateProfileString,addr szIniSonarRange,addr buffer,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
		.break .if !eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.range[edi],eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.interval[edi],eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.nsample[edi],eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.pingadd[edi],eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.gainadd[edi],eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.gaininc[edi],eax
		inc		ebx
		lea		edi,[edi+sizeof RANGE]
	.endw
	;Store the number of range definitions read from ini
	mov		sonardata.MaxRange,ebx
	ret

LoadSonarFromIni endp

SonarProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC
	LOCAL	hBmp:HBITMAP
	LOCAL	pt:POINT

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hSonar,eax
		invoke CreateSolidBrush,SONARBACKCOLOR
		mov		sonardata.hBrBack,eax
		invoke CreatePen,PS_SOLID,1,SONARPENCOLOR
		mov		sonardata.hPen,eax
		invoke GetDC,hWin
		mov		hDC,eax

		invoke CreateCompatibleDC,hDC
		mov		sonardata.mDC,eax
		invoke CreateCompatibleBitmap,hDC,MAXXECHO,MAXYECHO
		mov		sonardata.hBmp,eax
		invoke SelectObject,sonardata.mDC,eax
		mov		sonardata.hBmpOld,eax
		mov		rect.left,0
		mov		rect.top,0
		mov		rect.right,MAXXECHO
		mov		rect.bottom,MAXYECHO
		invoke FillRect,sonardata.mDC,addr rect,sonardata.hBrBack

		invoke CreateCompatibleDC,hDC
		mov		sonardata.mDCS,eax
		invoke CreateCompatibleBitmap,hDC,SIGNALBAR,MAXYECHO
		mov		sonardata.hBmpS,eax
		invoke SelectObject,sonardata.mDCS,eax
		mov		sonardata.hBmpOldS,eax
		invoke SelectObject,sonardata.mDCS,sonardata.hPen
		mov		sonardata.hPenOld,eax
		mov		rect.left,0
		mov		rect.top,0
		mov		rect.right,SIGNALBAR
		mov		rect.bottom,MAXYECHO
		invoke FillRect,sonardata.mDCS,addr rect,sonardata.hBrBack

		invoke ReleaseDC,hWin,hDC
		invoke strcpy,addr szFishSound,addr szAppPath
		invoke strcat,addr szFishSound,addr szFishWav
		invoke SetTimer,hWin,1000,800,NULL
		invoke SetTimer,hWin,1001,1000,NULL
	.elseif eax==WM_TIMER
		.if wParam==1000
			.if !fSTLink
				mov		fSTLink,IDIGNORE
				invoke STLinkConnect,hWnd
				.if eax==IDABORT
					invoke SendMessage,hWnd,WM_CLOSE,0,0
				.else
					mov		fSTLink,eax
				.endif
				.if fSTLink && fSTLink!=IDIGNORE
					invoke STLinkReset,hWnd
				.endif
				invoke CreateThread,NULL,NULL,addr STM32Thread,hWin,0,addr tid
				invoke CloseHandle,eax
			.endif
			.if fSTLink && !fThread
				invoke KillTimer,hWin,1000
				mov		fThread,TRUE
				invoke CreateThread,NULL,NULL,addr SonarThreadProc,hWin,0,addr tid
				invoke CloseHandle,eax
				.if sonardata.ChartSync
					movzx	eax,sonardata.RangeInx
					invoke GetRangePtr,eax
					mov		eax,sonarrange.interval[eax]
				.else
					mov		eax,350
					sub		eax,sonardata.ChartSpeed
					sub		eax,sonardata.ChartSpeed
					sub		eax,sonardata.ChartSpeed
				.endif
				.if sonardata.hReply
					mov		ecx,REPLYSPEED
					xor		edx,edx
					div		ecx
				.endif
				invoke SetTimer,hWin,1000,eax,NULL
			.endif
		.elseif wParam==1001
			xor		sonardata.ShowDepth,1
			.if sonardata.ShowDepth<2
				invoke InvalidateRect,hSonar,NULL,TRUE
			.endif
			.if fFishSound
				dec		fFishSound
			.endif
		.endif
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
			invoke GetSubMenu,hContext,5
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,mousept.x,mousept.y,0,hWnd,0
		.endif
	.elseif eax==WM_DESTROY
		.if fSTLink && fSTLink!=IDIGNORE
			invoke STLinkDisconnect
		.endif
		invoke DeleteObject,sonardata.hBrBack
		invoke SelectObject,sonardata.mDC,sonardata.hBmpOld
		invoke DeleteObject,sonardata.hBmp
		invoke DeleteDC,sonardata.mDC
		invoke SelectObject,sonardata.mDCS,sonardata.hBmpOldS
		invoke DeleteObject,sonardata.hBmpS
		invoke SelectObject,sonardata.mDCS,sonardata.hPenOld
		invoke DeleteObject,sonardata.hPen
		invoke DeleteDC,sonardata.mDCS
		invoke SaveSonarToIni
	.elseif eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke FillRect,mDC,addr rect,sonardata.hBrBack
		sub		rect.right,RANGESCALE+SIGNALBAR
		sub		rect.bottom,12
		mov		ecx,MAXXECHO
		sub		ecx,rect.right
		invoke StretchBlt,mDC,0,6,rect.right,rect.bottom,sonardata.mDC,ecx,0,rect.right,MAXYECHO,SRCCOPY
		add		rect.right,RANGESCALE
		invoke StretchBlt,mDC,rect.right,6,SIGNALBAR,rect.bottom,sonardata.mDCS,0,0,SIGNALBAR,MAXYECHO,SRCCOPY
		add		rect.right,SIGNALBAR
		invoke ShowRangeDepthTempScaleFish,mDC
		add		rect.bottom,12
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
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

SonarProc endp
