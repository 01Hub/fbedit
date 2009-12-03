;
;
;' =========================================================================
;' With these wrapper functions you can easily convert pictures from one
;' format to another using GDI+, e.g.
;' nStatus = ConvertImageToJpeg("D:\FOTOS\TEST.BMP", "D:\FOTOS\TEST.JPG")
;' =========================================================================
;#COMPILE EXE
;#DEBUG ERROR ON
;#DIM ALL
;#INCLUDE "WIN32API.INC"
;TYPE GdiplusStartupInput
;   GdiplusVersion AS DWORD             '// Must be 1
;   DebugEventCallback AS DWORD         '// Ignored on free builds
;   SuppressBackgroundThread AS LONG    '// FALSE unless you're prepared to call
;                                       '// the hook/unhook functions properly
;   SuppressExternalCodecs AS LONG      '// FALSE unless you want GDI+ only to use
;                                       '// its internal image codecs.
;END TYPE
;TYPE GdiplusStartupOutput
;'  // The following 2 fields are NULL if SuppressBackgroundThread is FALSE.
;'  // Otherwise, they are functions which must be called appropriately to
;'  // replace the background thread.
;'  //
;'  // These should be called on the application's main message loop - i.e.
;'  // a message loop which is active for the lifetime of GDI+.
;'  // "NotificationHook" should be called before starting the loop,
;'  // and "NotificationUnhook" should be called after the loop ends.
;   NotificationHook AS DWORD
;   NotificationUnhook AS DWORD
;END TYPE
;TYPE ImageCodecInfo
;   ClassID AS GUID            '// CLSID. Codec identifier
;   FormatID AS GUID           '// GUID. File format identifier
;   CodecName AS DWORD         '// WCHAR*. Pointer to a null-terminated string
;                              '// that contains the codec name
;   DllName AS DWORD           '// WCHAR*. Pointer to a null-terminated string
;                              '// that contains the path name of the DLL in
;                              '// which the codec resides. If the codec is not
;                              '// a DLL, this pointer is NULL
;   FormatDescription AS DWORD '// WCHAR*. Pointer to a null-terminated string
;                              '// that contains the name of the format used by the codec
;   FilenameExtension AS DWORD '// WCHAR*. Pointer to a null-terminated string
;                              '// that contains all file-name extensions associated
;                              '// with the codec. The extensions are separated with semicolons.
;   MimeType AS DWORD          '// WCHAR*. Pointer to a null-terminated string
;                              '// that contains the mime type of the codec
;   Flags AS DWORD             '// Combination of flags from the ImageCodecFlags enumeration
;   Version AS DWORD           '// Integer that indicates the version of the codec
;   SigCount AS DWORD          '// Integer that indicates the number of signatures
;                              '// used by the file format associated with the codec
;   SigSize AS DWORD           '// Integer that indicates the number of bytes of each signature
;   SigPattern AS DWORD        '// BYTE*. Pointer to an array of bytes that contains
;                              '// the pattern for each signature
;   SigMask AS DWORD           '// BYTE*. Pointer to an array of bytes that contains
;                              '// the mask for each signature
;END TYPE
;DECLARE FUNCTION GdiplusStartup LIB "GDIPLUS.DLL" ALIAS "GdiplusStartup" _
;            (token AS DWORD, inputbuf AS GdiplusStartupInput, outputbuf AS GdiplusStartupOutput) AS LONG
;DECLARE SUB GdiplusShutdown LIB "GDIPLUS.DLL" ALIAS "GdiplusShutdown" _
;            (BYVAL token AS DWORD)
;DECLARE FUNCTION GdipLoadImageFromFile LIB "GDIPLUS.DLL" ALIAS "GdipLoadImageFromFile" _
;            (BYVAL flname AS STRING, lpImage AS DWORD) AS LONG
;DECLARE FUNCTION GdipDisposeImage LIB "GDIPLUS.DLL" ALIAS "GdipDisposeImage" _
;            (BYVAL lpImage AS DWORD) AS LONG
;DECLARE FUNCTION GdipGetImageEncodersSize LIB "GDIPLUS.DLL" ALIAS "GdipGetImageEncodersSize" _
;            (numEncoders AS DWORD, nSize AS DWORD) AS LONG
;DECLARE FUNCTION GdipGetImageEncoders LIB "GDIPLUS.DLL" ALIAS "GdipGetImageEncoders" _
;            (BYVAL numEncoders AS DWORD, BYVAL nSize AS DWORD, BYVAL lpEncoders AS DWORD) AS LONG
;DECLARE FUNCTION GdipSaveImageToFile LIB "GDIPLUS.DLL" ALIAS "GdipSaveImageToFile" _
;            (BYVAL lpImage AS DWORD, BYVAL flname AS STRING, clsidEncoder AS GUID, OPTIONAL BYVAL EncoderParams AS DWORD) AS LONG
;
;FUNCTION GDIP_Image_LoadFromFile(BYVAL flname AS STRING, lpImage AS DWORD) AS DWORD
;   flname = UCODE$(flname)
;   FUNCTION = GdipLoadImageFromFile(flname, lpImage)
;END FUNCTION

