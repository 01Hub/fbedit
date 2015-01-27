
.code

FpToAscii proc USES esi edi,lpFpin:DWORD,lpStr:DWORD,fSci:DWORD
	LOCAL	iExp:DWORD
	LOCAL	sztemp[32]:BYTE
	LOCAL	temp:REAL10

	mov		esi,lpFpin
	mov		edi,lpStr
	.if	dword ptr [esi]== 0 && dword ptr [esi+4]==0
		; Special case zero.  fxtract fails for zero.
		mov		word ptr [edi], '0'
		ret
	.endif
	; Check for a negative number.
	push	[esi+6]
	.if	sdword ptr [esi+6]<0
		and		byte ptr [esi+9],07fh	; change to positive
		mov		byte ptr [edi],'-'		; store a minus sign
		inc		edi
	.endif
	fld		REAL10 ptr [esi]
	fld		st(0)
	; Compute the closest power of 10 below the number.  We can't get an
	; exact value because of rounding.  We could get close by adding in
	; log10(mantissa), but it still wouldn't be exact.  Since we'll have to
	; check the result anyway, it's silly to waste cycles worrying about
	; the mantissa.
	;
	; The exponent is basically log2(lpfpin).  Those of you who remember
	; algebra realize that log2(lpfpin) x log10(2) = log10(lpfpin), which is
	; what we want.
	fxtract					; ST=> mantissa, exponent, [lpfpin]
	fstp	st(0)			; drop the mantissa
	fldlg2					; push log10(2)
	fmulp	st(1),st		; ST = log10([lpfpin]), [lpfpin]
	fistp 	iExp			; ST = [lpfpin]
	; A 10-byte double can carry 19.5 digits, but fbstp only stores 18.
	.IF	iExp<18
		fld		st(0)		; ST = lpfpin, lpfpin
		frndint				; ST = int(lpfpin), lpfpin
		fcomp	st(1)		; ST = lpfpin, status set
		fstsw	ax
		.IF ah&FP_EQUALTO && !fSci	; if EQUAL
			; We have an integer!  Lucky day.  Go convert it into a temp buffer.
			call FloatToBCD
			mov		eax,17
			mov		ecx,iExp
			sub		eax,ecx
			inc		ecx
			lea		esi,[sztemp+eax]
			; The off-by-one order of magnitude problem below can hit us here.  
			; We just trim off the possible leading zero.
			.IF byte ptr [esi]=='0'
				inc esi
				dec ecx
			.ENDIF
			; Copy the rest of the converted BCD value to our buffer.
			rep movsb
			jmp ftsExit
		.ENDIF
	.ENDIF
	; Have fbstp round to 17 places.
	mov		eax, 17			; experiment
	sub		eax,iExp		; adjust exponent to 17
	call PowerOf10
	; Either we have exactly 17 digits, or we have exactly 16 digits.  We can
	; detect that condition and adjust now.
	fcom	ten16
	; x0xxxx00 means top of stack > ten16
	; x0xxxx01 means top of stack < ten16
	; x1xxxx00 means top of stack = ten16
	fstsw	ax
	.IF ah & 1
		fmul	ten
		dec		iExp
	.ENDIF
	; Go convert to BCD.
	call FloatToBCD
	lea		esi,sztemp		; point to converted buffer
	; If the exponent is between -15 and 16, we should express this as a number
	; without scientific notation.
	mov ecx, iExp
	.IF SDWORD PTR ecx>=-15 && SDWORD PTR ecx<=16 && !fSci
		; If the exponent is less than zero, we insert '0.', then -ecx
		; leading zeros, then 16 digits of mantissa.  If the exponent is
		; positive, we copy ecx+1 digits, then a decimal point (maybe), then 
		; the remaining 16-ecx digits.
		inc ecx
		.IF SDWORD PTR ecx<=0
			mov		word ptr [edi],'.0'
			add		edi, 2
			neg		ecx
			mov		al,'0'
			rep		stosb
			mov		ecx,18
		.ELSE
			.if byte ptr [esi]=='0' && ecx>1
				inc		esi
				dec		ecx
			.endif
			rep		movsb
			mov		byte ptr [edi],'.'
			inc		edi
			mov		ecx,17
			sub		ecx,iExp
		.ENDIF
		rep movsb
		; Trim off trailing zeros.
		.WHILE byte ptr [edi-1]=='0'
			dec		edi
		.ENDW
		; If we cleared out all the decimal digits, kill the decimal point, too.
		.IF byte ptr [edi-1]=='.'
			dec		edi
		.ENDIF
		; That's it.
		jmp		ftsExit
	.ENDIF
	; Now convert this to a standard, usable format.  If needed, a minus
	; sign is already present in the outgoing buffer, and edi already points
	; past it.
	mov		ecx,17
	.if byte ptr [esi]=='0'
		inc		esi
		dec		iExp
		dec		ecx
	.endif
	movsb						; copy the first digit
	mov		byte ptr [edi],'.'	; plop in a decimal point
	inc		edi
	rep movsb
	; The printf %g specified trims off trailing zeros here.  I dislike
	; this, so I've disabled it.  Comment out the if 0 and endif if you
	; want this.
	.WHILE byte ptr [edi-1]=='0'
		dec		edi
	.ENDW
	.if byte ptr [edi-1]=='.'
		dec		edi
	.endif
	; Shove in the exponent.
	mov		byte ptr [edi],'e'	; start the exponent
	mov		eax,iExp
	.IF sdword ptr eax<0		; plop in the exponent sign
		mov		byte ptr [edi+1],'-'
		neg		eax
	.ELSE
		mov		byte ptr [edi+1],'+'
	.ENDIF
	mov		ecx, 10
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+5],dl		; shove in the ones exponent digit
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+4],dl		; shove in the tens exponent digit
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+3],dl		; shove in the hundreds exponent digit
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+2],dl		; shove in the thousands exponent digit
	add		edi,6			; point to terminator
