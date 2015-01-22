
.code

SineGenerator proc uses ebx esi edi,buf:DWORD,amp:DWORD,harmonic:DWORD
	LOCAL	tmp:DWORD

	xor		ebx,ebx
	mov		edi,buf
	.while ebx<2048
		.if harmonic==0
			fld		float2
		.elseif harmonic==1
			fld		float4
		.elseif harmonic==2
			fld		float6
		.elseif harmonic==3
			fld		float8
		.endif
		fldpi
		fmulp	st(1),st
		mov		tmp,ebx
		fild	tmp
		fmulp	st(1),st
		mov		tmp,2048
		fild	tmp
		fdivp	st(1),st
		fsin
		mov		tmp,2047
		fild	tmp
		fmulp	st(1),st
		fistp	tmp
		mov		eax,tmp
		mov		ecx,amp
		imul	ecx
		mov		ecx,100
		idiv	ecx
		mov		[edi+ebx*WORD],ax
		inc		ebx
	.endw
	ret

SineGenerator endp

TriangleGenerator proc uses ebx esi edi,buf:DWORD,amp:DWORD,harmonic:DWORD
	LOCAL	buffer[256]:BYTE

	xor		ebx,ebx
	mov		eax,harmonic
	inc		eax
	shl		eax,2
	mov		esi,eax
	mov		edi,2048
	mov		edx,buf
	.while ebx<2048
		push	edx
		mov		eax,edi
		sub		eax,2048
		mov		ecx,amp
		imul	ecx
		mov		ecx,100
		idiv	ecx
		pop		edx
		mov		[edx+ebx*WORD],ax
		add		edi,esi
		.if edi>4095
			neg		esi
			add		edi,esi
		.endif
		inc		ebx
	.endw
	ret

TriangleGenerator endp

SquuareGenerator proc uses ebx esi edi,buf:DWORD,amp:DWORD,harmonic:DWORD
	LOCAL	buffer[256]:BYTE

	xor		ebx,ebx
	mov		edi,2048
	mov		edx,buf
	.while ebx<2048
		push	edx
		mov		eax,edi
		mov		ecx,amp
		imul	ecx
		mov		ecx,100
		idiv	ecx
		pop		edx
		mov		[edx+ebx*WORD],ax
		.if ebx==1023
			neg		edi
		.endif
		inc		ebx
	.endw
	ret

SquuareGenerator endp

SumHarmonicData proc uses ebx esi edi
	
	mov		edi,offset makewavedata.MW_SumHarmonicData
	invoke RtlZeroMemory,edi,2048*2
	mov		esi,offset makewavedata.MW_SecondHarmonicData
	call	SumWave
	mov		esi,offset makewavedata.MW_ThirdHarmonicData
	call	SumWave
	mov		esi,offset makewavedata.MW_FourthHarmonicData
	call	SumWave
	ret

SumWave:
	mov		edi,offset makewavedata.MW_SumHarmonicData
	xor		ebx,ebx
	.while ebx<2048
		movsx	eax,word ptr [esi+ebx*WORD]
		movsx	edx,word ptr [edi+ebx*WORD]
		add		eax,edx
		.if sdword ptr eax>2047
			mov		eax,2047
		.elseif sdword ptr eax<-2048
			mov		eax,-2048
		.endif
		mov		[edi+ebx*WORD],ax
		inc		ebx
	.endw
	retn

SumHarmonicData endp

NoiseGenerator proc uses ebx esi edi

	mov		esi,offset makewavedata.MW_RndNoiseData
	mov		edi,offset makewavedata.MW_NoiseData
	.while ebx<2048
		movsx	eax,word ptr [esi+ebx*WORD]
		mov		ecx,makewavedata.NoiseAmp
		imul	ecx
		mov		ecx,100
		idiv	ecx
		mov		ecx,100
		sub		ecx,makewavedata.NoiseFrequency
		.if ecx
			inc		ecx
			push	ecx
			push	edi
			lea		edi,[edi+ebx*WORD]
			rep		stosw
			pop		edi
			pop		ecx
			add		ebx,ecx
		.else
			mov		word ptr [edi+ebx*WORD],ax
			inc		ebx
		.endif
	.endw
	ret

NoiseGenerator endp

