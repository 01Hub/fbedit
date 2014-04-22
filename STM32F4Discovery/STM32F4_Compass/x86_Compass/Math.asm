
.code

;  Pitch = atan2(xAccel, sqrt(sq(yAccel)+sq(zAccel)));
GetPitch proc

	fld		fGx
	fld		fGy
	fld		fGy
	fmulp	st(1),st
	fld		fGz
	fld		fGz
	fmulp	st(1),st
	faddp	st(1),st
	fsqrt
	fpatan
	fst		compass.pitch
	;Convert from radians to degrees
	fld		rad2deg
	fmulp	st(1),st
	fistp	compass.ipitch

	ret

GetPitch endp

;  Roll = atan2(yAccel, sqrt(sq(xAccel)+sq(zAccel)));
GetRoll proc

	fld		fGy
	fld		fGx
	fld		fGx
	fmulp	st(1),st
	fld		fGz
	fld		fGz
	fmulp	st(1),st
	faddp	st(1),st
	fsqrt
	fpatan
	fst		compass.roll
	;Convert from radians to degrees
	fld		rad2deg
	fmulp	st(1),st
	fistp	compass.iroll

	ret

GetRoll endp

; Yaw=atan2(
;			(-yMagnetMap*cos(Roll) + zMagnetMap*sin(Roll)),
; 			xMagnetMap*cos(Pitch) +
;			zMagnetMap*sin(Pitch)*sin(Roll) +
;			zMagnetMap*sin(Pitch)*cos(Roll));

GetYaw proc
	;-yMagnetMap*cos(Roll) + zMagnetMap*sin(Roll)
	fld		fBy
	fchs
	fld		compass.roll
	fcos
	fmulp	st(1),st
	fld		fBz
	fld		compass.roll
	fsin
	fmulp	st(1),st
	faddp	st(1),st

	;xMagnetMap*cos(Pitch)
	fld		fBx
	fld		compass.pitch
	fcos
	fmulp	st(1),st

	;zMagnetMap*sin(Pitch)*sin(Roll)
	fld		fBz
	fld		compass.pitch
	fsin
	fmulp	st(1),st
	fld		compass.roll
	fsin
	fmulp	st(1),st

	faddp	st(1),st

	;zMagnetMap*sin(Pitch)*cos(Roll)
	fld		fBz
	fld		compass.pitch
	fsin
	fmulp	st(1),st
	fld		compass.roll
	fcos
	fmulp	st(1),st

	faddp	st(1),st

	;Yaw=atan2(
	fpatan

	;Convert from radians to degrees
	fld		REAL8 ptr [rad2deg]
	fmulp	st(1),st
	fistp	compass.ideg
	add		compass.ideg,180
	ret

GetYaw endp

