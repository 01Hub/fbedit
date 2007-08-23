Declare Function CreateClass(ByVal hModule As HMODULE,ByVal fGlobal As Boolean) As Integer

#Define STYLE_SIZENONE				0
#Define STYLE_SIZECENTERIMAGE		1
#Define STYLE_SIZESTRETCH			2
#Define STYLE_SIZEKEEPASPECT		3
#Define STYLE_SIZESIZECONTROL		4

#Define PVM_LOADFILE					WM_USER+1
#Define PVM_LOADRESOURCE			WM_USER+2

Const szClassName="FBEPICTVIEW"
