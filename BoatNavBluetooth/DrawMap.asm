
.code

Load_Image proc lpFileName:DWORD
	LOCAL	hBmp:DWORD
	LOCAL	image:DWORD
	LOCAL	wbuffer[MAX_PATH]:WORD

	;Load the jpeg and convert it to a bitmap handle
	xor		eax,eax
	mov		hBmp,eax
	mov		image,eax
	invoke RtlZeroMemory,addr wbuffer,sizeof wbuffer
	invoke MultiByteToWideChar,CP_OEMCP,MB_PRECOMPOSED,lpFileName,-1,addr wbuffer,MAX_PATH
	mov		wbuffer[eax*2],0
	invoke GdipLoadImageFromFile,addr wbuffer,addr image
	.if !eax
		;Convert to bitmap handle
		invoke GdipCreateHBITMAPFromBitmap,image,addr hBmp,0
		invoke GdipDisposeImage,image
	.endif
	mov		eax,hBmp
	ret

Load_Image endp

LoadDib proc uses ebx esi edi,mapinx:DWORD,dibx:DWORD,diby:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	;Check if out of bounds
	mov		eax,dibx
	mov		edx,diby
	.if eax>mapdata.nx || edx>mapdata.ny
		mov		dibx,0FFh
		mov		diby,0FFh
	.endif
	;Check if tile is loaded
	xor		ebx,ebx
	mov		esi,offset mapdata.bmpcache
	mov		edi,mapinx
	mov		ecx,dibx
	mov		edx,diby
	xor		eax,eax
	.while ebx<MAXBMP
		.if edi==[esi].MAPBMP.mapinx && ecx==[esi].MAPBMP.nx && edx==[esi].MAPBMP.ny && [esi].MAPBMP.hBmp
			;The tile is loaded
			mov		eax,[esi].MAPBMP.hBmp
			.break
		.endif
		lea		esi,[esi+sizeof MAPBMP]
		inc		ebx
	.endw
	.if !eax
		;The tile is not loaded
		invoke wsprintf,addr buffer,addr szFileName,addr szAppPath,mapinx,diby,dibx
		invoke GetFileAttributes,addr buffer
		.if eax==INVALID_HANDLE_VALUE
			invoke wsprintf,addr buffer,addr szFileName,addr szAppPath,mapinx,0FFh,0FFh
		.endif
		invoke Load_Image,addr buffer
		.if eax
			push	eax
			;Find free or unused tile
			xor		ebx,ebx
			xor		edi,edi
			mov		esi,offset mapdata.bmpcache
			.while ebx<MAXBMP-1
				.if ![esi].MAPBMP.inuse
					mov		edi,esi
					.break .if ![esi].MAPBMP.hBmp
				.endif
				lea		esi,[esi+sizeof MAPBMP]
				inc		ebx
			.endw
			.if edi
				;Found free or unused tile
				mov		esi,edi
			.endif
			.if [esi].MAPBMP.hBmp
				;The tile has a bitmap, delete it
				invoke DeleteObject,[esi].MAPBMP.hBmp
			.endif
			;Update the tile
			mov		eax,mapinx
			mov		[esi].MAPBMP.mapinx,eax
			mov		eax,dibx
			mov		[esi].MAPBMP.nx,eax
			mov		eax,diby
			mov		[esi].MAPBMP.ny,eax
			mov		[esi].MAPBMP.inuse,TRUE
			pop		eax
			mov		[esi].MAPBMP.hBmp,eax
		.endif
	.endif
	ret

LoadDib endp

SetMapUsed proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	stx:DWORD
	LOCAL	enx:DWORD
	LOCAL	sty:DWORD
	LOCAL	eny:DWORD

	;Find and mark tiles that is still needed
	mov		eax,topx
	shr		eax,9
	mov		stx,eax
	mov		eax,mapdata.mapwt
	imul	zoomval
	idiv	dd256
	add		eax,topx
	shr		eax,9
	mov		enx,eax	
	mov		eax,topy
	shr		eax,9
	mov		sty,eax
	mov		eax,mapdata.mapht
	imul	zoomval
	idiv	dd256
	add		eax,topy
	shr		eax,9
	mov		eny,eax
	xor		ebx,ebx
	mov		esi,offset mapdata.bmpcache
	.while ebx<MAXBMP
		mov		[esi].MAPBMP.inuse,0
		.if [esi].MAPBMP.hBmp
			mov		eax,[esi].MAPBMP.mapinx
			mov		ecx,[esi].MAPBMP.nx
			mov		edx,[esi].MAPBMP.ny
			.if eax==mapdata.mapinx && ecx>=stx && ecx<=enx && edx>=sty && edx<=eny
				;The tile is needed
				mov		[esi].MAPBMP.inuse,TRUE
			.endif
		.endif
		lea		esi,[esi+sizeof MAPBMP]
		inc		ebx
	.endw
	ret

SetMapUsed endp

ShowMap proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	dibx:DWORD
	LOCAL	ofsx:DWORD
	LOCAL	diby:DWORD
	LOCAL	mapx:DWORD
	LOCAL	mapy:DWORD

	invoke SetMapUsed,topx,topy,zoomval
	;Find leftmost dibx and ofsx
	mov		eax,topx
	shr		eax,9
	mov		dibx,eax
	mov		eax,topx
	and		eax,511
	mov		ofsx,eax
	mov		mapx,0
	;Find topmost diby
	mov		eax,topy
	shr		eax,9
	mov		diby,eax
	mov		eax,topy
	and		eax,511
	imul	dd256
	idiv	zoomval
	neg		eax
	mov		mapy,eax
	call	DrawY
	ret

DrawY:
	.while TRUE
		call	DrawX
		mov		eax,512
		imul	dd256
		idiv	zoomval
		add		mapy,eax
		mov		eax,mapy
		.break .if sdword ptr eax>=mapdata.mapht
		inc		diby
		mov		eax,diby
	.endw
	retn