ftsExit:
	; Clean up and go home.
	mov		esi,lpFpin
	pop		[esi+6]
	mov		byte ptr [edi],0
	fwait
	ret

; Convert a floating point register to ASCII.
; The result always has exactly 18 digits, with zero padding on the
; left if required.
;
; Entry:	ST(0) = a number to convert, 0 <= ST(0) < 1E19.
;			sztemp = an 18-character buffer.
;
; Exit:		sztemp = the converted result.
FloatToBCD:
	push	esi
	push	edi
    fbstp	temp
	; Now we need to unpack the BCD to ASCII.
    lea		esi,[temp]
    lea		edi,[sztemp]
    mov		ecx,8
    .REPEAT
		movzx	ax,byte ptr [esi+ecx]	; 0000 0000 AAAA BBBB
		rol		ax,12					; BBBB 0000 0000 AAAA
		shr		ah,4					; 0000 BBBB 0000 AAAA
		add		ax,3030h				; 3B3A
		stosw
		dec		ecx
    .UNTIL SIGN?
	pop		edi
	pop		esi
    retn

PowerOf10:
    mov		ecx,eax
    .IF	SDWORD PTR eax<0
		neg		eax
    .ENDIF
    fld1
    mov		dl,al
    and		edx,0fh
    .IF	!ZERO?
		lea		edx,[edx+edx*4]
		fld		ten_1[edx*2][-10]
		fmulp	st(1),st
    .ENDIF
    mov		dl,al
    shr		dl,4
    and		edx,0fh
    .IF !ZERO?
		lea		edx,[edx+edx*4]
		fld		ten_16[edx*2][-10]
		fmulp	st(1),st
    .ENDIF
    mov		dl,ah
    and		edx,1fh
    .IF !ZERO?
		lea		edx,[edx+edx*4]
		fld		ten_256[edx*2][-10]
		fmulp	st(1),st
    .ENDIF
    .IF SDWORD PTR ecx<0
		fdivp	st(1),st
    .ELSE
		fmulp	st(1),st
    .ENDIF
    retn

FpToAscii endp

PrintFp proc lpFP:ptr REAL10
	LOCAL	buffer[256]:BYTE

	invoke FpToAscii,lpFP,addr buffer,FALSE
	lea		eax,buffer
	PrintStringByAddr eax
	ret

PrintFp endp

;**** LC Meter