;FUNCTION GDIP_Image_Delete(BYVAL lpImage AS DWORD) AS LONG
;   FUNCTION = GdipDisposeImage(lpImage)
;END FUNCTION

;FUNCTION ReadUnicodeString (BYVAL lp AS DWORD) AS STRING
;   LOCAL p AS BYTE PTR, s AS STRING
;   p = lp                             '// Pointer to the string
;   IF p = %NULL THEN EXIT FUNCTION    '// Null pointer
;   WHILE CHR$(@p) <> $NUL
;      s = s + CHR$(@p)
;      p = p + 2                       '// Unicode strings require two bytes per character
;   WEND
;   FUNCTION = s
;END FUNCTION

;' ==========================================================================
;' GetEncoderClsid
;' The function GetEncoderClsid in the following example receives the MIME
;' type of an encoder and returns the class identifier (CLSID) of that encoder.
;' The MIME types of the encoders built into GDI+ are as follows:
;'   image/bmp
;'   image/jpeg
;'   image/gif
;'   image/tiff
;'   image/png
;' ==========================================================================
;FUNCTION GetEncoderClsid (BYVAL sMimeType AS STRING) AS STRING
;   DIM pImageCodecInfo AS ImageCodecInfo PTR
;   LOCAL numEncoders AS DWORD, nSize AS DWORD
;   LOCAL lRslt AS LONG, i AS LONG, x AS LONG
;   LOCAL p AS BYTE PTR, s AS STRING
;   LOCAL nSigCount AS LONG, nSigSize AS LONG
;   sMimeType = UCASE$(sMimeType)
;   lRslt = GdipGetImageEncodersSize(numEncoders, nSize)
;   REDIM buffer(nSize - 1) AS BYTE
;   pImageCodecInfo = VARPTR(buffer(0))
;   lRslt = GdipGetImageEncoders(numEncoders, nSize, pImageCodecInfo)
;   IF lRslt = 0 THEN
;      FOR i = 1 TO numEncoders
;         IF INSTR(UCASE$(ReadUnicodeString(@pImageCodecInfo.MimeType)), sMimeType) THEN
;            FUNCTION = GUIDTXT$(@pImageCodecInfo.ClassID)
;            EXIT FOR
;         END IF
;         INCR pImageCodecInfo       '// Increments pointer
;      NEXT
;   END IF
;END FUNCTION

;FUNCTION GDIP_Image_SaveToFile (BYVAL lpImage AS DWORD, BYVAL flname AS STRING, _
;         clsidEncoder AS GUID, OPTIONAL BYVAL EncoderParams AS DWORD) AS LONG
;   flname = UCODE$(flname)
;   FUNCTION = GdipSaveImageToFile(lpImage, flname, clsidEncoder, EncoderParams)
;END FUNCTION

