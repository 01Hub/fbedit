
AF_BTH							equ 32
SOCK_STREAM						equ 1
BTHPROTO_RFCOMM					equ 3
RNRSERVICE_REGISTER				equ 0
RNRSERVICE_DELETE				equ 2

BTH_ADDR						equ QWORD ?

FILEREPLAYSIZE					equ 28+6*12+10+512

;typedef struct
;{
;  vu8 Start;                                    // 0x20000000 0=Wait/Done, 1=Start, 99=In progress
;  u8 PingPulses;                                // 0x20000001 Number of ping pulses (0-255)
;  u8 PingTimer;                                 // 0x20000002 TIM1 auto reload value, ping frequency
;  u8 RangeInx;                                  // 0x20000003 Current range index
;  u16 PixelTimer;                               // 0x20000004 TIM2 auto reload value, sample rate
;  u16 GainInit[18];                             // 0x20000006 Gain setup array, first half word is initial gain
;  u16 GainArray[MAXECHO];                       // 0x2000002A Gain array
;  vu16 EchoIndex;                               // 0x2000042A Current index into EchoArray
;  vu16 GPSHead;                                 // 0x2000042E GPSArray head, index into GPSArray
;  vu16 GPSTail;                                 // 0x20000430 GPSArray tail, index into GPSArray
;  u8 GPSArray[MAXGPS];                          // 0x20000432 GPS array, received GPS NMEA 0183 messages
;}STM32_SonarTypeDef;

CLIENTSENDDATA struct
	Start						BYTE ?
	PingPulses					BYTE ?
	PingTimer					BYTE ?
	RangeInx					BYTE ?
	PixelTimer					WORD ?
	GainInit					WORD 18 dup(?)
CLIENTSENDDATA ends

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

.const

wVersionRequested 				DWORD 202h
szServerAddress					BYTE '00:18:B2:02:D2:AD',0
GUID_SPP						GUID <00001101h,0000h,1000h,<080h,000h,000h,080h,05Fh,09Bh,034h,0FBh>>

.data?

wsdata							WSADATA <>
serveraddress					SOCKADDR_BTH <>
client_socket					SOCKET ?
serversenddata					BYTE 1024 dup(?)
clientsenddata					CLIENTSENDDATA <>
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
	LOCAL	gpsbuff[1024]:BYTE
	LOCAL	GPSTail:DWORD

	mov		GPSTail,0
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
				mov		sonardata.fBluetooth,TRUE
				invoke Sleep,2000
				xor		esi,esi
				xor		edi,edi
				.while !fExitBluetoothThread
					.if mapdata.GPSReset
						mov		mapdata.GPSReset,FALSE
						mov		clientsenddata.Start,2
						; Send data to STM
						mov		esi,offset clientsenddata
						mov		edi,sizeof CLIENTSENDDATA
						call	BTPut
					.endif
					mov		clientsenddata.Start,1
					mov		clientsenddata.PingTimer,(STM32_Clock/200000/2)-1
					movzx	ebx,sonardata.RangeInx
					mov		clientsenddata.RangeInx,bl
					;Get pixel timer
					invoke RangeToTimer,ebx
					mov		clientsenddata.PixelTimer,ax
					;Get range specific data
					invoke GetRangePtr,ebx
					mov		ebx,eax
					;Ping pulses
					mov		eax,sonardata.PingInit
					.if sonardata.AutoPing
						add		eax,sonardata.sonarrange.pingadd[ebx]
					.endif
					mov		clientsenddata.PingPulses,al
					;Initial gain
					mov		eax,sonardata.GainSet
					mov		clientsenddata.GainInit[0],ax
					;Setup gain array
					xor		ecx,ecx
					xor		edi,edi
					.if sonardata.AutoGain
						;Time dependent gain
						.while ecx<17
							mov		eax,sonardata.sonarrange.gain[ebx+ecx*DWORD]
							lea		edi,[edi+1]
							mov		clientsenddata.GainInit[edi*WORD],ax
							lea		ecx,[ecx+1]
						.endw
					.else
						;Fixed gain
						xor		eax,eax
						.while ecx<17
							lea		edi,[edi+1]
							mov		clientsenddata.GainInit[edi*WORD],ax
							lea		ecx,[ecx+1]
						.endw
					.endif
					; Send data to STM
					mov		esi,offset clientsenddata
					mov		edi,sizeof CLIENTSENDDATA
					call	BTPut
					.break .if eax==INVALID_SOCKET
					; Get data from STM
					mov		esi,offset serversenddata
					mov		edi,FILEREPLAYSIZE
					call	BTGet
					.break .if eax==INVALID_SOCKET || eax==0
					mov		fdataready,TRUE
					mov		clientsenddata.Start,3
					; Send data to STM
					mov		esi,offset clientsenddata
					mov		edi,sizeof CLIENTSENDDATA
					call	BTPut
					; Get data from STM
					lea		esi,gpsbuff
					mov		edi,512+4
					call	BTGet
					.break .if eax==INVALID_SOCKET || eax==0
				  @@:
					mov		edi,offset szbuff
					mov		ecx,GPSTail
					movzx	edx,word ptr gpsbuff
					.while ecx!=edx && gpsbuff[ecx+4]!='$'
						inc		ecx
						and		ecx,511
					.endw
					.if gpsbuff[ecx+4]=='$'
						.while ecx!=edx && gpsbuff[ecx+4]!=0Dh
							mov		al,gpsbuff[ecx+4]
							mov		[edi],al
							inc		edi
							inc		ecx
							and		ecx,511
						.endw
						.if gpsbuff[ecx+4]==0Dh
							mov		byte ptr [edi],0
							mov		GPSTail,ecx
							;Update NMEA logg
							invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_GETCOUNT,0,0
							mov		ebx,eax
							.if eax>MAXNMEA
								invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_DELETESTRING,0,0
								dec		ebx
							.endif
							invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_ADDSTRING,0,offset szbuff
							invoke SendDlgItemMessage,hWnd,IDC_LSTNMEA,LB_SETTOPINDEX,ebx,0
							jmp		@b
						.endif
					.endif
				.endw
			.endif
			invoke closesocket,client_socket
			invoke CloseHandle,client_socket
		.endif
	.endif
	invoke WSACleanup
	mov		fExitBluetoothThread,2
	mov		sonardata.fBluetooth,FALSE
	xor		eax,eax
	ret

; Get data from STM
BTGet:
	xor		ebx,ebx
	.while ebx<edi
		mov		eax,edi
		sub		eax,ebx
		invoke recv,client_socket,addr [esi+ebx],eax,0
		.break .if eax==INVALID_SOCKET || eax==0
		add		ebx,eax
	.endw
	retn

; Send data to STM
BTPut:
	xor		ebx,ebx
	.while ebx<edi
		mov		eax,edi
		sub		eax,ebx
		invoke send,client_socket,addr [esi+ebx],eax,0
		.break .if eax==INVALID_SOCKET || eax==0
		add		ebx,eax
	.endw
	retn

BlueToothClient endp
 
