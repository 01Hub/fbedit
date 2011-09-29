.386
.model flat,stdcall
option casemap:none

include GrabtMap.inc

.code

SaveDIB32 proc uses ebx esi edi,hBmp:HBITMAP,hFile:HANDLE
	LOCAL	cbWrite:DWORD
	LOCAL	dibs:BITMAP
	LOCAL	pBMI:DWORD
	LOCAL	DataSize:DWORD
	LOCAL	pBFH:DWORD

	invoke GetObject,hBmp,SIZEOF BITMAP,addr dibs
	;Calculate Data size
	mov		eax,dibs.bmHeight
	shl		eax,2
	mul 	dibs.bmWidth
	mov		DataSize,eax
	;Create a memory buffer
	xor		eax,eax
	add		eax,sizeof BITMAPINFOHEADER
	add		eax,sizeof BITMAPFILEHEADER
	add		eax,DataSize
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
	mov		pBFH,eax
	add		eax,sizeof BITMAPFILEHEADER
	mov 	pBMI,eax
	;Bitmap header is address sensitive do not pass through generic routine
	mov		edi,pBMI
	mov		[edi].BITMAPINFO.bmiHeader.biXPelsPerMeter,0
	mov		[edi].BITMAPINFO.bmiHeader.biYPelsPerMeter,0
	mov		[edi].BITMAPINFO.bmiHeader.biClrUsed,0
	mov		[edi].BITMAPINFO.bmiHeader.biClrImportant,0
	mov		[edi].BITMAPINFO.bmiHeader.biSize,sizeof BITMAPINFOHEADER
	mov		eax,dibs.bmWidth
	mov		[edi].BITMAPINFO.bmiHeader.biWidth,eax
	mov		eax,dibs.bmHeight
	mov		[edi].BITMAPINFO.bmiHeader.biHeight,eax
	mov		[edi].BITMAPINFO.bmiHeader.biPlanes,1
	mov		[edi].BITMAPINFO.bmiHeader.biCompression,BI_RGB
	mov		[edi].BITMAPINFO.bmiHeader.biBitCount,32
	mov		eax,DataSize
	mov		[edi].BITMAPINFO.bmiHeader.biSizeImage,eax

	mov		esi,pBFH
	mov		[esi].BITMAPFILEHEADER.bfType,"MB"
	mov		eax,DataSize
	add		eax,sizeof BITMAPINFOHEADER + sizeof BITMAPFILEHEADER
	mov		[esi].BITMAPFILEHEADER.bfSize,eax
	mov		[esi].BITMAPFILEHEADER.bfReserved1,0
	mov		[esi].BITMAPFILEHEADER.bfReserved2,0
	mov		eax,sizeof BITMAPFILEHEADER
	add		eax,sizeof BITMAPINFOHEADER	
	mov		[esi].BITMAPFILEHEADER.bfOffBits,eax
	mov		ecx,sizeof BITMAPFILEHEADER
	add		ecx,sizeof BITMAPINFOHEADER
	push	ecx
	invoke WriteFile,hFile,pBFH,ecx,addr cbWrite,NULL
	pop		ebx
	add		ebx,pBFH
	invoke GetBitmapBits,hBmp,DataSize,ebx
	call	Flip
	invoke WriteFile,hFile,ebx,DataSize,addr cbWrite,NULL
	invoke GlobalFree,ebx
	invoke GlobalFree,pBFH
	mov		eax,hFile
	ret

Flip:
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,DataSize
	push	eax
	mov		edi,eax
	mov		esi,ebx
	add		esi,DataSize
	mov		eax,dibs.bmWidth
	shl		eax,2
	mov		ebx,eax
	mov		edx,dibs.bmHeight
	.while edx
		push	edx
		sub		esi,ebx
		push	esi
		mov		ecx,ebx
		rep		movsb
		pop		esi
		pop		edx
		dec		edx
	.endw
	pop		ebx
	retn

SaveDIB32 endp

GrabScreen proc py:DWORD,px:DWORD
	LOCAL	hdcScreen:HDC
	LOCAL	hdcCompatible:HDC
	LOCAL	hbmScreen:HBITMAP
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	rect:RECT

	invoke GetWindowRect,hWeb,addr rect
	invoke CreateDC,addr szDisplayDC,NULL,NULL,NULL
	mov		hdcScreen,eax
	invoke CreateCompatibleDC,hdcScreen
	mov		hdcCompatible,eax
	invoke CreateCompatibleBitmap,hdcScreen,PICWT,PICHT
	mov		hbmScreen,eax
	invoke SelectObject,hdcCompatible,hbmScreen
	push	eax
	mov		eax,rect.left
	add		eax,PICX
	mov		edx,rect.top
	add		edx,PICY
	invoke BitBlt,hdcCompatible,0,0,PICWT,PICHT,hdcScreen,eax,edx,SRCCOPY
	invoke wsprintf,addr buffer,addr szfilename,py,px
	invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	invoke SaveDIB32,hbmScreen,eax
	invoke CloseHandle,eax
	pop		eax
	invoke SelectObject,hdcCompatible,eax
	invoke DeleteObject,hbmScreen
	invoke DeleteDC,hdcCompatible
	invoke DeleteDC,hdcScreen
	invoke SetWindowText,hWnd,addr buffer
	ret

