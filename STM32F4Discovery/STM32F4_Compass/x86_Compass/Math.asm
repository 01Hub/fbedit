
iDivide				PROTO :DWORD,:DWORD
iHundredAtanDeg		PROTO :DWORD,:DWORD
iHundredAtan2Deg	PROTO :DWORD,:DWORD
iTrig				PROTO :DWORD,:DWORD

MINDELTATRIG		equ 1
K1					equ 5701
K2					equ -1645
K3					equ 446
MINDELTADIV			equ 1

.data?
;	/* roll pitch and yaw angles computed by iecompass */
;	static Int16 iPhi, iThe, iPsi;
;	/* magnetic field readings corrected for hard iron effects and PCB orientation */
;	static Int16 iBfx, iBfy, iBfz;
;	/* hard iron estimate */
;	static Int16 iVx, iVy, iVz;

;roll pitch and yaw angles computed by iecompass
iPhi				WORD ?
iThe				WORD ?
iPsi				WORD ?

;magnetic field readings corrected for hard iron effects and PCB orientation
iBfx				WORD ?
iBfy				WORD ?
iBfz				WORD ?

;hard iron estimate
iVx					WORD ?
iVy					WORD ?
iVz					WORD ?

.code

;****************************************************************************************************************
;	tilt-compensated e-Compass code
;	public static void iecompass(Int16 iBpx, Int16 iBpy, Int16 iBpz, Int16 iGpx, Int16 iGpy, Int16 iGpz)
;	{
;		/* stack variables */
;		/* iBpx, iBpy, iBpz: the three components of the magnetometer sensor */
;		/* iGpx, iGpy, iGpz: the three components of the accelerometer sensor */
;		/* local variables */
;		Int16 iSin, iCos; /* sine and cosine */
;		/* subtract the hard iron offset */
;		iBpx -= iVx; /* see Eq 16 */
;		iBpy -= iVy; /* see Eq 16 */
;		iBpz -= iVz; /* see Eq 16 */
;		/* calculate current roll angle Phi */
;		iPhi = iHundredAtan2Deg(iGpy, iGpz);/* Eq 13 */
;		/* calculate sin and cosine of roll angle Phi */
;		iSin = iTrig(iGpy, iGpz); /* Eq 13: sin = opposite / hypotenuse */
;		iCos = iTrig(iGpz, iGpy); /* Eq 13: cos = adjacent / hypotenuse */
;		/* de-rotate by roll angle Phi */
;		iBfy = (Int16)((iBpy * iCos - iBpz * iSin) >> 15);/* Eq 19 y component */
;		iBpz = (Int16)((iBpy * iSin + iBpz * iCos) >> 15);/* Bpy*sin(Phi)+Bpz*cos(Phi)*/
;		iGpz = (Int16)((iGpy * iSin + iGpz * iCos) >> 15);/* Eq 15 denominator */
;		/* calculate current pitch angle Theta */
;		iThe = iHundredAtan2Deg((Int16)-iGpx, iGpz);/* Eq 15 */
;		/* restrict pitch angle to range -90 to 90 degrees */
;		if (iThe > 9000) iThe = (Int16) (18000 - iThe);
;		if (iThe < -9000) iThe = (Int16) (-18000 - iThe);
;		/* calculate sin and cosine of pitch angle Theta */
;		iSin = (Int16)-iTrig(iGpx, iGpz); /* Eq 15: sin = opposite / hypotenuse */
;		iCos = iTrig(iGpz, iGpx); /* Eq 15: cos = adjacent / hypotenuse */
;		/* correct cosine if pitch not in range -90 to 90 degrees */
;		if (iCos < 0) iCos = (Int16)-iCos;
;		/* de-rotate by pitch angle Theta */
;		iBfx = (Int16)((iBpx * iCos + iBpz * iSin) >> 15); /* Eq 19: x component */
;		iBfz = (Int16)((-iBpx * iSin + iBpz * iCos) >> 15);/* Eq 19: z component */
;		/* calculate current yaw = e-compass angle Psi */
;		iPsi = iHundredAtan2Deg((Int16)-iBfy, iBfx); /* Eq 22 */
;	}

