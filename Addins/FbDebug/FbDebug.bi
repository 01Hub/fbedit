
#Define IDM_MAKE_RUN							10143
#Define IDM_MAKE_RUNDEBUG					10145
#Define MAX_MISS								10

Dim Shared hInstance As HINSTANCE
Dim Shared hooks As ADDINHOOKS
Dim Shared lpHandles As ADDINHANDLES Ptr
Dim Shared lpFunctions As ADDINFUNCTIONS Ptr
Dim Shared lpData As ADDINDATA Ptr
Dim Shared nMnuToggle As Integer
Dim Shared nMnuClear As Integer
Dim Shared szFileName As ZString*MAX_PATH
Dim Shared lpOldEditProc As Any Ptr
Dim Shared hThread As HANDLE

Const szCRLF=!"\13\10"
Const szNULL=!"\0"

Type BP
	nInx		As Integer
	sFile		As String
	sBP		As String
End Type

Dim Shared bp(31) As BP
Dim Shared nLnDebug As Integer
Dim Shared ptcur As POINT