DrawX:
	push	dibx
	push	mapx
	push	ofsx
	.while TRUE
		mov		esi,512
		sub		esi,ofsx
		mov		eax,esi
		imul	dd256
		idiv	zoomval
		mov		ebx,eax
		invoke LoadDib,mapdata.mapinx,dibx,diby
		.if eax
			invoke SelectObject,mapdata.tDC,eax
			push	eax
			mov		edi,512
			mov		eax,edi
			imul	dd256
			idiv	zoomval
			invoke StretchBlt,mapdata.mDC,mapx,mapy,ebx,eax,mapdata.tDC,ofsx,0,esi,edi,SRCCOPY
			pop		eax
			invoke SelectObject,mapdata.tDC,eax
		.endif
		add		mapx,ebx
		mov		eax,mapx
		.break .if eax>=mapdata.mapwt
		mov		ofsx,0
		inc		dibx
	.endw
	pop		ofsx
	pop		mapx
	pop		dibx
	retn

ShowMap endp

ShowPlace proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	x:DWORD
	LOCAL	y:DWORD

	.if zoomval
		invoke SetTextColor,mapdata.mDC2,0
		mov		esi,offset mapdata.place
		xor		ebx,ebx
		.while ebx<MAXPLACES
			.if [esi].PLACE.zoom
				.if ![esi].PLACE.ptmap.x && ![esi].PLACE.ptmap.y
					invoke GpsPosToMapPos,[esi].PLACE.iLon,[esi].PLACE.iLat,addr [esi].PLACE.ptmap.x,addr [esi].PLACE.ptmap.y
				.endif
				invoke MapPosToScrnPos,[esi].PLACE.ptmap.x,[esi].PLACE.ptmap.y,addr x,addr y
				mov		eax,x
				sub		eax,topx
				imul	dd256
				idiv	zoomval
				mov		x,eax
				mov		eax,y
				sub		eax,topy
				imul	dd256
				idiv	zoomval
				mov		y,eax
				mov		eax,mapdata.zoominx
				.if [esi].PLACE.font && eax<[esi].PLACE.zoom && [esi].PLACE.text
					mov		eax,[esi].PLACE.font
					invoke SelectObject,mapdata.mDC2,mapdata.font[eax*4]
					push	eax
					invoke strlen,addr [esi].PLACE.text
					mov		ecx,x
					add		ecx,8
					mov		edx,y
					sub		edx,10
					invoke TextOut,mapdata.mDC2,ecx,edx,addr [esi].PLACE.text,eax
					pop		eax
					invoke SelectObject,mapdata.mDC2,eax
				.endif
				.if [esi].PLACE.icon
					mov		eax,[esi].PLACE.icon
					mov		ecx,x
					sub		ecx,8
					mov		edx,y
					sub		edx,8
					invoke ImageList_Draw,hIml,addr [eax+15],mapdata.mDC2,ecx,edx,ILD_TRANSPARENT
				.endif
			.endif
			lea		esi,[esi+sizeof PLACE]
			inc		ebx
		.endw
	.endif
	ret

ShowPlace endp

ShowGpsCursor proc uses ebx esi edi,topx:DWORD,topy:DWORD,curx:DWORD,cury:DWORD,zoomval:DWORD
	LOCAL	pt:POINT

	.if zoomval && mapdata.fcursor
		mov		eax,curx
		sub		eax,topx
		imul	dd256
		idiv	zoomval
		sub		eax,8
		mov		pt.x,eax
		mov		eax,cury
		sub		eax,topy
		imul	dd256
		idiv	zoomval
		sub		eax,8
		mov		pt.y,eax
		invoke ImageList_Draw,hIml,mapdata.ncursor,mapdata.mDC2,pt.x,pt.y,ILD_TRANSPARENT
		.if mapdata.fUnLocked
			mov		eax,sonardata.cursonarbmpinx
			mov		edx,sizeof SONARBMP
			mul		edx
			mov		esi,eax
			invoke GpsPosToMapPos,sonardata.sonarbmp.iLon[esi],sonardata.sonarbmp.iLat[esi],addr pt.x,addr pt.y
			invoke MapPosToScrnPos,pt.x,pt.y,addr pt.x,addr pt.y
			mov		eax,pt.x
			sub		eax,topx
			imul	dd256
			idiv	zoomval
			sub		eax,8
			mov		pt.x,eax
			mov		eax,pt.y
			sub		eax,topy
			imul	dd256
			idiv	zoomval
			sub		eax,8
			mov		pt.y,eax
			invoke ImageList_Draw,hIml,28,mapdata.mDC2,pt.x,pt.y,ILD_TRANSPARENT
		.endif
	.endif
	ret

ShowGpsCursor endp

ShowSpeedBattTempTimeScale proc uses ebx esi edi
	LOCAL	rect:RECT
	LOCAL	x:DWORD
	LOCAL	y:DWORD
	LOCAL	lon1:DWORD
	LOCAL	lat1:DWORD
	LOCAL	lon2:DWORD
	LOCAL	lat2:DWORD
	LOCAL	fdist:REAL10
	LOCAL	fbear:REAL10

	invoke SetTextColor,mapdata.mDC2,0
	xor		ebx,ebx
	mov		esi,offset mapdata.options
	.while ebx<MAXMAPOPTION
		.if [esi].OPTIONS.show
			mov		ecx,[esi].OPTIONS.pt.x
			mov		edx,[esi].OPTIONS.pt.y
			mov		rect.left,ecx
			mov		rect.top,edx
			mov		eax,mapdata.mapwt
			sub		eax,ecx
			mov		rect.right,eax
			mov		eax,mapdata.mapht
			sub		eax,edx
			mov		rect.bottom,eax
			mov		eax,[esi].OPTIONS.font
			.if ebx>=3
				shl		eax,1
			.else
				add		eax,7
			.endif
			mov		ecx,mapdata.font[eax*4]
			mov		edx,[esi].OPTIONS.position
			.if !edx
				;Left, Top
				mov		eax,DT_LEFT or DT_SINGLELINE
			.elseif edx==1
				;Center, Top
				mov		eax,DT_CENTER or DT_SINGLELINE
			.elseif edx==2
				;Rioght, Top
				mov		eax,DT_RIGHT or DT_SINGLELINE
			.elseif edx==3
				;Left, Bottom
				mov		eax,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
			.elseif edx==4
				;Center, Bottom
				mov		eax,DT_CENTER or DT_BOTTOM or DT_SINGLELINE
			.elseif edx==5
				;Right, Bottom
				mov		eax,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
			.endif
			.if ebx || mapdata.fcursor
				invoke TextDraw,mapdata.mDC2,ecx,addr rect,addr [esi].OPTIONS.text,eax
			.endif
			.if ebx==3
				call	ShowScale
			.endif
		.endif
		lea		esi,[esi+sizeof OPTIONS]
		inc		ebx
	.endw
	ret

