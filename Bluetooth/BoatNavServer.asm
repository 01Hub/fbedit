
.586
.model flat,stdcall
option casemap:none

include BoatNavServer.inc

.code

BtAddrFromString proc uses ebx esi edi,lpBtAddr:DWORD,lpszAddress:DWORD

	invoke RtlZeroMemory,lpBtAddr,sizeof QWORD
	mov		esi,lpszAddress
	mov		edi,lpBtAddr
	mov		ebx,6
	.while ebx
		dec		ebx
		xor		edx,edx
		movzx	eax,word ptr [esi]
		call	GetNyb
		mov		al,ah
		call	GetNyb
		mov		byte ptr [edi+ebx],dl
		add		esi,3
	.endw
	ret

GetNyb:
	shl		edx,4
	.if al<='9'
		and		al,0Fh
	.elseif al>='A' && al<="F"
		sub		al,41h-10
	.elseif al>='a' && al<="f"
		and		al,5Fh
		sub		al,41h-10
	.endif
	or		edx,eax
	retn

BtAddrFromString endp

SendToLog proc uses ebx esi edi,hWin:HWND,lpMsg:DWORD,nErr:DWORD
	LOCAL buff[256]:BYTE
	LOCAL errbuff[256]:BYTE

	invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_SETSEL,-1,-1
	.if nErr
		invoke FormatMessage,FORMAT_MESSAGE_FROM_SYSTEM,NULL,nErr,0,addr errbuff,sizeof errbuff,NULL
		invoke wsprintf,addr buff,lpMsg,nErr
		invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,addr buff
		invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,addr errbuff
	.else
		invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,lpMsg
	.endif
	invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,offset szCrLf
	ret

SendToLog endp

GetBluetoothDevices proc uses ebx esi edi,hWin:HWND

	;Initialising winsock
	invoke WSAStartup,wVersionRequested,addr wsdata
	.if !eax
		;Initialising query for device
		mov		eax,sizeof WSAQUERYSET
		mov		queryset.dwSize,eax
		mov		eax,NS_BTH
		mov		queryset.dwNameSpace,eax
		invoke WSALookupServiceBegin,addr queryset,LUP_CONTAINERS,addr hLookup
		.if !eax
			.while TRUE
				mov		bufferLength,4096
				invoke RtlZeroMemory,offset buffer,4096
				mov		eax,LUP_RETURN_NAME or LUP_CONTAINERS or LUP_RETURN_ADDR or LUP_FLUSHCACHE or LUP_RETURN_TYPE or LUP_RETURN_BLOB or LUP_RES_SERVICE
				invoke WSALookupServiceNext,hLookup,eax,offset bufferLength,offset buffer
				.if !eax
					;A device found
					mov		esi,offset buffer
					invoke SendToLog,hWin,[esi].WSAQUERYSET.lpszServiceInstanceName,0
					mov		queryset2.dwSize,sizeof WSAQUERYSET
					mov		queryset2.dwNameSpace,NS_BTH
					mov		queryset2.dwNumberOfCsAddrs,0
					mov		edi,[esi].WSAQUERYSET.lpcsaBuffer
					mov		addressSize,1000
					mov 	eax,[edi].CSADDR_INFO.RemoteAddr.lpSockaddr
					invoke WSAAddressToString,[edi].CSADDR_INFO.RemoteAddr.lpSockaddr,eax,NULL,offset addressAsString,offset addressSize
					.if !eax
						invoke SendToLog,hWin,offset addressAsString,0
						mov		queryset2.dwSize,sizeof WSAQUERYSET
						mov		queryset2.lpszContext,offset addressAsString
						mov		queryset2.lpServiceClassId,offset protocol
						mov		eax,LUP_FLUSHCACHE or LUP_RETURN_NAME or LUP_RETURN_TYPE or LUP_RETURN_ADDR or LUP_RETURN_BLOB or LUP_RETURN_COMMENT
						invoke WSALookupServiceBegin,offset queryset2,eax,offset hLookup2
						.if !eax
							.while TRUE
								mov		bufferLength2,4096
								invoke RtlZeroMemory,offset buffer2,4096
								mov		eax,LUP_FLUSHCACHE or LUP_RETURN_NAME or LUP_RETURN_TYPE or LUP_RETURN_ADDR or LUP_RETURN_BLOB or LUP_RETURN_COMMENT
								invoke WSALookupServiceNext,hLookup2,eax,offset bufferLength2,offset buffer2
								.if !eax
									mov		esi,offset buffer2
									invoke SendToLog,hWin,[esi].WSAQUERYSET.lpszServiceInstanceName,0
								.else
									invoke GetLastError
									invoke SendToLog,hWin,offset szErr6,eax
									.break
								.endif
							.endw
						.else
							invoke GetLastError
							invoke SendToLog,hWin,offset szErr5,eax
							.break
						.endif
					.else
						invoke GetLastError
						invoke SendToLog,hWin,offset szErr4,eax
						.break
					.endif
				.else
					invoke GetLastError
					invoke SendToLog,hWin,offset szErr3,eax
					.break
				.endif
			.endw
		.else
			invoke GetLastError
			invoke SendToLog,hWin,offset szErr2,eax
		.endif
	.else
		invoke GetLastError
		invoke SendToLog,hWin,offset szErr1,eax
	.endif
	ret

