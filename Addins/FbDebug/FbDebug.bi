
#Define IDM_MAKE_RUNDEBUG					10145

Dim Shared hInstance As HINSTANCE
Dim Shared hooks As ADDINHOOKS
Dim Shared lpHandles As ADDINHANDLES Ptr
Dim Shared lpFunctions As ADDINFUNCTIONS Ptr
Dim Shared lpData As ADDINDATA Ptr
Dim Shared szFileName As ZString*MAX_PATH
Dim Shared hThread As HANDLE

Const szCRLF=!"\13\10"