;iBpx, iBpy, iBpz: the three components of the magnetometer sensor
;iGpx, iGpy, iGpz: the three components of the accelerometer sensor
iecompass proc iBpx:DWORD,iBpy:DWORD,iBpz:DWORD,iGpx:DWORD,iGpy:DWORD,iGpz:DWORD
	LOCAL	iSin:WORD
	LOCAL	iCos:WORD

;PrintText "iecompass"
	;/* subtract the hard iron offset */
	;iBpx -= iVx; /* see Eq 16 */
	mov		ax,iVx
	sub		word ptr iBpx,ax
	;iBpy -= iVy; /* see Eq 16 */
	mov		ax,iVy
	sub		word ptr iBpy,ax
	;iBpz -= iVz; /* see Eq 16 */
	mov		ax,iVz
	sub		word ptr iBpz,ax

	;/* calculate current roll angle Phi */
	;iPhi = iHundredAtan2Deg(iGpy, iGpz);/* Eq 13 */
	invoke iHundredAtan2Deg,iGpy,iGpz
	mov		iPhi,ax
	;/* calculate sin and cosine of roll angle Phi */
	;iSin = iTrig(iGpy, iGpz); /* Eq 13: sin = opposite / hypotenuse */
	invoke iTrig,iGpy,iGpz
	mov		iSin,ax
	;iCos = iTrig(iGpz, iGpy); /* Eq 13: cos = adjacent / hypotenuse */
	invoke iTrig,iGpz,iGpy
	mov		iCos,ax
	;/* de-rotate by roll angle Phi */
	;iBfy = (Int16)((iBpy * iCos - iBpz * iSin) >> 15);/* Eq 19 y component */
	mov		ax,word ptr iBpy
	mov		cx,iCos
	imul	cx
	push	eax
	mov		ax,word ptr iBpz
	mov		cx,iSin
	imul	cx
	mov		ecx,eax
	pop		eax
	sub		eax,ecx
	shr		eax,15
	mov		iBfy,ax
	;iBpz = (Int16)((iBpy * iSin + iBpz * iCos) >> 15);/* Bpy*sin(Phi)+Bpz*cos(Phi)*/
	mov		ax,word ptr iBpy
	mov		cx,iSin
	imul	cx
	push	eax
	mov		ax,word ptr iBpz
	mov		cx,iCos
	imul	cx
	mov		ecx,eax
	pop		eax
	add		eax,ecx
	shr		eax,15
	mov		word ptr iBpz,ax
	;iGpz = (Int16)((iGpy * iSin + iGpz * iCos) >> 15);/* Eq 15 denominator */
	mov		ax,word ptr iGpy
	mov		cx,iSin
	imul	cx
	push	eax
	mov		ax,word ptr iGpz
	mov		cx,iCos
	imul	cx
	mov		ecx,eax
	pop		eax
	add		eax,ecx
	shr		eax,15
	mov		word ptr iGpz,ax
	;/* calculate current pitch angle Theta */
	;iThe = iHundredAtan2Deg((Int16)-iGpx, iGpz);/* Eq 15 */
	mov		ax,word ptr iGpx
	neg		ax
	invoke iHundredAtan2Deg,ax,iGpz
	mov		iThe,ax
	;/* restrict pitch angle to range -90 to 90 degrees */
	;if (iThe > 9000) iThe = (Int16) (18000 - iThe);
	.if sword ptr iThe>sword ptr 9000
		mov		ax,18000
		sub		ax,iThe
		mov		iThe,ax
	.endif
	;if (iThe < -9000) iThe = (Int16) (-18000 - iThe);
	.if sword ptr iThe<sword ptr -9000
		mov		ax,-18000
		sub		ax,iThe
		mov		iThe,ax
	.endif
	;/* calculate sin and cosine of pitch angle Theta */
	;iSin = (Int16)-iTrig(iGpx, iGpz); /* Eq 15: sin = opposite / hypotenuse */
	invoke iTrig,iGpx,iGpz
	neg		ax
	mov		iSin,ax
	;iCos = iTrig(iGpz, iGpx); /* Eq 15: cos = adjacent / hypotenuse */
	invoke iTrig,iGpz,iGpx
	mov		iCos,ax
	;/* correct cosine if pitch not in range -90 to 90 degrees */
	;if (iCos < 0) iCos = (Int16)-iCos;
	.if sword ptr iCos<0
		neg		iCos
	.endif
	;/* de-rotate by pitch angle Theta */
	;iBfx = (Int16)((iBpx * iCos + iBpz * iSin) >> 15); /* Eq 19: x component */
	mov		ax,word ptr iBpx
	mov		cx,iCos
	imul	cx
	push	eax
	mov		ax,word ptr iBpz
	mov		cx,iSin
	imul	cx
	mov		ecx,eax
	pop		eax
	add		eax,ecx
	shr		eax,15
	mov		iBfx,ax
	;iBfz = (Int16)((-iBpx * iSin + iBpz * iCos) >> 15);/* Eq 19: z component */
	mov		ax,word ptr iBpx
	neg		ax
	mov		cx,iSin
	imul	cx
	push	eax
	mov		ax,word ptr iBpz
	mov		cx,iCos
	imul	cx
	mov		ecx,eax
	pop		eax
	add		eax,ecx
	shr		eax,15
	mov		iBfz,ax
	;/* calculate current yaw = e-compass angle Psi */
	;iPsi = iHundredAtan2Deg((Int16)-iBfy, iBfx); /* Eq 22 */
	mov		ax,iBfy
	neg		ax
	invoke iHundredAtan2Deg,ax,iBfx
	mov		iPsi,ax
	ret

