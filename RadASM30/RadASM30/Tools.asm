SBLASTPANE			equ 350

.const

szProject			BYTE 'Project',0
szFile				BYTE 'File',0
szProperties		BYTE 'Properties',0
szOutput			BYTE 'Output',0
szImmediate			BYTE 'Immediate',0

szTahoma			BYTE 'Tahoma',0
szCourierNew		BYTE 'Courier New',0
szTerminal			BYTE 'Terminal',0


tbrbtnsfile			TBBUTTON <20,IDM_FILE_PRINT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
					TBBUTTON <6,IDM_FILE_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <7,IDM_FILE_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <8,IDM_FILE_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <11,IDM_FILE_SAVEALL,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

tbrbtnsedit1		TBBUTTON <0,IDM_EDIT_CUT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <1,IDM_EDIT_COPY,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <2,IDM_EDIT_PASTE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
					TBBUTTON <3,IDM_EDIT_UNDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <4,IDM_EDIT_REDO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <5,IDM_EDIT_DELETE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
					TBBUTTON <9,IDM_EDIT_FIND,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <10,IDM_EDIT_REPLACE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

tbrbtnsedit2		TBBUTTON <16,IDM_EDIT_TOGGLEBM,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <17,IDM_EDIT_NEXTBM,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <18,IDM_EDIT_PREVBM,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <19,IDM_EDIT_CLEARBM,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
					TBBUTTON <23,IDM_EDIT_INDENT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <22,IDM_EDIT_OUTDENT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <24,IDM_EDIT_COMMENT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <25,IDM_EDIT_UNCOMMENT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>


tbrbtnsview			TBBUTTON <21,IDM_VIEW_OUTPUT,TBSTATE_ENABLED,TBSTYLE_BUTTON or TBSTYLE_CHECK,0,0>
					TBBUTTON <26,IDM_VIEW_PROJECT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

tbrbtnsmake			TBBUTTON <12,IDM_MAKE_ASSEMBLE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <13,IDM_MAKE_BUILD,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <14,IDM_MAKE_RUN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
					TBBUTTON <15,IDM_MAKE_GO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

.data?

OldStatusProc		DWORD ?

.code