ShowScale:
	;Get the width of the scale bar using vertical center of screen.
	mov		edx,mapdata.mapht
	shr		edx,1
	invoke ScrnPosToMapPos,0,edx,addr x,addr y
	invoke MapPosToGpsPos,x,y,addr lon1,addr lat1
	add		x,2000
	invoke MapPosToGpsPos,x,y,addr lon2,addr lat2
	invoke BearingDistanceInt,lon1,lat1,lon2,lat2,addr fdist,addr fbear
	mov		eax,mapdata.zoominx
	mov		ecx,sizeof ZOOM
	mul		ecx
	mov		eax,mapdata.zoom.scalem[eax]
	mov		edx,2000
	mul		edx
	mov		lon1,eax
	fild	lon1
	lea		eax,fdist
	fld		REAL10 PTR [eax]
	fdiv
	fistp	lon1
	mov		eax,lon1
	shl		eax,8
	mov		edx,mapdata.mapinx
	.if edx==4
		shr		eax,1
	.elseif edx==16
		shr		eax,2
	.elseif edx==64
		shr		eax,3
	.elseif edx==256
		shr		eax,4
	.endif
	xor		edx,edx
	mov		ecx,mapdata.zoomval
	div		ecx
	mov		edi,eax
	;Draw the text
	invoke strlen,addr [esi].OPTIONS.text
	mov		ecx,eax
	mov		edx,[esi].OPTIONS.position
	.if !edx
		;Left, Top
		mov		eax,rect.left
		mov		x,eax
		mov		eax,edi
		shr		eax,1
		sub		x,eax
		invoke DrawText,mapdata.mDC2,addr [esi].OPTIONS.text,ecx,addr rect,DT_LEFT or DT_SINGLELINE or DT_CALCRECT
		mov		eax,rect.right
		sub		eax,rect.left
		shr		eax,1
		add		x,eax
	.elseif edx==1
		;Center, Top
		mov		rect.left,0
		mov		eax,[esi].OPTIONS.pt.x
		sub		rect.right,eax
		mov		eax,rect.right
		shr		eax,1
		mov		x,eax
		mov		eax,edi
		shr		eax,1
		sub		x,eax
		invoke DrawText,mapdata.mDC2,addr [esi].OPTIONS.text,ecx,addr rect,DT_CENTER or DT_SINGLELINE or DT_CALCRECT
	.elseif edx==2
		;Rioght, Top
		mov		eax,rect.right
		sub		eax,edi
		mov		x,eax
		invoke DrawText,mapdata.mDC2,addr [esi].OPTIONS.text,ecx,addr rect,DT_RIGHT or DT_SINGLELINE or DT_CALCRECT
		mov		eax,rect.right
		sub		eax,rect.left
		add		x,eax
	.elseif edx==3
		;Left, Bottom
		mov		eax,rect.left
		mov		x,eax
		mov		eax,edi
		shr		eax,1
		sub		x,eax
		invoke DrawText,mapdata.mDC2,addr [esi].OPTIONS.text,ecx,addr rect,DT_LEFT or DT_BOTTOM or DT_SINGLELINE or DT_CALCRECT
		mov		eax,rect.right
		sub		eax,rect.left
		shr		eax,1
		add		x,eax
	.elseif edx==4
		;Center, Bottom
		mov		rect.left,0
		mov		eax,[esi].OPTIONS.pt.x
		sub		rect.right,eax
		mov		eax,rect.right
		shr		eax,1
		mov		x,eax
		mov		eax,edi
		shr		eax,1
		sub		x,eax
		invoke DrawText,mapdata.mDC2,addr [esi].OPTIONS.text,ecx,addr rect,DT_CENTER or DT_BOTTOM or DT_SINGLELINE or DT_CALCRECT
	.elseif edx==5
		;Right, Bottom
		mov		eax,rect.right
		sub		eax,edi
		mov		x,eax
		invoke DrawText,mapdata.mDC2,addr [esi].OPTIONS.text,ecx,addr rect,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE or DT_CALCRECT
		mov		eax,rect.right
		sub		eax,rect.left
		add		x,eax
	.endif
	;Draw the scalebar
	mov		eax,rect.bottom
	sub		eax,4
	invoke MoveToEx,mapdata.mDC2,x,eax,NULL
	invoke LineTo,mapdata.mDC2,x,rect.bottom
	add		x,edi
	invoke LineTo,mapdata.mDC2,x,rect.bottom
	mov		eax,rect.bottom
	sub		eax,5
	invoke LineTo,mapdata.mDC2,x,eax
	retn

ShowSpeedBattTempTimeScale endp

ShowTrail proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	pt:POINT

	invoke CreatePen,PS_SOLID,2,0808080h
	invoke SelectObject,mapdata.mDC2,eax
	push	eax
	mov		ebx,mapdata.trailtail
	call	ToScreen
	invoke MoveToEx,mapdata.mDC2,pt.x,pt.y,NULL
	.while ebx!=mapdata.trailhead
		inc		ebx
		and		ebx,MAXTRAIL-1
		.if ebx!=mapdata.trailhead
			call	ToScreen
			invoke LineTo,mapdata.mDC2,pt.x,pt.y
		.endif
	.endw
	pop		eax
	invoke SelectObject,mapdata.mDC2,eax
	invoke DeleteObject,eax
	ret

ToScreen:
	mov		edx,ebx
	shl		edx,4
	invoke GpsPosToMapPos,mapdata.trail.iLon[edx],mapdata.trail.iLat[edx],addr pt.x,addr pt.y
	invoke MapPosToScrnPos,pt.x,pt.y,addr pt.x,addr pt.y
	mov 	eax,pt.x
	sub		eax,topx
	imul	dd256
	idiv	zoomval
	mov		pt.x,eax
	mov 	eax,pt.y
	sub		eax,topy
	imul	dd256
	idiv	zoomval
	mov		pt.y,eax
	retn