iecompass endp

;****************************************************************************************************************
;	7.3 Sine and Cosine Calculation C# Source Code
;	The function iTrig computes angle sines and cosines using the definitions:

;	The accuracy is determined by the threshold MINDELTATRIG. The setting for maximum accuracy is
;	MINDELTATRIG = 1.
;	const UInt16 MINDELTATRIG = 1; /* final step size for iTrig */
;	/* function to calculate ir = ix / sqrt(ix*ix+iy*iy) using binary division */
;	static Int16 iTrig(Int16 ix, Int16 iy)
;	{
;		UInt32 itmp; /* scratch */
;		UInt32 ixsq; /* ix * ix */
;		Int16 isignx; /* storage for sign of x. algorithm assumes x >= 0 then corrects later */
;		UInt32 ihypsq; /* (ix * ix) + (iy * iy) */
;		Int16 ir; /* result = ix / sqrt(ix*ix+iy*iy) range -1, 1 returned as signed Int16 */
;		Int16 idelta; /* delta on candidate result dividing each stage by factor of 2 */
;		/* stack variables */
;		/* ix, iy: signed 16 bit integers representing sensor reading in range -32768 to 32767 */
;		/* function returns signed Int16 as signed fraction (ie +32767=0.99997, -32768=-1.0000) */
;		/* algorithm solves for ir*ir*(ix*ix+iy*iy)=ix*ix */
;		/* correct for pathological case: ix==iy==0 */
;		if ((ix == 0) && (iy == 0)) ix = iy = 1;
;		/* check for -32768 which is not handled correctly */
;		if (ix == -32768) ix = -32767;
;		if (iy == -32768) iy = -32767;
;		/* store the sign for later use. algorithm assumes x is positive for convenience */
;		isignx = 1;
;		if (ix < 0)
;		{
;			ix = (Int16)-ix;
;			isignx = -1;
;		}
;		/* for convenience in the boosting set iy to be positive as well as ix */
;		iy = (Int16)Math.Abs(iy);
;		/* to reduce quantization effects, boost ix and iy but keep below maximum signed 16 bit */
;		while ((ix < 16384) && (iy < 16384))
;		{
;			ix = (Int16)(ix + ix);
;			iy = (Int16)(iy + iy);
;		}
;		/* calculate ix*ix and the hypotenuse squared */
;		ixsq = (UInt32)(ix * ix); /* ixsq=ix*ix: 0 to 32767^2 = 1073676289 */
;		ihypsq = (UInt32)(ixsq + iy * iy); /* ihypsq=(ix*ix+iy*iy) 0 to 2*32767*32767=2147352578 */
;		/* set result r to zero and binary search step to 16384 = 0.5 */
;		ir = 0;
;		idelta = 16384; /* set as 2^14 = 0.5 */
;		/* loop over binary sub-division algorithm */
;		do
;		{
;			/* generate new candidate solution for ir and test if we are too high or too low */
;			/* itmp=(ir+delta)^2, range 0 to 32767*32767 = 2^30 = 1073676289 */
;			itmp = (UInt32)((ir + idelta) * (ir + idelta));
;			/* itmp=(ir+delta)^2*(ix*ix+iy*iy), range 0 to 2^31 = 2147221516 */
;			itmp = (itmp >> 15) * (ihypsq >> 15);
;			if (itmp <= ixsq) ir += idelta;
;			idelta = (Int16)(idelta >> 1); /* divide by 2 using right shift one bit */
;		} while (idelta >= MINDELTATRIG); /* last loop is performed for idelta=MINDELTATRIG */
;		/* correct the sign before returning */
;		return (Int16)(ir * isignx);
;	}

