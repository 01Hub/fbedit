
.const

szPrpCode		db 'Code',0
szPrpConst		db 'Const',0
szPrpData		db 'Data',0
szPrpStruct		db 'Struct',0

defgen			DEFGEN <'comment +',<0>,';',<27h,22h>,'\'>
szIgnore1		db 'option',0
szIgnore2		db 'include',0
szIgnore3		db 'includelib',0
szIgnore4		db '@@:',0
szIgnore5		db 'uses',0
szIgnore6		db 'eax',0
szIgnore7		db 'ebx',0
szIgnore8		db 'ecx',0
szIgnore9		db 'edx',0
szIgnore10		db 'esi',0
szIgnore11		db 'edi',0
szIgnore12		db 'ebp',0
szIgnore13		db 'esp',0

deftypeproc		DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_PROC,'p',4,'proc'>
deftypeendp		DEFTYPE <TYPE_OPTNAMEFIRST,DEFTYPE_ENDPROC,'p',4,'endp'>

deftypeconst	DEFTYPE <TYPE_NAMEFIRST,DEFTYPE_CONST,'c',3,'equ'>
deftypelocal	DEFTYPE <TYPE_NAMESECOND,DEFTYPE_LOCALDATA,'l',5,'local'>

.code

SetPropertyDefs proc

	; Set character table
	invoke GetCharTabPtr
	invoke SendMessage,hProperty,PRM_SETCHARTAB,0,eax
	;Combo items
	invoke SendMessage,hProperty,PRM_ADDPROPERTYTYPE,'p',addr szPrpCode
	invoke SendMessage,hProperty,PRM_ADDPROPERTYTYPE,'c',addr szPrpConst
	invoke SendMessage,hProperty,PRM_ADDPROPERTYTYPE,'d',addr szPrpData
	invoke SendMessage,hProperty,PRM_ADDPROPERTYTYPE,'s',addr szPrpStruct
	;Set general definitions
	invoke SendMessage,hProperty,PRM_SETGENDEF,0,addr defgen
	;Words to ignore
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,addr szIgnore1
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,addr szIgnore2
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,addr szIgnore3
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_LINEFIRSTWORD,addr szIgnore4
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore5
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore6
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore7
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore8
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore9
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore10
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore11
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore12
	invoke SendMessage,hProperty,PRM_ADDIGNORE,IGNORE_PROCPARAM,addr szIgnore13
	;Def types
	invoke SendMessage,hProperty,PRM_ADDDEFTYPE,0,addr deftypeproc
	invoke SendMessage,hProperty,PRM_ADDDEFTYPE,0,addr deftypeendp
	invoke SendMessage,hProperty,PRM_ADDDEFTYPE,0,addr deftypeconst
	invoke SendMessage,hProperty,PRM_ADDDEFTYPE,0,addr deftypelocal
	;Add files
	mov		edx,2 shl 8 or 'P'
	invoke SendMessage,hProperty,PRM_ADDPROPERTYFILE,edx,addr szApiCallFile
	mov		edx,2 shl 8 or 'C'
	invoke SendMessage,hProperty,PRM_ADDPROPERTYFILE,edx,addr szApiConstFile
	;Set default selection
	invoke SendMessage,hProperty,PRM_SELECTPROPERTY,'p',0
	invoke SendMessage,hProperty,PRM_SETSELBUTTON,2,0
	;Set colors
	;invoke SendMessage,hProperty,PRM_SETBACKCOLOR,0,0C0C0E0h
	;invoke SendMessage,hProperty,PRM_SETTEXTCOLOR,0,0800000h
	ret

SetPropertyDefs endp

ParseEdit proc hWin:HWND
	LOCAL	hMem:HGLOBAL

	invoke SendMessage,hProperty,PRM_DELPROPERTY,hWin,0
	invoke SendMessage,hWin,WM_GETTEXTLENGTH,0,0
	inc		eax
	push	eax
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
	mov		hMem,eax
	pop		eax
	invoke SendMessage,hWin,WM_GETTEXT,eax,hMem
	invoke SendMessage,hProperty,PRM_PARSEFILE,hWin,hMem
	invoke GlobalFree,hMem
	invoke SendMessage,hProperty,PRM_SELECTPROPERTY,'p',0
	ret

ParseEdit endp