GetBluetoothDevices endp

HexBYTE proc uses ebx edi,lpBuff:DWORD,Val:DWORD

	mov		edi,lpBuff
	mov		eax,Val
	mov		ah,al
	shr		al,4
	and		ah,0Fh
	.if al<=9
		add		al,30h
	.else
		add		al,41h-0Ah
	.endif
	.if ah<=9
		add		ah,30h
	.else
		add		ah,41h-0Ah
	.endif
	mov		[edi],ax
	ret

HexBYTE endp

SendData proc uses ebx esi edi,hWin:HWND
	LOCAL	filereplay[FILEREPLAYSIZE]:BYTE
	LOCAL	dwread:DWORD
	LOCAL	buff[356]:BYTE

	.if hfile==0
		; Open the file
		invoke CreateFile,offset szFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov		hfile,eax
		.endif
	.endif
	.if hfile
		invoke recv,server_recsendsocket,addr buff,3,0
		; Read from file
		invoke ReadFile,hfile,offset serversenddata.bData,FILEREPLAYSIZE,addr dwread,NULL
		mov		eax,dwread
PrintDec eax
		.if eax==FILEREPLAYSIZE
			; Send the data
			mov		serversenddata.wLenght,FILEREPLAYSIZE
			invoke send,server_recsendsocket,offset serversenddata,FILEREPLAYSIZE+4,0
		.else
			; Done sending the file
			invoke CloseHandle,hfile
			mov		hfile,0
			invoke SendToLog,hWin,offset szDone,0
			xor		eax,eax
		.endif
	.else
		; Error opening file
		mov		eax,SOCKET_ERROR
	.endif
	ret

SendData endp

RecieveData proc uses ebx esi edi,hWin:HWND
	LOCAL	buff[256]:BYTE

	invoke RtlZeroMemory,addr buff,sizeof buff
	invoke recv,server_recsendsocket,addr buff,sizeof buff,0
	push	eax
	.if eax!=SOCKET_ERROR && eax!=0
		invoke SendToLog,hWin,addr buff,0
	.else
		invoke GetLastError
		invoke SendToLog,hWin,offset szError9,eax
	.endif
	pop		eax
	ret

RecieveData endp

BlueToothClient proc uses ebx esi edi,hWin:HWND
 
	invoke WSAStartup,wVersionRequested, offset wsdata
	.if !eax
		invoke socket,AF_BTH,SOCK_STREAM,BTHPROTO_RFCOMM
		.if eax!=INVALID_SOCKET
			mov		client_socket,eax
			invoke RtlZeroMemory,offset serveraddress,sizeof SOCKADDR_BTH
			mov		serveraddress.addressFamily,AF_BTH
			invoke BtAddrFromString,offset serveraddress.btAddr,offset szServerAddress
			;invoke RtlMoveMemory,offset serveraddress.serviceClassId,offset GUID_SPP,sizeof GUID
			invoke RtlMoveMemory,offset serveraddress.serviceClassId,offset protocol,sizeof GUID
			invoke connect,client_socket,offset serveraddress,sizeof SOCKADDR_BTH
			.if eax!=INVALID_SOCKET
				xor		esi,esi
				xor		edi,edi
				.while !fExitBlueToothClientThread
					invoke send,client_socket,offset szOK,3,0
					.break .if eax==INVALID_SOCKET
					; Get length of block and checksum
					xor		ebx,ebx
					.while ebx<4 && !fExitBlueToothClientThread
						mov		eax,4
						sub		eax,ebx
						invoke recv,client_socket,addr serversenddata[ebx],eax,0
						.break .if eax==INVALID_SOCKET || eax==0
						add		ebx,eax
					.endw
					.break .if eax==INVALID_SOCKET || eax==0
					inc		esi
					xor		ebx,ebx
					.while !fExitBlueToothClientThread
						movzx	eax,serversenddata.wLenght
						.break .if eax==ebx
						sub		eax,ebx
						invoke recv,client_socket,addr serversenddata.bData[ebx],eax,0
						.break .if eax==INVALID_SOCKET || eax==0
						add		ebx,eax
					.endw
					inc		esi