ShowTrail endp

ShowDist proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	pt:POINT

	xor		ebx,ebx
	call	ToScreen
	invoke MoveToEx,mapdata.mDC2,pt.x,pt.y,NULL
	sub		pt.x,8
	sub		pt.y,8
	invoke ImageList_Draw,hIml,16,mapdata.mDC2,pt.x,pt.y,ILD_TRANSPARENT
	inc		ebx
	.while ebx<mapdata.disthead && ebx<MAXDIST
		call	ToScreen
		lea		edx,[ebx+1]
		mov		eax,17
		.if edx==mapdata.disthead
			mov		eax,18
		.endif
		mov		ecx,pt.x
		sub		ecx,8
		mov		edx,pt.y
		sub		edx,8
		invoke ImageList_Draw,hIml,eax,mapdata.mDC2,ecx,edx,ILD_TRANSPARENT
		invoke LineTo,mapdata.mDC2,pt.x,pt.y
		inc		ebx
	.endw
	ret

ToScreen:
	mov		edx,ebx
	shl		edx,4
	invoke GpsPosToMapPos,mapdata.dist.iLon[edx],mapdata.dist.iLat[edx],addr pt.x,addr pt.y
	invoke MapPosToScrnPos,pt.x,pt.y,addr pt.x,addr pt.y
	mov 	eax,pt.x
	sub		eax,topx
	imul	dd256
	idiv	zoomval
	mov		pt.x,eax
	mov 	eax,pt.y
	sub		eax,topy
	imul	dd256
	idiv	zoomval
	mov		pt.y,eax
	retn

ShowDist endp

ShowTrip proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	pt:POINT

	xor		ebx,ebx
	call	ToScreen
	invoke MoveToEx,mapdata.mDC2,pt.x,pt.y,NULL
	sub		pt.x,8
	sub		pt.y,8
	invoke ImageList_Draw,hIml,16,mapdata.mDC2,pt.x,pt.y,ILD_TRANSPARENT
	inc		ebx
	.while ebx<mapdata.triphead && ebx<MAXTRIP
		call	ToScreen
		lea		edx,[ebx+1]
		mov		eax,17
		.if edx==mapdata.triphead
			mov		eax,18
		.endif
		mov		ecx,pt.x
		sub		ecx,8
		mov		edx,pt.y
		sub		edx,8
		invoke ImageList_Draw,hIml,eax,mapdata.mDC2,ecx,edx,ILD_TRANSPARENT
		invoke LineTo,mapdata.mDC2,pt.x,pt.y
		inc		ebx
	.endw
	ret

ToScreen:
	mov		edx,ebx
	shl		edx,4
	invoke GpsPosToMapPos,mapdata.trip.iLon[edx],mapdata.trip.iLat[edx],addr pt.x,addr pt.y
	invoke MapPosToScrnPos,pt.x,pt.y,addr pt.x,addr pt.y
	mov 	eax,pt.x
	sub		eax,topx
	imul	dd256
	idiv	zoomval
	mov		pt.x,eax
	mov 	eax,pt.y
	sub		eax,topy
	imul	dd256
	idiv	zoomval
	mov		pt.y,eax
	retn

ShowTrip endp

ShowGrid proc uses ebx esi edi,topx:DWORD,topy:DWORD,zoomval:DWORD
	LOCAL	fpixm:REAL10
	LOCAL	i:DWORD
	LOCAL	x:DWORD
	LOCAL	y:DWORD

	invoke CreatePen,PS_SOLID,1,0A0A0A0h
	invoke SelectObject,mapdata.mDC2,eax
	push	eax
	mov		eax,mapdata.zoominx
	mov		ecx,sizeof ZOOM
	mul		ecx
	lea		esi,[eax+offset mapdata.zoom]
	fild	mapdata.zoom.xPixels[sizeof ZOOM]
	fild	mapdata.zoom.xMeters[sizeof ZOOM]
	fdivp	st(1),st(0)
	fstp	fpixm
	fild	topx
	fild	[esi].ZOOM.scalem
	fld		fpixm
	fmulp	st(1),st(0)
	fdivp	st(1),st(0)
	fistp	i
	.while TRUE
		fild	[esi].ZOOM.scalem
		fild	i
		fmulp	st(1),st(0)
		fld		fpixm
		fmulp	st(1),st(0)
		fistp	x
		invoke MapPosToScrnPos,x,0,addr x,addr y
		mov		eax,x
		sub		eax,topx
		imul	dd256
		idiv	zoomval
		mov		x,eax
		.break .if sdword ptr eax>mapdata.mapwt
		.if sdword ptr eax>=0
			invoke MoveToEx,mapdata.mDC2,x,0,NULL
			invoke LineTo,mapdata.mDC2,x,mapdata.mapht
		.endif
		inc		i
	.endw
	fild	mapdata.zoom.yPixels[sizeof ZOOM]
	fild	mapdata.zoom.yMeters[sizeof ZOOM]
	fdivp	st(1),st(0)
	fstp	fpixm
	fild	topy
	fild	[esi].ZOOM.scalem
	fld		fpixm
	fmulp	st(1),st(0)
	fdivp	st(1),st(0)
	fistp	i
	.while TRUE
		fild	[esi].ZOOM.scalem
		fild	i
		fmulp	st(1),st(0)
		fld		fpixm
		fmulp	st(1),st(0)
		fistp	y
		invoke MapPosToScrnPos,0,y,addr x,addr y
		mov		eax,y
		sub		eax,topy
		imul	dd256
		idiv	zoomval
		mov		y,eax
		.break .if sdword ptr eax>mapdata.mapht
		.if sdword ptr eax>=0
			invoke MoveToEx,mapdata.mDC2,0,y,NULL
			invoke LineTo,mapdata.mDC2,mapdata.mapwt,y
		.endif
		inc		i
	.endw
	pop		eax
	invoke SelectObject,mapdata.mDC2,eax
	invoke DeleteObject,eax
	ret

