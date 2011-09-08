
IDD_DLGSONAR            equ 1500
IDC_TRBSONARGAIN        equ 1504
IDC_CHKSONARGAIN        equ 1503
IDC_TRBSONARPING        equ 1510
IDC_CHKSONARPING        equ 1509
IDC_TRBSONARRANGE       equ 1507
IDC_CHKSONARRANGE       equ 1506
IDC_TRBSONARNOISE       equ 1501
IDC_CHKSONARNOISE		equ 1521
IDC_TRBSONARFISH        equ 1530
IDC_CHKSONARALARM       equ 1514
IDC_TRBSONARCHART       equ 1512
IDC_CHKCHARTPAUSE       equ 1532
IDC_TRBPINGTIMER        equ 1526
IDC_TRBSOUNDSPEED       equ 1528
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
IDC_BTNSSU              equ 1523
IDC_BTNSSD              equ 1529
IDC_BTNFU               equ 1515
IDC_BTNFD               equ 1531

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
	mov		eax,sonarrange.pixeltimer[ebx]
	mov		sonardata.PixelTimer,ax
	mov		eax,sonarrange.range[ebx]
	mov		sonardata.RangeVal,eax
	invoke wsprintf,addr sonardata.options.text,addr szFmtDec,eax
	ret

SetRange endp

ButtonProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_LBUTTONDOWN
		invoke SetTimer,hWin,1000,500,NULL
	.elseif eax==WM_LBUTTONUP
		invoke KillTimer,hWin,1000
	.elseif eax==WM_TIMER
		invoke GetWindowLong,hWin,GWL_ID
		push	eax
		invoke GetParent,hWin
		pop		edx
		invoke SendMessage,eax,WM_COMMAND,edx,hWin
		invoke KillTimer,hWin,1000
		invoke SetTimer,hWin,1000,50,NULL
		xor		eax,eax
		ret
	.endif
	invoke CallWindowProc,lpOldButtonProc,hWin,uMsg,wParam,lParam
	ret

ButtonProc endp

;Description
;===========
;A short ping at 200KHz is transmitted at intervalls depending on range.
;From the time it takes for the echo to return we can calculate the depth.
;The ADC measures the strenght of the echo at intervalls depending on range
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
;The timer is clocked at 56 MHz so it increments every 0,0178571 us.
;For each tick the sound travels 1450 * 0,0178571 = 25,8929 um or 25,8929e-6 meters.

;Timer value calculation
;=======================
;Example 2m range and 56 MHz clock
;Timer period Tp=1/56MHz
;Each pixel is Px=2m/512.
;Time for each pixel is t=Px/1450/2
;Timer ticks Tt=t/Tp

;Formula T=((Range/512)/(1450/2))56000000

RangeToTimer proc RangeInx:DWORD
	LOCAL	tmp:DWORD

	invoke GetRangePtr,RangeInx
	mov		eax,sonarrange.range[eax]
	mov		tmp,eax
	fild	tmp
	mov		tmp,MAXYECHO
	fild	tmp
	fdivp	st(1),st
	mov		eax,sonardata.SoundSpeed
	shr		eax,1			;Divide by 2 since it is the echo
	mov		tmp,eax
	fild	tmp
	fdivp	st(1),st
	mov		tmp,STM32_Clock
	fild	tmp
	fmulp	st(1),st
	fistp	tmp
	mov		eax,tmp
	dec		eax
	ret

RangeToTimer endp

SetupPixelTimer proc uses ebx edi
	
	xor		ebx,ebx
	mov		edi,offset sonarrange
	.while ebx<sonardata.MaxRange
		invoke RangeToTimer,ebx
		mov		[edi].RANGE.pixeltimer,eax
		inc		ebx
		lea		edi,[edi+sizeof RANGE]
	.endw
	movzx	eax,sonardata.RangeInx
	invoke SetRange,eax
	ret