PrintDec esi
add		edi,ebx
PrintDec edi
					.break .if eax==INVALID_SOCKET || eax==0
					invoke lstrcmp,offset serversenddata.bData,offset szQuit
					.break .if !eax
;					invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_SETSEL,-1,-1
;					invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,offset szOK
;					invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,offset szCRLF
				.endw
				.if eax!=INVALID_SOCKET
					invoke closesocket,client_socket
					invoke CloseHandle,client_socket
					invoke SendToLog,hWin,offset szQuit,0
				.else
					invoke GetLastError
					invoke SendToLog,hWin,offset szError3,eax
					invoke closesocket,client_socket
					invoke CloseHandle,client_socket
				.endif
			.else
				invoke GetLastError
				invoke SendToLog,hWin,offset szError4,eax
				invoke closesocket,client_socket
				invoke CloseHandle,client_socket
			.endif
		.else
			invoke GetLastError
			invoke SendToLog,hWin,offset szError2,eax
		.endif
	.else
		invoke GetLastError
		invoke SendToLog,hWin,offset szError1,eax
	.endif
	invoke WSACleanup
	ret
 
BlueToothClient endp
 
 
BlueToothServer proc uses ebx esi edi,hWin:HWND
	LOCAL	buff[512]:BYTE

	invoke SendToLog,hWin,offset szServerStart,0
	invoke RtlZeroMemory,offset wsdata,sizeof WSADATA
	invoke WSAStartup,wVersionRequested, offset wsdata
	.if !eax
		invoke socket,AF_BTH,SOCK_STREAM,BTHPROTO_RFCOMM
		.if eax!=INVALID_SOCKET
			mov		server_socket,eax
			invoke RtlZeroMemory,offset protocolInfo,sizeof WSAPROTOCOL_INFO
			mov		protocolInfoSize,sizeof WSAPROTOCOL_INFO
			invoke getsockopt,server_socket,SOL_SOCKET,SO_PROTOCOL_INFO,offset protocolInfo,offset protocolInfoSize
			.if !eax
				mov		msockaddr,offset address
				mov		address.addressFamily, AF_BTH
				mov		dword ptr address.btAddr[0], 0
				mov		dword ptr address.btAddr[4], 0
				invoke RtlMoveMemory,offset address.serviceClassId,offset GUID_NULL,sizeof GUID
				mov		dword ptr address.port[0],0FFFFFFFFh
				mov		dword ptr address.port[4],0FFFFFFFFh
				invoke bind,server_socket,offset address,sizeof SOCKADDR_BTH
				.if !eax
					mov		mlength,sizeof SOCKADDR_BTH
					invoke getsockname,server_socket,offset address,offset mlength
					.if !eax
						invoke listen,server_socket,10
						invoke RtlZeroMemory,offset service,sizeof WSAQUERYSET
						mov		service.dwSize,sizeof WSAQUERYSET
						mov		service.lpszServiceInstanceName,offset szACC
						mov		service.lpszComment,offset szPUSH
						invoke RtlMoveMemory,offset serviceID,offset GUID_SPP,sizeof GUID
						mov		service.lpServiceClassId,offset serviceID;
						mov		service.dwNumberOfCsAddrs,1
						mov		service.dwNameSpace,NS_BTH
						invoke RtlZeroMemory,offset csAddr,sizeof CSADDR_INFO
						mov		csAddr.LocalAddr.iSockaddrLength,sizeof SOCKADDR_BTH
						mov		csAddr.LocalAddr.lpSockaddr,offset address
						mov		csAddr.iSocketType,SOCK_STREAM
						mov		csAddr.iProtocol,BTHPROTO_RFCOMM
						mov		service.lpcsaBuffer,offset csAddr;
						invoke WSASetService,offset service,RNRSERVICE_REGISTER,0
						.if !eax
							mov		ilen,sizeof SOCKADDR_BTH
							invoke accept,server_socket,offset sab2,offset ilen
							.if eax!=INVALID_SOCKET
								mov		server_recsendsocket,eax
								invoke SendToLog,hWin,offset szServerConnect,0
								.while eax!=INVALID_SOCKET && eax!=0 && fExitBlueToothServerThread==0
									invoke SendData,hWin
								.endw
								.if eax!=INVALID_SOCKET
									invoke lstrlen,offset szQuit
									lea		ebx,[eax+1]
									invoke RtlMoveMemory,offset serversenddata.bData,offset szQuit,ebx
									mov		serversenddata.wLenght,bx
									invoke send,server_recsendsocket,offset serversenddata,addr [ebx+4],0
									invoke SendToLog,hWin,offset szQuit,0
								.endif
							.else
								invoke GetLastError
								invoke SendToLog,hWin,offset szError8,eax
							.endif
							invoke WSASetService,offset service,RNRSERVICE_DELETE,0
						.else
							invoke GetLastError
							invoke SendToLog,hWin,offset szError7,eax
						.endif
					.else
						invoke GetLastError
						invoke SendToLog,hWin,offset szError5,eax
					.endif
				.else
					invoke GetLastError
					invoke SendToLog,hWin,offset szError4,eax
				.endif
			.else
				invoke GetLastError
				invoke SendToLog,hWin,offset szError3,eax
			.endif
		.else
			invoke GetLastError
			invoke SendToLog,hWin,offset szError2,eax
		.endif
	.else
		invoke GetLastError
		invoke SendToLog,hWin,offset szError1,eax
	.endif
	.if server_recsendsocket
		invoke closesocket,server_recsendsocket
		invoke CloseHandle,server_recsendsocket
		mov		server_recsendsocket,0
	.endif
	.if server_socket
		invoke closesocket,server_socket
		invoke CloseHandle,server_socket
		mov		server_socket,0
	.endif
	.if hfile
		invoke CloseHandle,hfile
		mov		hfile,0
	.endif
	invoke WSACleanup
	invoke SendToLog,hWin,offset szServerStop,0
	invoke CloseHandle,hBlueToothServer
	mov		hBlueToothServer,0
	xor		eax,eax
	ret