SumAllWaves proc uses ebx esi edi

	invoke RtlZeroMemory,offset makewavedata.MW_ResultData,2048*2
	mov		esi,offset makewavedata.MW_MainData
	call	SumWave
	mov		esi,offset makewavedata.MW_SumHarmonicData
	call	SumWave
	mov		esi,offset makewavedata.MW_NoiseData
	call	SumWave
	ret

SumWave:
	mov		edi,offset makewavedata.MW_ResultData
	xor		ebx,ebx
	.while ebx<2048
		movsx	eax,word ptr [esi+ebx*WORD]
		movsx	edx,word ptr [edi+ebx*WORD]
		add		eax,edx
		.if sdword ptr eax>2047
			mov		eax,2047
		.elseif sdword ptr eax<-2048
			mov		eax,-2048
		.endif
		mov		[edi+ebx*WORD],ax
		inc		ebx
	.endw
	retn

SumAllWaves endp


;int main(void)
;{
;    uint16_t start_state = 0xACE1u;  /* Any nonzero start state will work. */
;    uint16_t lfsr = start_state;
;    unsigned period = 0;
; 
;    do
;    {
;        unsigned lsb = lfsr & 1;  /* Get LSB (i.e., the output bit). */
;        lfsr >>= 1;               /* Shift register */
;        if (lsb == 1)             /* Only apply toggle mask if output bit is 1. */
;            lfsr ^= 0xB400u;      /* Apply toggle mask, value has 1 at bits corresponding
;                                   * to taps, 0 elsewhere. */
;        ++period;
;    } while (lfsr != start_state);
; 
;    return 0;
;}
RandomNoise proc uses ebx esi edi

	mov		edi,offset makewavedata.MW_RndNoiseData
	mov		dx,0ACE1h
	mov		ax,dx
	xor		ebx,ebx
	.repeat
		mov		cx,ax
		sub		cx,08000h
		sar		cx,4
		mov		[edi+ebx*WORD],cx
		mov		cx,ax
		and		cx,1
		shr		ax,1
		.if cx
			xor		ax,0B400h
		.endif
		inc		ebx
	.until ebx==2048
	ret

RandomNoise endp

MakeWave proc buf:DWORD,amp:DWORD,harmonic:DWORD,wavetype:DWORD

	mov		eax,wavetype
	.if eax==0
		invoke SineGenerator,buf,amp,harmonic
	.elseif eax==1
		invoke TriangleGenerator,buf,amp,harmonic
	.elseif eax==2
		invoke SquuareGenerator,buf,amp,harmonic
	.endif
	ret

MakeWave endp

MakeWaveChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[64]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hMakeWaveCld,eax
		mov		makewavedata.MainAmp,50
		mov		makewavedata.SecondHarmonicAmp,0
		mov		makewavedata.ThirdHarmonicAmp,0
		mov		makewavedata.FourthHarmonicAmp,0
		mov		makewavedata.NoiseAmp,0
		invoke CheckDlgButton,hWin,IDC_RBNRESULT,BST_CHECKED
		mov		makewavedata.ShowWave,3
		mov		makewavedata.MainType,0
		invoke CheckDlgButton,hWin,IDC_RBNMAINSINE,BST_CHECKED
		mov		makewavedata.HarmonicType,0
		invoke CheckDlgButton,hWin,IDC_RBNHARMONICSINE,BST_CHECKED

		invoke SendDlgItemMessage,hWin,IDC_TRBMA,TBM_SETRANGE,FALSE,100 SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRBMA,TBM_SETPOS,TRUE,makewavedata.MainAmp
		invoke SendDlgItemMessage,hWin,IDC_TRB2HA,TBM_SETRANGE,FALSE,100 SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRB3HA,TBM_SETRANGE,FALSE,100 SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRB4HA,TBM_SETRANGE,FALSE,100 SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRBNA,TBM_SETRANGE,FALSE,100 SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRBNF,TBM_SETRANGE,FALSE,100 SHL 16
		invoke MakeWave,offset makewavedata.MW_MainData,makewavedata.MainAmp,0,1

		invoke RandomNoise
		invoke NoiseGenerator
		invoke SumAllWaves
		invoke ImageList_GetIcon,hIml,0,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNMADN
		push	IDC_BTN2HADN
		push	IDC_BTN3HADN
		push	IDC_BTN4HADN
		push	IDC_BTNNADN
		mov		eax,IDC_BTNNFDN
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		invoke ImageList_GetIcon,hIml,1,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNMAUP
		push	IDC_BTN2HAUP
		push	IDC_BTN3HAUP
		push	IDC_BTN4HAUP
		push	IDC_BTNNAUP
		mov		eax,IDC_BTNNFUP
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_RBNMAIN && eax<=IDC_RBNRESULT
				push	eax
				invoke IsDlgButtonChecked,hWin,eax
				.if eax
					pop		eax
					sub		eax,IDC_RBNMAIN
					mov		makewavedata.ShowWave,eax
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.else
					pop		eax
				.endif
			.elseif eax>=IDC_RBNMAINSINE && eax<=IDC_RBNMAINSQUARE
				push	eax
				invoke IsDlgButtonChecked,hWin,eax
				.if eax
					pop		eax
					sub		eax,IDC_RBNMAINSINE
					mov		makewavedata.MainType,eax
					invoke MakeWave,offset makewavedata.MW_MainData,makewavedata.MainAmp,0,makewavedata.MainType
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.else
					pop		eax
				.endif
			.elseif eax>=IDC_RBNHARMONICSINE && eax<=IDC_RBNHARMONICSQUARE
				push	eax
				invoke IsDlgButtonChecked,hWin,eax
				.if eax
					pop		eax
					sub		eax,IDC_RBNHARMONICSINE
					mov		makewavedata.HarmonicType,eax
					invoke MakeWave,offset makewavedata.MW_SecondHarmonicData,makewavedata.SecondHarmonicAmp,1,makewavedata.HarmonicType
					invoke MakeWave,offset makewavedata.MW_ThirdHarmonicData,makewavedata.ThirdHarmonicAmp,2,makewavedata.HarmonicType
					invoke MakeWave,offset makewavedata.MW_FourthHarmonicData,makewavedata.FourthHarmonicAmp,3,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.else
					pop		eax
				.endif
			.elseif eax==IDC_BTNMADN
				.if makewavedata.MainAmp
					dec		makewavedata.MainAmp
					invoke SendDlgItemMessage,hWin,IDC_TRBMA,TBM_SETPOS,TRUE,makewavedata.MainAmp
					invoke MakeWave,offset makewavedata.MW_MainData,makewavedata.MainAmp,0,makewavedata.MainType
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNMAUP
				.if makewavedata.MainAmp<100
					inc		makewavedata.MainAmp
					invoke SendDlgItemMessage,hWin,IDC_TRBMA,TBM_SETPOS,TRUE,makewavedata.MainAmp
					invoke MakeWave,offset makewavedata.MW_MainData,makewavedata.MainAmp,0,makewavedata.MainType
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTN2HADN
				.if makewavedata.SecondHarmonicAmp
					dec		makewavedata.SecondHarmonicAmp
					invoke SendDlgItemMessage,hWin,IDC_TRB2HA,TBM_SETPOS,TRUE,makewavedata.SecondHarmonicAmp
					invoke MakeWave,offset makewavedata.MW_SecondHarmonicData,makewavedata.SecondHarmonicAmp,1,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTN2HAUP
				.if makewavedata.SecondHarmonicAmp<100
					inc		makewavedata.SecondHarmonicAmp
					invoke SendDlgItemMessage,hWin,IDC_TRB2HA,TBM_SETPOS,TRUE,makewavedata.SecondHarmonicAmp
					invoke MakeWave,offset makewavedata.MW_SecondHarmonicData,makewavedata.SecondHarmonicAmp,1,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTN3HADN
				.if makewavedata.ThirdHarmonicAmp
					dec		makewavedata.ThirdHarmonicAmp
					invoke SendDlgItemMessage,hWin,IDC_TRB3HA,TBM_SETPOS,TRUE,makewavedata.ThirdHarmonicAmp
					invoke MakeWave,offset makewavedata.MW_ThirdHarmonicData,makewavedata.ThirdHarmonicAmp,2,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTN3HAUP
				.if makewavedata.ThirdHarmonicAmp<100
					inc		makewavedata.ThirdHarmonicAmp
					invoke SendDlgItemMessage,hWin,IDC_TRB3HA,TBM_SETPOS,TRUE,makewavedata.ThirdHarmonicAmp
					invoke MakeWave,offset makewavedata.MW_ThirdHarmonicData,makewavedata.ThirdHarmonicAmp,2,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTN4HADN
				.if makewavedata.FourthHarmonicAmp
					dec		makewavedata.FourthHarmonicAmp
					invoke SendDlgItemMessage,hWin,IDC_TRB4HA,TBM_SETPOS,TRUE,makewavedata.FourthHarmonicAmp
					invoke MakeWave,offset makewavedata.MW_FourthHarmonicData,makewavedata.FourthHarmonicAmp,3,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTN4HAUP
				.if makewavedata.FourthHarmonicAmp<100
					inc		makewavedata.FourthHarmonicAmp
					invoke SendDlgItemMessage,hWin,IDC_TRB4HA,TBM_SETPOS,TRUE,makewavedata.FourthHarmonicAmp
					invoke MakeWave,offset makewavedata.MW_FourthHarmonicData,makewavedata.FourthHarmonicAmp,3,makewavedata.HarmonicType
					invoke SumHarmonicData
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNNADN
				.if makewavedata.NoiseAmp
					dec		makewavedata.NoiseAmp
					invoke SendDlgItemMessage,hWin,IDC_TRBNA,TBM_SETPOS,TRUE,makewavedata.NoiseAmp
					invoke NoiseGenerator
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNNAUP
				.if makewavedata.NoiseAmp<100
					inc		makewavedata.NoiseAmp
					invoke SendDlgItemMessage,hWin,IDC_TRBNA,TBM_SETPOS,TRUE,makewavedata.NoiseAmp
					invoke NoiseGenerator
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNNFDN
				.if makewavedata.NoiseFrequency
					dec		makewavedata.NoiseFrequency
					invoke SendDlgItemMessage,hWin,IDC_TRBNF,TBM_SETPOS,TRUE,makewavedata.NoiseFrequency
					invoke NoiseGenerator
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNNFUP
				.if makewavedata.NoiseFrequency<100
					inc		makewavedata.NoiseFrequency
					invoke SendDlgItemMessage,hWin,IDC_TRBNF,TBM_SETPOS,TRUE,makewavedata.NoiseFrequency
					invoke NoiseGenerator
					invoke SumAllWaves
					invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
				.endif
			.endif
		.endif
	.elseif eax==WM_HSCROLL
		invoke GetDlgCtrlID,lParam
		.if eax==IDC_TRBMA
			invoke SendDlgItemMessage,hWin,IDC_TRBMA,TBM_GETPOS,0,0
			mov		makewavedata.MainAmp,eax
			invoke MakeWave,offset makewavedata.MW_MainData,makewavedata.MainAmp,0,makewavedata.MainType
			invoke SumAllWaves
			invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
		.elseif eax==IDC_TRB2HA
			invoke SendDlgItemMessage,hWin,IDC_TRB2HA,TBM_GETPOS,0,0
			mov		makewavedata.SecondHarmonicAmp,eax
			invoke MakeWave,offset makewavedata.MW_SecondHarmonicData,makewavedata.SecondHarmonicAmp,1,makewavedata.HarmonicType
			invoke SumHarmonicData
			invoke SumAllWaves
			invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
		.elseif eax==IDC_TRB3HA
			invoke SendDlgItemMessage,hWin,IDC_TRB3HA,TBM_GETPOS,0,0
			mov		makewavedata.ThirdHarmonicAmp,eax
			invoke MakeWave,offset makewavedata.MW_ThirdHarmonicData,makewavedata.ThirdHarmonicAmp,2,makewavedata.HarmonicType
			invoke SumHarmonicData
			invoke SumAllWaves
			invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
		.elseif eax==IDC_TRB4HA
			invoke SendDlgItemMessage,hWin,IDC_TRB4HA,TBM_GETPOS,0,0
			mov		makewavedata.FourthHarmonicAmp,eax
			invoke MakeWave,offset makewavedata.MW_FourthHarmonicData,makewavedata.FourthHarmonicAmp,3,makewavedata.HarmonicType
			invoke SumHarmonicData
			invoke SumAllWaves
			invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
		.elseif eax==IDC_TRBNA
			invoke SendDlgItemMessage,hWin,IDC_TRBNA,TBM_GETPOS,0,0
			mov		makewavedata.NoiseAmp,eax
			invoke NoiseGenerator
			invoke SumAllWaves
			invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
		.elseif eax==IDC_TRBNF
			invoke SendDlgItemMessage,hWin,IDC_TRBNF,TBM_GETPOS,0,0
			mov		makewavedata.NoiseFrequency,eax
			invoke NoiseGenerator
			invoke SumAllWaves
			invoke InvalidateRect,hMakeWaveScrn,NULL,TRUE
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

