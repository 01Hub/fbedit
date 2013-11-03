
AF_BTH							equ 32
SOCK_STREAM						equ 1
BTHPROTO_RFCOMM					equ 3
RNRSERVICE_REGISTER				equ 0
RNRSERVICE_DELETE				equ 2

BTH_ADDR						equ QWORD ?

FILEREPLAYSIZE					equ 28+6*12+10+512

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

SOCKADDR_BTH struct
	addressFamily				WORD ?
	btAddr						BTH_ADDR
	serviceClassId				GUID <>
	port						DWORD ?
SOCKADDR_BTH ends

SERVERDATA struct
	wLenght						WORD ?
	wCheckSum					WORD ?
	bData						BYTE 1024 dup(?)
SERVERDATA ends

.const

wVersionRequested 				DWORD 202h
szServerAddress					BYTE '00:1B:B1:12:3E:7D',0
GUID_SPP						GUID <00001101h,0000h,1000h,<080h,000h,000h,080h,05Fh,09Bh,034h,0FBh>>
szQuit							BYTE 'Quit',0
szOK							BYTE 'OK',0

.data?

wsdata							WSADATA <>
serveraddress					SOCKADDR_BTH <>
client_socket					SOCKET ?
serversenddata					SERVERDATA <>
fdataready						DWORD ?

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

BlueToothClient proc uses ebx esi edi,Param:DWORD
 
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
				xor		esi,esi
				xor		edi,edi
				.while !fExitBluetoothThread
					invoke send,client_socket,offset szOK,3,0
					.break .if eax==INVALID_SOCKET
					; Get length of block and checksum
					xor		ebx,ebx
					.while ebx<4
						mov		eax,4
						sub		eax,ebx
						invoke recv,client_socket,addr serversenddata[ebx],eax,0
						.break .if eax==INVALID_SOCKET || eax==0
						add		ebx,eax
					.endw
					.break .if eax==INVALID_SOCKET || eax==0
					inc		esi
					xor		ebx,ebx
					.while TRUE
						movzx	eax,serversenddata.wLenght
						.break .if eax==ebx
						sub		eax,ebx
						invoke recv,client_socket,addr serversenddata.bData[ebx],eax,0
						.break .if eax==INVALID_SOCKET || eax==0
						add		ebx,eax
					.endw
					inc		esi
					.break .if eax==INVALID_SOCKET || eax==0
					invoke lstrcmp,offset serversenddata.bData,offset szQuit
					.break .if !eax
;					invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_SETSEL,-1,-1
;					invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,offset szOK
;					invoke SendDlgItemMessage,hWin,IDC_EDTLOG,EM_REPLACESEL,FALSE,offset szCRLF
					mov		fdataready,TRUE
					push	eax
					invoke Sleep,100
PrintDec esi
					pop		eax
				.endw
				.if eax!=INVALID_SOCKET
					invoke closesocket,client_socket
					invoke CloseHandle,client_socket
;					invoke SendToLog,hWin,offset szQuit,0
				.else
;					invoke GetLastError
;					invoke SendToLog,hWin,offset szError3,eax
					invoke closesocket,client_socket
					invoke CloseHandle,client_socket
				.endif
			.else
;				invoke GetLastError
;				invoke SendToLog,hWin,offset szError4,eax
				invoke closesocket,client_socket
				invoke CloseHandle,client_socket
			.endif
		.else
;			invoke GetLastError
;			invoke SendToLog,hWin,offset szError2,eax
		.endif
	.else
;		invoke GetLastError
;		invoke SendToLog,hWin,offset szError1,eax
	.endif
	invoke WSACleanup
	mov		fExitBluetoothThread,2
	xor		eax,eax
	ret
 
BlueToothClient endp
 