CreateTools proc
	LOCAL	dck:DOCKING
	LOCAL	tci:TC_ITEM
	LOCAL	buffer[256]:BYTE

	invoke CreateWindowEx,0,addr szToolClassName,NULL,WS_CHILD,0,0,0,0,ha.hWnd,0,ha.hInstance,0
	mov		ha.hTool,eax
	invoke SendMessage,ha.hTool,TLM_INIT,ha.hClient,ha.hWnd
	;Project tool
	invoke GetPrivateProfileString,addr szIniTool,addr szIniProject,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	mov		dck.ID,1
	mov		dck.Caption,offset szProject
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Visible,eax
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Docked,eax
	invoke GetItemInt,addr buffer,TL_RIGHT
	mov		dck.Position,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.IsChild,eax
	invoke GetItemInt,addr buffer,180
	mov		dck.dWidth,eax
	invoke GetItemInt,addr buffer,200
	mov		dck.dHeight,eax
	invoke GetItemInt,addr buffer,10
	mov		dck.fr.left,eax
	invoke GetItemInt,addr buffer,10
	mov		dck.fr.top,eax
	invoke GetItemInt,addr buffer,200
	mov		dck.fr.right,eax
	invoke GetItemInt,addr buffer,300
	mov		dck.fr.bottom,eax
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolProject,eax
	invoke CreateWindowEx,0,addr szTabControlClassName,NULL,WS_VISIBLE or WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or TCS_FOCUSNEVER,0,0,0,0,ha.hToolProject,0,ha.hInstance,0
	mov		ha.hTabProject,eax
	invoke SendMessage,ha.hTabProject,WM_SETFONT,ha.hToolFont,FALSE
	mov		tci.imask,TCIF_TEXT
	mov		tci.pszText,offset szFile
	invoke SendMessage,ha.hTabProject,TCM_INSERTITEM,999,addr tci
	invoke SendMessage,ha.hTabProject,TCM_SETCURSEL,eax,0
	mov		tci.pszText,offset szProject
	invoke SendMessage,ha.hTabProject,TCM_INSERTITEM,999,addr tci
	invoke CreateWindowEx,0,addr szFBClassName,NULL,WS_CHILD or WS_VISIBLE or FBSTYLE_FLATTOOLBAR,0,0,0,0,ha.hToolProject,0,ha.hInstance,0
	mov		ha.hFileBrowser,eax
	invoke CreateWindowEx,0,addr szPBClassName,NULL,WS_CHILD or RPBS_FLATTOOLBAR or RPBS_NOPATH,0,0,0,0,ha.hToolProject,0,ha.hInstance,0
	mov		ha.hProjectBrowser,eax
	;Properties tool
	invoke GetPrivateProfileString,addr szIniTool,addr szIniProperty,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	mov		dck.ID,2
	mov		dck.Caption,offset szProperties
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Visible,eax
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Docked,eax
	invoke GetItemInt,addr buffer,TL_RIGHT
	mov		dck.Position,eax
	invoke GetItemInt,addr buffer,1
	mov		dck.IsChild,eax
	invoke GetItemInt,addr buffer,150
	mov		dck.dWidth,eax
	invoke GetItemInt,addr buffer,250
	mov		dck.dHeight,eax
	invoke GetItemInt,addr buffer,20
	mov		dck.fr.left,eax
	invoke GetItemInt,addr buffer,20
	mov		dck.fr.top,eax
	invoke GetItemInt,addr buffer,200
	mov		dck.fr.right,eax
	invoke GetItemInt,addr buffer,300
	mov		dck.fr.bottom,eax
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolProperties,eax
	invoke CreateWindowEx,0,addr szPropertyClassName,NULL,WS_CHILD or WS_VISIBLE or PRSTYLE_FLATTOOLBAR or PRSTYLE_PROJECT,0,0,0,0,ha.hToolProperties,0,ha.hInstance,0
	mov		ha.hProperties,eax
	invoke SendMessage,ha.hProperties,WM_SETFONT,ha.hToolFont,FALSE
	;Output tool
	invoke GetPrivateProfileString,addr szIniTool,addr szIniOutput,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	mov		dck.ID,3
	mov		dck.Caption,offset szOutput
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Visible,eax
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Docked,eax
	invoke GetItemInt,addr buffer,TL_BOTTOM
	mov		dck.Position,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.IsChild,eax
	invoke GetItemInt,addr buffer,150
	mov		dck.dWidth,eax
	invoke GetItemInt,addr buffer,110
	mov		dck.dHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.fr.left,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.fr.top,eax
	invoke GetItemInt,addr buffer,200
	mov		dck.fr.right,eax
	invoke GetItemInt,addr buffer,300
	mov		dck.fr.bottom,eax
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolOutput,eax
	invoke CreateWindowEx,0,addr szTabControlClassName,NULL,WS_VISIBLE or WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or TCS_FOCUSNEVER or TCS_VERTICAL,0,0,0,0,ha.hToolOutput,0,ha.hInstance,0
	mov		ha.hTabOutput,eax
	invoke SendMessage,ha.hTabOutput,WM_SETFONT,ha.hToolFont,FALSE
	mov		tci.imask,TCIF_TEXT
	mov		tci.pszText,offset szOutput
	invoke SendMessage,ha.hTabOutput,TCM_INSERTITEM,999,addr tci
	invoke SendMessage,ha.hTabOutput,TCM_SETCURSEL,eax,0
	mov		tci.pszText,offset szImmediate
	invoke SendMessage,ha.hTabOutput,TCM_INSERTITEM,999,addr tci
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szRAEditClass,NULL,WS_VISIBLE or WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or STYLE_NOSPLITT or STYLE_NOLINENUMBER or STYLE_NOCOLLAPSE or STYLE_NOSTATE or STYLE_NOSIZEGRIP,0,0,0,0,ha.hToolOutput,0,ha.hInstance,0
	mov		ha.hOutput,eax
	invoke SendMessage,ha.hOutput,REM_SETFONT,0,addr ha.racf
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szRAEditClass,NULL,WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or STYLE_NOSPLITT or STYLE_NOLINENUMBER or STYLE_NOCOLLAPSE or STYLE_NOSTATE or STYLE_NOSIZEGRIP,0,0,0,0,ha.hToolOutput,0,ha.hInstance,0
	mov		ha.hImmediate,eax
	invoke SendMessage,ha.hImmediate,REM_SETFONT,0,addr ha.racf
	;Tab tool
	invoke GetPrivateProfileString,addr szIniTool,addr szIniTab,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	mov		dck.ID,4
	mov		dck.Caption,offset szNULL
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Visible,eax
	invoke GetItemInt,addr buffer,TRUE
	mov		dck.Docked,eax
	invoke GetItemInt,addr buffer,TL_TOP
	mov		dck.Position,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.IsChild,eax
	invoke GetItemInt,addr buffer,150
	mov		dck.dWidth,eax
	invoke GetItemInt,addr buffer,30
	mov		dck.dHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.fr.left,eax
	invoke GetItemInt,addr buffer,0
	mov		dck.fr.top,eax
	invoke GetItemInt,addr buffer,200
	mov		dck.fr.right,eax
	invoke GetItemInt,addr buffer,30
	mov		dck.fr.bottom,eax
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolTab,eax
	invoke CreateWindowEx,0,addr szTabControlClassName,NULL,WS_VISIBLE or WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or TCS_FOCUSNEVER or TCS_BUTTONS or TCS_FOCUSNEVER,0,0,0,0,ha.hToolTab,0,ha.hInstance,0
	mov		ha.hTab,eax
	invoke SendMessage,ha.hTab,WM_SETFONT,ha.hToolFont,FALSE
	invoke SetWindowLong,ha.hTab,GWL_WNDPROC,offset TabProc
	mov		lpOldTabProc,eax
	ret