MakeWaveChildProc endp

MakeWaveScrnChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCMAKEWAVE
		mov		hMakeWaveScrn,eax
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

MakeWaveScrnChildProc endp

MakeWaveProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	waverect:RECT
	LOCAL	mDC:HDC
	LOCAL	hBmp:HBITMAP
	LOCAL	pt:POINT
	LOCAL	nMin:DWORD
	LOCAL	nMax:DWORD

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		mov		hBmp,eax
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		sub		rect.bottom,TEXTHIGHT
		; Calculate the wave rect
		mov		eax,rect.right
		sub		eax,SCOPEWT
		shr		eax,1
		mov		waverect.left,eax
		add		eax,SCOPEWT
		inc		eax
		mov		waverect.right,eax
		mov		eax,rect.bottom
		sub		eax,SCOPEHT
		shr		eax,1
		mov		waverect.top,eax
		add		eax,SCOPEHT
		inc		eax
		mov		waverect.bottom,eax
		;Create a clip region
		invoke CreateRectRgn,waverect.left,waverect.top,waverect.right,waverect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax
		;Draw grid
		call	DrawGrid

		;Draw wave
		mov		eax,makewavedata.ShowWave
		.if eax==0
			mov		esi,offset offset makewavedata.MW_MainData
		.elseif eax==1
			mov		esi,offset offset makewavedata.MW_SumHarmonicData
		.elseif eax==2
			mov		esi,offset offset makewavedata.MW_NoiseData
		.elseif eax==3
			mov		esi,offset offset makewavedata.MW_ResultData
		.endif
		mov		eax,008000h
		call	DrawWave
		invoke SelectClipRgn,mDC,NULL
		add		rect.bottom,TEXTHIGHT
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