iTrig proc ix:DWORD,iy:DWORD
	LOCAL	itmp:DWORD
	LOCAL	ixsq:DWORD
	LOCAL	isignx:WORD
	LOCAL	ihypsq:DWORD
	LOCAL	ir:WORD
	LOCAL	idelta:WORD

;PrintText "iTrig"
	;/* ix, iy: signed 16 bit integers representing sensor reading in range -32768 to 32767 */
	;/* function returns signed Int16 as signed fraction (ie +32767=0.99997, -32768=-1.0000) */
	;/* algorithm solves for ir*ir*(ix*ix+iy*iy)=ix*ix */
	;/* correct for pathological case: ix==iy==0 */
	;if ((ix == 0) && (iy == 0)) ix = iy = 1;
	.if ix==0 && iy==0
		mov		ix,1
		mov		iy,1
	.endif
	;/* check for -32768 which is not handled correctly */
	;if (ix == -32768) ix = -32767;
	.if sword ptr ix==sword ptr -32768
		mov		ix,-32767
	.endif
	;if (iy == -32768) iy = -32767;
	.if sword ptr iy==sword ptr -32768
		mov		iy,-32767
	.endif
	;/* store the sign for later use. algorithm assumes x is positive for convenience */
	;isignx = 1;
	mov		isignx,1
	;if (ix < 0)
	;{
	;	ix = (Int16)-ix;
	;	isignx = -1;
	;}
	.if sword ptr ix<0
		neg		ix
		mov		isignx,-1
	.endif
	;/* for convenience in the boosting set iy to be positive as well as ix */
	;iy = (Int16)Math.Abs(iy);
	.if sword ptr iy<0
		neg		iy
	.endif
	;/* to reduce quantization effects, boost ix and iy but keep below maximum signed 16 bit */
	;while ((ix < 16384) && (iy < 16384))
	;{
	;	ix = (Int16)(ix + ix);
	;	iy = (Int16)(iy + iy);
	;}
	.while ix<16384 && iy<16384
		shl		ix,1
		shl		iy,1
	.endw
	;/* calculate ix*ix and the hypotenuse squared */
	;ixsq = (UInt32)(ix * ix); /* ixsq=ix*ix: 0 to 32767^2 = 1073676289 */
	mov		ax,word ptr ix
	mov		cx,ax
	imul	cx
	mov		ixsq,eax
	;ihypsq = (UInt32)(ixsq + iy * iy); /* ihypsq=(ix*ix+iy*iy) 0 to 2*32767*32767=2147352578 */
	mov		ax,word ptr iy
	mov		cx,ax
	imul	cx
	add		eax,ixsq
	mov		ihypsq,eax
	;/* set result r to zero and binary search step to 16384 = 0.5 */
	;ir = 0;
	mov		ir,0
	;idelta = 16384; /* set as 2^14 = 0.5 */
	mov		idelta,16384

	;/* loop over binary sub-division algorithm */
	;do
	;{
	;	/* generate new candidate solution for ir and test if we are too high or too low */
	;	/* itmp=(ir+delta)^2, range 0 to 32767*32767 = 2^30 = 1073676289 */
	;	itmp = (UInt32)((ir + idelta) * (ir + idelta));
	;	/* itmp=(ir+delta)^2*(ix*ix+iy*iy), range 0 to 2^31 = 2147221516 */
	;	itmp = (itmp >> 15) * (ihypsq >> 15);
	;	if (itmp <= ixsq) ir += idelta;
	;	idelta = (Int16)(idelta >> 1); /* divide by 2 using right shift one bit */
	;} while (idelta >= MINDELTATRIG); /* last loop is performed for idelta=MINDELTATRIG */
	.while TRUE
		;/* generate new candidate solution for ir and test if we are too high or too low */
		;/* itmp=(ir+delta)^2, range 0 to 32767*32767 = 2^30 = 1073676289 */
		;itmp = (UInt32)((ir + idelta) * (ir + idelta));
		movsx	eax,ir
		movsx	ecx,idelta
		add		eax,ecx
		mov		ecx,eax
		imul	ecx
		mov		itmp,eax
		;itmp = (itmp >> 15) * (ihypsq >> 15);
		mov		eax,itmp
		shr		eax,15
		mov		ecx,ihypsq
		shr		ecx,15
		imul	ecx
		mov		itmp,eax
		;if (itmp <= ixsq) ir += idelta;
		mov		eax,itmp
		.if sdword ptr eax<=sdword ptr ixsq
			mov		cx,idelta
			add		ir,cx
		.endif
		;idelta = (Int16)(idelta >> 1); /* divide by 2 using right shift one bit */
		shr		idelta,1
		;} while (idelta >= MINDELTATRIG); /* last loop is performed for idelta=MINDELTATRIG */
		.break .if idelta<MINDELTATRIG
	.endw
	;/* correct the sign before returning */
	;return (Int16)(ir * isignx);
	mov		ax,ir
	.if sword ptr isignx<0
		neg		ax
	.endif
	ret

