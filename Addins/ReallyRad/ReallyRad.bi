
dim SHARED hInstance as HINSTANCE
dim SHARED hooks as ADDINHOOKS
dim SHARED lpHandles as ADDINHANDLES ptr
dim SHARED lpFunctions as ADDINFUNCTIONS ptr
dim SHARED lpData as ADDINDATA ptr
Dim Shared szName As String
Dim Shared szProc As String
Dim Shared lpCTLDBLCLICK As CTLDBLCLICK Ptr

Const szNULL=!"\0"
Const szDefDialogProc="DialogProc"

Const szDIALOGNAME="[*DIALOGNAME*]"
Const szDIALOGPROC="[*DIALOGPROC*]"
