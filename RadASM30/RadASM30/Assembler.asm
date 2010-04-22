
.code

GetColors proc
	LOCAL	racolor:RACOLOR

	invoke GetPrivateProfileString,addr szIniColors,addr szIniColors,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
	.if eax
		xor		ebx,ebx
		.while ebx<sizeof RADCOLOR/4
			invoke GetItemInt,addr tmpbuff,0
			mov		dword ptr da.radcolor[ebx*4],eax
			inc		ebx
		.endw
	.else
		invoke RtlMoveMemory,addr da.radcolor,addr defcol,sizeof RADCOLOR
	.endif
	invoke SendMessage,ha.hOutput,REM_GETCOLOR,0,addr racolor
	mov		eax,da.radcolor.toolback
	mov		racolor.bckcol,eax
	mov		eax,da.radcolor.tooltext
	mov		racolor.txtcol,eax
	invoke SendMessage,ha.hOutput,REM_SETCOLOR,0,addr racolor
	invoke SendMessage,ha.hImmediate,REM_SETCOLOR,0,addr racolor
	invoke SendMessage,ha.hFileBrowser,FBM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hFileBrowser,FBM_SETTEXTCOLOR,0,da.radcolor.tooltext
	invoke SendMessage,ha.hProjectBrowser,RPBM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hProjectBrowser,RPBM_SETTEXTCOLOR,0,da.radcolor.tooltext
	invoke SendMessage,ha.hProperty,PRM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hProperty,PRM_SETTEXTCOLOR,0,da.radcolor.tooltext
	ret

GetColors endp

DeleteDuplicates proc uses esi edi,lpszType:DWORD
	LOCAL	nCount:DWORD

	invoke SendMessage,ha.hProperty,PRM_GETSORTEDLIST,lpszType,addr nCount
	mov		esi,eax
	push	esi
	xor		ecx,ecx
	mov		edi,offset szNULL
	.while ecx<nCount
		push	ecx
		invoke strcmp,edi,[esi]
		.if !eax
			mov		eax,[esi]
			lea		eax,[eax-sizeof PROPERTIES]
			mov		[eax].PROPERTIES.nType,255
		.else
			mov		edi,[esi]
		.endif
		pop		ecx
		inc		ecx
		lea		esi,[esi+4]
	.endw
	pop		esi
	invoke GlobalFree,esi
	invoke SendMessage,ha.hProperty,PRM_COMPACTLIST,FALSE,0
	ret

DeleteDuplicates endp

GetCodeComplete proc uses ebx esi edi
	LOCAL	buffer[256]:BYTE
	LOCAL	apifile[MAX_PATH]:BYTE

	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniTrig,NULL,addr da.szCCTrig,sizeof da.szCCTrig,addr da.szAssemblerIni
	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniInc,NULL,addr da.szCCInc,sizeof da.szCCInc,addr da.szAssemblerIni
	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniLib,NULL,addr da.szCCLib,sizeof da.szCCLib,addr da.szAssemblerIni

	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniApi,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
	.while tmpbuff
		invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer
		movzx	ebx,buffer
		invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer
		.if ebx && buffer
			invoke strcpy,addr apifile,addr da.szAppPath
			invoke strcat,addr apifile,addr szBSApiBS
			invoke strcat,addr apifile,addr buffer
			invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,ebx,addr apifile
		.endif
	.endw
	;Add 'C' list to 'W' list
	mov		dword ptr buffer,'C'
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[1]
	.while eax
		mov		esi,eax
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		invoke strcpy,offset tmpbuff,esi
		mov		eax,2 shl 8 or 'W'
		invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYLIST,eax,offset tmpbuff
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	;Add 'M' list to 'W' list
	mov		dword ptr buffer,'M'
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[1]
	.while eax
		mov		esi,eax
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		.while byte ptr [esi]
			.if byte ptr [esi]=='['
				inc		esi
				mov		edi,offset tmpbuff
				.while byte ptr [esi]!=']'
					mov		al,[esi]
					mov		[edi],al
					inc		esi
					inc		edi
				.endw
				mov		byte ptr [edi],0
				mov		eax,2 shl 8 or 'W'
				invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYLIST,eax,offset tmpbuff
			.endif
			inc		esi
		.endw
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	;Delete duplicates
	mov		dword ptr buffer,'W'
	invoke DeleteDuplicates,addr buffer
	ret

GetCodeComplete endp

