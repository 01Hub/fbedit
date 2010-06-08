
;#########################################################################
;Include files

include windows.inc
include kernel32.inc
include user32.inc
include Gdi32.inc

;#########################################################################
;Libraries

includelib kernel32.lib
includelib user32.lib
includelib Gdi32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

;#########################################################################
;RadASM AddIn Include

include ..\Addins.inc

.const

szCoInvoke		db 'CoInvoke',0

szSomeText		db 'aaitemA',0,'paramA0,paramA1,paramA2',0
				db 'aaitemB',0,'paramB0,paramB1,paramB2,paramB3',0
				db 'abitemC',0,'paramC0,paramC1,paramC2',0
				db 'abitemD',0,'paramD0,paramD1,paramD2,paramD3',0,0

szCR			db VK_RETURN,0

RABRUSH struct
	hBrBck		dd ?						;Back color brush
	hBrSelBck	dd ?						;Sel back color brush
	hBrHilite1	dd ?						;Line hilite 1
	hBrHilite2	dd ?						;Line hilite 2
	hBrHilite3	dd ?						;Line hilite 3
	hBrSelBar	dd ?						;Selection bar
	hPenSelbar	dd ?						;Selection bar pen
RABRUSH ends

RAFONTINFO struct
	charset		dd ?						;Character set
	fDBCS		dd ?						;Use double byte characters
	fntwt		dd ?						;Font width
	fntht		dd ?						;Font height
	spcwt		dd ?						;Space width
	tabwt		dd ?						;Tab width
	italic		dd ?						;Height shift
	monospace	dd ?						;Font is monospaced
	linespace	dd ?						;Extra line spacing
RAFONTINFO ends

RAEDT struct
	hwnd		dd ?						;Handle of edit a or b
	hvscroll	dd ?						;Handle of scroll bar
	cpxmax		dd ?						;Last cursor pos x
	cpy			dd ?						;Scroll position
	cp			dd ?						;Character position
	rc			RECT <?>					;Edit a or b rect
	topyp		dd ?						;First visible lines Y position
	topln		dd ?						;First visible lines linenumber
	topcp		dd ?						;First visible lines character position
RAEDT ends

EDIT struct
	hwnd		dd ?						;Handle of main window
	fstyle		dd ?						;Window style
	ID			dd ?						;Window ID
	hpar		dd ?						;Handle of parent window
	edta		RAEDT <>
	edtb		RAEDT <>
	hhscroll	dd ?						;Handle of horizontal scrollbar
	hgrip		dd ?						;Handle of sizegrip
	hnogrip		dd ?						;Handle of nosizegrip
	hsbtn		dd ?						;Handle of splitt button
	hlin		dd ?						;Handle of linenumber button
	hexp		dd ?						;Handle of expand button
	hcol		dd ?						;Handle of collapse button
	hsta		dd ?						;Handle of state window
	htt			dd ?						;Handle of tooltip
	fresize		dd ?						;Resize in action flag
	fsplitt		dd ?						;Splitt factor
	nsplitt		dd ?						;Splitt height

	hHeap		dd 3 dup(?)					;Handle of heap
	hLine		dd ?						;Handle of line pointer mem
	cbLine		dd ?						;Size of line pointer mem
	rpLine		dd ?						;Relative pointer into line pointer mem
	rpLineFree	dd ?						;Pointer to free line pointer
	hChars		dd ?						;Handle of character mem
	cbChars		dd ?						;Size of character mem
	rpChars		dd ?						;Relative pointer into character mem
	rpCharsFree	dd ?						;Relative pointer to free character
	hUndo		dd ?						;Handle of undo memory
	cbUndo		dd ?						;Size of undo memory
	rpUndo		dd ?						;Relative pointer to free (last)
	line		dd ?						;Linenumber
	cpLine		dd ?						;Character position for start of line

	rc			RECT <?>					;Main rect
	selbarwt	dd ?						;Width of selection bar
	nlinenrwt	dd ?						;Initial width of linenumber bar
	linenrwt	dd ?						;Width of linenumber bar
	nScroll		dd ?						;Mouse wheel scroll lines
	nPageBreak	dd ?						;Page break
	cpMin		dd ?						;Selection min
	cpMax		dd ?						;Selection max
	fOvr		dd ?						;Insert / Overwrite
	nHidden		dd ?						;Number of hidden lines
	cpx			dd ?						;Scroll position
	focus		dd ?						;Handle of edit having focus
	fCaretHide	dd ?						;Caret is hidden
	fChanged	dd ?						;Content changed
	fHideSel	dd ?						;Hide selection
	fIndent		dd ?						;Auto indent
	clr			RACOLOR <?>
	br			RABRUSH <?>
	nTab		dd ?						;Tab size
	fnt			RAFONT <?>
	fntinfo		RAFONTINFO <?>
	lpBmCB		dd ?						;Bookmark paint callback
	nchange		dd ?						;Used by EN_SELCHANGE
	nlastchange	dd ?						;Used by EN_SELCHANGE
	nWordGroup	dd ?						;Hilite word group
	fExpandTab	dd ?						;TRUE/FALSE Epand tabs to spaces
	savesel		CHARRANGE <?>
	htlt		dd ?						;Scroll tooltip
	nMode		dd ?						;Block selection
	blrg		BLOCKRANGE <?>
	lockundoid	dd ?
	ccmntblocks	dd ?
EDIT ends

.data


.data?

hInstance			dd ?					;Dll's module handle
lpHandles			dd ?					;Pointer to handles struct
lpProc				dd ?					;Pointer to proc struct
lpData				dd ?					;Pointer to data struct

hCC					dd ?					;Handle of codecomplete listbox
hTT					dd ?					;Hancle of codecomplete tooltip
hProperty			dd ?					;Handle of properties tool

nPos				dd ?
linebuff			db 16384 dup(?)
hook				HOOK <>

.code

;#########################################################################
;Output Window procs

TextOutput proc lpszStr

   pushad
   push  lpszStr
   mov   eax,lpProc
   call  [eax].ADDINPROCS.lpTextOutput
   push  offset szCR
   mov   eax,lpProc
   call  [eax].ADDINPROCS.lpTextOutput
   popad
   ret

TextOutput endp
