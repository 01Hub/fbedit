
; STM32 value line Discovery Digital Oscilloscope demo project.
; -------------------------------------------------------------------------------
;
; IMPORTANT NOTICE!
; -----------------
; The use of the evaluation board is restricted:
; "This device is not, and may not be, offered for sale or lease, or sold or
; leased or otherwise distributed".
;
; For more info see this license agreement:
; http://www.st.com/internet/com/LEGAL_RESOURCES/LEGAL_AGREEMENT/
; LICENSE_AGREEMENT/EvaluationProductLicenseAgreement.pdf

.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include STM32F4_Scope.inc
include Frequency.asm
include Scope.asm
include LogicAnalyser.asm
include HSClock.asm
include DDSWave.asm

.code

SampleThreadProc proc lParam:DWORD
	LOCAL	DVM[2]:DWORD

	.while !fThreadExit
		.if !fConnected && !fNoSTLink
			;Connect to the STLink
			invoke STLinkConnect,hWnd
			.if eax==IDIGNORE
				mov		fNoSTLink,TRUE
			.elseif eax==IDABORT
				mov		fNoSTLink,TRUE
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.else
				mov		fConnected,eax
				invoke STLinkReset,hWnd
			.endif
		.endif
		.if fConnected
			.if fFRQDVM
				mov		fFRQDVM,0
				;Read frequency for CHA
				invoke STLinkRead,hWnd,STM32FrequencyCHA,addr scopedata.scopeCHAdata.frq_data,4
				.if fConnected
					;Read frequency for CHB
					invoke STLinkRead,hWnd,STM32FrequencyCHB,addr scopedata.scopeCHBdata.frq_data,4
					.if fConnected
						;Read DVM data for CHA and CHB from injected channels
						invoke STLinkRead,hWnd,4001223Ch,addr DVM,8
						;Set frequency and DVM data
						fild	scopedata.scopeCHAdata.frq_data.Frequency
						fstp	scopedata.scopeCHAdata.frequency
						fild	scopedata.scopeCHBdata.frq_data.Frequency
						fstp	scopedata.scopeCHBdata.frequency
						invoke SetFrequencyAndDVM,DVM[0],DVM[4]
					.endif
				.endif
			.elseif fHSCCHA
				mov		fHSCCHA,0
				;Send all initialisation data
				invoke RtlMoveMemory,addr hsclockdata.HSC_CommandStructDone,addr hsclockdata.HSC_CommandStruct,sizeof STM32_CommandStructDef
				mov		eax,hsclockdata.hscCHAData.hsclockenable
				mov		hsclockdata.hscFRQ.HSCEnable,ax
				movzx	eax,hsclockdata.hscCHAData.hsclockfrequency
				mov		hsclockdata.hscFRQ.HSCCount,ax
				movzx	eax,hsclockdata.hscCHAData.hsclockdivisor
				mov		hsclockdata.hscFRQ.HSCClockDiv,ax
				movzx	eax,hsclockdata.hscCHAData.hsclockccr
				mov		hsclockdata.hscFRQ.HSCDuty,ax
				invoke STLinkWrite,hWnd,STM32FrequencyCHA+8,addr hsclockdata.hscFRQ.HSCEnable,sizeof STM32_FRQDataStructDef-8
				mov		hsclockdata.HSC_CommandStructDone.Command,STM32_CommandWait
				mov		hsclockdata.HSC_CommandStructDone.Mode,STM32_ModeHSClockCHA
				invoke STLinkWrite,hWnd,STM32CommandStart,addr hsclockdata.HSC_CommandStructDone,sizeof STM32_CommandStructDef
				mov		hsclockdata.HSC_CommandStructDone.Command,STM32_CommandInit
				invoke STLinkWrite,hWnd,STM32CommandStart,addr hsclockdata.HSC_CommandStructDone,4
				.while TRUE
					invoke STLinkRead,hWnd,STM32CommandStart,addr hsclockdata.HSC_CommandStructDone,4
					.break .if hsclockdata.HSC_CommandStructDone.Command==STM32_CommandDone
					invoke Sleep,10
				.endw
			.elseif fHSCCHB
				mov		fHSCCHB,0
				;Send all initialisation data
				invoke RtlMoveMemory,addr hsclockdata.HSC_CommandStructDone,addr hsclockdata.HSC_CommandStruct,sizeof STM32_CommandStructDef
				mov		eax,hsclockdata.hscCHBData.hsclockenable
				mov		hsclockdata.hscFRQ.HSCEnable,ax
				movzx	eax,hsclockdata.hscCHBData.hsclockfrequency
				mov		hsclockdata.hscFRQ.HSCCount,ax
				movzx	eax,hsclockdata.hscCHBData.hsclockdivisor
				mov		hsclockdata.hscFRQ.HSCClockDiv,ax
				movzx	eax,hsclockdata.hscCHBData.hsclockccr
				mov		hsclockdata.hscFRQ.HSCDuty,ax
				invoke STLinkWrite,hWnd,STM32FrequencyCHB+8,addr hsclockdata.hscFRQ.HSCEnable,sizeof STM32_FRQDataStructDef-8
				mov		hsclockdata.HSC_CommandStructDone.Command,STM32_CommandWait
				mov		hsclockdata.HSC_CommandStructDone.Mode,STM32_ModeHSClockCHB
				invoke STLinkWrite,hWnd,STM32CommandStart,addr hsclockdata.HSC_CommandStructDone,sizeof STM32_CommandStructDef
				mov		hsclockdata.HSC_CommandStructDone.Command,STM32_CommandInit
				invoke STLinkWrite,hWnd,STM32CommandStart,addr hsclockdata.HSC_CommandStructDone,4
				.while TRUE
					invoke STLinkRead,hWnd,STM32CommandStart,addr hsclockdata.HSC_CommandStructDone,4
					.break .if hsclockdata.HSC_CommandStructDone.Command==STM32_CommandDone
					invoke Sleep,10
				.endw
			.elseif fSCOPE
				mov		fSCOPE,0
				invoke RtlMoveMemory,addr scopedata.ADC_CommandStructDone,addr scopedata.ADC_CommandStruct,sizeof STM32_CommandStructDef
				mov		scopedata.ADC_CommandStructDone.TriggerWait,3
				mov		scopedata.ADC_CommandStructDone.Command,STM32_CommandWait
				mov		scopedata.ADC_CommandStructDone.Mode,STM32_ModeScopeCHA
				.if scopedata.ADC_CommandStructDone.TriggerMode==STM32_TriggerLGA || scopedata.ADC_CommandStructDone.TriggerMode==STM32_TriggerLGAEdge
					movzx	eax,lgadata.LGA_CommandStruct.TriggerValue
					mov		scopedata.ADC_CommandStructDone.TriggerValue,al
					movzx	eax,lgadata.LGA_CommandStruct.TriggerMask
					mov		scopedata.ADC_CommandStructDone.TriggerMask,al
				.endif
				invoke STLinkWrite,hWnd,STM32CommandStart,addr scopedata.ADC_CommandStructDone,sizeof STM32_CommandStructDef
				mov		scopedata.ADC_CommandStructDone.Command,STM32_CommandInit
				invoke STLinkWrite,hWnd,STM32CommandStart,addr scopedata.ADC_CommandStructDone,4
				.while TRUE
					invoke STLinkRead,hWnd,STM32CommandStart,addr scopedata.ADC_CommandStructDone,4
					.break .if scopedata.ADC_CommandStructDone.Command==STM32_CommandDone
					invoke Sleep,10
				.endw
				movzx	eax,scopedata.ADC_CommandStructDone.DataBlocks
				shl		eax,8
				invoke STLinkRead,hWnd,STM32DataStart,addr scopedata.scopeCHAdata.ADC_Data,eax
				xor		ebx,ebx
				movzx	edi,scopedata.ADC_CommandStructDone.DataBlocks
				shl		edi,6
				.while ebx<edi
					mov		eax,dword ptr scopedata.scopeCHAdata.ADC_Data[ebx*4]
					movzx	edx,ax
					shr		eax,16
					.if scopedata.ADC_CommandStructDone.ScopeDataBits==0
						shr		edx,4
						shr		eax,4
					.elseif scopedata.ADC_CommandStructDone.ScopeDataBits==1
						shr		edx,2
						shr		eax,2
					.elseif scopedata.ADC_CommandStructDone.ScopeDataBits==3
						shl		edx,2
						shl		eax,2
					.endif
					mov		scopedata.scopeCHAdata.ADC_Data[ebx],dl
					mov		scopedata.scopeCHBdata.ADC_Data[ebx],al
					inc		ebx
				.endw
				;Get frequency and period for CHA
				fld		nsinasec
				fild	scopedata.scopeCHAdata.frq_data.Frequency
				fst		scopedata.scopeCHAdata.frequency
				fdivp	st(1),st
				fstp	scopedata.scopeCHAdata.period
				;Get frequency and period for CHB
				fld		nsinasec
				fild	scopedata.scopeCHBdata.frq_data.Frequency
				fst		scopedata.scopeCHBdata.frequency
				fdivp	st(1),st
				fstp	scopedata.scopeCHBdata.period
				;Update the scope CHA screen
				.if scopedata.scopeCHAdata.fSubsampling
					invoke Subsampling,childdialogs.hWndScopeCHA
				.endif
				invoke GetDlgItem,childdialogs.hWndScopeCHA,IDC_UDCSCOPE
				mov		ebx,eax
				invoke InvalidateRect,ebx,NULL,TRUE
				invoke UpdateWindow,ebx
				;Update the scope CHB screen
				.if scopedata.scopeCHBdata.fSubsampling
					invoke Subsampling,childdialogs.hWndScopeCHB
				.endif
				invoke GetDlgItem,childdialogs.hWndScopeCHB,IDC_UDCSCOPE
				mov		ebx,eax
				invoke InvalidateRect,ebx,NULL,TRUE
				invoke UpdateWindow,ebx
			.elseif fLGA
				mov		fLGA,0
				invoke RtlMoveMemory,addr lgadata.LGA_CommandStructDone,addr lgadata.LGA_CommandStruct,sizeof STM32_CommandStructDef
				mov		lgadata.LGA_CommandStructDone.TriggerWait,3
				mov		lgadata.LGA_CommandStructDone.Command,STM32_CommandWait
				mov		lgadata.LGA_CommandStructDone.Mode,STM32_ModeLGA
				invoke STLinkWrite,hWnd,STM32CommandStart,addr lgadata.LGA_CommandStructDone,sizeof STM32_CommandStructDef
				mov		lgadata.LGA_CommandStructDone.Command,STM32_CommandInit
				invoke STLinkWrite,hWnd,STM32CommandStart,addr lgadata.LGA_CommandStructDone,4
				.while TRUE
					invoke STLinkRead,hWnd,STM32CommandStart,addr lgadata.LGA_CommandStructDone,4
					.break .if lgadata.LGA_CommandStructDone.Command==STM32_CommandDone
					invoke Sleep,10
				.endw
				movzx	eax,lgadata.LGA_CommandStructDone.DataBlocks
				shl		eax,6
				invoke STLinkRead,hWnd,STM32DataStart,addr lgadata.LGA_Data,eax
				invoke GetDlgItem,childdialogs.hWndLogicAnalyser,IDC_UDCLOGICANALYSER
				mov		ebx,eax
				invoke InvalidateRect,ebx,NULL,TRUE
				invoke UpdateWindow,ebx
			.elseif fDDS
				mov		fDDS,0
				invoke RtlMoveMemory,addr ddsdata.DDS_CommandStructDone,addr ddsdata.DDS_CommandStruct,sizeof STM32_CommandStructDef
				mov		ddsdata.DDS_CommandStructDone.Command,STM32_CommandWait
				invoke STLinkWrite,hWnd,STM32CommandStart,addr ddsdata.DDS_CommandStructDone,sizeof STM32_CommandStructDef
				mov		ddsdata.DDS_CommandStructDone.Command,STM32_CommandInit
				invoke STLinkWrite,hWnd,STM32CommandStart,addr ddsdata.DDS_CommandStructDone,4
				.while TRUE
					invoke STLinkRead,hWnd,STM32CommandStart,addr ddsdata.DDS_CommandStructDone,4
					.break .if ddsdata.DDS_CommandStructDone.Command==STM32_CommandDone
					invoke Sleep,10
				.endw
			.endif
		.endif
	.endw
	mov		fThreadExit,0
	ret