CreateTools endp

SaveTools proc uses esi edi
	LOCAL	buffer[256]:BYTE

	invoke SendMessage,ha.hTool,TLM_GETSTRUCT,0,ha.hToolProject
	mov		esi,eax
	mov		edi,offset szIniProject
	call	SaveIt
	invoke SendMessage,ha.hTool,TLM_GETSTRUCT,0,ha.hToolProperties
	mov		esi,eax
	mov		edi,offset szIniProperty
	call	SaveIt
	invoke SendMessage,ha.hTool,TLM_GETSTRUCT,0,ha.hToolOutput
	mov		esi,eax
	mov		edi,offset szIniOutput
	call	SaveIt
	invoke SendMessage,ha.hTool,TLM_GETSTRUCT,0,ha.hToolTab
	mov		esi,eax
	mov		edi,offset szIniTab
	call	SaveIt
	ret

SaveIt:
	mov		buffer,0
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.Visible
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.Docked
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.Position
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.IsChild
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.dWidth
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.dHeight
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.fr.left
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.fr.top
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.fr.right
	invoke PutItemInt,addr buffer,[esi].TOOL.dck.fr.bottom
	invoke WritePrivateProfileString,addr szIniTool,edi,addr buffer[1],addr da.szRadASMIni
	retn

SaveTools endp

MakeToolBar proc uses ebx,lpBtn:DWORD,nBtn:DWORD

	invoke CreateWindowEx,0,addr szToolBarClassName,0,WS_CHILD or WS_VISIBLE or TBSTYLE_FLAT or TBSTYLE_TOOLTIPS or CCS_NODIVIDER or CCS_NORESIZE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,100,22,ha.hWnd,0,ha.hInstance,0
	mov		ebx,eax
;	.if fNT
;		;Unicode
;		invoke SendMessage,ebx,TB_SETUNICODEFORMAT,TRUE,0
;	.endif
	;Set toolbar struct size
	invoke SendMessage,ebx,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	;Set toolbar buttons
	invoke SendMessage,ebx,TB_ADDBUTTONS,nBtn,lpBtn
	;Set the imagelist
	invoke SendMessage,ebx,TB_SETIMAGELIST,0,ha.hImlTbr
	mov		eax,ebx
	ret

MakeToolBar endp

