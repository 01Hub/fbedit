
.code

HscChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	resfrq:DWORD
	LOCAL	timarr:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCHSC
		mov		hHsc,eax
		mov		eax,STM32_Cmd.STM32_Hsc.HSCDiv
		inc		eax
		invoke ClockToFrequency,eax,STM32_CLOCK/4
		invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,eax,FALSE
		invoke ImageList_GetIcon,hIml,0,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNHSCDN,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke ImageList_GetIcon,hIml,1,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNHSCUP,BM_SETIMAGE,IMAGE_ICON,ebx
		push	0
		push	IDC_BTNHSCDN
		mov		eax,IDC_BTNHSCUP
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		mov		eax,FALSE
		ret
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNHSCDN
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				.if eax>2
					dec		eax
					mov		resfrq,eax
					inc		eax
					.while eax!=resfrq
						dec		eax
						push	eax
						mov		edx,eax
						invoke GetHSCFrq,edx,addr resfrq,addr timarr
						pop		eax
					.endw
					invoke SetHSC,hWin,eax
				.endif
			.elseif eax==IDC_BTNHSCUP
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				.if eax<50000000
					inc		eax
					invoke SetHSC,hWin,eax
				.endif
			.endif
		.elseif edx==EN_KILLFOCUS
			.if eax==IDC_EDTHSCFRQ
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				invoke SetHSC,hWin,eax
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

HscChildProc endp