BlueToothServer endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_LIMITTEXT,-1,0
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED || edx==1
			.if eax==IDC_BTNSERVER
				.if hBlueToothServer
					; Terminate BlueToothServer Thread
					mov		fExitBlueToothServerThread,TRUE
;					invoke WaitForSingleObject,hBlueToothServer,3000
;					.if eax==WAIT_TIMEOUT
;						invoke TerminateThread,hBlueToothServer,0
;					.endif
				.else
					invoke CreateThread,NULL,NULL,addr BlueToothServer,hWin,0,addr tid
					mov		hBlueToothServer,eax
				.endif
;				invoke BlueToothServer,hWin
			.elseif eax==IDC_BTNDEVICES
				invoke GetBluetoothDevices,hWin
			.elseif eax==IDC_BTNCLIENT
				.if hBlueToothClient
					; Terminate BlueToothClient Thread
					mov		fExitBlueToothClientThread,TRUE
					invoke WaitForSingleObject,hBlueToothClient,3000
					.if eax==WAIT_TIMEOUT
						invoke TerminateThread,hBlueToothClient,0
					.endif
					mov		hBlueToothClient,0
				.else
					invoke CreateThread,NULL,NULL,addr BlueToothClient,hWin,0,addr tid
					mov		hBlueToothClient,eax
				.endif
;				invoke BlueToothClient,hWin
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif eax==WM_DESTROY
		.if hBlueToothServer
			; Terminate BlueToothServer Thread
			mov		fExitBlueToothServerThread,TRUE
			invoke WaitForSingleObject,hBlueToothServer,3000
			.if eax==WAIT_TIMEOUT
				invoke TerminateThread,hBlueToothServer,0
			.endif
		.endif
		.if hBlueToothClient
			; Terminate BlueToothClient Thread
			mov		fExitBlueToothClientThread,TRUE
			invoke WaitForSingleObject,hBlueToothClient,3000
			.if eax==WAIT_TIMEOUT
				invoke TerminateThread,hBlueToothClient,0
			.endif
		.endif
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

	invoke RtlZeroMemory,addr wc,sizeof WNDCLASSEX
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szMainClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	invoke RtlZeroMemory,addr msg,sizeof MSG
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
	invoke InitCommonControls
	invoke WinMain,hInstance,NULL,0,SW_SHOWDEFAULT
	invoke ExitProcess,eax

end start