SetupPixelTimer endp

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
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARPING,TBM_SETRANGE,FALSE,(MAXPING SHL 16)+0
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARPING,TBM_SETPOS,TRUE,sonardata.PingInit
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARNOISE,TBM_SETRANGE,FALSE,(255 SHL 16)+1
		movzx	eax,sonardata.Noise
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARNOISE,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARFISH,TBM_SETRANGE,FALSE,(3 SHL 16)+0
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARFISH,TBM_SETPOS,TRUE,sonardata.FishDetect
		.if sonardata.FishAlarm
			invoke CheckDlgButton,hWin,IDC_CHKSONARALARM,BST_CHECKED
		.endif
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETRANGE,FALSE,(4 SHL 16)+1
		invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETPOS,TRUE,sonardata.ChartSpeed
		invoke IsDlgButtonChecked,hWnd,IDC_CHKCHART
		.if eax
			invoke CheckDlgButton,hWin,IDC_CHKCHARTPAUSE,BST_CHECKED
		.endif
		invoke SendDlgItemMessage,hWin,IDC_TRBPINGTIMER,TBM_SETRANGE,FALSE,((STM32_PingTimer+2) SHL 16)+STM32_PingTimer-2
		movzx	eax,sonardata.PingTimer
		invoke SendDlgItemMessage,hWin,IDC_TRBPINGTIMER,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBSOUNDSPEED,TBM_SETRANGE,FALSE,((SOUNDSPEEDMAX) SHL 16)+SOUNDSPEEDMIN
		invoke SendDlgItemMessage,hWin,IDC_TRBSOUNDSPEED,TBM_SETPOS,TRUE,sonardata.SoundSpeed
		;Subclass buttons to get autorepeat
		push	0
		push	IDC_BTNGD
		push	IDC_BTNGU
		push	IDC_BTNPD
		push	IDC_BTNPU
		push	IDC_BTNRD
		push	IDC_BTNRU
		push	IDC_BTNCD
		push	IDC_BTNCU
		push	IDC_BTNND
		push	IDC_BTNNU
		push	IDC_BTNSSD
		push	IDC_BTNSSU
		push	IDC_BTNPTD
		push	IDC_BTNPTU
		push	IDC_BTNFD
		mov		eax,IDC_BTNFU
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
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
			.elseif eax==IDC_CHKCHARTPAUSE
				invoke IsDlgButtonChecked,hWin,IDC_CHKCHARTPAUSE
				.if eax
					mov		eax,BST_CHECKED
				.endif
				invoke CheckDlgButton,hWnd,IDC_CHKCHART,eax
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
				.if sonardata.PingInit<MAXPING
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
			.elseif eax==IDC_BTNFD
				.if sonardata.FishDetect
					dec		sonardata.FishDetect
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARFISH,TBM_SETPOS,TRUE,sonardata.FishDetect
				.endif
			.elseif eax==IDC_BTNFU
				.if sonardata.FishDetect<3
					inc		sonardata.FishDetect
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARFISH,TBM_SETPOS,TRUE,sonardata.FishDetect
				.endif
			.elseif eax==IDC_BTNCD
				.if sonardata.ChartSpeed>1
					dec		sonardata.ChartSpeed
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETPOS,TRUE,sonardata.ChartSpeed
				.endif
			.elseif eax==IDC_BTNCU
				.if sonardata.ChartSpeed<4
					inc		sonardata.ChartSpeed
					invoke SendDlgItemMessage,hWin,IDC_TRBSONARCHART,TBM_SETPOS,TRUE,sonardata.ChartSpeed
				.endif
			.elseif eax==IDC_BTNPTD
				.if sonardata.PingTimer>STM32_PingTimer-2
					dec		sonardata.PingTimer
					movzx	eax,sonardata.PingTimer
					invoke SendDlgItemMessage,hWin,IDC_TRBPINGTIMER,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNPTU
				.if sonardata.PingTimer<STM32_PingTimer+2
					inc		sonardata.PingTimer
					movzx	eax,sonardata.PingTimer
					invoke SendDlgItemMessage,hWin,IDC_TRBPINGTIMER,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNSSU
				.if sonardata.SoundSpeed<SOUNDSPEEDMAX
					inc		sonardata.SoundSpeed
					invoke SendDlgItemMessage,hWin,IDC_TRBSOUNDSPEED,TBM_SETPOS,TRUE,sonardata.SoundSpeed
					invoke SetupPixelTimer
				.endif
			.elseif eax==IDC_BTNSSD
				.if sonardata.SoundSpeed>SOUNDSPEEDMIN
					dec		sonardata.SoundSpeed
					invoke SendDlgItemMessage,hWin,IDC_TRBSOUNDSPEED,TBM_SETPOS,TRUE,sonardata.SoundSpeed
					invoke SetupPixelTimer
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
		.elseif eax==IDC_TRBSONARFISH
			mov		sonardata.FishDetect,ebx
		.elseif eax==IDC_TRBSONARCHART
			mov		sonardata.ChartSpeed,ebx
		.elseif eax==IDC_TRBPINGTIMER
			mov		sonardata.PingTimer,bl
		.elseif eax==IDC_TRBSOUNDSPEED
			mov		sonardata.SoundSpeed,ebx
			invoke SetupPixelTimer
		.endif
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
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

UpdateBitmap proc uses ebx esi edi,NewRange:DWORD
	LOCAL	rect:RECT
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC
	LOCAL	wt:DWORD

	invoke GetDC,hSonar
	mov		hDC,eax
	invoke CreateCompatibleDC,hDC
	mov		mDC,eax
	invoke ReleaseDC,hSonar,hDC
	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,MAXXECHO
	mov		rect.bottom,MAXYECHO
	invoke FillRect,sonardata.mDC,addr rect,sonardata.hBrBack
	lea		esi,sonardata.sonarbmp
	mov		ebx,MAXSONARBMP
	.while ebx
		.if [esi].SONARBMP.hBmp
			mov		eax,[esi].SONARBMP.xpos
			add		eax,[esi].SONARBMP.wt
			.if sdword ptr eax>0
				invoke SelectObject,mDC,[esi].SONARBMP.hBmp
				push	eax
				invoke GetRangePtr,[esi].SONARBMP.RangeInx
				mov		ecx,sonarrange.range[eax]
				mov		eax,MAXYECHO
				mul		ecx
				mov		ecx,NewRange
				div		ecx
				mov		edx,[esi].SONARBMP.wt
				mov		ecx,[esi].SONARBMP.xpos
				xor		edi,edi
				.if sdword ptr ecx<0
					neg		ecx
					mov		edi,ecx
					sub		edx,ecx
					xor		ecx,ecx
				.endif
				invoke StretchBlt,sonardata.mDC,ecx,0,edx,eax,mDC,edi,0,edx,MAXYECHO,SRCCOPY
				pop		eax
				invoke SelectObject,mDC,eax
			.else
				invoke DeleteObject,[esi].SONARBMP.hBmp
				mov		[esi].SONARBMP.hBmp,0
			.endif
		.endif
		lea		esi,[esi+sizeof SONARBMP]
		dec		ebx
	.endw
	invoke DeleteDC,mDC
	ret

UpdateBitmap endp

SonarUpdateProc proc uses ebx esi edi
	LOCAL	rect:RECT
	LOCAL	buffer[256]:BYTE
	LOCAL	tmp:DWORD
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC

	.if sonardata.hReply
		call	Update
		;Update range
		movzx	eax,sonardata.STM32Echo
		mov		sonardata.RangeInx,al
	.elseif fSTLink
		call	Update
	.endif
	ret

