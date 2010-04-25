
;NewProject.dlg
IDD_DLGNEWPROJECT				equ 3000
IDC_CBOASSEMBLER				equ 1002
IDC_EDTPROJECTNAME				equ 1004
IDC_EDTPROJECTDESC				equ 1005
IDC_EDTPROJECTPATH				equ 1007
IDC_BTNPROJECTPATH				equ 1009
IDC_CHKPROJECTSUB				equ 1011
IDC_CHKPROJECTBAK				equ 1012
IDC_CHKPROJECTRES				equ 1013
IDC_CHKPROJECTINC				equ 1014
IDC_CHKPROJECTMOD				equ 1015
IDC_TABNEWPROJECT				equ 1016


;NewProjectTab1.dlg
IDD_DLGNEWPROJECTTAB1			equ 3010
IDC_CHKHEADER					equ 1004
IDC_CHKCODE						equ 1005
IDC_CHKRESOURCE					equ 1006
IDC_CHKTEXT						equ 1007

;NewProjectTab2.dlg
IDD_DLGNEWPROJECTTAB2			equ 3020
IDC_LSTPROJECTBUILD				equ 1001

;NewProjectTab3.dlg
IDD_DLGNEWPROJECTTAB3			equ 3030
IDC_LSTPROJECTTEMPLATE			equ 1002

.data

szTabFiles						db 'Files',0
szTabBuild						db 'Build',0
szTabTemplate					db 'Template',0
szSelectAssembler				db 'Select Assembler',0
szNoTemplate					db '(None)',0

.data?

hTabNewProject					HWND 4 dup(?)

.code

NewProjectTab1 proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke CheckDlgButton,hWin,IDC_CHKCODE,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKPROJECTBAK,BST_CHECKED
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

NewProjectTab1 endp

NewProjectTab2 proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

NewProjectTab2 endp

NewProjectTab3 proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

NewProjectTab3 endp

NewProjectProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	tci:TC_ITEM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[128]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		;Create the tabs
		invoke GetDlgItem,hWin,IDC_TABNEWPROJECT
		mov		hTabNewProject,eax
		mov		tci.imask,TCIF_TEXT
		mov		tci.pszText,offset szTabFiles
		invoke SendMessage,hTabNewProject,TCM_INSERTITEM,0,addr tci
		mov		tci.pszText,offset szTabBuild
		invoke SendMessage,hTabNewProject,TCM_INSERTITEM,1,addr tci
		mov		tci.pszText,offset szTabTemplate
		invoke SendMessage,hTabNewProject,TCM_INSERTITEM,2,addr tci
		;Create the tab dialogs
		;Files
		invoke CreateDialogParam,ha.hInstance,IDD_DLGNEWPROJECTTAB1,hTabNewProject,addr NewProjectTab1,0
		mov		hTabNewProject[4],eax
		;Build
		invoke CreateDialogParam,ha.hInstance,IDD_DLGNEWPROJECTTAB2,hTabNewProject,addr NewProjectTab2,0
		mov		hTabNewProject[8],eax
		;Template
		invoke CreateDialogParam,ha.hInstance,IDD_DLGNEWPROJECTTAB3,hTabNewProject,addr NewProjectTab3,0
		mov		hTabNewProject[12],eax
		mov		SelTab,1
		;Add assemblers
		invoke SendDlgItemMessage,hWin,IDC_CBOASSEMBLER,CB_ADDSTRING,0,addr szSelectAssembler
		invoke strcpy,addr tmpbuff,addr da.szAssemblers
		.while tmpbuff
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer
			invoke SendDlgItemMessage,hWin,IDC_CBOASSEMBLER,CB_ADDSTRING,0,addr buffer
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBOASSEMBLER,CB_SETCURSEL,0,0
		invoke CheckDlgButton,hWin,IDC_CHKPROJECTSUB,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKPROJECTBAK,BST_CHECKED
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.elseif edx==EN_CHANGE
			.if eax==IDC_EDTPROJECTNAME
				invoke GetDlgItem,hWin,IDOK
				mov		ebx,eax
				invoke SendDlgItemMessage,hWin,IDC_EDTPROJECTNAME,WM_GETTEXTLENGTH,0,0
				invoke EnableWindow,ebx,eax
			.endif
		.elseif edx==CBN_SELCHANGE
			invoke SendDlgItemMessage,hWin,IDC_CBOASSEMBLER,CB_GETCURSEL,0,0
			.if eax
				mov		ebx,eax
				invoke EnableWindow,hTabNewProject[4],TRUE
				invoke EnableWindow,hTabNewProject[8],TRUE
				invoke EnableWindow,hTabNewProject[12],TRUE
				invoke SendDlgItemMessage,hTabNewProject[8],IDC_LSTPROJECTBUILD,LB_RESETCONTENT,0,0
				invoke SendDlgItemMessage,hTabNewProject[12],IDC_LSTPROJECTTEMPLATE,LB_RESETCONTENT,0,0
				;Get the assembler.ini
				invoke SendDlgItemMessage,hWin,IDC_CBOASSEMBLER,CB_GETLBTEXT,ebx,addr buffer
				invoke strcpy,addr tmpbuff,addr da.szAppPath
				invoke strcat,addr tmpbuff,addr szBS
				invoke strcat,addr tmpbuff,addr buffer
				invoke strcat,addr tmpbuff,addr szDotIni
				invoke strcpy,addr buffer,addr tmpbuff
				invoke GetFileAttributes,addr buffer
				.if eax!=INVALID_HANDLE_VALUE
					;Get build types
					xor		ebx,ebx
					.while ebx<32
						invoke BinToDec,ebx,addr buffer1
						invoke GetPrivateProfileString,addr szIniMake,addr buffer1,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr buffer
						.if eax
							invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer1
							invoke SendDlgItemMessage,hTabNewProject[8],IDC_LSTPROJECTBUILD,LB_ADDSTRING,0,addr buffer1
							invoke SendDlgItemMessage,hTabNewProject[8],IDC_LSTPROJECTBUILD,LB_SETITEMDATA,eax,ebx
						.endif
						inc		ebx
					.endw
					invoke SendDlgItemMessage,hTabNewProject[8],IDC_LSTPROJECTBUILD,LB_SETSEL,TRUE,0
					;Get templates
					invoke SendDlgItemMessage,hTabNewProject[12],IDC_LSTPROJECTTEMPLATE,LB_ADDSTRING,0,addr szNoTemplate
					;Find and add template files

					invoke SendDlgItemMessage,hTabNewProject[12],IDC_LSTPROJECTTEMPLATE,LB_SETCURSEL,0,0
				.endif
				invoke GetDlgItem,hWin,IDC_EDTPROJECTNAME
				invoke EnableWindow,eax,TRUE
				invoke GetDlgItem,hWin,IDC_EDTPROJECTDESC
				invoke EnableWindow,eax,TRUE
				invoke GetDlgItem,hWin,IDOK
				mov		ebx,eax
				invoke SendDlgItemMessage,hWin,IDC_EDTPROJECTNAME,WM_GETTEXTLENGTH,0,0
				invoke EnableWindow,ebx,eax
			.else
				invoke EnableWindow,hTabNewProject[4],FALSE
				invoke EnableWindow,hTabNewProject[8],FALSE
				invoke EnableWindow,hTabNewProject[12],FALSE
				invoke SendDlgItemMessage,hTabNewProject[8],IDC_LSTPROJECTBUILD,LB_RESETCONTENT,0,0
				invoke SendDlgItemMessage,hTabNewProject[12],IDC_LSTPROJECTTEMPLATE,LB_RESETCONTENT,0,0
				invoke GetDlgItem,hWin,IDC_EDTPROJECTNAME
				invoke EnableWindow,eax,FALSE
				invoke GetDlgItem,hWin,IDC_EDTPROJECTDESC
				invoke EnableWindow,eax,FALSE
				invoke GetDlgItem,hWin,IDOK
				invoke EnableWindow,eax,FALSE
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.elseif eax==WM_NOTIFY
		mov		eax,lParam
		mov		eax,[eax].NMHDR.code
		.if eax==TCN_SELCHANGE
			;Tab selection
			invoke SendMessage,hTabNewProject,TCM_GETCURSEL,0,0
			inc		eax
			.if eax!=SelTab
				push	eax
				mov		eax,SelTab
				invoke ShowWindow,[hTabNewProject+eax*4],SW_HIDE
				pop		eax
				mov		SelTab,eax
				invoke ShowWindow,[hTabNewProject+eax*4],SW_SHOWDEFAULT
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

NewProjectProc endp

