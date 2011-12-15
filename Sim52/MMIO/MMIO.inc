
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

;Debug
include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

include ..\Addin.inc

IDD_DLGMMIO             equ 1000
IDC_CHKMMO0             equ 1001
IDC_IMG57               equ 1100
IDC_IMG58               equ 1101
IDC_IMG59               equ 1102
IDC_IMG44               equ 1103
IDC_IMG61               equ 1104
IDC_IMG62               equ 1105
IDC_IMG63               equ 1106
IDC_IMG32               equ 1107
IDC_EDTADDRMMO0         equ 1005
IDC_CHKMMO1             equ 1002
IDC_IMG41               equ 1200
IDC_IMG42               equ 1201
IDC_IMG43               equ 1202
IDC_IMG60               equ 1203
IDC_IMG45               equ 1204
IDC_IMG46               equ 1205
IDC_IMG47               equ 1206
IDC_IMG48               equ 1207
IDC_EDTADDRMMO1         equ 1006
IDC_CHKMMO2             equ 1003
IDC_IMG25               equ 1300
IDC_IMG26               equ 1301
IDC_IMG27               equ 1302
IDC_IMG28               equ 1303
IDC_IMG29               equ 1304
IDC_IMG30               equ 1305
IDC_IMG31               equ 1306
IDC_IMG64               equ 1307
IDC_EDTADDRMMO2         equ 1007
IDC_CHKMMO3             equ 1004
IDC_IMG9                equ 1400
IDC_IMG10               equ 1401
IDC_IMG11               equ 1402
IDC_IMG12               equ 1403
IDC_IMG13               equ 1404
IDC_IMG14               equ 1405
IDC_IMG15               equ 1406
IDC_IMG16               equ 1407
IDC_EDTADDRMMO3         equ 1008
IDC_CHKMMI0             equ 1009
IDC_IMG49               equ 1110
IDC_IMG50               equ 1111
IDC_IMG51               equ 1112
IDC_IMG52               equ 1113
IDC_IMG53               equ 1114
IDC_IMG54               equ 1115
IDC_IMG55               equ 1116
IDC_IMG56               equ 1117
IDC_EDTADDRMMI0         equ 1013
IDC_CHKMMI1             equ 1010
IDC_IMG33               equ 1210
IDC_IMG34               equ 1211
IDC_IMG35               equ 1212
IDC_IMG36               equ 1213
IDC_IMG37               equ 1214
IDC_IMG38               equ 1215
IDC_IMG39               equ 1216
IDC_IMG40               equ 1217
IDC_EDTADDRMMI1         equ 1014
IDC_CHKMMI2             equ 1011
IDC_IMG17               equ 1310
IDC_IMG18               equ 1311
IDC_IMG19               equ 1312
IDC_IMG20               equ 1313
IDC_IMG21               equ 1314
IDC_IMG22               equ 1315
IDC_IMG23               equ 1316
IDC_IMG24               equ 1317
IDC_EDTADDRMMI2         equ 1015
IDC_CHKMMI3             equ 1012
IDC_IMG1                equ 1410
IDC_IMG2                equ 1411
IDC_IMG3                equ 1412
IDC_IMG4                equ 1413
IDC_IMG5                equ 1414
IDC_IMG6                equ 1415
IDC_IMG7                equ 1416
IDC_IMG8                equ 1417
IDC_EDTADDRMMI3         equ 1016
IDC_STCMMO0             equ 1017
IDC_STCMMO1             equ 1018
IDC_STCMMO2             equ 1019
IDC_STCMMO3             equ 1020
IDC_STCMMI3             equ 1021
IDC_STCMMI2             equ 1022
IDC_STCMMI1             equ 1023
IDC_STCMMI0             equ 1024
IDB_LEDGRAY             equ 100
IDB_LEDRED              equ 101

.const

szMenuMMIO				BYTE 'Memory Mapped I/O',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
lpAddin					DWORD ?
IDAddin					DWORD ?
lpOldEditProc			DWORD ?