SetBattery:
	.if eax!=sonardata.Battery
		mov		sonardata.Battery,eax
		mov		ecx,100
		mul		ecx
		mov		ecx,1792
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
		sub		tmp,150
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

SetATemp:
	.if eax!=sonardata.ATemp
		xor		ebx,ebx
		mov		esi,offset atemp
		.while ebx<NATEMP
			.if eax<[esi+ebx*sizeof TEMP].TEMP.adcvalue && eax>=[esi+ebx*sizeof TEMP+sizeof TEMP].TEMP.adcvalue
				.break
			.endif
			inc		ebx
		.endw
		.if ebx<NATEMP
			mov		sonardata.ATemp,eax
			;Tx=(T1-T2)/(V1-V2)*(V1-Vx)+T1
			mov		eax,[esi+ebx*sizeof TEMP].TEMP.temp
			sub		eax,[esi+ebx*sizeof TEMP+sizeof TEMP].TEMP.temp
			mov		tmp,eax
			fild	tmp
			mov		eax,[esi+ebx*sizeof TEMP].TEMP.adcvalue
			sub		eax,[esi+ebx*sizeof TEMP+sizeof TEMP].TEMP.adcvalue
			mov		tmp,eax
			fild	tmp
			fdivp	st(1),st
			mov		eax,[esi+ebx*sizeof TEMP].TEMP.adcvalue
			sub		eax,sonardata.ATemp
			mov		tmp,eax
			fild	tmp
			fmulp	st(1),st
			fistp	tmp
			mov		eax,[esi+ebx*sizeof TEMP].TEMP.temp
			sub		eax,tmp
			sub		eax,20
			mov		tmp,eax
			invoke wsprintf,addr buffer,addr szFmtDec,tmp
			invoke strlen,addr buffer
			movzx	ecx,word ptr buffer[eax-1]
			shl		ecx,8
			mov		cl,'.'
			mov		dword ptr buffer[eax-1],ecx
			invoke strcat,addr buffer,addr szCelcius
			invoke strcpy,addr map.options.text[sizeof OPTIONS*2],addr buffer
		.endif
	.endif
	retn

GetBitmap:
	invoke GetDC,hSonar
	mov		hDC,eax
	invoke CreateCompatibleDC,hDC
	mov		mDC,eax
	invoke CreateCompatibleBitmap,hDC,sonardata.sonarbmp.wt,MAXYECHO
	invoke SelectObject,mDC,eax
	push	eax
	invoke ReleaseDC,hSonar,hDC
	mov		eax,MAXXECHO
	sub		eax,sonardata.sonarbmp.wt
	invoke BitBlt,mDC,0,0,sonardata.sonarbmp.wt,MAXYECHO,sonardata.mDC,eax,0,SRCCOPY
	pop		eax
	invoke SelectObject,mDC,eax
	mov		sonardata.sonarbmp.hBmp,eax
	invoke DeleteDC,mDC
	retn

ScrollBitmapArray:
	lea		edi,sonardata.sonarbmp[63*sizeof SONARBMP]
	.if [edi].SONARBMP.hBmp
		invoke DeleteObject,[edi].SONARBMP.hBmp
	.endif
	lea		esi,[edi-sizeof SONARBMP]
	mov		edx,MAXSONARBMP-1
	.while edx
		mov		ecx,sizeof SONARBMP/4
		rep		movsd
		lea		edi,[edi-sizeof SONARBMP*2]
		lea		esi,[edi-sizeof SONARBMP]
		dec		edx
	.endw
	movzx	eax,sonardata.STM32Echo
	mov		sonardata.sonarbmp.RangeInx,eax
	mov		sonardata.sonarbmp.xpos,MAXXECHO
	mov		sonardata.sonarbmp.wt,0
	mov		sonardata.sonarbmp.hBmp,0
	retn

UpdateBitmapArray:
	lea		edi,sonardata.sonarbmp[63*sizeof SONARBMP]
	mov		edx,MAXSONARBMP-1
	.while edx
		.if [edi].SONARBMP.hBmp
			dec		[edi].SONARBMP.xpos
			mov		eax,[edi].SONARBMP.xpos
			add		eax,[edi].SONARBMP.wt
			.if sdword ptr eax<0
				;Delete the bitmap, it is no longer needed
				push	edx
				invoke DeleteObject,[edi].SONARBMP.hBmp
				pop		edx
				mov		[edi].SONARBMP.hBmp,0
			.endif
		.endif
		lea		edi,[edi-sizeof SONARBMP]
		dec		edx
	.endw
	.if [edi].SONARBMP.wt<MAXXECHO
		inc		[edi].SONARBMP.wt
		dec		[edi].SONARBMP.xpos
	.endif
	retn

Update:
	;Battery
	movzx	eax,sonardata.ADCBattery
	call	SetBattery
	;Water temprature
	movzx	eax,sonardata.ADCWaterTemp
	call	SetWTemp
	;Air temprature
	movzx	eax,sonardata.ADCAirTemp
	call	SetATemp
	;Check if range is still the same
	movzx	eax,STM32Echo
	.if eax!=sonardata.sonarbmp.RangeInx
		;Get bitmap
		call	GetBitmap
		call	ScrollBitmapArray
		invoke GetRangePtr,eax
		invoke UpdateBitmap,sonarrange.range[eax]
	.endif
	call	UpdateBitmapArray
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
		movzx	eax,sonardata.STM32Echo[ebx]
		.if eax
			.if eax>=0C0h
				;Red
			.elseif eax>=050h
				;Green
				shl		eax,8
			.elseif eax>030h
				;Yellow
				add		al,0B0h
				mov		ah,al
			.else
				;Gray
				xor		eax,0FFh
				mov		ah,al
				shl		eax,8
				mov		al,ah
			.endif
			invoke SetPixel,sonardata.mDC,MAXXECHO-1,ebx,eax
		.endif
		inc		ebx
	.endw
	;Draw signal bar
	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,SIGNALBAR
	mov		rect.bottom,MAXYECHO
	invoke FillRect,sonardata.mDCS,addr rect,sonardata.hBrBack
	mov		ebx,1
	.while ebx<MAXYECHO
		movzx	eax,sonardata.STM32Echo[ebx]
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
	invoke InvalidateRect,hSonar,NULL,TRUE
	invoke UpdateWindow,hSonar
	retn

