#define IDD_DLGLNG              30000
#define IDC_EDTLNGFILE          30001
#define IDC_BTNFILE             30002
#define IDC_BTNLNGSAVE          30003
#define IDC_BTNLNGNEW           30004
#define IDC_EDTLNGLANG          30005
#Define IDC_LSTLNGDIALOG        30006

#Define IDD_DLGMENU				30100

Dim Shared hInstance As HINSTANCE
Dim Shared hEdt As HWND
Const szDivider As String=!";--------------------------------------------------------------------------\13\10"
Const szAppName As String="Language translator"
' Custom controls used by FbEdit
Dim hRichEditDll As HMODULE
Dim hRAEditDll As HMODULE
Dim hRAResEdDll As HMODULE
Dim hRAGridDll As HMODULE
Dim hRAFileDll As HMODULE
Dim hRAPropertyDll As HMODULE
Dim hRACodeCompleteDll As HMODULE
Const szFbEditLNGIni As String="FbEditLNG.ini"
Dim Shared szAppPath As ZString*260
Const szNULL=!"\0"
Const LNGFilterString="Language Projects (*.lng)" & szNULL & "*.lng" & szNULL & szNULL
Dim Shared szFileName As ZString*260
Const szNew As String=!"[Lang]\13\10Lang=English (default)\13\10"
Const szList As String=!"[10000] Main menu\0" _
							  !"[20000] Context menu\0" _
							  !"\0"