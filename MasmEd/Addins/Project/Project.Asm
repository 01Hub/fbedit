;#########################################################################
;		Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;		Include file

include Project.inc
include NewProject.asm
include NewTemplate.asm

.code

UpdateMenu proc uses ebx,hMnu:HMENU
	LOCAL	mii:MENUITEMINFO

	mov		ebx,MenuIDAddin
	mov		mii.cbSize,sizeof MENUITEMINFO
	;Create sub menu
	invoke CreatePopupMenu
	mov		hSubMenu,eax
	mov		mii.fMask,MIIM_ID or MIIM_TYPE
	mov		mii.fType,MFT_STRING
	lea		eax,[ebx+1]
	mov		mii.wID,eax
	mov		mii.dwTypeData,offset szNewProject
	invoke InsertMenuItem,hSubMenu,9,TRUE,addr mii
	lea		eax,[ebx+2]
	mov		mii.wID,eax
	mov		mii.dwTypeData,offset szCreateTemplate
	invoke InsertMenuItem,hSubMenu,9,TRUE,addr mii
	lea		eax,[ebx+3]
	mov		mii.wID,eax
	mov		mii.dwTypeData,offset szOptions
	invoke InsertMenuItem,hSubMenu,9,TRUE,addr mii
	mov		mii.fMask,MIIM_SUBMENU
	mov		edx,lpHandles
	invoke GetMenuItemInfo,[edx].ADDINHANDLES.hMnu,IDM_TOOLS,FALSE,addr mii
	mov		eax,mii.hSubMenu
	mov		hMnu,eax
	mov		mii.fMask,MIIM_ID or MIIM_TYPE or MIIM_SUBMENU
	mov		mii.fType,MFT_STRING
	mov		mii.wID,ebx
	mov		eax,hSubMenu
	mov		mii.hSubMenu,eax
	mov		mii.dwTypeData,offset szMenuItem
	invoke InsertMenuItem,hMnu,99,TRUE,addr mii
	ret

UpdateMenu endp

;#########################################################################
;Common AddIn Procedures

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

OutputString proc uses ebx,lpString:DWORD

	mov		ebx,lpProc
	push	0
	call	[ebx].ADDINPROCS.lpOutputSelect
	push	TRUE
	call	[ebx].ADDINPROCS.lpOutputShow
	push	lpString
	call	[ebx].ADDINPROCS.lpOutputString
	ret

OutputString endp

; Export this proc
InstallAddin proc uses ebx,hWin:DWORD

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0;	
	mov		lpHandles,eax
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	invoke SendMessage,ebx,AIM_GETMENUID,4,0	
	mov		MenuIDAddin[0],eax
	inc		eax
	mov		MenuIDAddin[4],eax
	inc		eax
	mov		MenuIDAddin[8],eax
	inc		eax
	mov		MenuIDAddin[12],eax
	mov		ebx,lpData
	invoke lstrcpy,offset ProjectPath,addr [ebx].ADDINDATA.AppPath
	invoke lstrcat,offset ProjectPath,offset szProjectsPath
	invoke lstrcpy,offset TemplatePath,addr [ebx].ADDINDATA.AppPath
	invoke lstrcat,offset TemplatePath,offset szTemplatesPath
	invoke lstrcpy,offset szTxt,offset szDefTxt
	invoke lstrcpy,offset szBin,offset szDefBin
	mov		hook.hook1,HOOK_COMMAND or HOOK_MENUUPDATE
	xor		eax,eax
	mov		hook.hook2,eax
	mov		hook.hook3,eax
	mov		hook.hook4,eax
	mov		eax,offset hook
	ret 

InstallAddin endp

; Export this proc
AddinProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	; This proc handles messages sent from MasmEd to our addin
	; Return TRUE to prevent MasmEd and other addins from executing the command.

	mov		eax,uMsg
	.if eax==AIM_COMMAND
		mov		eax,wParam
		mov		edx,offset MenuIDAddin
		.if eax==[edx+4]
			;The 'Create New Project' menuitem we added has been selected
			invoke DialogBoxParam,hInstance,IDD_DLGNEWPROJECT,hWin,offset NewProjectDialogProc,0
			mov		eax,TRUE
			jmp		ExRet
		.elseif eax==[edx+8]
			;The 'Create Project Template' menuitem we added has been selected
			invoke DialogBoxParam,hInstance,IDD_DLGNEWTEMPLATE,hWin,offset NewTemplateDialogProc,0
			mov		eax,TRUE
			jmp		ExRet
		.elseif eax==[edx+12]
			;The 'Options' menuitem we added has been selected
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.elseif eax==AIM_MENUUPDATE
		invoke UpdateMenu,wParam
	.endif
	mov		eax,FALSE
  ExRet:
	ret

AddinProc endp

;#########################################################################

end DllEntry