;------------------------------------------------------------------
;Capacitance meter: Cx=((((F1/F3)^2)-1)/(((F1/F2)^2)-1))*Ccal
;IN:	Nothing
;OUT:	Nothing
;------------------------------------------------------------------
CalculateCapacitor proc uses esi,lpBuffer:PTR BYTE
	LOCAL	tmp:REAL10
	LOCAL	iExp:DWORD

	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Frq.Frequency
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		tmp
	fld		tmp
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal1
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		tmp
	fld		tmp
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fdivp	st(1),st
	fld		REAL10 ptr [CCal]
	fmulp	st(1),st
	fstp	REAL10 ptr [LCx]
	fld		REAL10 ptr [LCx]
	fxtract					; ST=> mantissa, exponent, [lpfpin]
	fstp	st(0)			; drop the mantissa
	fldlg2					; push log10(2)
	fmulp	st(1),st		; ST = log10([lpfpin]), [lpfpin]
	fistp 	iExp			; ST = [lpfpin]
	.if sdword ptr iExp<=-10
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_12]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szPF
	.elseif  sdword ptr iExp<=-7
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_9]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szNF
	.else
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_6]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szUF
	.endif
	invoke FpToAscii,offset LCx,lpBuffer,FALSE
	mov		edx,lpBuffer
	xor		ecx,ecx
	.if byte ptr [edx]=='-'
		mov		word ptr [edx],'0'
	.endif
	.while byte ptr [edx]
		.if byte ptr [edx]=='.'
			mov		byte ptr [edx+4],0
			inc		edx
			.break
		.elseif byte ptr [edx]!='0'
			inc		ecx
		.endif
		inc		edx
	.endw
	.while byte ptr [edx]
		.if byte ptr [edx]!='0'
			inc		ecx
			.break
		.endif
		inc		edx
	.endw
	.if !ecx
		mov		edx,lpBuffer
		mov		word ptr [edx],'0'
	.endif
	invoke lstrcat,lpBuffer,esi
	ret

CalculateCapacitor endp

;------------------------------------------------------------------
;Induktance meter: Lx=(((F1/F3)^2)-1)*(((F1/F2)^2)-1)*(1/Ccal)*(1/(2*PI*F1))^2
;IN:	Nothing
;OUT:	Nothing
;------------------------------------------------------------------
CalculateInductor proc uses esi,lpBuffer:PTR BYTE
	LOCAL	tmp:REAL10
	LOCAL	tmpa:REAL10
	LOCAL	tmpb:REAL10
	LOCAL	tmpc:REAL10
	LOCAL	tmpd:REAL10
	LOCAL	iExp:DWORD

	; (((F1/F3)^2)-1)
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Frq.Frequency
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fstp	REAL10 ptr [tmpa]
	; (((F1/F2)^2)-1)
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal1
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fstp	REAL10 ptr [tmpb]
	; (1/Ccal)
	fld1
	fld		REAL10 ptr [CCal]
	fdivp	st(1),st
	fstp	REAL10 ptr [tmpc]
	; (1/(2PI*F1))^2
	fldpi
	fld		REAL10 ptr [two]
	fmulp	st(1),st
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fmulp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld1
	fld		REAL10 ptr [tmp]
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fmulp	st(1),st
	fstp	REAL10 ptr [tmpd]
	fld		REAL10 ptr [tmpd]
	fld		REAL10 ptr [tmpa]
	fmulp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmpb]
	fmulp	st(1),st
	fld		REAL10 ptr [tmpc]
	fmulp	st(1),st
	fstp	REAL10 ptr [LCx]
	fld		REAL10 ptr [LCx]
	fxtract					; ST=> mantissa, exponent, [lpfpin]
	fstp	st(0)			; drop the mantissa
	fldlg2					; push log10(2)
	fmulp	st(1),st		; ST = log10([lpfpin]), [lpfpin]
	fistp 	iExp			; ST = [lpfpin]
	.if  sdword ptr iExp<=-7
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_9]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szNH
	.elseif  sdword ptr iExp<=-3
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_6]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szUH
	.elseif  sdword ptr iExp<=-1
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_3]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szMH
	.else
		mov		esi,offset szH
	.endif
	invoke FpToAscii,offset LCx,lpBuffer,FALSE
	mov		edx,lpBuffer
	xor		ecx,ecx
	.if byte ptr [edx]=='-'
		mov		word ptr [edx],'0'
	.endif
	.while byte ptr [edx]
		.if byte ptr [edx]=='.'
			mov		byte ptr [edx+4],0
			inc		edx
			.break
		.elseif byte ptr [edx]!='0'
			inc		ecx
		.endif
		inc		edx
	.endw
	.while byte ptr [edx]
		.if byte ptr [edx]!='0'
			inc		ecx
			.break
		.endif
		inc		edx
	.endw
	.if !ecx
		mov		edx,lpBuffer
		mov		word ptr [edx],'0'
	.endif
	invoke lstrcat,lpBuffer,esi
	ret