GrabScreen endp

SendMouse proc uses ebx esi,lpmi:DWORD,nSleep:DWORD

	mov		esi,lpmi
	xor		ebx,ebx
	.while ebx<5
		invoke SendInput,1,esi,sizeof INPUT
		invoke Sleep,250
		inc		ebx
		lea		esi,[esi+sizeof INPUT]
	.endw
	invoke Sleep,nSleep
	ret

SendMouse endp

TestRight proc uses ebx,Param:DWORD

	invoke Sleep,3000
	xor		ebx,ebx
	.while ebx<MAXX-1
		invoke SendMouse,addr mapright,2000
		inc		ebx
	.endw
	ret

TestRight endp

TestDown proc uses ebx,Param:DWORD

	invoke Sleep,3000
	xor		ebx,ebx
	.while ebx<MAXY-1
		invoke SendMouse,addr mapdown,2000
		inc		ebx
	.endw
	ret

TestDown endp

GrabMap proc uses ebx esi edi,Param:DWORD

	invoke Sleep,5000
	xor		edi,edi
	.while edi<MAXY
		xor		esi,esi
		.while esi<MAXX-1
			invoke GrabScreen,edi,esi
			invoke SendMouse,addr mapright,2000
			inc		esi
		.endw
		invoke GrabScreen,edi,esi
		invoke SendMouse,addr mapdown,2000
		inc		edi
		.while esi
			invoke GrabScreen,edi,esi
			invoke SendMouse,addr mapleft,2000
			dec		esi
		.endw
		invoke GrabScreen,edi,esi
		invoke SendMouse,addr mapdown,2000
		inc		edi
	.endw
	ret

GrabMap endp

ShowRect proc
	LOCAL	wrect:RECT
	LOCAL	hDC:HDC
	LOCAL	rect:RECT

	invoke GetWindowRect,hWeb,addr wrect
	mov		eax,wrect.left
	add		eax,PICX-1
	mov		rect.left,eax
	add		eax,512+2
	mov		rect.right,eax
	mov		eax,wrect.top
	add		eax,PICY-1
	mov		rect.top,eax
	add		eax,512+2
	mov		rect.bottom,eax
	invoke GetDC,NULL
	mov		hDC,eax
	invoke CreateSolidBrush,0
	push	eax
	invoke FrameRect,hDC,addr rect,eax
	pop		eax
	invoke DeleteObject,eax
	invoke ReleaseDC,NULL,hDC
	ret

ShowRect endp

SetupMouseMove proc
	LOCAL	rect:RECT

	invoke GetWindowRect,hWeb,addr rect

	mov		eax,rect.left
	add		eax,PICX+512
	mov		maprightmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY
	mov		maprightmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX
	mov		mapleftmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY
	mov		mapleftmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX
	mov		mapdownmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY+512
	mov		mapdownmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX
	mov		maplefttopmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY
	mov		maplefttopmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX+512
	mov		maprightbottommov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY+512
	mov		maprightbottommov.dwdy,eax

	ret

SetupMouseMove endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke GetDlgItem,hWin,IDC_MAP
		mov		hWeb,eax
		invoke lstrcpy,addr szurl,addr szUrlLand
		invoke lstrcpy,addr szfilename,addr szFileNameLand
		invoke SendMessage,hWeb,WBM_NAVIGATE,0,addr szurl
		invoke SetTimer,hWin,1000,500,NULL
	.elseif eax==WM_TIMER
		invoke ShowRect
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		and		eax,0FFFFh
		.if eax==IDM_FILE_EXIT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_FILE_LAND
			invoke lstrcpy,addr szurl,addr szUrlLand
			invoke lstrcpy,addr szfilename,addr szFileNameLand
			invoke SendMessage,hWeb,WBM_NAVIGATE,0,addr szurl
		.elseif eax==IDM_FILE_SEA
			invoke lstrcpy,addr szurl,addr szUrlSea
			invoke lstrcpy,addr szfilename,addr szFileNameSea
			invoke SendMessage,hWeb,WBM_NAVIGATE,0,addr szurl
		.elseif eax==IDM_FILE_RIGHT
			invoke CreateThread,NULL,NULL,addr TestRight,0,NORMAL_PRIORITY_CLASS,addr tid
		.elseif eax==IDM_FILE_DOWN
			invoke CreateThread,NULL,NULL,addr TestDown,0,NORMAL_PRIORITY_CLASS,addr tid
		.elseif eax==IDM_FILE_LEFTTOP
			invoke Sleep,3000
			invoke SendMouse,addr maplefttop,2000
		.elseif eax==IDM_FILE_RIGHTBOTTOM
			invoke Sleep,3000
			invoke SendMouse,addr maprightbottom,2000
		.elseif eax==IDM_FILE_START
			invoke CreateThread,NULL,NULL,addr GrabMap,0,NORMAL_PRIORITY_CLASS,addr tid
		.endif
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hWeb,0,0,rect.right,rect.bottom,TRUE
		invoke SetupMouseMove
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWMAXIMIZED
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	mov		CommandLine,eax
	invoke InitCommonControls
	invoke LoadLibrary,addr szwb
	.if eax
		mov		hLib,eax
		invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
		invoke FreeLibrary,hLib
	.endif
	invoke ExitProcess,eax

end start