AddNewProjectFile proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		;Zero out the ofn struct
	    invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	ha.hWnd
		pop		ofn.hwndOwner
		push	ha.hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset da.szALLString
		invoke strcpy,addr buffer,addr szNULL
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		mov		ofn.Flags,OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
	    mov		ofn.lpstrDefExt,offset szNULL
	    mov		ofn.lpstrTitle,offset szAddNewProjectFile
	    ;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,addr buffer
			.if !eax
				invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
				.if eax==-1
					invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
					.if eax!=INVALID_HANDLE_VALUE
						invoke CloseHandle,eax
						invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr buffer
						invoke OpenTheFile,addr buffer,0
					.endif
				.endif
			.endif
		.endif
	.endif
	ret

AddNewProjectFile endp

AddExistingProjectFiles proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	hMem:HGLOBAL
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	nOpen:DWORD

	mov		nOpen,0
	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8192
		mov		hMem,eax
		mov		esi,eax
		;Zero out the ofn struct
		invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	ha.hWnd
		pop		ofn.hwndOwner
		push	ha.hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset da.szALLString
		mov		ofn.lpstrFile,esi
		mov		ofn.nMaxFile,8192
		mov		ofn.lpstrDefExt,NULL
		mov		ofn.lpstrInitialDir,offset da.szProjectPath
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
	    mov		ofn.lpstrTitle,offset szAddExistingProjectFiles
		;Show the Open dialog
		invoke GetOpenFileName,addr ofn
		.if eax
			invoke strlen,esi
			.if byte ptr [esi+eax+1]
				;Multiselect
				mov		edi,esi
				lea		esi,[esi+eax+1]
				.while byte ptr [esi]
					invoke strcpy,addr buffer,edi
					invoke strcat,addr buffer,addr szBS
					invoke strcat,addr buffer,esi
					invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
					.if eax==-1
						invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr buffer
						invoke OpenTheFile,addr buffer,0
						invoke GetWindowLong,ha.hEdt,GWL_ID
						.if eax==ID_EDITCODE
							invoke GetWindowLong,ha.hEdt,GWL_USERDATA
							invoke ParseEdit,ha.hMdi,[eax].TABMEM.pid
						.endif
						inc		nOpen
					.endif
					invoke strlen,esi
					lea		esi,[esi+eax+1]
				.endw
			.else
				;Single file
				invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,esi
				.if !eax
					invoke UpdateAll,UAM_ISOPENACTIVATE,esi
					.if eax==-1
						invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,esi
						invoke OpenTheFile,esi,0
						invoke GetWindowLong,ha.hEdt,GWL_ID
						.if eax==ID_EDITCODE
							invoke GetWindowLong,ha.hEdt,GWL_USERDATA
							invoke ParseEdit,ha.hMdi,[eax].TABMEM.pid
						.endif
						mov		nOpen,1
					.endif
				.endif
			.endif
		.endif
		invoke GlobalFree,hMem
	.endif
	mov		eax,nOpen
	ret

AddExistingProjectFiles endp

AddOpenProjectFile proc uses ebx

	invoke GetWindowLong,ha.hEdt,GWL_USERDATA
	mov		ebx,eax
	invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,addr [ebx].TABMEM.filename
	.if !eax
		invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr [ebx].TABMEM.filename
		mov		eax,[eax].PBITEM.id
		mov		[ebx].TABMEM.pid,eax
		invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
		.if eax==ID_EDITCODE
			invoke ParseEdit,[ebx].TABMEM.hwnd,[ebx].TABMEM.pid
		.endif
	.endif
	ret

AddOpenProjectFile endp

AddAllOpenProjectFiles proc uses ebx edi
	LOCAL	tci:TC_ITEM

	xor		edi,edi
	mov		tci.imask,TCIF_PARAM
	.while TRUE
		invoke SendMessage,ha.hTab,TCM_GETITEM,edi,addr tci
		.break .if !eax
		mov		ebx,tci.lParam
		invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,addr [ebx].TABMEM.filename
		.if !eax
			invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr [ebx].TABMEM.filename
			mov		eax,[eax].PBITEM.id
			mov		[ebx].TABMEM.pid,eax
			invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
			.if eax==ID_EDITCODE
				invoke ParseEdit,[ebx].TABMEM.hwnd,[ebx].TABMEM.pid
			.endif
		.endif
		inc		edi
	.endw
	ret

AddAllOpenProjectFiles endp

OpenProjectItemFile proc uses ebx

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		mov		ebx,eax
		invoke UpdateAll,UAM_ISOPENACTIVATE,addr [ebx].PBITEM.szitem
		.if eax==-1
			invoke OpenTheFile,addr [ebx].PBITEM.szitem,0
		.endif
	.endif
	ret