iTrig endp

;****************************************************************************************************************
;	7.4 ATAN2 Calculation C# Source Code
;	The function iHundredAtan2Deg is a wrapper function which implements the ATAN2 function by
;	assigning the results of an ATAN function to the correct quadrant. The result is the angle in degrees times
;	100.
;	/* calculates 100*atan2(iy/ix)=100*atan2(iy,ix) in deg for ix, iy in range -32768 to 32767 */
;	static Int16 iHundredAtan2Deg(Int16 iy, Int16 ix)
;	{
;		Int16 iResult; /* angle in degrees times 100 */
;		/* check for -32768 which is not handled correctly */
;		if (ix == -32768) ix = -32767;
;		if (iy == -32768) iy = -32767;
;		/* check for quadrants */
;		if ((ix >= 0) && (iy >= 0)) /* range 0 to 90 degrees */
;			iResult = iHundredAtanDeg(iy, ix);
;		else if ((ix <= 0) && (iy >= 0)) /* range 90 to 180 degrees */
;			iResult = (Int16)(18000 - (Int16)iHundredAtanDeg(iy, (Int16)-ix));
;		else if ((ix <= 0) && (iy <= 0)) /* range -180 to -90 degrees */
;			iResult = (Int16)((Int16)-18000 + iHundredAtanDeg((Int16)-iy, (Int16)-ix));
;		else /* ix >=0 and iy <= 0 giving range -90 to 0 degrees */
;			iResult = (Int16)(-iHundredAtanDeg((Int16)-iy, ix));
;	return (iResult);
;	}

iHundredAtan2Deg proc iy:DWORD,ix:DWORD
	LOCAL	iResult:WORD			;angle in degrees times 100

