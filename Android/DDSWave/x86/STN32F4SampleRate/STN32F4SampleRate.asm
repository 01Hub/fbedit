.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include STN32F4SampleRate.inc

.code

;########################################################################

Clear proc uses ebx esi edi

	mov		esi,offset SampleRates
	mov		edi,offset SampleRateClk
	xor		ebx,ebx
	xor		eax,eax
	.while ebx<256
		mov		[esi],eax
		mov		[edi],eax
		lea		esi,[esi+DWORD]
		lea		edi,[edi+DWORD]
		inc		ebx
	.endw
	ret

Clear endp

Exist proc uses ebx esi edi sr:DWORD

	xor		ebx,ebx
	mov		edi,sr
	xor		eax,eax
	mov		esi,offset SampleRates
	.while ebx<256
		.if edi==[esi]
			inc		eax
			.break
		.endif
		lea		esi,[esi+DWORD]
		inc		ebx
	.endw
	ret

Exist endp

GetSRTriple proc sr:DWORD

	; Get adc clock
	mov		eax,STM32F4_CLOCK/2
	cdq
	mov		ecx,sr
	shr		ecx,4
	and		ecx,3
	inc		ecx
	shl		ecx,1
	div		ecx
	cdq
	; Get adc two samplings deley
	mov		ecx,sr
	and		ecx,15
	add		ecx,5
	div		ecx
	ret

GetSRTriple endp

GetSRSingle proc sr:DWORD

	; Get adc clock
	mov		eax,STM32F4_CLOCK/2
	cdq
	mov		ecx,sr
	shr		ecx,3
	and		ecx,3
	inc		ecx
	shl		ecx,1
	div		ecx
	cdq
	mov		ecx,sr
	and		ecx,7
	mov		ecx,ADCSingle_SampleClocks[ecx*DWORD]
	add		ecx,12
	div		ecx
	ret

GetSRSingle endp

GetSRTimer proc sr:DWORD


	ret

GetSRTimer endp

Sort proc

	mov		esi,offset SampleRates
	xor		ecx,ecx
	.while ecx<256
		lea		edx,[ecx+1]
		mov		eax,[esi+ecx*DWORD]
		.while edx<256
			mov		ebx,[esi+edx*DWORD]
			.if ebx<eax
				xchg	eax,ebx
				mov		[esi+ecx*DWORD],eax
				mov		[esi+edx*DWORD],ebx
				push	eax
				mov		eax,[esi+ecx*DWORD+1024]
				xchg	eax,[esi+edx*DWORD+1024]
				mov		[esi+ecx*DWORD+1024],eax
				pop		eax
			.endif
			inc		edx
		.endw
		inc		ecx
	.endw
	ret

Sort endp

Print proc

	xor		ebx,ebx
	mov		esi,offset SampleRates
	.while ebx<256
		mov		eax,[esi+ebx*DWORD]
		mov		edx,[esi+ebx*DWORD+1024]
		.if eax
			PrintHex dl
			;PrintDec eax
		.endif
		inc		ebx
	.endw
	ret

Print endp

DlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	mov	eax,uMsg
	.if	eax==WM_INITDIALOG
		;initialization here
	.elseif	eax==WM_COMMAND
		mov edx,wParam
		movzx eax,dx
		shr edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				mov		edi,offset SampleRates
				invoke Clear
				xor		ebx,ebx
				.while ebx<64
					invoke GetSRTriple,ebx
					mov		esi,eax
					invoke Exist,eax
					.if !eax
						mov		[edi+ebx*4],esi
						mov		[edi+ebx*4+1024],ebx
;						PrintHex ebx
;						PrintDec esi
					.endif
					inc		ebx
				.endw
				.while ebx<64+32
					invoke GetSRSingle,ebx
					mov		esi,eax
					invoke Exist,eax
					.if !eax
						mov		[edi+ebx*4],esi
						mov		[edi+ebx*4+1024],ebx
;						PrintHex ebx
;						PrintDec esi
					.endif
					inc		ebx
				.endw
;				.while ebx<64+32+4
;					invoke GetSRTimer,ebx
;					inc		ebx
;				.endw
				invoke Sort
				invoke Print
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.endif
	.elseif	eax==WM_CLOSE
		invoke	EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	InitCommonControls
	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr DlgProc,NULL
	invoke	ExitProcess,0

end start