;FUNCTION ConvertImage(BYVAL LoadFlName AS STRING, BYVAL SaveFlName AS STRING, BYVAL sMimeType AS STRING) AS LONG
;   LOCAL token AS DWORD, nStatus AS LONG
;   LOCAL StartupInput AS GdiplusStartupInput
;   LOCAL StartupOutput AS GdiplusStartupOutput
;   LOCAL s AS STRING, sEncoderClsid AS GUID
;   LOCAL lpImage AS DWORD
;   IF TRIM$(LoadFlName) = "" THEN EXIT FUNCTION
;   IF TRIM$(SaveFlName) = "" THEN EXIT FUNCTION
;   StartupInput.GdiplusVersion = 1
;   nStatus = GdiplusStartup(token, StartupInput, BYVAL %NULL)
;   IF nStatus THEN
;      PRINT "Error initializing GDI+"
;      EXIT FUNCTION
;   END IF
;   s = GetEncoderClsid(sMimeType)
;   IF s = "" THEN
;      PRINT "Encoder not installed"
;      EXIT FUNCTION
;   END IF
;   sEncoderClsid = GUID$(s)
;   nStatus = GDIP_Image_LoadFromFile(LoadFlName, lpImage)
;   IF nStatus THEN
;      FUNCTION = nStatus
;      EXIT FUNCTION
;   END IF
;   IF lpImage THEN
;      nStatus = GDIP_Image_SaveToFile(lpImage, SaveFlName, sEncoderClsid)
;      IF nStatus THEN
;         GDIP_Image_Delete lpImage
;         FUNCTION = nStatus
;         EXIT FUNCTION
;      END IF
;   END IF
;   GDIP_Image_Delete lpImage
;   GdiplusShutdown token
;END FUNCTION

;FUNCTION ConvertImageToBmp(BYVAL LoadFlName AS STRING, BYVAL SaveFlName AS STRING) AS LONG
;   FUNCTION = ConvertImage(LoadFlName, SaveFlName, "image/bmp")
;END FUNCTION

;FUNCTION ConvertImageToJpeg(BYVAL LoadFlName AS STRING, BYVAL SaveFlName AS STRING) AS LONG
;   FUNCTION = ConvertImage(LoadFlName, SaveFlName, "image/jpeg")
;END FUNCTION

;FUNCTION ConvertImageToGif(BYVAL LoadFlName AS STRING, BYVAL SaveFlName AS STRING) AS LONG
;   FUNCTION = ConvertImage(LoadFlName, SaveFlName, "image/gif")
;END FUNCTION

;FUNCTION ConvertImageToTiff(BYVAL LoadFlName AS STRING, BYVAL SaveFlName AS STRING) AS LONG
;   FUNCTION = ConvertImage(LoadFlName, SaveFlName, "image/tiff")
;END FUNCTION

;FUNCTION ConvertImageToPng(BYVAL LoadFlName AS STRING, BYVAL SaveFlName AS STRING) AS LONG
;   FUNCTION = ConvertImage(LoadFlName, SaveFlName, "image/png")
;END FUNCTION

;FUNCTION PBMAIN
;   LOCAL nStatus AS LONG
;   nStatus = ConvertImageToJpeg("D:\FOTOS\TEST.BMP", "D:\FOTOS\TEST.JPG")
;   IF nStatus THEN
;      PRINT "Failure, status = "nStatus
;   ELSE
;      PRINT "The file was converted succesfully"
;   END IF
;   WAITKEY$
;END FUNCTION

;' GetEncoderClsid
;' The function GetEncoderClsid in the following example receives the MIME
;' type of an encoder and returns the class identifier (CLSID) of that encoder.
;' The MIME types of the encoders built into GDI+ are as follows:
;'   image/bmp
;'   image/jpeg
;'   image/gif
;'   image/tiff
;'   image/png
;' ==========================================================================
;FUNCTION GetEncoderClsid (BYVAL sMimeType AS STRING) AS STRING
;   DIM pImageCodecInfo AS ImageCodecInfo PTR
;   LOCAL numEncoders AS DWORD, nSize AS DWORD
;   LOCAL lRslt AS LONG, i AS LONG, x AS LONG
;   LOCAL p AS BYTE PTR, s AS STRING
;   LOCAL nSigCount AS LONG, nSigSize AS LONG
;   sMimeType = UCASE$(sMimeType)
;   lRslt = GdipGetImageEncodersSize(numEncoders, nSize)
;   REDIM buffer(nSize - 1) AS BYTE
;   pImageCodecInfo = VARPTR(buffer(0))
;   lRslt = GdipGetImageEncoders(numEncoders, nSize, pImageCodecInfo)
;   IF lRslt = 0 THEN
;      FOR i = 1 TO numEncoders
;         IF INSTR(UCASE$(ReadUnicodeString(@pImageCodecInfo.MimeType)), sMimeType) THEN
;            FUNCTION = GUIDTXT$(@pImageCodecInfo.ClassID)
;            EXIT FOR
;         END IF
;         INCR pImageCodecInfo       '// Increments pointer
;      NEXT
;   END IF
;END FUNCTION