OpenProjectItemFile endp

OpenProjectItemGroup proc uses ebx esi edi

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		mov		edi,[eax].PBITEM.id
		xor		esi,esi
		.while TRUE
			invoke SendMessage,ha.hProjectBrowser,RPBM_GETITEM,esi,0
			.break .if !eax
			.if sdword ptr [eax].PBITEM.id>0 && edi==[eax].PBITEM.idparent
				mov		ebx,eax
				invoke UpdateAll,UAM_ISOPENACTIVATE,addr [ebx].PBITEM.szitem
				.if eax==-1
					invoke OpenTheFile,addr [ebx].PBITEM.szitem,0
				.endif
			.endif
			inc		esi
		.endw
	.endif
	ret

OpenProjectItemGroup endp

RemoveProjectFile proc uses ebx

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		mov		ebx,eax
		invoke UpdateAll,UAM_ISOPEN,addr [ebx].PBITEM.szitem
		.if eax!=-1
			invoke GetWindowLong,eax,GWL_USERDATA
			invoke GetWindowLong,eax,GWL_USERDATA
			mov		[eax].TABMEM.pid,0
		.endif
		invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,[ebx].PBITEM.id,0
		invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_DELETEITEM,0,0
	.endif
	ret

RemoveProjectFile endp

GetProjectFiles proc uses ebx esi edi
	LOCAL	fi:FILEINFO
	LOCAL	pbi:PBITEM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	nMiss:DWORD

	;File browser path
	invoke GetPrivateProfileString,addr szIniProject,addr szIniPath,addr da.szAppPath,addr da.szFBPath,sizeof da.szFBPath,addr da.szProject
	;Check if path exist
	invoke GetFileAttributes,addr da.szFBPath
	.if eax==INVALID_HANDLE_VALUE
		invoke strcpy,addr da.szFBPath,addr da.szProjectPath
	.endif
	invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr da.szFBPath
	;Get groups
	invoke GetPrivateProfileString,addr szIniProject,addr szIniGroup,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szProject
	.if eax
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,FALSE,RPBG_GROUPS
		invoke RtlZeroMemory,addr pbi,sizeof PBITEM
		invoke GetItemInt,addr tmpbuff,0
		.if sdword ptr eax>0
			invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,FALSE,eax
		.endif
		xor		ebx,ebx
		.while tmpbuff
			invoke GetItemInt,addr tmpbuff,0
			mov		pbi.id,eax
			invoke GetItemInt,addr tmpbuff,0
			mov		pbi.idparent,eax
			invoke GetItemInt,addr tmpbuff,0
			mov		pbi.expanded,eax
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr pbi.szitem
			invoke SendMessage,ha.hProjectBrowser,RPBM_SETITEM,ebx,addr pbi
			inc		ebx
		.endw
		;Get files
		mov		nMiss,0
		mov		esi,START_FILES
		.while esi<MAX_FILES
			invoke GetFileInfo,esi,addr szIniProject,addr da.szProject,addr fi
			.if eax
				invoke RtlZeroMemory,addr pbi,sizeof PBITEM
				mov		pbi.id,esi
				mov		eax,fi.idparent
				mov		pbi.idparent,eax
				mov		eax,fi.flag
				mov		pbi.flag,eax
				invoke strcpy,addr pbi.szitem,addr fi.filename
				mov		eax,fi.ID
				mov		pbi.lParam,eax
				invoke GetFileAttributes,addr pbi.szitem
				.if eax!=INVALID_HANDLE_VALUE
					invoke SendMessage,ha.hProjectBrowser,RPBM_SETITEM,ebx,addr pbi
					.if pbi.flag==FLAG_MAIN
						;Main file
						invoke RemovePath,addr pbi.szitem,addr da.szProjectPath,addr buffer
						.if pbi.lParam==ID_EDITCODE
							invoke strcpy,addr da.szMainAsm,addr buffer
						.elseif pbi.lParam==ID_EDITRES
							invoke strcpy,addr da.szMainRC,addr buffer
						.endif
					.endif
					inc		ebx
				.endif
				mov		nMiss,0
			.else
				inc		nMiss
				.break .if nMiss>MAX_MISS
			.endif
			inc		esi
		.endw
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,TRUE,RPBG_GROUPS
		invoke SetProjectTab,1
		;Get open files
		invoke GetPrivateProfileString,addr szIniProject,addr szIniOpen,addr szNULL,addr buffer,sizeof buffer,addr da.szProject
		.if eax
			push	da.win.fcldmax
			mov		da.win.fcldmax,FALSE
			;Selected tab
			invoke GetItemInt,addr buffer,0
			push	eax
			.while buffer
				invoke GetItemInt,addr buffer,0
				.if eax
					invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,eax,0
					.if eax
						invoke OpenTheFile,addr [eax].PBITEM.szitem,[eax].PBITEM.lParam
					.endif
				.endif
			.endw
			pop		eax
			pop		da.win.fcldmax
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			.if eax==-1
				invoke SendMessage,ha.hTab,TCM_SETCURSEL,0,0
			.endif
			.if eax!=-1
				invoke TabToolActivate
				.if da.win.fcldmax
					invoke SendMessage,ha.hClient,WM_MDIMAXIMIZE,ha.hMdi,0
				.endif
			.endif
			;Get make command lines
			xor		ebx,ebx
			mov		edi,offset da.make
			invoke RtlZeroMemory,edi,sizeof da.make
			invoke SendMessage,ha.hCboBuild,CB_RESETCONTENT,0,0
			.while ebx<32
				invoke BinToDec,ebx,addr buffer
				invoke GetPrivateProfileString,addr szIniMake,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szProject
				.if eax
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szType
					invoke GetItemQuotedStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szCompileRC
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szOutCompileRC
					invoke GetItemQuotedStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szAssemble
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szOutAssemble
					invoke GetItemQuotedStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szLink
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szOutLink
					invoke GetItemQuotedStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szLib
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].MAKE.szOutLib
					invoke SendMessage,ha.hCboBuild,CB_ADDSTRING,0,addr [edi].MAKE.szType
					lea		edi,[edi+sizeof MAKE]
				.endif
				inc		ebx
			.endw
			invoke SendMessage,ha.hCboBuild,CB_SETCURSEL,0,0
		.endif
	.endif
	ret

