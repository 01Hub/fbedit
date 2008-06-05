
#Define IDM_MAKE_COMPILE					10142 'F5
#Define IDM_MAKE_RUN							10143 'Shift+F5
#Define IDM_MAKE_GO							10144 'Ctrl+F5
#Define IDM_MAKE_QUICKRUN					10147 'Shift+Ctrl+F5

#Define MAX_MISS								10

#Define SOURCEMAX								250

Declare Function DllFunction Cdecl Alias "DllFunction" (ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As bool

Dim Shared hInstance As HINSTANCE
Dim Shared hooks As ADDINHOOKS
Dim Shared lpHandles As ADDINHANDLES Ptr
Dim Shared lpFunctions As ADDINFUNCTIONS Ptr
Dim Shared lpData As ADDINDATA Ptr
Dim Shared nMnuToggle As Integer
Dim Shared nMnuClear As Integer
Dim Shared nMnuRun As Integer
Dim Shared nMnuRunToCursor As Integer
Dim Shared nMnuStepInto As Integer
Dim Shared nMnuStepOver As Integer
Dim Shared szFileName As ZString*MAX_PATH
Dim Shared lpOldEditProc As Any Ptr
Dim Shared hThread As HANDLE

Const szCRLF=!"\13\10"
Const szNULL=!"\0"

Type BP
	nInx		As Integer		' Project index
	sFile		As String		' Filename
	sBP		As String		' Breakpoints
End Type

Dim Shared bp(SOURCEMAX) As BP
Dim Shared nLnDebug As Integer
Dim Shared nLnRunTo As Integer
Dim Shared nDebugMode As Integer
Dim Shared nprocrnb As Integer

Dim Shared ptcur As POINT
Dim Shared hTip As HWND
Dim Shared szTipText As ZString*256
Dim Shared ebp_this As UInteger
Dim Shared fAL As Integer
Dim Shared bpinx As Integer