DrawGrid:
	; Create gridlines pen
	invoke CreatePen,PS_SOLID,1,404040h
	invoke SelectObject,mDC,eax
	push	eax
	;Draw horizontal lines
	mov		edi,waverect.top
	xor		ecx,ecx
	.while ecx<GRIDY+1
		push	ecx
		invoke MoveToEx,mDC,waverect.left,edi,NULL
		invoke LineTo,mDC,waverect.right,edi
		add		edi,GRIDSIZE
		pop		ecx
		inc		ecx
	.endw
	;Draw vertical lines
	mov		edi,waverect.left
	xor		ecx,ecx
	.while ecx<GRIDX+1
		push	ecx
		invoke MoveToEx,mDC,edi,waverect.top,NULL
		invoke LineTo,mDC,edi,waverect.bottom
		add		edi,GRIDSIZE
		pop		ecx
		inc		ecx
	.endw
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawWave:
	invoke CreatePen,PS_SOLID,2,eax
	invoke SelectObject,mDC,eax
	push	eax
	mov		nMin,4096
	mov		nMax,0
	xor		edi,edi
	call	GetPoint
	invoke MoveToEx,mDC,pt.x,pt.y,NULL
	.while edi<4097*WORD
		call	GetPoint
		invoke LineTo,mDC,pt.x,pt.y
		inc		edi
		inc		edi
	.endw
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

GetPoint:
	;Get X position
	mov		eax,edi
	mov		ecx,waverect.right
	sub		ecx,waverect.left
	mul		ecx
	mov		ecx,4097*2
	div		ecx
	add		eax,waverect.left
	mov		pt.x,eax
	;Get y position
	mov		edx,edi
	and		edx,4095
	movsx	eax,word ptr [esi+edx]
	add		eax,2048
	.if eax<nMin
		mov		nMin,eax
	.endif
	.if eax>nMax
		mov		nMax,eax
	.endif
	sub		eax,DACMAX
	neg		eax
	mov		ecx,waverect.bottom
	sub		ecx,waverect.top
	sub		ecx,GRIDSIZE*2
	imul	ecx
	mov		ecx,DACMAX
	idiv	ecx
	add		eax,waverect.top
	add		eax,GRIDSIZE
	mov		pt.y,eax
	retn

MakeWaveProc endp