CalculateInductor endp

;**** High speed clock

FrequencyToClock proc uses ebx,frq:DWORD,clkdiv:DWORD

	mov		ebx,1
	.while TRUE
		mov		eax,clkdiv
		cdq
		div		ebx
		cdq
		mov		ecx,frq
		div		ecx
		.break .if eax<=65536
		inc		ebx
	.endw
	ret

FrequencyToClock endp

ClockToFrequency proc count:DWORD,clk:DWORD

	mov		eax,clk
	cdq
	mov		ecx,count
	div		ecx
	ret

ClockToFrequency endp

GetHSCFrq proc uses ebx esi edi,frq:DWORD,lpRes:DWORD,lpTIMARR:DWORD

	mov		eax,frq
	.if eax<3
		mov		ebx,STM32_CLOCK/2048
		mov		esi,1023
	.elseif eax<6
		mov		ebx,STM32_CLOCK/1024
		mov		esi,511
	.elseif eax<12
		mov		ebx,STM32_CLOCK/512
		mov		esi,255
	.elseif eax<24
		mov		ebx,STM32_CLOCK/256
		mov		esi,127
	.elseif eax<48
		mov		ebx,STM32_CLOCK/128
		mov		esi,63
	.elseif eax<96
		mov		ebx,STM32_CLOCK/64
		mov		esi,31
	.elseif eax<192
		mov		ebx,STM32_CLOCK/32
		mov		esi,15
	.elseif eax<382
		mov		ebx,STM32_CLOCK/16
		mov		esi,7
	.elseif eax<763
		mov		ebx,STM32_CLOCK/8
		mov		esi,3
	.else
		mov		ebx,STM32_CLOCK/4
		mov		esi,1
	.endif
	invoke FrequencyToClock,eax,ebx
	push	eax
	invoke ClockToFrequency,eax,ebx
	mov		edi,lpRes
	mov		[edi],eax
	mov		edi,lpTIMARR
	mov		[edi],esi
	pop		eax
	ret

GetHSCFrq endp

SetHSC proc hWin:HWND,frq:DWORD
	LOCAL	resfrq:DWORD
	LOCAL	timarr:DWORD

	invoke GetHSCFrq,frq,addr resfrq,addr timarr
	dec		eax
	mov		STM32_Cmd.STM32_Hsc.HSCDiv,eax
	mov		eax,timarr
	mov		STM32_Cmd.STM32_Hsc.HSCSet,eax
	invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,resfrq,FALSE
	.if fBluetooth
		mov		mode,CMD_HSCSET
	.endif
	ret

SetHSC endp

;**** Scope

GetSampleTime proc uses esi,lpSTM32_Scp:ptr STM32_SCP
	LOCAL	iTmp:DWORD

	;Get sample rate in Hz
	mov		esi,lpSTM32_Scp
	mov		iTmp,STM32_CLOCK/2
	fild	iTmp
	mov		eax,[esi].STM32_SCP.ADC_Prescaler
	inc		eax
	shl		eax,1
	mov		iTmp,eax
	fild	iTmp
	fdivp	st(1),st
	.if [esi].STM32_SCP.ADC_TripleMode
		mov		eax,[esi].STM32_SCP.ADC_TwoSamplingDelay
		add		eax,5
	.else
		mov		eax,[esi].STM32_SCP.ADC_SampleTime
		mov		eax,ADCSingle_SampleClocks[eax*DWORD]
		add		eax,12
	.endif
	mov		iTmp,eax
	fild	iTmp
	fdivp	st(1),st
	fstp	SampleRate
	;Get sample time in ns
	fld		ten_9
	fld		SampleRate
	fdivp	st(1),st
	fstp	SampleTime
;invoke PrintFp,addr SampleTime
	ret

GetSampleTime endp

GetSignalPeriod proc

	;Get signals period in ns
	fld		ten_9
	fild	STM32_Cmd.STM32_Frq.FrequencySCP
	fdivp	st(1),st
	fistp	SignalPeriod
	ret

GetSignalPeriod endp

GetSamplesPrPeriod proc
	
	fild	SignalPeriod
	fld		SampleTime
	fdivp	st(1),st
	fistp	SamplesPrPeriod
	ret

GetSamplesPrPeriod endp