DoToolBar proc

	invoke MakeToolBar,addr tbrbtnsfile,6
	mov		ha.hTbrFile,eax
	invoke MakeToolBar,addr tbrbtnsedit1,10
	mov		ha.hTbrEdit1,eax
	invoke MakeToolBar,addr tbrbtnsedit2,9
	mov		ha.hTbrEdit2,eax
	invoke MakeToolBar,addr tbrbtnsview,2
	mov		ha.hTbrView,eax
	invoke MakeToolBar,addr tbrbtnsmake,5
	mov		ha.hTbrMake,eax
	ret

DoToolBar endp

DoReBar proc uses ebx esi edi
	LOCAL	rbbi:REBARBANDINFO
	LOCAL	buffer[256]:BYTE
	LOCAL	nIns:DWORD

	mov		edx,WS_CHILD or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or CCS_NODIVIDER or CCS_NOPARENTALIGN
	mov		edx,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or CCS_NODIVIDER or CCS_NOPARENTALIGN
	invoke CreateWindowEx,0,addr szReBarClassName,NULL,edx,0,0,0,0,ha.hWnd,NULL,ha.hInstance,NULL
	mov		ha.hReBar,eax
	invoke GetPrivateProfileString,addr szIniWin,addr szIniReBar,addr szDefReBar,addr buffer,sizeof buffer,addr da.szRadASMIni
	mov		nIns,0
	.while buffer
		invoke RtlZeroMemory,addr rbbi,sizeof REBARBANDINFO
		mov		rbbi.cbSize,sizeof REBARBANDINFO
		mov		rbbi.fMask,RBBIM_STYLE or RBBIM_CHILD or RBBIM_SIZE or RBBIM_CHILDSIZE or RBBIM_ID
		;ID
		invoke GetItemInt,addr buffer,0
		mov		ebx,eax
		;Style
		invoke GetItemInt,addr buffer,0
		mov		esi,eax
		;lx
		invoke GetItemInt,addr buffer,0
		mov		edi,eax
		.if ebx==1
			;File toolbar
			mov		eax,esi
			and		eax,-1 xor RBBS_HIDDEN
			mov		rbbi.fStyle,eax
			mov		rbbi.lx,edi
			mov		rbbi.cyMinChild,22
			mov		rbbi.cxMinChild,123
			mov		rbbi.cxIdeal,123
			mov		eax,ha.hTbrFile
			mov		rbbi.hwndChild,eax
			mov		rbbi.wID,1
			invoke SendMessage,ha.hReBar,RB_INSERTBAND,nIns,addr rbbi
			mov		rbbi.fMask,RBBIM_STYLE
			mov		rbbi.fStyle,esi
			invoke SendMessage,ha.hReBar,RB_SETBANDINFO,nIns,addr rbbi
		.elseif ebx==2
			;Edit1 toolbar
			mov		eax,esi
			and		eax,-1 xor RBBS_HIDDEN
			mov		rbbi.fStyle,eax
			mov		rbbi.lx,edi
			mov		rbbi.cyMinChild,22
			mov		rbbi.cxMinChild,199
			mov		rbbi.cxIdeal,199
			mov		eax,ha.hTbrEdit1
			mov		rbbi.hwndChild,eax
			mov		rbbi.wID,2
			invoke SendMessage,ha.hReBar,RB_INSERTBAND,nIns,addr rbbi
			mov		rbbi.fMask,RBBIM_STYLE
			mov		rbbi.fStyle,esi
			invoke SendMessage,ha.hReBar,RB_SETBANDINFO,nIns,addr rbbi
		.elseif ebx==3
			;Edit2 toolbar
			mov		eax,esi
			and		eax,-1 xor RBBS_HIDDEN
			mov		rbbi.fStyle,eax
			mov		rbbi.lx,edi
			mov		rbbi.cxMinChild,193
			mov		rbbi.cxIdeal,193
			mov		eax,ha.hTbrEdit2
			mov		rbbi.hwndChild,eax
			mov		rbbi.wID,3
			invoke SendMessage,ha.hReBar,RB_INSERTBAND,nIns,addr rbbi
			mov		rbbi.fMask,RBBIM_STYLE
			mov		rbbi.fStyle,esi
			invoke SendMessage,ha.hReBar,RB_SETBANDINFO,nIns,addr rbbi
		.elseif ebx==4
			;View toolbar
			mov		eax,esi
			and		eax,-1 xor RBBS_HIDDEN
			mov		rbbi.fStyle,eax
			mov		rbbi.lx,edi
			mov		rbbi.cyMinChild,22
			mov		rbbi.cxMinChild,47
			mov		rbbi.cxIdeal,47
			mov		eax,ha.hTbrView
			mov		rbbi.hwndChild,eax
			mov		rbbi.wID,4
			invoke SendMessage,ha.hReBar,RB_INSERTBAND,nIns,addr rbbi
			mov		rbbi.fMask,RBBIM_STYLE
			mov		rbbi.fStyle,esi
			invoke SendMessage,ha.hReBar,RB_SETBANDINFO,nIns,addr rbbi
		.elseif ebx==5
			;Make toolbar
			mov		eax,esi
			and		eax,-1 xor RBBS_HIDDEN
			mov		rbbi.fStyle,eax
			mov		rbbi.lx,edi
			mov		rbbi.cyMinChild,22
			mov		rbbi.cxMinChild,101
			mov		rbbi.cxIdeal,101
			mov		eax,ha.hTbrMake
			mov		rbbi.hwndChild,eax
			mov		rbbi.wID,5
			invoke SendMessage,ha.hReBar,RB_INSERTBAND,nIns,addr rbbi
			mov		rbbi.fMask,RBBIM_STYLE
			mov		rbbi.fStyle,esi
			invoke SendMessage,ha.hReBar,RB_SETBANDINFO,nIns,addr rbbi
		.elseif ebx==6
			;Build combobox
			mov		eax,esi
			and		eax,-1 xor RBBS_HIDDEN
			mov		rbbi.fStyle,eax
			mov		rbbi.lx,edi
			mov		rbbi.cyMinChild,22
			mov		rbbi.cxMinChild,123
			mov		rbbi.cxIdeal,123
			invoke CreateWindowEx,0,addr szStaticClassName,NULL,WS_CHILD or WS_VISIBLE or CBS_DROPDOWNLIST or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,ha.hWnd,NULL,ha.hInstance,NULL
			mov		ha.hStcBuild,eax
			mov		rbbi.hwndChild,eax
			invoke CreateWindowEx,0,addr szComboBoxClassName,NULL,WS_CHILD or WS_VISIBLE or CBS_DROPDOWNLIST or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,123,150,ha.hStcBuild,NULL,ha.hInstance,NULL
			mov		ha.hCboBuild,eax
			invoke SendMessage,ha.hCboBuild,WM_SETFONT,ha.hToolFont,FALSE
			mov		rbbi.wID,6
			invoke SendMessage,ha.hReBar,RB_INSERTBAND,nIns,addr rbbi
			mov		rbbi.fMask,RBBIM_STYLE
			mov		rbbi.fStyle,esi
			invoke SendMessage,ha.hReBar,RB_SETBANDINFO,nIns,addr rbbi
		.endif
		inc		nIns
	.endw
	ret