ShowGrid endp

;This thread proc pains the map window
MAPThread proc uses esi edi,Param:DWORD
	LOCAL	zoomval:DWORD
	LOCAL	topx:DWORD
	LOCAL	topy:DWORD
	LOCAL	curx:DWORD
	LOCAL	cury:DWORD

	.while !fExitMAPThread
		.if mapdata.paintnow
			mov		mapdata.paintnow,0
			mov		eax,mapdata.zoomval
			mov		zoomval,eax
			mov		ecx,mapdata.topx
			mov		edx,mapdata.topy
			mov		topx,ecx
			mov		topy,edx
			mov		ecx,mapdata.cursorx
			mov		edx,mapdata.cursory
			mov		curx,ecx
			mov		cury,edx
			invoke ShowMap,topx,topy,zoomval
			invoke BitBlt,mapdata.mDC2,0,0,mapdata.mapwt,mapdata.mapht,mapdata.mDC,0,0,SRCCOPY
			.if mapdata.mapgrid
				invoke ShowGrid,topx,topy,zoomval
			.endif
			.if mapdata.gpstrail
				mov		eax,mapdata.trailhead
				.if eax!=mapdata.trailtail
					invoke ShowTrail,topx,topy,zoomval
				.endif
			.endif
			invoke ShowPlace,topx,topy,zoomval
			.if mapdata.triphead
				invoke ShowTrip,topx,topy,zoomval
			.endif
			.if mapdata.disthead
				invoke ShowDist,topx,topy,zoomval
			.endif
			invoke ShowGpsCursor,topx,topy,curx,cury,zoomval
			invoke ShowSpeedBattTempTimeScale
			invoke BitBlt,mapdata.hDC,0,0,mapdata.mapwt,mapdata.mapht,mapdata.mDC2,0,0,SRCCOPY
		.else
			invoke DoSleep,100
		.endif
	.endw
	mov		fExitMAPThread,2
	xor		eax,eax
	ret

MAPThread endp

InitMaps proc uses ebx
	LOCAL	buffer[MAX_PATH]:BYTE

	;Get zoom index
	invoke GetPrivateProfileInt,addr szIniMap,addr szIniZoom,1,addr szIniFileName
	mov		mapdata.zoominx,eax
	;Get zoom level
	mov		edx,sizeof ZOOM
	mul		edx
	mov		edx,mapdata.zoom.zoomval[eax]
	mov		mapdata.zoomval,edx
	mov		edx,mapdata.zoom.mapinx[eax]
	mov		mapdata.mapinx,edx
	mov		edx,mapdata.zoom.nx[eax]
	mov		mapdata.nx,edx
	mov		edx,mapdata.zoom.ny[eax]
	mov		mapdata.ny,edx
	invoke strcpy,addr mapdata.options.text[sizeof OPTIONS*3],addr mapdata.zoom.text[eax]
	;Get map pixel positions, left top and right bottom
	invoke GetPrivateProfileString,addr szIniMap,addr szIniPos,addr szNULL,addr buffer,sizeof buffer,addr szIniFileName
	invoke GetItemInt,addr buffer,0
	mov		mapdata.topx,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.topy,eax
	invoke GetItemInt,addr buffer,256
	mov		mapdata.cursorx,eax
	invoke GetItemInt,addr buffer,256
	mov		mapdata.cursory,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.iLon,eax
	invoke GetItemInt,addr buffer,0
	mov		mapdata.iLat,eax
	ret

InitMaps endp

InitZoom proc uses ebx esi edi

	mov		esi,offset mapdata.zoom
	xor		ebx,ebx
	.while ebx<MAXZOOM
		invoke wsprintf,addr szbuff,addr szFmtDec,ebx
		invoke GetPrivateProfileString,addr szIniZoom,addr szbuff,addr szNULL,addr szbuff,sizeof szbuff,addr szIniFileName
		.break .if !eax
		invoke GetItemInt,addr szbuff,0
		mov		[esi].ZOOM.zoomval,eax
		invoke GetItemInt,addr szbuff,0
		mov		[esi].ZOOM.mapinx,eax
		invoke GetItemInt,addr szbuff,0
		mov		[esi].ZOOM.scalem,eax
		invoke strcpyn,addr [esi].ZOOM.text,addr szbuff,sizeof ZOOM.text
		invoke CountMapTiles,[esi].ZOOM.mapinx,addr [esi].ZOOM.nx,addr [esi].ZOOM.ny
		invoke GetMapSize,[esi].ZOOM.nx,[esi].ZOOM.ny,addr [esi].ZOOM.xPixels,addr [esi].ZOOM.yPixels,addr [esi].ZOOM.xMeters,addr [esi].ZOOM.yMeters
		.if !ebx
			mov		eax,[esi].ZOOM.xPixels
			mov		mapdata.xPixels,eax
			mov		eax,[esi].ZOOM.yPixels
			mov		mapdata.yPixels,eax
			mov		eax,[esi].ZOOM.xMeters
			mov		mapdata.xMeters,eax
			mov		eax,[esi].ZOOM.yMeters
			mov		mapdata.yMeters,eax
		.endif
		;Convert xPixels to zoomval
		mov		eax,[esi].ZOOM.xPixels
		imul	dd256
		idiv	[esi].ZOOM.zoomval
		mov		[esi].ZOOM.xPixels,eax
		;Convert yPixels to zoomval
		mov		eax,[esi].ZOOM.yPixels
		imul	dd256
		idiv	[esi].ZOOM.zoomval
		mov		[esi].ZOOM.yPixels,eax
		lea		esi,[esi+sizeof ZOOM]
		inc		ebx
	.endw
	mov		mapdata.zoommax,ebx
	ret

InitZoom endp

InitScroll proc

	mov		eax,mapdata.nx
	inc		eax
	shl		eax,9
	sub		eax,mapdata.mapwt
	shr		eax,4
	invoke SetScrollRange,hMap,SB_HORZ,0,eax,TRUE
	mov		eax,mapdata.topx
	shr		eax,4
	invoke SetScrollPos,hMap,SB_HORZ,eax,TRUE
	mov		eax,mapdata.ny
	inc		eax
	shl		eax,9
	sub		eax,mapdata.mapht
	shr		eax,4
	invoke SetScrollRange,hMap,SB_VERT,0,eax,TRUE
	mov		eax,mapdata.topy
	shr		eax,4
	invoke SetScrollPos,hMap,SB_VERT,eax,TRUE
	ret