SonarUpdateProc endp

STM32Thread proc uses ebx esi edi,lParam:DWORD
	LOCAL	status:DWORD
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
	mov		rngchanged,4
	invoke RtlZeroMemory,addr STM32Echo,sizeof STM32Echo
  Again:
	invoke IsDlgButtonChecked,hWnd,IDC_CHKCHART
	.if eax
		invoke Sleep,100
	.else
		.if sonardata.hReply
			;Copy old echo
			call	CopyEcho
			;Read echo from file
			invoke ReadFile,sonardata.hReply,addr STM32Echo,MAXYECHO,addr dwread,NULL
			.if dwread!=MAXYECHO
				invoke CloseHandle,sonardata.hReply
				mov		sonardata.hReply,0
				invoke SetScrollPos,hSonar,SB_HORZ,0,TRUE
				mov		sonardata.dptinx,0
				jmp		Again
			.endif
			invoke GetScrollPos,hSonar,SB_HORZ
			inc		eax
			invoke SetScrollPos,hSonar,SB_HORZ,eax,TRUE
			movzx	eax,STM32Echo
			.if al!=STM32Echo[MAXYECHO]
				mov		rngchanged,4
			.endif
			invoke SetRange,eax
		.elseif fSTLink && fSTLink!=IDIGNORE
			;Download Start status (first byte)
			invoke STLinkRead,hWnd,STM32_Sonar,addr status,4
			.if !eax || eax==IDABORT || eax==IDIGNORE
				jmp		STLinkErr
			.endif
			.if !(status & 255)
				;Download ADCBattery, ADCWaterTemp and ADCAirTemp
				invoke STLinkRead,hWnd,STM32_Sonar+8,addr sonardata.EchoIndex,8
				.if !eax || eax==IDABORT || eax==IDIGNORE
					jmp		STLinkErr
				.endif
				;Copy old echo
				call	CopyEcho
				;Download sonar echo array
				invoke STLinkRead,hWnd,STM32_Sonar+16,addr STM32Echo,MAXYECHO
				.if !eax || eax==IDABORT || eax==IDIGNORE
					jmp		STLinkErr
				.endif
			 	;Upload Start, PingPulses, PingTimer, Gain, GainInc, RangeInx and PixelTimer to init the next reading
				movzx	ebx,sonardata.RangeInx
				invoke GetRangePtr,ebx
				mov		ebx,eax
				.if sonardata.AutoGain
					mov		eax,sonardata.GainInit
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
					.if eax>MAXPING
						mov		eax,MAXPING
					.endif
				.endif
				mov		sonardata.Ping,al
			 	mov		sonardata.Start,0
				invoke STLinkWrite,hWnd,STM32_Sonar,addr sonardata.Start,8
				.if !eax || eax==IDABORT || eax==IDIGNORE
					jmp		STLinkErr
				.endif
				;Start the next phase
			 	mov		sonardata.Start,1
				invoke STLinkWrite,hWnd,STM32_Sonar,addr sonardata.Start,8
				.if !eax || eax==IDABORT || eax==IDIGNORE
					jmp		STLinkErr
				.endif
			.else
				;Data not ready yet
				invoke Sleep,10
				jmp		Again
			.endif
		.elseif fSTLink==IDIGNORE
			;Copy old echo
			call	CopyEcho
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
			mov		eax,sonarrange.pixeltimer[eax]
			mov		ecx,sonarrange.pixeltimer
			xor		edx,edx
			div		ecx
			mov		ecx,eax
			mov		eax,100
			xor		edx,edx
			div		ecx
			.if eax<3
				mov		eax,3
			.endif
			push	eax
			mov		edi,eax
			mov		edx,1
			.while edx<edi
				invoke Random,50
				add		eax,255-50
				mov		STM32Echo[edx],al
				inc		edx
			.endw
			;Show surface clutter
			invoke Random,edi
			mov		ecx,edi
			add		ecx,eax
			.while edx<ecx
				invoke Random,255
				mov		STM32Echo[edx],al
				inc		edx
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
			invoke Random,edi
			mov		edx,eax
			sub		ebx,eax
			.while edx
				;Random bottom vegetation
				.if ebx<MAXYECHO
					invoke Random,64
					add		eax,32
					mov		STM32Echo[ebx],al
				.endif
				inc		ebx
				dec		edx
			.endw
			pop		edx
			push	ebx
			shl		edx,2
			xor		ecx,ecx
			.while ecx<edx
				;Random bottom echo
				invoke Random,64
				.if ebx<MAXYECHO
					add		eax,255-64
					sub		eax,ecx
					mov		STM32Echo[ebx],al
				.endif
				inc		ebx
				inc		ecx
			.endw
			mov		eax,edx
			shl		edx,2
			invoke Random,eax
			add		edx,eax
			xor		ecx,ecx
			.while ecx<edx
				;Random bottom weak echo
				mov		eax,ecx
				xor		al,0FFh
				.if !eax
					inc		eax
				.endif
				invoke Random,eax
				.if ebx<MAXYECHO
					mov		STM32Echo[ebx],al
				.endif
				inc		ebx
				inc		ecx
			.endw
			pop		ebx
			invoke Random,ebx
			.if eax>100 && eax<MAXYECHO-1
				mov		edx,eax
				invoke Random,255
				.if eax>124 && eax<130
					;Random fish
					mov		ah,al
					mov		word ptr STM32Echo[edx],ax
					mov		word ptr STM32Echo[edx+MAXYECHO],ax
					mov		word ptr STM32Echo[edx+MAXYECHO*2],ax
				.endif
			.endif
			mov		sonardata.ADCBattery,08E0h
			mov		sonardata.ADCWaterTemp,06A0h
			mov		sonardata.ADCAirTemp,0900h
		.endif
	
		.if sonardata.hLog
			;Write to log file
			invoke WriteFile,sonardata.hLog,addr STM32Echo,MAXYECHO,addr dwwrite,NULL
		.endif
		movzx	eax,STM32Echo
		.if al!=STM32Echo[MAXYECHO]
			invoke RtlMoveMemory,addr STM32Echo[MAXYECHO*3],addr STM32Echo,MAXYECHO
			invoke RtlMoveMemory,addr STM32Echo[MAXYECHO*2],addr STM32Echo,MAXYECHO
			invoke RtlMoveMemory,addr STM32Echo[MAXYECHO*1],addr STM32Echo,MAXYECHO
		.endif
		.if rngchanged
			call	FindDepth
			dec		rngchanged
		.else
			call	FindDepth
			call	FindFish
			call	TestRangeChange
		.endif
		;Get current range index
		movzx	eax,STM32Echo
		mov		sonardata.STM32Echo,al
		invoke GetRangePtr,eax
		mov		eax,sonarrange.interval[eax]
		.if sonardata.hReply!=0 || fSTLink==IDIGNORE
			mov		ecx,REPLYSPEED
			xor		edx,edx
			div		ecx
		.endif
		mov		esi,sonardata.ChartSpeed
		xor		edx,edx
		div		esi
		mov		edi,eax
		.if esi==1
			call	Show0
		.elseif esi==2
			call	Show50
			call	Show0
		.elseif esi==3
			call	Show66
			call	Show33
			call	Show0
		.else
			call	Show75
			call	Show50
			call	Show25
			call	Show0
		.endif
	.endif
	jmp		Again

