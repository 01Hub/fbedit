
.code

ClearBreakpoints proc

	invoke RtlZeroMemory,offset breakpoint,sizeof breakpoint
	invoke RtlZeroMemory,offset szBPSourceName,sizeof szBPSourceName
	ret

ClearBreakpoints endp

AddBreakpoint proc uses ebx esi,nLine:DWORD,lpFileName:DWORD

	mov		esi,offset szBPSourceName
	mov		ebx,0
	.while byte ptr [esi]
		invoke strcmpi,esi,lpFileName
		.break .if !eax
		inc		ebx
		lea		esi,[esi+MAX_PATH]
	.endw
	.if !byte ptr [esi]
		invoke strcpy,esi,lpFileName
	.endif
	mov		esi,offset breakpoint
	.while [esi].BREAKPOINT.LineNumber
		lea		esi,[esi+sizeof BREAKPOINT]
	.endw
	mov		[esi].BREAKPOINT.FileID,ebx
	mov		eax,nLine
	mov		[esi].BREAKPOINT.LineNumber,eax
	ret

AddBreakpoint endp

MapBreakPoints proc uses ebx esi edi
	LOCAL	CountBP:DWORD
	LOCAL	CountSource:DWORD
	LOCAL	Unhandled:DWORD

	mov		Unhandled,0
	mov		CountBP,512
	mov		esi,offset breakpoint
	.while CountBP
		mov		eax,[esi].BREAKPOINT.LineNumber
		.if eax
			push	esi
			call	MatchIt
			pop		esi
		.endif
		dec		CountBP
		add		esi,sizeof BREAKPOINT
	.endw
	mov		eax,Unhandled
	ret

MatchIt:
	mov		eax,[esi].BREAKPOINT.FileID
	mov		edx,MAX_PATH
	mul		edx
	mov		edi,offset szBPSourceName
	lea		edi,[edi+eax]
	mov		eax,dbg.inxsource
	mov		CountSource,eax
	mov		ebx,dbg.hMemSource
	.while CountSource
		invoke strcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		edx,[ebx].DEBUGSOURCE.FileID
			mov		eax,[esi].BREAKPOINT.LineNumber
			mov		esi,dbg.hMemLine
			inc		Unhandled
			xor		ecx,ecx
			.while ecx<dbg.inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if dx==[esi].DEBUGLINE.FileID
						.if [esi].DEBUGLINE.NoDebug==0
							mov		[esi].DEBUGLINE.BreakPoint,TRUE
							dec		Unhandled
						.endif
						.break
					.endif
				.endif
				inc		ecx
				add		esi,sizeof DEBUGLINE
			.endw
			.break
		.endif
		dec		CountSource
		add		ebx,sizeof DEBUGSOURCE
	.endw
	retn

MapBreakPoints endp

SetBreakPointsAll proc

	;Step Into
	mov		edx,dbg.minadr
	mov		ecx,dbg.maxadr
	sub		ecx,edx
	invoke WriteProcessMemory,dbg.hdbghand,edx,dbg.hMemBP,ecx,0
	ret

SetBreakPointsAll endp

SetBreakPoints proc uses ebx edi

	mov		edi,dbg.hMemLine
	mov		ebx,dbg.inxline
	.while ebx
		.if [edi].DEBUGLINE.BreakPoint; && ![edi].DEBUGLINE.NoDebug
			invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	ret

SetBreakPoints endp

SetBreakpointAtCurrentLine proc uses ebx esi edi,nLine:DWORD,lpFileName:DWORD

	mov		edi,dbg.inxsource
	mov		ebx,dbg.hMemSource
	.while edi
		invoke strcmpi,lpFileName,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		edx,[ebx].DEBUGSOURCE.FileID
			mov		eax,nLine		;LineNumber
			mov		esi,dbg.hMemLine
			xor		ecx,ecx
			.while ecx<dbg.inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if dx==[esi].DEBUGLINE.FileID
						invoke WriteProcessMemory,dbg.hdbghand,[esi].DEBUGLINE.Address,addr szBP,1,0
						jmp		Ex
					.endif
				.endif
				inc		ecx
				add		esi,sizeof DEBUGLINE
			.endw
			.break
		.endif
		dec		edi
		lea		ebx,[ebx+sizeof DEBUGSOURCE]
	.endw
  Ex:
	ret

SetBreakpointAtCurrentLine endp

ClearBreakPointsAll proc

	mov		edx,dbg.minadr
	mov		ecx,dbg.maxadr
	sub		ecx,edx
	invoke WriteProcessMemory,dbg.hdbghand,edx,dbg.hMemNoBP,ecx,0
	ret

ClearBreakPointsAll endp