.const

szMimeType				db 'image/jpeg',0

.data?

gdiplSTI				GdiplusStartupInput <>
token					dd ?
EncoderClsid			GUID <>
szDefPicture			db MAX_PATH dup(?)

;Temporary data
HorRes					dd ?
VerRes					dd ?
imagen1					dd ?
imagen2					dd ?
lFormat					dd ?
grafico					dd ?
wbuffer					dw MAX_PATH dup(?)

.code

Save_Image proc uses ebx,lpImage:DWORD,lpFileName:DWORD

	invoke MultiByteToWideChar,CP_ACP,0,lpFileName,-1,offset wbuffer,MAX_PATH
	mov		wbuffer[eax*2],0
	invoke GdipSaveImageToFile,lpImage,offset wbuffer,offset EncoderClsid,0
	ret

Save_Image endp

Load_Image proc uses ebx,lpLoadFileName:DWORD,wt:DWORD,ht:DWORD,lpSaveFileName:DWORD
	LOCAL	hBmp:DWORD
	LOCAL	iwt:DWORD
	LOCAL	iht:DWORD
	; Tambien utiliza las variables globales Destinoimagenrec, grafico, hBitmap
	; Convert Image Filename to Wide character other wise it will return error
	invoke MultiByteToWideChar,CP_ACP,0,lpLoadFileName,-1,offset wbuffer,MAX_PATH
	mov		wbuffer[eax*2],0
	; Load image from file and save bitmap to imagen1
	invoke GdipLoadImageFromFile,addr wbuffer,addr imagen1
	.if !eax
		; Get original image pixel format (usually 32 Bit color) and save it to lFormat
		invoke GdipGetImagePixelFormat,imagen1,addr lFormat
		; Get control dimensions
		; C++ Bitmap::Bitmap(width, height, format) Create new bitmap with widht and height just set and same pixel format as the original image and save it to imagen2
		invoke GdipCreateBitmapFromScan0,wt,ht,0,lFormat,0,addr imagen2
		; Set graphic interpolation mode to high quality output
		;	Shrink the image using low-quality interpolation.(InterpolationModeNearestNeighbor)
		;	Shrink the image using medium-quality interpolation. (InterpolationModeHighQualityBilinear)
		;	Shrink the image using high-quality interpolation. (InterpolationModeHighQualityBicubic)
		invoke GdipSetInterpolationMode,grafico,InterpolationModeHighQualityBilinear  ; equ	6
		; Get original image Horizontal resolution and save it to HorRes variable
		invoke GdipGetImageHorizontalResolution,imagen1,addr HorRes
		; Get original image Vertical resolution and save it to VerRes variable
		invoke GdipGetImageVerticalResolution,imagen1,addr VerRes
		; Set new image vertical and horizontal resolution to match orignal image resolution
		invoke GdipBitmapSetResolution,imagen2,HorRes,VerRes
		invoke GdipGetImageWidth,imagen1,addr iwt
		invoke GdipGetImageHeight,imagen1,addr iht
		mov		eax,iwt
		shl		eax,8
		mov		ecx,iht
		xor		edx,edx
		div		ecx
		mov		ebx,eax
		; Create new graphics object from new image
		invoke GdipGetImageGraphicsContext,imagen2,addr grafico
		;	 RGB 0,0,0
		; Set image background to Black color
		invoke GdipGraphicsClear,grafico,0
		; Draw resized original image to graphic object of new bitmap
		mov		eax,ht
		mul		ebx
		shr		eax,8
		mov		wt,eax
		invoke GdipDrawImageRectI,grafico,imagen1,0,0,wt,ht
		; Destroy orignal image
		invoke GdipDisposeImage,imagen1
		; Delete new image graphic object
		invoke GdipDeleteGraphics,grafico
		; Create standard GDI Bitmap from Gdi+ Bitmap and save bitmap handle in hBitmap variable
		; If you want to rotate image use:
		;invoke GdipImageRotateFlip,imagen2,Rotate90FlipNone
		invoke GdipCreateHBITMAPFromBitmap,imagen2,addr hBmp,0
		mov		edx,lpSaveFileName
		.if edx
			.if byte ptr [edx]
				invoke Save_Image,imagen2,lpSaveFileName
			.endif
		.endif
		; Set VB Picture box control image to our new resized image
		invoke GdipDisposeImage,imagen2
		mov		eax,hBmp
	.else
		xor		eax,eax
	.endif
	ret