GetTotalSamples proc uses esi,lpSTM32_Scp:ptr STM32_SCP
	LOCAL	iTmp:DWORD

	;Get time/div*GRIDX (10)
	mov		esi,lpSTM32_Scp
	mov		eax,[esi].STM32_SCP.ScopeTimeDiv
	mov		ecx,sizeof SCOPETIME
	mul		ecx
	mov		eax,ScopeTime.time[eax]
	mov		ecx,GRIDX
	mul		ecx
	mov		iTmp,eax
	fild	iTmp
	fld		SampleTime
	fdivp	st(1),st
	fistp	iTmp
	mov		eax,iTmp
	shl		eax,1
	.if [esi].STM32_SCP.fSubSampling
		shl		eax,3
	.endif
	shr		eax,2
	inc		eax
	shl		eax,2
	mov		edx,eax
	shr		edx,2
	and		edx,0FFFFFFFCh
	add		eax,edx
	.if eax>10000h
		mov		eax,10000h
	.endif
	ret

GetTotalSamples endp

GetAuto proc uses ebx esi edi,hWin:HWND

	;Set Time/Div
	invoke GetSignalPeriod
	mov		eax,SignalPeriod
	shr		eax,2
	xor		ebx,ebx
	xor		esi,esi
	.while ebx<=MAXSCPTIMEDIV
		.break .if eax<ScopeTime.time[esi]
		inc		ebx
		lea		esi,[esi+sizeof SCOPETIME]
	.endw
	mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,ebx
	invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETPOS,TRUE,ebx
	;Set Sample rate
	mov		STM32_Cmd.STM32_Scp.ADC_TripleMode,FALSE
	mov		STM32_Cmd.STM32_Scp.ADC_SampleTime,0
	.while TRUE
		mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,3
		.while TRUE
			invoke GetSampleTime,offset STM32_Cmd.STM32_Scp
			invoke GetSamplesPrPeriod
			mov		eax,SamplesPrPeriod
			.break .if eax>200 || !STM32_Cmd.STM32_Scp.ADC_Prescaler
			dec		STM32_Cmd.STM32_Scp.ADC_Prescaler
		.endw
		.break .if eax<300 || STM32_Cmd.STM32_Scp.ADC_SampleTime==7
		inc		STM32_Cmd.STM32_Scp.ADC_SampleTime
	.endw
	.if eax<200
		mov		STM32_Cmd.STM32_Scp.ADC_TripleMode,TRUE
		mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,0
		.while TRUE
			mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,3
			.while TRUE
				invoke GetSampleTime,offset STM32_Cmd.STM32_Scp
				invoke GetSamplesPrPeriod
				mov		eax,SamplesPrPeriod
				.break .if eax>200 || !STM32_Cmd.STM32_Scp.ADC_Prescaler
				dec		STM32_Cmd.STM32_Scp.ADC_Prescaler
			.endw
			.break .if eax<300 || STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay==20-5
			inc		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
		.endw
	.endif
	mov		eax,BST_UNCHECKED
	.if STM32_Cmd.STM32_Scp.ADC_TripleMode
		mov		eax,BST_CHECKED
	.endif
	invoke SendDlgItemMessage,hWin,IDC_CHKTRIPLE,BM_SETCHECK,eax,0
	mov		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
	sub		eax,3
	neg		eax
	invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETPOS,TRUE,eax
	.if STM32_Cmd.STM32_Scp.ADC_TripleMode
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETRANGE,FALSE,(20-5) SHL 16
		mov		eax,20-5
		sub		eax,STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
	.else
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETRANGE,FALSE,7 SHL 16
		mov		eax,7
		sub		eax,STM32_Cmd.STM32_Scp.ADC_SampleTime
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
	.endif
	ret

GetAuto endp

