SBLASTPANE		equ 350

.const

szProject			BYTE 'Project',0
szFile				BYTE 'File',0
szProperties		BYTE 'Properties',0
szOutput			BYTE 'Output',0

szTahoma			BYTE 'Tahoma',0

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
					TBBUTTON <26,IDM_VIEW_DIALOG,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

tbrbtnsmake			TBBUTTON <12,IDM_MAKE_ASSEMBLE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <13,IDM_MAKE_BUILD,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <14,IDM_MAKE_RUN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
					TBBUTTON <15,IDM_MAKE_GO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

.data?

OldStatusProc		DWORD ?
lfnttool			LOGFONT <?>

.code

CreateTools proc
	LOCAL	dck:DOCKING
	LOCAL	tci:TC_ITEM

	invoke CreateWindowEx,0,addr szToolClassName,NULL,WS_CHILD,0,0,0,0,ha.hWnd,0,ha.hInstance,0
	mov		ha.hTool,eax
	invoke SendMessage,ha.hTool,TLM_INIT,ha.hClient,ha.hWnd
	;Project tool
	mov		dck.ID,1
	mov		dck.Caption,offset szProject
	mov		dck.Visible,TRUE
	mov		dck.Docked,TRUE
	mov		dck.Position,TL_RIGHT
	mov		dck.IsChild,FALSE
	mov		dck.dWidth,150
	mov		dck.dHeight,200
	mov		dck.fr.left,0
	mov		dck.fr.top,0
	mov		dck.fr.right,200
	mov		dck.fr.bottom,300
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
	mov		dck.ID,2
	mov		dck.Caption,offset szProperties
	mov		dck.Visible,TRUE
	mov		dck.Docked,TRUE
	mov		dck.Position,TL_RIGHT
	mov		dck.IsChild,1
	mov		dck.dWidth,150
	mov		dck.dHeight,250
	mov		dck.fr.left,0
	mov		dck.fr.top,0
	mov		dck.fr.right,200
	mov		dck.fr.bottom,300
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolProperties,eax
	;Output tool
	mov		dck.ID,3
	mov		dck.Caption,offset szOutput
	mov		dck.Visible,TRUE
	mov		dck.Docked,TRUE
	mov		dck.Position,TL_BOTTOM
	mov		dck.IsChild,0
	mov		dck.dWidth,150
	mov		dck.dHeight,100
	mov		dck.fr.left,0
	mov		dck.fr.top,0
	mov		dck.fr.right,200
	mov		dck.fr.bottom,300
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolOutput,eax
	;Tab tool
	mov		dck.ID,4
	mov		dck.Caption,offset szNULL
	mov		dck.Visible,TRUE
	mov		dck.Docked,TRUE
	mov		dck.Position,TL_TOP
	mov		dck.IsChild,0
	mov		dck.dWidth,150
	mov		dck.dHeight,30
	mov		dck.fr.left,0
	mov		dck.fr.top,0
	mov		dck.fr.right,200
	mov		dck.fr.bottom,30
	invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
	mov		ha.hToolTab,eax
	ret

CreateTools endp

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

DoReBar proc
	LOCAL	rbbi:REBARBANDINFO

	invoke RtlZeroMemory,addr rbbi,sizeof REBARBANDINFO
	invoke CreateWindowEx,0,addr szReBarClassName,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,ha.hWnd,NULL,ha.hInstance,NULL
	mov		ha.hReBar,eax
	mov		rbbi.cbSize,sizeof REBARBANDINFO
	mov		rbbi.fMask,RBBIM_STYLE or RBBIM_CHILD or RBBIM_SIZE or RBBIM_CHILDSIZE
	mov		rbbi.fStyle,RBBS_GRIPPERALWAYS or RBBS_CHILDEDGE
	;File toolbar
	mov		rbbi.lx,123
	mov		rbbi.cyMinChild,22
	mov		rbbi.cxMinChild,123
	mov		eax,ha.hTbrFile
	mov		rbbi.hwndChild,eax
	invoke SendMessage,ha.hReBar,RB_INSERTBAND,0,addr rbbi
	;Edit1 toolbar
	mov		rbbi.lx,199
	mov		rbbi.cyMinChild,22
	mov		rbbi.cxMinChild,199
	mov		eax,ha.hTbrEdit1
	mov		rbbi.hwndChild,eax
	invoke SendMessage,ha.hReBar,RB_INSERTBAND,1,addr rbbi
	;Edit2 toolbar
	mov		rbbi.lx,193
	mov		rbbi.cyMinChild,22
	mov		rbbi.cxMinChild,193
	mov		eax,ha.hTbrEdit2
	mov		rbbi.hwndChild,eax
	invoke SendMessage,ha.hReBar,RB_INSERTBAND,2,addr rbbi
	;View toolbar
	mov		rbbi.lx,47
	mov		rbbi.cyMinChild,22
	mov		rbbi.cxMinChild,47
	mov		eax,ha.hTbrView
	mov		rbbi.hwndChild,eax
	invoke SendMessage,ha.hReBar,RB_INSERTBAND,3,addr rbbi
	;Make toolbar
	mov		rbbi.lx,101
	mov		rbbi.cyMinChild,22
	mov		rbbi.cxMinChild,101
	mov		eax,ha.hTbrMake
	mov		rbbi.hwndChild,eax
	invoke SendMessage,ha.hReBar,RB_INSERTBAND,4,addr rbbi
	;Build combobox
	mov		rbbi.lx,1024
	mov		rbbi.cyMinChild,22
	mov		rbbi.cxMinChild,123
	invoke CreateWindowEx,0,addr szComboBoxClassName,NULL,WS_CHILD or WS_VISIBLE or CBS_DROPDOWNLIST or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,ha.hWnd,NULL,ha.hInstance,NULL
	mov		ha.hCboBuild,eax
	mov		rbbi.hwndChild,eax
	invoke SendMessage,ha.hCboBuild,WM_SETFONT,ha.hToolFont,FALSE
	invoke SendMessage,ha.hReBar,RB_INSERTBAND,5,addr rbbi
;	mov		rbbi.lx,1024
;	mov		rbbi.cyMinChild,22
;	mov		rbbi.cxMinChild,0
;	invoke CreateWindowEx,0,addr szStaticClassName,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,ha.hWnd,NULL,ha.hInstance,NULL
;	mov		rbbi.hwndChild,eax
;	invoke SendMessage,ha.hReBar,RB_INSERTBAND,2,addr rbbi
	ret

DoReBar endp

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

	.if da.win.fSbr
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

	invoke strcpy,addr lfnttool.lfFaceName,addr szTahoma
	mov 	lfnttool.lfHeight,-10
	invoke CreateFontIndirect,addr lfnttool
	mov     ha.hToolFont,eax
	ret

DoFonts endp