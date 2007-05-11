
dim SHARED hInstance as HINSTANCE
dim SHARED hooks as ADDINHOOKS
dim SHARED lpHandles as ADDINHANDLES ptr
dim SHARED lpFunctions as ADDINFUNCTIONS ptr
dim SHARED lpData as ADDINDATA ptr

type MNUITEM
	hmnu	as HMENU
	wid	as integer
	ntype	as integer
	txt	as zstring*64
	acl	as zstring*32
	img	as integer
	wdt	as integer
	hgt	as integer
end type

#define IDB_TOOLBAR				100
#define IDB_MNUARROW				101
#define IDB_MENUCHECK			102

dim SHARED hIml as HIMAGELIST
dim SHARED hGrayIml as HIMAGELIST
dim SHARED lpOldWndProc as any ptr
dim SHARED hMem as HGLOBAL
dim SHARED hMenu as HMENU
dim SHARED hMenuBrush as HBRUSH
dim SHARED hMnuFont as HFONT
dim SHARED MnuFontHt as integer
dim SHARED nCheck as Integer

#define MIM_BACKGROUND			2
#define MIM_APPLYTOSUBMENUS	&H80000000