STLinkErr:
	invoke SendMessage,hWnd,WM_CLOSE,0,0
	xor		eax,eax
	ret

Show0:
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
	push	edi
	call	ScrollFish
	invoke SonarUpdateProc
	pop		edi
	invoke Sleep,edi
	retn

Show25:
	mov		ebx,1
	.if sonardata.NoiseReject
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			mov		ah,STM32Echo[ebx+MAXYECHO]
			.if al<sonardata.Noise || ah<sonardata.Noise
				mov		al,0
			.else
				;Blend in 25% of previous echo
				movzx	edx,ah
				movzx	eax,al
				shl		eax,2
				add		eax,edx
				mov		ecx,5
				xor		edx,edx
				div		ecx
				.if al<sonardata.Noise
					mov		al,0
				.endif
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.else
		.while ebx<MAXYECHO
			;Blend in 25% of previous echo
			movzx	eax,STM32Echo[ebx]
			shl		eax,2
			movzx	edx,STM32Echo[ebx+MAXYECHO]
			add		eax,edx
			mov		ecx,5
			xor		edx,edx
			div		ecx
			.if al<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.endif
	call	ScrollFish
	invoke SonarUpdateProc
	invoke Sleep,edi
	retn

Show33:
	mov		ebx,1
	.if sonardata.NoiseReject
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			mov		ah,STM32Echo[ebx+MAXYECHO]
			.if al<sonardata.Noise || ah<sonardata.Noise
				mov		al,0
			.else
				;Blend in 33% of previous echo
				movzx	eax,ah
				mov		ecx,3
				xor		edx,edx
				div		ecx
				mov		edx,eax
				movzx	eax,STM32Echo[ebx]
				add		eax,edx
				mov		ecx,3
				mul		ecx
				shr		eax,2
				.if al<sonardata.Noise
					mov		al,0
				.endif
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.else
		.while ebx<MAXYECHO
			;Blend in 33% of previous echo
			movzx	eax,STM32Echo[ebx+MAXYECHO]
			mov		ecx,3
			xor		edx,edx
			div		ecx
			mov		edx,eax
			movzx	eax,STM32Echo[ebx]
			add		eax,edx
			mov		ecx,3
			mul		ecx
			shr		eax,2
			.if al<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.endif
	call	ScrollFish
	invoke SonarUpdateProc
	invoke Sleep,edi
	retn

Show50:
	mov		ebx,1
	.if sonardata.NoiseReject
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			mov		ah,STM32Echo[ebx+MAXYECHO]
			.if al<sonardata.Noise || ah<sonardata.Noise
				mov		al,0
			.else
				;Blend in 50% of previous echo
				movzx	edx,ah
				movzx	eax,al
				add		eax,edx
				shr		eax,1
				.if al<sonardata.Noise
					mov		al,0
				.endif
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.else
		.while ebx<MAXYECHO
			;Blend in 50% of previous echo
			movzx	eax,STM32Echo[ebx]
			movzx	edx,STM32Echo[ebx+MAXYECHO]
			add		eax,edx
			shr		eax,1
			.if al<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.endif
	call	ScrollFish
	invoke SonarUpdateProc
	invoke Sleep,edi
	retn

