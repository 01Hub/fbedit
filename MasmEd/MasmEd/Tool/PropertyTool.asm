
.const

szPrpCode		db 'Code',0
szPrpLabel		db 'Label',0
szPrpConst		db 'Const',0
szPrpData		db 'Data',0
szPrpStruct		db 'Struct',0

szCCs			db 's',0

defgen			DEFGEN <'comment +',<0>,';',<27h,22h>,'\'>

deftypeproc		DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_PROC,'p',4,'proc'>
deftypeendp		DEFTYPE <TYPE_OPTNAMEFIRST,DEFTYPE_ENDPROC,'p',4,'endp'>
deftypelabel	DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_LABEL,'l',1,':'>

deftypeconst	DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_CONST,'c',3,'equ'>
deftypelocal	DEFTYPE <TYPE_NAMESECOND,DEFTYPE_LOCALDATA,'l',5,'local'>

deftypestruct	DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_STRUCT,'s',6,'struct'>
deftypestruc	DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_STRUCT,'s',5,'struc'>
deftypeunion	DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_STRUCT,'s',5,'union'>
deftypestructo	DEFTYPE <TYPE_OPTNAMESECOND,DEFTYPE_STRUCT,'s',6,'struct'>
deftypestruco	DEFTYPE <TYPE_OPTNAMESECOND,DEFTYPE_STRUCT,'s',5,'struc'>
deftypeuniono	DEFTYPE <TYPE_OPTNAMESECOND,DEFTYPE_STRUCT,'s',5,'union'>
deftypeends		DEFTYPE <TYPE_OPTNAMEFIRST,DEFTYPE_ENDSTRUCT,'s',4,'ends'>


szApiCallFile	db 'masmApiCall.api',0
szApiConstFile	db 'masmApiConst.api',0
szApiStructFile	db 'masmApiStruct.api',0
szApiTypeFile	db 'masmApiType.api',0
szApiWordFile	db 'masmApiWord.api',0

ignorefirstword	db 'option',0,'include',0,'includelib',0,'invoke',0,0
ignoreparam		db 'private',0,'public',0,'uses',0,'eax',0,'ebx',0,'ecx',0,'edx',0,'esi',0,'edi',0,'ebp',0,'esp',0,0
datatypes		db 'db',0,'dw',0,'dd',0,'dq',0,'df',0,'dt',0,'byte',0,'word',0,'dword',0,'qword',0,'real4',0,'real8',0,'real10',0,'tbyte',0,0
datatypeptr		db 'ptr',0

.data

deftypedata		DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_DATA,'d',2,'db'>

.code

SetPropertyDefs proc uses esi
	LOCAL	buffer[MAX_PATH]:BYTE

	; Set character table
	invoke GetCharTabPtr
	invoke SendMessage,ha.hProperty,PRM_SETCHARTAB,0,eax
	;Combo items
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,'p',addr szPrpCode
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,'l',addr szPrpLabel
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,'c',addr szPrpConst
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,'d',addr szPrpData
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,'s',addr szPrpStruct
	;Set general definitions
	invoke SendMessage,ha.hProperty,PRM_SETGENDEF,0,addr defgen
	;Words to ignore
	mov		esi,offset ignorefirstword
	.while byte ptr [esi]
		invoke SendMessage,ha.hProperty,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,esi
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	mov		esi,offset ignoreparam
	.while byte ptr [esi]
		invoke SendMessage,ha.hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,esi
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	invoke SendMessage,ha.hProperty,PRM_ADDIGNORE,IGNORE_PTR,offset datatypeptr
	;Def types
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypeproc
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypeendp
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypelabel
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypeconst
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypelocal
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypestruct
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypestruc
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypeunion
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypeends
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypestructo
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypestruco
	invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypeuniono
	mov		esi,offset datatypes
	.while byte ptr [esi]
		invoke strcpy,addr deftypedata.szWord,esi
		invoke strlen,esi
		mov		deftypedata.len,al
		lea		esi,[esi+eax+1]
		invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftypedata
	.endw
	;Add api files
	mov		esi,offset szApiCallFile
	call	MakePath
	mov		edx,2 shl 8 or 'P'
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,edx,addr buffer
	mov		esi,offset szApiConstFile
	call	MakePath
	mov		edx,2 shl 8 or 'C'
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,edx,addr buffer
	mov		esi,offset szApiStructFile
	call	MakePath
	mov		edx,2 shl 8 or 'S'
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,edx,addr buffer
	mov		esi,offset szApiTypeFile
	call	MakePath
	mov		edx,3 shl 8 or 'T'
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,edx,addr buffer
	mov		esi,offset szApiWordFile
	call	MakePath
	mov		edx,2 shl 8 or 'W'
	invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,edx,addr buffer
	;Set default selection
	invoke SendMessage,ha.hProperty,PRM_SELECTPROPERTY,'p',0
	invoke SendMessage,ha.hProperty,PRM_SETSELBUTTON,2,0
	invoke SendMessage,ha.hProperty,PRM_SETLANGUAGE,nMASM,0
	ret

MakePath:
	invoke strcpy,addr buffer,addr da.AppPath
	invoke strcat,addr buffer,addr szBackSlash
	invoke strcat,addr buffer,esi
	retn

SetPropertyDefs endp

ParseEdit proc hWin:HWND
	LOCAL	hMem:HGLOBAL

	invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,hWin,0
	invoke SendMessage,hWin,WM_GETTEXTLENGTH,0,0
	inc		eax
	push	eax
	add		eax,64
	and		eax,0FFFFFFE0h
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
	mov		hMem,eax
	pop		eax
	invoke SendMessage,hWin,WM_GETTEXT,eax,hMem
	invoke SendMessage,ha.hProperty,PRM_PARSEFILE,hWin,hMem
	invoke GlobalFree,hMem
	invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
	ret

ParseEdit endp

;DumpStruct proc uses esi
;
;	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr szCCs,addr szNULL
;	.while eax
;		mov		esi,eax
;		invoke SendMessage,ha.hOut,EM_REPLACESEL,FALSE,esi
;		invoke SendMessage,ha.hOut,EM_REPLACESEL,FALSE,addr szComma
;		invoke strlen,esi
;		lea		esi,[esi+eax+1]
;		invoke SendMessage,ha.hOut,EM_REPLACESEL,FALSE,esi
;		invoke SendMessage,ha.hOut,EM_REPLACESEL,FALSE,addr szCr
;		invoke SendMessage,ha.hOut,EM_SCROLLCARET,0,0
;		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
;	.endw
;	ret
;
;DumpStruct endp