DoReBar endp

SaveReBar proc uses ebx
	LOCAL	rbbi:REBARBANDINFO
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	mov		ebx,0
	.while ebx<6
		call	SaveIt
		inc		ebx
	.endw
	invoke WritePrivateProfileString,addr szIniWin,addr szIniReBar,addr buffer[1],addr da.szRadASMIni
	ret

SaveIt:
	invoke RtlZeroMemory,addr rbbi,sizeof REBARBANDINFO
	mov		rbbi.cbSize,sizeof REBARBANDINFO
	mov		rbbi.fMask,RBBIM_STYLE or RBBIM_SIZE or RBBIM_ID
	invoke SendMessage,ha.hReBar,RB_GETBANDINFO,ebx,addr rbbi
	.if eax
		invoke PutItemInt,addr buffer,rbbi.wID
		invoke PutItemInt,addr buffer,rbbi.fStyle
		invoke PutItemInt,addr buffer,rbbi.lx
	.endif
	retn

SaveReBar endp

HideToolBar proc uses ebx,ID:DWORD
	LOCAL	rbbi:REBARBANDINFO

	mov		ebx,0
	.while ebx<6
		mov		rbbi.cbSize,sizeof REBARBANDINFO
		mov		rbbi.fMask,RBBIM_STYLE or RBBIM_ID
		invoke SendMessage,ha.hReBar,RB_GETBANDINFO,ebx,addr rbbi
		.if eax
			mov		eax,ID
			.if eax==rbbi.wID
				xor		rbbi.fStyle,RBBS_HIDDEN
				invoke SendMessage,ha.hReBar,RB_SETBANDINFO,ebx,addr rbbi
				.break
			.endif
		.endif
		inc		ebx
	.endw
	ret

