include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include wsock32.inc
include ws2_32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib wsock32.lib
includelib ws2_32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

IDD_DIALOG						equ	1000
IDC_EDTLOG						equ 1001
IDC_LSTDEVICES					equ 1002
IDC_BTNSERVER					equ 1003
IDC_BTNDEVICES					equ 1004
IDC_BTNCLIENT					equ 1005

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

szMainClassName					BYTE 'DLGCLASS',0
protocol						GUID <00000100h,0000h,1000h,<080h,000h,000h,080h,05Fh,09Bh,034h,0FBh>>
GUID_NULL						GUID <00000000h,0000h,0000h,<000h,000h,000h,000h,000h,000h,000h,000h>>
GUID_SPP						GUID <00001101h,0000h,1000h,<080h,000h,000h,080h,05Fh,09Bh,034h,0FBh>>

szCrLf							BYTE 0Dh,0Ah,0
szError1						BYTE 'Err#1:',0Dh,0Ah,'%d ',0
szError2						BYTE 'Err#2:',0Dh,0Ah,'%d ',0
szError3						BYTE 'Err#3:',0Dh,0Ah,'%d ',0
szError4						BYTE 'Err#4:',0Dh,0Ah,'%d ',0
szError5						BYTE 'Err#5:',0Dh,0Ah,'%d ',0
szError6						BYTE 'Err#6:',0Dh,0Ah,'%d ',0
szError7						BYTE 'Err#7:',0Dh,0Ah,'%d ',0
szError8						BYTE 'Err#8:',0Dh,0Ah,'%d ',0
szError9						BYTE 'Err#9:',0Dh,0Ah,'%d ',0
szSend							BYTE 'Bytes sendt: %d',0

szErr1							BYTE 'Err: WSAStartup',0Dh,0Ah,'%d ',0
szErr2							BYTE 'Err: WSALookupServiceBegin #1',0Dh,0Ah,'%d ',0
szErr3							BYTE 'Err: WSALookupServiceNext #1',0Dh,0Ah,'%d ',0
szErr4							BYTE 'Err: WSAAddressToString',0Dh,0Ah,'%d ',0
szErr5							BYTE 'Err: WSALookupServiceBegin #2',0Dh,0Ah,'%d ',0
szErr6							BYTE 'Err: WSALookupServiceNext #2',0Dh,0Ah,'%d ',0

szACC							BYTE 'Test Data...',0
szData							BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF'
								BYTE '0123456789ABCDEF',0Dh,0Ah,0

szQuit							BYTE 'Quit',0
szOK							BYTE 'OK',0Dh,0Ah,0
szCRLF							BYTE 0Dh,0Ah,0

szPUSH							BYTE 'Pushing data to PC',0
szDev							BYTE 'LOCAL Bluetooth device is %04x%08x \nServer channel = %d\n',0

szFileName						BYTE 'Sonar20130829_1857.snr',0
szDone							BYTE '*** Done sending file. ***',0

wVersionRequested 				DWORD 202h
;szServerAddress					BYTE '00:1E:4C:DC:EF:36',0
;szServerAddress					BYTE '00:1B:B1:12:3E:7D',0
szServerAddress					BYTE '00:18:B2:02:D2:AD',0
szServerStart					BYTE 'Server started',0
szServerConnect					BYTE 'Server connected',0
szServerStop					BYTE 'Server stopped',0

.data

bufferLength					DWORD 4096
addressSize						DWORD 1000

BT_PORT_ANY						QWORD -1
service							WSAQUERYSET <>
serviceID						GUID <>
sab2							SOCKADDR_BTH <>
ilen							DWORD 0

.data?

hInstance						HINSTANCE ?
hWnd							HWND ?
wsdata							WSADATA <>

queryset						WSAQUERYSET <>
queryset2						WSAQUERYSET <>
hLookup							HANDLE  ?
hLookup2						HANDLE ?
buffer							BYTE 4096 dup(?)
bufferLength2					DWORD ?
buffer2							BYTE 4096 dup(?)
addressAsString 				WCHAR 1000 dup(?)

hfile							HANDLE ?

; Servar
protocolInfo					WSAPROTOCOL_INFO <>
protocolInfoSize 				DWORD ?
address							SOCKADDR_BTH <>
mlength							DWORD ?
msockaddr						DWORD ?
csAddr							CSADDR_INFO <>

server_socket					SOCKET ?
server_recsendsocket			SOCKET ?
hBlueToothServer				HANDLE ?
fExitBlueToothServerThread		DWORD ?
; Client
serveraddress					SOCKADDR_BTH <>
client_socket					SOCKET ?
serversenddata					SERVERDATA <>
hBlueToothClient				HANDLE ?
fExitBlueToothClientThread		DWORD ?