InitScroll endp

MapChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	pt:POINT
	LOCAL	x:DWORD
	LOCAL	y:DWORD
	LOCAL	iLon:DWORD
	LOCAL	iLat:DWORD
	LOCAL	fDist:REAL10
	LOCAL	fBear:REAL10

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hMap,eax
		invoke ImageList_Create,16,16,ILC_COLOR24 or ILC_MASK,8+16,0
		mov		hIml,eax
		invoke LoadBitmap,hInstance,100
		mov		ebx,eax
		invoke ImageList_AddMasked,hIml,ebx,0FF00FFh
		invoke DeleteObject,ebx
		invoke GetDC,hWin
		mov		mapdata.hDC,eax
		invoke CreateCompatibleDC,mapdata.hDC
		mov		mapdata.mDC,eax
		invoke GetSystemMetrics,SM_CXSCREEN
		mov		mapdata.cxs,eax
		invoke GetSystemMetrics,SM_CYSCREEN
		mov		mapdata.cys,eax
		invoke CreateCompatibleBitmap,mapdata.hDC,mapdata.cxs,mapdata.cys
		invoke SelectObject,mapdata.mDC,eax
		mov		mapdata.hmBmpOld,eax
		invoke CreateCompatibleDC,mapdata.hDC
		mov		mapdata.mDC2,eax
		invoke CreateCompatibleBitmap,mapdata.hDC,1,1
		invoke SelectObject,mapdata.mDC2,eax
		mov		mapdata.hmBmpOld2,eax
		invoke CreateCompatibleDC,mapdata.hDC
		mov		mapdata.tDC,eax
		invoke SetStretchBltMode,mapdata.mDC,COLORONCOLOR
		invoke SetBkMode,mapdata.mDC2,TRANSPARENT
	.elseif eax==WM_CONTEXTMENU
		mov		eax,lParam
		.if eax!=-1
			movsx	edx,ax
			mov		mousept.x,edx
			mov		pt.x,edx
			shr		eax,16
			movsx	edx,ax
			mov		mousept.y,edx
			mov		pt.y,edx
			.if mapdata.btrip
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.btrip==2
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_TRIP_DONE,eax
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.btrip==3
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_TRIP_EDIT,eax
				.if mapdata.btrip==3 && mapdata.onpoint!=-1
					mov		eax,MF_BYCOMMAND or MF_ENABLED
					.if mapdata.triphead==1
						mov		eax,MF_BYCOMMAND or MF_GRAYED
					.endif
					invoke EnableMenuItem,hContext,IDM_TRIP_DELETE,eax
					invoke GetSubMenu,hContext,2
				.else
					invoke GetSubMenu,hContext,1
				.endif
			.elseif mapdata.bdist
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.bdist==2
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_DIST_DONE,eax
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.if mapdata.bdist==3
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hContext,IDM_DIST_EDIT,eax
				.if mapdata.bdist==3 && mapdata.onpoint!=-1
					mov		eax,MF_BYCOMMAND or MF_ENABLED
					.if mapdata.disthead==1
						mov		eax,MF_BYCOMMAND or MF_GRAYED
					.endif
					invoke EnableMenuItem,hContext,IDM_DIST_DELETE,eax
					invoke GetSubMenu,hContext,4
				.else
					invoke GetSubMenu,hContext,3
				.endif
			.else
				invoke ScreenToClient,hWin,addr pt
				invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr iLon,addr iLat
				invoke FindPlace,iLon,iLat
				mov		nPlace,eax
				mov		edx,MF_BYCOMMAND or MF_GRAYED
				.if eax!=-1
					mov		edx,MF_BYCOMMAND or MF_ENABLED
				.endif
				invoke EnableMenuItem,hContext,IDM_EDITPLACE,edx
				invoke GetSubMenu,hContext,0
			.endif
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,mousept.x,mousept.y,0,hWnd,0
			invoke ScreenToClient,hWin,addr mousept
		.endif
	.elseif eax==WM_PAINT
		inc		mapdata.paintnow
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		mov		eax,rect.right
		mov		mapdata.mapwt,eax
		mov		eax,rect.bottom
		mov		mapdata.mapht,eax
		invoke CreateCompatibleBitmap,mapdata.hDC,mapdata.mapwt,mapdata.mapht
		invoke SelectObject,mapdata.mDC2,eax
		invoke DeleteObject,eax
		invoke InitScroll
	.elseif eax==WM_MOUSEMOVE
		mov		edx,lParam
		movsx	eax,dx
		shr		edx,16
		movsx	edx,dx
		mov		pt.x,eax
		mov		pt.y,edx
		push	eax
		push	edx
		invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
		invoke MapPosToGpsPos,x,y,addr iLon,addr iLat
		invoke SetDlgItemInt,hControls,IDC_STCLAT,iLat,TRUE
		mov		eax,iLon
		invoke SetDlgItemInt,hControls,IDC_STCLON,eax,TRUE
		pop		edx
		pop		eax
		.if mapdata.bdist==1 && mapdata.disthead
			.if eax>mapdata.mapwt || edx>mapdata.mapht
				invoke ReleaseCapture
				.if mapdata.disthead
					inc		mapdata.paintnow
				.endif
			.else
				mov		pt.x,eax
				mov		pt.y,edx
				invoke BitBlt,mapdata.hDC,0,0,mapdata.mapwt,mapdata.mapht,mapdata.mDC2,0,0,SRCCOPY
				mov		edi,mapdata.disthead
				dec		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke GpsPosToMapPos,mapdata.dist.iLon[ebx],mapdata.dist.iLat[ebx],addr x,addr y
				invoke MapPosToScrnPos,x,y,addr x,addr y
				mov 	eax,x
				sub		eax,mapdata.topx
				imul	dd256
				idiv	mapdata.zoomval
				mov		x,eax
				mov 	eax,y
				sub		eax,mapdata.topy
				imul	dd256
				idiv	mapdata.zoomval
				mov		y,eax
				invoke MoveToEx,mapdata.hDC,x,y,NULL
				invoke LineTo,mapdata.hDC,pt.x,pt.y
				inc		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx]
				invoke GetCapture
				.if eax!=hWin
					invoke SetCapture,hWin
				.endif
				invoke GetDistance,addr mapdata.dist,mapdata.disthead
			.endif
		.elseif mapdata.bdist==3 && mapdata.disthead
			.if (wParam & MK_LBUTTON) && mapdata.onpoint!=-1
				mov		ebx,mapdata.onpoint
				shl		ebx,4
				mov		ecx,eax
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx]
				.if mapdata.onpoint
					invoke BearingDistanceInt,mapdata.dist.iLon[ebx-sizeof LOG],addr mapdata.dist.iLat[ebx-sizeof LOG],mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx],addr fDist,addr fBear
					fld		fBear
					fistp	mapdata.dist.iBear[ebx-sizeof LOG]
				.endif
				mov		eax,mapdata.disthead
				dec		eax
				invoke GetDistance,addr mapdata.dist,eax
			.else
				invoke FindPoint,eax,edx,addr mapdata.dist,mapdata.disthead
				mov		mapdata.onpoint,eax
			.endif
			inc		mapdata.paintnow
		.elseif mapdata.btrip==1 && mapdata.triphead
			.if eax>mapdata.mapwt || edx>mapdata.mapht
				invoke ReleaseCapture
				.if mapdata.triphead
					inc		mapdata.paintnow
				.endif
			.else
				mov		pt.x,eax
				mov		pt.y,edx
				invoke BitBlt,mapdata.hDC,0,0,mapdata.mapwt,mapdata.mapht,mapdata.mDC2,0,0,SRCCOPY
				mov		edi,mapdata.triphead
				dec		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke GpsPosToMapPos,mapdata.trip.iLon[ebx],mapdata.trip.iLat[ebx],addr x,addr y
				invoke MapPosToScrnPos,x,y,addr x,addr y
				mov 	eax,x
				sub		eax,mapdata.topx
				imul	dd256
				idiv	mapdata.zoomval
				mov		x,eax
				mov 	eax,y
				sub		eax,mapdata.topy
				imul	dd256
				idiv	mapdata.zoomval
				mov		y,eax
				invoke MoveToEx,mapdata.hDC,x,y,NULL
				invoke LineTo,mapdata.hDC,pt.x,pt.y
				inc		edi
				mov		eax,sizeof LOG
				mul		edi
				mov		ebx,eax
				invoke ScrnPosToMapPos,pt.x,pt.y,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx]
				invoke GetCapture
				.if eax!=hWin
					invoke SetCapture,hWin
				.endif
				invoke GetDistance,addr mapdata.trip,mapdata.triphead
			.endif
		.elseif mapdata.btrip==3 && mapdata.triphead
			.if (wParam & MK_LBUTTON) && mapdata.onpoint!=-1
				mov		ebx,mapdata.onpoint
				shl		ebx,4
				mov		ecx,eax
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx]
				.if mapdata.onpoint
					invoke BearingDistanceInt,mapdata.trip.iLon[ebx-sizeof LOG],addr mapdata.trip.iLat[ebx-sizeof LOG],mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx],addr fDist,addr fBear
					fld		fBear
					fistp	mapdata.trip.iBear[ebx-sizeof LOG]
				.endif
				mov		eax,mapdata.triphead
				dec		eax
				invoke GetDistance,addr mapdata.trip,eax
			.else
				invoke FindPoint,eax,edx,addr mapdata.trip,mapdata.triphead
				mov		mapdata.onpoint,eax
			.endif
			inc		mapdata.paintnow
		.elseif wParam==MK_LBUTTON
			;Drag the map
			mov		eax,lParam
			movsx	eax,ax
			sub		eax,mousept.x
			neg		eax
			imul	mapdata.zoomval
			idiv	dd256
			add		eax,mousemappt.x
			mov		mapdata.topx,eax
			.if SIGN?
				mov		mapdata.topx,0
			.endif
			mov		eax,lParam
			shr		eax,16
			movsx	eax,ax
			sub		eax,mousept.y
			neg		eax
			imul	mapdata.zoomval
			idiv	dd256
			add		eax,mousemappt.y
			mov		mapdata.topy,eax
			.if SIGN?
				mov		mapdata.topy,0
			.endif
			mov		eax,mapdata.topx
			shr		eax,4
			invoke SetScrollPos,hMap,SB_HORZ,eax,TRUE
			mov		eax,mapdata.topy
			shr		eax,4
			invoke SetScrollPos,hMap,SB_VERT,eax,TRUE
			inc		mapdata.paintnow
		.endif
	.elseif eax==WM_LBUTTONDOWN
		mov		eax,mapdata.topx
		mov		mousemappt.x,eax
		mov		eax,mapdata.topy
		mov		mousemappt.y,eax
		mov		edx,lParam
		movsx	eax,dx
		mov		mousept.x,eax
		shr		edx,16
		movsx	edx,dx
		mov		mousept.y,edx
		.if mapdata.bdist==1
			;Add new point
			mov		edi,mapdata.disthead
			.if edi<MAXDIST-1
				mov		ecx,eax
				mov		ebx,edi
				shl		ebx,4
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.dist.iLon[ebx],addr mapdata.dist.iLat[ebx]
				inc		mapdata.disthead
				inc		mapdata.paintnow
			.endif
		.elseif mapdata.btrip==1
			;Add new point
			mov		edi,mapdata.triphead
			.if edi<MAXTRIP-1
				mov		ecx,eax
				mov		ebx,edi
				shl		ebx,4
				invoke ScrnPosToMapPos,ecx,edx,addr x,addr y
				invoke MapPosToGpsPos,x,y,addr mapdata.trip.iLon[ebx],addr mapdata.trip.iLat[ebx]
				inc		mapdata.triphead
				inc		mapdata.paintnow
			.endif
		.elseif (!mapdata.bdist || mapdata.bdist==2) && (!mapdata.btrip || mapdata.btrip==2)
			invoke SetCapture,hWin
			invoke LoadCursor,0,IDC_SIZEALL
			invoke SetCursor,eax
		.endif
	.elseif eax==WM_LBUTTONUP
		.if (!mapdata.bdist || mapdata.bdist==2) && (!mapdata.btrip || mapdata.btrip==2)
			invoke GetCapture
			.if eax==hWin
				invoke ReleaseCapture
				invoke LoadCursor,0,IDC_ARROW
				invoke SetCursor,eax
			.endif
		.endif
		invoke SetFocus,hWnd
	.elseif eax==WM_SETCURSOR
		.if mapdata.bdist==1 || mapdata.btrip==1 || (mapdata.bdist==3 && mapdata.onpoint!=-1) || (mapdata.btrip==3 && mapdata.onpoint!=-1)
			invoke LoadCursor,0,IDC_CROSS
		.else
			invoke LoadCursor,0,IDC_ARROW
		.endif
		invoke SetCursor,eax
	.elseif eax==WM_MOUSEWHEEL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		movsx	eax,ax
		test	edx,MK_CONTROL
		.if ZERO?
			.if sdword ptr eax<0
				invoke GetScrollPos,hWin,SB_VERT
				add		eax,4
				call	VScroll
			.else
				invoke GetScrollPos,hWin,SB_VERT
				sub		eax,4
				call	VScroll
			.endif
		.else
			.if sdword ptr eax<0
				invoke GetScrollPos,hWin,SB_HORZ
				add		eax,4
				call	HScroll
			.else
				invoke GetScrollPos,hWin,SB_HORZ
				sub		eax,4
				call	HScroll
			.endif
		.endif
	.elseif eax==WM_KEYDOWN
		mov		eax,wParam
		.if eax==VK_RIGHT
			invoke GetScrollPos,hWin,SB_HORZ
			add		eax,4
			call	HScroll
		.elseif eax==VK_LEFT
			invoke GetScrollPos,hWin,SB_HORZ
			sub		eax,4
			call	HScroll
		.elseif eax==VK_DOWN
			invoke GetScrollPos,hWin,SB_VERT
			add		eax,4
			call	VScroll
		.elseif eax==VK_UP
			invoke GetScrollPos,hWin,SB_VERT
			sub		eax,4
			call	VScroll
		.endif
	.elseif eax==WM_VSCROLL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		.if edx==SB_THUMBPOSITION
			call	VScroll
		.elseif edx==SB_LINEDOWN
			invoke GetScrollPos,hWin,SB_VERT
			add		eax,4
			call	VScroll
		.elseif edx==SB_LINEUP
			invoke GetScrollPos,hWin,SB_VERT
			sub		eax,4
			.if CARRY?
				xor		eax,eax
			.endif
			call	VScroll
		.elseif edx==SB_PAGEDOWN
			invoke GetScrollPos,hWin,SB_VERT
			mov		edx,mapdata.mapht
			shr		edx,4
			add		eax,edx
			call	VScroll
		.elseif edx==SB_PAGEUP
			invoke GetScrollPos,hWin,SB_VERT
			mov		edx,mapdata.mapht
			shr		edx,4
			sub		eax,edx
			call	VScroll
		.endif
	.elseif eax==WM_HSCROLL
		mov		eax,wParam
		movzx	edx,ax
		shr		eax,16
		.if edx==SB_THUMBPOSITION
			call	HScroll
		.elseif edx==SB_LINEDOWN
			invoke GetScrollPos,hWin,SB_HORZ
			add		eax,4
			call	HScroll
		.elseif edx==SB_LINEUP
			invoke GetScrollPos,hWin,SB_HORZ
			sub		eax,4
			call	HScroll
		.elseif edx==SB_PAGEDOWN
			invoke GetScrollPos,hWin,SB_HORZ
			mov		edx,mapdata.mapwt
			shr		edx,4
			add		eax,edx
			call	HScroll
		.elseif edx==SB_PAGEUP
			invoke GetScrollPos,hWin,SB_HORZ
			mov		edx,mapdata.mapwt
			shr		edx,4
			sub		eax,edx
			call	HScroll
		.endif
	.elseif eax==WM_DESTROY
		invoke SelectObject,mapdata.mDC,mapdata.hmBmpOld
		invoke DeleteObject,eax
		invoke DeleteDC,mapdata.mDC
		invoke SelectObject,mapdata.mDC2,mapdata.hmBmpOld2
		invoke DeleteObject,eax
		invoke DeleteDC,mapdata.mDC2
		invoke DeleteDC,mapdata.tDC
		invoke ReleaseDC,hWin,mapdata.hDC
		xor		ebx,ebx
		mov		esi,offset mapdata.bmpcache
		.while ebx<MAXBMP
			.if [esi].MAPBMP.hBmp
				invoke DeleteObject,[esi].MAPBMP.hBmp
			.endif
			lea		esi,[esi+sizeof MAPBMP]
			inc		ebx
		.endw
		xor		ebx,ebx
		.while ebx<MAXFONT
			.if mapdata.font[ebx*4]
				invoke DeleteObject,mapdata.font[ebx*4]
			.endif
			inc		ebx
		.endw
		invoke ImageList_Destroy,hIml
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

VScroll:
	.if sdword ptr eax<0
		xor		eax,eax
	.endif
	push	eax
	invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
	pop		eax
	shl		eax,4
	mov		edx,mapdata.ny
	inc		edx
	shl		edx,9
	sub		edx,mapdata.mapht
	.if eax>edx
		mov		eax,edx
	.endif
	mov		mapdata.topy,eax
	inc		mapdata.paintnow
	retn

HScroll:
	.if sdword ptr eax<0
		xor		eax,eax
	.endif
	push	eax
	invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
	pop		eax
	shl		eax,4
	mov		edx,mapdata.nx
	inc		edx
	shl		edx,9
	sub		edx,mapdata.mapwt
	.if eax>edx
		mov		eax,edx
	.endif
	mov		mapdata.topx,eax
	inc		mapdata.paintnow
	retn

MapChildProc endp