GetKeywords proc uses esi edi
	LOCAL	hMem:HGLOBAL
	LOCAL	buffer[16]:BYTE
	LOCAL	nInx:DWORD

	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,65536*8
	mov		hMem,eax
	invoke SetHiliteWords,0,0
	mov		buffer,'C'
	mov		nInx,0
	.while nInx<16
		invoke BinToDec,nInx,addr buffer[1]
		invoke GetPrivateProfileString,addr szIniKeywords,addr buffer,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
		.if eax
			mov		eax,nInx
			mov		eax,dword ptr da.radcolor[eax*4]
			invoke SetHiliteWords,eax,addr tmpbuff
		.endif
		inc		nInx
	.endw
	;Add api calls to Group#15
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'P'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		byte ptr [edi],'^'
		inc		edi
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[15*4],hMem
	;Add api constants to Group#14
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'C'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	mov		esi,eax
	.while esi
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		mov		byte ptr [edi],'^'
		inc		edi
		.while byte ptr [esi]
			mov		al,[esi]
			.if al==','
				mov		byte ptr [edi],' '
				inc		edi
				mov		al,'^'
			.endif
			mov		[edi],al
			inc		esi
			inc		edi
		.endw
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
		mov		esi,eax
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[14*4],hMem
	;Add api words to Group#14
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'W'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		byte ptr [edi],'^'
		inc		edi
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[14*4],hMem
	;Add api structs to Group#13
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'S'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		byte ptr [edi],'^'
		inc		edi
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[13*4],hMem
	;Add api types to Group#12
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'T'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		cl,[eax]
		mov		ch,cl
		and		cl,5Fh
		.if cl==ch
			;Case sensitive
			mov		byte ptr [edi],'^'
			inc		edi
		.endif
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[12*4],hMem
	invoke GlobalFree,hMem
	ret

GetKeywords endp