Show66:
	mov		ebx,1
	.if sonardata.NoiseReject
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			mov		ah,STM32Echo[ebx+MAXYECHO]
			.if al<sonardata.Noise || ah<sonardata.Noise
				mov		al,0
			.else
				;Blend in 66% of previous echo
				movzx	eax,al
				mov		ecx,3
				xor		edx,edx
				div		ecx
				mov		edx,eax
				movzx	eax,STM32Echo[ebx+MAXYECHO]
				add		eax,edx
				mov		ecx,3
				mul		ecx
				shr		eax,2
				.if al<sonardata.Noise
					mov		al,0
				.endif
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.else
		.while ebx<MAXYECHO
			;Blend in 66% of previous echo
			movzx	eax,STM32Echo[ebx]
			mov		ecx,3
			xor		edx,edx
			div		ecx
			mov		edx,eax
			movzx	eax,STM32Echo[ebx+MAXYECHO]
			add		eax,edx
			mov		ecx,3
			mul		ecx
			shr		eax,2
			.if al<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.endif
	call	ScrollFish
	invoke SonarUpdateProc
	invoke Sleep,edi
	retn

Show75:
	mov		ebx,1
	.if sonardata.NoiseReject
		.while ebx<MAXYECHO
			mov		al,STM32Echo[ebx]
			mov		ah,STM32Echo[ebx+MAXYECHO]
			.if al<sonardata.Noise || ah<sonardata.Noise
				mov		al,0
			.else
				;Blend in 75% of previous echo
				movzx	edx,al
				movzx	eax,ah
				shl		eax,2
				add		eax,edx
				mov		ecx,5
				xor		edx,edx
				div		ecx
				.if al<sonardata.Noise
					mov		al,0
				.endif
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.else
		.while ebx<MAXYECHO
			;Blend in 75% of previous echo
			movzx	eax,STM32Echo[ebx+MAXYECHO]
			shl		eax,2
			movzx	edx,STM32Echo[ebx]
			add		eax,edx
			mov		ecx,5
			xor		edx,edx
			div		ecx
			.if al<sonardata.Noise
				mov		al,0
			.endif
			mov		sonardata.STM32Echo[ebx],al
			inc		ebx
		.endw
	.endif
	call	ScrollFish
	invoke SonarUpdateProc
	invoke Sleep,edi
	retn

CopyEcho:
	;Copy old echo
	invoke RtlMoveMemory,addr STM32Echo[MAXYECHO*3],addr STM32Echo[MAXYECHO*2],MAXYECHO
	invoke RtlMoveMemory,addr STM32Echo[MAXYECHO*2],addr STM32Echo[MAXYECHO*1],MAXYECHO
	invoke RtlMoveMemory,addr STM32Echo[MAXYECHO*1],addr STM32Echo[MAXYECHO*0],MAXYECHO
	retn

FindDepth:
	and		sonardata.ShowDepth,1
	;Skip blank
	mov		ebx,1
	.while ebx<32
		mov		al,STM32Echo[ebx]
		.break .if al>=sonardata.Noise
		inc		ebx
	.endw
	;Skip ping and surface clutter
	movzx	ecx,sonardata.Noise
	.while ebx<256
		xor		ch,ch
		mov		ax,word ptr STM32Echo[ebx+MAXYECHO*0]
		mov		dx,word ptr STM32Echo[ebx+MAXYECHO*0+2]
		.if al<cl && ah<cl && dl<cl && dh<cl
			inc		ch
		.endif
		mov		ax,word ptr STM32Echo[ebx+MAXYECHO*1]
		mov		dx,word ptr STM32Echo[ebx+MAXYECHO*1+2]
		.if al<cl && ah<cl && dl<cl && dh<cl
			inc		ch
		.endif
		mov		ax,word ptr STM32Echo[ebx+MAXYECHO*2]
		mov		dx,word ptr STM32Echo[ebx+MAXYECHO*2+2]
		.if al<cl && ah<cl && dl<cl && dh<cl
			inc		ch
		.endif
		mov		ax,word ptr STM32Echo[ebx+MAXYECHO*3]
		mov		dx,word ptr STM32Echo[ebx+MAXYECHO*3+2]
		.if al<cl && ah<cl && dl<cl && dh<cl
			inc		ch
		.endif
		.break .if ch==4
		inc		ebx
	.endw
	mov		sonardata.minyecho,ebx
	;Find the strongest echo in a 4x32 sqare
	xor		esi,esi
	xor		edi,edi
	.while ebx<MAXYECHO
		xor		ecx,ecx
		xor		edx,edx
		.while ecx<32
			lea		eax,[ebx+ecx]
			.break .if eax>=MAXYECHO
			movzx	eax,STM32Echo[ebx+ecx+MAXYECHO*0]
			add		edx,eax
			movzx	eax,STM32Echo[ebx+ecx+MAXYECHO*1]
			add		edx,eax
			movzx	eax,STM32Echo[ebx+ecx+MAXYECHO*2]
			add		edx,eax
			movzx	eax,STM32Echo[ebx+ecx+MAXYECHO*3]
			add		edx,eax
			inc		ecx
		.endw
		lea		eax,[edx-32*4]
		.if sdword ptr eax>esi
			mov		esi,edx
			mov		edi,ebx
		.endif
		inc		ebx
	.endw
	.if edi>1
		mov		sonardata.nodptinx,0
		mov		eax,sonardata.dptinx
		.if eax
			sub		eax,edi
			.if sdword ptr eax>MAXDEPTHJUMP
				mov		edi,sonardata.dptinx
				sub		edi,MAXDEPTHJUMP
			.elseif sdword ptr eax<-MAXDEPTHJUMP
				mov		edi,sonardata.dptinx
				add		edi,MAXDEPTHJUMP
			.endif
		.endif
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
	movzx	eax,STM32Echo
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
	.if eax>3
		mov		byte ptr buffer[eax-1],0
	.else
		movzx	ecx,word ptr buffer[eax-1]
		shl		ecx,8
		mov		cl,'.'
		mov		dword ptr buffer[eax-1],ecx
	.endif
	invoke strcpy,addr sonardata.options.text[1*sizeof OPTIONS],addr buffer
	retn

ScrollFish:
	mov		esi,offset fishdata
	mov		ecx,MAXFISH
	.while ecx
		dec		[esi].FISH.xpos
		lea		esi,[esi+sizeof FISH]
		dec		ecx
	.endw
	retn