Load_Image endp

; ==========================================================================
; GetEncoderClsid
; The function GetEncoderClsid in the following example receives the MIME
; type of an encoder and returns the class identifier (CLSID) of that encoder.
; The MIME types of the encoders built into GDI+ are as follows:
;   image/bmp
;   image/jpeg
;   image/gif
;   image/tiff
;   image/png
; ==========================================================================
GetEncoderClsid proc
	LOCAL	numEncoders:DWORD
	LOCAL	nSize:DWORD
	LOCAL	hMem:DWORD

	invoke MultiByteToWideChar,CP_ACP,0,offset szMimeType,-1,offset wbuffer,MAX_PATH
	mov		wbuffer[eax*2],0
	invoke GdipGetImageEncodersSize,addr numEncoders,addr nSize
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,nSize
	mov		hMem,eax
	invoke GdipGetImageEncoders,numEncoders,nSize,hMem
	mov		ebx,hMem
	.while numEncoders
		invoke lstrcmpiW,[ebx].ImageCodecInfo.MimeType,offset wbuffer
		.if !eax
			invoke RtlMoveMemory,offset EncoderClsid,addr [ebx].ImageCodecInfo.ClassID,sizeof GUID
			.break
		.endif
		add		ebx,sizeof ImageCodecInfo
		dec		numEncoders
	.endw
	invoke GlobalFree,hMem
	ret

GetEncoderClsid endp

GetImage proc lpLoadFileName:DWORD,wt:DWORD,ht:DWORD,lpSaveFileName:DWORD
	LOCAL	hBmp:DWORD

	mov		eax,INVALID_HANDLE_VALUE
	mov		edx,lpSaveFileName
	.if edx
		.if byte ptr [edx]
			invoke GetFileAttributes,edx
		.endif
	.endif
	.if eax!=INVALID_HANDLE_VALUE
		; Get the tumbnail
		invoke MultiByteToWideChar,CP_ACP,0,lpSaveFileName,-1,offset wbuffer,MAX_PATH
		mov		wbuffer[eax*2],0
		; Load image from file and save bitmap to imagen1
		invoke GdipLoadImageFromFile,addr wbuffer,addr imagen1
		invoke GdipCreateHBITMAPFromBitmap,imagen1,addr hBmp,0
		invoke GdipDisposeImage,imagen1
		mov		eax,hBmp
	.else
		mov		eax,INVALID_HANDLE_VALUE
		mov		edx,lpLoadFileName
		.if edx
			.if byte ptr [edx]
				invoke GetFileAttributes,edx
			.endif
		.endif
		.if eax!=INVALID_HANDLE_VALUE
			invoke Load_Image,lpLoadFileName,wt,ht,lpSaveFileName
		.else
			invoke Load_Image,addr szDefPicture,wt,ht,0
		.endif
	.endif
	ret

GetImage endp

GdipInit proc

	; Initialize GDI+ Librery
	mov		gdiplSTI.GdiplusVersion,1
	push	NULL
	lea		eax,gdiplSTI
	push	eax
	lea		eax,token
	push	eax
	call	GdiplusStartup
	; Get Gdi+ jpeg encoder clsid for saving jpeg's
	invoke GetEncoderClsid
	ret

GdipInit endp