;PrintText "iHundredAtan2Deg"
	;check for -32768 which is not handled correctly
	;if (ix == -32768) ix = -32767;
	.if sword ptr ix==sword ptr -32768
		mov		ix,-32767
	.endif
	;if (iy == -32768) iy = -32767;
	.if sword ptr iy==sword ptr -32768
		mov		iy,-32767
	.endif
	;check for quadrants */
	;if ((ix >= 0) && (iy >= 0)) /* range 0 to 90 degrees */
	.if sword ptr ix>=0 && sword ptr iy>=0
		;iResult = iHundredAtanDeg(iy, ix);
		invoke iHundredAtanDeg,iy,ix
		mov		iResult,ax
	;else if ((ix <= 0) && (iy >= 0)) /* range 90 to 180 degrees */
	.elseif sword ptr ix<=0 && sword ptr iy>=0
		;iResult = (Int16)(18000 - (Int16)iHundredAtanDeg(iy, (Int16)-ix));
		mov		ax,word ptr ix
		neg		ax
		invoke iHundredAtanDeg,iy,ax
		mov		cx,18000
		sub		cx,ax
		mov		iResult,cx
	;else if ((ix <= 0) && (iy <= 0)) /* range -180 to -90 degrees */
	.elseif sword ptr ix<=0 && sword ptr iy<=0
		;iResult = (Int16)((Int16)-18000 + iHundredAtanDeg((Int16)-iy, (Int16)-ix));
		mov		cx,word ptr iy
		neg		cx
		mov		ax,word ptr ix
		neg		ax
		invoke iHundredAtanDeg,cx,ax
		mov		cx,-18000
		add		cx,ax
		mov		iResult,cx
	;else /* ix >=0 and iy <= 0 giving range -90 to 0 degrees */
	.else
		;iResult = (Int16)(-iHundredAtanDeg((Int16)-iy, ix));
		mov		cx,word ptr iy
		neg		cx
		invoke iHundredAtanDeg,cx,ix
		neg		ax
		mov		iResult,ax
	.endif
	movsx	eax,iResult
	ret

iHundredAtan2Deg endp

;****************************************************************************************************************
;	7.5 ATAN Calculation C# Source Code
;	The function iHundredAtanDeg computes the function for X and Y in the range 0 to 32767
;	(interpreted as 0.0 to 0.9999695 in Q15 fractional arithmetic) outputting the angle in degrees * 100 in the
;	range 0 to 9000 (0.0‹ to 90.0‹).
;	For Y. X the output angle is in the range 0‹ to 45‹ and is computed using the polynomial approximation:

;	Angle*100=(K1/2^15)*(Y/X)+(K2/2^45)*(Y/X)^3+(K3/2^75)*(Y/X)^5

;	For Y > X, the identity is used (valid in degrees for positive x):
;	atan(X)=90-atan(1/X)
;	Angle*100=9000-(K1/2^15)*(X/Y)+(K2/2^45)*(X/Y)^3+(K3/2^75)*(X/Y)^5
;	K1, K2 and K3 were computed by brute force optimization to minimize the maximum error