CheckFish:
	push	esi
	push	edi
	mov		edi,MAXFISH
	mov		esi,offset fishdata
	.while edi
		.if sdword ptr [esi].FISH.xpos>512-32
			.if sdword ptr [esi].FISH.depth>ecx && sdword ptr [esi].FISH.depth<edx
				;The detected fish is close to a previously detected fish, ignore it
				xor		eax,eax
				.break
			.endif
		.endif
		dec		edi
		lea		esi,[esi+sizeof FISH]
	.endw
	pop		edx
	pop		esi
	retn

FindFish:
	.if sonardata.FishDetect || sonardata.FishAlarm
		mov		ebx,sonardata.minyecho
		mov		edi,sonardata.dptinx
		.if !edi
			;Depth unknowm
			retn
		.elseif edi>sonardata.minyecho
			;Skip bottom vegetation
			movzx	ecx,sonardata.Noise
			.while edi>ebx
				dec		edi
				mov		ax,word ptr STM32Echo[edi]
				mov		dx,word ptr STM32Echo[edi+MAXYECHO]
				.if al<cl && ah<cl && dl<cl && dh<cl
					inc		ch
				.else
					xor		ch,ch
				.endif
				.break .if ch==5
			.endw
		.else
			;Too shallow
			retn
		.endif
		.while ebx<edi
			mov		ax,word ptr STM32Echo[ebx]
			;2x3
			mov		dx,word ptr STM32Echo[ebx+MAXYECHO]
			mov		cx,word ptr STM32Echo[ebx+MAXYECHO*2]
			.if sonardata.FishDetect==2
				;2x2
				mov		cx,ax
			.elseif sonardata.FishDetect==3
				;2x1
				mov		dx,ax
				mov		cx,ax
			.endif
			.if al>=SMALLFISHECHO && ah>=SMALLFISHECHO && dl>=SMALLFISHECHO && dh>=SMALLFISHECHO && cl>=SMALLFISHECHO && ch>=SMALLFISHECHO
				.if sonardata.FishDetect
					mov		eax,fishinx
					mov		ecx,sizeof FISH
					mul		ecx
					mov		esi,eax
					movzx	eax,STM32Echo
					invoke GetRangePtr,eax
					mov		edx,sonarrange.range[eax]
					call	CalculateDepth
					mov		ecx,eax
					sub		ecx,edx
					lea		edx,[eax+edx]
					call	CheckFish
					.if eax
						movzx	edx,STM32Echo[ebx]
						.if edx>=LARGEFISHECHO
							;Large fish
							mov		edx,18
						.else
							;Small fish
							mov		edx,17
						.endif
						;Update the fishdata array
						mov		fishdata.fishtype[esi],edx
						mov		fishdata.xpos[esi],511
						mov		fishdata.depth[esi],eax
						;Increment the fishdata index
						mov		eax,fishinx
						inc		eax
						.if eax==MAXFISH
							xor		eax,eax
						.endif
						mov		fishinx,eax
					.endif
				.endif
				.if sonardata.FishAlarm && !fFishSound
					mov		fFishSound,3
					invoke PlaySound,addr szFishSound,hInstance,SND_ASYNC
				.endif
				.break
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
					mov		rngchanged,8
					mov		sonardata.dptinx,0
				.endif
			.endif
		.else
			;Check if range should be changed
			.if eax && ebx<MAXYECHO/3
				;Range decrement
				dec		eax
				invoke SetRange,eax
				mov		rngchanged,8
				mov		sonardata.dptinx,0
			.elseif eax<edx && ebx>(MAXYECHO-MAXYECHO/5)
				;Range increment
				inc		eax
				invoke SetRange,eax
				mov		rngchanged,8
				mov		sonardata.dptinx,0
			.endif
		.endif
	.endif
	retn

STM32Thread endp

ShowRangeDepthTempScaleFish proc uses ebx esi edi,hDC:HDC
	LOCAL	rcsonar:RECT
	LOCAL	rect:RECT
	LOCAL	x:DWORD
	LOCAL	tmp:DWORD
	LOCAL	nticks:DWORD
	LOCAL	ntick:DWORD

	invoke GetClientRect,hSonar,addr rcsonar
	call	ShowFish
	invoke SetBkMode,hDC,TRANSPARENT
	call	ShowScale
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
	ret

ShowFish:
	movzx	eax,sonardata.STM32Echo
	invoke GetRangePtr,eax
	mov		eax,sonarrange.range[eax]
	mov		ebx,10
	mul		ebx
	mov		ebx,eax
	mov		ecx,MAXFISH
	mov		esi,offset fishdata
	.while ecx
		push	ecx
		.if [esi].FISH.fishtype && sdword ptr [esi].FISH.xpos>=-10 && [esi].FISH.depth<=ebx
			mov		eax,[esi].FISH.depth
			mov		edx,rcsonar.bottom
			mul		edx
			xor		edx,edx
			div		ebx
			mov		edx,[esi].FISH.xpos
			sub		edx,MAXXECHO+SIGNALBAR
			add		edx,rcsonar.right
			invoke ImageList_Draw,hIml,[esi].FISH.fishtype,hDC,addr [edx-8],eax,ILD_TRANSPARENT
		.endif
		pop		ecx
		lea		esi,[esi+sizeof FISH]
		dec		ecx
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

