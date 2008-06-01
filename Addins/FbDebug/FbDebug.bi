
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

Dim Shared hThread As HANDLE

Const szCRLF=!"\13\10"
Const szNULL=!"\0"