GetProjectFiles endp

SaveProjectItem proc nInx:DWORD
	LOCAL	fi:FILEINFO
	LOCAL	buffer[8]:BYTE

	invoke SetFileInfo,nInx,addr fi
	.if eax
		mov		tmpbuff,0
		invoke PutItemInt,addr tmpbuff,fi.idparent
		invoke PutItemInt,addr tmpbuff,fi.flag
		invoke PutItemInt,addr tmpbuff,fi.ID
		invoke PutItemInt,addr tmpbuff,fi.rect.left
		invoke PutItemInt,addr tmpbuff,fi.rect.top
		invoke PutItemInt,addr tmpbuff,fi.rect.right
		invoke PutItemInt,addr tmpbuff,fi.rect.bottom
		invoke PutItemInt,addr tmpbuff,fi.nline
		invoke PutItemStr,addr tmpbuff,addr fi.filename
		mov		buffer,'F'
		invoke BinToDec,fi.pid,addr buffer[1]
		invoke WritePrivateProfileString,addr szIniProject,addr buffer,addr tmpbuff[1],addr da.szProject
	.endif
	ret

SaveProjectItem endp

PutProject proc uses ebx esi edi
	LOCAL	tci:TC_ITEM
	LOCAL	buffer[8]:BYTE
	LOCAL	nMiss:DWORD

	mov		dword ptr buffer,0
	invoke WritePrivateProfileSection,addr szIniSession,addr buffer,addr da.szRadASMIni
	;Project
	invoke WritePrivateProfileString,addr szIniSession,addr szIniProject,addr da.szProject,addr da.szRadASMIni
	;File browser path
	invoke WritePrivateProfileString,addr szIniProject,addr szIniPath,addr da.szFBPath,addr da.szProject
	;Project groups
	mov		tmpbuff,0
	;Refresh expanded flags
	invoke SendMessage,ha.hProjectBrowser,RPBM_GETEXPAND,0,0
	;Get selected grouping
	invoke SendMessage,ha.hProjectBrowser,RPBM_GETGROUPING,0,0
	invoke PutItemInt,addr tmpbuff,eax
	;Get groups
	xor		ebx,ebx
	.while TRUE
		invoke SendMessage,ha.hProjectBrowser,RPBM_GETITEM,ebx,0
		.break .if !eax
		mov		esi,eax
		.break .if ![esi].PBITEM.id
		.if sdword ptr [esi].PBITEM.id<0
			invoke PutItemInt,addr tmpbuff,[esi].PBITEM.id
			invoke PutItemInt,addr tmpbuff,[esi].PBITEM.idparent
			invoke PutItemInt,addr tmpbuff,[esi].PBITEM.expanded
			invoke PutItemStr,addr tmpbuff,addr [esi].PBITEM.szitem
		.endif
		inc		ebx
	.endw
	invoke WritePrivateProfileString,addr szIniProject,addr szIniGroup,addr tmpbuff[1],addr da.szProject
	;Remove files not longer in project
	mov		ebx,START_FILES
	mov		nMiss,0
	.while ebx<MAX_FILES
		mov		buffer,'F'
		invoke BinToDec,ebx,addr buffer[1]
		invoke GetPrivateProfileString,addr szIniProject,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szProject
		.if eax
			invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,ebx,0
			.if !eax
				;Remove it from project file
				invoke WritePrivateProfileString,addr szIniProject,addr buffer,addr szNULL,addr da.szProject
			.endif
			mov		nMiss,0
		.else
			inc		nMiss
			.break .if nMiss>MAX_MISS
		.endif
		inc		ebx
	.endw
	;Get open project files
	mov		dword ptr tmpbuff,0
	.if ha.hMdi
		invoke ShowWindow,ha.hClient,SW_HIDE
		mov		eax,da.win.fcldmax
		push	eax
		.if eax
			invoke SendMessage,ha.hClient,WM_MDIRESTORE,ha.hMdi,0
		.endif
		invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
		invoke PutItemInt,addr tmpbuff,eax
		xor		ebx,ebx
		.while TRUE
			mov		tci.imask,TCIF_PARAM
			invoke SendMessage,ha.hTab,TCM_GETITEM,ebx,addr tci
			.break .if !eax
			mov		esi,tci.lParam
			mov		eax,[esi].TABMEM.pid
			.if eax
				invoke PutItemInt,addr tmpbuff,eax
			.endif
			inc		ebx
		.endw
		pop		da.win.fcldmax
		invoke ShowWindow,ha.hClient,SW_SHOWNA
	.endif
	invoke WritePrivateProfileString,addr szIniProject,addr szIniOpen,addr tmpbuff[1],addr da.szProject
	ret

