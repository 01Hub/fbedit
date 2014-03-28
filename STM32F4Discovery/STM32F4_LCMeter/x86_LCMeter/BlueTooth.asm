
AF_BTH							equ 32
SOCK_STREAM						equ 1
BTHPROTO_RFCOMM					equ 3
RNRSERVICE_REGISTER				equ 0
RNRSERVICE_DELETE				equ 2

WSAQUERYSET struct
	dwSize						DWORD ?
	lpszServiceInstanceName		DWORD ?
	lpServiceClassId			DWORD ?
	lpVersion					DWORD ?
	lpszComment					DWORD ?
	dwNameSpace					DWORD ?
	lpNSProviderId				DWORD ?
	lpszContext					DWORD ?
	dwNumberOfProtocols			DWORD ?
	lpafpProtocols				DWORD ?
	lpszQueryString				DWORD ?
	dwNumberOfCsAddrs			DWORD ?
	lpcsaBuffer					DWORD ?
	dwOutputFlags				DWORD ?
	lpBlob						DWORD ?
WSAQUERYSET ends

SOCKET_ADDRESS struct
	lpSockaddr					DWORD ?
	iSockaddrLength				DWORD ?
SOCKET_ADDRESS ends

CSADDR_INFO struct
	LocalAddr					SOCKET_ADDRESS <>
	RemoteAddr					SOCKET_ADDRESS <>
	iSocketType					DWORD ?
	iProtocol					DWORD ?
CSADDR_INFO ends

WSAPROTOCOLCHAIN struct
	ChainLen					DWORD ?
	ChainEntries				DWORD MAX_PROTOCOL_CHAIN dup(?)
WSAPROTOCOLCHAIN ends
  
WSAPROTOCOL_INFO struct
	dwServiceFlags1				DWORD ?
	dwServiceFlags2				DWORD ?
	dwServiceFlags3				DWORD ?
	dwServiceFlags4				DWORD ?
	dwProviderFlags				DWORD ?
	ProviderId					GUID <>
	dwCatalogEntryId			DWORD ?
	ProtocolChain				WSAPROTOCOLCHAIN <>
	iVersion					DWORD ?
	iAddressFamily				DWORD ?
	iMaxSockAddr				DWORD ?
	iMinSockAddr				DWORD ?
	iSocketType					DWORD ?
	iProtocol					DWORD ?
	iProtocolMaxOffset			DWORD ?
	iNetworkByteOrder			DWORD ?
	iSecurityScheme				DWORD ?
	dwMessageSize				DWORD ?
	dwProviderReserved			DWORD ?
	szProtocol					TCHAR WSAPROTOCOL_LEN+1 dup(?)
WSAPROTOCOL_INFO ends

.const

wVersionRequested 				DWORD 202h
szServerAddress					BYTE '98:D3:31:B2:0D:40',0
GUID_SPP						GUID <00001101h,0000h,1000h,<080h,000h,000h,080h,05Fh,09Bh,034h,0FBh>>

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

BlueToothConnect proc

	invoke WSAStartup,wVersionRequested, offset wsdata
	.if !eax
		invoke socket,AF_BTH,SOCK_STREAM,BTHPROTO_RFCOMM
		.if eax!=INVALID_SOCKET
			mov		client_socket,eax
			invoke RtlZeroMemory,offset serveraddress,sizeof SOCKADDR_BTH
			mov		serveraddress.addressFamily,AF_BTH
			invoke BtAddrFromString,offset serveraddress.btAddr,offset szServerAddress
			invoke RtlMoveMemory,offset serveraddress.serviceClassId,offset GUID_SPP,sizeof GUID
			invoke connect,client_socket,offset serveraddress,sizeof SOCKADDR_BTH
			.if eax!=INVALID_SOCKET
				mov		fBluetooth,TRUE
				mov		eax,TRUE
			.else
				invoke WSACleanup
				mov		eax,FALSE
			.endif
		.else
			invoke WSACleanup
			mov		eax,FALSE
		.endif
	.else
		invoke WSACleanup
		mov		eax,FALSE
	.endif
	mov		fBluetooth,eax
	ret

BlueToothConnect endp

BlueToothDisconnect proc

	.if fBluetooth
		invoke closesocket,client_socket
		invoke CloseHandle,client_socket
		invoke WSACleanup
	.endif
	ret

BlueToothDisconnect endp

; Send data to STM
BTPut proc uses ebx esi edi,lpData:DWORD,len:DWORD
	
	mov		esi,lpData
	mov		edi,len
	xor		ebx,ebx
	.while ebx<edi
		mov		eax,edi
		sub		eax,ebx
		invoke send,client_socket,addr [esi+ebx],eax,0
		.break .if eax==INVALID_SOCKET || eax==0
		add		ebx,eax
	.endw
	.if eax==INVALID_SOCKET
		mov		fBluetooth,0
		invoke SendDlgItemMessage,hWnd,IDC_IMGCONNECTED,STM_SETICON,hGrayIcon,0
	.endif
	ret

BTPut endp

; Get data from STM
BTGet proc uses ebx esi edi,lpData:DWORD,len:DWORD
	
	mov		esi,lpData
	mov		edi,len
	xor		ebx,ebx
	.while ebx<edi
		mov		eax,edi
		sub		eax,ebx
		invoke recv,client_socket,addr [esi+ebx],eax,0
		.break .if eax==INVALID_SOCKET || eax==0
		add		ebx,eax
	.endw
	.if eax==INVALID_SOCKET
		mov		fBluetooth,0
		invoke SendDlgItemMessage,hWnd,IDC_IMGCONNECTED,STM_SETICON,hGrayIcon,0
	.endif
	ret

BTGet endp