SampleThreadProc endp

MainDlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	tid:DWORD
	LOCAL	tmp:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke CreateFontIndirect,addr Tahoma
		mov		hFont,eax
		;Setup scopedata
		mov		scopedata.ADC_CommandStruct.Mode,STM32_ModeScopeCHA
		mov		scopedata.ADC_CommandStruct.DataBlocks,4
		mov		scopedata.ADC_CommandStruct.TriggerMode,STM32_TriggerManual
		mov		scopedata.ADC_CommandStruct.TriggerValue,ADCMAX/2
		mov		scopedata.ADC_CommandStruct.ScopeDCNullOutCHA,ADCMAX/2
		mov		scopedata.ADC_CommandStruct.ScopeAmplifyCHA,07h
		mov		scopedata.ADC_CommandStruct.ScopeDCNullOutCHB,ADCMAX/2
		mov		scopedata.ADC_CommandStruct.ScopeAmplifyCHB,07h
		mov		scopedata.ADC_CommandStruct.TriggerValue,0FFh
		mov		scopedata.ADC_CommandStruct.TriggerMask,0FFh
		invoke RtlMoveMemory,offset scopedata.ADC_CommandStructDone,offset scopedata.ADC_CommandStruct,sizeof STM32_CommandStructDef
		mov		lpSTM32_Command,offset scopedata.ADC_CommandStruct
		mov		lpSTM32_CommandDone,offset scopedata.ADC_CommandStructDone
		;Create scope child dialogs
		invoke CreateDialogParam,hInstance,IDD_DLGSCOPE,hWin,addr ScopeChildProc,offset scopedata.scopeCHAdata
		mov		childdialogs.hWndScopeCHA,eax
		invoke CreateDialogParam,hInstance,IDD_DLGSCOPE,hWin,addr ScopeChildProc,offset scopedata.scopeCHBdata
		mov		childdialogs.hWndScopeCHB,eax
		;Create high speed clock child dialogs
		invoke CreateDialogParam,hInstance,IDD_DLGHSCLOCK,hWin,addr HSClockChildProc,offset hsclockdata.hscCHAData
		mov		childdialogs.hWndHSClockCHA,eax
		invoke CreateDialogParam,hInstance,IDD_DLGHSCLOCK,hWin,addr HSClockChildProc,offset hsclockdata.hscCHBData
		mov		childdialogs.hWndHSClockCHB,eax
		;Create logic analyser child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGLOGICANALYSER,hWin,addr LogicAnalyserChildProc,0
		mov		childdialogs.hWndLogicAnalyser,eax
		;Create DDS Wave child dialog
		invoke CreateDialogParam,hInstance,IDD_DDSWAVE,hWin,addr DDSWaveChildProc,0
		mov		childdialogs.hWndDDSWave,eax
		;Create frequency and DVM child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGFREQUENCY,hWin,addr FrequencyChildProc,0
		mov		childdialogs.hWndFrequency,eax
		;Insert some scope test data
		mov		eax,07Fh
		xor		ecx,ecx
		mov		edx,8
		mov		esi,offset scopedata.scopeCHAdata.ADC_Data
		mov		edi,offset scopedata.scopeCHBdata.ADC_Data
		.while ecx<STM32_DataSize
			mov		[edi+ecx],al
			mov		[esi+ecx],al
			.if sdword ptr eax>0E0h || sdword ptr eax<020h
				neg		edx
			.endif
			add		eax,edx
			inc		ecx
		.endw
		invoke GetSampleRate,addr scopedata.ADC_CommandStructDone
		mov		tmp,eax
		fld		qword ptr nsinasec
		fild	tmp
		fdivp	st(1),st
		fst		scopedata.scopeCHAdata.convperiod
		fstp	scopedata.scopeCHBdata.convperiod
		invoke ShowWindow,childdialogs.hWndScopeCHA,SW_SHOWNA
		invoke GetFrequency,childdialogs.hWndScopeCHA
		invoke GetFrequency,childdialogs.hWndScopeCHB
		invoke SetFrequencyAndDVM,0,0
		invoke SetTimer,hWin,1000,333,NULL
		invoke CreateThread,NULL,NULL,addr SampleThreadProc,hWin,0,addr tid
		mov		hThread,eax
	.elseif eax==WM_TIMER
		invoke IsDlgButtonChecked,hWin,IDC_CHKAUTO
		.if eax && !fSCOPE && !fLGA
			invoke IsWindowVisible,childdialogs.hWndLogicAnalyser
			.if eax
				mov 	fLGA,1
			.endif
			invoke IsWindowVisible,childdialogs.hWndScopeCHA
			.if eax
				mov 	fSCOPE,1
			.endif
			invoke IsWindowVisible,childdialogs.hWndScopeCHB
			.if eax
				mov 	fSCOPE,1
			.endif
		.endif
		.if !fFRQDVM
			mov		fFRQDVM,1
		.endif
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		.if eax==IDM_FILE_OPEN_SCOPECHA
		.elseif eax==IDM_FILE_OPEN_SCOPECHB
		.elseif eax==IDM_FILE_SAVE_SCOPECHA
		.elseif eax==IDM_FILE_SAVE_SCOPECHB
		.elseif eax==IDM_FILE_EXIT || eax==IDCANCEL
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_VIEW_SCOPECHA
			mov		scopedata.ADC_CommandStruct.Mode,STM32_ModeScopeCHA
			mov		lpSTM32_Command,offset scopedata.ADC_CommandStruct
			mov		lpSTM32_CommandDone,offset scopedata.ADC_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_SCOPECHB
			mov		scopedata.ADC_CommandStruct.Mode,STM32_ModeScopeCHB
			mov		lpSTM32_Command,offset scopedata.ADC_CommandStruct
			mov		lpSTM32_CommandDone,offset scopedata.ADC_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_SCOPECHACHB
			mov		scopedata.ADC_CommandStruct.Mode,STM32_ModeScopeCHACHB
			mov		lpSTM32_Command,offset scopedata.ADC_CommandStruct
			mov		lpSTM32_CommandDone,offset scopedata.ADC_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_LOGICANALYSER
			mov		lgadata.LGA_CommandStruct.Mode,STM32_ModeLGA
			mov		lpSTM32_Command,offset lgadata.LGA_CommandStruct
			mov		lpSTM32_CommandDone,offset lgadata.LGA_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_HSCLOCKCHA
			mov		hsclockdata.HSC_CommandStruct.Mode,STM32_ModeHSClockCHA
			mov		lpSTM32_Command,offset hsclockdata.HSC_CommandStruct
			mov		lpSTM32_CommandDone,offset hsclockdata.HSC_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_HSCLOCKCHB
			mov		hsclockdata.HSC_CommandStruct.Mode,STM32_ModeHSClockCHB
			mov		lpSTM32_Command,offset hsclockdata.HSC_CommandStruct
			mov		lpSTM32_CommandDone,offset hsclockdata.HSC_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_HSCLOCKCHACHB
			mov		hsclockdata.HSC_CommandStruct.Mode,STM32_ModeHSClockCHACHB
			mov		lpSTM32_Command,offset hsclockdata.HSC_CommandStruct
			mov		lpSTM32_CommandDone,offset hsclockdata.HSC_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_HIDE
		.elseif eax==IDM_VIEW_DDSWAVEGEN
			mov		ddsdata.DDS_CommandStruct.Mode,STM32_ModeDDSWave
			mov		lpSTM32_Command,offset ddsdata.DDS_CommandStruct
			mov		lpSTM32_CommandDone,offset ddsdata.DDS_CommandStructDone
			invoke SendMessage,hWin,WM_SIZE,0,0
			invoke ShowWindow,childdialogs.hWndDDSWave,SW_SHOWNA
			invoke ShowWindow,childdialogs.hWndHSClockCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndHSClockCHB,SW_HIDE
			invoke ShowWindow,childdialogs.hWndLogicAnalyser,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHA,SW_HIDE
			invoke ShowWindow,childdialogs.hWndScopeCHB,SW_HIDE
		.elseif eax==IDM_SETUP_SCOPE
			.if childdialogs.hWndScopeSetup
				invoke SetFocus,childdialogs.hWndScopeSetup
			.else
				invoke CreateDialogParam,hInstance,IDD_DLGSCOPESETUP,hWin,addr ScopeSetupProc,0
				mov		childdialogs.hWndScopeSetup,eax
			.endif
		.elseif eax==IDM_SETUP_LOGICANALYSER
			.if childdialogs.hWndLGASetup
				invoke SetFocus,childdialogs.hWndLGASetup
			.else
				invoke CreateDialogParam,hInstance,IDD_DLGLGASETUP,hWin,addr LGASetupProc,0
				mov		childdialogs.hWndLGASetup,eax
			.endif
		.elseif eax==IDM_SETUP_HIGHSPEEDCLOCK
			.if childdialogs.hWndHSClockSetup
				invoke SetFocus,childdialogs.hWndHSClockSetup
			.else
				invoke CreateDialogParam,hInstance,IDD_DLGHSCLOCKSETUP,hWin,addr HSClockSetupProc,0
				mov		childdialogs.hWndHSClockSetup,eax
			.endif
		.elseif eax==IDM_SETUP_DDSWAVEGEN
			.if childdialogs.hWndDDSWaveSetup
				invoke SetFocus,childdialogs.hWndDDSWaveSetup
			.else
				invoke CreateDialogParam,hInstance,IDD_DDSWAVESETUP,hWin,addr DDSWaveSetupProc,0
				mov		childdialogs.hWndDDSWaveSetup,eax
			.endif
		.elseif eax==IDM_HELP_ABOUT
		.elseif eax==IDC_BTNSAMPLE
			invoke IsWindowVisible,childdialogs.hWndLogicAnalyser
			.if eax
				mov 	fLGA,1
			.endif
			invoke IsWindowVisible,childdialogs.hWndScopeCHA
			.if eax
				mov 	fSCOPE,1
			.endif
			invoke IsWindowVisible,childdialogs.hWndScopeCHB
			.if eax
				mov 	fSCOPE,1
			.endif
		.endif
	.elseif	eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		mov		edi,rect.right
		sub		edi,85
		mov		ebx,rect.bottom
		sub		ebx,25
		invoke GetDlgItem,hWin,IDCANCEL
		invoke MoveWindow,eax,edi,ebx,80,22,TRUE
		sub		ebx,25
		invoke GetDlgItem,hWin,IDC_BTNSAMPLE
		invoke MoveWindow,eax,edi,ebx,80,22,TRUE
		sub		ebx,20
		invoke GetDlgItem,hWin,IDC_CHKAUTO
		invoke MoveWindow,eax,edi,ebx,80,16,TRUE
		sub		rect.bottom,60
		mov		eax,rect.right
		sub		eax,135
		invoke MoveWindow,childdialogs.hWndFrequency,0,rect.bottom,rect.right,60,TRUE
		mov		eax,lpSTM32_Command
		movzx	eax,[eax].STM32_CommandStructDef.Mode
		.if eax==STM32_ModeScopeCHA || eax==STM32_ModeScopeCHB
			invoke MoveWindow,childdialogs.hWndScopeCHA,0,0,rect.right,rect.bottom,TRUE
			invoke MoveWindow,childdialogs.hWndScopeCHB,0,0,rect.right,rect.bottom,TRUE
		.elseif eax==STM32_ModeScopeCHACHB
			push	rect.bottom
			shr		rect.bottom,1
			invoke MoveWindow,childdialogs.hWndScopeCHA,0,0,rect.right,rect.bottom,TRUE
			mov		eax,rect.bottom
			pop		rect.bottom
			mov		rect.top,eax
			sub		rect.bottom,eax
			invoke MoveWindow,childdialogs.hWndScopeCHB,0,rect.top,rect.right,rect.bottom,TRUE
		.elseif eax==STM32_ModeLGA
			invoke MoveWindow,childdialogs.hWndLogicAnalyser,0,0,rect.right,rect.bottom,TRUE
		.elseif eax==STM32_ModeDDSWave
			invoke MoveWindow,childdialogs.hWndDDSWave,0,0,rect.right,rect.bottom,TRUE
		.elseif eax==STM32_ModeHSClockCHA
			invoke MoveWindow,childdialogs.hWndHSClockCHA,0,0,rect.right,rect.bottom,TRUE
		.elseif eax==STM32_ModeHSClockCHB
			invoke MoveWindow,childdialogs.hWndHSClockCHB,0,0,rect.right,rect.bottom,TRUE
		.elseif eax==STM32_ModeHSClockCHACHB
			push	rect.bottom
			shr		rect.bottom,1
			invoke MoveWindow,childdialogs.hWndHSClockCHA,0,0,rect.right,rect.bottom,TRUE
			mov		eax,rect.bottom
			pop		rect.bottom
			mov		rect.top,eax
			sub		rect.bottom,eax
			invoke MoveWindow,childdialogs.hWndHSClockCHB,0,rect.top,rect.right,rect.bottom,TRUE
		.endif
	.elseif eax==WM_ACTIVATE
		mov		eax,wParam
		.if eax!=WA_INACTIVE
			mov		eax,hWin
			mov		hDlg,eax
		.endif
	.elseif	eax==WM_CLOSE
		invoke KillTimer,hWin,1000
		mov		fThreadExit,TRUE
		invoke WaitForSingleObject,hThread,250
		invoke CloseHandle,hThread
		.if fConnected
			invoke STLinkDisconnect,hWin
		.endif
		invoke DeleteObject,hFont
		invoke DestroyWindow,hWin
	.elseif eax==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor		eax,eax
	ret

MainDlgProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	InitCommonControls
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset MainDlgProc
	mov		wc.lpszClassName,offset szMAINCLASS
	mov		wc.cbClsExtra,0
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	mov		eax,hInstance
	mov		wc.hInstance,eax
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,0,IDC_ARROW
	mov		wc.hCursor,eax
	mov		wc.hbrBackground,NULL
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset TextProc
	mov		wc.lpszClassName,offset szTEXTCLASS
	mov		wc.hbrBackground,NULL
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset ScopeProc
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpszClassName,offset szSCOPECLASS
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset LogicAnalyserProc
	mov		wc.hbrBackground,NULL
	mov		wc.lpszClassName,offset szLOGICANALYSERCLASS
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset HSClockProc
	mov		wc.hbrBackground,NULL
	mov		wc.lpszClassName,offset szHSCLOCKCLASS
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset DDSWaveProc
	mov		wc.hbrBackground,NULL
	mov		wc.lpszClassName,offset szDDSWAVECLASS
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_MAIN,NULL,addr MainDlgProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke IsDialogMessage,hDlg,addr msg
		.if !eax
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
	.endw
	mov		eax,msg.wParam
	invoke	ExitProcess,0

end start