PutProject endp

CloseProject proc

	invoke UpdateAll,UAM_SAVEALL,TRUE
	.if eax
		.if da.fProject
			invoke PutProject
		.endif
		invoke UpdateAll,UAM_CLOSEALL,0
		invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,0,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETITEM,0,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,TRUE,RPBG_NOCHANGE
		invoke SetProjectTab,0
		invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
		mov		da.fProject,0
		mov		da.szProject,0
		mov		da.szProjectPath,0
		invoke OpenAssembler
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

CloseProject endp

SetMain proc uses ebx edi,pid:DWORD,ID:DWORD

	;Remove old main
	xor		ebx,ebx
	.while TRUE
		invoke SendMessage,ha.hProjectBrowser,RPBM_FINDNEXTITEM,ebx,0
		.break .if !eax
		mov		ebx,[eax].PBITEM.id
		.if [eax].PBITEM.flag==FLAG_MAIN
			mov		edi,eax
			invoke GetTheFileType,addr [edi].PBITEM.szitem
			.if eax==ID
				;Update the item
				mov		[edi].PBITEM.flag,FLAG_NORMAL
				invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEMINDEX,ebx,0
				invoke SendMessage,ha.hProjectBrowser,RPBM_SETITEM,eax,edi
				.break
			.endif
		.endif
	.endw
	;Set new main
	invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,pid,0
	.if eax
		mov		edi,eax
		mov		[edi].PBITEM.flag,FLAG_MAIN
		invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEMINDEX,pid,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETITEM,eax,edi
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,TRUE,RPBG_NOCHANGE
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

SetMain endp

ToggleModule proc uses edi,pid:DWORD

	invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,pid,0
	.if eax
		mov		edi,eax
		.if [edi].PBITEM.flag==FLAG_NORMAL
			mov		[edi].PBITEM.flag,FLAG_MODULE
		.elseif [edi].PBITEM.flag==FLAG_MAIN
			mov		[edi].PBITEM.flag,FLAG_MODULE
			mov		da.szMainAsm,0
		.else
			mov		[edi].PBITEM.flag,FLAG_NORMAL
		.endif
		invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEMINDEX,pid,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETITEM,eax,edi
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,TRUE,RPBG_NOCHANGE
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

ToggleModule endp