OpenAssembler proc uses ebx esi edi
	LOCAL	pbfe:PBFILEEXT
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffcbo[128]:BYTE
	LOCAL	bufftype[128]:BYTE
	LOCAL	deftype:DEFTYPE
	LOCAL	defgen:DEFGEN


	;Assembler.ini
	;Check version
	invoke strcpy,addr buffer,addr da.szAppPath
	invoke strcat,addr buffer,addr szBS
	invoke strcat,addr buffer,addr da.szAssembler
	invoke strcat,addr buffer,addr szDotIni
	invoke GetPrivateProfileInt,addr szIniVersion,addr szIniVersion,0,addr buffer
	.if eax<3000
		invoke GetColors
		invoke strcpy,addr tmpbuff,addr szAssemblerVersion
		invoke strcat,addr tmpbuff,addr buffer
		invoke MessageBox,ha.hWnd,addr tmpbuff,addr DisplayName,MB_OK or MB_ICONERROR
		xor		eax,eax
	.else
		invoke strcpy,addr da.szAssemblerIni,addr buffer
		invoke SendMessage,ha.hStatus,SB_SETTEXT,2,addr da.szAssembler
		;Get file filters
		invoke RtlZeroMemory,addr da.szCODEString,sizeof da.szCODEString
		invoke RtlZeroMemory,addr da.szRESString,sizeof da.szRESString
		invoke RtlZeroMemory,addr da.szTXTString,sizeof da.szTXTString
		invoke RtlZeroMemory,addr da.szANYString,sizeof da.szANYString
		invoke RtlZeroMemory,addr da.szALLString,sizeof da.szALLString
		mov		word ptr bufftype,'0'
		invoke GetPrivateProfileString,addr szIniFile,addr bufftype,addr szDefCODEString,addr da.szCODEString,sizeof da.szCODEString-1,addr da.szAssemblerIni
		mov		word ptr bufftype,'1'
		invoke GetPrivateProfileString,addr szIniFile,addr bufftype,addr szDefRESString,addr da.szRESString,sizeof da.szRESString-1,addr da.szAssemblerIni
		mov		word ptr bufftype,'2'
		invoke GetPrivateProfileString,addr szIniFile,addr bufftype,addr szDefTXTString,addr da.szTXTString,sizeof da.szTXTString-1,addr da.szAssemblerIni
		mov		word ptr bufftype,'3'
		invoke GetPrivateProfileString,addr szIniFile,addr bufftype,addr szDefANYString,addr da.szANYString,sizeof da.szANYString-1,addr da.szAssemblerIni
		invoke strcpy,addr da.szALLString,addr da.szCODEString
		invoke strcat,addr da.szALLString,addr szPipe
		invoke strcat,addr da.szALLString,addr da.szRESString
		invoke strcat,addr da.szALLString,addr szPipe
		invoke strcat,addr da.szALLString,addr da.szTXTString
		invoke strcat,addr da.szALLString,addr szPipe
		invoke strcat,addr da.szALLString,addr da.szANYString
		mov		eax,offset da.szCODEString
		call	FixString
		mov		eax,offset da.szRESString
		call	FixString
		mov		eax,offset da.szTXTString
		call	FixString
		mov		eax,offset da.szANYString
		call	FixString
		mov		eax,offset da.szALLString
		call	FixString
		;Get file types
		invoke GetPrivateProfileString,addr szIniFile,addr szIniCode,NULL,addr da.szCodeFiles,sizeof da.szCodeFiles,addr da.szAssemblerIni
		invoke GetPrivateProfileString,addr szIniFile,addr szIniText,NULL,addr da.szTextFiles,sizeof da.szTextFiles,addr da.szAssemblerIni
		invoke GetPrivateProfileString,addr szIniFile,addr szIniHex,NULL,addr da.szHexFiles,sizeof da.szHexFiles,addr da.szAssemblerIni
		invoke GetPrivateProfileString,addr szIniFile,addr szIniResource,NULL,addr da.szResourceFiles,sizeof da.szResourceFiles,addr da.szAssemblerIni
		;Get project browser file types
		invoke SendMessage,ha.hProjectBrowser,RPBM_ADDFILEEXT,0,0
		invoke GetPrivateProfileString,addr szIniFile,addr szIniType,NULL,addr da.szTypes,sizeof da.szTypes,addr da.szAssemblerIni
		invoke strcpy,addr tmpbuff,addr da.szTypes
		xor ebx,ebx
		.while tmpbuff
			inc		ebx
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer
			mov		pbfe.id,ebx
			invoke strcpy,addr pbfe.szfileext,addr buffer
			invoke SendMessage,ha.hProjectBrowser,RPBM_ADDFILEEXT,addr [ebx-1],addr pbfe
		.endw
		;Get colors
		invoke GetColors
		;Get code blocks
		mov		esi,offset da.rabdstr
		mov		edi,offset da.rabd
		invoke RtlZeroMemory,edi,sizeof da.rabd
		mov		ebx,1
		.while ebx<33
			invoke BinToDec,ebx,addr buffer
			invoke GetPrivateProfileString,addr szIniCodeBlock,addr buffer,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
			.break .if !eax
			invoke GetItemStr,addr tmpbuff,addr szNULL,esi
			.if byte ptr [esi]
				mov		[edi].RABLOCKDEF.lpszStart,esi
				invoke strlen,esi
				lea		esi,[esi+eax+2]
			.endif 
			invoke GetItemStr,addr tmpbuff,addr szNULL,esi 
			.if byte ptr [esi]
				mov		[edi].RABLOCKDEF.lpszEnd,esi
				invoke strlen,esi
				lea		esi,[esi+eax+2]
			.endif 
			invoke GetItemStr,addr tmpbuff,addr szNULL,esi 
			.if byte ptr [esi]
				mov		[edi].RABLOCKDEF.lpszNot1,esi
				invoke strlen,esi
				lea		esi,[esi+eax+2]
			.endif 
			invoke GetItemStr,addr tmpbuff,addr szNULL,esi 
			.if byte ptr [esi]
				mov		[edi].RABLOCKDEF.lpszNot2,esi
				invoke strlen,esi
				lea		esi,[esi+eax+2]
			.endif 
			invoke GetItemInt,addr tmpbuff,0
			push	eax
			invoke GetItemInt,addr tmpbuff,0
			pop		edx
			shl		eax,16
			or		eax,edx
			mov		[edi].RABLOCKDEF.flag,eax
			inc		ebx
			lea		edi,[edi+sizeof RABLOCKDEF]
		.endw
		;Reset block defs
		invoke SendMessage,ha.hOutput,REM_ADDBLOCKDEF,0,0
		mov		esi,offset da.rabd
		.while [esi].RABLOCKDEF.lpszStart
			invoke SendMessage,ha.hOutput,REM_ADDBLOCKDEF,0,esi
			mov		eax,[esi].RABLOCKDEF.lpszStart
			call	FixString
			mov		eax,[esi].RABLOCKDEF.lpszEnd
			call	FixString
			lea		esi,[esi+sizeof RABLOCKDEF]
		.endw
		invoke GetPrivateProfileString,addr szIniCodeBlock,addr szIniCmnt,NULL,addr tmpbuff,64,addr da.szAssemblerIni
		invoke GetItemStr,addr tmpbuff,addr szNULL,addr da.szCmntStart
		invoke GetItemStr,addr tmpbuff,addr szNULL,addr da.szCmntEnd
		invoke SendMessage,ha.hOutput,REM_SETCOMMENTBLOCKS,addr da.szCmntStart,addr da.szCmntEnd
		;Get options
		invoke GetPrivateProfileString,addr szIniEdit,addr szIniBraceMatch,NULL,addr da.szBraceMatch,sizeof da.szBraceMatch,addr da.szAssemblerIni
		invoke SendMessage,ha.hOutput,REM_BRACKETMATCH,0,offset da.szBraceMatch
		invoke GetPrivateProfileString,addr szIniEdit,addr szIniOption,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
		invoke GetItemInt,addr tmpbuff,4
		mov		da.edtopt.tabsize,eax
		invoke GetItemInt,addr tmpbuff,EDTOPT_INDENT or EDTOPT_LINENR
		mov		da.edtopt.fopt,eax
		invoke GetPrivateProfileString,addr szIniFile,addr szIniFilter,NULL,addr tmpbuff,sizeof da.szFilter+2,addr da.szAssemblerIni
		invoke GetItemInt,addr tmpbuff,1
		invoke SendMessage,ha.hFileBrowser,FBM_SETFILTER,TRUE,eax
		invoke GetItemStr,addr tmpbuff,addr szDefFilter,addr da.szFilter
		invoke SendMessage,ha.hFileBrowser,FBM_SETFILTERSTRING,TRUE,addr da.szFilter
		;Get parser
		invoke SendMessage,ha.hProperty,PRM_RESET,0,0
		invoke GetPrivateProfileInt,addr szIniParse,addr szIniAssembler,0,addr da.szAssemblerIni
		mov		da.nAsm,eax
		invoke SendMessage,ha.hProperty,PRM_SETLANGUAGE,da.nAsm,0
		invoke SendMessage,ha.hProperty,PRM_SETCHARTAB,0,da.lpCharTab
		invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szCmntBlockSt
		invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szCmntBlockEn
		invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szCmntChar
		invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szString
		invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szLineCont
		invoke SendMessage,ha.hProperty,PRM_SETGENDEF,0,addr defgen
		invoke GetPrivateProfileString,addr szIniParse,addr szIniDef,NULL,addr buffer,sizeof buffer,addr da.szAssemblerIni
		invoke GetPrivateProfileString,addr szIniParse,addr szIniType,NULL,addr buffcbo,sizeof buffcbo,addr da.szAssemblerIni
		.if eax
			.while buffcbo
				invoke GetItemStr,addr buffcbo,addr szNULL,addr bufftype
				.if bufftype
					invoke GetPrivateProfileString,addr szIniParse,addr bufftype,NULL,addr buffer,sizeof buffer,addr da.szAssemblerIni
					.while buffer
						invoke GetItemInt,addr buffer,0
						mov		deftype.nType,al
						invoke GetItemInt,addr buffer,0
						mov		deftype.nDefType,al
						invoke GetItemStr,addr buffer,addr szNULL,addr deftype.Def
						invoke GetItemStr,addr buffer,addr szNULL,addr deftype.szWord
						invoke strlen,addr deftype.szWord
						mov		deftype.len,al
						invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftype
					.endw
					movzx	edx,deftype.Def
					invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,edx,addr bufftype
				.endif
			.endw
			invoke GetPrivateProfileString,addr szIniParse,addr szIniIgnore,NULL,addr buffer,sizeof buffer,addr da.szAssemblerIni
			.while buffer
				invoke GetItemInt,addr buffer,0
				push	eax
				invoke GetItemStr,addr buffer,addr szNULL,addr bufftype
				pop		edx
				.if bufftype
					invoke SendMessage,ha.hProperty,PRM_ADDIGNORE,edx,addr bufftype
				.endif
			.endw
			invoke SendMessage,ha.hProperty,PRM_SELECTPROPERTY,'p',0
		.endif
		invoke GetCodeComplete
		invoke GetKeywords
		mov		eax,TRUE
	.endif
	ret

FixString:
	.if eax
		.while byte ptr [eax]
			.if byte ptr [eax]=='|'
				mov		byte ptr [eax],0
			.endif
			inc		eax
		.endw
	.endif
	retn

OpenAssembler endp