;	/* fifth order of polynomial approximation giving 0.05 deg max error */
;	const Int16 K1 = 5701;
;	const Int16 K2 = -1645;
;	const Int16 K3 = 446;
;	/* calculates 100*atan(iy/ix) range 0 to 9000 for all ix, iy positive in range 0 to 32767 */
;	static Int16 iHundredAtanDeg(Int16 iy, Int16 ix)
;	{
;		Int32 iAngle; /* angle in degrees times 100 */
;		Int16 iRatio; /* ratio of iy / ix or vice versa */
;		Int32 iTmp; /* temporary variable */
;		/* check for pathological cases */
;		if ((ix == 0) && (iy == 0)) return (0);
;		if ((ix == 0) && (iy != 0)) return (9000);
;		/* check for non-pathological cases */
;		if (iy <= ix)
;			iRatio = iDivide(iy, ix); /* return a fraction in range 0. to 32767 = 0. to 1. */
;		else
;			iRatio = iDivide(ix, iy); /* return a fraction in range 0. to 32767 = 0. to 1. */

;		/* first, third and fifth order polynomial approximation */
;		iAngle = (Int32) K1 * (Int32) iRatio;
;		iTmp = ((Int32) iRatio >> 5) * ((Int32) iRatio >> 5) * ((Int32) iRatio >> 5);
;		iAngle += (iTmp >> 15) * (Int32) K2;
;		iTmp = (iTmp >> 20) * ((Int32) iRatio >> 5) * ((Int32) iRatio >> 5)
;		iAngle += (iTmp >> 15) * (Int32) K3;
;		iAngle = iAngle >> 15;
;		/* check if above 45 degrees */
;		if (iy > ix) iAngle = (Int16)(9000 - iAngle);
;		/* for tidiness, limit result to range 0 to 9000 equals 0.0 to 90.0 degrees */
;		if (iAngle < 0) iAngle = 0;
;		if (iAngle > 9000) iAngle = 9000;
;		return ((Int16) iAngle);
;	}

iHundredAtanDeg proc iy:DWORD,ix:DWORD
	LOCAL	iAngle:DWORD			;angle in degrees times 100
	LOCAL	iRatio:WORD				;ratio of iy / ix or vice versa
	LOCAL	iTmp:DWORD				;temporary variable

;PrintText "iHundredAtanDeg"
	;/* check for pathological cases */
	;if ((ix == 0) && (iy == 0)) return (0);
	.if ix==0 && iy==0
		xor		eax,eax
		jmp		Ex
	.endif
	;if ((ix == 0) && (iy != 0)) return (9000);
	.if ix==0 && iy!=0
		mov		eax,9000
		jmp		Ex
	.endif
	;/* check for non-pathological cases */
	;if (iy <= ix)
	;	iRatio = iDivide(iy, ix); /* return a fraction in range 0. to 32767 = 0. to 1. */
	;else
	;	iRatio = iDivide(ix, iy); /* return a fraction in range 0. to 32767 = 0. to 1. */
	mov		ax,word ptr iy
	.if sword ptr ax<=sword ptr ix
		invoke iDivide,iy,ix		;return a fraction in range 0. to 32767 = 0. to 1.
		mov		iRatio,ax
	.else
		invoke iDivide,ix,iy		;return a fraction in range 0. to 32767 = 0. to 1.
		mov		iRatio,ax
	.endif
	;/* first, third and fifth order polynomial approximation */
	;iAngle = (Int32) K1 * (Int32) iRatio;
	mov		eax,K1
	movsx	ecx,iRatio
	imul	ecx
	mov		iAngle,eax
	;iTmp = ((Int32) iRatio >> 5) * ((Int32) iRatio >> 5) * ((Int32) iRatio >> 5);
	movsx	eax,iRatio
	shr		eax,5
	mov		ecx,eax
	imul	ecx
	imul	ecx
	mov		iTmp,eax
	;iAngle += (iTmp >> 15) * (Int32) K2;
	mov		ecx,iTmp
	shr		ecx,15
	mov		eax,K2
	imul	ecx
	add		iAngle,eax
	;iTmp = (iTmp >> 20) * ((Int32) iRatio >> 5) * ((Int32) iRatio >> 5)
	movzx	eax,iRatio
	shr		eax,5
	mov		ecx,eax
	imul	ecx
	mov		ecx,iTmp
	shr		ecx,20
	imul	ecx
	mov		iTmp,eax
	;iAngle += (iTmp >> 15) * (Int32) K3;
	mov		ecx,iTmp
	shr		ecx,15
	mov		eax,K3
	imul	ecx
	add		iAngle,eax
	;iAngle = iAngle >> 15;
	shr		iAngle,15
	;check if above 45 degrees
	;if (iy > ix) iAngle = (Int16)(9000 - iAngle);
	mov		ax,word ptr iy
	.if ax>word ptr ix
		mov		eax,9000
		sub		eax,iAngle
		mov		iAngle,eax
	.endif
	;/* for tidiness, limit result to range 0 to 9000 equals 0.0 to 90.0 degrees */
	;if (iAngle < 0) iAngle = 0;
	.if sdword ptr iAngle<0
		mov		iAngle,0
	.endif
	;if (iAngle > 9000) iAngle = 9000;
	.if iAngle>9000
		mov		iAngle,9000
	.endif
	;return ((Int16) iAngle);
	mov		eax,iAngle
	and		eax,0FFFFh