HideToolBar endp

StatusProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_LBUTTONUP
		mov		eax,lParam
		and		eax,0FFFFh
		.if eax>SBLASTPANE
;			invoke SendMessage,hWnd,WM_COMMAND,IDM_VIEW_OUTPUTWINDOW,0
		.endif
	.endif
	invoke CallWindowProc,OldStatusProc,hWin,uMsg,wParam,lParam
	ret

StatusProc endp

DoStatus proc
	LOCAL	sbParts[4]:DWORD

	test	da.win.fView,VIEW_STATUSBAR
	.if !ZERO?
		mov		eax,WS_CHILD or WS_VISIBLE or SBS_SIZEGRIP or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
	.else
		mov		eax,WS_CHILD or SBS_SIZEGRIP or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
	.endif
	invoke CreateStatusWindow,eax,NULL,ha.hWnd,200
	mov		ha.hStatus,eax
	invoke SetWindowLong,ha.hStatus,GWL_WNDPROC,offset StatusProc
	mov		OldStatusProc,eax
	mov [sbParts+0],225				; pixels from left
	mov [sbParts+4],250				; pixels from left
	mov [sbParts+8],SBLASTPANE		; pixels from left
	mov [sbParts+12],-1				; last part
	invoke SendMessage,ha.hStatus,SB_SETPARTS,4,addr sbParts
	ret

DoStatus endp

DoImageList proc
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC
	LOCAL	hBmp:DWORD
	LOCAL	nCount:DWORD
	LOCAL	rect:RECT

	;Create toolbar imagelist
	invoke ImageList_LoadImage,ha.hInstance,IDB_TBRBMP,16,29,0FF00FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
	mov		ha.hImlTbr,eax
	;Create grayed toolbar imagelist
	invoke ImageList_GetImageCount,ha.hImlTbr
	mov		nCount,eax
	shl		eax,4
	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,eax
	mov		rect.bottom,16
	invoke ImageList_Create,16,16,ILC_MASK or ILC_COLOR24,nCount,10
	mov		ha.hImlTbrGray,eax
	invoke GetDC,NULL
	mov		hDC,eax
	invoke CreateCompatibleDC,hDC
	mov		mDC,eax
	invoke CreateCompatibleBitmap,hDC,rect.right,16
	mov		hBmp,eax
	invoke ReleaseDC,NULL,hDC
	invoke SelectObject,mDC,hBmp
	push	eax
	invoke CreateSolidBrush,0FF00FFh
	push	eax
	invoke FillRect,mDC,addr rect,eax
	xor		ecx,ecx
	.while ecx<nCount
		push	ecx
		invoke ImageList_Draw,ha.hImlTbr,ecx,mDC,rect.left,0,ILD_TRANSPARENT
		pop		ecx
		add		rect.left,16
		inc		ecx
	.endw
	invoke GetPixel,mDC,0,0
	mov		ebx,eax
	xor		esi,esi
	.while esi<16
		xor		edi,edi
		.while edi<rect.right
			invoke GetPixel,mDC,edi,esi
			.if eax!=ebx
				bswap	eax
				shr		eax,8
				movzx	ecx,al			; red
				imul	ecx,ecx,66
				movzx	edx,ah			; green
				imul	edx,edx,129
				add		edx,ecx
				shr		eax,16			; blue
				imul	eax,eax,25
				add		eax,edx
				add		eax,128
				shr		eax,8
				add		eax,16
				imul	eax,eax,010101h
				and		eax,0fcfcfch
				shr		eax,2
				add		eax,0505050h
				invoke SetPixel,mDC,edi,esi,eax
			.endif
			inc		edi
		.endw
		inc		esi
	.endw
	pop		eax
	invoke DeleteObject,eax
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteDC,mDC
	invoke ImageList_AddMasked,ha.hImlTbrGray,hBmp,ebx
	invoke DeleteObject,hBmp
	ret

