.const

szProject			db 'Project',0

.data?

hTL1				HWND ?

.code

CreateTools proc
	LOCAL	dck:DOCKING

		invoke CreateWindowEx,0,addr szToolClassName,NULL,WS_CHILD,0,0,0,0,ha.hWnd,0,ha.hInstance,0
		mov		ha.hTool,eax
		invoke SendMessage,ha.hTool,TLM_INIT,ha.hClient,ha.hWnd
		mov		dck.ID,1
		mov		dck.Caption,offset szProject
		mov		dck.Visible,TRUE
		mov		dck.Docked,TRUE
		mov		dck.Position,TL_RIGHT
		mov		dck.IsChild,FALSE
		mov		dck.dWidth,150
		mov		dck.dHeight,100
		mov		dck.fr.left,0
		mov		dck.fr.top,0
		mov		dck.fr.right,200
		mov		dck.fr.bottom,300
		invoke SendMessage,ha.hTool,TLM_CREATE,0,addr dck
		mov		hTL1,eax
	ret

CreateTools endp