Ex:
	ret

iHundredAtanDeg endp

;****************************************************************************************************************
;	7.6 Integer Division C# Source Code
;	The function iDivide is an accurate integer division function where it is given that both the numerator and
;	denominator are non-negative, non-zero and where the denominator is greater than the numerator. The
;	result is in the range 0 decimal to 32767 decimal which is interpreted in Q15 fractional arithmetic as the
;	range 0.0 to 0.9999695.
;	The function solves for r where:
;	Eqn. 33
;	using a binary division algorithm to solve for:
;	Eqn. 34
;	The accuracy is determined by the threshold MINDELTADIV. The setting for maximum accuracy is
;	MINDELTADIV = 1.
;	const UInt16 MINDELTADIV = 1; /* final step size for iDivide */
;	
;	/* function to calculate ir = iy / ix with iy <= ix, and ix, iy both > 0 */
;	static Int16 iDivide(Int16 iy, Int16 ix)
;	{
;		Int16 itmp; /* scratch */
;		Int16 ir; /* result = iy / ix range 0., 1. returned in range 0 to 32767 */
;		Int16 idelta; /* delta on candidate result dividing each stage by factor of 2 */
;		/* set result r to zero and binary search step to 16384 = 0.5 */
;		ir = 0;
;		idelta = 16384; /* set as 2^14 = 0.5 */
;		/* to reduce quantization effects, boost ix and iy to the maximum signed 16 bit value */
;		while ((ix < 16384) && (iy < 16384))
;		{
;			ix = (Int16)(ix + ix);
;			iy = (Int16)(iy + iy);
;		}
;		/* loop over binary sub-division algorithm solving for ir*ix = iy */
;		do
;		{
;			/* generate new candidate solution for ir and test if we are too high or too low */
;			itmp = (Int16)(ir + idelta); /* itmp=ir+delta, the candidate solution */
;			itmp = (Int16)((itmp * ix) >> 15);
;			if (itmp <= iy) ir += idelta;
;			idelta = (Int16)(idelta >> 1); /* divide by 2 using right shift one bit */
;		} while (idelta >= MINDELTADIV); /* last loop is performed for idelta=MINDELTADIV */
;		return (ir);
;	}

iDivide proc iy:DWORD,ix:DWORD
	LOCAL	itmp:WORD					;scratch
	LOCAL	ir:WORD						;result = iy / ix range 0., 1. returned in range 0 to 32767
	LOCAL	idelta:WORD					;delta on candidate result dividing each stage by factor of 2

.if ix==0 || iy==0
	xor		eax,eax
	ret
.endif
	mov		ir,0						;set result r to zero and binary search step to 16384 = 0.5
	mov		idelta,16384				;set as 2^14 = 0.5
	;to reduce quantization effects, boost ix and iy to the maximum signed 16 bit value
	.while ix<16384 && iy<16384
		mov		ax,word ptr ix
		add		word ptr ix,ax
		mov		ax,word ptr iy
		add		word ptr iy,ax
	.endw
	;loop over binary sub-division algorithm solving for ir*ix = iy
	.while TRUE
		;generate new candidate solution for ir and test if we are too high or too low
		mov		ax,ir
		add		ax,idelta				;itmp=ir+delta, the candidate solution
		mov		cx,word ptr ix
		imul	cx
		shr		ax,15
		.if ax<=word ptr iy
			mov		ax,idelta
			add		ir,ax
			shr		idelta,1
		.endif
		mov		ax,idelta
		.break .if ax<MINDELTADIV
	.endw
	movzx		eax,ir
	ret

iDivide endp
