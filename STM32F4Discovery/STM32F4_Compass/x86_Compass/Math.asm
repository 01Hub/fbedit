
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
	fstp	compass.pitch
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
	fstp	compass.roll
	ret

GetRoll endp

; Yaw=atan2((-yMagnetMap*cos(Roll) + zMagnetMap*sin(Roll) ) ,
; 			xMagnetMap*cos(Pitch) +
;			zMagnetMap*sin(Pitch)*sin(Roll)+
;			zMagnetMap*sin(Pitch)*cos(Roll));

GetYaw proc

	invoke GetPitch
	invoke GetRoll

	fldz
	fld		fBy
	fsubp	st(1),st
	fld		compass.roll
	fcos
	fmulp	st(1),st
	fld		fBz
	fld		compass.roll
	fsin
	fmulp	st(1),st
	faddp	st(1),st

	fld		fBx
	fld		compass.pitch
	fcos
	fmulp	st(1),st

	fld		fBz
	fld		compass.pitch
	fsin
	fmulp	st(1),st
	fld		compass.roll
	fsin
	fmulp	st(1),st

	faddp	st(1),st

	fld		fBz
	fld		compass.pitch
	fsin
	fmulp	st(1),st
	fld		compass.roll
	fcos
	fmulp	st(1),st

	faddp	st(1),st
	fpatan

	fld		REAL8 ptr [rad2deg]
	fmulp	st(1),st
	fistp	compass.ideg
	add		compass.ideg,180
	ret

GetYaw endp

CalcHeading proc

	;/* calculate roll angle Phi (-180deg, 180deg) and si, cos */
	;Phi = atan2(Gy, Gz) * RadToDeg;			/* Equation 2*/
	fld		fGy
	fld		fGz
	fpatan
	fstp	compass.roll

	fld		compass.roll
	fsin
	fistp	sinAngle
	fld		compass.roll
	fcos
	fstp	cosAngle

	;/* de-rotate by roll angle Phi */
	;Bfy = By * cosAngle - Bz * sinAngle;	/* Equation 5 y component*/
	fld		fBy
	fld		cosAngle
	fmulp	st(1),st
	fld		fBz
	fld		sinAngle
	fmulp	st(1),st
	fsubp	st(1),st
	fstp	Bfy

	;/* Bz=(By-Vy)**sin(Phi)+(Bz-Vz)*cos(Phi) */
	;Bz = By * sinAngle + Bz * cosAngle;
	fld		fBy
	fld		sinAngle
	fmulp	st(1),st
	fld		fBz
	fld		cosAngle
	fmulp	st(1),st
	faddp	st(1),st
	fstp	fBz

	;/* Gz=Gy*sin(Phi)+Gz*cos(Phi) */
	;Gz = Gy * sinAngle + Gz * cosAngle;
	fld		fGy
	fld		sinAngle
	fmulp	st(1),st
	fld		fGz
	fld		cosAngle
	fmulp	st(1),st
	faddp	st(1),st
	fstp	fGz

	;/* calculate pitch angle Theta (-90deg, 90deg) and sin, cos */
	;The = atan(-Gx / Gz) * RadToDeg;		/* Equation 3 */
	fldz
	fld		fGx
	fsubp	st(1),st
	fld		fGz
;	fabs
	fpatan
	fstp	compass.pitch

	fld		compass.pitch
	fsin
	fstp	sinAngle
	fld		compass.pitch
	fcos
	fstp	cosAngle

	;/* de-rotate by pitch angle Theta */
	;Bfx = Bx * cosAngle + Bz * sinAngle;	/* Equation 5 x component */
	fld		fBx
	fld		cosAngle
	fmulp	st(1),st
	fld		fBz
	fld		sinAngle
	fmulp	st(1),st
	faddp	st(1),st
	fstp	Bfx

	;Bfz = -Bx * sinAngle + Bz * cosAngle;	/* Equation 5 z component */

	;/* calculate yaw = ecompass angle psi (-180deg, 180deg) */
	;Psi = atan2(-Bfy, Bfx) * RadToDeg:		/* Equation 7 */
	fldz
	fld		Bfy
	fsubp	st(1),st
	fld		Bfx
	fpatan

	fld		REAL8 ptr [rad2deg]
	fmulp	st(1),st
	fistp	compass.ideg
	add		compass.ideg,180
	ret

CalcHeading endp