ScopeSubSampling proc uses ebx esi edi
	LOCAL	nsample:DWORD
	LOCAL	adcperiod:REAL10
	LOCAL	iTmp:DWORD
	LOCAL	frq:DWORD

	mov		fNoFrequency,TRUE
	mov		eax,STM32_Cmd.STM32_Frq.FrequencySCP
	.if eax>10000
		mov		fNoFrequency,FALSE
		mov		frq,eax
		;Get signals period in ns
		fld		ten_9
		fild	frq
		fdivp	st(1),st
		fstp	adcperiod
		xor		edi,edi
		.while edi<2048
			mov		SubSample[edi*DWORD],0
			mov		SubSampleCount[edi*WORD],0
			inc		edi
		.endw
		mov		esi,offset ADC_Data
		mov		eax,SamplesPrPeriod
		shl		eax,4
		add		eax,ADCSAMPLESTART
		.if eax>STM32_Scp.ADC_SampleSize
			mov		eax,STM32_Scp.ADC_SampleSize
		.endif
		mov		nsample,eax
		mov		ebx,ADCSAMPLESTART
		.while ebx<nsample
			fld		SampleTime
			mov		iTmp,2048
			fild	iTmp
			fmulp	st(1),st
			mov		iTmp,ebx
			fild	iTmp
			fmulp	st(1),st
			fld		adcperiod
			fdivp	st(1),st
			fistp	iTmp
			mov		edi,iTmp
			and		edi,2048-1
			movzx	eax,ADC_Data[ebx*WORD]
			add		SubSample[edi*DWORD],eax
			inc		SubSampleCount[edi*WORD]
			inc		ebx
		.endw
		xor		esi,esi
		xor		ebx,ebx
		.while ebx<2048
			movzx	ecx,SubSampleCount[ebx*WORD]
			.if ecx
				inc		esi
				mov		eax,SubSample[ebx*DWORD]
				cdq
				div		ecx
				.if !eax
					inc		eax
				.endif
				mov		SubSample[ebx*DWORD],eax
			.endif
			inc		ebx
		.endw
	.endif
;PrintDec esi
	ret

ScopeSubSampling endp

SetMode proc
	LOCAL	buffer[64]:BYTE

	invoke lstrcpy,addr buffer,offset szLCMeter
	.if mode==CMD_LCMCAL
		mov		eax,offset szCalibrate
	.elseif mode==CMD_LCMCAP
		mov		eax,offset szCapacitance
	.elseif mode==CMD_LCMIND
		mov		eax,offset szInductance
	.elseif mode==CMD_FRQCH1
		mov		eax,offset szFerquencyCH1
	.elseif mode==CMD_FRQCH2
		mov		eax,offset szFerquencyCH2
	.elseif mode==CMD_FRQCH3
		mov		eax,offset szFerquencyCH3
	.elseif mode==CMD_SCPSET
		mov		eax,offset szScope
	.elseif mode==CMD_DDSSET
		mov		eax,offset szDDS
	.elseif mode==CMD_LGASET
		mov		eax,offset szLGA
	.else
		mov		eax,offset szLCM
	.endif
	invoke lstrcat,addr buffer,eax
	invoke SetWindowText,hWnd,addr buffer
	ret

SetMode endp

FormatFrequency proc uses ebx esi edi,frq:DWORD,lpBuffer:DWORD

	mov		eax,frq
	.if eax<1000
		;Hz
		invoke wsprintf,lpBuffer,addr szFmtHz,eax
	.elseif eax<1000000
		;KHz
		invoke wsprintf,lpBuffer,addr szFmtKHz,eax
		mov		ebx,6
		call	InsertDot
	.else
		;MHz
		invoke wsprintf,lpBuffer,addr szFmtMHz,eax
		mov		ebx,9
		call	InsertDot
	.endif
	ret

InsertDot:
	mov		esi,lpBuffer
	invoke lstrlen,esi
	mov		edx,eax
	sub		ebx,edx
	neg		ebx
	mov		al,'.'
	.while ebx<=edx
		xchg	al,[esi+ebx]
		inc		ebx
	.endw
	mov		[esi+ebx],al
	retn

FormatFrequency endp

ButtonProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_LBUTTONDOWN || eax==WM_LBUTTONDBLCLK
		mov		nBtnCount,16
		invoke SetTimer,hWin,1001,500,NULL
	.elseif eax==WM_LBUTTONUP
		invoke KillTimer,hWin,1001
		mov		nBtnCount,16
	.elseif eax==WM_TIMER
		invoke GetWindowLong,hWin,GWL_ID
		mov		ebx,eax
		invoke GetParent,hWin
		mov		esi,eax
		invoke SendMessage,esi,WM_COMMAND,ebx,hWin
		mov		edi,nBtnCount
		shr		edi,4
		.if edi>40
			mov		edi,40
		.endif
		.while edi
			invoke SendMessage,esi,WM_COMMAND,ebx,hWin
			dec		edi
		.endw
		invoke KillTimer,hWin,1001
		invoke SetTimer,hWin,1001,50,NULL
		inc		nBtnCount
		xor		eax,eax
		ret
	.endif
	invoke CallWindowProc,lpOldButtonProc,hWin,uMsg,wParam,lParam
	ret

ButtonProc endp