DoImageList endp

DoFonts proc
	LOCAL	buffer[256]:BYTE
	LOCAL	lfnt:LOGFONT

	;Tools font
	invoke RtlZeroMemory,addr lfnt,sizeof LOGFONT
	invoke GetPrivateProfileString,addr szIniFont,addr szIniTool,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemStr,addr buffer,addr szTahoma,addr lfnt.lfFaceName
	invoke GetItemInt,addr buffer,-11
	mov 	lfnt.lfHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		lfnt.lfCharSet,al
	invoke CreateFontIndirect,addr lfnt
	mov     ha.hToolFont,eax
	;Code edit fonts
	invoke RtlZeroMemory,addr lfnt,sizeof LOGFONT
	invoke GetPrivateProfileString,addr szIniFont,addr szIniCode,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemStr,addr buffer,addr szCourierNew,addr lfnt.lfFaceName
	invoke GetItemInt,addr buffer,-12
	mov 	lfnt.lfHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		lfnt.lfCharSet,al
	invoke CreateFontIndirect,addr lfnt
	mov		ha.racf.hFont,eax
	mov		lfnt.lfItalic,TRUE
	invoke CreateFontIndirect,addr lfnt
	mov		ha.racf.hIFont,eax
	invoke RtlZeroMemory,addr lfnt,sizeof LOGFONT
	invoke GetPrivateProfileString,addr szIniFont,addr szIniLine,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemStr,addr buffer,addr szTerminal,addr lfnt.lfFaceName
	invoke GetItemInt,addr buffer,-7
	mov 	lfnt.lfHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		lfnt.lfCharSet,al
	invoke CreateFontIndirect,addr lfnt
	mov		ha.racf.hLnrFont,eax
	;Text edit fonts
	invoke RtlZeroMemory,addr lfnt,sizeof LOGFONT
	invoke GetPrivateProfileString,addr szIniFont,addr szIniText,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemStr,addr buffer,addr szCourierNew,addr lfnt.lfFaceName
	invoke GetItemInt,addr buffer,-12
	mov 	lfnt.lfHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		lfnt.lfCharSet,al
	invoke CreateFontIndirect,addr lfnt
	mov		ha.ratf.hFont,eax
	mov		lfnt.lfItalic,TRUE
	invoke CreateFontIndirect,addr lfnt
	mov		ha.ratf.hIFont,eax
	invoke RtlZeroMemory,addr lfnt,sizeof LOGFONT
	invoke GetPrivateProfileString,addr szIniFont,addr szIniLine,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemStr,addr buffer,addr szTerminal,addr lfnt.lfFaceName
	invoke GetItemInt,addr buffer,-7
	mov 	lfnt.lfHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		lfnt.lfCharSet,al
	invoke CreateFontIndirect,addr lfnt
	mov		ha.ratf.hLnrFont,eax
	;Hex edit fonts
	invoke RtlZeroMemory,addr lfnt,sizeof LOGFONT
	invoke GetPrivateProfileString,addr szIniFont,addr szIniHex,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemStr,addr buffer,addr szCourierNew,addr lfnt.lfFaceName
	invoke GetItemInt,addr buffer,-12
	mov 	lfnt.lfHeight,eax
	invoke GetItemInt,addr buffer,0
	mov		lfnt.lfCharSet,al
	invoke CreateFontIndirect,addr lfnt
	mov		ha.rahf.hFont,eax
	mov		ha.rahf.hLnrFont,eax
	ret

DoFonts endp