DrawTick:
	mov		eax,rect.bottom
	sub		eax,rect.top
	mov		tmp,eax
	fild	tmp
	fild	nticks
	fdivp	st(1),st
	fild	ntick
	fmulp	st(1),st
	fistp	tmp
	mov		eax,rect.top
	add		tmp,eax
	invoke MoveToEx,hDC,rect.left,tmp,NULL
	invoke LineTo,hDC,rect.right,tmp
	.if !ntick
		add		tmp,2
	.else
		sub		tmp,18
	.endif
	push	rect.left
	push	rect.top
	push	rect.right
	sub		rect.left,20
	add		rect.right,20
	mov		eax,tmp
	mov		rect.top,eax
	invoke TextDraw,hDC,NULL,addr rect,esi,DT_CENTER or DT_TOP or DT_SINGLELINE
	pop		rect.right
	pop		rect.top
	pop		rect.left
	retn

DrawScaleBar:
	mov		ebx,rect.right
	sub		ebx,rect.left
	shr		ebx,1
	add		ebx,rect.left
	invoke MoveToEx,hDC,ebx,rect.top,NULL
	invoke LineTo,hDC,ebx,rect.bottom
	movzx	eax,sonardata.STM32Echo
	invoke GetRangePtr,eax
	mov		edx,sonarrange.nticks[eax]
	mov		nticks,edx
	mov		ntick,0
	lea		esi,sonarrange.scale[eax]
	.while dword ptr ntick<=edx
		push	edx
		call	DrawTick
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		pop		edx
		inc		ntick
	.endw
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
	movzx	eax,sonardata.PingTimer
	invoke PutItemInt,addr buffer,eax
	invoke PutItemInt,addr buffer,sonardata.SoundSpeed
	invoke WritePrivateProfileString,addr szIniSonar,addr szIniSonar,addr buffer[1],addr szIniFileName
	ret

SaveSonarToIni endp

LoadSonarFromIni proc uses ebx edi
	LOCAL	buffer[256]:BYTE
	
	invoke RtlZeroMemory,addr buffer,sizeof buffer
	invoke GetPrivateProfileString,addr szIniSonar,addr szIniSonar,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	;Width,AutoRange,AutoGain,AutoPing,FishDetect,FishAlarm,RangeInx,Noise,PingInit,GainInit,ChartSpeed,NoiseReject,ChartSync,PingTimer,SoundSpeed
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
	invoke GetItemInt,addr buffer,15
	mov		sonardata.Noise,al
	invoke GetItemInt,addr buffer,63
	mov		sonardata.PingInit,eax
	invoke GetItemInt,addr buffer,63
	mov		sonardata.GainInit,eax
	invoke GetItemInt,addr buffer,0
	mov		sonardata.ChartSpeed,eax
	invoke GetItemInt,addr buffer,1
	mov		sonardata.NoiseReject,eax
	invoke GetItemInt,addr buffer,STM32_PingTimer
	mov		sonardata.PingTimer,al
	invoke GetItemInt,addr buffer,(SOUNDSPEEDMAX+SOUNDSPEEDMIN)/2
	mov		sonardata.SoundSpeed,eax
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
		mov		sonarrange.pingadd[edi],eax
		invoke GetItemInt,addr buffer,0
		mov		sonarrange.gaininc[edi],eax
		lea		esi,sonarrange.scale[edi]
		invoke strcpy,esi,addr buffer
		xor		eax,eax
		.while byte ptr [esi]
			.if byte ptr [esi]==','
				inc		eax
				mov		byte ptr [esi],0
			.endif
			inc		esi
		.endw
		mov		sonarrange.nticks[edi],eax
		inc		ebx
		lea		edi,[edi+sizeof RANGE]
	.endw
	;Store the number of range definitions read from ini
	mov		sonardata.MaxRange,ebx
	invoke SetupPixelTimer
	ret

LoadSonarFromIni endp

SonarClear proc uses ebx esi
	LOCAL	rect:RECT

	invoke RtlZeroMemory,addr fishdata,MAXFISH*sizeof FISH
	invoke RtlZeroMemory,addr STM32Echo,sizeof STM32Echo
	invoke RtlZeroMemory,addr sonardata.STM32Echo,sizeof sonardata.STM32Echo
	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,MAXXECHO
	mov		rect.bottom,MAXYECHO
	invoke FillRect,sonardata.mDC,addr rect,sonardata.hBrBack
	invoke GetClientRect,hSonar,addr rect
	mov		rect.right,SIGNALBAR
	
	invoke FillRect,sonardata.mDCS,addr rect,sonardata.hBrBack
	lea		esi,sonardata.sonarbmp
	mov		ebx,MAXSONARBMP
	.while ebx
		.if [esi].SONARBMP.hBmp
			invoke DeleteObject,[esi].SONARBMP.hBmp
			mov		[esi].SONARBMP.hBmp,0
		.endif
		lea		esi,[esi+sizeof SONARBMP]
		dec		ebx
	.endw
	movzx	eax,sonardata.RangeInx
	mov		sonardata.sonarbmp.RangeInx,eax
	mov		sonardata.sonarbmp.xpos,MAXXECHO
	mov		sonardata.sonarbmp.wt,0
	mov		sonardata.sonarbmp.hBmp,0
	invoke InvalidateRect,hSonar,NULL,TRUE
	ret

SonarClear endp

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

		movzx	eax,sonardata.RangeInx
		mov		sonardata.sonarbmp.RangeInx,eax
		mov		sonardata.sonarbmp.xpos,MAXXECHO
		mov		sonardata.sonarbmp.wt,0
		mov		sonardata.sonarbmp.hBmp,0

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
		invoke SonarClear
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
	.elseif eax==WM_HSCROLL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		.if edx==SB_THUMBPOSITION
			.if sonardata.hReply
				push	eax
				invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
				pop		eax
				shl		eax,9
				invoke SetFilePointer,sonardata.hReply,eax,NULL,0
			.endif
		.elseif edx==SB_LINEDOWN
		.elseif edx==SB_LINEUP
		.elseif edx==SB_PAGEDOWN
		.elseif edx==SB_PAGEUP
		.endif
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

SonarProc endp
