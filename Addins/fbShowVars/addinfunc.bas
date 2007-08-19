
Sub AddToMenu( ByVal id As Integer, ByVal sMenu As String )

	AppendMenu( hMenu, MF_STRING, id, sMenu )

End Sub

Sub UpdateMenu(ByVal id As Integer, ByVal sMenu As String )

	Dim As MENUITEMINFO mii

	mii.cbSize = SizeOf( MENUITEMINFO )
	mii.fMask = MIIM_TYPE
	mii.fType = MFT_STRING
	mii.dwTypeData = @sMenu
	SetMenuItemInfo( lpHandles->hmenu, id, FALSE, @mii )

End Sub

Sub AddAccelerator( ByVal fvirt As Integer, ByVal akey As Integer, ByVal id As Integer )

	Dim As Integer i, nAccel
	Dim As ACCEL acl( 500 )

	nAccel = CopyAcceleratorTable( lpHandles->haccel, NULL, 0 )
	CopyAcceleratorTable( lpHandles->haccel, @acl( 0 ), nAccel )
	DestroyAcceleratorTable( lpHandles->haccel )
	' Check if id exist
	For i = 0 To nAccel - 1
		If acl( i ).cmd = id Then
			' id exist, update accelerator
			acl( i ).fVirt = fvirt
			acl( i ).key = akey
			GoTo Ex
		EndIf
	Next
	' Check if accelerator exist
	For i = 0 To nAccel - 1
		If acl( i ).fVirt = fvirt And acl( i ).key = akey Then
			' Accelerator exist, update id
			acl( i ).cmd=id
			GoTo Ex
		EndIf
	Next
	' Add new accelerator
	acl( nAccel ).fVirt = fvirt
	acl( nAccel ).key = akey
	acl( nAccel ).cmd = id
	nAccel += 1
Ex:
	lpHandles->haccel = CreateAcceleratorTable( @acl( 0 ), nAccel )

End Sub

Sub CheckMenu()

	CheckMenuItem(lpHandles->hmenu,IDM_VIEW_OUTPUT,IIf(lpData->lpWINPOS->fview And VIEW_OUTPUT,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(lpHandles->hmenu,IDM_VIEW_PROJECT,IIf(lpData->lpWINPOS->fview And VIEW_PROJECT,MF_CHECKED,MF_UNCHECKED))
	CheckMenuItem(lpHandles->hmenu,IDM_VIEW_PROPERTY,IIf(lpData->lpWINPOS->fview And VIEW_PROPERTY,MF_CHECKED,MF_UNCHECKED))

End Sub
